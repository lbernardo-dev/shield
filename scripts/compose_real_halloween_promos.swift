import AppKit
import CoreGraphics
import Foundation

struct PromoSpec {
    let background: String
    let screenshot: String
    let output: String
    let title: String
    let subtitle: String
    let eventLabel: String
    let hideTopLeftSystemLink: Bool
}

let root = FileManager.default.currentDirectoryPath
let baseIcon = "\(root)/Shield/Resources/Assets.xcassets/AppIcon.appiconset/icon_1024.png"
let halloweenIcon = "\(root)/Shield/Resources/Assets.xcassets/MaskIDHalloween.appiconset/icon_1024.png"
let background = "\(root)/Shield/Resources/Assets.xcassets/SeasonalThemeBackdrop.imageset/seasonal-theme-backdrop.png"

let specs = [
    PromoSpec(
        background: background,
        screenshot: "/private/tmp/maskid-halloween-iphone18pro-clean.png",
        output: "\(root)/Marketing/Social/Halloween-2026/maskid-halloween-real-es.png",
        title: "HALLOWEEN EN MASKID",
        subtitle: "Tu identidad, bajo tu propia máscara.",
        eventLabel: "EVENTO DE TEMPORADA",
        hideTopLeftSystemLink: false
    ),
    PromoSpec(
        background: background,
        screenshot: "/private/tmp/maskid-halloween-iphone18pro-en-clean.png",
        output: "\(root)/Marketing/Social/Halloween-2026/maskid-halloween-real-en.png",
        title: "MASKID AFTER DARK",
        subtitle: "Privacy takes the night shift.",
        eventLabel: "SEASONAL EVENT",
        hideTopLeftSystemLink: true
    )
]

let canvasSize = NSSize(width: 1080, height: 1350)

func loadImage(_ path: String) -> CGImage {
    let url = URL(fileURLWithPath: path) as CFURL
    guard let source = CGImageSourceCreateWithURL(url, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        fatalError("Could not load image: \(path)")
    }
    return image
}

func croppedToAspectFill(_ image: CGImage, target: CGRect) -> CGImage {
    let width = CGFloat(image.width)
    let height = CGFloat(image.height)
    let sourceAspect = width / height
    let targetAspect = target.width / target.height
    var crop = CGRect(x: 0, y: 0, width: width, height: height)
    if sourceAspect > targetAspect {
        let cropWidth = height * targetAspect
        crop.origin.x = (width - cropWidth) / 2
        crop.size.width = cropWidth
    } else {
        let cropHeight = width / targetAspect
        crop.origin.y = (height - cropHeight) / 2
        crop.size.height = cropHeight
    }
    return image.cropping(to: crop.integral) ?? image
}

func draw(_ image: CGImage, in rect: CGRect, alpha: CGFloat = 1) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    context.setAlpha(alpha)
    NSImage(cgImage: image, size: NSSize(width: rect.width, height: rect.height)).draw(
        in: rect,
        from: .zero,
        operation: .sourceOver,
        fraction: alpha
    )
    context.restoreGState()
}

func drawAspectFill(_ image: CGImage, in rect: CGRect) {
    draw(croppedToAspectFill(image, target: rect), in: rect)
}

func drawRounded(_ image: CGImage, in rect: CGRect, radius: CGFloat, stroke: NSColor? = nil) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -18), blur: 28, color: NSColor.black.withAlphaComponent(0.70).cgColor)
    context.addPath(path)
    context.setFillColor(NSColor.black.cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(path)
    context.clip()
    draw(image, in: rect)
    context.restoreGState()

    if let stroke {
        context.saveGState()
        context.addPath(path)
        context.setStrokeColor(stroke.cgColor)
        context.setLineWidth(3)
        context.strokePath()
        context.restoreGState()
    }
}

func drawText(_ text: String, at point: CGPoint, font: NSFont, color: NSColor, alignment: NSTextAlignment = .left) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = alignment
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: color,
        .paragraphStyle: paragraph
    ]
    NSAttributedString(string: text, attributes: attributes).draw(at: point)
}

func drawPill(_ text: String, rect: CGRect) {
    NSColor(calibratedWhite: 0.04, alpha: 0.78).setFill()
    NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2).fill()
    NSColor(calibratedRed: 1.0, green: 0.55, blue: 0.14, alpha: 0.82).setStroke()
    let border = NSBezierPath(roundedRect: rect, xRadius: rect.height / 2, yRadius: rect.height / 2)
    border.lineWidth = 1.5
    border.stroke()
    drawText(
        text,
        at: CGPoint(x: rect.midX, y: rect.minY + 9),
        font: NSFont.systemFont(ofSize: 18, weight: .semibold),
        color: NSColor(calibratedRed: 1.0, green: 0.72, blue: 0.40, alpha: 1),
        alignment: .center
    )
}

func drawTransition(from start: CGPoint, to end: CGPoint, warm: NSColor) {
    guard let context = NSGraphicsContext.current?.cgContext else { return }
    context.saveGState()
    let path = CGMutablePath()
    path.move(to: start)
    path.addCurve(
        to: end,
        control1: CGPoint(x: start.x + 145, y: start.y + 62),
        control2: CGPoint(x: end.x - 145, y: end.y - 62)
    )
    context.addPath(path)
    context.setStrokeColor(warm.withAlphaComponent(0.92).cgColor)
    context.setLineWidth(6)
    context.setLineCap(.round)
    context.setShadow(offset: .zero, blur: 14, color: warm.withAlphaComponent(0.85).cgColor)
    context.strokePath()

    let angle = atan2(end.y - start.y, end.x - start.x)
    let size: CGFloat = 17
    let left = CGPoint(x: end.x - size * cos(angle - .pi / 6), y: end.y - size * sin(angle - .pi / 6))
    let right = CGPoint(x: end.x - size * cos(angle + .pi / 6), y: end.y - size * sin(angle + .pi / 6))
    let arrow = CGMutablePath()
    arrow.move(to: end)
    arrow.addLine(to: left)
    arrow.addLine(to: right)
    arrow.closeSubpath()
    context.addPath(arrow)
    context.setFillColor(warm.cgColor)
    context.fillPath()
    context.restoreGState()
}

