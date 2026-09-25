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
                    size: 42,
                    presentation: .staticMark,
                    treatment: .compact
                )

                Text(LanguageManager.shared.common("common_app_name"))
                    .shieldFont(22, weight: .heavy)
                    .foregroundColor(ShieldTheme.primary(scheme))
            }

            Spacer()

            Menu {
                Button(action: onToggleLanguage) {
                    Label(LanguageManager.shared.settings("settings_language"), systemImage: "character.book.closed")
                }

                Button(action: onToggleScheme) {
                    Label(LanguageManager.shared.settings("settings_dark_mode"), systemImage: scheme == .dark ? "sun.max.fill" : "moon.fill")
                }

                Button(action: onOpenSettings) {
                    Label(LanguageManager.shared.common("common_tab_settings"), systemImage: "gearshape")
                }
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .frame(width: 44, height: 44)
                    .background(ShieldTheme.rowBackground(scheme), in: Circle())
                    .contentShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(LanguageManager.shared.common("common_tab_settings"))
            .accessibilityHint(LanguageManager.shared.home("home_account_menu_hint"))
        }
    }
}

struct HomeHeroCardView: View {
    let scheme: ColorScheme
    let isPro: Bool
    let freeUsed: Int
    let freeLimit: Int
    let onUpgrade: () -> Void
    let onLearnMore: () -> Void

    private var isAtFreeLimit: Bool {
        freeUsed >= freeLimit
    }

    private var usageFraction: Double {
        min(1.0, Double(freeUsed) / Double(max(freeLimit, 1)))
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
        VStack(alignment: .leading, spacing: 0) {
            Text(heroTitle)
                .shieldFont(32, weight: .heavy)
                .foregroundColor(ShieldTheme.primary(scheme))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 6)

            Text(heroSubtitle)
                .shieldFont(18, weight: .medium)
                .foregroundColor(ShieldTheme.secondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 12)

            HomeProcessingCard(scheme: scheme, onLearnMore: onLearnMore)

            if !isPro {
                freePlanMeter
                    .padding(.top, 12)
            }
        }
    }

    private var heroTitle: String {
        LanguageManager.shared.home("home_hero_title")
    }

    private var heroSubtitle: String {
        LanguageManager.shared.home("home_hero_subtitle")
    }

    private var freePlanMeter: some View {
        Button(action: onUpgrade) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(LanguageManager.shared.home("home_plan_status", usageState, freeUsed, freeLimit))
                        .shieldFont(14, weight: .bold)
                        .foregroundColor(usageColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(ShieldTheme.rowBackground(scheme))
                                .frame(height: 6)
                            Capsule()
                                .fill(usageColor)
                                .frame(width: proxy.size.width * usageFraction, height: 6)
                        }
                    }
                    .frame(height: 6)
                }

                Spacer(minLength: 4)

                HStack(spacing: 4) {
                    Text(LanguageManager.shared.home("home_upgrade"))
                        .shieldFont(13, weight: .bold)
                }
                .foregroundColor(usageColor)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ShieldTheme.cardBackground(scheme).opacity(0.9))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

}

private struct HomeProcessingCard: View {
    let scheme: ColorScheme
    let onLearnMore: () -> Void

    var body: some View {
        Button(action: onLearnMore) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(ShieldTheme.accentDim(scheme))
                    Image(systemName: "lock.shield.fill")
                        .shieldFont(24, weight: .semibold)
                        .foregroundColor(ShieldTheme.accentColor(scheme))
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 5) {
                    Text(LanguageManager.shared.home("home_processing_local_title"))
                        .shieldFont(16, weight: .bold)
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .lineLimit(2)

                    Text(LanguageManager.shared.home("home_processing_local_body"))
                        .shieldFont(13)
                        .foregroundColor(ShieldTheme.secondary(scheme))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Text(LanguageManager.shared.home("home_processing_local_learn_more"))
                            .shieldFont(13, weight: .semibold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(ShieldTheme.accentColor(scheme))
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ShieldTheme.selectedBackground(scheme))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(ShieldTheme.accentStroke(scheme).opacity(0.4), lineWidth: 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(LanguageManager.shared.home("home_processing_local_title"))
        .accessibilityHint(LanguageManager.shared.home("home_processing_local_body"))
        .accessibilityIdentifier("home.onDeviceInfo")
    }
}

struct HomeRecentDocumentCard: View {
    let doc: DocumentItem
    let lang: AppLanguage
    let action: () -> Void

    @EnvironmentObject private var appState: AppState

    private var shouldMask: Bool {
        doc.isVaulted
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                thumbnail

                VStack(alignment: .leading, spacing: 4) {
                    Text(shouldMask
                         ? LanguageManager.shared.home("home_protected_document")
                         : doc.title)
                        .shieldFont(16, weight: .bold)
                        .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    Text(doc.compactDateLabel(lang: lang))
                        .shieldFont(14)
                        .foregroundColor(ShieldTheme.secondary(appState.preferredScheme))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 13, weight: .semibold))
                        Text(LanguageManager.shared.home("home_review_pending"))
                            .shieldFont(12, weight: .semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    .foregroundColor(ShieldTheme.warning)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(ShieldTheme.warningBackground(appState.preferredScheme), in: Capsule())
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                    .accessibilityHidden(true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ShieldTheme.cardBackground(appState.preferredScheme))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(ShieldTheme.line(appState.preferredScheme), lineWidth: 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(doc.isLocked)
        .opacity(doc.isLocked ? 0.7 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(shouldMask
                            ? LanguageManager.shared.home("home_protected_document")
                            : doc.title)
        .accessibilityValue(LanguageManager.shared.home("home_review_pending"))
        .accessibilityHint(doc.isVaulted
                           ? LanguageManager.shared.vault("vault_unlock_faceid")
                           : "")
    }

    private var thumbnail: some View {
        ZStack {
            if doc.kind == .photo {
                DocumentThumbnailView(doc: doc, maxPixelSize: 300, contentMode: .fill)
                    .frame(width: 104, height: 74)
                    .blur(radius: shouldMask ? 5 : 0)
            } else {
                DocumentView(
                    kind: doc.kind,
                    size: CGSize(width: 104, height: 74),
                    fields: doc.fields,
                    redactions: doc.redactions(for: 0),
                    watermark: doc.watermark,
                    imageFileName: doc.imageFileName,
                    isVaulted: doc.isVaulted,
                    imageAdjustment: doc.imageAdjustment
                )
                    .frame(width: 104, height: 74)
                .blur(radius: shouldMask ? 5 : 0)
            }

            if doc.isLocked || shouldMask {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.38))
                Image(systemName: "lock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 104, height: 74)
        .background(ShieldTheme.rowBackground(appState.preferredScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }
}
