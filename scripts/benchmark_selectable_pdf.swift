import AppKit
import CoreGraphics
import CoreText
import Foundation
import PDFKit

private struct FixturePage {
    let size: CGSize
    let pageNumber: Int
}

private struct Timed<Value> {
    let value: Value
    let seconds: Double
}

private func measured<T>(_ operation: () throws -> T) rethrows -> Timed<T> {
    let start = DispatchTime.now().uptimeNanoseconds
    let value = try operation()
    let elapsed = DispatchTime.now().uptimeNanoseconds - start
    return Timed(value: value, seconds: Double(elapsed) / 1_000_000_000)
}

private func drawText(_ text: String, at point: CGPoint, size: CGFloat, context: CGContext, bold: Bool = false) {
    let name = bold ? "Helvetica-Bold" : "Helvetica"
    let font = CTFontCreateWithName(name as CFString, size, nil)
    let attributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key(kCTFontAttributeName as String): font,
        NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0.08, alpha: 1)
    ]
    let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
    context.textPosition = point
    CTLineDraw(line, context)
}

private func redactionRect(for page: FixturePage) -> CGRect {
    CGRect(x: 32, y: page.size.height - 151, width: page.size.width - 64, height: 38)
}

private func drawGraphics(for page: FixturePage, in context: CGContext) {
    let width = page.size.width
    let height = page.size.height
    context.setFillColor(CGColor(gray: 0.94, alpha: 1))
    context.fill(CGRect(x: 0, y: height - 85, width: width, height: 20))

    context.setStrokeColor(CGColor(gray: 0.48, alpha: 1))
    context.setLineWidth(0.7)
    context.move(to: CGPoint(x: 32, y: height - 180))
    context.addLine(to: CGPoint(x: width - 32, y: height - 180))
    context.move(to: CGPoint(x: 32, y: 78))
    context.addLine(to: CGPoint(x: width - 32, y: 78))
    context.strokePath()

    // Synthetic scan marks, a table, a stamp and a signature model visible content
    // that a text-only OCR reconstruction would not faithfully preserve.
    context.setStrokeColor(CGColor(gray: 0.67, alpha: 1))
    context.setLineWidth(0.45)
    for column in 0..<5 {
        let x = 32 + CGFloat(column) * (width - 64) / 5
        context.move(to: CGPoint(x: x, y: 245))
        context.addLine(to: CGPoint(x: x, y: 330))
    }
    for row in 0..<4 {
        let y = 245 + CGFloat(row) * 28
        context.move(to: CGPoint(x: 32, y: y))
        context.addLine(to: CGPoint(x: width - 32, y: y))
    }
    context.strokePath()

    let stamp = CGRect(x: width - 116, y: height - 353, width: 64, height: 64)
    context.setStrokeColor(CGColor(red: 0.58, green: 0.16, blue: 0.12, alpha: 1))
    context.setLineWidth(2)
    context.strokeEllipse(in: stamp)
    context.move(to: CGPoint(x: stamp.minX + 9, y: stamp.midY))
    context.addLine(to: CGPoint(x: stamp.maxX - 9, y: stamp.midY))
    context.move(to: CGPoint(x: stamp.midX, y: stamp.minY + 9))
    context.addLine(to: CGPoint(x: stamp.midX, y: stamp.maxY - 9))
    context.strokePath()

    context.setStrokeColor(CGColor(gray: 0.15, alpha: 1))
    context.setLineWidth(2.2)
    context.move(to: CGPoint(x: 48, y: 106))
    context.addCurve(to: CGPoint(x: 183, y: 118), control1: CGPoint(x: 75, y: 148), control2: CGPoint(x: 120, y: 76))
    context.addCurve(to: CGPoint(x: 248, y: 106), control1: CGPoint(x: 204, y: 161), control2: CGPoint(x: 228, y: 81))
    context.strokePath()

    let barcodeOrigin = CGPoint(x: width - 147, y: 96)
    for bar in 0..<36 {
        if (bar * 17 + page.pageNumber * 11) % 5 != 0 {
            let x = barcodeOrigin.x + CGFloat(bar) * 2.3
            context.fill(CGRect(x: x, y: barcodeOrigin.y, width: (bar % 3 == 0 ? 1.5 : 0.8), height: 34))
        }
    }
}

