import SwiftUI
import LocalAuthentication
import CryptoKit
import Security

// MARK: - VaultView

struct VaultView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @Environment(\.scenePhase) private var scenePhase
    @State private var isUnlocked: Bool = {
#if DEBUG
        ASOScreenshotMode.isEnabled && ASOScreenshotMode.scene == "vault"
#else
        false
#endif
    }()
    @State private var authError: String? = nil
    @State private var selectedDoc: DocumentItem? = nil
    @State private var showPINSetup = false
    @State private var showPINEntry = false
    @State private var showAddToVault = false
    @State private var shouldAuthenticateOnGateAppearance = true

    var body: some View {
        ZStack {
            ShieldTheme.pageBackground(scheme).ignoresSafeArea()

            if !isUnlocked {
                lockGate
            } else {
                vaultContent
            }
        }
        .fullScreenCover(isPresented: $showPINSetup) {
            PINSetupView(isPresented: $showPINSetup) {
                isUnlocked = true
            }.environmentObject(appState)
        }
        .fullScreenCover(isPresented: $showPINEntry) {
            PINEntryView(isPresented: $showPINEntry) {
                isUnlocked = true
            }.environmentObject(appState)
        }
        .fullScreenCover(item: $selectedDoc) { doc in
            EditorView(doc: doc).environmentObject(appState)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                isUnlocked = false
                selectedDoc = nil
            }
        }
    }

    // MARK: - Lock gate

    private var lockGate: some View {
        VStack(spacing: 28) {
            Spacer()
            MaskIDIdentityMark(
                size: 160,
                presentation: .animatedLoop,
                treatment: .hero
            )
            VStack(spacing: 8) {
                Text(LanguageManager.shared.vault("vault_locked_title"))
                    .shieldFont(24, weight: .heavy, design: .rounded)
                    .foregroundColor(ShieldTheme.primary(scheme))
                Text(LanguageManager.shared.vault("vault_locked_desc"))
                    .shieldFont(14, weight: .medium)
                    .foregroundColor(ShieldTheme.secondary(scheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            if let err = authError {
                Text(err)
                    .shieldFont(13, weight: .semibold)
                    .foregroundColor(ShieldTheme.danger)
            }

            VStack(spacing: 12) {
                ShieldButton(
                    label: LanguageManager.shared.vault("vault_unlock_faceid"),
                    icon: "faceid",
                    height: 52
                ) {
                    authenticate()
                }
                .padding(.horizontal, 36)
                .accessibilityIdentifier("vault.unlock")

                if PINManager.hasPIN {
                    Button { showPINEntry = true } label: {
                        Text(LanguageManager.shared.vault("vault_use_pin"))
                            .shieldFont(14, weight: .bold)
                            .foregroundColor(ShieldTheme.accent(scheme))
                            .padding(.vertical, 4)
                    }
                } else {
                    Button { showPINSetup = true } label: {
                        Text(LanguageManager.shared.vault("vault_setup_pin"))
                            .shieldFont(14, weight: .semibold)
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                            .padding(.vertical, 4)
                    }
                }
            }
            .frame(maxWidth: 480)
            Spacer()
        }
        .onAppear {
#if DEBUG
            if ASOScreenshotMode.isEnabled {
                shouldAuthenticateOnGateAppearance = false
                return
            }
#endif
            guard shouldAuthenticateOnGateAppearance else { return }
            shouldAuthenticateOnGateAppearance = false
            authenticate()
        }
    }

    // MARK: - Vault content

    private var vaultContent: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .shieldFont(18, weight: .bold)
                            .foregroundColor(ShieldTheme.success)
                        Text(LanguageManager.shared.vault("vault_title"))
                            .shieldFont(28, weight: .heavy, design: .rounded)
                            .foregroundColor(ShieldTheme.primary(scheme))
                    }
                    Text(LanguageManager.shared.vault("vault_status_count", appState.vaultDocuments.count))
                        .shieldFont(12, weight: .medium)
                        .foregroundColor(ShieldTheme.secondary(scheme))
                        .lineLimit(1)
                }
                Spacer(minLength: ShieldTheme.s2)

                Button {
                    lockVault()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "lock.fill")
                            .shieldFont(11, weight: .bold)
                        Text(LanguageManager.shared.vault("vault_lock_button"))
                            .shieldFont(12, weight: .bold)
                    }
                    .foregroundColor(Color(hex: "FF6B6B"))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color(hex: "FF3B30").opacity(0.14), in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "FF3B30").opacity(0.35), lineWidth: 0.8)
                    )
                }
                .accessibilityIdentifier("vault.lock")
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 8)

            securitySummary
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

            ScrollView(showsIndicators: false) {
                Group {
                    if appState.vaultDocuments.isEmpty {
                        ShieldStateView(
                            kind: .empty,
                            title: LanguageManager.shared.vault("vault_empty_title"),
                            message: LanguageManager.shared.vault("vault_empty_desc"),
                            actionLabel: LanguageManager.shared.vault("vault_add_to_vault")
                        ) {
                            showAddToVault = true
                        }
                        .frame(minHeight: 260)
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 300, maximum: 540), spacing: 12)],
                            alignment: .leading,
                            spacing: 12
                        ) {
                            ForEach(appState.vaultDocuments) { doc in
                                DocumentRow(doc: doc, lang: appState.language, vaultUnlocked: true) {
                                    selectedDoc = doc
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        appState.deleteDocument(doc)
                                    } label: {
                                        Label(LanguageManager.shared.common("common_delete"), systemImage: "trash")
                                    }
                                    Button {
                                        appState.toggleVault(doc)
                                    } label: {
                                        Label(LanguageManager.shared.vault("vault_move_out"), systemImage: "lock.open")
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: 1_100)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !appState.vaultDocuments.isEmpty {
                ShieldStickyFooter {
                    ShieldButton(
                        label: LanguageManager.shared.vault("vault_add_to_vault"),
                        icon: "plus.circle.fill",
                        style: .secondary
                    ) {
                        showAddToVault = true
                    }
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .sheet(isPresented: $showAddToVault) {
            AddToVaultSheet(isPresented: $showAddToVault)
                .environmentObject(appState)
        }
    }

    private var securitySummary: some View {
        HStack(spacing: 8) {
            ShieldStatusLabel(
                text: LanguageManager.shared.vault("vault_aes_badge"),
                kind: .success
            )
            .fixedSize(horizontal: true, vertical: true)

            ShieldStatusLabel(
                text: LanguageManager.shared.vault("vault_on_device"),
                kind: .info
            )
            .fixedSize(horizontal: true, vertical: true)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Auth

    private func lockVault() {
        selectedDoc = nil
        authError = nil
        shouldAuthenticateOnGateAppearance = false
        withAnimation { isUnlocked = false }
        AppState.trackEvent("vault_locked", properties: ["method": "manual"])
    }

    private func authenticate() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            presentPINFallback()
            return
        }
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: LanguageManager.shared.vault("vault_reason")
        ) { success, evalError in
            DispatchQueue.main.async {
                if success {
                    self.isUnlocked = true
                    self.authError = nil
                    AppState.trackEvent("vault_unlocked", properties: ["method": "biometric"])
                } else {
                    self.authError = evalError?.localizedDescription
                    self.presentPINFallback()
                }
            }
        }
    }

    private func presentPINFallback() {
        if PINManager.hasPIN {
            showPINEntry = true
        } else {
            showPINSetup = true
        }
    }
}

// MARK: - AddToVaultSheet

struct AddToVaultSheet: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @State private var selectedDocs: Set<String> = []

    private var eligibleDocuments: [DocumentItem] {
        appState.documents.filter { !$0.isVaulted }
    }

    var body: some View {
        NavigationView {
            ZStack {
                ShieldTheme.pageBackground(scheme).ignoresSafeArea()

                if eligibleDocuments.isEmpty {
                    // All-vaulted empty state
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [ShieldTheme.success.opacity(0.25), ShieldTheme.accent.opacity(0.15)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 96, height: 96)
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [ShieldTheme.success, ShieldTheme.accent],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                        }
                        VStack(spacing: 8) {
                            Text(LanguageManager.shared.vault("vault_all_vaulted_title"))
                                .shieldFont(18, weight: .bold)
                                .foregroundColor(ShieldTheme.primary(scheme))
                            Text(LanguageManager.shared.vault("vault_all_vaulted_desc"))
                                .shieldFont(14)
                                .foregroundColor(ShieldTheme.secondary(scheme))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(eligibleDocuments) { doc in
                                VaultPickerRow(
                                    doc: doc,
                                    isSelected: selectedDocs.contains(doc.id),
                                    language: appState.language,
                                    scheme: scheme
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                        if selectedDocs.contains(doc.id) {
                                            selectedDocs.remove(doc.id)
                                        } else {
                                            selectedDocs.insert(doc.id)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, ShieldTheme.s5)
                        .padding(.vertical, ShieldTheme.s4)
                    }
                }
            }
            .navigationTitle(LanguageManager.shared.vault("vault_add_to_vault"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LanguageManager.shared.common("common_cancel")) {
                        isPresented = false
                    }
                    .foregroundColor(ShieldTheme.accent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(LanguageManager.shared.vault("vault_move_to_vault")) {
                        for id in selectedDocs {
                            if let doc = appState.documents.first(where: { $0.id == id }) {
                                appState.toggleVault(doc)
                            }
                        }
                        isPresented = false
                    }
                    .disabled(selectedDocs.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - VaultPickerRow

private struct VaultPickerRow: View {
    let doc: DocumentItem
    let isSelected: Bool
    let language: AppLanguage
    let scheme: ColorScheme

    @State private var thumbnail: UIImage? = nil

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(ShieldTheme.cardBackground(scheme))
                    .frame(width: 60, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected
                                    ? ShieldTheme.accent
                                    : ShieldTheme.surfaceLine,
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                if let img = thumbnail {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Image(systemName: doc.sourceType == .pdf ? "doc.richtext" : "photo")
                        .font(.system(size: 22))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                }
            }
            .shadow(color: Color.black.opacity(isSelected ? 0.18 : 0.06), radius: isSelected ? 6 : 3, y: 2)
            .animation(.spring(response: 0.3), value: isSelected)

            // Info
            VStack(alignment: .leading, spacing: 5) {
                Text(doc.title)
                    .shieldFont(15, weight: .semibold)
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .lineLimit(2)

                HStack(spacing: 6) {
                    // Category badge
                    Text(doc.category.label(lang: language))
                        .shieldFont(11, weight: .medium)
                        .foregroundColor(ShieldTheme.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(ShieldTheme.accent.opacity(0.12))
                        .clipShape(Capsule())

                    // Page count
                    if doc.pageCount > 1 {
                        Text("\(doc.pageCount) págs.")
                            .shieldFont(11)
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                    }
                }

                // Date
                Text(doc.compactDateLabel(lang: language))
                    .shieldFont(11)
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }

            Spacer()

            // Selection indicator
            ZStack {
                Circle()
                    .stroke(isSelected ? ShieldTheme.accent : ShieldTheme.surfaceLineStrong, lineWidth: 2)
                    .frame(width: 26, height: 26)
                if isSelected {
                    Circle()
                        .fill(ShieldTheme.accent)
                        .frame(width: 26, height: 26)
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(ShieldTheme.cardBackground(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? ShieldTheme.accent.opacity(0.4) : ShieldTheme.surfaceLine,
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        .onAppear { loadThumbnail() }
    }

    private func loadThumbnail() {
        guard thumbnail == nil else { return }
        let fileName = doc.imageFileName(for: 0)
        guard let name = fileName else { return }
        thumbnail = AppState.loadImage(fileName: name, isVaulted: doc.isVaulted)
    }
}

// MARK: - PINManager

enum PINManager {
    private static let service = "com.romerodev.shield.vault"
    private static let account = "vault-pin"
    private static let lockoutAccount = "vault-pin-lockout"
    private static let lockoutBaseSeconds = 30
    private static let lockoutStartAttempt = 3
    private static let maxBackoffExponent = 6
    private static let derivationIterations = 60_000

    private struct PINRecord: Codable {
        let version: Int
        let salt: Data
        let digest: Data
        let iterations: Int
    }

    private struct LockoutRecord: Codable {
        var failedAttempts: Int
        var lockoutUntil: TimeInterval
    }

    static var hasPIN: Bool {
        (try? KeychainStore.read(service: service, account: account)) != nil
    }

    static var isLockedOut: Bool {
        lockoutRemainingSeconds() > 0
    }

    static func save(pin: String) {
        guard pin.count == 6 else { return }
        var salt = Data(count: 16)
        let status = salt.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!)
        }
        guard status == errSecSuccess else { return }
        let record = PINRecord(
            version: 2,
            salt: salt,
            digest: derive(pin: pin, salt: salt, iterations: derivationIterations),
            iterations: derivationIterations
        )
        guard let encoded = try? JSONEncoder().encode(record) else { return }
        try? KeychainStore.save(
            encoded,
            service: service,
            account: account,
            accessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        )
        resetLockout()
    }

    static func verify(pin: String) -> Bool {
        guard !isLockedOut else { return false }
        guard let stored = try? KeychainStore.read(service: service, account: account) else { return false }
        let isValid: Bool
        if let record = try? JSONDecoder().decode(PINRecord.self, from: stored),
           record.version == 2,
           record.iterations >= 10_000 {
            let candidate = derive(pin: pin, salt: record.salt, iterations: record.iterations)
            isValid = constantTimeEqual(candidate, record.digest)
        } else if let data = pin.data(using: .utf8) {
            // One-time migration from the legacy unsalted SHA-256 record.
            isValid = constantTimeEqual(Data(SHA256.hash(data: data)), stored)
            if isValid { save(pin: pin) }
        } else {
            isValid = false
        }
        if isValid {
            resetLockout()
        } else {
            registerFailure()
        }
        return isValid
    }

    static func clear() {
        KeychainStore.delete(service: service, account: account)
        KeychainStore.delete(service: service, account: lockoutAccount)
        resetLockout()
    }

    static func lockoutRemainingSeconds() -> Int {
        let until = loadLockout().lockoutUntil
        guard until > 0 else { return 0 }
        let remaining = Int(ceil(until - Date().timeIntervalSince1970))
        if remaining <= 0 {
            resetLockout()
            return 0
        }
        return remaining
    }

    private static func registerFailure() {
        var record = loadLockout()
        record.failedAttempts += 1

        guard record.failedAttempts >= lockoutStartAttempt else {
            record.lockoutUntil = 0
            saveLockout(record)
            return
        }

        let exponent = min(record.failedAttempts - lockoutStartAttempt, maxBackoffExponent)
        let delay = lockoutBaseSeconds * Int(pow(2.0, Double(exponent)))
        record.lockoutUntil = Date().addingTimeInterval(TimeInterval(delay)).timeIntervalSince1970
        saveLockout(record)
    }

    private static func resetLockout() {
        KeychainStore.delete(service: service, account: lockoutAccount)
        UserDefaults.standard.removeObject(forKey: "shield.pin.failedAttempts")
        UserDefaults.standard.removeObject(forKey: "shield.pin.lockoutUntil")
    }

    private static func loadLockout() -> LockoutRecord {
        guard let data = try? KeychainStore.read(service: service, account: lockoutAccount),
              let record = try? JSONDecoder().decode(LockoutRecord.self, from: data) else {
            return LockoutRecord(failedAttempts: 0, lockoutUntil: 0)
        }
        return record
    }

    private static func saveLockout(_ record: LockoutRecord) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        try? KeychainStore.save(
            data,
            service: service,
            account: lockoutAccount,
            accessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        )
    }

    private static func derive(pin: String, salt: Data, iterations: Int) -> Data {
        let key = SymmetricKey(data: salt)
        var digest = Data(HMAC<SHA256>.authenticationCode(for: Data(pin.utf8) + salt, using: key))
        for _ in 1..<iterations {
            digest = Data(HMAC<SHA256>.authenticationCode(for: digest, using: key))
        }
        return digest
    }

    private static func constantTimeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        var difference: UInt8 = 0
        for (left, right) in zip(lhs, rhs) {
            difference |= left ^ right
        }
        return difference == 0
    }
}

// MARK: - PINSetupView

struct PINSetupView: View {
    @Binding var isPresented: Bool
    var onSuccess: () -> Void
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    @State private var pin = ""
    @State private var confirmPin = ""
    @State private var step = 0  // 0=enter, 1=confirm
    @State private var errorMsg = ""

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "lock.fill")
                .shieldFont(44, weight: .light)
                .foregroundColor(ShieldTheme.accent)

            Text(step == 0
                 ? LanguageManager.shared.vault("vault_pin_setup_choose")
                 : LanguageManager.shared.vault("vault_pin_setup_confirm"))
                .shieldFont(20, weight: .bold)
                .foregroundColor(ShieldTheme.primary(scheme))

            // PIN dots
            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i < currentPin.count ? ShieldTheme.accent : ShieldTheme.rowBackground(scheme))
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(ShieldTheme.line(scheme), lineWidth: 1))
                }
            }

            if !errorMsg.isEmpty {
                Text(errorMsg)
                    .shieldFont(14)
                    .foregroundColor(ShieldTheme.danger)
            }

            // Numpad
            PINNumpad(onDigit: handleDigit, onDelete: handleDelete)

            Button { isPresented = false } label: {
                Text(LanguageManager.shared.capture("capture_cancel"))
                    .shieldFont(15)
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ShieldTheme.pageBackground(scheme).ignoresSafeArea())
        .preferredColorScheme(appState.preferredScheme)
    }

    private var currentPin: String { step == 0 ? pin : confirmPin }

    private func handleDigit(_ d: String) {
        guard currentPin.count < 6 else { return }
        errorMsg = ""
        if step == 0 { pin += d } else { confirmPin += d }
        if currentPin.count == 6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { advance() }
        }
    }

    private func handleDelete() {
        if step == 0 { if !pin.isEmpty { pin.removeLast() } }
        else { if !confirmPin.isEmpty { confirmPin.removeLast() } }
    }

    private func advance() {
        if step == 0 {
            step = 1
        } else {
            if pin == confirmPin {
                PINManager.save(pin: pin)
                isPresented = false
                AppState.trackEvent("vault_unlocked", properties: ["method": "pin_setup"])
                onSuccess()
            } else {
                errorMsg = LanguageManager.shared.vault("vault_pin_mismatch")
                pin = ""; confirmPin = ""; step = 0
            }
        }
    }
}

