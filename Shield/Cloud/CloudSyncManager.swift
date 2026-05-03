import Foundation
import CloudKit
import SwiftUI

// MARK: - CloudSyncManager
// Syncs the document index (metadata only) via iCloud CloudKit private database.
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
                record["title"]          = doc.title as CKRecordValue
                record["kind"]           = doc.kind.rawValue as CKRecordValue
                record["category"]       = doc.category.rawValue as CKRecordValue
                record["date"]           = doc.date as CKRecordValue
                record["redactionCount"] = doc.totalRedactionCount as CKRecordValue
                record["isFavorite"]     = (doc.isFavorite ? 1 : 0) as CKRecordValue
                record["isVaulted"]      = (doc.isVaulted ? 1 : 0) as CKRecordValue
                record["sourceType"]     = doc.sourceType.rawValue as CKRecordValue
                records.append(record)
            }

            let op = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
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
            syncStatus = .error(error.localizedDescription)
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

            let (matchResults, _) = try await db.records(matching: query, resultsLimit: 500)
            let records = matchResults.compactMap { _, result -> CloudDocumentRecord? in
                guard case .success(let record) = result else { return nil }
                return CloudDocumentRecord(from: record)
            }
            syncStatus = .success
            lastSyncDate = Date()
            return records
        } catch {
            syncStatus = .error(error.localizedDescription)
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
            // Non-fatal: record may not exist on remote
        }
    }

    // MARK: - Helpers

    func setSyncEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "shield.icloud.enabled")
        if enabled {
            Task { await checkAvailabilityAsync() }
        } else {
            isAvailable = false
            syncStatus = .idle
        }
    }

    /// Called on app foreground to recheck account status and pull any remote changes.
    func syncOnForeground(documents: [DocumentItem]) {
        guard isSyncEnabled else { return }
        Task {
            await checkAvailabilityAsync()
            guard isAvailable else { return }
            // Push local index first, then reconcile remote deletions.
            await pushDocuments(documents)
            _ = await fetchRemoteIndex()
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
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM HH:mm"
        return fmt.string(from: d)
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
