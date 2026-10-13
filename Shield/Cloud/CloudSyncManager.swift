import CloudKit
import Foundation

struct CloudAssetPayload: Codable {
    enum Kind: String, Codable {
        case image
        case source
    }

    let kind: Kind
    let fileName: String
    let data: Data
}

private struct CloudDocumentPackage: Codable {
    let document: DocumentItem
    let assets: [CloudAssetPayload]
}

@MainActor
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    static let cloudKitContainerIdentifier = "iCloud.com.romerodev.shield"

    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var isAvailable = false

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case error(String)
    }

    private struct RemoteDocument {
        let record: CKRecord
        let package: CloudDocumentPackage
    }

    private let recordType = "ShieldDocumentV2"
    private let legacyRecordType = "ShieldDocument"
    private let pendingDeletionKey = "shield.icloud.pendingDeletionIDs"
    private var isDisablingSync = false

    private var isSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: "shield.icloud.enabled")
    }

    private var ckContainer: CKContainer? {
        guard isSyncEnabled else { return nil }
        return CKContainer(identifier: Self.cloudKitContainerIdentifier)
    }

    private init() {
        if isSyncEnabled {
            Task { await checkAvailabilityAsync() }
        }
    }

    func checkAvailability() {
        Task { await checkAvailabilityAsync() }
    }

    private func checkAvailabilityAsync() async {
        guard let container = ckContainer else {
            isAvailable = false
            return
        }
        do {
            isAvailable = try await container.accountStatus() == .available
        } catch {
            isAvailable = false
        }
    }

    @discardableResult
    func setSyncEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            guard PremiumManager.shared.isPro else {
                syncStatus = .error(LanguageManager.shared.settings("settings_icloud_pro_only"))
                return false
            }
            UserDefaults.standard.set(true, forKey: "shield.icloud.enabled")
            await checkAvailabilityAsync()
            guard PremiumManager.shared.isPro else {
                UserDefaults.standard.set(false, forKey: "shield.icloud.enabled")
                syncStatus = .error(LanguageManager.shared.settings("settings_icloud_pro_only"))
                return false
            }
            if !isAvailable {
                UserDefaults.standard.set(false, forKey: "shield.icloud.enabled")
                syncStatus = .error(LanguageManager.shared.settings("settings_icloud_unavailable"))
                return false
            }
            return true
        }

        guard isSyncEnabled else { return true }
        isDisablingSync = true
        defer { isDisablingSync = false }
        // Stop new reconciliation before deleting records so an in-flight
        // upload can detect the opt-out when it returns from CloudKit.
        UserDefaults.standard.set(false, forKey: "shield.icloud.enabled")
        do {
            try await deleteAllRemoteDocuments()
            UserDefaults.standard.removeObject(forKey: "shield.icloud.lastSync")
            isAvailable = false
            lastSyncDate = nil
            syncStatus = .idle
            return true
        } catch {
            UserDefaults.standard.set(true, forKey: "shield.icloud.enabled")
            syncStatus = .error(Self.localizedSyncError(error))
            return false
        }
    }

    /// Reconciles complete, restorable packages for non-Vault documents in the
    /// user's private CloudKit database. Private CKAssets are encrypted by CloudKit.
    func syncNow(appState: AppState) async {
        guard Self.canSynchronize(userOptedIn: isSyncEnabled, hasProAccess: PremiumManager.shared.isPro) else {
            return
        }
        await checkAvailabilityAsync()
        guard Self.canSynchronize(userOptedIn: isSyncEnabled, hasProAccess: PremiumManager.shared.isPro) else {
            syncStatus = .idle
            return
        }
        guard isAvailable, let container = ckContainer else {
            syncStatus = .error(LanguageManager.shared.settings("settings_icloud_unavailable"))
            return
        }

        syncStatus = .syncing
        do {
            let database = container.privateCloudDatabase
            try await deletePendingRemoteRecords(in: database)
            var remote = try await fetchRemoteDocuments(in: database)
            var localByID = Dictionary(appState.documents.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let localVaultedIDs = Set(appState.vaultDocuments.map(\.id))
            guard Self.canSynchronize(userOptedIn: isSyncEnabled, hasProAccess: PremiumManager.shared.isPro) else {
                syncStatus = .idle
                return
            }

            // Pull remote creations and newer edits first so a new device never
            // erases an existing cloud library merely because its local library is empty.
            for id in remote.keys.sorted() {
                guard Self.canSynchronize(userOptedIn: isSyncEnabled, hasProAccess: PremiumManager.shared.isPro) else {
                    syncStatus = .idle
                    return
                }
                guard let remoteDocument = remote[id] else { continue }
                guard !Self.shouldDiscardRemotePackage(
                    localDocumentIsVaulted: localVaultedIDs.contains(id),
                    remoteDocument: remoteDocument.package.document
                ) else {
                    // Remove legacy Vault packages instead of restoring or retaining them.
                    try await deleteRemoteRecords(id: id, from: database)
                    remote.removeValue(forKey: id)
                    continue
                }
                let local = localByID[id]
                if local == nil || remoteDocument.package.document.modifiedAt > local!.modifiedAt {
                    try appState.restoreCloudDocument(
                        remoteDocument.package.document,
                        assets: remoteDocument.package.assets
                    )
                    localByID[id] = remoteDocument.package.document
                }
            }

            // Push local creations and edits. Deletions are explicit from AppState,
            // which avoids interpreting a fresh device as a delete-all operation.
            for document in appState.documents {
                guard Self.canSynchronize(userOptedIn: isSyncEnabled, hasProAccess: PremiumManager.shared.isPro) else {
                    syncStatus = .idle
                    return
                }
                let documentID = document.id
                guard let currentDocument = appState.documents.first(where: { $0.id == documentID }),
                      Self.isEligibleForCloudSync(currentDocument)
                else { continue }

                let remoteDocument = remote[documentID]
                if remoteDocument == nil ||
                    currentDocument.modifiedAt > remoteDocument!.package.document.modifiedAt {
                    try await upload(
                        currentDocument,
                        existingRecord: remoteDocument?.record,
                        to: database
                    )

                    // Vault moves and deletions can happen while CloudKit is
                    // saving. Remove a just-uploaded package if its local record
                    // stopped being eligible during that request.
                    guard isSyncEnabled,
                          let latestDocument = appState.documents.first(where: { $0.id == documentID }),
                          Self.isEligibleForCloudSync(latestDocument)
                    else {
                        queueRemoteDeletion(id: documentID)
                        try await deleteRemoteRecords(id: documentID, from: database)
                        removePendingDeletion(documentID)
                        remote.removeValue(forKey: documentID)
                        continue
                    }
                }
            }

            // A Vault move can enqueue deletion while the reconciliation above
            // is suspended on CloudKit requests.
            try await deletePendingRemoteRecords(in: database)
            markSuccess()
        } catch {
            syncStatus = .error(
                Self.isMissingSchemaError(error)
                    ? LanguageManager.shared.settings("settings_icloud_error_setup")
                    : Self.localizedSyncError(error)
            )
        }
    }

    static func isEligibleForCloudSync(_ document: DocumentItem) -> Bool {
        !document.isVaulted
    }

    static func canSynchronize(userOptedIn: Bool, hasProAccess: Bool) -> Bool {
        userOptedIn && hasProAccess
    }

    static func shouldDiscardRemotePackage(
        localDocumentIsVaulted: Bool,
        remoteDocument: DocumentItem
    ) -> Bool {
        localDocumentIsVaulted || !isEligibleForCloudSync(remoteDocument)
    }

    func syncOnForeground(appState: AppState) {
        guard Self.canSynchronize(userOptedIn: isSyncEnabled, hasProAccess: PremiumManager.shared.isPro) else {
            if !pendingDeletionIDs.isEmpty {
                Task { await retryPendingRemoteDeletions() }
            }
            return
        }
        Task { await syncNow(appState: appState) }
    }

    func scheduleRemoteDeletion(id: String) {
        guard isSyncEnabled || isDisablingSync else { return }
        queueRemoteDeletion(id: id)
        Task { await deleteRemoteDocument(id: id) }
    }

    func deleteRemoteDocument(id: String) async {
        guard let database = await privateCloudDatabaseForRemoval() else { return }
        do {
            try await deleteRemoteRecords(id: id, from: database)
            removePendingDeletion(id)
        } catch {
            syncStatus = .error(Self.localizedSyncError(error))
        }
    }

    private func retryPendingRemoteDeletions() async {
        guard !pendingDeletionIDs.isEmpty,
              let database = await privateCloudDatabaseForRemoval()
        else { return }
        do {
            try await deletePendingRemoteRecords(in: database)
        } catch {
            syncStatus = .error(Self.localizedSyncError(error))
        }
    }

    private func privateCloudDatabaseForRemoval() async -> CKDatabase? {
        let container = CKContainer(identifier: Self.cloudKitContainerIdentifier)
        do {
            guard try await container.accountStatus() == .available else { return nil }
            return container.privateCloudDatabase
        } catch {
            return nil
        }
    }

    private func deleteRemoteRecords(id: String, from database: CKDatabase) async throws {
        for type in [recordType, legacyRecordType] {
            let recordID = CKRecord.ID(recordName: recordName(for: id, type: type))
            do {
                try await database.deleteRecord(withID: recordID)
            } catch let error as CKError where error.code == .unknownItem {
                continue
            }
        }
    }

    private func deletePendingRemoteRecords(in database: CKDatabase) async throws {
        for id in pendingDeletionIDs.sorted() {
            try await deleteRemoteRecords(id: id, from: database)
            removePendingDeletion(id)
        }
    }

    private var pendingDeletionIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: pendingDeletionKey) ?? [])
    }

    private func removePendingDeletion(_ id: String) {
        var ids = pendingDeletionIDs
        ids.remove(id)
        UserDefaults.standard.set(Array(ids), forKey: pendingDeletionKey)
    }

    private func queueRemoteDeletion(id: String) {
        var ids = pendingDeletionIDs
        ids.insert(id)
        UserDefaults.standard.set(Array(ids), forKey: pendingDeletionKey)
    }

    private func upload(
        _ document: DocumentItem,
        existingRecord: CKRecord?,
        to database: CKDatabase
    ) async throws {
        let package = try makePackage(for: document)
        let data = try PropertyListEncoder().encode(package)
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("shield-cloud-\(UUID().uuidString).package")
        try data.write(to: temporaryURL, options: [.atomic, .completeFileProtection])
        defer { try? FileManager.default.removeItem(at: temporaryURL) }

        let record = existingRecord ?? CKRecord(
            recordType: recordType,
            recordID: CKRecord.ID(recordName: recordName(for: document.id, type: recordType))
        )
        record["docID"] = document.id as CKRecordValue
        record["modifiedAt"] = document.modifiedAt as CKRecordValue
        record["package"] = CKAsset(fileURL: temporaryURL)
        _ = try await database.save(record)
    }

    private func makePackage(for document: DocumentItem) throws -> CloudDocumentPackage {
        var assets: [CloudAssetPayload] = []
        for fileName in document.allImageFileNames.sorted() {
            let url = AppState.resolveImageURL(fileName: fileName, isVaulted: document.isVaulted)
            let data = try SecureFileStore.shared.read(from: url)
            assets.append(CloudAssetPayload(kind: .image, fileName: fileName, data: data))
        }
        if let fileName = document.sourceFileName {
            let url = AppState.resolveSourceURL(fileName: fileName, isVaulted: document.isVaulted)
            let data = try SecureFileStore.shared.read(from: url)
            assets.append(CloudAssetPayload(kind: .source, fileName: fileName, data: data))
        }
        return CloudDocumentPackage(document: document, assets: assets)
    }

    private func fetchRemoteDocuments(in database: CKDatabase) async throws -> [String: RemoteDocument] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        do {
            var page = try await database.records(matching: query, resultsLimit: 100)
            var result: [String: RemoteDocument] = [:]
            while true {
                for (_, recordResult) in page.matchResults {
                    guard case .success(let record) = recordResult,
                          let id = record["docID"] as? String,
                          let asset = record["package"] as? CKAsset,
                          let url = asset.fileURL
                    else { continue }
                    let data = try Data(contentsOf: url)
                    let package = try PropertyListDecoder().decode(CloudDocumentPackage.self, from: data)
                    result[id] = RemoteDocument(record: record, package: package)
                }
                guard let cursor = page.queryCursor else { break }
                page = try await database.records(continuingMatchFrom: cursor, resultsLimit: 100)
            }
            return result
        } catch where Self.isMissingSchemaError(error) {
            return [:]
        }
    }

    private func deleteAllRemoteDocuments() async throws {
        let container = CKContainer(identifier: Self.cloudKitContainerIdentifier)
        guard try await container.accountStatus() == .available else {
            throw CKError(.notAuthenticated)
        }
        let database = container.privateCloudDatabase
        var recordIDs: [CKRecord.ID] = []
        for type in [recordType, legacyRecordType] {
            recordIDs += try await fetchRecordIDs(for: type, in: database)
        }
        guard !recordIDs.isEmpty else { return }
        let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIDs)
        operation.qualityOfService = .userInitiated
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsResultBlock = { continuation.resume(with: $0) }
            database.add(operation)
        }
    }

    private func fetchRecordIDs(for type: String, in database: CKDatabase) async throws -> [CKRecord.ID] {
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        do {
            var page = try await database.records(matching: query, desiredKeys: [], resultsLimit: 500)
            var ids: [CKRecord.ID] = []
            while true {
                ids += page.matchResults.compactMap { id, result in
                    guard case .success = result else { return nil }
                    return id
                }
                guard let cursor = page.queryCursor else { break }
                page = try await database.records(
                    continuingMatchFrom: cursor,
                    desiredKeys: [],
                    resultsLimit: 500
                )
            }
            return ids
        } catch where Self.isMissingSchemaError(error) {
            return []
        }
    }

    private func recordName(for id: String, type: String) -> String {
        type == legacyRecordType ? "shield-doc-\(id)" : "shield-doc-v2-\(id)"
    }

    private func markSuccess() {
        syncStatus = .success
        lastSyncDate = Date()
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "shield.icloud.lastSync")
    }

    static func isMissingRecordTypeError(_ error: Error) -> Bool {
        isMissingSchemaError(error)
    }

    private static func isMissingSchemaError(_ error: Error) -> Bool {
        guard let cloudError = error as? CKError else { return false }
        return cloudError.code == .unknownItem
    }

    private static func localizedSyncError(_ error: Error) -> String {
        guard let cloudError = error as? CKError else {
            return LanguageManager.shared.settings("settings_icloud_error_retry")
        }
        switch cloudError.code {
        case .networkFailure, .networkUnavailable, .serviceUnavailable,
             .requestRateLimited, .zoneBusy:
            return LanguageManager.shared.settings("settings_icloud_error_retry")
        case .notAuthenticated:
            return LanguageManager.shared.settings("settings_icloud_unavailable")
        case .quotaExceeded:
            return LanguageManager.shared.settings("settings_icloud_error_quota")
        default:
            return LanguageManager.shared.settings("settings_icloud_error_retry")
        }
    }

    var lastSyncFormatted: String? {
        let date = lastSyncDate ?? {
            let timestamp = UserDefaults.standard.double(forKey: "shield.icloud.lastSync")
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }()
        return date?.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened)
                .locale(Locale(identifier: LanguageManager.shared.current.rawValue))
        )
    }
}
