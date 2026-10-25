import SwiftUI
import Combine

// MARK: - EditorTool

enum EditorTool: String, CaseIterable, Identifiable {
    case rect
    case pan
    case fields
    case auto
    case text
    case watermark
    case adjust   // image adjustment (brightness, contrast, rotation, crop, flip)

    var id: String { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .rect:      return LanguageManager.shared.t("editor_tool_rect", table: "Editor", language: lang)
        case .pan:       return LanguageManager.shared.t("editor_tool_pan", table: "Editor", language: lang)
        case .fields:    return LanguageManager.shared.t("editor_tool_fields", table: "Editor", language: lang)
        case .auto:      return LanguageManager.shared.t("editor_tool_auto", table: "Editor", language: lang)
        case .text:      return LanguageManager.shared.t("editor_tool_text", table: "Editor", language: lang)
        case .watermark: return LanguageManager.shared.t("editor_tool_watermark", table: "Editor", language: lang)
        case .adjust:    return LanguageManager.shared.t("editor_tool_adjust", table: "Editor", language: lang)
        }
    }

    var icon: String {
        switch self {
        case .rect:      return "rectangle.dashed"
        case .pan:       return "hand.raised.fill"
        case .fields:    return "sparkles"
        case .auto:      return "checkmark.shield"
        case .text:      return "text.alignleft"
        case .watermark: return "drop.halffull"
        case .adjust:    return "slider.horizontal.3"
        }
    }

    var requiresPro: Bool {
        switch self {
        case .watermark, .adjust: true
        default: false
        }
    }

    var premiumFeature: PremiumFeature? {
        switch self {
        case .watermark: .customWatermarks
        case .adjust: .advancedAdjustments
        default: nil
        }
    }
}

// MARK: - ImageAdjustment

struct ImageAdjustment: Equatable {
    var brightness: Double = 0       // -1...1
    var contrast: Double = 1.0       // 0.5...2.0
    var saturation: Double = 1.0     // 0...2
    var sharpness: Double = 0        // 0...1
    var rotation: Double = 0         // 0, 90, 180, 270
    var flipHorizontal: Bool = false
    var flipVertical: Bool = false
    var cropLeft: Double = 0
    var cropRight: Double = 0
    var cropTop: Double = 0
    var cropBottom: Double = 0

    var isDefault: Bool {
        brightness == 0 && abs(contrast - 1.0) < 0.001 &&
        abs(saturation - 1.0) < 0.001 && sharpness == 0 &&
        rotation == 0 && !flipHorizontal && !flipVertical &&
        cropLeft == 0 && cropRight == 0 && cropTop == 0 && cropBottom == 0
    }

    static let `default` = ImageAdjustment()
}

// MARK: - EditorViewModel

final class EditorViewModel: ObservableObject {
    @Published private(set) var doc: DocumentItem
    private var baselineDoc: DocumentItem
    private var ocrBootstrapTask: Task<Void, Never>? = nil
    private var ocrBootstrapRequestID: UUID?
    private var faceBootstrapTask: Task<Void, Never>? = nil

    @Published var tool: EditorTool = .rect
    @Published var maskStyle: MaskStyle = .block
    @Published var preferredExportFormat: ProtectionProfileOutputFormat?
    @Published var redactions: [Redaction] = []
    @Published var activeRedactionID: UUID? = nil
    @Published var watermark: Watermark? = nil
    @Published var showSensitiveBanner: Bool = false
    @Published var showFieldOverlays: Bool = false
    @Published var showOCRSheet: Bool = false
    @Published var showExportSheet: Bool = false
    @Published var showAdjustPanel: Bool = false
    @Published var currentPage: Int = 0
    @Published var activeMode: RedactionMode? = nil
    @Published var imageAdjustment: ImageAdjustment = .default
    @Published var isDraggingRedaction: Bool = false
    @Published var isResizingRedaction: Bool = false
    @Published var isAnalyzingOCRSuggestions: Bool = false
    @Published var isPeekingOriginal: Bool = false
    @Published var showPresetPicker: Bool = false
    @Published private(set) var needsGeometryReviewPersistence = false

    var pageCount: Int { doc.pageCount }
    var currentImageFileName: String? { doc.imageFileName(for: currentPage) }
    var batchReviewPendingPageIndices: [Int] { doc.batchReviewPendingPageIndices }
    var currentPageFaceSuggestions: [OCRFaceSuggestion] {
        guard doc.fields.ocrFaceSuggestionsRevision == OCRService.faceSuggestionRevision else { return [] }
        let dismissed = Set(doc.fields.ocrDismissedFaceSuggestionIDs ?? [])
        return (doc.fields.ocrFaceSuggestions ?? [])
            .filter { $0.pageIndex == currentPage && !dismissed.contains($0.id) }
            .sorted { $0.boundingRect.minX < $1.boundingRect.minX }
    }
    var currentPageUnresolvedFaceSuggestions: [OCRFaceSuggestion] {
        currentPageFaceSuggestions.filter { !isFaceSuggestionProtected($0) }
    }
    var suggestedRedactionCount: Int { Self.suggestedRectsForBanner(in: doc).count }
    var hasUnsavedChanges: Bool { normalizedSignature(for: doc) != normalizedSignature(for: baselineDoc) }
    var changeCount: Int {
        guard hasUnsavedChanges else { return 0 }

        let baselineMap = Dictionary(uniqueKeysWithValues: baselineDoc.pageRedactions.map { ($0.pageIndex, $0.redactions) })
        let currentMap = Dictionary(uniqueKeysWithValues: doc.pageRedactions.map { ($0.pageIndex, $0.redactions) })
        let allPages = Set(baselineMap.keys).union(currentMap.keys)
        let changedPages = allPages.reduce(0) { partial, page in
            (baselineMap[page] ?? []) == (currentMap[page] ?? []) ? partial : (partial + 1)
        }
        let watermarkChanged = watermarkSignature(baselineDoc.watermark) == watermarkSignature(doc.watermark) ? 0 : 1
        let adjustmentChanged = baselineDoc.imageAdjustment == doc.imageAdjustment ? 0 : 1
        return max(1, changedPages + watermarkChanged + adjustmentChanged)
    }
    var allPageRedactions: [Int: [Redaction]] {
        Dictionary(uniqueKeysWithValues: doc.pageRedactions.map { ($0.pageIndex, $0.redactions) })
    }
    var documentSnapshot: DocumentItem {
        persistCurrentPageState()
        return doc
    }

