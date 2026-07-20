import SwiftUI
import AVFoundation
import LocalAuthentication

// MARK: - Screen 1: Welcome

struct OBWelcomeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ObservedObject var state: OnboardingState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(ShieldTheme.accent.opacity(0.12), lineWidth: 1)
                    .frame(width: 176, height: 176)
                    .scaleEffect(reduceMotion ? 1 : 1.08)
                Circle()
                    .stroke(ShieldTheme.accent.opacity(0.22), lineWidth: 1)
                    .frame(width: 142, height: 142)
                Image("MaskIDMark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(ShieldTheme.accent.opacity(0.35), lineWidth: 1.5)
                    )
                    .shadow(color: ShieldTheme.accent.opacity(0.4), radius: 10, x: 0, y: 0)
                    .accessibilityHidden(true)
            }
            .symbolEffect(.pulse, options: reduceMotion ? .nonRepeating : .repeating, isActive: !reduceMotion)
            .padding(.bottom, 36)

            Text(LanguageManager.shared.onboarding("onboarding_welcome_title"))
                .font(.largeTitle.weight(.heavy))
                .foregroundColor(ShieldTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.75)
                .padding(.horizontal, 24)
                .padding(.vertical, 6)

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
            .sensoryFeedback(.impact(weight: .medium), trigger: state.currentStep)
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
            .disabled(state.selectedGoal == nil)
            .sensoryFeedback(.selection, trigger: state.selectedGoal)
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
            .sensoryFeedback(.selection, trigger: state.selectedPainPoints)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Screen 4: Demo

struct OBDemoView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var state: OnboardingState
    @State private var redacted: Set<String> = []
    @State private var showResult = false
    private let minRequired = 2

    var body: some View {
        Group {
            if showResult {
                resultView
                    .transition(.scale(scale: 0.96).combined(with: .opacity))
            } else {
                interactiveView
                    .transition(.opacity)
            }
        }
        .sensoryFeedback(.selection, trigger: redacted.count)
        .sensoryFeedback(.success, trigger: showResult) { _, newValue in
            newValue
        }
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
                            Text(LanguageManager.shared.onboarding("onboarding_demo_name_label")).font(.system(size: 9, weight: .bold)).foregroundColor(ShieldTheme.textTertiary)
                            Text(LanguageManager.shared.onboarding("onboarding_demo_sample_name"))
                                .font(.system(size: 13, weight: .semibold)).foregroundColor(ShieldTheme.textPrimary)
                        }
                        Divider().background(ShieldTheme.surfaceLine)
                        demoField(id: "dob", labelKey: "onboarding_demo_field_dob", value: LanguageManager.shared.onboarding("onboarding_demo_sample_dob"))
                        Divider().background(ShieldTheme.surfaceLine)
                        demoField(id: "docnum", labelKey: "onboarding_demo_field_doc_num", value: LanguageManager.shared.onboarding("onboarding_demo_sample_doc_num"))
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
                                Text(LanguageManager.shared.onboarding("onboarding_demo_address_value"))
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
            Spacer(minLength: 16)

            protectedDocumentPreview

            VStack(spacing: 10) {
                Text(LanguageManager.shared.onboarding("onboarding_demo_result_title"))
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(-0.5)
                Text(LanguageManager.shared.onboarding("onboarding_demo_result_subtitle"))
                    .font(.system(size: 15))
                    .foregroundColor(ShieldTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 22)

            HStack(spacing: 8) {
                resultTrustPill("iphone", key: "onboarding_demo_result_device")
                resultTrustPill("photo.on.rectangle.angled", key: "onboarding_demo_result_gallery")
                resultTrustPill("checkmark.circle", key: "onboarding_demo_result_review")
            }
            .padding(.top, 20)
            .padding(.horizontal, 20)

            Spacer(minLength: 18)

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

    private var protectedDocumentPreview: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack {
                    Text(LanguageManager.shared.onboarding("onboarding_demo_sample_country"))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(ShieldTheme.textSecondary)
                    Spacer()
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundStyle(ShieldTheme.success)
                }
                .padding(12)
                .background(Color(hex: "1a1a2e"))

                VStack(alignment: .leading, spacing: 13) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(.black)
                            .frame(width: 58, height: 72)
                        VStack(alignment: .leading, spacing: 9) {
                            RoundedRectangle(cornerRadius: 3).fill(ShieldTheme.surfaceLine).frame(width: 118, height: 9)
                            RoundedRectangle(cornerRadius: 3).fill(.black).frame(width: 136, height: 14)
                            RoundedRectangle(cornerRadius: 3).fill(.black).frame(width: 102, height: 14)
                        }
                    }
                    RoundedRectangle(cornerRadius: 3).fill(.black).frame(maxWidth: .infinity).frame(height: 14)
                }
                .padding(16)
            }
            .frame(width: 270)
            .background(ShieldTheme.surface2)
            .clipShape(.rect(cornerRadius: 18))
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(ShieldTheme.success.opacity(0.45), lineWidth: 1)
            }
            .shadow(color: ShieldTheme.success.opacity(0.12), radius: 24, y: 12)

            Label(
                LanguageManager.shared.onboarding("onboarding_demo_result_count", redacted.count),
                systemImage: "eye.slash.fill"
            )
            .font(.caption.bold())
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(ShieldTheme.success, in: Capsule())
            .offset(y: 16)
        }
        .padding(.bottom, 16)
        .accessibilityElement(children: .combine)
    }

    private func resultTrustPill(_ symbol: String, key: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ShieldTheme.accent)
            Text(LanguageManager.shared.onboarding(key))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(ShieldTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 64)
        .background(ShieldTheme.surface2, in: .rect(cornerRadius: 12))
    }

    private func toggle(_ id: String) {
        if redacted.contains(id) { redacted.remove(id) } else { redacted.insert(id) }
    }
}

