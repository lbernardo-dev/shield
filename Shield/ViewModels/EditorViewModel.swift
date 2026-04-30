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

    var pageCount: Int { doc.pageCount }
    var currentImageFileName: String? { doc.imageFileName(for: currentPage) }
    var suggestedRedactionCount: Int { AutoRedactions.suggested(for: doc.kind).count }
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

    var canUndo: Bool { historyIdx > 0 }
    var canRedo: Bool { historyIdx < history.count - 1 }

    init(doc: DocumentItem) {
        self.doc = doc
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
        let suggestions = AutoRedactions.suggested(for: doc.kind)
        self.showSensitiveBanner = !suggestions.isEmpty
        if !suggestions.isEmpty {
            AppState.trackEvent("risk_detected", properties: [
                "kind": doc.kind.rawValue,
                "suggested_count": String(suggestions.count)
            ])
        }
    }

    // MARK: - History

    private func push(_ next: [Redaction]) {
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
        let suggested = AutoRedactions.suggested(for: doc.kind, style: maskStyle)
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
            // For photo/generic docs: build mode redactions from OCR field boxes
            let modeRects = AutoRedactions.ocrModeRects(for: mode, fields: doc.fields)
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

    // MARK: - Image adjustment

    func updateAdjustment(_ adjustment: ImageAdjustment) {
        imageAdjustment = adjustment
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

    // MARK: - Redaction drag & resize

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
        persistCurrentPageState()
    }

    func resizeRedaction(id: UUID, newRect: CGRect) {
        let minSize: CGFloat = 0.02
        let safeRect = CGRect(
            x: max(0, min(0.98, newRect.origin.x)),
            y: max(0, min(0.98, newRect.origin.y)),
            width: max(minSize, min(1 - newRect.origin.x, newRect.width)),
            height: max(minSize, min(1 - newRect.origin.y, newRect.height))
        )
        let updated = redactions.map { r -> Redaction in
            guard r.id == id else { return r }
            var resized = r
            resized.rect = safeRect
            return resized
        }
        redactions = updated
        persistCurrentPageState()
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
