import SwiftUI
import LocalAuthentication

// MARK: - Public web destinations

enum ShieldPublicPage: String, CaseIterable, Sendable {
    case overview
    case privacy
    case terms
    case subscriptions
    case support
    case faq

    func localizedURL(for language: AppLanguage) -> URL {
        let path: String
        switch (self, language) {
        case (.overview, .es): path = "es/casos/shield/"
        case (.privacy, .es): path = "es/casos/shield/privacidad/"
        case (.terms, .es): path = "es/casos/shield/terminos/"
        case (.subscriptions, .es): path = "es/casos/shield/suscripciones/"
        case (.support, .es): path = "es/casos/shield/soporte/"
        case (.faq, .es): path = "es/casos/shield/preguntas-frecuentes/"
        case (.overview, .en): path = "en/case-studies/shield/"
        case (.privacy, .en): path = "en/case-studies/shield/privacy/"
        case (.terms, .en): path = "en/case-studies/shield/terms/"
        case (.subscriptions, .en): path = "en/case-studies/shield/subscriptions/"
        case (.support, .en): path = "en/case-studies/shield/support/"
        case (.faq, .en): path = "en/case-studies/shield/faq/"
        }
        return Self.baseURL.appending(path: path)
    }

    var compatibilityURL: URL {
        let path: String
        switch self {
        case .overview: path = "apps/shield/"
        case .privacy: path = "apps/shield/privacy/"
        case .terms: path = "apps/shield/terms/"
        case .subscriptions: path = "apps/shield/subscriptions/"
        case .support: path = "apps/shield/support/"
        case .faq: path = "apps/shield/faq/"
        }
        return Self.baseURL.appending(path: path)
    }

    private static let baseURL = URL(string: "https://lbernardo-dev.github.io/apps/")!
}

struct ShieldPublicPageButton: View {
    let page: ShieldPublicPage
    let language: AppLanguage
    var compact = false

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        Button(action: openPage) {
            HStack(spacing: ShieldTheme.s3) {
                Image(systemName: "safari.fill")
                    .font(.body.weight(.bold))
                    .accessibilityHidden(true)
                if compact {
                    Text(strings.settings("settings_open_online"))
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strings.settings("settings_open_official_page"))
                            .font(.body.weight(.bold))
                        Text(strings.settings("settings_opens_browser"))
                            .font(.caption)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                    }
                }
                Spacer(minLength: ShieldTheme.s2)
                Image(systemName: "arrow.up.forward")
                    .font(.caption.weight(.bold))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(ShieldTheme.accent(scheme))
            .padding(compact ? ShieldTheme.s3 : ShieldTheme.s4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ShieldTheme.accentDim(scheme))
            .overlay {
                RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                    .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 1)
            }
            .compositingGroup()
            .clipShape(.rect(cornerRadius: ShieldTheme.rMD))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityHint(strings.settings("settings_opens_browser"))
    }

    private func openPage() {
        openURL(page.localizedURL(for: language)) { accepted in
            guard !accepted else { return }
            openURL(page.compatibilityURL)
        }
    }
}

// MARK: - Shared settings chrome

private struct ShieldSettingsCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .background(ShieldTheme.cardBackground(scheme))
            .overlay {
                RoundedRectangle(cornerRadius: ShieldTheme.rLG)
                    .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
            }
            .clipShape(.rect(cornerRadius: ShieldTheme.rLG))
    }
}

extension View {
    func shieldSettingsCard() -> some View {
        modifier(ShieldSettingsCardModifier())
    }
}

struct SettingsIconBadge: View {
    let icon: String
    let color: Color
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: size * 0.4, weight: .bold))
            .foregroundStyle(color == Color(hex: "FFD60A") ? Color.black : Color.white)
            .frame(width: size, height: size)
            .background(color.gradient)
            .clipShape(.rect(cornerRadius: size * 0.26))
            .accessibilityHidden(true)
    }
}

struct SettingsSummaryCard: View {
    let documentCount: Int
    let vaultedCount: Int
    let isPro: Bool

    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    var body: some View {
        VStack(spacing: ShieldTheme.s4) {
            HStack(spacing: ShieldTheme.s4) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(ShieldTheme.accentText)
                    .frame(width: 66, height: 66)
                    .background(ShieldTheme.accent(scheme).gradient)
                    .clipShape(.rect(cornerRadius: ShieldTheme.rMD))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: ShieldTheme.s2) {
                    Text("Shield")
                        .font(.title2.weight(.heavy))
                        .foregroundStyle(ShieldTheme.primary(scheme))

                    HStack(spacing: ShieldTheme.s2) {
                        summaryPill(icon: "info.circle.fill", text: strings.settings("settings_version_value", version))
                        summaryPill(icon: "hammer.fill", text: strings.settings("settings_build_value", build))
                    }
                }
                Spacer(minLength: 0)
            }

