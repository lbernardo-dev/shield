import SwiftUI
import Vision
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - Scan Review + Image Adjustments

enum ScanFilterPreset: String, CaseIterable, Identifiable {
    case original
    case auto
    case blackWhite
    case highContrast

    var id: String { rawValue }

    func label() -> String {
        switch self {
        case .original: return LanguageManager.shared.capture("capture_filter_original")
        case .auto: return LanguageManager.shared.capture("capture_filter_auto")
        case .blackWhite: return LanguageManager.shared.capture("capture_black_white")
        case .highContrast: return LanguageManager.shared.capture("capture_high_contrast")
        }
    }
}

enum ScanAdjustmentPreset: String, CaseIterable, Identifiable {
    case document
    case photo
    case grayscale

    var id: String { rawValue }

    func label() -> String {
        switch self {
        case .document: return LanguageManager.shared.capture("capture_document")
        case .photo: return LanguageManager.shared.capture("capture_photo")
        case .grayscale: return LanguageManager.shared.capture("capture_grayscale_strong")
        }
    }

    func adjustment() -> ScanPageAdjustment {
        switch self {
        case .document:
            return ScanPageAdjustment(
                filterPreset: .auto,
                straightenDegrees: 0,
                rotationDegrees: 0,
                perspectiveTopInset: 0,
                perspectiveBottomInset: 0,
                perspectiveSkew: 0,
                perspectiveTopYOffset: 0,
                perspectiveBottomYOffset: 0,
                cropLeft: 0,
                cropRight: 0,
                cropTop: 0,
                cropBottom: 0,
                brightness: 0.02,
                contrast: 1.25,
                sharpness: 0.4,
                noiseReduction: 0.02
            )
        case .photo:
            return ScanPageAdjustment(
                filterPreset: .original,
                straightenDegrees: 0,
                rotationDegrees: 0,
                perspectiveTopInset: 0,
                perspectiveBottomInset: 0,
                perspectiveSkew: 0,
                perspectiveTopYOffset: 0,
                perspectiveBottomYOffset: 0,
                cropLeft: 0,
                cropRight: 0,
                cropTop: 0,
                cropBottom: 0,
                brightness: 0,
                contrast: 1.08,
                sharpness: 0.18,
                noiseReduction: 0
            )
        case .grayscale:
            return ScanPageAdjustment(
                filterPreset: .highContrast,
                straightenDegrees: 0,
                rotationDegrees: 0,
                perspectiveTopInset: 0,
                perspectiveBottomInset: 0,
                perspectiveSkew: 0,
                perspectiveTopYOffset: 0,
                perspectiveBottomYOffset: 0,
                cropLeft: 0,
                cropRight: 0,
                cropTop: 0,
                cropBottom: 0,
                brightness: 0.05,
                contrast: 1.52,
                sharpness: 0.6,
                noiseReduction: 0.03
            )
        }
    }
}

struct ScanPageAdjustment: Equatable {
    var filterPreset: ScanFilterPreset = .auto
    var straightenDegrees: Double = 0
    var rotationDegrees: Double = 0
    var perspectiveTopInset: Double = 0
    var perspectiveBottomInset: Double = 0
    var perspectiveSkew: Double = 0
    var perspectiveTopYOffset: Double = 0
    var perspectiveBottomYOffset: Double = 0
    var quad: ScanQuad? = nil
    var cropLeft: Double = 0
    var cropRight: Double = 0
    var cropTop: Double = 0
    var cropBottom: Double = 0
    var brightness: Double = 0
    var contrast: Double = 1.0
    var sharpness: Double = 0
    var noiseReduction: Double = 0

    static let `default` = ScanPageAdjustment()

    var hasAdjustments: Bool {
        self != .default
    }
}

extension ScanPageAdjustment {
    init(documentTransform transform: DocumentPageTransform) {
        self.init(
            filterPreset: ScanFilterPreset(rawValue: transform.filterPreset) ?? .original,
            straightenDegrees: transform.straightenDegrees,
            rotationDegrees: transform.rotationDegrees,
            perspectiveTopInset: transform.perspectiveTopInset,
            perspectiveBottomInset: transform.perspectiveBottomInset,
            perspectiveSkew: transform.perspectiveSkew,
            perspectiveTopYOffset: transform.perspectiveTopYOffset,
            perspectiveBottomYOffset: transform.perspectiveBottomYOffset,
            quad: transform.quad.map {
                ScanQuad(
                    topLeft: $0.topLeft,
                    topRight: $0.topRight,
                    bottomLeft: $0.bottomLeft,
                    bottomRight: $0.bottomRight
                )
            },
            cropLeft: transform.cropLeft,
            cropRight: transform.cropRight,
            cropTop: transform.cropTop,
            cropBottom: transform.cropBottom,
            brightness: transform.brightness,
            contrast: transform.contrast,
            sharpness: transform.sharpness,
            noiseReduction: transform.noiseReduction
        )
    }

    var documentTransform: DocumentPageTransform {
        DocumentPageTransform(
            filterPreset: filterPreset.rawValue,
            straightenDegrees: straightenDegrees,
            rotationDegrees: rotationDegrees,
            perspectiveTopInset: perspectiveTopInset,
            perspectiveBottomInset: perspectiveBottomInset,
            perspectiveSkew: perspectiveSkew,
            perspectiveTopYOffset: perspectiveTopYOffset,
            perspectiveBottomYOffset: perspectiveBottomYOffset,
            quad: quad.map {
                DocumentNormalizedQuad(
                    topLeft: $0.topLeft,
                    topRight: $0.topRight,
                    bottomLeft: $0.bottomLeft,
                    bottomRight: $0.bottomRight
                )
            },
            cropLeft: cropLeft,
            cropRight: cropRight,
            cropTop: cropTop,
            cropBottom: cropBottom,
            brightness: brightness,
            contrast: contrast,
            sharpness: sharpness,
            noiseReduction: noiseReduction
        )
    }
}

