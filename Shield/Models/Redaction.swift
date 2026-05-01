import SwiftUI

// MARK: - MaskStyle

enum MaskStyle: String, CaseIterable, Identifiable, Codable {
    case block
    case blockWhite
    case pixelate
    case blurStrong
    case blurSoft
    case diagonal
    case secure
    case redactedTag
    case semi

    var id: String { rawValue }

    var isPremium: Bool {
        switch self {
        case .block, .blockWhite: return false
        default: return true
        }
    }

    var isBlur: Bool { self == .blurStrong || self == .blurSoft }

    var localizedLabel: String {
        switch self {
        case .block:        return LanguageManager.shared.model("model_mask_style_block")
        case .blockWhite:   return LanguageManager.shared.model("model_mask_style_block_white")
        case .pixelate:     return LanguageManager.shared.model("model_mask_style_pixelate")
        case .blurStrong:   return LanguageManager.shared.model("model_mask_style_blur_strong")
        case .blurSoft:     return LanguageManager.shared.model("model_mask_style_blur_soft")
        case .diagonal:     return LanguageManager.shared.model("model_mask_style_diagonal")
        case .secure:       return LanguageManager.shared.model("model_mask_style_secure")
        case .redactedTag:  return LanguageManager.shared.model("model_mask_style_redacted_tag")
        case .semi:         return LanguageManager.shared.model("model_mask_style_semi")
        }
    }

    func label(lang: AppLanguage) -> String {
        localizedLabel
    }
}

// MARK: - Redaction

struct Redaction: Identifiable, Equatable, Codable {
    let id: UUID
    /// Normalized rect (0..1) in document space
    var rect: CGRect
    var style: MaskStyle

    init(rect: CGRect, style: MaskStyle = .block) {
        self.id = UUID()
        self.rect = rect
        self.style = style
    }

    // Codable for CGRect
    enum CodingKeys: String, CodingKey { case id, x, y, w, h, style }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id    = try c.decode(UUID.self, forKey: .id)
        style = try c.decode(MaskStyle.self, forKey: .style)
        let x = try c.decode(CGFloat.self, forKey: .x)
        let y = try c.decode(CGFloat.self, forKey: .y)
        let w = try c.decode(CGFloat.self, forKey: .w)
        let h = try c.decode(CGFloat.self, forKey: .h)
        rect = CGRect(x: x, y: y, width: w, height: h)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,            forKey: .id)
        try c.encode(style,         forKey: .style)
        try c.encode(rect.origin.x, forKey: .x)
        try c.encode(rect.origin.y, forKey: .y)
        try c.encode(rect.width,    forKey: .w)
        try c.encode(rect.height,   forKey: .h)
    }
}

// MARK: - Watermark

struct Watermark: Codable {
    var text: String
    var opacity: Double = 0.18
    var isRepeating: Bool = true   // NOTE: was `repeat` (Swift keyword) — renamed
    var colorHex: String = "000000"

    var color: Color { Color(hex: colorHex) }
}

// MARK: - RedactionMode

enum RedactionMode: String, CaseIterable, Identifiable {
    case rental
    case travel
    case job
    case verify
    case legal
    case health
    case banking

    var id: String { rawValue }

    var localizedLabel: String {
        switch self {
        case .rental:  return LanguageManager.shared.model("model_redaction_mode_rental")
        case .travel:  return LanguageManager.shared.model("model_redaction_mode_travel")
        case .job:     return LanguageManager.shared.model("model_redaction_mode_job")
        case .verify:  return LanguageManager.shared.model("model_redaction_mode_verify")
        case .legal:   return LanguageManager.shared.model("model_redaction_mode_legal")
        case .health:  return LanguageManager.shared.model("model_redaction_mode_health")
        case .banking: return LanguageManager.shared.model("model_redaction_mode_banking")
        }
    }

    var icon: String {
        switch self {
        case .rental:  return "house.fill"
        case .travel:  return "airplane"
        case .job:     return "briefcase.fill"
        case .verify:  return "checkmark.shield.fill"
        case .legal:   return "scalemass.fill"
        case .health:  return "heart.fill"
        case .banking: return "building.columns.fill"
        }
    }

    var color: Color {
        switch self {
        case .rental:  return Color(hex: "5E5CE6")
        case .travel:  return Color(hex: "64D2FF")
        case .job:     return Color(hex: "FF9F0A")
        case .verify:  return Color(hex: "30D158")
        case .legal:   return Color(hex: "BF5AF2")
        case .health:  return Color(hex: "FF375F")
        case .banking: return Color(hex: "34C759")
        }
    }

    var localizedSubtitle: String {
        switch self {
        case .rental:  return LanguageManager.shared.model("model_redaction_mode_rental_sub")
        case .travel:  return LanguageManager.shared.model("model_redaction_mode_travel_sub")
        case .job:     return LanguageManager.shared.model("model_redaction_mode_job_sub")
        case .verify:  return LanguageManager.shared.model("model_redaction_mode_verify_sub")
        case .legal:   return LanguageManager.shared.model("model_redaction_mode_legal_sub")
        case .health:  return LanguageManager.shared.model("model_redaction_mode_health_sub")
        case .banking: return LanguageManager.shared.model("model_redaction_mode_banking_sub")
        }
    }

    /// Whether this mode is a Pro-only preset
    var requiresPro: Bool {
        switch self {
        case .legal, .health, .banking: return true
        default: return false
        }
    }

    func label(lang: AppLanguage) -> String {
        localizedLabel
    }

    func subtitle(lang: AppLanguage) -> String {
        localizedSubtitle
    }
}