    func goToPage(_ page: Int) {
        guard page >= 0, page < pageCount else { return }
        persistCurrentPageState()
        currentPage = page
        redactions = doc.redactions(for: page)
        activeRedactionID = nil
        self.history = [EditorHistorySnapshot(
            redactions: self.redactions,
            imageAdjustment: self.imageAdjustment,
            watermark: self.watermark
        )]
        self.historyIdx = 0
    }

    func markCurrentBatchPageReviewed() {
        guard doc.batchReviewPendingPageIndices.contains(currentPage) else { return }
        doc.batchReviewPendingPageIndices.removeAll { $0 == currentPage }
        if doc.batchReviewPendingPageIndices.isEmpty {
            doc.batchSuggestionPageIndices = []
            doc.redactionGeometryReviewedFingerprint = currentRedactionGeometryFingerprint
            doc.redactionGeometryReviewPendingFingerprint = nil
            // This aggregate event contains only the number of reviewed pages;
            // AppState sends product analytics only after explicit opt-in.
            AppState.trackEvent("batch_document_review_completed", properties: [
                "pages": String(doc.pageCount)
            ])
        }
        needsGeometryReviewPersistence = true
    }

    func isFaceSuggestionProtected(_ suggestion: OCRFaceSuggestion) -> Bool {
        let protectedRect = OCRService.protectiveFaceMaskRect(
            around: suggestion.boundingRect,
            rollDegrees: suggestion.rollDegrees
        )
        return redactions.contains { redaction in
            let overlap = redaction.rect.intersection(protectedRect)
            guard !overlap.isNull, !overlap.isEmpty else { return false }
            let maskArea = protectedRect.width * protectedRect.height
            guard maskArea > 0 else { return false }
            return overlap.width * overlap.height / maskArea >= 0.9
        }
    }

    func acceptFaceSuggestion(_ suggestion: OCRFaceSuggestion) {
        guard suggestion.pageIndex == currentPage,
              !isFaceSuggestionProtected(suggestion) else { return }
        push(redactions + [Redaction(
            rect: OCRService.protectiveFaceMaskRect(
                around: suggestion.boundingRect,
                rollDegrees: suggestion.rollDegrees
            ),
            style: .block
        )])
        AppState.trackEvent("face_redaction_suggestion_accepted", properties: [
            "page": String(currentPage),
            "confidence": String(format: "%.2f", suggestion.confidence)
        ])
    }

    func dismissFaceSuggestion(_ suggestion: OCRFaceSuggestion) {
        guard suggestion.pageIndex == currentPage else { return }
        var dismissed = Set(doc.fields.ocrDismissedFaceSuggestionIDs ?? [])
        dismissed.insert(suggestion.id)
        doc.fields.ocrDismissedFaceSuggestionIDs = dismissed.sorted { $0.uuidString < $1.uuidString }
    }

    // Drawing state
    @Published var drawingStart: CGPoint? = nil
    @Published var drawingCurrent: CGPoint? = nil

    // Undo/redo
    struct EditorHistorySnapshot: Equatable {
        var redactions: [Redaction]
        var imageAdjustment: ImageAdjustment
        var watermark: Watermark?

        static func == (lhs: EditorHistorySnapshot, rhs: EditorHistorySnapshot) -> Bool {
            guard lhs.redactions == rhs.redactions,
                  lhs.imageAdjustment == rhs.imageAdjustment else { return false }
            switch (lhs.watermark, rhs.watermark) {
            case (nil, nil): return true
            case let (l?, r?):
                return l.text == r.text && l.opacity == r.opacity && l.isRepeating == r.isRepeating
            default: return false
            }
        }
    }

    private var history: [EditorHistorySnapshot] = []
    private var historyIdx: Int = 0
    private var redactionTransformBaseline: [Redaction]? = nil

    var canUndo: Bool { historyIdx > 0 }
    var canRedo: Bool { historyIdx < history.count - 1 }

    init(doc: DocumentItem) {
        self.doc = doc
        self.baselineDoc = doc
        let currentGeometryFingerprint = RedactionReviewGate.fingerprint(
            pageTransforms: doc.pageTransforms,
            imageAdjustment: doc.imageAdjustment,
            rasterBackedTypedDocument: doc.usesRasterBackedTypedDocumentCoordinates
        )
        let reviewedGeometryFingerprint = doc.redactionGeometryReviewedFingerprint
            ?? RedactionReviewGate.identityFingerprint
        let hasPendingQueueForCurrentGeometry =
            doc.redactionGeometryReviewPendingFingerprint == currentGeometryFingerprint &&
            !doc.batchReviewPendingPageIndices.isEmpty
        let geometryNeedsReview = currentGeometryFingerprint != reviewedGeometryFingerprint
        let pendingQueueGeometryChanged = doc.redactionGeometryReviewPendingFingerprint != nil &&
            doc.redactionGeometryReviewPendingFingerprint != currentGeometryFingerprint
        if (geometryNeedsReview && !hasPendingQueueForCurrentGeometry) || pendingQueueGeometryChanged {
            let pendingPages = RedactionReviewGate.pendingPageIndices(
                existing: doc.batchReviewPendingPageIndices,
                pageCount: doc.pageCount
            )
            if pendingPages != doc.batchReviewPendingPageIndices ||
                doc.redactionGeometryReviewPendingFingerprint != currentGeometryFingerprint {
                self.doc.batchReviewPendingPageIndices = pendingPages
                self.doc.redactionGeometryReviewPendingFingerprint = currentGeometryFingerprint
                self.needsGeometryReviewPersistence = true
            }
        }
        self.redactions = doc.redactions(for: 0)
        self.watermark = doc.watermark
        if let stored = doc.imageAdjustment {
            self.imageAdjustment = ImageAdjustment(
                brightness: stored.brightness,
                contrast: stored.contrast,
                saturation: stored.saturation,
                sharpness: stored.sharpness,
                rotation: stored.rotation,
                flipHorizontal: stored.flipHorizontal,
                flipVertical: stored.flipVertical,
                cropLeft: stored.cropLeft,
                cropRight: stored.cropRight,
                cropTop: stored.cropTop,
                cropBottom: stored.cropBottom
            )
        }
        self.history = [EditorHistorySnapshot(
            redactions: self.redactions,
            imageAdjustment: self.imageAdjustment,
            watermark: self.watermark
        )]
        self.historyIdx = 0
        let suggestions = Self.suggestedRectsForBanner(in: doc)
        let hasOCRFields = doc.kind == .photo || doc.kind == .genericID
            ? !doc.fields.documentNumber.isEmpty || !doc.fields.fullName.isEmpty
            : false
        self.showSensitiveBanner = !suggestions.isEmpty || hasOCRFields
        if showSensitiveBanner {
            AppState.trackEvent("risk_detected", properties: [
                "kind": doc.kind.rawValue,
                "count": String(suggestions.count)
            ])
        }
    }

