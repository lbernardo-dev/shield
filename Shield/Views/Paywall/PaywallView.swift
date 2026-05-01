import SwiftUI
import StoreKit

// MARK: - PaywallView

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openURL) private var openURL
    @StateObject private var pm = PremiumManager.shared
    @Binding var isPresented: Bool
    var trigger: PaywallTrigger = .manual
    @State private var selectedProduct: ShieldProduct = .annual
    @State private var didStartCheckout = false
    private let privacyURL = URL(string: "https://shieldapp.io/privacy")
    private let termsURL = URL(string: "https://shieldapp.io/terms")

    private func features() -> [(icon: String, color: String, title: String, subtitle: String)] {
        return [
            ("doc.stack.fill",       "64D2FF",
             appState.str("paywall_feature_unlimited_docs", table: "Paywall"),
             appState.str("paywall_feature_unlimited_desc", table: "Paywall")),
            ("eye.slash.fill",       "FFD60A",
             appState.str("paywall_feature_all_styles", table: "Paywall"),
             appState.str("paywall_feature_styles_desc", table: "Paywall")),
            ("lock.rectangle.stack", "30D158",
             appState.str("paywall_feature_vault", table: "Paywall"),
             appState.str("paywall_feature_vault_desc", table: "Paywall")),
            ("doc.fill",             "FF9F0A",
             appState.str("paywall_feature_pdf_title", table: "Paywall"),
             appState.str("paywall_feature_pdf_desc", table: "Paywall")),
            ("drop.halffull",        "5E5CE6",
             appState.str("paywall_feature_watermark", table: "Paywall"),
             appState.str("paywall_feature_watermark_desc", table: "Paywall")),
            ("slider.horizontal.3",  "FF453A",
             appState.str("paywall_feature_adjust_title", table: "Paywall"),
             appState.str("paywall_feature_adjust_desc", table: "Paywall")),
            ("wand.and.stars",       "BF5AF2",
             appState.str("paywall_feature_auto_title", table: "Paywall"),
             appState.str("paywall_feature_auto_desc", table: "Paywall")),
            ("icloud",               "30D158",
             appState.str("paywall_feature_icloud", table: "Paywall"),
             appState.str("paywall_feature_icloud_desc", table: "Paywall")),
        ]
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0D0D10"), Color(hex: "0A0A0B")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close
                HStack {
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ShieldTheme.textTertiary)
                            .frame(width: 30, height: 30)
                            .background(ShieldTheme.surface3)
                            .clipShape(Circle())
                    }
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

                        // CTA
                        ctaSection

                        // Footer
                        footerLinks
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            AppState.trackEvent("paywall_viewed", properties: ["trigger": trigger.rawValue])
            await pm.loadProducts()
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
            ZStack {
                Circle()
                    .fill(ShieldTheme.accentDim)
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(ShieldTheme.accent)
            }
            Text("Shield Pro")
                .font(.system(size: 30, weight: .heavy))
                .foregroundColor(ShieldTheme.textPrimary)
                .tracking(-0.6)
            Text(appState.str("paywall_hero_subtitle", table: "Paywall"))
                .font(.system(size: 15))
                .foregroundColor(ShieldTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var contextBanner: some View {
        return HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(ShieldTheme.accent)
            Text(appState.str(trigger.localizationKey, table: "Paywall"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ShieldTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(ShieldTheme.accentDim)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ShieldTheme.accent.opacity(0.35), lineWidth: 0.8))
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
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: f.color))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ShieldTheme.textPrimary)
                        Text(f.subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(ShieldTheme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShieldTheme.success)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(ShieldTheme.surface2)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ShieldTheme.surfaceLine, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Plan selector

    private var planSelector: some View {
        VStack(spacing: 10) {
            if pm.products.isEmpty {
                // Loading skeleton
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ShieldTheme.surface2)
                        .frame(height: 72)
                        .opacity(0.5)
                }
            } else {
                ForEach(pm.products, id: \.id) { product in
                    PlanRow(
                        product: product,
                        isSelected: selectedProduct.rawValue == product.id,
                        savingsLabel: savingsLabel(for: product),
                        lang: appState.language,
                        onTap: {
                            if let sp = ShieldProduct(rawValue: product.id) {
                                withAnimation { selectedProduct = sp }
                            }
                        }
                    )
                }
            }
        }
    }

    private func savingsLabel(for product: Product) -> String? {
        guard product.id == ShieldProduct.annual.rawValue,
              let monthly = pm.products.first(where: { $0.id == ShieldProduct.monthly.rawValue })
        else { return nil }
        return pm.annualSavings(monthly: monthly, annual: product, lang: appState.language)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    guard let product = pm.products.first(where: { $0.id == selectedProduct.rawValue })
                    else { return }
                    didStartCheckout = true
                    await pm.purchase(product)
                    if pm.isPro { isPresented = false }
                }
            } label: {
                HStack(spacing: 8) {
                    if pm.isPurchasing {
                        ProgressView().tint(ShieldTheme.accentText)
                    } else {
                        Image(systemName: "crown.fill")
                        Text(appState.str("paywall_get_pro", table: "Paywall"))
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(ShieldTheme.accent)
                .foregroundColor(ShieldTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(pm.isPurchasing)

            if let err = pm.purchaseError {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(ShieldTheme.danger)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Footer

    private var footerLinks: some View {
        HStack(spacing: 20) {
            Button {
                Task {
                    await pm.restore()
                    if pm.isPro { isPresented = false }
                }
            } label: {
                Group {
                    if pm.isRestoring {
                        ProgressView().tint(ShieldTheme.textTertiary).scaleEffect(0.7)
                    } else {
                        Text(appState.str("paywall_restore", table: "Paywall"))
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(ShieldTheme.textTertiary)
            }

            Text("·").foregroundColor(ShieldTheme.textQuaternary)

            Button {
                if let privacyURL { openURL(privacyURL) }
            } label: {
                Text(appState.str("paywall_privacy", table: "Paywall"))
                    .font(.system(size: 12))
                    .foregroundColor(ShieldTheme.textTertiary)
            }

            Text("·").foregroundColor(ShieldTheme.textQuaternary)

            Button {
                if let termsURL { openURL(termsURL) }
            } label: {
                Text(appState.str("paywall_terms", table: "Paywall"))
                    .font(.system(size: 12))
                    .foregroundColor(ShieldTheme.textTertiary)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - PlanRow

private struct PlanRow: View {
    @EnvironmentObject var appState: AppState
    let product: Product
    let isSelected: Bool
    let savingsLabel: String?
    let lang: AppLanguage
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Radio
                ZStack {
                    Circle()
                        .stroke(isSelected ? ShieldTheme.accent : ShieldTheme.surfaceLine, lineWidth: isSelected ? 2 : 1)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(ShieldTheme.accent)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(planName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(ShieldTheme.textPrimary)
                        // Trial badge for annual plan
                        if ShieldProduct(rawValue: product.id) == .annual {
                            Text(appState.str("paywall_trial_days", args: 7, table: "Paywall"))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Color(hex: "30D158"))
                                .clipShape(Capsule())
                        }
                        if let s = savingsLabel {
                            Text(s)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(ShieldTheme.accentText)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(ShieldTheme.accent)
                                .clipShape(Capsule())
                        }
                    }
                    Text(planSubtitle)
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(product.displayPrice)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ShieldTheme.textPrimary)
                    Text(periodLabel)
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.textTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? ShieldTheme.accentDim : ShieldTheme.surface2)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? ShieldTheme.accent : ShieldTheme.surfaceLine,
                            lineWidth: isSelected ? 1.5 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var planName: String {
        switch ShieldProduct(rawValue: product.id) {
        case .monthly:  return appState.str("paywall_plan_monthly", table: "Paywall")
        case .annual:   return appState.str("paywall_plan_annual", table: "Paywall")
        case .lifetime: return appState.str("paywall_plan_lifetime", table: "Paywall")
        case nil:       return product.displayName
        }
    }

    private var planSubtitle: String {
        switch ShieldProduct(rawValue: product.id) {
        case .monthly:  return appState.str("paywall_billed_monthly", table: "Paywall")
        case .annual:   return appState.str("paywall_billed_annually", table: "Paywall")
        case .lifetime: return appState.str("paywall_one_time", table: "Paywall")
        case nil:       return ""
        }
    }

    private var periodLabel: String {
        switch ShieldProduct(rawValue: product.id) {
        case .monthly:  return appState.str("paywall_per_mo_short", table: "Paywall")
        case .annual:   return appState.str("paywall_per_yr_short", table: "Paywall")
        case .lifetime: return appState.str("paywall_once_short", table: "Paywall")
        case nil:       return ""
        }
    }
}
