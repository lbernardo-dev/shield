import SwiftUI
import AVFoundation
import LocalAuthentication
import StoreKit

// MARK: - Screen 1: Welcome

struct OBWelcomeView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var state: OnboardingState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(ShieldTheme.accentDim)
                    .frame(width: 110, height: 110)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundColor(ShieldTheme.accent)
            }
            .symbolEffect(.pulse, isActive: true)
            .padding(.bottom, 36)

            Text(LanguageManager.shared.onboarding("onboarding_welcome_title"))
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(ShieldTheme.textPrimary)
                .multilineTextAlignment(.center)
                .tracking(-0.7)
                .padding(.horizontal, 24)

            Spacer().frame(height: 16)

            Text(LanguageManager.shared.onboarding("onboarding_welcome_subtitle"))
                .font(.system(size: 15))
                .foregroundColor(ShieldTheme.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: state.next) {
                Text(LanguageManager.shared.onboarding("onboarding_welcome_cta"))
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 54)
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

// MARK: - Screen 2: Goal

struct OBGoalView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var state: OnboardingState

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 10) {
                Text(LanguageManager.shared.onboarding("onboarding_goal_title"))
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)
                    .padding(.horizontal, 24)
                Text(LanguageManager.shared.onboarding("onboarding_goal_subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(ShieldTheme.textSecondary)
            }

            Spacer().frame(height: 28)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(OBGoal.allCases) { goal in
                        OBSelectRow(
                            emoji: goal.emoji,
                            label: goal.label(lang: appState.language),
                            isSelected: state.selectedGoal == goal,
                            multiSelect: false
                        ) { state.selectedGoal = goal }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Button(action: state.next) {
                Text(LanguageManager.shared.onboarding("onboarding_continue"))
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(state.selectedGoal != nil ? ShieldTheme.accent : ShieldTheme.surface2)
                    .foregroundColor(state.selectedGoal != nil ? ShieldTheme.accentText : ShieldTheme.textTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .animation(.easeInOut(duration: 0.15), value: state.selectedGoal != nil)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Screen 3: Pain Points

struct OBPainPointsView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var state: OnboardingState

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 10) {
                Text(LanguageManager.shared.onboarding("onboarding_pain_title"))
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)
                    .padding(.horizontal, 24)
                Text(LanguageManager.shared.onboarding("onboarding_pain_subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(ShieldTheme.textSecondary)
            }

            Spacer().frame(height: 28)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(OBPainPoint.allCases) { pain in
                        OBSelectRow(
                            emoji: pain.emoji,
                            label: pain.label(lang: appState.language),
                            isSelected: state.selectedPainPoints.contains(pain),
                            multiSelect: true
                        ) {
                            if state.selectedPainPoints.contains(pain) {
                                state.selectedPainPoints.remove(pain)
                            } else {
                                state.selectedPainPoints.insert(pain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Button(action: state.next) {
                Text(LanguageManager.shared.onboarding("onboarding_continue"))
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 54)
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

// MARK: - Screen 4: Social Proof

struct OBSocialProofView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var state: OnboardingState

    private struct T { let name: String; let tag: String; let text: String }
    private let testimonials: [T] = [
        T(name: "onboarding_social_1_name", tag: "onboarding_social_1_tag", text: "onboarding_social_1_text"),
        T(name: "onboarding_social_2_name", tag: "onboarding_social_2_tag", text: "onboarding_social_2_text"),
        T(name: "onboarding_social_3_name", tag: "onboarding_social_3_tag", text: "onboarding_social_3_text"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Text(LanguageManager.shared.onboarding("onboarding_social_title"))
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(ShieldTheme.textPrimary)
                .multilineTextAlignment(.center)
                .tracking(-0.5)
                .padding(.horizontal, 24)

            Spacer().frame(height: 28)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(Array(testimonials.enumerated()), id: \.offset) { _, t in
                        OBTestimonialCard(
                            name: LanguageManager.shared.onboarding(t.name),
                            tag: LanguageManager.shared.onboarding(t.tag),
                            text: LanguageManager.shared.onboarding(t.text)
                        )
                    }
                    Text(LanguageManager.shared.onboarding("onboarding_social_note"))
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Button(action: state.next) {
                Text(LanguageManager.shared.onboarding("onboarding_continue"))
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 54)
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

// MARK: - Screen 5: Solution

struct OBSolutionView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var state: OnboardingState

    private var items: [(title: String, fix: String)] {
        let pains = state.selectedPainPoints.isEmpty
            ? [OBPainPoint.photo, .dob, .docNumber]
            : Array(state.selectedPainPoints.prefix(3))
        var result = pains.map { p -> (String, String) in
            let k = p.solutionKeys
            return (LanguageManager.shared.onboarding(k.title), LanguageManager.shared.onboarding(k.fix))
        }
        result.append((
            LanguageManager.shared.onboarding("onboarding_solution_default_title"),
            LanguageManager.shared.onboarding("onboarding_solution_default_fix")
        ))
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            Text(LanguageManager.shared.onboarding("onboarding_solution_title"))
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(ShieldTheme.textPrimary)
                .multilineTextAlignment(.center)
                .tracking(-0.5)
                .padding(.horizontal, 24)

            Spacer().frame(height: 28)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        OBSolutionRow(pain: item.title, fix: item.fix)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Button(action: state.next) {
                Text(LanguageManager.shared.onboarding("onboarding_continue"))
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 54)
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

// MARK: - Screen 6: Preferences

struct OBPreferencesView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var state: OnboardingState
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            VStack(spacing: 10) {
                Text(LanguageManager.shared.onboarding("onboarding_prefs_title"))
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)
                    .padding(.horizontal, 24)
                Text(LanguageManager.shared.onboarding("onboarding_prefs_subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(ShieldTheme.textSecondary)
            }

            Spacer().frame(height: 28)

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(OBDocType.allCases) { doc in
                        OBDocTypeCard(
                            emoji: doc.emoji,
                            label: doc.label(lang: appState.language),
                            isSelected: state.selectedDocTypes.contains(doc)
                        ) {
                            if state.selectedDocTypes.contains(doc) {
                                state.selectedDocTypes.remove(doc)
                            } else {
                                state.selectedDocTypes.insert(doc)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Button(action: state.next) {
                Text(LanguageManager.shared.onboarding("onboarding_continue"))
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 54)
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

// MARK: - Screen 7: Camera Permission

struct OBCameraPermView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var state: OnboardingState

    var body: some View {
        OBPermissionLayout(
            sfSymbol: "camera.fill",
            accentHex: "64D2FF",
            title: LanguageManager.shared.onboarding("onboarding_camera_title"),
            subtitle: LanguageManager.shared.onboarding("onboarding_camera_subtitle"),
            bullets: [
                LanguageManager.shared.onboarding("onboarding_camera_bullet_1"),
                LanguageManager.shared.onboarding("onboarding_camera_bullet_2"),
                LanguageManager.shared.onboarding("onboarding_camera_bullet_3"),
            ],
            enableLabel: LanguageManager.shared.onboarding("onboarding_camera_enable"),
            notNowLabel: LanguageManager.shared.onboarding("onboarding_not_now"),
            onEnable: {
                AVCaptureDevice.requestAccess(for: .video) { _ in
                    DispatchQueue.main.async { state.next() }
                }
            },
            onSkip: { state.next() }
        )
    }
}

// MARK: - Screen 8: Face ID Permission

struct OBFaceIDPermView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var state: OnboardingState

    var body: some View {
        let reason = LanguageManager.shared.onboarding("onboarding_face_id_enable")
        OBPermissionLayout(
            sfSymbol: "faceid",
            accentHex: "30D158",
            title: LanguageManager.shared.onboarding("onboarding_face_id_title"),
            subtitle: LanguageManager.shared.onboarding("onboarding_face_id_subtitle"),
            bullets: [
                LanguageManager.shared.onboarding("onboarding_face_id_bullet_1"),
                LanguageManager.shared.onboarding("onboarding_face_id_bullet_2"),
                LanguageManager.shared.onboarding("onboarding_face_id_bullet_3"),
            ],
            enableLabel: reason,
            notNowLabel: LanguageManager.shared.onboarding("onboarding_not_now"),
            onEnable: {
                let ctx = LAContext()
                var err: NSError?
                guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
                    state.next()
                    return
                }
                ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                    DispatchQueue.main.async {
                        if success { UserDefaults.standard.set(true, forKey: "shield.biometric") }
                        state.next()
                    }
                }
            },
            onSkip: { state.next() }
        )
    }
}

// MARK: - Screen 9: Processing

struct OBProcessingView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var state: OnboardingState
    @State private var angle: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(ShieldTheme.accentDim)
                    .frame(width: 110, height: 110)
                Image(systemName: "shield.fill")
                    .font(.system(size: 52))
                    .foregroundColor(ShieldTheme.accent)
                    .rotationEffect(.degrees(angle))
            }

            Text(LanguageManager.shared.onboarding("onboarding_processing_text"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(ShieldTheme.textPrimary)

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                angle = 360
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            state.next()
        }
    }
}

// MARK: - Screen 10: Demo

struct OBDemoView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var state: OnboardingState
    @State private var redacted: Set<String> = []
    @State private var showResult = false
    private let minRequired = 2

    var body: some View {
        if showResult { resultView } else { interactiveView }
    }

    private var interactiveView: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 20)

            VStack(spacing: 8) {
                Text(LanguageManager.shared.onboarding("onboarding_demo_title"))
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)
                    .padding(.horizontal, 24)
                Text(LanguageManager.shared.onboarding("onboarding_demo_subtitle"))
                    .font(.system(size: 14))
                    .foregroundColor(ShieldTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer().frame(height: 24)

            // Sample document
            VStack(spacing: 0) {
                HStack {
                    Text(LanguageManager.shared.onboarding("onboarding_demo_sample_country"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ShieldTheme.textSecondary)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color(hex: "1a1a2e"))

                HStack(alignment: .top, spacing: 12) {
                    // Photo
                    Button { withAnimation(.easeInOut(duration: 0.15)) { toggle("photo") } } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(redacted.contains("photo") ? Color.black : Color(hex: "2a2a3a"))
                                .frame(width: 80, height: 100)
                            if redacted.contains("photo") {
                                Image(systemName: "eye.slash.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.3))
                            } else {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(ShieldTheme.textTertiary)
                            }
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())

                    VStack(alignment: .leading, spacing: 8) {
                        // Name (not redactable)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("NOMBRE").font(.system(size: 9, weight: .bold)).foregroundColor(ShieldTheme.textTertiary)
                            Text(LanguageManager.shared.onboarding("onboarding_demo_sample_name"))
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(ShieldTheme.textPrimary)
                        }
                        Divider().background(ShieldTheme.surfaceLine)
                        demoField(id: "dob", labelKey: "onboarding_demo_field_dob", value: "12/05/1988")
                        Divider().background(ShieldTheme.surfaceLine)
                        demoField(id: "docnum", labelKey: "onboarding_demo_field_doc_num", value: "47821634-X")
                    }
                }
                .padding(16)

                Divider().background(ShieldTheme.surfaceLine)

                // Address
                Button { withAnimation(.easeInOut(duration: 0.15)) { toggle("address") } } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LanguageManager.shared.onboarding("onboarding_demo_field_address").uppercased())
                                .font(.system(size: 9, weight: .bold)).foregroundColor(ShieldTheme.textTertiary)
                            if redacted.contains("address") {
                                RoundedRectangle(cornerRadius: 3).fill(Color.black)
                                    .frame(maxWidth: .infinity).frame(height: 16)
                            } else {
                                Text("Calle Mayor 14, 28001 Madrid")
                                    .font(.system(size: 13)).foregroundColor(ShieldTheme.textPrimary)
                            }
                        }
                        Spacer()
                        if redacted.contains("address") {
                            Image(systemName: "eye.slash.fill").font(.system(size: 12)).foregroundColor(ShieldTheme.accent)
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .background(ShieldTheme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(ShieldTheme.surfaceLine, lineWidth: 0.5))
            .padding(.horizontal, 24)

            Spacer().frame(height: 16)

            Text(instructionText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(redacted.count >= minRequired ? ShieldTheme.success : ShieldTheme.textSecondary)
                .multilineTextAlignment(.center)
                .animation(.easeInOut(duration: 0.2), value: redacted.count)

            Spacer()

            Button { withAnimation { showResult = true } } label: {
                Text(LanguageManager.shared.onboarding("onboarding_demo_see_result"))
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(redacted.count >= minRequired ? ShieldTheme.accent : ShieldTheme.surface2)
                    .foregroundColor(redacted.count >= minRequired ? ShieldTheme.accentText : ShieldTheme.textTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .animation(.easeInOut(duration: 0.2), value: redacted.count >= minRequired)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(redacted.count < minRequired)
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
    }

    @ViewBuilder
    private func demoField(id: String, labelKey: String, value: String) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.15)) { toggle(id) } } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LanguageManager.shared.onboarding(labelKey).uppercased())
                        .font(.system(size: 9, weight: .bold)).foregroundColor(ShieldTheme.textTertiary)
                    if redacted.contains(id) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.black).frame(width: 90, height: 14)
                    } else {
                        Text(value).font(.system(size: 13)).foregroundColor(ShieldTheme.textPrimary)
                    }
                }
                Spacer()
                if redacted.contains(id) {
                    Image(systemName: "eye.slash.fill").font(.system(size: 11)).foregroundColor(ShieldTheme.accent)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var instructionText: String {
        let remaining = max(0, minRequired - redacted.count)
        if redacted.count >= minRequired { return LanguageManager.shared.onboarding("onboarding_demo_instruction_done") }
        if remaining == 1 { return LanguageManager.shared.onboarding("onboarding_demo_instruction_singular") }
        return LanguageManager.shared.onboarding("onboarding_demo_instruction_plural")
    }

    private var resultView: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(hex: "30D158").opacity(0.15))
                        .frame(width: 96, height: 96)
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(Color(hex: "30D158"))
                }
                Text(LanguageManager.shared.onboarding("onboarding_demo_result_title"))
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)
                Text(LanguageManager.shared.onboarding("onboarding_demo_result_subtitle"))
                    .font(.system(size: 15))
                    .foregroundColor(ShieldTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Spacer()
            Button(action: state.next) {
                Text(LanguageManager.shared.onboarding("onboarding_demo_result_cta"))
                    .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(ShieldTheme.accent)
                    .foregroundColor(ShieldTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
    }

    private func toggle(_ id: String) {
        if redacted.contains(id) { redacted.remove(id) } else { redacted.insert(id) }
    }
}

// MARK: - Screen 11: Paywall

struct OBPaywallView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    var onComplete: () -> Void

    private let features: [(icon: String, hex: String, key: String)] = [
        ("doc.stack.fill",       "64D2FF", "paywall_feature_unlimited_docs"),
        ("eye.slash.fill",       "FFD60A", "paywall_feature_all_styles"),
        ("lock.rectangle.stack", "30D158", "paywall_feature_vault"),
        ("wand.and.stars",       "BF5AF2", "paywall_feature_auto_title"),
        ("icloud",               "30D158", "paywall_feature_icloud"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 40)

                VStack(spacing: 10) {
                    Image(systemName: "shield.fill")
                        .font(.system(size: 40))
                        .foregroundColor(ShieldTheme.accent)
                        .padding(.bottom, 8)
                    Text(LanguageManager.shared.paywall("paywall_title"))
                        .font(.system(size: 30, weight: .heavy))
                        .foregroundColor(ShieldTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .tracking(-0.7)
                        .padding(.horizontal, 24)
                    Text(LanguageManager.shared.paywall("paywall_hero_subtitle"))
                        .font(.system(size: 14))
                        .foregroundColor(ShieldTheme.textSecondary)
                }

                Spacer().frame(height: 24)

                // Testimonial
                VStack(spacing: 6) {
                    HStack(spacing: 3) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill").font(.system(size: 12)).foregroundColor(ShieldTheme.accent)
                        }
                    }
                    Text(LanguageManager.shared.paywall("paywall_testimonial"))
                        .font(.system(size: 13)).foregroundColor(ShieldTheme.textPrimary)
                        .multilineTextAlignment(.center).italic()
                    Text(LanguageManager.shared.paywall("paywall_testimonial_author"))
                        .font(.system(size: 12)).foregroundColor(ShieldTheme.textSecondary)
                }
                .padding(16)
                .background(ShieldTheme.surface2)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShieldTheme.surfaceLine, lineWidth: 0.5))
                .padding(.horizontal, 24)

                Spacer().frame(height: 24)

                // Features
                VStack(spacing: 10) {
                    ForEach(features, id: \.key) { f in
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(hex: f.hex).opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: f.icon)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: f.hex))
                            }
                            Text(LanguageManager.shared.paywall(f.key))
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(ShieldTheme.textPrimary)
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(hex: "30D158"))
                        }
                        .padding(.horizontal, 24)
                    }
                }

                Spacer().frame(height: 32)

                VStack(spacing: 12) {
                    Button {
                        Task {
                            guard let product = pm.products.first(where: { $0.id == ShieldProduct.annual.rawValue }) else { return }
                            await pm.purchase(product)
                            if pm.isPro { onComplete() }
                        }
                    } label: {
                        Group {
                            if pm.isPurchasing {
                                ProgressView().tint(ShieldTheme.accentText)
                            } else {
                                Text(LanguageManager.shared.paywall("paywall_get_pro"))
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(ShieldTheme.accentText)
                            }
                        }
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(ShieldTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(pm.isPurchasing)

                    Button {
                        Task { await pm.restore(); if pm.isPro { onComplete() } }
                    } label: {
                        Text(LanguageManager.shared.paywall("paywall_restore"))
                            .font(.system(size: 14)).foregroundColor(ShieldTheme.textSecondary).frame(height: 40)
                    }

                    Button(action: onComplete) {
                        Text(LanguageManager.shared.paywall("paywall_skip"))
                            .font(.system(size: 13)).foregroundColor(ShieldTheme.textTertiary).frame(height: 36)
                    }

                    Text(LanguageManager.shared.paywall("paywall_legal"))
                        .font(.system(size: 10)).foregroundColor(ShieldTheme.textTertiary)
                        .multilineTextAlignment(.center).padding(.horizontal, 40)
                }
                .padding(.horizontal, 24).padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Shared subviews

struct OBPermissionLayout: View {
    let sfSymbol: String
    let accentHex: String
    let title: String
    let subtitle: String
    let bullets: [String]
    let enableLabel: String
    let notNowLabel: String
    let onEnable: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(hex: accentHex).opacity(0.12))
                    .frame(width: 110, height: 110)
                Image(systemName: sfSymbol)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundColor(Color(hex: accentHex))
            }
            .padding(.bottom, 32)

            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)
                    .padding(.horizontal, 24)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(ShieldTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }

            Spacer().frame(height: 28)

            VStack(spacing: 12) {
                ForEach(bullets, id: \.self) { bullet in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: accentHex))
                        Text(bullet)
                            .font(.system(size: 14))
                            .foregroundColor(ShieldTheme.textPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, 32)
                }
            }

            Spacer()

            VStack(spacing: 10) {
                Button(action: onEnable) {
                    Text(enableLabel)
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity).frame(height: 54)
                        .background(Color(hex: accentHex))
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: onSkip) {
                    Text(notNowLabel)
                        .font(.system(size: 15))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(height: 44)
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 40)
        }
    }
}

