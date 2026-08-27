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

    @Test("Security and LockScreen localization keys exist and translate in ES and EN")
    @MainActor
    func securityAndLockLocalizationKeys() {
        // Spanish checks
        #expect(LanguageManager.shared.t("onboarding_security_title", table: "Onboarding", language: .es) == "Protege tu espacio privado")
        #expect(LanguageManager.shared.t("onboarding_security_enter_pin", table: "Onboarding", language: .es) == "Introduce un PIN de 6 dígitos")
        #expect(LanguageManager.shared.t("onboarding_security_confirm_pin", table: "Onboarding", language: .es) == "Confirma tu PIN")
        #expect(LanguageManager.shared.t("onboarding_security_mismatch", table: "Onboarding", language: .es) == "Los PIN no coinciden. Inténtalo de nuevo.")
        #expect(LanguageManager.shared.t("lock_unlock_faceid", table: "Auth", language: .es) == "Desbloquear con Face ID")
        #expect(LanguageManager.shared.t("lock_unlock_pin", table: "Auth", language: .es) == "Desbloquear con PIN")

        // English checks
        #expect(LanguageManager.shared.t("onboarding_security_title", table: "Onboarding", language: .en) == "Protect your private space")
        #expect(LanguageManager.shared.t("onboarding_security_enter_pin", table: "Onboarding", language: .en) == "Enter a 6-digit PIN")
        #expect(LanguageManager.shared.t("onboarding_security_confirm_pin", table: "Onboarding", language: .en) == "Confirm your PIN")
        #expect(LanguageManager.shared.t("onboarding_security_mismatch", table: "Onboarding", language: .en) == "PINs do not match. Try again.")
        #expect(LanguageManager.shared.t("lock_unlock_faceid", table: "Auth", language: .en) == "Unlock with Face ID")
        #expect(LanguageManager.shared.t("lock_unlock_pin", table: "Auth", language: .en) == "Unlock with PIN")
    }

    @Test("Runtime language change reactively updates resolved strings")
    @MainActor
    func runtimeLanguageSwitching() {
        let initialLang = LanguageManager.shared.current
        defer { LanguageManager.shared.current = initialLang }

        LanguageManager.shared.current = .es
        #expect(LanguageManager.shared.onboarding("onboarding_security_title") == "Protege tu espacio privado")
        #expect(LanguageManager.shared.auth("lock_unlock_faceid") == "Desbloquear con Face ID")

        LanguageManager.shared.current = .en
        #expect(LanguageManager.shared.onboarding("onboarding_security_title") == "Protect your private space")
        #expect(LanguageManager.shared.auth("lock_unlock_faceid") == "Unlock with Face ID")
    }

    @Test("The explicit table resolver mirrors runtime fallback for missing keys")
    @MainActor
    func explicitResolverFallsBackToKey() {
        #expect(LanguageManager.shared.t("model_category_does_not_exist", table: "Model", language: .es) == "model_category_does_not_exist")
    }
}