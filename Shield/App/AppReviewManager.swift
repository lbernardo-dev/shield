import Foundation
import AppEngagementKit
import MessageUI
import OSLog
import StoreKit
import SwiftUI
import UIKit

// MARK: - Product-specific event vocabulary

enum FeatureKey: String, Codable, CaseIterable, Sendable {
    case documentImport = "document_import"
    case secureExport = "secure_export"
    case premiumMaskStyle = "premium_mask_style"
    case premiumAdjustment = "premium_adjustment"
    case batchProcessing = "batch_processing"
    case vaultProtection = "vault_protection"
    case unknown = "unknown"
}

enum EntitlementTier: String, Codable, Sendable {
    case free
    case trial
    case premium
    case lifetime
    case paidApp

    var isPremium: Bool {
        switch self {
        case .free: false
        case .trial, .premium, .lifetime, .paidApp: true
        }
    }
}

enum EngagementEvent: Equatable, Sendable {
    case appLaunched
    case sessionStarted
    case sessionEnded
    case onboardingCompleted
    case coreActionCompleted(feature: FeatureKey)
    case meaningfulResultDelivered(feature: FeatureKey)
    case premiumResultDelivered(feature: FeatureKey)
    case milestoneReached(key: String)
    case purchaseCompleted(productID: String)
    case subscriptionActivated(productID: String)
    case subscriptionRenewed(productID: String)
    case subscriptionAutoRenewDisabled
    case subscriptionAutoRenewEnabled
    case subscriptionExpired(reason: String?)
    case subscriptionBillingIssue
    case subscriptionReactivated
    case flowAbandoned(flow: FeatureKey)
    case operationFailed(feature: FeatureKey)
    case repeatedFailure(feature: FeatureKey)
    case supportRequested
    case returnedAfterInactivity(days: Int)
    case permissionDenied(permission: String)
}

// MARK: - Persisted state

struct SubscriptionSnapshot: Codable, Equatable, Sendable {
    let productID: String?
    let state: String
    let willAutoRenew: Bool
    let expirationReason: String?
    let expiresAt: Date?
    let checkedAt: Date

    var isActive: Bool {
        let normalized = state.lowercased()
        return normalized.contains("subscribed")
            || normalized.contains("ingrace")
            || normalized.contains("grace")
    }

    var isBillingIssue: Bool {
        let normalizedState = state.lowercased()
        let normalizedReason = expirationReason?.lowercased() ?? ""
        return normalizedState.contains("billing")
            || normalizedState.contains("retry")
            || normalizedState.contains("grace")
            || normalizedReason.contains("billing")
            || normalizedReason.contains("payment")
    }
}

struct PendingReviewOpportunity: Codable, Equatable, Sendable {
    let feature: FeatureKey
    let tier: EntitlementTier
    let createdAt: Date
}

struct PendingFeedbackOpportunity: Codable, Equatable, Sendable {
    let trigger: FeedbackTrigger
    let feature: FeatureKey?
    let tier: EntitlementTier
    let createdAt: Date
}

struct EngagementState: Codable, Equatable, Sendable {
    var firstSeenAt: Date?
    var sessionCount: Int
    var activeDayCount: Int
    var lastActiveAt: Date?
    var meaningfulResultCount: Int
    var premiumResultCount: Int
    var lastMeaningfulResultAt: Date?
    var lastReviewAttemptAt: Date?
    var lastReviewAttemptVersion: String?
    var reviewAttemptCount: Int
    var lastFeedbackPromptAt: Date?
    var reviewSuppressedUntil: Date?
    var lastPurchaseAt: Date?
    var pendingReviewOpportunity: PendingReviewOpportunity?
    var pendingFeedbackOpportunity: PendingFeedbackOpportunity?
    var lastSubscriptionSnapshot: SubscriptionSnapshot?
    var failureCounts: [String: Int]

    init(
        firstSeenAt: Date? = nil,
        sessionCount: Int = 0,
        activeDayCount: Int = 0,
        lastActiveAt: Date? = nil,
        meaningfulResultCount: Int = 0,
        premiumResultCount: Int = 0,
        lastMeaningfulResultAt: Date? = nil,
        lastReviewAttemptAt: Date? = nil,
        lastReviewAttemptVersion: String? = nil,
        reviewAttemptCount: Int = 0,
        lastFeedbackPromptAt: Date? = nil,
        reviewSuppressedUntil: Date? = nil,
        lastPurchaseAt: Date? = nil,
        pendingReviewOpportunity: PendingReviewOpportunity? = nil,
        pendingFeedbackOpportunity: PendingFeedbackOpportunity? = nil,
        lastSubscriptionSnapshot: SubscriptionSnapshot? = nil,
        failureCounts: [String: Int] = [:]
    ) {
        self.firstSeenAt = firstSeenAt
        self.sessionCount = sessionCount
        self.activeDayCount = activeDayCount
        self.lastActiveAt = lastActiveAt
        self.meaningfulResultCount = meaningfulResultCount
        self.premiumResultCount = premiumResultCount
        self.lastMeaningfulResultAt = lastMeaningfulResultAt
        self.lastReviewAttemptAt = lastReviewAttemptAt
        self.lastReviewAttemptVersion = lastReviewAttemptVersion
        self.reviewAttemptCount = reviewAttemptCount
        self.lastFeedbackPromptAt = lastFeedbackPromptAt
        self.reviewSuppressedUntil = reviewSuppressedUntil
        self.lastPurchaseAt = lastPurchaseAt
        self.pendingReviewOpportunity = pendingReviewOpportunity
        self.pendingFeedbackOpportunity = pendingFeedbackOpportunity
        self.lastSubscriptionSnapshot = lastSubscriptionSnapshot
        self.failureCounts = failureCounts
    }
}

