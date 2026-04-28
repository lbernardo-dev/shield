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

    func label(lang: AppLanguage) -> String {
        switch self {
        case .block:        return lang == .es ? "Negro" : "Black"
        case .blockWhite:   return lang == .es ? "Blanco" : "White"
        case .pixelate:     return lang == .es ? "Pixelado" : "Pixelate"
        case .blurStrong:   return lang == .es ? "Blur fuerte" : "Strong blur"
        case .blurSoft:     return lang == .es ? "Blur suave" : "Soft blur"
        case .diagonal:     return "Diagonal"
        case .secure:       return lang == .es ? "Alta seg." : "High-sec."
        case .redactedTag:  return lang == .es ? "Etiqueta" : "Label"
        case .semi:         return "Semi"
        }
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

    var id: String { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .rental: return lang == .es ? "Alquiler" : "Rental"
        case .travel: return lang == .es ? "Viaje" : "Travel"
        case .job:    return lang == .es ? "Empleo" : "Job"
        case .verify: return lang == .es ? "Verificación" : "Verify"
        }
    }

    var icon: String {
        switch self {
        case .rental: return "house.fill"
        case .travel: return "airplane"
        case .job:    return "briefcase.fill"
        case .verify: return "checkmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .rental: return Color(hex: "5E5CE6")
        case .travel: return Color(hex: "64D2FF")
        case .job:    return Color(hex: "FF9F0A")
        case .verify: return Color(hex: "30D158")
        }
    }

    func subtitle(lang: AppLanguage) -> String {
        switch self {
        case .rental: return lang == .es ? "Oculta foto, dirección, MRZ" : "Hides photo, address, MRZ"
        case .travel: return lang == .es ? "Oculta nº pasaporte" : "Hides passport №"
        case .job:    return lang == .es ? "Oculta DOB, firma" : "Hides DOB, signature"
        case .verify: return lang == .es ? "Solo nombre + foto" : "Only name + photo"
        }
    }
}
