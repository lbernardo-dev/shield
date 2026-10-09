import Foundation

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
