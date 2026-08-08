import Foundation
import Testing
@testable import Shield

@Suite("Localization respects the requested language")
struct LocalizationLanguageTests {
    @Test("Label resolution honors the passed language instead of the current one")
    @MainActor
    func labelUsesRequestedLanguage() {
        #expect(DocumentCategory.identity.label(lang: .es) == "Identidad")
        #expect(DocumentCategory.identity.label(lang: .en) == "ID")
        #expect(AppTab.vault.label(lang: .es) == "Bóveda")
        #expect(AppTab.vault.label(lang: .en) == "Vault")
        #expect(OBGoal.travel.label(lang: .es) == "Viaje o inmigración")
        #expect(OBGoal.travel.label(lang: .en) == "Travel or immigration")
    }

    @Test("The explicit table resolver mirrors runtime fallback for missing keys")
    @MainActor
    func explicitResolverFallsBackToKey() {
        #expect(LanguageManager.shared.t("model_category_does_not_exist", table: "Model", language: .es) == "model_category_does_not_exist")
    }
}