struct ReviewFeedbackConfiguration: Sendable {
    static let maskID = ReviewFeedbackConfiguration(
        freeMinimumResults: 3,
        freeMinimumSessions: 3,
        freeMinimumActiveDays: 2,
        minimumMeaningfulUseAge: 72 * 60 * 60,
        premiumMinimumResults: 1,
        minimumHoursAfterPurchase: 24 * 60 * 60,
        reviewCooldown: 120 * 24 * 60 * 60,
        feedbackCooldown: 30 * 24 * 60 * 60,
        negativeSignalSuppression: 10 * 24 * 60 * 60,
        inactivityThreshold: 30 * 24 * 60 * 60,
        repeatedFailureThreshold: 2,
        subscriptionGroupID: "shield_pro_group"
    )

    let freeMinimumResults: Int
    let freeMinimumSessions: Int
    let freeMinimumActiveDays: Int
    let minimumMeaningfulUseAge: TimeInterval
    let premiumMinimumResults: Int
    let minimumHoursAfterPurchase: TimeInterval
    let reviewCooldown: TimeInterval
    let feedbackCooldown: TimeInterval
    let negativeSignalSuppression: TimeInterval
    let inactivityThreshold: TimeInterval
    let repeatedFailureThreshold: Int
    let subscriptionGroupID: String
}

enum ReviewEvaluationReason: Equatable, Sendable {
    case eligible
    case noQualifiedSuccess
    case insufficientMeaningfulResults
    case insufficientSessions
    case insufficientActiveDays
    case insufficientRelationshipAge
    case cooldownActive
    case versionAlreadyAttempted
    case purchaseDeferral
    case negativeSignalSuppression
}

struct ReviewEvaluation: Equatable, Sendable {
    let isEligible: Bool
    let reason: ReviewEvaluationReason
}

struct ReviewPresentationContext: Sendable {
    var isOnboarding = false
    var isBusy = false
    var hasActiveError = false
    var isInterruptedTask = false
    var isPaywallVisible = false
    var isCancellationFlow = false
    var isSupportFlow = false
    var isDestructiveOperation = false
    var isSensitiveAlertVisible = false
    var isImmediatelyAfterPayment = false
    var isNaturalPause = true

    static let naturalResult = ReviewPresentationContext()
}

enum ReviewEligibilityPolicy {
    static func evaluate(
        state: EngagementState,
        event: EngagementEvent,
        tier: EntitlementTier,
        now: Date,
        appVersion: String,
        configuration: ReviewFeedbackConfiguration = .maskID
    ) -> ReviewEvaluation {
        guard isQualifiedSuccess(event) else {
            return ReviewEvaluation(isEligible: false, reason: .noQualifiedSuccess)
        }

        let resultCount = tier.isPremium ? state.premiumResultCount : state.meaningfulResultCount
        let minimumResults = tier.isPremium
            ? configuration.premiumMinimumResults
            : configuration.freeMinimumResults
        guard resultCount >= minimumResults else {
            return ReviewEvaluation(isEligible: false, reason: .insufficientMeaningfulResults)
        }

        if !tier.isPremium {
            guard state.sessionCount >= configuration.freeMinimumSessions else {
                return ReviewEvaluation(isEligible: false, reason: .insufficientSessions)
            }
            guard state.activeDayCount >= configuration.freeMinimumActiveDays else {
                return ReviewEvaluation(isEligible: false, reason: .insufficientActiveDays)
            }
            if let firstSeenAt = state.firstSeenAt,
               now.timeIntervalSince(firstSeenAt) < configuration.minimumMeaningfulUseAge {
                return ReviewEvaluation(isEligible: false, reason: .insufficientRelationshipAge)
            }
        } else if let lastPurchaseAt = state.lastPurchaseAt,
                  now.timeIntervalSince(lastPurchaseAt) < configuration.minimumHoursAfterPurchase {
            return ReviewEvaluation(isEligible: false, reason: .purchaseDeferral)
        }

        if let lastAttempt = state.lastReviewAttemptAt,
           now.timeIntervalSince(lastAttempt) < configuration.reviewCooldown {
            return ReviewEvaluation(isEligible: false, reason: .cooldownActive)
        }
        if state.lastReviewAttemptVersion == appVersion {
            return ReviewEvaluation(isEligible: false, reason: .versionAlreadyAttempted)
        }
        if let suppressedUntil = state.reviewSuppressedUntil, suppressedUntil > now {
            return ReviewEvaluation(isEligible: false, reason: .negativeSignalSuppression)
        }
        return ReviewEvaluation(isEligible: true, reason: .eligible)
    }

    static func isQualifiedSuccess(_ event: EngagementEvent) -> Bool {
        switch event {
        case .meaningfulResultDelivered, .premiumResultDelivered, .milestoneReached:
            true
        default:
            false
        }
    }
}

enum ReviewPresentationGate {
    static func isAllowed(_ context: ReviewPresentationContext) -> Bool {
        !context.isOnboarding
            && !context.isBusy
            && !context.hasActiveError
            && !context.isInterruptedTask
            && !context.isPaywallVisible
            && !context.isCancellationFlow
            && !context.isSupportFlow
            && !context.isDestructiveOperation
            && !context.isSensitiveAlertVisible
            && !context.isImmediatelyAfterPayment
            && context.isNaturalPause
    }
}