struct ScanQuad: Equatable {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomLeft: CGPoint
    var bottomRight: CGPoint

    static let identity = ScanQuad(
        topLeft: CGPoint(x: 0.05, y: 0.05),
        topRight: CGPoint(x: 0.95, y: 0.05),
        bottomLeft: CGPoint(x: 0.05, y: 0.95),
        bottomRight: CGPoint(x: 0.95, y: 0.95)
    )
}

nonisolated enum ScanImageProcessor {
    static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func apply(_ image: UIImage, adjustment: ScanPageAdjustment, previewMaxDimension: CGFloat? = nil) -> UIImage? {
        guard let cg = image.cgImage else { return image }
        var ci = CIImage(cgImage: cg)

        if let previewMaxDimension, previewMaxDimension > 0 {
            let extent = ci.extent
            let longestSide = max(extent.width, extent.height)
            if longestSide > previewMaxDimension {
                let scale = previewMaxDimension / longestSide
                ci = ci.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            }
        }

        ci = applyPreset(ci, preset: adjustment.filterPreset)

        if abs(adjustment.straightenDegrees) > 0.001 {
            let angle = adjustment.straightenDegrees * .pi / 180
            ci = ci.applyingFilter("CIStraightenFilter", parameters: [kCIInputAngleKey: angle])
        }

        if hasPerspectiveAdjustments(adjustment) {
            ci = applyPerspective(ci, adjustment: adjustment)
        }

        let extent = ci.extent
        let left = extent.width * adjustment.cropLeft
        let right = extent.width * adjustment.cropRight
        let top = extent.height * adjustment.cropTop
        let bottom = extent.height * adjustment.cropBottom
        let cropRect = CGRect(
            x: extent.minX + left,
            y: extent.minY + bottom,
            width: max(20, extent.width - left - right),
            height: max(20, extent.height - top - bottom)
        )
        ci = ci.cropped(to: cropRect)

        let color = CIFilter.colorControls()
        color.inputImage = ci
        color.brightness = Float(adjustment.brightness)
        color.contrast = Float(adjustment.contrast)
        color.saturation = 1.0
        ci = color.outputImage ?? ci

        if adjustment.sharpness > 0.001 {
            let sharpen = CIFilter.sharpenLuminance()
            sharpen.inputImage = ci
            sharpen.sharpness = Float(adjustment.sharpness)
            sharpen.radius = 0.8
            ci = sharpen.outputImage ?? ci
        }

        if adjustment.noiseReduction > 0.001 {
            let noise = CIFilter.noiseReduction()
            noise.inputImage = ci
            noise.noiseLevel = Float(adjustment.noiseReduction)
            noise.sharpness = 0.4
            ci = noise.outputImage ?? ci
        }

        guard let out = context.createCGImage(ci, from: ci.extent) else { return nil }
        let rendered = UIImage(cgImage: out)

        if abs(adjustment.rotationDegrees) < 0.001 { return rendered }
        return rotate(image: rendered, degrees: adjustment.rotationDegrees)
    }

    private static func applyPreset(_ image: CIImage, preset: ScanFilterPreset) -> CIImage {
        switch preset {
        case .original:
            return image
        case .auto:
            let color = CIFilter.colorControls()
            color.inputImage = image
            color.saturation = 0
            color.brightness = 0.03
            color.contrast = 1.16
            return color.outputImage ?? image
        case .blackWhite:
            let mono = CIFilter.colorControls()
            mono.inputImage = image
            mono.saturation = 0
            mono.brightness = 0.05
            mono.contrast = 1.32
            return mono.outputImage ?? image
        case .highContrast:
            let color = CIFilter.colorControls()
            color.inputImage = image
            color.saturation = 0
            color.brightness = 0.08
            color.contrast = 1.55
            return color.outputImage ?? image
        }
    }

    private static func hasPerspectiveAdjustments(_ adjustment: ScanPageAdjustment) -> Bool {
        adjustment.quad != nil ||
        abs(adjustment.perspectiveTopInset) > 0.0001 ||
        abs(adjustment.perspectiveBottomInset) > 0.0001 ||
        abs(adjustment.perspectiveSkew) > 0.0001 ||
        abs(adjustment.perspectiveTopYOffset) > 0.0001 ||
        abs(adjustment.perspectiveBottomYOffset) > 0.0001
    }

    private static func applyPerspective(_ image: CIImage, adjustment: ScanPageAdjustment) -> CIImage {
        let extent = image.extent
        guard extent.width > 10, extent.height > 10 else { return image }

        if let quad = adjustment.quad {
            let w = extent.width
            let h = extent.height
            let filter = CIFilter.perspectiveCorrection()
            filter.inputImage = image
            filter.topLeft = CGPoint(x: extent.minX + quad.topLeft.x * w, y: extent.minY + (1 - quad.topLeft.y) * h)
            filter.topRight = CGPoint(x: extent.minX + quad.topRight.x * w, y: extent.minY + (1 - quad.topRight.y) * h)
            filter.bottomLeft = CGPoint(x: extent.minX + quad.bottomLeft.x * w, y: extent.minY + (1 - quad.bottomLeft.y) * h)
            filter.bottomRight = CGPoint(x: extent.minX + quad.bottomRight.x * w, y: extent.minY + (1 - quad.bottomRight.y) * h)
            return filter.outputImage ?? image
        }

        let width = extent.width
        let height = extent.height

        let topInset = width * CGFloat(clamp(adjustment.perspectiveTopInset, min: 0, max: 0.42))
        let bottomInset = width * CGFloat(clamp(adjustment.perspectiveBottomInset, min: 0, max: 0.42))
        let skew = width * CGFloat(clamp(adjustment.perspectiveSkew, min: -0.2, max: 0.2))
        let topYOffset = height * CGFloat(clamp(adjustment.perspectiveTopYOffset, min: 0, max: 0.3))
        let bottomYOffset = height * CGFloat(clamp(adjustment.perspectiveBottomYOffset, min: 0, max: 0.3))

        var topLeftX = extent.minX + topInset + max(0, skew)
        var topRightX = extent.maxX - topInset + min(0, skew)
        var bottomLeftX = extent.minX + bottomInset - min(0, skew)
        var bottomRightX = extent.maxX - bottomInset - max(0, skew)

        let minGap = width * 0.25
        if topRightX - topLeftX < minGap {
            let cx = (topRightX + topLeftX) * 0.5
            topLeftX = cx - minGap * 0.5
            topRightX = cx + minGap * 0.5
        }
        if bottomRightX - bottomLeftX < minGap {
            let cx = (bottomRightX + bottomLeftX) * 0.5
            bottomLeftX = cx - minGap * 0.5
            bottomRightX = cx + minGap * 0.5
        }

        let topY = extent.maxY - topYOffset
        let bottomY = extent.minY + bottomYOffset
        guard topY - bottomY > height * 0.25 else { return image }

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = image
        filter.topLeft = CGPoint(x: topLeftX, y: topY)
        filter.topRight = CGPoint(x: topRightX, y: topY)
        filter.bottomLeft = CGPoint(x: bottomLeftX, y: bottomY)
        filter.bottomRight = CGPoint(x: bottomRightX, y: bottomY)
        return filter.outputImage ?? image
    }

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }

    private static func rotate(image: UIImage, degrees: Double) -> UIImage? {
        let radians = CGFloat(degrees * .pi / 180)
        let oldSize = image.size
        let rotatedBounds = CGRect(origin: .zero, size: oldSize)
            .applying(CGAffineTransform(rotationAngle: radians))
        let newSize = CGSize(width: abs(rotatedBounds.width), height: abs(rotatedBounds.height))

        UIGraphicsBeginImageContextWithOptions(newSize, false, image.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return image }
        ctx.translateBy(x: newSize.width * 0.5, y: newSize.height * 0.5)
        ctx.rotate(by: radians)
        image.draw(in: CGRect(x: -oldSize.width / 2, y: -oldSize.height / 2, width: oldSize.width, height: oldSize.height))
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return output
    }
}

