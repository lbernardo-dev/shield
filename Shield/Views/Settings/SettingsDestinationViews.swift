import SwiftUI
import LocalAuthentication

extension EnvironmentValues {
    @Entry var closeSettings: () -> Void = {}
}

// MARK: - Public web destinations

enum ShieldPublicPage: String, CaseIterable, Sendable {
    case overview
    case privacy
    case terms
    case subscriptions
    case support
    case faq

    func localizedURL(for language: AppLanguage) -> URL {
        let path: String
        switch (self, language) {
        case (.overview, .es): path = "es/casos/shield/"
        case (.privacy, .es): path = "es/casos/shield/privacidad/"
        case (.terms, .es): path = "es/casos/shield/terminos/"
        case (.subscriptions, .es): path = "es/casos/shield/suscripciones/"
        case (.support, .es): path = "es/casos/shield/soporte/"
        case (.faq, .es): path = "es/casos/shield/preguntas-frecuentes/"
        case (.overview, .en): path = "en/case-studies/shield/"
        case (.privacy, .en): path = "en/case-studies/shield/privacy/"
        case (.terms, .en): path = "en/case-studies/shield/terms/"
        case (.subscriptions, .en): path = "en/case-studies/shield/subscriptions/"
        case (.support, .en): path = "en/case-studies/shield/support/"
        case (.faq, .en): path = "en/case-studies/shield/faq/"
        }
        return URL(string: Self.baseURL.absoluteString + path)!
    }

    var compatibilityURL: URL {
        let path: String
        switch self {
        case .overview: path = "apps/shield/"
        case .privacy: path = "apps/shield/privacy/"
        case .terms: path = "apps/shield/terms/"
        case .subscriptions: path = "apps/shield/subscriptions/"
        case .support: path = "apps/shield/support/"
        case .faq: path = "apps/shield/faq/"
        }
        return URL(string: Self.baseURL.absoluteString + path)!
    }

    private static let baseURL = URL(string: "https://lbernardo-dev.github.io/apps/")!
}

struct ShieldPublicPageButton: View {
    let page: ShieldPublicPage
    let language: AppLanguage
    var compact = false

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        Button(action: openPage) {
            HStack(spacing: ShieldTheme.s3) {
                Image(systemName: "safari.fill")
                    .font(.body.weight(.bold))
                    .accessibilityHidden(true)
                if compact {
                    Text(strings.settings("settings_open_online"))
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strings.settings("settings_open_official_page"))
                            .font(.body.weight(.bold))
                        Text(strings.settings("settings_opens_browser"))
                            .font(.caption)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                    }
                }
                Spacer(minLength: ShieldTheme.s2)
                Image(systemName: "arrow.up.forward")
                    .font(.caption.weight(.bold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(ShieldTheme.accent(scheme))
            .padding(compact ? ShieldTheme.s3 : ShieldTheme.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ShieldTheme.accentDim(scheme))
            .overlay {
                RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                    .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 1)
            }
            .compositingGroup()
            .clipShape(.rect(cornerRadius: ShieldTheme.rMD))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityHint(strings.settings("settings_opens_browser"))
    }

    private func openPage() {
        openURL(page.localizedURL(for: language)) { accepted in
            guard !accepted else { return }
            openURL(page.compatibilityURL)
        }
    }
}

// MARK: - Shared settings chrome

private struct ShieldSettingsCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let isHalloween = ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark && !reduceTransparency
        content
            .background(
                isHalloween
                    ? Color(hex: "1C1026").opacity(0.82)
                    : ShieldTheme.cardBackground(scheme)
            )
            .background(
                isHalloween ? .ultraThinMaterial : .regularMaterial
            )
            .overlay {
                RoundedRectangle(cornerRadius: ShieldTheme.rLG)
                    .stroke(
                        isHalloween
                            ? LinearGradient(
                                colors: [
                                    Color(hex: "FF9A3D").opacity(0.38),
                                    Color(hex: "7C3AED").opacity(0.22),
                                    Color(hex: "FF9A3D").opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [ShieldTheme.line(scheme)], startPoint: .top, endPoint: .bottom),
                        lineWidth: isHalloween ? 1.0 : 0.8
                    )
            }
            .clipShape(.rect(cornerRadius: ShieldTheme.rLG))
            .shadow(
                color: isHalloween ? Color(hex: "F97316").opacity(0.14) : Color.black.opacity(0.04),
                radius: isHalloween ? 12 : 4,
                y: 3
            )
    }
}

extension View {
    func shieldSettingsCard() -> some View {
        modifier(ShieldSettingsCardModifier())
    }
}

