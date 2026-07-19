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
        case .library:  return LanguageManager.shared.common("common_tab_docs")
        case .gallery:  return LanguageManager.shared.common("common_tab_styles")
        case .vault:    return LanguageManager.shared.common("common_tab_vault")
        case .settings: return LanguageManager.shared.common("common_tab_settings")
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
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @MainActor
    private var bottomPadding: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        let windowScene = scenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
            ?? scenes.first as? UIWindowScene
        let bottom = windowScene?.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets.bottom ?? 0
        return bottom > 0 ? 16 : 6
    }

    var body: some View {
        HStack(spacing: 0) {
            // Library
            tabItem(.library)

            // Gallery
            tabItem(.gallery)

            // Scan FAB (center)
            Button(action: onScanTap) {
                ZStack {
                    Circle()
                        .fill(ShieldTheme.accent(scheme))
                        .frame(width: 72, height: 72)
                        .shadow(color: ShieldTheme.accent(scheme).opacity(scheme == .dark ? 0.45 : 0.24), radius: 12, x: 0, y: 5)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(ShieldTheme.accentText)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .frame(maxWidth: .infinity)
            .offset(y: -24)
            .accessibilityLabel(LanguageManager.shared.capture("capture_scan_document"))
            .accessibilityHint(LanguageManager.shared.capture("capture_scan_accessibility_hint"))

            // Vault
            tabItem(.vault)

            // Settings
            tabItem(.settings)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, bottomPadding)
        .background(
            ZStack {
                // Material blur
                Rectangle()
                    .fill(reduceTransparency ? AnyShapeStyle(ShieldTheme.cardBackground(scheme)) : AnyShapeStyle(.ultraThinMaterial))
                // Top hairline
                VStack {
                    Rectangle()
                        .fill(ShieldTheme.line(scheme))
                        .frame(height: 0.5)
                    Spacer()
                }
            }
        )
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
