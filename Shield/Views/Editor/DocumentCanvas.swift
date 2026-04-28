import SwiftUI

// MARK: - DocumentCanvas
// Interactive canvas for drawing and viewing redactions

struct DocumentCanvas: View {
    @ObservedObject var vm: EditorViewModel
    let canvasSize: CGSize

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

            // Active drawing rect
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
                            .fill(isSelected ? ShieldTheme.success.opacity(0.20) : Color(hex: "FFD60A").opacity(0.0))
                            .overlay(
                                Rectangle()
                                    .stroke(
                                        isSelected ? ShieldTheme.success : Color(hex: "FFD60A"),
                                        style: StrokeStyle(lineWidth: 1.5, dash: isSelected ? [] : [3, 2])
                                    )
                            )
                            .frame(width: scaledRect.width, height: scaledRect.height)
                            .onTapGesture {
                                vm.toggleField(box)
                            }

                        // Field label
                        Text((isSelected ? "✓ " : "") + box.label)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(isSelected ? ShieldTheme.success : Color(hex: "FFD60A"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .offset(y: -18)
                    }
                    .position(x: scaledRect.midX, y: scaledRect.midY)
                }
            }

            // Redaction selection handles
            ForEach(vm.redactions) { redaction in
                let r = redaction.rect
                let scaledRect = CGRect(
                    x: r.origin.x * canvasSize.width,
                    y: r.origin.y * canvasSize.height,
                    width: r.width * canvasSize.width,
                    height: r.height * canvasSize.height
                )
                let isActive = vm.activeRedactionID == redaction.id

                // Tap target
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: scaledRect.width, height: scaledRect.height)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            vm.activeRedactionID = isActive ? nil : redaction.id
                        }
                    }
                    .position(x: scaledRect.midX, y: scaledRect.midY)

                // Active handle border
                if isActive {
                    Rectangle()
                        .stroke(Color(hex: "FFD60A"), lineWidth: 1.5)
                        .frame(width: scaledRect.width + 8, height: scaledRect.height + 8)
                        .overlay(alignment: .topTrailing) {
                            Button {
                                vm.removeRedaction(id: redaction.id)
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(ShieldTheme.danger)
                                        .frame(width: 22, height: 22)
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 22, height: 22)
                                    Image(systemName: "xmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .offset(x: 10, y: -10)
                            }
                        }
                        .allowsHitTesting(isActive)
                        .position(x: scaledRect.midX, y: scaledRect.midY)
                        .animation(.easeInOut(duration: 0.15), value: isActive)
                }
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .gesture(
            DragGesture(minimumDistance: 2)
                .onChanged { value in
                    let loc = value.location
                    let norm = CGPoint(
                        x: loc.x / canvasSize.width,
                        y: loc.y / canvasSize.height
                    )
                    if vm.drawingStart == nil {
                        vm.beginDraw(at: norm)
                    } else {
                        vm.updateDraw(to: norm)
                    }
                }
                .onEnded { _ in
                    vm.endDraw()
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    vm.activeRedactionID = nil
                }
        )
    }
}
