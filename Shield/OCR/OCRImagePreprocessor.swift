import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - OCRImagePreprocessor

enum OCRImagePreprocessor {
    private static let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .priorityRequestLow: false
    ])

    enum PreprocessMode: String, CaseIterable, Identifiable, Sendable {
        case shadowRemoval
        case adaptiveContrast
        case documentBinarization
        case edgeEnhancement

        var id: String { rawValue }
    }

    /// Generates high-accuracy pre-processed image variants optimized for OCR recognition.
    static func generateOptimizedVariants(
        from image: UIImage,
        includeRotations: Bool = false
    ) -> [UIImage] {
        guard let cgImage = image.cgImage else { return [] }
        let ciImage = CIImage(cgImage: cgImage)
        var variants: [UIImage] = []

        func render(_ ci: CIImage) -> UIImage? {
            guard let out = ciContext.createCGImage(ci, from: ci.extent) else { return nil }
            return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
        }

        // 1. Shadow Removal & Background Equalization
        if let shadowRemoved = removeShadows(from: ciImage),
           let rendered = render(shadowRemoved) {
            variants.append(rendered)
        }

        // 2. Adaptive High-Contrast & Sharpen (for low-light and patterned backgrounds)
        if let highContrast = enhanceAdaptiveContrast(from: ciImage),
           let rendered = render(highContrast) {
            variants.append(rendered)
        }

        // 3. Document Binarization & Tone Flattening (for fine text and MRZ zones)
        if let binarized = binarizeDocument(from: ciImage),
           let rendered = render(binarized) {
            variants.append(rendered)
        }

        // 4. If requested (e.g. low initial confidence), generate orientation variants
        if includeRotations {
            let orientations: [CGImagePropertyOrientation] = [.right, .left, .down]
            for orient in orientations {
                let rotatedCI = ciImage.oriented(orient)
                if let rendered = render(rotatedCI) {
                    variants.append(rendered)
                }
            }
        }

        return variants
    }

    /// Removes phone shadows, flash glare, and gradient lighting from document surfaces.
    private static func removeShadows(from ciImage: CIImage) -> CIImage? {
        // Grayscale conversion
        let grayscale = CIFilter.colorControls()
        grayscale.inputImage = ciImage
        grayscale.saturation = 0.0
        grayscale.contrast = 1.15
        guard let grayCI = grayscale.outputImage else { return nil }

        // Background estimation using large box blur
        let blur = CIFilter.boxBlur()
        blur.inputImage = grayCI
        blur.radius = 28.0
        guard let blurredCI = blur.outputImage else { return grayCI }

        // Divide original grayscale by blurred background (high-pass filter for text)
        let blend = CIFilter.colorDodgeBlendMode()
        blend.inputImage = grayCI
        blend.backgroundImage = blurredCI
        guard let dodgeCI = blend.outputImage else { return grayCI }

        // Re-enhance contrast of extracted text
        let finalContrast = CIFilter.colorControls()
        finalContrast.inputImage = dodgeCI
        finalContrast.contrast = 1.35
        finalContrast.brightness = -0.05
        return finalContrast.outputImage ?? grayCI
    }

    /// Enhances micro-contrast and sharpens edges of security document characters.
    private static func enhanceAdaptiveContrast(from ciImage: CIImage) -> CIImage? {
        let controls = CIFilter.colorControls()
        controls.inputImage = ciImage
        controls.saturation = 0.0
        controls.brightness = 0.04
        controls.contrast = 1.55
        guard let contrastCI = controls.outputImage else { return nil }

        let sharpen = CIFilter.sharpenLuminance()
        sharpen.inputImage = contrastCI
        sharpen.sharpness = 0.65
        return sharpen.outputImage ?? contrastCI
    }

    /// High-pass adaptive binarization for MRZ (Machine Readable Zone) and dense numeric fields.
    private static func binarizeDocument(from ciImage: CIImage) -> CIImage? {
        let monochrome = CIFilter.colorMonochrome()
        monochrome.inputImage = ciImage
        monochrome.color = CIColor(red: 0.5, green: 0.5, blue: 0.5)
        monochrome.intensity = 1.0
        guard let monoCI = monochrome.outputImage else { return nil }

        let exposure = CIFilter.exposureAdjust()
        exposure.inputImage = monoCI
        exposure.ev = 0.4
        guard let expCI = exposure.outputImage else { return monoCI }

        let contrast = CIFilter.colorControls()
        contrast.inputImage = expCI
        contrast.contrast = 1.85
        contrast.brightness = -0.08
        return contrast.outputImage ?? monoCI
    }
}
