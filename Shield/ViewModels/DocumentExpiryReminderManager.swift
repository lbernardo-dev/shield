import Foundation
import SwiftUI
import UserNotifications

// MARK: - DocumentExpiryStatus

enum DocumentExpiryStatus: Equatable, Sendable {
    case notSet
    case valid(daysRemaining: Int)
    case expiringSoon(daysRemaining: Int)
    case expired(daysOverdue: Int)

    var isExpiringOrExpired: Bool {
        switch self {
        case .expiringSoon, .expired: return true
        case .notSet, .valid: return false
        }
    }
}

// MARK: - DocumentExpiryReminderManager

@MainActor
final class DocumentExpiryReminderManager: ObservableObject {
    static let shared = DocumentExpiryReminderManager()

    private let notificationCenter = UNUserNotificationCenter.current()
    nonisolated static let identifierPrefix = "shield.expiry."

    private static let supportedDateFormats = [
        "dd/MM/yyyy", "dd-MM-yyyy", "dd.MM.yyyy", "dd MM yyyy",
        "yyyy-MM-dd", "yyyy/MM/dd", "yyyy.MM.dd",
        "dd/MM/yy", "dd-MM-yy", "dd.MM.yy",
        "MM/yyyy", "MM-yyyy"
    ]

    private init() {}

    // MARK: - Date Parsing

    static func parseExpiryDate(from string: String) -> Date? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current

        for format in supportedDateFormats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }

    func expiryDate(for doc: DocumentItem) -> Date? {
        Self.parseExpiryDate(from: doc.fields.expires)
    }

    func status(for doc: DocumentItem) -> DocumentExpiryStatus {
        guard let date = expiryDate(for: doc) else { return .notSet }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTarget = calendar.startOfDay(for: date)

        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget)
        let days = components.day ?? 0

        if days < 0 {
            return .expired(daysOverdue: abs(days))
        } else if days <= 30 {
            return .expiringSoon(daysRemaining: days)
        } else {
            return .valid(daysRemaining: days)
        }
    }

    // MARK: - Notifications Scheduling

    func requestAuthorizationIfNeeded() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            do {
                return try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .denied, .ephemeral:
            return false
        @unknown default:
            return false
        }
    }

    func scheduleReminders(for doc: DocumentItem, lang: AppLanguage = .es) {
        guard let expiryDate = expiryDate(for: doc) else {
            cancelReminders(for: doc.id)
            return
        }

        let now = Date()
        guard expiryDate > now else {
            cancelReminders(for: doc.id)
            return
        }

        let docId = doc.id
        let docTitle = doc.title

        Task {
            let granted = await requestAuthorizationIfNeeded()
            guard granted else { return }

            // Clear previous notifications for this document
            cancelReminders(for: docId)

            let calendar = Calendar.current
            let reminders = [30, 7] // days before expiration

            for daysBefore in reminders {
                guard let triggerDate = calendar.date(byAdding: .day, value: -daysBefore, to: expiryDate),
                      triggerDate > now else {
                    continue
                }

                let content = UNMutableNotificationContent()
                content.title = lang == .es
                    ? "Alerta de caducidad: \(docTitle)"
                    : "Expiration alert: \(docTitle)"
                content.body = lang == .es
                    ? "Tu documento caduca en \(daysBefore) días (\(Self.formattedDate(expiryDate, lang: lang))). Recuerda renovarlo a tiempo."
                    : "Your document expires in \(daysBefore) days (\(Self.formattedDate(expiryDate, lang: lang))). Remember to renew it."
                content.sound = .default

                let triggerComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                let identifier = "\(Self.identifierPrefix)\(docId).\(daysBefore)d"

                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                try? await notificationCenter.add(request)
            }
        }
    }

    func cancelReminders(for docID: String) {
        Task {
            let requests = await notificationCenter.pendingNotificationRequests()
            let prefix = "\(Self.identifierPrefix)\(docID)"
            let toRemove = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) }
            if !toRemove.isEmpty {
                notificationCenter.removePendingNotificationRequests(withIdentifiers: toRemove)
            }
        }
    }

    func syncAllVaultReminders(documents: [DocumentItem], lang: AppLanguage = .es) {
        for doc in documents where doc.isVaulted {
            scheduleReminders(for: doc, lang: lang)
        }
    }

    // MARK: - Helpers

    static func formattedDate(_ date: Date, lang: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: lang.rawValue)
        return formatter.string(from: date)
    }
}