private func drawFixturePage(
    _ page: FixturePage,
    in context: CGContext,
    includeGraphics: Bool,
    includeSensitiveText: Bool,
    drawMask: Bool
) {
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(origin: .zero, size: page.size))

    if includeGraphics { drawGraphics(for: page, in: context) }
    let h = page.size.height
    drawText("MASKID SYNTHETIC DOCUMENT · PAGE \(page.pageNumber)", at: CGPoint(x: 38, y: h - 60), size: 15, context: context, bold: true)
    if includeSensitiveText {
        drawText("ACCOUNT NUMBER: SECRET-4908-5501-2345-6789", at: CGPoint(x: 38, y: h - 136), size: 13, context: context, bold: true)
    }
    drawText("Recipient: Example Customer \(page.pageNumber)", at: CGPoint(x: 38, y: h - 208), size: 12, context: context)
    drawText("Reference: INV-2026-\(String(format: "%04d", page.pageNumber))", at: CGPoint(x: 38, y: h - 232), size: 11, context: context)
    drawText("office affinity efficient · Straße · fiancé · résumé", at: CGPoint(x: 38, y: h - 260), size: 10, context: context)
    drawText("Synthetic QA fixture. Not real personal information.", at: CGPoint(x: 38, y: 52), size: 8, context: context)

    if drawMask {
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.fill(redactionRect(for: page))
    }
}

private func writePDF(at url: URL, pages: [FixturePage], includeGraphics: Bool, includeSensitiveText: Bool, drawMasks: Bool) throws {
    var mediaBox = CGRect(origin: .zero, size: pages[0].size)
    guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
        throw NSError(domain: "SelectablePDFBenchmark", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create PDF context"])
    }
    for page in pages {
        let bounds = CGRect(origin: .zero, size: page.size)
        context.beginPDFPage([kCGPDFContextMediaBox as String: bounds] as CFDictionary)
        drawFixturePage(page, in: context, includeGraphics: includeGraphics, includeSensitiveText: includeSensitiveText, drawMask: drawMasks)
        context.endPDFPage()
    }
    context.closePDF()
}

