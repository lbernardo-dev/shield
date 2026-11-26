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
  @State private var showAnalyticsConsent = false
  @State private var releasePrompt: AppReleasePrompt?
  @State private var nextAppStoreCheck: Date = .distantPast

  var body: some View {
    ZStack {
      if sessionStage == .ready {
        let editorNeedsBoundaryResolution =
          premium.accessState.isReadOnly
          && appState.activeEditorDocumentID != nil
        if premium.isPro || premium.accessState.hasFullAccess || editorNeedsBoundaryResolution {
          AuthenticatedShellView(appState: appState)
            .id("shell-\(appState.language.rawValue)-\(seasonalThemes.activeThemeID.rawValue)")
            .transition(.opacity)
        } else if premium.isResolvingSubscription || !premium.hasResolvedSubscription
          || premium.accessState == .verifying
        {
          ZStack {
            ShieldTheme.pageBackground(appState.preferredScheme).ignoresSafeArea()
            ProgressView(appState.language == .es ? "Cargando MaskID…" : "Loading MaskID…")
              .tint(ShieldTheme.primary(appState.preferredScheme))
          }
          .transition(.opacity)
        } else {
          AccessGateRootView()
            .environmentObject(appState)
            .transition(.opacity)
        }
      }

      if sessionStage == .locked {
        LockScreenView(isBlockedBySplash: showSplash)
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

      if scenePhase == .background && sessionStage == .ready && !showSplash {
        PrivacySnapshotShield()
          .zIndex(10_000)
      }

      ReviewFeedbackBridge(
        isPresentationAllowed: sessionStage == .ready && premium.accessState.hasFullAccess
      )
      .zIndex(30_000)

      #if DEBUG
        if ASOScreenshotMode.isEnabled, ASOScreenshotMode.scene == "paywall", asoOverlayPresented {
          PaywallView(isPresented: $asoOverlayPresented, trigger: .manual)
            .environmentObject(appState)
            .zIndex(20_000)
        }

        if ASOScreenshotMode.isEnabled,
          ASOScreenshotMode.scene == "batch" || ASOScreenshotMode.scene == "08-batch-processing"
            || ASOScreenshotMode.scene == "08" || ASOScreenshotMode.scene == "batch-review-queue",
          asoOverlayPresented
        {
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
    .animation(
      (reduceMotion || seasonalThemes.isReducingDecorativeEffects)
        ? nil : .easeInOut(duration: 0.3), value: sessionStage
    )
    .colorScheme(appState.preferredScheme)
    .environment(\.reduceDecorativeEffects, seasonalThemes.isReducingDecorativeEffects)
    .environment(
      \.seasonalInvitationAllowed,
      sessionStage == .ready && premium.accessState.hasFullAccess && !showSplash
        && !appState.showCapture && !showAnalyticsConsent && releasePrompt == nil
        && scenePhase == .active
    )
    .task(id: canPresentRelease) { await presentReleaseIfNeeded() }
    .task {
      while !Task.isCancelled {
        premium.refreshTemporalAccess()
        if premium.canOfferFeedbackExtension {
          ReviewFeedbackCoordinator.shared.track(.temporaryAccessExpiring)
        }
        do {
          try await Task.sleep(for: .seconds(30))
        } catch {
          return
        }
      }
    }
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
      withAnimation(
        (reduceMotion || seasonalThemes.isReducingDecorativeEffects) ? nil : ShieldMotion.navigation
      ) {
        themeTransition = newTheme
      }
      let displayedTheme = newTheme
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) {
        guard themeTransition == displayedTheme else { return }
        withAnimation(
          (reduceMotion || seasonalThemes.isReducingDecorativeEffects)
            ? nil : ShieldMotion.navigation
        ) {
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
        showAnalyticsConsent = false
      }
    }
    .sheet(item: $releasePrompt) { prompt in
      AppReleaseSheet(prompt: prompt)
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
        .overlay {
          if !premium.accessState.hasFullAccess {
            CaptureAccessBoundaryOverlay()
              .environmentObject(appState)
          }
        }
    }
  }

  private var canPresentRelease: Bool {
    let arguments = ProcessInfo.processInfo.arguments
    return !arguments.contains("-ui-testing")
      && !arguments.contains("-aso-screenshots")
      && scenePhase == .active
      && sessionStage == .ready
      && appState.activeTab == .library
      && appState.activeEditorDocumentID == nil
      && appState.selectedDoc == nil
      && !appState.showVault
      && !appState.showCapture
      && !showAnalyticsConsent
      && !showSplash
      && releasePrompt == nil
  }

  private func presentReleaseIfNeeded() async {
    guard canPresentRelease else { return }
    do {
      // Let the startup and consent presentations finish transitioning.
      try await Task.sleep(for: .milliseconds(600))
      if AppRelease.hasUnseenNotes() {
        releasePrompt = .whatsNew
        return
      }

      guard Date.now >= nextAppStoreCheck else { return }
      let available = try await AppStoreUpdate.availableVersion()
      try Task.checkCancellation()
      nextAppStoreCheck = .now.addingTimeInterval(6 * 60 * 60)
      if let available, AppStoreUpdate.canRemind(about: available) {
        releasePrompt = .update(available)
      }
    } catch {
      guard !Task.isCancelled else { return }
      nextAppStoreCheck = .now.addingTimeInterval(15 * 60)
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
    premium.refreshTemporalAccess()

    guard newPhase == .active else {
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
      sessionStage == .ready
    else {
      return
    }
    showAnalyticsConsent = true
  }
}

private struct CaptureAccessBoundaryOverlay: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var premium = PremiumManager.shared
  @Environment(\.colorScheme) private var scheme
  @State private var showPlans = false

  private var isSpanish: Bool { appState.language == .es }

  private var canOpenPlans: Bool {
    switch premium.accessState {
    case .readOnlyRecovery, .mandatoryPaywall, .storageUnavailable, .verifying:
      true
    case .newUserNotice, .existingUserNotice, .temporaryFullAccess, .purchased:
      false
    }
  }

  private var boundaryMessage: String {
    switch premium.accessState {
    case .newUserNotice, .existingUserNotice:
      return isSpanish
        ? "La captura o importación en curso aún no se ha guardado. Vuelve a las opciones de acceso para leer el aviso antes de empezar. Si sales, este borrador se descartará; los archivos ya guardados no cambian."
        : "This capture or import has not been saved. Return to the access options and read the notice before starting. Leaving discards this draft; saved files are not changed."
    default:
      return isSpanish
        ? "La captura o importación en curso aún no se ha guardado. Puedes consultar los planes; si compras, continuarás aquí. Si vuelves a tus documentos, se descartará este borrador sin afectar a los archivos ya guardados."
        : "This capture or import has not been saved yet. You can review plans and continue here after purchase. Returning to your documents discards this draft but does not affect saved files."
    }
  }

  var body: some View {
    VStack(spacing: ShieldTheme.s4) {
      Image(systemName: "doc.text.magnifyingglass")
        .shieldFont(34, weight: .semibold)
        .foregroundStyle(ShieldTheme.accent(scheme))
        .accessibilityHidden(true)
      Text(isSpanish ? "Acceso temporalmente detenido" : "Temporary access paused")
        .shieldFont(24, weight: .heavy)
        .multilineTextAlignment(.center)
        .foregroundStyle(ShieldTheme.primary(scheme))
      Text(boundaryMessage)
        .shieldFont(15)
        .multilineTextAlignment(.center)
        .foregroundStyle(ShieldTheme.secondary(scheme))
        .fixedSize(horizontal: false, vertical: true)

      if canOpenPlans {
        Button(isSpanish ? "Ver Lifetime" : "View Lifetime") {
          showPlans = true
        }
        .buttonStyle(.borderedProminent)
        .tint(ShieldTheme.accent(scheme))
        .frame(minHeight: 48)
        .accessibilityIdentifier("access.captureBoundary.plans")
      }

      Button(isSpanish ? "Volver a mis documentos" : "Return to my documents") {
        appState.showCapture = false
      }
      .buttonStyle(.bordered)
      .frame(minHeight: 48)
      .accessibilityIdentifier("access.captureBoundary.recovery")
    }
    .padding(ShieldTheme.s5)
    .frame(maxWidth: 560)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ShieldTheme.pageBackground(scheme).ignoresSafeArea())
    .sheet(isPresented: $showPlans) {
      PaywallView(
        isPresented: $showPlans,
        trigger: .manual,
        isMandatoryAccess: true,
        onRecoverOwnData: { appState.showCapture = false }
      )
      .environmentObject(appState)
    }
  }
}

private struct AccessGateRootView: View {
  @EnvironmentObject private var appState: AppState
  @StateObject private var premium = PremiumManager.shared
  @State private var showRecovery = false
  @State private var showPlans = false
  @State private var selectedDocument: DocumentItem?
  @State private var documentToDelete: DocumentItem?
  @State private var showDeleteAllConfirmation = false
  @State private var showPrivacy = false
  @State private var showTerms = false
  @State private var showSubscriptionTerms = false
  @State private var showAppearance = false
  @State private var showVault = false
  @State private var accessStartFailed = false

  private var isSpanish: Bool { appState.language == .es }

  var body: some View {
    Group {
      switch premium.accessState {
      case .verifying:
        if showRecovery {
          recoveryScreen(until: nil, storageIssue: false, verificationIssue: true)
        } else {
          statusScreen(
            title: isSpanish ? "Comprobando el acceso" : "Checking access",
            detail: isSpanish
              ? "Estamos verificando las compras asociadas a tu cuenta. Tus documentos siguen en este dispositivo."
              : "We are checking purchases linked to your account. Your documents remain on this device."
          )
        }
      case .newUserNotice, .existingUserNotice:
        if showPlans {
          PaywallView(isPresented: $showPlans, trigger: .manual)
            .environmentObject(appState)
        } else {
          accessNotice
        }
      case .readOnlyRecovery(let until):
        if showPlans {
          PaywallView(
            isPresented: .constant(true),
            trigger: .manual,
            isMandatoryAccess: true,
            onRecoverOwnData: { showPlans = false }
          )
          .environmentObject(appState)
        } else {
          recoveryScreen(until: until, storageIssue: false)
        }
      case .mandatoryPaywall:
        if premium.isPro || premium.accessState.hasFullAccess {
          Color.clear
        } else if showRecovery {
          recoveryScreen(until: nil, storageIssue: false)
        } else {
          PaywallView(
            isPresented: .constant(true),
            trigger: .manual,
            isMandatoryAccess: true,
            onRecoverOwnData: { showRecovery = true }
          )
          .environmentObject(appState)
        }
      case .storageUnavailable:
        recoveryScreen(until: nil, storageIssue: true)
      case .temporaryFullAccess, .purchased:
        ProgressView(isSpanish ? "Abriendo MaskID…" : "Opening MaskID…")
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(ShieldTheme.pageBackground(appState.preferredScheme).ignoresSafeArea())
    .preferredColorScheme(appState.preferredScheme)
    .sheet(item: $selectedDocument) { document in
      EditorView(doc: document, isReadOnly: true)
        .environmentObject(appState)
    }
    .sheet(isPresented: $showPrivacy) {
      SettingsArticleView(article: .privacy)
        .environmentObject(appState)
    }
    .sheet(isPresented: $showTerms) {
      SettingsArticleView(article: .terms)
        .environmentObject(appState)
    }
    .sheet(isPresented: $showSubscriptionTerms) {
      SettingsArticleView(article: .subscriptionTerms)
        .environmentObject(appState)
    }
    .sheet(isPresented: $showAppearance) {
      AppPreferencesSettingsView()
        .environmentObject(appState)
    }
    .sheet(isPresented: $showVault) {
      NavigationStack {
        VaultView()
          .environmentObject(appState)
      }
    }
    .confirmationDialog(
      isSpanish ? "¿Eliminar este documento?" : "Delete this document?",
      isPresented: Binding(
        get: { documentToDelete != nil },
        set: { if !$0 { documentToDelete = nil } }
      ),
      titleVisibility: .visible
    ) {
      Button(isSpanish ? "Eliminar documento" : "Delete document", role: .destructive) {
        if let documentToDelete { appState.deleteDocument(documentToDelete) }
        documentToDelete = nil
      }
      Button(isSpanish ? "Cancelar" : "Cancel", role: .cancel) { documentToDelete = nil }
    }
    .confirmationDialog(
      isSpanish ? "¿Eliminar todos tus documentos?" : "Delete all your documents?",
      isPresented: $showDeleteAllConfirmation,
      titleVisibility: .visible
    ) {
      Button(isSpanish ? "Eliminar todos los datos" : "Delete all data", role: .destructive) {
        appState.deleteAllDocuments()
      }
      Button(isSpanish ? "Cancelar" : "Cancel", role: .cancel) {}
    } message: {
      Text(
        isSpanish
          ? "Esta acción elimina los documentos guardados en este dispositivo, incluidos los de la Bóveda."
          : "This removes documents saved on this device, including Vault documents.")
    }
    .task {
      await premium.updateProStatus()
    }
  }

  private var accessNotice: some View {
    ScrollView {
      VStack(spacing: ShieldTheme.s5) {
        MaskIDIdentityMark(size: 76, presentation: .staticMark, treatment: .compact)
          .accessibilityHidden(true)
        Text(noticeTitle)
          .shieldFont(28, weight: .heavy)
          .multilineTextAlignment(.center)
          .foregroundStyle(ShieldTheme.primary(appState.preferredScheme))
        Text(noticeBody)
          .shieldFont(16)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
          .foregroundStyle(ShieldTheme.secondary(appState.preferredScheme))

        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
          Label(noticeTermOne, systemImage: "clock")
          Label(noticeTermTwo, systemImage: "creditcard")
          Label(noticeTermThree, systemImage: "lock.shield")
        }
        .shieldFont(14, weight: .medium)
        .frame(maxWidth: 560, alignment: .leading)
        .padding(ShieldTheme.s4)
        .background(
          ShieldTheme.cardBackground(appState.preferredScheme),
          in: RoundedRectangle(cornerRadius: 18))

        if accessStartFailed {
          Text(
            isSpanish
              ? "No se pudo guardar el inicio del periodo en el dispositivo. No se ha iniciado ningún periodo. Inténtalo de nuevo."
              : "The access start could not be saved on this device. No period has started. Please try again."
          )
          .font(.footnote)
          .foregroundStyle(ShieldTheme.warning)
          .multilineTextAlignment(.center)
          .accessibilityAddTraits(.isStaticText)
        }

        Button {
          accessStartFailed = !premium.startTemporaryAccess()
        } label: {
          Text(startButtonTitle)
            .font(.headline)
            .frame(maxWidth: 560, minHeight: 52)
        }
        .buttonStyle(.borderedProminent)
        .tint(ShieldTheme.accent(appState.preferredScheme))
        .accessibilityIdentifier("access.notice.start")

        Button(isSpanish ? "Ver Lifetime y su precio" : "View Lifetime and price") {
          showPlans = true
        }
        .font(.subheadline.weight(.semibold))
        .frame(minHeight: 44)
        .accessibilityIdentifier("access.notice.plans")

        Button(isSpanish ? "Consultar o exportar mis documentos" : "View or export my documents") {
          showRecovery = true
        }
        .font(.subheadline.weight(.semibold))
        .frame(minHeight: 44)
        .accessibilityIdentifier("access.notice.recovery")

        legalActions
      }
      .frame(maxWidth: 600)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, ShieldTheme.s5)
      .padding(.vertical, ShieldTheme.s6)
    }
  }

  private var noticeTitle: String {
    isSpanish ? "Acceso temporal a MaskID Premium" : "Temporary MaskID Premium access"
  }

  private var noticeBody: String {
    isSpanish
      ? "Activa 15 días naturales de acceso Premium completo, sin tarjeta, suscripción ni cargos automáticos. Después podrás comprar MaskID Lifetime para continuar usando las funciones Premium; tus documentos seguirán disponibles para consultarlos, exportarlos o eliminarlos."
      : "Activate 15 calendar days of full Premium access with no card, subscription, or automatic charge. Afterward, you can buy MaskID Lifetime to continue using Premium features; your documents remain available to view, export, or delete."
  }

  private var noticeTermOne: String {
    isSpanish ? "15 días naturales desde que lo activas" : "15 calendar days from activation"
  }

  private var noticeTermTwo: String {
    isSpanish
      ? "No hay renovación automática ni cargo al terminar"
      : "No automatic renewal or charge when this period ends"
  }

  private var noticeTermThree: String {
    isSpanish
      ? "Tus documentos se conservan; las compras previas mantienen su acceso"
      : "Your documents are preserved; previous purchases keep their access"
  }

  private var startButtonTitle: String {
    isSpanish ? "Comenzar 15 días" : "Start 15 days"
  }

  private func statusScreen(title: String, detail: String) -> some View {
    VStack(spacing: ShieldTheme.s4) {
      ProgressView()
      Text(title).shieldFont(22, weight: .bold)
        .foregroundStyle(ShieldTheme.primary(appState.preferredScheme))
      Text(detail).shieldFont(15)
        .multilineTextAlignment(.center)
        .foregroundStyle(ShieldTheme.secondary(appState.preferredScheme))
        .fixedSize(horizontal: false, vertical: true)
      Button(isSpanish ? "Restaurar compras" : "Restore purchases") {
        Task { await premium.restore() }
      }
      .frame(minHeight: 44)
      Button(isSpanish ? "Consultar o exportar mis documentos" : "View or export my documents") {
        showRecovery = true
      }
      .frame(minHeight: 44)
      legalActions
    }
    .padding(ShieldTheme.s5)
    .frame(maxWidth: 560)
  }

  private func recoveryScreen(
    until: Date?,
    storageIssue: Bool,
    verificationIssue: Bool = false
  ) -> some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: ShieldTheme.s4) {
          Text(isSpanish ? "Recuperación de tus datos" : "Recover your data")
            .shieldFont(26, weight: .heavy)
            .foregroundStyle(ShieldTheme.primary(appState.preferredScheme))
          Text(
            recoveryMessage(
              until: until,
              storageIssue: storageIssue,
              verificationIssue: verificationIssue
            )
          )
          .shieldFont(15)
          .foregroundStyle(ShieldTheme.secondary(appState.preferredScheme))
          .fixedSize(horizontal: false, vertical: true)

          if recoveryDocuments.isEmpty {
            ContentUnavailableView(
              appState.vaultDocuments.isEmpty
                ? (isSpanish ? "No hay documentos guardados" : "No saved documents")
                : (isSpanish ? "Tus documentos están en la Bóveda" : "Your documents are in Vault"),
              systemImage: appState.vaultDocuments.isEmpty
                ? "doc.text.magnifyingglass"
                : "lock.shield",
              description: Text(
                appState.vaultDocuments.isEmpty
                  ? (isSpanish
                    ? "Los documentos locales siguen conservados mientras no los elimines."
                    : "Local documents remain preserved unless you delete them.")
                  : (isSpanish
                    ? "Desbloquea la Bóveda para consultarlos y exportarlos."
                    : "Unlock Vault to view and export them."))
            )
          } else {
            ForEach(recoveryDocuments) { document in
              HStack(spacing: ShieldTheme.s3) {
                VStack(alignment: .leading, spacing: 4) {
                  Text(document.title)
                    .font(.headline)
                    .foregroundStyle(ShieldTheme.primary(appState.preferredScheme))
                    .lineLimit(2)
                  Text(
                    "\(document.category.label(lang: appState.language)) · \(document.pageCount) \(isSpanish ? "pág." : "pages")"
                  )
                  .font(.caption)
                  .foregroundStyle(ShieldTheme.secondary(appState.preferredScheme))
                }
                Spacer(minLength: 4)
                Button {
                  selectedDocument = document
                } label: {
                  Label(
                    isSpanish ? "Ver y exportar" : "View and export",
                    systemImage: "square.and.arrow.up"
                  )
                  .labelStyle(.iconOnly)
                  .frame(width: 44, height: 44)
                }
                .accessibilityLabel(
                  isSpanish
                    ? "Ver y exportar \(document.title)"
                    : "View and export \(document.title)"
                )
                .accessibilityIdentifier("access.recovery.open.\(document.id)")
                Button(role: .destructive) {
                  documentToDelete = document
                } label: {
                  Image(systemName: "trash")
                    .frame(width: 44, height: 44)
                }
                .accessibilityLabel(
                  isSpanish
                    ? "Eliminar \(document.title)"
                    : "Delete \(document.title)")
              }
              .padding(ShieldTheme.s3)
              .background(
                ShieldTheme.cardBackground(appState.preferredScheme),
                in: RoundedRectangle(cornerRadius: 16))
            }
          }

          if !appState.vaultDocuments.isEmpty {
            Button {
              showVault = true
            } label: {
              Label(
                isSpanish
                  ? "Desbloquear Bóveda (\(appState.vaultDocuments.count))"
                  : "Unlock Vault (\(appState.vaultDocuments.count))",
                systemImage: "lock.shield"
              )
              .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("access.recovery.vault")
          }

          if !appState.documents.isEmpty {
            Button(role: .destructive) {
              showDeleteAllConfirmation = true
            } label: {
              Label(
                isSpanish ? "Eliminar todos los documentos" : "Delete all documents",
                systemImage: "trash.slash"
              )
              .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
          }
        }
        .frame(maxWidth: 700, alignment: .leading)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.top, ShieldTheme.s5)
        .padding(.bottom, ShieldTheme.s4)
      }

      VStack(spacing: ShieldTheme.s2) {
        HStack(spacing: ShieldTheme.s3) {
          Button(isSpanish ? "Restaurar compras" : "Restore purchases") {
            Task { await premium.restore() }
          }
          .disabled(premium.isRestoring)
          Button(isSpanish ? "Gestionar suscripción" : "Manage subscription") {
            Task { await SubscriptionLifecycleObserver.shared.showManageSubscriptions() }
          }
        }
        HStack(spacing: ShieldTheme.s3) {
          Button(isSpanish ? "Apariencia" : "Appearance") { showAppearance = true }
          Button(isSpanish ? "Privacidad" : "Privacy") { showPrivacy = true }
          Button(isSpanish ? "Términos" : "Terms") { showTerms = true }
          Button(isSpanish ? "Condiciones de compra" : "Purchase terms") {
            showSubscriptionTerms = true
          }
        }
        ShieldPublicPageButton(page: .support, language: appState.language, compact: true)
        if case .mandatoryPaywall = premium.accessState, showRecovery {
          Button(isSpanish ? "Volver a Lifetime" : "Back to Lifetime") {
            showRecovery = false
          }
          .font(.subheadline.weight(.semibold))
          .frame(minHeight: 44)
        }
        if case .readOnlyRecovery = premium.accessState, !storageIssue {
          Button(isSpanish ? "Ver MaskID Lifetime" : "See MaskID Lifetime") {
            showPlans = true
          }
          .font(.subheadline.weight(.semibold))
          .frame(minHeight: 44)
        }
        if canReturnToNotice {
          Button(isSpanish ? "Volver al aviso de acceso" : "Back to access options") {
            showRecovery = false
          }
          .font(.subheadline.weight(.semibold))
          .frame(minHeight: 44)
        }
        if showPlans {
          Button(isSpanish ? "Volver a mis documentos" : "Back to my documents") {
            showPlans = false
          }
          .font(.subheadline.weight(.semibold))
          .frame(minHeight: 44)
        }
      }
      .font(.footnote.weight(.semibold))
      .buttonStyle(.plain)
      .frame(maxWidth: 700)
      .padding(.horizontal, ShieldTheme.s3)
      .padding(.top, ShieldTheme.s2)
      .padding(.bottom, ShieldTheme.s3)
      .background(ShieldTheme.cardBackground(appState.preferredScheme))
    }
  }

  private func recoveryMessage(
    until: Date?,
    storageIssue: Bool,
    verificationIssue: Bool
  ) -> String {
    if verificationIssue {
      return isSpanish
        ? "La verificación de compras no está disponible ahora. Tus documentos siguen accesibles en solo lectura; puedes exportarlos, restaurar compras o volver a intentar la verificación."
        : "Purchase verification is unavailable right now. Your documents remain available in read-only mode; you can export them, restore purchases, or retry verification."
    }
    if storageIssue {
      return isSpanish
        ? "No se pudo leer el registro local de acceso. No se ha creado un periodo nuevo. Puedes restaurar una compra o consultar, exportar y eliminar tus documentos guardados."
        : "The local access record could not be read. No new period was created. You can restore a purchase or view, export, and delete saved documents."
    }
    if let until {
      let date = until.formatted(date: .long, time: .shortened)
      return isSpanish
        ? "MaskID está en solo lectura. Puedes abrir y exportar tus documentos hasta el \(date). No se modifican ni eliminan automáticamente."
        : "MaskID is in read-only mode. You can open and export your documents until \(date). They are not changed or deleted automatically."
    }
    return isSpanish
      ? "El acceso a las funciones comerciales ha terminado. Puedes seguir accediendo a tus propios documentos para consultarlos, exportarlos o eliminarlos."
      : "Commercial access has ended. You can still access your own documents to view, export, or delete them."
  }

  private var recoveryDocuments: [DocumentItem] {
    appState.documents.filter { !$0.isVaulted }
  }

  private var legalActions: some View {
    HStack(spacing: ShieldTheme.s3) {
      Button(isSpanish ? "Privacidad" : "Privacy") { showPrivacy = true }
      Button(isSpanish ? "Términos" : "Terms") { showTerms = true }
      Button(isSpanish ? "Condiciones de compra" : "Purchase terms") {
        showSubscriptionTerms = true
      }
      ShieldPublicPageButton(page: .support, language: appState.language, compact: true)
    }
    .font(.footnote.weight(.semibold))
    .buttonStyle(.plain)
  }

  private var canReturnToNotice: Bool {
    switch premium.accessState {
    case .verifying, .newUserNotice, .existingUserNotice:
      true
    default:
      false
    }
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
          Color(hex: "01050A"),
        ],
        center: .center,
        startRadius: 20,
        endRadius: 420
      )
      .ignoresSafeArea()

      VStack(spacing: ShieldTheme.s4) {
        MaskIDIdentityMark(
          size: 200,
          presentation: .staticMark,
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
        let doc = appState.selectedDoc
      {
        EditorView(doc: doc)
          .id(doc.id)
          .transition(.move(edge: .trailing))
          .zIndex(60)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: appState.showCapture)
    .animation(
      reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.88),
      value: appState.selectedDoc?.id
    )
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
    TabView(
      selection: Binding(
        get: { appState.activeTab },
        set: { newTab in
          guard newTab != appState.activeTab else { return }
          withAnimation(reduceMotion ? nil : ShieldMotion.press) {
            appState.activeTab = newTab
          }
        }
      )
    ) {
      Tab(value: AppTab.library) {
        NavigationStack {
          HomeView(onScanTap: openCapture)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
      } label: {
        Label(AppTab.library.label(lang: appState.language), systemImage: AppTab.library.icon)
          .accessibilityIdentifier("tab.\(AppTab.library.rawValue)")
      }

      Tab(value: AppTab.gallery) {
        NavigationStack {
          StyleGalleryView()
            .toolbarBackground(.hidden, for: .navigationBar)
        }
      } label: {
        Label(AppTab.gallery.label(lang: appState.language), systemImage: AppTab.gallery.icon)
          .accessibilityIdentifier("tab.\(AppTab.gallery.rawValue)")
      }

      if #available(iOS 27.0, *) {
        Tab(value: AppTab.vault, role: .prominent) {
          VaultView()
        } label: {
          Label(AppTab.vault.label(lang: appState.language), systemImage: AppTab.vault.icon)
            .accessibilityIdentifier("tab.\(AppTab.vault.rawValue)")
        }
      } else {
        Tab(value: AppTab.vault) {
          VaultView()
        } label: {
          Label(AppTab.vault.label(lang: appState.language), systemImage: AppTab.vault.icon)
            .accessibilityIdentifier("tab.\(AppTab.vault.rawValue)")
        }
      }
    }
    .tabViewStyle(.sidebarAdaptable)
    .tint(ShieldTheme.accent(appState.preferredScheme))
    .defaultAdaptableTabBarPlacement(.sidebar)
    .sheet(
      isPresented: Binding(
        get: { appState.activeTab == .settings },
        set: { if !$0 { appState.activeTab = .library } }
      )
    ) {
      NavigationStack {
        SettingsView(onClose: {
          appState.activeTab = .library
        })
      }
      .preferredColorScheme(appState.preferredScheme)
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
