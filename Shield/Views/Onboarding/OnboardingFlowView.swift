import SwiftUI

// MARK: - OnboardingFlowView

struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var state = OnboardingState()

    var body: some View {
        GeometryReader { _ in
            ZStack {
                if state.currentStep == 4 {
                    Color.black
                        .ignoresSafeArea()
                } else {
                    RadialGradient(
                        colors: [Color(hex: "1a1a22"), ShieldTheme.surface1],
                        center: .top, startRadius: 0, endRadius: 500
                    )
                    .ignoresSafeArea()
                }

                VStack(spacing: 0) {
                    if state.showTopBar {
                        topBar
                            .padding(.horizontal, 24)
                            .padding(.top, ShieldTheme.topChromePadding)
                            .padding(.bottom, ShieldTheme.topChromeBottomSpacing)
                    }

                    stepContent
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .id(state.currentStep)
                }
            }
        }
        .preferredColorScheme(appState.preferredScheme)
        .sensoryFeedback(.selection, trigger: state.currentStep)
        .onAppear {
            AppState.trackEvent("onboarding_started")
            trackCurrentStep()
        }
        .onChange(of: state.currentStep) {
            trackCurrentStep()
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            if state.currentStep > 0 {
                Button(action: moveBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ShieldTheme.textPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .accessibilityLabel(LanguageManager.shared.onboarding("onboarding_back"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.70))
                        .frame(height: 3)
                        .accessibilityHidden(true)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ShieldTheme.accent)
                        .frame(width: geo.size.width * state.progress, height: 3)
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.28), value: state.progress)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: 3)
            .padding(.vertical, 20.5)
            .contentShape(Rectangle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(LanguageManager.shared.onboarding("onboarding_progress_label"))
            .accessibilityValue(LanguageManager.shared.onboarding(
                "onboarding_progress_value", state.currentStep + 1, state.totalSteps
            ))

            Button(action: { completeOnboarding(source: "top_skip") }) {
                Text(LanguageManager.shared.onboarding("onboarding_skip"))
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(ShieldTheme.textSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityHint(LanguageManager.shared.onboarding("onboarding_skip_hint"))
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch state.currentStep {
        case 0:  OBWelcomeView(state: state)
        case 1:  OBGoalView(state: state)
        case 2:  OBPainPointsView(state: state)
        case 3:  OBDemoView(state: state)
        case 4:  OBCameraPermView(state: state)
        case 5:  OBPaywallView(onBack: moveBack, onComplete: { completeOnboarding(source: "paywall") })
        default: EmptyView()
        }
    }

    private func completeOnboarding(source: String = "flow") {
        state.persistAnswers()
        AppState.trackEvent("onboarding_completed", properties: [
            "last_step": String(state.currentStep),
            "source": source
        ])
        withAnimation {
            appState.isOnboarded = true
            appState.isAuthenticated = true
        }
    }

    private func moveBack() {
        AppState.trackEvent("onboarding_back_tapped", properties: [
            "from_step": String(state.currentStep),
            "name": stepName
        ])
        state.previous()
    }

    private func trackCurrentStep() {
        AppState.trackEvent("onboarding_step_viewed", properties: [
            "step": String(state.currentStep),
            "name": stepName
        ])
    }

    private var stepName: String {
        switch state.currentStep {
        case 0: "welcome"
        case 1: "goal"
        case 2: "privacy_concerns"
        case 3: "interactive_demo"
        case 4: "camera_permission"
        case 5: "paywall"
        default: "unknown"
        }
    }
}
