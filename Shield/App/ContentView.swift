import SwiftUI
import UIKit

// MARK: - ContentView

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject private var seasonalThemes: SeasonalThemeCoordinator
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject private var cloud = CloudSyncManager.shared
    @ObservedObject private var premium = PremiumManager.shared
    @State private var asoOverlayPresented = true
    @State private var showSplash = LaunchSplashState.shouldPresent
    @State private var themeTransition: SeasonalThemeID?
    @AppStorage(FirebaseIntegration.analyticsConsentPromptAnsweredKey)
    private var analyticsConsentPromptAnswered = false
    @State private var showAnalyticsConsent = false

    var body: some View {
        ZStack {
            AuthenticatedShellView(appState: appState)
                .id("shell-\(appState.language.rawValue)-\(seasonalThemes.activeThemeID.rawValue)")
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

            ReviewFeedbackBridge(isPresentationAllowed: sessionStage == .ready)
                .zIndex(30_000)

#if DEBUG
            if ASOScreenshotMode.isEnabled, ASOScreenshotMode.scene == "paywall", asoOverlayPresented {
                PaywallView(isPresented: $asoOverlayPresented, trigger: .manual)
                    .environmentObject(appState)
                    .zIndex(20_000)
            }

            if ASOScreenshotMode.isEnabled, (ASOScreenshotMode.scene == "batch" || ASOScreenshotMode.scene == "08-batch-processing" || ASOScreenshotMode.scene == "08" || ASOScreenshotMode.scene == "batch-review-queue"), asoOverlayPresented {
                BatchRedactView(isPresented: $asoOverlayPresented)
                    .environmentObject(appState)
                    .zIndex(20_000)
            }

            if ASOScreenshotMode.isEnabled, ASOScreenshotMode.scene == "profile", asoOverlayPresented {
                UserProfileView()
                    .environmentObject(appState)
                    .zIndex(20_000)
            }
#endif
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .top) {
            if let themeTransition {
                SeasonalThemeChangeOverlay(themeID: themeTransition)
                    .padding(.top, ShieldTheme.s4)
                    .padding(.horizontal, ShieldTheme.s4)
                    .zIndex(40_000)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
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
        .onAppear(perform: presentAnalyticsConsentIfNeeded)
        .onAppear {
            Task { @MainActor in
                // Wait until SwiftUI has finished installing the initial scene.
                // A single task yield can still run inside the first layout on
                // iPad and publish theme state during a view update.
                try? await Task.sleep(for: .milliseconds(60))
                seasonalThemes.refresh(
                    isPro: premium.isPro,
                    hasResolvedEntitlement: premium.hasResolvedSubscription
                )
                appState.applySeasonalThemeAppearance(for: seasonalThemes.activeThemeID)
                syncSeasonalThemeIcon()
                seasonalThemes.setSceneActive(true)
            }
        }
        .onChange(of: seasonalThemes.activeThemeID) { _, newTheme in
            appState.applySeasonalThemeAppearance(for: newTheme)
            syncSeasonalThemeIcon()
            withAnimation(reduceMotion ? nil : ShieldMotion.navigation) {
                themeTransition = newTheme
            }
            let displayedTheme = newTheme
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
                guard themeTransition == displayedTheme else { return }
                withAnimation(reduceMotion ? nil : ShieldMotion.navigation) {
                    themeTransition = nil
                }
            }
        }
        .onChange(of: seasonalThemes.activeScheduledThemeID) { _, _ in
            Task { await premium.loadProducts() }
        }
        .onChange(of: premium.isPro) { _, isPro in
            seasonalThemes.refresh(
                isPro: isPro,
                hasResolvedEntitlement: premium.hasResolvedSubscription
            )
            appState.applySeasonalThemeAppearance(for: seasonalThemes.activeThemeID)
            syncSeasonalThemeIcon()
            appState.refreshWidgetSnapshot()
            if isPro, sessionStage == .ready {
                cloud.syncOnForeground(appState: appState)
            }
        }
        .onChange(of: premium.hasResolvedSubscription) { _, isResolved in
            seasonalThemes.refresh(
                isPro: premium.isPro,
                hasResolvedEntitlement: isResolved
            )
            appState.applySeasonalThemeAppearance(for: seasonalThemes.activeThemeID)
            syncSeasonalThemeIcon()
        }
        .onChange(of: showSplash) { _, isShowing in
            if !isShowing { presentAnalyticsConsentIfNeeded() }
        }
        .sheet(isPresented: $showAnalyticsConsent) {
            AnalyticsConsentView { granted in
                FirebaseIntegration.setAnalyticsConsent(granted)
                analyticsConsentPromptAnswered = true
                showAnalyticsConsent = false
            }
        }
        // Keep the capture presentation hosted by the stable app root. The
        // authenticated navigation tree is intentionally rebuilt when the
        // active tab, language, or managed theme changes; hosting this cover
        // there can swallow a tap made immediately after returning from
        // Settings even though the scan button remains hittable.
        .fullScreenCover(
            isPresented: Binding(
                get: { appState.showCapture },
                set: { appState.showCapture = $0 }
            )
        ) {
            CaptureView()
                .environmentObject(appState)
        }
    }

    private var sessionStage: SessionStage {
        if !appState.isOnboarded { return .onboarding }
        if !appState.isAuthenticated { return .locked }
        return .ready
    }

    private func syncSeasonalThemeIcon() {
        guard !seasonalThemes.shouldDeferSeasonalIconUntilEntitlementResolves else { return }
        appState.applySeasonalThemeIcon(for: seasonalThemes.activeThemeID)
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        appState.handleScenePhaseChange(newPhase)
        seasonalThemes.setSceneActive(newPhase == .active)

        guard newPhase == .active else {
            if newPhase == .background {
                premium.invalidateCloudKitPremiumAccess()
            }
            return
        }
        appState.syncAppIconWithSystem()
        seasonalThemes.refresh(
            isPro: premium.isPro,
            hasResolvedEntitlement: premium.hasResolvedSubscription
        )
        appState.applySeasonalThemeAppearance(for: seasonalThemes.activeThemeID)
        syncSeasonalThemeIcon()

        Task { await premium.refreshCloudKitPremiumAccess() }

        guard sessionStage == .ready else { return }
        cloud.syncOnForeground(appState: appState)
        Task {
            await premium.updateProStatus()
            await premium.loadProducts()
            await SubscriptionLifecycleObserver.shared.refresh()
        }
    }

    private func dismissSplash() {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.45)) {
            showSplash = false
        }
    }

    private func presentAnalyticsConsentIfNeeded() {
        let arguments = ProcessInfo.processInfo.arguments
        let forcedForTesting = arguments.contains("-show-analytics-consent")
        // Product analytics is off by default and can be enabled from Privacy
        // Settings. Never put a consent sheet in front of the first document
        // task; this forced path exists only for the consent UI test.
        guard forcedForTesting,
              !showSplash,
              sessionStage == .ready,
              !analyticsConsentPromptAnswered || forcedForTesting else {
            return
        }
        showAnalyticsConsent = true
    }
}

