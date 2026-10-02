import SwiftUI

// MARK: - AppIconOption

/// Represents the available application icons designed with modern Icon Composer.
/// The standard experience uses the current blue mask mark; other icons are
/// optional Pro variants.
enum AppIconOption: String, CaseIterable, Identifiable, Sendable {
    case blue = "MaskIDBlue"
    case halloween = "MaskIDHalloween"

    var id: String { rawValue }

    /// Whether this icon is the default baseline app icon.
    var isDefault: Bool {
        self == .blue
    }

    /// Whether unlocking/activating this icon requires Pro subscription.
    var isPro: Bool {
        self != .blue
    }

    /// The asset/resource image name in bundle or asset catalogs.
    var imageName: String {
        rawValue
    }

    /// Safely loads the PNG representation of this icon directly from bundle
    /// files without triggering asset-catalog app-icon assertions.
    var uiImage: UIImage? {
        if let path = Bundle.main.path(forResource: imageName, ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        // Keep the fallback on the current app-icon family. The old face mark
        // was a product illustration, not the app identity, and must never be
        // used as a system-icon or theme-preview fallback.
        return UIImage(named: imageName) ?? UIImage(named: "icon_1024")
    }

    /// Safe SwiftUI Image view for rendering anywhere across the UI.
    var image: Image {
        if let uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "shield.fill")
    }

    /// The name passed to `UIApplication.setAlternateIconName`.
    /// Passing `nil` resets iOS to the primary modern app icon.
    var alternateIconName: String? {
        isDefault ? nil : rawValue
    }

    /// Primary accent color matching the aesthetic identity of the icon.
    var accentColor: Color {
        switch self {
        case .blue:      return Color(hex: "0088FF")
        case .halloween: return Color(hex: "F97316")
        }
    }

    /// Gradient tones used in preview halo and backdrop lighting.
    var haloColors: [Color] {
        switch self {
        case .blue:
            return [Color(hex: "00B4D8"), Color(hex: "0077B6")]
        case .halloween:
            return [Color(hex: "FB923C"), Color(hex: "7C2D12")]
        }
    }

    /// Localized display title for the icon.
    func localizedName(language: AppLanguage) -> String {
        let key: String
        switch self {
        case .blue:      key = "settings_app_icon_blue"
        case .halloween: key = "settings_app_icon_halloween"
        }
        return LanguageManager.shared.t(key, table: "Settings", language: language)
    }

    /// Localized descriptive subtitle for preview sheets.
    func localizedSubtitle(language: AppLanguage) -> String {
        let key: String
        switch self {
        case .blue:      key = "settings_app_icon_blue_desc"
        case .halloween: key = "settings_app_icon_halloween_desc"
        }
        return LanguageManager.shared.t(key, table: "Settings", language: language)
    }

    /// Resolves the option from an alternate icon name returned by UIApplication.
    static func from(alternateIconName: String?) -> AppIconOption {
        guard let alternateIconName else { return .blue }
        return AppIconOption(rawValue: alternateIconName) ?? .blue
    }

    /// Baseline default icon.
    static let defaultIcon: AppIconOption = .blue

    /// Alias for base theme icon.
    static let base: AppIconOption = .blue
}
