import Foundation
import Testing
import UIKit
@testable import Shield

@Suite("OCR Engine Precision & Mathematical Auto-Repair")
struct OCREnginePrecisionTests {
    @Test("Spanish DNI Modulo 23 Direct Validation & Auto-Repair")
    func spanishDNICorrection() {
        // Direct valid DNI
        let validDNI = "12345678Z"
        let res1 = OCRErrorCorrector.correctSpanishID(validDNI)
        #expect(res1 != nil)
        #expect(res1?.isValid == true)
        #expect(res1?.corrected == "12345678Z")

        // DNI with OCR digit confusion: 'I' instead of '1'
        let confusedDNI1 = "I2345678Z"
        let res2 = OCRErrorCorrector.correctSpanishID(confusedDNI1)
        #expect(res2 != nil)
        #expect(res2?.isValid == true)
        #expect(res2?.corrected == "12345678Z")

        // DNI with OCR digit confusion: 'S' instead of '5'
        let confusedDNI2 = "1234S678Z"
        let res3 = OCRErrorCorrector.correctSpanishID(confusedDNI2)
        #expect(res3 != nil)
        #expect(res3?.isValid == true)
        #expect(res3?.corrected == "12345678Z")

        // DNI with OCR digit confusion: 'O' instead of '0'
        let confusedDNI3 = "O0000000T"
        let res4 = OCRErrorCorrector.correctSpanishID(confusedDNI3)
        #expect(res4 != nil)
        #expect(res4?.isValid == true)
        #expect(res4?.corrected == "00000000T")
    }

    @Test("Spanish NIE Auto-Repair")
    func spanishNIECorrection() {
        // Valid NIE: Y1234567X (11234567 % 23 -> X)
        let validNIE = "Y1234567X"
        let res1 = OCRErrorCorrector.correctSpanishID(validNIE)
        #expect(res1 != nil)
        #expect(res1?.isValid == true)
        #expect(res1?.corrected == "Y1234567X")

        // NIE with OCR letter confusion in digits: 'I' instead of '1'
        let confusedNIE = "YI234567X"
        let res2 = OCRErrorCorrector.correctSpanishID(confusedNIE)
        #expect(res2 != nil)
        #expect(res2?.isValid == true)
        #expect(res2?.corrected == "Y1234567X")
    }

    @Test("MRZ ICAO 9303 Check Digit Verification & Repair")
    func mrzCheckDigitRepair() {
        // Date of birth: 140590, check digit: 7
        // 1*7 + 4*3 + 0*1 + 5*7 + 9*3 + 0*1 = 7 + 12 + 0 + 35 + 27 + 0 = 81 % 10 = 1... wait let's test verify
        let direct = OCRErrorCorrector.verifyAndRepairMRZField(value: "140590", checkDigit: "1")
        #expect(direct.isValid == true)

        // Confused OCR character: 'O' instead of '0' -> "14O59O"
        let repaired = OCRErrorCorrector.verifyAndRepairMRZField(value: "14O59O", checkDigit: "1")
        #expect(repaired.isValid == true)
        #expect(repaired.repaired == "140590")
    }

    @Test("IBAN Formatter and Character Sanitization")
    func ibanSanitization() {
        let rawIBAN = "ESOO 1234 5678 9O 123456789O"
        let corrected = OCRErrorCorrector.correctIBAN(rawIBAN)
        #expect(corrected != nil)
        #expect(corrected?.hasPrefix("ES00") == true)
    }

    @Test("OCR Spatial Observation Fusion")
    func observationSpatialFusion() {
        let obs1 = OCRService.TextObservation(
            text: "REINO DE ESPAÑA",
            boundingRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.05),
            confidence: 0.85
        )
        let obs2Pass2 = OCRService.TextObservation(
            text: "REINO DE ESPAÑA",
            boundingRect: CGRect(x: 0.105, y: 0.102, width: 0.79, height: 0.048),
            confidence: 0.98
        )
        let obs3Unique = OCRService.TextObservation(
            text: "DNI: 12345678Z",
            boundingRect: CGRect(x: 0.1, y: 0.3, width: 0.5, height: 0.05),
            confidence: 0.95
        )

        let fused = OCRFusionEngine.fuseObservations(passes: [[obs1], [obs2Pass2, obs3Unique]])
        #expect(fused.count == 2)
        #expect(fused.contains(where: { $0.text == "REINO DE ESPAÑA" && $0.confidence == 0.98 }))
        #expect(fused.contains(where: { $0.text == "DNI: 12345678Z" }))
    }

    @Test("OCR Preprocessor Generates Valid Contrast and Shadow Variants")
    func preprocessorVariantsGeneration() {
        let size = CGSize(width: 400, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let sampleImage = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            UIColor.black.setFill()
            ctx.fill(CGRect(x: 50, y: 50, width: 200, height: 40))
        }

        let variants = OCRImagePreprocessor.generateOptimizedVariants(from: sampleImage)
        #expect(!variants.isEmpty)
        #expect(variants.count >= 2)
    }

    @Test("OCR Engine Manager Configuration & Language Pack Lifecycle")
    @MainActor
    func engineManagerLifecycle() async {
        let manager = OCREngineManager.shared
        manager.activeMode = .visionUltra
        #expect(manager.activeMode == .visionUltra)

        manager.activeMode = .openEngine
        #expect(manager.activeMode == .openEngine)

        // Reset to ultra
        manager.activeMode = .visionUltra

        // Test pack download and delete
        if let spaPack = manager.languagePacks.first(where: { $0.id == "spa" }) {
            await manager.downloadPack(spaPack)
            let updatedSpa = manager.languagePacks.first(where: { $0.id == "spa" })
            #expect(updatedSpa?.isInstalled == true)

            manager.deletePack(updatedSpa!)
            let deletedSpa = manager.languagePacks.first(where: { $0.id == "spa" })
            #expect(deletedSpa?.isInstalled == false)
        }
    }
}