// MARK: - PINEntryView

struct PINEntryView: View {
    @Binding var isPresented: Bool
    var onSuccess: () -> Void
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    @State private var pin = ""
    @State private var errorMsg = ""
    @State private var lockoutRemaining = 0
    @State private var lockoutTimer: Timer?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "lock.fill")
                .shieldFont(44, weight: .light)
                .foregroundColor(ShieldTheme.accent)

            Text(LanguageManager.shared.vault("vault_pin_entry_prompt"))
                .shieldFont(20, weight: .bold)
                .foregroundColor(ShieldTheme.primary(scheme))

            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i < pin.count ? ShieldTheme.accent : ShieldTheme.rowBackground(scheme))
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(ShieldTheme.line(scheme), lineWidth: 1))
                }
            }

            if !errorMsg.isEmpty {
                Text(errorMsg)
                    .shieldFont(14)
                    .foregroundColor(ShieldTheme.danger)
            }

            if lockoutRemaining > 0 {
                Text(LanguageManager.shared.vault("vault_pin_try_again_in", lockoutRemaining))
                    .shieldFont(13)
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }

            PINNumpad(onDigit: handleDigit, onDelete: handleDelete, isDisabled: lockoutRemaining > 0)

            Button { isPresented = false } label: {
                Text(LanguageManager.shared.capture("capture_cancel"))
                    .shieldFont(15)
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ShieldTheme.pageBackground(scheme).ignoresSafeArea())
        .preferredColorScheme(appState.preferredScheme)
        .onAppear {
            refreshLockoutState()
            startLockoutTimer()
        }
        .onDisappear {
            lockoutTimer?.invalidate()
            lockoutTimer = nil
        }
    }

    private func handleDigit(_ d: String) {
        guard lockoutRemaining == 0 else { return }
        guard pin.count < 6 else { return }
        errorMsg = ""
        pin += d
        if pin.count == 6 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { verify() }
        }
    }

    private func handleDelete() {
        if !pin.isEmpty { pin.removeLast() }
    }

    private func verify() {
        guard lockoutRemaining == 0 else { return }
        if PINManager.verify(pin: pin) {
            isPresented = false
            AppState.trackEvent("vault_unlocked", properties: ["method": "pin_entry"])
            onSuccess()
        } else {
            refreshLockoutState()
            if lockoutRemaining > 0 {
                errorMsg = LanguageManager.shared.vault("vault_pin_too_many_attempts", lockoutRemaining)
            } else {
                errorMsg = LanguageManager.shared.vault("vault_pin_incorrect")
            }
            pin = ""
        }
    }

    private func refreshLockoutState() {
        lockoutRemaining = PINManager.lockoutRemainingSeconds()
    }

    private func startLockoutTimer() {
        lockoutTimer?.invalidate()
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                let remaining = PINManager.lockoutRemainingSeconds()
                lockoutRemaining = remaining
                if remaining == 0, !errorMsg.isEmpty, errorMsg.contains("Wait") || errorMsg.contains("Espera") {
                    errorMsg = ""
                }
            }
        }
    }
}

