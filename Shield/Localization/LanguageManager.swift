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
        
        return key
    }

    /// Resolver with arguments
    func t(_ key: String, table: String, args: CVarArg...) -> String {
        t(key, table: table, argsArray: args)
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
        guard !args.isEmpty else { return format }
        return String(format: format, locale: locale, arguments: args)
    }
}