            SettingsRowDivider(inset: 0)

            HStack(spacing: 0) {
                summaryMetric(
                    icon: "doc.text.fill",
                    value: documentCount.formatted(),
                    label: strings.settings("settings_summary_documents")
                )
                Rectangle()
                    .fill(ShieldTheme.line(scheme))
                    .frame(width: 1, height: 46)
                summaryMetric(
                    icon: "lock.fill",
                    value: vaultedCount.formatted(),
                    label: strings.settings("settings_summary_vault")
                )
                Rectangle()
                    .fill(ShieldTheme.line(scheme))
                    .frame(width: 1, height: 46)
                summaryMetric(
                    icon: isPro ? "crown.fill" : "checkmark.circle.fill",
                    value: strings.settings(isPro ? "settings_plan_pro" : "settings_plan_free"),
                    label: strings.settings("settings_summary_plan")
                )
            }

            Label(strings.settings("settings_summary_privacy"), systemImage: "hand.raised.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(ShieldTheme.s3)
                .background(ShieldTheme.rowBackground(scheme))
                .clipShape(.rect(cornerRadius: ShieldTheme.rSM))
        }
        .padding(ShieldTheme.s4)
        .shieldSettingsCard()
        .accessibilityElement(children: .contain)
    }

    private func summaryPill(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(ShieldTheme.secondary(scheme))
            .lineLimit(1)
            .padding(.horizontal, ShieldTheme.s2)
            .padding(.vertical, 5)
            .background(ShieldTheme.rowBackground(scheme))
            .clipShape(Capsule())
    }

    private func summaryMetric(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Label(value, systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))
                .lineLimit(1)
            Text(label)
                .font(.caption2)
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

struct SettingsCardSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var scheme

    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            Label(title.uppercased(), systemImage: icon)
                .font(.subheadline.weight(.bold))
                .tracking(0.5)
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .accessibilityAddTraits(.isHeader)
                .padding(.leading, ShieldTheme.s3)

            VStack(spacing: 0) {
                content
            }
            .shieldSettingsCard()
        }
    }
}

struct SettingsNavigationRow: View {
    let route: SettingsRoute
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        NavigationLink(value: route) {
            SettingsRowLabel(icon: icon, color: color, title: title, subtitle: subtitle, showsChevron: true)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier(route.accessibilityIdentifier)
        .accessibilityHint(subtitle)
    }
}

struct SettingsActionRow: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    var accessibilityIdentifier: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowLabel(icon: icon, color: color, title: title, subtitle: subtitle, showsChevron: true)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier(accessibilityIdentifier ?? title)
        .accessibilityHint(subtitle)
    }
}

private struct SettingsRowLabel: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let showsChevron: Bool

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: ShieldTheme.s4) {
            SettingsIconBadge(icon: icon, color: color)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(ShieldTheme.primary(scheme))
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: ShieldTheme.s2)
            if showsChevron {
                Image(systemName: "chevron.forward")
                    .font(.body.weight(.bold))
                    .foregroundStyle(ShieldTheme.tertiary(scheme))
                    .accessibilityHidden(true)
            }
        }
        .padding(ShieldTheme.s4)
        .contentShape(Rectangle())
    }
}

struct SettingsRowDivider: View {
    var inset: CGFloat = 76
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Rectangle()
            .fill(ShieldTheme.line(scheme))
            .frame(height: 0.8)
            .padding(.leading, inset)
            .accessibilityHidden(true)
    }
}

private struct SettingsControlRow<Control: View>: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String?
    @ViewBuilder let control: Control

    @Environment(\.colorScheme) private var scheme

    init(
        icon: String,
        color: Color,
        title: String,
        subtitle: String? = nil,
        @ViewBuilder control: () -> Control
    ) {
        self.icon = icon
        self.color = color
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }

    var body: some View {
        HStack(spacing: ShieldTheme.s3) {
            SettingsIconBadge(icon: icon, color: color, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(ShieldTheme.primary(scheme))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: ShieldTheme.s2)
            control
        }
        .padding(ShieldTheme.s4)
    }
}