    // MARK: - History

    func commitCurrentStateToHistory() {
        let currentSnap = EditorHistorySnapshot(
            redactions: redactions,
            imageAdjustment: imageAdjustment,
            watermark: watermark
        )
        guard history.isEmpty || history[historyIdx] != currentSnap else { return }
        history = Array(history.prefix(historyIdx + 1))
        history.append(currentSnap)
        historyIdx = history.count - 1
        persistCurrentPageState()
    }

    private func push(_ next: [Redaction]) {
        redactions = next
        commitCurrentStateToHistory()
    }

    func undo() {
        guard canUndo else { return }
        historyIdx -= 1
        let snap = history[historyIdx]
        let geometryChanged = requirePageReviewIfGeometryChanged(from: imageAdjustment, to: snap.imageAdjustment)
        redactions = snap.redactions
        imageAdjustment = snap.imageAdjustment
        watermark = snap.watermark
        persistCurrentPageState()
        if geometryChanged {
            bootstrapOCRSuggestionsIfNeeded()
            bootstrapFaceSuggestionsIfNeeded()
        }
    }

    func redo() {
        guard canRedo else { return }
        historyIdx += 1
        let snap = history[historyIdx]
        let geometryChanged = requirePageReviewIfGeometryChanged(from: imageAdjustment, to: snap.imageAdjustment)
        redactions = snap.redactions
        imageAdjustment = snap.imageAdjustment
        watermark = snap.watermark
        persistCurrentPageState()
        if geometryChanged {
            bootstrapOCRSuggestionsIfNeeded()
            bootstrapFaceSuggestionsIfNeeded()
        }
    }

    // MARK: - Drawing

    func beginDraw(at point: CGPoint) {
        guard tool == .rect else { return }
        drawingStart = point
        drawingCurrent = point
    }

    func updateDraw(to point: CGPoint) {
        guard drawingStart != nil else { return }
        drawingCurrent = point
    }

    func endDraw() {
        guard let start = drawingStart, let current = drawingCurrent else { return }
        drawingStart = nil
        drawingCurrent = nil

        let x = min(start.x, current.x)
        let y = min(start.y, current.y)
        let w = abs(current.x - start.x)
        let h = abs(current.y - start.y)
        guard w > 0.01 && h > 0.01 else { return }

        let r = Redaction(rect: CGRect(x: x, y: y, width: w, height: h), style: maskStyle)
        push(redactions + [r])
        AppState.trackEvent("redaction_applied", properties: ["source": "manual_draw"])
    }

    var drawingRect: CGRect? {
        guard let start = drawingStart, let current = drawingCurrent else { return nil }
        return CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
    }

    // MARK: - Redaction ops

    func applyAutoDetect() {
        // For photo/genericID kinds, only apply rects that are backed by real OCR text.
        // Never fall through to the grid-based fallback, which would produce fake zones
        // on images that contain no actual text (e.g., a photo of a tree).
        if doc.kind == .photo || doc.kind == .genericID {
            let hasRealOCRText = Self.ocrHasRealText(in: doc)
            guard hasRealOCRText else {
                // No text found by Vision — nothing to redact automatically.
                showSensitiveBanner = false
                return
            }
            let preciseRects = AutoRedactions.ocrPrecisionModeRects(
                for: .banking,
                fields: currentPageOCRFields
            )
            guard !preciseRects.isEmpty else {
                showSensitiveBanner = false
                return
            }
            let suggested = preciseRects.map { Redaction(rect: $0, style: maskStyle) }
            push(suggested)
            AppState.trackEvent("redaction_applied", properties: [
                "source": "auto_detect",
                "count": String(suggested.count)
            ])
            showSensitiveBanner = false
            showFieldOverlays = false
            return
        }

        // Structured document kinds (DNI, passport, etc.) always have calibrated template zones.
        let suggestedRects = Self.suggestedRectsForBanner(in: doc)
        guard !suggestedRects.isEmpty else { return }
        let suggested = suggestedRects.map { Redaction(rect: $0, style: maskStyle) }
        push(suggested)
        AppState.trackEvent("redaction_applied", properties: [
            "source": "auto_detect",
            "count": String(suggested.count)
        ])
        showSensitiveBanner = false
        showFieldOverlays = false
    }

