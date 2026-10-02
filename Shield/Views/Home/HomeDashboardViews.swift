import SwiftUI

struct HomeTopBarView: View {
    let scheme: ColorScheme
    let language: AppLanguage
    let onToggleLanguage: () -> Void
    let onToggleScheme: () -> Void
    let onOpenSettings: () -> Void
    let isManagedTheme: Bool

    @EnvironmentObject private var appState: AppState
    @ObservedObject private var profileManager = UserProfileManager.shared
    @State private var showProfileSheet = false

    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
    }

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 9) {
                MaskIDIdentityMark(
                    size: 42,
                    presentation: .staticMark,
                    treatment: .compact
                )

                HStack(spacing: 6) {
                    Text(LanguageManager.shared.common("common_app_name"))
                        .shieldFont(22, weight: .heavy)
                        .foregroundColor(ShieldTheme.primary(scheme))
                    if isHalloween {
                        Text("🎃")
                            .font(.system(size: 16))
                    }
                }
            }

            Spacer()

            Button {
                showProfileSheet = true
            } label: {
                Group {
                    if let avatar = profileManager.avatarImage {
                        Image(uiImage: avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(
                                    isHalloween ? Color(hex: "F97316") : ShieldTheme.accent(scheme),
                                    lineWidth: 2
                                )
                            )
                    } else if !profileManager.profile.initials.isEmpty && profileManager.profile.hasData {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isHalloween
                                        ? [Color(hex: "4A2657"), Color(hex: "231433")]
                                        : [ShieldTheme.accent(scheme), Color(hex: "0077B6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(profileManager.profile.initials)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle().stroke(
                                    isHalloween ? Color(hex: "F97316").opacity(0.6) : Color.clear,
                                    lineWidth: 1.5
                                )
                            )
                    } else {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(isHalloween ? Color(hex: "FFD6A0") : ShieldTheme.primary(scheme))
                            .frame(width: 44, height: 44)
                            .background(
                                isHalloween
                                    ? Color(hex: "231433").opacity(0.85)
                                    : ShieldTheme.rowBackground(scheme),
                                in: Circle()
                            )
                            .overlay(
                                Circle().stroke(
                                    isHalloween
                                        ? Color(hex: "F97316").opacity(0.5)
                                        : Color.clear,
                                    lineWidth: 1
                                )
                            )
                    }
                }
                .contentShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(LanguageManager.shared.settings("settings_profile_title"))
            .accessibilityHint(LanguageManager.shared.home("home_account_menu_hint"))
            .contextMenu {
                Button(action: { showProfileSheet = true }) {
                    Label(LanguageManager.shared.settings("settings_profile_title"), systemImage: "person.crop.circle")
                }

                Button(action: onToggleLanguage) {
                    Label(LanguageManager.shared.settings("settings_language"), systemImage: "character.book.closed")
                }

                Button(action: onToggleScheme) {
                    Label(LanguageManager.shared.settings("settings_dark_mode"), systemImage: scheme == .dark ? "sun.max.fill" : "moon.fill")
                }
                .disabled(isManagedTheme)

                Button(action: onOpenSettings) {
                    Label(LanguageManager.shared.common("common_tab_settings"), systemImage: "gearshape")
                }
            }
            .sheet(isPresented: $showProfileSheet) {
                UserProfileView()
                    .environmentObject(appState)
            }
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

    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
    }

    private var isAtFreeLimit: Bool {
        freeUsed >= freeLimit
    }

    private var usageFraction: Double {
        min(1.0, Double(freeUsed) / Double(max(freeLimit, 1)))
    }

    private var usageColor: Color {
        if isHalloween {
            return Color(hex: "FFA53D")
        }
        switch usageFraction {
        case ..<0.5: return ShieldTheme.success
        case ..<0.8: return ShieldTheme.warning
        default: return ShieldTheme.danger
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
            HStack(spacing: 8) {
                Text(heroTitle)
                    .shieldFont(32, weight: .heavy)
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
                if isHalloween {
                    Text("🦇")
                        .font(.system(size: 22))
                }
            }
            .padding(.bottom, 6)

            Text(heroSubtitle)
                .shieldFont(18, weight: .medium)
                .foregroundColor(isHalloween ? Color(hex: "D8B4FE") : ShieldTheme.secondary(scheme))
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
                                .fill(
                                    isHalloween
                                        ? Color(hex: "341846").opacity(0.8)
                                        : ShieldTheme.rowBackground(scheme)
                                )
                                .frame(height: 6)
                            Capsule()
                                .fill(
                                    isHalloween
                                        ? LinearGradient(colors: [Color(hex: "FFA53D"), Color(hex: "F97316")], startPoint: .leading, endPoint: .trailing)
                                        : LinearGradient(colors: [usageColor, usageColor], startPoint: .leading, endPoint: .trailing)
                                )
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
                isHalloween
                    ? Color(hex: "1C1026").opacity(0.85)
                    : ShieldTheme.cardBackground(scheme).opacity(0.9)
            )
            .overlay {
                if isHalloween {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "FF9A3D").opacity(0.45), Color(hex: "7C3AED").opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }

}

