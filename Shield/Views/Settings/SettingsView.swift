import SwiftUI
import LocalAuthentication
import MessageUI

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @ObservedObject private var cloud = CloudSyncManager.shared
    @Environment(\.colorScheme) var scheme
    @State private var showPaywall = false
    @State private var paywallTrigger: PaywallTrigger = .manual
    @State private var showAbout = false
    @State private var showDeleteConfirm = false
    @State private var showMailCompose = false
    @State private var biometricEnabled: Bool = UserDefaults.standard.bool(forKey: "shield.biometric")
    @State private var autoLockIndex: Int = UserDefaults.standard.integer(forKey: "shield.autoLock")
    @State private var hapticEnabled: Bool = UserDefaults.standard.object(forKey: "shield.haptic") == nil
        ? true
        : UserDefaults.standard.bool(forKey: "shield.haptic")
    @State private var strictKYCEnabled: Bool = UserDefaults.standard.object(forKey: "shield.ocr.strictKYC") == nil
        ? false
        : UserDefaults.standard.bool(forKey: "shield.ocr.strictKYC")
    @State private var warnLowConfidenceEnabled: Bool = UserDefaults.standard.object(forKey: "shield.ocr.warnLowConfidence") == nil
        ? true
        : UserDefaults.standard.bool(forKey: "shield.ocr.warnLowConfidence")
    @State private var ocrConfidenceIndex: Int = UserDefaults.standard.object(forKey: "shield.ocr.minConfidence") == nil
        ? 1
        : UserDefaults.standard.integer(forKey: "shield.ocr.minConfidence")
    @State private var exportFormatIndex: Int = UserDefaults.standard.integer(forKey: "shield.exportFormat")
    @State private var exportQualityIndex: Int = UserDefaults.standard.integer(forKey: "shield.exportQuality")
    @State private var iCloudEnabled: Bool = UserDefaults.standard.bool(forKey: "shield.icloud.enabled")
    @State private var showPINSetup = false
    @State private var showPINEntry = false
    @State private var showBiometricAlert = false
    @State private var pendingBiometricEnable = false

    @State private var expandedRow: ExpandedRow? = nil

    enum ExpandedRow: Equatable { case autoLock, exportFormat, exportQuality, ocrConfidence }

    private var autoLockOptions: [String] {
        [
            appState.str("settings_autolock_immediately"),
            appState.str("settings_autolock_1_minute"),
            appState.str("settings_autolock_5_minutes"),
            appState.str("settings_autolock_15_minutes"),
            appState.str("settings_autolock_never")
        ]
    }
    private var exportFormats: [String] {
        [appState.str("settings_format_pdf"), appState.str("settings_format_image")]
    }
    private var exportQualities: [String] {
        [appState.str("settings_quality_high"), appState.str("settings_quality_medium"), appState.str("settings_quality_low")]
    }
    private let ocrConfidenceOptions = ["70%", "80%", "90%"]

    var body: some View {
        ZStack {
            ShieldTheme.pageBackground(scheme).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Title
                    HStack {
                        Text(appState.str("settings_title"))
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(ShieldTheme.primary(scheme))
                            .tracking(-0.5)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    // Pro banner (if not pro)
                    if !pm.isPro {
                        proBanner
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    } else {
                        proActiveBanner
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }

                    // Appearance
                    settingsSection(title: appState.str("settings_appearance")) {
                        // Theme
                        settingsRow(
                            icon: "moon.fill",
                            iconColor: "5E5CE6",
                            title: appState.str("settings_dark_mode")
                        ) {
                            ShieldToggle(isOn: Binding(
                                get: { appState.preferredScheme == .dark },
                                set: { appState.preferredScheme = $0 ? .dark : .light }
                            ))
                        }
                        ShieldDivider().padding(.leading, 54)

                        // Language
                        settingsRow(
                            icon: "globe",
                            iconColor: "64D2FF",
                            title: appState.str("settings_language")
                        ) {
                            Picker("", selection: $appState.language) {
                                Text("Español").tag(AppLanguage.es)
                                Text("English").tag(AppLanguage.en)
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 130)
                        }
                    }

                    // Security
                    settingsSection(title: appState.str("settings_security")) {
                        settingsRow(
                            icon: "faceid",
                            iconColor: "30D158",
                            title: appState.str("settings_face_id")
                        ) {
                            ShieldToggle(isOn: $biometricEnabled)
                                .onChange(of: biometricEnabled) { _, v in
                                    if v {
                                        guard PINManager.hasPIN else {
                                            pendingBiometricEnable = true
                                            biometricEnabled = false
                                            UserDefaults.standard.set(false, forKey: "shield.biometric")
                                            showPINSetup = true
                                            return
                                        }
                                        requestBiometricEnable()
                                    } else {
                                        pendingBiometricEnable = false
                                        UserDefaults.standard.set(false, forKey: "shield.biometric")
                                    }
                                }
                        }
                        ShieldDivider().padding(.leading, 54)

                        settingsRowButton(
                            icon: "lock.circle.fill",
                            iconColor: "BF5AF2",
                            title: PINManager.hasPIN ? appState.str("settings_change_pin") : appState.str("settings_setup_pin")
                        ) {
                            if PINManager.hasPIN {
                                showPINEntry = true
                            } else {
                                showPINSetup = true
                            }
                        }
                        ShieldDivider().padding(.leading, 54)

                        expandableRow(
                            icon: "lock.rotation",
                            iconColor: "FF9F0A",
                            title: appState.str("settings_auto_lock"),
                            value: autoLockOptions[autoLockIndex],
                            row: .autoLock
                        ) {
                            Picker("", selection: $autoLockIndex) {
                                ForEach(0..<autoLockOptions.count, id: \.self) { i in
                                    Text(autoLockOptions[i]).tag(i)
                                }
                            }
                            .pickerStyle(.inline)
                            .onChange(of: autoLockIndex) { _, v in
                                UserDefaults.standard.set(v, forKey: "shield.autoLock")
                            }
                        }

                        ShieldDivider().padding(.leading, 54)

                        settingsRow(
                            icon: "hand.tap.fill",
                            iconColor: "FF453A",
                            title: appState.str("settings_haptic_feedback")
                        ) {
                            ShieldToggle(isOn: $hapticEnabled)
                                .onChange(of: hapticEnabled) { _, v in
                                    UserDefaults.standard.set(v, forKey: "shield.haptic")
                                }
                        }

                        ShieldDivider().padding(.leading, 54)

                        settingsRow(
                            icon: "checkmark.shield.fill",
                            iconColor: "0A84FF",
                            title: appState.str("settings_strict_kyc")
                        ) {
                            ShieldToggle(isOn: $strictKYCEnabled)
                                .onChange(of: strictKYCEnabled) { _, v in
                                    UserDefaults.standard.set(v, forKey: "shield.ocr.strictKYC")
                                }
                        }

                        ShieldDivider().padding(.leading, 54)

                        settingsRow(
                            icon: "exclamationmark.triangle.fill",
                            iconColor: "FF9F0A",
                            title: appState.str("settings_low_confidence_alert")
                        ) {
                            ShieldToggle(isOn: $warnLowConfidenceEnabled)
                                .onChange(of: warnLowConfidenceEnabled) { _, v in
                                    UserDefaults.standard.set(v, forKey: "shield.ocr.warnLowConfidence")
                                }
                        }

                        ShieldDivider().padding(.leading, 54)

                        expandableRow(
                            icon: "slider.horizontal.3",
                            iconColor: "64D2FF",
                            title: appState.str("settings_ocr_threshold"),
                            value: ocrConfidenceOptions[ocrConfidenceIndex],
                            row: .ocrConfidence
                        ) {
                            Picker("", selection: $ocrConfidenceIndex) {
                                ForEach(0..<ocrConfidenceOptions.count, id: \.self) { i in
                                    Text(ocrConfidenceOptions[i]).tag(i)
                                }
                            }
                            .pickerStyle(.inline)
                            .onChange(of: ocrConfidenceIndex) { _, v in
                                UserDefaults.standard.set(v, forKey: "shield.ocr.minConfidence")
                            }
                        }
                    }

                    // iCloud sync (Pro only)
                    iCloudSection

                    // Export defaults
                    settingsSection(title: appState.str("settings_export")) {
                        expandableRow(
                            icon: "doc.fill",
                            iconColor: "FFD60A",
                            title: appState.str("settings_default_format"),
                            value: exportFormats[exportFormatIndex],
                            row: .exportFormat
                        ) {
                            Picker("", selection: $exportFormatIndex) {
                                ForEach(0..<exportFormats.count, id: \.self) { i in
                                    Text(exportFormats[i]).tag(i)
                                }
                            }
                            .pickerStyle(.inline)
                            .onChange(of: exportFormatIndex) { _, v in
                                UserDefaults.standard.set(v, forKey: "shield.exportFormat")
                            }
                        }

                        ShieldDivider().padding(.leading, 54)

                        expandableRow(
                            icon: "photo.fill",
                            iconColor: "64D2FF",
                            title: appState.str("settings_image_quality"),
                            value: exportQualities[exportQualityIndex],
                            row: .exportQuality
                        ) {
                            Picker("", selection: $exportQualityIndex) {
                                ForEach(0..<exportQualities.count, id: \.self) { i in
                                    Text(exportQualities[i]).tag(i)
                                }
                            }
                            .pickerStyle(.inline)
                            .onChange(of: exportQualityIndex) { _, v in
                                UserDefaults.standard.set(v, forKey: "shield.exportQuality")
                            }
                        }
                    }

                    // About
                    settingsSection(title: appState.str("settings_about")) {
                        settingsRow(
                            icon: "info.circle.fill",
                            iconColor: "5E5CE6",
                            title: appState.str("settings_version")
                        ) {
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                                .font(.system(size: 14))
                                .foregroundColor(ShieldTheme.tertiary(scheme))
                        }

                        ShieldDivider().padding(.leading, 54)

                        settingsRowButton(
                            icon: "star.fill",
                            iconColor: "FFD60A",
                            title: appState.str("settings_rate_app")
                        ) {
                            if let url = URL(string: "itms-apps://itunes.apple.com/app/id6745955196?action=write-review") {
                                UIApplication.shared.open(url)
                            }
                        }

                        ShieldDivider().padding(.leading, 54)

                        settingsRowButton(
                            icon: "envelope.fill",
                            iconColor: "30D158",
                            title: appState.str("settings_contact")
                        ) {
                            if MFMailComposeViewController.canSendMail() {
                                showMailCompose = true
                            } else {
                                let subject = appState.str("settings_support_subject")
                                    .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                                if let url = URL(string: "mailto:support@shieldapp.io?subject=\(subject)") {
                                    UIApplication.shared.open(url)
                                }
                            }
                        }
                    }

                    // Developer (debug only)
                    #if DEBUG
                    developerSection
                    #endif

                    // Danger zone
                    settingsSection(title: appState.str("settings_privacy")) {
                        settingsRowButton(
                            icon: "trash.fill",
                            iconColor: "FF453A",
                            title: appState.str("settings_delete_all_documents"),
                            titleColor: ShieldTheme.danger
                        ) {
                            showDeleteConfirm = true
                        }
                    }

                    Spacer().frame(height: 100)
                }
            }
        }
        .fullScreenCover(isPresented: $showPINSetup) {
            PINSetupView(isPresented: $showPINSetup) {
                if pendingBiometricEnable {
                    pendingBiometricEnable = false
                    requestBiometricEnable()
                }
            }.environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showPINEntry) {
            PINEntryView(isPresented: $showPINEntry) {
                showPINSetup = true
            }.environmentObject(appState)
        }
        .alert(
            appState.str("settings_biometric_unavailable"),
            isPresented: $showBiometricAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.str("settings_biometric_unavailable_message"))
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: paywallTrigger)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showMailCompose) {
            MailComposeView(
                recipient: "support@shieldapp.io",
                subject: appState.str("settings_support_subject"),
                body: appState.str("settings_support_body")
            )
        }
        .confirmationDialog(
            appState.str("settings_delete_all_confirm_title"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(appState.str("settings_delete_all_button"), role: .destructive) {
                appState.deleteAllDocuments()
            }
            Button(appState.str("common_cancel"), role: .cancel) {}
        } message: {
            Text(appState.str("settings_delete_all_confirm_message"))
        }
        .onAppear {
            sanitizePreferences()
        }
    }

    // MARK: - Developer section (DEBUG only)

    #if DEBUG
    private var developerSection: some View {
        settingsSection(title: appState.str("settings_developer")) {
            settingsRow(
                icon: "hammer.fill",
                iconColor: "FF6B35",
                title: appState.str("settings_premium_override")
            ) {
                ShieldToggle(isOn: Binding(
                    get: { pm.isDebugProOverride },
                    set: { pm.setDebugProOverride($0) }
                ))
            }
        }
    }
    #endif

    // MARK: - iCloud section

    @ViewBuilder
    private var iCloudSection: some View {
        settingsSection(title: appState.str("settings_icloud")) {
            if !pm.isPro {
                settingsRow(icon: "icloud", iconColor: "5E5CE6",
                            title: appState.str("settings_icloud_sync")) {
                    Button {
                        paywallTrigger = .settingsUpgrade
                        showPaywall = true
                    } label: {
                        Text(appState.str("common_pro"))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(ShieldTheme.accentText)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(ShieldTheme.accent)
                            .clipShape(Capsule())
                    }
                }
            } else {
                settingsRow(icon: "icloud", iconColor: "5E5CE6",
                            title: appState.str("settings_icloud_sync_with")) {
                    ShieldToggle(isOn: $iCloudEnabled)
                        .onChange(of: iCloudEnabled) { _, v in
                            cloud.setSyncEnabled(v)
                            if v {
                                Task { await cloud.pushDocuments(appState.documents) }
                            }
                        }
                }

                if iCloudEnabled {
                    ShieldDivider().padding(.leading, 54)
                    settingsRow(icon: "arrow.clockwise.icloud", iconColor: "64D2FF",
                                title: appState.str("settings_icloud_sync_now")) {
                        Button {
                            Task { await cloud.pushDocuments(appState.documents) }
                        } label: {
                            if case .syncing = cloud.syncStatus {
                                ProgressView().scaleEffect(0.7).tint(ShieldTheme.accent)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(ShieldTheme.accent)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    if let lastSync = cloud.lastSyncFormatted {
                        ShieldDivider().padding(.leading, 54)
                        settingsRow(icon: "checkmark.icloud", iconColor: "30D158",
                                    title: appState.str("settings_icloud_last_sync")) {
                            Text(lastSync)
                                .font(.system(size: 12))
                                .foregroundColor(ShieldTheme.tertiary(scheme))
                        }
                    }

                    if case .error(let msg) = cloud.syncStatus {
                        ShieldDivider().padding(.leading, 54)
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.icloud")
                                .font(.system(size: 14)).foregroundColor(ShieldTheme.danger)
                            Text(msg)
                                .font(.system(size: 12))
                                .foregroundColor(ShieldTheme.danger)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 10)
                    }

                    if !cloud.isAvailable {
                        ShieldDivider().padding(.leading, 54)
                        settingsRow(icon: "xmark.icloud", iconColor: "FF453A",
                                    title: appState.str("settings_icloud_unavailable")) {
                            EmptyView()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Pro banners

    private var proBanner: some View {
        Button {
            paywallTrigger = .settingsUpgrade
            showPaywall = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ShieldTheme.accentDim)
                        .frame(width: 44, height: 44)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundColor(ShieldTheme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shield Pro")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ShieldTheme.textPrimary)
                    Text(appState.str("settings_pro_unlock_features"))
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.textTertiary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ShieldTheme.textTertiary)
            }
            .padding(16)
            .background(
                LinearGradient(colors: [Color(hex: "1a1a22"), Color(hex: "15151b")],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShieldTheme.accentDim, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var proActiveBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(ShieldTheme.successDim)
                    .frame(width: 44, height: 44)
                Image(systemName: "crown.fill")
                    .font(.system(size: 20))
                    .foregroundColor(ShieldTheme.success)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.str("settings_pro_active"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Text(appState.str("settings_pro_unlocked"))
                    .font(.system(size: 12))
                    .foregroundColor(ShieldTheme.success)
            }
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(ShieldTheme.success)
                .font(.system(size: 20))
        }
        .padding(16)
        .background(ShieldTheme.successDim)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShieldTheme.success.opacity(0.3), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Section builder

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ShieldTheme.tertiary(scheme))
                .tracking(0.5)
                .padding(.horizontal, 20)
                .padding(.bottom, 6)

            VStack(spacing: 0) {
                content()
            }
            .background(ShieldTheme.cardBackground(scheme))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShieldTheme.line(scheme), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 20)
    }

    @ViewBuilder
    private func settingsRow<Control: View>(
        icon: String, iconColor: String, title: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(spacing: 14) {
            iconBadge(icon, color: iconColor)
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(ShieldTheme.primary(scheme))
            Spacer()
            control()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func expandableRow<P: View>(
        icon: String, iconColor: String, title: String, value: String,
        row: ExpandedRow,
        @ViewBuilder picker: () -> P
    ) -> some View {
        let isExpanded = expandedRow == row
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedRow = isExpanded ? nil : row
                }
            } label: {
                HStack(spacing: 14) {
                    iconBadge(icon, color: iconColor)
                    Text(title)
                        .font(.system(size: 15))
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Spacer()
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ShieldTheme.quaternary(scheme))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ShieldDivider().padding(.leading, 54)
                picker()
                    .padding(.horizontal, 14)
            }
        }
    }

    @ViewBuilder
    private func settingsRowButton(
        icon: String, iconColor: String, title: String,
        titleColor: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                iconBadge(icon, color: iconColor)
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(titleColor ?? ShieldTheme.primary(scheme))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ShieldTheme.quaternary(scheme))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func iconBadge(_ icon: String, color: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: color))
                .frame(width: 32, height: 32)
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private func sanitizePreferences() {
        let clampedAutoLock = max(0, min(autoLockIndex, autoLockOptions.count - 1))
        if clampedAutoLock != autoLockIndex {
            autoLockIndex = clampedAutoLock
            UserDefaults.standard.set(clampedAutoLock, forKey: "shield.autoLock")
        }

        let clampedFormat = max(0, min(exportFormatIndex, exportFormats.count - 1))
        if clampedFormat != exportFormatIndex {
            exportFormatIndex = clampedFormat
            UserDefaults.standard.set(clampedFormat, forKey: "shield.exportFormat")
        }

        let clampedQuality = max(0, min(exportQualityIndex, exportQualities.count - 1))
        if clampedQuality != exportQualityIndex {
            exportQualityIndex = clampedQuality
            UserDefaults.standard.set(clampedQuality, forKey: "shield.exportQuality")
        }

        let clampedOCR = max(0, min(ocrConfidenceIndex, ocrConfidenceOptions.count - 1))
        if clampedOCR != ocrConfidenceIndex {
            ocrConfidenceIndex = clampedOCR
            UserDefaults.standard.set(clampedOCR, forKey: "shield.ocr.minConfidence")
        }
    }

    private func requestBiometricEnable() {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            biometricEnabled = false
            UserDefaults.standard.set(false, forKey: "shield.biometric")
            showBiometricAlert = true
            return
        }
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: appState.str("settings_biometric_reason")
        ) { ok, _ in
            DispatchQueue.main.async {
                biometricEnabled = ok
                UserDefaults.standard.set(ok, forKey: "shield.biometric")
                if !ok { showBiometricAlert = true }
            }
        }
    }
}

// MARK: - MailComposeView

struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.setToRecipients([recipient])
        vc.setSubject(subject)
        vc.setMessageBody(body, isHTML: false)
        vc.mailComposeDelegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}