enum SubscriptionLifecyclePolicy {
    static func events(
        previous: SubscriptionSnapshot,
        current: SubscriptionSnapshot
    ) -> [EngagementEvent] {
        if previous.isActive, !current.isActive {
            if current.isBillingIssue {
                return [.subscriptionBillingIssue]
            }
            if previous.willAutoRenew && !current.willAutoRenew {
                return [.subscriptionAutoRenewDisabled]
            }
            return [.subscriptionExpired(reason: current.expirationReason)]
        }

        var events: [EngagementEvent] = []
        if previous.willAutoRenew && !current.willAutoRenew {
            events.append(current.isBillingIssue ? .subscriptionBillingIssue : .subscriptionAutoRenewDisabled)
        } else if !previous.willAutoRenew && current.willAutoRenew {
            events.append(.subscriptionAutoRenewEnabled)
        }

        if previous.isActive,
           current.isActive,
           current.willAutoRenew,
           let oldExpiry = previous.expiresAt,
           let newExpiry = current.expiresAt,
           newExpiry > oldExpiry {
            events.append(.subscriptionRenewed(productID: current.productID ?? "unknown"))
        }
        return events
    }
}

// MARK: - Feedback model and transport

enum FeedbackTrigger: String, Codable, CaseIterable, Sendable {
    case subscriptionCancelled = "subscription_cancelled"
    case returnedAfterInactivity = "returned_after_inactivity"
    case repeatedFailure = "repeated_failure"
    case flowAbandoned = "flow_abandoned"
    case manual = "manual"

    var categories: [FeedbackCategory] {
        switch self {
        case .subscriptionCancelled:
            [.notUsingEnough, .missingFeature, .tooExpensive, .tooComplicated, .didNotWork, .privacy, .other]
        case .returnedAfterInactivity:
            [.missingFeature, .tooComplicated, .didNotWork, .notUsingEnough, .privacy, .other]
        case .repeatedFailure:
            [.didNotWork, .tooComplicated, .missingFeature, .privacy, .other]
        case .flowAbandoned:
            [.tooComplicated, .missingFeature, .didNotWork, .other]
        case .manual:
            FeedbackCategory.allCases
        }
    }
}

enum FeedbackCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case missingFeature = "missing_feature"
    case tooComplicated = "too_complicated"
    case didNotWork = "did_not_work"
    case tooExpensive = "too_expensive"
    case notUsingEnough = "not_using_enough"
    case privacy = "privacy"
    case other

    var id: String { rawValue }

    var localizationKey: String { "review_feedback_category_\(rawValue)" }
}

struct FeedbackContext: Identifiable, Sendable {
    let id = UUID()
    let trigger: FeedbackTrigger
    let feature: FeatureKey?
    let tier: EntitlementTier

    var titleKey: String {
        switch trigger {
        case .subscriptionCancelled: "review_feedback_cancel_title"
        case .returnedAfterInactivity: "review_feedback_return_title"
        case .repeatedFailure, .flowAbandoned: "review_feedback_friction_title"
        case .manual: "review_feedback_title"
        }
    }

    var messageKey: String {
        switch trigger {
        case .subscriptionCancelled: "review_feedback_cancel_message"
        case .returnedAfterInactivity: "review_feedback_return_message"
        case .repeatedFailure, .flowAbandoned: "review_feedback_friction_message"
        case .manual: "review_feedback_message"
        }
    }
}

// Privacy contract: feedback sends only the selected category, optional user
// comment, app/device diagnostics, locale, entitlement tier, and lifecycle
// timestamps. It never includes document contents, credentials, or payment data.
struct FeedbackEnvelope: Codable, Sendable {
    let category: FeedbackCategory
    let message: String?
    let trigger: FeedbackTrigger
    let appVersion: String
    let buildNumber: String
    let osVersion: String
    let locale: String
    let entitlementTier: EntitlementTier
    let featureKey: FeatureKey?
    let appName: String
    let deviceModel: String
    let installDate: Date?
    let lastUpdateDate: Date?
    let submittedAt: Date

    init(
        category: FeedbackCategory,
        message: String?,
        trigger: FeedbackTrigger,
        appVersion: String,
        buildNumber: String,
        osVersion: String,
        locale: String,
        entitlementTier: EntitlementTier,
        featureKey: FeatureKey?,
        appName: String = AppEngagementConfig.maskID.appName,
        deviceModel: String = UIDevice.current.model,
        installDate: Date? = nil,
        lastUpdateDate: Date? = nil,
        submittedAt: Date = Date()
    ) {
        self.category = category
        self.message = message
        self.trigger = trigger
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.osVersion = osVersion
        self.locale = locale
        self.entitlementTier = entitlementTier
        self.featureKey = featureKey
        self.appName = appName
        self.deviceModel = deviceModel
        self.installDate = installDate
        self.lastUpdateDate = lastUpdateDate
        self.submittedAt = submittedAt
    }

    var mailBody: String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "\(appName) feedback",
            "Category: \(category.rawValue)",
            "Trigger: \(trigger.rawValue)",
            "Feature: \(featureKey?.rawValue ?? "none")",
            "Tier: \(entitlementTier.rawValue)",
            "App version: \(appVersion)",
            "Build: \(buildNumber)",
            "OS: \(osVersion)",
            "Device: \(deviceModel)",
            "Locale: \(locale)",
            "Install date: \(installDate.map(formatter.string(from:)) ?? "unknown")",
            "Last update date: \(lastUpdateDate.map(formatter.string(from:)) ?? "unknown")",
            "Submitted at: \(formatter.string(from: submittedAt))",
            ""
        ]
        if let message, !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Comment:")
            lines.append(message.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return lines.joined(separator: "\n")
    }
}