private struct HomeProcessingCard: View {
    let scheme: ColorScheme
    let onLearnMore: () -> Void

    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
    }

    var body: some View {
        Button(action: onLearnMore) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    if isHalloween {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "F97316").opacity(0.28), Color(hex: "7C3AED").opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Circle()
                            .stroke(Color(hex: "FF9A3D").opacity(0.5), lineWidth: 1)
                        Image(systemName: "lock.shield.fill")
                            .shieldFont(24, weight: .semibold)
                            .foregroundColor(Color(hex: "FFA53D"))
                    } else {
                        Circle()
                            .fill(ShieldTheme.accentDim(scheme))
                        Image(systemName: "lock.shield.fill")
                            .shieldFont(24, weight: .semibold)
                            .foregroundColor(ShieldTheme.accentColor(scheme))
                    }
                }
                .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 5) {
                    Text(LanguageManager.shared.home("home_processing_local_title"))
                        .shieldFont(16, weight: .bold)
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .lineLimit(2)

                    Text(LanguageManager.shared.home("home_processing_local_body"))
                        .shieldFont(13)
                        .foregroundColor(isHalloween ? Color(hex: "D8B4FE") : ShieldTheme.secondary(scheme))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 4) {
                        Text(LanguageManager.shared.home("home_processing_local_learn_more"))
                            .shieldFont(13, weight: .semibold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.accentColor(scheme))
                }

                Spacer(minLength: 0)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHalloween
                    ? Color(hex: "1F112B").opacity(0.85)
                    : ShieldTheme.selectedBackground(scheme)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isHalloween
                            ? LinearGradient(
                                colors: [Color(hex: "FF9A3D").opacity(0.55), Color(hex: "7C3AED").opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [ShieldTheme.accentStroke(scheme).opacity(0.4)], startPoint: .top, endPoint: .bottom),
                        lineWidth: isHalloween ? 1.0 : 0.8
                    )
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
    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && appState.preferredScheme == .dark
    }

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
                        .foregroundColor(isHalloween ? Color(hex: "D8B4FE") : ShieldTheme.secondary(appState.preferredScheme))
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 13, weight: .semibold))
                        Text(LanguageManager.shared.home("home_review_pending"))
                            .shieldFont(12, weight: .semibold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                    }
                    .foregroundColor(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.warning)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(
                        isHalloween
                            ? Color(hex: "F97316").opacity(0.18)
                            : ShieldTheme.warningBackground(appState.preferredScheme),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule().stroke(
                            isHalloween ? Color(hex: "FFA53D").opacity(0.4) : Color.clear,
                            lineWidth: 0.8
                        )
                    )
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isHalloween ? Color(hex: "FF9A3D").opacity(0.8) : ShieldTheme.tertiary(appState.preferredScheme))
                    .accessibilityHidden(true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isHalloween
                    ? Color(hex: "1C1026").opacity(0.85)
                    : ShieldTheme.cardBackground(appState.preferredScheme)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isHalloween
                            ? LinearGradient(
                                colors: [Color(hex: "FF9A3D").opacity(0.55), Color(hex: "7C3AED").opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [ShieldTheme.line(appState.preferredScheme)], startPoint: .top, endPoint: .bottom),
                        lineWidth: isHalloween ? 1.0 : 0.8
                    )
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
