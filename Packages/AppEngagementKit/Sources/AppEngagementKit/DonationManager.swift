import Foundation
import SwiftUI
import UIKit

@MainActor
public final class DonationManager {
    public let configuration: AppEngagementConfig

    public init(configuration: AppEngagementConfig) {
        self.configuration = configuration
    }

    public var donationURL: URL? {
        configuration.paypalDonationURL
    }

    @discardableResult
    public func openDonationPage() -> Bool {
        guard let url = configuration.paypalDonationURL else { return false }
        UIApplication.shared.open(url)
        return true
    }
}

/// A centered, visible PayPal.Me prompt for a small one-time contribution.
/// The configured amount is prefilled in PayPal.Me; PayPal still controls the
/// final confirmation screen and may allow the donor to edit the amount.
public struct SupportCoffeePrompt: View {
    private let manager: DonationManager
    private let title: String
    private let detail: String
    private let accessibilityLabel: String
    private let accessibilityHint: String

    public init(
        manager: DonationManager,
        title: String,
        detail: String,
        accessibilityLabel: String,
        accessibilityHint: String
    ) {
        self.manager = manager
        self.title = title
        self.detail = detail
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }

    public var body: some View {
        Group {
            if let url = manager.donationURL {
                Link(destination: url) {
                    promptContent
                }
                .buttonStyle(.plain)
            } else {
                promptContent
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
    }

    private var promptContent: some View {
        VStack(spacing: 7) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(Color(red: 0.58, green: 0.32, blue: 0.16))
                .accessibilityHidden(true)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.accentColor)
                .underline()

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
    }
}
