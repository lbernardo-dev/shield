import SwiftUI
import UIKit

// MARK: - Design tokens (from tokens.css)

enum ShieldTheme {
    // Surfaces — dark
    static let surface0 = Color(hex: "0A0A0B")
    static let surface1 = Color(hex: "111114")
    static let surface2 = Color(hex: "18181D")
    static let surface3 = Color(hex: "1F1F26")
    static let surface4 = Color(hex: "26262E")
    static let surfaceLine = Color.white.opacity(0.08)
    static let surfaceLineStrong = Color.white.opacity(0.14)

    // Text — dark
    static let textPrimary = Color(hex: "F5F5F7")
    static let textSecondary = Color(hex: "F5F5F7").opacity(0.66)
    static let textTertiary = Color(hex: "F5F5F7").opacity(0.42)
    static let textQuaternary = Color(hex: "F5F5F7").opacity(0.24)

    // Accent (dark = yellow, light = near-black)
    static let accent = Color(hex: "D9AA00")
    static let accentStrong = Color(hex: "F2C200")
    static let accentDim = Color(hex: "D9AA00").opacity(0.22)
    static let accentText = Color(hex: "0A0A0B")

    // Semantic
    static let success = Color(hex: "30D158")
    static let successDim = Color(hex: "30D158").opacity(0.16)
    static let warning = Color(hex: "FF9F0A")
    static let danger = Color(hex: "FF453A")
    static let dangerDim = Color(hex: "FF453A").opacity(0.16)
    static let info = Color(hex: "64D2FF")

    // Radii
    static let rXS: CGFloat = 6
    static let rSM: CGFloat = 10
    static let rMD: CGFloat = 14
    static let rLG: CGFloat = 20
    static let rXL: CGFloat = 28

    // Spacing (4pt grid)
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
    static let s10: CGFloat = 40
    static let s12: CGFloat = 48
}

// MARK: - Light-mode adaptive colors

extension ShieldTheme {
    /// Spacing inside a root view that already respects the top safe area.
    /// Do not add `safeAreaInsets.top` again: SwiftUI has already positioned
    /// the view below the status bar / Dynamic Island.
    static let topChromePadding: CGFloat = 10
    static let topChromeBottomSpacing: CGFloat = 10
    static func accent(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? accentStrong : accent
    }
    static func accentDim(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? accent.opacity(0.18) : accent.opacity(0.24)
    }
    static func accentStroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? accent.opacity(0.34) : accent.opacity(0.56)
    }
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? surface1 : Color(hex: "F7F7FA")
    }
    static func cardBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? surface2 : Color.white
    }
    static func rowBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? surface3 : Color(hex: "ECECF1")
    }
    static func line(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? surfaceLine : Color.black.opacity(0.14)
    }
    static func primary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? textPrimary : Color(hex: "0A0A0B")
    }
    static func secondary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? textSecondary : Color(hex: "0A0A0B").opacity(0.66)
    }
    static func tertiary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? textTertiary : Color(hex: "0A0A0B").opacity(0.42)
    }
    static func accentColor(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? accent : Color(hex: "1A1A1A")
    }
    static func pageBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? surface0 : Color(hex: "F4F4F8")
    }
    static func quaternary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? textQuaternary : Color(hex: "0A0A0B").opacity(0.24)
    }
}

// MARK: - Color(hex:)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View modifiers

struct ShieldCardStyle: ViewModifier {
    @Environment(\.colorScheme) var scheme
    func body(content: Content) -> some View {
        content
            .background(ShieldTheme.cardBackground(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                    .stroke(ShieldTheme.line(scheme), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD))
    }
}

extension View {
    func shieldCard() -> some View {
        modifier(ShieldCardStyle())
    }
}

// MARK: - URL helper

extension URL {
    func loadImage() -> UIImage? {
        SecureFileStore.shared.loadImage(from: self)
    }
}
