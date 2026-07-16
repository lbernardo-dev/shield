import CryptoKit
import Foundation
import Security

nonisolated struct SharedImportPayload: Codable, Sendable, Equatable {
    let originalFileName: String
    let typeIdentifier: String
    let createdAt: Date
    let data: Data
}

enum SharedImportCryptor {
    nonisolated static func seal(_ payload: SharedImportPayload, keyData: Data) throws -> Data {
        let encoded = try JSONEncoder().encode(payload)
        let key = SymmetricKey(data: keyData)
        let box = try AES.GCM.seal(encoded, using: key)
        guard let combined = box.combined else { throw SharedImportStoreError.encryptionFailed }
        return combined
    }

    nonisolated static func open(_ encrypted: Data, keyData: Data) throws -> SharedImportPayload {
        let key = SymmetricKey(data: keyData)
        let box = try AES.GCM.SealedBox(combined: encrypted)
        let cleartext = try AES.GCM.open(box, using: key)
        return try JSONDecoder().decode(SharedImportPayload.self, from: cleartext)
    }
}

enum SharedImportStoreError: Error, LocalizedError, Sendable {
    case appGroupUnavailable
    case unsupportedFile
    case fileTooLarge
    case keychainFailure(OSStatus)
    case encryptionFailed
    case noPendingImport

    var errorDescription: String? {
        switch self {
        case .appGroupUnavailable: return "No se pudo acceder al contenedor seguro compartido."
        case .unsupportedFile: return "El elemento compartido no es una imagen o PDF compatible."
        case .fileTooLarge: return "El archivo compartido supera el límite seguro de 50 MB."
        case .keychainFailure: return "No se pudo acceder a la clave segura compartida."
        case .encryptionFailed: return "No se pudo proteger la importación compartida."
        case .noPendingImport: return "No hay importaciones compartidas pendientes."
        }
    }
}

enum SharedImportStore {
    nonisolated static let appGroupIdentifier = "group.com.romerodev.shield"
    nonisolated static let callbackURL = URL(string: "shield://import-shared")!
    nonisolated static let maximumBytes = 50 * 1_024 * 1_024

    private nonisolated static let keyService = "com.romerodev.shield.shared-import"
    private nonisolated static let keyAccount = "inbox-key-v1"
    // Keychain APIs receive runtime strings, so Xcode build-setting placeholders are
    // not expanded here. Keep this in sync with the Team ID used by both targets.
    private nonisolated static let keyAccessGroup = "L2B56644F5.com.romerodev.shield.shared"
    private nonisolated static let queueDirectoryName = "EncryptedImportInbox"
    private nonisolated static let temporaryDirectoryName = "ShieldSharedImports"

    nonisolated static func enqueue(data: Data, fileName: String, typeIdentifier: String) throws {
        guard !data.isEmpty else { throw SharedImportStoreError.unsupportedFile }
        guard data.count <= maximumBytes else { throw SharedImportStoreError.fileTooLarge }
        let safeName = sanitizedFileName(fileName, fallbackTypeIdentifier: typeIdentifier)
        let payload = SharedImportPayload(
            originalFileName: safeName,
            typeIdentifier: typeIdentifier,
            createdAt: Date(),
            data: data
        )
        let encrypted = try SharedImportCryptor.seal(payload, keyData: try sharedKey())
        let inbox = try inboxDirectory()
        let output = inbox.appendingPathComponent("\(UUID().uuidString).shieldshare")
        try encrypted.write(to: output, options: [.atomic, .completeFileProtection])
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: output.path
        )
    }

    nonisolated static func dequeueToTemporaryFile() throws -> URL {
        let inbox = try inboxDirectory()
        let candidates = try FileManager.default.contentsOfDirectory(
            at: inbox,
            includingPropertiesForKeys: [.creationDateKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        .filter { $0.pathExtension == "shieldshare" }
        .sorted { lhs, rhs in
            let left = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let right = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return left < right
        }
        guard let queuedURL = candidates.first else { throw SharedImportStoreError.noPendingImport }
        let encrypted = try Data(contentsOf: queuedURL, options: [.mappedIfSafe])
        let payload = try SharedImportCryptor.open(encrypted, keyData: try sharedKey())

        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(temporaryDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        let output = temporaryDirectory.appendingPathComponent(
            "\(UUID().uuidString)-\(sanitizedFileName(payload.originalFileName, fallbackTypeIdentifier: payload.typeIdentifier))"
        )
        try payload.data.write(to: output, options: [.atomic, .completeFileProtection])
        do {
            try FileManager.default.removeItem(at: queuedURL)
        } catch {
            try? FileManager.default.removeItem(at: output)
            throw error
        }
        return output
    }

    nonisolated static func removeTemporaryFile(_ url: URL) {
        guard isTemporaryImportURL(url) else { return }
        try? FileManager.default.removeItem(at: url)
    }

    nonisolated static func isTemporaryImportURL(_ url: URL) -> Bool {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(temporaryDirectoryName, isDirectory: true)
            .standardizedFileURL.path
        return url.standardizedFileURL.path.hasPrefix(root + "/")
    }

    nonisolated static func removeExpiredItems(olderThan age: TimeInterval = 24 * 60 * 60) {
        let cutoff = Date().addingTimeInterval(-age)
        for directory in [try? inboxDirectory(), FileManager.default.temporaryDirectory.appendingPathComponent(temporaryDirectoryName)] {
            guard let directory,
                  let files = try? FileManager.default.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: [.creationDateKey],
                    options: [.skipsHiddenFiles]
                  ) else { continue }
            for file in files {
                let created = (try? file.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                if created < cutoff { try? FileManager.default.removeItem(at: file) }
            }
        }
    }

    private nonisolated static func inboxDirectory() throws -> URL {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        ) else { throw SharedImportStoreError.appGroupUnavailable }
        let directory = container.appendingPathComponent(queueDirectoryName, isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        return directory
    }

    private nonisolated static func sanitizedFileName(
        _ proposed: String,
        fallbackTypeIdentifier: String
    ) -> String {
        let fallbackExtension = fallbackTypeIdentifier.contains("pdf") ? "pdf" : "jpg"
        let fallback = "Shared-Document.\(fallbackExtension)"
        let lastComponent = (proposed as NSString).lastPathComponent
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_. "))
        let filtered = lastComponent.unicodeScalars.filter { allowed.contains($0) }
        let value = String(String.UnicodeScalarView(filtered)).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? fallback : String(value.prefix(120))
    }

    private nonisolated static func sharedKey() throws -> Data {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keyService,
            kSecAttrAccount as String: keyAccount,
            kSecAttrAccessGroup as String: keyAccessGroup
        ]
        var readQuery = baseQuery
        readQuery[kSecReturnData as String] = true
        readQuery[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let readStatus = SecItemCopyMatching(readQuery as CFDictionary, &result)
        if readStatus == errSecSuccess, let data = result as? Data, data.count == 32 { return data }
        guard readStatus == errSecItemNotFound else {
            throw SharedImportStoreError.keychainFailure(readStatus)
        }

        let generated = Data((0..<32).map { _ in UInt8.random(in: .min ... .max) })
        var addQuery = baseQuery
        addQuery[kSecValueData as String] = generated
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        if addStatus == errSecSuccess { return generated }
        if addStatus == errSecDuplicateItem { return try sharedKey() }
        throw SharedImportStoreError.keychainFailure(addStatus)
    }
}
