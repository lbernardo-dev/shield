import Foundation
import CloudKit
import SwiftUI

// MARK: - CloudSyncManager
// Backs up a minimized document index (metadata only) to the user's private
// CloudKit database. Local documents remain authoritative because document
// contents never leave the device and cannot be reconstructed from this index.
// File contents (images, PDFs) stay on-device only for maximum privacy.
// Safe to use even when CloudKit capability is not yet configured — all operations
// guard on isAvailable before touching CKContainer.

@MainActor
final class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()

    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var lastSyncDate: Date? = nil
    @Published private(set) var isAvailable: Bool = false

    enum SyncStatus: Equatable {
        case idle
        case syncing
        case success
        case error(String)
    }

    private let containerID = "iCloud.com.romerodev.shield"
    private let recordType = "ShieldDocument"
    private var isSyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: "shield.icloud.enabled")
    }

    private var ckContainer: CKContainer? {
        // Lazy — only create the CKContainer when actually needed.
        // CKContainer(identifier:) itself is safe, but guarding here
        // avoids any entitlement-related runtime assertions in debug builds.
        guard isSyncEnabled else { return nil }
        return CKContainer(identifier: containerID)
    }

    private init() {
        // Defer availability check to avoid blocking view init and to guard
        // against missing CloudKit entitlement during development.
        if UserDefaults.standard.bool(forKey: "shield.icloud.enabled") {
            Task { await checkAvailabilityAsync() }
        }
    }

    // MARK: - Availability

    func checkAvailability() {
        Task { await checkAvailabilityAsync() }
    }

    private func checkAvailabilityAsync() async {
        guard let container = ckContainer else {
            isAvailable = false
            return
        }
        let available: Bool = await withCheckedContinuation { continuation in
            container.accountStatus { status, _ in
                continuation.resume(returning: status == .available)
            }
        }
        isAvailable = available
    }

    // MARK: - Push (upload document index)

    func pushDocuments(_ documents: [DocumentItem]) async {
        guard isSyncEnabled, isAvailable, let container = ckContainer else { return }
        syncStatus = .syncing

        do {
            let db = container.privateCloudDatabase
            var records: [CKRecord] = []

            for doc in documents {
                let id = CKRecord.ID(recordName: "shield-doc-\(doc.id)")
                let record = CKRecord(recordType: recordType, recordID: id)
                record["docID"]          = doc.id as CKRecordValue
                // Never upload user-entered titles or sensitive document state.
                record["title"]          = "Protected document" as CKRecordValue
                record["kind"]           = doc.kind.rawValue as CKRecordValue
                record["category"]       = doc.category.rawValue as CKRecordValue
                record["date"]           = doc.date as CKRecordValue
                record["redactionCount"] = doc.totalRedactionCount as CKRecordValue
                record["isFavorite"]     = (doc.isFavorite ? 1 : 0) as CKRecordValue
                record["sourceType"]     = doc.sourceType.rawValue as CKRecordValue
                records.append(record)
            }

            // Mirror local index membership so records for locally deleted
            // documents cannot remain indefinitely in the private database.
            let localRecordIDs = Set(records.map(\.recordID))
            let remoteRecordIDs = try await fetchRemoteRecordIDs(in: db)
            let recordIDsToDelete = remoteRecordIDs.filter { !localRecordIDs.contains($0) }

            let op = CKModifyRecordsOperation(
                recordsToSave: records,
                recordIDsToDelete: recordIDsToDelete
            )
            op.savePolicy = .changedKeys
            op.qualityOfService = .userInitiated

            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                op.modifyRecordsResultBlock = { result in
                    switch result {
                    case .success: continuation.resume()
                    case .failure(let e): continuation.resume(throwing: e)
                    }
                }
                db.add(op)
            }

            syncStatus = .success
            lastSyncDate = Date()
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "shield.icloud.lastSync")
        } catch {
            syncStatus = .error(
                Self.isMissingRecordTypeError(error)
                    ? LanguageManager.shared.settings("settings_icloud_error_setup")
                    : Self.localizedSyncError(error)
            )
        }
    }

    // MARK: - Pull (fetch remote index to detect changes on other devices)

    func fetchRemoteIndex() async -> [CloudDocumentRecord] {
        guard isSyncEnabled, isAvailable, let container = ckContainer else { return [] }
        syncStatus = .syncing

        do {
            let db = container.privateCloudDatabase
            let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

            var page = try await db.records(matching: query, resultsLimit: 500)
            var records: [CloudDocumentRecord] = []
            while true {
                records.append(contentsOf: page.matchResults.compactMap { _, result in
                    guard case .success(let record) = result else { return nil }
                    return CloudDocumentRecord(from: record)
                })
                guard let cursor = page.queryCursor else { break }
                page = try await db.records(
                    continuingMatchFrom: cursor,
                    resultsLimit: 500
                )
            }
            syncStatus = .success
            lastSyncDate = Date()
            return records
        } catch {
            if Self.isMissingRecordTypeError(error) {
                // A new production container can legitimately have no schema yet.
                // Treat that as an empty remote index instead of exposing Apple's
                // internal developer error to the user.
                syncStatus = .success
                lastSyncDate = Date()
                return []
            }
            syncStatus = .error(Self.localizedSyncError(error))
            return []
        }
    }

    // MARK: - Delete

    func deleteRemoteDocument(id: String) async {
        guard isSyncEnabled, isAvailable, let container = ckContainer else { return }
        let recordID = CKRecord.ID(recordName: "shield-doc-\(id)")
        do {
            try await container.privateCloudDatabase.deleteRecord(withID: recordID)
        } catch {
            if !Self.isMissingRecordTypeError(error) {
                syncStatus = .error(Self.localizedSyncError(error))
            }
        }
    }

    // MARK: - Helpers

    @discardableResult
    func setSyncEnabled(_ enabled: Bool) async -> Bool {
        if enabled {
            UserDefaults.standard.set(true, forKey: "shield.icloud.enabled")
            await checkAvailabilityAsync()
            return true
        }

        guard isSyncEnabled else { return true }
        do {
            try await deleteAllRemoteIndex()
            UserDefaults.standard.set(false, forKey: "shield.icloud.enabled")
            isAvailable = false
            syncStatus = .idle
            UserDefaults.standard.removeObject(forKey: "shield.icloud.lastSync")
            lastSyncDate = nil
            return true
        } catch {
            syncStatus = .error(Self.localizedSyncError(error))
            return false
        }
    }

    /// Performs an ordered account check, upload and remote-index refresh.
    /// This avoids racing the first sync against CloudKit account discovery.
    func syncNow(documents: [DocumentItem]) async {
        guard isSyncEnabled else { return }
        await checkAvailabilityAsync()
        guard isAvailable else {
            syncStatus = .error(LanguageManager.shared.settings("settings_icloud_unavailable"))
            return
        }
        await pushDocuments(documents)
    }

    /// Called on app foreground to recheck account status and pull any remote changes.
    func syncOnForeground(documents: [DocumentItem]) {
        guard isSyncEnabled else { return }
        Task {
            await syncNow(documents: documents)
        }
    }

    static func isMissingRecordTypeError(_ error: Error) -> Bool {
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
        guard let d = lastSyncDate else {
            let ts = UserDefaults.standard.double(forKey: "shield.icloud.lastSync")
            guard ts > 0 else { return nil }
            return formatDate(Date(timeIntervalSince1970: ts))
        }
        return formatDate(d)
    }

    private func formatDate(_ d: Date) -> String {
        d.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened)
                .locale(Locale(identifier: LanguageManager.shared.current.rawValue))
        )
    }

    private func fetchRemoteRecordIDs(in database: CKDatabase) async throws -> [CKRecord.ID] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        do {
            var page = try await database.records(
                matching: query,
                desiredKeys: [],
                resultsLimit: 500
            )
            var recordIDs: [CKRecord.ID] = []
            while true {
                recordIDs.append(contentsOf: page.matchResults.compactMap { recordID, result in
                    guard case .success = result else { return nil }
                    return recordID
                })
                guard let cursor = page.queryCursor else { break }
                page = try await database.records(
                    continuingMatchFrom: cursor,
                    desiredKeys: [],
                    resultsLimit: 500
                )
            }
            return recordIDs
        } catch where Self.isMissingRecordTypeError(error) {
            return []
        }
    }

    private func deleteAllRemoteIndex() async throws {
        guard let container = ckContainer else { return }
        let status = try await container.accountStatus()
        guard status == .available else { throw CKError(.notAuthenticated) }
        let database = container.privateCloudDatabase
        let recordIDs = try await fetchRemoteRecordIDs(in: database)
        guard !recordIDs.isEmpty else { return }

        let operation = CKModifyRecordsOperation(
            recordsToSave: nil,
            recordIDsToDelete: recordIDs
        )
        operation.qualityOfService = .userInitiated
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            operation.modifyRecordsResultBlock = { result in
                continuation.resume(with: result)
            }
            database.add(operation)
        }
    }
}

// MARK: - CloudDocumentRecord

struct CloudDocumentRecord {
    let docID: String
    let title: String
    let kind: String
    let category: String
    let date: Date
    let redactionCount: Int
    let isFavorite: Bool
    let isVaulted: Bool

    init?(from record: CKRecord) {
        guard let docID = record["docID"] as? String,
              let title = record["title"] as? String else { return nil }
        self.docID         = docID
        self.title         = title
        self.kind          = record["kind"] as? String ?? "photo"
        self.category      = record["category"] as? String ?? "identity"
        self.date          = record["date"] as? Date ?? Date()
        self.redactionCount = record["redactionCount"] as? Int ?? 0
        self.isFavorite    = (record["isFavorite"] as? Int ?? 0) == 1
        self.isVaulted     = (record["isVaulted"] as? Int ?? 0) == 1
    }
}
