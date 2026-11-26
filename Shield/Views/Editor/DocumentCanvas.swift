import SwiftUI

// MARK: - DocumentCanvas

struct DocumentCanvas: View {
  @ObservedObject var vm: EditorViewModel
  let canvasSize: CGSize
  var effectiveZoom: CGFloat = 1.0
  var localSearchOccurrences: [LocalSearchOccurrence] = []
  @Environment(\.colorScheme) private var scheme
  @State private var dragFocalPoint: CGPoint? = nil

  var body: some View {
    ZStack {
      // Base layer: Original Clean Document (when Split-View is active)
      if vm.isSplitViewActive {
        DocumentView(
          kind: vm.doc.kind,
          size: canvasSize,
          fields: vm.doc.fields,
          redactions: [],
          watermark: nil,
          showFieldOverlays: false,
          imageFileName: vm.currentImageFileName,
          isVaulted: vm.doc.isVaulted,
          imageAdjustment: vm.doc.imageAdjustment
        )
        .allowsHitTesting(false)
      }

      // Document render — no hit testing so the canvas gestures fire
      DocumentView(
        kind: vm.doc.kind,
        size: canvasSize,
        fields: vm.doc.fields,
        redactions: vm.isPeekingOriginal ? [] : vm.redactions,
        watermark: vm.isPeekingOriginal ? nil : vm.watermark,
        showFieldOverlays: (vm.tool == .fields || vm.showFieldOverlays) && !vm.isPeekingOriginal,
        imageFileName: vm.currentImageFileName,
        isVaulted: vm.doc.isVaulted,
        imageAdjustment: vm.doc.imageAdjustment
      )
      .allowsHitTesting(false)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(LanguageManager.shared.editor("editor_protected_document_preview"))
      .accessibilityIdentifier("editor.document.preview")
      .accessibilityAddTraits(.isImage)
      .mask(alignment: .trailing) {
        if vm.isSplitViewActive {
          Rectangle()
            .frame(width: max(0, canvasSize.width * (1.0 - vm.splitViewPosition)))
        } else {
          Rectangle()
        }
      }

      // Drawing preview
      if let dr = vm.drawingRect, !vm.isPeekingOriginal {
        let s = scaledRect(dr)
        Rectangle()
          .fill(ShieldTheme.selection(scheme).opacity(0.20))
          .overlay(
            Rectangle().stroke(
              ShieldTheme.selection(scheme),
              style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
            )
          )
          .frame(width: s.width, height: s.height)
          .position(x: s.midX, y: s.midY)
          .allowsHitTesting(false)
      }

      // Field overlays (tool == .fields)
      if vm.tool == .fields && !vm.isPeekingOriginal {
        ForEach(DocumentFieldBoxes.boxes(for: vm.doc.kind)) { box in
          FieldOverlay(box: box, vm: vm, canvasSize: canvasSize)
        }
      }

      if !vm.isPeekingOriginal {
        ForEach(Array(localSearchOccurrences.enumerated()), id: \.element.id) { index, occurrence in
          if let rect = occurrence.boundingRect {
            let searchRect = scaledRect(rect)
            RoundedRectangle(cornerRadius: 4)
              .stroke(
                ShieldTheme.selection(scheme), style: StrokeStyle(lineWidth: 2, dash: [5, 3])
              )
              .frame(width: searchRect.width, height: searchRect.height)
              .overlay(alignment: .topLeading) {
                Text("\(index + 1)")
                  .font(.system(size: 10, weight: .bold, design: .rounded))
                  .foregroundStyle(.white)
                  .padding(.horizontal, 5)
                  .padding(.vertical, 2)
                  .background(ShieldTheme.selection(scheme), in: Capsule())
                  .offset(y: -16)
              }
              .position(x: searchRect.midX, y: searchRect.midY)
              .allowsHitTesting(false)
              .accessibilityLabel(
                occurrence.confidence.map { confidence in
                  LanguageManager.shared.home(
                    "home_search_occurrence_accessibility",
                    index + 1,
                    Int(confidence * 100)
                  )
                }
                  ?? LanguageManager.shared.home(
                    "home_search_occurrence_accessibility_no_confidence",
                    index + 1
                  )
              )
          }
        }
      }

      if !vm.isPeekingOriginal {
        ForEach(Array(vm.currentPageFaceSuggestions.enumerated()), id: \.element.id) {
          index, suggestion in
          if !vm.isFaceSuggestionProtected(suggestion) {
            let faceRect = scaledRect(
              OCRService.protectiveFaceMaskRect(
                around: suggestion.boundingRect,
                rollDegrees: suggestion.rollDegrees
              ))
            RoundedRectangle(cornerRadius: 6)
              .stroke(ShieldTheme.warning, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
              .frame(width: faceRect.width, height: faceRect.height)
              .overlay(alignment: .topLeading) {
                Image(systemName: "face.smiling")
                  .font(.system(size: 10, weight: .bold))
                  .foregroundStyle(ShieldTheme.accentText)
                  .padding(4)
                  .background(ShieldTheme.warning, in: Circle())
                  .offset(x: -7, y: -8)
              }
              .position(x: faceRect.midX, y: faceRect.midY)
              .allowsHitTesting(false)
              .accessibilityLabel(
                LanguageManager.shared.editor(
                  "editor_face_suggestion_accessibility",
                  index + 1,
                  Int(suggestion.confidence * 100)
                )
              )
          }
        }
      }

      // Redaction overlays
      if !vm.isPeekingOriginal {
        ForEach(vm.redactions) { redaction in
          RedactionOverlay(
            redaction: redaction,
            isActive: vm.activeRedactionID == redaction.id,
            canvasSize: canvasSize,
            effectiveZoom: effectiveZoom,
            vm: vm
          )
        }
        .mask(alignment: .trailing) {
          if vm.isSplitViewActive {
            Rectangle()
              .frame(width: max(0, canvasSize.width * (1.0 - vm.splitViewPosition)))
          } else {
            Rectangle()
          }
        }
      }

      // Split View Interactive Divider
      if vm.isSplitViewActive {
        SplitViewDividerOverlay(
          canvasSize: canvasSize,
          position: $vm.splitViewPosition,
          scheme: scheme
        )
        .zIndex(150)
      }

      // Precision Loupe (magnifies underlying text 2.0x when drawing)
      if let focal = dragFocalPoint, !vm.isPeekingOriginal {
        PrecisionLoupeView(
          focalPoint: focal,
          canvasSize: canvasSize,
          doc: vm.doc,
          currentImageFileName: vm.currentImageFileName,
          redactions: vm.redactions,
          scheme: scheme
        )
        .zIndex(200)
      }
    }
    .frame(width: canvasSize.width, height: canvasSize.height)
    .contentShape(Rectangle())
    .gesture(
      DragGesture(minimumDistance: 4, coordinateSpace: .local)
        .onChanged { value in
          guard vm.tool == .rect,
            !vm.isDraggingRedaction,
            !vm.isResizingRedaction
          else { return }
          AppState.markUserActivity()
          let pt = norm(value.location)
          if vm.drawingStart == nil {
            vm.beginDraw(at: norm(value.startLocation))
          }
          vm.updateDraw(to: pt)
          dragFocalPoint = value.location
        }
        .onEnded { _ in
          guard vm.tool == .rect,
            !vm.isDraggingRedaction,
            !vm.isResizingRedaction
          else { return }
          vm.endDraw()
          dragFocalPoint = nil
        }
    )
    .simultaneousGesture(
      TapGesture().onEnded {
        AppState.markUserActivity()
        if !vm.isDraggingRedaction && !vm.isResizingRedaction {
          vm.activeRedactionID = nil
        }
      }
    )
    .accessibilityElement(children: .contain)
    .accessibilityLabel(LanguageManager.shared.editor("editor_canvas_accessibility_label"))
    .accessibilityAction(named: Text("Añadir máscara al centro")) {
      vm.addRedaction(
        Redaction(
          rect: CGRect(x: 0.20, y: 0.35, width: 0.60, height: 0.12),
          style: vm.maskStyle
        )
      )
      UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
  }

  func scaledRect(_ r: CGRect) -> CGRect {
    DocumentCoordinateTransform.canonicalToViewport(rect: r, in: canvasSize)
  }

  func norm(_ pt: CGPoint) -> CGPoint {
    DocumentCoordinateTransform.viewportToCanonical(point: pt, in: canvasSize)
  }
}

// MARK: - FieldOverlay

private struct FieldOverlay: View {
  let box: FieldBox
  @ObservedObject var vm: EditorViewModel
  let canvasSize: CGSize
  @Environment(\.colorScheme) private var scheme

  private var sr: CGRect {
    DocumentCoordinateTransform.canonicalToViewport(rect: box.rect, in: canvasSize)
  }
  private var isSelected: Bool {
    vm.redactions.contains {
      abs($0.rect.origin.x - box.rect.origin.x) < 0.01
        && abs($0.rect.origin.y - box.rect.origin.y) < 0.01
    }
  }

  private var localizedLabel: String {
    let key: String
    switch box.label {
    case "Surname 1": key = "model_label_surname1"
    case "Surname 2": key = "model_label_surname2"
    case "Surname", "Apellido(s)": key = "model_label_surname"
    case "Given names", "Names", "Nombre(s)": key = "model_label_given_names"
    case "Name": key = "model_label_given_name"
    case "Passport №": key = "model_label_passport_no"
    case "Doc №", "Codice fiscale", "Driver №": key = "model_label_doc_number"
    case "DOB", "Nacimiento", "Nascita": key = "model_label_dob"
    case "Expires", "Vence", "Scadenza": key = "model_label_expires"
    case "Nationality": key = "model_label_nationality"
    case "Address": key = "model_field_address"
    case "Issued": key = "model_label_uk_issued"
    case "Cognome": key = "model_label_ita_surname"
    case "Nome": key = "model_label_ita_name"
    default: return box.label
    }
    return LanguageManager.shared.model(key)
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      Rectangle()
        .fill(isSelected ? ShieldTheme.success.opacity(0.20) : Color.clear)
        .overlay(
          Rectangle().stroke(
            isSelected ? ShieldTheme.success : ShieldTheme.selection(scheme),
            style: StrokeStyle(lineWidth: 1.5, dash: isSelected ? [] : [3, 2])
          )
        )
        .frame(width: sr.width, height: sr.height)
        .contentShape(Rectangle())
        .onTapGesture { vm.toggleField(box) }
      Text((isSelected ? "✓ " : "") + localizedLabel)
        .shieldFont(9, weight: .bold)
        .foregroundColor(isSelected ? ShieldTheme.success : ShieldTheme.selection(scheme))
        .padding(.horizontal, 5).padding(.vertical, 2)
        .background(Color.black.opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .offset(y: -18)
        .allowsHitTesting(false)
    }
    .position(x: sr.midX, y: sr.midY)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(localizedLabel)
    .accessibilityValue(
      LanguageManager.shared.editor(
        isSelected ? "editor_mask_selected" : "editor_mask_not_selected")
    )
    .accessibilityHint(LanguageManager.shared.editor("editor_field_toggle_hint"))
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    .accessibilityAction { vm.toggleField(box) }
  }
}

// MARK: - RedactionOverlay

private struct RedactionOverlay: View {
  let redaction: Redaction
  let isActive: Bool
  let canvasSize: CGSize
  let effectiveZoom: CGFloat
  @ObservedObject var vm: EditorViewModel
  @Environment(\.colorScheme) private var scheme

  // Start-of-gesture snapshots — prevents using live-updated redaction.rect as delta base
  @State private var moveStart: CGRect? = nil
  @State private var resizeNWStart: CGRect? = nil
  @State private var resizeNEStart: CGRect? = nil
  @State private var resizeSWStart: CGRect? = nil
  @State private var resizeSEStart: CGRect? = nil

  private var sr: CGRect {
    DocumentCoordinateTransform.canonicalToViewport(rect: redaction.rect, in: canvasSize)
  }

  private var zoom: CGFloat {
    max(effectiveZoom, 0.5)
  }

  private func nudgeRedaction(dx: CGFloat, dy: CGFloat) {
    let current = redaction.rect
    let maxX: CGFloat = 1.0 - current.width
    let maxY: CGFloat = 1.0 - current.height
    let newX: CGFloat = min(maxX, max(0.0, current.origin.x + dx))
    let newY: CGFloat = min(maxY, max(0.0, current.origin.y + dy))
    let newRect = CGRect(x: newX, y: newY, width: current.width, height: current.height)
    vm.resizeRedaction(id: redaction.id, newRect: newRect)
  }

  private func handleMoveDrag(translation: CGSize) {
    AppState.markUserActivity()
    vm.isDraggingRedaction = true
    if moveStart == nil {
      moveStart = redaction.rect
      vm.beginRedactionTransform()
    }
    guard let start = moveStart else { return }
    let delta = DocumentCoordinateTransform.canonicalDelta(
      translation: translation,
      zoom: zoom,
      canvasSize: canvasSize
    )
    let limitX: CGFloat = 1.0 - start.width
    let limitY: CGFloat = 1.0 - start.height
    let rawX: CGFloat = start.origin.x + delta.dx
    let rawY: CGFloat = start.origin.y + delta.dy
    let newX: CGFloat = max(0.0, min(limitX, rawX))
    let newY: CGFloat = max(0.0, min(limitY, rawY))
    let newRect = CGRect(x: newX, y: newY, width: start.width, height: start.height)
    vm.resizeRedaction(id: redaction.id, newRect: newRect)
  }

  private func handleMoveEnd() {
    vm.isDraggingRedaction = false
    moveStart = nil
    vm.commitRedactionTransform()
  }

  @ViewBuilder
  private func tapAndDragTarget(s: CGRect) -> some View {
    Rectangle()
      .fill(Color.clear)
      .frame(width: max(s.width, 36), height: max(s.height, 36))
      .contentShape(Rectangle())
      .onTapGesture {
        withAnimation(.easeInOut(duration: 0.15)) {
          vm.activeRedactionID = isActive ? nil : redaction.id
        }
      }
      .gesture(
        isActive
          ? DragGesture(minimumDistance: 2, coordinateSpace: .local)
            .onChanged { value in
              handleMoveDrag(translation: value.translation)
            }
            .onEnded { _ in
              handleMoveEnd()
            }
          : nil
      )
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(
        LanguageManager.shared.editor(
          "editor_mask_item_accessibility",
          redaction.style.label(lang: LanguageManager.shared.current))
      )
      .accessibilityValue(
        String(
          format: "%.0f%%, %.0f%%", redaction.rect.origin.x * 100, redaction.rect.origin.y * 100)
      )
      .accessibilityAction(named: Text("Seleccionar o deseleccionar")) {
        vm.activeRedactionID = isActive ? nil : redaction.id
      }
      .accessibilityAction(named: Text("Eliminar máscara")) {
        vm.removeRedaction(id: redaction.id)
      }
      .accessibilityAdjustableAction { direction in
        switch direction {
        case .increment:
          nudgeRedaction(dx: 0.05, dy: 0.0)
        case .decrement:
          nudgeRedaction(dx: -0.05, dy: 0.0)
        @unknown default:
          break
        }
      }
  }

  var body: some View {
    let s = sr
    ZStack {
      tapAndDragTarget(s: s)

      if isActive {
        // Selection border
        Rectangle()
          .stroke(ShieldTheme.selection(scheme), lineWidth: 2.5)
          .frame(width: s.width + 4, height: s.height + 4)
          .allowsHitTesting(false)

        // Delete button — top center-right
        Button {
          vm.removeRedaction(id: redaction.id)
        } label: {
          ZStack {
            Circle().fill(ShieldTheme.danger).frame(width: 24, height: 24)
            Circle().stroke(Color.white, lineWidth: 2).frame(width: 24, height: 24)
            Image(systemName: "xmark")
              .shieldFont(10, weight: .bold).foregroundColor(.white)
          }
        }
        .offset(x: s.width / 2 + 14, y: -(s.height / 2 + 14))
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(LanguageManager.shared.editor("editor_mask_delete"))
        .accessibilityHidden(true)

        // NW resize handle (Top-Left)
        ResizeHandle()
          .offset(x: -(s.width / 2), y: -(s.height / 2))
          .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .local)
              .onChanged { value in
                AppState.markUserActivity()
                vm.isResizingRedaction = true
                if resizeNWStart == nil {
                  resizeNWStart = redaction.rect
                  vm.beginRedactionTransform()
                }
                guard let start = resizeNWStart else { return }
                let delta = DocumentCoordinateTransform.canonicalDelta(
                  translation: value.translation,
                  zoom: zoom,
                  canvasSize: canvasSize
                )
                let rawX = start.origin.x + delta.dx
                let rawY = start.origin.y + delta.dy
                let clampedX = min(start.maxX - 0.03, max(0, rawX))
                let clampedY = min(start.maxY - 0.03, max(0, rawY))
                let newW = start.maxX - clampedX
                let newH = start.maxY - clampedY
                vm.resizeRedaction(
                  id: redaction.id,
                  newRect: CGRect(x: clampedX, y: clampedY, width: newW, height: newH)
                )
              }
              .onEnded { _ in
                vm.isResizingRedaction = false
                resizeNWStart = nil
                vm.commitRedactionTransform()
              }
          )

        // NE resize handle (Top-Right)
        ResizeHandle()
          .offset(x: s.width / 2, y: -(s.height / 2))
          .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .local)
              .onChanged { value in
                AppState.markUserActivity()
                vm.isResizingRedaction = true
                if resizeNEStart == nil {
                  resizeNEStart = redaction.rect
                  vm.beginRedactionTransform()
                }
                guard let start = resizeNEStart else { return }
                let delta = DocumentCoordinateTransform.canonicalDelta(
                  translation: value.translation,
                  zoom: zoom,
                  canvasSize: canvasSize
                )
                let rawY = start.origin.y + delta.dy
                let clampedY = min(start.maxY - 0.03, max(0, rawY))
                let newH = start.maxY - clampedY
                let newW = max(0.03, min(1 - start.origin.x, start.width + delta.dx))
                vm.resizeRedaction(
                  id: redaction.id,
                  newRect: CGRect(x: start.origin.x, y: clampedY, width: newW, height: newH)
                )
              }
              .onEnded { _ in
                vm.isResizingRedaction = false
                resizeNEStart = nil
                vm.commitRedactionTransform()
              }
          )

        // SW resize handle (Bottom-Left)
        ResizeHandle()
          .offset(x: -(s.width / 2), y: s.height / 2)
          .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .local)
              .onChanged { value in
                AppState.markUserActivity()
                vm.isResizingRedaction = true
                if resizeSWStart == nil {
                  resizeSWStart = redaction.rect
                  vm.beginRedactionTransform()
                }
                guard let start = resizeSWStart else { return }
                let delta = DocumentCoordinateTransform.canonicalDelta(
                  translation: value.translation,
                  zoom: zoom,
                  canvasSize: canvasSize
                )
                let rawX = start.origin.x + delta.dx
                let clampedX = min(start.maxX - 0.03, max(0, rawX))
                let newW = start.maxX - clampedX
                let newH = max(0.03, min(1 - start.origin.y, start.height + delta.dy))
                vm.resizeRedaction(
                  id: redaction.id,
                  newRect: CGRect(x: clampedX, y: start.origin.y, width: newW, height: newH)
                )
              }
              .onEnded { _ in
                vm.isResizingRedaction = false
                resizeSWStart = nil
                vm.commitRedactionTransform()
              }
          )

        // SE resize handle (Bottom-Right)
        ResizeHandle()
          .offset(x: s.width / 2, y: s.height / 2)
          .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .local)
              .onChanged { value in
                AppState.markUserActivity()
                vm.isResizingRedaction = true
                if resizeSEStart == nil {
                  resizeSEStart = redaction.rect
                  vm.beginRedactionTransform()
                }
                guard let start = resizeSEStart else { return }
                let delta = DocumentCoordinateTransform.canonicalDelta(
                  translation: value.translation,
                  zoom: zoom,
                  canvasSize: canvasSize
                )
                let newW = max(0.03, min(1 - start.origin.x, start.width + delta.dx))
                let newH = max(0.03, min(1 - start.origin.y, start.height + delta.dy))
                vm.resizeRedaction(
                  id: redaction.id,
                  newRect: CGRect(x: start.origin.x, y: start.origin.y, width: newW, height: newH)
                )
              }
              .onEnded { _ in
                vm.isResizingRedaction = false
                resizeSEStart = nil
                vm.commitRedactionTransform()
              }
          )
      }
    }
    .position(x: s.midX, y: s.midY)
    .animation(.easeInOut(duration: 0.12), value: isActive)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(LanguageManager.shared.editor("editor_mask_accessibility_label"))
    .accessibilityValue(
      LanguageManager.shared.editor(isActive ? "editor_mask_selected" : "editor_mask_not_selected")
    )
    .accessibilityHint(LanguageManager.shared.editor("editor_mask_accessibility_hint"))
    .accessibilityIdentifier("editor.mask.\(redaction.id.uuidString)")
    .accessibilityAddTraits(isActive ? .isSelected : [])
    .accessibilityAction {
      vm.activeRedactionID = isActive ? nil : redaction.id
    }
    .accessibilityActions {
      Button(LanguageManager.shared.editor("editor_mask_delete")) {
        vm.removeRedaction(id: redaction.id)
      }
      Button(LanguageManager.shared.editor("editor_mask_move_up")) {
        moveAccessibilityMask(dx: 0, dy: -0.02)
      }
      Button(LanguageManager.shared.editor("editor_mask_move_down")) {
        moveAccessibilityMask(dx: 0, dy: 0.02)
      }
      Button(LanguageManager.shared.editor("editor_mask_move_left")) {
        moveAccessibilityMask(dx: -0.02, dy: 0)
      }
      Button(LanguageManager.shared.editor("editor_mask_move_right")) {
        moveAccessibilityMask(dx: 0.02, dy: 0)
      }
    }
    .accessibilityAdjustableAction { direction in
      let delta: CGFloat = 0.02
      var rect = redaction.rect
      switch direction {
      case .increment:
        rect.size.width = min(1 - rect.origin.x, rect.width + delta)
        rect.size.height = min(1 - rect.origin.y, rect.height + delta)
      case .decrement:
        rect.size.width = max(0.04, rect.width - delta)
        rect.size.height = max(0.04, rect.height - delta)
      @unknown default:
        return
      }
      vm.beginRedactionTransform()
      vm.resizeRedaction(id: redaction.id, newRect: rect)
      vm.commitRedactionTransform()
    }
  }

  private func moveAccessibilityMask(dx: CGFloat, dy: CGFloat) {
    var rect = redaction.rect
    rect.origin.x = min(max(0, rect.origin.x + dx), 1 - rect.width)
    rect.origin.y = min(max(0, rect.origin.y + dy), 1 - rect.height)
    vm.beginRedactionTransform()
    vm.resizeRedaction(id: redaction.id, newRect: rect)
    vm.commitRedactionTransform()
  }
}

