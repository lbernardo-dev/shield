import SwiftUI
import AppEngagementKit
import StoreKit

private struct SettingsAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL
    @Environment(\.closeSettings) private var closeSettings
    @StateObject private var premium = PremiumManager.shared

    @State private var showPaywall = false
    @State private var showOfferCodeRedemption = false
    @State private var activeAlert: SettingsAlert?
    @State private var navigationPath = NavigationPath()

    private var strings: LanguageManager { .shared }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                SeasonalThemeBackdrop()

                VStack(spacing: 0) {
                    title
                        .frame(maxWidth: 760)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, ShieldTheme.s4)
                        .padding(.bottom, ShieldTheme.s3)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: ShieldTheme.s5) {
                        SettingsSummaryCard(
                            documentCount: appState.documents.count,
                            vaultedCount: appState.documents.filter(\.isVaulted).count,
                            isPro: premium.isPro,
                            onUnlockPro: { showPaywall = true },
                            onManageSubscription: openManageSubscription
                        )

                        SettingsCardSection(
                            title: strings.settings("settings_subscription_tools"),
                            icon: "creditcard.fill"
                        ) {
                            SettingsActionRow(
                                icon: "arrow.clockwise.circle.fill",
                                color: Color(hex: "30D158"),
                                title: premium.isRestoring
                                    ? strings.settings("settings_subscription_restoring")
                                    : strings.settings("settings_subscription_restore_action"),
                                subtitle: strings.settings("settings_subscription_restore_action_subtitle"),
                                accessibilityIdentifier: "settings.subscription.restore",
                                action: restorePurchases
                            )
                            SettingsRowDivider()
                            SettingsActionRow(
                                icon: "ticket.fill",
                                color: Color(hex: "8E44AD"),
                                title: strings.settings("settings_subscription_redeem_offer"),
                                subtitle: strings.settings("settings_subscription_redeem_offer_subtitle"),
                                accessibilityIdentifier: "settings.subscription.redeemOffer",
                                action: { showOfferCodeRedemption = true }
                            )
                        }

                        SettingsCardSection(
                            title: strings.settings("settings_section_personalization"),
                            icon: "slider.horizontal.3"
                        ) {
                            SettingsNavigationRow(
                                route: .themes,
                                icon: "wand.and.stars",
                                color: Color(hex: "F97316"),
                                title: strings.settings("settings_themes_title"),
                                subtitle: strings.settings("settings_themes_subtitle")
                            )
                            SettingsRowDivider()
                            SettingsNavigationRow(
                                route: .appPreferences,
                                icon: "paintbrush.fill",
                                color: Color(hex: "D9AA00"),
                                title: strings.settings("settings_app_preferences"),
                                subtitle: strings.settings("settings_app_preferences_subtitle")
                            )
                        }

                        SettingsCardSection(
                            title: strings.settings("settings_section_workspace"),
                            icon: "lock.shield.fill"
                        ) {
                            SettingsNavigationRow(
                                route: .ocrSettings,
                                icon: "text.viewfinder",
                                color: Color(hex: "00B4D8"),
                                title: strings.settings("settings_ocr_engine_title"),
                                subtitle: strings.settings("settings_ocr_engine_subtitle")
                            )
                            SettingsRowDivider()
                            SettingsNavigationRow(
                                route: .security,
                                icon: "lock.fill",
                                color: Color(hex: "30D158"),
                                title: strings.settings("settings_security_privacy"),
                                subtitle: strings.settings("settings_security_privacy_subtitle")
                            )
                            SettingsRowDivider()
                            SettingsNavigationRow(
                                route: .cloud,
                                icon: "icloud.fill",
                                color: Color(hex: "5E5CE6"),
                                title: strings.settings("settings_icloud_sync"),
                                subtitle: strings.settings("settings_icloud_subtitle")
                            )
                            SettingsRowDivider()
                            SettingsNavigationRow(
                                route: .export,
                                icon: "square.and.arrow.up.fill",
                                color: Color(hex: "0A84FF"),
                                title: strings.settings("settings_export_preferences"),
                                subtitle: strings.settings("settings_export_preferences_subtitle")
                            )
                        }

                        SettingsCardSection(
                            title: strings.settings("settings_feedback_section"),
                            icon: "bubble.left.and.bubble.right.fill"
                        ) {
                            SettingsActionRow(
                                icon: "envelope.fill",
                                color: Color(hex: "30D158"),
                                title: strings.settings("settings_send_feedback"),
                                subtitle: strings.settings("settings_send_feedback_subtitle"),
                                accessibilityIdentifier: "settings.action.sendFeedback",
                                action: sendFeedback
                            )
                            SettingsRowDivider()
                            SettingsActionRow(
                                icon: "star.fill",
                                color: Color(hex: "FFD60A"),
                                title: strings.settings("settings_rate_app"),
                                subtitle: strings.settings("settings_rate_app_subtitle"),
                                accessibilityIdentifier: "settings.action.rateApp",
                                action: requestRating
                            )
                        }

                        SettingsCardSection(
                            title: strings.settings("settings_about"),
                            icon: "info.circle.fill"
                        ) {
                            aboutRows
                        }

                        #if DEBUG && targetEnvironment(simulator)
                        SettingsCardSection(
                            title: strings.settings("settings_developer"),
                            icon: "hammer.fill"
                        ) {
                            SettingsNavigationRow(
                                route: .developer,
                                icon: "hammer.fill",
                                color: Color(hex: "8E8E93"),
                                title: strings.settings("settings_developer_tools"),
                                subtitle: strings.settings("settings_developer_tools_subtitle")
                            )
                        }
                        #endif

                        SettingsFooter()
                            .padding(.top, ShieldTheme.s2)
                        }
                        .frame(maxWidth: 760)
                        .padding(.horizontal, ShieldTheme.s4)
                        .padding(.bottom, ShieldTheme.s6)
                    }
                }
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsRoute.self) { route in
                destination(for: route)
            }
            .onAppear(perform: consumeThemeDeepLink)
            .onChange(of: appState.pendingThemeDeepLink) { _, _ in
                consumeThemeDeepLink()
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: .settingsUpgrade)
                .environmentObject(appState)
        }
        .offerCodeRedemption(isPresented: $showOfferCodeRedemption) { result in
            switch result {
            case .success:
                AppState.trackEvent("offer_code_redeem_finished", properties: ["result": "completed"])
                Task { await premium.reconcileAfterOfferCodeRedemption() }
            case .failure(let error):
                AppState.trackEvent("offer_code_redeem_finished", properties: [
                    "result": "failed",
                    "error_type": String((error as NSError).code)
                ])
            }
        }
        .alert(item: $activeAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text(strings.common("common_ok")))
            )
        }
        .onChange(of: premium.purchaseError) { _, error in
            guard let error else { return }
            activeAlert = SettingsAlert(
                title: strings.settings("settings_subscription_tools"),
                message: error
            )
        }
    }

    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
    }

    private var title: some View {
        HStack(alignment: .firstTextBaseline, spacing: ShieldTheme.s3) {
            VStack(alignment: .leading, spacing: 3) {
                Text(strings.settings("settings_eyebrow"))
                    .font(.caption.weight(.bold))
                    .tracking(0.7)
                    .foregroundStyle(ShieldTheme.accent(scheme))
                    .textCase(.uppercase)
                HStack(spacing: 6) {
                    Text(strings.settings("settings_title"))
                        .shieldFont(32, weight: .heavy, design: .rounded)
                        .foregroundStyle(ShieldTheme.primary(scheme))
                    if isHalloween {
                        Text("🎃")
                            .font(.system(size: 24))
                    }
                }
            }
            Spacer(minLength: ShieldTheme.s2)
            SettingsCloseButton(action: closeSettings)
        }
        .padding(.top, ShieldTheme.topChromePadding)
    }

    private func openManageSubscription() {
        Task { await SubscriptionLifecycleObserver.shared.showManageSubscriptions() }
    }

    private func restorePurchases() {
        Task {
            await premium.restore()
            if premium.purchaseError == nil {
                activeAlert = SettingsAlert(
                    title: strings.settings("settings_subscription_tools"),
                    message: strings.settings(
                        premium.isPro
                            ? "settings_subscription_restore_success"
                            : "settings_subscription_restore_empty"
                    )
                )
            }
        }
    }

    @ViewBuilder
    private var aboutRows: some View {
        SettingsNavigationRow(
            route: .information,
            icon: "info.circle.fill",
            color: Color(hex: "D9AA00"),
            title: strings.settings("settings_information_disclaimer"),
            subtitle: strings.settings("settings_information_disclaimer_subtitle")
        )
        SettingsRowDivider()
        SettingsNavigationRow(
            route: .whatsNew,
            icon: "sparkles",
            color: Color(hex: "00C7BE"),
            title: strings.settings("settings_whats_new"),
            subtitle: strings.settings("settings_whats_new_subtitle")
        )
        SettingsRowDivider()
        SettingsNavigationRow(
            route: .privacy,
            icon: "hand.raised.fill",
            color: Color(hex: "5E5CE6"),
            title: strings.settings("settings_privacy_policy"),
            subtitle: strings.settings("settings_privacy_policy_subtitle")
        )
        SettingsRowDivider()
        SettingsNavigationRow(
            route: .terms,
            icon: "doc.text.fill",
            color: Color(hex: "8E8E93"),
            title: strings.settings("settings_terms_service"),
            subtitle: strings.settings("settings_terms_service_subtitle")
        )
        SettingsRowDivider()
        SettingsNavigationRow(
            route: .subscriptionTerms,
            icon: "doc.badge.gearshape.fill",
            color: Color(hex: "8E8E93"),
            title: strings.settings("settings_subscription_terms"),
            subtitle: strings.settings("settings_subscription_terms_subtitle")
        )
        SettingsRowDivider()
        SettingsNavigationRow(
            route: .support,
            icon: "questionmark.bubble.fill",
            color: Color(hex: "0A84FF"),
            title: strings.settings("settings_support"),
            subtitle: strings.settings("settings_support_subtitle")
        )
        SettingsRowDivider()
        SettingsNavigationRow(
            route: .faq,
            icon: "questionmark.circle.fill",
            color: Color(hex: "FF9F0A"),
            title: strings.settings("settings_faq"),
            subtitle: strings.settings("settings_faq_subtitle")
        )
        SettingsRowDivider()
    }

    @ViewBuilder
    private func destination(for route: SettingsRoute) -> some View {
        switch route {
        case .ocrSettings:
            OCREngineSettingsView()
        case .appPreferences:
            AppPreferencesSettingsView()
                .environmentObject(appState)
        case .themes:
            SeasonalThemeGalleryView()
                .environmentObject(appState)
        case .security:
            SecuritySettingsView()
                .environmentObject(appState)
        case .cloud:
            CloudSettingsView()
                .environmentObject(appState)
        case .export:
            ExportSettingsView()
        case .information:
            SettingsArticleView(article: .information)
        case .whatsNew:
            WhatsNewSettingsView()
        case .privacy:
            SettingsArticleView(article: .privacy)
        case .terms:
            SettingsArticleView(article: .terms)
        case .subscriptionTerms:
            SettingsArticleView(article: .subscriptionTerms)
        case .support:
            SupportSettingsView(onSendFeedback: sendFeedback, onRate: requestRating)
        case .faq:
            FAQSettingsView()
        #if DEBUG && targetEnvironment(simulator)
        case .developer:
            DeveloperSettingsView()
        #endif
        }
    }

    private func sendFeedback() {
        ReviewFeedbackCoordinator.shared.presentManualFeedback()
    }

    private func requestRating() {
        openURL(AppReviewManager.shared.writeReviewURL) { accepted in
            if !accepted {
                activeAlert = SettingsAlert(
                    title: strings.settings("settings_rating_unavailable_title"),
                    message: strings.settings("settings_rating_unavailable_message")
                )
            }
        }
    }

    private func consumeThemeDeepLink() {
        guard appState.pendingThemeDeepLink != nil else { return }
        navigationPath.append(SettingsRoute.themes)
    }
}