private struct SettingsDetailScaffold<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var scheme

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ZStack {
            ShieldTheme.pageBackground(scheme).ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: ShieldTheme.s5) {
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    content
                    Spacer().frame(height: 80)
                }
                .frame(maxWidth: 760)
                .padding(ShieldTheme.s4)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(ShieldTheme.pageBackground(scheme), for: .navigationBar)
    }
}

struct SettingsFooter: View {
    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        VStack(spacing: ShieldTheme.s2) {
            Text(strings.settings("settings_footer_version", appVersion))
                .font(.headline.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))
            Text(strings.settings("settings_footer_build", appBuild))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ShieldTheme.secondary(scheme))
            Text(strings.settings("settings_footer_designed"))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ShieldTheme.secondary(scheme))
            Label(strings.settings("settings_footer_privacy"), systemImage: "lock.shield.fill")
                .font(.caption)
                .foregroundStyle(ShieldTheme.tertiary(scheme))
                .multilineTextAlignment(.center)
            Text(strings.settings("settings_footer_rights"))
                .font(.caption)
                .foregroundStyle(ShieldTheme.tertiary(scheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ShieldTheme.s4)
        .accessibilityElement(children: .combine)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }
}

// MARK: - App preferences

struct AppPreferencesSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var scheme
    @State private var selectedLanguage: AppLanguage = LanguageManager.shared.current

    private var strings: LanguageManager { .shared }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_app_preferences"),
            subtitle: strings.settings("settings_app_preferences_detail")
        ) {
            SettingsCardSection(title: strings.settings("settings_appearance"), icon: "paintbrush.fill") {
                SettingsControlRow(
                    icon: "moon.fill",
                    color: Color(hex: "5E5CE6"),
                    title: strings.settings("settings_dark_mode")
                ) {
                    Toggle("", isOn: Binding(
                        get: { appState.preferredScheme == .dark },
                        set: { appState.preferredScheme = $0 ? .dark : .light }
                    ))
                    .labelsHidden()
                    .tint(ShieldTheme.accent(scheme))
                    .accessibilityLabel(strings.settings("settings_dark_mode"))
                }
                SettingsRowDivider()
                SettingsControlRow(
                    icon: "globe",
                    color: Color(hex: "00C7BE"),
                    title: strings.settings("settings_language")
                ) {
                    Picker(strings.settings("settings_language"), selection: $selectedLanguage) {
                        Text(strings.common("common_language_es")).tag(AppLanguage.es)
                        Text(strings.common("common_language_en")).tag(AppLanguage.en)
                    }
                    .pickerStyle(.menu)
                    .tint(ShieldTheme.accent(scheme))
                }
            }
        }
        .onAppear { selectedLanguage = appState.language }
        .onChange(of: selectedLanguage) { _, newValue in
            guard appState.language != newValue else { return }
            appState.language = newValue
        }
    }
}

// MARK: - Security and privacy

