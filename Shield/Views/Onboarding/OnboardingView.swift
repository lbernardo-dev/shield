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
    @State private var verified: Bool = false
    @State private var authError: String? = nil

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "15151b"), Color(hex: "0a0a0b")],
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Shield icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 36)
                        .fill(Color(hex: "FFD60A").opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 36)
                                .stroke(Color(hex: "FFD60A").opacity(0.3), lineWidth: 1.5)
                        )
                        .frame(width: 140, height: 140)

                    Image(systemName: "faceid")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(verified ? ShieldTheme.success : ShieldTheme.accent)
                        .symbolEffect(.pulse, isActive: isAuthenticating)
                }
                .clipped()

                VStack(spacing: 6) {
                    Text("Shield")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(ShieldTheme.textPrimary)
                    Text(verified
                         ? "✓ \(appState.language == .es ? "Verificado" : "Verified")"
                         : (isAuthenticating
                            ? (appState.language == .es ? "Verificando…" : "Verifying…")
                            : appState.str(.useFaceId)))
                        .font(.system(size: 14))
                        .foregroundColor(ShieldTheme.textSecondary)

                    if let authError {
                        Text(authError)
                            .font(.system(size: 13))
                            .foregroundColor(ShieldTheme.danger)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                    }
                }

                Button {
                    authenticate()
                } label: {
                    Text(appState.str(.unlock))
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(ShieldTheme.accent)
                        .foregroundColor(ShieldTheme.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.horizontal, 28)
                .disabled(isAuthenticating)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { authenticate() }
    }

    private func authenticate() {
        guard !isAuthenticating else { return }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            authError = error?.localizedDescription ?? (appState.language == .es
                ? "No se pudo activar la autenticación del dispositivo."
                : "Device authentication is unavailable.")
            return
        }

        isAuthenticating = true
        authError = nil

        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: appState.language == .es ? "Desbloquea Shield" : "Unlock Shield"
        ) { success, evaluateError in
            DispatchQueue.main.async {
                isAuthenticating = false
                if success {
                    verified = true
                    withAnimation(.easeInOut(duration: 0.2)) {
                        appState.isAuthenticated = true
                    }
                } else {
                    verified = false
                    authError = evaluateError?.localizedDescription ?? (appState.language == .es
                        ? "No se pudo verificar tu identidad."
                        : "Your identity could not be verified.")
                }
            }
        }
    }
}
