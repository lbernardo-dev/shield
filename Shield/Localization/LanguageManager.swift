import SwiftUI

// MARK: - AppLanguage

enum AppLanguage: String, CaseIterable, Codable {
    case es, en
    var displayName: String { rawValue.uppercased() }
}

// MARK: - LanguageManager

@Observable
@MainActor
final class LanguageManager {
    static let shared = LanguageManager()

    private static let overrideKey = "shield.language"
    private static let manualOverrideFlagKey = "shield.language.isManualOverride"

    /// Guards the initializer's own assignment to `current` from being
    /// recorded as an explicit user override — only a later, real change
    /// (e.g. the in-app language toggle) should pin the language and stop
    /// following the system locale.
    private var isBootstrapping = true

    var current: AppLanguage {
        didSet {
            guard !isBootstrapping, current != oldValue else { return }
            UserDefaults.standard.set(true, forKey: Self.manualOverrideFlagKey)
            UserDefaults.standard.set(current.rawValue, forKey: Self.overrideKey)
        }
    }

    var currentLanguage: AppLanguage { current }

    func localize(key: String) -> String {
        let normalizedKey = key.lowercased()
        if normalizedKey.hasPrefix("common_") { return common(normalizedKey) }
        if normalizedKey.hasPrefix("model_") { return model(normalizedKey) }
        if normalizedKey.hasPrefix("onboarding_") { return onboarding(normalizedKey) }
        if normalizedKey.hasPrefix("home_") { return home(normalizedKey) }
        if normalizedKey.hasPrefix("editor_") { return editor(normalizedKey) }
        if normalizedKey.hasPrefix("capture_") { return capture(normalizedKey) }
        if normalizedKey.hasPrefix("settings_") { return settings(normalizedKey) }
        if normalizedKey.hasPrefix("vault_") { return vault(normalizedKey) }
        if normalizedKey.hasPrefix("paywall_") { return paywall(normalizedKey) }
        if normalizedKey.hasPrefix("gallery_") { return gallery(normalizedKey) }
        if normalizedKey.hasPrefix("auth_") || normalizedKey.hasPrefix("lock_") { return auth(normalizedKey) }
        return common(normalizedKey)
    }

    func localize(key: String, args: CVarArg...) -> String {
        let format = localize(key: key)
        return String(format: format, locale: Locale(identifier: current.rawValue), arguments: args)
    }

    init() {
        if UserDefaults.standard.bool(forKey: Self.manualOverrideFlagKey),
           let saved = UserDefaults.standard.string(forKey: Self.overrideKey),
           let lang = AppLanguage(rawValue: saved) {
            current = lang
        } else {
            // No explicit in-app choice yet: defer to the OS's own locale
            // resolution (device language, or the app's per-app Language
            // override under Settings > General > Language & Region),
            // so the app tracks the system automatically until the user
            // picks a language in-app.
            current = Self.systemPreferredLanguage()
        }
        isBootstrapping = false
    }

    /// Resolves the best-matching supported locale using the same
    /// preference-ranked algorithm Foundation uses for bundle resources,
    /// rather than a hand-rolled string prefix check.
    private static func systemPreferredLanguage() -> AppLanguage {
        let supported = AppLanguage.allCases.map(\.rawValue)
        let preferred = Bundle.preferredLocalizations(from: supported)
        guard let code = preferred.first, let lang = AppLanguage(rawValue: code) else {
            return .en
        }
        return lang
    }