struct FourPointPerspectiveEditor: View {
    private enum Corner {
        case topLeft
        case topRight
        case bottomLeft
        case bottomRight
    }

    @Binding var quad: ScanQuad
    let imageSize: CGSize

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Path { path in
                    let tl = point(quad.topLeft, in: geo.size)
                    let tr = point(quad.topRight, in: geo.size)
                    let bl = point(quad.bottomLeft, in: geo.size)
                    let br = point(quad.bottomRight, in: geo.size)
                    path.move(to: tl)
                    path.addLine(to: tr)
                    path.addLine(to: br)
                    path.addLine(to: bl)
                    path.closeSubpath()
                }
                .stroke(ShieldTheme.accentStrong.opacity(0.88), style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))

                handle(position: point(quad.topLeft, in: geo.size), label: "↖") { location in
                    update(.topLeft, with: location, in: geo.size)
                }
                handle(position: point(quad.topRight, in: geo.size), label: "↗") { location in
                    update(.topRight, with: location, in: geo.size)
                }
                handle(position: point(quad.bottomLeft, in: geo.size), label: "↙") { location in
                    update(.bottomLeft, with: location, in: geo.size)
                }
                handle(position: point(quad.bottomRight, in: geo.size), label: "↘") { location in
                    update(.bottomRight, with: location, in: geo.size)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .coordinateSpace(name: "quad-editor")
        }
    }

    private func point(_ normalized: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: normalized.x * size.width, y: normalized.y * size.height)
    }

    private func update(_ corner: Corner, with location: CGPoint, in size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }

        let normalized = CGPoint(
            x: clamp(location.x / size.width, lower: 0, upper: 1),
            y: clamp(location.y / size.height, lower: 0, upper: 1)
        )

        quad = constrainedQuad(for: corner, target: normalized)
    }

    private func constrainedQuad(for corner: Corner, target: CGPoint) -> ScanQuad {
        let margin: CGFloat = 0.04
        var next = quad

        switch corner {
        case .topLeft:
            next.topLeft = CGPoint(
                x: clamp(target.x, lower: 0, upper: next.topRight.x - margin),
                y: clamp(target.y, lower: 0, upper: next.bottomLeft.y - margin)
            )
        case .topRight:
            next.topRight = CGPoint(
                x: clamp(target.x, lower: next.topLeft.x + margin, upper: 1),
                y: clamp(target.y, lower: 0, upper: next.bottomRight.y - margin)
            )
        case .bottomLeft:
            next.bottomLeft = CGPoint(
                x: clamp(target.x, lower: 0, upper: next.bottomRight.x - margin),
                y: clamp(target.y, lower: next.topLeft.y + margin, upper: 1)
            )
        case .bottomRight:
            next.bottomRight = CGPoint(
                x: clamp(target.x, lower: next.bottomLeft.x + margin, upper: 1),
                y: clamp(target.y, lower: next.topRight.y + margin, upper: 1)
            )
        }

        return next
    }

    private func clamp(_ value: CGFloat, lower: CGFloat, upper: CGFloat) -> CGFloat {
        let minValue = Swift.min(lower, upper)
        let maxValue = Swift.max(lower, upper)
        return Swift.max(minValue, Swift.min(maxValue, value))
    }

    @ViewBuilder
    private func handle(position: CGPoint, label: String, onDrag: @escaping (CGPoint) -> Void) -> some View {
        ZStack {
            Circle()
                .fill(ShieldTheme.accentStrong)
                .frame(width: 28, height: 28)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black)
        }
        .position(position)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .named("quad-editor"))
                .onChanged { value in
                    onDrag(value.location)
                }
        )
    }
}

