import Foundation
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

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
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
        return true
    }
}

/// A custom button style that applies tactile spring physics and opacity changes without color tinting.
public struct CoffeeButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.72 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// A centered, accessible coffee support button for a small one-time contribution.
/// The configured amount is prefilled in PayPal.Me; PayPal still controls the
/// final confirmation screen and may allow the donor to edit the amount.
public struct SupportCoffeeButton: View {
    @Environment(\.colorScheme) private var colorScheme

    private let manager: DonationManager
    private let title: String
    private let accessibilityLabel: String
    private let accessibilityHint: String

    public init(
        manager: DonationManager,
        title: String,
        detail: String? = nil,
        accessibilityLabel: String,
        accessibilityHint: String
    ) {
        self.manager = manager
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }

    public init(
        manager: DonationManager,
        title: String,
        accessibilityLabel: String,
        accessibilityHint: String
    ) {
        self.init(
            manager: manager,
            title: title,
            detail: nil,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint
        )
    }

    /// Adaptive coffee tone ensuring high contrast:
    /// - Dark Mode: Warm amber / caramel (#FBB84D, ratio > 12:1 against dark backgrounds)
    /// - Light Mode: Roasted espresso (#94521F, ratio > 5.5:1 against light backgrounds)
    private var coffeeThemeColor: Color {
        colorScheme == .dark
            ? Color(red: 0.98, green: 0.72, blue: 0.30)
            : Color(red: 0.58, green: 0.32, blue: 0.12)
    }

    public var body: some View {
        Button {
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            manager.openDonationPage()
        } label: {
            VStack(spacing: 7) {
                Image(systemName: "cup.and.saucer.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(coffeeThemeColor)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(CoffeeButtonStyle())
        .disabled(manager.donationURL == nil)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityHint(Text(accessibilityHint))
    }
}

public typealias SupportCoffeePrompt = SupportCoffeeButton
