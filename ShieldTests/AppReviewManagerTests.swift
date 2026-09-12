import Foundation
import Testing
@testable import Shield

@MainActor
private final class SuccessfulFeedbackTransport: FeedbackTransport {
    func send(_ feedback: FeedbackEnvelope) async throws {}
}

@Suite("Review and feedback orchestration policy")
struct AppReviewManagerTests {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    private func eligibleFreeState() -> EngagementState {
        EngagementState(
            firstSeenAt: now.addingTimeInterval(-4 * 24 * 60 * 60),
            sessionCount: 3,
            activeDayCount: 2,
            meaningfulResultCount: 3
        )
    }

    @Test("Free user before the threshold is not eligible")
    func freeBeforeThreshold() {
        var state = eligibleFreeState()
        state.meaningfulResultCount = 2
        let result = ReviewEligibilityPolicy.evaluate(
            state: state,
            event: .meaningfulResultDelivered(feature: .secureExport),
            tier: .free,
            now: now,
            appVersion: "1.0.9"
        )
        #expect(!result.isEligible)
        #expect(result.reason == .insufficientMeaningfulResults)
    }

    @Test("Free user after successful threshold becomes a candidate")
    func freeAfterThreshold() {
        let result = ReviewEligibilityPolicy.evaluate(
            state: eligibleFreeState(),
            event: .meaningfulResultDelivered(feature: .secureExport),
            tier: .free,
            now: now,
            appVersion: "1.0.9"
        )
        #expect(result.isEligible)
        #expect(result.reason == .eligible)
    }

    @Test("Premium purchase alone does not qualify")
    func premiumPurchaseOnly() {
        var state = eligibleFreeState()
        state.premiumResultCount = 0
        state.lastPurchaseAt = now.addingTimeInterval(-48 * 60 * 60)
        let result = ReviewEligibilityPolicy.evaluate(
            state: state,
            event: .purchaseCompleted(productID: "com.romerodev.shield.pro.annual"),
            tier: .premium,
            now: now,
            appVersion: "1.0.9"
        )
        #expect(!result.isEligible)
        #expect(result.reason == .noQualifiedSuccess)
    }

    @Test("Premium result qualifies only after the purchase deferral")
    func premiumValueAfterPurchase() {
        var state = eligibleFreeState()
        state.premiumResultCount = 1
        state.lastPurchaseAt = now.addingTimeInterval(-48 * 60 * 60)
        let result = ReviewEligibilityPolicy.evaluate(
            state: state,
            event: .premiumResultDelivered(feature: .premiumMaskStyle),
            tier: .premium,
            now: now,
            appVersion: "1.0.9"
        )
        #expect(result.isEligible)
    }

    @Test("Premium result immediately after purchase is deferred")
    func premiumValueImmediatelyAfterPurchase() {
        var state = eligibleFreeState()
        state.premiumResultCount = 1
        state.lastPurchaseAt = now.addingTimeInterval(-2 * 60 * 60)
        let result = ReviewEligibilityPolicy.evaluate(
            state: state,
            event: .premiumResultDelivered(feature: .premiumMaskStyle),
            tier: .premium,
            now: now,
            appVersion: "1.0.9"
        )
        #expect(!result.isEligible)
        #expect(result.reason == .purchaseDeferral)
    }

    @Test("Cooldown and version awareness prevent repeated automatic attempts")
    func cooldownAndVersion() {
        var state = eligibleFreeState()
        state.lastReviewAttemptAt = now.addingTimeInterval(-30 * 24 * 60 * 60)
        var result = ReviewEligibilityPolicy.evaluate(
            state: state,
            event: .meaningfulResultDelivered(feature: .secureExport),
            tier: .free,
            now: now,
            appVersion: "1.0.9"
        )
        #expect(!result.isEligible)
        #expect(result.reason == .cooldownActive)

        state.lastReviewAttemptAt = now.addingTimeInterval(-200 * 24 * 60 * 60)
        state.lastReviewAttemptVersion = "1.0.9"
        result = ReviewEligibilityPolicy.evaluate(
            state: state,
            event: .meaningfulResultDelivered(feature: .secureExport),
            tier: .free,
            now: now,
            appVersion: "1.0.9"
        )
        #expect(!result.isEligible)
        #expect(result.reason == .versionAlreadyAttempted)
    }

