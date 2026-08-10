import SwiftUI

// MARK: - PaywallView

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var pm = PremiumManager.shared
    @Binding var isPresented: Bool
    var trigger: PaywallTrigger = .manual
    @State private var selectedProductID = ShieldProduct.annual.rawValue
    @State private var didStartCheckout = false

    private func features() -> [(icon: String, color: String, title: String, subtitle: String)] {
        return [
            ("doc.on.doc.fill",       "64D2FF",
             LanguageManager.shared.paywall("paywall_feature_unlimited_docs"),
             LanguageManager.shared.paywall("paywall_feature_unlimited_desc")),
            ("eye.slash.fill",       "FFD60A",
             LanguageManager.shared.paywall("paywall_feature_all_styles"),
             LanguageManager.shared.paywall("paywall_feature_styles_desc")),
            ("lock.rectangle.stack.fill", "30D158",
             LanguageManager.shared.paywall("paywall_feature_vault"),
             LanguageManager.shared.paywall("paywall_feature_vault_desc")),
            ("icloud",               "30D158",
             LanguageManager.shared.paywall("paywall_feature_icloud"),
             LanguageManager.shared.paywall("paywall_feature_icloud_desc")),
        ]
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: ShieldTheme.premiumBackground(appState.preferredScheme),
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close
                HStack {
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .shieldFont(14, weight: .semibold)
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                            .frame(width: 44, height: 44)
                            .contentShape(Circle())
                            .background(ShieldTheme.rowBackground(scheme))
                            .clipShape(Circle())
                    }
                    .accessibilityIdentifier("paywall.close")
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Hero
                        heroSection

                        // Context banner
                        contextBanner

                        // Features grid
                        featuresGrid

                        // Plan selector
                        planSelector
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, ShieldTheme.s5)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ShieldStickyFooter {
                ctaSection
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(appState.preferredScheme)
        .sensoryFeedback(.selection, trigger: selectedProductID)
        .sensoryFeedback(.success, trigger: pm.isPro) { _, isPro in isPro }
        .task {
            AppState.trackEvent("paywall_viewed", properties: ["trigger": trigger.rawValue])
            await pm.loadProducts()
            selectAvailableProductIfNeeded()
        }
        .onChange(of: pm.products.map(\.id)) { _, _ in
            selectAvailableProductIfNeeded()
        }
        .onDisappear {
            if !pm.isPro {
                AppState.trackEvent("paywall_dismissed", properties: [
                    "trigger": trigger.rawValue,
                    "started_checkout": didStartCheckout ? "true" : "false"
                ])
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            heroMark
            Text(LanguageManager.shared.paywall("paywall_title"))
                .shieldFont(30, weight: .heavy)
                .foregroundColor(ShieldTheme.primary(scheme))
            Text(LanguageManager.shared.paywall("paywall_hero_subtitle"))
                .shieldFont(15)
                .foregroundColor(ShieldTheme.secondary(scheme))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var heroMark: some View {
        MaskIDIdentityMark(
            size: 104,
            presentation: .animatedLoop,
            treatment: .hero
        )
    }

    private var contextBanner: some View {
        return HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .shieldFont(14)
                .foregroundColor(ShieldTheme.accent(scheme))
            Text(LanguageManager.shared.paywall(trigger.localizationKey))
                .shieldFont(12, weight: .semibold)
                .foregroundColor(ShieldTheme.secondary(scheme))
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(ShieldTheme.accentDim(scheme))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ShieldTheme.accentStroke(scheme), lineWidth: 0.8))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Features

    private var featuresGrid: some View {
        VStack(spacing: 10) {
            ForEach(Array(features().enumerated()), id: \.offset) { _, f in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: f.color).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: f.icon)
                            .shieldFont(18, weight: .semibold)
                            .foregroundColor(Color(hex: f.color))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.title)
                            .shieldFont(14, weight: .semibold)
                            .foregroundColor(ShieldTheme.primary(scheme))
                        Text(f.subtitle)
                            .shieldFont(12)
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                    }
                    Spacer()
                    Image(systemName: "checkmark")
                        .shieldFont(12, weight: .bold)
                        .foregroundColor(ShieldTheme.success)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(ShieldTheme.cardBackground(scheme))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ShieldTheme.line(scheme), lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Plan selector

    private var planSelector: some View {
        Group {
            if pm.isLoadingProducts {
                VStack(spacing: 12) {
                    // Loading skeleton
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ShieldTheme.cardBackground(scheme))
                            .frame(height: 84)
                            .redacted(reason: .placeholder)
                    }
                }
            } else if pm.products.isEmpty {
                PaywallProductsUnavailable {
                    Task { await pm.loadProducts() }
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(pm.products, id: \.id) { product in
                        planRowView(for: product)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func planRowView(for product: PremiumProduct) -> some View {
        PlanRow(
            product: product,
            isSelected: selectedProductID == product.id,
            savingsLabel: savingsLabel(for: product),
            trialLabel: pm.trialLabels[product.id],
            lang: appState.language,
            onTap: {
                withAnimation(reduceMotion ? nil : ShieldMotion.state) { selectedProductID = product.id }
            }
        )
    }

    private func savingsLabel(for product: PremiumProduct) -> String? {
        switch ShieldProduct(rawValue: product.id) {
        case .annual:
            guard let monthly = pm.products.first(where: { $0.id == ShieldProduct.monthly.rawValue })
            else { return nil }
            return pm.annualSavings(monthly: monthly, annual: product, lang: appState.language)
        case .lifetime:
            guard let annual = pm.products.first(where: { $0.id == ShieldProduct.annual.rawValue })
            else { return nil }
            return pm.lifetimeSavings(annual: annual, lifetime: product, lang: appState.language)
        default:
            return nil
        }
    }

    // MARK: - CTA

    private func purchaseSelectedProduct() {
        Task {
            guard let product = selectedPremiumProduct
            else { return }
            didStartCheckout = true
            await pm.purchase(product)
            if pm.isPro { isPresented = false }
        }
    }

    private var selectedPremiumProduct: PremiumProduct? {
        pm.products.first { $0.id == selectedProductID }
    }

    private func selectAvailableProductIfNeeded() {
        guard selectedPremiumProduct == nil,
              let firstAvailable = pm.products.first else {
            return
        }
        selectedProductID = firstAvailable.id
    }

    @ViewBuilder
    private var ctaLabel: some View {
        HStack(spacing: 8) {
            if pm.isPurchasing {
                ProgressView().tint(ShieldTheme.accentText)
            } else {
                Image(systemName: "sparkles")
                Text(LanguageManager.shared.paywall(
                    pm.trialLabels[selectedProductID] != nil
                        ? "paywall_free_trial"
                        : "paywall_get_pro"
                ))
                .shieldFont(16, weight: .bold)
            }
        }
    }

    private var ctaSection: some View {
        VStack(spacing: ShieldTheme.s2) {
            Button {
                purchaseSelectedProduct()
            } label: {
                ctaLabel
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(canPurchase ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme))
                    .foregroundColor(canPurchase ? ShieldTheme.accentText : ShieldTheme.tertiary(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!canPurchase)
            .accessibilityIdentifier("paywall.purchase")

            if let err = pm.purchaseError {
                Text(err)
                    .shieldFont(12)
                    .foregroundColor(ShieldTheme.danger)
                    .multilineTextAlignment(.center)
            }

            footerLinks
        }
    }

    private var canPurchase: Bool {
        !pm.isPurchasing && selectedPremiumProduct != nil
    }

    // MARK: - Footer

    private var footerLinks: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 2) {
                restoreLink
                footerLinkSeparator
                privacyLink
                footerLinkSeparator
                termsLink
                footerLinkSeparator
                subscriptionTermsLink
            }

            VStack(spacing: 0) {
                HStack(spacing: ShieldTheme.s2) {
                    restoreLink
                    footerLinkSeparator
                    privacyLink
                }
                HStack(spacing: ShieldTheme.s2) {
                    termsLink
                    footerLinkSeparator
                    subscriptionTermsLink
                }
            }

            VStack(spacing: 0) {
                restoreLink
                privacyLink
                termsLink
                subscriptionTermsLink
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(LanguageManager.shared.paywall("paywall_legal_actions"))
    }

    private var restoreLink: some View {
        Button {
            Task {
                await pm.restore()
                if pm.isPro { isPresented = false }
            }
        } label: {
            Group {
                if pm.isRestoring {
                    ProgressView()
                        .tint(ShieldTheme.tertiary(scheme))
                        .controlSize(.mini)
                } else {
                    Text(LanguageManager.shared.paywall("paywall_restore"))
                }
            }
            .shieldFont(10, weight: .semibold)
            .foregroundColor(ShieldTheme.secondary(scheme))
            .padding(.horizontal, 2)
            .frame(minHeight: ShieldTheme.minimumTapTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(pm.isRestoring)
        .accessibilityIdentifier("paywall.restore")
    }

    private var privacyLink: some View {
        publicPageLink(
            title: LanguageManager.shared.paywall("paywall_privacy"),
            page: .privacy,
            identifier: "paywall.privacy"
        )
    }

    private var termsLink: some View {
        publicPageLink(
            title: LanguageManager.shared.paywall("paywall_terms"),
            page: .terms,
            identifier: "paywall.terms"
        )
    }

    private var subscriptionTermsLink: some View {
        publicPageLink(
            title: LanguageManager.shared.settings("settings_subscription_terms"),
            page: .subscriptions,
            identifier: "paywall.subscriptionTerms"
        )
    }

    private var footerLinkSeparator: some View {
        Text("·")
            .shieldFont(10, weight: .bold)
            .foregroundStyle(ShieldTheme.quaternary(scheme))
            .accessibilityHidden(true)
    }

    private func publicPageLink(
        title: String,
        page: ShieldPublicPage,
        identifier: String
    ) -> some View {
        Button {
            openPublicPage(page)
        } label: {
            Text(title)
                .shieldFont(10, weight: .semibold)
                .foregroundColor(ShieldTheme.tertiary(scheme))
                .lineLimit(1)
                .padding(.horizontal, 2)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint(LanguageManager.shared.settings("settings_opens_browser"))
        .accessibilityIdentifier(identifier)
    }

    private func openPublicPage(_ page: ShieldPublicPage) {
        openURL(page.localizedURL(for: appState.language)) { accepted in
            guard !accepted else { return }
            openURL(page.compatibilityURL)
        }
    }
}

// MARK: - PlanRow

struct PaywallProductsUnavailable: View {
    let onRetry: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "wifi.exclamationmark")
                .shieldFont(30, weight: .semibold)
                .foregroundStyle(ShieldTheme.tertiary(scheme))
            Text(LanguageManager.shared.paywall("paywall_products_unavailable"))
                .shieldFont(15, weight: .semibold)
                .foregroundStyle(ShieldTheme.primary(scheme))
                .multilineTextAlignment(.center)
            Text(LanguageManager.shared.paywall("paywall_products_unavailable_tip"))
                .shieldFont(13)
                .foregroundStyle(ShieldTheme.tertiary(scheme))
                .multilineTextAlignment(.center)
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text(LanguageManager.shared.paywall("paywall_retry"))
                }
                .shieldFont(14, weight: .semibold)
                .foregroundStyle(ShieldTheme.accent(scheme))
                .padding(.horizontal, 20)
                .frame(minHeight: ShieldTheme.minimumTapTarget)
                .background(ShieldTheme.accentDim(scheme), in: .rect(cornerRadius: 12))
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityIdentifier("paywall.retry")
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}

struct PlanRow: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var scheme
    let product: PremiumProduct
    let isSelected: Bool
    let savingsLabel: String?
    let trialLabel: String?
    let lang: AppLanguage
    let onTap: () -> Void

    var body: some View {
        let isAnnual = ShieldProduct(rawValue: product.id) == .annual
        let hasBadges = trialLabel != nil || savingsLabel != nil

        Button(action: onTap) {
            HStack(spacing: 16) {
                // Radio Circle
                ZStack {
                    Circle()
                        .stroke(isSelected ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme).opacity(0.4), lineWidth: isSelected ? 2 : 1.5)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(ShieldTheme.accent(scheme))
                            .frame(width: 10, height: 10)
                    }
                }
                .foregroundColor(isSelected ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))

                // Content details
                VStack(alignment: .leading, spacing: 4) {
                    Text(planName)
                        .shieldFont(16, weight: .bold)
                        .foregroundColor(ShieldTheme.primary(scheme))
                    
                    Text(planSubtitle)
                        .shieldFont(12)
                        .foregroundColor(ShieldTheme.tertiary(scheme))

                    if hasBadges {
                        HStack(spacing: 6) {
                            if let trialLabel {
                                Text(trialLabel)
                                    .shieldFont(10, weight: .bold)
                                    .foregroundColor(Color(hex: "30D158"))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: "30D158").opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            if let s = savingsLabel {
                                Text(s)
                                    .shieldFont(10, weight: .bold)
                                    .foregroundColor(ShieldTheme.accent(scheme))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(ShieldTheme.accentDim(scheme))
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer()

                // Pricing
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .shieldFont(18, weight: .bold)
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Text(periodLabel)
                        .shieldFont(11, weight: .medium)
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 96)
            .background(isSelected ? ShieldTheme.selectedBackground(scheme) : ShieldTheme.cardBackground(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? ShieldTheme.accent(scheme) : ShieldTheme.line(scheme),
                            lineWidth: isSelected ? 2 : 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: isSelected ? ShieldTheme.accent(scheme).opacity(0.08) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("paywall.plan.\(product.packageIdentifier)")
        .accessibilityValue(isSelected ? LanguageManager.shared.common("common_selected") : "")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .overlay(alignment: .topTrailing) {
            if isAnnual {
                Text(LanguageManager.shared.paywall("paywall_best_value").uppercased())
                    .shieldFont(9, weight: .bold)
                    .foregroundColor(ShieldTheme.accentText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(ShieldTheme.accent(scheme))
                    .clipShape(Capsule())
                    .offset(y: -8)
                    .padding(.trailing, 16)
            }
        }
    }

    private var planName: String {
        switch ShieldProduct(rawValue: product.id) {
        case .monthly:  return LanguageManager.shared.paywall("paywall_plan_monthly")
        case .annual:   return LanguageManager.shared.paywall("paywall_plan_annual")
        case .lifetime: return LanguageManager.shared.paywall("paywall_plan_lifetime")
        case nil:       return product.displayName
        }
    }

    private var planSubtitle: String {
        switch ShieldProduct(rawValue: product.id) {
        case .monthly:  return LanguageManager.shared.paywall("paywall_billed_monthly")
        case .annual:   return LanguageManager.shared.paywall("paywall_billed_annually")
        case .lifetime: return LanguageManager.shared.paywall("paywall_billed_once")
        case nil:       return ""
        }
    }

    private var periodLabel: String {
        switch ShieldProduct(rawValue: product.id) {
        case .monthly:  return LanguageManager.shared.paywall("paywall_per_mo_short")
        case .annual:   return LanguageManager.shared.paywall("paywall_per_yr_short")
        case .lifetime: return LanguageManager.shared.paywall("paywall_once_short")
        case nil:       return ""
        }
    }
}
