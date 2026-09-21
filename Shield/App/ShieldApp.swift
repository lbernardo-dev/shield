import SwiftUI

@main
struct ShieldApp: App {
    @StateObject private var appState = AppState()
    @State private var languageManager = LanguageManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        _ = AppEngagementRuntime.metadata
        FirebaseIntegration.configure()
        PremiumManager.configureRevenueCat()
        ShieldMetricSubscriber.shared.subscribe()
        SubscriptionLifecycleObserver.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environment(languageManager)
                .preferredColorScheme(appState.preferredScheme)
                .onChange(of: scenePhase) { _, newPhase in
                    appState.handleScenePhaseChange(newPhase)
                    if newPhase == .active { consumeSystemRequest() }
                }
                .onOpenURL { url in
                    if url.isFileURL {
                        appState.pendingSharedImportURL = url
                        appState.showCapture = true
                    } else if url.scheme == "shield" {
                        switch url.host {
                        case "capture":
                            appState.showCapture = true
                        case "vault":
                            appState.activeTab = .vault
                        case "preset":
                            let preset = url.pathComponents.dropFirst().first?.lowercased()
                            if preset == "verify" || preset == "dni" || preset == "id" {
                                appState.pendingRedactionMode = .verify
                            } else if preset == "job" || preset == "payroll" || preset == "nomina" {
                                appState.pendingRedactionMode = .job
                            } else if preset == "rental" || preset == "alquiler" {
                                appState.pendingRedactionMode = .rental
                            } else if preset == "banking" {
                                appState.pendingRedactionMode = .banking
                            }
                            appState.showCapture = true
                        case "import-shared":
                            consumeSharedImport()
                        default:
                            break
                        }
                    }
                }
                .onAppear(perform: consumeSystemRequest)
        }
    }

    private func consumeSystemRequest() {
        SharedImportStore.removeExpiredItems()
        if ShieldSystemRequestStore.consume(.presetVerify) {
            appState.pendingRedactionMode = .verify
            appState.showCapture = true
        } else if ShieldSystemRequestStore.consume(.presetJob) {
            appState.pendingRedactionMode = .job
            appState.showCapture = true
        } else if ShieldSystemRequestStore.consume(.presetRental) {
            appState.pendingRedactionMode = .rental
            appState.showCapture = true
        } else if ShieldSystemRequestStore.consume(.openCapture)
            || consumeLegacySystemRequest(key: "shield.intent.openCapture") {
            UserDefaults.standard.removeObject(forKey: "shield.intent.openCapture")
            appState.showCapture = true
        }
        if ShieldSystemRequestStore.consume(.openVault)
            || consumeLegacySystemRequest(key: "shield.intent.openVault") {
            UserDefaults.standard.removeObject(forKey: "shield.intent.openVault")
            appState.activeTab = .vault
        }
        consumeSharedImport()
    }

    private func consumeLegacySystemRequest(key: String) -> Bool {
        UserDefaults.standard.bool(forKey: key)
    }

    private func consumeSharedImport() {
        guard appState.pendingSharedImportURL == nil else { return }
        do {
            let url = try SharedImportStore.dequeueToTemporaryFile()
            appState.pendingSharedImportURL = url
            appState.showCapture = true
            AppState.trackEvent("share_extension_started", properties: ["source": "share_sheet"])
        } catch SharedImportStoreError.noPendingImport {
            return
        } catch let error as LocalizedError {
            appState.pendingSharedImportError = error.errorDescription
            appState.showCapture = true
            AppState.trackEvent("share_extension_failed", properties: [
                "source": "share_sheet",
                "error_type": String(describing: type(of: error))
            ])
        } catch {
            appState.pendingSharedImportError = "Could not open the shared item. Try sharing it again."
            appState.showCapture = true
            AppState.trackEvent("share_extension_failed", properties: [
                "source": "share_sheet",
                "error_type": String(describing: type(of: error))
            ])
        }
    }
}
