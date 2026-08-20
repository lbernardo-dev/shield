import UIKit
import ImageIO
import CryptoKit

// MARK: - ThumbnailManager

actor ThumbnailManager {
    static let shared = ThumbnailManager()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let thumbnailsDir: URL

    private init() {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.thumbnailsDir = docs.appendingPathComponent("shield_thumbnails", isDirectory: true)

        if !fileManager.fileExists(atPath: thumbnailsDir.path) {
            try? fileManager.createDirectory(at: thumbnailsDir, withIntermediateDirectories: true)
        }

        memoryCache.countLimit = 150
        memoryCache.totalCostLimit = 40 * 1024 * 1024 // 40MB max in-memory thumbnail cache
    }

    // MARK: - API

    func thumbnail(
        for filename: String,
        isVaulted: Bool = false,
        maxPixelSize: CGFloat = 360
    ) async -> UIImage? {
        let cacheKey = "\(filename)_\(Int(maxPixelSize))_\(isVaulted)" as NSString

        // 1. Memory Cache
        if let memoryImage = memoryCache.object(forKey: cacheKey) {
            return memoryImage
        }

        // 2. Vaulted documents are not cached unencrypted to public thumbnail disk
        if isVaulted {
            guard let fullImage = AppState.loadImage(fileName: filename, isVaulted: true) else {
                return nil
            }
            let downsampled = downsample(image: fullImage, maxPixelSize: maxPixelSize)
            if let downsampled {
                let cost = Int(downsampled.size.width * downsampled.size.height * 4)
                memoryCache.setObject(downsampled, forKey: cacheKey, cost: cost)
            }
            return downsampled
        }

        // 3. Disk Thumbnail Cache
        let thumbFileURL = thumbnailsDir.appendingPathComponent("\(filename)_\(Int(maxPixelSize)).jpg")
        if let diskImage = UIImage(contentsOfFile: thumbFileURL.path) {
            let cost = Int(diskImage.size.width * diskImage.size.height * 4)
            memoryCache.setObject(diskImage, forKey: cacheKey, cost: cost)
            return diskImage
        }

        // 4. Generate from original source file
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let originalURL = docs.appendingPathComponent("shield_images").appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: originalURL.path) else { return nil }

        guard let source = CGImageSourceCreateWithURL(originalURL as CFURL, nil) else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        let thumbnail = UIImage(cgImage: cgThumb)

        // Save to disk
        if let jpegData = thumbnail.jpegData(compressionQuality: 0.82) {
            try? jpegData.write(to: thumbFileURL, options: .atomic)
        }

        // Cache in memory
        let cost = Int(thumbnail.size.width * thumbnail.size.height * 4)
        memoryCache.setObject(thumbnail, forKey: cacheKey, cost: cost)

        return thumbnail
    }

    private func downsample(image: UIImage, maxPixelSize: CGFloat) -> UIImage? {
        guard let data = image.jpegData(compressionQuality: 0.9) ?? image.pngData() else { return image }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return image }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let cgThumb = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return image
        }
        return UIImage(cgImage: cgThumb)
    }

    func invalidate(filename: String) {
        let enumerator = fileManager.enumerator(at: thumbnailsDir, includingPropertiesForKeys: nil)
        while let file = enumerator?.nextObject() as? URL {
            if file.lastPathComponent.hasPrefix(filename) {
                try? fileManager.removeItem(at: file)
            }
        }
    }

    func clearAll() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: thumbnailsDir)
        try? fileManager.createDirectory(at: thumbnailsDir, withIntermediateDirectories: true)
    }
}
