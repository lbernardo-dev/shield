import Foundation
import Testing
@testable import Shield

@Suite("Document schema migration")
struct DocumentMigrationTests {
    @Test("Current documents preserve immutable originals and page transforms")
    func currentSchemaRoundTrip() throws {
        let transform = DocumentPageTransform(
            filterPreset: "blackWhite",
            rotationDegrees: 90,
            cropLeft: 0.1,
            contrast: 1.25
        )
        let modifiedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let geometryFingerprint = RedactionReviewGate.fingerprint(
            pageTransforms: [transform],
            imageAdjustment: nil
        )
        let original = DocumentItem(
            kind: .photo,
            title: "Fixture",
            modifiedAt: modifiedAt,
            imageFileName: "rendered.jpg",
            originalPageFileNames: ["original.jpg"],
            pageTransforms: [transform],
            batchReviewPendingPageIndices: [2, 1, 2],
            batchSuggestionPageIndices: [1],
            redactionGeometryReviewedFingerprint: geometryFingerprint,
            redactionGeometryReviewPendingFingerprint: geometryFingerprint
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(DocumentItem.self, from: data)

        #expect(decoded.schemaVersion == DocumentItem.currentSchemaVersion)
        #expect(decoded.originalPageFileNames == ["original.jpg"])
        #expect(decoded.pageTransforms == [transform])
        #expect(decoded.batchReviewPendingPageIndices == [1, 2])
        #expect(decoded.batchSuggestionPageIndices == [1])
        #expect(decoded.redactionGeometryReviewedFingerprint == geometryFingerprint)
        #expect(decoded.redactionGeometryReviewPendingFingerprint == geometryFingerprint)
        #expect(decoded.modifiedAt == modifiedAt)
    }

    @Test("Legacy documents migrate without inventing an immutable original")
    func legacyMigration() throws {
        let current = DocumentItem(
            kind: .photo,
            title: "Legacy",
            imageFileName: "legacy.jpg"
        )
        let encoded = try JSONEncoder().encode(current)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "schemaVersion")
        object.removeValue(forKey: "originalPageFileNames")
        object.removeValue(forKey: "pageTransforms")
        object.removeValue(forKey: "modifiedAt")
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        var decoded = try JSONDecoder().decode(DocumentItem.self, from: legacyData)
        #expect(decoded.schemaVersion == 1)
        decoded.migrateToCurrentSchema()

        #expect(decoded.schemaVersion == DocumentItem.currentSchemaVersion)
        #expect(decoded.originalPageFileNames == nil)
        #expect(decoded.pageTransforms == [.identity])
        #expect(decoded.modifiedAt == decoded.date)
    }

    @Test("Schema 4 keeps immutable originals while adding geometry review metadata")
    func schemaFourMigrationPreservesOriginals() {
        var document = DocumentItem(
            kind: .photo,
            title: "Schema four",
            imageFileName: "rendered.jpg",
            originalPageFileNames: ["source.jpg"],
            pageTransforms: [.identity]
        )
        document.schemaVersion = 4

        document.migrateToCurrentSchema()

        #expect(document.schemaVersion == DocumentItem.currentSchemaVersion)
        #expect(document.originalPageFileNames == ["source.jpg"])
    }
}
