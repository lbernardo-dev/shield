import SwiftUI
import VisionKit
import PhotosUI
import UniformTypeIdentifiers
import UIKit

// MARK: - DocumentScannerView (VisionKit wrapper)

struct DocumentScannerView: UIViewControllerRepresentable {
    var onScan: ([UIImage]) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView

        init(_ parent: DocumentScannerView) {
            self.parent = parent
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                parent.onCancel()
                return
            }

            var images: [UIImage] = []
            images.reserveCapacity(scan.pageCount)
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            parent.onScan(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.onCancel()
        }
    }
}

// MARK: - DocumentScannerOverlayView

struct DocumentScannerOverlayView: View {
    let documentType: ScanDocumentType
    let showGuide: Bool
    let lang: AppLanguage
    var onScan: ([UIImage]) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            DocumentScannerView(onScan: onScan, onCancel: onCancel)
                .ignoresSafeArea()

            if showGuide && documentType != .freeform {
                GeometryReader { geo in
                    let frameW = geo.size.width * 0.84
                    let frameH = frameW / documentType.aspectRatio
                    let offsetX = (geo.size.width - frameW) / 2
                    let offsetY = (geo.size.height - frameH) / 2

                    ZStack {
                        GuideFrameCutout(
                            frameRect: CGRect(x: offsetX, y: offsetY, width: frameW, height: frameH)
                        )
                        .fill(Color.black.opacity(0.45))
                        .ignoresSafeArea()

                        GuideFrameBorder(
                            x: offsetX, y: offsetY, w: frameW, h: frameH
                        )

                        if !documentType.fieldHints.isEmpty {
                            ForEach(Array(documentType.fieldHints.enumerated()), id: \.offset) { _, hint in
                                let hx = offsetX + hint.normRect.origin.x * frameW
                                let hy = offsetY + hint.normRect.origin.y * frameH
                                let hw = hint.normRect.width * frameW
                                let hh = hint.normRect.height * frameH

                                ZStack(alignment: .topLeading) {
                                    Rectangle()
                                        .strokeBorder(
                                            Color.white.opacity(0.45),
                                            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                                        )
                                        .frame(width: hw, height: hh)

                                    Text(hint.label)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white.opacity(0.85))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.55))
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                        .offset(y: -16)
                                }
                                .position(x: hx + hw / 2, y: hy + hh / 2)
                            }
                        }

                        VStack(spacing: 4) {
                            Text(documentType.label(lang: lang))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(ShieldTheme.accent.opacity(0.85))
                                .clipShape(Capsule())

                            Text(LanguageManager.shared.t("capture_align_hint", table: "Capture"))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        .position(x: geo.size.width / 2, y: offsetY - 44)
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }
}

private struct GuideFrameCutout: Shape {
    let frameRect: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRoundedRect(in: frameRect, cornerSize: CGSize(width: 12, height: 12))
        return path
    }
}

extension GuideFrameCutout {
    func fill(_ content: some ShapeStyle) -> some View {
        self.fill(content, style: FillStyle(eoFill: true))
    }
}

private struct GuideFrameBorder: View {
    let x: CGFloat
    let y: CGFloat
    let w: CGFloat
    let h: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(ShieldTheme.accent, lineWidth: 2)
                .frame(width: w, height: h)
                .position(x: x + w / 2, y: y + h / 2)

            ForEach(corners, id: \.self) { corner in
                cornerTick(at: corner)
            }
        }
    }

    private var corners: [String] { ["tl", "tr", "bl", "br"] }

    private func cornerTick(at corner: String) -> some View {
        let len: CGFloat = 22
        let tl = corner == "tl"
        let tr = corner == "tr"
        let bl = corner == "bl"
        let cx: CGFloat = (tl || bl) ? x : x + w
        let cy: CGFloat = (tl || tr) ? y : y + h
        let hDir: CGFloat = (tl || bl) ? 1 : -1
        let vDir: CGFloat = (tl || tr) ? 1 : -1

        return ZStack {
            Path { p in
                p.move(to: CGPoint(x: cx, y: cy))
                p.addLine(to: CGPoint(x: cx + hDir * len, y: cy))
            }
            .stroke(ShieldTheme.accent, lineWidth: 3)

            Path { p in
                p.move(to: CGPoint(x: cx, y: cy))
                p.addLine(to: CGPoint(x: cx, y: cy + vDir * len))
            }
            .stroke(ShieldTheme.accent, lineWidth: 3)
        }
    }
}

// MARK: - PhotoPickerView (PhotosUI wrapper)

struct PhotoPickerView: UIViewControllerRepresentable {
    var onPick: ([UIImage]) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = CaptureImportLimits.production.maximumPages
        config.preferredAssetRepresentationMode = .compatible
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                parent.onCancel()
                return
            }

            Task { [weak self] in
                var orderedImages: [UIImage] = []
                orderedImages.reserveCapacity(results.count)

                for result in results {
                    guard !Task.isCancelled else { return }
                    if let image = await Self.loadImage(from: result.itemProvider) {
                        orderedImages.append(image)
                    }
                }

                guard let self else { return }
                if orderedImages.isEmpty {
                    parent.onCancel()
                } else {
                    parent.onPick(orderedImages)
                }
            }
        }

        private static func loadImage(from provider: NSItemProvider) async -> UIImage? {
            let typeIdentifier = UTType.image.identifier
            if provider.hasItemConformingToTypeIdentifier(typeIdentifier),
               let data = await withCheckedContinuation({ continuation in
                provider.loadDataRepresentation(forTypeIdentifier: typeIdentifier) { data, _ in
                    continuation.resume(returning: data)
                }
               }),
               let image = CaptureImportPipeline.downsampleImage(
                    data: data,
                    maximumDimension: CaptureImportLimits.production.maximumPixelDimension
               ) {
                return image
            }

            guard provider.canLoadObject(ofClass: UIImage.self) else { return nil }
            return await loadUIImage(from: provider)
        }

        private static func loadUIImage(from provider: NSItemProvider) async -> UIImage? {
            await withCheckedContinuation { continuation in
                provider.loadObject(ofClass: UIImage.self) { object, _ in
                    continuation.resume(returning: object as? UIImage)
                }
            }
        }
    }
}

// MARK: - FilesPickerView (UIDocumentPickerViewController wrapper)

struct FilesPickerView: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .image, .jpeg, .png, .tiff]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilesPickerView

        init(_ parent: FilesPickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else {
                parent.onCancel()
                return
            }
            parent.onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel()
        }
    }
}

// MARK: - Image Normalization

extension UIImage {
    nonisolated func normalizedForShield() -> UIImage {
        if self.imageOrientation == .up && self.cgImage != nil {
            return self
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        let renderer = UIGraphicsImageRenderer(size: self.size, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: self.size))
        }
    }
}