struct SettingsIconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 44

    @Environment(\.colorScheme) private var scheme
    private var isHalloween: Bool { ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundStyle(color == Color(hex: "FFD60A") ? Color.black : Color.white)
                .frame(width: size, height: size)
                .background(color.gradient)
                .clipShape(.rect(cornerRadius: size * 0.26))
                .overlay {
                    if isHalloween {
                        RoundedRectangle(cornerRadius: size * 0.26)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                    }
                }

            if isHalloween {
                if icon.contains("wand") || icon.contains("sparkle") {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(Color(hex: "FFD6A0"))
                        .offset(x: 2, y: 2)
                } else if icon.contains("lock") || icon.contains("paintbrush") {
                    SeasonalThemeHalloweenPumpkin(size: 12)
                        .offset(x: 3, y: 3)
                } else if icon.contains("viewfinder") || icon.contains("camera") {
                    Image(systemName: "network")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Color(hex: "FFD6A0"))
                        .offset(x: 2, y: 2)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct SettingsSummaryCard: View {
    let documentCount: Int
    let vaultedCount: Int
    let isPro: Bool
    var onUnlockPro: (() -> Void)? = nil
    var onManageSubscription: (() -> Void)? = nil

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    private var strings: LanguageManager { .shared }

    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark && !reduceTransparency
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.1.0"
    }

    private var manageText: String {
        strings.currentLanguage == .es ? "Gestionar suscripción" : "Manage Subscription"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if isHalloween {
                SeasonalThemeWebCorner(size: 46)
                    .offset(x: 2, y: 2)
                    .opacity(0.65)
                    .allowsHitTesting(false)
            }

            VStack(spacing: ShieldTheme.s4) {
                HStack(spacing: ShieldTheme.s3) {
                    MaskIDIdentityMark(
                        size: 44,
                        presentation: .animatedLoop,
                        treatment: .compact
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text("MaskID")
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(ShieldTheme.primary(scheme))
                        Text(strings.settings("settings_version_value", version))
                            .font(.caption)
                            .foregroundStyle(ShieldTheme.tertiary(scheme))
                    }
                    Spacer(minLength: 0)
                    Label(
                        strings.settings(isPro ? "settings_plan_pro" : "settings_plan_free"),
                        systemImage: isPro ? "sparkles" : "checkmark.circle.fill"
                    )
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isPro ? ShieldTheme.accent(scheme) : ShieldTheme.success)
                    .padding(.horizontal, ShieldTheme.s3)
                    .padding(.vertical, ShieldTheme.s2)
                    .background(
                        isHalloween
                            ? Color(hex: "291636").opacity(0.85)
                            : ShieldTheme.rowBackground(scheme),
                        in: Capsule()
                    )
                    .overlay {
                        if isHalloween {
                            Capsule().stroke(Color(hex: "FFD6B0").opacity(0.2), lineWidth: 0.8)
                        }
                    }
                }

                HStack(spacing: 0) {
                    if isHalloween {
                        SeasonalThemeCandelabra(size: 26)
                            .padding(.trailing, 4)
                    }

                    summaryMetric(
                        icon: "doc.text.fill",
                        value: documentCount.formatted(),
                        label: strings.settings("settings_summary_documents")
                    )

                    Rectangle()
                        .fill(isHalloween ? Color(hex: "FFD6B0").opacity(0.18) : ShieldTheme.line(scheme))
                        .frame(width: 1, height: 38)

                    summaryMetric(
                        icon: "lock.fill",
                        value: vaultedCount.formatted(),
                        label: strings.settings("settings_summary_vault")
                    )

                    if isHalloween {
                        SeasonalThemeHalloweenPumpkin(size: 24)
                            .padding(.leading, 4)
                    }
                }

                Divider()
                    .overlay(isHalloween ? Color(hex: "FFD6B0").opacity(0.16) : ShieldTheme.line(scheme))

                if isPro {
                    if let onManageSubscription {
                        Button(action: onManageSubscription) {
                            HStack(spacing: ShieldTheme.s2) {
                                Image(systemName: "creditcard.fill")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(ShieldTheme.accent(scheme))
                                Text(manageText)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(ShieldTheme.primary(scheme))
                                Spacer()
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(ShieldTheme.secondary(scheme))
                            }
                            .padding(.horizontal, ShieldTheme.s3)
                            .frame(minHeight: 46)
                            .background(
                                isHalloween
                                    ? Color(hex: "291636").opacity(0.8)
                                    : ShieldTheme.rowBackground(scheme),
                                in: RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                } else {
                    if let onUnlockPro {
                        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
                            HStack(spacing: ShieldTheme.s3) {
                                SettingsIconBadge(icon: "crown.fill", color: Color(hex: "FFD60A"), size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(strings.settings("settings_unlock_premium"))
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(ShieldTheme.primary(scheme))
                                    Text(strings.settings("settings_pro_unlock_features"))
                                        .font(.caption)
                                        .foregroundStyle(ShieldTheme.secondary(scheme))
                                }
                                Spacer(minLength: 0)

                                if isHalloween {
                                    HStack(spacing: -4) {
                                        ZStack(alignment: .top) {
                                            SeasonalThemeHalloweenPumpkin(size: 20)
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 8))
                                                .foregroundStyle(Color(hex: "FFD60A"))
                                                .offset(y: -4)
                                        }
                                        ZStack(alignment: .top) {
                                            SeasonalThemeHalloweenPumpkin(size: 24)
                                            Image(systemName: "crown.fill")
                                                .font(.system(size: 10))
                                                .foregroundStyle(Color(hex: "FFD60A"))
                                                .offset(y: -5)
                                        }
                                    }
                                    .opacity(0.9)
                                }
                            }

                            Button(action: onUnlockPro) {
                                HStack(spacing: ShieldTheme.s3) {
                                    if isHalloween {
                                        Image(systemName: "bat.fill")
                                            .font(.subheadline.weight(.heavy))
                                            .foregroundStyle(Color(hex: "170A02"))
                                    }

                                    Text(strings.settings("settings_view_options"))
                                        .font(.headline.weight(.heavy))
                                        .foregroundStyle(isHalloween ? Color(hex: "170A02") : ShieldTheme.accentText)

                                    if isHalloween {
                                        Image(systemName: "bat.fill")
                                            .font(.subheadline.weight(.heavy))
                                            .foregroundStyle(Color(hex: "170A02"))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 48)
                                .background(
                                    isHalloween
                                        ? LinearGradient(
                                            colors: [Color(hex: "FFA53D"), Color(hex: "F97316"), Color(hex: "EA580C")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        : LinearGradient(colors: [ShieldTheme.accent(scheme)], startPoint: .top, endPoint: .bottom)
                                )
                                .clipShape(Capsule())
                                .overlay {
                                    if isHalloween {
                                        Capsule()
                                            .stroke(Color(hex: "FFD6A0").opacity(0.55), lineWidth: 1)
                                    }
                                }
                                .shadow(
                                    color: isHalloween ? Color(hex: "F97316").opacity(0.65) : Color.clear,
                                    radius: 12,
                                    y: 4
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
            }
            .padding(ShieldTheme.s4)
        }
        .shieldSettingsCard()
        .accessibilityElement(children: .contain)
    }

    private func summaryPill(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(ShieldTheme.secondary(scheme))
            .lineLimit(1)
            .padding(.horizontal, ShieldTheme.s2)
            .padding(.vertical, 5)
            .background(ShieldTheme.rowBackground(scheme))
            .clipShape(Capsule())
    }

    private func summaryMetric(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Label(value, systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct SettingsCardSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var scheme

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            Label(title.uppercased(), systemImage: icon)
                .font(.subheadline.weight(.bold))
                .tracking(0.5)
                .foregroundStyle(
                    ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
                        ? Color(hex: "FFD6B0")
                        : ShieldTheme.secondary(scheme)
                )
                .accessibilityAddTraits(.isHeader)
                .padding(.leading, ShieldTheme.s3)

            VStack(spacing: 0) {
                content
            }
            .shieldSettingsCard()
        }
    }
}

struct SettingsNavigationRow: View {
    let route: SettingsRoute
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        NavigationLink(value: route) {
            SettingsRowLabel(icon: icon, color: color, title: title, subtitle: subtitle, showsChevron: true, route: route)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier(route.accessibilityIdentifier)
        .accessibilityHint(subtitle)
    }
}

struct SettingsActionRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    var accessibilityIdentifier: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowLabel(icon: icon, color: color, title: title, subtitle: subtitle, showsChevron: true, route: nil)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier(accessibilityIdentifier ?? title)
        .accessibilityHint(subtitle)
    }
}

struct SettingsRowVignetteView: View {
    let route: SettingsRoute

    var body: some View {
        ZStack(alignment: .trailing) {
            LinearGradient(
                colors: [Color.clear, Color(hex: "1C1026").opacity(0.12), Color(hex: "1C1026").opacity(0.42)],
                startPoint: .leading,
                endPoint: .trailing
            )

            switch route {
            case .themes:
                HStack(spacing: 4) {
                    Spacer()
                    ZStack(alignment: .bottomTrailing) {
                        Canvas { context, size in
                            let moonRect = CGRect(x: size.width * 0.42, y: size.height * 0.05, width: 42, height: 42)
                            context.fill(Circle().path(in: moonRect), with: .color(ShieldTheme.halloweenPumpkin.opacity(0.32)))

                            var castle = Path()
                            castle.move(to: CGPoint(x: size.width * 0.35, y: size.height))
                            castle.addLine(to: CGPoint(x: size.width * 0.45, y: size.height * 0.45))
                            castle.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.30))
                            castle.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.45))
                            castle.addLine(to: CGPoint(x: size.width * 0.65, y: size.height * 0.20))
                            castle.addLine(to: CGPoint(x: size.width * 0.70, y: size.height * 0.45))
                            castle.addLine(to: CGPoint(x: size.width * 0.85, y: size.height * 0.55))
                            castle.addLine(to: CGPoint(x: size.width, y: size.height * 0.70))
                            castle.addLine(to: CGPoint(x: size.width, y: size.height))
                            castle.closeSubpath()
                            context.fill(castle, with: .color(Color(hex: "0D0612").opacity(0.85)))
                        }
                        .frame(width: 110, height: 58)

                        SeasonalThemeHalloweenPumpkin(size: 20)
                            .offset(x: -16, y: -2)
                    }
                }
            case .appPreferences:
                HStack(spacing: 4) {
                    Spacer()
                    ZStack(alignment: .topTrailing) {
                        Canvas { context, size in
                            var branch = Path()
                            branch.move(to: CGPoint(x: size.width, y: 0))
                            branch.addCurve(
                                to: CGPoint(x: size.width * 0.38, y: size.height * 0.32),
                                control1: CGPoint(x: size.width * 0.75, y: size.height * 0.1),
                                control2: CGPoint(x: size.width * 0.55, y: size.height * 0.2)
                            )
                            context.stroke(branch, with: .color(Color(hex: "0D0612")), style: StrokeStyle(lineWidth: 3, lineCap: .round))

                            var chain = Path()
                            chain.move(to: CGPoint(x: size.width * 0.50, y: size.height * 0.26))
                            chain.addLine(to: CGPoint(x: size.width * 0.50, y: size.height * 0.46))
                            context.stroke(chain, with: .color(Color(hex: "4A2E10")), style: StrokeStyle(lineWidth: 1.2))
                        }
                        .frame(width: 100, height: 58)

                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color(hex: "FFD6A0").opacity(0.55), Color(hex: "F97316").opacity(0.2), .clear],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 16
                                    )
                                )
                                .frame(width: 32, height: 32)
                            Image(systemName: "lantern.fill")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color(hex: "FFD6A0"), Color(hex: "F97316"))
                        }
                        .offset(x: -42, y: 20)
                    }
                }
            case .ocrSettings:
                HStack(spacing: 4) {
                    Spacer()
                    Canvas { context, size in
                        let ground = CGRect(x: 0, y: size.height * 0.75, width: size.width, height: size.height * 0.25)
                        context.fill(Ellipse().path(in: ground), with: .color(Color(hex: "0D0612").opacity(0.85)))

                        var cross = Path()
                        cross.move(to: CGPoint(x: size.width * 0.70, y: size.height * 0.40))
                        cross.addLine(to: CGPoint(x: size.width * 0.70, y: size.height * 0.85))
                        cross.move(to: CGPoint(x: size.width * 0.62, y: size.height * 0.50))
                        cross.addLine(to: CGPoint(x: size.width * 0.78, y: size.height * 0.50))
                        context.stroke(cross, with: .color(Color(hex: "170D22")), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

                        let tomb = CGRect(x: size.width * 0.42, y: size.height * 0.50, width: 15, height: 18)
                        context.fill(RoundedRectangle(cornerRadius: 3).path(in: tomb), with: .color(Color(hex: "170D22")))
                    }
                    .frame(width: 100, height: 58)
                }
            case .security:
                HStack(spacing: 4) {
                    Spacer()
                    ZStack(alignment: .bottomTrailing) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color(hex: "FFD6A0").opacity(0.45), Color(hex: "F97316").opacity(0.18), .clear],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 15
                                    )
                                )
                                .frame(width: 30, height: 30)
                            Image(systemName: "lantern.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Color(hex: "FFD6A0"), Color(hex: "F97316"))
                        }
                        .offset(x: -38, y: -16)

                        SeasonalThemeHalloweenPumpkin(size: 18)
                            .offset(x: -14, y: -2)
                    }
                    .frame(width: 100, height: 58)
                }
            default:
                HStack(spacing: 4) {
                    Spacer()
                    Image(systemName: "bat.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: "FFD6B0").opacity(0.18))
                        .offset(x: -22, y: -6)
                }
                .frame(width: 70, height: 58)
            }
        }
        .opacity(0.75)
    }
}

private struct SettingsRowLabel: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let showsChevron: Bool
    var route: SettingsRoute? = nil

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark && !reduceTransparency
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            if isHalloween, let route {
                SettingsRowVignetteView(route: route)
                    .frame(width: 130, height: 62)
                    .clipped()
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }

            HStack(spacing: ShieldTheme.s4) {
                SettingsIconBadge(icon: icon, color: color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(ShieldTheme.primary(scheme))
                        .multilineTextAlignment(.leading)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: ShieldTheme.s2)
                if showsChevron {
                    Image(systemName: "chevron.forward")
                        .font(.body.weight(.bold))
                        .foregroundStyle(
                            isHalloween
                                ? Color(hex: "FFD6A0").opacity(0.85)
                                : ShieldTheme.tertiary(scheme)
                        )
                        .accessibilityHidden(true)
                }
            }
            .padding(ShieldTheme.s4)
        }
        .contentShape(Rectangle())
    }
}

struct SettingsRowDivider: View {
    var inset: CGFloat = 76
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Rectangle()
            .fill(
                ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
                    ? Color(hex: "FFD6B0").opacity(0.12)
                    : ShieldTheme.line(scheme)
            )
            .frame(height: 0.8)
            .padding(.leading, inset)
            .accessibilityHidden(true)
    }
}