// MARK: - ResizeHandle

private struct ResizeHandle: View {
  @Environment(\.colorScheme) private var scheme
  var body: some View {
    ZStack {
      Circle()
        .fill(Color.white)
        .frame(width: 18, height: 18)
        .shadow(color: .black.opacity(0.40), radius: 3, x: 0, y: 1)
      Circle()
        .stroke(ShieldTheme.selection(scheme), lineWidth: 3)
        .frame(width: 18, height: 18)
    }
    .frame(width: 44, height: 44)
    .contentShape(Rectangle())
    .accessibilityHidden(true)
  }
}

// MARK: - PrecisionLoupeView

struct PrecisionLoupeView: View {
  let focalPoint: CGPoint
  let canvasSize: CGSize
  let doc: DocumentItem
  let currentImageFileName: String?
  let redactions: [Redaction]
  let scheme: ColorScheme

  private let loupeDiameter: CGFloat = 96
  private let zoomFactor: CGFloat = 2.0

  private var clampedLoupeCenter: CGPoint {
    let halfD = loupeDiameter / 2
    let margin: CGFloat = 8
    let clampedX = min(
      max(focalPoint.x, halfD + margin), max(canvasSize.width - halfD - margin, halfD + margin))
    let yOffset: CGFloat = focalPoint.y < 85 ? 65 : -65
    let targetY = focalPoint.y + yOffset
    let clampedY = min(
      max(targetY, halfD + margin), max(canvasSize.height - halfD - margin, halfD + margin))
    return CGPoint(x: clampedX, y: clampedY)
  }