@MainActor
protocol FeedbackTransport {
    func send(_ feedback: FeedbackEnvelope) async throws
}

enum FeedbackTransportError: Error {
    case destinationUnavailable
    case couldNotOpenMail
}

@MainActor
final class MailFeedbackTransport: NSObject, FeedbackTransport, MFMailComposeViewControllerDelegate {
    private let recipient: String

    init(recipient: String = SettingsSupportConfiguration.email ?? "") {
        self.recipient = recipient
    }

    func send(_ feedback: FeedbackEnvelope) async throws {
        guard !recipient.isEmpty else { throw FeedbackTransportError.destinationUnavailable }

        let subject = "Feedback — \(feedback.appName) \(feedback.appVersion)"
        if MFMailComposeViewController.canSendMail(), let presenter = Self.topViewController {
            let composer = MFMailComposeViewController()
            composer.setToRecipients([recipient])
            composer.setSubject(subject)
            composer.setMessageBody(feedback.mailBody, isHTML: false)
            composer.mailComposeDelegate = self
            presenter.present(composer, animated: true)
            return
        }

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: feedback.mailBody)
        ]
        guard let url = components.url else { throw FeedbackTransportError.destinationUnavailable }

        let opened = await withCheckedContinuation { continuation in
            UIApplication.shared.open(url, options: [:]) { accepted in
                continuation.resume(returning: accepted)
            }
        }
        guard opened else { throw FeedbackTransportError.couldNotOpenMail }
    }

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: Error?
    ) {
        controller.dismiss(animated: true)
    }

    private static var topViewController: UIViewController? {
        let root = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first(where: { $0.isKeyWindow })?.rootViewController

        var current = root
        while let presented = current?.presentedViewController {
            current = presented
        }
        return current
    }
}

enum AppStoreConfiguration {
    // Verified against App Store Connect metadata in .asc/metadata/review.
    static let appID = "6790398619"
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")!
}

// MARK: - Review and feedback orchestration

@MainActor
final class ReviewFeedbackCoordinator: ObservableObject {
    static let shared = ReviewFeedbackCoordinator()

    @Published private(set) var reviewRequestSignal = 0
    @Published var activeFeedbackContext: FeedbackContext?

    private enum Key {
        static let state = "shield.review_feedback.engagementState"
        static let legacyInstalledAt = "shield.review.installedAt"
        static let legacyValueScore = "shield.review.valueScore"
        static let legacyRequestDates = "shield.review.automaticRequestDates"
    }

    private let defaults: UserDefaults
    private let configuration: ReviewFeedbackConfiguration
    private let transport: FeedbackTransport
    private let entitlementTierProvider: @MainActor () -> EntitlementTier
    private let logger = Logger(subsystem: "com.romerodev.shield", category: "ReviewFeedback")
    private var state: EngagementState

    init(
        defaults: UserDefaults = .standard,
        configuration: ReviewFeedbackConfiguration = .maskID,
        transport: FeedbackTransport? = nil,
        tierProvider: @escaping @MainActor () -> EntitlementTier = {
            PremiumManager.shared.isPro ? .premium : .free
        }
    ) {
        self.defaults = defaults
        self.configuration = configuration
        self.transport = transport ?? MailFeedbackTransport()
        self.entitlementTierProvider = tierProvider
        self.state = Self.loadState(from: defaults)
        if self.state.firstSeenAt == nil {
            self.state.firstSeenAt = Date()
            saveState()
        }
    }

