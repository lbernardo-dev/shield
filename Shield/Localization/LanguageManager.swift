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

    var current: AppLanguage {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: "shield.language") }
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
        if let saved = UserDefaults.standard.string(forKey: "shield.language"),
           let lang = AppLanguage(rawValue: saved) {
            current = lang
        } else {
            let pref = Locale.preferredLanguages.first ?? ""
            current = pref.hasPrefix("es") ? .es : .en
        }
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
}
