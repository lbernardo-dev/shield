import LocalAuthentication
import SwiftUI

// MARK: - LockScreenView

struct LockScreenView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme
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
                Spacer()

                VStack(spacing: 22) {
                    ZStack(alignment: .bottomTrailing) {
                        Image("MaskIDMark")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 122, height: 122)
                            .clipShape(.rect(cornerRadius: 34))
                            .overlay(
                                RoundedRectangle(cornerRadius: 34)
                                    .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 1)
                            )
                            .symbolEffect(.pulse, isActive: isAuthenticating)
                            .accessibilityHidden(true)

                        if verified {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundStyle(ShieldTheme.success, ShieldTheme.cardBackground(scheme))
                                .contentTransition(.symbolEffect(.replace))
                                .accessibilityHidden(true)
                        }
                    }

                    VStack(spacing: 10) {
                        Text(LanguageManager.shared.common("common_app_name"))
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(ShieldTheme.primary(scheme))
                            .tracking(-0.8)

                        Text(lockSubtitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 26)
                    }

                    Group {
                        if let err = authError {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .accessibilityHidden(true)
                                Text(err)
                                    .lineLimit(3)
                            }
                            .foregroundColor(ShieldTheme.danger)
                        } else {
                            HStack(spacing: 8) {
                                Image(systemName: lockStatusIcon)
                                    .accessibilityHidden(true)
                                Text(lockStatusMessage)
                            }
                            .foregroundColor(ShieldTheme.secondary(scheme))
                        }
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(ShieldTheme.cardBackground(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    HStack(spacing: 10) {
                        lockFeaturePill(icon: "iphone.gen3.radiowaves.left.and.right", label: lockPillOnDevice)
                        lockFeaturePill(icon: "key.fill", label: lockPillEncrypted)
                        lockFeaturePill(icon: "eye.slash.fill", label: lockPillPrivate)
                    }

                    VStack(spacing: 12) {
                        primaryUnlockButton

                        if showsSecondaryPINButton {
                            Button { showPINEntry = true } label: {
                                Text(LanguageManager.shared.auth("lock_use_pin"))
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(ShieldTheme.secondary(scheme))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 46)
                                    .background(ShieldTheme.cardBackground(scheme))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }

                        if biometricEnabled && hasBiometrics && authError != nil {
                            Button { authenticatePasscode() } label: {
                                Text(LanguageManager.shared.auth("lock_use_passcode"))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(ShieldTheme.tertiary(scheme))
                                    .frame(height: 34)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }

                        if let actionHint = lockActionHint {
                            Text(actionHint)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(ShieldTheme.tertiary(scheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                        }
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 44)
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

    private var lockSubtitle: String {
        LanguageManager.shared.auth("lock_verify_subtitle")
    }

    private var lockPillOnDevice: String {
        LanguageManager.shared.home("home_on_device")
    }

    private var lockPillEncrypted: String {
        LanguageManager.shared.auth("lock_pill_encrypted")
    }

    private var lockPillPrivate: String {
        LanguageManager.shared.auth("lock_pill_private")
    }

    private var showsSecondaryPINButton: Bool {
        biometricEnabled && hasBiometrics && PINManager.hasPIN
    }

    private var lockStatusIcon: String {
        if isAuthenticating {
            return "faceid"
        }
        if PINManager.hasPIN {
            return biometricEnabled && hasBiometrics ? "lock.badge.shield" : "number"
        }
        return "key.horizontal.fill"
    }

    private var lockStatusMessage: String {
        if isAuthenticating {
            return LanguageManager.shared.auth("lock_verifying")
        }
        if PINManager.hasPIN {
            return LanguageManager.shared.auth("lock_unlock_to_continue")
        }
        return LanguageManager.shared.auth("lock_setup_passcode_message")
    }

    private var lockActionHint: String? {
        guard !PINManager.hasPIN else { return nil }
        return LanguageManager.shared.auth("lock_passcode_hint")
    }

    @ViewBuilder
    private var primaryUnlockButton: some View {
        Button(action: primaryUnlockAction) {
            HStack(spacing: 10) {
                Image(systemName: primaryUnlockIcon)
                    .font(.system(size: 18, weight: .medium))
                    .accessibilityHidden(true)
                Text(primaryUnlockTitle)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(ShieldTheme.accent(scheme))
            .foregroundColor(ShieldTheme.accentText)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isAuthenticating)
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
            return "lock.circle.fill"
        }
        return "number.circle.fill"
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

    private func lockFeaturePill(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .accessibilityHidden(true)
            Text(label)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(ShieldTheme.secondary(scheme))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(ShieldTheme.cardBackground(scheme))
        .overlay(
            Capsule().stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
        )
        .clipShape(Capsule())
    }

    private var lockBackground: some View {
        ZStack {
            LinearGradient(
                colors: scheme == .dark
                    ? [Color(hex: "09090d"), Color(hex: "11111a"), Color(hex: "09090d")]
                    : [Color(hex: "FFFCEF"), ShieldTheme.pageBackground(scheme), Color(hex: "F3F4FA")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [ShieldTheme.accentDim(scheme), Color.clear],
                center: .top,
                startRadius: 20,
                endRadius: 320
            )
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

    private func authenticatePasscode() {
        guard !isAuthenticating, !appState.isAuthenticated else { return }
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else {
            if PINManager.hasPIN {
                showPINEntry = true
            } else {
                authError = LanguageManager.shared.auth("lock_system_auth_unavailable")
            }
            return
        }
        isAuthenticating = true
        authError = nil
        ctx.evaluatePolicy(
            .deviceOwnerAuthentication,
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
