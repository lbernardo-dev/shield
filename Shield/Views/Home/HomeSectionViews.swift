import SwiftUI

struct HomeModesSection: View {
    let scheme: ColorScheme
    let lang: AppLanguage
    let isPro: Bool
    let onShowBatch: () -> Void
    let onShowPaywall: () -> Void
    let onModeSelected: (RedactionMode) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(title: LanguageManager.shared.home("home_quick_modes"))
                Spacer()
                Button {
                    if isPro {
                        onShowBatch()
                    } else {
                        PremiumManager.recordFeatureGate(.batchProcessing, trigger: .settingsUpgrade)
                        onShowPaywall()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isPro ? "square.stack.3d.up.fill" : "lock.fill")
                            .shieldFont(11, weight: .semibold)
                        Text(LanguageManager.shared.home("home_batch_pro"))
                            .shieldFont(12, weight: .bold)
                    }
                    .foregroundColor(isPro ? ShieldTheme.accentText : ShieldTheme.tertiary(scheme))
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(isPro ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme))
                    .overlay(Capsule().stroke(isPro ? ShieldTheme.accentStroke(scheme) : ShieldTheme.line(scheme).opacity(0.5), lineWidth: isPro ? 1 : 0.5))
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.trailing, ShieldTheme.s5)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RedactionMode.allCases, id: \.self) { mode in
                        let locked = mode.requiresPro && !isPro
                        ModeCard(mode: mode, lang: lang, isLocked: locked) {
                            if locked {
                                PremiumManager.recordFeatureGate(.professionalModes, trigger: .settingsUpgrade)
                                onShowPaywall()
                            } else {
                                onModeSelected(mode)
                            }
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            .padding(.horizontal, ShieldTheme.s5)
        }
    }
}

struct HomePaginationControls: View {
    let scheme: ColorScheme
    let currentPage: Int
    let totalPages: Int
    let onPrevious: () -> Void
    let onNext: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .shieldFont(12, weight: .bold)
                    .foregroundColor(currentPage > 0 ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme).opacity(0.35))
                    .frame(width: 36, height: 32)
                    .background(ShieldTheme.cardBackground(scheme))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ShieldTheme.line(scheme), lineWidth: 0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .disabled(currentPage == 0)

            Spacer()

            Text("\(currentPage + 1) / \(totalPages)")
                .shieldFont(12, weight: .bold)
                .foregroundColor(ShieldTheme.secondary(scheme))

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .shieldFont(12, weight: .bold)
                    .foregroundColor(currentPage < totalPages - 1 ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme).opacity(0.35))
                    .frame(width: 36, height: 32)
                    .background(ShieldTheme.cardBackground(scheme))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ShieldTheme.line(scheme), lineWidth: 0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .disabled(currentPage >= totalPages - 1)
        }
    }
}

struct HomeVaultCard: View {
    let scheme: ColorScheme
    let onTap: () -> Void

    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    if isHalloween {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "F97316").opacity(0.2))
                            .frame(width: 44, height: 44)
                        Image(systemName: "lock.rectangle.stack.fill")
                            .shieldFont(20, weight: .semibold)
                            .foregroundColor(Color(hex: "FFA53D"))
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ShieldTheme.accentDim(scheme))
                            .frame(width: 44, height: 44)
                        Image(systemName: "lock.rectangle.stack.fill")
                            .shieldFont(20, weight: .semibold)
                            .foregroundColor(ShieldTheme.accent(scheme))
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(LanguageManager.shared.home("home_vault"))
                        .shieldFont(15, weight: .bold)
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Text(LanguageManager.shared.home("home_secure_storage_faceid"))
                        .shieldFont(12)
                        .foregroundColor(isHalloween ? Color(hex: "D8B4FE") : ShieldTheme.tertiary(scheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .shieldFont(12, weight: .medium)
                    .foregroundColor(isHalloween ? Color(hex: "FFA53D").opacity(0.8) : ShieldTheme.tertiary(scheme))
            }
            .padding(16)
            .background(
                isHalloween
                    ? Color(hex: "1C1026").opacity(0.85)
                    : ShieldTheme.cardBackground(scheme)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isHalloween
                            ? LinearGradient(colors: [Color(hex: "FF9A3D").opacity(0.4), Color(hex: "7C3AED").opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [ShieldTheme.line(scheme)], startPoint: .top, endPoint: .bottom),
                        lineWidth: isHalloween ? 1.0 : 0.8
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