private struct SettingsControlRow<Control: View>: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String?
    @ViewBuilder let control: Control

    @Environment(\.colorScheme) private var scheme

    init(
        icon: String,
        color: Color,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder control: () -> Control
    ) {
        self.icon = icon
        self.color = color
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }

    var body: some View {
        HStack(spacing: ShieldTheme.s3) {
            SettingsIconBadge(icon: icon, color: color, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(ShieldTheme.primary(scheme))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: ShieldTheme.s2)
            control
        }
        .padding(ShieldTheme.s4)
    }
}

private struct SettingsDetailScaffold<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.closeSettings) private var closeSettings

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ZStack {
            SeasonalThemeBackdrop()

            VStack(spacing: 0) {
                HStack(spacing: ShieldTheme.s3) {
                    Button {
                        dismiss()
                    } label: {
                        Label(LanguageManager.shared.common("common_back"), systemImage: "chevron.left")
                            .font(.body.weight(.semibold))
                            .frame(minHeight: 44)
                    }
                    .accessibilityIdentifier("settings.back")
                    Spacer()
                    SettingsCloseButton(action: closeSettings)
                }
                .frame(maxWidth: ShieldTheme.readableWidth)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, ShieldTheme.s4)
                .background(ShieldTheme.pageBackground(scheme))

                ScrollView(showsIndicators: false) {
                    LazyVStack(alignment: .leading, spacing: ShieldTheme.s5) {
                        Text(title)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(ShieldTheme.primary(scheme))
                        if let subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundStyle(ShieldTheme.secondary(scheme))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        content
                    }
                    .frame(maxWidth: ShieldTheme.readableWidth)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(ShieldTheme.s4)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

struct SettingsCloseButton: View {
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.body.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))
                .frame(width: 44, height: 44)
                .background(ShieldTheme.rowBackground(scheme), in: Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(strings.common("common_close"))
        .accessibilityIdentifier("settings.close")
    }
}

struct SettingsFooter: View {
    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        VStack(spacing: ShieldTheme.s2) {
            Text(strings.settings("settings_footer_version", appVersion))
                .font(.headline.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))
            Text(strings.settings("settings_footer_build", appBuild))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ShieldTheme.secondary(scheme))
            Text(strings.settings("settings_footer_designed"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ShieldTheme.secondary(scheme))
            Label(strings.settings("settings_footer_privacy"), systemImage: "lock.shield.fill")
                .font(.caption)
                .foregroundStyle(ShieldTheme.tertiary(scheme))
                .multilineTextAlignment(.center)
            Text(strings.settings("settings_footer_rights"))
                .font(.caption)
                .foregroundStyle(ShieldTheme.tertiary(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ShieldTheme.s4)
        .accessibilityElement(children: .combine)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}

// MARK: - App preferences

struct AppPreferencesSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var coordinator: SeasonalThemeCoordinator
    @Environment(\.colorScheme) private var scheme
    @State private var selectedLanguage: AppLanguage = LanguageManager.shared.current

    private var strings: LanguageManager { .shared }
    private var visualControlsLocked: Bool { coordinator.activeThemeID.isSeasonal }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_app_preferences"),
            subtitle: strings.settings("settings_app_preferences_detail")
        ) {
            SettingsCardSection(title: strings.settings("settings_appearance"), icon: "paintbrush.fill") {
                if visualControlsLocked {
                    Label(
                        strings.settings("settings_theme_visuals_locked"),
                        systemImage: "lock.fill"
                    )
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, ShieldTheme.s2)
                }

                SettingsControlRow(
                    icon: "moon.fill",
                    color: Color(hex: "5E5CE6"),
                    title: strings.settings("settings_dark_mode")
                ) {
                    Toggle("", isOn: Binding(
                        get: { appState.preferredScheme == .dark },
                        set: { appState.preferredScheme = $0 ? .dark : .light }
                    ))
                    .labelsHidden()
                    .tint(ShieldTheme.accent(scheme))
                    .accessibilityLabel(strings.settings("settings_dark_mode"))
                    .disabled(visualControlsLocked)
                }
                SettingsRowDivider()
                SettingsControlRow(
                    icon: "globe",
                    color: Color(hex: "00C7BE"),
                    title: strings.settings("settings_language")
                ) {
                    Picker(strings.settings("settings_language"), selection: $selectedLanguage) {
                        Text(strings.common("common_language_es")).tag(AppLanguage.es)
                        Text(strings.common("common_language_en")).tag(AppLanguage.en)
                    }
                    .pickerStyle(.menu)
                    .tint(ShieldTheme.accent(scheme))
                }
            }

            SettingsCardSection(
                title: strings.settings("settings_app_icon"),
                icon: "app.badge.checkmark"
            ) {
                AppIconPickerSection()
                    .disabled(visualControlsLocked)
                    .opacity(visualControlsLocked ? 0.60 : 1)
            }
        }
        .onAppear { selectedLanguage = appState.language }
        .onChange(of: selectedLanguage) { _, newValue in
            guard appState.language != newValue else { return }
            appState.language = newValue
        }
    }
}

// MARK: - Seasonal themes

struct SeasonalThemeGalleryView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var coordinator: SeasonalThemeCoordinator
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var premium = PremiumManager.shared
    @State private var previewTheme: SeasonalThemeID?
    @State private var showPaywall = false
#if DEBUG
#if targetEnvironment(simulator)
    @State private var debugPreviewSelection = "automatic"
#endif
#endif

    private var strings: LanguageManager { .shared }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_themes_title"),
            subtitle: strings.settings("settings_themes_detail")
        ) {
            SeasonalThemeStatusCard(
                activeThemeID: coordinator.activeThemeID,
                selection: coordinator.selection,
                isPro: premium.isPro,
                onAutomatic: selectAutomatic,
                onBase: selectBase
            )

            if coordinator.activeThemeID == .halloween2026 {
                SeasonalThemeSoundControl(
                    isEnabled: coordinator.isSoundscapeEnabled,
                    onChange: coordinator.setSoundscapeEnabled
                )
            }

            SettingsCardSection(
                title: strings.settings("settings_theme_gallery_section"),
                icon: "square.grid.2x2.fill"
            ) {
                ForEach(Array(coordinator.definitions.enumerated()), id: \.element.id) { index, definition in
                    let availability = coordinator.availability(for: definition.id)
                    SeasonalThemeCard(
                        definition: definition,
                        availability: availability,
                        isSelected: coordinator.activeThemeID == definition.id,
                        isPro: premium.isPro,
                        canActivate: coordinator.canManuallyActivate(definition.id),
                        reduceMotion: reduceMotion,
                        onPreview: { previewTheme = definition.id },
                        onActivate: { activate(definition.id) }
                    )
                    if index < coordinator.definitions.count - 1 {
                        SettingsRowDivider()
                    }
                }
            }

            if !premium.isPro {
                ThemePremiumCallout(onUnlock: { showPaywall = true })
            }

#if DEBUG
#if targetEnvironment(simulator)
            debugThemePreviewSection
#endif
#endif
        }
        .onAppear {
            coordinator.refresh(isPro: premium.isPro)
#if DEBUG
#if targetEnvironment(simulator)
            debugPreviewSelection = coordinator.debugPreviewThemeID?.rawValue ?? "automatic"
#endif
#endif
        }
        .sheet(item: $previewTheme) { themeID in
            SeasonalThemePreviewSheet(
                themeID: themeID,
                isPro: premium.isPro,
                availability: coordinator.availability(for: themeID),
                canActivate: coordinator.canManuallyActivate(themeID),
                onActivate: { activate(themeID) },
                onUnlock: { showPaywall = true }
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: .styleLocked)
                .environmentObject(appState)
        }
    }

    private func selectAutomatic() {
        appState.clearSeasonalIconOverride()
        _ = coordinator.select(.automatic)
        coordinator.refresh(isPro: premium.isPro)
        appState.applySeasonalThemeIcon(for: coordinator.activeThemeID, isPro: premium.isPro)
    }

    private func selectBase() {
        appState.clearSeasonalIconOverride()
        _ = coordinator.select(.base)
        appState.applySeasonalThemeIcon(for: coordinator.activeThemeID, isPro: premium.isPro)
    }

    private func activate(_ themeID: SeasonalThemeID) {
        guard premium.isPro else {
            if themeID != .base { showPaywall = true }
            return
        }
        guard coordinator.canManuallyActivate(themeID) else {
            return
        }
        appState.clearSeasonalIconOverride()
        _ = coordinator.select(themeID == .base ? .base : .manual(themeID))
        appState.applySeasonalThemeIcon(for: coordinator.activeThemeID, isPro: premium.isPro)
        previewTheme = nil
    }

