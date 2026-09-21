import Foundation

/// The data contract used by the mail-based feedback transport.
///
/// Privacy contract: this payload contains only the selected reason, the
/// optional comment, app/device diagnostics, locale, and install/update/send
/// timestamps. It does not contain document contents, account credentials,
/// payment data, or tracking identifiers.
public struct FeedbackPayload: Codable, Sendable {
    public let reason: String
    public let comment: String?
    public let trigger: String
    public let appName: String
    public let appVersion: String
    public let buildNumber: String
    public let osVersion: String
    public let deviceModel: String
    public let locale: String
    public let installDate: Date?
    public let lastUpdateDate: Date?
    public let submittedAt: Date

    public init(
        reason: String,
        comment: String?,
        trigger: String,
        appName: String,
        appVersion: String,
        buildNumber: String,
        osVersion: String,
        deviceModel: String,
        locale: String,
        installDate: Date?,
        lastUpdateDate: Date?,
        submittedAt: Date = Date()
    ) {
        self.reason = reason
        self.comment = comment
        self.trigger = trigger
        self.appName = appName
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.osVersion = osVersion
        self.deviceModel = deviceModel
        self.locale = locale
        self.installDate = installDate
        self.lastUpdateDate = lastUpdateDate
        self.submittedAt = submittedAt
    }

    public var mailBody: String {
        let formatter = ISO8601DateFormatter()
        let installDateText = installDate.map(formatter.string(from:)) ?? "unknown"
        let lastUpdateDateText = lastUpdateDate.map(formatter.string(from:)) ?? "unknown"
        var lines = [
            "\(appName) feedback",
            "Reason: \(reason)",
            "Trigger: \(trigger)",
            "App version: \(appVersion)",
            "Build: \(buildNumber)",
            "OS: \(osVersion)",
            "Device: \(deviceModel)",
            "Locale: \(locale)",
            "Install date: \(installDateText)",
            "Last update date: \(lastUpdateDateText)",
            "Submitted at: \(formatter.string(from: submittedAt))",
            ""
        ]
        if let comment, !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("Comment:")
            lines.append(comment.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return lines.joined(separator: "\n")
    }
}

/// Shared feedback policy for apps that use the standard prompt flow.
/// Product-specific UI and mail presentation remain in the host app.
@MainActor
public final class FeedbackManager {
    public let configuration: AppEngagementConfig

    private let defaults: UserDefaults
    private let now: () -> Date
    private let promptDateKey: String

    public init(
        configuration: AppEngagementConfig,
        defaults: UserDefaults = .standard,
        keyPrefix: String = "app.engagement.feedback",
        now: @escaping () -> Date = Date.init
    ) {
        self.configuration = configuration
        self.defaults = defaults
        self.now = now
        self.promptDateKey = "(keyPrefix).lastAutomaticPromptDate"
    }

    public var recipient: String {
        configuration.feedbackRecipient
    }

    public var lastAutomaticPromptDate: Date? {
        defaults.object(forKey: promptDateKey) as? Date
    }

    public func canShowAutomaticPrompt(at date: Date? = nil) -> Bool {
        guard let lastAutomaticPromptDate else { return true }
        let cooldown = TimeInterval(configuration.minDaysBetweenFeedbackPrompts) * 24 * 60 * 60
        return (date ?? now()).timeIntervalSince(lastAutomaticPromptDate) >= cooldown
    }

    public func recordAutomaticPromptShown(at date: Date? = nil) {
        defaults.set(date ?? now(), forKey: promptDateKey)
    }

    public func makePayload(
        reason: String,
        comment: String?,
        trigger: String,
        appVersion: String,
        buildNumber: String,
        osVersion: String,
        deviceModel: String,
        locale: String,
        metadata: AppInstallMetadata,
        submittedAt: Date? = nil
    ) -> FeedbackPayload {
        FeedbackPayload(
            reason: reason,
            comment: comment,
            trigger: trigger,
            appName: configuration.appName,
            appVersion: appVersion,
            buildNumber: buildNumber,
            osVersion: osVersion,
            deviceModel: deviceModel,
            locale: locale,
            installDate: metadata.installDate,
            lastUpdateDate: metadata.lastUpdateDate,
            submittedAt: submittedAt ?? now()
        )
    }
}
