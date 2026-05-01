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
                        .fill(ShieldTheme.accent)
                        .frame(width: 64, height: 64)
                        .shadow(color: ShieldTheme.accent.opacity(0.45), radius: 12, x: 0, y: 5)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(ShieldTheme.accentText)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .frame(maxWidth: .infinity)
            .offset(y: -22)

            // Vault
            tabItem(.vault)

            // Settings
            tabItem(.settings)
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(
            ZStack {
                // Material blur
                Rectangle()
                    .fill(.ultraThinMaterial)
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
                    .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? ShieldTheme.accent : ShieldTheme.tertiary(scheme))
                    .scaleEffect(isActive ? 1.05 : 1)
                    .animation(.spring(response: 0.25), value: isActive)
                Text(tab.label(lang: lang))
                    .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                    .foregroundColor(isActive ? ShieldTheme.accent : ShieldTheme.tertiary(scheme))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
