import SwiftUI
import MessageUI

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var scheme
    @Environment(\.openURL) private var openURL
    @StateObject private var premium = PremiumManager.shared

    @State private var showPaywall = false
    @State private var showMailCompose = false
    @State private var showSupportUnavailable = false
    @State private var showRatingUnavailable = false

    private var strings: LanguageManager { .shared }

    var body: some View {
        NavigationStack {
            ZStack {
                ShieldTheme.pageBackground(scheme).ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: ShieldTheme.s5) {
                        title
                        SettingsSummaryCard(
                            documentCount: appState.documents.count,
                            vaultedCount: appState.documents.filter(\.isVaulted).count,
                            isPro: premium.isPro
                        )

                        if !premium.isPro {
                            premiumCard
                        }

                        SettingsCardSection(
                            title: strings.settings("settings_section_personalization"),
                            icon: "slider.horizontal.3"
                        ) {
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
                                action: openRatingPage
                            )
                        }

                        SettingsCardSection(
                            title: strings.settings("settings_about"),
                            icon: "info.circle.fill"
                        ) {
                            aboutRows
                        }

                        #if DEBUG
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
                            .padding(.bottom, 110)
                    }
                    .frame(maxWidth: 760)
                    .padding(.horizontal, ShieldTheme.s4)
                }
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
            .navigationDestination(for: SettingsRoute.self) { route in
                destination(for: route)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: .settingsUpgrade)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showMailCompose) {
            if let email = SettingsSupportConfiguration.email {
                MailComposeView(
                    recipient: email,
                    subject: strings.settings("settings_support_subject"),
                    body: strings.settings("settings_support_body")
                )
            }
        }
        .alert(
            strings.settings("settings_support_unavailable_title"),
            isPresented: $showSupportUnavailable
        ) {
            Button(strings.common("common_ok"), role: .cancel) {}
        } message: {
            Text(strings.settings("settings_support_unavailable_message"))
        }
        .alert(
            strings.settings("settings_rating_unavailable_title"),
            isPresented: $showRatingUnavailable
        ) {
            Button(strings.common("common_ok"), role: .cancel) {}
        } message: {
            Text(strings.settings("settings_rating_unavailable_message"))
        }
    }

    private var title: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(strings.settings("settings_eyebrow"))
                    .font(.caption.weight(.bold))
                    .tracking(0.7)
                    .foregroundStyle(ShieldTheme.accent(scheme))
                    .textCase(.uppercase)
                Text(strings.settings("settings_title"))
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .tracking(-0.7)
                    .foregroundStyle(ShieldTheme.primary(scheme))
            }
            Spacer()
        }
        .padding(.top, ShieldTheme.topChromePadding)
    }

    private var premiumCard: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s4) {
            HStack(spacing: ShieldTheme.s3) {
                SettingsIconBadge(icon: "crown.fill", color: Color(hex: "FF9F0A"), size: 48)
                VStack(alignment: .leading, spacing: 3) {
                    Text(strings.settings("settings_unlock_premium"))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(ShieldTheme.primary(scheme))
                    Text(strings.settings("settings_pro_unlock_features"))
                        .font(.subheadline)
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                }
            }

            Button {
                showPaywall = true
            } label: {
                Text(strings.settings("settings_view_options"))
                    .font(.headline.weight(.bold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 50)
                    .foregroundStyle(ShieldTheme.accentText)
                    .background(ShieldTheme.accent(scheme))
                    .clipShape(.rect(cornerRadius: ShieldTheme.rMD))
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(ShieldTheme.s4)
        .shieldSettingsCard()
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
    }

    @ViewBuilder
    private func destination(for route: SettingsRoute) -> some View {
        switch route {
        case .appPreferences:
            AppPreferencesSettingsView()
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
            SupportSettingsView(onSendFeedback: sendFeedback, onRate: openRatingPage)
        case .faq:
            FAQSettingsView()
        #if DEBUG
        case .developer:
            DeveloperSettingsView()
        #endif
        }
    }

    private func sendFeedback() {
        guard SettingsSupportConfiguration.email != nil else {
            showSupportUnavailable = true
            return
        }
        guard MFMailComposeViewController.canSendMail() else {
            openMailURL()
            return
        }
        showMailCompose = true
    }

    private func openMailURL() {
        guard let email = SettingsSupportConfiguration.email else {
            showSupportUnavailable = true
            return
        }
        guard let url = SettingsSupportConfiguration.feedbackURL(
            recipient: email,
            subject: strings.settings("settings_support_subject"),
            body: strings.settings("settings_support_body")
        ) else {
            showSupportUnavailable = true
            return
        }

        openURL(url) { accepted in
            guard !accepted else { return }
            openSupportPageFallback()
        }
    }

    private func openSupportPageFallback() {
        let supportURL = ShieldPublicPage.support.localizedURL(for: appState.language)
        openURL(supportURL) { accepted in
            if !accepted { showSupportUnavailable = true }
        }
    }

    private func openRatingPage() {
        guard let nativeURL = SettingsStoreConfiguration.nativeReviewURL else {
            openRatingWebFallback()
            return
        }
        openURL(nativeURL) { accepted in
            guard !accepted else { return }
            openRatingWebFallback()
        }
    }

    private func openRatingWebFallback() {
        guard let webURL = SettingsStoreConfiguration.webReviewURL else {
            showRatingUnavailable = true
            return
        }
        openURL(webURL) { accepted in
            if !accepted { showRatingUnavailable = true }
        }
    }
}

// MARK: - Routing and configuration

enum SettingsRoute: Hashable {
    case appPreferences
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
    #if DEBUG
    case developer
    #endif

    var accessibilityIdentifier: String {
        switch self {
        case .appPreferences: "settings.route.appPreferences"
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
        #if DEBUG
        case .developer: "settings.route.developer"
        #endif
        }
    }
}

enum SettingsSupportConfiguration {
    static let email: String? = "romerodev.app+shield@gmail.com"

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

enum SettingsStoreConfiguration {
    private static var appID: String? {
        Bundle.main.object(forInfoDictionaryKey: "ShieldAppStoreID") as? String
    }

    static var nativeReviewURL: URL? {
        guard let appID else { return nil }
        return reviewURL(appID: appID, scheme: "itms-apps")
    }

    static var webReviewURL: URL? {
        guard let appID else { return nil }
        return reviewURL(appID: appID, scheme: "https")
    }

    static func reviewURL(appID: String, scheme: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "apps.apple.com"
        components.path = "/app/id\(appID)"
        components.queryItems = [URLQueryItem(name: "action", value: "write-review")]
        return components.url
    }
}

// MARK: - Mail composer

struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.setToRecipients([recipient])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        controller.mailComposeDelegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
