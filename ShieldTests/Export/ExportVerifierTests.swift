import PDFKit
import Testing
import UIKit
import ImageIO
import UniformTypeIdentifiers
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

    @Test("Detects image metadata and accepts a stripped image")
    func verifiesImageMetadataRemoval() async throws {
        let inputURL = temporaryImageURL()
        let outputURL = temporaryImageURL()
        defer {
            try? FileManager.default.removeItem(at: inputURL)
            try? FileManager.default.removeItem(at: outputURL)
        }

        let image = UIGraphicsImageRenderer(size: CGSize(width: 240, height: 180)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 240, height: 180))
        }
        let metadataData = try #require(jpegData(for: image, includeGPS: true))
        try metadataData.write(to: inputURL)

        let before = await ExportVerifier.verifyImage(at: inputURL)
        #expect(before.isVerified == false)
        #expect(before.sensitiveMetadataKeys.contains("GPS"))
        #expect(before.metadataRemoved == false)

        let inputImage = try #require(UIImage(contentsOfFile: inputURL.path))
        let strippedData = try #require(ExportEngine.imageDataStrippingMetadata(inputImage))
        try strippedData.write(to: outputURL)

        let after = await ExportVerifier.verifyImage(at: outputURL)
        #expect(after.isVerified)
        #expect(after.metadataRemoved)
        #expect(after.sensitiveMetadataKeys.isEmpty)
    }

    @Test("Rejects image text that remains inside a redaction zone")
    func rejectsImageOCRResidual() async throws {
        let url = temporaryImageURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let image = UIGraphicsImageRenderer(size: CGSize(width: 500, height: 220)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 500, height: 220))
            ("SECRET 1234" as NSString).draw(
                at: CGPoint(x: 30, y: 70),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 58, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
            )
        }
        let data = try #require(ExportEngine.imageDataStrippingMetadata(image))
        try data.write(to: url)

        let report = await ExportVerifier.verifyImage(
            at: url,
            redactionRectsByPage: [0: [CGRect(x: 0, y: 0.2, width: 1, height: 0.6)]],
            redactionsApplied: 1
        )

        #expect(report.isVerified == false)
        #expect(report.issues.contains("ocr_residual_found"))
        #expect(report.ocrResidualTexts.isEmpty == false)
    }

    @Test("Rejects PDF annotations and document metadata")
    func rejectsAnnotationsAndDocumentMetadata() async throws {
        let url = temporaryPDFURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let pdfData = try #require(rasterPDFData(
            pageSizes: [CGSize(width: 320, height: 480)]
        ))
        let document = try #require(PDFDocument(data: pdfData))
        document.documentAttributes = [
            PDFDocumentAttribute.titleAttribute: "Fictitious identity fixture",
            PDFDocumentAttribute.authorAttribute: "MaskID QA",
            PDFDocumentAttribute.creatorAttribute: "Fixture generator"
        ]
        let page = try #require(document.page(at: 0))
        let annotation = PDFAnnotation(
            bounds: CGRect(x: 20, y: 20, width: 80, height: 40),
            forType: .text,
            withProperties: nil
        )
        page.addAnnotation(annotation)
        #expect(document.write(to: url))

        let report = await ExportVerifier.verifyPDF(
            at: url,
            expectedPageCount: 1,
            normalizedVisualObfuscations: 0
        )

        #expect(report.isVerified == false)
        #expect(report.annotationCount == 1)
        #expect(report.issues.contains("annotations_found"))
        #expect(report.issues.contains("sensitive_metadata_found"))
        #expect(report.sensitiveMetadataKeys.contains("title"))
        #expect(report.sensitiveMetadataKeys.contains("author"))
        #expect(report.sensitiveMetadataKeys.contains("creator"))
    }

    @Test("Verifies rotated, low-quality, multilingual multi-page raster PDFs")
    func verifiesAdversarialMultipagePDF() async throws {
        let url = temporaryPDFURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let pdfData = try #require(rasterPDFData(
            pageSizes: [
                CGSize(width: 96, height: 64),
                CGSize(width: 640, height: 360),
                CGSize(width: 360, height: 640),
                CGSize(width: 420, height: 280)
            ],
            rotations: [2: 90],
            labels: [
                "ID 1234",
                "Nombre · Adresse · Straße",
                "Passport fixture / سفر",
                "Signature and QR fixture"
            ]
        ))
        let document = try #require(PDFDocument(data: pdfData))
        #expect(document.pageCount == 4)
        try pdfData.write(to: url)

        let report = await ExportVerifier.verifyPDF(
            at: url,
            expectedPageCount: 4,
            normalizedVisualObfuscations: 0
        )

        #expect(report.isVerified)
        #expect(report.actualPageCount == 4)
        #expect(report.pagesReviewed == 4)
        #expect(report.hasExtractableText == false)
    }

    @Test("Accepts transparent PNG without treating technical properties as personal metadata")
    func acceptsTransparentPNG() async throws {
        let url = temporaryPNGURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let image = transparentFixtureImage()
        let data = try #require(pngData(for: image))
        try data.write(to: url)

        let report = await ExportVerifier.verifyImage(at: url)

        #expect(report.isVerified)
        #expect(report.metadataRemoved)
        #expect(report.sensitiveMetadataKeys.isEmpty)
    }

    @Test("Detects GPS, EXIF and TIFF metadata in a camera-style image")
    func detectsCameraMetadataFixture() async throws {
        let url = temporaryImageURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let image = fixtureImage(
            size: CGSize(width: 240, height: 180),
            label: "PHOTO FIXTURE"
        )
        let data = try #require(jpegData(
            for: image,
            includeGPS: true,
            includeCameraMetadata: true
        ))
        try data.write(to: url)

        let report = await ExportVerifier.verifyImage(at: url)

        #expect(report.isVerified == false)
        #expect(report.issues.contains("sensitive_metadata_found"))
        #expect(report.sensitiveMetadataKeys.contains("GPS"))
        #expect(report.sensitiveMetadataKeys.contains("EXIF"))
        #expect(report.sensitiveMetadataKeys.contains("TIFF"))
        #expect(report.metadataRemoved == false)
    }

    @Test("Secure Export removes source text from PDF and image output bytes", .timeLimit(.minutes(1)))
    func secureExportRemovesSourceTextFromOutput() async throws {
        let appState = AppState()
        let documentID = "byte-check-\(UUID().uuidString)"
        let image = UIGraphicsImageRenderer(size: CGSize(width: 500, height: 220)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 500, height: 220))
            ("SECRET 1234" as NSString).draw(
                at: CGPoint(x: 30, y: 70),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 58, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
            )
        }
        let fileName = try #require(appState.saveImage(image, id: documentID))
        defer {
            SecureFileStore.shared.removeFile(
                at: AppState.resolveImageURL(fileName: fileName, isVaulted: false)
            )
        }

        let document = DocumentItem(
            id: documentID,
            kind: .photo,
            title: "Secure export byte fixture",
            imageFileName: fileName,
            pageFileNames: [fileName]
        )
        let redactions = [Redaction(
            rect: CGRect(x: 0, y: 0.2, width: 1, height: 0.6),
            style: .block
        )]
        let secretBytes = Data("SECRET 1234".utf8)

        let pdfArtifact = try await ExportEngine.exportAsPDF(
            doc: document,
            pageRedactions: [0: redactions],
            watermark: nil,
            scale: 1
        )
        defer { try? FileManager.default.removeItem(at: pdfArtifact.url) }

        let pdfData = try Data(contentsOf: pdfArtifact.url)
        let outputPDF = try #require(PDFDocument(data: pdfData))
        #expect(pdfData.range(of: secretBytes) == nil)
        #expect((outputPDF.string ?? "").isEmpty)
        #expect(outputPDF.page(at: 0)?.annotations.isEmpty == true)
        #expect(pdfArtifact.report.isVerified)

        let imageArtifact = try await ExportEngine.exportAsImage(
            doc: document,
            imageFileName: fileName,
            redactions: redactions,
            watermark: nil,
            scale: 1
        )
        defer { try? FileManager.default.removeItem(at: imageArtifact.url) }

        let imageData = try Data(contentsOf: imageArtifact.url)
        #expect(imageData.range(of: secretBytes) == nil)
        #expect(imageArtifact.report.isVerified)
    }

    @Test("Verifies a fifty-page raster PDF without page loss", .timeLimit(.minutes(1)))
    func verifiesLargeMultipagePDF() async throws {
        let url = temporaryPDFURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let pageCount = 50
        let data = try #require(rasterPDFData(
            pageSizes: Array(repeating: CGSize(width: 320, height: 480), count: pageCount),
            labels: (0..<pageCount).map { "PAGE \($0 + 1) ID 0000" }
        ))
        try data.write(to: url)

        let report = await ExportVerifier.verifyPDF(
            at: url,
            expectedPageCount: pageCount,
            normalizedVisualObfuscations: 0
        )

        #expect(report.isVerified)
        #expect(report.actualPageCount == pageCount)
        #expect(report.pagesReviewed == pageCount)
    }

    private func temporaryPDFURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("shield-verifier-\(UUID().uuidString).pdf")
    }

    private func temporaryImageURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("shield-verifier-\(UUID().uuidString).jpg")
    }

    private func temporaryPNGURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("shield-verifier-\(UUID().uuidString).png")
    }

    private func fixtureImage(
        size: CGSize,
        label: String,
        transparent: Bool = false
    ) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = !transparent
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            if !transparent {
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            } else {
                UIColor.systemBlue.withAlphaComponent(0.55).setFill()
                context.fill(CGRect(
                    x: 8,
                    y: 8,
                    width: max(1, size.width - 16),
                    height: max(1, size.height - 16)
                ))
            }

            let fontSize = max(8, min(size.width, size.height) / 8)
            (label as NSString).draw(
                in: CGRect(
                    x: 8,
                    y: 8,
                    width: max(1, size.width - 16),
                    height: max(1, size.height - 16)
                ),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                    .foregroundColor: transparent ? UIColor.white : UIColor.black
                ]
            )
        }
    }

    private func transparentFixtureImage() -> UIImage {
        fixtureImage(
            size: CGSize(width: 240, height: 180),
            label: "ALPHA FIXTURE",
            transparent: true
        )
    }

    private func rasterPDFData(
        pageSizes: [CGSize],
        rotations: [Int: Int] = [:],
        labels: [String] = []
    ) -> Data? {
        let document = PDFDocument()
        for (index, size) in pageSizes.enumerated() {
            let label = labels.indices.contains(index) ? labels[index] : "RASTER PAGE \(index + 1)"
            guard let page = PDFPage(image: fixtureImage(size: size, label: label)) else {
                return nil
            }
            page.setBounds(CGRect(origin: .zero, size: size), for: .mediaBox)
            page.rotation = rotations[index] ?? 0
            document.insert(page, at: index)
        }
        return document.dataRepresentation()
    }

    private func pngData(for image: UIImage) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else { return nil }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }

    private func jpegData(
        for image: UIImage,
        includeGPS: Bool,
        includeCameraMetadata: Bool = false
    ) -> Data? {
        guard let cgImage = image.cgImage else { return nil }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else { return nil }

        var properties: [String: Any] = includeGPS
            ? [kCGImagePropertyGPSDictionary as String: [
                kCGImagePropertyGPSLatitude as String: 40.4168,
                kCGImagePropertyGPSLongitude as String: -3.7038
            ]]
            : [:]
        if includeCameraMetadata {
            properties[kCGImagePropertyExifDictionary as String] = [
                kCGImagePropertyExifDateTimeOriginal as String: "2026:09:12 12:00:00"
            ]
            properties[kCGImagePropertyTIFFDictionary as String] = [
                kCGImagePropertyTIFFMake as String: "MaskID Fixture Camera"
            ]
        }
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
