import Foundation
import Testing
@testable import Shield

@Suite("Subscription experience resolution")
struct SubscriptionExperienceTests {
    private func snapshot(
        id: String,
        price: Decimal,
        unit: SubscriptionDurationUnit = .year,
        duration: Int = 1,
        group: String = "shield_pro_group",
        level: Int = 1,
        introductoryOffer: Bool = false
    ) -> SubscriptionProductSnapshot {
        SubscriptionProductSnapshot(
            productIdentifier: id,
            price: price,
            displayPrice: "€\(NSDecimalNumber(decimal: price))",
            durationUnit: unit,
            durationValue: duration,
            subscriptionGroupIdentifier: group,
            subscriptionGroupLevel: level,
            hasIntroductoryOffer: introductoryOffer
        )
    }

    @Test("Accepts a localized annual Event price and computes its real discount")
    func acceptsStorefrontPrice() {
        let standard = snapshot(
            id: AnnualEventPriceValidator.standardProductID,
            price: Decimal(string: "29.99")!
        )
        let event = snapshot(
            id: AnnualEventPriceValidator.eventProductID,
            price: Decimal(string: "14.99")!
        )

        let pricing = AnnualEventPriceValidator.validate(standard: standard, event: event)

        #expect(pricing?.discountPercent == 50)
        #expect(pricing?.standardDisplayPrice == "€29.99")
        #expect(pricing?.eventDisplayPrice == "€14.99")
    }

    @Test("Recurring plans disclose the next charge, billing period, and renewal")
    @MainActor
    func renewalDisclosureMakesTheNextChargeClear() {
        let english = SubscriptionRenewalDisclosureCopy.text(
            displayPrice: "$12.99",
            renewalPeriodLabel: "/year",
            language: .en
        )
        #expect(english.contains("$12.99/year"))
        #expect(english.contains("automatically renews until canceled"))

        let spanish = SubscriptionRenewalDisclosureCopy.text(
            displayPrice: "12,99 €",
            renewalPeriodLabel: "/año",
            language: .es
        )
        #expect(spanish.contains("12,99 €/año"))
        #expect(spanish.contains("se renueva automáticamente"))
        #expect(!spanish.localizedCaseInsensitiveContains("prueba"))
    }

