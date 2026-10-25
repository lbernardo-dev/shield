import Testing
import UIKit
import PDFKit
@testable import Shield

@Suite("Bounded import pipeline")
struct ImportPipelineTests {
    @Test("Image data is downsampled before entering the review flow")
    func downsamplingHonorsPixelLimit() throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4_000, height: 2_000))
        let source = renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4_000, height: 2_000))
        }
        let data = try #require(source.jpegData(compressionQuality: 0.9))
        let result = try #require(
            CaptureImportPipeline.downsampleImage(data: data, maximumDimension: 512)
        )

        #expect(max(result.size.width, result.size.height) <= 512)
    }

    @Test("Page limits reject oversized batches before processing")
    @MainActor
    func rejectsOversizedBatch() async {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { _ in }
        let limits = CaptureImportLimits(
            maximumFileBytes: 1_024,
            maximumPages: 1,
            maximumPixelDimension: 512,
            maximumDecodedBytes: 1_024 * 1_024
        )

        do {
            _ = try await CaptureImportPipeline.prepareImages(
                [image, image],
                limits: limits,
                progress: { _, _ in }
            )
            Issue.record("Expected the batch to be rejected")
        } catch let error as CaptureImportError {
            #expect(error == .tooManyPages(maximum: 1))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("Image files enter processing as a single normalized page")
    @MainActor
    func preparesImageFile() async throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 32)).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 64, height: 32))
        }
        let data = try #require(image.jpegData(compressionQuality: 0.9))
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("maskid-import-\(UUID().uuidString).jpg")
        defer { try? FileManager.default.removeItem(at: url) }
        try data.write(to: url, options: .atomic)

        let limits = CaptureImportLimits(
            maximumFileBytes: 1_024 * 1_024,
            maximumPages: 5,
            maximumPixelDimension: 64,
            maximumDecodedBytes: 1_024 * 1_024
        )
        let prepared = try await CaptureImportPipeline.prepareFile(at: url, limits: limits) { _, _ in }

        #expect(prepared.sourceType == .image)
        #expect(prepared.pages.count == 1)
        #expect(prepared.sourceData == nil)
        #expect(max(prepared.pages[0].cgImage?.width ?? 0, prepared.pages[0].cgImage?.height ?? 0) <= 64)
    }

    @Test("PDF files preserve the source and prepare every page")
    @MainActor
    func preparesMultipagePDF() async throws {
        let bounds = CGRect(x: 0, y: 0, width: 600, height: 800)
        let pdfData = UIGraphicsPDFRenderer(bounds: bounds).pdfData { context in
            for _ in 0..<2 {
                context.beginPage()
                UIColor.white.setFill()
                context.fill(bounds)
            }
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("maskid-import-\(UUID().uuidString).pdf")
        defer { try? FileManager.default.removeItem(at: url) }
        try pdfData.write(to: url, options: .atomic)

        let prepared = try await CaptureImportPipeline.prepareFile(at: url) { _, _ in }

        #expect(prepared.sourceType == .pdf)
        #expect(prepared.sourceExtension == "pdf")
        #expect(prepared.pages.count == 2)
        #expect(prepared.sourceData == pdfData)
    }

    @Test("Page display geometry respects PDF rotation")
    @MainActor
    func rotatedPDFPageUsesDisplayedAspectRatio() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 800)).image { _ in }
        let page = try #require(PDFPage(image: image))
        page.setBounds(CGRect(x: 20, y: 30, width: 400, height: 700), for: .cropBox)
        page.rotation = 90

        let size = PDFPageDisplayGeometry.size(of: page)

        #expect(size.width == 700)
        #expect(size.height == 400)
    }

    @Test("Unknown files are rejected before entering review")
    @MainActor
    func rejectsUnsupportedFile() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("maskid-import-\(UUID().uuidString).txt")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("not an image or a PDF".utf8).write(to: url, options: .atomic)

        do {
            _ = try await CaptureImportPipeline.prepareFile(at: url) { _, _ in }
            Issue.record("Expected the file to be rejected")
        } catch let error as CaptureImportError {
            #expect(error == .unsupportedFormat)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}

@Suite("Document library persistence transactions")
struct DocumentLibraryTransactionTests {
    @Test("Failed encrypted snapshot keeps imported document out of the library")
    func failedInsertDoesNotPublishDocument() {
        let existing = DocumentItem(kind: .photo, title: "Existing", imageFileName: "existing.jpg")
        let imported = DocumentItem(kind: .photo, title: "Imported", imageFileName: "imported.jpg")
        var documents = [existing]
        var attemptedSnapshot: [DocumentItem] = []

        let didCommit = DocumentCollectionTransaction.insert(imported, into: &documents) { candidate in
            attemptedSnapshot = candidate
            return false
        }

        #expect(!didCommit)
        #expect(attemptedSnapshot.map(\.id) == [imported.id, existing.id])
        #expect(documents.map(\.id) == [existing.id])
    }

    @Test("Failed edit snapshot preserves the previously saved document")
    func failedReplaceKeepsPreviousDocument() {
        let original = DocumentItem(kind: .photo, title: "Original", imageFileName: "page.jpg")
        var edited = original
        edited.title = "Edited"
        var documents = [original]

        let didCommit = DocumentCollectionTransaction.replace(edited, in: &documents) { _ in false }

        #expect(!didCommit)
        #expect(documents.count == 1)
        #expect(documents.first?.title == "Original")
    }

    @Test("Successful import snapshot commits before publishing the new library state")
    func successfulInsertPublishesDocument() {
        let existing = DocumentItem(kind: .photo, title: "Existing", imageFileName: "existing.jpg")
        let imported = DocumentItem(kind: .photo, title: "Imported", imageFileName: "imported.jpg")
        var documents = [existing]

        let didCommit = DocumentCollectionTransaction.insert(imported, into: &documents) { candidate in
            candidate.map(\.id) == [imported.id, existing.id]
        }

        #expect(didCommit)
        #expect(documents.map(\.id) == [imported.id, existing.id])
    }
}