    @discardableResult
    func applyMode(_ mode: RedactionMode) -> Bool {
        guard PremiumManager.shared.canUseMode(mode) else {
            PremiumManager.recordFeatureGate(.professionalModes, trigger: .manual)
            return false
        }

        if activeMode == mode {
            push([])
            activeMode = nil
            return true
        }

        // For structured doc kinds, use the template-based approach
        if doc.kind != .photo && doc.kind != .genericID {
            var suggested = AutoRedactions.suggested(for: doc.kind, style: maskStyle)
            switch mode {
            case .rental:
                // Rental: hide photo + all PII except name
                suggested = suggested.filter { r in
                    r.rect.width >= 0.9 || r.rect.width <= 0.25 || r.rect.origin.y > 0.75
                }
            case .travel:
                // Travel: hide passport number and MRZ, keep name/photo
                suggested = suggested.filter { r in
                    r.rect.width >= 0.9 || (r.rect.origin.y > 0.55 && r.rect.width > 0.18)
                }
            case .job:
                // Job: hide DOB, address, doc number; keep name
                suggested = suggested.filter { r in
                    r.rect.origin.y > 0.58 && r.rect.origin.y < 0.86
                }
            case .verify:
                // Verify: only hide doc number + MRZ, show everything else
                suggested = suggested.filter { r in
                    r.rect.origin.y > 0.72 || r.rect.width >= 0.9
                }
            case .legal:
                // Legal: hide DOB, address, document number, signature area
                suggested = suggested.filter { r in
                    r.rect.origin.y > 0.52 && r.rect.origin.y < 0.92
                }
            case .health:
                // Health: hide DOB, nationality, document number, MRZ
                suggested = suggested.filter { r in
                    (r.rect.origin.y > 0.45 && r.rect.origin.y < 0.78) || r.rect.width >= 0.9
                }
            case .banking:
                // Banking: hide everything except name — maximally protective
                suggested = suggested.filter { r in
                    r.rect.origin.y > 0.38
                }
            }
            push(suggested)
        } else {
            // For photo/generic docs: ONLY use bounding-box-precise OCR rects.
            // NEVER fall back to the grid template — that generates fake zones on
            // images that contain no text at all (e.g. a photo of a tree or landscape).
            guard Self.ocrHasRealText(in: doc) else {
                // No real OCR text found — do nothing, do not mark the mode as active.
                return false
            }
            let modeRects = AutoRedactions.ocrPrecisionModeRects(
                for: mode,
                fields: currentPageOCRFields
            )
            guard !modeRects.isEmpty else {
                // OCR ran but this mode's required fields were not present in the image
                // (e.g. no DOB found for the job preset). Clear redactions and deselect mode.
                push([])
                activeMode = nil
                return false
            }
            let modeRedactions = modeRects.map { Redaction(rect: $0, style: maskStyle) }
            push(modeRedactions)
        }

        AppState.trackEvent("redaction_applied", properties: [
            "source": "mode",
            "mode": mode.rawValue
        ])
        activeMode = mode
        showSensitiveBanner = false
        return true
    }

    func applyPreset(_ preset: RedactionPreset, lang: AppLanguage) {
        let customProfile = preset == .custom ? ProtectionProfileStore.load() : nil
        let maskedEntities = customProfile?.maskedEntities ?? preset.maskedEntities
        let profileMaskStyle = customProfile?.maskStyle ?? maskStyle
        preferredExportFormat = customProfile?.preferredOutputFormat
        var newRedactions = redactions
        if let pageEvidence = doc.fields.ocrPageEvidence?.first(where: { $0.pageIndex == currentPage }) {
            let obsMap = Dictionary(uniqueKeysWithValues: pageEvidence.observations.map { ($0.id, $0) })
            for entity in pageEvidence.entities where maskedEntities.contains(entity.kind) {
                for evID in entity.evidenceIDs {
                    if let obs = obsMap[evID] {
                        let overlaps = newRedactions.contains { r in
                            r.rect.intersects(obs.boundingRect)
                        }
                        if !overlaps {
                            let redaction = Redaction(rect: obs.boundingRect, style: profileMaskStyle)
                            newRedactions.append(redaction)
                        }
                    }
                }
            }
        }

        if preset != .custom,
           newRedactions == redactions,
           doc.kind != .photo,
           doc.kind != .genericID {
            let suggested = AutoRedactions.suggested(for: doc.kind, style: profileMaskStyle)
            newRedactions = suggested
        }

        if newRedactions != redactions { push(newRedactions) }

        if customProfile?.shouldApplyWatermark ?? true {
            let configuredText = customProfile?.watermarkText?.trimmingCharacters(in: .whitespacesAndNewlines)
            let text = configuredText.flatMap { $0.isEmpty ? nil : $0 }
                ?? preset.defaultWatermarkText(lang: lang)
            setWatermark(Watermark(text: text, opacity: 0.28, isRepeating: true, colorHex: "000000"))
        } else if customProfile != nil {
            setWatermark(nil)
        }

        AppState.trackEvent("preset_applied", properties: [
            "preset": preset.rawValue
        ])
    }

    /// Whether Vision OCR found real identifiable text in this document.
    /// The UI can read this to show feedback when a preset has no data to act on.
    var ocrHasRealText: Bool { Self.ocrHasRealText(in: doc) }

    private var currentPageOCRFields: DocumentFields {
        var fields = doc.fields
        guard let page = fields.ocrPageEvidence?.first(where: { $0.pageIndex == currentPage }) else {
            return fields
        }
        fields.ocrBoundingTexts = page.observations.map(\.text)
        fields.ocrBoundingRects = page.observations.map(\.boundingRect)
        fields.ocrPageEvidence = [page]
        return fields
    }

    // MARK: - Image adjustment

    func updateAdjustment(_ adjustment: ImageAdjustment) {
        let nextAdjustment = sanitizedAdjustment(adjustment)
        let geometryChanged = requirePageReviewIfGeometryChanged(from: imageAdjustment, to: nextAdjustment)
        imageAdjustment = nextAdjustment
        persistCurrentPageState()
        if geometryChanged {
            bootstrapOCRSuggestionsIfNeeded()
            bootstrapFaceSuggestionsIfNeeded()
        }
    }

    func resetAdjustment() {
        let geometryChanged = requirePageReviewIfGeometryChanged(from: imageAdjustment, to: .default)
        imageAdjustment = .default
        commitCurrentStateToHistory()
        if geometryChanged {
            bootstrapOCRSuggestionsIfNeeded()
            bootstrapFaceSuggestionsIfNeeded()
        }
    }

    func rotateImage90CW() {
        var adj = imageAdjustment
        adj.rotation = ((adj.rotation + 90).truncatingRemainder(dividingBy: 360))
        let geometryChanged = requirePageReviewIfGeometryChanged(from: imageAdjustment, to: adj)
        imageAdjustment = adj
        commitCurrentStateToHistory()
        if geometryChanged {
            bootstrapOCRSuggestionsIfNeeded()
            bootstrapFaceSuggestionsIfNeeded()
        }
    }

    func flipImageHorizontal() {
        var adj = imageAdjustment
        adj.flipHorizontal.toggle()
        let geometryChanged = requirePageReviewIfGeometryChanged(from: imageAdjustment, to: adj)
        imageAdjustment = adj
        commitCurrentStateToHistory()
        if geometryChanged {
            bootstrapOCRSuggestionsIfNeeded()
            bootstrapFaceSuggestionsIfNeeded()
        }
    }

    func flipImageVertical() {
        var adj = imageAdjustment
        adj.flipVertical.toggle()
        let geometryChanged = requirePageReviewIfGeometryChanged(from: imageAdjustment, to: adj)
        imageAdjustment = adj
        commitCurrentStateToHistory()
        if geometryChanged {
            bootstrapOCRSuggestionsIfNeeded()
            bootstrapFaceSuggestionsIfNeeded()
        }
    }