#if DEBUG
#if targetEnvironment(simulator)
    private var debugThemePreviewSection: some View {
        SettingsCardSection(
            title: strings.settings("settings_theme_debug_section"),
            icon: "ladybug.fill"
        ) {
            SettingsControlRow(
                icon: "wand.and.stars",
                color: Color(hex: "FF9F0A"),
                title: strings.settings("settings_theme_debug_selector"),
                subtitle: strings.settings("settings_theme_debug_detail")
            ) {
                Picker(
                    strings.settings("settings_theme_debug_selector"),
                    selection: $debugPreviewSelection
                ) {
                    Text(strings.settings("settings_theme_debug_automatic"))
                        .tag("automatic")
                    ForEach(coordinator.definitions) { definition in
                        Text(definition.id.title(language: strings.currentLanguage))
                            .tag(definition.id.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .tint(ShieldTheme.accent(scheme))
                .accessibilityIdentifier("settings.theme.debugPicker")
                .onChange(of: debugPreviewSelection) { _, newValue in
                    applyDebugPreviewSelection(newValue)
                }
            }

            SettingsRowDivider()

            Button {
                debugPreviewSelection = "automatic"
                applyDebugPreviewSelection("automatic")
            } label: {
                HStack(spacing: ShieldTheme.s2) {
                    Image(systemName: "arrow.uturn.backward.circle")
                    Text(strings.settings("settings_theme_debug_reset"))
                    Spacer(minLength: 0)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ShieldTheme.primary(scheme))
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .padding(.horizontal, ShieldTheme.s4)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityIdentifier("settings.theme.debugReset")
        }
    }

    private func applyDebugPreviewSelection(_ rawValue: String) {
        let themeID = rawValue == "automatic" ? nil : SeasonalThemeID(rawValue: rawValue)
        // This simulator-only path intentionally bypasses the production
        // Premium gate so Free accounts can inspect the complete theme.
        coordinator.setDebugPreviewTheme(themeID)
        appState.applySeasonalThemeIcon(for: coordinator.activeThemeID, isPro: premium.isPro)
    }
#endif
#endif
}

private struct SeasonalThemeSoundControl: View {
    let isEnabled: Bool
    let onChange: (Bool) -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animPhase: CGFloat = 0
    private var strings: LanguageManager { .shared }

    var body: some View {
        HStack(spacing: ShieldTheme.s3) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        isEnabled
                            ? LinearGradient(colors: [ShieldTheme.halloweenBlood, Color(hex: "5A1028")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [ShieldTheme.halloweenBlood.opacity(0.18)], startPoint: .top, endPoint: .bottom)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(
                                isEnabled ? Color(hex: "FF9A3D").opacity(0.4) : Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    }

                if isEnabled {
                    // Animated Equalizer Waveform
                    HStack(spacing: 2.5) {
                        ForEach(0..<4, id: \.self) { bar in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: "FFD6A0"))
                                .frame(width: 3, height: CGFloat(8 + (bar % 3) * 6))
                                .scaleEffect(y: reduceMotion ? 1.0 : (animPhase > 0 ? 1.2 : 0.6), anchor: .bottom)
                                .animation(
                                    reduceMotion ? nil : .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(bar) * 0.12),
                                    value: animPhase
                                )
                        }
                    }
                } else {
                    Image(systemName: "speaker.slash.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(ShieldTheme.halloweenBloodHighlight)
                }
            }
            .frame(width: 46, height: 46)
            .accessibilityHidden(true)
            .onAppear {
                if !reduceMotion { animPhase = 1 }
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(strings.settings("settings_theme_soundscape_title"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(ShieldTheme.primary(scheme))
                    if isEnabled {
                        Text("ON")
                            .font(.caption2.weight(.heavy))
                            .foregroundStyle(Color(hex: "170A02"))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: "FFA53D"), in: Capsule())
                    }
                }
                Text(strings.settings("settings_theme_soundscape_detail"))
                    .font(.subheadline)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: ShieldTheme.s2)

            Toggle(
                strings.settings("settings_theme_soundscape_title"),
                isOn: Binding(
                    get: { isEnabled },
                    set: onChange
                )
            )
            .labelsHidden()
            .tint(ShieldTheme.accent(scheme))
            .accessibilityLabel(strings.settings("settings_theme_soundscape_title"))
            .accessibilityHint(strings.settings("settings_theme_soundscape_detail"))
        }
        .padding(ShieldTheme.s4)
        .shieldSettingsCard()
    }
}

private struct SeasonalThemeStatusCard: View {
    let activeThemeID: SeasonalThemeID
    let selection: SeasonalThemeSelection
    let isPro: Bool
    let onAutomatic: () -> Void
    let onBase: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    private var strings: LanguageManager { .shared }

    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark && !reduceTransparency
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s4) {
            HStack(spacing: ShieldTheme.s3) {
                ZStack {
                    Circle()
                        .fill(
                            isHalloween
                                ? LinearGradient(colors: [Color(hex: "F97316").opacity(0.3), Color(hex: "7C3AED").opacity(0.15)], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [ShieldTheme.accent(scheme).opacity(0.18)], startPoint: .top, endPoint: .bottom)
                        )
                        .overlay {
                            if isHalloween {
                                Circle().stroke(Color(hex: "FF9A3D").opacity(0.4), lineWidth: 1)
                            }
                        }

                    if activeThemeID == .halloween2026 {
                        SeasonalThemeHalloweenPumpkin(size: 26)
                    } else {
                        Image(systemName: "wand.and.stars")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(ShieldTheme.accent(scheme))
                    }
                }
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(strings.settings("settings_theme_current"))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(isHalloween ? Color(hex: "FFD6B0") : ShieldTheme.secondary(scheme))
                    Text(activeThemeID.title(language: strings.currentLanguage))
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(ShieldTheme.primary(scheme))
                }
                Spacer()
                Text(isPro ? strings.settings("settings_plan_pro") : strings.settings("settings_plan_free"))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isPro ? ShieldTheme.accent(scheme) : ShieldTheme.success)
                    .padding(.horizontal, ShieldTheme.s3)
                    .padding(.vertical, ShieldTheme.s2)
                    .background(
                        isHalloween ? Color(hex: "291636") : ShieldTheme.rowBackground(scheme),
                        in: Capsule()
                    )
            }

            Text(strings.settings("settings_theme_timezone_note"))
                .font(.subheadline)
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: ShieldTheme.s2) {
                Button(action: onAutomatic) {
                    Label(
                        strings.settings("settings_theme_automatic"),
                        systemImage: isAutomatic ? "checkmark.circle.fill" : "calendar"
                    )
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .foregroundStyle(isAutomatic ? (isHalloween ? Color(hex: "170A02") : ShieldTheme.accentText) : ShieldTheme.primary(scheme))
                    .background(
                        isAutomatic
                            ? (isHalloween
                                ? LinearGradient(colors: [Color(hex: "FFA53D"), Color(hex: "F97316")], startPoint: .top, endPoint: .bottom)
                                : LinearGradient(colors: [ShieldTheme.accent(scheme)], startPoint: .top, endPoint: .bottom))
                            : LinearGradient(colors: [ShieldTheme.rowBackground(scheme)], startPoint: .top, endPoint: .bottom),
                        in: RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                    )
                }
                .buttonStyle(ScaleButtonStyle())

                if isPro {
                    Button(action: onBase) {
                        Label(
                            strings.settings("settings_theme_base_short"),
                            systemImage: isBase ? "checkmark.circle.fill" : "circle"
                        )
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .foregroundStyle(isBase ? ShieldTheme.accentText : ShieldTheme.primary(scheme))
                        .background(
                            isBase ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme),
                            in: RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(ShieldTheme.s4)
        .shieldSettingsCard()
        .accessibilityElement(children: .contain)
    }

    private var isAutomatic: Bool {
        if case .automatic = selection { return true }
        return false
    }

    private var isBase: Bool {
        if case .base = selection { return true }
        return false
    }
}

private struct SeasonalThemeCard: View {
    let definition: SeasonalThemeDefinition
    let availability: SeasonalThemeAvailability
    let isSelected: Bool
    let isPro: Bool
    let canActivate: Bool
    let reduceMotion: Bool
    let onPreview: () -> Void
    let onActivate: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    private var strings: LanguageManager { .shared }

    private var isHalloween: Bool {
        definition.id == .halloween2026 && scheme == .dark && !reduceTransparency
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            Button(action: onPreview) {
                HStack(spacing: ShieldTheme.s4) {
                    SeasonalThemeMiniPreview(themeID: definition.id, reduceMotion: reduceMotion)
                        .frame(width: 76, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous)
                                .stroke(
                                    isHalloween && isSelected
                                        ? Color(hex: "FF9A3D").opacity(0.6)
                                        : Color.white.opacity(0.12),
                                    lineWidth: 1
                                )
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: ShieldTheme.s2) {
                            Text(definition.id.title(language: strings.currentLanguage))
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(ShieldTheme.primary(scheme))
                            if definition.requiresProForManualActivation {
                                Text("PRO")
                                    .font(.caption2.weight(.heavy))
                                    .foregroundStyle(isHalloween ? Color(hex: "170A02") : ShieldTheme.accentText)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.accent(scheme), in: Capsule())
                            }
                        }
                        Text(definition.id.subtitle(language: strings.currentLanguage))
                            .font(.subheadline)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(statusTitle)
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(statusColor)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.forward")
                        .font(.body.weight(.bold))
                        .foregroundStyle(
                            isHalloween ? Color(hex: "FFD6A0").opacity(0.85) : ShieldTheme.tertiary(scheme)
                        )
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityIdentifier("settings.theme.preview.\(definition.id.rawValue)")

            Button(action: onActivate) {
                HStack(spacing: ShieldTheme.s2) {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    Text(isSelected ? strings.settings("settings_theme_active") : actionTitle)
                    Spacer()
                    if !isPro && definition.requiresProForManualActivation {
                        Image(systemName: "lock.fill")
                    }
                }
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(
                    isSelected
                        ? (isHalloween ? Color(hex: "170A02") : ShieldTheme.accentText)
                        : ShieldTheme.primary(scheme)
                )
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.horizontal, ShieldTheme.s3)
                .background(
                    isSelected
                        ? (isHalloween
                            ? LinearGradient(colors: [Color(hex: "FFA53D"), Color(hex: "F97316"), Color(hex: "EA580C")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [ShieldTheme.accent(scheme)], startPoint: .top, endPoint: .bottom))
                        : (isHalloween
                            ? LinearGradient(colors: [Color(hex: "291636").opacity(0.8)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [ShieldTheme.rowBackground(scheme)], startPoint: .top, endPoint: .bottom)),
                    in: RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                )
                .overlay {
                    if isSelected && isHalloween {
                        RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                            .stroke(Color(hex: "FFD6A0").opacity(0.55), lineWidth: 1)
                    }
                }
                .shadow(
                    color: isSelected && isHalloween ? Color(hex: "F97316").opacity(0.5) : Color.clear,
                    radius: 8,
                    y: 2
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!canActivate)
            .opacity(canActivate ? 1 : 0.72)
            .accessibilityIdentifier("settings.theme.activate.\(definition.id.rawValue)")
            .accessibilityHint(canActivate ? "" : strings.settings("settings_theme_event_upcoming_message"))
        }
        .padding(ShieldTheme.s4)
    }

    private var statusTitle: String {
        switch availability {
        case .base:
            return "\(strings.settings("settings_theme_status_base")) 🛡️"
        case .upcoming:
            return "\(strings.settings("settings_theme_status_upcoming")) ⏳"
        case .active:
            return definition.id == .halloween2026
                ? "\(strings.settings("settings_theme_status_active")) 🎃"
                : strings.settings("settings_theme_status_active")
        case .archived:
            return "\(strings.settings("settings_theme_status_archived")) 📜"
        }
    }

    private var statusColor: Color {
        switch availability {
        case .active: return ShieldTheme.success
        case .upcoming: return ShieldTheme.warning
        case .archived: return ShieldTheme.tertiary(scheme)
        case .base: return ShieldTheme.accent(scheme)
        }
    }

    private var actionTitle: String {
        if definition.id == .base {
            return isPro
                ? strings.settings("settings_theme_use_base")
                : strings.settings("settings_theme_automatic")
        }
        if availability == .upcoming { return strings.settings("settings_theme_scheduled") }
        return isPro ? strings.settings("settings_theme_activate") : strings.settings("settings_theme_unlock")
    }
}

private struct SeasonalThemeMiniPreview: View {
    let themeID: SeasonalThemeID
    let reduceMotion: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                colors: themeID == .halloween2026
                    ? [Color(hex: "22102A"), Color(hex: "7C2D12")]
                    : [Color(hex: "071426"), Color(hex: "20C7D9")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: themeID == .halloween2026 ? "moon.stars.fill" : "shield.fill")
                .font(.title2.weight(.bold))
                .foregroundStyle(themeID == .halloween2026 ? Color(hex: "FF9A3D") : .white)
                .scaleEffect(reduceMotion ? 1 : 1.05)

            if themeID == .halloween2026 {
                Image(systemName: "network")
                    .font(.system(size: 30, weight: .ultraLight))
                    .foregroundStyle(Color(hex: "FFD6B0").opacity(0.22))
                    .offset(x: 22, y: -20)
                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(hex: "A3E635").opacity(0.78))
                    .offset(x: -26, y: 22)
            }
        }
        .accessibilityHidden(true)
    }
}

