import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var cloud = CloudSyncManager.shared
    @State private var asoOverlayPresented = true

    var body: some View {
        ZStack {
            AuthenticatedShellView(appState: appState)
                .id("shell-\(appState.language.rawValue)")
                .opacity(sessionStage == .ready ? 1 : 0)
                .allowsHitTesting(sessionStage == .ready)
                .accessibilityHidden(sessionStage != .ready)

            if sessionStage == .locked {
                LockScreenView()
                    .id("lock-\(appState.language.rawValue)")
                    .transition(.opacity)
            }

            if sessionStage == .onboarding {
                OnboardingFlowView()
                    .id("onboarding-\(appState.language.rawValue)")
                    .transition(.opacity)
            }

            if scenePhase != .active {
                PrivacySnapshotShield()
                    .zIndex(10_000)
            }

#if DEBUG
            if ASOScreenshotMode.isEnabled, ASOScreenshotMode.scene == "paywall" {
                PaywallView(isPresented: $asoOverlayPresented, trigger: .manual)
                    .environmentObject(appState)
                    .zIndex(20_000)
            }

            if ASOScreenshotMode.isEnabled, ASOScreenshotMode.scene == "batch" {
                BatchRedactView(isPresented: $asoOverlayPresented)
                    .environmentObject(appState)
                    .zIndex(20_000)
            }
#endif
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.3), value: sessionStage)
        .colorScheme(appState.preferredScheme)
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .simultaneousGesture(
            // minimumDistance 0 fires on touch-down, so scrolling, zooming and
            // drawing count as activity for the inactivity auto-lock, not just taps.
            DragGesture(minimumDistance: 0)
                .onChanged { _ in noteUserActivity() }
        )
        .simultaneousGesture(
            TapGesture().onEnded(noteUserActivity)
        )
    }

    private var sessionStage: SessionStage {
        if !appState.isOnboarded { return .onboarding }
        if !appState.isAuthenticated { return .locked }
        return .ready
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        appState.handleScenePhaseChange(newPhase)

        guard newPhase == .active, sessionStage == .ready else { return }
        cloud.syncOnForeground(appState: appState)
    }

    private func noteUserActivity() {
        AppState.markUserActivity()
    }
}

private struct PrivacySnapshotShield: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 14) {
                Image("MaskIDMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .clipShape(.rect(cornerRadius: 18))
                    .accessibilityHidden(true)
                Text("MaskID")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityHidden(true)
    }
}

private enum SessionStage {
    case onboarding
    case locked
    case ready
}

private struct AuthenticatedShellView: View {
    @ObservedObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            if horizontalSizeClass == .regular {
                HStack(spacing: 0) {
                    ShieldSidebar(
                        selected: $appState.activeTab,
                        lang: appState.language,
                        onScanTap: { appState.showCapture = true }
                    )
                    Divider()
                    tabContent
                }
            } else {
                tabContent
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        ShieldTabBar(
                            selected: $appState.activeTab,
                            lang: appState.language,
                            onScanTap: { appState.showCapture = true }
                        )
                    }
                    .ignoresSafeArea(edges: .bottom)
            }

            if appState.showCapture {
                CaptureView()
                    .transition(.move(edge: .bottom))
                    .zIndex(50)
            }

            if let doc = appState.selectedDoc {
                EditorView(doc: doc)
                    .id(doc.id)
                    .transition(.move(edge: .trailing))
                    .zIndex(60)
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: appState.showCapture)
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.88), value: appState.selectedDoc?.id)
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