struct ScanReviewView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var scheme
    let pages: [UIImage]
    let initialAdjustments: [ScanPageAdjustment]?
    var onCancel: () -> Void
    var onConfirm: ([UIImage], Bool, [DocumentPageTransform]) -> Void

    init(
        pages: [UIImage],
        initialAdjustments: [ScanPageAdjustment]? = nil,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping ([UIImage], Bool, [DocumentPageTransform]) -> Void
    ) {
        self.pages = pages
        self.initialAdjustments = initialAdjustments
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }

    @State private var selectedPage = 0
    @State private var adjustments: [ScanPageAdjustment] = []
    @State private var applying = false
    @State private var selectedPreset: ScanAdjustmentPreset = .document
    @State private var showQuadEditor = false
    @State private var showAdvancedControls = false
    @State private var processedImage: UIImage? = nil
    @State private var processingTask: Task<Void, Never>? = nil
    @State private var isProcessingImage = false
    @State private var isAdjustingSlider = false
    @State private var renderSequence = 0

    var body: some View {
        GeometryReader { geo in
            let controlsHeight = min(max(geo.size.height * 0.48, 340), 470)
            VStack(spacing: 0) {
                previewArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(spacing: 0) {
                    pageStrip
                    controls
                }
                .frame(width: geo.size.width, height: controlsHeight)
                .background(ShieldTheme.pageBackground(scheme))
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .safeAreaInset(edge: .top, spacing: 0) {
                header(topInset: geo.safeAreaInsets.top)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ShieldTheme.pageBackground(scheme).ignoresSafeArea())
        .preferredColorScheme(appState.preferredScheme)
        .onAppear(perform: setupInitialState)
        .onChange(of: selectedPage) {
            updateProcessedImage()
            autoDetectPerspectiveIfNeeded(for: selectedPage)
        }
        .onChange(of: adjustments) { updateProcessedImage() }
        .onChange(of: showQuadEditor) { updateProcessedImage() }
    }

    private func setupInitialState() {
        selectedPage = 0
        showQuadEditor = false
        showAdvancedControls = false

        if let initial = initialAdjustments, initial.count == pages.count {
            adjustments = initial
        } else {
            adjustments = Array(repeating: .default, count: pages.count)
        }

        updateProcessedImage()
        autoDetectPerspectiveIfNeeded(for: selectedPage)
    }

    private func updateProcessedImage() {
        processingTask?.cancel()

        let image = pages[safe: selectedPage] ?? pages.first ?? UIImage()
        let adjustment = adjustments[safe: selectedPage] ?? .default

        if showQuadEditor {
            processedImage = image
            isProcessingImage = false
            return
        }

        let sequence = renderSequence + 1
        renderSequence = sequence
        isProcessingImage = true
        let previewDimension: CGFloat? = isAdjustingSlider ? 1400 : nil
        let task = Task {
            let result = await Task.detached(priority: .userInitiated) {
                ScanImageProcessor.apply(image, adjustment: adjustment, previewMaxDimension: previewDimension)
            }.value

            let wasCancelled = Task.isCancelled
            await MainActor.run {
                if !wasCancelled, sequence == renderSequence {
                    processedImage = result ?? image
                }
                if sequence == renderSequence {
                    isProcessingImage = false
                }
            }
        }
        processingTask = task
    }

    private func header(topInset: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Button(LanguageManager.shared.capture("capture_cancel")) {
                    onCancel()
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(ShieldTheme.secondary(scheme))

                Spacer()

                if showQuadEditor {
                    Button(LanguageManager.shared.common("common_apply")) {
                        applyManualCrop()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ShieldTheme.accent(scheme))
                }

                Button(applying ? LanguageManager.shared.capture("capture_processing") : LanguageManager.shared.common("common_continue")) {
                    applyAndContinue()
                }
                .disabled(applying || showQuadEditor)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor((applying || showQuadEditor) ? ShieldTheme.tertiary(scheme) : ShieldTheme.accent(scheme))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("\(selectedPage + 1)/\(max(1, pages.count))")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .padding(.horizontal, 10)
                    .frame(height: 32)
                    .background(ShieldTheme.rowBackground(scheme))
                    .overlay(
                        Capsule().stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
                    )
                    .clipShape(Capsule())
                Text(LanguageManager.shared.capture("capture_enhance_title"))
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
                Text(LanguageManager.shared.capture("capture_enhance_subtitle"))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, max(8, topInset > 0 ? 6 : 14))
        .padding(.bottom, 10)
        .background(ShieldTheme.pageBackground(scheme))
    }

    private var previewArea: some View {
        let image = pages[safe: selectedPage] ?? pages.first ?? UIImage()
        let preview = processedImage ?? image

        return ZStack {
            GeometryReader { geo in
                let availableSize = CGSize(
                    width: max(0, geo.size.width - 24),
                    height: max(0, geo.size.height - 24)
                )
                let previewRect = aspectFitRect(for: preview.size, in: availableSize)

                Group {
                    if preview.size.width > 0, preview.size.height > 0 {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(ShieldTheme.cardBackground(scheme))
                                .frame(width: previewRect.width, height: previewRect.height)

                            Image(uiImage: preview)
                                .resizable()
                                .interpolation(.high)
                                .antialiased(true)
                                .aspectRatio(contentMode: .fit)
                                .frame(width: previewRect.width, height: previewRect.height)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            if showQuadEditor {
                                let currentQuad = Binding<ScanQuad>(
                                    get: { adjustments[safe: selectedPage]?.quad ?? .identity },
                                    set: { newQuad in
                                        if selectedPage < adjustments.count {
                                            adjustments[selectedPage].quad = newQuad
                                        }
                                    }
                                )
                                FourPointPerspectiveEditor(quad: currentQuad, imageSize: preview.size)
                                    .frame(width: previewRect.width, height: previewRect.height)
                            }
                        }
                        .frame(width: previewRect.width, height: previewRect.height)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 8)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    } else {
                        ProgressView()
                            .tint(ShieldTheme.accent(scheme))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var pageStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, image in
                    Button {
                        selectedPage = idx
                    } label: {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 68)
                            .clipped()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedPage == idx ? ShieldTheme.accent(scheme) : ShieldTheme.line(scheme), lineWidth: selectedPage == idx ? 2 : 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private var controls: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                presetSection
                filterSection
                quickGeometrySection
                advancedControlsToggle
                if showAdvancedControls {
                    geometrySection
                    cropSection
                    imageSection
                }

                HStack(spacing: 8) {
                    Button {
                        resetCurrentPage()
                } label: {
                    Text(LanguageManager.shared.capture("capture_reset_page"))
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(ShieldTheme.rowBackground(scheme))
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        resetAllPages()
                } label: {
                    Text(LanguageManager.shared.capture("capture_reset_all"))
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(ShieldTheme.rowBackground(scheme))
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                    .buttonStyle(ScaleButtonStyle())
                }

                Button {
                    guard let current = adjustments[safe: selectedPage] else { return }
                    adjustments = Array(repeating: current, count: pages.count)
                    AppState.trackEvent("scan_batch_applied", properties: ["pages": String(pages.count)])
                } label: {
                    Text(LanguageManager.shared.capture("capture_apply_all_pages"))
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(ShieldTheme.accentDim(scheme))
                        .foregroundColor(ShieldTheme.accent(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LanguageManager.shared.capture("capture_quick_presets"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.secondary(scheme))

            optionChips {
                ForEach(ScanAdjustmentPreset.allCases) { preset in
                    optionChip(
                        title: preset.label(),
                        icon: preset == .document ? "doc.text.viewfinder" : (preset == .photo ? "photo" : "circle.lefthalf.filled"),
                        isActive: selectedPreset == preset
                    ) {
                        selectedPreset = preset
                        applyPresetToCurrentPage(preset)
                    }
                }
            }
        }
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LanguageManager.shared.capture("capture_filters"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.secondary(scheme))

            optionChips {
                ForEach(ScanFilterPreset.allCases) { preset in
                    optionChip(
                        title: preset.label(),
                        icon: preset == .original ? "circle" : (preset == .auto ? "sparkles" : "camera.filters"),
                        isActive: binding(\.filterPreset).wrappedValue == preset
                    ) {
                        binding(\.filterPreset).wrappedValue = preset
                    }
                }
            }
        }
    }

    private var geometrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LanguageManager.shared.capture("capture_geometry"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.secondary(scheme))

            if showQuadEditor {
                HStack(spacing: 8) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.accent(scheme))
                    Text(LanguageManager.shared.capture("capture_drag_perspective_hint"))
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.secondary(scheme))
                    Spacer()
                    Button {
                        if selectedPage < adjustments.count {
                            adjustments[selectedPage].quad = .identity
                        }
                    } label: {
                        Text(LanguageManager.shared.capture("capture_reset"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ShieldTheme.danger)
                    }
                }
                .padding(8)
                .background(ShieldTheme.accentDim(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            sliderRow(
                title: LanguageManager.shared.capture("capture_straighten"),
                valueText: "\(Int(binding(\.straightenDegrees).wrappedValue))°"
            ) {
                liveSlider(value: binding(\.straightenDegrees), in: -25...25, step: 1)
            }

            sliderRow(
                title: LanguageManager.shared.capture("capture_top_perspective"),
                valueText: percent(binding(\.perspectiveTopInset).wrappedValue)
            ) {
                liveSlider(value: binding(\.perspectiveTopInset), in: 0...0.3, step: 0.01)
            }

            sliderRow(
                title: LanguageManager.shared.capture("capture_bottom_perspective"),
                valueText: percent(binding(\.perspectiveBottomInset).wrappedValue)
            ) {
                liveSlider(value: binding(\.perspectiveBottomInset), in: 0...0.3, step: 0.01)
            }

            sliderRow(
                title: LanguageManager.shared.capture("capture_horizontal_skew"),
                valueText: signed(binding(\.perspectiveSkew).wrappedValue)
            ) {
                liveSlider(value: binding(\.perspectiveSkew), in: -0.16...0.16, step: 0.005)
            }

            sliderRow(
                title: LanguageManager.shared.capture("capture_top_vertical_trim"),
                valueText: percent(binding(\.perspectiveTopYOffset).wrappedValue)
            ) {
                liveSlider(value: binding(\.perspectiveTopYOffset), in: 0...0.25, step: 0.01)
            }

            sliderRow(
                title: LanguageManager.shared.capture("capture_bottom_vertical_trim"),
                valueText: percent(binding(\.perspectiveBottomYOffset).wrappedValue)
            ) {
                liveSlider(value: binding(\.perspectiveBottomYOffset), in: 0...0.25, step: 0.01)
            }

        }
    }

    private var quickGeometrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LanguageManager.shared.capture("capture_geometry"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.secondary(scheme))

            sliderRow(
                title: LanguageManager.shared.capture("capture_straighten"),
                valueText: "\(Int(binding(\.straightenDegrees).wrappedValue))°"
            ) {
                liveSlider(value: binding(\.straightenDegrees), in: -25...25, step: 1)
            }

            HStack(spacing: 8) {
                Button {
                    detectPerspectiveForCurrentPage()
                } label: {
                    Text(LanguageManager.shared.capture("capture_auto_perspective"))
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(ShieldTheme.rowBackground(scheme))
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                    if !showQuadEditor, adjustments[safe: selectedPage]?.quad == nil,
                       selectedPage < adjustments.count {
                        adjustments[selectedPage].quad = .identity
                    }
                    withAnimation(.spring(response: 0.25)) {
                        if showQuadEditor {
                            applyManualCrop()
                        } else {
                            showQuadEditor = true
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: showQuadEditor ? "checkmark.circle.fill" : "skew")
                            .font(.system(size: 11, weight: .semibold))
                        Text(showQuadEditor
                             ? LanguageManager.shared.capture("capture_apply_crop")
                             : LanguageManager.shared.capture("capture_manual_perspective"))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(showQuadEditor ? ShieldTheme.accentDim(scheme) : ShieldTheme.rowBackground(scheme))
                    .foregroundColor(showQuadEditor ? ShieldTheme.accent(scheme) : ShieldTheme.primary(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())
            }

            HStack(spacing: 8) {
                Button {
                    rotateCurrentPage(by: -90)
                } label: {
                    Text(LanguageManager.shared.capture("capture_rotate_left"))
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(ShieldTheme.rowBackground(scheme))
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                    rotateCurrentPage(by: 90)
                } label: {
                    Text(LanguageManager.shared.capture("capture_rotate_right"))
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(ShieldTheme.rowBackground(scheme))
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private var advancedControlsToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showAdvancedControls.toggle()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: showAdvancedControls ? "slider.horizontal.3" : "slider.horizontal.below.square.and.square.filled")
                    .font(.system(size: 12, weight: .semibold))
                Text(showAdvancedControls
                     ? LanguageManager.shared.capture("capture_hide_advanced_controls")
                     : LanguageManager.shared.capture("capture_show_advanced_controls"))
                    .font(.system(size: 12, weight: .semibold))
                Spacer()
                Image(systemName: showAdvancedControls ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .frame(maxWidth: .infinity)
            .background(ShieldTheme.rowBackground(scheme))
            .foregroundColor(ShieldTheme.secondary(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var cropSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LanguageManager.shared.capture("capture_crop"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.secondary(scheme))

            sliderRow(title: LanguageManager.shared.capture("capture_left"), valueText: percent(binding(\.cropLeft).wrappedValue)) {
                liveSlider(value: binding(\.cropLeft), in: 0...0.35, step: 0.01)
            }
            sliderRow(title: LanguageManager.shared.capture("capture_right"), valueText: percent(binding(\.cropRight).wrappedValue)) {
                liveSlider(value: binding(\.cropRight), in: 0...0.35, step: 0.01)
            }
            sliderRow(title: LanguageManager.shared.capture("capture_top"), valueText: percent(binding(\.cropTop).wrappedValue)) {
                liveSlider(value: binding(\.cropTop), in: 0...0.35, step: 0.01)
            }
            sliderRow(title: LanguageManager.shared.capture("capture_bottom"), valueText: percent(binding(\.cropBottom).wrappedValue)) {
                liveSlider(value: binding(\.cropBottom), in: 0...0.35, step: 0.01)
            }
        }
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LanguageManager.shared.capture("capture_adjustments"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.secondary(scheme))

            sliderRow(title: LanguageManager.shared.capture("capture_brightness"), valueText: signed(binding(\.brightness).wrappedValue)) {
                liveSlider(value: binding(\.brightness), in: -0.3...0.3, step: 0.01)
            }
            sliderRow(title: LanguageManager.shared.capture("capture_contrast"), valueText: String(format: "%.2f", binding(\.contrast).wrappedValue)) {
                liveSlider(value: binding(\.contrast), in: 0.7...1.8, step: 0.01)
            }
            sliderRow(title: LanguageManager.shared.capture("capture_sharpness"), valueText: String(format: "%.2f", binding(\.sharpness).wrappedValue)) {
                liveSlider(value: binding(\.sharpness), in: 0...1.5, step: 0.01)
            }
            sliderRow(title: LanguageManager.shared.capture("capture_noise_reduction"), valueText: String(format: "%.2f", binding(\.noiseReduction).wrappedValue)) {
                liveSlider(value: binding(\.noiseReduction), in: 0...0.08, step: 0.005)
            }
        }
    }

    @ViewBuilder
    private func sliderRow<Content: View>(title: String, valueText: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ShieldTheme.primary(scheme))
                Spacer()
                Text(valueText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }
            content()
        }
        .padding(10)
        .background(ShieldTheme.cardBackground(scheme))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func applyAndContinue() {
        guard !applying else { return }
        applying = true

        Task {
            var output: [UIImage] = []
            output.reserveCapacity(pages.count)

            for (idx, page) in pages.enumerated() {
                let adjustment = adjustments[safe: idx] ?? .default
                output.append(ScanImageProcessor.apply(page, adjustment: adjustment) ?? page)
            }

            let hasAdjustments = adjustments.contains { $0.hasAdjustments }
            await MainActor.run {
                applying = false
                onConfirm(output, hasAdjustments, adjustments.map(\.documentTransform))
            }
        }
    }

    private func applyPresetToCurrentPage(_ preset: ScanAdjustmentPreset) {
        guard adjustments.indices.contains(selectedPage) else { return }
        let base = preset.adjustment()
        adjustments[selectedPage] = sanitizedCrop(base)
        AppState.trackEvent("scan_adjustment_applied", properties: [
            "mode": "preset",
            "preset": preset.rawValue
        ])
    }

    private func resetCurrentPage() {
        guard adjustments.indices.contains(selectedPage) else { return }
        adjustments[selectedPage] = .default
    }

    private func resetAllPages() {
        adjustments = Array(repeating: .default, count: pages.count)
    }

    private func detectPerspectiveForCurrentPage() {
        guard adjustments.indices.contains(selectedPage) else { return }
        guard let image = pages[safe: selectedPage], let cg = image.cgImage else { return }

        Task {
            guard let detected = detectPerspectiveRect(from: cg) else { return }
            await MainActor.run {
                guard adjustments.indices.contains(selectedPage) else { return }
                var adj = adjustments[selectedPage]
                adj.perspectiveTopInset = detected.topInset
                adj.perspectiveBottomInset = detected.bottomInset
                adj.perspectiveSkew = detected.skew
                adj.perspectiveTopYOffset = detected.topYOffset
                adj.perspectiveBottomYOffset = detected.bottomYOffset
                adj.quad = detected.quad
                adjustments[selectedPage] = sanitizedCrop(adj)
                AppState.trackEvent("scan_adjustment_applied", properties: [
                    "mode": "auto_perspective"
                ])
            }
        }
    }

    private func autoDetectPerspectiveIfNeeded(for pageIndex: Int) {
        guard adjustments.indices.contains(pageIndex) else { return }
        let adjustment = adjustments[pageIndex]
        guard adjustment.quad == nil else { return }
        guard adjustment.cropLeft == 0,
              adjustment.cropRight == 0,
              adjustment.cropTop == 0,
              adjustment.cropBottom == 0,
              adjustment.perspectiveTopInset == 0,
              adjustment.perspectiveBottomInset == 0,
              adjustment.perspectiveSkew == 0,
              adjustment.perspectiveTopYOffset == 0,
              adjustment.perspectiveBottomYOffset == 0 else { return }
        guard let image = pages[safe: pageIndex], let cg = image.cgImage else { return }

        Task {
            guard let detected = detectPerspectiveRect(from: cg) else { return }
            await MainActor.run {
                guard adjustments.indices.contains(pageIndex) else { return }
                var adj = adjustments[pageIndex]
                guard adj.quad == nil else { return }
                adj.perspectiveTopInset = detected.topInset
                adj.perspectiveBottomInset = detected.bottomInset
                adj.perspectiveSkew = detected.skew
                adj.perspectiveTopYOffset = detected.topYOffset
                adj.perspectiveBottomYOffset = detected.bottomYOffset
                adj.quad = detected.quad
                adjustments[pageIndex] = sanitizedCrop(adj)
                if pageIndex == selectedPage {
                    updateProcessedImage()
                }
            }
        }
    }

    private func rotateCurrentPage(by degrees: Double) {
        guard adjustments.indices.contains(selectedPage) else { return }

        var adjustment = adjustments[selectedPage]
        adjustment.rotationDegrees = normalizedRightAngle(adjustment.rotationDegrees + degrees)
        adjustment.quad = nil
        adjustment.perspectiveTopInset = 0
        adjustment.perspectiveBottomInset = 0
        adjustment.perspectiveSkew = 0
        adjustment.perspectiveTopYOffset = 0
        adjustment.perspectiveBottomYOffset = 0
        showQuadEditor = false
        adjustments[selectedPage] = sanitizedCrop(adjustment)
    }

    private func applyManualCrop() {
        guard showQuadEditor else { return }
        isAdjustingSlider = false
        withAnimation(.spring(response: 0.25)) {
            showQuadEditor = false
        }
        updateProcessedImage()
    }

    private struct DetectedPerspective {
        let topInset: Double
        let bottomInset: Double
        let skew: Double
        let topYOffset: Double
        let bottomYOffset: Double
        let quad: ScanQuad
    }

    private func detectPerspectiveRect(from cgImage: CGImage) -> DetectedPerspective? {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.45
        request.minimumSize = 0.25
        request.quadratureTolerance = 35

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let rect = request.results?.first else { return nil }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        guard width > 10, height > 10 else { return nil }

        let tl = VNImagePointForNormalizedPoint(rect.topLeft, Int(width), Int(height))
        let tr = VNImagePointForNormalizedPoint(rect.topRight, Int(width), Int(height))
        let bl = VNImagePointForNormalizedPoint(rect.bottomLeft, Int(width), Int(height))
        let br = VNImagePointForNormalizedPoint(rect.bottomRight, Int(width), Int(height))

        let leftTopInset = max(0, tl.x / width)
        let rightTopInset = max(0, (width - tr.x) / width)
        let leftBottomInset = max(0, bl.x / width)
        let rightBottomInset = max(0, (width - br.x) / width)

        let topInset = clamp((leftTopInset + rightTopInset) * 0.5, min: 0, max: 0.3)
        let bottomInset = clamp((leftBottomInset + rightBottomInset) * 0.5, min: 0, max: 0.3)

        let topMid = (tl.x + tr.x) * 0.5
        let bottomMid = (bl.x + br.x) * 0.5
        let skew = clamp((topMid - bottomMid) / width, min: -0.16, max: 0.16)

        let topY = (tl.y + tr.y) * 0.5
        let bottomY = (bl.y + br.y) * 0.5
        let topYOffset = clamp((height - topY) / height, min: 0, max: 0.25)
        let bottomYOffset = clamp(bottomY / height, min: 0, max: 0.25)

        let quad = ScanQuad(
            topLeft: CGPoint(x: clamp(tl.x / width, min: 0, max: 1), y: clamp(1.0 - tl.y / height, min: 0, max: 1)),
            topRight: CGPoint(x: clamp(tr.x / width, min: 0, max: 1), y: clamp(1.0 - tr.y / height, min: 0, max: 1)),
            bottomLeft: CGPoint(x: clamp(bl.x / width, min: 0, max: 1), y: clamp(1.0 - bl.y / height, min: 0, max: 1)),
            bottomRight: CGPoint(x: clamp(br.x / width, min: 0, max: 1), y: clamp(1.0 - br.y / height, min: 0, max: 1))
        )

        return DetectedPerspective(
            topInset: topInset,
            bottomInset: bottomInset,
            skew: skew,
            topYOffset: topYOffset,
            bottomYOffset: bottomYOffset,
            quad: quad
        )
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> Double {
        Double(Swift.max(min, Swift.min(max, value)))
    }

    private func binding<T>(_ keyPath: WritableKeyPath<ScanPageAdjustment, T>) -> Binding<T> {
        Binding(
            get: { adjustments[safe: selectedPage]?[keyPath: keyPath] ?? ScanPageAdjustment.default[keyPath: keyPath] },
            set: { newValue in
                guard adjustments.indices.contains(selectedPage) else { return }
                var adj = adjustments[selectedPage]
                adj[keyPath: keyPath] = newValue
                adjustments[selectedPage] = sanitizedCrop(adj)
            }
        )
    }

    private func sanitizedCrop(_ adjustment: ScanPageAdjustment) -> ScanPageAdjustment {
        var a = adjustment
        let h = a.cropLeft + a.cropRight
        if h > 0.8 {
            let scale = 0.8 / h
            a.cropLeft *= scale
            a.cropRight *= scale
        }
        let v = a.cropTop + a.cropBottom
        if v > 0.8 {
            let scale = 0.8 / v
            a.cropTop *= scale
            a.cropBottom *= scale
        }
        return a
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func signed(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", value))"
    }

    private func normalizedRightAngle(_ value: Double) -> Double {
        let normalized = value.truncatingRemainder(dividingBy: 360)
        switch normalized {
        case ..<(-225): return normalized + 360
        case -225..<(-135): return -180
        case -135..<(-45): return -90
        case -45..<45: return 0
        case 45..<135: return 90
        case 135..<225: return 180
        default: return normalized - 360
        }
    }

    private func liveSlider(value: Binding<Double>, in bounds: ClosedRange<Double>, step: Double) -> some View {
        Slider(
            value: value,
            in: bounds,
            step: step,
            onEditingChanged: { editing in
                isAdjustingSlider = editing
                if !editing {
                    updateProcessedImage()
                }
            }
        )
    }

    @ViewBuilder
    private func optionChips<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                content()
            }
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
    }

    private func optionChip(title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(isActive ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme))
            .foregroundColor(isActive ? ShieldTheme.accentText : ShieldTheme.primary(scheme))
            .overlay(
                Capsule()
                    .stroke(isActive ? ShieldTheme.accentStroke(scheme) : ShieldTheme.line(scheme), lineWidth: isActive ? 1 : 0.8)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func aspectFitRect(for imageSize: CGSize, in containerSize: CGSize) -> CGRect {
        guard imageSize.width > 0,
              imageSize.height > 0,
              containerSize.width > 0,
              containerSize.height > 0 else {
            return CGRect(origin: .zero, size: containerSize)
        }

        let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        return CGRect(
            x: (containerSize.width - fittedSize.width) * 0.5,
            y: (containerSize.height - fittedSize.height) * 0.5,
            width: fittedSize.width,
            height: fittedSize.height
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
