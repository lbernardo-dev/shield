import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - DocumentProcessor Actor

actor DocumentProcessor {
    static let shared = DocumentProcessor()

    private let ciContext = CIContext(options: [
        .useSoftwareRenderer: false,
        .priorityRequestLow: false
    ])

    private init() {}

    // MARK: - Async Image Variant Generation

    func processVariants(for image: UIImage) -> [UIImage] {
        return OCRImagePreprocessor.generateOptimizedVariants(from: image)
    }

    // MARK: - Async Image Filtering

    func applyFilter(
        preset: String,
        to image: UIImage,
        brightness: Double = 0,
        contrast: Double = 1,
        sharpness: Double = 0
    ) -> UIImage? {
        guard let cgImage = image.cgImage else { return image }
        var ci = CIImage(cgImage: cgImage)

        // Color Controls (brightness / contrast)
        let controls = CIFilter.colorControls()
        controls.inputImage = ci
        controls.brightness = Float(brightness)
        controls.contrast = Float(contrast)

        if preset == "grayscale" || preset == "bn" {
            controls.saturation = 0.0
        } else if preset == "highContrast" {
            controls.saturation = 0.0
            controls.contrast = Float(contrast * 1.5)
        }

        if let out = controls.outputImage {
            ci = out
        }

        // Sharpness
        if sharpness > 0 {
            let sharp = CIFilter.sharpenLuminance()
            sharp.inputImage = ci
            sharp.sharpness = Float(sharpness)
            if let out = sharp.outputImage {
                ci = out
            }
        }

        guard let resultCG = ciContext.createCGImage(ci, from: ci.extent) else {
            return image
        }

        return UIImage(cgImage: resultCG, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Async Text Fusion

    func fuseObservations(passes: [[OCRService.TextObservation]]) -> [OCRService.TextObservation] {
        return OCRFusionEngine.fuseObservations(passes: passes)
    }
}
