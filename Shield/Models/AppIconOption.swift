import SwiftUI

// MARK: - AppIconOption

/// Represents the available application icons designed with modern Icon Composer.
/// Default icon for free and pro users is `MaskIDBlue`. Other icons are exclusive to Pro users.
enum AppIconOption: String, CaseIterable, Identifiable, Sendable {
    case blue = "MaskIDBlue"
    case gold = "MaskIDGold"
    case green = "MaskIDGreen"
    case ocean = "MaskIDOcean"
    case purple = "MaskIDPurple"
    case red = "MaskIDRed"

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

    /// Safely loads the PNG representation of this icon directly from bundle files without triggering asset catalog app icon assertions.
    var uiImage: UIImage? {
        if let path = Bundle.main.path(forResource: imageName, ofType: "png"),
           let image = UIImage(contentsOfFile: path) {
            return image
        }
        return UIImage(named: "MaskIDMark")
    }

    /// Safe SwiftUI Image view for rendering anywhere across the UI.
    var image: Image {
        if let uiImage {
            return Image(uiImage: uiImage)
        }
        return Image("MaskIDMark")
    }

    /// The name passed to `UIApplication.setAlternateIconName`.
    /// Passing `nil` resets iOS to the primary default app icon (`MaskIDBlue`).
    var alternateIconName: String? {
        isDefault ? nil : rawValue
    }

    /// Primary accent color matching the aesthetic identity of the icon.
    var accentColor: Color {
        switch self {
        case .blue:   return Color(hex: "0088FF")
        case .gold:   return Color(hex: "FFB800")
        case .green:  return Color(hex: "00D084")
        case .ocean:  return Color(hex: "06B6D4")
        case .purple: return Color(hex: "A855F7")
        case .red:    return Color(hex: "EF4444")
        }
    }

    /// Gradient tones used in preview halo and backdrop lighting.
    var haloColors: [Color] {
        switch self {
        case .blue:
            return [Color(hex: "00B4D8"), Color(hex: "0077B6")]
        case .gold:
            return [Color(hex: "FFD60A"), Color(hex: "D9AA00")]
        case .green:
            return [Color(hex: "30D158"), Color(hex: "00A86B")]
        case .ocean:
            return [Color(hex: "00C7BE"), Color(hex: "0077B6")]
        case .purple:
            return [Color(hex: "BF5AF2"), Color(hex: "5E5CE6")]
        case .red:
            return [Color(hex: "FF453A"), Color(hex: "C92A2A")]
        }
    }

    /// Localized display title for the icon.
    func localizedName(language: AppLanguage) -> String {
        let key: String
        switch self {
        case .blue:   key = "settings_app_icon_blue"
        case .gold:   key = "settings_app_icon_gold"
        case .green:  key = "settings_app_icon_green"
        case .ocean:  key = "settings_app_icon_ocean"
        case .purple: key = "settings_app_icon_purple"
        case .red:    key = "settings_app_icon_red"
        }
        return LanguageManager.shared.t(key, table: "Settings", language: language)
    }

    /// Localized descriptive subtitle for preview sheets.
    func localizedSubtitle(language: AppLanguage) -> String {
        let key: String
        switch self {
        case .blue:   key = "settings_app_icon_blue_desc"
        case .gold:   key = "settings_app_icon_gold_desc"
        case .green:  key = "settings_app_icon_green_desc"
        case .ocean:  key = "settings_app_icon_ocean_desc"
        case .purple: key = "settings_app_icon_purple_desc"
        case .red:    key = "settings_app_icon_red_desc"
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
}