    func track(_ event: EngagementEvent, now: Date = Date()) {
        guard !Self.isAutomatedRun else { return }

        var next = state
        if next.firstSeenAt == nil { next.firstSeenAt = now }

        switch event {
        case .appLaunched:
            break
        case .sessionStarted:
            registerSession(&next, now: now)
        case .sessionEnded:
            break
        case .onboardingCompleted:
            break
        case .coreActionCompleted:
            break
        case .meaningfulResultDelivered(let feature):
            registerMeaningfulResult(&next, feature: feature, tier: currentTier, now: now)
        case .premiumResultDelivered(let feature):
            registerMeaningfulResult(&next, feature: feature, tier: currentTier, now: now)
            next.premiumResultCount += 1
            createReviewOpportunityIfEligible(&next, event: event, feature: feature, tier: currentTier, now: now)
        case .milestoneReached(let key):
            let feature: FeatureKey = key.contains("export") ? .secureExport : .unknown
            createReviewOpportunityIfEligible(
                &next,
                event: event,
                feature: feature,
                tier: currentTier,
                now: now
            )
        case .purchaseCompleted:
            next.lastPurchaseAt = now
        case .subscriptionActivated:
            next.lastPurchaseAt = next.lastPurchaseAt ?? now
        case .subscriptionRenewed:
            break
        case .subscriptionAutoRenewDisabled:
            suppressAndCreateFeedback(
                &next,
                trigger: .subscriptionCancelled,
                feature: nil,
                tier: currentTier,
                now: now
            )
        case .subscriptionAutoRenewEnabled, .subscriptionReactivated:
            break
        case .subscriptionExpired(let reason):
            if Self.isVoluntaryCancellation(reason: reason) {
                suppressAndCreateFeedback(
                    &next,
                    trigger: .subscriptionCancelled,
                    feature: nil,
                    tier: currentTier,
                    now: now
                )
            } else {
                next.reviewSuppressedUntil = now.addingTimeInterval(configuration.negativeSignalSuppression)
                next.pendingReviewOpportunity = nil
            }
        case .subscriptionBillingIssue:
            next.reviewSuppressedUntil = now.addingTimeInterval(configuration.negativeSignalSuppression)
            next.pendingReviewOpportunity = nil
        case .flowAbandoned(let flow):
            suppressAndCreateFeedback(
                &next,
                trigger: .flowAbandoned,
                feature: flow,
                tier: currentTier,
                now: now
            )
        case .operationFailed(let feature):
            let count = (next.failureCounts[feature.rawValue] ?? 0) + 1
            next.failureCounts[feature.rawValue] = count
            next.reviewSuppressedUntil = now.addingTimeInterval(configuration.negativeSignalSuppression)
            next.pendingReviewOpportunity = nil
            if count >= configuration.repeatedFailureThreshold {
                createFeedbackIfAllowed(
                    &next,
                    trigger: .repeatedFailure,
                    feature: feature,
                    tier: currentTier,
                    now: now
                )
            }
        case .repeatedFailure(let feature):
            suppressAndCreateFeedback(
                &next,
                trigger: .repeatedFailure,
                feature: feature,
                tier: currentTier,
                now: now
            )
        case .supportRequested:
            next.reviewSuppressedUntil = now.addingTimeInterval(configuration.negativeSignalSuppression)
            next.pendingReviewOpportunity = nil
        case .returnedAfterInactivity(let days):
            guard days > 0 else { break }
            createFeedbackIfAllowed(
                &next,
                trigger: .returnedAfterInactivity,
                feature: nil,
                tier: currentTier,
                now: now
            )
        case .permissionDenied:
            next.reviewSuppressedUntil = now.addingTimeInterval(configuration.negativeSignalSuppression)
            next.pendingReviewOpportunity = nil
        }

        state = next
        saveState()
    }

    /// Called only after a completed result is visible and the UI is idle.
    func markNaturalPause(
        context: ReviewPresentationContext = .naturalResult,
        now: Date = Date()
    ) {
        guard !Self.isAutomatedRun, ReviewPresentationGate.isAllowed(context) else { return }

        if let pendingFeedback = state.pendingFeedbackOpportunity,
           canPresentFeedback(now: now) {
            state.pendingFeedbackOpportunity = nil
            state.lastFeedbackPromptAt = now
            activeFeedbackContext = FeedbackContext(
                trigger: pendingFeedback.trigger,
                feature: pendingFeedback.feature,
                tier: pendingFeedback.tier
            )
            saveState()
            return
        }

        guard let pending = state.pendingReviewOpportunity else { return }
        let evaluation = ReviewEligibilityPolicy.evaluate(
            state: state,
            event: .meaningfulResultDelivered(feature: pending.feature),
            tier: pending.tier,
            now: now,
            appVersion: Self.appVersion,
            configuration: configuration
        )
        guard evaluation.isEligible else {
            debug("Opportunity rejected: \(String(describing: evaluation.reason))")
            return
        }
        AppState.trackEvent("review_opportunity_eligible", properties: [
            "trigger": "natural_pause",
            "feature_key": pending.feature.rawValue,
            "user_tier": pending.tier.rawValue
        ])
        reviewRequestSignal &+= 1
    }

    /// Opens the manually requested feedback form from Settings without
    /// waiting for an automatic engagement opportunity.
    func presentManualFeedback() {
        guard activeFeedbackContext == nil else { return }
        activeFeedbackContext = FeedbackContext(
            trigger: .manual,
            feature: nil,
            tier: currentTier
        )
    }

    func consumeReviewRequest(using request: @escaping @MainActor () -> Void) {
        guard !Self.isAutomatedRun else {
            return
        }

        guard let opportunity = state.pendingReviewOpportunity else { return }
        state.pendingReviewOpportunity = nil
        recordReviewAttempt(source: "natural_pause", feature: opportunity.feature, tier: opportunity.tier)
        saveState()
        request()
    }

    func dismissFeedback() {
        let trigger = activeFeedbackContext?.trigger.rawValue ?? "unknown"
        activeFeedbackContext = nil
        state.lastFeedbackPromptAt = Date()
        saveState()
        AppState.trackEvent("feedback_dismissed", properties: ["trigger": trigger])
    }

    func completeFeedback() {
        activeFeedbackContext = nil
        saveState()
    }

    func submitFeedback(category: FeedbackCategory, message: String?, context: FeedbackContext) async -> Bool {
        let envelope = FeedbackEnvelope(
            category: category,
            message: message,
            trigger: context.trigger,
            appVersion: Self.appVersion,
            buildNumber: Self.buildNumber,
            osVersion: UIDevice.current.systemVersion,
            locale: Locale.current.identifier,
            entitlementTier: context.tier,
            featureKey: context.feature,
            appName: AppEngagementConfig.maskID.appName,
            deviceModel: UIDevice.current.model,
            installDate: AppEngagementRuntime.metadata.installDate,
            lastUpdateDate: AppEngagementRuntime.metadata.lastUpdateDate,
            submittedAt: Date()
        )

        do {
            try await transport.send(envelope)
            state.lastFeedbackPromptAt = Date()
            saveState()
            AppState.trackEvent("feedback_submitted", properties: [
                "trigger": context.trigger.rawValue,
                "category": category.rawValue,
                "feature_key": context.feature?.rawValue ?? "none",
                "user_tier": context.tier.rawValue
            ])
            return true
        } catch {
            debug("Feedback transport failed: \(String(describing: error))")
            return false
        }
    }

