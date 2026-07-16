import CoreGraphics
import Testing
import UIKit
@testable import Shield

@Suite("OCR evidence and evaluation")
struct OCREvidenceTests {
    @Test("Detected entities retain page, box, source text, and confidence")
    func entityKeepsEvidence() throws {
        var fields = DocumentFields.empty
        fields.documentNumber = "12345678Z"
        fields.ocrFieldConfidence = ["documentNumber": 0.91]
        let observation = OCRService.TextObservation(
            text: "12345678Z",
            boundingRect: CGRect(x: 0.55, y: 0.2, width: 0.3, height: 0.08),
            confidence: 0.88
        )

        let pages = OCRService.buildPageEvidence(
            observations: [[observation]],
            extractedFields: [fields]
        )
        let page = try #require(pages.first)
        let entity = try #require(page.entities.first)
        let evidence = try #require(page.observations.first)

        #expect(page.pageIndex == 0)
        #expect(entity.kind == .documentNumber)
        #expect(entity.evidenceIDs == [evidence.id])
        #expect(entity.confidence == 0.88)
        #expect(evidence.boundingRect == observation.boundingRect)
    }

    @Test("Low-confidence evidence never creates an automatic mask")
    func lowConfidenceDoesNotMask() {
        let evidence = OCRTextEvidence(
            pageIndex: 0,
            text: "12345678Z",
            boundingRect: CGRect(x: 0.5, y: 0.2, width: 0.3, height: 0.08),
            confidence: 0.3
        )
        let entity = OCRSensitiveEntity(
            kind: .documentNumber,
            value: "12345678Z",
            pageIndex: 0,
            evidenceIDs: [evidence.id],
            confidence: 0.3
        )
        var fields = DocumentFields.empty
        fields.ocrPageEvidence = [
            OCRPageEvidence(pageIndex: 0, observations: [evidence], entities: [entity])
        ]

        #expect(AutoRedactions.ocrPrecisionModeRects(for: .banking, fields: fields).isEmpty)
    }

    @Test("Corpus metrics report precision, recall, and F1 reproducibly")
    func corpusMetrics() {
        let observation = OCRTextEvidence(
            pageIndex: 1,
            text: "AB123456",
            boundingRect: CGRect(x: 0.4, y: 0.2, width: 0.3, height: 0.08),
            confidence: 0.9
        )
        let entity = OCRSensitiveEntity(
            kind: .documentNumber,
            value: "AB123456",
            pageIndex: 1,
            evidenceIDs: [observation.id],
            confidence: 0.9
        )
        let detected = [OCRPageEvidence(pageIndex: 1, observations: [observation], entities: [entity])]
        let expected = [OCRExpectedEntity(pageIndex: 1, kind: .documentNumber, value: "AB 123456")]

        let metrics = OCREvaluator.evaluate(expected: expected, detected: detected)
        #expect(metrics.precision == 1)
        #expect(metrics.recall == 1)
        #expect(metrics.f1 == 1)
    }

    @Test("Validated financial and contact identifiers become evidenced entities")
    func genericPIIValidators() throws {
        let observations = [[
            OCRService.TextObservation(
                text: "Email: ana.garcia@example.com",
                boundingRect: CGRect(x: 0.1, y: 0.1, width: 0.7, height: 0.08),
                confidence: 0.99
            ),
            OCRService.TextObservation(
                text: "IBAN ES9121000418450200051332",
                boundingRect: CGRect(x: 0.1, y: 0.25, width: 0.8, height: 0.08),
                confidence: 0.98
            ),
            OCRService.TextObservation(
                text: "Tarjeta 4111 1111 1111 1111",
                boundingRect: CGRect(x: 0.1, y: 0.4, width: 0.8, height: 0.08),
                confidence: 0.97
            ),
            OCRService.TextObservation(
                text: "Tel +34 612 345 678",
                boundingRect: CGRect(x: 0.1, y: 0.55, width: 0.7, height: 0.08),
                confidence: 0.95
            )
        ]]
        let evidence = OCRService.buildPageEvidence(
            observations: observations,
            extractedFields: [.empty]
        )
        let page = try #require(evidence.first)
        let kinds = Set(page.entities.map(\.kind))

        #expect(kinds.contains(.email))
        #expect(kinds.contains(.iban))
        #expect(kinds.contains(.paymentCard))
        #expect(kinds.contains(.phoneNumber))
        #expect(page.entities.allSatisfy { !$0.evidenceIDs.isEmpty })
    }