struct SecuritySettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var scheme

    @State private var biometricEnabled = UserDefaults.standard.bool(forKey: "shield.biometric")
    @State private var hapticEnabled = UserDefaults.standard.object(forKey: "shield.haptic") == nil
        ? true : UserDefaults.standard.bool(forKey: "shield.haptic")
    @State private var strictKYCEnabled = UserDefaults.standard.bool(forKey: "shield.ocr.strictKYC")
    @State private var warnLowConfidenceEnabled = UserDefaults.standard.object(forKey: "shield.ocr.warnLowConfidence") == nil
        ? true : UserDefaults.standard.bool(forKey: "shield.ocr.warnLowConfidence")
    @State private var autoLockIndex = UserDefaults.standard.integer(forKey: "shield.autoLock")
    @State private var confidenceIndex = UserDefaults.standard.object(forKey: "shield.ocr.minConfidence") == nil
        ? 1 : UserDefaults.standard.integer(forKey: "shield.ocr.minConfidence")
    @State private var showPINSetup = false
    @State private var showPINEntry = false
    @State private var showBiometricAlert = false
    @State private var pendingBiometricEnable = false
    @State private var showDeleteConfirm = false

    private let confidenceOptions = ["70%", "80%", "90%"]
    private var strings: LanguageManager { .shared }

    private var autoLockOptions: [String] {
        [
            strings.settings("settings_autolock_immediately"),
            strings.settings("settings_autolock_1_minute"),
            strings.settings("settings_autolock_5_minutes"),
            strings.settings("settings_autolock_15_minutes"),
            strings.settings("settings_autolock_never")
        ]
    }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_security_privacy"),
            subtitle: strings.settings("settings_security_detail")
        ) {
            SettingsCardSection(title: strings.settings("settings_access_protection"), icon: "lock.fill") {
                SettingsControlRow(
                    icon: "faceid",
                    color: Color(hex: "30D158"),
                    title: strings.settings("settings_face_id")
                ) {
                    Toggle("", isOn: $biometricEnabled)
                        .labelsHidden()
                        .tint(ShieldTheme.accent(scheme))
                        .accessibilityLabel(strings.settings("settings_face_id"))
                }
                SettingsRowDivider()
                SettingsActionRow(
                    icon: "lock.circle.fill",
                    color: Color(hex: "BF5AF2"),
                    title: PINManager.hasPIN
                        ? strings.settings("settings_change_pin")
                        : strings.settings("settings_setup_pin"),
                    subtitle: strings.settings("settings_pin_subtitle")
                ) {
                    if PINManager.hasPIN { showPINEntry = true } else { showPINSetup = true }
                }
                SettingsRowDivider()
                SettingsControlRow(
                    icon: "lock.rotation",
                    color: Color(hex: "FF9F0A"),
                    title: strings.settings("settings_auto_lock")
                ) {
                    Picker(strings.settings("settings_auto_lock"), selection: $autoLockIndex) {
                        ForEach(autoLockOptions.indices, id: \.self) { index in
                            Text(autoLockOptions[index]).tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(ShieldTheme.accent(scheme))
                }
            }

            SettingsCardSection(title: strings.settings("settings_detection_review"), icon: "text.viewfinder") {
                toggleRow(
                    icon: "hand.tap.fill",
                    color: Color(hex: "FF453A"),
                    title: strings.settings("settings_haptic_feedback"),
                    binding: $hapticEnabled
                )
                SettingsRowDivider()
                toggleRow(
                    icon: "checkmark.shield.fill",
                    color: Color(hex: "0A84FF"),
                    title: strings.settings("settings_strict_kyc"),
                    binding: $strictKYCEnabled
                )
                SettingsRowDivider()
                toggleRow(
                    icon: "exclamationmark.triangle.fill",
                    color: Color(hex: "FF9F0A"),
                    title: strings.settings("settings_low_confidence_alert"),
                    binding: $warnLowConfidenceEnabled
                )
                SettingsRowDivider()
                SettingsControlRow(
                    icon: "slider.horizontal.3",
                    color: Color(hex: "64D2FF"),
                    title: strings.settings("settings_ocr_threshold")
                ) {
                    Picker(strings.settings("settings_ocr_threshold"), selection: $confidenceIndex) {
                        ForEach(confidenceOptions.indices, id: \.self) { index in
                            Text(confidenceOptions[index]).tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(ShieldTheme.accent(scheme))
                }
            }

            SettingsCardSection(title: strings.settings("settings_data_management"), icon: "trash.fill") {
                SettingsActionRow(
                    icon: "trash.fill",
                    color: Color(hex: "FF453A"),
                    title: strings.settings("settings_delete_all_documents"),
                    subtitle: strings.settings("settings_delete_all_subtitle"),
                    action: { showDeleteConfirm = true }
                )
            }
        }
        .fullScreenCover(isPresented: $showPINSetup) {
            PINSetupView(isPresented: $showPINSetup) {
                if pendingBiometricEnable {
                    pendingBiometricEnable = false
                    enableBiometrics()
                }
            }
            .environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showPINEntry) {
            PINEntryView(isPresented: $showPINEntry) { showPINSetup = true }
                .environmentObject(appState)
        }
        .alert(strings.settings("settings_biometric_unavailable"), isPresented: $showBiometricAlert) {
            Button(strings.common("common_ok"), role: .cancel) {}
        } message: {
            Text(strings.settings("settings_biometric_unavailable_message"))
        }
        .confirmationDialog(
            strings.settings("settings_delete_all_confirm_title"),
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(strings.settings("settings_delete_all_button"), role: .destructive) {
                appState.deleteAllDocuments()
            }
            Button(strings.common("common_cancel"), role: .cancel) {}
        } message: {
            Text(strings.settings("settings_delete_all_confirm_message"))
        }
        .onAppear(perform: sanitizeSelections)
        .onChange(of: biometricEnabled) { oldValue, newValue in
            guard oldValue != newValue else { return }
            if newValue {
                guard PINManager.hasPIN else {
                    pendingBiometricEnable = true
                    biometricEnabled = false
                    showPINSetup = true
                    return
                }
                enableBiometrics()
            } else if !pendingBiometricEnable {
                UserDefaults.standard.set(false, forKey: "shield.biometric")
            }
        }
        .onChange(of: autoLockIndex) { _, value in UserDefaults.standard.set(value, forKey: "shield.autoLock") }
        .onChange(of: hapticEnabled) { _, value in UserDefaults.standard.set(value, forKey: "shield.haptic") }
        .onChange(of: strictKYCEnabled) { _, value in UserDefaults.standard.set(value, forKey: "shield.ocr.strictKYC") }
        .onChange(of: warnLowConfidenceEnabled) { _, value in UserDefaults.standard.set(value, forKey: "shield.ocr.warnLowConfidence") }
        .onChange(of: confidenceIndex) { _, value in UserDefaults.standard.set(value, forKey: "shield.ocr.minConfidence") }
    }

    private func toggleRow(icon: String, color: Color, title: String, binding: Binding<Bool>) -> some View {
        SettingsControlRow(icon: icon, color: color, title: title) {
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(ShieldTheme.accent(scheme))
                .accessibilityLabel(title)
        }
    }

    private func sanitizeSelections() {
        autoLockIndex = max(0, min(autoLockIndex, autoLockOptions.count - 1))
        confidenceIndex = max(0, min(confidenceIndex, confidenceOptions.count - 1))
    }

    private func enableBiometrics() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricEnabled = false
            UserDefaults.standard.set(false, forKey: "shield.biometric")
            showBiometricAlert = true
            return
        }

        context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: strings.settings("settings_biometric_reason")
        ) { success, _ in
            DispatchQueue.main.async {
                biometricEnabled = success
                UserDefaults.standard.set(success, forKey: "shield.biometric")
                if !success { showBiometricAlert = true }
            }
        }
    }
}

