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
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(ShieldTheme.accentColor(scheme))
                        .frame(width: 30, height: 30)
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(scheme == .dark ? ShieldTheme.accentText : ShieldTheme.accent)
                        .accessibilityLabel(LanguageManager.shared.common("common_app_name"))
                }

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
                        .background(ShieldTheme.cardBackground(scheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ShieldTheme.line(scheme), lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
        language == .es ? "Privado en el dispositivo" : "Private on-device"
    }

    private func smallChromeButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ShieldTheme.primary(scheme))
                .frame(width: 32, height: 32)
                .background(ShieldTheme.cardBackground(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(ShieldTheme.line(scheme), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(minWidth: 44, minHeight: 44)
    }
}

struct HomeHeroCardView: View {
    let scheme: ColorScheme
    let language: AppLanguage
    let documentCount: Int
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

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(heroTitle)
                        .font(.system(size: 21, weight: .heavy))
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(heroSubtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ShieldTheme.secondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                statusBadge
            }

            quickStatsRow
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
        language == .es
            ? "Protege antes de compartir."
            : "Protect before sharing."
    }

    private var heroSubtitle: String {
        language == .es
            ? "Escanea o importa y oculta datos sensibles sin sacar el archivo del dispositivo."
            : "Scan or import and hide sensitive data without sending the file off-device."
    }

    private var summaryLine: String {
        language == .es
            ? "\(documentCount) documentos protegibles"
            : "\(documentCount) protected-ready documents"
    }

    private var statusBadge: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(isPro ? "PRO" : "FREE")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(isPro ? ShieldTheme.accentText : ShieldTheme.primary(scheme))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isPro ? ShieldTheme.accent : ShieldTheme.cardBackground(scheme))
                .clipShape(Capsule())

            Label(LanguageManager.shared.home("home_on_device"), systemImage: "lock.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(ShieldTheme.success)
        }
        .padding(10)
        .background(ShieldTheme.cardBackground(scheme).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var quickStatsRow: some View {
        VStack(spacing: 8) {
            statPill(
                icon: "doc.text.fill",
                text: summaryLine,
                tint: ShieldTheme.primary(scheme)
            )
            statPill(
                icon: "lock.shield.fill",
                text: LanguageManager.shared.home("home_no_servers"),
                tint: ShieldTheme.success
            )
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button(action: onPrimaryAction) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 14, weight: .bold))
                    Text(LanguageManager.shared.capture("capture_scan_document"))
                        .font(.system(size: 15, weight: .bold))
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
                        .minimumScaleFactor(0.85)
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
        language == .es ? "Importar" : "Import"
    }

    private var freePlanMeter: some View {
        Button(action: onUpgrade) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(LanguageManager.shared.home("home_plan_status", LanguageManager.shared.home("home_free_plan"), freeUsed, freeLimit))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isAtFreeLimit ? ShieldTheme.danger : ShieldTheme.secondary(scheme))

                    Spacer()

                    Text(LanguageManager.shared.home("home_upgrade"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isAtFreeLimit ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(ShieldTheme.rowBackground(scheme))
                            .frame(height: 6)
                        Capsule()
                            .fill(isAtFreeLimit ? ShieldTheme.danger : ShieldTheme.accent(scheme))
                            .frame(width: proxy.size.width * usageFraction, height: 6)
                    }
                }
                .frame(height: 6)
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

    private func statPill(icon: String, text: String, tint: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(tint)
                .accessibilityHidden(true)

            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ShieldTheme.secondary(scheme))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ShieldTheme.cardBackground(scheme).opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .accessibilityElement(children: .combine)
    }
}
