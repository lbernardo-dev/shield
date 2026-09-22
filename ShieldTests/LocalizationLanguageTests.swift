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

    @Test("Trust Center copy is present and localized")
    @MainActor
    func trustCenterLocalizationKeys() {
        #expect(LanguageManager.shared.t("settings_info_protection_title", table: "SettingsInfo", language: .es) == "Cómo protege MaskID tus archivos")
        #expect(LanguageManager.shared.t("settings_info_protection_title", table: "SettingsInfo", language: .en) == "How MaskID protects your files")
        #expect(LanguageManager.shared.t("settings_info_protection_body", table: "SettingsInfo", language: .es).contains("OCR en el dispositivo"))
        #expect(LanguageManager.shared.t("settings_info_protection_body", table: "SettingsInfo", language: .en).contains("Protection Check"))
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

    @Test("New retention, expiry, and conversion keys translate in ES and EN")
    @MainActor
    func retentionAndConversionLocalizationKeys() {
        let keys: [(table: String, key: String)] = [
            ("Vault", "vault_expiring_alert_title"),
            ("Vault", "vault_expiring_alert_desc"),
            ("Vault", "vault_privacy_hygiene_title"),
            ("Vault", "vault_privacy_hygiene_desc"),
            ("Vault", "vault_privacy_hygiene_action"),
            ("Vault", "vault_share_protected"),
            ("Vault", "vault_biometric_reason"),
            ("Vault", "vault_reason"),
            ("Editor", "editor_sha256_hash"),
            ("Editor", "editor_watermark_preset_title"),
            ("Editor", "editor_pro_features_title"),
            ("Editor", "editor_pro_features_message"),
            ("Editor", "editor_try_pro_free"),
            ("Editor", "editor_export_standard"),
            ("Editor", "editor_reset_zoom"),
            ("Home", "home_quota_warning"),
            ("Onboarding", "ob_goal_pro_rental_benefit"),
            ("Onboarding", "ob_goal_pro_work_benefit"),
            ("Onboarding", "ob_goal_pro_vehicle_benefit"),
            ("Onboarding", "ob_goal_pro_banking_benefit"),
            ("Onboarding", "ob_goal_pro_travel_benefit")
        ]

        for item in keys {
            let esVal = LanguageManager.shared.t(item.key, table: item.table, language: .es)
            let enVal = LanguageManager.shared.t(item.key, table: item.table, language: .en)

            #expect(esVal != item.key, "Key \(item.key) failed to localize in ES")
            #expect(!esVal.isEmpty, "Key \(item.key) returned empty in ES")

            #expect(enVal != item.key, "Key \(item.key) failed to localize in EN")
            #expect(!enVal.isEmpty, "Key \(item.key) returned empty in EN")

            #expect(esVal != enVal, "Key \(item.key) is identical in ES and EN (\(esVal))")
        }
    }
}