// MARK: - Screen 5: Camera Permission

struct OBCameraPermView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @ObservedObject var state: OnboardingState
    @State private var authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var isRequesting = false

    var body: some View {
        GeometryReader { proxy in
            Color.black
                .overlay {
                    VStack(spacing: 0) {
                        Spacer(minLength: 6)

                        permissionAnimation
                            .frame(height: min(390, max(300, proxy.size.height * 0.54)))

                        permissionContent
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                    }
                }
        }
        .environment(\.colorScheme, .dark)
        .onAppear(perform: refreshAuthorizationStatus)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            refreshAuthorizationStatus()
        }
    }

    private var permissionContent: some View {
        VStack(spacing: 10) {
            cameraPermissionSymbol

            Text(presentationTitle)
                .font(.title.bold())
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(presentationSubtitle)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Button(action: handlePrimaryAction) {
                ZStack {
                    Text(primaryButtonTitle)
                        .opacity(isRequesting ? 0 : 1)
                    if isRequesting {
                        ProgressView()
                            .tint(ShieldTheme.accentText)
                    }
                }
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .foregroundStyle(ShieldTheme.accentText)
            .background(ShieldTheme.accent, in: Capsule())
            .buttonStyle(ScaleButtonStyle())
            .disabled(isRequesting)
            .padding(.top, 10)

            Button(LanguageManager.shared.onboarding("onboarding_not_now"), action: handleNotNow)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(minHeight: 36)
                .disabled(isRequesting)
                .padding(.top, 1)
        }
        .frame(maxWidth: 330)
        .padding(.horizontal, 24)
    }

    private var cameraPermissionSymbol: some View {
        Image(systemName: "camera")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .fontWeight(.ultraLight)
            .foregroundStyle(.white)
            .frame(width: 62, height: 62)
            .overlay(alignment: .topLeading) {
                if reduceMotion {
                    permissionChevron
                } else {
                    permissionChevron
                        .symbolEffect(.bounce.down, options: .repeating)
                }
            }
            .accessibilityHidden(true)
    }

    private var permissionChevron: some View {
        Image(systemName: "chevron.down")
            .font(.system(size: 12, weight: .medium))
            .offset(x: -2, y: -8)
    }

    private var permissionAnimation: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let ratio = min(size.width / 390, size.height / 870)

            if reduceMotion {
                cameraPhone(frame: .visible, size: size, ratio: ratio)
            } else {
                KeyframeAnimator(initialValue: CameraPermissionFrame(), repeating: true) { frame in
                    cameraPhone(frame: frame, size: size, ratio: ratio)
                } keyframes: { _ in
                    KeyframeTrack(\.scale) {
                        MoveKeyframe(1)
                        LinearKeyframe(1, duration: 0.5)
                        CubicKeyframe(0.95, duration: 0.5)
                        LinearKeyframe(0.95, duration: 5)
                        CubicKeyframe(1, duration: 0.35)
                        LinearKeyframe(1, duration: 0.5)
                    }
                    KeyframeTrack(\.cameraOpacity) {
                        MoveKeyframe(0)
                        LinearKeyframe(0, duration: 0.5)
                        CubicKeyframe(1, duration: 0.5)
                        LinearKeyframe(1, duration: 5)
                        CubicKeyframe(0, duration: 0.35)
                        LinearKeyframe(0, duration: 0.5)
                    }
                    KeyframeTrack(\.progress) {
                        MoveKeyframe(0)
                        LinearKeyframe(0, duration: 1.5)
                        SpringKeyframe(-1, duration: 1.5, spring: .smooth(duration: 1, extraBounce: 0))
                        SpringKeyframe(1, duration: 1.5, spring: .smooth(duration: 1, extraBounce: 0))
                        SpringKeyframe(0, duration: 1.5, spring: .smooth(duration: 1, extraBounce: 0))
                        CubicKeyframe(0, duration: 0.35)
                        LinearKeyframe(0, duration: 0.5)
                    }
                }
            }
        }
        .aspectRatio(390 / 870, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LanguageManager.shared.onboarding("onboarding_camera_artwork_accessibility"))
    }

    private func cameraPhone(frame: CameraPermissionFrame, size: CGSize, ratio: CGFloat) -> some View {
        let cornerRadius = 47 * ratio

        return Rectangle()
            .fill(Color.white.opacity(0.10))
            .overlay {
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(.black)
                        .overlay {
                            Image("OnboardingCamera")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width * 3, height: size.height)
                                .offset(x: -frame.progress * size.width)
                        }
                        .clipped()

                    HStack(spacing: 0) {
                        Circle()
                            .fill(.white.secondary)
                            .frame(width: size.height * 0.05)
                            .frame(maxWidth: .infinity)

                        Circle()
                            .fill(.white)
                            .frame(width: size.height * 0.2, height: size.height * 0.1)
                            .frame(maxWidth: .infinity)

                        Circle()
                            .fill(.white.secondary)
                            .frame(width: size.height * 0.05)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: size.height * 0.17)
                    .background(.black.opacity(0.5))
                }
                .clipped()
                .offset(y: size.height - (size.height * frame.cameraOpacity))
            }
            .overlay(alignment: .top) {
                Capsule()
                    .fill(.black)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    .frame(width: 120 * ratio, height: 36 * ratio)
                    .overlay {
                        Circle()
                            .fill(.green)
                            .frame(width: 10 * ratio, height: 10 * ratio)
                            .offset(x: 12 * ratio)
                            .opacity(frame.cameraOpacity)
                    }
                    .padding(.top, 11 * ratio)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.18), lineWidth: 2)
            }
            .compositingGroup()
            .scaleEffect(frame.scale, anchor: .center)
            .rotation3DEffect(
                .degrees(frame.progress * 15),
                axis: (x: 0, y: abs(frame.progress), z: abs(frame.progress / 4)),
                anchor: .center
            )
            .offset(x: frame.progress * 80)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .aspectRatio(390 / 870, contentMode: .fit)
            .shadow(color: .black.opacity(0.45), radius: 22, y: 12)
    }

    private struct CameraPermissionFrame {
        var scale: CGFloat = 1
        var cameraOpacity: CGFloat = 0
        var progress: CGFloat = 0

        static let visible = CameraPermissionFrame(scale: 0.95, cameraOpacity: 1, progress: 0)
    }

    private var presentationTitle: String {
        switch authorizationStatus {
        case .denied:
            LanguageManager.shared.onboarding("onboarding_camera_denied_title")
        case .restricted:
            LanguageManager.shared.onboarding("onboarding_camera_restricted_title")
        default:
            LanguageManager.shared.onboarding("onboarding_camera_title")
        }
    }

    private var presentationSubtitle: String {
        switch authorizationStatus {
        case .denied:
            LanguageManager.shared.onboarding("onboarding_camera_denied_subtitle")
        case .restricted:
            LanguageManager.shared.onboarding("onboarding_camera_restricted_subtitle")
        default:
            LanguageManager.shared.onboarding("onboarding_camera_subtitle")
        }
    }

    private var primaryButtonTitle: String {
        switch authorizationStatus {
        case .authorized, .restricted:
            LanguageManager.shared.onboarding("onboarding_continue")
        case .denied:
            LanguageManager.shared.onboarding("onboarding_camera_open_settings")
        default:
            LanguageManager.shared.onboarding("onboarding_camera_enable")
        }
    }

    private func handlePrimaryAction() {
        switch authorizationStatus {
        case .authorized, .restricted:
            AppState.trackEvent("camera_permission_continued", properties: [
                "status": authorizationStatus == .authorized ? "authorized" : "restricted"
            ])
            state.next()
        case .denied:
            AppState.trackEvent("camera_settings_opened")
            guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
            openURL(settingsURL)
        case .notDetermined:
            isRequesting = true
            Task {
                let granted = await AVCaptureDevice.requestAccess(for: .video)
                authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
                isRequesting = false
                AppState.trackEvent("camera_permission_resolved", properties: [
                    "granted": granted ? "true" : "false"
                ])
                if granted { state.next() }
            }
            // requestAccess's completion can fail to resume on some Simulator/OS
            // combinations, permanently disabling the CTA. Fall back to polling the
            // system status directly so the button never gets stuck; if the real
            // completion above still lands later, it applies its own (authoritative)
            // result on top of this with no risk of double-advancing the step.
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                guard isRequesting else { return }
                refreshAuthorizationStatus()
            }
        @unknown default:
            state.next()
        }
    }

    private func handleNotNow() {
        AppState.trackEvent("camera_permission_skipped", properties: [
            "status": String(describing: authorizationStatus)
        ])
        state.next()
    }

    private func refreshAuthorizationStatus() {
        let refreshedStatus = AVCaptureDevice.authorizationStatus(for: .video)
        authorizationStatus = refreshedStatus

        // The system permission sheet can return the app to the foreground before
        // requestAccess resumes (especially in Simulator). Never leave the CTA
        // disabled once iOS has already resolved the permission decision.
        if refreshedStatus != .notDetermined {
            isRequesting = false
        }
    }
}

