import Foundation
import PDFKit
import Vision

enum ExportVerifier {
    static func verifyPDF(
        at url: URL,
        expectedPageCount: Int,
        normalizedVisualObfuscations: Int,
        redactionRectsByPage: [Int: [CGRect]] = [:]
    ) async -> ExportVerificationReport {
        guard let document = PDFDocument(url: url) else {
            return ExportVerificationReport(
                outputOpened: false,
                expectedPageCount: expectedPageCount,
                actualPageCount: 0,
                hasExtractableText: false,
                annotationCount: 0,
                sensitiveMetadataKeys: [],
                ocrResidualTexts: [],
                normalizedVisualObfuscations: normalizedVisualObfuscations,
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
            outputOpened: true,
            expectedPageCount: expectedPageCount,
            actualPageCount: document.pageCount,
            hasExtractableText: !extractedText.isEmpty,
            annotationCount: annotationCount,
            sensitiveMetadataKeys: sensitiveMetadataKeys,
            ocrResidualTexts: ocrResidualTexts,
            normalizedVisualObfuscations: normalizedVisualObfuscations,
            issues: issues
        )
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

            for normalizedRect in normalizedRects {
                let cropRect = CGRect(
                    x: normalizedRect.minX * CGFloat(pageImage.width),
                    y: normalizedRect.minY * CGFloat(pageImage.height),
                    width: normalizedRect.width * CGFloat(pageImage.width),
                    height: normalizedRect.height * CGFloat(pageImage.height)
                ).integral.intersection(CGRect(
                    x: 0,
                    y: 0,
                    width: pageImage.width,
                    height: pageImage.height
                ))
                guard cropRect.width >= 2,
                      cropRect.height >= 2,
                      let crop = pageImage.cropping(to: cropRect) else { continue }

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
}
