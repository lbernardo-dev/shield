import UIKit
import Vision

// MARK: - BarcodeDetectionItem

struct BarcodeDetectionItem: Identifiable, Sendable {
    let id: String
    let symbology: String
    let payload: String?
    let normalizedRect: CGRect // 0..1 in standard top-left coordinate system

    init(id: String = UUID().uuidString, symbology: String, payload: String?, normalizedRect: CGRect) {
        self.id = id
        self.symbology = symbology
        self.payload = payload
        self.normalizedRect = normalizedRect
    }

    var isHighRisk: Bool {
        symbology.contains("PDF417") || symbology.contains("QR") || symbology.contains("Aztec") || symbology.contains("DataMatrix")
    }
}

// MARK: - BarcodeDetector

enum BarcodeDetector {
    static func detectBarcodes(in image: UIImage) async -> [BarcodeDetectionItem] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNDetectBarcodesRequest { req, error in
                guard error == nil, let results = req.results as? [VNBarcodeObservation] else {
                    continuation.resume(returning: [])
                    return
                }

                let items = results.map { obs -> BarcodeDetectionItem in
                    let box = obs.boundingBox
                    let topY = 1.0 - box.origin.y - box.height
                    let standardRect = CGRect(x: box.origin.x, y: topY, width: box.width, height: box.height)

                    let symbologyName = obs.symbology.rawValue.replacingOccurrences(of: "VNBarcodeSymbology", with: "")

                    return BarcodeDetectionItem(
                        symbology: symbologyName,
                        payload: obs.payloadStringValue,
                        normalizedRect: standardRect
                    )
                }

                continuation.resume(returning: items)
            }

            request.symbologies = [
                .qr,
                .pdf417,
                .aztec,
                .dataMatrix,
                .code128,
                .code39,
                .ean13,
                .itf14,
                .upce
            ]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
}
