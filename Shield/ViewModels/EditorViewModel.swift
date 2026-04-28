import SwiftUI
import Combine

// MARK: - EditorTool

enum EditorTool: String, CaseIterable, Identifiable {
    case rect
    case fields
    case auto
    case text
    case watermark

    var id: String { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .rect:      return lang == .es ? "Rectángulo" : "Rect"
        case .fields:    return lang == .es ? "Campos" : "Fields"
        case .auto:      return "Auto"
        case .text:      return "Texto"
        case .watermark: return lang == .es ? "Marca agua" : "WM"
        }
    }

    var icon: String {
        switch self {
        case .rect:      return "rectangle.dashed"
        case .fields:    return "sparkles"
        case .auto:      return "checkmark.shield"
        case .text:      return "text.alignleft"
        case .watermark: return "drop.halffull"
        }
    }
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
    @Published var currentPage: Int = 0
    @Published var activeMode: RedactionMode? = nil

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
        self.showSensitiveBanner = !AutoRedactions.suggested(for: doc.kind).isEmpty
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
        showSensitiveBanner = false
        showFieldOverlays = false
    }

    func applyMode(_ mode: RedactionMode) {
        if activeMode == mode {
            // Deselect: clear redactions and reset
            push([])
            activeMode = nil
            return
        }
        var suggested = AutoRedactions.suggested(for: doc.kind, style: maskStyle)
        switch mode {
        case .travel:
            suggested = suggested.filter { $0.rect.origin.x != 0.04 && $0.rect.width != 1.0 }
        case .job:
            suggested = suggested.filter { r in
                r.rect.origin.y > 0.6 && r.rect.origin.y < 0.85
            }
        case .verify:
            suggested = suggested.filter { r in
                r.rect.origin.y > 0.6
            }
        default: break
        }
        push(suggested)
        activeMode = mode
        showSensitiveBanner = false
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
        }
    }

    func removeRedaction(id: UUID) {
        push(redactions.filter { $0.id != id })
        activeRedactionID = nil
    }

    func changeStyle(of id: UUID, to style: MaskStyle) {
        push(redactions.map { r in
            r.id == id ? Redaction(rect: r.rect, style: style) : r
        })
    }

    func addFromOCR(rect: CGRect) {
        push(redactions + [Redaction(rect: rect, style: maskStyle)])
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
        doc = snapshot
    }
}
