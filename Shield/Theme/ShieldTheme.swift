import SwiftUI
import UIKit

// MARK: - Design tokens (from tokens.css)

enum ShieldTheme {
    // Surfaces — dark
    static let surface0 = Color(hex: "050D18")
    static let surface1 = Color(hex: "071426")
    static let surface2 = Color(hex: "0E2038")
    static let surface3 = Color(hex: "142A45")
    static let surface4 = Color(hex: "1B3552")
    static let surfaceLine = Color.white.opacity(0.08)
    static let surfaceLineStrong = Color.white.opacity(0.14)

    // Text — dark
    static let textPrimary = Color(hex: "F5F5F7")
    static let textSecondary = Color(hex: "F5F5F7").opacity(0.66)
    static let textTertiary = Color(hex: "F5F5F7").opacity(0.42)
    static let textQuaternary = Color(hex: "F5F5F7").opacity(0.24)

    // MaskID identity palette: electric cyan over deep privacy navy.
    static let accent = Color(hex: "20C7D9")
    static let accentStrong = Color(hex: "42DCEA")
    static let accentDim = Color(hex: "20C7D9").opacity(0.22)
    static let accentText = Color(hex: "071426")

    // Semantic
    static let success = Color(hex: "30D158")
    static let successDim = Color(hex: "30D158").opacity(0.16)
    static let warning = Color(hex: "FF9F0A")
    static let danger = Color(hex: "FF453A")
    static let dangerDim = Color(hex: "FF453A").opacity(0.16)
    static let info = Color(hex: "64D2FF")

    // Layout
    static let minimumTapTarget: CGFloat = 44
    static let controlHeight: CGFloat = 50
    static let readableWidth: CGFloat = 760
    static let workspaceWidth: CGFloat = 1_100

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
    static func strongLine(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? surfaceLineStrong : Color.black.opacity(0.24)
    }
    static func elevatedBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? surface3 : Color(hex: "FDFDFE")
    }
    static func selectedBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? accent.opacity(0.18) : accent.opacity(0.14)
    }
    static func successBackground(_ scheme: ColorScheme) -> Color {
        success.opacity(scheme == .dark ? 0.16 : 0.12)
    }
    static func warningBackground(_ scheme: ColorScheme) -> Color {
        warning.opacity(scheme == .dark ? 0.18 : 0.13)
    }
    static func errorBackground(_ scheme: ColorScheme) -> Color {
        danger.opacity(scheme == .dark ? 0.18 : 0.12)
    }
    static func scrim(_ scheme: ColorScheme) -> Color {
        Color.black.opacity(scheme == .dark ? 0.58 : 0.34)
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
        scheme == .dark ? accent : Color(hex: "087D8A")
    }
    static func pageBackground(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? surface0 : Color(hex: "F4F4F8")
    }
    static func quaternary(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? textQuaternary : Color(hex: "0A0A0B").opacity(0.24)
    }

    /// Full-screen "premium" backdrop used by Paywall and post-value
    /// onboarding surfaces. In dark mode it keeps the deep privacy-navy
    /// identity; in light mode it becomes a soft, readable gradient so the
    /// surface no longer "ignores" the appearance setting.
    static func premiumBackground(_ scheme: ColorScheme) -> [Color] {
        scheme == .dark
            ? [surface0, surface2]
            : [Color(hex: "F4F4F8"), Color.white]
    }

    /// Selection/affordance highlight for canvas overlays. Yellow reads
    /// clearly over the dark render surface; a deeper amber keeps contrast
    /// in light mode where documents render on white.
    static func selection(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "FFD60A") : Color(hex: "B8860B")
    }
}

// MARK: - Motion

enum ShieldMotion {
    static let fast: Double = 0.12
    static let standard: Double = 0.22
    static let contextual: Double = 0.36

    static let press = Animation.easeOut(duration: fast)
    static let state = Animation.smooth(duration: standard)
    static let navigation = Animation.spring(duration: contextual, bounce: 0.08)
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

// MARK: - Typography (Dynamic Type aware)

/// Base sizes for the Shield type scale. These are the design's default
/// point sizes at the system's default content size category; `shieldFont`
/// scales them with the user's Dynamic Type preference.
enum ShieldTypeSize {
    static let micro: CGFloat = 9
    static let caption: CGFloat = 11
    static let captionMid: CGFloat = 12
    static let footnote: CGFloat = 13
    static let subheadline: CGFloat = 14
    static let callout: CGFloat = 15
    static let body: CGFloat = 16
    static let headline: CGFloat = 17
    static let title3: CGFloat = 20
    static let title2: CGFloat = 22
    static let title1: CGFloat = 28
    static let display: CGFloat = 34
}

/// Applies a fixed-layout font size as a Dynamic Type-aware token. The view
/// is re-evaluated when the user changes the system text size, keeping the
/// identical visual design at the default size while honoring accessibility
/// Large/Accessibility sizes. Canvas/output renderers must keep using
/// `.system(size:)` so exported documents never depend on device settings.
struct ShieldFontModifier: ViewModifier {
    @ScaledMetric(relativeTo: .body) private var dynamicSize: CGFloat = 14
    let weight: Font.Weight
    let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design) {
        let legibleSize = max(size, 10)
        _dynamicSize = ScaledMetric(
            wrappedValue: legibleSize,
            relativeTo: ShieldTypeSize.relativeStyle(for: legibleSize)
        )
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: dynamicSize, weight: weight, design: design))
    }
}

extension ShieldTypeSize {
    static func relativeStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<12: .caption2
        case ..<14: .footnote
        case ..<16: .subheadline
        case ..<18: .body
        case ..<21: .headline
        case ..<24: .title3
        case ..<30: .title2
        default: .largeTitle
        }
    }
}

extension View {
    /// Substitutes the (non-scaling) `.system(size:weight:design:)` pattern
    /// with a Dynamic Type-aware equivalent.
    func shieldFont(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(ShieldFontModifier(size: size, weight: weight, design: design))
    }
}

// MARK: - View modifiers

struct ShieldCardStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        content
            .background(
                reduceTransparency
                    ? ShieldTheme.elevatedBackground(scheme)
                    : ShieldTheme.cardBackground(scheme)
            )
            .overlay(
                RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                    .stroke(
                        contrast == .increased
                            ? ShieldTheme.strongLine(scheme)
                            : ShieldTheme.line(scheme),
                        lineWidth: contrast == .increased ? 1 : 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD))
            .shadow(
                color: Color.black.opacity(scheme == .dark ? 0.12 : 0.07),
                radius: 8,
                y: 3
            )
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
