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
    let language: AppLanguage
    let isPro: Bool
    let freeUsed: Int
    let freeLimit: Int
    let onUpgrade: () -> Void
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void
    let onLearnMore: () -> Void

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
        VStack(alignment: .leading, spacing: 0) {
            Text(heroTitle)
                .shieldFont(36, weight: .heavy)
                .foregroundColor(ShieldTheme.primary(scheme))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 6)

            Text(heroSubtitle)
                .shieldFont(20, weight: .medium)
                .foregroundColor(ShieldTheme.secondary(scheme))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 24)

            VStack(spacing: 12) {
                HeroActionButton(
                    label: LanguageManager.shared.home("home_scan_action"),
                    icon: "camera.viewfinder",
                    style: .primary,
                    action: onPrimaryAction
                )

                HeroActionButton(
                    label: cloudImportTitle,
                    icon: "square.and.arrow.up",
                    style: .secondary,
                    action: onSecondaryAction
                )
            }

            HomeProcessingCard(
                scheme: scheme,
                onLearnMore: onLearnMore
            )
            .padding(.top, 18)

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

                if remainingDocuments <= 2 && remainingDocuments > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .shieldFont(12)
                            .foregroundColor(ShieldTheme.warning)
                        Text(LanguageManager.shared.home("home_quota_warning_title"))
                            .font(.caption.weight(.bold))
                            .foregroundColor(ShieldTheme.primary(scheme))
                    }
                    .padding(.top, 2)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(ShieldTheme.cardBackground(scheme).opacity(0.85))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }

}

private struct HeroActionButton: View {
    enum Style { case primary, secondary }

    let label: String
    let icon: String
    let style: Style
    let action: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 25, weight: .semibold))
                    .frame(width: 34, height: 34)

                Text(label)
                    .shieldFont(19, weight: .semibold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .accessibilityHidden(true)
            }
            .foregroundColor(style == .primary ? ShieldTheme.accentText : ShieldTheme.primary(scheme))
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(style == .primary ? ShieldTheme.accent(scheme) : ShieldTheme.cardBackground(scheme))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        style == .primary ? Color.clear : ShieldTheme.line(scheme),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(label)
        .accessibilityIdentifier(style == .primary ? "home.scan" : "home.import")
    }
}

private struct HomeProcessingCard: View {
    let scheme: ColorScheme
    let onLearnMore: () -> Void

    var body: some View {
        Button(action: onLearnMore) {
            HStack(alignment: .center, spacing: 16) {
                MaskIDIdentityMark(
                    size: 72,
                    presentation: .staticMark,
                    treatment: .feature
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(LanguageManager.shared.home("home_processing_local_title"))
                        .shieldFont(17, weight: .bold)
                        .foregroundColor(ShieldTheme.primary(scheme))

                    Text(LanguageManager.shared.home("home_processing_local_body"))
                        .shieldFont(14)
                        .foregroundColor(ShieldTheme.secondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Text(LanguageManager.shared.home("home_processing_local_learn_more"))
                            .shieldFont(14, weight: .semibold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(ShieldTheme.accentColor(scheme))
                }

                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ShieldTheme.selectedBackground(scheme))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(ShieldTheme.accentStroke(scheme).opacity(0.4), lineWidth: 0.8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
            HStack(spacing: 16) {
                thumbnail

                VStack(alignment: .leading, spacing: 6) {
                    Text(shouldMask
                         ? LanguageManager.shared.home("home_protected_document")
                         : doc.title)
                        .shieldFont(17, weight: .bold)
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
                            .shieldFont(13, weight: .semibold)
                    }
                    .foregroundColor(ShieldTheme.warning)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(ShieldTheme.warningBackground(appState.preferredScheme), in: Capsule())
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                    .accessibilityHidden(true)
            }
            .padding(16)
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
                    .frame(width: 116, height: 82)
                    .blur(radius: shouldMask ? 5 : 0)
            } else {
                DocumentView(
                    kind: doc.kind,
                    size: CGSize(width: 116, height: 82),
                    fields: doc.fields,
                    redactions: doc.redactions(for: 0),
                    watermark: doc.watermark,
                    imageFileName: doc.imageFileName,
                    isVaulted: doc.isVaulted,
                    imageAdjustment: doc.imageAdjustment
                )
                .frame(width: 116, height: 82)
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
        .frame(width: 116, height: 82)
        .background(ShieldTheme.rowBackground(appState.preferredScheme), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityHidden(true)
    }
}
