import Foundation
import CloudKit
import CryptoKit
import Testing
@testable import Shield

@Suite("Security and privacy", .serialized)
struct SecurityPrivacyTests {
    @Test("A missing CloudKit record type is recognized without exposing an internal error")
    @MainActor
    func missingCloudKitRecordType() {
        let error = CKError(.unknownItem)
        #expect(CloudSyncManager.isMissingRecordTypeError(error))
        #expect(!CloudSyncManager.isMissingRecordTypeError(CKError(.networkUnavailable)))
    }

    @Test("Secure storage encrypts at rest and separates vault keys")
    func encryptedStorageUsesSeparateKeyDomains() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("shield-security-\(UUID().uuidString)", isDirectory: true)
        let libraryURL = root
            .appendingPathComponent("images", isDirectory: true)
            .appendingPathComponent("fixture.bin")
        let vaultURL = root
            .appendingPathComponent("vault-images", isDirectory: true)
            .appendingPathComponent("fixture.bin")
        defer { try? FileManager.default.removeItem(at: root) }

        let plaintext = Data("sensitive-personal-data-123456".utf8)
        try FileManager.default.createDirectory(
            at: libraryURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try SecureFileStore.shared.write(plaintext, to: libraryURL)
        try SecureFileStore.shared.copyFile(from: libraryURL, to: vaultURL)

        let libraryCiphertext = try Data(contentsOf: libraryURL)
        let vaultCiphertext = try Data(contentsOf: vaultURL)
        #expect(libraryCiphertext != plaintext)
        #expect(vaultCiphertext != plaintext)
        #expect(!libraryCiphertext.range(of: plaintext).isSome)
        #expect(!vaultCiphertext.range(of: plaintext).isSome)
        #expect(try SecureFileStore.shared.read(from: libraryURL) == plaintext)
        #expect(try SecureFileStore.shared.read(from: vaultURL) == plaintext)

        let storedLibraryKey = try KeychainStore.read(
            service: "com.romerodev.shield.secure-store",
            account: "master-key"
        )
        let libraryKey = try #require(storedLibraryKey)
        let storedVaultKey = try KeychainStore.read(
            service: "com.romerodev.shield.secure-store",
            account: "vault-master-key"
        )
        let vaultKey = try #require(storedVaultKey)
        #expect(libraryKey.count == 32)
        #expect(vaultKey.count == 32)
        #expect(libraryKey != vaultKey)

        SecureFileStore.shared.removeFile(at: libraryURL)
        SecureFileStore.shared.removeFile(at: vaultURL)
        #expect(!FileManager.default.fileExists(atPath: libraryURL.path))
        #expect(!FileManager.default.fileExists(atPath: vaultURL.path))
    }

    @Test("PIN credentials are salted, verified and cleared")
    func pinLifecycle() throws {
        PINManager.clear()
        defer { PINManager.clear() }

        PINManager.save(pin: "482951")
        #expect(PINManager.hasPIN)
        #expect(PINManager.verify(pin: "482951"))
        #expect(!PINManager.verify(pin: "482950"))

        let storedCredential = try KeychainStore.read(
            service: "com.romerodev.shield.vault",
            account: "vault-pin"
        )
        let stored = try #require(storedCredential)
        #expect(stored != Data("482951".utf8))
        #expect(stored != Data(SHA256.hash(data: Data("482951".utf8))))

        PINManager.clear()
        #expect(!PINManager.hasPIN)
    }

    @Test("Feedback mail URL preserves recipient and safely encodes localized content")
    func feedbackURLIsValid() throws {
        let url = try #require(SettingsSupportConfiguration.feedbackURL(
            recipient: "romerodev.app+shield@gmail.com",
            subject: "Comentarios sobre Shield & privacidad",
            body: "Describe aquí qué ocurrió.\nGracias."
        ))
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))

        #expect(components.scheme == "mailto")
        #expect(components.path == "romerodev.app+shield@gmail.com")
        #expect(components.queryItems?.first(where: { $0.name == "subject" })?.value == "Comentarios sobre Shield & privacidad")
        #expect(components.queryItems?.first(where: { $0.name == "body" })?.value == "Describe aquí qué ocurrió.\nGracias.")
    }

    @Test("Review cadence is quieter for Premium users")
    func premiumReviewCadenceIsQuieter() {
        #expect(AppReviewPolicy.premium.minimumAppAge > AppReviewPolicy.free.minimumAppAge)
        #expect(AppReviewPolicy.premium.valueThreshold > AppReviewPolicy.free.valueThreshold)
        #expect(AppReviewPolicy.premium.cooldown > AppReviewPolicy.free.cooldown)
        #expect(AppReviewPolicy.premium.annualRequestLimit < AppReviewPolicy.free.annualRequestLimit)
    }
}

private extension Optional {
    var isSome: Bool { self != nil }
}
