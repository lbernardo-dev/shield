import Foundation
import UIKit
import Testing
@testable import Shield

@Suite("Enhanced Capabilities & Architecture Tests")
struct EnhancementFeaturesTests {

    @Test("Image-backed identity documents render their scanned page")
    func imageBackedIdentityDocumentsUseRasterSource() {
        #expect(DocumentRenderingSource.resolve(imageFileName: "dni-front.jpg") == .rasterImage("dni-front.jpg"))
        #expect(DocumentRenderingSource.resolve(imageFileName: nil) == .vectorTemplate)
        #expect(DocumentRenderingSource.resolve(imageFileName: "") == .vectorTemplate)

        let legacyCoordinates = RedactionReviewGate.fingerprint(pageTransforms: [], imageAdjustment: nil)
        let rasterCoordinates = RedactionReviewGate.fingerprint(
            pageTransforms: [],
            imageAdjustment: nil,
            rasterBackedTypedDocument: true
        )
        #expect(legacyCoordinates != rasterCoordinates)

        let legacyTypedDocument = DocumentItem(kind: .dniESP, title: "Legacy scan", imageFileName: "dni.jpg")
        #expect(legacyTypedDocument.usesRasterBackedTypedDocumentCoordinates)
        let vectorTemplate = DocumentItem(kind: .dniESP, title: "Template only")
        #expect(!vectorTemplate.usesRasterBackedTypedDocumentCoordinates)
    }