private struct ThemePremiumCallout: View {
    let onUnlock: () -> Void
    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            Label(strings.settings("settings_theme_pro_callout_title"), systemImage: "sparkles")
                .font(.headline.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))
            Text(strings.settings("settings_theme_pro_callout_subtitle"))
                .font(.subheadline)
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
            Button(action: onUnlock) {
                Text(strings.settings("settings_view_options"))
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity, minHeight: 46)
                    .foregroundStyle(ShieldTheme.accentText)
                    .background(ShieldTheme.accent(scheme), in: RoundedRectangle(cornerRadius: ShieldTheme.rMD))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(ShieldTheme.s4)
        .shieldSettingsCard()
    }
}

private struct SeasonalThemePreviewSheet: View {
    let themeID: SeasonalThemeID
    let isPro: Bool
    let availability: SeasonalThemeAvailability
    let canActivate: Bool
    let onActivate: () -> Void
    let onUnlock: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var strings: LanguageManager { .shared }

    var body: some View {
        NavigationStack {
            ZStack {
                ShieldTheme.pageBackground(scheme).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: ShieldTheme.s5) {
                        SeasonalThemePreviewBanner(themeID: themeID, reduceMotion: reduceMotion)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rXL, style: .continuous))
                            .overlay(alignment: .bottomLeading) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(themeID.title(language: strings.currentLanguage))
                                        .font(.largeTitle.weight(.heavy))
                                    Text(themeID.subtitle(language: strings.currentLanguage))
                                        .font(.subheadline.weight(.semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(ShieldTheme.s5)
                            }

                        if let assetName = SeasonalThemeCatalog.definition(for: themeID)?.eventDetailArtworkAssetName {
                            SeasonalThemePreviewArtwork(
                                assetName: assetName,
                                accessibilityLabel: strings.settings("settings_theme_event_artwork")
                            )
                        }

                        SeasonalThemePreviewOverview(themeID: themeID)

                        SeasonalThemePreviewVisuals(themeID: themeID, reduceMotion: reduceMotion)

                        if let definition = SeasonalThemeCatalog.definition(for: themeID),
                           let eventNameKey = definition.eventNameKey,
                           let eventDescriptionKey = definition.eventDescriptionKey,
                           let schedule = definition.schedule {
                            SeasonalThemeEventDetails(
                                name: strings.settings(eventNameKey),
                                description: strings.settings(eventDescriptionKey),
                                schedule: schedule,
                                language: strings.currentLanguage
                            )
                        }

                        if availability == .upcoming {
                            Label(
                                strings.settings("settings_theme_event_upcoming_message"),
                                systemImage: "clock.badge"
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ShieldTheme.warning)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        } else if themeID.isSeasonal && !isPro {
                            Label(
                                strings.settings("settings_theme_event_automatic_message"),
                                systemImage: "calendar.badge.clock"
                            )
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                        }

                        Button {
                            if availability == .upcoming || (themeID == .base && !isPro) {
                                return
                            }
                            if isPro || themeID == .base { onActivate() } else { onUnlock() }
                        } label: {
                            Text(availability == .upcoming
                                 ? strings.settings("settings_theme_scheduled")
                                 : (themeID == .base && !isPro
                                    ? strings.settings("settings_theme_automatic")
                                    : (isPro || themeID == .base
                                       ? strings.settings("settings_theme_activate")
                                       : strings.settings("settings_theme_unlock"))))
                                .font(.headline.weight(.bold))
                                .frame(maxWidth: .infinity, minHeight: 50)
                                .foregroundStyle(
                                    availability == .upcoming || (themeID == .base && !isPro)
                                        ? ShieldTheme.secondary(scheme)
                                        : ShieldTheme.accentText
                                )
                                .background(
                                    availability == .upcoming || (themeID == .base && !isPro)
                                        ? ShieldTheme.rowBackground(scheme)
                                        : ShieldTheme.accent(scheme),
                                    in: RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(availability == .upcoming || (themeID == .base && !isPro))
                        .accessibilityHint(
                            availability == .upcoming
                                ? strings.settings("settings_theme_event_upcoming_message")
                                : (themeID == .base && !isPro
                                   ? strings.settings("settings_theme_automatic")
                                   : "")
                        )
                    }
                    .padding(ShieldTheme.s4)
                }
            }
            .navigationTitle(strings.settings("settings_theme_preview"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.common("common_close"), action: dismiss.callAsFunction)
                }
            }
        }
    }
}

private struct SeasonalThemePreviewArtwork: View {
    let assetName: String
    let accessibilityLabel: String

    var body: some View {
        Image(assetName)
            .resizable()
            .scaledToFill()
            .aspectRatio(9.0 / 16.0, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rXL, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ShieldTheme.rXL, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
            }
            .accessibilityLabel(accessibilityLabel)
    }
}

private struct SeasonalThemePreviewBanner: View {
    let themeID: SeasonalThemeID
    let reduceMotion: Bool

    var body: some View {
        Group {
            if let assetName = SeasonalThemeCatalog.definition(for: themeID)?.eventBannerAssetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                SeasonalThemeMiniPreview(themeID: themeID, reduceMotion: reduceMotion)
            }
        }
        .overlay {
            LinearGradient(
                colors: [.clear, .black.opacity(0.68)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .accessibilityLabel(
            themeID == .halloween2026
                ? LanguageManager.shared.settings("settings_theme_halloween_banner_accessibility")
                : LanguageManager.shared.settings("settings_theme_base")
        )
    }
}

private struct SeasonalThemePreviewOverview: View {
    let themeID: SeasonalThemeID

    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            Text(strings.settings("settings_theme_information"))
                .font(.headline.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))

            Text(themeID == .halloween2026
                 ? strings.settings("settings_theme_halloween_preview_detail")
                 : strings.settings("settings_theme_base_subtitle"))
                .font(.body)
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SeasonalThemePreviewVisuals: View {
    let themeID: SeasonalThemeID
    let reduceMotion: Bool

    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            Text(strings.settings("settings_theme_visual_preview"))
                .font(.headline.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))

            HStack(alignment: .top, spacing: ShieldTheme.s4) {
                VStack(spacing: ShieldTheme.s2) {
                    Group {
                        if let icon = themeID.icon {
                            icon.image
                                .resizable()
                                .scaledToFit()
                        } else {
                            AppIconOption.defaultIcon.image
                                .resizable()
                                .scaledToFit()
                                .padding(12)
                        }
                    }
                    .frame(width: 78, height: 78)
                    .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous)
                            .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
                    }

                    Text(strings.settings("settings_theme_icon_preview"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                        .multilineTextAlignment(.center)
                }
                .frame(width: 82)

                SeasonalThemeHomeSnapshot(themeID: themeID, reduceMotion: reduceMotion)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SeasonalThemeHomeSnapshot: View {
    let themeID: SeasonalThemeID
    let reduceMotion: Bool

    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    private var isHalloween: Bool { themeID == .halloween2026 }
    private var snapshotBackground: Color {
        isHalloween ? Color(hex: "100A14") : ShieldTheme.background(scheme)
    }
    private var snapshotCard: Color {
        isHalloween ? Color(hex: "26142E") : ShieldTheme.cardBackground(scheme)
    }
    private var snapshotAccent: Color {
        isHalloween ? Color(hex: "F97316") : ShieldTheme.accent(scheme)
    }
    private var snapshotAccentText: Color {
        isHalloween ? Color(hex: "1B0E05") : ShieldTheme.accentText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                if let icon = themeID.icon {
                    icon.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                } else {
                    AppIconOption.defaultIcon.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("MaskID")
                        .font(.caption.weight(.bold))
                    Text(strings.settings("settings_theme_home_preview_subtitle"))
                        .font(.caption2)
                        .opacity(0.62)
                }
                .foregroundStyle(isHalloween ? Color(hex: "FFF7F0") : ShieldTheme.primary(scheme))

                Spacer(minLength: 0)
                Image(systemName: "slider.horizontal.3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isHalloween ? Color(hex: "FFD6B0") : ShieldTheme.secondary(scheme))
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(strings.settings("settings_theme_home_preview_title"))
                            .font(.subheadline.weight(.heavy))
                        Text(strings.settings("settings_theme_home_preview_detail"))
                            .font(.caption2)
                            .fixedSize(horizontal: false, vertical: true)
                            .opacity(0.72)
                    }
                    .foregroundStyle(isHalloween ? Color(hex: "FFF7F0") : ShieldTheme.primary(scheme))

                    Spacer(minLength: 0)
                    Image(systemName: isHalloween ? "moon.stars.fill" : "lock.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(snapshotAccent)
                }

                HStack(spacing: 6) {
                    Image(systemName: "viewfinder")
                    Text(strings.settings("settings_theme_home_preview_action"))
                }
                .font(.caption.weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 30)
                .foregroundStyle(snapshotAccentText)
                .background(snapshotAccent, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .padding(10)
            .background(snapshotCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            HStack(spacing: 5) {
                ForEach([
                    "settings_theme_home_preview_chip_one",
                    "settings_theme_home_preview_chip_two",
                    "settings_theme_home_preview_chip_three"
                ], id: \.self) { key in
                    Text(strings.settings(key))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isHalloween ? Color(hex: "FFD6B0") : ShieldTheme.secondary(scheme))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(snapshotCard.opacity(0.78), in: Capsule())
                }
            }
            .lineLimit(1)
        }
        .padding(10)
        .background(snapshotBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isHalloween ? Color(hex: "FFD6B0").opacity(0.16) : ShieldTheme.line(scheme), lineWidth: 0.8)
        }
        .scaleEffect(reduceMotion ? 1 : 1.002)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(strings.settings("settings_theme_home_preview_accessibility"))
    }
}

private struct SeasonalThemeEventDetails: View {
    let name: String
    let description: String
    let schedule: SeasonalThemeSchedule
    let language: AppLanguage

    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s4) {
            Text(strings.settings("settings_theme_event_section"))
                .font(.headline.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))

            VStack(alignment: .leading, spacing: ShieldTheme.s3) {
                Text(name)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ShieldTheme.primary(scheme))

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: ShieldTheme.s3) {
                    ThemeEventDateCard(
                        label: strings.settings("settings_theme_event_start"),
                        date: eventDate(isStart: true)
                    )
                    ThemeEventDateCard(
                        label: strings.settings("settings_theme_event_end"),
                        date: eventDate(isStart: false)
                    )
                }