// MARK: - Screen 6: Paywall

struct OBPaywallView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openURL) private var openURL
    @StateObject private var pm = PremiumManager.shared
    @State private var selectedProduct: ShieldProduct = .annual
    var onBack: () -> Void
    var onComplete: () -> Void

    private let features: [(icon: String, hex: String, key: String)] = [
        ("doc.on.doc.fill",       "64D2FF", "paywall_feature_unlimited_docs"),
        ("eye.slash.fill",       "FFD60A", "paywall_feature_all_styles"),
        ("lock.rectangle.stack", "30D158", "paywall_feature_vault"),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0D0D10"), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    HStack {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(ShieldTheme.textPrimary)
                                .frame(width: 44, height: 44)
                                .background(ShieldTheme.surface2, in: Circle())
                        }
                        .accessibilityLabel(LanguageManager.shared.onboarding("onboarding_back"))
                        Spacer()
                    }
                    paywallHero
                    valueRecap
                    planSelector
                    purchaseSection
                    footer
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 30)
            }
        }
        .task { await pm.loadProducts() }
        .onChange(of: pm.products.map(\.id)) { _, availableProductIDs in
            guard !availableProductIDs.contains(selectedProduct.rawValue),
                  let fallback = ShieldProduct.allCases.first(where: { availableProductIDs.contains($0.rawValue) })
            else { return }
            selectedProduct = fallback
        }
        .sensoryFeedback(.selection, trigger: selectedProduct)
        .sensoryFeedback(.success, trigger: pm.isPro) { _, isPro in isPro }
    }

    private var paywallHero: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(ShieldTheme.accentDim)
                    .frame(width: 72, height: 72)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(ShieldTheme.accent)
            }
            .symbolEffect(.breathe, options: .repeating)

            Text(LanguageManager.shared.paywall("paywall_title"))
                .font(.system(size: 29, weight: .heavy))
                .foregroundStyle(ShieldTheme.textPrimary)
                .multilineTextAlignment(.center)
            Text(LanguageManager.shared.paywall("paywall_hero_subtitle"))
                .font(.callout)
                .foregroundStyle(ShieldTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    private var valueRecap: some View {
        VStack(spacing: 10) {
            ForEach(features, id: \.key) { feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(hex: feature.hex))
                        .frame(width: 28, height: 28)
                        .background(Color(hex: feature.hex).opacity(0.14), in: .rect(cornerRadius: 8))
                    Text(LanguageManager.shared.paywall(feature.key))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(ShieldTheme.textPrimary)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ShieldTheme.success)
                }
            }
        }
        .padding(14)
        .background(ShieldTheme.surface2, in: .rect(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(ShieldTheme.surfaceLine, lineWidth: 0.5)
        }
    }

    private var planSelector: some View {
        VStack(spacing: 12) {
            if pm.products.isEmpty {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(ShieldTheme.surface2)
                        .frame(height: 84)
                        .redacted(reason: .placeholder)
                }
            } else {
                ForEach(pm.products, id: \.id) { product in
                    PlanRow(
                        product: product,
                        isSelected: selectedProduct.rawValue == product.id,
                        savingsLabel: savingsLabel(for: product),
                        trialLabel: pm.trialLabels[product.id],
                        lang: appState.language
                    ) {
                        guard let selection = ShieldProduct(rawValue: product.id) else { return }
                        withAnimation(.snappy(duration: 0.24)) {
                            selectedProduct = selection
                        }
                        AppState.trackEvent("paywall_plan_selected", properties: [
                            "plan": selection.analyticsName
                        ])
                    }
                }
            }
        }
    }

    private var purchaseSection: some View {
        VStack(spacing: 10) {
            Button {
                Task {
                    guard let product = pm.products.first(where: { $0.id == selectedProduct.rawValue }) else { return }
                    AppState.trackEvent("paywall_purchase_started", properties: [
                        "plan": selectedProduct.analyticsName
                    ])
                    await pm.purchase(product)
                    if pm.isPro {
                        AppState.trackEvent("paywall_purchase_completed", properties: [
                            "plan": selectedProduct.analyticsName
                        ])
                        onComplete()
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if pm.isPurchasing {
                        ProgressView().tint(ShieldTheme.accentText)
                    } else {
                        Image(systemName: "shield.fill")
                        Text(LanguageManager.shared.paywall("paywall_get_pro"))
                            .font(.body.bold())
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(ShieldTheme.accent, in: .rect(cornerRadius: 16))
                .foregroundStyle(ShieldTheme.accentText)
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(pm.isPurchasing || pm.products.isEmpty)

            if let error = pm.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(ShieldTheme.danger)
                    .multilineTextAlignment(.center)
            }

            Button(LanguageManager.shared.paywall("paywall_skip")) {
                AppState.trackEvent("paywall_skipped")
                onComplete()
            }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(ShieldTheme.textSecondary)
                .frame(minHeight: 44)
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                Button(LanguageManager.shared.paywall("paywall_restore")) {
                    Task {
                        AppState.trackEvent("paywall_restore_started")
                        await pm.restore()
                        if pm.isPro { onComplete() }
                    }
                }
                publicPageLink(
                    LanguageManager.shared.paywall("paywall_privacy"),
                    page: .privacy
                )
                publicPageLink(
                    LanguageManager.shared.paywall("paywall_terms"),
                    page: .terms
                )
            }
            .font(.caption)
            .foregroundStyle(ShieldTheme.textTertiary)

            publicPageLink(
                LanguageManager.shared.settings("settings_subscription_terms"),
                page: .subscriptions
            )
            .font(.caption)
            .foregroundStyle(ShieldTheme.textTertiary)

            Text(LanguageManager.shared.paywall("paywall_legal"))
                .font(.system(size: 10))
                .foregroundStyle(ShieldTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
    }

    private func publicPageLink(_ title: String, page: ShieldPublicPage) -> some View {
        Button(title) {
            openURL(page.localizedURL(for: appState.language)) { accepted in
                guard !accepted else { return }
                openURL(page.compatibilityURL)
            }
        }
        .accessibilityHint(LanguageManager.shared.settings("settings_opens_browser"))
    }

    private func savingsLabel(for product: PremiumProduct) -> String? {
        switch ShieldProduct(rawValue: product.id) {
        case .annual:
            guard let monthly = pm.products.first(where: { $0.id == ShieldProduct.monthly.rawValue })
            else { return nil }
            return pm.annualSavings(monthly: monthly, annual: product, lang: appState.language)
        case .lifetime:
            guard let annual = pm.products.first(where: { $0.id == ShieldProduct.annual.rawValue })
            else { return nil }
            return pm.lifetimeSavings(annual: annual, lifetime: product, lang: appState.language)
        default:
            return nil
        }
    }
}

// MARK: - Shared subviews

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
