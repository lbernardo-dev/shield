import SwiftUI
import UIKit
import PDFKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - ExportEngine

enum ExportEngine {
    enum ExportError: LocalizedError {
        case noPages
        case sourceUnavailable(page: Int)
        case protectedPDF
        case cancelled
        case verificationFailed

        var errorDescription: String? {
            switch self {
            case .noPages: "The document has no exportable pages."
            case .sourceUnavailable(let page): "Page \(page + 1) could not be loaded."
            case .protectedPDF: "The source PDF is locked or password protected."
            case .cancelled: "The export was cancelled."
            case .verificationFailed: "The exported PDF did not pass the security verification."
            }
        }
    }

    static func exportAsPDF(
        doc: DocumentItem,
        pageRedactions: [Int: [Redaction]],
        watermark: Watermark?,
        scale: CGFloat,
        progress: @escaping (Double) -> Void = { _ in }
    ) async throws -> SecurePDFExport {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("shield_\(doc.id)_\(UUID().uuidString).pdf")

        do {
            let pageFiles = doc.pageFileNames ?? [doc.imageFileName].compactMap { $0 }
            let sourcePDF: PDFDocument?
            let vectorPage: UIImage?
            let expectedPageCount: Int

            if !pageFiles.isEmpty {
                sourcePDF = nil
                vectorPage = nil
                expectedPageCount = pageFiles.count
            } else if doc.sourceType == .pdf,
                      let sourceFileName = doc.sourceFileName,
                      let pdfData = AppState.loadSourceData(fileName: sourceFileName, isVaulted: doc.isVaulted),
                      let pdfDocument = PDFDocument(data: pdfData) {
                guard !pdfDocument.isLocked else { throw ExportError.protectedPDF }
                sourcePDF = pdfDocument
                vectorPage = nil
                expectedPageCount = pdfDocument.pageCount
            } else {
                let pageSize = CGSize(width: 595, height: 595 / 1.6)
                sourcePDF = nil
                vectorPage = await MainActor.run { renderVectorDoc(doc: doc, size: pageSize) }
                expectedPageCount = 1
            }

            guard expectedPageCount > 0 else { throw ExportError.noPages }

            var generationError: ExportError?
            let defaultBounds = CGRect(x: 0, y: 0, width: 595, height: 842)
            let pdfRenderer = UIGraphicsPDFRenderer(bounds: defaultBounds)
            try pdfRenderer.writePDF(to: tempURL) { ctx in
                for pageIndex in 0..<expectedPageCount {
                    if Task.isCancelled {
                        generationError = .cancelled
                        return
                    }

                    autoreleasepool {
                        let sourceAndRect: (UIImage, CGRect)?
                        if !pageFiles.isEmpty {
                            if var sourceImage = AppState.loadImage(
                                fileName: pageFiles[pageIndex],
                                isVaulted: doc.isVaulted
                            ) {
                                if let adjustment = doc.imageAdjustment {
                                    sourceImage = applyImageAdjustment(sourceImage, store: adjustment) ?? sourceImage
                                }
                                let pageWidth: CGFloat = 595
                                let aspectRatio = max(sourceImage.size.width / max(sourceImage.size.height, 1), 0.01)
                                let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageWidth / aspectRatio)
                                sourceAndRect = (sourceImage, pageRect)
                            } else {
                                sourceAndRect = nil
                            }
                        } else if let sourcePDF,
                                  let page = sourcePDF.page(at: pageIndex) {
                            let bounds = page.bounds(for: .mediaBox).standardized
                            let pageSize = bounds.size == .zero ? defaultBounds.size : bounds.size
                            var sourceImage = renderPDFPage(page: page, size: pageSize, scale: scale)
                            if let adjustment = doc.imageAdjustment {
                                sourceImage = applyImageAdjustment(sourceImage, store: adjustment) ?? sourceImage
                            }
                            sourceAndRect = (sourceImage, CGRect(origin: .zero, size: pageSize))
                        } else if let vectorPage {
                            let pageRect = CGRect(x: 0, y: 0, width: 595, height: 595 / 1.6)
                            sourceAndRect = (vectorPage, pageRect)
                        } else {
                            sourceAndRect = nil
                        }

                        guard let (sourceImage, pageRect) = sourceAndRect,
                              let flattenedPage = compositePageImage(
                                sourceImage: sourceImage,
                                redactions: pageRedactions[pageIndex] ?? [],
                                watermark: watermark,
                                pageSize: pageRect.size,
                                rasterScale: scale
                              ) else {
                            generationError = .sourceUnavailable(page: pageIndex)
                            return
                        }

                        ctx.beginPage(withBounds: pageRect, pageInfo: [:])
                        flattenedPage.draw(in: pageRect)
                        progress(Double(pageIndex + 1) / Double(expectedPageCount))
                    }

                    if generationError != nil { return }
                }
            }
            if let generationError { throw generationError }
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: tempURL.path
            )

