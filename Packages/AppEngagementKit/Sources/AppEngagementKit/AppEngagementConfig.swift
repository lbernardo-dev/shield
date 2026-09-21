import Foundation
import SwiftUI

/// Per-app configuration for the reusable engagement surfaces.
///
/// The PayPal.Me URL is public by design; it identifies the receiving page but
/// contains no client secret. The fixed amount is appended only when opening
/// the payment page and is not displayed as an account identifier in the UI.
public struct AppEngagementConfig {
    public let appName: String
    public let appSlug: String
    public let feedbackReasons: [LocalizedStringKey]
    public let inactivityThresholdDays: Int
    public let minDaysBetweenFeedbackPrompts: Int
    public let paypalBusinessId: String
    public let paypalMeURL: URL?
    public let paypalFixedAmount: Decimal
    public let paypalCurrencyCode: String

    public init(
        appName: String,
        appSlug: String,
        feedbackReasons: [LocalizedStringKey],
        inactivityThresholdDays: Int = 21,
        minDaysBetweenFeedbackPrompts: Int = 30,
        paypalBusinessId: String = "",
        paypalMeURL: URL? = nil,
        paypalFixedAmount: Decimal = 2.99,
        paypalCurrencyCode: String = "EUR"
    ) {
        self.appName = appName
        self.appSlug = appSlug
        self.feedbackReasons = feedbackReasons
        self.inactivityThresholdDays = max(1, inactivityThresholdDays)
        self.minDaysBetweenFeedbackPrompts = max(0, minDaysBetweenFeedbackPrompts)
        self.paypalBusinessId = paypalBusinessId
        self.paypalMeURL = paypalMeURL
        self.paypalFixedAmount = max(0, paypalFixedAmount)
        self.paypalCurrencyCode = paypalCurrencyCode.uppercased()
    }

    public var sanitizedAppSlug: String {
        let folded = appSlug
            .folding(
                options: [.diacriticInsensitive, .caseInsensitive],
                locale: Locale(identifier: "en_US_POSIX")
            )
            .lowercased()
        let scalars = folded.unicodeScalars
        let allowed = scalars.filter { scalar in
            (scalar.value >= 97 && scalar.value <= 122) || (scalar.value >= 48 && scalar.value <= 57)
        }
        return String(String.UnicodeScalarView(allowed))
    }

    public var feedbackRecipient: String {
        "romerodev.app+\(sanitizedAppSlug)@gmail.com"
    }

    /// Builds a one-time PayPal.Me request such as `/2.99EUR`.
    ///
    /// PayPal.Me pre-fills the amount; it does not technically prevent a donor
    /// from editing that amount before confirming the payment. A PayPal
    /// Business Payment Link is required when the amount must be immutable.
    public var paypalDonationURL: URL? {
        if let paypalMeURL {
            let amount = NSDecimalNumber(decimal: paypalFixedAmount).stringValue
            let amountComponent = "\(amount)\(paypalCurrencyCode)"
            return paypalMeURL.appendingPathComponent(amountComponent)
        }

        guard !paypalBusinessId.isEmpty else { return nil }
        var components = URLComponents(string: "https://www.paypal.com/donate")
        components?.queryItems = [
            URLQueryItem(name: "business", value: paypalBusinessId),
            URLQueryItem(name: "no_recurring", value: "0"),
            URLQueryItem(name: "currency_code", value: paypalCurrencyCode),
            URLQueryItem(name: "item_name", value: appName)
        ]
        return components?.url
    }
}

public struct AppInstallMetadata: Equatable, Sendable {
    public let installDate: Date
    public let lastUpdateDate: Date?
    public let appVersion: String

    public init(installDate: Date, lastUpdateDate: Date?, appVersion: String) {
        self.installDate = installDate
        self.lastUpdateDate = lastUpdateDate
        self.appVersion = appVersion
    }
}

/// Persists the first launch and the last app-version transition with the
/// app's existing UserDefaults domain.
public final class AppInstallMetadataStore {
    private let defaults: UserDefaults
    private let keyPrefix: String

    public init(defaults: UserDefaults = .standard, keyPrefix: String = "app.engagement") {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    @discardableResult
    public func recordLaunch(appVersion: String, now: Date = Date()) -> AppInstallMetadata {
        let installKey = "\(keyPrefix).installDate"
        let lastUpdateKey = "\(keyPrefix).lastUpdateDate"
        let versionKey = "\(keyPrefix).lastKnownVersion"

        let installDate: Date
        if let saved = defaults.object(forKey: installKey) as? Date {
            installDate = saved
        } else {
            installDate = now
            defaults.set(now, forKey: installKey)
        }

        let previousVersion = defaults.string(forKey: versionKey)
        var lastUpdateDate = defaults.object(forKey: lastUpdateKey) as? Date
        if let previousVersion, previousVersion != appVersion {
            lastUpdateDate = now
            defaults.set(now, forKey: lastUpdateKey)
        }
        defaults.set(appVersion, forKey: versionKey)

        return AppInstallMetadata(
            installDate: installDate,
            lastUpdateDate: lastUpdateDate,
            appVersion: appVersion
        )
    }
}
