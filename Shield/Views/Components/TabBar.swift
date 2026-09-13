import SwiftUI

// MARK: - AppTab

enum AppTab: Int, CaseIterable, Identifiable, Hashable {
    case library
    case gallery
    case vault
    case settings

    var id: Int { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .library:  return LanguageManager.shared.t("common_tab_docs", table: "Common", language: lang)
        case .gallery:  return LanguageManager.shared.t("common_tab_styles", table: "Common", language: lang)
        case .vault:    return LanguageManager.shared.t("common_tab_vault", table: "Common", language: lang)
        case .settings: return LanguageManager.shared.t("common_tab_settings", table: "Common", language: lang)
        }
    }

    var icon: String {
        switch self {
        case .library:  return "doc.on.doc"
        case .gallery:  return "square.grid.2x2"
        case .vault:    return "lock.rectangle.stack"
        case .settings: return "gearshape"
        }
    }

    var filledIcon: String {
        switch self {
        case .library:  return "doc.on.doc.fill"
        case .gallery:  return "square.grid.2x2.fill"
        case .vault:    return "lock.rectangle.stack.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - ShieldTabBar

struct ShieldTabBar: View {
    @Binding var selected: AppTab
    let lang: AppLanguage
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabItem(tab)
            }
        }
        .frame(height: 50)
        .padding(.horizontal, 4)
        .background(ShieldTheme.cardBackground(scheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ShieldTheme.line(scheme))
                .frame(height: 0.5)
        }
    }
}

struct ShieldScanButton: View {
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(ShieldTheme.accent(scheme))
                    .overlay {
                        Circle()
                            .stroke(ShieldTheme.cardBackground(scheme), lineWidth: 3.5)
                    }
                    .shadow(
                        color: ShieldTheme.accent(scheme).opacity(scheme == .dark ? 0.38 : 0.22),
                        radius: 8,
                        y: 2
                    )
                Image(systemName: "camera.viewfinder")
                    .shieldFont(20, weight: .bold)
                    .foregroundColor(ShieldTheme.accentText)
            }
            .frame(width: 64, height: 64)
            .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(LanguageManager.shared.capture("capture_scan_document"))
        .accessibilityHint(LanguageManager.shared.capture("capture_scan_accessibility_hint"))
        .accessibilityIdentifier("tab.capture")
    }
}

/// The primary Scan action is an accessory to navigation, not a fifth tab.
/// On iOS 26 the system moves and compacts this accessory with the tab bar,
/// including the vertical control rail used by iPhone Duo.
@available(iOS 26.0, *)
struct ShieldScanAccessory: View {
    let action: () -> Void
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Button(action: action) {
                if placement == .inline {
                    Image(systemName: "camera.viewfinder")
                        .font(.title3.weight(.semibold))
                        .frame(minWidth: ShieldTheme.minimumTapTarget, minHeight: ShieldTheme.minimumTapTarget)
                } else {
                    Label(
                        LanguageManager.shared.capture("capture_scan_document"),
                        systemImage: "camera.viewfinder"
                    )
                    .font(.headline)
                    .padding(.horizontal, ShieldTheme.s2)
                    .frame(minHeight: ShieldTheme.minimumTapTarget)
                }
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .accessibilityLabel(LanguageManager.shared.capture("capture_scan_document"))
            .accessibilityHint(LanguageManager.shared.capture("capture_scan_accessibility_hint"))
            .accessibilityIdentifier("tab.capture")
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ShieldTheme.s2)
    }
}

/// Fallback accessory for iOS versions without the system Liquid Glass
/// accessory placement APIs.
struct ShieldLegacyScanAccessory: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            ShieldScanButton(action: action)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.vertical, ShieldTheme.s2)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: ShieldTheme.rLG, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

/// Primary Scan action for an adaptable sidebar. ViewThatFits lets the system
/// keep the label when the rail is wide and collapse it to the symbol when the
/// available width is narrow, without device-specific coordinates.
@available(iOS 26.0, *)
struct ShieldSidebarScanAction: View {
    let action: () -> Void

    var body: some View {
        ViewThatFits(in: .horizontal) {
            Button(action: action) {
                Label(
                    LanguageManager.shared.capture("capture_scan_document"),
                    systemImage: "camera.viewfinder"
                )
                .frame(maxWidth: .infinity, minHeight: ShieldTheme.minimumTapTarget)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)

            Button(action: action) {
                Image(systemName: "camera.viewfinder")
                    .font(.title3.weight(.semibold))
                    .frame(minWidth: ShieldTheme.minimumTapTarget, minHeight: ShieldTheme.minimumTapTarget)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .accessibilityLabel(LanguageManager.shared.capture("capture_scan_document"))
        .accessibilityHint(LanguageManager.shared.capture("capture_scan_accessibility_hint"))
        .accessibilityIdentifier("sidebar.capture")
    }
}

private extension ShieldTabBar {
    @ViewBuilder
    private func tabItem(_ tab: AppTab) -> some View {
        let isActive = selected == tab
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { selected = tab }
        } label: {
            VStack(spacing: 1.5) {
                Image(systemName: isActive ? tab.filledIcon : tab.icon)
                    .font(.system(size: 18, weight: isActive ? .semibold : .regular))
                    .foregroundStyle(isActive ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
                    .scaleEffect(isActive ? 1.05 : 1)
                    .animation(.spring(response: 0.25), value: isActive)
                Text(tab.label(lang: lang))
                    .font(.system(size: 10, weight: isActive ? .bold : .medium))
                    .foregroundStyle(isActive ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
            }
            .frame(maxWidth: .infinity, minHeight: ShieldTheme.minimumTapTarget)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label(lang: lang))
        .accessibilityValue(isActive ? LanguageManager.shared.common("common_selected") : "")
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityIdentifier("tab.\(tab.rawValue)")
    }
}

// MARK: - iPad sidebar

struct ShieldSidebar: View {
    @Binding var selected: AppTab
    let lang: AppLanguage
    var onScanTap: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 8) {
            Button(action: onScanTap) {
                Image(systemName: "camera.viewfinder")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(ShieldTheme.accentText)
                    .frame(width: 52, height: 52)
                    .background(ShieldTheme.accent(scheme), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(LanguageManager.shared.capture("capture_scan_document"))
            .keyboardShortcut("n", modifiers: .command)
            .padding(.bottom, 12)

            ForEach(AppTab.allCases) { tab in
                let active = selected == tab
                Button {
                    selected = tab
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: active ? tab.filledIcon : tab.icon)
                            .font(.title3)
                        Text(tab.label(lang: lang))
                            .font(.caption2)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(active ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(active ? ShieldTheme.accentDim(scheme) : .clear, in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)
                .keyboardShortcut(shortcut(for: tab), modifiers: .command)
                .accessibilityLabel(tab.label(lang: lang))
                .accessibilityValue(active ? LanguageManager.shared.common("common_selected") : "")
                .accessibilityAddTraits(active ? .isSelected : [])
                .accessibilityIdentifier("sidebar.\(tab.rawValue)")
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 16)
        .frame(width: 92)
        .background(ShieldTheme.cardBackground(scheme))
    }

    private func shortcut(for tab: AppTab) -> KeyEquivalent {
        KeyEquivalent(Character(String(tab.rawValue + 1)))
    }
}
