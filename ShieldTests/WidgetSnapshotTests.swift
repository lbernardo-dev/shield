import Foundation
import Testing
@testable import Shield

@Suite("Widget privacy boundary")
struct WidgetSnapshotTests {
    @Test("Snapshot round-trips aggregate metrics and plan access")
    func snapshotRoundTrip() throws {
        let snapshot = ShieldWidgetSnapshot(
            totalDocuments: 12,
            documentsWithRedactions: 9,
            vaultedDocuments: 3,
            watermarkedDocuments: 4,
            hasPremiumAccess: true
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(ShieldWidgetSnapshot.self, from: data)

        #expect(decoded == snapshot)
        #expect(decoded.totalDocuments == 12)
        #expect(decoded.documentsWithRedactions == 9)
        #expect(decoded.vaultedDocuments == 3)
        #expect(decoded.watermarkedDocuments == 4)
        #expect(decoded.hasPremiumAccess)
    }

    @Test("Snapshot decodes legacy v1 payloads seamlessly")
    func legacySnapshotDecoding() throws {
        // The widget previously stored this metric as "protectedDocuments".
        let legacyJSON = """
        {
            "totalDocuments": 10,
            "protectedDocuments": 8,
            "securityScore": 80,
            "vaultedDocuments": 2
        }
        """
        let data = legacyJSON.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ShieldWidgetSnapshot.self, from: data)

        #expect(decoded.totalDocuments == 10)
        #expect(decoded.documentsWithRedactions == 8)
        #expect(decoded.vaultedDocuments == 2)
        #expect(decoded.watermarkedDocuments == 0)
        #expect(!decoded.hasPremiumAccess)
        let currentJSON = String(decoding: try JSONEncoder().encode(decoded), as: UTF8.self)
        #expect(currentJSON.contains("documentsWithRedactions"))
        #expect(!currentJSON.contains("securityScore"))
    }

    @Test("Snapshot cannot carry document content")
    func snapshotDoesNotContainSensitiveDocumentFields() throws {
        let snapshot = ShieldWidgetSnapshot(
            totalDocuments: 1,
            documentsWithRedactions: 1,
            vaultedDocuments: 1,
            watermarkedDocuments: 1
        )
        let encoded = try JSONEncoder().encode(snapshot)
        let json = String(decoding: encoded, as: UTF8.self)

        #expect(!json.contains("title"))
        #expect(!json.contains("ocr"))
        #expect(!json.contains("image"))
        #expect(!json.contains("filename"))
    }

    @Test("Negative aggregate values are clamped")
    func snapshotClampsNegativeValues() {
        let snapshot = ShieldWidgetSnapshot(
            totalDocuments: -1,
            documentsWithRedactions: -2,
            vaultedDocuments: -3,
            watermarkedDocuments: -4
        )

        #expect(snapshot.totalDocuments == 0)
        #expect(snapshot.documentsWithRedactions == 0)
        #expect(snapshot.vaultedDocuments == 0)
        #expect(snapshot.watermarkedDocuments == 0)
    }

    @Test("Document subset counts cannot exceed the library total")
    func subsetCountsDoNotExceedTotal() {
        let snapshot = ShieldWidgetSnapshot(
            totalDocuments: 2,
            documentsWithRedactions: 5,
            vaultedDocuments: 3,
            watermarkedDocuments: 4
        )

        #expect(snapshot.documentsWithRedactions == 2)
        #expect(snapshot.vaultedDocuments == 2)
        #expect(snapshot.watermarkedDocuments == 2)
    }
}
