import Foundation
import PDFKit
import Vision
import ImageIO
import CryptoKit

enum ExportVerifier {
    typealias OCRTextRecognizer = @Sendable (CGImage) async throws -> [String]

    private struct OCRVerificationResult {
        var residualTexts: [String] = []
        var unavailableRegionCount = 0
    }

    private static let visionTextRecognizer: OCRTextRecognizer = { image in
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        let observations = try await request.perform(on: image)
        return observations.compactMap { observation -> String? in
            guard let candidate = observation.topCandidates(1).first,
                  candidate.confidence >= 0.25 else { return nil }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        }
    }

    static func verifyPDF(
        at url: URL,
        expectedPageCount: Int,
        expectedPageSizes: [CGSize]? = nil,
        normalizedVisualObfuscations: Int,
        redactionRectsByPage: [Int: [CGRect]] = [:],
        redactionsApplied: Int = 0,
        watermarkApplied: Bool = false,
        remainingDetectedSensitiveElements: Int = 0,
        ocrTextRecognizer: OCRTextRecognizer? = nil
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
        let ocrResult = await detectResidualText(
            in: document,
            redactionRectsByPage: redactionRectsByPage,
            recognizer: ocrTextRecognizer ?? visionTextRecognizer
        )

        var issues: [String] = []
        if document.pageCount != expectedPageCount { issues.append("page_count_mismatch") }
        if let expectedPageSizes, expectedPageSizes.count == document.pageCount {
            for (pageIndex, expectedSize) in expectedPageSizes.enumerated() {
                guard let page = document.page(at: pageIndex) else {
                    issues.append("page_geometry_mismatch")
                    continue
                }
                let actualSize = PDFPageDisplayGeometry.size(of: page, box: .cropBox)
                let tolerance = max(1, max(expectedSize.width, expectedSize.height) * 0.002)
                if abs(actualSize.width - expectedSize.width) > tolerance ||
                    abs(actualSize.height - expectedSize.height) > tolerance {
                    issues.append("page_geometry_mismatch")
                    break
                }
            }
        } else if expectedPageSizes != nil {
            issues.append("page_geometry_mismatch")
        }
        if !extractedText.isEmpty { issues.append("extractable_text_found") }
        if annotationCount > 0 { issues.append("annotations_found") }
        if !sensitiveMetadataKeys.isEmpty { issues.append("sensitive_metadata_found") }
        if ocrResult.unavailableRegionCount > 0 || hasIncompleteRedactionGeometry(
            redactionsApplied: redactionsApplied,
            redactionRectsByPage: redactionRectsByPage,
            pageCount: document.pageCount
        ) {
            issues.append("ocr_verification_incomplete")
        }
        if !ocrResult.residualTexts.isEmpty { issues.append("ocr_residual_found") }

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
            ocrResidualTexts: ocrResult.residualTexts,
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
        remainingDetectedSensitiveElements: Int = 0,
        ocrTextRecognizer: OCRTextRecognizer? = nil
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
        let ocrResult = await detectResidualText(
            in: image,
            normalizedRects: redactionRectsByPage[0] ?? [],
            pageIndex: 0,
            recognizer: ocrTextRecognizer ?? visionTextRecognizer
        )

        var issues: [String] = []
        if !sensitiveMetadataKeys.isEmpty { issues.append("sensitive_metadata_found") }
        if ocrResult.unavailableRegionCount > 0 || hasIncompleteRedactionGeometry(
            redactionsApplied: redactionsApplied,
            redactionRectsByPage: redactionRectsByPage,
            pageCount: 1
        ) {
            issues.append("ocr_verification_incomplete")
        }
        if !ocrResult.residualTexts.isEmpty { issues.append("ocr_residual_found") }

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
            ocrResidualTexts: ocrResult.residualTexts,
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

    private static func hasIncompleteRedactionGeometry(
        redactionsApplied: Int,
        redactionRectsByPage: [Int: [CGRect]],
        pageCount: Int
    ) -> Bool {
        let regionCount = redactionRectsByPage.values.reduce(0) { $0 + $1.count }
        let hasOutOfRangePage = redactionRectsByPage.contains { entry in
            let (pageIndex, rects) = entry
            return !rects.isEmpty && !(0..<pageCount).contains(pageIndex)
        }
        let countMismatch = redactionsApplied > 0 && regionCount != redactionsApplied
        return hasOutOfRangePage || countMismatch
    }

    private static func detectResidualText(
        in document: PDFDocument,
        redactionRectsByPage: [Int: [CGRect]],
        recognizer: OCRTextRecognizer
    ) async -> OCRVerificationResult {
        var result = OCRVerificationResult()

        for (pageIndex, normalizedRects) in redactionRectsByPage where !normalizedRects.isEmpty {
            guard pageIndex >= 0,
                  pageIndex < document.pageCount,
                  let page = document.page(at: pageIndex) else {
                result.unavailableRegionCount += normalizedRects.count
                continue
            }

            let bounds = page.bounds(for: .cropBox).standardized
            let renderSize = CGSize(
                width: max(1, bounds.width * 2),
                height: max(1, bounds.height * 2)
            )
            let image = page.thumbnail(of: renderSize, for: .cropBox)
            guard let pageImage = image.cgImage else {
                result.unavailableRegionCount += normalizedRects.count
                continue
            }

            let pageResult = await detectResidualText(
                in: pageImage,
                normalizedRects: normalizedRects,
                pageIndex: pageIndex,
                recognizer: recognizer
            )
            result.residualTexts.append(contentsOf: pageResult.residualTexts)
            result.unavailableRegionCount += pageResult.unavailableRegionCount
        }

        return result
    }

    private static func detectResidualText(
        in image: CGImage,
        normalizedRects: [CGRect],
        pageIndex: Int,
        recognizer: OCRTextRecognizer
    ) async -> OCRVerificationResult {
        let imageBounds = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        var result = OCRVerificationResult()

        for normalizedRect in normalizedRects {
            guard normalizedRect.origin.x.isFinite,
                  normalizedRect.origin.y.isFinite,
                  normalizedRect.width.isFinite,
                  normalizedRect.height.isFinite,
                  normalizedRect.width > 0,
                  normalizedRect.height > 0 else {
                result.unavailableRegionCount += 1
                continue
            }

            let rect = normalizedRect.standardized
            let cropRect = CGRect(
                x: rect.minX * CGFloat(image.width),
                y: rect.minY * CGFloat(image.height),
                width: rect.width * CGFloat(image.width),
                height: rect.height * CGFloat(image.height)
            ).integral.intersection(imageBounds)
            guard cropRect.width >= 2,
                  cropRect.height >= 2,
                  let crop = image.cropping(to: cropRect) else {
                result.unavailableRegionCount += 1
                continue
            }

            let texts: [String]
            do {
                texts = try await recognizer(crop)
            } catch {
                result.unavailableRegionCount += 1
                continue
            }

            result.residualTexts.append(contentsOf: texts.map { "page_\(pageIndex + 1):\($0)" })
        }

        return result
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
