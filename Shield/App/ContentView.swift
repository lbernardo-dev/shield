import SwiftUI

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var cloud = CloudSyncManager.shared
    @State private var asoOverlayPresented = true
    @State private var showSplash = LaunchSplashState.shouldPresent

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

            if showSplash {
                SplashView(onFinished: dismissSplash)
                    .transition(.opacity)
                    .zIndex(9_000)
            }

            if scenePhase != .active {
                PrivacySnapshotShield()
                    .zIndex(10_000)
            }

#if DEBUG
            if ASOScreenshotMode.isEnabled, ASOScreenshotMode.scene == "paywall", asoOverlayPresented {
                PaywallView(isPresented: $asoOverlayPresented, trigger: .manual)
                    .environmentObject(appState)
                    .zIndex(20_000)
            }

            if ASOScreenshotMode.isEnabled, ASOScreenshotMode.scene == "batch", asoOverlayPresented {
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
        .onAppear {
            guard showSplash else { return }
            LaunchSplashState.hasBeenPresented = true
        }
    }

    private var sessionStage: SessionStage {
        if !appState.isOnboarded { return .onboarding }
        if !appState.isAuthenticated { return .locked }
        return .ready
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        appState.handleScenePhaseChange(newPhase)

        guard newPhase == .active else { return }
        appState.syncAppIconWithSystem()

        guard sessionStage == .ready else { return }
        cloud.syncOnForeground(appState: appState)
    }

    private func dismissSplash() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.45)) {
            showSplash = false
        }
    }
}

private struct PrivacySnapshotShield: View {
    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color(hex: "061E33"),
                    Color(hex: "030E1A"),
                    Color(hex: "01050A")
                ],
                center: .center,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: ShieldTheme.s4) {
                MaskIDIdentityMark(
                    size: 200,
                    presentation: .animatedLoop,
                    treatment: .splash
                )

                VStack(spacing: 6) {
                    Text(LanguageManager.shared.common("common_app_name"))
                        .shieldFont(22, weight: .heavy, design: .rounded)
                        .foregroundStyle(Color.white)

                    Text(LanguageManager.shared.auth("lock_protection_active"))
                        .shieldFont(12, weight: .bold)
                        .foregroundStyle(Color(hex: "00E5FF"))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Color(hex: "00B4D8").opacity(0.16), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "00B4D8").opacity(0.35), lineWidth: 0.8)
                        )
                }
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
                        if appState.activeTab != .settings {
                            ShieldTabBar(
                                selected: $appState.activeTab,
                                lang: appState.language,
                                onScanTap: { appState.showCapture = true }
                            )
                        }
                    }
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
                .environment(\.closeSettings) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        appState.activeTab = .library
                    }
                }
        }
    }
}

private enum LaunchSplashState {
    /// Prevents root view reconstruction from replaying the launch overlay.
    static var hasBeenPresented = false

    /// UI tests and ASO screenshot capture exercise underlying screens and must not wait on decorative launch motion.
    static var shouldPresent: Bool {
        !hasBeenPresented
            && !ProcessInfo.processInfo.arguments.contains("-ui-testing")
            && !ProcessInfo.processInfo.arguments.contains("-aso-screenshots")
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
}
