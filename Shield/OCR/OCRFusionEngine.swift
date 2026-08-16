import UIKit

// MARK: - OCRFusionEngine

enum OCRFusionEngine {
    /// Fuses observations from multiple pre-processing passes using spatial overlap (IoU) and confidence scoring.
    static func fuseObservations(passes: [[OCRService.TextObservation]]) -> [OCRService.TextObservation] {
        guard !passes.isEmpty else { return [] }
        guard passes.count > 1 else { return passes[0] }

        var fused: [OCRService.TextObservation] = []

        for pass in passes {
            for obs in pass {
                if let matchIndex = findMatchingIndex(for: obs, in: fused) {
                    let existing = fused[matchIndex]
                    // Select candidate with higher confidence & character completeness
                    let existingQuality = textQualityScore(existing)
                    let newQuality = textQualityScore(obs)

                    if newQuality > existingQuality {
                        fused[matchIndex] = obs
                    }
                } else {
                    fused.append(obs)
                }
            }
        }

        // Sort in reading order: top-to-bottom, then left-to-right
        return fused.sorted { a, b in
            if abs(a.boundingRect.origin.y - b.boundingRect.origin.y) > 0.02 {
                return a.boundingRect.origin.y < b.boundingRect.origin.y
            }
            return a.boundingRect.origin.x < b.boundingRect.origin.x
        }
    }

    private static func findMatchingIndex(
        for obs: OCRService.TextObservation,
        in list: [OCRService.TextObservation]
    ) -> Int? {
        var bestIndex: Int? = nil
        var bestIoU: CGFloat = 0.35 // Minimum 35% spatial overlap threshold

        for (index, candidate) in list.enumerated() {
            let iou = intersectionOverUnion(obs.boundingRect, candidate.boundingRect)
            if iou > bestIoU {
                bestIoU = iou
                bestIndex = index
            }
        }
        return bestIndex
    }

    private static func intersectionOverUnion(_ r1: CGRect, _ r2: CGRect) -> CGFloat {
        let intersection = r1.intersection(r2)
        guard !intersection.isNull && !intersection.isEmpty else { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = (r1.width * r1.height) + (r2.width * r2.height) - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }

    private static func textQualityScore(_ obs: OCRService.TextObservation) -> Double {
        let trimmed = obs.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        var score = obs.confidence * 100.0
        // Bonus for length and structured formatting
        score += min(Double(trimmed.count) * 1.5, 30.0)

        // Penalty for excessive non-alphanumeric noise
        let alphanumerics = trimmed.filter { $0.isLetter || $0.isNumber }
        let noiseRatio = 1.0 - (Double(alphanumerics.count) / Double(trimmed.count))
        score -= noiseRatio * 40.0

        return score
    }
}