    func recordSubscriptionSnapshot(_ snapshot: SubscriptionSnapshot, now: Date = Date()) {
        let events = state.lastSubscriptionSnapshot.map {
            SubscriptionLifecyclePolicy.events(previous: $0, current: snapshot)
        } ?? []
        state.lastSubscriptionSnapshot = snapshot
        saveState()
        for event in events {
            track(event, now: now)
        }
    }

    var currentState: EngagementState { state }

    private var currentTier: EntitlementTier {
        entitlementTierProvider()
    }

    private func registerSession(_ state: inout EngagementState, now: Date) {
        if let lastActiveAt = state.lastActiveAt,
           now.timeIntervalSince(lastActiveAt) >= configuration.inactivityThreshold,
           state.sessionCount >= configuration.freeMinimumSessions {
            let days = max(1, Int(now.timeIntervalSince(lastActiveAt) / (24 * 60 * 60)))
            createFeedbackIfAllowed(
                &state,
                trigger: .returnedAfterInactivity,
                feature: nil,
                tier: currentTier,
                now: now
            )
            AppState.trackEvent("returned_after_inactivity", properties: ["count": String(days)])
        }

        state.sessionCount += 1
        if let lastActiveAt = state.lastActiveAt {
            if !Calendar.current.isDate(lastActiveAt, inSameDayAs: now) {
                state.activeDayCount += 1
            }
        } else {
            state.activeDayCount = max(state.activeDayCount, 1)
        }
        state.lastActiveAt = now
    }

    private func registerMeaningfulResult(
        _ state: inout EngagementState,
        feature: FeatureKey,
        tier: EntitlementTier,
        now: Date
    ) {
        state.meaningfulResultCount += 1
        state.lastMeaningfulResultAt = now
        state.failureCounts[feature.rawValue] = 0
        createReviewOpportunityIfEligible(
            &state,
            event: .meaningfulResultDelivered(feature: feature),
            feature: feature,
            tier: tier,
            now: now
        )
    }

    private func createReviewOpportunityIfEligible(
        _ state: inout EngagementState,
        event: EngagementEvent,
        feature: FeatureKey,
        tier: EntitlementTier,
        now: Date
    ) {
        guard state.pendingFeedbackOpportunity == nil else { return }
        let evaluation = ReviewEligibilityPolicy.evaluate(
            state: state,
            event: event,
            tier: tier,
            now: now,
            appVersion: Self.appVersion,
            configuration: configuration
        )
        guard evaluation.isEligible else {
            debug("Opportunity rejected: \(String(describing: evaluation.reason))")
            return
        }
        guard state.pendingReviewOpportunity == nil else { return }
        state.pendingReviewOpportunity = PendingReviewOpportunity(
            feature: feature,
            tier: tier,
            createdAt: now
        )
        AppState.trackEvent("review_opportunity_created", properties: [
            "trigger": eventName(event),
            "feature_key": feature.rawValue,
            "user_tier": tier.rawValue
        ])
    }

    private func suppressAndCreateFeedback(
        _ state: inout EngagementState,
        trigger: FeedbackTrigger,
        feature: FeatureKey?,
        tier: EntitlementTier,
        now: Date
    ) {
        state.reviewSuppressedUntil = now.addingTimeInterval(configuration.negativeSignalSuppression)
        state.pendingReviewOpportunity = nil
        createFeedbackIfAllowed(&state, trigger: trigger, feature: feature, tier: tier, now: now)
    }

    private func createFeedbackIfAllowed(
        _ state: inout EngagementState,
        trigger: FeedbackTrigger,
        feature: FeatureKey?,
        tier: EntitlementTier,
        now: Date
    ) {
        guard state.pendingFeedbackOpportunity == nil else { return }
        if let lastPrompt = state.lastFeedbackPromptAt,
           now.timeIntervalSince(lastPrompt) < configuration.feedbackCooldown {
            return
        }
        state.pendingFeedbackOpportunity = PendingFeedbackOpportunity(
            trigger: trigger,
            feature: feature,
            tier: tier,
            createdAt: now
        )
        state.pendingReviewOpportunity = nil
        AppState.trackEvent("feedback_opportunity_created", properties: [
            "trigger": trigger.rawValue,
            "feature_key": feature?.rawValue ?? "none",
            "user_tier": tier.rawValue
        ])
        debug("Feedback opportunity accepted: \(trigger.rawValue)")
    }

    private func canPresentFeedback(now: Date) -> Bool {
        guard let lastPrompt = state.lastFeedbackPromptAt else { return true }
        return now.timeIntervalSince(lastPrompt) >= configuration.feedbackCooldown
    }

    private func recordReviewAttempt(source: String, feature: FeatureKey?, tier: EntitlementTier) {
        let now = Date()
        state.lastReviewAttemptAt = now
        state.lastReviewAttemptVersion = Self.appVersion
        state.reviewAttemptCount += 1
        saveState()
        AppState.trackEvent("review_request_attempted", properties: [
            "trigger": source,
            "feature_key": feature?.rawValue ?? "none",
            "user_tier": tier.rawValue
        ])
    }