    /// Core resolver — pulls from the specified String Catalog (.xcstrings)
    func t(_ key: String, table: String) -> String {
        let locale = Locale(identifier: current.rawValue)
        
        // 1. Try modern String(localized:) with LocalizedStringResource (native for .xcstrings)
        let resource = LocalizedStringResource(
            String.LocalizationValue(key),
            table: table,
            locale: locale,
            bundle: .atURL(Bundle.main.bundleURL)
        )
        let localized = String(localized: resource)
        
        // If it found a translation (different from key), return it
        if localized != key {
            return localized
        }
        
        // 2. Fallback to Bundle-based lookup (in case .xcstrings are compiled to .strings)
        let langCode = current.rawValue
        let bundle: Bundle
        if let path = Bundle.main.path(forResource: langCode, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            bundle = langBundle
        } else {
            bundle = .main
        }
        
        let bundleLocalized = bundle.localizedString(forKey: key, value: key, table: table)
        if bundleLocalized != key {
            return bundleLocalized
        }
        
        // 3. Try Common table as a final fallback
        if table != "Common" {
            let commonResource = LocalizedStringResource(
                String.LocalizationValue(key),
                table: "Common",
                locale: locale,
                bundle: .atURL(Bundle.main.bundleURL)
            )
            let commonLocalized = String(localized: commonResource)
            if commonLocalized != key {
                return commonLocalized
            }
            
            let commonBundleLocalized = bundle.localizedString(forKey: key, value: key, table: "Common")
            if commonBundleLocalized != key {
                return commonBundleLocalized
            }
        }
        
        if let dynamic = Self.dynamicFallbackText(key, language: current) {
            return dynamic
        }

        return key
    }

    /// Resolver with arguments
    func t(_ key: String, table: String, args: CVarArg...) -> String {
        t(key, table: table, argsArray: args)
    }

    /// Resolves a catalog key against an explicit language rather than the
    /// current app language.
    func t(_ key: String, table: String, language: AppLanguage) -> String {
        let locale = Locale(identifier: language.rawValue)
        let resource = LocalizedStringResource(
            String.LocalizationValue(key),
            table: table,
            locale: locale,
            bundle: .atURL(Bundle.main.bundleURL)
        )
        let localized = String(localized: resource)
        if localized != key {
            return localized
        }
        if let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
           let languageBundle = Bundle(path: path) {
            let bundled = languageBundle.localizedString(forKey: key, value: key, table: table)
            if bundled != key {
                return bundled
            }
        }
        if let dynamic = Self.dynamicFallbackText(key, language: language) {
            return dynamic
        }
        return key
    }

    nonisolated private static func dynamicFallbackText(_ key: String, language: AppLanguage) -> String? {
        let isSpanish = language == .es
        switch key {
        case "settings_ocr_engine_title":
            return isSpanish ? "Motor OCR y Calidad" : "OCR Engine & Quality"
        case "settings_ocr_engine_subtitle":
            return isSpanish ? "Motores locales, preprocesamiento y modelos" : "Local engines, pre-processing and models"
        case "settings_ocr_engine_header_title":
            return isSpanish ? "Reconocimiento OCR 100% Local" : "100% On-Device OCR Recognition"
        case "settings_ocr_engine_header_desc":
            return isSpanish ? "Privacidad absoluta. Ninguna imagen o texto sale de tu dispositivo." : "Zero-knowledge privacy. No images or text leave your device."
        case "settings_ocr_active_engine":
            return isSpanish ? "Motor de Reconocimiento Activo" : "Active Recognition Engine"
        case "settings_ocr_enhancement_title":
            return isSpanish ? "Preprocesamiento Neuro-Gráfico" : "Neuro-Graphic Pre-Processing"
        case "settings_ocr_shadow_removal":
            return isSpanish ? "Eliminación de sombras y reflejos" : "Shadow and glare removal"
        case "settings_ocr_shadow_removal_desc":
            return isSpanish ? "Normaliza la iluminación en fotos de documentos" : "Normalizes document lighting across surface"
        case "settings_ocr_contrast":
            return isSpanish ? "Realce adaptativo de contraste" : "Adaptive contrast enhancement"
        case "settings_ocr_contrast_desc":
            return isSpanish ? "Aumenta la legibilidad en fondos con patrones y marcas" : "Boosts readability on patterned ID backgrounds"
        case "settings_ocr_deskew":
            return isSpanish ? "Auto-orientación y corrección angular" : "Auto-orientation and deskew"
        case "settings_ocr_deskew_desc":
            return isSpanish ? "Corrige documentos inclinados o fotografiados de lado" : "Corrects tilted or rotated document captures"
        case "settings_ocr_math_correction":
            return isSpanish ? "Auto-corrección matemática de PII" : "Mathematical PII auto-repair"
        case "settings_ocr_math_correction_desc":
            return isSpanish ? "Verifica y repara DNI, NIE, MRZ e IBAN por dígito de control" : "Verifies and repairs DNI, NIE, MRZ and IBAN checksums"
        case "settings_ocr_local_models":
            return isSpanish ? "Modelos Libres y Paquetes de Idioma" : "Free Open Models & Language Packs"
        case "settings_ocr_download":
            return isSpanish ? "Descargar" : "Download"
        case "settings_ocr_diagnostics":
            return isSpanish ? "Diagnóstico y Prueba de Motor" : "Diagnostics & Engine Test"
        case "settings_ocr_diagnostics_desc":
            return isSpanish ? "Verifica la precisión y el tiempo de respuesta del pipeline OCR en tu dispositivo" : "Validates precision and latency of the on-device OCR pipeline"
        case "settings_ocr_run_test":
            return isSpanish ? "Ejecutar Diagnóstico Local" : "Run Local Diagnostic"
        default:
            return nil
        }
    }

