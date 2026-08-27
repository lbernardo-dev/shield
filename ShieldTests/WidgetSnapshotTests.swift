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
            generatedAt: generatedAt
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(ShieldWidgetSnapshot.self, from: data)

        #expect(decoded == snapshot)
        #expect(decoded.totalDocuments == 12)
        #expect(decoded.protectedDocuments == 9)
        #expect(decoded.vaultedDocuments == 3)
    }

    @Test("Snapshot cannot carry document content")
    func snapshotDoesNotContainSensitiveDocumentFields() throws {
        let snapshot = ShieldWidgetSnapshot(totalDocuments: 1, protectedDocuments: 1, vaultedDocuments: 1)
        let encoded = try JSONEncoder().encode(snapshot)
        let json = String(decoding: encoded, as: UTF8.self)

        #expect(!json.contains("title"))
        #expect(!json.contains("ocr"))
        #expect(!json.contains("image"))
        #expect(!json.contains("filename"))
    }

    @Test("Negative aggregate values are clamped")
    func snapshotClampsNegativeValues() {
        let snapshot = ShieldWidgetSnapshot(totalDocuments: -1, protectedDocuments: -2, vaultedDocuments: -3)

        #expect(snapshot.totalDocuments == 0)
        #expect(snapshot.protectedDocuments == 0)
        #expect(snapshot.vaultedDocuments == 0)
    }
}