private func render(_ page: PDFPage, scale: CGFloat, targetSize: CGSize? = nil, mask: CGRect? = nil) throws -> CGImage {
    let bounds = page.bounds(for: .mediaBox).standardized
    let outputSize = targetSize ?? bounds.size
    let width = max(1, Int((outputSize.width * scale).rounded()))
    let height = max(1, Int((outputSize.height * scale).rounded()))
    guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    ) else {
        throw NSError(domain: "SelectablePDFBenchmark", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create render context"])
    }
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    context.scaleBy(x: outputSize.width / bounds.width * scale, y: outputSize.height / bounds.height * scale)
    page.draw(with: .mediaBox, to: context)
    if let mask {
        context.setFillColor(CGColor(gray: 0, alpha: 1))
        context.fill(mask)
    }
    guard let image = context.makeImage() else {
        throw NSError(domain: "SelectablePDFBenchmark", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not finalize render"])
    }
    return image
}

private func makeFlatPDF(source: PDFDocument, pages: [FixturePage], at url: URL, scale: CGFloat) throws {
    let flattened = PDFDocument()
    for index in pages.indices {
        guard let sourcePage = source.page(at: index) else { throw NSError(domain: "SelectablePDFBenchmark", code: 4) }
        let pixels = try render(sourcePage, scale: scale, mask: redactionRect(for: pages[index]))
        let representation = NSBitmapImageRep(cgImage: pixels)
        guard let jpeg = representation.representation(using: .jpeg, properties: [.compressionFactor: 0.94]),
              let image = NSImage(data: jpeg),
              let outputPage = PDFPage(image: image) else {
            throw NSError(domain: "SelectablePDFBenchmark", code: 5, userInfo: [NSLocalizedDescriptionKey: "Could not encode flat page"])
        }
        outputPage.setBounds(CGRect(origin: .zero, size: pages[index].size), for: .mediaBox)
        flattened.insert(outputPage, at: index)
    }
    guard flattened.write(to: url) else { throw NSError(domain: "SelectablePDFBenchmark", code: 6) }
}

private func meanAbsoluteError(_ lhs: CGImage, _ rhs: CGImage) -> Double {
    guard lhs.width == rhs.width, lhs.height == rhs.height,
          let left = lhs.dataProvider?.data as Data?, let right = rhs.dataProvider?.data as Data?,
          left.count == right.count, !left.isEmpty else { return .infinity }
    let a = [UInt8](left)
    let b = [UInt8](right)
    var total = UInt64(0)
    for index in stride(from: 0, to: a.count, by: 4) {
        total += UInt64(abs(Int(a[index]) - Int(b[index])))
        total += UInt64(abs(Int(a[index + 1]) - Int(b[index + 1])))
        total += UInt64(abs(Int(a[index + 2]) - Int(b[index + 2])))
    }
    return Double(total) / Double((a.count / 4) * 3)
}

private func fileSize(_ url: URL) throws -> Int64 {
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    return (attributes[.size] as? NSNumber)?.int64Value ?? 0
}

private func main() throws {
    let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "build/selectable-pdf-benchmark", isDirectory: true)
    try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    let pages = (0..<12).map { index in
        FixturePage(
            size: index.isMultiple(of: 3) ? CGSize(width: 420, height: 595) : CGSize(width: 612, height: 792),
            pageNumber: index + 1
        )
    }
    let sourceURL = outputDirectory.appendingPathComponent("source-selectable.pdf")
    let flatURL = outputDirectory.appendingPathComponent("protected-raster.pdf")
    let reconstructedURL = outputDirectory.appendingPathComponent("protected-selectable-prototype.pdf")

    let sourceTiming = try measured {
        try writePDF(at: sourceURL, pages: pages, includeGraphics: true, includeSensitiveText: true, drawMasks: false)
    }
    guard let source = PDFDocument(url: sourceURL) else { throw NSError(domain: "SelectablePDFBenchmark", code: 7) }

    let flatTiming = try measured { try makeFlatPDF(source: source, pages: pages, at: flatURL, scale: 2) }
    let reconstructionTiming = try measured {
        try writePDF(at: reconstructedURL, pages: pages, includeGraphics: false, includeSensitiveText: false, drawMasks: true)
    }
    guard let flat = PDFDocument(url: flatURL), let reconstructed = PDFDocument(url: reconstructedURL) else {
        throw NSError(domain: "SelectablePDFBenchmark", code: 8)
    }

    var flatErrors: [Double] = []
    var reconstructedErrors: [Double] = []
    for index in pages.indices {
        guard let sourcePage = source.page(at: index), let flatPage = flat.page(at: index), let rebuiltPage = reconstructed.page(at: index) else {
            throw NSError(domain: "SelectablePDFBenchmark", code: 9)
        }
        let reference = try render(sourcePage, scale: 2, targetSize: pages[index].size, mask: redactionRect(for: pages[index]))
        flatErrors.append(meanAbsoluteError(reference, try render(flatPage, scale: 2, targetSize: pages[index].size)))
        reconstructedErrors.append(meanAbsoluteError(reference, try render(rebuiltPage, scale: 2, targetSize: pages[index].size)))
    }

    let sourceText = source.string ?? ""
    let flatText = flat.string ?? ""
    let reconstructedText = reconstructed.string ?? ""
    let secret = "SECRET-4908-5501-2345-6789"
    let report: [String: Any] = [
        "fixture": "12 synthetic pages, mixed page sizes, selectable CoreText source, ligature-prone multilingual text, table/vector marks, stamp, signature and barcode-like marks",
        "redaction": "One account-number line per page is covered by an opaque normalized rectangle",
        "rasterScale": 2,
        "flatPDF": ["bytes": try fileSize(flatURL), "generationSeconds": flatTiming.seconds, "meanAbsoluteRGBError": flatErrors.reduce(0, +) / Double(flatErrors.count), "extractableText": !flatText.isEmpty, "secretSurvivesSearch": flatText.contains(secret)],
        "selectablePrototype": ["bytes": try fileSize(reconstructedURL), "generationSeconds": reconstructionTiming.seconds, "meanAbsoluteRGBError": reconstructedErrors.reduce(0, +) / Double(reconstructedErrors.count), "extractableText": !reconstructedText.isEmpty, "secretSurvivesSearch": reconstructedText.contains(secret), "retainedSafePhrase": reconstructedText.localizedCaseInsensitiveContains("office affinity")],
        "source": ["bytes": try fileSize(sourceURL), "generationSeconds": sourceTiming.seconds, "containsSyntheticSecret": sourceText.contains(secret)],
        "limits": ["not a production OCR or exporter benchmark", "the prototype receives ideal fixture text and exact geometry", "does not cover arbitrary fonts, scanned originals, rotation, attachments, layers, annotations, PDF history or independent OCR"],
        "outputDirectory": outputDirectory.path
    ]
    let json = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
    FileHandle.standardOutput.write(json)
    FileHandle.standardOutput.write(Data([0x0A]))
}

do {
    try main()
} catch {
    fputs("selectable PDF benchmark failed: \(error)\n", stderr)
    exit(1)
}
