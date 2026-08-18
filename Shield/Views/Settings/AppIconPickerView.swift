import SwiftUI
import UIKit

// MARK: - AppIconPickerSection

/// Section embedded into App Preferences to display and customize app icons with Icon Composer support.
struct AppIconPickerSection: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var scheme
    @StateObject private var premium = PremiumManager.shared

    @State private var previewingIcon: AppIconOption? = nil
    @State private var showPaywall = false
    @State private var errorMessage: String? = nil
    @State private var isChangingIcon = false

    private var strings: LanguageManager { .shared }

    private let columns = [
        GridItem(.flexible(), spacing: ShieldTheme.s3),
        GridItem(.flexible(), spacing: ShieldTheme.s3),
        GridItem(.flexible(), spacing: ShieldTheme.s3)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            LazyVGrid(columns: columns, spacing: ShieldTheme.s3) {
                ForEach(AppIconOption.allCases) { icon in
                    AppIconCard(
                        icon: icon,
                        isSelected: appState.currentAppIcon == icon,
                        isProUser: premium.isPro,
                        onSelect: { selectIcon(icon) }
                    )
                }
            }
            .padding(.vertical, ShieldTheme.s2)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(ShieldTheme.danger)
                    .padding(.top, 4)
            }
        }
        .sheet(item: $previewingIcon) { icon in
            AppIconPreviewSheet(
                icon: icon,
                onUnlockPro: {
                    previewingIcon = nil
                    showPaywall = true
                }
            )
            .environmentObject(appState)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: .settingsUpgrade)
                .environmentObject(appState)
        }
    }

    private func selectIcon(_ icon: AppIconOption) {
        if icon.isPro && !premium.isPro {
            // Free user trying to select a Pro icon -> Open rich preview modal
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            previewingIcon = icon
            return
        }

        guard appState.currentAppIcon != icon else { return }

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isChangingIcon = true
        errorMessage = nil

        Task { @MainActor in
            do {
                try await appState.setAppIcon(icon, isPro: premium.isPro)
            } catch {
                errorMessage = error.localizedDescription
            }
            isChangingIcon = false
        }
    }
}

// MARK: - AppIconCard