    @discardableResult
    private func requirePageReviewIfGeometryChanged(from old: ImageAdjustment, to new: ImageAdjustment) -> Bool {
        guard RedactionReviewGate.requiresReview(
            from: storedAdjustment(for: old),
            to: storedAdjustment(for: new)
        ) else { return false }
        doc.batchReviewPendingPageIndices = RedactionReviewGate.pendingPageIndices(
            existing: doc.batchReviewPendingPageIndices,
            pageCount: pageCount
        )
        doc.redactionGeometryReviewPendingFingerprint = RedactionReviewGate.fingerprint(
            pageTransforms: doc.pageTransforms,
            imageAdjustment: storedAdjustment(for: new),
            rasterBackedTypedDocument: doc.usesRasterBackedTypedDocumentCoordinates
        )
        doc.fields.ocrPageEvidence = nil
        doc.fields.ocrPageTexts = nil
        doc.fields.ocrFullText = nil
        doc.fields.ocrBoundingTexts = nil
        doc.fields.ocrBoundingRects = nil
        doc.fields.ocrFaceSuggestions = nil
        doc.fields.ocrFaceSuggestionsRevision = nil
        doc.fields.ocrDismissedFaceSuggestionIDs = nil
        showSensitiveBanner = false
        ocrBootstrapTask?.cancel()
        ocrBootstrapRequestID = nil
        isAnalyzingOCRSuggestions = false
        faceBootstrapTask?.cancel()
        needsGeometryReviewPersistence = true
        return true
    }

    private var currentRedactionGeometryFingerprint: String {
        RedactionReviewGate.fingerprint(
            pageTransforms: doc.pageTransforms,
            imageAdjustment: storedAdjustment(for: imageAdjustment),
            rasterBackedTypedDocument: doc.usesRasterBackedTypedDocumentCoordinates
        )
    }

    private func storedAdjustment(for adjustment: ImageAdjustment) -> ImageAdjustmentStore? {
        guard !adjustment.isDefault else { return nil }
        return ImageAdjustmentStore(
            brightness: adjustment.brightness,
            contrast: adjustment.contrast,
            saturation: adjustment.saturation,
            sharpness: adjustment.sharpness,
            rotation: adjustment.rotation,
            flipHorizontal: adjustment.flipHorizontal,
            flipVertical: adjustment.flipVertical,
            cropLeft: adjustment.cropLeft,
            cropRight: adjustment.cropRight,
            cropTop: adjustment.cropTop,
            cropBottom: adjustment.cropBottom
        )
    }

    private func sanitizedAdjustment(_ adjustment: ImageAdjustment) -> ImageAdjustment {
        var sanitized = adjustment
        sanitized.cropLeft = max(0, min(0.45, sanitized.cropLeft))
        sanitized.cropRight = max(0, min(0.45, sanitized.cropRight))
        sanitized.cropTop = max(0, min(0.45, sanitized.cropTop))
        sanitized.cropBottom = max(0, min(0.45, sanitized.cropBottom))

        let horizontalCrop = sanitized.cropLeft + sanitized.cropRight
        if horizontalCrop > 0.9 {
            let scale = 0.9 / horizontalCrop
            sanitized.cropLeft *= scale
            sanitized.cropRight *= scale
        }

        let verticalCrop = sanitized.cropTop + sanitized.cropBottom
        if verticalCrop > 0.9 {
            let scale = 0.9 / verticalCrop
            sanitized.cropTop *= scale
            sanitized.cropBottom *= scale
        }

        return sanitized
    }

    // MARK: - Redaction drag & resize

    func beginRedactionTransform() {
        guard redactionTransformBaseline == nil else { return }
        redactionTransformBaseline = redactions
    }

    func commitRedactionTransform() {
        guard let baseline = redactionTransformBaseline else { return }
        redactionTransformBaseline = nil
        guard baseline != redactions else { return }
        commitCurrentStateToHistory()
    }

    func moveRedaction(id: UUID, by delta: CGSize, canvasSize: CGSize) {
        guard canvasSize.width > 0, canvasSize.height > 0 else { return }
        let dx = delta.width / canvasSize.width
        let dy = delta.height / canvasSize.height
        let updated = redactions.map { r -> Redaction in
            guard r.id == id else { return r }
            var moved = r
            let newX = max(0, min(1 - r.rect.width, r.rect.origin.x + dx))
            let newY = max(0, min(1 - r.rect.height, r.rect.origin.y + dy))
            moved.rect = CGRect(x: newX, y: newY, width: r.rect.width, height: r.rect.height)
            return moved
        }
        redactions = updated
    }

    func resizeRedaction(id: UUID, newRect: CGRect) {
        let safeRect = NormalizedDocumentGeometry.rect(newRect)
        let updated = redactions.map { r -> Redaction in
            guard r.id == id else { return r }
            var resized = r
            resized.rect = safeRect
            return resized
        }
        redactions = updated
    }

    func toggleField(_ box: FieldBox) {
        let existing = redactions.first { r in
            abs(r.rect.origin.x - box.rect.origin.x) < 0.01 &&
            abs(r.rect.origin.y - box.rect.origin.y) < 0.01
        }
        if let e = existing {
            push(redactions.filter { $0.id != e.id })
        } else {
            push(redactions + [Redaction(rect: box.rect, style: maskStyle)])
            AppState.trackEvent("redaction_applied", properties: ["source": "field_overlay"])
        }
    }

    func addRedaction(_ redaction: Redaction) {
        push(redactions + [redaction])
        AppState.trackEvent("redaction_applied", properties: ["source": "manual"])
    }

    func updateRedaction(_ redaction: Redaction) {
        push(redactions.map { $0.id == redaction.id ? redaction : $0 })
    }

    func removeRedaction(id: UUID) {
        push(redactions.filter { $0.id != id })
        activeRedactionID = nil
    }

    func changeStyle(of id: UUID, to style: MaskStyle) {
        push(redactions.map { r in
            guard r.id == id else { return r }
            var updated = r
            updated.style = style
            return updated
        })
    }

    func addFromOCR(rect: CGRect) {
        push(redactions + [Redaction(rect: rect, style: maskStyle)])
        AppState.trackEvent("redaction_applied", properties: ["source": "ocr_field"])
    }

