import Foundation
import Testing
@testable import Shield

@Suite("Widget privacy boundary")
struct WidgetSnapshotTests {
    @Test("Snapshot round-trips only aggregate protection metrics")
    func snapshotRoundTrip() throws {
        let generatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = ShieldWidgetSnapshot(
            totalDocuments: 12,
            protectedDocuments: 9,
            vaultedDocuments: 3,
            watermarkedDocuments: 4,
            securityScore: 75,
            lastProtectedDate: generatedAt,
            generatedAt: generatedAt
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(ShieldWidgetSnapshot.self, from: data)

        #expect(decoded == snapshot)
        #expect(decoded.totalDocuments == 12)
        #expect(decoded.protectedDocuments == 9)
        #expect(decoded.vaultedDocuments == 3)
        #expect(decoded.watermarkedDocuments == 4)
        #expect(decoded.securityScore == 75)
        #expect(decoded.lastProtectedDate == generatedAt)
    }

    @Test("Snapshot decodes legacy v1 payloads seamlessly")
    func legacySnapshotDecoding() throws {
        // Old payload missing watermarkedDocuments, securityScore, and lastProtectedDate
        let legacyJSON = """
        {
            "totalDocuments": 10,
            "protectedDocuments": 8,
            "vaultedDocuments": 2,
            "generatedAt": 1700000000
        }
        """
        let data = legacyJSON.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ShieldWidgetSnapshot.self, from: data)

        #expect(decoded.totalDocuments == 10)
        #expect(decoded.protectedDocuments == 8)
        #expect(decoded.vaultedDocuments == 2)
        #expect(decoded.watermarkedDocuments == 0)
        #expect(decoded.securityScore == 80) // 8/10 = 80%
        #expect(decoded.lastProtectedDate == nil)
    }

    @Test("Snapshot cannot carry document content")
    func snapshotDoesNotContainSensitiveDocumentFields() throws {
        let snapshot = ShieldWidgetSnapshot(
            totalDocuments: 1,
            protectedDocuments: 1,
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
            protectedDocuments: -2,
            vaultedDocuments: -3,
            watermarkedDocuments: -4,
            securityScore: -10
        )

        #expect(snapshot.totalDocuments == 0)
        #expect(snapshot.protectedDocuments == 0)
        #expect(snapshot.vaultedDocuments == 0)
        #expect(snapshot.watermarkedDocuments == 0)
        #expect(snapshot.securityScore == 0)
    }
}