func drawPromo(_ spec: PromoSpec) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(canvasSize.width),
        pixelsHigh: Int(canvasSize.height),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bitmapFormat: [],
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    let graphics = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = graphics

    NSColor(calibratedRed: 0.035, green: 0.018, blue: 0.055, alpha: 1).setFill()
    NSBezierPath(rect: NSRect(origin: .zero, size: canvasSize)).fill()
    drawAspectFill(loadImage(spec.background), in: CGRect(origin: .zero, size: canvasSize))

    if let context = NSGraphicsContext.current?.cgContext {
        context.saveGState()
        context.setFillColor(NSColor.black.withAlphaComponent(0.36).cgColor)
        context.fill(CGRect(origin: .zero, size: canvasSize))
        let colors = [
            NSColor.black.withAlphaComponent(0.68).cgColor,
            NSColor.clear.cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.48])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: 600), options: [])
        context.restoreGState()
    }

    drawPill(spec.eventLabel, rect: CGRect(x: 72, y: 1256, width: 240, height: 36))
    drawText(spec.title, at: CGPoint(x: 72, y: 1168), font: NSFont.systemFont(ofSize: 54, weight: .heavy), color: .white)
    drawText(spec.subtitle, at: CGPoint(x: 74, y: 1122), font: NSFont.systemFont(ofSize: 26, weight: .medium), color: NSColor(calibratedRed: 0.85, green: 0.73, blue: 1.0, alpha: 1))

    let base = loadImage(baseIcon)
    let seasonal = loadImage(halloweenIcon)
    let iconSize: CGFloat = 152
    let baseRect = CGRect(x: 72, y: 948, width: iconSize, height: iconSize)
    let seasonalRect = CGRect(x: 856, y: 948, width: iconSize, height: iconSize)
    drawRounded(base, in: baseRect, radius: 34, stroke: NSColor(calibratedRed: 0.20, green: 0.75, blue: 1.0, alpha: 0.75))
    drawRounded(seasonal, in: seasonalRect, radius: 34, stroke: NSColor(calibratedRed: 1.0, green: 0.48, blue: 0.10, alpha: 0.88))
    drawText("ORIGINAL", at: CGPoint(x: baseRect.midX, y: 919), font: NSFont.systemFont(ofSize: 17, weight: .semibold), color: NSColor.white.withAlphaComponent(0.86), alignment: .center)
    drawText("HALLOWEEN", at: CGPoint(x: seasonalRect.midX, y: 919), font: NSFont.systemFont(ofSize: 17, weight: .semibold), color: NSColor(calibratedRed: 1.0, green: 0.70, blue: 0.36, alpha: 1), alignment: .center)
    drawTransition(from: CGPoint(x: baseRect.maxX + 18, y: baseRect.midY), to: CGPoint(x: seasonalRect.minX - 18, y: seasonalRect.midY), warm: NSColor(calibratedRed: 1.0, green: 0.50, blue: 0.16, alpha: 1))

    let screenshot = loadImage(spec.screenshot)
    let phoneFrame = CGRect(x: 309, y: 34, width: 462, height: 874)
    let screenRect = CGRect(x: 326, y: 51, width: 428, height: 840)
    if let context = NSGraphicsContext.current?.cgContext {
        context.saveGState()
        let framePath = CGPath(roundedRect: phoneFrame, cornerWidth: 62, cornerHeight: 62, transform: nil)
        context.addPath(framePath)
        context.setFillColor(NSColor(calibratedWhite: 0.02, alpha: 0.98).cgColor)
        context.setShadow(offset: CGSize(width: 0, height: -24), blur: 32, color: NSColor.black.withAlphaComponent(0.82).cgColor)
        context.fillPath()
        context.restoreGState()
    }
    drawRounded(screenshot, in: screenRect, radius: 50, stroke: NSColor(calibratedWhite: 1, alpha: 0.22))
    if spec.hideTopLeftSystemLink {
        let maskRect = CGRect(x: screenRect.minX + 2, y: screenRect.maxY - 76, width: 122, height: 66)
        NSColor(calibratedRed: 0.035, green: 0.018, blue: 0.055, alpha: 1).setFill()
        NSBezierPath(roundedRect: maskRect, xRadius: 20, yRadius: 20).fill()
    }
    if let context = NSGraphicsContext.current?.cgContext {
        context.saveGState()
        context.setFillColor(NSColor(calibratedWhite: 0.98, alpha: 0.82).cgColor)
        context.fill(CGRect(x: phoneFrame.midX - 58, y: phoneFrame.maxY - 24, width: 116, height: 7))
        context.restoreGState()
    }

    NSGraphicsContext.restoreGraphicsState()
    guard let data = rep.representation(using: .png, properties: [:]) else { fatalError("Could not encode PNG") }
    let outputURL = URL(fileURLWithPath: spec.output)
    try? FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    do {
        try data.write(to: outputURL)
        print("Wrote \(spec.output)")
    } catch {
        fatalError("Could not write \(spec.output): \(error)")
    }
}

for spec in specs {
    drawPromo(spec)
}