    func removeOCRRedaction(rect: CGRect) {
        let threshold: CGFloat = 0.06
        let filtered = redactions.filter { r in
            abs(r.rect.midX - rect.midX) > threshold || abs(r.rect.midY - rect.midY) > threshold
        }
        if filtered.count != redactions.count {
            push(filtered)
        }
    }

    /// Persists OCR-extracted fields (including bounding boxes) into the document.
    /// Called after the OCR sheet finishes analysis so mode-based masking works.
    func updateOCRFields(_ fields: DocumentFields) {
        ocrBootstrapTask?.cancel()
        ocrBootstrapRequestID = nil
        isAnalyzingOCRSuggestions = false
        var snapshot = doc
        var updatedFields = fields
        if updatedFields.ocrFaceSuggestions == nil {
            updatedFields.ocrFaceSuggestions = doc.fields.ocrFaceSuggestions
        }
        if updatedFields.ocrDismissedFaceSuggestionIDs == nil {
            updatedFields.ocrDismissedFaceSuggestionIDs = doc.fields.ocrDismissedFaceSuggestionIDs
        }
        snapshot.fields = updatedFields
        doc = snapshot
        baselineDoc.fields = updatedFields
        // Show sensitive banner if OCR found any identifiable fields
        let hasFields = !fields.documentNumber.isEmpty || !fields.fullName.isEmpty
        if hasFields && !showSensitiveBanner {
            showSensitiveBanner = true
        }
    }

