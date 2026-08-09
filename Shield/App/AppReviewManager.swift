import Foundation
import StoreKit
import UIKit

enum AppReviewValueEvent {
    case documentCreated
    case secureExportCompleted

    var score: Int {
        switch self {
        case .documentCreated: 1
        case .secureExportCompleted: 2
        }
    }
}

struct AppReviewState: Equatable {
    var installedAt: Date
    var valueScore: Int
    var automaticRequestDates: [Date]
}

struct AppReviewPolicy {
    struct Tier: Equatable {
        let minimumAppAge: TimeInterval
        let valueThreshold: Int
        let cooldown: TimeInterval
        let annualRequestLimit: Int
    }

    static let day: TimeInterval = 24 * 60 * 60
    static let year: TimeInterval = 365 * day

    // Free users are asked earlier and can be asked more often, but only after
    // completing useful work. Premium users receive a deliberately quieter cadence.
    static let free = Tier(
        minimumAppAge: 2 * day,
        valueThreshold: 3,
        cooldown: 45 * day,
        annualRequestLimit: 3
    )
    static let premium = Tier(
        minimumAppAge: 14 * day,
        valueThreshold: 8,
        cooldown: 120 * day,
        annualRequestLimit: 2
    )

    static func tier(isPremium: Bool) -> Tier {
        isPremium ? premium : free
    }

    static func isEligible(
        state: AppReviewState,
        isPremium: Bool,
        now: Date
    ) -> Bool {
        let policy = tier(isPremium: isPremium)
        guard now.timeIntervalSince(state.installedAt) >= policy.minimumAppAge else { return false }
        guard state.valueScore >= policy.valueThreshold else { return false }

        let recentRequests = state.automaticRequestDates.filter {
            now.timeIntervalSince($0) < year
        }
        guard recentRequests.count < policy.annualRequestLimit else { return false }

        if let lastRequest = recentRequests.max() {
            guard now.timeIntervalSince(lastRequest) >= policy.cooldown else { return false }
        }
        return true
    }
}

@MainActor
final class AppReviewManager {
    static let shared = AppReviewManager()

    private enum Key {
        static let installedAt = "shield.review.installedAt"
        static let valueScore = "shield.review.valueScore"
        static let automaticRequestDates = "shield.review.automaticRequestDates"
    }

    private let defaults: UserDefaults
    private var automaticRequestPending = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Key.installedAt) == nil {
            defaults.set(Date().timeIntervalSince1970, forKey: Key.installedAt)
        }
    }

    func record(_ event: AppReviewValueEvent, isPremium: Bool) {
        guard !Self.isAutomatedRun else { return }

        var state = loadState()
        state.valueScore += event.score
        save(state)

        guard !automaticRequestPending else { return }
        guard AppReviewPolicy.isEligible(state: state, isPremium: isPremium, now: Date()) else { return }

        automaticRequestPending = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(1.4))
            self?.performAutomaticRequestIfPossible(isPremium: isPremium)
        }
    }

    /// Explicit user intent from Settings. StoreKit and the App Store decide
    /// whether the system rating sheet is displayed.
    func requestFromSettings() {
        guard !Self.isAutomatedRun else { return }
        guard let scene = activeWindowScene else { return }
        AppStore.requestReview(in: scene)
        AppState.trackEvent("review_requested", properties: ["source": "settings"])
    }

    private func performAutomaticRequestIfPossible(isPremium: Bool) {
        defer { automaticRequestPending = false }
        guard let scene = activeWindowScene else { return }

        let now = Date()
        var state = loadState()
        guard AppReviewPolicy.isEligible(state: state, isPremium: isPremium, now: now) else { return }

        state.valueScore = 0
        state.automaticRequestDates = state.automaticRequestDates.filter {
            now.timeIntervalSince($0) < AppReviewPolicy.year
        } + [now]
        save(state)

        AppStore.requestReview(in: scene)
        AppState.trackEvent("review_requested", properties: [
            "source": "value_moment",
            "kind": isPremium ? "premium" : "free"
        ])
    }

    private var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    private func loadState() -> AppReviewState {
        let installedTimestamp = defaults.double(forKey: Key.installedAt)
        let requestTimestamps = defaults.array(forKey: Key.automaticRequestDates) as? [TimeInterval] ?? []
        return AppReviewState(
            installedAt: Date(timeIntervalSince1970: installedTimestamp),
            valueScore: defaults.integer(forKey: Key.valueScore),
            automaticRequestDates: requestTimestamps.map(Date.init(timeIntervalSince1970:))
        )
    }

    private func save(_ state: AppReviewState) {
        defaults.set(state.installedAt.timeIntervalSince1970, forKey: Key.installedAt)
        defaults.set(state.valueScore, forKey: Key.valueScore)
        defaults.set(state.automaticRequestDates.map(\.timeIntervalSince1970), forKey: Key.automaticRequestDates)
    }

    private static var isAutomatedRun: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("-ui-testing") || arguments.contains("-aso-screenshots")
    }
}