struct AppIconCard: View {
    let icon: AppIconOption
    let isSelected: Bool
    let isProUser: Bool
    let onSelect: () -> Void

    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    // Icon preview container
                    iconVisual
                        .frame(width: 64, height: 64)
                        .clipShape(.rect(cornerRadius: 15, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(
                                    isSelected
                                        ? icon.accentColor
                                        : ShieldTheme.line(scheme).opacity(0.8),
                                    lineWidth: isSelected ? 2.5 : 1
                                )
                        }
                        .shadow(
                            color: isSelected ? icon.accentColor.opacity(0.35) : Color.black.opacity(0.12),
                            radius: isSelected ? 8 : 4,
                            y: isSelected ? 4 : 2
                        )

                    // Pro Badge or Checkmark Badge
                    if isSelected {
                        ZStack {
                            Circle()
                                .fill(icon.accentColor)
                                .frame(width: 22, height: 22)
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(Color.white)
                        }
                        .offset(x: 6, y: -6)
                    } else if icon.isPro && !isProUser {
                        ZStack {
                            Capsule()
                                .fill(Color.black.opacity(0.82))
                                .overlay {
                                    Capsule()
                                        .stroke(Color(hex: "FFD60A").opacity(0.6), lineWidth: 0.8)
                                }
                            HStack(spacing: 2) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color(hex: "FFD60A"))
                            }
                        }
                        .frame(width: 20, height: 20)
                        .offset(x: 5, y: -5)
                    }
                }
                .padding(.top, 4)

                // Label
                Text(icon.localizedName(language: strings.currentLanguage))
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? ShieldTheme.primary(scheme) : ShieldTheme.secondary(scheme))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if isSelected {
                    Text(strings.settings("settings_app_icon_active"))
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(icon.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(icon.accentColor.opacity(0.15), in: Capsule())
                } else if icon.isPro {
                    Text("PRO")
                        .font(.system(size: 9, weight: .heavy))
                        .foregroundStyle(Color(hex: "FFB800"))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: "FFB800").opacity(0.15), in: Capsule())
                } else {
                    Text(strings.settings("settings_app_icon_default"))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(ShieldTheme.tertiary(scheme))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, ShieldTheme.s2)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous)
                    .fill(isSelected ? icon.accentColor.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("settings.icon.\(icon.rawValue)")
        .accessibilityLabel(icon.localizedName(language: strings.currentLanguage))
        .accessibilityValue(isSelected ? strings.settings("settings_app_icon_active") : (icon.isPro ? "PRO" : ""))
    }

    @ViewBuilder
    private var iconVisual: some View {
        if let uiImage = icon.uiImage {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            // Fallback generated asset preview
            ZStack {
                LinearGradient(
                    colors: icon.haloColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "shield.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

// MARK: - AppIconPreviewSheet

/// Preview modal presented to free users to inspect an exclusive Icon Composer icon in full detail.
struct AppIconPreviewSheet: View {
    let icon: AppIconOption
    let onUnlockPro: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        NavigationStack {
            ZStack {
                ShieldTheme.pageBackground(scheme).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: ShieldTheme.s5) {
                        // Ambient Header Lighting
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            icon.accentColor.opacity(scheme == .dark ? 0.35 : 0.22),
                                            icon.accentColor.opacity(0.08),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 130
                                    )
                                )
                                .frame(width: 240, height: 240)

                            if let uiImage = icon.uiImage {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 110, height: 110)
                                    .clipShape(.rect(cornerRadius: 26, style: .continuous))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                                            .stroke(icon.accentColor.opacity(0.6), lineWidth: 2)
                                    }
                                    .shadow(color: icon.accentColor.opacity(0.45), radius: 18, y: 8)
                            }
                        }
                        .padding(.top, ShieldTheme.s4)

                        // Title & Subtitle
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                Text(icon.localizedName(language: strings.currentLanguage))
                                    .shieldFont(24, weight: .heavy, design: .rounded)
                                    .foregroundStyle(ShieldTheme.primary(scheme))

                                Text("PRO")
                                    .font(.caption2.weight(.heavy))
                                    .foregroundStyle(Color.black)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: "FFD60A"), in: Capsule())
                            }

                            Text(icon.localizedSubtitle(language: strings.currentLanguage))
                                .font(.subheadline)
                                .foregroundStyle(ShieldTheme.secondary(scheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, ShieldTheme.s4)
                        }

                        // Feature Highlights Card
                        VStack(alignment: .leading, spacing: ShieldTheme.s4) {
                            featureRow(
                                icon: "sparkles",
                                color: icon.accentColor,
                                title: strings.settings("settings_app_icon_benefit_composer_title"),
                                subtitle: strings.settings("settings_app_icon_benefit_composer_desc")
                            )
                            Divider().overlay(ShieldTheme.line(scheme))
                            featureRow(
                                icon: "applewatch",
                                color: Color(hex: "00C7BE"),
                                title: strings.settings("settings_app_icon_benefit_watch_title"),
                                subtitle: strings.settings("settings_app_icon_benefit_watch_desc")
                            )
                            Divider().overlay(ShieldTheme.line(scheme))
                            featureRow(
                                icon: "paintbrush.fill",
                                color: Color(hex: "BF5AF2"),
                                title: strings.settings("settings_app_icon_benefit_sync_title"),
                                subtitle: strings.settings("settings_app_icon_benefit_sync_desc")
                            )
                        }
                        .padding(ShieldTheme.s4)
                        .background(ShieldTheme.cardBackground(scheme))
                        .overlay {
                            RoundedRectangle(cornerRadius: ShieldTheme.rLG, style: .continuous)
                                .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
                        }
                        .clipShape(.rect(cornerRadius: ShieldTheme.rLG, style: .continuous))
                        .padding(.horizontal, ShieldTheme.s4)

                        // Unlock CTA
                        Button(action: onUnlockPro) {
                            HStack(spacing: ShieldTheme.s2) {
                                Image(systemName: "sparkles")
                                    .font(.body.weight(.bold))
                                Text(strings.settings("settings_app_icon_unlock_pro"))
                                    .font(.headline.weight(.bold))
                            }
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FFD60A"), Color(hex: "FF9F0A")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(.rect(cornerRadius: ShieldTheme.rMD, style: .continuous))
                            .shadow(color: Color(hex: "FFD60A").opacity(0.35), radius: 10, y: 4)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.horizontal, ShieldTheme.s4)
                        .padding(.top, ShieldTheme.s2)
                        .padding(.bottom, ShieldTheme.s5)
                    }
                }
            }
            .navigationTitle(strings.settings("settings_app_icon_preview"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(strings.common("common_close")) {
                        dismiss()
                    }
                    .font(.body.weight(.medium))
                    .foregroundStyle(ShieldTheme.primary(scheme))
                }
            }
        }
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: ShieldTheme.s3) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.16))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ShieldTheme.primary(scheme))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
            }
            Spacer(minLength: 0)
        }
    }
}