    @Test("Legacy typed scan masks require review after raster rendering is enabled")
    @MainActor
    func legacyTypedScanMasksAreQueuedForReview() {
        let transforms = [DocumentPageTransform.identity]
        let legacyFingerprint = RedactionReviewGate.fingerprint(
            pageTransforms: transforms,
            imageAdjustment: nil
        )
        let legacyDocument = DocumentItem(
            kind: .dniESP,
            title: "Previously templated scan",
            imageFileName: "legacy-dni.jpg",
            pageTransforms: transforms,
            redactionGeometryReviewedFingerprint: legacyFingerprint
        )
        let legacyViewModel = EditorViewModel(doc: legacyDocument)
        #expect(legacyViewModel.doc.batchReviewPendingPageIndices == [0])
        #expect(legacyViewModel.doc.redactionGeometryReviewPendingFingerprint == RedactionReviewGate.fingerprint(
            pageTransforms: transforms,
            imageAdjustment: nil,
            rasterBackedTypedDocument: true
        ))

        let rasterFingerprint = RedactionReviewGate.fingerprint(
            pageTransforms: transforms,
            imageAdjustment: nil,
            rasterBackedTypedDocument: true
        )
        let newDocument = DocumentItem(
            kind: .dniESP,
            title: "New raster scan",
            imageFileName: "new-dni.jpg",
            pageTransforms: transforms,
            redactionGeometryReviewedFingerprint: rasterFingerprint
        )
        let newViewModel = EditorViewModel(doc: newDocument)
        #expect(newViewModel.doc.batchReviewPendingPageIndices.isEmpty)
    }

    @Test("Spanish DNI preview header labels fit without colliding")
    @MainActor
    func spanishDNIHeaderLabelsStayInTheirColumns() {
        let cardWidth: CGFloat = 1_000
        let cardHeight: CGFloat = 625
        let title = "REINO DE ESPAÑA"
        let subtitle = "DOCUMENTO NACIONAL DE IDENTIDAD"
        let titleFontSize = DocumentHeaderTypography.fittedPointSize(
            for: title,
            baseSize: cardHeight * 0.065,
            maximumWidth: cardWidth * 0.39,
            weight: .black
        )
        let subtitleFontSize = DocumentHeaderTypography.fittedPointSize(
            for: subtitle,
            baseSize: cardHeight * 0.045,
            maximumWidth: cardWidth * 0.45,
            weight: .bold
        )
        let titleWidth = (title as NSString).size(withAttributes: [
            .font: UIFont.systemFont(ofSize: titleFontSize, weight: .black)
        ]).width
        let subtitleWidth = (subtitle as NSString).size(withAttributes: [
            .font: UIFont.systemFont(ofSize: subtitleFontSize, weight: .bold)
        ]).width
        let titleEndX = cardWidth * 0.05 + titleWidth
        let subtitleStartX = cardWidth * 0.97 - subtitleWidth

        #expect(titleEndX <= cardWidth * 0.44)
        #expect(subtitleStartX >= cardWidth * 0.52)
        #expect(titleEndX < subtitleStartX)
    }

    @Test("Vector document suggestions cover complete sensitive values")
    func vectorSuggestionsCoverSensitiveValues() {
        let fixtures: [(DocumentKind, [CGRect])] = [
            (.dniESP, [
                CGRect(x: 0.30, y: 0.82, width: 0.29, height: 0.052),
                CGRect(x: 0.62, y: 0.68, width: 0.33, height: 0.052)
            ]),
            (.passportUSA, [
                CGRect(x: 0.62, y: 0.256, width: 0.23, height: 0.042),
                CGRect(x: 0.28, y: 0.776, width: 0.28, height: 0.042)
            ]),
            (.passportMEX, [
                CGRect(x: 0.28, y: 0.636, width: 0.25, height: 0.040),
                CGRect(x: 0.28, y: 0.756, width: 0.24, height: 0.040)
            ]),
            (.dniITA, [
                CGRect(x: 0.38, y: 0.626, width: 0.24, height: 0.038),
                CGRect(x: 0.38, y: 0.746, width: 0.36, height: 0.038)
            ]),
            (.drivingUK, [
                CGRect(x: 0.36, y: 0.518, width: 0.23, height: 0.036),
                CGRect(x: 0.36, y: 0.758, width: 0.35, height: 0.036),
                CGRect(x: 0.36, y: 0.878, width: 0.56, height: 0.036)
            ]),
            (.genericID, [
                CGRect(x: 0.30, y: 0.626, width: 0.26, height: 0.040),
                CGRect(x: 0.30, y: 0.746, width: 0.27, height: 0.040)
            ])
        ]

        for (kind, sensitiveValues) in fixtures {
            let masks = AutoRedactions.suggested(for: kind).map(\.rect)
            for valueRect in sensitiveValues {
                #expect(masks.contains { $0.insetBy(dx: -0.002, dy: -0.002).contains(valueRect) })
            }
        }
    }

    @Test("OCR template fallbacks map each action to the matching field")
    func ocrTemplateFallbacksMapFieldsSemantically() {
        let fixtures: [(DocumentKind, [String])] = [
            (.dniESP, ["docNum", "name", "dob", "expires", "nat"]),
            (.passportUSA, ["docNum", "name", "dob", "expires", "nat"]),
            (.drivingUK, ["docNum", "name", "dob", "expires", "addr"]),
            (.passportMEX, ["docNum", "name", "dob", "expires", "nat"]),
            (.dniITA, ["docNum", "name", "dob", "expires", "nat"]),
            (.genericID, ["docNum", "name", "dob", "expires", "nat"])
        ]

        for (kind, fieldKeys) in fixtures {
            for fieldKey in fieldKeys {
                guard let rect = DocumentFieldBoxes.fallbackRect(for: fieldKey, kind: kind) else {
                    Issue.record("Missing \(fieldKey) fallback for \(kind.rawValue)")
                    continue
                }
                #expect(rect.minX >= 0 && rect.minY >= 0)
                #expect(rect.maxX <= 1 && rect.maxY <= 1)
            }
        }

        let spanishDocumentNumber = DocumentFieldBoxes.fallbackRect(for: "docNum", kind: .dniESP)
        let spanishName = DocumentFieldBoxes.fallbackRect(for: "name", kind: .dniESP)
        #expect((spanishDocumentNumber?.minY ?? 0) > 0.7)
        #expect((spanishName?.maxY ?? 1) < 0.61)
        #expect(DocumentFieldBoxes.fallbackRect(for: "addr", kind: .passportUSA) == nil)
        #expect(DocumentFieldBoxes.fallbackRect(for: "docNum", kind: .photo) == nil)
    }

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

    @Test("Custom protection profiles persist a real entity policy")
    func customProtectionProfilePolicy() throws {
        var profile = CustomProtectionProfile.privacyFirst
        profile.name = "Rental copy"
        profile.setMasked(false, kind: .address)
        profile.setMasked(true, kind: .fullName)
        profile.maskStyleRawValue = MaskStyle.blockWhite.rawValue
        profile.appliesWatermark = true
        profile.watermarkText = "For rental verification only"
        profile.preferredOutputFormatRawValue = ProtectionProfileOutputFormat.image.rawValue

        #expect(!profile.maskedEntities.contains(.address))
        #expect(profile.maskedEntities.contains(.fullName))
        let decoded = try JSONDecoder().decode(
            CustomProtectionProfile.self,
            from: JSONEncoder().encode(profile)
        )
        #expect(decoded == profile)
        #expect(decoded.maskStyle == .blockWhite)
        #expect(decoded.shouldApplyWatermark)
        #expect(decoded.preferredOutputFormat == .image)
    }

    @Test("New custom protection profiles start from the privacy-first policy")
    func newProtectionProfileStartsPrivacyFirst() {
        let profile = CustomProtectionProfile.newProfile(name: "Rental")
        #expect(profile.name == "Rental")
        #expect(profile.maskedEntities == CustomProtectionProfile.privacyFirst.maskedEntities)
        #expect(!profile.maskedEntities.isEmpty)
    }

    @Test("Local search indexes OCR content but excludes vaulted content")
    func localSearchPrivacyBoundary() {
        var fields = DocumentFields.empty
        fields.ocrFullText = "Ignored legacy full text"
        fields.ocrPageTexts = [
            "Ana García · IBAN ES91 2100 0418 4502 0005 1332",
            "PASSPORT REF #AB-123"
        ]
        fields.ocrPageEvidence = nil
        let document = DocumentItem(
            kind: .photo,
            title: "Lease",
            pageFileNames: ["page-1.jpg", "page-2.jpg"],
            fields: fields
        )

        #expect(document.matchesLocalSearch("García"))
        #expect(document.matchesLocalSearch("garcia"))
        #expect(document.matchesLocalSearch("ES9121000418450200051332"))
        #expect(document.matchesLocalSearch("Ignored legacy full text"))
        #expect(document.matchingOCRPageIndices(for: "García") == [0])
        #expect(document.matchingOCRPageIndices(for: "passport; García") == [0, 1])
        #expect(document.matchingOCRPageIndices(for: "AB123") == [1])
        #expect(!document.matchesLocalSearch("visa"))

        var vaulted = document
        vaulted.isVaulted = true
        #expect(!vaulted.matchesLocalSearch("García"))
    }

    @Test("Geometry edits require page review while visual filters do not")
    func redactionGeometryReviewGate() {
        let baseline = ImageAdjustmentStore(
            brightness: 0,
            contrast: 1,
            saturation: 1,
            sharpness: 0,
            rotation: 0,
            flipHorizontal: false,
            flipVertical: false,
            cropLeft: 0,
            cropRight: 0,
            cropTop: 0,
            cropBottom: 0
        )
        var visualOnly = baseline
        visualOnly.brightness = 0.2
        var cropped = baseline
        cropped.cropLeft = 0.1

        #expect(!RedactionReviewGate.requiresReview(from: baseline, to: visualOnly))
        #expect(RedactionReviewGate.requiresReview(from: baseline, to: cropped))
        #expect(RedactionReviewGate.requiresReview(from: nil, to: cropped))
        #expect(!RedactionReviewGate.requiresReview(from: nil, to: nil))
    }

    @Test("Editor canvas aspect follows crop and rotation geometry")
    func canvasAspectTracksImageGeometry() {
        var adjustment = ImageAdjustmentStore(
            brightness: 0,
            contrast: 1,
            saturation: 1,
            sharpness: 0,
            rotation: 0,
            flipHorizontal: false,
            flipVertical: false,
            cropLeft: 0.25,
            cropRight: 0,
            cropTop: 0,
            cropBottom: 0
        )

        #expect(abs(DocumentCoordinateTransform.adjustedAspect(2, using: adjustment) - 1.5) < 0.001)
        adjustment.rotation = 90
        #expect(abs(DocumentCoordinateTransform.adjustedAspect(2, using: adjustment) - CGFloat(1 / 1.5)) < 0.001)
    }

    @Test("Editor geometry edits block export until every page is reviewed")
    func editorGeometryEditQueuesAllPagesForReview() {
        let document = DocumentItem(
            kind: .photo,
            title: "Two-page scan",
            pageFileNames: ["page-1.jpg", "page-2.jpg"]
        )
        let viewModel = EditorViewModel(doc: document)
        var adjustment = viewModel.imageAdjustment
        adjustment.rotation = 90
        viewModel.updateAdjustment(adjustment)

        #expect(viewModel.batchReviewPendingPageIndices == [0, 1])
        #expect(viewModel.documentSnapshot.imageAdjustment?.rotation == 90)

        viewModel.markCurrentBatchPageReviewed()
        #expect(viewModel.batchReviewPendingPageIndices == [1])

        let resumedViewModel = EditorViewModel(doc: viewModel.documentSnapshot)
        #expect(resumedViewModel.batchReviewPendingPageIndices == [1])
    }

    @Test("Legacy documents with edited geometry enter the review queue")
    func legacyGeometryRequiresReview() {
        let adjustment = ImageAdjustmentStore(
            brightness: 0,
            contrast: 1,
            saturation: 1,
            sharpness: 0,
            rotation: 90,
            flipHorizontal: false,
            flipVertical: false,
            cropLeft: 0,
            cropRight: 0,
            cropTop: 0,
            cropBottom: 0
        )
        let document = DocumentItem(
            kind: .photo,
            title: "Legacy rotated scan",
            pageFileNames: ["page-1.jpg", "page-2.jpg"],
            imageAdjustment: adjustment
        )
        let viewModel = EditorViewModel(doc: document)

        #expect(viewModel.batchReviewPendingPageIndices == [0, 1])
        #expect(viewModel.needsGeometryReviewPersistence)
    }

    @Test("Page geometry changes require review across the entire document")
    func redactionReviewCoversAllPages() {
        let baseline = [DocumentPageTransform.identity, DocumentPageTransform.identity]
        var changed = baseline
        changed[1].perspectiveSkew = 0.12
        var filterOnly = baseline
        filterOnly[0].filterPreset = "grayscale"

        #expect(RedactionReviewGate.requiresReview(from: baseline, to: changed))
        #expect(!RedactionReviewGate.requiresReview(from: baseline, to: filterOnly))
        #expect(
            RedactionReviewGate.fingerprint(pageTransforms: baseline, imageAdjustment: nil) ==
                RedactionReviewGate.fingerprint(pageTransforms: filterOnly, imageAdjustment: nil)
        )
        #expect(RedactionReviewGate.pendingPageIndices(existing: [1, 8, -1], pageCount: 3) == [0, 1, 2])
        #expect(RedactionReviewGate.pendingPageIndices(existing: [1], pageCount: 0).isEmpty)
    }

    @Test("Geometry edits invalidate face suggestions from the previous image layout")
    func geometryEditInvalidatesFaceSuggestionCoordinates() {
        let suggestion = OCRFaceSuggestion(
            pageIndex: 0,
            boundingRect: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3),
            confidence: 0.9
        )
        var fields = DocumentFields.empty
        fields.ocrFaceSuggestions = [suggestion]
        fields.ocrFaceSuggestionsRevision = OCRService.faceSuggestionRevision
        fields.ocrDismissedFaceSuggestionIDs = [suggestion.id]
        fields.ocrPageTexts = ["Stale OCR text"]
        fields.ocrFullText = "Stale OCR text"
        let document = DocumentItem(
            kind: .photo,
            title: "Face review",
            pageFileNames: ["face-review.jpg"],
            fields: fields
        )
        let viewModel = EditorViewModel(doc: document)
        var adjustment = viewModel.imageAdjustment
        adjustment.cropLeft = 0.1

        viewModel.updateAdjustment(adjustment)

        #expect(viewModel.doc.fields.ocrFaceSuggestions == nil)
        #expect(viewModel.doc.fields.ocrFaceSuggestionsRevision == nil)
        #expect(viewModel.doc.fields.ocrDismissedFaceSuggestionIDs == nil)
        #expect(viewModel.doc.fields.ocrPageTexts == nil)
        #expect(viewModel.doc.fields.ocrFullText == nil)
        #expect(!viewModel.doc.matchesLocalSearch("Stale OCR text"))
        #expect(viewModel.batchReviewPendingPageIndices == [0])
    }

    @Test("Dismissing a face suggestion records its identifier for persistence")
    func dismissingFaceSuggestionRecordsDismissal() {
        let suggestion = OCRFaceSuggestion(
            pageIndex: 0,
            boundingRect: CGRect(x: 0.25, y: 0.25, width: 0.2, height: 0.2),
            confidence: 0.9
        )
        var fields = DocumentFields.empty
        fields.ocrFaceSuggestions = [suggestion]
        fields.ocrFaceSuggestionsRevision = OCRService.faceSuggestionRevision
        let document = DocumentItem(
            kind: .photo,
            title: "Face review",
            pageFileNames: ["face-review.jpg"],
            fields: fields
        )
        let viewModel = EditorViewModel(doc: document)

        viewModel.dismissFaceSuggestion(suggestion)

        #expect(viewModel.doc.fields.ocrDismissedFaceSuggestionIDs == [suggestion.id])
        #expect(viewModel.currentPageFaceSuggestions.isEmpty)
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

    @Test("Automatic mode applies scheduled themes to Free and Pro by local calendar")
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
                selection: .base,
                at: SeasonalThemeClock(now: date(2026, 10, 15, 12, 0, timeZone: newYork), timeZone: newYork)
            ) == .halloween2026
        )
        #expect(
            SeasonalThemeResolver.resolve(
                isPro: true,
                selection: .automatic,
                at: SeasonalThemeClock(now: date(2026, 10, 15, 12, 0, timeZone: newYork), timeZone: newYork)
            ) == .halloween2026
        )
        #expect(
            SeasonalThemeResolver.resolve(
                isPro: true,
                selection: .automatic,
                at: SeasonalThemeClock(now: date(2026, 11, 1, 0, 0, timeZone: tokyo), timeZone: tokyo)
            ) == .base
        )
    }

    @Test("A new installation defaults to automatic and follows an active event")
    @MainActor
    func seasonalThemeNewInstallDefaultsToAutomatic() {
        let suiteName = "SeasonalThemeNewInstall-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let coordinator = SeasonalThemeCoordinator(userDefaults: defaults)
        #expect(coordinator.selection == .automatic)

        let madrid = timeZone("Europe/Madrid")
        coordinator.refresh(
            now: date(2026, 10, 25, 12, 0, timeZone: madrid),
            timeZone: madrid,
            isPro: false
        )
        #expect(coordinator.activeThemeID == .halloween2026)
        #expect(coordinator.activeScheduledThemeID == .halloween2026)
        #expect(!coordinator.select(.base))
        #expect(coordinator.activeThemeID == .halloween2026)
    }

    @Test("An explicit Base opt-out waits for current entitlement before syncing the icon")
    @MainActor
    func seasonalThemeBaseOptOutWaitsForEntitlementResolution() {
        let suiteName = "SeasonalThemeBaseEntitlement-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(try! JSONEncoder().encode(SeasonalThemeSelection.base), forKey: "shield.theme.selection")

        let madrid = timeZone("Europe/Madrid")
        let clock = date(2026, 10, 25, 12, 0, timeZone: madrid)
        let coordinator = SeasonalThemeCoordinator(userDefaults: defaults)
        coordinator.refresh(now: clock, timeZone: madrid, isPro: false, hasResolvedEntitlement: false)

        #expect(coordinator.activeThemeID == .halloween2026)
        #expect(coordinator.shouldDeferSeasonalIconUntilEntitlementResolves)

        coordinator.refresh(now: clock, timeZone: madrid, isPro: true, hasResolvedEntitlement: true)
        #expect(coordinator.activeThemeID == .base)
        #expect(!coordinator.shouldDeferSeasonalIconUntilEntitlementResolves)

        let freeCoordinator = SeasonalThemeCoordinator(userDefaults: defaults)
        freeCoordinator.refresh(now: clock, timeZone: madrid, isPro: false, hasResolvedEntitlement: true)
        #expect(freeCoordinator.activeThemeID == .halloween2026)
        #expect(!freeCoordinator.shouldDeferSeasonalIconUntilEntitlementResolves)

        let afterEvent = date(2026, 11, 2, 12, 0, timeZone: madrid)
        let unresolvedAfterEvent = SeasonalThemeCoordinator(userDefaults: defaults)
        unresolvedAfterEvent.refresh(
            now: afterEvent,
            timeZone: madrid,
            isPro: false,
            hasResolvedEntitlement: false
        )
        #expect(unresolvedAfterEvent.activeThemeID == .base)
        #expect(!unresolvedAfterEvent.shouldDeferSeasonalIconUntilEntitlementResolves)
    }

    @Test("Only a deliberate Pro Base choice suppresses an active event")
    @MainActor
    func seasonalThemeBaseOptOutRequiresPremiumAndPersists() {
        let suiteName = "SeasonalThemeExplicitBase-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let madrid = timeZone("Europe/Madrid")
        let clock = date(2026, 10, 25, 12, 0, timeZone: madrid)
        let proCoordinator = SeasonalThemeCoordinator(userDefaults: defaults)
        proCoordinator.refresh(
            now: clock,
            timeZone: madrid,
            isPro: true
        )

        #expect(proCoordinator.selection == .automatic)
        #expect(proCoordinator.activeThemeID == .halloween2026)
        #expect(proCoordinator.select(.base))
        #expect(proCoordinator.activeThemeID == .base)

        let restoredProCoordinator = SeasonalThemeCoordinator(userDefaults: defaults)
        restoredProCoordinator.refresh(
            now: clock,
            timeZone: madrid,
            isPro: true
        )
        #expect(restoredProCoordinator.selection == .base)
        #expect(restoredProCoordinator.activeThemeID == .base)

        restoredProCoordinator.refresh(
            now: clock,
            timeZone: madrid,
            isPro: false
        )
        #expect(restoredProCoordinator.activeThemeID == .halloween2026)
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

        let madrid = timeZone("Europe/Madrid")
        let outsideEvent = date(2026, 8, 1, 12, 0, timeZone: madrid)

        let coordinator = SeasonalThemeCoordinator(userDefaults: defaults)
        coordinator.refresh(now: outsideEvent, timeZone: madrid, isPro: false)
        coordinator.setDebugPreviewTheme(.halloween2026)

        #expect(coordinator.debugPreviewThemeID == .halloween2026)
        #expect(coordinator.activeThemeID == .halloween2026)

        coordinator.setDebugPreviewTheme(nil)
        coordinator.refresh(now: outsideEvent, timeZone: madrid, isPro: false)

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
