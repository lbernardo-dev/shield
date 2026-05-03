import SwiftUI
import LocalAuthentication
import CryptoKit

// MARK: - VaultView

struct VaultView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @Environment(\.colorScheme) var scheme
    @State private var isUnlocked = false
    @State private var authError: String? = nil
    @State private var showPaywall = false
    @State private var paywallTrigger: PaywallTrigger = .manual
    @State private var selectedDoc: DocumentItem? = nil
    @State private var showPINSetup = false
    @State private var showPINEntry = false
    @State private var showAddToVault = false

    var body: some View {
        ZStack {
            ShieldTheme.pageBackground(scheme).ignoresSafeArea()

            if !pm.isPro {
                proGate
            } else if !isUnlocked {
                lockGate
            } else {
                vaultContent
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: paywallTrigger).environmentObject(appState)
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
    }

    // MARK: - Pro gate

    private var proGate: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 24).fill(ShieldTheme.accentDim).frame(width: 96, height: 96)
                Image(systemName: "lock.rectangle.stack.fill").font(.system(size: 44)).foregroundColor(ShieldTheme.accent)
            }
            VStack(spacing: 8) {
                Text(LanguageManager.shared.vault("vault_title_pro"))
                    .font(.system(size: 22, weight: .bold)).foregroundColor(ShieldTheme.primary(scheme))
                Text(LanguageManager.shared.vault("vault_pro_desc"))
                    .font(.system(size: 15)).foregroundColor(ShieldTheme.secondary(scheme)).multilineTextAlignment(.center)
            }
            Button {
                paywallTrigger = .vaultUpgrade
                showPaywall = true
            } label: {
                Label(LanguageManager.shared.paywall("paywall_unlock_pro"), systemImage: "crown.fill")
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(ShieldTheme.accent).foregroundColor(ShieldTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle()).padding(.horizontal, 32)
            Spacer()
        }
    }

    // MARK: - Lock gate

    private var lockGate: some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(hex: "FFD60A").opacity(0.08))
                    .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color(hex: "FFD60A").opacity(0.25), lineWidth: 1.5))
                    .frame(width: 120, height: 120)
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
                            .foregroundColor(ShieldTheme.textTertiary)
                    }
                }
            }
            Spacer()
        }
        .onAppear { authenticate() }
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
                    withAnimation { isUnlocked = false }
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
                .foregroundColor(ShieldTheme.textTertiary)
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

    private func authenticate() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            authenticateWithDevicePasscodeOrPIN()
            return
        }
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: LanguageManager.shared.vault("vault_biometric_reason")
        ) { success, err in
            DispatchQueue.main.async {
                if success {
                    withAnimation { isUnlocked = true; authError = nil }
                } else {
                    authError = err?.localizedDescription
                }
            }
        }
    }

    private func authenticateWithDevicePasscodeOrPIN() {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            presentPINFallback()
            return
        }
        ctx.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: LanguageManager.shared.vault("vault_biometric_reason")
        ) { success, err in
            DispatchQueue.main.async {
                if success {
                    withAnimation { isUnlocked = true; authError = nil }
                } else {
                    authError = err?.localizedDescription
                }
            }
        }
    }

    private func presentPINFallback() {
        if PINManager.hasPIN {
            showPINEntry = true
            return
        }
        showPINSetup = true
        authError = LanguageManager.shared.vault("vault_pin_setup_help")
    }
}

// MARK: - AddToVaultSheet

