import SwiftUI

// MARK: - DocumentCanvas

struct DocumentCanvas: View {
    @ObservedObject var vm: EditorViewModel
    let canvasSize: CGSize

    var body: some View {
        ZStack {
            // Document render — no hit testing so the canvas DragGesture fires
            DocumentView(
                kind: vm.doc.kind,
                size: canvasSize,
                fields: vm.doc.fields,
                redactions: vm.redactions,
                watermark: vm.watermark,
                showFieldOverlays: vm.tool == .fields || vm.showFieldOverlays,
                imageFileName: vm.currentImageFileName,
                isVaulted: vm.doc.isVaulted,
                imageAdjustment: vm.doc.imageAdjustment
            )
            .allowsHitTesting(false)

            // Drawing preview
            if let dr = vm.drawingRect {
                let s = scaledRect(dr)
                Rectangle()
                    .fill(Color(hex: "FFD60A").opacity(0.20))
                    .overlay(
                        Rectangle().stroke(Color(hex: "FFD60A"),
                                          style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    )
                    .frame(width: s.width, height: s.height)
                    .position(x: s.midX, y: s.midY)
                    .allowsHitTesting(false)
            }

            // Field overlays (tool == .fields)
            if vm.tool == .fields {
                ForEach(DocumentFieldBoxes.boxes(for: vm.doc.kind)) { box in
                    FieldOverlay(box: box, vm: vm, canvasSize: canvasSize)
                }
            }

            // Redaction overlays
            ForEach(vm.redactions) { redaction in
                RedactionOverlay(
                    redaction: redaction,
                    isActive: vm.activeRedactionID == redaction.id,
                    canvasSize: canvasSize,
                    vm: vm
                )
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .contentShape(Rectangle())
        // Draw gesture has priority so users can start drawing even over existing masks.
        .highPriorityGesture(
            DragGesture(minimumDistance: 4, coordinateSpace: .local)
                .onChanged { value in
                    guard vm.tool == .rect,
                          !vm.isDraggingRedaction,
                          !vm.isResizingRedaction else { return }
                    AppState.markUserActivity()
                    let pt = norm(value.location)
                    if vm.drawingStart == nil {
                        vm.beginDraw(at: norm(value.startLocation))
                    }
                    vm.updateDraw(to: pt)
                }
                .onEnded { _ in
                    guard vm.tool == .rect,
                          !vm.isDraggingRedaction,
                          !vm.isResizingRedaction else { return }
                    vm.endDraw()
                }
        )
        // Tap on empty area deselects. Uses simultaneousGesture so overlay taps still fire,
        // but the overlay's onTapGesture runs AFTER and toggles back to the correct selection.
        .simultaneousGesture(
            TapGesture().onEnded {
                AppState.markUserActivity()
                vm.activeRedactionID = nil
            }
        )
    }

    func scaledRect(_ r: CGRect) -> CGRect {
        CGRect(x: r.origin.x * canvasSize.width,
               y: r.origin.y * canvasSize.height,
               width: r.width * canvasSize.width,
               height: r.height * canvasSize.height)
    }

    func norm(_ pt: CGPoint) -> CGPoint {
        CGPoint(
            x: max(0, min(1, pt.x / canvasSize.width)),
            y: max(0, min(1, pt.y / canvasSize.height))
        )
    }
}

// MARK: - FieldOverlay

private struct FieldOverlay: View {
    let box: FieldBox
    @ObservedObject var vm: EditorViewModel
    let canvasSize: CGSize

    private var sr: CGRect {
        CGRect(x: box.rect.origin.x * canvasSize.width,
               y: box.rect.origin.y * canvasSize.height,
               width: box.rect.width * canvasSize.width,
               height: box.rect.height * canvasSize.height)
    }
    private var isSelected: Bool {
        vm.redactions.contains {
            abs($0.rect.origin.x - box.rect.origin.x) < 0.01 &&
            abs($0.rect.origin.y - box.rect.origin.y) < 0.01
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(isSelected ? ShieldTheme.success.opacity(0.20) : Color.clear)
                .overlay(Rectangle().stroke(
                    isSelected ? ShieldTheme.success : Color(hex: "FFD60A"),
                    style: StrokeStyle(lineWidth: 1.5, dash: isSelected ? [] : [3, 2])
                ))
                .frame(width: sr.width, height: sr.height)
                .contentShape(Rectangle())
                .onTapGesture { vm.toggleField(box) }
            Text((isSelected ? "✓ " : "") + box.label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(isSelected ? ShieldTheme.success : Color(hex: "FFD60A"))
                .padding(.horizontal, 5).padding(.vertical, 2)
                .background(Color.black.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .offset(y: -18)
                .allowsHitTesting(false)
        }
        .position(x: sr.midX, y: sr.midY)
    }
}

// MARK: - RedactionOverlay

private struct RedactionOverlay: View {
    let redaction: Redaction
    let isActive: Bool
    let canvasSize: CGSize
    @ObservedObject var vm: EditorViewModel

    // Start-of-gesture snapshots — prevents using the live-updated redaction.rect as delta base
    @State private var moveStart: CGRect? = nil
    @State private var resizeSEStart: CGRect? = nil
    @State private var resizeSWStart: CGRect? = nil

    private var sr: CGRect {
        CGRect(x: redaction.rect.origin.x * canvasSize.width,
               y: redaction.rect.origin.y * canvasSize.height,
               width: redaction.rect.width * canvasSize.width,
               height: redaction.rect.height * canvasSize.height)
    }

    var body: some View {
        let s = sr
        ZStack {
            // Tap-to-select & drag-to-move
            Rectangle()
                .fill(Color.clear)
                .frame(width: max(s.width, 28), height: max(s.height, 28))
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        vm.activeRedactionID = isActive ? nil : redaction.id
                    }
                }
                .gesture(
                    isActive
                    ? DragGesture(minimumDistance: 3, coordinateSpace: .local)
                        .onChanged { value in
                            AppState.markUserActivity()
                            vm.isDraggingRedaction = true
                            // Snapshot at gesture start so delta is always from original position
                            if moveStart == nil { moveStart = redaction.rect }
                            guard let start = moveStart else { return }
                            // translation is always relative to startLocation, stable across updates
                            let dx = value.translation.width / canvasSize.width
                            let dy = value.translation.height / canvasSize.height
                            let newX = max(0, min(1 - start.width, start.origin.x + dx))
                            let newY = max(0, min(1 - start.height, start.origin.y + dy))
                            vm.resizeRedaction(id: redaction.id,
                                newRect: CGRect(x: newX, y: newY,
                                               width: start.width, height: start.height))
                        }
                        .onEnded { _ in
                            vm.isDraggingRedaction = false
                            moveStart = nil
                        }
                    : nil
                )

            if isActive {
                // Selection ring
                Rectangle()
                    .stroke(Color(hex: "FFD60A"), lineWidth: 2)
                    .frame(width: s.width + 6, height: s.height + 6)
                    .allowsHitTesting(false)

                // Delete — top-right
                Button { vm.removeRedaction(id: redaction.id) } label: {
                    ZStack {
                        Circle().fill(ShieldTheme.danger).frame(width: 26, height: 26)
                        Circle().stroke(Color.white, lineWidth: 2).frame(width: 26, height: 26)
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                    }
                }
                .offset(x: s.width / 2 + 10, y: -(s.height / 2 + 10))

                // SE resize — bottom-right
                ResizeHandle()
                    .offset(x: s.width / 2 + 2, y: s.height / 2 + 2)
                    .gesture(
                        DragGesture(minimumDistance: 1, coordinateSpace: .local)
                            .onChanged { value in
                                AppState.markUserActivity()
                                vm.isResizingRedaction = true
                                if resizeSEStart == nil { resizeSEStart = redaction.rect }
                                guard let start = resizeSEStart else { return }
                                let dw = value.translation.width / canvasSize.width
                                let dh = value.translation.height / canvasSize.height
                                vm.resizeRedaction(id: redaction.id,
                                    newRect: CGRect(x: start.origin.x, y: start.origin.y,
                                                    width: max(0.04, start.width + dw),
                                                    height: max(0.04, start.height + dh)))
                            }
                            .onEnded { _ in
                                vm.isResizingRedaction = false
                                resizeSEStart = nil
                            }
                    )

                // SW resize — bottom-left
                ResizeHandle()
                    .offset(x: -(s.width / 2 + 2), y: s.height / 2 + 2)
                    .gesture(
                        DragGesture(minimumDistance: 1, coordinateSpace: .local)
                            .onChanged { value in
                                AppState.markUserActivity()
                                vm.isResizingRedaction = true
                                if resizeSWStart == nil { resizeSWStart = redaction.rect }
                                guard let start = resizeSWStart else { return }
                                let dx = value.translation.width / canvasSize.width
                                let dh = value.translation.height / canvasSize.height
                                let newX = min(start.maxX - 0.04, start.origin.x + dx)
                                let newW = max(0.04, start.maxX - newX)
                                let newH = max(0.04, start.height + dh)
                                vm.resizeRedaction(id: redaction.id,
                                    newRect: CGRect(x: newX, y: start.origin.y,
                                                    width: newW, height: newH))
                            }
                            .onEnded { _ in
                                vm.isResizingRedaction = false
                                resizeSWStart = nil
                            }
                    )
            }
        }
        .position(x: s.midX, y: s.midY)
        .animation(.easeInOut(duration: 0.12), value: isActive)
    }
}

// MARK: - ResizeHandle

private struct ResizeHandle: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 18, height: 18)
                .shadow(color: .black.opacity(0.35), radius: 3, x: 0, y: 1)
            Circle()
                .stroke(Color(hex: "FFD60A"), lineWidth: 2.5)
                .frame(width: 18, height: 18)
        }
        .contentShape(Circle().scale(1.8))
    }
}
