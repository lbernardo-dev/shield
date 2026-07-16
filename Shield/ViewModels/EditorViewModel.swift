import SwiftUI
import Combine

// MARK: - EditorTool

enum EditorTool: String, CaseIterable, Identifiable {
    case rect
    case fields
    case auto
    case text
    case watermark
    case adjust   // image adjustment (brightness, contrast, rotation, crop, flip)

    var id: String { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .rect:      return lang == .es ? "Rectángulo" : "Rect"
        case .fields:    return lang == .es ? "Campos" : "Fields"
        case .auto:      return "Auto"
        case .text:      return "Texto"
        case .watermark: return lang == .es ? "Marca agua" : "WM"
        case .adjust:    return lang == .es ? "Ajustar" : "Adjust"
        }
    }

    var icon: String {
        switch self {
        case .rect:      return "rectangle.dashed"
        case .fields:    return "sparkles"
        case .auto:      return "checkmark.shield"
        case .text:      return "text.alignleft"
        case .watermark: return "drop.halffull"
        case .adjust:    return "slider.horizontal.3"
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

    @Published var tool: EditorTool = .rect
    @Published var maskStyle: MaskStyle = .block
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

    var pageCount: Int { doc.pageCount }
    var currentImageFileName: String? { doc.imageFileName(for: currentPage) }
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
        history = [redactions]
        historyIdx = 0
    }

    // Drawing state
    @Published var drawingStart: CGPoint? = nil
    @Published var drawingCurrent: CGPoint? = nil

    // Undo/redo
    private var history: [[Redaction]] = [[]]
    private var historyIdx: Int = 0
    private var redactionTransformBaseline: [Redaction]? = nil

    var canUndo: Bool { historyIdx > 0 }
    var canRedo: Bool { historyIdx < history.count - 1 }

    init(doc: DocumentItem) {
        self.doc = doc
        self.baselineDoc = doc
        self.redactions = doc.redactions(for: 0)
        self.watermark = doc.watermark
        self.history = [self.redactions]
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
        let suggestions = Self.suggestedRectsForBanner(in: doc)
        let hasOCRFields = doc.kind == .photo || doc.kind == .genericID
            ? !doc.fields.documentNumber.isEmpty || !doc.fields.fullName.isEmpty
            : false
        self.showSensitiveBanner = !suggestions.isEmpty || hasOCRFields
        if showSensitiveBanner {
            AppState.trackEvent("risk_detected", properties: [
                "kind": doc.kind.rawValue,
                "suggested_count": String(suggestions.count)
            ])
        }
    }

    // MARK: - History

    private func push(_ next: [Redaction]) {
        guard next != redactions else { return }
        history = Array(history.prefix(historyIdx + 1))
        history.append(next)
        historyIdx = history.count - 1
        redactions = next
        persistCurrentPageState()
    }

    func undo() {
        guard canUndo else { return }
        historyIdx -= 1
        redactions = history[historyIdx]
        persistCurrentPageState()
    }

    func redo() {
        guard canRedo else { return }
        historyIdx += 1
        redactions = history[historyIdx]
        persistCurrentPageState()
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

    func applyMode(_ mode: RedactionMode) {
        if activeMode == mode {
            push([])
            activeMode = nil
            return
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
                return
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
                return
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
        imageAdjustment = sanitizedAdjustment(adjustment)
        persistCurrentPageState()
    }

    func resetAdjustment() {
        imageAdjustment = .default
        persistCurrentPageState()
    }

    func rotateImage90CW() {
        var adj = imageAdjustment
        adj.rotation = ((adj.rotation + 90).truncatingRemainder(dividingBy: 360))
        imageAdjustment = adj
        persistCurrentPageState()
    }

    func flipImageHorizontal() {
        var adj = imageAdjustment
        adj.flipHorizontal.toggle()
        imageAdjustment = adj
        persistCurrentPageState()
    }

    func flipImageVertical() {
        var adj = imageAdjustment
        adj.flipVertical.toggle()
        imageAdjustment = adj
        persistCurrentPageState()
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
        history = Array(history.prefix(historyIdx + 1))
        history.append(redactions)
        historyIdx = history.count - 1
        persistCurrentPageState()
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
        var snapshot = doc
        snapshot.fields = fields
        doc = snapshot
        baselineDoc.fields = fields
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
        let hasFields = !doc.fields.documentNumber.isEmpty || !doc.fields.fullName.isEmpty
        let hasBoxes = !(doc.fields.ocrBoundingTexts ?? []).isEmpty
        guard !hasFields && !hasBoxes else { return }

        let images = loadSourceImagesForOCR()
        guard !images.isEmpty else { return }

        isAnalyzingOCRSuggestions = true
        ocrBootstrapTask?.cancel()
        ocrBootstrapTask = Task { [weak self] in
            guard let self else { return }
            let pageObs = await OCRService.recognizeObservationsByPageAdaptive(in: images)
            if Task.isCancelled { return }
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
                var snapshot = self.doc
                snapshot.fields = resolvedFields
                self.doc = snapshot
                // OCR bootstrap is automatic metadata enrichment, not a user edit.
                self.baselineDoc.fields = resolvedFields

                // For photo/genericID: only show the banner when Vision actually found
                // identifiable field text (name, doc number, etc.).
                // An empty OCR result (e.g., a photo of a tree) must NOT trigger the banner.
                let hasIdentifiableFields = !resolvedFields.documentNumber.isEmpty ||
                    !resolvedFields.fullName.isEmpty
                let hasOCRBoundingRects = !(resolvedFields.ocrBoundingTexts ?? []).isEmpty
                let hasSuggestedRects = !Self.suggestedRectsForBanner(in: snapshot).isEmpty

                if snapshot.kind == .photo || snapshot.kind == .genericID {
                    // Only show banner when real text-backed zones exist, not grid fallback.
                    self.showSensitiveBanner = hasIdentifiableFields && hasOCRBoundingRects && hasSuggestedRects
                } else {
                    self.showSensitiveBanner = hasSuggestedRects || hasIdentifiableFields
                }
                self.isAnalyzingOCRSuggestions = false
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
        persistCurrentPageState()
    }

    func markSaved() {
        persistCurrentPageState()
        baselineDoc = doc
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

    private func loadSourceImagesForOCR() -> [UIImage] {
        let rawImages: [UIImage]
        if let pages = doc.pageFileNames, !pages.isEmpty {
            rawImages = pages.compactMap { AppState.loadImage(fileName: $0, isVaulted: doc.isVaulted) }
        } else if let fileName = doc.imageFileName,
                  let image = AppState.loadImage(fileName: fileName, isVaulted: doc.isVaulted) {
            rawImages = [image]
        } else {
            rawImages = []
        }
        guard let adjustment = doc.imageAdjustment else { return rawImages }
        return rawImages.map { ExportEngine.applyImageAdjustment($0, store: adjustment) ?? $0 }
    }

    /// Updates the render cache while keeping immutable originals untouched.
    func updateRenderedPages(transforms: [DocumentPageTransform]) {
        var snapshot = doc
        snapshot.pageTransforms = transforms
        snapshot.imageAdjustment = nil
        snapshot.date = Date()
        doc = snapshot
        imageAdjustment = .default
    }

    private func persistCurrentPageState() {
        var snapshot = doc
        snapshot.setRedactions(redactions, for: currentPage)
        snapshot.watermark = watermark
        if !imageAdjustment.isDefault {
            snapshot.imageAdjustment = ImageAdjustmentStore(
                brightness: imageAdjustment.brightness,
                contrast: imageAdjustment.contrast,
                saturation: imageAdjustment.saturation,
                sharpness: imageAdjustment.sharpness,
                rotation: imageAdjustment.rotation,
                flipHorizontal: imageAdjustment.flipHorizontal,
                flipVertical: imageAdjustment.flipVertical,
                cropLeft: imageAdjustment.cropLeft,
                cropRight: imageAdjustment.cropRight,
                cropTop: imageAdjustment.cropTop,
                cropBottom: imageAdjustment.cropBottom
            )
        } else {
            snapshot.imageAdjustment = nil
        }
        doc = snapshot
    }
}
