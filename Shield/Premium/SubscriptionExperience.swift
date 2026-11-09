import Foundation
import Security

enum AccessCohort: String, Codable, Equatable {
    case newUser
    case existingFreeUser
}

/// Product policy defaults live in one place so transition periods can be
/// reviewed or changed without scattering day counts across the app.
struct AccessConfiguration: Equatable {
    var newUserFullAccessDays = 15
    var existingUserFullAccessDays = 30
    var existingUserRecoveryDays = 30

    static let current = AccessConfiguration()
    static let noticeVersion = "commercial-access-2026-11-v1"
}

enum AccessMigrationClassifier {
    static func cohort(
        preMigrationInstallEvidence: Bool,
        wasOnboarded: Bool,
        savedDocumentCount: Int,
        previouslyProcessedDocumentCount: Int
    ) -> AccessCohort {
        preMigrationInstallEvidence || wasOnboarded || savedDocumentCount > 0 || previouslyProcessedDocumentCount > 0
            ? .existingFreeUser
            : .newUser
    }
}

enum AccessCapability: String, CaseIterable {
    case createContent
    case modifyContent
    case importContent
    case premiumWorkflow
    case cloudWrite
    case viewOwnData
    case exportOwnData
    case deleteOwnData
    case restorePurchases
    case manageSubscription
    case support
    case legalInformation
    case appearanceSettings
}

enum AppAccessState: Equatable {
    case verifying
    case storageUnavailable
    case newUserNotice
    case existingUserNotice
    case temporaryFullAccess(expiresAt: Date, cohort: AccessCohort)
    case readOnlyRecovery(until: Date)
    case mandatoryPaywall
    case purchased

    var hasFullAccess: Bool {
        switch self {
        case .temporaryFullAccess, .purchased: true
        default: false
        }
    }

    var isReadOnly: Bool {
        switch self {
        case .verifying, .storageUnavailable, .readOnlyRecovery, .mandatoryPaywall: true
        default: false
        }
    }

    func allows(_ capability: AccessCapability) -> Bool {
        if hasFullAccess { return true }
        switch capability {
        case .viewOwnData, .exportOwnData, .deleteOwnData, .restorePurchases,
             .manageSubscription, .support, .legalInformation, .appearanceSettings:
            return true
        case .createContent, .modifyContent, .importContent, .premiumWorkflow, .cloudWrite:
            return false
        }
    }
}

struct AccessRecord: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion = currentSchemaVersion
    var cohort: AccessCohort
    var noticeAcceptedAt: Date?
    var noticeVersion: String?
    var fullAccessStartedAt: Date?
    var fullAccessExpiresAt: Date?
    var recoveryExpiresAt: Date?
    var lastTrustedAt: Date?
    var paidEntitlementObservedAt: Date?

    static func start(
        cohort: AccessCohort,
        at now: Date,
        calendar: Calendar = .current,
        configuration: AccessConfiguration = .current
    ) -> AccessRecord? {
        let fullDays = cohort == .newUser
            ? configuration.newUserFullAccessDays
            : configuration.existingUserFullAccessDays
        guard let fullEnd = calendar.date(byAdding: .day, value: fullDays, to: now) else { return nil }
        let recoveryEnd: Date?
        if cohort == .existingFreeUser {
            guard let value = calendar.date(
                byAdding: .day,
                value: configuration.existingUserRecoveryDays,
                to: fullEnd
            ) else { return nil }
            recoveryEnd = value
        } else {
            recoveryEnd = nil
        }
        return AccessRecord(
            cohort: cohort,
            noticeAcceptedAt: now,
            noticeVersion: AccessConfiguration.noticeVersion,
            fullAccessStartedAt: now,
            fullAccessExpiresAt: fullEnd,
            recoveryExpiresAt: recoveryEnd,
            lastTrustedAt: now,
            paidEntitlementObservedAt: nil
        )
    }

    static func paidAccessObserved(cohort: AccessCohort, at now: Date) -> AccessRecord {
        AccessRecord(
            cohort: cohort,
            noticeAcceptedAt: nil,
            noticeVersion: nil,
            fullAccessStartedAt: nil,
            fullAccessExpiresAt: nil,
            recoveryExpiresAt: nil,
            lastTrustedAt: now,
            paidEntitlementObservedAt: now
        )
    }

    func trustedNow(_ candidate: Date) -> Date {
        max(candidate, lastTrustedAt ?? candidate)
    }
}

enum AccessPolicy {
    static func resolve(
        record: AccessRecord?,
        missingRecordCohort: AccessCohort,
        now: Date,
        hasPaidAccess: Bool,
        storageAvailable: Bool = true
    ) -> AppAccessState {
        if hasPaidAccess { return .purchased }
        guard storageAvailable else { return .storageUnavailable }
        guard let record else {
            return missingRecordCohort == .newUser ? .newUserNotice : .existingUserNotice
        }
        if record.paidEntitlementObservedAt != nil, record.fullAccessStartedAt == nil {
            return .mandatoryPaywall
        }
        let trustedNow = record.trustedNow(now)
        guard record.noticeAcceptedAt != nil,
              let fullStart = record.fullAccessStartedAt,
              let fullEnd = record.fullAccessExpiresAt,
              fullEnd > fullStart
        else {
            return record.cohort == .newUser ? .newUserNotice : .existingUserNotice
        }
        if trustedNow < fullEnd {
            return .temporaryFullAccess(expiresAt: fullEnd, cohort: record.cohort)
        }
        if record.cohort == .existingFreeUser,
           let recoveryEnd = record.recoveryExpiresAt,
           trustedNow < recoveryEnd {
            return .readOnlyRecovery(until: recoveryEnd)
        }
        return .mandatoryPaywall
    }