    @Test("Hard presentation gates reject onboarding, paywall, errors, and cancellation")
    func hardPresentationGates() {
        #expect(!ReviewPresentationGate.isAllowed(ReviewPresentationContext(isOnboarding: true)))
        #expect(!ReviewPresentationGate.isAllowed(ReviewPresentationContext(isPaywallVisible: true)))
        #expect(!ReviewPresentationGate.isAllowed(ReviewPresentationContext(hasActiveError: true)))
        #expect(!ReviewPresentationGate.isAllowed(ReviewPresentationContext(isCancellationFlow: true)))
        #expect(ReviewPresentationGate.isAllowed(.naturalResult))
    }

    @Test("Manual review action uses Apple's write-review product link")
    @MainActor
    func manualReviewURL() {
        let url = AppReviewManager.shared.writeReviewURL
        #expect(url.scheme == "https")
        #expect(url.host == "apps.apple.com")
        #expect(url.path == "/app/id6790398619")
        #expect(url.query == "action=write-review")
    }

    @Test("Subscription auto-renew transition creates cancellation feedback")
    func cancellationTransition() {
        let previous = SubscriptionSnapshot(
            productID: "annual",
            state: "subscribed",
            willAutoRenew: true,
            expirationReason: nil,
            expiresAt: now.addingTimeInterval(30 * 24 * 60 * 60),
            checkedAt: now
        )
        let current = SubscriptionSnapshot(
            productID: "annual",
            state: "subscribed",
            willAutoRenew: false,
            expirationReason: "autoRenewDisabled",
            expiresAt: now.addingTimeInterval(30 * 24 * 60 * 60),
            checkedAt: now
        )
        #expect(SubscriptionLifecyclePolicy.events(previous: previous, current: current) == [.subscriptionAutoRenewDisabled])
    }

    @Test("Billing retry is not classified as voluntary cancellation")
    func billingFailureTransition() {
        let previous = SubscriptionSnapshot(
            productID: "annual",
            state: "subscribed",
            willAutoRenew: true,
            expirationReason: nil,
            expiresAt: now.addingTimeInterval(30 * 24 * 60 * 60),
            checkedAt: now
        )
        let current = SubscriptionSnapshot(
            productID: "annual",
            state: "inBillingRetryPeriod",
            willAutoRenew: false,
            expirationReason: "billingError",
            expiresAt: now.addingTimeInterval(3 * 24 * 60 * 60),
            checkedAt: now
        )
        #expect(SubscriptionLifecyclePolicy.events(previous: previous, current: current) == [.subscriptionBillingIssue])
        #expect(current.isBillingIssue)
    }

    @Test("Feedback trigger categories are contextual and never rating-gated")
    func contextualFeedbackCategories() {
        #expect(FeedbackTrigger.subscriptionCancelled.categories.contains(.tooExpensive))
        #expect(!FeedbackTrigger.repeatedFailure.categories.contains(.tooExpensive))
        #expect(FeedbackTrigger.manual.categories.contains(.privacy))
    }

    @Test("Feedback payload contains only safe technical context")
    func privacySafeFeedbackPayload() {
        let envelope = FeedbackEnvelope(
            category: .missingFeature,
            message: "Please add a better batch workflow",
            trigger: .repeatedFailure,
            appVersion: "1.0.9",
            buildNumber: "109",
            osVersion: "18.0",
            locale: "es_ES",
            entitlementTier: .free,
            featureKey: .secureExport
        )
        #expect(envelope.mailBody.contains("secure_export"))
        #expect(!envelope.mailBody.contains("documentNumber"))
        #expect(!envelope.mailBody.contains("OCR"))
    }

    @Test("Successful feedback keeps the context for the thank-you screen")
    @MainActor
    func successfulFeedbackKeepsContextForThanksScreen() async {
        let defaults = UserDefaults(suiteName: "ReviewFeedbackTests.\(UUID().uuidString)")!
        let coordinator = ReviewFeedbackCoordinator(
            defaults: defaults,
            transport: SuccessfulFeedbackTransport(),
            tierProvider: { .free }
        )
        let context = FeedbackContext(trigger: .manual, feature: nil, tier: .free)
        coordinator.activeFeedbackContext = context

        let didSubmit = await coordinator.submitFeedback(
            category: .other,
            message: "A useful comment",
            context: context
        )

        #expect(didSubmit)
        #expect(coordinator.activeFeedbackContext?.id == context.id)
    }

    @Test("Feedback thank-you screen uses a ten-second countdown")
    func feedbackThanksCountdownDuration() {
        #expect(FeedbackPromptConfiguration.thanksCountdownSeconds == 10)
    }
}