// MARK: - Routing and configuration

enum SettingsRoute: Hashable {
    case ocrSettings
    case appPreferences
    case themes
    case security
    case cloud
    case export
    case information
    case whatsNew
    case privacy
    case terms
    case subscriptionTerms
    case support
    case faq
    #if DEBUG && targetEnvironment(simulator)
    case developer
    #endif

    var accessibilityIdentifier: String {
        switch self {
        case .ocrSettings: "settings.route.ocrSettings"
        case .appPreferences: "settings.route.appPreferences"
        case .themes: "settings.route.themes"
        case .security: "settings.route.security"
        case .cloud: "settings.route.cloud"
        case .export: "settings.route.export"
        case .information: "settings.route.information"
        case .whatsNew: "settings.route.whatsNew"
        case .privacy: "settings.route.privacy"
        case .terms: "settings.route.terms"
        case .subscriptionTerms: "settings.route.subscriptionTerms"
        case .support: "settings.route.support"
        case .faq: "settings.route.faq"
        #if DEBUG && targetEnvironment(simulator)
        case .developer: "settings.route.developer"
        #endif
        }
    }

}

enum SettingsSupportConfiguration {
    static let email: String? = AppEngagementConfig.maskID.feedbackRecipient

    static func feedbackURL(recipient: String, subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(SeasonalThemeCoordinator.shared)
}
