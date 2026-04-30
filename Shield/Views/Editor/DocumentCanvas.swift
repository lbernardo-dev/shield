import SwiftUI

// MARK: - DocumentCanvas
// Interactive canvas for drawing, moving, and resizing redactions.

struct DocumentCanvas: View {
    @ObservedObject var vm: EditorViewModel
    let canvasSize: CGSize

    // Drag state for moving active redaction
    @State private var dragOffset: CGSize = .zero
    @State private var dragStartRect: CGRect? = nil

    var body: some View {
        ZStack {
            // Document render
            DocumentView(
                kind: vm.doc.kind,
                size: canvasSize,
                fields: vm.doc.fields,
                redactions: vm.redactions,
                watermark: vm.watermark,
                showFieldOverlays: vm.tool == .fields || vm.showFieldOverlays,
                imageFileName: vm.currentImageFileName,
                isVaulted: vm.doc.isVaulted
            )

            // Active drawing rect preview
            if let drawRect = vm.drawingRect {
                let scaled = CGRect(
                    x: drawRect.origin.x * canvasSize.width,
                    y: drawRect.origin.y * canvasSize.height,
                    width: drawRect.width * canvasSize.width,
                    height: drawRect.height * canvasSize.height
                )
                Rectangle()
                    .fill(Color(hex: "FFD60A").opacity(0.25))
                    .overlay(
                        Rectangle()
                            .stroke(Color(hex: "FFD60A"), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                    )
                    .frame(width: scaled.width, height: scaled.height)
                    .position(x: scaled.midX, y: scaled.midY)
                    .allowsHitTesting(false)
            }

            // Field tap overlay (when tool == .fields)
            if vm.tool == .fields {
                ForEach(DocumentFieldBoxes.boxes(for: vm.doc.kind)) { box in
                    let r = box.rect
                    let scaledRect = CGRect(
                        x: r.origin.x * canvasSize.width,
                        y: r.origin.y * canvasSize.height,
                        width: r.width * canvasSize.width,
                        height: r.height * canvasSize.height
                    )
                    let isSelected = vm.redactions.contains { redact in
                        abs(redact.rect.origin.x - r.origin.x) < 0.01 &&
                        abs(redact.rect.origin.y - r.origin.y) < 0.01
                    }
                    ZStack(alignment: .topLeading) {
                        Rectangle()
                            .fill(isSelected ? ShieldTheme.success.opacity(0.20) : Color.clear)
                            .overlay(
                                Rectangle()
                                    .stroke(
                                        isSelected ? ShieldTheme.success : Color(hex: "FFD60A"),
                                        style: StrokeStyle(lineWidth: 1.5, dash: isSelected ? [] : [3, 2])
                                    )
                            )
                            .frame(width: scaledRect.width, height: scaledRect.height)
                            .onTapGesture { vm.toggleField(box) }
                        Text((isSelected ? "✓ " : "") + box.label)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(isSelected ? ShieldTheme.success : Color(hex: "FFD60A"))
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.black.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .offset(y: -18)
                    }
                    .position(x: scaledRect.midX, y: scaledRect.midY)
                }
            }

            // Redaction overlays: tap-to-select, drag-to-move, corner-to-resize, delete
            ForEach(vm.redactions) { redaction in
                let isActive = vm.activeRedactionID == redaction.id
                let r = redaction.rect
                let scaledRect = CGRect(
                    x: r.origin.x * canvasSize.width,
                    y: r.origin.y * canvasSize.height,
                    width: r.width * canvasSize.width,
                    height: r.height * canvasSize.height
                )

                ZStack {
                    // Invisible tap target covering the redaction area
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: scaledRect.width, height: scaledRect.height)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                vm.activeRedactionID = isActive ? nil : redaction.id
                            }
                        }
                        .gesture(
                            isActive ? DragGesture(minimumDistance: 3)
                                .onChanged { value in
                                    AppState.markUserActivity()
                                    vm.isDraggingRedaction = true
                                    if dragStartRect == nil { dragStartRect = r }
                                    guard let start = dragStartRect else { return }
                                    let dx = value.translation.width / canvasSize.width
                                    let dy = value.translation.height / canvasSize.height
                                    let newX = max(0, min(1 - start.width, start.origin.x + dx))
                                    let newY = max(0, min(1 - start.height, start.origin.y + dy))
                                    vm.resizeRedaction(id: redaction.id,
                                        newRect: CGRect(x: newX, y: newY, width: start.width, height: start.height))
                                }
                                .onEnded { _ in
                                    vm.isDraggingRedaction = false
                                    dragStartRect = nil
                                }
                            : nil
                        )

                    // Active selection ring
                    if isActive {
                        Rectangle()
                            .stroke(Color(hex: "FFD60A"), lineWidth: 2)
                            .frame(width: scaledRect.width + 6, height: scaledRect.height + 6)

                        // Delete button (top-right)
                        Button {
                            vm.removeRedaction(id: redaction.id)
                        } label: {
                            ZStack {
                                Circle().fill(ShieldTheme.danger).frame(width: 24, height: 24)
                                Circle().stroke(Color.white, lineWidth: 2).frame(width: 24, height: 24)
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                            }
                        }
                        .offset(x: scaledRect.width / 2 + 8, y: -(scaledRect.height / 2 + 8))

                        // SE resize handle (bottom-right corner)
                        ResizeHandle()
                            .offset(x: scaledRect.width / 2 + 2, y: scaledRect.height / 2 + 2)
                            .gesture(
                                DragGesture(minimumDistance: 2)
                                    .onChanged { value in
                                        AppState.markUserActivity()
                                        vm.isResizingRedaction = true
                                        let dw = value.translation.width / canvasSize.width
                                        let dh = value.translation.height / canvasSize.height
                                        let newW = max(0.04, r.width + dw)
                                        let newH = max(0.04, r.height + dh)
                                        vm.resizeRedaction(id: redaction.id,
                                            newRect: CGRect(x: r.origin.x, y: r.origin.y,
                                                            width: newW, height: newH))
                                    }
                                    .onEnded { _ in vm.isResizingRedaction = false }
                            )

                        // SW resize handle (bottom-left)
                        ResizeHandle()
                            .offset(x: -(scaledRect.width / 2 + 2), y: scaledRect.height / 2 + 2)
                            .gesture(
                                DragGesture(minimumDistance: 2)
                                    .onChanged { value in
                                        AppState.markUserActivity()
                                        vm.isResizingRedaction = true
                                        let dx = value.translation.width / canvasSize.width
                                        let dh = value.translation.height / canvasSize.height
                                        let newX = min(r.maxX - 0.04, r.origin.x + dx)
                                        let newW = max(0.04, r.maxX - newX)
                                        let newH = max(0.04, r.height + dh)
                                        vm.resizeRedaction(id: redaction.id,
                                            newRect: CGRect(x: newX, y: r.origin.y,
                                                            width: newW, height: newH))
                                    }
                                    .onEnded { _ in vm.isResizingRedaction = false }
                            )
                    }
                }
                .position(x: scaledRect.midX, y: scaledRect.midY)
                .animation(.easeInOut(duration: 0.12), value: isActive)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .gesture(
            DragGesture(minimumDistance: 3)
                .onChanged { value in
                    guard !vm.isDraggingRedaction, !vm.isResizingRedaction else { return }
                    AppState.markUserActivity()
                    let loc = value.location
                    let norm = CGPoint(x: loc.x / canvasSize.width, y: loc.y / canvasSize.height)
                    if vm.drawingStart == nil {
                        vm.beginDraw(at: norm)
                    } else {
                        vm.updateDraw(to: norm)
                    }
                }
                .onEnded { _ in
                    guard !vm.isDraggingRedaction, !vm.isResizingRedaction else { return }
                    vm.endDraw()
                }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                AppState.markUserActivity()
                if !vm.isDraggingRedaction { vm.activeRedactionID = nil }
            }
        )
    }
}

// MARK: - ResizeHandle

private struct ResizeHandle: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 14, height: 14)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
            Circle()
                .stroke(Color(hex: "FFD60A"), lineWidth: 2)
                .frame(width: 14, height: 14)
        }
    }
}
