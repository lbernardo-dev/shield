import LocalAuthentication
import SwiftUI

// MARK: - LockScreenView

struct LockScreenView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isAuthenticating = false
    @State private var verified = false
    @State private var authError: String? = nil
    @State private var showPINEntry = false
    @State private var showPINSetup = false
    @State private var didTriggerAutoBiometric = false

    private var biometricEnabled: Bool {
        UserDefaults.standard.bool(forKey: "shield.biometric")
    }

    private var hasBiometrics: Bool {
        let ctx = LAContext()
        var err: NSError?
        return ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    var body: some View {
        ZStack {
            lockBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                lockHeader
                    .padding(.horizontal, ShieldTheme.s5)
                    .padding(.top, ShieldTheme.topChromePadding)

                Spacer(minLength: ShieldTheme.s4)

                VStack(spacing: ShieldTheme.s5) {
                    // Center Avatar with Integrated Scanning Sheen & Ambient Halo
                    identityMark(size: 200)

                    // Title & Description
                    VStack(spacing: ShieldTheme.s2) {
                        Text(LanguageManager.shared.auth("lock_access_title"))
                            .shieldFont(24, weight: .heavy, design: .rounded)
                            .foregroundStyle(ShieldTheme.primary(scheme))
                            .multilineTextAlignment(.center)

                        Text(LanguageManager.shared.auth("lock_verify_subtitle"))
                            .shieldFont(14, weight: .medium)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, ShieldTheme.s4)
                    }

                    // Status Pill / Error Message
                    lockStatus
                }
                .frame(maxWidth: 480)

                Spacer(minLength: ShieldTheme.s4)

                // Actions directly below
                lockActions
                    .padding(.horizontal, ShieldTheme.s5)
                    .padding(.bottom, ShieldTheme.s6)
            }
        }
        .preferredColorScheme(appState.preferredScheme)
        .fullScreenCover(isPresented: $showPINEntry) {
            PINEntryView(isPresented: $showPINEntry) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.completeSuccessfulUnlock()
                }
            }.environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showPINSetup) {
            PINSetupView(isPresented: $showPINSetup) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.completeSuccessfulUnlock()
                }
            }.environmentObject(appState)
        }
        .onAppear {
            autoPromptIfNeeded()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                autoPromptIfNeeded()
            }
        }
    }

    private var lockHeader: some View {
        HStack(spacing: ShieldTheme.s3) {
            Text(LanguageManager.shared.common("common_app_name"))
                .shieldFont(20, weight: .heavy)
                .foregroundStyle(ShieldTheme.primary(scheme))

            Spacer(minLength: ShieldTheme.s2)

            Label(
                LanguageManager.shared.auth("lock_protection_active"),
                systemImage: "lock.shield.fill"
            )
            .shieldFont(12, weight: .bold)
            .foregroundStyle(Color(hex: "00E5FF"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "00B4D8").opacity(0.16), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: "00B4D8").opacity(0.35), lineWidth: 0.8)
            )
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: 560)
    }

    private func identityMark(size: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            MaskIDIdentityMark(
                size: size,
                presentation: .animatedLoop,
                treatment: .hero,
                isEmphasized: isAuthenticating
            )

            if verified {
                Image(systemName: "checkmark.circle.fill")
                    .shieldFont(28, weight: .bold)
                    .foregroundStyle(ShieldTheme.success, ShieldTheme.cardBackground(scheme))
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
            }
        }
    }

    private var lockStatus: some View {
        HStack(alignment: .center, spacing: ShieldTheme.s2) {
            if isAuthenticating {
                ProgressView()
                    .controlSize(.small)
                    .tint(ShieldTheme.accentColor(scheme))
                    .accessibilityHidden(true)
            } else {
                Image(systemName: authError == nil ? lockStatusIcon : "exclamationmark.triangle.fill")
                    .accessibilityHidden(true)
            }

            Text(authError ?? lockStatusMessage)
                .shieldFont(12, weight: .semibold)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(authError == nil ? ShieldTheme.secondary(scheme) : ShieldTheme.danger)
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.vertical, 8)
        .background(
            authError == nil
                ? ShieldTheme.cardBackground(scheme).opacity(0.85)
                : ShieldTheme.errorBackground(scheme),
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(authError == nil ? ShieldTheme.line(scheme) : ShieldTheme.danger.opacity(0.4), lineWidth: 0.8)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("lock.status")
    }

    private var lockActions: some View {
        VStack(spacing: ShieldTheme.s3) {
            primaryUnlockButton

            if showsSecondaryPINButton {
                ShieldButton(
                    label: LanguageManager.shared.auth("lock_use_pin"),
                    icon: "number",
                    style: .secondary,
                    height: 50
                ) {
                    showPINEntry = true
                }
                .accessibilityIdentifier("lock.secondaryPIN")
            }

            if biometricEnabled && hasBiometrics && authError != nil {
                Button {
                    authenticate()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "faceid")
                        Text(LanguageManager.shared.auth("lock_unlock_faceid"))
                    }
                    .shieldFont(13, weight: .bold)
                    .foregroundStyle(ShieldTheme.accentColor(scheme))
                    .padding(.vertical, 6)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(maxWidth: 480)
    }

    @ViewBuilder
    private var primaryUnlockButton: some View {
        ShieldButton(
            label: primaryUnlockTitle,
            icon: primaryUnlockIcon,
            height: 54,
            isLoading: isAuthenticating,
            action: primaryUnlockAction
        )
        .disabled(isAuthenticating)
        .accessibilityIdentifier("lock.primaryUnlock")
    }

    private var primaryUnlockTitle: String {
        if biometricEnabled && hasBiometrics && PINManager.hasPIN {
            return LanguageManager.shared.auth("lock_unlock_faceid")
        }
        if PINManager.hasPIN {
            return LanguageManager.shared.auth("lock_unlock_pin")
        }
        return LanguageManager.shared.auth("lock_set_pin_continue")
    }

    private var primaryUnlockIcon: String {
        if biometricEnabled && hasBiometrics && PINManager.hasPIN {
            return "faceid"
        }
        if PINManager.hasPIN {
            return "number.square.fill"
        }
        return "key.fill"
    }

    private func primaryUnlockAction() {
        if biometricEnabled && hasBiometrics && PINManager.hasPIN {
            authenticate()
            return
        }
        if PINManager.hasPIN {
            showPINEntry = true
            return
        }
        showPINSetup = true
    }

    private var showsSecondaryPINButton: Bool {
        biometricEnabled && hasBiometrics && PINManager.hasPIN
    }

    private var lockStatusIcon: String {
        if isAuthenticating {
            return "faceid"
        }
        if PINManager.hasPIN {
            return biometricEnabled && hasBiometrics ? "lock.shield.fill" : "number.square.fill"
        }
        return "key.horizontal.fill"
    }

    private var lockStatusMessage: String {
        if isAuthenticating {
            return LanguageManager.shared.auth("lock_verifying")
        }
        if PINManager.hasPIN {
            return LanguageManager.shared.auth(
                biometricEnabled && hasBiometrics ? "lock_ready_faceid" : "lock_ready_pin"
            )
        }
        return LanguageManager.shared.auth("lock_setup_passcode_message")
    }

    private var lockBackground: some View {
        ZStack {
            if scheme == .dark {
                RadialGradient(
                    colors: [
                        Color(hex: "071E36"),
                        Color(hex: "030E1B"),
                        Color(hex: "01050A")
                    ],
                    center: .center,
                    startRadius: 30,
                    endRadius: 460
                )
            } else {
                RadialGradient(
                    colors: [
                        Color(hex: "E0F2FE"),
                        Color(hex: "F0F7FF"),
                        Color(hex: "FFFFFF")
                    ],
                    center: .center,
                    startRadius: 30,
                    endRadius: 460
                )
            }
        }
    }

    private func authenticate() {
        guard !isAuthenticating, !appState.isAuthenticated else { return }
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            authError = LanguageManager.shared.auth("lock_faceid_unavailable")
            return
        }
        isAuthenticating = true
        authError = nil
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: LanguageManager.shared.auth("lock_reason")
        ) { success, evalErr in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    verified = true
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.completeSuccessfulUnlock()
                    }
                } else {
                    authError = evalErr?.localizedDescription
                }
            }
        }
    }

    private func autoPromptIfNeeded() {
#if DEBUG
        guard !ASOScreenshotMode.isEnabled else { return }
#endif
        guard !didTriggerAutoBiometric else { return }
        guard !appState.isAuthenticated else { return }
        guard scenePhase == .active else { return }
        guard biometricEnabled, hasBiometrics, PINManager.hasPIN else { return }
        guard !showPINEntry, !showPINSetup, !isAuthenticating else { return }

        didTriggerAutoBiometric = true
        Task {
            // Give the lock UI time to settle before presenting Face ID.
            try? await Task.sleep(nanoseconds: 350_000_000)
            if !appState.isAuthenticated, scenePhase == .active, !isAuthenticating {
                authenticate()
            }
        }
    }
}