            let normalizedCount = pageRedactions.values
                .flatMap { $0 }
                .count(where: { $0.style.isVisualObfuscation })
            let report = await ExportVerifier.verifyPDF(
                at: tempURL,
                expectedPageCount: expectedPageCount,
                normalizedVisualObfuscations: normalizedCount,
                redactionRectsByPage: pageRedactions.mapValues { $0.map(\.rect) }
            )
            guard report.isVerified else { throw ExportError.verificationFailed }
            return SecurePDFExport(url: tempURL, report: report)
        } catch {
            try? FileManager.default.removeItem(at: tempURL)
            throw error
        }
    }

    private static func compositePageImage(
        sourceImage: UIImage,
        redactions: [Redaction],
        watermark: Watermark?,
        pageSize: CGSize,
        rasterScale: CGFloat
    ) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(1, rasterScale)
        let renderer = UIGraphicsImageRenderer(size: pageSize, format: format)

        let securedRedactions = redactions.map { redaction in
            var secured = redaction
            secured.style = redaction.style.secureExportStyle
            return secured
        }

        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: pageSize)
            sourceImage.draw(in: rect)
            for r in securedRedactions {
                let rRect = CGRect(
                    x: r.rect.origin.x * pageSize.width, y: r.rect.origin.y * pageSize.height,
                    width: r.rect.width * pageSize.width, height: r.rect.height * pageSize.height
                )
                drawRedactionCG(context: ctx.cgContext, rect: rRect, style: r.style)
            }
            if let wm = watermark {
                drawWatermarkCG(context: ctx.cgContext, in: CGRect(origin: .zero, size: pageSize), watermark: wm)
            }
        }
    }

    static func imageStrippingMetadata(_ image: UIImage, compressionQuality: CGFloat = 0.92) -> UIImage? {
        guard let cgImage = image.cgImage else { return image }
        let mutableData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else { return image }
        CGImageDestinationAddImage(dest, cgImage, [kCGImageDestinationLossyCompressionQuality as String: compressionQuality] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return image }
        return UIImage(data: mutableData as Data)
    }

    static func exportAsImage(doc: DocumentItem, imageFileName: String?, redactions: [Redaction], watermark: Watermark?, scale: CGFloat) async -> UIImage? {
        var sourceImage = imageFileName.flatMap {
            AppState.loadImage(fileName: $0, isVaulted: doc.isVaulted)
        }
        if let adj = doc.imageAdjustment, let img = sourceImage {
            sourceImage = applyImageAdjustment(img, store: adj) ?? img
        }

        let baseSize: CGSize
        if let img = sourceImage {
            baseSize = img.size
        } else {
            baseSize = CGSize(width: 800, height: 500)
        }
        let scaledSize = CGSize(width: baseSize.width * scale, height: baseSize.height * scale)

        let vectorImage: UIImage? = sourceImage == nil ? await MainActor.run {
            renderVectorDoc(doc: doc, size: scaledSize)
        } : nil

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: scaledSize, format: format)

        let securedRedactions = redactions.map { redaction in
            var secured = redaction
            secured.style = redaction.style.secureExportStyle
            return secured
        }

        var baseImage = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: scaledSize)
            let cgCtx = ctx.cgContext

            if let img = sourceImage {
                img.draw(in: CGRect(origin: .zero, size: scaledSize))
            } else if let img = vectorImage {
                img.draw(in: rect)
            }

            for r in securedRedactions {
                let redactRect = CGRect(
                    x: r.rect.origin.x * scaledSize.width,
                    y: r.rect.origin.y * scaledSize.height,
                    width: r.rect.width * scaledSize.width,
                    height: r.rect.height * scaledSize.height
                )
                drawRedactionCG(context: cgCtx, rect: redactRect, style: r.style)
            }
        }

        if let wm = watermark {
            baseImage = renderer.image { ctx in
                baseImage.draw(in: CGRect(origin: .zero, size: scaledSize))
                drawWatermarkCG(context: ctx.cgContext, in: CGRect(origin: .zero, size: scaledSize), watermark: wm)
            }
        }

        return imageStrippingMetadata(baseImage) ?? baseImage
    }

    @MainActor
    static func renderVectorDoc(doc: DocumentItem, size: CGSize) -> UIImage? {
        let view = DocumentView(
            kind: doc.kind,
            size: size,
            fields: doc.fields,
            redactions: [],
            watermark: nil,
            imageFileName: doc.imageFileName,
            isVaulted: doc.isVaulted
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    static func applyImageAdjustment(_ image: UIImage, store: ImageAdjustmentStore) -> UIImage? {
        guard let cg = image.cgImage else { return image }
        var ci = CIImage(cgImage: cg)
        let ctx = CIContext(options: [.useSoftwareRenderer: false])

        let ext = ci.extent
        let cropLeft = ext.width * CGFloat(store.cropLeft)
        let cropRight = ext.width * CGFloat(store.cropRight)
        let cropTop = ext.height * CGFloat(store.cropTop)
        let cropBottom = ext.height * CGFloat(store.cropBottom)
        let cropRect = CGRect(
            x: ext.minX + cropLeft,
            y: ext.minY + cropBottom,
            width: max(20, ext.width - cropLeft - cropRight),
            height: max(20, ext.height - cropTop - cropBottom)
        )
        ci = ci.cropped(to: cropRect)

        let colorFilter = CIFilter.colorControls()
        colorFilter.inputImage = ci
        colorFilter.brightness = Float(store.brightness)
        colorFilter.contrast = Float(store.contrast)
        colorFilter.saturation = Float(store.saturation)
        ci = colorFilter.outputImage ?? ci

        if store.sharpness > 0.001 {
            let sharpen = CIFilter.sharpenLuminance()
            sharpen.inputImage = ci
            sharpen.sharpness = Float(store.sharpness)
            sharpen.radius = 0.8
            ci = sharpen.outputImage ?? ci
        }

        guard let outCG = ctx.createCGImage(ci, from: ci.extent) else { return image }
        var result = UIImage(cgImage: outCG)

        if abs(store.rotation) > 0.001 {
            result = rotateUIImage(result, degrees: store.rotation) ?? result
        }

        if store.flipHorizontal || store.flipVertical {
            result = flipUIImage(result, h: store.flipHorizontal, v: store.flipVertical) ?? result
        }

        return result
    }

    private static func rotateUIImage(_ image: UIImage, degrees: Double) -> UIImage? {
        let radians = CGFloat(degrees * .pi / 180)
        let rotatedRect = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians)).integral
        UIGraphicsBeginImageContextWithOptions(rotatedRect.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.translateBy(x: rotatedRect.midX, y: rotatedRect.midY)
        ctx.rotate(by: radians)
        image.draw(in: CGRect(
            x: -image.size.width / 2,
            y: -image.size.height / 2,
            width: image.size.width,
            height: image.size.height
        ))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private static func flipUIImage(_ image: UIImage, h: Bool, v: Bool) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.translateBy(x: h ? image.size.width : 0, y: v ? image.size.height : 0)
        ctx.scaleBy(x: h ? -1 : 1, y: v ? -1 : 1)
        image.draw(at: .zero)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private static func renderPDFPage(page: PDFPage, size: CGSize, scale: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(1, scale)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let cgCtx = ctx.cgContext
            cgCtx.saveGState()
            cgCtx.translateBy(x: 0, y: size.height)
            cgCtx.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: cgCtx)
            cgCtx.restoreGState()
        }
    }

    private static func applyBlurToCrop(
        sourceImage: CGImage,
        rect: CGRect,
        radius: CGFloat
    ) -> UIImage? {
        let ciSource = CIImage(cgImage: sourceImage)
        let blurred = ciSource
            .cropped(to: rect)
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": radius])
            .cropped(to: rect)
        guard let cgResult = CIContext().createCGImage(blurred, from: rect) else { return nil }
        return UIImage(cgImage: cgResult)
    }

    private static func drawRedactionCG(context: CGContext, rect: CGRect, style: MaskStyle) {
        switch style {
        case .blockWhite:
            context.setFillColor(UIColor.white.cgColor)
            context.fill(rect)
        case .semi:
            context.setFillColor(UIColor.black.withAlphaComponent(0.55).cgColor)
            context.fill(rect)
        case .blurStrong:
            context.setFillColor(UIColor.white.withAlphaComponent(0.80).cgColor)
            context.fill(rect)
            context.setFillColor(UIColor.gray.withAlphaComponent(0.30).cgColor)
            context.fill(rect)
        case .blurSoft:
            context.setFillColor(UIColor.white.withAlphaComponent(0.55).cgColor)
            context.fill(rect)
            context.setFillColor(UIColor.white.withAlphaComponent(0.15).cgColor)
            context.fill(rect)
        default:
            context.setFillColor(UIColor.black.cgColor)
            context.fill(rect)
        }

        if style == .redactedTag {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: min(rect.height * 0.5, 14), weight: .bold),
                .foregroundColor: UIColor(Color(hex: "FFD60A"))
            ]
            let text = LanguageManager.shared.model("model_mask_redacted_label") as NSString
            let textSize = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2
            ), withAttributes: attrs)
        }

        if style == .diagonal {
            context.setFillColor(UIColor(Color(hex: "FFD60A")).cgColor)
            var x = rect.minX
            while x < rect.maxX + rect.height {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: x, y: rect.minY))
                path.addLine(to: CGPoint(x: x + 3, y: rect.minY))
                path.addLine(to: CGPoint(x: x + 3 - rect.height, y: rect.maxY))
                path.addLine(to: CGPoint(x: x - rect.height, y: rect.maxY))
                path.close()
                context.saveGState()
                context.clip(to: rect)
                path.fill()
                context.restoreGState()
                x += 6
            }
        }
    }

    private static func drawWatermarkCG(context: CGContext, in rect: CGRect, watermark: Watermark) {
        let fontSize = rect.width * 0.07
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .heavy),
            .foregroundColor: UIColor(watermark.color).withAlphaComponent(CGFloat(watermark.opacity))
        ]
        let text = watermark.text as NSString

        if watermark.isRepeating {
            let stepX = rect.width / 2.5
            let stepY = rect.height / 3.5
            var y = rect.minY
            var row = 0
            while y < rect.maxY + stepY {
                let xOffset: CGFloat = row.isMultiple(of: 2) ? 0 : stepX / 2
                var x = rect.minX - stepX + xOffset
                while x < rect.maxX + stepX {
                    let textSize = text.size(withAttributes: attrs)
                    context.saveGState()
                    context.translateBy(x: x + textSize.width / 2, y: y + textSize.height / 2)
                    context.rotate(by: -CGFloat.pi / 6)
                    text.draw(at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2), withAttributes: attrs)
                    context.restoreGState()
                    x += stepX
                }
                y += stepY
                row += 1
            }
        } else {
            let textSize = text.size(withAttributes: attrs)
            context.saveGState()
            context.translateBy(x: rect.midX, y: rect.midY)
            context.rotate(by: -CGFloat.pi / 6)
            text.draw(at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2), withAttributes: attrs)
            context.restoreGState()
        }
    }
}

// MARK: - ShareSheetView

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