    @Test("Rejects product, duration, group, level, introductory offer, and price mismatches")
    func rejectsConfigurationMismatch() {
        let standard = snapshot(
            id: AnnualEventPriceValidator.standardProductID,
            price: Decimal(string: "29.99")!
        )
        let validEvent = snapshot(
            id: AnnualEventPriceValidator.eventProductID,
            price: Decimal(string: "14.99")!
        )

        #expect(AnnualEventPriceValidator.validate(
            standard: standard,
            event: snapshot(id: "wrong.product", price: Decimal(string: "14.99")!)
        ) == nil)
        #expect(AnnualEventPriceValidator.validate(
            standard: standard,
            event: snapshot(id: AnnualEventPriceValidator.eventProductID, price: 14.99, unit: .month)
        ) == nil)
        #expect(AnnualEventPriceValidator.validate(
            standard: standard,
            event: snapshot(id: AnnualEventPriceValidator.eventProductID, price: 14.99, group: "other")
        ) == nil)
        #expect(AnnualEventPriceValidator.validate(
            standard: standard,
            event: snapshot(id: AnnualEventPriceValidator.eventProductID, price: 14.99, level: 2)
        ) == nil)
        #expect(AnnualEventPriceValidator.validate(
            standard: standard,
            event: snapshot(
                id: AnnualEventPriceValidator.eventProductID,
                price: Decimal(string: "14.99")!,
                introductoryOffer: true
            )
        ) == nil)
        #expect(AnnualEventPriceValidator.validate(
            standard: standard,
            event: snapshot(id: AnnualEventPriceValidator.eventProductID, price: Decimal(string: "20.00")!)
        ) == nil)
        #expect(AnnualEventPriceValidator.validate(standard: standard, event: validEvent) != nil)
    }

    @Test("Automatically selects the Event paywall for a valid campaign in its scheduled window")
    func failsSafeToStandardPaywall() {
        let validPricing = AnnualEventPricing(
            standardPrice: 29.99,
            eventPrice: 14.99,
            standardDisplayPrice: "€29.99",
            eventDisplayPrice: "€14.99",
            discount: Decimal(string: "0.5002")!,
            discountPercent: 50
        )

        #expect(SubscriptionPaywallExperienceResolver.shouldUseEvent(
            eventIsActive: true,
            monetizationConfigured: true,
            userIsNotConfirmedFree: false,
            eventOfferingAvailable: true,
            expectedProductsAvailable: true,
            validatedPricing: validPricing
        ))
        #expect(!SubscriptionPaywallExperienceResolver.shouldUseEvent(
            eventIsActive: false,
            monetizationConfigured: true,
            userIsNotConfirmedFree: false,
            eventOfferingAvailable: true,
            expectedProductsAvailable: true,
            validatedPricing: validPricing
        ))
        #expect(!SubscriptionPaywallExperienceResolver.shouldUseEvent(
            eventIsActive: true,
            monetizationConfigured: true,
            userIsNotConfirmedFree: true,
            eventOfferingAvailable: true,
            expectedProductsAvailable: true,
            validatedPricing: validPricing
        ))
        #expect(!SubscriptionPaywallExperienceResolver.shouldUseEvent(
            eventIsActive: true,
            monetizationConfigured: true,
            userIsNotConfirmedFree: false,
            eventOfferingAvailable: true,
            expectedProductsAvailable: true,
            validatedPricing: nil
        ))
    }

    @Test("Halloween campaign follows its scheduled device-local window")
    func halloweenCampaignWindow() {
        let zone = TimeZone(identifier: "Europe/Madrid")!
        let calendar = Calendar(identifier: .gregorian)
        let before = calendar.date(from: DateComponents(timeZone: zone, year: 2026, month: 9, day: 30, hour: 23, minute: 59))!
        let active = calendar.date(from: DateComponents(timeZone: zone, year: 2026, month: 10, day: 15, hour: 12))!
        let after = calendar.date(from: DateComponents(timeZone: zone, year: 2026, month: 11, day: 1, hour: 0))!

        #expect(SeasonalThemeResolver.activeScheduledTheme(
            at: SeasonalThemeClock(now: before, timeZone: zone)
        ) == nil)
        #expect(SeasonalThemeResolver.activeScheduledTheme(
            at: SeasonalThemeClock(now: active, timeZone: zone)
        ) == .halloween2026)
        #expect(SeasonalThemeResolver.activeScheduledTheme(
            at: SeasonalThemeClock(now: after, timeZone: zone)
        ) == nil)
    }

    @Test("Uses the active event's configured discount target")
    func usesCampaignDiscountTarget() {
        let standard = snapshot(id: AnnualEventPriceValidator.standardProductID, price: 29.99)
        let event = snapshot(id: AnnualEventPriceValidator.eventProductID, price: 17.99)

        #expect(AnnualEventPriceValidator.validate(
            standard: standard,
            event: event,
            targetDiscountPercent: 40
        ) != nil)
        #expect(AnnualEventPriceValidator.validate(
            standard: standard,
            event: event,
            targetDiscountPercent: 50
        ) == nil)
    }
}

