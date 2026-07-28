import Foundation
import FirebaseAnalytics
import FirebaseCore
import FirebaseCrashlytics

enum FirebaseIntegration {
    static func configure() {
        guard FirebaseApp.app() == nil else { return }

        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return
        }

        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)
        configureCrashlytics()
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
        guard FirebaseApp.app() != nil else { return }
        Analytics.logEvent(name, parameters: parameters.mapValues { $0 as Any })
    }
}
