import SwiftUI

struct HomeTopBarView: View {
    let scheme: ColorScheme
    let language: AppLanguage
    let onToggleLanguage: () -> Void
    let onToggleScheme: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 9) {
                MaskIDIdentityMark(
                    size: 32,
                    presentation: .animatedLoop,
                    treatment: .compact
                )

                VStack(alignment: .leading, spacing: 1) {
                    Text(LanguageManager.shared.common("common_app_name"))
                        .shieldFont(16, weight: .heavy)
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Text(workspaceTagline)
                        .shieldFont(10, weight: .medium)
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                smallChromeButton(title: language.displayName, action: onToggleLanguage)

                Button(action: onToggleScheme) {
                    Image(systemName: scheme == .dark ? "sun.max.fill" : "moon.fill")
                        .shieldFont(13, weight: .semibold)
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .frame(width: 32, height: 32)
                        .background(ShieldTheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ShieldTheme.line(scheme), lineWidth: 0.5))
                }
                .buttonStyle(ScaleButtonStyle())
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel(LanguageManager.shared.settings("settings_dark_mode"))

                IconButton(
                    icon: "slider.horizontal.3",
                    accessibilityName: LanguageManager.shared.common("common_tab_settings"),
                    size: 32,
                    color: ShieldTheme.primary(scheme),
                    background: ShieldTheme.cardBackground(scheme),
                    action: onOpenSettings
                )
            }
        }
    }

    private var workspaceTagline: String {
        LanguageManager.shared.home("home_workspace_tagline")
    }

    private func smallChromeButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .shieldFont(11, weight: .bold)
                .foregroundColor(ShieldTheme.primary(scheme))
                .frame(width: 32, height: 32)
                .background(ShieldTheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(ShieldTheme.line(scheme), lineWidth: 0.5))
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(minWidth: 44, minHeight: 44)
    }
}

struct HomeHeroCardView: View {
    let scheme: ColorScheme
    let language: AppLanguage
    let isPro: Bool
    let freeUsed: Int
    let freeLimit: Int
    let onUpgrade: () -> Void
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void

    private var isAtFreeLimit: Bool {
        freeUsed >= freeLimit
    }

    private var usageFraction: Double {
        min(1.0, Double(freeUsed) / Double(max(freeLimit, 1)))
    }

    private var remainingDocuments: Int {
        max(0, freeLimit - freeUsed)
    }

    private var usageColor: Color {
        switch usageFraction {
        case ..<0.5: ShieldTheme.success
        case ..<0.8: ShieldTheme.warning
        default: ShieldTheme.danger
        }
    }

    private var usageState: String {
        if isAtFreeLimit {
            return LanguageManager.shared.home("home_plan_limit")
        }
        if usageFraction >= 0.5 {
            return LanguageManager.shared.home("home_plan_attention")
        }
        return LanguageManager.shared.home("home_plan_available")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(heroTitle)
                    .font(.title3.weight(.heavy))
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                planBadge
            }

            Text(heroSubtitle)
                .font(.subheadline)
                .foregroundColor(ShieldTheme.secondary(scheme))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            actionRow

            if !isPro {
                freePlanMeter
            }
        }
        .padding(16)
        .background(heroBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(ShieldTheme.line(scheme).opacity(0.7), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var heroTitle: String {
        LanguageManager.shared.home("home_hero_title")
    }

    private var heroSubtitle: String {
        LanguageManager.shared.home("home_hero_subtitle")
    }

    private var planBadge: some View {
        Label(isPro ? "PRO" : LanguageManager.shared.home("home_free_plan"), systemImage: isPro ? "sparkles" : "person.crop.circle")
            .font(.caption.weight(.bold))
            .foregroundColor(isPro ? ShieldTheme.accentText : ShieldTheme.primary(scheme))
            .padding(.horizontal, 10)
            .frame(minHeight: 32)
            .background(isPro ? ShieldTheme.accent(scheme) : ShieldTheme.cardBackground(scheme))
            .overlay(
                Capsule().stroke(isPro ? ShieldTheme.accentStroke(scheme) : ShieldTheme.line(scheme), lineWidth: 0.8)
            )
            .clipShape(Capsule())
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            ShieldButton(
                label: LanguageManager.shared.home("home_scan_action"),
                icon: "camera.viewfinder",
                action: onPrimaryAction
            )

            ShieldButton(
                label: cloudImportTitle,
                icon: "square.and.arrow.down",
                style: .secondary,
                action: onSecondaryAction
            )
        }
    }

    private var cloudImportTitle: String {
        LanguageManager.shared.home("home_import_action")
    }

    private var freePlanMeter: some View {
        Button(action: onUpgrade) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(usageState)
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(usageColor)
                        Text(LanguageManager.shared.home("home_plan_remaining", remainingDocuments))
                            .font(.caption)
                            .foregroundColor(ShieldTheme.secondary(scheme))
                    }

                    Spacer()

                    Text(LanguageManager.shared.home("home_upgrade"))
                        .font(.caption.weight(.bold))
                        .foregroundColor(usageColor)
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(ShieldTheme.rowBackground(scheme))
                            .frame(height: 8)
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [usageColor.opacity(0.65), usageColor],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: proxy.size.width * usageFraction, height: 8)
                    }
                }
                .frame(height: 8)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ShieldTheme.cardBackground(scheme).opacity(0.85))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var heroBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ShieldTheme.cardBackground(scheme),
                    ShieldTheme.rowBackground(scheme),
                    ShieldTheme.cardBackground(scheme)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    ShieldTheme.accent(scheme).opacity(scheme == .dark ? 0.22 : 0.18),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 220
            )
        }
    }

}