                if let referenceTimeZoneIdentifier = schedule.referenceTimeZoneIdentifier {
                    Label {
                        Text(strings.settings("settings_theme_event_timezone"))
                        Text(referenceTimeZoneIdentifier)
                            .fontWeight(.semibold)
                    } icon: {
                        Image(systemName: "globe")
                    }
                    .font(.caption)
                    .foregroundStyle(ShieldTheme.tertiary(scheme))
                }

                Label(
                    strings.settings("settings_theme_event_device_time"),
                    systemImage: "clock"
                )
                .font(.caption)
                .foregroundStyle(ShieldTheme.tertiary(scheme))
            }
            .padding(ShieldTheme.s4)
            .background(ShieldTheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous)
                    .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func eventDate(isStart: Bool) -> String {
        let clock = SeasonalThemeClock(timeZone: .autoupdatingCurrent)
        guard let bounds = schedule.bounds(using: clock) else { return "—" }
        let date = isStart ? bounds.start : bounds.end.addingTimeInterval(-1)
        let locale = Locale(identifier: language.rawValue)
        return date.formatted(
                .dateTime.day().month(.wide).year().hour().minute()
                .locale(locale)
        )
    }
}

private struct ThemeEventDateCard: View {
    let label: String
    let date: String

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ShieldTheme.tertiary(scheme))
            Text(date)
                .font(.caption.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ShieldTheme.s3)
        .background(ShieldTheme.rowBackground(scheme), in: RoundedRectangle(cornerRadius: ShieldTheme.rSM, style: .continuous))
    }
}

// MARK: - Security and privacy

struct SecuritySettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var scheme

    @State private var biometricEnabled = UserDefaults.standard.bool(forKey: "shield.biometric")
    @State private var hapticEnabled = UserDefaults.standard.object(forKey: "shield.haptic") == nil
        ? true : UserDefaults.standard.bool(forKey: "shield.haptic")
    @State private var strictKYCEnabled = UserDefaults.standard.bool(forKey: "shield.ocr.strictKYC")
    @State private var warnLowConfidenceEnabled = UserDefaults.standard.object(forKey: "shield.ocr.warnLowConfidence") == nil
        ? true : UserDefaults.standard.bool(forKey: "shield.ocr.warnLowConfidence")
    @State private var autoLockIndex = UserDefaults.standard.integer(forKey: "shield.autoLock")
    @State private var confidenceIndex = UserDefaults.standard.object(forKey: "shield.ocr.minConfidence") == nil
        ? 1 : UserDefaults.standard.integer(forKey: "shield.ocr.minConfidence")
    @State private var showPINSetup = false
    @State private var showPINEntry = false
    @State private var showBiometricAlert = false
    @State private var pendingBiometricEnable = false
    @State private var showDeleteConfirm = false

    private let confidenceOptions = ["70%", "80%", "90%"]
    private var strings: LanguageManager { .shared }

    private var autoLockOptions: [String] {
        [
            strings.settings("settings_autolock_immediately"),
            strings.settings("settings_autolock_1_minute"),
            strings.settings("settings_autolock_5_minutes"),
            strings.settings("settings_autolock_15_minutes"),
            strings.settings("settings_autolock_never")
        ]
    }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_security_privacy"),
            subtitle: strings.settings("settings_security_detail")
        ) {
            SettingsCardSection(title: strings.settings("settings_access_protection"), icon: "lock.fill") {
                SettingsControlRow(
                    icon: "faceid",
                    color: Color(hex: "30D158"),
                    title: strings.settings("settings_face_id")
                ) {
                    Toggle("", isOn: $biometricEnabled)
                        .labelsHidden()
                        .tint(ShieldTheme.accent(scheme))
                        .accessibilityLabel(strings.settings("settings_face_id"))
                }
                SettingsRowDivider()
                SettingsActionRow(
                    icon: "lock.circle.fill",
                    color: Color(hex: "BF5AF2"),
                    title: PINManager.hasPIN
                        ? strings.settings("settings_change_pin")
                        : strings.settings("settings_setup_pin"),
                    subtitle: strings.settings("settings_pin_subtitle")
                ) {
                    if PINManager.hasPIN { showPINEntry = true } else { showPINSetup = true }
                }
                SettingsRowDivider()
                SettingsControlRow(
                    icon: "lock.rotation",
                    color: Color(hex: "FF9F0A"),
                    title: strings.settings("settings_auto_lock")
                ) {
                    Picker(strings.settings("settings_auto_lock"), selection: $autoLockIndex) {
                        ForEach(autoLockOptions.indices, id: \.self) { index in
                            Text(autoLockOptions[index]).tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(ShieldTheme.accent(scheme))
                }
            }

            SettingsCardSection(title: strings.settings("settings_detection_review"), icon: "text.viewfinder") {
                toggleRow(
                    icon: "hand.tap.fill",
                    color: Color(hex: "FF453A"),
                    title: strings.settings("settings_haptic_feedback"),
                    binding: $hapticEnabled
                )
                SettingsRowDivider()
                toggleRow(
                    icon: "checkmark.shield.fill",
                    color: Color(hex: "0A84FF"),
                    title: strings.settings("settings_strict_kyc"),
                    binding: $strictKYCEnabled
                )
                SettingsRowDivider()
                toggleRow(
                    icon: "exclamationmark.triangle.fill",
                    color: Color(hex: "FF9F0A"),
                    title: strings.settings("settings_low_confidence_alert"),
                    binding: $warnLowConfidenceEnabled
                )
                SettingsRowDivider()
                SettingsControlRow(
                    icon: "slider.horizontal.3",
                    color: Color(hex: "64D2FF"),
                    title: strings.settings("settings_ocr_threshold")
                ) {
                    Picker(strings.settings("settings_ocr_threshold"), selection: $confidenceIndex) {
                        ForEach(confidenceOptions.indices, id: \.self) { index in
                            Text(confidenceOptions[index]).tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(ShieldTheme.accent(scheme))
                }
            }

            SettingsCardSection(title: strings.settings("settings_data_management"), icon: "trash.fill") {
                SettingsActionRow(
                    icon: "trash.fill",
                    color: Color(hex: "FF453A"),
                    title: strings.settings("settings_delete_all_documents"),
                    subtitle: strings.settings("settings_delete_all_subtitle"),
                    action: { showDeleteConfirm = true }
                )
            }
        }
        .fullScreenCover(isPresented: $showPINSetup) {
            PINSetupView(isPresented: $showPINSetup) {
                if pendingBiometricEnable {
                    pendingBiometricEnable = false
                    enableBiometrics()
                }
            }
            .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showPINEntry) {
            PINEntryView(isPresented: $showPINEntry) { showPINSetup = true }
                .environmentObject(appState)
        }
        .alert(strings.settings("settings_biometric_unavailable"), isPresented: $showBiometricAlert) {
            Button(strings.common("common_ok"), role: .cancel) {}
        } message: {
            Text(strings.settings("settings_biometric_unavailable_message"))
        }
        .confirmationDialog(
            strings.settings("settings_delete_all_confirm_title"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(strings.settings("settings_delete_all_button"), role: .destructive) {
                appState.deleteAllDocuments()
            }
            Button(strings.common("common_cancel"), role: .cancel) {}
        } message: {
            Text(strings.settings("settings_delete_all_confirm_message"))
        }
        .onAppear(perform: sanitizeSelections)
        .onChange(of: biometricEnabled) { oldValue, newValue in
            guard oldValue != newValue else { return }
            if newValue {
                guard PINManager.hasPIN else {
                    pendingBiometricEnable = true
                    biometricEnabled = false
                    showPINSetup = true
                    return
                }
                enableBiometrics()
            } else if !pendingBiometricEnable {
                UserDefaults.standard.set(false, forKey: "shield.biometric")
            }
        }
        .onChange(of: autoLockIndex) { _, value in UserDefaults.standard.set(value, forKey: "shield.autoLock") }
        .onChange(of: hapticEnabled) { _, value in UserDefaults.standard.set(value, forKey: "shield.haptic") }
        .onChange(of: strictKYCEnabled) { _, value in UserDefaults.standard.set(value, forKey: "shield.ocr.strictKYC") }
        .onChange(of: warnLowConfidenceEnabled) { _, value in UserDefaults.standard.set(value, forKey: "shield.ocr.warnLowConfidence") }
        .onChange(of: confidenceIndex) { _, value in UserDefaults.standard.set(value, forKey: "shield.ocr.minConfidence") }
    }

    private func toggleRow(icon: String, color: Color, title: String, binding: Binding<Bool>) -> some View {
        SettingsControlRow(icon: icon, color: color, title: title) {
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(ShieldTheme.accent(scheme))
                .accessibilityLabel(title)
        }
    }

    private func sanitizeSelections() {
        autoLockIndex = max(0, min(autoLockIndex, autoLockOptions.count - 1))
        confidenceIndex = max(0, min(confidenceIndex, confidenceOptions.count - 1))
    }

    private func enableBiometrics() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricEnabled = false
            UserDefaults.standard.set(false, forKey: "shield.biometric")
            showBiometricAlert = true
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: strings.settings("settings_biometric_reason")
        ) { success, _ in
            DispatchQueue.main.async {
                biometricEnabled = success
                UserDefaults.standard.set(success, forKey: "shield.biometric")
                if !success { showBiometricAlert = true }
            }
        }
    }
}

// MARK: - Cloud and export

struct CloudSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var scheme
    @StateObject private var premium = PremiumManager.shared
    @ObservedObject private var cloud = CloudSyncManager.shared
    @State private var isEnabled = UserDefaults.standard.bool(forKey: "shield.icloud.enabled")
    @State private var showPaywall = false

    private var strings: LanguageManager { .shared }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_icloud_sync"),
            subtitle: strings.settings("settings_icloud_detail")
        ) {
            SettingsCardSection(title: strings.settings("settings_sync_controls"), icon: "icloud.fill") {
                if premium.isPro {
                    SettingsControlRow(
                        icon: "icloud.fill",
                        color: Color(hex: "5E5CE6"),
                        title: strings.settings("settings_icloud_sync_with"),
                        subtitle: strings.settings("settings_icloud_minimized_note")
                    ) {
                        Toggle("", isOn: $isEnabled)
                            .labelsHidden()
                            .tint(ShieldTheme.accent(scheme))
                            .accessibilityLabel(strings.settings("settings_icloud_sync_with"))
                    }
                    if isEnabled {
                        SettingsRowDivider()
                        SettingsActionRow(
                            icon: "arrow.clockwise.icloud.fill",
                            color: Color(hex: "64D2FF"),
                            title: strings.settings("settings_icloud_sync_now"),
                            subtitle: syncStatus,
                            action: syncNow
                        )
                    }
                } else {
                    SettingsActionRow(
                        icon: "sparkles",
                        color: ShieldTheme.accent(scheme),
                        title: strings.settings("settings_icloud_pro_only"),
                        subtitle: strings.settings("settings_icloud_pro_subtitle"),
                        action: {
                            PremiumManager.recordFeatureGate(.cloudWorkflow, trigger: .settingsUpgrade)
                            showPaywall = true
                        }
                    )
                }
            }

            SettingsArticleCallout(
                icon: "hand.raised.fill",
                title: strings.settings("settings_private_by_design"),
                bodyText: strings.settings("settings_icloud_privacy_explanation")
            )
        }
        .onChange(of: isEnabled) { _, enabled in
            Task {
                let changed = await cloud.setSyncEnabled(enabled)
                if changed, enabled {
                    await cloud.syncNow(appState: appState)
                } else if !changed {
                    await MainActor.run { isEnabled = !enabled }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: .settingsUpgrade)
                .environmentObject(appState)
        }
    }

    private var syncStatus: String {
        if case .syncing = cloud.syncStatus { return strings.settings("settings_syncing") }
        if let lastSync = cloud.lastSyncFormatted {
            return strings.settings("settings_last_sync_value", lastSync)
        }
        if !cloud.isAvailable { return strings.settings("settings_icloud_unavailable") }
        return strings.settings("settings_sync_ready")
    }

    private func syncNow() {
        Task { await cloud.syncNow(appState: appState) }
    }
}

