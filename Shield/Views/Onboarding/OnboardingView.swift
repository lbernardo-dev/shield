import LocalAuthentication
import SwiftUI

// MARK: - LockScreenView

struct LockScreenView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.scenePhase) private var scenePhase
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
            // Background
            Color(hex: "0a0a0f").ignoresSafeArea()

            // Subtle radial glow behind icon
            RadialGradient(
                colors: [Color(hex: "FFD60A").opacity(0.07), Color.clear],
                center: .center,
                startRadius: 60,
                endRadius: 300
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // App icon area
                VStack(spacing: 20) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 32)
                            .fill(Color(hex: "FFD60A").opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .stroke(Color(hex: "FFD60A").opacity(0.25), lineWidth: 1)
                            )
                            .frame(width: 120, height: 120)

                        Image(systemName: verified ? "checkmark.shield.fill" : "shield.fill")
                            .font(.system(size: 54, weight: .medium))
                            .foregroundColor(verified ? ShieldTheme.success : ShieldTheme.accent)
                            .symbolEffect(.pulse, isActive: isAuthenticating)
                            .contentTransition(.symbolEffect(.replace))
                    }

                    VStack(spacing: 6) {
                        Text("Shield")
                            .font(.system(size: 28, weight: .heavy, design: .default))
                            .foregroundColor(ShieldTheme.textPrimary)
                            .tracking(-0.5)

                        Text(LanguageManager.shared.auth("lock_subtitle"))
                            .font(.system(size: 13))
                            .foregroundColor(ShieldTheme.textTertiary)
                    }
                }

                Spacer().frame(height: 60)

                // Status / error
                Group {
                    if let err = authError {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                            Text(err)
                                .font(.system(size: 13))
                        }
                        .foregroundColor(ShieldTheme.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    } else {
                        Text(isAuthenticating
                             ? LanguageManager.shared.auth("lock_verifying")
                             : LanguageManager.shared.auth("lock_unlock_to_continue"))
                            .font(.system(size: 13))
                            .foregroundColor(ShieldTheme.textTertiary)
                    }
                }
                .frame(minHeight: 36)

                Spacer().frame(height: 24)

                // Buttons
                VStack(spacing: 12) {
                    // Primary unlock button
                    if biometricEnabled && hasBiometrics {
                        if PINManager.hasPIN {
                            Button { authenticate() } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "faceid")
                                        .font(.system(size: 18, weight: .medium))
                                    Text(LanguageManager.shared.auth("lock_unlock_faceid"))
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(ShieldTheme.accent)
                                .foregroundColor(ShieldTheme.accentText)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .disabled(isAuthenticating)
                        } else {
                            Button { showPINSetup = true } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "number.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                    Text(LanguageManager.shared.auth("lock_set_pin_continue"))
                                        .font(.system(size: 16, weight: .bold))
                                }
                                .frame(maxWidth: .infinity).frame(height: 54)
                                .background(ShieldTheme.accent)
                                .foregroundColor(ShieldTheme.accentText)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    } else if PINManager.hasPIN {
                        Button { showPINEntry = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "lock.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                Text(LanguageManager.shared.auth("lock_unlock_pin"))
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(ShieldTheme.accent)
                            .foregroundColor(ShieldTheme.accentText)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    } else {
                        Button { authenticatePasscode() } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "lock.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                Text(LanguageManager.shared.auth("lock_unlock_generic"))
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(ShieldTheme.accent)
                            .foregroundColor(ShieldTheme.accentText)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(isAuthenticating)
                    }

                    // Always-visible code option in the same lock screen
                    if PINManager.hasPIN {
                        Button { showPINEntry = true } label: {
                            Text(LanguageManager.shared.auth("lock_use_pin"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ShieldTheme.textSecondary)
                                .frame(height: 44)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    } else {
                        Button { showPINSetup = true } label: {
                            Text(LanguageManager.shared.auth("lock_setup_pin"))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(ShieldTheme.textSecondary)
                                .frame(height: 44)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    if biometricEnabled && hasBiometrics && authError != nil {
                        Button { authenticatePasscode() } label: {
                            Text(LanguageManager.shared.auth("lock_use_passcode"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ShieldTheme.textTertiary)
                                .frame(height: 36)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 28)

                Spacer().frame(height: 60)
            }
        }
        .preferredColorScheme(.dark)
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
