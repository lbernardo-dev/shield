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
            ZStack {
                if #available(iOS 26, *) {
                    Color.clear
                        .glassEffect(.regular.tint(Color(hex: "FFD60A").opacity(0.15)), in: .rect(cornerRadius: 32))
                        .frame(width: 120, height: 120)
                } else {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color(hex: "FFD60A").opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color(hex: "FFD60A").opacity(0.25), lineWidth: 1.5))
                        .frame(width: 120, height: 120)
                }
                Image(systemName: "faceid").font(.system(size: 54, weight: .light)).foregroundColor(ShieldTheme.accent)
            }
            VStack(spacing: 6) {
                Text(LanguageManager.shared.vault("vault_locked_title"))
                    .font(.system(size: 22, weight: .bold)).foregroundColor(ShieldTheme.primary(scheme))
                Text(LanguageManager.shared.vault("vault_locked_desc"))
                    .font(.system(size: 14)).foregroundColor(ShieldTheme.secondary(scheme))
            }
            if let err = authError {
                Text(err).font(.system(size: 13)).foregroundColor(ShieldTheme.danger)
            }

            VStack(spacing: 10) {
                Button { authenticate() } label: {
                    Label(LanguageManager.shared.vault("vault_unlock_faceid"), systemImage: "faceid")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(ShieldTheme.accent).foregroundColor(ShieldTheme.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle()).padding(.horizontal, 40)

                if PINManager.hasPIN {
                    Button { showPINEntry = true } label: {
                        Text(LanguageManager.shared.vault("vault_use_pin"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ShieldTheme.accent)
                    }
                } else {
                    Button { showPINSetup = true } label: {
                        Text(LanguageManager.shared.vault("vault_setup_pin"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                    }
                }
            }
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
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ShieldTheme.success)
                        Text(LanguageManager.shared.vault("vault_title"))
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(ShieldTheme.primary(scheme))
                            .tracking(-0.5)
                    }
                    Text(LanguageManager.shared.vault("vault_status_count", appState.vaultDocuments.count))
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.success)
                }
                Spacer()
                Button {
                    lockVault()
                } label: {
                    Label(LanguageManager.shared.vault("vault_lock_button"), systemImage: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ShieldTheme.danger)
                        .padding(.horizontal, 12).frame(height: 32)
                        .background(ShieldTheme.dangerDim)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    if appState.vaultDocuments.isEmpty {
                        emptyVaultState
                    } else {
                        ForEach(appState.vaultDocuments) { doc in
                            DocumentRow(doc: doc, lang: appState.language, vaultUnlocked: true) {
                                selectedDoc = doc
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
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
                                .tint(.orange)
                            }
                        }
                    }

                    // Add to vault CTA
                    Button { showAddToVault = true } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle.fill").font(.system(size: 18)).foregroundColor(ShieldTheme.accent)
                            Text(LanguageManager.shared.vault("vault_add_to_vault"))
                                .font(.system(size: 14, weight: .semibold)).foregroundColor(ShieldTheme.accent)
                        }
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(ShieldTheme.accentDim)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShieldTheme.accent.opacity(0.3), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal, 16).padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showAddToVault) {
            AddToVaultSheet(isPresented: $showAddToVault)
                .environmentObject(appState)
        }
    }

    private var emptyVaultState: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.rectangle.stack")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(ShieldTheme.tertiary(scheme))
                .padding(.top, 40)
            Text(LanguageManager.shared.vault("vault_empty_title"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ShieldTheme.secondary(scheme))
            Text(LanguageManager.shared.vault("vault_empty_desc"))
                .font(.system(size: 14))
                .foregroundColor(ShieldTheme.tertiary(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
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
            localizedReason: LanguageManager.shared.vault("vault_biometric_reason")
        ) { success, err in
            DispatchQueue.main.async {
                if success {
                    withAnimation { isUnlocked = true; authError = nil }
                    AppState.trackEvent("vault_unlocked", properties: ["method": "biometric"])
                } else {
                    authError = err?.localizedDescription
                    if let laError = err as? LAError, laError.code != .userCancel, laError.code != .appCancel {
                        presentPINFallback()
                    }
                }
            }
        }
    }

    private func presentPINFallback() {
        if PINManager.hasPIN {
            showPINEntry = true
            authError = nil
            return
        }
        showPINSetup = true
        authError = LanguageManager.shared.vault("vault_pin_setup_help")
    }
}

// MARK: - AddToVaultSheet

struct AddToVaultSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @Binding var isPresented: Bool

    var libraryDocs: [DocumentItem] {
        appState.documents.filter { !$0.isVaulted }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(LanguageManager.shared.vault("vault_move_to_vault"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ShieldTheme.primary(scheme))
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .frame(width: 30, height: 30)
                        .background(ShieldTheme.rowBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()

            if libraryDocs.isEmpty {
                Spacer()
                Text(LanguageManager.shared.vault("vault_no_docs_library"))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                    .font(.system(size: 14))
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(libraryDocs) { doc in
                            Button {
                                appState.toggleVault(doc)
                                isPresented = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(doc.title)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(ShieldTheme.primary(scheme))
                                        Text(doc.dateLabelLocalized(lang: appState.language))
                                            .font(.system(size: 12))
                                            .foregroundColor(ShieldTheme.tertiary(scheme))
                                    }
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(ShieldTheme.accent)
                                }
                                .padding(14)
                                .background(ShieldTheme.rowBackground(scheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(ShieldTheme.cardBackground(scheme))
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
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
            accessible: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
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
            accessible: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
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
                .font(.system(size: 44, weight: .light))
                .foregroundColor(ShieldTheme.accent)

            Text(step == 0
                 ? LanguageManager.shared.vault("vault_pin_setup_choose")
                 : LanguageManager.shared.vault("vault_pin_setup_confirm"))
                .font(.system(size: 20, weight: .bold))
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
                    .font(.system(size: 14))
                    .foregroundColor(ShieldTheme.danger)
            }

            // Numpad
            PINNumpad(onDigit: handleDigit, onDelete: handleDelete)

            Button { isPresented = false } label: {
                Text(LanguageManager.shared.capture("capture_cancel"))
                    .font(.system(size: 15))
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
                .font(.system(size: 44, weight: .light))
                .foregroundColor(ShieldTheme.accent)

            Text(LanguageManager.shared.vault("vault_pin_entry_prompt"))
                .font(.system(size: 20, weight: .bold))
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
                    .font(.system(size: 14))
                    .foregroundColor(ShieldTheme.danger)
            }

            if lockoutRemaining > 0 {
                Text(LanguageManager.shared.vault("vault_pin_try_again_in", lockoutRemaining))
                    .font(.system(size: 13))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }

            PINNumpad(onDigit: handleDigit, onDelete: handleDelete, isDisabled: lockoutRemaining > 0)

            Button { isPresented = false } label: {
                Text(LanguageManager.shared.capture("capture_cancel"))
                    .font(.system(size: 15))
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
                                    if #available(iOS 26, *) {
                                        Color.clear
                                            .glassEffect(.regular.interactive(), in: .circle)
                                            .frame(width: 72, height: 72)
                                    } else {
                                        Circle()
                                            .fill(ShieldTheme.rowBackground(scheme))
                                            .frame(width: 72, height: 72)
                                    }
                                } else {
                                    Color.clear
                                        .frame(width: 72, height: 72)
                                }
                                if key == "⌫" {
                                    Image(systemName: "delete.left")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(ShieldTheme.primary(scheme))
                                } else if !key.isEmpty {
                                    Text(key)
                                        .font(.system(size: 26, weight: .medium))
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
