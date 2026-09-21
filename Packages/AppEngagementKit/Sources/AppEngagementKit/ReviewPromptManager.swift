import Foundation
import StoreKit
import UIKit

/// Small StoreKit 2 review manager for apps that do not need the richer
/// contextual coordinator already used by MaskID.
@MainActor
public final class ReviewPromptManager {
    public static let shared = ReviewPromptManager()

    private let defaults: UserDefaults
    private let cooldown: TimeInterval
    private let featureUseThreshold: Int
    private let now: () -> Date
    private var pendingRequest = false

    private enum Key {
        static let lastRequestDate = "app.engagement.review.lastRequestDate"
        static let featureCounts = "app.engagement.review.featureCounts"
    }

    public init(
        defaults: UserDefaults = .standard,
        cooldownDays: Int = 90,
        featureUseThreshold: Int = 3,
        now: @escaping () -> Date = Date.init
    ) {
        self.defaults = defaults
        self.cooldown = TimeInterval(max(1, cooldownDays)) * 24 * 60 * 60
        self.featureUseThreshold = max(2, featureUseThreshold)
        self.now = now
    }

    public func recordSuccess(_ eventKey: String) {
        guard !eventKey.isEmpty else { return }
        pendingRequest = true
    }

    public func recordFeatureUse(_ featureKey: String) {
        guard !featureKey.isEmpty else { return }
        var counts = defaults.dictionary(forKey: Key.featureCounts) as? [String: Int] ?? [:]
        let count = (counts[featureKey] ?? 0) + 1
        counts[featureKey] = count
        defaults.set(counts, forKey: Key.featureCounts)
        if count >= featureUseThreshold { pendingRequest = true }
    }

    public func requestReview(in scene: UIWindowScene) {
        guard pendingRequest, isOutsideCooldown else { return }
        pendingRequest = false
        defaults.set(now(), forKey: Key.lastRequestDate)
        AppStore.requestReview(in: scene)
    }

    public var isOutsideCooldown: Bool {
        guard let lastRequest = defaults.object(forKey: Key.lastRequestDate) as? Date else { return true }
        return now().timeIntervalSince(lastRequest) >= cooldown
    }

    public func featureUseCount(_ featureKey: String) -> Int {
        let counts = defaults.dictionary(forKey: Key.featureCounts) as? [String: Int] ?? [:]
        return counts[featureKey] ?? 0
    }
}