    private func saveState() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: Key.state)
    }

    private static func loadState(from defaults: UserDefaults) -> EngagementState {
        if let data = defaults.data(forKey: Key.state),
           let saved = try? JSONDecoder().decode(EngagementState.self, from: data) {
            return saved
        }

        let firstSeen: Date? = {
            guard defaults.object(forKey: Key.legacyInstalledAt) != nil else { return nil }
            return Date(timeIntervalSince1970: defaults.double(forKey: Key.legacyInstalledAt))
        }()
        let legacyScore = defaults.integer(forKey: Key.legacyValueScore)
        let legacyDates = (defaults.array(forKey: Key.legacyRequestDates) as? [Double]) ?? []
        return EngagementState(
            firstSeenAt: firstSeen,
            meaningfulResultCount: legacyScore > 0 ? 1 : 0,
            lastReviewAttemptAt: legacyDates.map(Date.init(timeIntervalSince1970:)).max(),
            reviewAttemptCount: legacyDates.count
        )
    }

    private func debug(_ message: String) {
        #if DEBUG
        logger.debug("\(message, privacy: .public)")
        #endif
    }

    private func eventName(_ event: EngagementEvent) -> String {
        switch event {
        case .meaningfulResultDelivered: "meaningful_result"
        case .premiumResultDelivered: "premium_result"
        case .milestoneReached: "milestone"
        default: "success"
        }
    }

    private static func isVoluntaryCancellation(reason: String?) -> Bool {
        let normalized = reason?.lowercased() ?? ""
        guard !normalized.contains("billing"),
              !normalized.contains("payment"),
              !normalized.contains("retry"),
              !normalized.contains("grace") else { return false }
        return normalized.contains("auto")
            || normalized.contains("renew")
            || normalized.isEmpty
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }

    private static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
    }

    private static var isAutomatedRun: Bool {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.contains("-ui-testing") || arguments.contains("-aso-screenshots")
    }
}

// Compatibility name for existing portfolio integrations. New callers should
// use ReviewFeedbackCoordinator and semantic EngagementEvent values.
@MainActor
final class AppReviewManager {
    static let shared = AppReviewManager()

    private init() {}

    /// Explicit review actions use Apple's product-page deep link. The
    /// StoreKit request action is reserved for automatic natural-pause moments
    /// because Apple does not display it for TestFlight builds.
    var writeReviewURL: URL { AppStoreConfiguration.writeReviewURL }
}

// MARK: - StoreKit 2 subscription lifecycle

@MainActor
final class SubscriptionLifecycleObserver {
    static let shared = SubscriptionLifecycleObserver()

    private var started = false
    private let logger = Logger(subsystem: "com.romerodev.shield", category: "SubscriptionLifecycle")

    func start() {
        guard !started else { return }
        started = true
        Task { await refresh() }
    }

    func refresh() async {
        do {
            let statuses = try await Product.SubscriptionInfo.status(
                for: ReviewFeedbackConfiguration.maskID.subscriptionGroupID
            )
            let snapshots = statuses.compactMap(Self.snapshot(from:))
            guard let snapshot = snapshots.first(where: { $0.isActive }) ?? snapshots.first else { return }
            ReviewFeedbackCoordinator.shared.recordSubscriptionSnapshot(snapshot)
        } catch {
            #if DEBUG
            logger.debug("Subscription status refresh unavailable: \(String(describing: error), privacy: .public)")
            #endif
        }
    }

    func showManageSubscriptions() async {
        guard let scene = activeWindowScene else { return }
        await refresh()
        do {
            try await AppStore.showManageSubscriptions(in: scene)
            await refresh()
            ReviewFeedbackCoordinator.shared.markNaturalPause(
                context: ReviewPresentationContext(isCancellationFlow: false, isNaturalPause: true)
            )
        } catch {
            #if DEBUG
            logger.debug("Manage subscriptions unavailable: \(String(describing: error), privacy: .public)")
            #endif
        }
    }

    private var activeWindowScene: UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    private static func snapshot(
        from status: Product.SubscriptionInfo.Status
    ) -> SubscriptionSnapshot? {
        guard case .verified(let renewalInfo) = status.renewalInfo,
              case .verified(let transaction) = status.transaction else {
            return nil
        }
        return SubscriptionSnapshot(
            productID: transaction.productID,
            state: String(describing: status.state),
            willAutoRenew: renewalInfo.willAutoRenew,
            expirationReason: renewalInfo.expirationReason.map { String(describing: $0) },
            expiresAt: transaction.expirationDate,
            checkedAt: Date()
        )
    }
}

// MARK: - SwiftUI StoreKit boundary and feedback UI

struct ReviewFeedbackBridge: View {
    let isPresentationAllowed: Bool

    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var coordinator = ReviewFeedbackCoordinator.shared

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
            .onAppear(perform: consumeIfPossible)
            .onChange(of: coordinator.reviewRequestSignal) { _, _ in consumeIfPossible() }
            .onChange(of: scenePhase) { _, _ in consumeIfPossible() }
            .onChange(of: isPresentationAllowed) { _, _ in consumeIfPossible() }
        .sheet(item: $coordinator.activeFeedbackContext) { context in
                FeedbackPromptView(context: context) { category, message in
                    await coordinator.submitFeedback(category: category, message: message, context: context)
                } onComplete: {
                    coordinator.completeFeedback()
                } onDismiss: {
                    coordinator.dismissFeedback()
                }
            }
    }

    private func consumeIfPossible() {
        guard isPresentationAllowed, scenePhase == .active else { return }
        coordinator.consumeReviewRequest {
            requestReview()
        }
    }
}