    @Test("Invalid IBAN and card shapes are not promoted")
    func rejectsInvalidFinancialIdentifiers() throws {
        let observations = [[
            OCRService.TextObservation(
                text: "IBAN ES0012345678901234567890",
                boundingRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.08),
                confidence: 0.99
            ),
            OCRService.TextObservation(
                text: "Tarjeta 4111 1111 1111 1112",
                boundingRect: CGRect(x: 0.1, y: 0.3, width: 0.8, height: 0.08),
                confidence: 0.99
            )
        ]]
        let evidence = OCRService.buildPageEvidence(observations: observations, extractedFields: [.empty])
        let kinds = Set(try #require(evidence.first).entities.map(\.kind))
        #expect(!kinds.contains(.iban))
        #expect(!kinds.contains(.paymentCard))
    }

    @Test("Structured PII corpus meets release precision and recall thresholds")
    func structuredPIICorpusThresholds() {
        let observations = [
            [
                OCRService.TextObservation(
                    text: "Contacto ana.garcia@example.com",
                    boundingRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.08),
                    confidence: 0.99
                ),
                OCRService.TextObservation(
                    text: "IBAN ES91 2100 0418 4502 0005 1332",
                    boundingRect: CGRect(x: 0.1, y: 0.25, width: 0.8, height: 0.08),
                    confidence: 0.99
                ),
                OCRService.TextObservation(
                    text: "Referencia ES00 0000 0000 0000 0000 0000",
                    boundingRect: CGRect(x: 0.1, y: 0.4, width: 0.8, height: 0.08),
                    confidence: 0.99
                )
            ],
            [
                OCRService.TextObservation(
                    text: "Teléfono +34 612 345 678",
                    boundingRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.08),
                    confidence: 0.98
                ),
                OCRService.TextObservation(
                    text: "Tarjeta 4111-1111-1111-1111",
                    boundingRect: CGRect(x: 0.1, y: 0.25, width: 0.8, height: 0.08),
                    confidence: 0.98
                ),
                OCRService.TextObservation(
                    text: "Tarjeta inválida 4111-1111-1111-1112",
                    boundingRect: CGRect(x: 0.1, y: 0.4, width: 0.8, height: 0.08),
                    confidence: 0.98
                )
            ]
        ]
        let expected = [
            OCRExpectedEntity(pageIndex: 0, kind: .email, value: "ana.garcia@example.com"),
            OCRExpectedEntity(pageIndex: 0, kind: .iban, value: "ES9121000418450200051332"),
            OCRExpectedEntity(pageIndex: 1, kind: .phoneNumber, value: "+34612345678"),
            OCRExpectedEntity(pageIndex: 1, kind: .paymentCard, value: "4111111111111111")
        ]
        let detected = OCRService.buildPageEvidence(
            observations: observations,
            extractedFields: [.empty, .empty]
        )
        let metrics = OCREvaluator.evaluate(expected: expected, detected: detected)

        #expect(metrics.precision >= 0.98, "Structured PII precision regressed to \(metrics.precision)")
        #expect(metrics.recall >= 0.95, "Structured PII recall regressed to \(metrics.recall)")
    }

    @Test("Real Vision OCR recognizes a high-contrast privacy fixture", .timeLimit(.minutes(1)))
    @MainActor
    func actualVisionFixture() async {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1_400, height: 620)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1_400, height: 620))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 52, weight: .semibold),
                .foregroundColor: UIColor.black
            ]
            ("EMAIL ana.garcia@example.com" as NSString).draw(at: CGPoint(x: 60, y: 110), withAttributes: attributes)
            ("IBAN ES91 2100 0418 4502 0005 1332" as NSString).draw(at: CGPoint(x: 60, y: 260), withAttributes: attributes)
            ("DNI 12345678Z" as NSString).draw(at: CGPoint(x: 60, y: 410), withAttributes: attributes)
        }
        let observations = await OCRService.recognizeObservationsByPage(in: [image])
        let text = observations.flatMap { $0 }.map(\.text).joined(separator: " ").uppercased()
        #expect(text.contains("ANA.GARCIA@EXAMPLE.COM"))
        #expect(text.replacingOccurrences(of: " ", with: "").contains("ES9121000418450200051332"))
    }
}