struct ExportSettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var formatIndex = UserDefaults.standard.integer(forKey: "shield.exportFormat")
    @State private var qualityIndex = UserDefaults.standard.integer(forKey: "shield.exportQuality")

    private var strings: LanguageManager { .shared }
    private var formats: [String] {
        [strings.settings("settings_format_pdf"), strings.settings("settings_format_image")]
    }
    private var qualities: [String] {
        [
            strings.settings("settings_quality_high"),
            strings.settings("settings_quality_medium"),
            strings.settings("settings_quality_low")
        ]
    }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_export_preferences"),
            subtitle: strings.settings("settings_export_detail")
        ) {
            SettingsCardSection(title: strings.settings("settings_export"), icon: "square.and.arrow.up.fill") {
                SettingsControlRow(
                    icon: "doc.fill",
                    color: Color(hex: "D9AA00"),
                    title: strings.settings("settings_default_format")
                ) {
                    Picker(strings.settings("settings_default_format"), selection: $formatIndex) {
                        ForEach(formats.indices, id: \.self) { index in Text(formats[index]).tag(index) }
                    }
                    .pickerStyle(.menu)
                    .tint(ShieldTheme.accent(scheme))
                }
                SettingsRowDivider()
                SettingsControlRow(
                    icon: "photo.fill",
                    color: Color(hex: "64D2FF"),
                    title: strings.settings("settings_image_quality")
                ) {
                    Picker(strings.settings("settings_image_quality"), selection: $qualityIndex) {
                        ForEach(qualities.indices, id: \.self) { index in Text(qualities[index]).tag(index) }
                    }
                    .pickerStyle(.menu)
                    .tint(ShieldTheme.accent(scheme))
                }
            }

            SettingsArticleCallout(
                icon: "checkmark.shield.fill",
                title: strings.settings("settings_verified_export_title"),
                bodyText: strings.settings("settings_verified_export_body")
            )
        }
        .onAppear {
            formatIndex = max(0, min(formatIndex, formats.count - 1))
            qualityIndex = max(0, min(qualityIndex, qualities.count - 1))
        }
        .onChange(of: formatIndex) { _, value in UserDefaults.standard.set(value, forKey: "shield.exportFormat") }
        .onChange(of: qualityIndex) { _, value in UserDefaults.standard.set(value, forKey: "shield.exportQuality") }
    }
}

// MARK: - About, legal, support, and FAQ

enum SettingsArticleKind {
    case information
    case privacy
    case terms
    case subscriptionTerms

    var titleKey: String {
        switch self {
        case .information: "settings_information_disclaimer"
        case .privacy: "settings_privacy_policy"
        case .terms: "settings_terms_service"
        case .subscriptionTerms: "settings_subscription_terms"
        }
    }

    var introKey: String {
        switch self {
        case .information: "settings_info_intro"
        case .privacy: "settings_privacy_intro"
        case .terms: "settings_terms_intro"
        case .subscriptionTerms: "settings_subscription_intro"
        }
    }

    var sectionKeys: [(String, String)] {
        switch self {
        case .information:
            [
                ("settings_info_protection_title", "settings_info_protection_body"),
                ("settings_info_scope_title", "settings_info_scope_body"),
                ("settings_info_detection_title", "settings_info_detection_body"),
                ("settings_info_export_title", "settings_info_export_body"),
                ("settings_info_security_title", "settings_info_security_body"),
                ("settings_info_health_title", "settings_info_health_body"),
                ("settings_info_responsibility_title", "settings_info_responsibility_body")
            ]
        case .privacy:
            [
                ("settings_privacy_controller_title", "settings_privacy_controller_body"),
                ("settings_privacy_processing_title", "settings_privacy_processing_body"),
                ("settings_privacy_storage_title", "settings_privacy_storage_body"),
                ("settings_privacy_icloud_title", "settings_privacy_icloud_body"),
                ("settings_privacy_permissions_title", "settings_privacy_permissions_body"),
                ("settings_privacy_diagnostics_title", "settings_privacy_diagnostics_body"),
                ("settings_privacy_retention_title", "settings_privacy_retention_body"),
                ("settings_privacy_rights_title", "settings_privacy_rights_body"),
                ("settings_privacy_children_title", "settings_privacy_children_body"),
                ("settings_privacy_changes_title", "settings_privacy_changes_body")
            ]
        case .terms:
            [
                ("settings_terms_acceptance_title", "settings_terms_acceptance_body"),
                ("settings_terms_license_title", "settings_terms_license_body"),
                ("settings_terms_user_content_title", "settings_terms_user_content_body"),
                ("settings_terms_permitted_title", "settings_terms_permitted_body"),
                ("settings_terms_accuracy_title", "settings_terms_accuracy_body"),
                ("settings_terms_purchases_title", "settings_terms_purchases_body"),
                ("settings_terms_ip_title", "settings_terms_ip_body"),
                ("settings_terms_liability_title", "settings_terms_liability_body"),
                ("settings_terms_termination_title", "settings_terms_termination_body"),
                ("settings_terms_law_title", "settings_terms_law_body")
            ]
        case .subscriptionTerms:
            [
                ("settings_subscription_products_title", "settings_subscription_products_body"),
                ("settings_subscription_payment_title", "settings_subscription_payment_body"),
                ("settings_subscription_renewal_title", "settings_subscription_renewal_body"),
                ("settings_subscription_trial_title", "settings_subscription_trial_body"),
                ("settings_subscription_manage_title", "settings_subscription_manage_body"),
                ("settings_subscription_restore_title", "settings_subscription_restore_body"),
                ("settings_subscription_refunds_title", "settings_subscription_refunds_body"),
                ("settings_subscription_lifetime_title", "settings_subscription_lifetime_body"),
                ("settings_subscription_changes_title", "settings_subscription_changes_body")
            ]
        }
    }

