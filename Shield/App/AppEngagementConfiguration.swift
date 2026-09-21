import AppEngagementKit
import SwiftUI

/// MaskID's single engagement configuration. Other apps can provide their
/// own value without changing the reusable AppEngagementKit managers.
extension AppEngagementConfig {
    static let maskID = AppEngagementConfig(
        appName: "MaskID",
        appSlug: "maskid",
        feedbackReasons: [
            LocalizedStringKey("review_feedback_category_missing_feature"),
            LocalizedStringKey("review_feedback_category_too_complicated"),
            LocalizedStringKey("review_feedback_category_did_not_work"),
            LocalizedStringKey("review_feedback_category_too_expensive"),
            LocalizedStringKey("review_feedback_category_not_using_enough"),
            LocalizedStringKey("review_feedback_category_privacy"),
            LocalizedStringKey("review_feedback_category_other")
        ],
        // MaskID previously used a 30-day return threshold; preserve that
        // established product policy while the package default remains 21.
        inactivityThresholdDays: 30,
        minDaysBetweenFeedbackPrompts: 30,
        paypalMeURL: URL(string: "https://paypal.me/paytolbernardo"),
        paypalFixedAmount: 2.99,
        paypalCurrencyCode: "EUR"
    )
}

enum AppEngagementRuntime {
    static let installMetadataStore = AppInstallMetadataStore(
        defaults: .standard,
        keyPrefix: "shield.engagement"
    )

    static var metadata: AppInstallMetadata {
        installMetadataStore.recordLaunch(appVersion: appVersion)
    }

    private static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
    }
}
