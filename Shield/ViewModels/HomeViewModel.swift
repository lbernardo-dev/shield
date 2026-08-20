import SwiftUI
import Combine
import LocalAuthentication

// MARK: - HomeViewModel

@MainActor
final class HomeViewModel: ObservableObject {
    // Sheet presentation
    @Published var showAllDocs = false
    @Published var showFilters = false
    @Published var showPaywall = false
    @Published var showCloudImport = false
    @Published var requestedCloudProvider: ExternalStorageProvider?
    @Published var showBatchRedact = false
    @Published var showWorkspaceTools = false
    @Published var showPresetPicker = false

    // Vault Authentication Flow
    @Published var showVaultAuthForDoc: DocumentItem? = nil
    @Published var showVaultPINEntry = false
    @Published var showVaultPINSetup = false
    @Published var vaultAuthDoc: DocumentItem? = nil
    @Published var showVaultAutoLock = false
    @Published var vaultAutoLockDoc: DocumentItem? = nil

    // Actions
    func handleDocumentTap(_ doc: DocumentItem, appState: AppState) {
        if doc.isVaulted {
            vaultAuthDoc = doc
            authenticateForVaultDoc(doc)
        } else {
            appState.selectedDoc = doc
        }
    }

    func authenticateForVaultDoc(_ doc: DocumentItem) {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if PINManager.hasPIN {
                showVaultPINEntry = true
            } else {
                showVaultPINSetup = true
            }
            return
        }
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: LanguageManager.shared.home("home_vault_auth_reason")
        ) { success, _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if success {
                    self.showVaultAuthForDoc = doc
                } else if PINManager.hasPIN {
                    self.showVaultPINEntry = true
                } else {
                    self.showVaultPINSetup = true
                }
            }
        }
    }
}
