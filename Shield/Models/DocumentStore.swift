import Foundation
import OSLog

// MARK: - DocumentStore

/// Reads and migrates the legacy per-document store. AppState now keeps the
/// encrypted documents.json snapshot as the single canonical document store.
final class DocumentStore {
    static let shared = DocumentStore()

    private let fileManager = FileManager.default
    private let logger = Logger(subsystem: "com.romerodev.shield", category: "DocumentStore")

    private let documentsDirectory: URL
    private let legacyFileURL: URL

    private init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.documentsDirectory = docs.appendingPathComponent("shield_documents", isDirectory: true)
        self.legacyFileURL = docs.appendingPathComponent("shield_documents.json")

        try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Load Legacy Documents

    func loadAllDocuments() -> [DocumentItem] {
        let perDocumentRecords = loadPerDocumentRecords()
        if !perDocumentRecords.isEmpty {
            return perDocumentRecords
        }
        if let snapshot = loadLegacySnapshot() {
            return snapshot.sorted { $0.date > $1.date }
        }
        return []
    }

    /// An empty array is meaningful when migrating: it records that the user
    /// deleted every document in the old monolithic format.
    func loadLegacySnapshot() -> [DocumentItem]? {
        guard fileManager.fileExists(atPath: legacyFileURL.path) else { return nil }
        do {
            let data = try SecureFileStore.shared.read(from: legacyFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([DocumentItem].self, from: data)
        } catch {
            logger.error("Failed to decode legacy document snapshot: \(error.localizedDescription, privacy: .private)")
            return nil
        }
    }

    /// Recovers per-document writes that landed just before an older release
    /// crashed while updating its monolithic snapshot. That release wrote the
    /// records first and the snapshot second, so only records newer than the
    /// snapshot can safely override it.
    func loadDocumentsModified(after snapshotDate: Date) -> [DocumentItem]? {
        let fileURLs = (try? fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        let jsonURLs = fileURLs.filter { $0.pathExtension.lowercased() == "json" }
        var documents: [DocumentItem] = []

        for url in jsonURLs {
            guard let modifiedAt = try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
                logger.error("Failed to read modification date for legacy document \(url.lastPathComponent, privacy: .public)")
                return nil
            }
            guard modifiedAt > snapshotDate else { continue }

            do {
                let data = try SecureFileStore.shared.read(from: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let document = try decoder.decode(DocumentItem.self, from: data)
                if !SecureFileStore.shared.isEncryptedFile(at: url) {
                    try SecureFileStore.shared.write(data, to: url)
                    guard SecureFileStore.shared.isEncryptedFile(at: url),
                          try SecureFileStore.shared.read(from: url) == data else {
                        throw SecureFileStoreError.invalidCiphertext
                    }
                }
                documents.append(document)
            } catch {
                logger.error("Failed to recover legacy document \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .private)")
                return nil
            }
        }

        return documents
    }

    private func loadPerDocumentRecords() -> [DocumentItem] {
        var documents: [DocumentItem] = []

        let fileURLs = (try? fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        let jsonURLs = fileURLs.filter { $0.pathExtension.lowercased() == "json" }
        var failedToLoadRecord = false

        for url in jsonURLs {
            do {
                let data = try SecureFileStore.shared.read(from: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let document = try decoder.decode(DocumentItem.self, from: data)

                // Older releases wrote these records as plaintext JSON. Replace
                // each legacy record atomically before allowing it into the app.
                if !SecureFileStore.shared.isEncryptedFile(at: url) {
                    try SecureFileStore.shared.write(data, to: url)
                    guard SecureFileStore.shared.isEncryptedFile(at: url),
                          try SecureFileStore.shared.read(from: url) == data else {
                        throw SecureFileStoreError.invalidCiphertext
                    }
                }

                documents.append(document)
            } catch {
                failedToLoadRecord = true
                logger.error("Failed to load legacy document at \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .private)")
            }
        }

        // Do not migrate a partial snapshot and then discard unreadable records.
        // Leave all legacy files available for a later retry or manual recovery.
        guard !failedToLoadRecord else { return [] }

        return documents.sorted { $0.date > $1.date }
    }

    // MARK: - Encrypted Compatibility Store

    @discardableResult
    func saveDocument(_ document: DocumentItem) -> Bool {
        let fileURL = documentsDirectory.appendingPathComponent("\(document.id).json")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(document)
            try SecureFileStore.shared.write(data, to: fileURL)
            guard SecureFileStore.shared.isEncryptedFile(at: fileURL),
                  try SecureFileStore.shared.read(from: fileURL) == data else {
                throw SecureFileStoreError.invalidCiphertext
            }
            return true
        } catch {
            logger.error("Failed to save document \(document.id, privacy: .public): \(error.localizedDescription, privacy: .private)")
            return false
        }
    }

    func deleteDocument(id: String) {
        let fileURL = documentsDirectory.appendingPathComponent("\(id).json")
        do {
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            logger.error("Failed to delete document \(id, privacy: .public): \(error.localizedDescription, privacy: .private)")
        }
    }

    /// Persists every record before pruning stale IDs, so a failed write cannot
    /// turn a partial batch into data loss.
    @discardableResult
    func saveAllDocuments(_ documents: [DocumentItem]) -> Bool {
        for document in documents where !saveDocument(document) {
            return false
        }

        let retainedIDs = Set(documents.map(\.id))
        let fileURLs = (try? fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        do {
            for url in fileURLs where url.pathExtension.lowercased() == "json" {
                guard !retainedIDs.contains(url.deletingPathExtension().lastPathComponent) else { continue }
                try fileManager.removeItem(at: url)
            }
            return true
        } catch {
            logger.error("Failed to reconcile document records: \(error.localizedDescription, privacy: .private)")
            return false
        }
    }

    /// Removes only the legacy document metadata after the encrypted canonical
    /// snapshot has been verified by AppState.
    func removeLegacyFiles() {
        let fileURLs = (try? fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )) ?? []

        for url in fileURLs where url.pathExtension.lowercased() == "json" {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                logger.error("Failed to remove legacy document at \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .private)")
            }
        }

        do {
            if fileManager.fileExists(atPath: legacyFileURL.path) {
                try fileManager.removeItem(at: legacyFileURL)
            }
        } catch {
            logger.error("Failed to remove legacy document snapshot: \(error.localizedDescription, privacy: .private)")
        }
    }
}
