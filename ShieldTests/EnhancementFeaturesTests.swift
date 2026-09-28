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
            if preset == .custom {
                #expect(preset.maskedEntities.isEmpty)
            } else {
                #expect(!preset.maskedEntities.isEmpty)
                #expect(preset.maskedEntities.contains(.barcode))
            }
        }

        #expect(RedactionPreset.rental.maskedEntities.contains(.supportNumber))
        #expect(RedactionPreset.rental.maskedEntities.contains(.address))
        #expect(RedactionPreset.employment.maskedEntities.contains(.dateOfBirth))
        #expect(RedactionPreset.banking.maskedEntities.contains(.paymentCard))
        #expect(RedactionPreset.marketplace.maskedEntities.contains(.email))
        #expect(RedactionPreset.travel.maskedEntities.contains(.mrz))
        #expect(RedactionPreset.school.maskedEntities.contains(.dateOfBirth))
        #expect(RedactionPreset.insurance.maskedEntities.contains(.iban))
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

    // MARK: - Seasonal themes

    @Test("Seasonal themes resolve against each device's local calendar")
    func seasonalThemeLocalCalendarResolution() {
        let madrid = timeZone("Europe/Madrid")
        let newYork = timeZone("America/New_York")
        let tokyo = timeZone("Asia/Tokyo")

        #expect(
            SeasonalThemeResolver.resolve(
                isPro: false,
                selection: .automatic,
                at: SeasonalThemeClock(now: date(2026, 10, 1, 0, 0, timeZone: madrid), timeZone: madrid)
            ) == .halloween2026
        )
        #expect(
            SeasonalThemeResolver.resolve(
                isPro: false,
                selection: .automatic,
                at: SeasonalThemeClock(now: date(2026, 10, 15, 12, 0, timeZone: newYork), timeZone: newYork)
            ) == .halloween2026
        )
        #expect(
            SeasonalThemeResolver.resolve(
                isPro: false,
                selection: .automatic,
                at: SeasonalThemeClock(now: date(2026, 11, 1, 0, 0, timeZone: tokyo), timeZone: tokyo)
            ) == .base
        )
    }

    @Test("Pro manual selection takes precedence over the seasonal window")
    func seasonalThemePremiumPrecedence() {
        let madrid = timeZone("Europe/Madrid")
        let outsideEvent = SeasonalThemeClock(
            now: date(2026, 12, 12, 12, 0, timeZone: madrid),
            timeZone: madrid
        )

        #expect(
            SeasonalThemeResolver.resolve(
                isPro: true,
                selection: .manual(.halloween2026),
                at: outsideEvent
            ) == .halloween2026
        )
        #expect(
            SeasonalThemeResolver.resolve(
                isPro: false,
                selection: .manual(.halloween2026),
                at: outsideEvent
            ) == .base
        )
        #expect(
            SeasonalThemeResolver.resolve(
                isPro: true,
                selection: .base,
                at: SeasonalThemeClock(now: date(2026, 10, 15, 12, 0, timeZone: madrid), timeZone: madrid)
            ) == .base
        )
    }

    @Test("Future themes remain previewable but cannot become active early")
    func seasonalThemeFutureActivationIsBlocked() {
        let madrid = timeZone("Europe/Madrid")
        let beforeStart = SeasonalThemeClock(
            now: date(2026, 9, 30, 23, 59, timeZone: madrid),
            timeZone: madrid
        )

        #expect(
            SeasonalThemeResolver.resolve(
                isPro: true,
                selection: .manual(.halloween2026),
                at: beforeStart
            ) == .base
        )
        #expect(
            SeasonalThemeResolver.canManuallyActivate(
                isPro: true,
                themeID: .halloween2026,
                at: beforeStart
            ) == false
        )
        #expect(
            SeasonalThemeResolver.canManuallyActivate(
                isPro: true,
                themeID: .halloween2026,
                at: SeasonalThemeClock(
                    now: date(2026, 10, 1, 0, 0, timeZone: madrid),
                    timeZone: madrid
                )
            ) == true
        )
    }

    @Test("Event detail keeps the IANA editorial reference separate from local resolution")
    func seasonalThemeEventTimeZoneMetadata() {
        let definition = SeasonalThemeCatalog.definition(for: .halloween2026)
        #expect(definition?.schedule?.policy == .deviceLocalCalendar)
        #expect(definition?.schedule?.referenceTimeZoneIdentifier == "Europe/Madrid")
        #expect(definition?.eventDetailArtworkAssetName == "SeasonalThemeEventArtwork")
    }

    @Test("Pro users can always select the standard theme")
    func premiumUsersCanSelectStandardTheme() {
        let madrid = timeZone("Europe/Madrid")
        let clock = SeasonalThemeClock(now: date(2026, 10, 15, 12, 0, timeZone: madrid), timeZone: madrid)
        #expect(SeasonalThemeResolver.canManuallyActivate(isPro: true, themeID: .base, at: clock))
        #expect(!SeasonalThemeResolver.canManuallyActivate(isPro: false, themeID: .base, at: clock))
    }

    @Test("Seasonal schedules remain valid around daylight saving transitions")
    func seasonalThemeDSTSchedule() {
        let schedule = SeasonalThemeSchedule(
            calendarIdentifier: "gregorian",
            start: DateComponents(year: 2026, month: 3, day: 8, hour: 2, minute: 30),
            end: DateComponents(year: 2026, month: 3, day: 9, hour: 2, minute: 30),
            policy: .fixedTimeZone("America/New_York"),
            referenceTimeZoneIdentifier: nil
        )
        let clock = SeasonalThemeClock(
            now: date(2026, 3, 8, 12, 0, timeZone: timeZone("America/New_York")),
            timeZone: timeZone("Europe/Madrid")
        )

        let bounds = schedule.bounds(using: clock)
        #expect(bounds != nil)
        if let bounds {
            #expect(bounds.end > bounds.start)
        }
    }

#if DEBUG
#if targetEnvironment(simulator)
    @Test("Free simulator preview can override and restore the effective theme")
    func seasonalThemeSimulatorPreviewOverride() {
        let suiteName = "shield.theme.preview-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let coordinator = SeasonalThemeCoordinator(userDefaults: defaults)
        coordinator.refresh(isPro: false)
        coordinator.setDebugPreviewTheme(.halloween2026)

        #expect(coordinator.debugPreviewThemeID == .halloween2026)
        #expect(coordinator.activeThemeID == .halloween2026)

        coordinator.setDebugPreviewTheme(nil)

        #expect(coordinator.debugPreviewThemeID == nil)
        #expect(coordinator.activeThemeID == .base)
    }
#endif
#endif

    private func timeZone(_ identifier: String) -> TimeZone {
        TimeZone(identifier: identifier)!
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, timeZone: TimeZone) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
