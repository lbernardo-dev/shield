import Foundation

/// Non-sensitive aggregate data shared with WidgetKit through the App Group.
///
/// Widget processes must never read the app's document store or vault. This
/// snapshot contains aggregate counts and resolved plan access only, so it
/// never exposes document titles, OCR, images, or file names.
struct ShieldWidgetSnapshot: Codable, Equatable, Sendable {
    let totalDocuments: Int
    let documentsWithRedactions: Int
    let vaultedDocuments: Int
    let watermarkedDocuments: Int
    let hasPremiumAccess: Bool

    init(
        totalDocuments: Int,
        documentsWithRedactions: Int,
        vaultedDocuments: Int,
        watermarkedDocuments: Int = 0,
        hasPremiumAccess: Bool = false
    ) {
        let safeTotal = max(0, totalDocuments)
        let safeRedacted = min(safeTotal, max(0, documentsWithRedactions))
        let safeVaulted = min(safeTotal, max(0, vaultedDocuments))
        let safeWatermarked = min(safeTotal, max(0, watermarkedDocuments))
        self.totalDocuments = safeTotal
        self.documentsWithRedactions = safeRedacted
        self.vaultedDocuments = safeVaulted
        self.watermarkedDocuments = safeWatermarked
        self.hasPremiumAccess = hasPremiumAccess
    }

    enum CodingKeys: String, CodingKey {
        case totalDocuments
        case documentsWithRedactions
        case legacyProtectedDocuments = "protectedDocuments"
        case vaultedDocuments
        case watermarkedDocuments
        case hasPremiumAccess
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let total = try container.decodeIfPresent(Int.self, forKey: .totalDocuments) ?? 0
        let redacted = try container.decodeIfPresent(Int.self, forKey: .documentsWithRedactions)
            ?? container.decodeIfPresent(Int.self, forKey: .legacyProtectedDocuments)
            ?? 0
        let vaulted = try container.decodeIfPresent(Int.self, forKey: .vaultedDocuments) ?? 0
        let watermarked = try container.decodeIfPresent(Int.self, forKey: .watermarkedDocuments) ?? 0
        let hasPremiumAccess = try container.decodeIfPresent(Bool.self, forKey: .hasPremiumAccess) ?? false

        self.init(
            totalDocuments: total,
            documentsWithRedactions: redacted,
            vaultedDocuments: vaulted,
            watermarkedDocuments: watermarked,
            hasPremiumAccess: hasPremiumAccess
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(totalDocuments, forKey: .totalDocuments)
        try container.encode(documentsWithRedactions, forKey: .documentsWithRedactions)
        try container.encode(vaultedDocuments, forKey: .vaultedDocuments)
        try container.encode(watermarkedDocuments, forKey: .watermarkedDocuments)
        try container.encode(hasPremiumAccess, forKey: .hasPremiumAccess)
    }

    static let empty = ShieldWidgetSnapshot(
        totalDocuments: 0,
        documentsWithRedactions: 0,
        vaultedDocuments: 0,
        watermarkedDocuments: 0
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
    case presetVerify
    case presetJob
    case presetRental
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
