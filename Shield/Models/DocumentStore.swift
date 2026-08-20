import Foundation
import OSLog

// MARK: - DocumentStore

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

        if !fileManager.fileExists(atPath: documentsDirectory.path) {
            try? fileManager.createDirectory(at: documentsDirectory, withIntermediateDirectories: true)
        }

        performMigrationIfNeeded()
    }

    // MARK: - Load All Documents

    func loadAllDocuments() -> [DocumentItem] {
        var documents: [DocumentItem] = []

        guard let fileURLs = try? fileManager.contentsOfDirectory(
            at: documentsDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let jsonURLs = fileURLs.filter { $0.pathExtension.lowercased() == "json" }

        for url in jsonURLs {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let doc = try decoder.decode(DocumentItem.self, from: data)
                documents.append(doc)
            } catch {
                logger.error("Failed to decode document at \(url.lastPathComponent, privacy: .public): \(error.localizedDescription, privacy: .private)")
            }
        }

        return documents.sorted { $0.date > $1.date }
    }

    // MARK: - Save Single Document (Atomic O(1))

    func saveDocument(_ document: DocumentItem) {
        let fileURL = documentsDirectory.appendingPathComponent("\(document.id).json")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(document)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Failed to save document \(document.id, privacy: .public): \(error.localizedDescription, privacy: .private)")
        }
    }

    // MARK: - Delete Single Document

    func deleteDocument(id: String) {
        let fileURL = documentsDirectory.appendingPathComponent("\(id).json")
        if fileManager.fileExists(atPath: fileURL.path) {
            try? fileManager.removeItem(at: fileURL)
        }
    }

    // MARK: - Batch Save

    func saveAllDocuments(_ documents: [DocumentItem]) {
        for doc in documents {
            saveDocument(doc)
        }
    }

    // MARK: - Migration from Legacy Monolithic shield_documents.json

    private func performMigrationIfNeeded() {
        guard fileManager.fileExists(atPath: legacyFileURL.path) else { return }

        // If documents directory is empty, migrate from legacy JSON
        let existingFiles = (try? fileManager.contentsOfDirectory(atPath: documentsDirectory.path)) ?? []
        if existingFiles.isEmpty {
            logger.info("Migrating legacy shield_documents.json to granular document store...")
            do {
                let data = try Data(contentsOf: legacyFileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let legacyDocs = try decoder.decode([DocumentItem].self, from: data)

                for doc in legacyDocs {
                    saveDocument(doc)
                }

                logger.info("Migrated \(legacyDocs.count) documents to granular storage successfully.")
            } catch {
                logger.error("Failed to migrate legacy documents: \(error.localizedDescription, privacy: .private)")
            }
        }
    }
}