// MARK: - Cloud and export

struct CloudSettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var scheme
    @StateObject private var premium = PremiumManager.shared
    @ObservedObject private var cloud = CloudSyncManager.shared
    @State private var isEnabled = UserDefaults.standard.bool(forKey: "shield.icloud.enabled")
    @State private var showPaywall = false

    private var strings: LanguageManager { .shared }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_icloud_sync"),
            subtitle: strings.settings("settings_icloud_detail")
        ) {
            SettingsCardSection(title: strings.settings("settings_sync_controls"), icon: "icloud.fill") {
                if premium.isPro {
                    SettingsControlRow(
                        icon: "icloud.fill",
                        color: Color(hex: "5E5CE6"),
                        title: strings.settings("settings_icloud_sync_with"),
                        subtitle: strings.settings("settings_icloud_minimized_note")
                    ) {
                        Toggle("", isOn: $isEnabled)
                            .labelsHidden()
                            .tint(ShieldTheme.accent(scheme))
                            .accessibilityLabel(strings.settings("settings_icloud_sync_with"))
                    }
                    if isEnabled {
                        SettingsRowDivider()
                        SettingsActionRow(
                            icon: "arrow.clockwise.icloud.fill",
                            color: Color(hex: "64D2FF"),
                            title: strings.settings("settings_icloud_sync_now"),
                            subtitle: syncStatus,
                            action: syncNow
                        )
                    }
                } else {
                    SettingsActionRow(
                        icon: "crown.fill",
                        color: Color(hex: "FF9F0A"),
                        title: strings.settings("settings_icloud_pro_only"),
                        subtitle: strings.settings("settings_icloud_pro_subtitle"),
                        action: { showPaywall = true }
                    )
                }
            }

            SettingsArticleCallout(
                icon: "hand.raised.fill",
                title: strings.settings("settings_private_by_design"),
                bodyText: strings.settings("settings_icloud_privacy_explanation")
            )
        }
        .onChange(of: isEnabled) { _, enabled in
            Task {
                let changed = await cloud.setSyncEnabled(enabled)
                if changed, enabled {
                    await cloud.syncNow(documents: appState.documents)
                } else if !changed {
                    await MainActor.run { isEnabled = !enabled }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: .settingsUpgrade)
                .environmentObject(appState)
        }
    }

    private var syncStatus: String {
        if case .syncing = cloud.syncStatus { return strings.settings("settings_syncing") }
        if let lastSync = cloud.lastSyncFormatted {
            return strings.settings("settings_last_sync_value", lastSync)
        }
        if !cloud.isAvailable { return strings.settings("settings_icloud_unavailable") }
        return strings.settings("settings_sync_ready")
    }

    private func syncNow() {
        Task { await cloud.syncNow(documents: appState.documents) }
    }
}

