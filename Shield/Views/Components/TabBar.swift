import SwiftUI

// MARK: - AppTab

enum AppTab: Int, CaseIterable, Identifiable {
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
    var onScanTap: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 0) {
            tabItem(.library)
            tabItem(.gallery)
            scanButton
            tabItem(.vault)
            tabItem(.settings)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(ShieldTheme.cardBackground(scheme))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ShieldTheme.line(scheme))
                .frame(height: 0.5)
        }
    }

    @ViewBuilder
    private var scanButton: some View {
        Button(action: onScanTap) {
            ZStack {
                Circle()
                    .fill(ShieldTheme.accent(scheme))
                    .frame(width: 72, height: 72)
                    .shadow(color: ShieldTheme.accent(scheme).opacity(scheme == .dark ? 0.45 : 0.24), radius: 12, x: 0, y: 5)
                Image(systemName: "camera.viewfinder")
                    .shieldFont(26, weight: .semibold)
                    .foregroundColor(ShieldTheme.accentText)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(maxWidth: .infinity)
        .offset(y: -24)
        .accessibilityLabel(LanguageManager.shared.capture("capture_scan_document"))
        .accessibilityHint(LanguageManager.shared.capture("capture_scan_accessibility_hint"))
        .accessibilityIdentifier("tab.capture")
    }

    @ViewBuilder
    private func tabItem(_ tab: AppTab) -> some View {
        let isActive = selected == tab
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { selected = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: isActive ? tab.filledIcon : tab.icon)
                    .font(.body.weight(isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
                    .scaleEffect(isActive ? 1.05 : 1)
                    .animation(.spring(response: 0.25), value: isActive)
                Text(tab.label(lang: lang))
                    .font(.caption2.weight(isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
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
                .accessibilityLabel(tab.label(lang: lang))
                .accessibilityAddTraits(active ? .isSelected : [])
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 16)
        .frame(width: 92)
        .background(ShieldTheme.cardBackground(scheme))
    }
}