// MARK: - PINNumpad

struct PINNumpad: View {
    var onDigit: (String) -> Void
    var onDelete: () -> Void
    var isDisabled: Bool = false
    @Environment(\.colorScheme) var scheme

    private let digits = [["1","2","3"],["4","5","6"],["7","8","9"],["","0","⌫"]]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(digits, id: \.self) { row in
                HStack(spacing: 20) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            if key == "⌫" { onDelete() }
                            else if !key.isEmpty { onDigit(key) }
                        } label: {
                            ZStack {
                                if !key.isEmpty {
                                    Circle()
                                        .fill(ShieldTheme.rowBackground(scheme))
                                        .frame(width: 72, height: 72)
                                } else {
                                    Color.clear
                                        .frame(width: 72, height: 72)
                                }
                                if key == "⌫" {
                                    Image(systemName: "delete.left")
                                        .shieldFont(20, weight: .medium)
                                        .foregroundColor(ShieldTheme.primary(scheme))
                                } else if !key.isEmpty {
                                    Text(key)
                                        .shieldFont(26, weight: .medium)
                                        .foregroundColor(ShieldTheme.primary(scheme))
                                }
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .disabled(key.isEmpty || isDisabled)
                        .opacity(isDisabled && !key.isEmpty ? 0.45 : 1)
                    }
                }
            }
        }
    }
}