    /// Best-effort background OCR so the sensitive banner doesn't show 0 suggestions
    /// for photo/generic docs when fields are still empty.
    func bootstrapOCRSuggestionsIfNeeded() {
        guard doc.kind == .photo || doc.kind == .genericID else { return }
        guard !isAnalyzingOCRSuggestions else { return }
        let hasPageEvidence = !(doc.fields.ocrPageEvidence ?? []).isEmpty
        let hasBoxes = !(doc.fields.ocrBoundingTexts ?? []).isEmpty
        guard !hasPageEvidence && !hasBoxes else { return }
        let pageFileNames = doc.pageFileNames.flatMap { $0.isEmpty ? nil : $0 }
            ?? [doc.imageFileName].compactMap { $0 }
        guard !pageFileNames.isEmpty else { return }

        let documentID = doc.id
        let isVaulted = doc.isVaulted
        let adjustment = storedAdjustment(for: imageAdjustment)
        let geometryFingerprint = currentRedactionGeometryFingerprint
        let requestID = UUID()

        isAnalyzingOCRSuggestions = true
        ocrBootstrapTask?.cancel()
        ocrBootstrapRequestID = requestID
        ocrBootstrapTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: .milliseconds(350))
            } catch {
                await MainActor.run { self.finishOCRBootstrap(requestID: requestID) }
                return
            }

            var pageObs = Array(repeating: [OCRService.TextObservation](), count: pageFileNames.count)
            var loadedAtLeastOnePage = false
            for (pageIndex, fileName) in pageFileNames.enumerated() {
                guard !Task.isCancelled else {
                    await MainActor.run { self.finishOCRBootstrap(requestID: requestID) }
                    return
                }
                let stillCurrent = await MainActor.run {
                    self.doc.id == documentID &&
                    self.currentRedactionGeometryFingerprint == geometryFingerprint
                }
                guard stillCurrent else {
                    await MainActor.run { self.finishOCRBootstrap(requestID: requestID) }
                    return
                }
                guard let sourceImage = AppState.loadImage(fileName: fileName, isVaulted: isVaulted) else {
                    continue
                }
                loadedAtLeastOnePage = true
                let image = adjustment.flatMap {
                    ExportEngine.applyImageAdjustment(sourceImage, store: $0)
                } ?? sourceImage
                let pageResult = await OCRService.recognizeObservationsByPageAdaptive(in: [image])
                guard !Task.isCancelled else {
                    await MainActor.run { self.finishOCRBootstrap(requestID: requestID) }
                    return
                }
                pageObs[pageIndex] = pageResult.first ?? []
            }
            guard loadedAtLeastOnePage else {
                await MainActor.run { self.finishOCRBootstrap(requestID: requestID) }
                return
            }

            let pageLines = pageObs.map { $0.map(\.text) }
            let lines = pageLines.flatMap { $0 }
            let perPageFields = pageLines.map(OCRService.extractFields(from:))
            var fields = perPageFields.first ?? OCRService.extractFields(from: lines)
            fields.ocrPageEvidence = OCRService.buildPageEvidence(
                observations: pageObs,
                extractedFields: perPageFields
            )
            fields.ocrDocumentType = OCRService.detectDocumentType(from: lines).rawValue
            if let page0 = pageObs.first {
                fields.ocrBoundingTexts = page0.map(\.text)
                fields.ocrBoundingRects = page0.map(\.boundingRect)
            }

            let resolvedFields = fields
            await MainActor.run {
                guard self.ocrBootstrapRequestID == requestID,
                      !Task.isCancelled,
                      self.doc.id == documentID,
                      self.currentRedactionGeometryFingerprint == geometryFingerprint else {
                    self.finishOCRBootstrap(requestID: requestID)
                    return
                }
                var snapshot = self.doc
                var mergedFields = snapshot.fields
                mergedFields.documentNumber = mergedFields.documentNumber.isEmpty
                    ? resolvedFields.documentNumber
                    : mergedFields.documentNumber
                mergedFields.fullName = mergedFields.fullName.isEmpty ? resolvedFields.fullName : mergedFields.fullName
                mergedFields.dateOfBirth = mergedFields.dateOfBirth.isEmpty
                    ? resolvedFields.dateOfBirth
                    : mergedFields.dateOfBirth
                mergedFields.nationality = mergedFields.nationality.isEmpty
                    ? resolvedFields.nationality
                    : mergedFields.nationality
                mergedFields.expires = mergedFields.expires.isEmpty ? resolvedFields.expires : mergedFields.expires
                mergedFields.sex = mergedFields.sex.isEmpty ? resolvedFields.sex : mergedFields.sex
                mergedFields.address = mergedFields.address.isEmpty ? resolvedFields.address : mergedFields.address
                if mergedFields.supportNumber?.isEmpty != false { mergedFields.supportNumber = resolvedFields.supportNumber }
                if mergedFields.issued?.isEmpty != false { mergedFields.issued = resolvedFields.issued }
                if mergedFields.mrz?.isEmpty != false { mergedFields.mrz = resolvedFields.mrz }
                mergedFields.ocrPageEvidence = resolvedFields.ocrPageEvidence
                mergedFields.ocrBoundingTexts = resolvedFields.ocrBoundingTexts
                mergedFields.ocrBoundingRects = resolvedFields.ocrBoundingRects
                mergedFields.ocrPageTexts = resolvedFields.ocrPageTexts
                mergedFields.ocrFullText = resolvedFields.ocrFullText
                if mergedFields.ocrDocumentType == nil { mergedFields.ocrDocumentType = resolvedFields.ocrDocumentType }
                if mergedFields.ocrMRZValid == nil { mergedFields.ocrMRZValid = resolvedFields.ocrMRZValid }
                if mergedFields.ocrMRZFormat == nil { mergedFields.ocrMRZFormat = resolvedFields.ocrMRZFormat }
                if mergedFields.ocrFieldConfidence == nil { mergedFields.ocrFieldConfidence = resolvedFields.ocrFieldConfidence }
                if mergedFields.ocrDetectedCountry == nil { mergedFields.ocrDetectedCountry = resolvedFields.ocrDetectedCountry }
                if mergedFields.ocrRiskLevel == nil { mergedFields.ocrRiskLevel = resolvedFields.ocrRiskLevel }
                if mergedFields.ocrLowConfidenceFields == nil {
                    mergedFields.ocrLowConfidenceFields = resolvedFields.ocrLowConfidenceFields
                }
                snapshot.fields = mergedFields
                self.doc = snapshot
                // OCR bootstrap is automatic metadata enrichment, not a user edit.
                self.baselineDoc.fields = mergedFields

                // For photo/genericID: only show the banner when Vision actually found
                // identifiable field text (name, doc number, etc.).
                // An empty OCR result (e.g., a photo of a tree) must NOT trigger the banner.
                let hasIdentifiableFields = !mergedFields.documentNumber.isEmpty ||
                    !mergedFields.fullName.isEmpty
                let hasOCRBoundingRects = !(mergedFields.ocrBoundingTexts ?? []).isEmpty
                let hasSuggestedRects = !Self.suggestedRectsForBanner(in: snapshot).isEmpty

                if snapshot.kind == .photo || snapshot.kind == .genericID {
                    // Only show banner when real text-backed zones exist, not grid fallback.
                    self.showSensitiveBanner = hasIdentifiableFields && hasOCRBoundingRects && hasSuggestedRects
                } else {
                    self.showSensitiveBanner = hasSuggestedRects || hasIdentifiableFields
                }
                self.finishOCRBootstrap(requestID: requestID)
            }
        }
    }

    private func finishOCRBootstrap(requestID: UUID) {
        guard ocrBootstrapRequestID == requestID else { return }
        ocrBootstrapRequestID = nil
        isAnalyzingOCRSuggestions = false
    }

    func bootstrapFaceSuggestionsIfNeeded() {
        let pageFileNames = OCRService.faceSuggestionPageFileNames(for: doc)
        guard !pageFileNames.isEmpty else { return }
        guard doc.fields.ocrFaceSuggestions == nil ||
                doc.fields.ocrFaceSuggestionsRevision != OCRService.faceSuggestionRevision else { return }
        if doc.fields.ocrFaceSuggestionsRevision != OCRService.faceSuggestionRevision {
            doc.fields.ocrFaceSuggestions = nil
            doc.fields.ocrFaceSuggestionsRevision = nil
            doc.fields.ocrDismissedFaceSuggestionIDs = nil
            baselineDoc.fields.ocrFaceSuggestions = nil
            baselineDoc.fields.ocrFaceSuggestionsRevision = nil
            baselineDoc.fields.ocrDismissedFaceSuggestionIDs = nil
        }
        let documentID = doc.id
        let isVaulted = doc.isVaulted
        let adjustment = storedAdjustment(for: imageAdjustment)
        let geometryFingerprint = currentRedactionGeometryFingerprint

        faceBootstrapTask?.cancel()
        faceBootstrapTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            var candidates: [OCRFaceSuggestion] = []
            for (pageIndex, fileName) in pageFileNames.enumerated() {
                guard !Task.isCancelled else { return }
                let isCurrent = await MainActor.run {
                    self.doc.id == documentID &&
                    self.currentRedactionGeometryFingerprint == geometryFingerprint
                }
                guard isCurrent else { return }
                guard let sourceImage = await MainActor.run(body: {
                    AppState.loadImage(fileName: fileName, isVaulted: isVaulted)
                }) else {
                    OCRService.logFaceDetectionFailure(
                        pageIndex: pageIndex,
                        reason: "The source page image could not be loaded."
                    )
                    return
                }
                let image = adjustment.flatMap {
                    ExportEngine.applyImageAdjustment(sourceImage, store: $0)
                } ?? sourceImage
                do {
                    candidates.append(contentsOf: try await OCRService.detectFaceSuggestions(
                        in: image,
                        pageIndex: pageIndex
                    ))
                } catch {
                    return
                }
            }
            guard !Task.isCancelled else { return }
            let suggestions = OCRService.deduplicatedFaceSuggestions(candidates)
            await MainActor.run {
                guard !Task.isCancelled,
                      self.doc.id == documentID,
                      self.currentRedactionGeometryFingerprint == geometryFingerprint else { return }
                var snapshot = self.doc
                snapshot.fields.ocrFaceSuggestions = suggestions
                snapshot.fields.ocrFaceSuggestionsRevision = OCRService.faceSuggestionRevision
                self.doc = snapshot
                self.baselineDoc.fields.ocrFaceSuggestions = suggestions
                self.baselineDoc.fields.ocrFaceSuggestionsRevision = OCRService.faceSuggestionRevision
            }
        }
    }

    // MARK: - Find All / Propagation

    /// Copies all redactions from the current page to every other page.
    /// Existing redactions on other pages are preserved — this only adds.
    func propagateCurrentPageToAllPages() {
        guard pageCount > 1, !redactions.isEmpty else { return }
        persistCurrentPageState()
        for pageIdx in 0..<pageCount {
            guard pageIdx != currentPage else { continue }
            let existing = doc.redactions(for: pageIdx)
            let existingRects = existing.map { $0.rect }
            let toAdd = redactions.filter { r in
                !existingRects.contains(where: { abs($0.origin.x - r.rect.origin.x) < 0.01 && abs($0.origin.y - r.rect.origin.y) < 0.01 })
            }.map { Redaction(rect: $0.rect, style: $0.style) }
            let merged = existing + toAdd
            doc.setRedactions(merged, for: pageIdx)
        }
        AppState.trackEvent("redaction_applied", properties: ["source": "propagate_all_pages", "pages": String(pageCount)])
    }

    /// Applies the currently selected redaction (if any) to all pages at the same position.
    func propagateSelectedRedactionToAllPages() {
        guard let id = activeRedactionID,
              let red = redactions.first(where: { $0.id == id }),
              pageCount > 1 else { return }
        persistCurrentPageState()
        for pageIdx in 0..<pageCount {
            guard pageIdx != currentPage else { continue }
            var existing = doc.redactions(for: pageIdx)
            let alreadyExists = existing.contains {
                abs($0.rect.origin.x - red.rect.origin.x) < 0.01 &&
                abs($0.rect.origin.y - red.rect.origin.y) < 0.01
            }
            if !alreadyExists {
                existing.append(Redaction(rect: red.rect, style: red.style))
                doc.setRedactions(existing, for: pageIdx)
            }
        }
        AppState.trackEvent("redaction_applied", properties: ["source": "propagate_selected", "pages": String(pageCount)])
    }

    /// Returns the count of pages (other than current) that contain a redaction at the same position as the selected one.
    func matchingPagesCount(for redactionID: UUID) -> Int {
        guard let red = redactions.first(where: { $0.id == redactionID }) else { return 0 }
        var count = 0
        for pageIdx in 0..<pageCount {
            guard pageIdx != currentPage else { continue }
            let existing = doc.redactions(for: pageIdx)
            if existing.contains(where: {
                abs($0.rect.origin.x - red.rect.origin.x) < 0.01 &&
                abs($0.rect.origin.y - red.rect.origin.y) < 0.01
            }) { count += 1 }
        }
        return count
    }

    func toggleWatermark(text: String) {
        if watermark != nil {
            watermark = nil
        } else {
            watermark = Watermark(text: text, opacity: 0.18, isRepeating: true)
        }
        persistCurrentPageState()
    }

    func setWatermark(_ watermark: Watermark?) {
        self.watermark = watermark
        commitCurrentStateToHistory()
    }

    func markSaved() {
        persistCurrentPageState()
        baselineDoc = doc
        needsGeometryReviewPersistence = false
    }

    func adoptSavedDocument(_ document: DocumentItem) {
        ocrBootstrapTask?.cancel()
        ocrBootstrapRequestID = nil
        isAnalyzingOCRSuggestions = false
        faceBootstrapTask?.cancel()
        doc = document
        currentPage = min(currentPage, max(0, document.pageCount - 1))
        redactions = document.redactions(for: currentPage)
        watermark = document.watermark
        imageAdjustment = .default
        baselineDoc = document

        history = [EditorHistorySnapshot(
            redactions: redactions,
            imageAdjustment: imageAdjustment,
            watermark: watermark
        )]
        historyIdx = 0
        if document.fields.ocrPageEvidence?.isEmpty != false,
           (document.fields.ocrBoundingTexts ?? []).isEmpty {
            bootstrapOCRSuggestionsIfNeeded()
        }
        if document.fields.ocrFaceSuggestions == nil { bootstrapFaceSuggestionsIfNeeded() }
    }

    /// Returns suggested redaction rects for the sensitive-zones banner.
    ///
    /// For `photo`/`genericID` documents the result is grounded exclusively in
    /// Vision OCR output: we only return rects when (a) Vision actually extracted
    /// bounding-box text from the image, AND (b) those texts matched at least one
    /// identifiable sensitive field (name, doc number, DOB, etc.).
    /// This prevents the grid-based fallback from generating fake zones on images
    /// that contain no readable text at all (e.g., a photo of a tree or landscape).
    private static func suggestedRectsForBanner(in doc: DocumentItem) -> [CGRect] {
        if doc.kind == .photo || doc.kind == .genericID {
            // Only proceed if Vision produced real bounding-box observations.
            guard ocrHasRealText(in: doc) else { return [] }
            // Only return rects that are anchored to actual OCR tokens (precision mode).
            // ocrModeRects falls back to gridRects when no bounding texts exist, but we
            // already guard against that above, so here we know precision mode will run.
            let ocrRects = AutoRedactions.ocrPrecisionModeRects(for: .banking, fields: doc.fields)
            return ocrRects
        }
        return AutoRedactions.suggested(for: doc.kind).map { $0.rect }
    }

    /// Returns true when Vision's OCR has produced at least one real text token
    /// AND the document has at least one identifiable sensitive field (name, doc number, etc.).
    /// This is the authoritative check for "does this image contain text worth masking".
    private static func ocrHasRealText(in doc: DocumentItem) -> Bool {
        let hasTexts = !(doc.fields.ocrBoundingTexts ?? []).isEmpty
        let hasFields = !doc.fields.documentNumber.isEmpty ||
            !doc.fields.fullName.isEmpty ||
            !doc.fields.dateOfBirth.isEmpty
        return hasTexts && hasFields
    }

    private func normalizedSignature(for source: DocumentItem) -> String {
        var snapshot = source
        // Date/title/category changes are not editor changes for "Guardar".
        snapshot.date = baselineDoc.date
        snapshot.title = baselineDoc.title
        snapshot.category = baselineDoc.category
        snapshot.customCategoryID = baselineDoc.customCategoryID
        // OCR metadata enrichment should not mark the document as "unsaved edit".
        snapshot.fields = baselineDoc.fields
        let data = (try? JSONEncoder().encode(snapshot)) ?? Data()
        return data.base64EncodedString()
    }

    private func watermarkSignature(_ watermark: Watermark?) -> String {
        guard let watermark else { return "nil" }
        let data = (try? JSONEncoder().encode(watermark)) ?? Data()
        return data.base64EncodedString()
    }

    private func persistCurrentPageState() {
        var snapshot = doc
        snapshot.setRedactions(redactions, for: currentPage)
        snapshot.watermark = watermark
        snapshot.imageAdjustment = storedAdjustment(for: imageAdjustment)
        doc = snapshot
    }
}
