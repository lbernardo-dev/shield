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
                    isPro ? onShowBatch() : onShowPaywall()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isPro ? "square.stack.3d.up.fill" : "lock.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(LanguageManager.shared.home("home_batch_pro"))
                            .font(.system(size: 12, weight: .bold))
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
                        ModeCard(mode: mode, lang: lang) {
                            onModeSelected(mode)
                        }
                    }
                }
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.bottom, 4)
            }
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(currentPage > 0 ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
                    .frame(width: 32, height: 32)
                    .background(ShieldTheme.cardBackground(scheme))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ShieldTheme.line(scheme), lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(currentPage == 0)

            Spacer()

            Text("\(currentPage + 1) / \(totalPages)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(ShieldTheme.secondary(scheme))

            Spacer()

            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(currentPage < totalPages - 1 ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
                    .frame(width: 32, height: 32)
                    .background(ShieldTheme.cardBackground(scheme))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(ShieldTheme.line(scheme), lineWidth: 0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(currentPage >= totalPages - 1)
        }
    }
}

struct HomeVaultCard: View {
    let scheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ShieldTheme.accentDim(scheme))
                        .frame(width: 44, height: 44)
                    Image(systemName: "lock.rectangle.stack.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(ShieldTheme.accent(scheme))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(LanguageManager.shared.home("home_vault"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Text(LanguageManager.shared.home("home_secure_storage_faceid"))
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }
            .padding(16)
            .background(ShieldTheme.cardBackground(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ShieldTheme.line(scheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
