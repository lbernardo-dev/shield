import Foundation
import Testing
@testable import Shield

@Suite("Encrypted Share Extension inbox")
struct SharedImportStoreTests {
    @Test("Shared payload encrypts metadata and content and round-trips")
    func encryptedPayloadRoundTrip() throws {
        let sensitive = Data("ES12 3456 7890 1234 5678 9012".utf8)
        let payload = SharedImportPayload(
            originalFileName: "Nomina-Ana-Garcia.pdf",
            typeIdentifier: "com.adobe.pdf",
            createdAt: Date(timeIntervalSince1970: 1234),
            data: sensitive
        )
        let key = Data(repeating: 0xA5, count: 32)
        let encrypted = try SharedImportCryptor.seal(payload, keyData: key)

        #expect(encrypted != sensitive)
        #expect(encrypted.range(of: sensitive) == nil)
        #expect(encrypted.range(of: Data(payload.originalFileName.utf8)) == nil)
        #expect(try SharedImportCryptor.open(encrypted, keyData: key) == payload)
    }

    @Test("Tampering is rejected")
    func tamperingFailsAuthentication() throws {
        let payload = SharedImportPayload(
            originalFileName: "document.jpg",
            typeIdentifier: "public.image",
            createdAt: .now,
            data: Data([1, 2, 3, 4])
        )
        let key = Data(repeating: 0x5A, count: 32)
        var encrypted = try SharedImportCryptor.seal(payload, keyData: key)
        encrypted[encrypted.index(before: encrypted.endIndex)] ^= 0xFF

        #expect(throws: (any Error).self) {
            _ = try SharedImportCryptor.open(encrypted, keyData: key)
        }
    }
}