    /// Internal resolver that takes an array of arguments
    private func t(_ key: String, table: String, argsArray: [CVarArg]) -> String {
        let format = t(key, table: table)
        return String(format: format, locale: Locale(identifier: current.rawValue), arguments: argsArray)
    }

    // MARK: - Aliases for easier migration

    func str(_ key: String, table: String) -> String {
        t(key, table: table)
    }

    func str(_ key: String, table: String, args: CVarArg...) -> String {
        let format = t(key, table: table)
        return String(format: format, locale: Locale(identifier: current.rawValue), arguments: args)
    }

    // MARK: - Catalog shortcuts

    func common(_ key: String, _ args: CVarArg...) -> String { t(key, table: "Common", argsArray: args) }
    func onboarding(_ key: String, _ args: CVarArg...) -> String { t(key, table: "Onboarding", argsArray: args) }
    func home(_ key: String, _ args: CVarArg...) -> String { t(key, table: "Home", argsArray: args) }
    func editor(_ key: String, _ args: CVarArg...) -> String { t(key, table: "Editor", argsArray: args) }
    func capture(_ key: String, _ args: CVarArg...) -> String { t(key, table: "Capture", argsArray: args) }
    func settings(_ key: String, _ args: CVarArg...) -> String {
        let existing = t(key, table: "Settings", argsArray: args)
        guard existing == key else { return existing }
        return t(key, table: "SettingsInfo", argsArray: args)
    }
    func vault(_ key: String, _ args: CVarArg...) -> String { t(key, table: "Vault", argsArray: args) }
    func paywall(_ key: String, _ args: CVarArg...) -> String { t(key, table: "Paywall", argsArray: args) }
    func gallery(_ key: String, _ args: CVarArg...) -> String { t(key, table: "Gallery", argsArray: args) }
    func model(_ key: String, _ args: CVarArg...) -> String { t(key, table: "Model", argsArray: args) }
    func auth(_ key: String, _ args: CVarArg...) -> String { t(key, table: "Auth", argsArray: args) }

    // MARK: - Off-main-actor resolver

    /// Localizes a key without touching main-actor state. Safe from any
    /// isolation context (e.g. `LocalizedError.errorDescription` on background
    /// import pipelines). Reads the persisted language directly.
    nonisolated static func backgroundText(_ key: String, table: String, _ args: CVarArg...) -> String {
        let language = UserDefaults.standard.string(forKey: "shield.language")
            .flatMap(AppLanguage.init(rawValue:))
            ?? ((Locale.preferredLanguages.first ?? "").hasPrefix("es") ? .es : .en)
        let locale = Locale(identifier: language.rawValue)
        let resource = LocalizedStringResource(
            String.LocalizationValue(key),
            table: table,
            locale: locale,
            bundle: .atURL(Bundle.main.bundleURL)
        )
        let format = String(localized: resource)
        if format != key {
            guard !args.isEmpty else { return format }
            return String(format: format, locale: locale, arguments: args)
        }
        if let dynamic = dynamicFallbackText(key, language: language) {
            guard !args.isEmpty else { return dynamic }
            return String(format: dynamic, locale: locale, arguments: args)
        }
        guard !args.isEmpty else { return format }
        return String(format: format, locale: locale, arguments: args)
    }
}
