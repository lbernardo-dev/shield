import AppIntents
import Foundation

struct OpenShieldCaptureIntent: AppIntent {
    static let title = LocalizedStringResource(
        "Mask a Document",
        table: "AppShortcuts"
    )
    static let description = IntentDescription(
        LocalizedStringResource(
            "Opens Shield ready to import, scan, or photograph a document.",
            table: "AppShortcuts"
        )
    )
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        UserDefaults.standard.set(true, forKey: "shield.intent.openCapture")
        return .result(dialog: IntentDialog(stringLiteral: String(localized: LocalizedStringResource(
            "Shield is ready to protect your document.",
            table: "AppShortcuts"
        ))))
    }
}

struct OpenShieldVaultIntent: AppIntent {
    static let title = LocalizedStringResource("Open Secure Vault", table: "AppShortcuts")
    static let description = IntentDescription(
        LocalizedStringResource(
            "Opens Shield's protected vault. Authentication is always required in the app.",
            table: "AppShortcuts"
        )
    )
    static let openAppWhenRun = true
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication

    func perform() async throws -> some IntentResult & ProvidesDialog {
        UserDefaults.standard.set(true, forKey: "shield.intent.openVault")
        return .result(dialog: IntentDialog(stringLiteral: String(localized: LocalizedStringResource(
            "Opening the secure vault.",
            table: "AppShortcuts"
        ))))
    }
}

struct ShieldAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenShieldCaptureIntent(),
            phrases: [
                "Mask a document with \(.applicationName)",
                "Protect a document in \(.applicationName)"
            ],
            shortTitle: "Mask Document",
            systemImageName: "eye.slash"
        )
        AppShortcut(
            intent: OpenShieldVaultIntent(),
            phrases: ["Open my secure vault in \(.applicationName)"],
            shortTitle: "Open Vault",
            systemImageName: "lock.shield"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .navy
}