struct AddToVaultSheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool

    var libraryDocs: [DocumentItem] {
        appState.documents.filter { !$0.isVaulted }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(LanguageManager.shared.vault("vault_move_to_vault"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()

            if libraryDocs.isEmpty {
                Spacer()
                Text(LanguageManager.shared.vault("vault_no_docs_library"))
                    .foregroundColor(ShieldTheme.textTertiary)
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
                                            .foregroundColor(ShieldTheme.textPrimary)
                                        Text(doc.dateLabelLocalized(lang: appState.language))
                                            .font(.system(size: 12))
                                            .foregroundColor(ShieldTheme.textTertiary)
                                    }
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(ShieldTheme.accent)
                                }
                                .padding(14)
                                .background(ShieldTheme.surface3)
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
        .background(ShieldTheme.surface2)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - PINManager

enum PINManager {
    private static let service = "com.romerodev.shield.vault"
    private static let account = "vault-pin"
    private static let failedAttemptsKey = "shield.pin.failedAttempts"
    private static let lockoutUntilKey = "shield.pin.lockoutUntil"
    private static let lockoutBaseSeconds = 30
    private static let lockoutStartAttempt = 3
    private static let maxBackoffExponent = 6

    static var hasPIN: Bool {
        (try? KeychainStore.read(service: service, account: account)) != nil
    }

    static var isLockedOut: Bool {
        lockoutRemainingSeconds() > 0
    }

    static func save(pin: String) {
        guard let data = pin.data(using: .utf8) else { return }
        let hashed = SHA256.hash(data: data)
        let digest = Data(hashed)
        try? KeychainStore.save(
            digest,
            service: service,
            account: account,
            accessible: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        )
        resetLockout()
    }

    static func verify(pin: String) -> Bool {
        guard !isLockedOut else { return false }
        guard let stored = try? KeychainStore.read(service: service, account: account),
              let data = pin.data(using: .utf8) else { return false }
        let digest = Data(SHA256.hash(data: data))
        let isValid = stored == digest
        if isValid {
            resetLockout()
        } else {
            registerFailure()
        }
        return isValid
    }

    static func clear() {
        KeychainStore.delete(service: service, account: account)
        resetLockout()
    }

    static func lockoutRemainingSeconds() -> Int {
        let until = UserDefaults.standard.double(forKey: lockoutUntilKey)
        guard until > 0 else { return 0 }
        let remaining = Int(ceil(until - Date().timeIntervalSince1970))
        if remaining <= 0 {
            resetLockout()
            return 0
        }
        return remaining
    }

    private static func registerFailure() {
        let defaults = UserDefaults.standard
        let attempts = defaults.integer(forKey: failedAttemptsKey) + 1
        defaults.set(attempts, forKey: failedAttemptsKey)

        guard attempts >= lockoutStartAttempt else {
            defaults.removeObject(forKey: lockoutUntilKey)
            return
        }

        let exponent = min(attempts - lockoutStartAttempt, maxBackoffExponent)
        let delay = lockoutBaseSeconds * Int(pow(2.0, Double(exponent)))
        let until = Date().addingTimeInterval(TimeInterval(delay)).timeIntervalSince1970
        defaults.set(until, forKey: lockoutUntilKey)
    }

    private static func resetLockout() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: failedAttemptsKey)
        defaults.removeObject(forKey: lockoutUntilKey)
    }
}

// MARK: - PINSetupView

struct PINSetupView: View {
    @Binding var isPresented: Bool
    var onSuccess: () -> Void
    @EnvironmentObject var appState: AppState

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
                .foregroundColor(ShieldTheme.textPrimary)

            // PIN dots
            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i < currentPin.count ? ShieldTheme.accent : ShieldTheme.surface3)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(ShieldTheme.surfaceLine, lineWidth: 1))
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
                    .foregroundColor(ShieldTheme.textTertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ShieldTheme.surface0.ignoresSafeArea())
        .preferredColorScheme(.dark)
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
                .foregroundColor(ShieldTheme.textPrimary)

            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i < pin.count ? ShieldTheme.accent : ShieldTheme.surface3)
                        .frame(width: 16, height: 16)
                        .overlay(Circle().stroke(ShieldTheme.surfaceLine, lineWidth: 1))
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
                    .foregroundColor(ShieldTheme.textTertiary)
            }

            PINNumpad(onDigit: handleDigit, onDelete: handleDelete, isDisabled: lockoutRemaining > 0)

            Button { isPresented = false } label: {
                Text(LanguageManager.shared.capture("capture_cancel"))
                    .font(.system(size: 15))
                    .foregroundColor(ShieldTheme.textTertiary)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ShieldTheme.surface0.ignoresSafeArea())
        .preferredColorScheme(.dark)
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
                                Circle()
                                    .fill(key.isEmpty ? Color.clear : ShieldTheme.surface3)
                                    .frame(width: 72, height: 72)
                                if key == "⌫" {
                                    Image(systemName: "delete.left")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundColor(ShieldTheme.textPrimary)
                                } else if !key.isEmpty {
                                    Text(key)
                                        .font(.system(size: 26, weight: .medium))
                                        .foregroundColor(ShieldTheme.textPrimary)
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