struct ExportSettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var formatIndex = UserDefaults.standard.integer(forKey: "shield.exportFormat")
    @State private var qualityIndex = UserDefaults.standard.integer(forKey: "shield.exportQuality")

    private var strings: LanguageManager { .shared }
    private var formats: [String] {
        [strings.settings("settings_format_pdf"), strings.settings("settings_format_image")]
    }
    private var qualities: [String] {
        [
            strings.settings("settings_quality_high"),
            strings.settings("settings_quality_medium"),
            strings.settings("settings_quality_low")
        ]
    }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_export_preferences"),
            subtitle: strings.settings("settings_export_detail")
        ) {
            SettingsCardSection(title: strings.settings("settings_export"), icon: "square.and.arrow.up.fill") {
                SettingsControlRow(
                    icon: "doc.fill",
                    color: Color(hex: "D9AA00"),
                    title: strings.settings("settings_default_format")
                ) {
                    Picker(strings.settings("settings_default_format"), selection: $formatIndex) {
                        ForEach(formats.indices, id: \.self) { index in Text(formats[index]).tag(index) }
                    }
                    .pickerStyle(.menu)
                    .tint(ShieldTheme.accent(scheme))
                }
                SettingsRowDivider()
                SettingsControlRow(
                    icon: "photo.fill",
                    color: Color(hex: "64D2FF"),
                    title: strings.settings("settings_image_quality")
                ) {
                    Picker(strings.settings("settings_image_quality"), selection: $qualityIndex) {
                        ForEach(qualities.indices, id: \.self) { index in Text(qualities[index]).tag(index) }
                    }
                    .pickerStyle(.menu)
                    .tint(ShieldTheme.accent(scheme))
                }
            }

            SettingsArticleCallout(
                icon: "checkmark.shield.fill",
                title: strings.settings("settings_verified_export_title"),
                bodyText: strings.settings("settings_verified_export_body")
            )
        }
        .onAppear {
            formatIndex = max(0, min(formatIndex, formats.count - 1))
            qualityIndex = max(0, min(qualityIndex, qualities.count - 1))
        }
        .onChange(of: formatIndex) { _, value in UserDefaults.standard.set(value, forKey: "shield.exportFormat") }
        .onChange(of: qualityIndex) { _, value in UserDefaults.standard.set(value, forKey: "shield.exportQuality") }
    }
}

// MARK: - About, legal, support, and FAQ

enum SettingsArticleKind {
    case information
    case privacy
    case terms
    case subscriptionTerms

    var titleKey: String {
        switch self {
        case .information: "settings_information_disclaimer"
        case .privacy: "settings_privacy_policy"
        case .terms: "settings_terms_service"
        case .subscriptionTerms: "settings_subscription_terms"
        }
    }

    var introKey: String {
        switch self {
        case .information: "settings_info_intro"
        case .privacy: "settings_privacy_intro"
        case .terms: "settings_terms_intro"
        case .subscriptionTerms: "settings_subscription_intro"
        }
    }

