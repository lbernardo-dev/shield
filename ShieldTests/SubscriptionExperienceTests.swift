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

    @Test("Trial disclosure states the trial duration, next charge, billing period, and renewal")
    @MainActor
    func trialDisclosureMakesTheNextChargeClear() {
        let english = SubscriptionTrialDisclosureCopy.text(
            trialLabel: "7-day free trial",
            displayPrice: "$24.99",
            renewalPeriodLabel: "/year",
            language: .en
        )
        #expect(english.contains("7-day free trial"))
        #expect(english.contains("$24.99/year"))
        #expect(english.contains("automatically renews until canceled"))

        let spanish = SubscriptionTrialDisclosureCopy.text(
            trialLabel: "7 días de prueba gratis",
            displayPrice: "24,99 €",
            renewalPeriodLabel: "/año",
            language: .es
        )
        #expect(spanish.contains("7 días de prueba gratis"))
        #expect(spanish.contains("24,99 €/año"))
        #expect(spanish.contains("se renueva automáticamente"))
    }

    @Test("Recurring plans without a trial disclose the next charge and renewal")
    @MainActor
    func renewalDisclosureMakesTheNextChargeClearWithoutTrial() {
        let english = SubscriptionTrialDisclosureCopy.text(
            trialLabel: nil,
            displayPrice: "$12.99",
            renewalPeriodLabel: "/year",
            language: .en
        )
        #expect(english.contains("$12.99/year"))
        #expect(english.contains("automatically renews until canceled"))
        #expect(!english.localizedCaseInsensitiveContains("trial"))

        let spanish = SubscriptionTrialDisclosureCopy.text(
            trialLabel: nil,
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