    static func refreshed(_ record: AccessRecord, at now: Date) -> AccessRecord {
        var updated = record
        updated.lastTrustedAt = record.trustedNow(now)
        return updated
    }
}

enum AccessBoundarySavePolicy {
    static func canIssueLease(
        for documentID: String,
        activeEditorDocumentID: String?,
        documentIsPersisted: Bool,
        previousState: AppAccessState,
        nextState: AppAccessState,
        leaseAlreadyIssued: Bool
    ) -> Bool {
        previousState.hasFullAccess
            && !nextState.hasFullAccess
            && nextState.isReadOnly
            && activeEditorDocumentID == documentID
            && documentIsPersisted
            && !leaseAlreadyIssued
    }
}

enum AccessRecordLoadResult {
    case record(AccessRecord)
    case missing
    case unavailable(OSStatus)
}

/// Stores only the first-access cohort and its clock in the device Keychain.
/// This reduces accidental resets; it does not provide server-backed anti-reset guarantees.
struct AccessStateStore {
    static let service = "com.romerodev.shield.access-state"
    static let account = "commercial-access-v1"

    func load() -> AccessRecordLoadResult {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return .missing }
        guard status == errSecSuccess,
              let data = result as? Data,
              let record = try? JSONDecoder().decode(AccessRecord.self, from: data),
              record.schemaVersion == AccessRecord.currentSchemaVersion
        else { return .unavailable(status == errSecSuccess ? errSecDecode : status) }
        return .record(record)
    }

    @discardableResult
    func save(_ record: AccessRecord) -> Bool {
        guard let data = try? JSONEncoder().encode(record) else { return false }
        let key: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.service,
            kSecAttrAccount as String: Self.account
        ]
        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(key as CFDictionary, update as CFDictionary)
        if status == errSecSuccess { return true }
        guard status == errSecItemNotFound else { return false }
        var add = key
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }
}

enum SubscriptionDurationUnit: Equatable {
    case day
    case week
    case month
    case year
    case other
}

struct SubscriptionProductSnapshot: Equatable {
    let productIdentifier: String
    let price: Decimal
    let displayPrice: String
    let durationUnit: SubscriptionDurationUnit
    let durationValue: Int
    let subscriptionGroupIdentifier: String
    let subscriptionGroupLevel: Int
    let hasIntroductoryOffer: Bool
}

struct AnnualEventPricing: Equatable {
    let standardPrice: Decimal
    let eventPrice: Decimal
    let standardDisplayPrice: String
    let eventDisplayPrice: String
    let discount: Decimal
    let discountPercent: Int
}

enum AnnualEventPriceValidator {
    static let standardProductID = ShieldProduct.annual.rawValue
    static let eventProductID = ShieldProduct.annualEvent.rawValue
    static let maximumTargetDeviation = Decimal(string: "0.05")!

    static func validate(
        standard: SubscriptionProductSnapshot,
        event: SubscriptionProductSnapshot,
        expectedEventProductIdentifier: String = eventProductID,
        targetDiscountPercent: Int = 50
    ) -> AnnualEventPricing? {
        guard standard.productIdentifier == standardProductID,
              event.productIdentifier == expectedEventProductIdentifier,
              (1...99).contains(targetDiscountPercent),
              standard.price > 0,
              event.price > 0,
              event.price < standard.price,
              !standard.displayPrice.isEmpty,
              !event.displayPrice.isEmpty,
              standard.durationUnit == .year,
              standard.durationValue == 1,
              event.durationUnit == .year,
              event.durationValue == 1,
              !standard.subscriptionGroupIdentifier.isEmpty,
              standard.subscriptionGroupIdentifier == event.subscriptionGroupIdentifier,
              standard.subscriptionGroupLevel == event.subscriptionGroupLevel,
              !event.hasIntroductoryOffer else {
            return nil
        }

        let discount = (standard.price - event.price) / standard.price
        let targetDiscount = Decimal(targetDiscountPercent) / 100
        let deviation = discount >= targetDiscount
            ? discount - targetDiscount
            : targetDiscount - discount
        guard deviation <= maximumTargetDeviation else { return nil }

        let percent = Int(
            NSDecimalNumber(decimal: discount * Decimal(100)).doubleValue.rounded()
        )
        return AnnualEventPricing(
            standardPrice: standard.price,
            eventPrice: event.price,
            standardDisplayPrice: standard.displayPrice,
            eventDisplayPrice: event.displayPrice,
            discount: discount,
            discountPercent: percent
        )
    }
}

enum SubscriptionPaywallExperienceResolver {
    static func shouldUseEvent(
        eventIsActive: Bool,
        monetizationConfigured: Bool,
        userIsNotConfirmedFree: Bool,
        eventOfferingAvailable: Bool,
        expectedProductsAvailable: Bool,
        validatedPricing: AnnualEventPricing?
    ) -> Bool {
        eventIsActive
            && monetizationConfigured
            && !userIsNotConfirmedFree
            && eventOfferingAvailable
            && expectedProductsAvailable
            && validatedPricing != nil
    }
}