    var sectionKeys: [(String, String)] {
        switch self {
        case .information:
            [
                ("settings_info_scope_title", "settings_info_scope_body"),
                ("settings_info_detection_title", "settings_info_detection_body"),
                ("settings_info_export_title", "settings_info_export_body"),
                ("settings_info_security_title", "settings_info_security_body"),
                ("settings_info_health_title", "settings_info_health_body"),
                ("settings_info_responsibility_title", "settings_info_responsibility_body")
            ]
        case .privacy:
            [
                ("settings_privacy_controller_title", "settings_privacy_controller_body"),
                ("settings_privacy_processing_title", "settings_privacy_processing_body"),
                ("settings_privacy_storage_title", "settings_privacy_storage_body"),
                ("settings_privacy_icloud_title", "settings_privacy_icloud_body"),
                ("settings_privacy_permissions_title", "settings_privacy_permissions_body"),
                ("settings_privacy_diagnostics_title", "settings_privacy_diagnostics_body"),
                ("settings_privacy_retention_title", "settings_privacy_retention_body"),
                ("settings_privacy_rights_title", "settings_privacy_rights_body"),
                ("settings_privacy_children_title", "settings_privacy_children_body"),
                ("settings_privacy_changes_title", "settings_privacy_changes_body")
            ]
        case .terms:
            [
                ("settings_terms_acceptance_title", "settings_terms_acceptance_body"),
                ("settings_terms_license_title", "settings_terms_license_body"),
                ("settings_terms_user_content_title", "settings_terms_user_content_body"),
                ("settings_terms_permitted_title", "settings_terms_permitted_body"),
                ("settings_terms_accuracy_title", "settings_terms_accuracy_body"),
                ("settings_terms_purchases_title", "settings_terms_purchases_body"),
                ("settings_terms_ip_title", "settings_terms_ip_body"),
                ("settings_terms_liability_title", "settings_terms_liability_body"),
                ("settings_terms_termination_title", "settings_terms_termination_body"),
                ("settings_terms_law_title", "settings_terms_law_body")
            ]
        case .subscriptionTerms:
            [
                ("settings_subscription_products_title", "settings_subscription_products_body"),
                ("settings_subscription_payment_title", "settings_subscription_payment_body"),
                ("settings_subscription_renewal_title", "settings_subscription_renewal_body"),
                ("settings_subscription_trial_title", "settings_subscription_trial_body"),
                ("settings_subscription_manage_title", "settings_subscription_manage_body"),
                ("settings_subscription_restore_title", "settings_subscription_restore_body"),
                ("settings_subscription_refunds_title", "settings_subscription_refunds_body"),
                ("settings_subscription_lifetime_title", "settings_subscription_lifetime_body"),
                ("settings_subscription_changes_title", "settings_subscription_changes_body")
            ]
        }
    }

    var publicPage: ShieldPublicPage {
        switch self {
        case .information: .overview
        case .privacy: .privacy
        case .terms: .terms
        case .subscriptionTerms: .subscriptions
        }
    }
}

struct SettingsArticleView: View {
    let article: SettingsArticleKind
    private var strings: LanguageManager { .shared }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings(article.titleKey),
            subtitle: strings.settings(article.introKey)
        ) {
            SettingsArticleCallout(
                icon: article == .privacy ? "hand.raised.fill" : "exclamationmark.shield.fill",
                title: strings.settings("settings_legal_updated_title"),
                bodyText: strings.settings("settings_legal_updated_value")
            )

            ShieldPublicPageButton(
                page: article.publicPage,
                language: LanguageManager.shared.current
            )

            ForEach(article.sectionKeys, id: \.0) { titleKey, bodyKey in
                SettingsArticleSection(
                    title: strings.settings(titleKey),
                    bodyText: strings.settings(bodyKey)
                )
            }

            Text(strings.settings("settings_legal_draft_notice"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct SettingsArticleSection: View {
    let title: String
    let bodyText: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s2) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(ShieldTheme.primary(scheme))
                .accessibilityAddTraits(.isHeader)
            Text(bodyText)
                .font(.body)
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ShieldTheme.s4)
        .shieldSettingsCard()
    }
}

struct SettingsArticleCallout: View {
    let icon: String
    let title: String
    let bodyText: String
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(alignment: .top, spacing: ShieldTheme.s3) {
            Image(systemName: icon)
                .font(.title3.weight(.bold))
                .foregroundStyle(ShieldTheme.accent(scheme))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ShieldTheme.primary(scheme))
                Text(bodyText)
                    .font(.subheadline)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(ShieldTheme.s4)
        .background(ShieldTheme.accentDim(scheme))
        .overlay {
            RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 1)
        }
        .clipShape(.rect(cornerRadius: ShieldTheme.rMD))
    }
}

