import Foundation
import Testing
@testable import Shield

@Suite("StoreKit review request policy")
struct AppReviewManagerTests {
    @Test("Free becomes eligible earlier than Premium after real value")
    func tierCadence() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let state = AppReviewState(
            installedAt: now.addingTimeInterval(-10 * AppReviewPolicy.day),
            valueScore: 3,
            automaticRequestDates: []
        )

        #expect(AppReviewPolicy.isEligible(state: state, isPremium: false, now: now))
        #expect(!AppReviewPolicy.isEligible(state: state, isPremium: true, now: now))
    }

    @Test("Premium needs more accumulated value and a longer relationship")
    func premiumThreshold() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let state = AppReviewState(
            installedAt: now.addingTimeInterval(-30 * AppReviewPolicy.day),
            valueScore: 8,
            automaticRequestDates: []
        )

        #expect(AppReviewPolicy.isEligible(state: state, isPremium: true, now: now))
    }

    @Test("Cooldown and yearly limits prevent review fatigue")
    func requestLimits() {
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let installedAt = now.addingTimeInterval(-400 * AppReviewPolicy.day)
        let recentFreeRequest = now.addingTimeInterval(-20 * AppReviewPolicy.day)
        let coolingDown = AppReviewState(
            installedAt: installedAt,
            valueScore: 20,
            automaticRequestDates: [recentFreeRequest]
        )
        #expect(!AppReviewPolicy.isEligible(state: coolingDown, isPremium: false, now: now))

        let annualLimitReached = AppReviewState(
            installedAt: installedAt,
            valueScore: 20,
            automaticRequestDates: [
                now.addingTimeInterval(-60 * AppReviewPolicy.day),
                now.addingTimeInterval(-120 * AppReviewPolicy.day),
                now.addingTimeInterval(-180 * AppReviewPolicy.day)
            ]
        )
        #expect(!AppReviewPolicy.isEligible(state: annualLimitReached, isPremium: false, now: now))
    }
}