  var body: some View {
    ZStack {
      // Magnified document content
      ZStack {
        DocumentView(
          kind: doc.kind,
          size: canvasSize,
          fields: doc.fields,
          redactions: redactions,
          watermark: nil,
          showFieldOverlays: false,
          imageFileName: currentImageFileName,
          isVaulted: doc.isVaulted,
          imageAdjustment: doc.imageAdjustment
        )
        .frame(width: canvasSize.width, height: canvasSize.height)
        .scaleEffect(
          zoomFactor,
          anchor: UnitPoint(
            x: max(0, min(1, focalPoint.x / max(canvasSize.width, 1))),
            y: max(0, min(1, focalPoint.y / max(canvasSize.height, 1)))
          )
        )
      }
      .frame(width: loupeDiameter, height: loupeDiameter)
      .clipShape(Circle())

      // Reticle Crosshairs
      Rectangle()
        .fill(ShieldTheme.accent(scheme))
        .frame(width: 14, height: 1.5)
      Rectangle()
        .fill(ShieldTheme.accent(scheme))
        .frame(width: 1.5, height: 14)

      Circle()
        .fill(ShieldTheme.accent(scheme))
        .frame(width: 3, height: 3)

      // Outer lens rim with glow
      Circle()
        .stroke(
          LinearGradient(
            colors: [
              ShieldTheme.accent(scheme),
              Color.white.opacity(0.85),
              ShieldTheme.accent(scheme).opacity(0.6),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 2.5
        )

      // Zoom indicator
      VStack {
        Spacer()
        Text("2.0x")
          .font(.system(size: 8, weight: .bold, design: .rounded))
          .foregroundStyle(.white)
          .padding(.horizontal, 5)
          .padding(.vertical, 1.5)
          .background(Color.black.opacity(0.75), in: Capsule())
          .offset(y: -4)
      }
      .frame(width: loupeDiameter, height: loupeDiameter)
    }
    .frame(width: loupeDiameter, height: loupeDiameter)
    .shadow(color: Color.black.opacity(0.45), radius: 8, x: 0, y: 4)
    .position(clampedLoupeCenter)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
    .transition(.scale(scale: 0.8).combined(with: .opacity))
  }
}

// MARK: - SplitViewDividerOverlay

private struct SplitViewDividerOverlay: View {
  let canvasSize: CGSize
  @Binding var position: CGFloat
  let scheme: ColorScheme

  private var dividerX: CGFloat {
    canvasSize.width * max(0.02, min(0.98, position))
  }

  var body: some View {
    ZStack {
      // Vertical dividing line with glow
      Rectangle()
        .fill(
          LinearGradient(
            colors: [
              ShieldTheme.accent(scheme).opacity(0.85),
              Color.white,
              ShieldTheme.accent(scheme).opacity(0.85),
            ],
            startPoint: .top,
            endPoint: .bottom
          )
        )
        .frame(width: 2.5, height: canvasSize.height)
        .shadow(color: Color.black.opacity(0.55), radius: 4, x: 0, y: 0)
        .position(x: dividerX, y: canvasSize.height / 2)

      // Center interactive grab handle
      HStack(spacing: 3) {
        Image(systemName: "arrow.left.and.right")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(ShieldTheme.accentText)
      }
      .frame(width: 32, height: 32)
      .background(ShieldTheme.accent(scheme), in: Circle())
      .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
      .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
      .position(x: dividerX, y: canvasSize.height / 2)
      .gesture(
        DragGesture(minimumDistance: 1, coordinateSpace: .local)
          .onChanged { value in
            let newPos = max(0.05, min(0.95, value.location.x / max(canvasSize.width, 1)))
            if abs(newPos - 0.5) < 0.02 && abs(position - 0.5) >= 0.02 {
              UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            position = newPos
          }
      )

      // Left tag: ORIGINAL
      Text(LanguageManager.shared.current == .es ? "ORIGINAL" : "ORIGINAL")
        .font(.system(size: 8, weight: .black, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.65), in: Capsule())
        .position(x: max(32, dividerX - 44), y: 24)

      // Right tag: PROTEGIDO
      Text(LanguageManager.shared.current == .es ? "PROTEGIDO" : "PROTECTED")
        .font(.system(size: 8, weight: .black, design: .rounded))
        .foregroundStyle(ShieldTheme.accentText)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(ShieldTheme.accent(scheme), in: Capsule())
        .position(x: min(canvasSize.width - 44, dividerX + 48), y: 24)
    }
    .allowsHitTesting(true)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      LanguageManager.shared.current == .es
        ? "Lente comparativa antes y después" : "Before and after comparison slider"
    )
    .accessibilityValue(String(format: "%.0f%%", position * 100))
    .accessibilityAdjustableAction { direction in
      switch direction {
      case .increment:
        position = min(0.95, position + 0.05)
      case .decrement:
        position = max(0.05, position - 0.05)
      @unknown default:
        break
      }
    }
  }
}
