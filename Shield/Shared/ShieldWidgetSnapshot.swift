import Foundation

/// Non-sensitive aggregate data shared with WidgetKit through the App Group.
///
/// Widget processes must never read the app's document store or vault. This
/// snapshot intentionally contains counts only, so the widget remains useful
/// without exposing document titles, OCR, images, or file names.
struct ShieldWidgetSnapshot: Codable, Equatable, Sendable {
    let totalDocuments: Int
    let protectedDocuments: Int
    let vaultedDocuments: Int
    let generatedAt: Date

    init(
        totalDocuments: Int,
        protectedDocuments: Int,
        vaultedDocuments: Int,
        generatedAt: Date = .now
    ) {
        self.totalDocuments = max(0, totalDocuments)
        self.protectedDocuments = max(0, protectedDocuments)
        self.vaultedDocuments = max(0, vaultedDocuments)
        self.generatedAt = generatedAt
    }

    static let empty = ShieldWidgetSnapshot(
        totalDocuments: 0,
        protectedDocuments: 0,
        vaultedDocuments: 0
    )
}

enum ShieldWidgetSnapshotStore {
    static let appGroupIdentifier = "group.com.romerodev.shield"
    static let snapshotKey = "shield.widget.snapshot.v1"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }

    static func save(_ snapshot: ShieldWidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    static func load() -> ShieldWidgetSnapshot {
        guard let data = defaults.data(forKey: snapshotKey),
              let snapshot = try? JSONDecoder().decode(ShieldWidgetSnapshot.self, from: data)
        else {
            return .empty
        }
        return snapshot
    }
}

enum ShieldSystemRequest: String, Sendable {
    case openCapture
    case openVault
}

/// Small App Group command channel shared by App Intents, widgets, and the app.
/// Values are consumed on launch and are never used to bypass authentication.
@MainActor
enum ShieldSystemRequestStore {
    private static let keyPrefix = "shield.system-request."

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: ShieldWidgetSnapshotStore.appGroupIdentifier) ?? .standard
    }

    static func request(_ request: ShieldSystemRequest) {
        defaults.set(true, forKey: key(for: request))
    }

    static func consume(_ request: ShieldSystemRequest) -> Bool {
        let requestKey = key(for: request)
        guard defaults.bool(forKey: requestKey) else { return false }
        defaults.removeObject(forKey: requestKey)
        return true
    }

    private static func key(for request: ShieldSystemRequest) -> String {
        keyPrefix + request.rawValue
    }
}
