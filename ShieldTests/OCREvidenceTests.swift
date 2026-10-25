import CoreGraphics
import ImageIO
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

    @Test("Batch suggestions use only evidence from the matching page")
    func batchSuggestionsStayPageSpecific() throws {
        let firstObservation = OCRTextEvidence(
            pageIndex: 0,
            text: "Address: 1 Main Street",
            boundingRect: CGRect(x: 0.08, y: 0.2, width: 0.42, height: 0.06),
            confidence: 0.98
        )
        let secondObservation = OCRTextEvidence(
            pageIndex: 1,
            text: "Address: 99 River Road",
            boundingRect: CGRect(x: 0.45, y: 0.68, width: 0.38, height: 0.07),
            confidence: 0.97
        )
        let firstEntity = OCRSensitiveEntity(
            kind: .address,
            value: "1 Main Street",
            pageIndex: 0,
            evidenceIDs: [firstObservation.id],
            confidence: 0.98
        )
        let secondEntity = OCRSensitiveEntity(
            kind: .address,
            value: "99 River Road",
            pageIndex: 1,
            evidenceIDs: [secondObservation.id],
            confidence: 0.97
        )
        var fields = DocumentFields.empty
        fields.ocrPageEvidence = [
            OCRPageEvidence(pageIndex: 0, observations: [firstObservation], entities: [firstEntity]),
            OCRPageEvidence(pageIndex: 1, observations: [secondObservation], entities: [secondEntity])
        ]
        let document = DocumentItem(
            kind: .photo,
            title: "Multipage lease",
            pageFileNames: ["page-1.jpg", "page-2.jpg", "page-3.jpg"],
            sourceType: .pdf,
            fields: fields
        )

        let plan = BatchRedactionPlanner.plan(for: document, mode: .rental)

        #expect(plan.pageRedactions.map(\.pageIndex) == [0, 1])
        #expect(plan.pagesWithSuggestions == 2)
        #expect(plan.pagesWithoutSuggestions == 1)
        let page0 = try #require(plan.pageRedactions.first(where: { $0.pageIndex == 0 })?.redactions.first)
        let page1 = try #require(plan.pageRedactions.first(where: { $0.pageIndex == 1 })?.redactions.first)
        #expect(page0.rect.midY < 0.4)
        #expect(page1.rect.midY > 0.6)
    }

    @Test("Face suggestion stays tight and privacy mask expands to the face boundary")
    func faceSuggestionCoordinatesAndProtectiveMaskStayPrecise() {
        let rect = OCRService.normalizedFaceRect(
            fromVisionBoundingBox: CGRect(x: 0.02, y: 0.1, width: 0.3, height: 0.5)
        )

        #expect(abs(rect.minX - 0.02) < 0.001)
        #expect(abs(rect.minY - 0.4) < 0.001)
        #expect(rect.maxX <= 1)
        #expect(rect.maxY <= 1)
        #expect(abs(rect.width - 0.3) < 0.001)
        #expect(abs(rect.height - 0.5) < 0.001)

        let mask = OCRService.protectiveFaceMaskRect(around: rect)
        #expect(abs(mask.minX) < 0.001)
        #expect(abs(mask.minY - 0.215) < 0.001)
        #expect(abs(mask.width - 0.383) < 0.001)
        #expect(abs(mask.height - 0.785) < 0.001)
    }

    @Test("Proposed face mask covers full face extent in upright and rotated photos")
    func protectiveFaceMaskCoversFaceForRoll() {
        let uprightDetection = CGRect(x: 0.314, y: 0.323, width: 0.361, height: 0.361)
        let uprightLabel = CGRect(x: 0.25, y: 0.19, width: 0.5, height: 0.59)
        let uprightMask = OCRService.protectiveFaceMaskRect(around: uprightDetection, rollDegrees: 0)
        #expect(uprightMask.contains(uprightLabel))

        let sidewaysDetection = CGRect(x: 0.313, y: 0.312, width: 0.367, height: 0.367)
        let sidewaysLabel = CGRect(x: 0.22, y: 0.25, width: 0.59, height: 0.5)
        let sidewaysMask = OCRService.protectiveFaceMaskRect(around: sidewaysDetection, rollDegrees: 89)
        #expect(sidewaysMask.contains(sidewaysLabel))
    }

    @Test("Face review runs for image-backed identity documents regardless of OCR type")
    func faceSuggestionPagesFollowImageAssets() {
        let identityScan = DocumentItem(
            kind: .dniESP,
            title: "Identity scan",
            imageFileName: "dni-front.jpg",
            pageFileNames: ["dni-front.jpg", "dni-back.jpg"]
        )
        let vectorOnlyDocument = DocumentItem(kind: .dniESP, title: "Typed identity")

        #expect(OCRService.faceSuggestionPageFileNames(for: identityScan) == ["dni-front.jpg", "dni-back.jpg"])
        #expect(OCRService.faceSuggestionPageFileNames(for: vectorOnlyDocument).isEmpty)
    }

    @Test("UIImage orientation maps to Vision image orientation including mirrors")
    func faceDetectionPreservesImageOrientation() {
        let orientations: [(UIImage.Orientation, CGImagePropertyOrientation)] = [
            (.up, .up),
            (.down, .down),
            (.left, .left),
            (.right, .right),
            (.upMirrored, .upMirrored),
            (.downMirrored, .downMirrored),
            (.leftMirrored, .leftMirrored),
            (.rightMirrored, .rightMirrored)
        ]

        for (imageOrientation, expected) in orientations {
            #expect(OCRService.visionOrientation(for: imageOrientation) == expected)
        }
    }

    @Test("Accepting a face suggestion applies a small opaque safety margin")
    @MainActor
    func acceptingFaceSuggestionUsesPreciseProtectiveMask() throws {
        let suggestion = OCRFaceSuggestion(
            pageIndex: 0,
            boundingRect: CGRect(x: 0.25, y: 0.25, width: 0.2, height: 0.24),
            confidence: 0.9
        )
        var fields = DocumentFields.empty
        fields.ocrFaceSuggestions = [suggestion]
        fields.ocrFaceSuggestionsRevision = OCRService.faceSuggestionRevision
        let document = DocumentItem(
            kind: .photo,
            title: "Face mask geometry",
            pageFileNames: ["face-mask-geometry.jpg"],
            fields: fields
        )
        let viewModel = EditorViewModel(doc: document)

        viewModel.acceptFaceSuggestion(suggestion)

        let redaction = try #require(viewModel.redactions.first)
        #expect(redaction.style == .block)
        #expect(redaction.rect == OCRService.protectiveFaceMaskRect(around: suggestion.boundingRect))
        #expect(viewModel.isFaceSuggestionProtected(suggestion))
    }

    @Test("Overlapping face suggestions are deduplicated without merging pages")
    func duplicateFaceSuggestionsAreRemovedPerPage() throws {
        let first = OCRFaceSuggestion(
            pageIndex: 2,
            boundingRect: CGRect(x: 0.2, y: 0.2, width: 0.3, height: 0.3),
            confidence: 0.91
        )
        let duplicate = OCRFaceSuggestion(
            pageIndex: 2,
            boundingRect: CGRect(x: 0.21, y: 0.21, width: 0.29, height: 0.29),
            confidence: 0.72
        )
        let otherPage = OCRFaceSuggestion(
            pageIndex: 3,
            boundingRect: first.boundingRect,
            confidence: 0.88
        )

        let deduplicated = OCRService.deduplicatedFaceSuggestions([duplicate, otherPage, first])

        #expect(deduplicated.count == 2)
        #expect(deduplicated.map(\.pageIndex) == [2, 3])
        #expect(try #require(deduplicated.first).confidence == 0.91)
    }

    @Test("On-demand OCR preserves page indexes when a source page cannot be loaded")
    @MainActor
    func optionalPageOCRPreservesIndexes() async {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 12, height: 12)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 12, height: 12))
        }

        let observations = await OCRService.recognizeObservationsByPage(inPages: [nil, image, nil])

        #expect(observations.count == 3)
        #expect(observations[0].isEmpty)
        #expect(observations[2].isEmpty)
    }

    @Test("Local search returns page boxes and confidence while keeping vault data private")
    func localSearchOccurrenceEvidence() throws {
        let observation = OCRTextEvidence(
            pageIndex: 1,
            text: "María García",
            boundingRect: CGRect(x: 0.2, y: 0.3, width: 0.4, height: 0.08),
            confidence: 0.93
        )
        var fields = DocumentFields.empty
        fields.ocrPageEvidence = [OCRPageEvidence(pageIndex: 1, observations: [observation], entities: [])]
        let document = DocumentItem(
            kind: .photo,
            title: "Sample",
            pageFileNames: ["one.jpg", "two.jpg"],
            fields: fields
        )

        let occurrence = try #require(document.localSearchOccurrences(for: "garcia").first)
        #expect(occurrence.pageIndex == 1)
        #expect(occurrence.boundingRect == observation.boundingRect)
        #expect(occurrence.confidence == 0.93)
        #expect(occurrence.protectedText == "María García")

        var vaulted = document
        vaulted.isVaulted = true
        #expect(vaulted.localSearchOccurrences(for: "garcia").isEmpty)
    }

    @Test("Face review suggestions and dismissals survive local document storage")
    func faceSuggestionsCodableRoundTrip() throws {
        let suggestion = OCRFaceSuggestion(
            pageIndex: 2,
            boundingRect: CGRect(x: 0.2, y: 0.3, width: 0.2, height: 0.25),
            confidence: 0.9,
            rollDegrees: 89
        )
        var fields = DocumentFields.empty
        fields.ocrFaceSuggestions = [suggestion]
        fields.ocrFaceSuggestionsRevision = OCRService.faceSuggestionRevision
        fields.ocrDismissedFaceSuggestionIDs = [suggestion.id]

        let decoded = try JSONDecoder().decode(DocumentFields.self, from: JSONEncoder().encode(fields))

        #expect(decoded.ocrFaceSuggestions == [suggestion])
        #expect(decoded.ocrFaceSuggestionsRevision == OCRService.faceSuggestionRevision)
        #expect(decoded.ocrDismissedFaceSuggestionIDs == [suggestion.id])
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