private struct PrivacySnapshotShield: View {
    @Environment(\.colorScheme) private var scheme

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
                        .foregroundStyle(ShieldTheme.accent(scheme))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(ShieldTheme.accentDim(scheme), in: Capsule())
                        .overlay(
                            Capsule()
                                .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 0.8)
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
    @State private var splitColumnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        ZStack {
            if horizontalSizeClass == .regular {
                regularNavigation
            } else if #available(iOS 26.0, *) {
                // Keep the adaptive TabView mounted while its sidebar changes
                // selection. Replacing it with a standalone SettingsView in
                // the same update can make UIKit build a sidebar transition
                // preview for a view that has already left the window.
                adaptiveTabNavigation
            } else if appState.activeTab == .settings {
                // Legacy navigation has a custom footer; settings is presented
                // outside that shell so it cannot cover the final settings rows.
                SettingsView()
                    .transition(.move(edge: .trailing))
                    .zIndex(20)
            } else {
                legacyCompactNavigation
            }

            if appState.activeTab != .settings,
               !appState.showCapture,
               let doc = appState.selectedDoc {
                EditorView(doc: doc)
                    .id(doc.id)
                    .transition(.move(edge: .trailing))
                    .zIndex(60)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: appState.showCapture)
        .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.88), value: appState.selectedDoc?.id)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: appState.activeTab)
    }

    private func openCapture() {
        guard !appState.showCapture else { return }

        // Tab and toolbar actions can arrive during UIKit's navigation update,
        // especially on iPad's sidebar-adaptable TabView. Defer the root-hosted
        // cover until that update has settled or SwiftUI may drop the request.
        Task { @MainActor in
            await Task.yield()
            guard !appState.showCapture else { return }

            // Clear an editor selection before presenting intake so its
            // transition cannot obscure the capture surface.
            if appState.selectedDoc != nil {
                appState.selectedDoc = nil
                await Task.yield()
            }

            guard !appState.showCapture else { return }
            appState.showCapture = true
        }
    }

    @ViewBuilder
    private var legacyCompactNavigation: some View {
        tabContent
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if appState.activeTab != .settings {
                    ShieldTabBar(
                        selected: $appState.activeTab,
                        lang: appState.language
                    )
                }
            }
    }

    @ViewBuilder
    private var regularNavigation: some View {
        NavigationSplitView(columnVisibility: $splitColumnVisibility) {
            List {
                ForEach(AppTab.navigationCases) { tab in
                    Button {
                        selectNativeTab(tab)
                    } label: {
                        Label(tab.label(lang: appState.language), systemImage: tab.icon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        appState.activeTab == tab
                            ? ShieldTheme.accentDim(appState.preferredScheme)
                            : Color.clear
                    )
                    .accessibilityValue(
                        appState.activeTab == tab
                            ? LanguageManager.shared.common("common_selected")
                            : ""
                    )
                    .accessibilityAddTraits(appState.activeTab == tab ? .isSelected : [])
                    .accessibilityLabel(tab.label(lang: appState.language))
                    .accessibilityIdentifier("tab.\(tab.rawValue)")
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
            .accessibilityIdentifier("navigation.sidebar")
        } detail: {
            if appState.activeTab == .settings {
                SettingsView(onClose: { selectNativeTab(.library) })
            } else {
                NavigationStack {
                    tabContent(for: appState.activeTab)
                }
                .id(appState.activeTab)
                .toolbarBackground(.hidden, for: .navigationBar)
            }
        }
        .navigationSplitViewStyle(.balanced)
    }

    /// Let SwiftUI choose the native tab representation. Capture is exposed
    /// from the Home toolbar and primary action, not from a persistent tab item.
    @available(iOS 26.0, *)
    private var adaptiveTabNavigation: some View {
        nativeTabView
            // On iPhone, hide the bottom tab bar while Settings is open. On
            // iPad and Duo, keep the native sidebar stable during selection;
            // it lives outside the document area and does not cover settings.
            .toolbarVisibility(
                horizontalSizeClass == .compact && appState.activeTab == .settings
                    ? .hidden
                    : .automatic,
                for: .tabBar
            )
    }

    @available(iOS 26.0, *)
    private var nativeTabView: some View {
        TabView(selection: Binding(
            get: { appState.activeTab },
            set: { newTab in
                guard newTab != appState.activeTab else { return }
                withAnimation(reduceMotion ? nil : ShieldMotion.press) {
                    appState.activeTab = newTab
                }
            }
        )) {
            ForEach(AppTab.navigationCases) { tab in
                Tab(value: tab) {
                    nativeTabRoot(for: tab)
                } label: {
                    Label(tab.label(lang: appState.language), systemImage: tab.icon)
                        .accessibilityIdentifier("tab.\(tab.rawValue)")
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .tint(ShieldTheme.accent(appState.preferredScheme))
        .defaultAdaptableTabBarPlacement(.sidebar)
    }

    @ViewBuilder
    @available(iOS 26.0, *)
    private func nativeTabRoot(for tab: AppTab) -> some View {
        if tab == .settings {
            // Settings owns its navigation stack and toolbar already.
            SettingsView(onClose: { selectNativeTab(.library) })
        } else {
            NavigationStack {
                tabContent(for: tab)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func selectNativeTab(_ tab: AppTab) {
        withAnimation(reduceMotion ? nil : ShieldMotion.press) {
            appState.activeTab = tab
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        tabContent(for: appState.activeTab)
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .library:
            HomeView(onScanTap: openCapture)
        case .gallery:
            StyleGalleryView()
        case .vault:
            VaultView()
        case .settings:
            SettingsView()
        case .capture:
            Color.clear
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
        .environmentObject(SeasonalThemeCoordinator.shared)
}
