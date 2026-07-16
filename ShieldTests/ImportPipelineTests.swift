import Testing
import UIKit
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
}
