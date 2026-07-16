import PDFKit
import Testing
import UIKit
@testable import Shield

@Suite("Secure PDF verification")
@MainActor
struct ExportVerifierTests {
    @Test("Rejects a PDF that still contains extractable text")
    func rejectsExtractableText() async throws {
        let url = temporaryPDFURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 200, height: 200))
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            ("SECRET" as NSString).draw(at: CGPoint(x: 20, y: 20), withAttributes: [
                .font: UIFont.systemFont(ofSize: 18)
            ])
        }

        let report = await ExportVerifier.verifyPDF(
            at: url,
            expectedPageCount: 1,
            normalizedVisualObfuscations: 0
        )

        #expect(report.isVerified == false)
        #expect(report.hasExtractableText)
        #expect(report.issues.contains("extractable_text_found"))
    }

    @Test("Accepts a raster-only PDF with the expected page count")
    func acceptsRasterOnlyPDF() async throws {
        let url = temporaryPDFURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let image = UIGraphicsImageRenderer(size: CGSize(width: 200, height: 200)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 200, height: 200))
            UIColor.black.setFill()
            context.fill(CGRect(x: 20, y: 20, width: 160, height: 40))
        }
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 200, height: 200))
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            image.draw(in: CGRect(x: 0, y: 0, width: 200, height: 200))
        }

        let report = await ExportVerifier.verifyPDF(
            at: url,
            expectedPageCount: 1,
            normalizedVisualObfuscations: 1,
            redactionRectsByPage: [0: [CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.2)]]
        )

        #expect(report.isVerified)
        #expect(report.actualPageCount == 1)
        #expect(report.normalizedVisualObfuscations == 1)
    }

    @Test("Rejects raster text still visible inside a redaction zone")
    func rejectsOCRResidualInsideRedaction() async throws {
        let url = temporaryPDFURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let pageRect = CGRect(x: 0, y: 0, width: 500, height: 220)
        let image = UIGraphicsImageRenderer(size: pageRect.size).image { context in
            UIColor.white.setFill()
            context.fill(pageRect)
            ("SECRET 1234" as NSString).draw(at: CGPoint(x: 30, y: 70), withAttributes: [
                .font: UIFont.systemFont(ofSize: 58, weight: .bold),
                .foregroundColor: UIColor.black
            ])
        }
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        try renderer.writePDF(to: url) { context in
            context.beginPage()
            image.draw(in: pageRect)
        }

        let report = await ExportVerifier.verifyPDF(
            at: url,
            expectedPageCount: 1,
            normalizedVisualObfuscations: 0,
            redactionRectsByPage: [0: [CGRect(x: 0, y: 0.2, width: 1, height: 0.6)]]
        )

        #expect(report.isVerified == false)
        #expect(report.issues.contains("ocr_residual_found"))
        #expect(report.ocrResidualTexts.isEmpty == false)
    }

    private func temporaryPDFURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("shield-verifier-\(UUID().uuidString).pdf")
    }
}
