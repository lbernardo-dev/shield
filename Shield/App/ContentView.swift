import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var cloud = CloudSyncManager.shared

    var body: some View {
        Group {
            if !appState.isOnboarded {
                OnboardingFlowView()
                    .transition(.opacity)
            } else if !appState.isAuthenticated {
                LockScreenView()
                    .transition(.opacity)
            } else {
                mainInterface
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.isOnboarded)
        .animation(.easeInOut(duration: 0.3), value: appState.isAuthenticated)
        .colorScheme(appState.preferredScheme)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                cloud.syncOnForeground(documents: appState.documents)
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                AppState.markUserActivity()
            }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.2).onEnded { _ in
                AppState.markUserActivity()
            }
        )
    }

    // MARK: - Main interface with tab bar

    private var mainInterface: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            tabContent
                .ignoresSafeArea(edges: .bottom)

            // Custom tab bar
            VStack(spacing: 0) {
                Spacer()
                ShieldTabBar(
                    selected: $appState.activeTab,
                    lang: appState.language,
                    onScanTap: { appState.showCapture = true }
                )
            }
            .ignoresSafeArea(edges: .bottom)

            // Full-screen overlays
            if appState.showCapture {
                CaptureView()
                    .transition(.move(edge: .bottom))
                    .zIndex(50)
            }

            if let doc = appState.selectedDoc {
                EditorView(doc: doc)
                    .transition(.move(edge: .trailing))
                    .zIndex(60)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: appState.showCapture)
        .animation(.spring(response: 0.35, dampingFraction: 0.88), value: appState.selectedDoc?.id)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in AppState.markUserActivity() }
        )
    }

    @ViewBuilder
    private var tabContent: some View {
        switch appState.activeTab {
        case .library:
            HomeView()
        case .gallery:
            StyleGalleryView()
        case .vault:
            VaultView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
}
