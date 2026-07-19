import CoreGraphics
import Foundation
import Testing
@testable import Shield

@Suite("Redaction persistence")
struct RedactionCodingTests {
    @Test("A redaction round-trips without changing geometry or style")
    func redactionRoundTrip() throws {
        let original = Redaction(
            rect: CGRect(x: 0.125, y: 0.25, width: 0.5, height: 0.125),
            style: .block
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Redaction.self, from: data)

        #expect(decoded == original)
    }

    @Test("Every mask style remains Codable", arguments: MaskStyle.allCases)
    func everyMaskStyleRoundTrips(_ style: MaskStyle) throws {
        let data = try JSONEncoder().encode(style)
        let decoded = try JSONDecoder().decode(MaskStyle.self, from: data)

        #expect(decoded == style)
    }

    @Test("Normalized geometry clamps invalid and overflowing rectangles")
    func normalizedGeometryClampsRectangles() {
        let overflow = NormalizedDocumentGeometry.rect(
            CGRect(x: 0.92, y: -0.4, width: 0.5, height: 2)
        )
        #expect(overflow.minX >= 0)
        #expect(overflow.minY >= 0)
        #expect(overflow.maxX <= 1)
        #expect(overflow.maxY <= 1)

        let invalid = NormalizedDocumentGeometry.rect(
            CGRect(x: .nan, y: .infinity, width: -.infinity, height: .nan)
        )
        #expect(invalid.minX.isFinite)
        #expect(invalid.minY.isFinite)
        #expect(invalid.width >= 0.02)
        #expect(invalid.height >= 0.02)
    }

    @Test("A drag is committed as one reversible history transaction")
    @MainActor
    func dragHistoryTransaction() {
        let initial = Redaction(
            rect: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.1),
            style: .block
        )
        let document = DocumentItem(
            kind: .photo,
            title: "History",
            imageFileName: "fixture.jpg",
            pageRedactions: [DocumentPageRedactions(pageIndex: 0, redactions: [initial])]
        )
        let viewModel = EditorViewModel(doc: document)

        viewModel.beginRedactionTransform()
        viewModel.resizeRedaction(
            id: initial.id,
            newRect: CGRect(x: 0.25, y: 0.3, width: 0.35, height: 0.2)
        )
        viewModel.resizeRedaction(
            id: initial.id,
            newRect: CGRect(x: 0.4, y: 0.45, width: 0.4, height: 0.25)
        )

        #expect(viewModel.canUndo == false)
        viewModel.commitRedactionTransform()
        #expect(viewModel.canUndo)

        viewModel.undo()
        #expect(viewModel.redactions == [initial])
        viewModel.redo()
        #expect(viewModel.redactions.first?.rect == CGRect(x: 0.4, y: 0.45, width: 0.4, height: 0.25))
    }
}

@Suite("Shield Pro catalog")
struct ShieldProductCatalogTests {
    @Test("The catalog contains monthly, annual, and lifetime products")
    func subscriptionProductIdentifiers() {
        #expect(ShieldProduct.allCases.map(\.rawValue) == [
            "com.romerodev.shield.pro.monthly",
            "com.romerodev.shield.pro.annual",
            "com.romerodev.shield.pro.lifetime.unlock"
        ])
    }

    @Test("Savings use the current monthly, annual, and lifetime prices")
    @MainActor
    func savingsPercentages() {
        let manager = PremiumManager.shared
        #expect(manager.savingsPercent(referencePrice: Decimal(string: "35.88")!, offerPrice: Decimal(string: "29.99")!) == 16)
        #expect(manager.savingsPercent(referencePrice: Decimal(string: "59.98")!, offerPrice: Decimal(string: "49.99")!) == 17)
    }
}

@Suite("Shield public URLs")
struct ShieldPublicURLTests {
    @Test("Spanish and English pages map to their localized public routes")
    func localizedRoutes() {
        let expectedSpanish = [
            "https://lbernardo-dev.github.io/apps/es/casos/shield/",
            "https://lbernardo-dev.github.io/apps/es/casos/shield/privacidad/",
            "https://lbernardo-dev.github.io/apps/es/casos/shield/terminos/",
            "https://lbernardo-dev.github.io/apps/es/casos/shield/suscripciones/",
            "https://lbernardo-dev.github.io/apps/es/casos/shield/soporte/",
            "https://lbernardo-dev.github.io/apps/es/casos/shield/preguntas-frecuentes/"
        ]
        let expectedEnglish = [
            "https://lbernardo-dev.github.io/apps/en/case-studies/shield/",
            "https://lbernardo-dev.github.io/apps/en/case-studies/shield/privacy/",
            "https://lbernardo-dev.github.io/apps/en/case-studies/shield/terms/",
            "https://lbernardo-dev.github.io/apps/en/case-studies/shield/subscriptions/",
            "https://lbernardo-dev.github.io/apps/en/case-studies/shield/support/",
            "https://lbernardo-dev.github.io/apps/en/case-studies/shield/faq/"
        ]

        #expect(ShieldPublicPage.allCases.map { $0.localizedURL(for: .es).absoluteString } == expectedSpanish)
        #expect(ShieldPublicPage.allCases.map { $0.localizedURL(for: .en).absoluteString } == expectedEnglish)
    }

    @Test("Every page has the stable compatibility route")
    func compatibilityRoutes() {
        let expected = [
            "https://lbernardo-dev.github.io/apps/apps/shield/",
            "https://lbernardo-dev.github.io/apps/apps/shield/privacy/",
            "https://lbernardo-dev.github.io/apps/apps/shield/terms/",
            "https://lbernardo-dev.github.io/apps/apps/shield/subscriptions/",
            "https://lbernardo-dev.github.io/apps/apps/shield/support/",
            "https://lbernardo-dev.github.io/apps/apps/shield/faq/"
        ]

        #expect(ShieldPublicPage.allCases.map { $0.compatibilityURL.absoluteString } == expected)
    }
}
