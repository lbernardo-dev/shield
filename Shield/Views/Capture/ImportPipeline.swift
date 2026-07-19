import Foundation
import ImageIO
import PDFKit
import UIKit

enum CaptureImportError: Error, Equatable, Sendable, LocalizedError {
    case emptyInput
    case unsupportedFormat
    case protectedPDF
    case fileTooLarge(maximumMB: Int)
    case tooManyPages(maximum: Int)
    case memoryBudgetExceeded(maximumMB: Int)
    case unreadablePage(index: Int)
    case sourceReadFailed
    case storageWriteFailed

    var errorDescription: String? {
        switch self {
        case .emptyInput: return LanguageManager.backgroundText("capture_error_empty", table: "Capture")
        case .unsupportedFormat: return LanguageManager.backgroundText("capture_error_unsupported", table: "Capture")
        case .protectedPDF: return LanguageManager.backgroundText("capture_error_protected_pdf", table: "Capture")
        case .fileTooLarge(let maximum): return LanguageManager.backgroundText("capture_error_too_large", table: "Capture", maximum)
        case .tooManyPages(let maximum): return LanguageManager.backgroundText("capture_error_too_many_pages", table: "Capture", maximum)
        case .memoryBudgetExceeded(let maximum): return LanguageManager.backgroundText("capture_error_memory", table: "Capture", maximum)
        case .unreadablePage(let index): return LanguageManager.backgroundText("capture_error_unreadable_page", table: "Capture", index + 1)
        case .sourceReadFailed: return LanguageManager.backgroundText("capture_error_source_read", table: "Capture")
        case .storageWriteFailed: return LanguageManager.backgroundText("capture_error_storage_write", table: "Capture")
        }
    }
}

struct CaptureImportLimits: Sendable, Equatable {
    var maximumFileBytes = 200 * 1_024 * 1_024
    var maximumPages = 50
    var maximumPixelDimension = 2_048
    var maximumDecodedBytes = 256 * 1_024 * 1_024

    nonisolated static let production = CaptureImportLimits()
}

struct PreparedCaptureImport: @unchecked Sendable {
    let pages: [UIImage]
    let title: String?
    let sourceType: ImportedDocumentSource
    let sourceData: Data?
    let sourceExtension: String?
}

enum CaptureImportPipeline {
    typealias ProgressHandler = @MainActor @Sendable (_ completed: Int, _ total: Int) -> Void

    nonisolated static func prepareFile(
        at url: URL,
        limits: CaptureImportLimits = .production,
        progress: ProgressHandler
    ) async throws -> PreparedCaptureImport {
        try Task.checkCancellation()
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile != false else { throw CaptureImportError.unsupportedFormat }
        if let size = values.fileSize, size > limits.maximumFileBytes {
            throw CaptureImportError.fileTooLarge(maximumMB: limits.maximumFileBytes / 1_024 / 1_024)
        }

        if let image = downsampleImage(at: url, maximumDimension: limits.maximumPixelDimension) {
            try validateMemory(for: [image], limits: limits)
            await progress(1, 1)
            return PreparedCaptureImport(
                pages: [image],
                title: url.deletingPathExtension().lastPathComponent,
                sourceType: .image,
                sourceData: nil,
                sourceExtension: nil
            )
        }

        guard let document = PDFDocument(url: url), document.pageCount > 0 else {
            throw CaptureImportError.unsupportedFormat
        }
        guard !document.isLocked else {
            throw CaptureImportError.protectedPDF
        }
        guard document.pageCount <= limits.maximumPages else {
            throw CaptureImportError.tooManyPages(maximum: limits.maximumPages)
        }

        var pages: [UIImage] = []
        pages.reserveCapacity(document.pageCount)
        var decodedBytes = 0
        for pageIndex in 0..<document.pageCount {
            try Task.checkCancellation()
            guard let page = document.page(at: pageIndex) else {
                throw CaptureImportError.unreadablePage(index: pageIndex)
            }
            let bounds = page.bounds(for: .mediaBox)
            let maximum = CGFloat(limits.maximumPixelDimension)
            let scale = min(1, maximum / max(bounds.width, bounds.height))
            let target = CGSize(
                width: max(1, bounds.width * scale),
                height: max(1, bounds.height * scale)
            )
            let image = page.thumbnail(of: target, for: .mediaBox).normalizedForShield()
            decodedBytes += estimatedDecodedBytes(of: image)
            guard decodedBytes <= limits.maximumDecodedBytes else {
                throw CaptureImportError.memoryBudgetExceeded(maximumMB: limits.maximumDecodedBytes / 1_024 / 1_024)
            }
            pages.append(image)
            await progress(pageIndex + 1, document.pageCount)
        }

        try Task.checkCancellation()
        guard let sourceData = try? Data(contentsOf: url, options: [.mappedIfSafe]) else {
            throw CaptureImportError.sourceReadFailed
        }
        return PreparedCaptureImport(
            pages: pages,
            title: url.deletingPathExtension().lastPathComponent,
            sourceType: .pdf,
            sourceData: sourceData,
            sourceExtension: "pdf"
        )
    }

    nonisolated static func prepareImages(
        _ images: [UIImage],
        limits: CaptureImportLimits = .production,
        progress: ProgressHandler
    ) async throws -> [UIImage] {
        guard !images.isEmpty else { throw CaptureImportError.emptyInput }
        guard images.count <= limits.maximumPages else {
            throw CaptureImportError.tooManyPages(maximum: limits.maximumPages)
        }

        var prepared: [UIImage] = []
        prepared.reserveCapacity(images.count)
        var decodedBytes = 0
        for (index, image) in images.enumerated() {
            try Task.checkCancellation()
            let page = downsampleImage(image, maximumDimension: limits.maximumPixelDimension)
                .normalizedForShield()
            decodedBytes += estimatedDecodedBytes(of: page)
            guard decodedBytes <= limits.maximumDecodedBytes else {
                throw CaptureImportError.memoryBudgetExceeded(maximumMB: limits.maximumDecodedBytes / 1_024 / 1_024)
            }
            prepared.append(page)
            await progress(index + 1, images.count)
        }
        return prepared
    }

    nonisolated static func downsampleImage(data: Data, maximumDimension: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return thumbnail(from: source, maximumDimension: maximumDimension)
    }

    private nonisolated static func downsampleImage(at url: URL, maximumDimension: Int) -> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return thumbnail(from: source, maximumDimension: maximumDimension)
    }

    private nonisolated static func thumbnail(
        from source: CGImageSource,
        maximumDimension: Int
    ) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maximumDimension
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        return UIImage(cgImage: image)
    }

    private nonisolated static func downsampleImage(
        _ image: UIImage,
        maximumDimension: Int
    ) -> UIImage {
        let largest = max(image.size.width, image.size.height) * image.scale
        guard largest > CGFloat(maximumDimension) else { return image }
        let factor = CGFloat(maximumDimension) / largest
        let target = CGSize(width: image.size.width * factor, height: image.size.height * factor)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private nonisolated static func estimatedDecodedBytes(of image: UIImage) -> Int {
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        return width.multipliedReportingOverflow(by: height).partialValue * 4
    }

    private nonisolated static func validateMemory(
        for images: [UIImage],
        limits: CaptureImportLimits
    ) throws {
        let bytes = images.reduce(0) { $0 + estimatedDecodedBytes(of: $1) }
        guard bytes <= limits.maximumDecodedBytes else {
            throw CaptureImportError.memoryBudgetExceeded(maximumMB: limits.maximumDecodedBytes / 1_024 / 1_024)
        }
    }
}