@Suite("Temporal commercial access policy")
struct AccessPolicyTests {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    private func date(days: Int, from date: Date? = nil) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: date ?? start)!
    }

    @Test("Fresh installations must see the notice before the 15-day clock starts")
    func freshInstallRequiresNotice() {
        #expect(AccessMigrationClassifier.cohort(
            preMigrationInstallEvidence: false,
            wasOnboarded: false,
            savedDocumentCount: 0,
            previouslyProcessedDocumentCount: 0
        ) == .newUser)
        #expect(AccessMigrationClassifier.cohort(
            preMigrationInstallEvidence: true,
            wasOnboarded: false,
            savedDocumentCount: 0,
            previouslyProcessedDocumentCount: 0
        ) == .existingFreeUser)
        #expect(AccessMigrationClassifier.cohort(
            preMigrationInstallEvidence: false,
            wasOnboarded: false,
            savedDocumentCount: 1,
            previouslyProcessedDocumentCount: 0
        ) == .existingFreeUser)
        #expect(AccessPolicy.resolve(
            record: nil,
            missingRecordCohort: .newUser,
            now: start,
            hasPaidAccess: false
        ) == .newUserNotice)
        let accepted = AccessRecord.start(cohort: .newUser, at: start)
        #expect(accepted?.fullAccessStartedAt == start)
        #expect(accepted?.noticeAcceptedAt == start)
        #expect(accepted?.noticeVersion == AccessConfiguration.noticeVersion)
        #expect(accepted?.fullAccessExpiresAt == date(days: 15))
    }

    @Test("Existing Free installs receive 30 full days followed by 30 read-only days")
    func existingFreeMigrationWindow() {
        let record = AccessRecord.start(cohort: .existingFreeUser, at: start)!
        #expect(record.fullAccessExpiresAt == date(days: 30))
        #expect(record.recoveryExpiresAt == date(days: 60))
        #expect(AccessPolicy.resolve(
            record: record,
            missingRecordCohort: .existingFreeUser,
            now: date(days: 29),
            hasPaidAccess: false
        ).hasFullAccess)
        #expect(AccessPolicy.resolve(
            record: record,
            missingRecordCohort: .existingFreeUser,
            now: date(days: 30),
            hasPaidAccess: false
        ) == .readOnlyRecovery(until: date(days: 60)))
        #expect(AccessPolicy.resolve(
            record: record,
            missingRecordCohort: .existingFreeUser,
            now: date(days: 59),
            hasPaidAccess: false
        ) == .readOnlyRecovery(until: date(days: 60)))
        #expect(AccessPolicy.resolve(
            record: record,
            missingRecordCohort: .existingFreeUser,
            now: date(days: 60),
            hasPaidAccess: false
        ) == .mandatoryPaywall)
    }

    @Test("New-user access expires after 15 days and never starts a subscription")
    func newUserExpiry() {
        let record = AccessRecord.start(cohort: .newUser, at: start)!
        #expect(AccessPolicy.resolve(
            record: record,
            missingRecordCohort: .newUser,
            now: date(days: 14),
            hasPaidAccess: false
        ).hasFullAccess)
        #expect(AccessPolicy.resolve(
            record: record,
            missingRecordCohort: .newUser,
            now: date(days: 15),
            hasPaidAccess: false
        ) == .mandatoryPaywall)
        #expect(record.recoveryExpiresAt == nil)
    }

    @Test("Paid purchases take precedence over expired access and storage errors")
    func paidEntitlementsTakePrecedence() {
        #expect(AccessPolicy.resolve(
            record: nil,
            missingRecordCohort: .existingFreeUser,
            now: start,
            hasPaidAccess: true,
            storageAvailable: false
        ) == .purchased)
        let previouslyPaid = AccessRecord.paidAccessObserved(cohort: .existingFreeUser, at: start)
        #expect(AccessPolicy.resolve(
            record: previouslyPaid,
            missingRecordCohort: .existingFreeUser,
            now: date(days: 1),
            hasPaidAccess: false
        ) == .mandatoryPaywall)
    }

    @Test("Recovery and mandatory-paywall modes keep personal data actions but block product writes")
    func readOnlyCapabilityMatrix() {
        let record = AccessRecord.start(cohort: .existingFreeUser, at: start)!
        let recovery = AccessPolicy.resolve(
            record: record,
            missingRecordCohort: .existingFreeUser,
            now: date(days: 30),
            hasPaidAccess: false
        )
        #expect(recovery.allows(.viewOwnData))
        #expect(recovery.allows(.exportOwnData))
        #expect(recovery.allows(.deleteOwnData))
        #expect(recovery.allows(.restorePurchases))
        #expect(recovery.allows(.legalInformation))
        #expect(!recovery.allows(.createContent))
        #expect(!recovery.allows(.modifyContent))
        #expect(!recovery.allows(.importContent))
        #expect(!recovery.allows(.cloudWrite))
    }

    @Test("Clock rollback cannot move the policy before its last stored trusted time")
    func clockRollbackClampsToLastTrustedValue() {
        var record = AccessRecord.start(cohort: .newUser, at: start)!
        record.lastTrustedAt = date(days: 8)
        #expect(record.trustedNow(date(days: 2)) == date(days: 8))
        #expect(AccessPolicy.resolve(
            record: record,
            missingRecordCohort: .newUser,
            now: date(days: 2),
            hasPaidAccess: false
        ) == .temporaryFullAccess(expiresAt: date(days: 15), cohort: .newUser))
    }

    @Test("Unaccepted notice cannot expose full access even if a malformed record has dates")
    func acceptanceIsRequiredForFullAccess() {
        var record = AccessRecord.start(cohort: .existingFreeUser, at: start)!
        record.noticeAcceptedAt = nil
        #expect(AccessPolicy.resolve(
            record: record,
            missingRecordCohort: .existingFreeUser,
            now: start,
            hasPaidAccess: false
        ) == .existingUserNotice)
    }

    @Test("Access periods use the central configuration defaults and can be changed centrally")
    func configurableAccessPeriods() {
        let defaults = AccessConfiguration.current
        #expect(defaults.newUserFullAccessDays == 15)
        #expect(defaults.existingUserFullAccessDays == 30)
        #expect(defaults.existingUserRecoveryDays == 30)

        let futurePolicy = AccessConfiguration(
            newUserFullAccessDays: 14,
            existingUserFullAccessDays: 45,
            existingUserRecoveryDays: 20
        )
        let newRecord = AccessRecord.start(
            cohort: .newUser,
            at: start,
            configuration: futurePolicy
        )
        let existingRecord = AccessRecord.start(
            cohort: .existingFreeUser,
            at: start,
            configuration: futurePolicy
        )
        #expect(newRecord?.fullAccessExpiresAt == date(days: 14))
        #expect(existingRecord?.fullAccessExpiresAt == date(days: 45))
        #expect(existingRecord?.recoveryExpiresAt == date(days: 65))
    }

    @Test("Calendar-day periods remain at local noon across the Madrid daylight-saving boundary")
    func calendarDaysAcrossDaylightSaving() {
        var madrid = Calendar(identifier: .gregorian)
        madrid.timeZone = TimeZone(identifier: "Europe/Madrid")!
        let localStart = madrid.date(from: DateComponents(
            year: 2026,
            month: 3,
            day: 28,
            hour: 12
        ))!
        let record = AccessRecord.start(
            cohort: .newUser,
            at: localStart,
            calendar: madrid
        )!
        let expectedLocalExpiry = madrid.date(from: DateComponents(
            year: 2026,
            month: 4,
            day: 12,
            hour: 12
        ))!
        #expect(record.fullAccessExpiresAt == expectedLocalExpiry)
        #expect(record.fullAccessExpiresAt!.timeIntervalSince(localStart) == 15 * 24 * 60 * 60 - 60 * 60)
    }

    @Test("Editor boundary save lease is one-shot and limited to the active persisted document")
    func accessBoundarySaveLeaseEligibility() {
        let full = AppAccessState.temporaryFullAccess(expiresAt: date(days: 15), cohort: .newUser)
        let readonly = AppAccessState.mandatoryPaywall
        #expect(AccessBoundarySavePolicy.canIssueLease(
            for: "doc-1",
            activeEditorDocumentID: "doc-1",
            documentIsPersisted: true,
            previousState: full,
            nextState: readonly,
            leaseAlreadyIssued: false
        ))
        #expect(!AccessBoundarySavePolicy.canIssueLease(
            for: "doc-1",
            activeEditorDocumentID: "doc-2",
            documentIsPersisted: true,
            previousState: full,
            nextState: readonly,
            leaseAlreadyIssued: false
        ))
        #expect(!AccessBoundarySavePolicy.canIssueLease(
            for: "unsaved-doc",
            activeEditorDocumentID: "unsaved-doc",
            documentIsPersisted: false,
            previousState: full,
            nextState: readonly,
            leaseAlreadyIssued: false
        ))
        #expect(!AccessBoundarySavePolicy.canIssueLease(
            for: "doc-1",
            activeEditorDocumentID: "doc-1",
            documentIsPersisted: true,
            previousState: full,
            nextState: .purchased,
            leaseAlreadyIssued: false
        ))
        #expect(!AccessBoundarySavePolicy.canIssueLease(
            for: "doc-1",
            activeEditorDocumentID: "doc-1",
            documentIsPersisted: true,
            previousState: full,
            nextState: readonly,
            leaseAlreadyIssued: true
        ))
    }
}
