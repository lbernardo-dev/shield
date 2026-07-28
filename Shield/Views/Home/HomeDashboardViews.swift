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
                Image("MaskIDMark")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(.rect(cornerRadius: 9))
                    .accessibilityLabel(LanguageManager.shared.common("common_app_name"))

                VStack(alignment: .leading, spacing: 1) {
                    Text(LanguageManager.shared.common("common_app_name"))
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Text(workspaceTagline)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                smallChromeButton(title: language.displayName, action: onToggleLanguage)

                Button(action: onToggleScheme) {
                    Image(systemName: scheme == .dark ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 13, weight: .semibold))
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
                .font(.system(size: 11, weight: .bold))
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
        VStack(alignment: .leading, spacing: 16) {
            Text(heroTitle)
                .font(.title2.weight(.heavy))
                .foregroundColor(ShieldTheme.primary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            Text(heroSubtitle)
                .font(.subheadline.weight(.medium))
                .foregroundColor(ShieldTheme.secondary(scheme))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                planBadge
                localProcessingBadge
            }
            actionRow

            if !isPro {
                freePlanMeter
            }
        }
        .padding(18)
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
        Label(isPro ? "PRO" : LanguageManager.shared.home("home_free_plan"), systemImage: isPro ? "crown.fill" : "person.crop.circle")
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

    private var localProcessingBadge: some View {
        Label(LanguageManager.shared.home("home_processing_local"), systemImage: "lock.fill")
            .font(.caption.weight(.semibold))
            .foregroundColor(ShieldTheme.success)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 10)
            .frame(minHeight: 32)
            .background(ShieldTheme.successDim)
            .clipShape(Capsule())
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button(action: onPrimaryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 14, weight: .bold))
                    Text(LanguageManager.shared.capture("capture_scan_document"))
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ShieldTheme.accent)
                .foregroundColor(ShieldTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(ScaleButtonStyle())

            Button(action: onSecondaryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "icloud.and.arrow.down")
                        .font(.system(size: 14, weight: .bold))
                    Text(cloudImportTitle)
                        .font(.system(size: 15, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(ShieldTheme.cardBackground(scheme))
                .foregroundColor(ShieldTheme.primary(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
                )
                .clipShape(RoundedRectangle(cornerRadius: 15))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var cloudImportTitle: String {
        LanguageManager.shared.home("home_import_action")
    }

    private var freePlanMeter: some View {
        Button(action: onUpgrade) {
            VStack(alignment: .leading, spacing: 10) {
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
            .padding(14)
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
