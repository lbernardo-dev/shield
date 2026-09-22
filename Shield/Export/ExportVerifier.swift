import Foundation
import PDFKit
import Vision
import ImageIO
import CryptoKit

enum ExportVerifier {
    static func verifyPDF(
        at url: URL,
        expectedPageCount: Int,
        normalizedVisualObfuscations: Int,
        redactionRectsByPage: [Int: [CGRect]] = [:],
        redactionsApplied: Int = 0,
        watermarkApplied: Bool = false,
        remainingDetectedSensitiveElements: Int = 0
    ) async -> ExportVerificationReport {
        guard let document = PDFDocument(url: url) else {
            return ExportVerificationReport(
                format: .pdf,
                outputOpened: false,
                expectedPageCount: expectedPageCount,
                actualPageCount: 0,
                pagesReviewed: 0,
                hasExtractableText: false,
                annotationCount: 0,
                sensitiveMetadataKeys: [],
                metadataRemoved: false,
                ocrResidualTexts: [],
                redactionsApplied: redactionsApplied,
                normalizedVisualObfuscations: normalizedVisualObfuscations,
                watermarkApplied: watermarkApplied,
                remainingDetectedSensitiveElements: remainingDetectedSensitiveElements,
                issues: ["output_unreadable"]
            )
        }

        let extractedText = document.string?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let annotationCount = (0..<document.pageCount).reduce(into: 0) { count, pageIndex in
            count += document.page(at: pageIndex)?.annotations.count ?? 0
        }
        let sensitiveMetadataKeys = sensitiveMetadataKeys(in: document)
        let ocrResidualTexts = detectResidualText(
            in: document,
            redactionRectsByPage: redactionRectsByPage
        )

        var issues: [String] = []
        if document.pageCount != expectedPageCount { issues.append("page_count_mismatch") }
        if !extractedText.isEmpty { issues.append("extractable_text_found") }
        if annotationCount > 0 { issues.append("annotations_found") }
        if !sensitiveMetadataKeys.isEmpty { issues.append("sensitive_metadata_found") }
        if !ocrResidualTexts.isEmpty { issues.append("ocr_residual_found") }

        return ExportVerificationReport(
            format: .pdf,
            outputOpened: true,
            expectedPageCount: expectedPageCount,
            actualPageCount: document.pageCount,
            pagesReviewed: document.pageCount,
            hasExtractableText: !extractedText.isEmpty,
            annotationCount: annotationCount,
            sensitiveMetadataKeys: sensitiveMetadataKeys,
            metadataRemoved: sensitiveMetadataKeys.isEmpty,
            ocrResidualTexts: ocrResidualTexts,
            redactionsApplied: redactionsApplied,
            normalizedVisualObfuscations: normalizedVisualObfuscations,
            watermarkApplied: watermarkApplied,
            remainingDetectedSensitiveElements: remainingDetectedSensitiveElements,
            sha256Hash: computeSHA256(for: url),
            issues: issues
        )
    }

    static func verifyImage(
        at url: URL,
        redactionRectsByPage: [Int: [CGRect]] = [:],
        redactionsApplied: Int = 0,
        normalizedVisualObfuscations: Int = 0,
        watermarkApplied: Bool = false,
        remainingDetectedSensitiveElements: Int = 0
    ) async -> ExportVerificationReport {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return ExportVerificationReport(
                format: .image,
                outputOpened: false,
                expectedPageCount: 1,
                actualPageCount: 0,
                pagesReviewed: 0,
                hasExtractableText: false,
                annotationCount: 0,
                sensitiveMetadataKeys: [],
                metadataRemoved: false,
                ocrResidualTexts: [],
                redactionsApplied: redactionsApplied,
                normalizedVisualObfuscations: 0,
                watermarkApplied: watermarkApplied,
                remainingDetectedSensitiveElements: remainingDetectedSensitiveElements,
                issues: ["output_unreadable"]
            )
        }

        let sensitiveMetadataKeys = imageSensitiveMetadataKeys(in: source)
        let residualTexts = detectResidualText(
            in: image,
            normalizedRects: redactionRectsByPage[0] ?? [],
            pageIndex: 0
        )

        var issues: [String] = []
        if !sensitiveMetadataKeys.isEmpty { issues.append("sensitive_metadata_found") }
        if !residualTexts.isEmpty { issues.append("ocr_residual_found") }

