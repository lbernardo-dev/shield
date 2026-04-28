import LocalAuthentication
import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var step: Int = 0

    struct Slide {
        let icon: String
        let titleKey: L10nKey
        let subtitleKey: L10nKey
        let bullets: [(icon: String, text: String)]
        var isAuth: Bool = false
    }

    var slides: [Slide] {
        let lang = appState.language
        return [
            Slide(
                icon: "checkmark.shield.fill",
                titleKey: .welcome,
                subtitleKey: .welcomeSub,
                bullets: [
                    ("eye.slash.fill",    lang == .es ? "Oculta datos sensibles" : "Hide sensitive data"),
                    ("sparkles",          lang == .es ? "Detección automática"   : "Automatic detection"),
                    ("lock.fill",         lang == .es ? "Procesado en el dispositivo" : "Processed on-device"),
                ]
            ),
            Slide(
                icon: "lock.fill",
                titleKey: .privacyTitle,
                subtitleKey: .privacySub,
                bullets: [
                    ("shield.fill",      lang == .es ? "Sin servidores ni nube"      : "No servers, no cloud"),
                    ("wifi.slash",       lang == .es ? "Sin conexión a internet"     : "No internet required"),
                    ("checkmark.circle", lang == .es ? "Tú controlas la exportación" : "You control sharing"),
                ]
            ),
            Slide(
                icon: "faceid",
                titleKey: .setupSecurity,
                subtitleKey: .setupSecuritySub,
                bullets: [],
                isAuth: true
            ),
        ]
    }

    var body: some View {
        ZStack {
            // Background
            RadialGradient(
                colors: [Color(hex: "1a1a22"), ShieldTheme.surface1],
                center: .top,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer().frame(height: 20)

                // Progress dots
                ShieldProgressDots(count: slides.count, current: step)
                    .padding(.bottom, 40)

                // Slide content
                let slide = slides[step]

                // Hero icon
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(ShieldTheme.accentDim)
                        .frame(width: 96, height: 96)
                    Image(systemName: slide.icon)
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(ShieldTheme.accent)
                }
                .symbolEffect(.pulse, isActive: true)
                .padding(.bottom, 32)

                // Title + subtitle
                VStack(spacing: 12) {
                    Text(appState.str(slide.titleKey))
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(ShieldTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .tracking(-0.6)

                    Text(appState.str(slide.subtitleKey))
                        .font(.system(size: 15))
                        .foregroundColor(ShieldTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                }

                // Bullets
                if !slide.bullets.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(slide.bullets, id: \.text) { bullet in
                            BulletRow(icon: bullet.icon, text: bullet.text)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }

                // Auth step
                if slide.isAuth {
                    VStack(spacing: 10) {
                        Button {
                            finishOnboarding()
                        } label: {
                            Label(appState.str(.enableFaceId), systemImage: "faceid")
                                .font(.system(size: 16, weight: .bold))
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(ShieldTheme.accent)
                                .foregroundColor(ShieldTheme.accentText)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(ScaleButtonStyle())

                        Button {
                            finishOnboarding()
                        } label: {
                            Text(appState.str(.setPin))
                                .font(.system(size: 15))
                                .foregroundColor(ShieldTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                }

                Spacer()

                // CTA
                if !slide.isAuth {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            step += 1
                        }
                    } label: {
                        Text(appState.str(.continueBtn))
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(ShieldTheme.accent)
                            .foregroundColor(ShieldTheme.accentText)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func finishOnboarding() {
        withAnimation {
            appState.isOnboarded = true
            appState.isAuthenticated = true
        }
    }
}

// MARK: - BulletRow

private struct BulletRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ShieldTheme.accentDim)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ShieldTheme.accent)
            }
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ShieldTheme.textPrimary)
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(ShieldTheme.surface2)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(ShieldTheme.surfaceLine, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - LockScreenView

struct LockScreenView: View {
    @EnvironmentObject var appState: AppState
    @State private var isAuthenticating = false
    @State private var verified = false
    @State private var authError: String? = nil
    @State private var showPINEntry = false

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

                        Text(appState.language == .es
                             ? "Tus documentos protegidos"
                             : "Your documents protected")
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
                             ? (appState.language == .es ? "Verificando…" : "Verifying…")
                             : (appState.language == .es ? "Desbloquea para continuar" : "Unlock to continue"))
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
                        Button { authenticate() } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "faceid")
                                    .font(.system(size: 18, weight: .medium))
                                Text(appState.language == .es ? "Desbloquear con Face ID" : "Unlock with Face ID")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .frame(maxWidth: .infinity).frame(height: 54)
                            .background(ShieldTheme.accent)
                            .foregroundColor(ShieldTheme.accentText)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(isAuthenticating)
                    } else if PINManager.hasPIN {
                        Button { showPINEntry = true } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "lock.circle.fill")
                                    .font(.system(size: 18, weight: .medium))
                                Text(appState.language == .es ? "Desbloquear con PIN" : "Unlock with PIN")
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
                                Text(appState.language == .es ? "Desbloquear" : "Unlock")
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

                    // Secondary fallbacks
                    if biometricEnabled && hasBiometrics {
                        if PINManager.hasPIN {
                            Button { showPINEntry = true } label: {
                                Text(appState.language == .es ? "Usar PIN" : "Use PIN")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(ShieldTheme.textSecondary)
                                    .frame(height: 44)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        } else if authError != nil {
                            // Face ID failed — offer passcode fallback
                            Button { authenticatePasscode() } label: {
                                Text(appState.language == .es ? "Usar código del iPhone" : "Use iPhone Passcode")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(ShieldTheme.textSecondary)
                                    .frame(height: 44)
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 28)

                Spacer().frame(height: 60)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPINEntry) {
            PINEntryView(isPresented: $showPINEntry) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.isAuthenticated = true
                }
            }
        }
        .task {
            // Wait for SwiftUI background to fully render before triggering any auth
            try? await Task.sleep(nanoseconds: 400_000_000)
            // Only auto-trigger Face ID — it shows a subtle overlay, not the gray system passcode screen.
            // Passcode and PIN are always user-initiated via the button.
            if biometricEnabled && hasBiometrics {
                authenticate()
            }
        }
    }

    private func authenticate() {
        guard !isAuthenticating else { return }
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            authError = appState.language == .es
                ? "Face ID no disponible en este dispositivo."
                : "Face ID is not available on this device."
            return
        }
        isAuthenticating = true
        authError = nil
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: appState.language == .es ? "Desbloquea Shield" : "Unlock Shield"
        ) { success, evalErr in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    verified = true
                    withAnimation(.easeInOut(duration: 0.2)) { appState.isAuthenticated = true }
                } else {
                    authError = evalErr?.localizedDescription
                }
            }
        }
    }

    private func authenticatePasscode() {
        guard !isAuthenticating else { return }
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &err) else {
            withAnimation { appState.isAuthenticated = true }
            return
        }
        isAuthenticating = true
        authError = nil
        ctx.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: appState.language == .es ? "Desbloquea Shield" : "Unlock Shield"
        ) { success, evalErr in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    verified = true
                    withAnimation(.easeInOut(duration: 0.2)) { appState.isAuthenticated = true }
                } else {
                    authError = evalErr?.localizedDescription
                }
            }
        }
    }
}
