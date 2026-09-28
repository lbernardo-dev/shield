import Foundation
import SwiftUI

/// Per-app configuration for the reusable engagement surfaces.
///
public struct AppEngagementConfig {
    public let appName: String
    public let appSlug: String
    public let feedbackReasons: [LocalizedStringKey]
    public let inactivityThresholdDays: Int
    public let minDaysBetweenFeedbackPrompts: Int
    public init(
        appName: String,
        appSlug: String,
        feedbackReasons: [LocalizedStringKey],
        inactivityThresholdDays: Int = 21,
        minDaysBetweenFeedbackPrompts: Int = 30
    ) {
        self.appName = appName
        self.appSlug = appSlug
        self.feedbackReasons = feedbackReasons
        self.inactivityThresholdDays = max(1, inactivityThresholdDays)
        self.minDaysBetweenFeedbackPrompts = max(0, minDaysBetweenFeedbackPrompts)
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
