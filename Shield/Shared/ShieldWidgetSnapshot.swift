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
    let watermarkedDocuments: Int
    let securityScore: Int
    let lastProtectedDate: Date?
    let generatedAt: Date

    init(
        totalDocuments: Int,
        protectedDocuments: Int,
        vaultedDocuments: Int,
        watermarkedDocuments: Int = 0,
        securityScore: Int? = nil,
        lastProtectedDate: Date? = nil,
        generatedAt: Date = .now
    ) {
        let safeTotal = max(0, totalDocuments)
        let safeProtected = max(0, protectedDocuments)
        let safeVaulted = max(0, vaultedDocuments)
        let safeWatermarked = max(0, watermarkedDocuments)
        self.totalDocuments = safeTotal
        self.protectedDocuments = safeProtected
        self.vaultedDocuments = safeVaulted
        self.watermarkedDocuments = safeWatermarked
        if let score = securityScore {
            self.securityScore = min(100, max(0, score))
        } else {
            self.securityScore = safeTotal > 0 ? min(100, Int((Double(safeProtected) / Double(safeTotal)) * 100)) : 100
        }
        self.lastProtectedDate = lastProtectedDate
        self.generatedAt = generatedAt
    }

    enum CodingKeys: String, CodingKey {
        case totalDocuments
        case protectedDocuments
        case vaultedDocuments
        case watermarkedDocuments
        case securityScore
        case lastProtectedDate
        case generatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let total = try container.decodeIfPresent(Int.self, forKey: .totalDocuments) ?? 0
        let protected = try container.decodeIfPresent(Int.self, forKey: .protectedDocuments) ?? 0
        let vaulted = try container.decodeIfPresent(Int.self, forKey: .vaultedDocuments) ?? 0
        let watermarked = try container.decodeIfPresent(Int.self, forKey: .watermarkedDocuments) ?? 0
        let score = try container.decodeIfPresent(Int.self, forKey: .securityScore)
        let lastProtected = try container.decodeIfPresent(Date.self, forKey: .lastProtectedDate)
        let generated = try container.decodeIfPresent(Date.self, forKey: .generatedAt) ?? .now

        self.init(
            totalDocuments: total,
            protectedDocuments: protected,
            vaultedDocuments: vaulted,
            watermarkedDocuments: watermarked,
            securityScore: score,
            lastProtectedDate: lastProtected,
            generatedAt: generated
        )
    }

    static let empty = ShieldWidgetSnapshot(
        totalDocuments: 0,
        protectedDocuments: 0,
        vaultedDocuments: 0,
        watermarkedDocuments: 0,
        securityScore: 100,
        lastProtectedDate: nil
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
