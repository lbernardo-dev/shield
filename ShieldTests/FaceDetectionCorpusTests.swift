import Foundation
import Testing
import UIKit
@testable import Shield

private final class FaceDetectionCorpusBundleToken: NSObject {}

@Suite("Face detection synthetic corpus")
struct FaceDetectionCorpusTests {
    private struct Corpus: Decodable {
        let matchingIoUThreshold: Double
        let cases: [CorpusCase]
    }

    private struct CorpusCase: Decodable {
        let image: String
        let faces: [[Double]]
        let conditions: [String]
    }

    private struct Match {
        let predictionIndex: Int
        let labelIndex: Int
        let iou: Double
    }

    @Test("Vision suggestions are measured against the labeled synthetic corpus")
    func visionSuggestionsMatchSyntheticCorpus() async throws {
        let resourceURL = try #require(Bundle(for: FaceDetectionCorpusBundleToken.self).resourceURL)
            .appendingPathComponent("FaceDetection", isDirectory: true)
        let manifestURL = resourceURL.appendingPathComponent("manifest.json")
        let manifestData = try Data(contentsOf: manifestURL)
        let corpus = try JSONDecoder().decode(Corpus.self, from: manifestData)
        let threshold = corpus.matchingIoUThreshold

        var truePositiveCount = 0
        var falsePositiveCount = 0
        var falseNegativeCount = 0
        var faceCoverageSum = 0.0
        var maskAreaRatioSum = 0.0
        var matchedCount = 0

        for sample in corpus.cases {
            let imageURL = resourceURL.appendingPathComponent(sample.image)
            let imageData = try Data(contentsOf: imageURL)
            let image = try #require(UIImage(data: imageData), "Could not decode \(sample.image)")
            let suggestions: [OCRFaceSuggestion]
            do {
                suggestions = try await OCRService.detectFaceSuggestions(inPages: [image])
            } catch {
                throw CorpusError.detectorUnavailable(sample.image, String(reflecting: error))
            }
            let predictions = suggestions.map(\.boundingRect)
            let labels = try sample.faces.map(Self.rect(from:))
            let matches = Self.greedyMatches(predictions: predictions, labels: labels, threshold: threshold)
            let predictionIndexes = Set(matches.map(\.predictionIndex))
            let labelIndexes = Set(matches.map(\.labelIndex))
            let falsePositives = predictions.count - predictionIndexes.count
            let falseNegatives = labels.count - labelIndexes.count

            truePositiveCount += matches.count
            falsePositiveCount += falsePositives
            falseNegativeCount += falseNegatives

            for match in matches {
                let label = labels[match.labelIndex]
                let mask = OCRService.protectiveFaceMaskRect(
                    around: suggestions[match.predictionIndex].boundingRect,
                    rollDegrees: suggestions[match.predictionIndex].rollDegrees
                )
                faceCoverageSum += Self.coverage(of: label, by: mask)
                maskAreaRatioSum += Self.ratio(Self.area(mask), Self.area(label))
                matchedCount += 1
            }

            print("FACE_CORPUS image=\(sample.image) conditions=\(sample.conditions.joined(separator: ",")) labels=\(labels.count) predictions=\(predictions.count) tp=\(matches.count) fp=\(falsePositives) fn=\(falseNegatives) matchedIoU=\(matches.map { String(format: "%.3f", $0.iou) }.joined(separator: ","))")
        }

        let precision = Self.ratio(truePositiveCount, truePositiveCount + falsePositiveCount)
        let recall = Self.ratio(truePositiveCount, truePositiveCount + falseNegativeCount)
        let f1 = precision + recall > 0 ? 2 * precision * recall / (precision + recall) : 0
        let averageMaskCoverage = Self.ratio(faceCoverageSum, Double(matchedCount))
        let averageMaskAreaRatio = Self.ratio(maskAreaRatioSum, Double(matchedCount))
        print("FACE_CORPUS_SUMMARY samples=\(corpus.cases.count) labels=\(truePositiveCount + falseNegativeCount) tp=\(truePositiveCount) fp=\(falsePositiveCount) fn=\(falseNegativeCount) precision=\(String(format: "%.3f", precision)) recall=\(String(format: "%.3f", recall)) f1=\(String(format: "%.3f", f1)) meanMaskCoverage=\(String(format: "%.3f", averageMaskCoverage)) meanMaskAreaToLabel=\(String(format: "%.3f", averageMaskAreaRatio)) iouThreshold=\(String(format: "%.2f", threshold))")

        #expect(!corpus.cases.isEmpty)
        #expect(corpus.cases.allSatisfy { $0.faces.allSatisfy { $0.count == 4 } })
        #expect(precision >= 0.90, "Synthetic corpus face-detection precision was \(precision).")
        #expect(recall >= 0.90, "Synthetic corpus face-detection recall was \(recall).")
        #expect(averageMaskCoverage >= 0.90, "Synthetic corpus face-mask coverage was \(averageMaskCoverage).")
        #expect(averageMaskAreaRatio <= 2.0, "Synthetic corpus mask area to labeled-face area was \(averageMaskAreaRatio).")
    }

    private static func rect(from components: [Double]) throws -> CGRect {
        guard components.count == 4 else {
            throw CorpusError.invalidFaceBox(components)
        }
        return CGRect(x: components[0], y: components[1], width: components[2], height: components[3])
    }

    private static func greedyMatches(
        predictions: [CGRect],
        labels: [CGRect],
        threshold: Double
    ) -> [Match] {
        let candidates = predictions.indices.flatMap { predictionIndex in
            labels.indices.compactMap { labelIndex -> Match? in
                let overlap = iou(predictions[predictionIndex], labels[labelIndex])
                guard overlap >= threshold else { return nil }
                return Match(predictionIndex: predictionIndex, labelIndex: labelIndex, iou: overlap)
            }
        }
        .sorted { $0.iou > $1.iou }

        var matchedPredictions = Set<Int>()
        var matchedLabels = Set<Int>()
        var matches: [Match] = []
        for candidate in candidates where
            !matchedPredictions.contains(candidate.predictionIndex) &&
            !matchedLabels.contains(candidate.labelIndex) {
            matchedPredictions.insert(candidate.predictionIndex)
            matchedLabels.insert(candidate.labelIndex)
            matches.append(candidate)
        }
        return matches
    }

    private static func iou(_ first: CGRect, _ second: CGRect) -> Double {
        let intersection = first.intersection(second)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = first.width * first.height + second.width * second.height - intersectionArea
        return unionArea > 0 ? Double(intersectionArea / unionArea) : 0
    }

    private static func coverage(of label: CGRect, by mask: CGRect) -> Double {
        let intersection = label.intersection(mask)
        guard !intersection.isNull, !intersection.isEmpty else { return 0 }
        let labelArea = area(label)
        return labelArea > 0 ? Double(intersection.width * intersection.height / labelArea) : 0
    }

    private static func area(_ rect: CGRect) -> Double {
        Double(max(0, rect.width) * max(0, rect.height))
    }

    private static func ratio(_ numerator: Int, _ denominator: Int) -> Double {
        denominator > 0 ? Double(numerator) / Double(denominator) : 0
    }

    private static func ratio(_ numerator: Double, _ denominator: Double) -> Double {
        denominator > 0 ? numerator / denominator : 0
    }

    private enum CorpusError: Error {
        case invalidFaceBox([Double])
        case detectorUnavailable(String, String)
    }
}