struct WhatsNewSettingsView: View {
    private var strings: LanguageManager { .shared }
    private let itemKeys = [
        "settings_whats_new_item_1", "settings_whats_new_item_2", "settings_whats_new_item_3",
        "settings_whats_new_item_4", "settings_whats_new_item_5", "settings_whats_new_item_6"
    ]

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_whats_new"),
            subtitle: strings.settings("settings_whats_new_intro")
        ) {
            SettingsCardSection(title: strings.settings("settings_version_value", appVersion), icon: "sparkles") {
                ForEach(Array(itemKeys.enumerated()), id: \.element) { index, key in
                    HStack(alignment: .top, spacing: ShieldTheme.s3) {
                        SettingsIconBadge(icon: "checkmark", color: Color(hex: "00C7BE"), size: 34)
                        Text(strings.settings(key))
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                    .padding(ShieldTheme.s4)
                    if index < itemKeys.count - 1 { SettingsRowDivider(inset: 62) }
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
}

struct SupportSettingsView: View {
    let onSendFeedback: () -> Void
    let onRate: () -> Void
    private var strings: LanguageManager { .shared }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_support"),
            subtitle: strings.settings("settings_support_intro")
        ) {
            SettingsArticleCallout(
                icon: "lifepreserver.fill",
                title: strings.settings("settings_support_before_contact_title"),
                bodyText: strings.settings("settings_support_before_contact_body")
            )

            ShieldPublicPageButton(page: .support, language: LanguageManager.shared.current)

            SettingsCardSection(title: strings.settings("settings_support_actions"), icon: "bubble.left.and.bubble.right.fill") {
                SettingsActionRow(
                    icon: "envelope.fill",
                    color: Color(hex: "30D158"),
                    title: strings.settings("settings_send_feedback"),
                    subtitle: strings.settings("settings_send_feedback_subtitle"),
                    accessibilityIdentifier: "settings.action.sendFeedback",
                    action: onSendFeedback
                )
                SettingsRowDivider()
                SettingsNavigationRow(
                    route: .faq,
                    icon: "questionmark.circle.fill",
                    color: Color(hex: "FF9F0A"),
                    title: strings.settings("settings_faq"),
                    subtitle: strings.settings("settings_faq_subtitle")
                )
                SettingsRowDivider()
                SettingsActionRow(
                    icon: "star.fill",
                    color: Color(hex: "FFD60A"),
                    title: strings.settings("settings_rate_app"),
                    subtitle: strings.settings("settings_rate_app_subtitle"),
                    accessibilityIdentifier: "settings.action.rateApp",
                    action: onRate
                )
            }

            SettingsArticleSection(
                title: strings.settings("settings_support_response_title"),
                bodyText: strings.settings("settings_support_response_body")
            )
        }
    }
}

struct FAQSettingsView: View {
    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }
    private let keys = Array(1...8)

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_faq"),
            subtitle: strings.settings("settings_faq_intro")
        ) {
            ShieldPublicPageButton(page: .faq, language: LanguageManager.shared.current)

            VStack(spacing: 0) {
                ForEach(keys, id: \.self) { index in
                    DisclosureGroup {
                        Text(strings.settings("settings_faq_\(index)_answer"))
                            .font(.subheadline)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, ShieldTheme.s2)
                            .padding(.bottom, ShieldTheme.s3)
                    } label: {
                        Text(strings.settings("settings_faq_\(index)_question"))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(ShieldTheme.primary(scheme))
                            .multilineTextAlignment(.leading)
                    }
                    .tint(ShieldTheme.accent(scheme))
                    .padding(ShieldTheme.s4)

                    if index < keys.count { SettingsRowDivider(inset: ShieldTheme.s4) }
                }
            }
            .shieldSettingsCard()
        }
    }
}

#if DEBUG
struct DeveloperSettingsView: View {
    @StateObject private var premium = PremiumManager.shared
    @Environment(\.colorScheme) private var scheme
    private var strings: LanguageManager { .shared }

    var body: some View {
        SettingsDetailScaffold(
            title: strings.settings("settings_developer_tools"),
            subtitle: strings.settings("settings_developer_tools_subtitle")
        ) {
            SettingsCardSection(title: strings.settings("settings_developer"), icon: "hammer.fill") {
                SettingsControlRow(
                    icon: "crown.fill",
                    color: Color(hex: "FF9F0A"),
                    title: strings.settings("settings_premium_override")
                ) {
                    Toggle("", isOn: Binding(
                        get: { premium.isDebugProOverride },
                        set: { premium.setDebugProOverride($0) }
                    ))
                    .labelsHidden()
                    .tint(ShieldTheme.accent(scheme))
                    .accessibilityLabel(strings.settings("settings_premium_override"))
                }
            }
        }
    }
}
#endif
