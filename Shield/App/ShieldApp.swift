import SwiftUI

@main
struct ShieldApp: App {
    @StateObject private var appState = AppState()
    @State private var languageManager = LanguageManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environment(languageManager)
                .preferredColorScheme(appState.preferredScheme)
                .onChange(of: scenePhase) { _, newPhase in
                    appState.handleScenePhaseChange(newPhase)
                }
        }
    }
}
