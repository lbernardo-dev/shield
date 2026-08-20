import Foundation
import UIKit
import Testing
@testable import Shield

@Suite("Enhanced Capabilities & Architecture Tests")
struct EnhancementFeaturesTests {

    // MARK: - Redaction Presets Tests

    @Test("Redaction Presets configuration and masked entities")
    func redactionPresetsValidation() {
        for preset in RedactionPreset.allCases {
            #expect(!preset.title(lang: .es).isEmpty)
            #expect(!preset.title(lang: .en).isEmpty)
            #expect(!preset.subtitle(lang: .es).isEmpty)
            #expect(!preset.subtitle(lang: .en).isEmpty)
            #expect(!preset.defaultWatermarkText(lang: .es).isEmpty)
            #expect(!preset.defaultWatermarkText(lang: .en).isEmpty)
            #expect(!preset.icon.isEmpty)
            #expect(!preset.iconColorHex.isEmpty)
            #expect(!preset.maskedEntities.isEmpty)
            #expect(preset.maskedEntities.contains(.barcode))
        }

        #expect(RedactionPreset.rental.maskedEntities.contains(.supportNumber))
        #expect(RedactionPreset.rental.maskedEntities.contains(.address))
        #expect(RedactionPreset.employment.maskedEntities.contains(.dateOfBirth))
        #expect(RedactionPreset.banking.maskedEntities.contains(.paymentCard))
    }

    // MARK: - Barcode Detection Items Tests

    @Test("Barcode detection data model and risk classification")
    func barcodeItemRiskClassification() {
        let qrItem = BarcodeDetectionItem(symbology: "QR", payload: "https://example.com/id", normalizedRect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.2))
        #expect(qrItem.isHighRisk == true)

        let pdf417Item = BarcodeDetectionItem(symbology: "PDF417", payload: "DNI-RAW-DATA", normalizedRect: CGRect(x: 0.2, y: 0.5, width: 0.6, height: 0.2))
        #expect(pdf417Item.isHighRisk == true)

        let aztecItem = BarcodeDetectionItem(symbology: "Aztec", payload: "PASS-DATA", normalizedRect: CGRect(x: 0, y: 0, width: 0.1, height: 0.1))
        #expect(aztecItem.isHighRisk == true)

        let eanItem = BarcodeDetectionItem(symbology: "EAN13", payload: "8412345678901", normalizedRect: CGRect(x: 0, y: 0, width: 0.1, height: 0.1))
        #expect(eanItem.isHighRisk == false)
    }

    // MARK: - Thumbnail Manager Tests

    @Test("ThumbnailManager caching and clear operations")
    func thumbnailManagerLifecycle() async throws {
        let manager = ThumbnailManager.shared

        // Create a test image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 600))
        let testImage = renderer.image { ctx in
            UIColor.systemBlue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 800, height: 600))
        }

        // Save test image to sandbox
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagesDir = docs.appendingPathComponent("shield_images", isDirectory: true)
        try? fm.createDirectory(at: imagesDir, withIntermediateDirectories: true)

        let filename = "test_thumb_doc_\(UUID().uuidString).jpg"
        let fileURL = imagesDir.appendingPathComponent(filename)
        let data = testImage.jpegData(compressionQuality: 0.9)!
        try data.write(to: fileURL)

        // Generate thumbnail
        let thumb = await manager.thumbnail(for: filename, isVaulted: false, maxPixelSize: 200)
        #expect(thumb != nil)
        if let thumb {
            #expect(max(thumb.size.width, thumb.size.height) <= 201)
        }

        // Subsequent call hits memory/disk cache
        let cachedThumb = await manager.thumbnail(for: filename, isVaulted: false, maxPixelSize: 200)
        #expect(cachedThumb != nil)

        // Invalidate single file
        await manager.invalidate(filename: filename)

        // Clean up
        try? fm.removeItem(at: fileURL)
    }

    // MARK: - Granular DocumentStore Tests

    @Test("DocumentStore atomic persistence and operations")
    func documentStorePersistence() {
        let store = DocumentStore.shared

        let testDoc = DocumentItem(
            id: "test-doc-store-\(UUID().uuidString)",
            kind: .dniESP,
            title: "DNI Test Store",
            category: .identity,
            customCategoryID: nil,
            date: Date(),
            modifiedAt: Date(),
            redactionCount: 2,
            isFavorite: true,
            isLocked: false,
            isVaulted: false,
            imageFileName: "test_img.jpg",
            pageFileNames: nil,
            originalPageFileNames: nil,
            pageTransforms: [],
            sourceType: .image,
            sourceFileName: nil,
            fields: .empty,
            pageRedactions: [DocumentPageRedactions(pageIndex: 0, redactions: [Redaction(rect: CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.1), style: .block)])],
            watermark: nil,
            imageAdjustment: nil
        )

        // Save
        store.saveDocument(testDoc)

        // Load all
        let allDocs = store.loadAllDocuments()
        let loaded = allDocs.first { $0.id == testDoc.id }
        #expect(loaded != nil)
        #expect(loaded?.title == "DNI Test Store")
        #expect(loaded?.isFavorite == true)
        #expect(loaded?.pageRedactions.first?.redactions.count == 1)

        // Delete
        store.deleteDocument(id: testDoc.id)
        let afterDelete = store.loadAllDocuments()
        #expect(afterDelete.contains { $0.id == testDoc.id } == false)
    }
}
