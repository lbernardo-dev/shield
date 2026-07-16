import Testing
import UIKit
import PDFKit
@testable import Shield

@Suite("Release performance budgets", .serialized)
struct PerformanceBudgetTests {
    @Test("Twenty A4-like pages stay within import time and decoded-memory budgets", .timeLimit(.minutes(1)))
    @MainActor
    func boundedTwentyPageImport() async throws {
        let fixture = UIGraphicsImageRenderer(size: CGSize(width: 1_600, height: 2_200)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1_600, height: 2_200))
            ("CONFIDENTIAL FIXTURE 12345678Z" as NSString).draw(
                at: CGPoint(x: 100, y: 200),
                withAttributes: [.font: UIFont.systemFont(ofSize: 64), .foregroundColor: UIColor.black]
            )
        }
        let pages = Array(repeating: fixture, count: 20)
        let clock = ContinuousClock()
        let start = clock.now
        let result = try await CaptureImportPipeline.prepareImages(pages) { _, _ in }
        let elapsed = start.duration(to: clock.now)

        #expect(result.count == 20)
        #expect(elapsed < .seconds(15), "Import preparation exceeded the 15-second simulator budget: \(elapsed)")
        #expect(result.allSatisfy { max($0.size.width, $0.size.height) <= 2_048 })
    }

    @Test("Maximum fifty-page batch remains bounded", .timeLimit(.minutes(1)))
    @MainActor
    func maximumBatchBoundary() async throws {
        let fixture = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 1_100)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 800, height: 1_100))
            ("MAXIMUM SAFE BATCH" as NSString).draw(
                at: CGPoint(x: 60, y: 100),
                withAttributes: [.font: UIFont.systemFont(ofSize: 36), .foregroundColor: UIColor.black]
            )
        }
        let pages = Array(repeating: fixture, count: 50)
        let clock = ContinuousClock()
        let start = clock.now
        let result = try await CaptureImportPipeline.prepareImages(pages) { _, _ in }
        let elapsed = start.duration(to: clock.now)

        #expect(result.count == CaptureImportLimits.production.maximumPages)
        #expect(elapsed < .seconds(20), "Fifty-page import exceeded the simulator budget: \(elapsed)")
    }

    @Test("A batch above the production limit is rejected before processing")
    @MainActor
    func rejectsFiftyFirstPage() async {
        let fixture = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 8)).image { _ in }
        let pages = Array(repeating: fixture, count: CaptureImportLimits.production.maximumPages + 1)

        await #expect(throws: CaptureImportError.tooManyPages(maximum: 50)) {
            _ = try await CaptureImportPipeline.prepareImages(pages) { _, _ in }
        }
    }

    @Test("Fifty-page PDF export streams every page and produces a verified artifact", .timeLimit(.minutes(1)))
    @MainActor
    func maximumBatchStreamingExport() async throws {
        let appState = AppState()
        let fixture = UIGraphicsImageRenderer(size: CGSize(width: 320, height: 480)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 320, height: 480))
            UIColor.black.setFill()
            context.fill(CGRect(x: 24, y: 24, width: 80, height: 12))
        }

        let documentID = "stream-export-\(UUID().uuidString)"
        var pageFiles: [String] = []
        for index in 0..<CaptureImportLimits.production.maximumPages {
            let fileID = "\(documentID)-\(index)"
            let fileName = try #require(appState.saveImage(fixture, id: fileID))
            pageFiles.append(fileName)
        }
        defer {
            for fileName in pageFiles {
                SecureFileStore.shared.removeFile(
                    at: AppState.resolveImageURL(fileName: fileName, isVaulted: false)
                )
            }
        }

        let document = DocumentItem(
            id: documentID,
            kind: .photo,
            title: "Streaming export fixture",
            imageFileName: pageFiles.first,
            pageFileNames: pageFiles
        )
        var progressUpdates: [Double] = []
        let artifact = try await ExportEngine.exportAsPDF(
            doc: document,
            pageRedactions: [:],
            watermark: nil,
            scale: 1
        ) { progress in
            progressUpdates.append(progress)
        }
        defer { try? FileManager.default.removeItem(at: artifact.url) }

        #expect(artifact.report.isVerified)
        #expect(PDFDocument(url: artifact.url)?.pageCount == CaptureImportLimits.production.maximumPages)
        #expect(progressUpdates.count == CaptureImportLimits.production.maximumPages)
        #expect(progressUpdates.last == 1)
    }
}