    var publicPage: ShieldPublicPage {
        switch self {
        case .information: .overview
        case .privacy: .privacy
        case .terms: .terms
        case .subscriptionTerms: .subscriptions
        }
    }
}

struct SettingsArticleView: View {
    let article: SettingsArticleKind
    private var strings: LanguageManager { .shared }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings(article.titleKey),
            subtitle: strings.settings(article.introKey)
        ) {
            SettingsArticleCallout(
                icon: article == .privacy ? "hand.raised.fill" : "exclamationmark.shield.fill",
                title: strings.settings("settings_legal_updated_title"),
                bodyText: strings.settings("settings_legal_updated_value")
            )

            ShieldPublicPageButton(
                page: article.publicPage,
                language: LanguageManager.shared.current
            )

            if article == .privacy {
                AnalyticsConsentSettingsSection()
            }

            ForEach(article.sectionKeys, id: \.0) { titleKey, bodyKey in
                SettingsArticleSection(
                    title: strings.settings(titleKey),
                    bodyText: strings.settings(bodyKey)
                )
            }

            Text(strings.settings("settings_legal_draft_notice"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct AnalyticsConsentSettingsSection: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage(FirebaseIntegration.analyticsConsentKey) private var analyticsConsent = false

    private var strings: LanguageManager { .shared }

    var body: some View {
        SettingsCardSection(
            title: strings.settings("settings_privacy_analytics_section"),
            icon: "chart.bar.xaxis"
        ) {
            SettingsControlRow(
                icon: "chart.bar.fill",
                color: Color(hex: "5E5CE6"),
                title: strings.settings("settings_privacy_analytics_title"),
                subtitle: strings.settings("settings_privacy_analytics_body")
            ) {
                Toggle("", isOn: $analyticsConsent)
                    .labelsHidden()
                    .tint(ShieldTheme.accent(scheme))
                    .accessibilityLabel(strings.settings("settings_privacy_analytics_title"))
                    .accessibilityHint(strings.settings("settings_privacy_analytics_body"))
                    .accessibilityIdentifier("settings.privacy.analyticsConsent")
            }
        }
        .onChange(of: analyticsConsent) { _, granted in
            FirebaseIntegration.setAnalyticsConsent(granted)
        }
    }
}

struct AnalyticsConsentView: View {
    let onDecision: (Bool) -> Void

    @Environment(\.colorScheme) private var scheme

    private var strings: LanguageManager { .shared }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: ShieldTheme.s5) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(ShieldTheme.accent(scheme))
                        .frame(width: 64, height: 64)
                        .background(ShieldTheme.accentDim(scheme), in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: ShieldTheme.s2) {
                        Text(strings.settings("settings_privacy_analytics_consent_title"))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(ShieldTheme.primary(scheme))
                        Text(strings.settings("settings_privacy_analytics_consent_body"))
                            .font(.body)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    SettingsArticleCallout(
                        icon: "lock.fill",
                        title: strings.settings("settings_privacy_analytics_consent_note_title"),
                        bodyText: strings.settings("settings_privacy_analytics_consent_note_body")
                    )

                    VStack(spacing: ShieldTheme.s3) {
                        Button {
                            onDecision(true)
                        } label: {
                            Text(strings.settings("settings_privacy_analytics_allow"))
                                .font(.body.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 48)
                                .foregroundStyle(ShieldTheme.accentText)
                                .background(ShieldTheme.accent(scheme), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .accessibilityIdentifier("analytics.consent.allow")

                        Button {
                            onDecision(false)
                        } label: {
                            Text(strings.settings("settings_privacy_analytics_decline"))
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 48)
                                .foregroundStyle(ShieldTheme.primary(scheme))
                                .background(ShieldTheme.rowBackground(scheme), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .accessibilityIdentifier("analytics.consent.decline")
                    }
                }
                .padding(ShieldTheme.s5)
            }
            .background(ShieldTheme.background(scheme))
            .navigationTitle(strings.settings("settings_privacy_analytics_navigation_title"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }
}

struct SettingsArticleSection: View {
    let title: String
    let bodyText: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s2) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))
                .accessibilityAddTraits(.isHeader)
            Text(bodyText)
                .font(.body)
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ShieldTheme.s4)
        .shieldSettingsCard()
    }
}

struct SettingsArticleCallout: View {
    let icon: String
    let title: String
    let bodyText: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(alignment: .top, spacing: ShieldTheme.s3) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(ShieldTheme.accent(scheme))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ShieldTheme.primary(scheme))
                Text(bodyText)
                    .font(.subheadline)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ShieldTheme.s4)
        .background(ShieldTheme.accentDim(scheme))
        .overlay {
            RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 1)
        }
        .clipShape(.rect(cornerRadius: ShieldTheme.rMD))
    }
}

struct WhatsNewSettingsView: View {
    private var strings: LanguageManager { .shared }
    private let itemKeys = [
        "settings_whats_new_item_1", "settings_whats_new_item_2", "settings_whats_new_item_3",
        "settings_whats_new_item_4", "settings_whats_new_item_5", "settings_whats_new_item_6"
    ]

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_whats_new"),
            subtitle: strings.settings("settings_whats_new_intro")
        ) {
            SettingsCardSection(title: strings.settings("settings_version_value", appVersion), icon: "sparkles") {
                ForEach(Array(itemKeys.enumerated()), id: \.element) { index, key in
                    HStack(alignment: .top, spacing: ShieldTheme.s3) {
                        SettingsIconBadge(icon: "checkmark", color: Color(hex: "00C7BE"), size: 34)
                        Text(strings.settings(key))
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(ShieldTheme.s4)
                    if index < itemKeys.count - 1 { SettingsRowDivider(inset: 62) }
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
}

struct SupportSettingsView: View {
    let onSendFeedback: () -> Void
    let onRate: () -> Void
    private var strings: LanguageManager { .shared }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_support"),
            subtitle: strings.settings("settings_support_intro")
        ) {
            SettingsArticleCallout(
                icon: "lifepreserver.fill",
                title: strings.settings("settings_support_before_contact_title"),
                bodyText: strings.settings("settings_support_before_contact_body")
            )

            ShieldPublicPageButton(page: .support, language: LanguageManager.shared.current)

            SettingsCardSection(title: strings.settings("settings_support_actions"), icon: "bubble.left.and.bubble.right.fill") {
                SettingsActionRow(
                    icon: "envelope.fill",
                    color: Color(hex: "30D158"),
                    title: strings.settings("settings_send_feedback"),
                    subtitle: strings.settings("settings_send_feedback_subtitle"),
                    accessibilityIdentifier: "settings.action.sendFeedback",
                    action: onSendFeedback
                )
                SettingsRowDivider()
                SettingsNavigationRow(
                    route: .faq,
                    icon: "questionmark.circle.fill",
                    color: Color(hex: "FF9F0A"),
                    title: strings.settings("settings_faq"),
                    subtitle: strings.settings("settings_faq_subtitle")
                )
                SettingsRowDivider()
                SettingsActionRow(
                    icon: "star.fill",
                    color: Color(hex: "FFD60A"),
                    title: strings.settings("settings_rate_app"),
                    subtitle: strings.settings("settings_rate_app_subtitle"),
                    accessibilityIdentifier: "settings.action.rateApp",
                    action: onRate
                )
            }

            SettingsArticleSection(
                title: strings.settings("settings_support_response_title"),
                bodyText: strings.settings("settings_support_response_body")
            )
        }
    }
}

struct FAQSettingsView: View {
    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }
    private let keys = Array(1...8)

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_faq"),
            subtitle: strings.settings("settings_faq_intro")
        ) {
            ShieldPublicPageButton(page: .faq, language: LanguageManager.shared.current)

            VStack(spacing: 0) {
                ForEach(keys, id: \.self) { index in
                    DisclosureGroup {
                        Text(strings.settings("settings_faq_\(index)_answer"))
                            .font(.subheadline)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, ShieldTheme.s2)
                            .padding(.bottom, ShieldTheme.s3)
                    } label: {
                        Text(strings.settings("settings_faq_\(index)_question"))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(ShieldTheme.primary(scheme))
                            .multilineTextAlignment(.leading)
                    }
                    .tint(ShieldTheme.accent(scheme))
                    .padding(ShieldTheme.s4)

                    if index < keys.count { SettingsRowDivider(inset: ShieldTheme.s4) }
                }
            }
            .shieldSettingsCard()
        }
    }
}

#if DEBUG && targetEnvironment(simulator)
struct DeveloperSettingsView: View {
    @StateObject private var premium = PremiumManager.shared
    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_developer_tools"),
            subtitle: strings.settings("settings_developer_tools_subtitle")
        ) {
            SettingsCardSection(title: strings.settings("settings_developer"), icon: "hammer.fill") {
                SettingsControlRow(
                    icon: "sparkles",
                    color: ShieldTheme.accent(scheme),
                    title: strings.settings("settings_premium_override")
                ) {
                    Toggle("", isOn: Binding(
                        get: { premium.isDebugProOverride },
                        set: { premium.setDebugProOverride($0) }
                    ))
                    .labelsHidden()
                    .tint(ShieldTheme.accent(scheme))
                    .accessibilityLabel(strings.settings("settings_premium_override"))
                }
            }
        }
    }
}
#endif