struct FeedbackPromptView: View {
    let context: FeedbackContext
    let onSubmit: (FeedbackCategory, String?) async -> Bool
    let onComplete: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: FeedbackCategory?
    @State private var comment = ""
    @State private var isSending = false
    @State private var showSendError = false
    @State private var didSubmit = false
    @State private var thanksSecondsRemaining = FeedbackPromptConfiguration.thanksCountdownSeconds

    private var strings: LanguageManager { .shared }

    var body: some View {
        NavigationStack {
            if didSubmit {
                FeedbackThanksView(secondsRemaining: thanksSecondsRemaining) {
                    onComplete()
                    dismiss()
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: ShieldTheme.s4) {
                        Text(strings.settings(context.titleKey))
                            .shieldFont(26, weight: .heavy, design: .rounded)
                            .foregroundStyle(ShieldTheme.primary(scheme))
                        Text(strings.settings(context.messageKey))
                            .font(.body)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(spacing: 0) {
                            ForEach(context.trigger.categories) { category in
                                Button {
                                    selectedCategory = category
                                } label: {
                                    HStack(spacing: ShieldTheme.s3) {
                                        Image(systemName: selectedCategory == category ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedCategory == category
                                                ? ShieldTheme.accent(scheme)
                                                : ShieldTheme.tertiary(scheme))
                                            .accessibilityHidden(true)
                                        Text(strings.settings(category.localizationKey))
                                            .foregroundStyle(ShieldTheme.primary(scheme))
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                    .padding(.vertical, ShieldTheme.s3)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("feedback.option.\(category.rawValue)")
                                .accessibilityAddTraits(selectedCategory == category ? .isSelected : [])
                            }
                        }
                        .padding(.horizontal, ShieldTheme.s3)
                        .background(ShieldTheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: ShieldTheme.rLG))

                        TextField(
                            strings.settings("review_feedback_comment_placeholder"),
                            text: $comment,
                            axis: .vertical
                        )
                        .lineLimit(4...8)
                        .textFieldStyle(.roundedBorder)
                        .accessibilityLabel(strings.settings("review_feedback_comment_placeholder"))
                        .accessibilityIdentifier("feedback.comment")
                        .accessibilityHint(strings.settings("review_feedback_comment_hint"))

                        Button {
                            submit()
                        } label: {
                            Group {
                                if isSending { ProgressView().tint(ShieldTheme.accentText) }
                                else { Text(strings.settings("review_feedback_send")) }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(ShieldTheme.accent(scheme))
                        .accessibilityIdentifier("feedback.action.send")
                        .disabled(selectedCategory == nil || isSending)

                        Button(strings.settings("review_feedback_not_now"), role: .cancel) {
                            onDismiss()
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .disabled(isSending)
                    }
                    .padding(ShieldTheme.s5)
                    .frame(maxWidth: 640)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .background(ShieldTheme.pageBackground(scheme).ignoresSafeArea())
        .navigationTitle(strings.settings("review_feedback_navigation_title"))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: didSubmit) {
            guard didSubmit else { return }

            thanksSecondsRemaining = FeedbackPromptConfiguration.thanksCountdownSeconds
            for seconds in stride(
                from: FeedbackPromptConfiguration.thanksCountdownSeconds,
                through: 1,
                by: -1
            ) {
                guard !Task.isCancelled else { return }
                thanksSecondsRemaining = seconds

                do {
                    try await Task.sleep(for: .seconds(1))
                } catch {
                    return
                }
            }

            guard !Task.isCancelled else { return }
            onComplete()
            dismiss()
        }
        .alert(
            strings.settings("review_feedback_error_title"),
            isPresented: $showSendError
        ) {
            Button(strings.common("common_ok"), role: .cancel) {}
        } message: {
            Text(strings.settings("review_feedback_error_message"))
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func submit() {
        guard let selectedCategory else { return }
        isSending = true
        Task { @MainActor in
            let didSend = await onSubmit(selectedCategory, comment)
            isSending = false
            if didSend {
                didSubmit = true
            } else {
                showSendError = true
            }
        }
    }
}

enum FeedbackPromptConfiguration {
    static let thanksCountdownSeconds = 10
}

private struct FeedbackThanksView: View {
    let secondsRemaining: Int
    let onClose: () -> Void

    @Environment(\.colorScheme) private var scheme

    private var strings: LanguageManager { .shared }

    var body: some View {
        VStack(spacing: ShieldTheme.s4) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(ShieldTheme.accent(scheme))
                .accessibilityHidden(true)
            Text(strings.settings("review_feedback_thanks_title"))
                .shieldFont(26, weight: .heavy, design: .rounded)
                .foregroundStyle(ShieldTheme.primary(scheme))
                .multilineTextAlignment(.center)
            Text(strings.settings("review_feedback_thanks_message"))
                .font(.body)
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .multilineTextAlignment(.center)
            Text(strings.settings("review_feedback_thanks_countdown", secondsRemaining))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(ShieldTheme.secondary(scheme))
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("feedback.thanks.countdown")
            Button(strings.common("common_ok"), action: onClose)
                .buttonStyle(.borderedProminent)
                .tint(ShieldTheme.accent(scheme))
                .accessibilityIdentifier("feedback.thanks.close")
        }
        .padding(ShieldTheme.s5)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
