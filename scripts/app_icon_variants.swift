import CoreImage
import Foundation
import ImageIO

guard CommandLine.arguments.count == 4 else {
    fputs("Usage: app_icon_variants.swift <source> <dark-output> <tinted-output>\n", stderr)
    exit(EXIT_FAILURE)
}

let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let darkURL = URL(fileURLWithPath: CommandLine.arguments[2])
let tintedURL = URL(fileURLWithPath: CommandLine.arguments[3])

guard
    let source = CIImage(contentsOf: sourceURL),
    let sRGB = CGColorSpace(name: CGColorSpace.sRGB)
else {
    fputs("Could not load source image or sRGB color space.\n", stderr)
    exit(EXIT_FAILURE)
}

let context = CIContext(options: [
    .workingColorSpace: sRGB,
    .outputColorSpace: sRGB
])

func writePNG(_ image: CIImage, to url: URL) throws {
    try context.writePNGRepresentation(
        of: image,
        to: url,
        format: .RGBA8,
        colorSpace: sRGB,
        options: [:]
    )
}

let dark = source.applyingFilter("CIColorControls", parameters: [
    kCIInputSaturationKey: 0.82,
    kCIInputBrightnessKey: -0.10,
    kCIInputContrastKey: 1.05
])

let tinted = source.applyingFilter("CIColorControls", parameters: [
    kCIInputSaturationKey: 0.0,
    kCIInputBrightnessKey: -0.04,
    kCIInputContrastKey: 1.08
])

do {
    try writePNG(dark, to: darkURL)
    try writePNG(tinted, to: tintedURL)
} catch {
    fputs("Could not write variants: \(error)\n", stderr)
    exit(EXIT_FAILURE)
}
