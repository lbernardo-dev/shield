import SwiftUI

@main
struct ShieldApp: App {
    @StateObject private var appState = AppState()
    @State private var languageManager = LanguageManager.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        PremiumManager.configureRevenueCat()
        ShieldMetricSubscriber.shared.subscribe()
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
                    } else if url.scheme == "shield", url.host == "import-shared" {
                        consumeSharedImport()
                    }
                }
                .onAppear(perform: consumeSystemRequest)
        }
    }

    private func consumeSystemRequest() {
        SharedImportStore.removeExpiredItems()
        if UserDefaults.standard.bool(forKey: "shield.intent.openCapture") {
            UserDefaults.standard.removeObject(forKey: "shield.intent.openCapture")
            appState.showCapture = true
        }
        if UserDefaults.standard.bool(forKey: "shield.intent.openVault") {
            UserDefaults.standard.removeObject(forKey: "shield.intent.openVault")
            appState.activeTab = .vault
        }
        consumeSharedImport()
    }

    private func consumeSharedImport() {
        guard appState.pendingSharedImportURL == nil else { return }
        guard let url = try? SharedImportStore.dequeueToTemporaryFile() else { return }
        appState.pendingSharedImportURL = url
        appState.showCapture = true
    }
}