        return ExportVerificationReport(
            format: .image,
            outputOpened: true,
            expectedPageCount: 1,
            actualPageCount: 1,
            pagesReviewed: 1,
            hasExtractableText: false,
            annotationCount: 0,
            sensitiveMetadataKeys: sensitiveMetadataKeys,
            metadataRemoved: sensitiveMetadataKeys.isEmpty,
            ocrResidualTexts: residualTexts,
            redactionsApplied: redactionsApplied,
            normalizedVisualObfuscations: normalizedVisualObfuscations,
            watermarkApplied: watermarkApplied,
            remainingDetectedSensitiveElements: remainingDetectedSensitiveElements,
            sha256Hash: computeSHA256(for: url),
            issues: issues
        )
    }

    private static func computeSHA256(for url: URL) -> String? {
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return nil }
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func detectResidualText(
        in document: PDFDocument,
        redactionRectsByPage: [Int: [CGRect]]
    ) -> [String] {
        var residualTexts: [String] = []

        for (pageIndex, normalizedRects) in redactionRectsByPage where !normalizedRects.isEmpty {
            guard pageIndex >= 0,
                  pageIndex < document.pageCount,
                  let page = document.page(at: pageIndex) else { continue }

            let bounds = page.bounds(for: .mediaBox).standardized
            let renderSize = CGSize(
                width: max(1, bounds.width * 2),
                height: max(1, bounds.height * 2)
            )
            let image = page.thumbnail(of: renderSize, for: .mediaBox)
            guard let pageImage = image.cgImage else { continue }

            residualTexts.append(contentsOf: detectResidualText(
                in: pageImage,
                normalizedRects: normalizedRects,
                pageIndex: pageIndex
            ))
        }

        return residualTexts
    }

    private static func detectResidualText(
        in image: CGImage,
        normalizedRects: [CGRect],
        pageIndex: Int
    ) -> [String] {
        let imageBounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        var residualTexts: [String] = []

        for normalizedRect in normalizedRects {
            let rect = normalizedRect.standardized
            let cropRect = CGRect(
                x: rect.minX * CGFloat(image.width),
                y: rect.minY * CGFloat(image.height),
                width: rect.width * CGFloat(image.width),
                height: rect.height * CGFloat(image.height)
            ).integral.intersection(imageBounds)
            guard cropRect.width >= 2,
                  cropRect.height >= 2,
                  let crop = image.cropping(to: cropRect) else { continue }

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false
            let handler = VNImageRequestHandler(cgImage: crop, options: [:])
            guard (try? handler.perform([request])) != nil else { continue }

            let texts = (request.results ?? []).compactMap { observation -> String? in
                guard let candidate = observation.topCandidates(1).first,
                      candidate.confidence >= 0.25 else { return nil }
                let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                return text.isEmpty ? nil : text
            }
            residualTexts.append(contentsOf: texts.map { "page_\(pageIndex + 1):\($0)" })
        }

        return residualTexts
    }

    private static func sensitiveMetadataKeys(in document: PDFDocument) -> [String] {
        let attributes = document.documentAttributes ?? [:]
        let sensitiveKeys: [(PDFDocumentAttribute, String)] = [
            (.titleAttribute, "title"),
            (.authorAttribute, "author"),
            (.subjectAttribute, "subject"),
            (.keywordsAttribute, "keywords"),
            (.creatorAttribute, "creator")
        ]

        return sensitiveKeys.compactMap { key, label in
            guard let value = attributes[key] else { return nil }
            if let text = value as? String, text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return nil
            }
            if let values = value as? [String], values.isEmpty { return nil }
            return label
        }
    }

    private static func imageSensitiveMetadataKeys(in source: CGImageSource) -> [String] {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as NSDictionary? else {
            return []
        }

        let groups: [(String, String)] = [
            (kCGImagePropertyExifDictionary as String, "EXIF"),
            (kCGImagePropertyGPSDictionary as String, "GPS"),
            (kCGImagePropertyTIFFDictionary as String, "TIFF"),
            (kCGImagePropertyIPTCDictionary as String, "IPTC"),
            (kCGImagePropertyMakerAppleDictionary as String, "camera metadata"),
            (kCGImagePropertyPNGDictionary as String, "PNG metadata")
        ]

        return groups.compactMap { key, label in
            guard let value = properties[key] else { return nil }
            guard let dictionary = value as? NSDictionary else { return label }
            let keys = Set(dictionary.allKeys.compactMap { $0 as? String })

            switch label {
            case "EXIF":
                let sensitiveKeys = Set([
                    "DateTimeOriginal", "DateTimeDigitized", "MakerNote",
                    "UserComment", "LensMake", "LensModel", "SerialNumber",
                    "CameraOwnerName", "BodySerialNumber", "ImageUniqueID"
                ])
                return keys.intersection(sensitiveKeys).isEmpty ? nil : label
            case "GPS":
                return dictionary.count == 0 ? nil : label
            case "TIFF":
                let sensitiveKeys = Set([
                    "Make", "Model", "Software", "Artist", "Copyright",
                    "DateTime", "HostComputer", "DocumentName", "ImageDescription"
                ])
                return keys.intersection(sensitiveKeys).isEmpty ? nil : label
            case "IPTC", "camera metadata":
                return dictionary.count == 0 ? nil : label
            case "PNG metadata":
                // ImageIO may expose technical PNG properties such as
                // InterlaceType even when the file has no user metadata.
                // Only flag fields that can carry authorship, location,
                // provenance, or other human-entered content.
                let meaningfulKeys = Set([
                    "Title", "Description", "Author", "Copyright",
                    "CreationTime", "Software", "Source", "Comment",
                    "Disclaimer", "Warning", "XMP"
                ])
                return keys.intersection(meaningfulKeys).isEmpty ? nil : label
            default:
                return label
            }
        }
    }
}