struct OBSelectRow: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let multiSelect: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(emoji).font(.system(size: 20))
                Text(label)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(ShieldTheme.textPrimary)
                Spacer()
                Image(systemName: multiSelect
                    ? (isSelected ? "checkmark.square.fill" : "square")
                    : (isSelected ? "checkmark.circle.fill" : "circle")
                )
                .font(.system(size: 18))
                .foregroundColor(isSelected ? ShieldTheme.accent : ShieldTheme.textTertiary)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .background(isSelected ? ShieldTheme.accentDim : ShieldTheme.surface2)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? ShieldTheme.accent.opacity(0.5) : ShieldTheme.surfaceLine, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct OBTestimonialCard: View {
    let name: String
    let tag: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(ShieldTheme.accent)
                }
            }
            Text("\"\(text)\"")
                .font(.system(size: 13)).foregroundColor(ShieldTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(ShieldTheme.accentDim).frame(width: 30, height: 30)
                    Text(String(name.prefix(1)))
                        .font(.system(size: 13, weight: .bold)).foregroundColor(ShieldTheme.accent)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(name).font(.system(size: 12, weight: .semibold)).foregroundColor(ShieldTheme.textPrimary)
                    Text(tag).font(.system(size: 11)).foregroundColor(ShieldTheme.textSecondary)
                }
            }
        }
        .padding(16)
        .background(ShieldTheme.surface2)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShieldTheme.surfaceLine, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct OBSolutionRow: View {
    let pain: String
    let fix: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10).fill(ShieldTheme.accentDim).frame(width: 36, height: 36)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 16)).foregroundColor(ShieldTheme.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(pain).font(.system(size: 11)).foregroundColor(ShieldTheme.textTertiary)
                Text(fix).font(.system(size: 14, weight: .semibold)).foregroundColor(ShieldTheme.textPrimary)
            }
            Spacer()
        }
        .padding(14)
        .background(ShieldTheme.surface2)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShieldTheme.surfaceLine, lineWidth: 0.5))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct OBDocTypeCard: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Text(emoji).font(.system(size: 28))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 18)
            .background(isSelected ? ShieldTheme.accentDim : ShieldTheme.surface2)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? ShieldTheme.accent.opacity(0.5) : ShieldTheme.surfaceLine, lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
