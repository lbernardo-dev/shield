import SwiftUI

// MARK: - AppTab

enum AppTab: Int, CaseIterable, Identifiable, Hashable {
    case library
    case gallery
    case vault
    case settings
    case capture

    static var navigationCases: [AppTab] {
        allCases.filter { $0 != .capture }
    }

    var id: Int { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .library:  return LanguageManager.shared.t("common_tab_docs", table: "Common", language: lang)
        case .gallery:  return LanguageManager.shared.t("common_tab_styles", table: "Common", language: lang)
        case .vault:    return LanguageManager.shared.t("common_tab_vault", table: "Common", language: lang)
        case .settings: return LanguageManager.shared.t("common_tab_settings", table: "Common", language: lang)
        case .capture:  return LanguageManager.shared.capture("capture_scan_document")
        }
    }

    var icon: String {
        if ShieldTheme.activeThemeID == .halloween2026 {
            switch self {
            case .library:  return "scroll"
            case .gallery:  return "wand.and.stars"
            case .vault:    return "lock.shield"
            case .settings: return "slider.horizontal.3"
            case .capture:  return "camera.viewfinder"
            }
        }
        switch self {
        case .library:  return "doc.on.doc"
        case .gallery:  return "square.grid.2x2"
        case .vault:    return "lock.rectangle.stack"
        case .settings: return "gearshape"
        case .capture:  return "camera.viewfinder"
        }
    }

    var filledIcon: String {
        if ShieldTheme.activeThemeID == .halloween2026 {
            switch self {
            case .library:  return "scroll.fill"
            case .gallery:  return "wand.and.stars"
            case .vault:    return "lock.shield.fill"
            case .settings: return "slider.horizontal.3"
            case .capture:  return "camera.viewfinder"
            }
        }
        switch self {
        case .library:  return "doc.on.doc.fill"
        case .gallery:  return "square.grid.2x2.fill"
        case .vault:    return "lock.rectangle.stack.fill"
        case .settings: return "gearshape.fill"
        case .capture:  return "camera.viewfinder"
        }
    }
}

// MARK: - ShieldTabBar

struct ShieldTabBar: View {
    @Binding var selected: AppTab
    let lang: AppLanguage
    @Environment(\.colorScheme) var scheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background bar spanning into safe area
            VStack(spacing: 0) {
                Rectangle()
                    .fill(ShieldTheme.line(scheme))
                    .frame(height: 0.5)
                Rectangle()
                    .fill(ShieldTheme.cardBackground(scheme))
            }
            .frame(height: 52)

            // Tabs
            HStack(spacing: 0) {
                tabItem(.library)
                tabItem(.gallery)
                tabItem(.vault)
                tabItem(.settings)
            }
            .frame(height: 52)
            .padding(.horizontal, 4)
        }
        .frame(height: 70, alignment: .bottom)
        .background(
            ShieldTheme.cardBackground(scheme)
                .ignoresSafeArea(edges: .bottom)
                .padding(.top, 18)
        )
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
                if !dynamicTypeSize.isAccessibilitySize {
                    Text(tab.label(lang: lang))
                        .shieldFont(10, weight: isActive ? .bold : .medium)
                        .foregroundStyle(isActive ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
                        .lineLimit(1)
                }
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

            ForEach(AppTab.navigationCases) { tab in
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
