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

    private let containerID = "iCloud.com.romerodev.shield"
    private let recordType = "ShieldDocumentV2"
    private let legacyRecordType = "ShieldDocument"
    private let pendingDeletionKey = "shield.icloud.pendingDeletionIDs"

    private var isSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: "shield.icloud.enabled")
    }

    private var ckContainer: CKContainer? {
        guard isSyncEnabled else { return nil }
        return CKContainer(identifier: containerID)
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
            UserDefaults.standard.set(true, forKey: "shield.icloud.enabled")
            await checkAvailabilityAsync()
            if !isAvailable {
                UserDefaults.standard.set(false, forKey: "shield.icloud.enabled")
                syncStatus = .error(LanguageManager.shared.settings("settings_icloud_unavailable"))
                return false
            }
            return true
        }

        guard isSyncEnabled else { return true }
        do {
            try await deleteAllRemoteDocuments()
            UserDefaults.standard.set(false, forKey: "shield.icloud.enabled")
            UserDefaults.standard.removeObject(forKey: "shield.icloud.lastSync")
            UserDefaults.standard.removeObject(forKey: pendingDeletionKey)
            isAvailable = false
            lastSyncDate = nil
            syncStatus = .idle
            return true
        } catch {
            syncStatus = .error(Self.localizedSyncError(error))
            return false
        }
    }

    /// Reconciles complete, restorable document packages in the user's private
    /// CloudKit database. Private CKAssets are encrypted by CloudKit by default.
    func syncNow(appState: AppState) async {
        guard isSyncEnabled else { return }
        await checkAvailabilityAsync()
        guard isAvailable, let container = ckContainer else {
            syncStatus = .error(LanguageManager.shared.settings("settings_icloud_unavailable"))
            return
        }

        syncStatus = .syncing
        do {
            let database = container.privateCloudDatabase
            for id in pendingDeletionIDs {
                try await deleteRemoteRecords(id: id, from: database)
                removePendingDeletion(id)
            }
            let remote = try await fetchRemoteDocuments(in: database)
            var localByID = Dictionary(uniqueKeysWithValues: appState.documents.map { ($0.id, $0) })

            // Pull remote creations and newer edits first so a new device never
            // erases an existing cloud library merely because its local library is empty.
            for (id, remoteDocument) in remote {
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
                let remoteDocument = remote[document.id]
                if remoteDocument == nil ||
                    document.modifiedAt > remoteDocument!.package.document.modifiedAt {
                    try await upload(
                        document,
                        existingRecord: remoteDocument?.record,
                        to: database
                    )
                }
            }

            markSuccess()
        } catch {
            syncStatus = .error(
                Self.isMissingSchemaError(error)
                    ? LanguageManager.shared.settings("settings_icloud_error_setup")
                    : Self.localizedSyncError(error)
            )
        }
    }

    func syncOnForeground(appState: AppState) {
        guard isSyncEnabled else { return }
        Task { await syncNow(appState: appState) }
    }

    func scheduleRemoteDeletion(id: String) {
        var ids = pendingDeletionIDs
        ids.insert(id)
        UserDefaults.standard.set(Array(ids), forKey: pendingDeletionKey)
        Task { await deleteRemoteDocument(id: id) }
    }

    func deleteRemoteDocument(id: String) async {
        guard isSyncEnabled else { return }
        await checkAvailabilityAsync()
        guard isAvailable, let container = ckContainer else { return }
        do {
            try await deleteRemoteRecords(id: id, from: container.privateCloudDatabase)
            removePendingDeletion(id)
        } catch {
            syncStatus = .error(Self.localizedSyncError(error))
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

    private var pendingDeletionIDs: Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: pendingDeletionKey) ?? [])
    }

    private func removePendingDeletion(_ id: String) {
        var ids = pendingDeletionIDs
        ids.remove(id)
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
        guard let container = ckContainer else { return }
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
