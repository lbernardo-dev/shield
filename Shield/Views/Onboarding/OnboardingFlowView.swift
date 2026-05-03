import SwiftUI

// MARK: - OnboardingFlowView

struct OnboardingFlowView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var state = OnboardingState()

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: "1a1a22"), ShieldTheme.surface1],
                center: .top, startRadius: 0, endRadius: 500
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                if state.showTopBar {
                    topBar
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }

                stepContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(state.currentStep)
            }
        }
        .preferredColorScheme(appState.preferredScheme)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ShieldTheme.surfaceLine)
                        .frame(height: 3)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(ShieldTheme.accent)
                        .frame(width: geo.size.width * state.progress, height: 3)
                        .animation(.easeInOut(duration: 0.28), value: state.progress)
                }
            }
            .frame(height: 3)

            Button(action: completeOnboarding) {
                Text(LanguageManager.shared.onboarding("onboarding_skip"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ShieldTheme.textTertiary)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch state.currentStep {
        case 0:  OBWelcomeView(state: state)
        case 1:  OBGoalView(state: state)
        case 2:  OBPainPointsView(state: state)
        case 3:  OBSocialProofView(state: state)
        case 4:  OBSolutionView(state: state)
        case 5:  OBPreferencesView(state: state)
        case 6:  OBCameraPermView(state: state)
        case 7:  OBFaceIDPermView(state: state)
        case 8:  OBProcessingView(state: state)
        case 9:  OBDemoView(state: state)
        case 10: OBPaywallView(onComplete: completeOnboarding)
        default: EmptyView()
        }
    }

    private func completeOnboarding() {
        state.persistAnswers()
        withAnimation {
            appState.isOnboarded = true
            appState.isAuthenticated = true
        }
    }
}
