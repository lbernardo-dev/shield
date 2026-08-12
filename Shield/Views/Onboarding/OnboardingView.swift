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

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: ShieldTheme.s4) {
                        lockHeader
                        accessCard
                        vaultHasSection
                        vaultNeedsSection
                        vaultDoesSection
                    }
                    .frame(minHeight: max(0, proxy.size.height - ShieldTheme.s8), alignment: .top)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, ShieldTheme.s5)
                    .padding(.top, ShieldTheme.topChromePadding)
                    .padding(.bottom, 100)
                }
                .scrollIndicators(.hidden)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            lockActions
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
                .shieldFont(22, weight: .heavy)
                .foregroundStyle(ShieldTheme.primary(scheme))

            Spacer(minLength: ShieldTheme.s2)

            Label(
                LanguageManager.shared.auth("lock_protection_active"),
                systemImage: "lock.fill"
            )
            .shieldFont(12, weight: .bold)
            .foregroundStyle(ShieldTheme.accentColor(scheme))
            .padding(.horizontal, ShieldTheme.s3)
            .frame(minHeight: 32)
            .background(ShieldTheme.accentDim(scheme), in: Capsule())
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity)
    }

    private var accessCard: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: ShieldTheme.s4) {
                    identityMark(size: 64)
                    accessCopy
                }
            } else {
                HStack(alignment: .top, spacing: ShieldTheme.s4) {
                    identityMark(size: 72)
                    accessCopy
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ShieldTheme.s5)
        .background {
            LinearGradient(
                colors: [
                    ShieldTheme.cardBackground(scheme),
                    ShieldTheme.accentDim(scheme).opacity(scheme == .dark ? 0.62 : 0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .overlay {
            RoundedRectangle(cornerRadius: ShieldTheme.rLG)
                .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 0.8)
        }
        .compositingGroup()
        .clipShape(.rect(cornerRadius: ShieldTheme.rLG))
    }

    private func identityMark(size: CGFloat) -> some View {
        ZStack(alignment: .bottomTrailing) {
            MaskIDIdentityMark(
                size: size,
                presentation: .animatedLoop,
                treatment: .compact,
                isEmphasized: isAuthenticating
            )

            if verified {
                Image(systemName: "checkmark.circle.fill")
                    .shieldFont(20, weight: .semibold)
                    .foregroundStyle(ShieldTheme.success, ShieldTheme.cardBackground(scheme))
                    .contentTransition(.symbolEffect(.replace))
                    .accessibilityHidden(true)
            }
        }
        .padding(ShieldTheme.s2)
        .background(
            ShieldTheme.accentDim(scheme),
            in: RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ShieldTheme.rMD, style: .continuous)
                .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 0.8)
        )
    }

    private var accessCopy: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            VStack(alignment: .leading, spacing: ShieldTheme.s2) {
                Text(LanguageManager.shared.auth("lock_access_title"))
                    .shieldFont(20, weight: .bold)
                    .foregroundStyle(ShieldTheme.primary(scheme))
                    .fixedSize(horizontal: false, vertical: true)

                Text(lockSubtitle)
                    .shieldFont(13, weight: .medium)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            lockStatus
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lockStatus: some View {
        HStack(alignment: .firstTextBaseline, spacing: ShieldTheme.s2) {
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
                .fixedSize(horizontal: false, vertical: true)
        }
        .shieldFont(13, weight: .semibold)
        .foregroundStyle(authError == nil ? ShieldTheme.secondary(scheme) : ShieldTheme.danger)
        .padding(.horizontal, ShieldTheme.s3)
        .padding(.vertical, ShieldTheme.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            authError == nil
                ? ShieldTheme.elevatedBackground(scheme).opacity(0.8)
                : ShieldTheme.errorBackground(scheme),
            in: RoundedRectangle(cornerRadius: ShieldTheme.rSM)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("lock.status")
    }

    // MARK: - Activity & Vault Real Summary Cards

    private var totalVaultedCount: Int {
        appState.documents.filter(\.isVaulted).count
    }

    private var totalMaskedCount: Int {
        appState.documents.reduce(0) { $0 + $1.totalRedactionCount }
    }

    private var vaultHasSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            sectionHeader(
                title: LanguageManager.shared.auth("lock_activity_summary_title"),
                icon: "chart.bar.fill"
            )

            HStack(spacing: ShieldTheme.s3) {
                vaultMetricTile(
                    icon: "doc.fill",
                    title: "\(appState.documents.count)",
                    subtitle: LanguageManager.shared.auth("lock_stat_processed_label")
                )
                vaultMetricTile(
                    icon: "lock.shield.fill",
                    title: "\(totalVaultedCount)",
                    subtitle: LanguageManager.shared.auth("lock_stat_vaulted_label")
                )
                vaultMetricTile(
                    icon: "eye.slash.fill",
                    title: "\(totalMaskedCount)",
                    subtitle: LanguageManager.shared.auth("lock_stat_masked_label")
                )
            }
        }
        .padding(ShieldTheme.s4)
        .shieldCard()
        .accessibilityElement(children: .contain)
    }

    private func vaultMetricTile(icon: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .shieldFont(13, weight: .bold)
                    .foregroundStyle(ShieldTheme.accentColor(scheme))
                    .accessibilityHidden(true)
                Text(title)
                    .shieldFont(18, weight: .heavy)
                    .foregroundStyle(ShieldTheme.primary(scheme))
            }
            Text(subtitle)
                .shieldFont(12, weight: .semibold)
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ShieldTheme.s3)
        .background(ShieldTheme.elevatedBackground(scheme), in: RoundedRectangle(cornerRadius: ShieldTheme.rSM))
        .accessibilityElement(children: .combine)
    }

    // MARK: - Section 2: LO QUE NECESITA (Requirements)

    private var vaultNeedsSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            sectionHeader(
                title: LanguageManager.shared.auth("lock_section_needs"),
                icon: "key.fill"
            )

            VStack(alignment: .leading, spacing: 0) {
                LockProtectionRow(
                    icon: biometricEnabled && hasBiometrics ? "faceid" : "number",
                    title: LanguageManager.shared.auth("lock_needs_auth_title"),
                    detail: lockStatusMessage
                )

                Divider()
                    .overlay(ShieldTheme.line(scheme))
                    .padding(.leading, 44)

                LockProtectionRow(
                    icon: "iphone",
                    title: LanguageManager.shared.auth("lock_needs_local_title"),
                    detail: LanguageManager.shared.auth("lock_local_detail")
                )
            }
        }
        .padding(ShieldTheme.s4)
        .shieldCard()
        .accessibilityElement(children: .contain)
    }

    // MARK: - Section 3: LO QUE HACE (Privacy & Protection Guarantees)

    private var vaultDoesSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            sectionHeader(
                title: LanguageManager.shared.auth("lock_section_does"),
                icon: "checkmark.seal.fill"
            )

            VStack(alignment: .leading, spacing: 0) {
                LockProtectionRow(
                    icon: "lock.shield.fill",
                    title: LanguageManager.shared.auth("lock_does_zk_title"),
                    detail: LanguageManager.shared.auth("lock_does_zk_detail")
                )

                Divider()
                    .overlay(ShieldTheme.line(scheme))
                    .padding(.leading, 44)

                LockProtectionRow(
                    icon: "eye.slash.fill",
                    title: LanguageManager.shared.auth("lock_does_shield_title"),
                    detail: LanguageManager.shared.auth("lock_does_shield_detail")
                )

                Divider()
                    .overlay(ShieldTheme.line(scheme))
                    .padding(.leading, 44)

                LockProtectionRow(
                    icon: "sparkles",
                    title: LanguageManager.shared.auth("lock_does_purge_title"),
                    detail: LanguageManager.shared.auth("lock_does_purge_detail")
                )
            }
        }
        .padding(ShieldTheme.s4)
        .shieldCard()
        .accessibilityElement(children: .contain)
    }

    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: ShieldTheme.s2) {
            Image(systemName: icon)
                .shieldFont(13, weight: .bold)
                .foregroundStyle(ShieldTheme.accentColor(scheme))
            Text(title)
                .shieldFont(13, weight: .bold)
                .foregroundStyle(ShieldTheme.primary(scheme))
                .textCase(.uppercase)
                .tracking(0.6)
        }
    }

    private var lockActions: some View {
        ShieldStickyFooter {
            VStack(spacing: ShieldTheme.s2) {
                primaryUnlockButton

                if showsSecondaryPINButton {
                    ShieldButton(
                        label: LanguageManager.shared.auth("lock_use_pin"),
                        icon: "number",
                        style: .secondary,
                        height: 44
                    ) {
                        showPINEntry = true
                    }
                    .accessibilityIdentifier("lock.secondaryPIN")
                }

                if biometricEnabled && hasBiometrics && authError != nil {
                    Button(LanguageManager.shared.auth("lock_use_passcode"), action: authenticatePasscode)
                        .shieldFont(13, weight: .semibold)
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                        .frame(minHeight: ShieldTheme.minimumTapTarget)
                        .buttonStyle(ScaleButtonStyle())
                }

                if let actionHint = lockActionHint {
                    Text(actionHint)
                        .shieldFont(12, weight: .medium)
                        .foregroundStyle(ShieldTheme.tertiary(scheme))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }

    private var lockSubtitle: String {
        LanguageManager.shared.auth("lock_verify_subtitle")
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
            return LanguageManager.shared.auth(
                biometricEnabled && hasBiometrics ? "lock_ready_faceid" : "lock_ready_pin"
            )
        }
        return LanguageManager.shared.auth("lock_setup_passcode_message")
    }

    private var lockActionHint: String? {
        guard !PINManager.hasPIN else { return nil }
        return LanguageManager.shared.auth("lock_passcode_hint")
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

private struct LockProtectionRow: View {
    let icon: String
    let title: String
    let detail: String

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(alignment: .top, spacing: ShieldTheme.s3) {
            Image(systemName: icon)
                .shieldFont(16, weight: .semibold)
                .foregroundStyle(ShieldTheme.accentColor(scheme))
                .frame(width: 32, height: 32)
                .background(ShieldTheme.accentDim(scheme), in: RoundedRectangle(cornerRadius: ShieldTheme.rSM))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: ShieldTheme.s1) {
                Text(title)
                    .shieldFont(14, weight: .semibold)
                    .foregroundStyle(ShieldTheme.primary(scheme))

                Text(detail)
                    .shieldFont(12, weight: .medium)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, ShieldTheme.s2)
        .accessibilityElement(children: .combine)
    }
}
