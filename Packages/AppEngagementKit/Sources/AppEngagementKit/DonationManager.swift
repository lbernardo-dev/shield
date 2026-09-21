import Foundation
import SwiftUI
import UIKit

@MainActor
public final class DonationManager {
    public let configuration: AppEngagementConfig

    public init(configuration: AppEngagementConfig) {
        self.configuration = configuration
    }

    @discardableResult
    public func openDonationPage() -> Bool {
        guard let url = configuration.paypalDonationURL else { return false }
        UIApplication.shared.open(url)
        return true
    }
}

/// Icon-only PayPal.Me action. The accessible label is the only visible
/// semantic text supplied by this component; the account identifier is never
/// rendered in the app.
public struct SupportCoffeeButton: View {
    private let manager: DonationManager
    private let accessibilityLabel: String
    private let accessibilityHint: String

    public init(
        manager: DonationManager,
        accessibilityLabel: String,
        accessibilityHint: String = "Opens PayPal"
    ) {
        self.manager = manager
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }

    public var body: some View {
        Button {
            _ = manager.openDonationPage()
        } label: {
            Image(systemName: "p.circle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color(red: 0.0, green: 0.32, blue: 0.72))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
    }
}
