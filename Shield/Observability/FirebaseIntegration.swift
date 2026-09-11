import Foundation
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics

enum FirebaseIntegration {
    static let analyticsConsentKey = "shield.analyticsConsent"
    static let analyticsConsentPromptAnsweredKey = "shield.analyticsConsentPromptAnswered"

    static var analyticsConsent: Bool {
        UserDefaults.standard.bool(forKey: analyticsConsentKey)
    }

    static func configure() {
        if FirebaseApp.app() != nil {
            applyAnalyticsConsent()
            return
        }

        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return
        }

        FirebaseApp.configure()
        applyAnalyticsConsent()
        configureCrashlytics()
    }

    /// Persists an explicit product-analytics decision and immediately applies
    /// it to Firebase. The default is false, including after an app update.
    static func setAnalyticsConsent(_ granted: Bool) {
        UserDefaults.standard.set(granted, forKey: analyticsConsentKey)
        applyAnalyticsConsent()
    }

    private static func applyAnalyticsConsent() {
        guard FirebaseApp.app() != nil else { return }
        Analytics.setAnalyticsCollectionEnabled(analyticsConsent)
    }

    private static func configureCrashlytics() {
        let crashlytics = Crashlytics.crashlytics()
        crashlytics.setCrashlyticsCollectionEnabled(true)

        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            crashlytics.setCustomValue(bundleIdentifier, forKey: "bundle_identifier")
        }

        if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            crashlytics.setCustomValue(appVersion, forKey: "app_version")
        }

        if let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            crashlytics.setCustomValue(buildNumber, forKey: "build_number")
        }
    }

    static func logEvent(_ name: String, parameters: [String: String]) {
        guard analyticsConsent, FirebaseApp.app() != nil else { return }
        Analytics.logEvent(name, parameters: parameters.mapValues { $0 as Any })
    }
}
