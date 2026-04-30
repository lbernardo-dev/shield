import SwiftUI
import LocalAuthentication
import MessageUI

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
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
    @State private var showPINSetup = false
    @State private var showPINEntry = false
    @State private var showBiometricAlert = false
    @State private var pendingBiometricEnable = false

    @State private var expandedRow: ExpandedRow? = nil

    enum ExpandedRow: Equatable { case autoLock, exportFormat, exportQuality, ocrConfidence }

    private let autoLockOptions   = ["Inmediato", "1 minuto", "5 minutos", "15 minutos", "Nunca"]
    private let autoLockOptionsEN = ["Immediately", "1 minute", "5 minutes", "15 minutes", "Never"]
    private let exportFormats     = ["PDF", "Imagen"]
    private let exportFormatsEN   = ["PDF", "Image"]
    private let exportQualities   = ["Alta", "Media", "Baja"]
    private let exportQualitiesEN = ["High", "Medium", "Low"]
    private let ocrConfidenceOptions = ["70%", "80%", "90%"]
    private let ocrConfidenceOptionsEN = ["70%", "80%", "90%"]

    var body: some View {
        ZStack {
            ShieldTheme.pageBackground(scheme).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Title
                    HStack {
                        Text(appState.language == .es ? "Ajustes" : "Settings")
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
                    settingsSection(title: appState.language == .es ? "Apariencia" : "Appearance") {
                        // Theme
                        settingsRow(
                            icon: "moon.fill",
                            iconColor: "5E5CE6",
                            title: appState.language == .es ? "Modo oscuro" : "Dark mode"
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
                            title: appState.language == .es ? "Idioma" : "Language"
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
                    settingsSection(title: appState.language == .es ? "Seguridad" : "Security") {
                        settingsRow(
                            icon: "faceid",
                            iconColor: "30D158",
                            title: appState.language == .es ? "Face ID / Touch ID" : "Face ID / Touch ID"
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
                            title: appState.language == .es
                                ? (PINManager.hasPIN ? "Cambiar PIN" : "Configurar PIN")
                                : (PINManager.hasPIN ? "Change PIN" : "Set up PIN")
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
                            title: appState.language == .es ? "Bloqueo automático" : "Auto-lock",
                            value: appState.language == .es
                                ? autoLockOptions[autoLockIndex]
                                : autoLockOptionsEN[autoLockIndex],
                            row: .autoLock
                        ) {
                            Picker("", selection: $autoLockIndex) {
                                ForEach(0..<autoLockOptions.count, id: \.self) { i in
                                    Text(appState.language == .es
                                         ? autoLockOptions[i]
                                         : autoLockOptionsEN[i]).tag(i)
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
                            title: appState.language == .es ? "Vibración háptica" : "Haptic feedback"
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
                            title: appState.language == .es ? "OCR KYC estricto (MRZ)" : "Strict KYC OCR (MRZ)"
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
                            title: appState.language == .es ? "Alerta OCR baja confianza" : "Low-confidence OCR alert"
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
                            title: appState.language == .es ? "Umbral mínimo OCR" : "OCR minimum threshold",
                            value: appState.language == .es
                                ? ocrConfidenceOptions[ocrConfidenceIndex]
                                : ocrConfidenceOptionsEN[ocrConfidenceIndex],
                            row: .ocrConfidence
                        ) {
                            Picker("", selection: $ocrConfidenceIndex) {
                                ForEach(0..<ocrConfidenceOptions.count, id: \.self) { i in
                                    Text(appState.language == .es
                                         ? ocrConfidenceOptions[i]
                                         : ocrConfidenceOptionsEN[i]).tag(i)
                                }
                            }
                            .pickerStyle(.inline)
                            .onChange(of: ocrConfidenceIndex) { _, v in
                                UserDefaults.standard.set(v, forKey: "shield.ocr.minConfidence")
                            }
                        }
                    }

                    // Export defaults
                    settingsSection(title: appState.language == .es ? "Exportación" : "Export") {
                        expandableRow(
                            icon: "doc.fill",
                            iconColor: "FFD60A",
                            title: appState.language == .es ? "Formato por defecto" : "Default format",
                            value: appState.language == .es
                                ? exportFormats[exportFormatIndex]
                                : exportFormatsEN[exportFormatIndex],
                            row: .exportFormat
                        ) {
                            Picker("", selection: $exportFormatIndex) {
                                ForEach(0..<exportFormats.count, id: \.self) { i in
                                    Text(appState.language == .es
                                         ? exportFormats[i]
                                         : exportFormatsEN[i]).tag(i)
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
                            title: appState.language == .es ? "Calidad de imagen" : "Image quality",
                            value: appState.language == .es
                                ? exportQualities[exportQualityIndex]
                                : exportQualitiesEN[exportQualityIndex],
                            row: .exportQuality
                        ) {
                            Picker("", selection: $exportQualityIndex) {
                                ForEach(0..<exportQualities.count, id: \.self) { i in
                                    Text(appState.language == .es
                                         ? exportQualities[i]
                                         : exportQualitiesEN[i]).tag(i)
                                }
                            }
                            .pickerStyle(.inline)
                            .onChange(of: exportQualityIndex) { _, v in
                                UserDefaults.standard.set(v, forKey: "shield.exportQuality")
                            }
                        }
                    }

                    // About
                    settingsSection(title: appState.language == .es ? "Acerca de" : "About") {
                        settingsRow(
                            icon: "info.circle.fill",
                            iconColor: "5E5CE6",
                            title: appState.language == .es ? "Versión" : "Version"
                        ) {
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                                .font(.system(size: 14))
                                .foregroundColor(ShieldTheme.tertiary(scheme))
                        }

                        ShieldDivider().padding(.leading, 54)

                        settingsRowButton(
                            icon: "star.fill",
                            iconColor: "FFD60A",
                            title: appState.language == .es ? "Valorar la app" : "Rate the app"
                        ) {
                            if let url = URL(string: "itms-apps://itunes.apple.com/app/id6745955196?action=write-review") {
                                UIApplication.shared.open(url)
                            }
                        }

                        ShieldDivider().padding(.leading, 54)

                        settingsRowButton(
                            icon: "envelope.fill",
                            iconColor: "30D158",
                            title: appState.language == .es ? "Contacto y soporte" : "Contact & support"
                        ) {
                            if MFMailComposeViewController.canSendMail() {
                                showMailCompose = true
                            } else {
                                let subject = (appState.language == .es ? "Soporte Shield" : "Shield Support")
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
                    settingsSection(title: appState.language == .es ? "Privacidad" : "Privacy") {
                        settingsRowButton(
                            icon: "trash.fill",
                            iconColor: "FF453A",
                            title: appState.language == .es ? "Borrar todos los documentos" : "Delete all documents",
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
            }
        }
        .fullScreenCover(isPresented: $showPINEntry) {
            PINEntryView(isPresented: $showPINEntry) {
                showPINSetup = true
            }
        }
        .alert(
            appState.language == .es ? "Biometría no disponible" : "Biometrics unavailable",
            isPresented: $showBiometricAlert
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(appState.language == .es
                 ? "Face ID / Touch ID no está configurado en este dispositivo."
                 : "Face ID / Touch ID is not set up on this device.")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: paywallTrigger)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showMailCompose) {
            MailComposeView(
                recipient: "support@shieldapp.io",
                subject: appState.language == .es ? "Soporte Shield" : "Shield Support",
                body: appState.language == .es ? "Hola, necesito ayuda con..." : "Hi, I need help with..."
            )
        }
        .confirmationDialog(
            appState.language == .es ? "¿Borrar todos los documentos?" : "Delete all documents?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button(appState.language == .es ? "Borrar todo" : "Delete all", role: .destructive) {
                appState.deleteAllDocuments()
            }
            Button(appState.language == .es ? "Cancelar" : "Cancel", role: .cancel) {}
        } message: {
            Text(appState.language == .es
                 ? "Esta acción no se puede deshacer."
                 : "This action cannot be undone.")
        }
        .onAppear {
            sanitizePreferences()
        }
    }

    // MARK: - Developer section (DEBUG only)

    #if DEBUG
    private var developerSection: some View {
        settingsSection(title: "Developer") {
            settingsRow(
                icon: "hammer.fill",
                iconColor: "FF6B35",
                title: appState.language == .es ? "Modo Premium (prueba)" : "Premium override"
            ) {
                ShieldToggle(isOn: Binding(
                    get: { pm.isDebugProOverride },
                    set: { pm.setDebugProOverride($0) }
                ))
            }
        }
    }
    #endif

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
                    Text(appState.language == .es
                         ? "Activa todas las funciones premium"
                         : "Unlock all premium features")
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
                Text("Shield Pro — Activo")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Text(appState.language == .es
                     ? "Todas las funciones desbloqueadas"
                     : "All features unlocked")
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
            localizedReason: appState.language == .es
                ? "Verifica tu identidad para activar Face ID"
                : "Verify your identity to enable Face ID"
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
