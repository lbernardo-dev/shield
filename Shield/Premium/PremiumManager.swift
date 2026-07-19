import SwiftUI
import OSLog
import RevenueCat

// MARK: - Product IDs  (match exactly what you register in App Store Connect)

enum ShieldProduct: String, CaseIterable {
    case monthly   = "com.romerodev.shield.pro.monthly"
    case annual    = "com.romerodev.shield.pro.annual"
    case lifetime  = "com.romerodev.shield.pro.lifetime.unlock"

    var analyticsName: String {
        switch self {
        case .monthly: "monthly"
        case .annual: "annual"
        case .lifetime: "lifetime"
        }
    }

    func label(lang: AppLanguage) -> String {
        let key: String
        switch self {
        case .monthly:  key = "paywall_plan_monthly"
        case .annual:   key = "paywall_plan_annual"
        case .lifetime: key = "paywall_plan_lifetime"
        }
        return LanguageManager.shared.str(key, table: "Paywall")
    }
}

struct PremiumProduct: Identifiable {
    let storeProduct: StoreProduct

    var id: String { storeProduct.productIdentifier }
    var displayName: String { storeProduct.localizedTitle }
    var displayPrice: String { storeProduct.localizedPriceString }
    var price: Decimal { storeProduct.price }
}
// MARK: - PaywallTrigger (why are we showing the paywall)
enum PaywallTrigger: String, CaseIterable {
    case manual
    case docLimitReached
    case exportLimitReached
    case styleLocked
    case vaultUpgrade
    case settingsUpgrade

    var localizationKey: String {
        switch self {
        case .manual:           return "paywall_trigger_manual"
        case .docLimitReached:  return "paywall_trigger_doc_limit"
        case .exportLimitReached: return "paywall_trigger_export_limit"
        case .styleLocked:      return "paywall_trigger_style_locked"
        case .vaultUpgrade:     return "paywall_trigger_vault"
        case .settingsUpgrade:  return "paywall_trigger_generic"
        }
    }
}

// MARK: - PremiumManager

@MainActor
final class PremiumManager: NSObject, ObservableObject, PurchasesDelegate {

    static let shared = PremiumManager()

    private static let entitlementFallback = "MaskID Pro"
    private let logger = Logger(subsystem: "com.romerodev.shield", category: "RevenueCat")

    @Published private(set) var isPro: Bool = false
    @Published private(set) var products: [PremiumProduct] = []
    /// Product ID → localized free-trial badge. Only populated for products with
    /// a free-trial introductory offer the user is still eligible for.
    @Published private(set) var trialLabels: [String: String] = [:]
    @Published private(set) var purchaseError: String? = nil
    @Published var isPurchasing: Bool = false
    @Published var isRestoring: Bool = false

    #if DEBUG
    @Published private(set) var isDebugProOverride: Bool = false
    #endif

    static func configureRevenueCat() {
        guard !Purchases.isConfigured else { return }
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
              !apiKey.isEmpty else { return }
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: apiKey)
    }

    private var entitlementIdentifier: String {
        Bundle.main.object(forInfoDictionaryKey: "RevenueCatEntitlementIdentifier") as? String
            ?? Self.entitlementFallback
    }

    private override init() {
        Self.configureRevenueCat()
        super.init()
        // Restore from cache immediately
        isPro = UserDefaults.standard.bool(forKey: "shield.isPro")
        #if DEBUG
        let override = UserDefaults.standard.bool(forKey: "shield.devProOverride")
        isDebugProOverride = override
        if override { isPro = true }
        #endif
        Purchases.shared.delegate = self
        Task {
            await updateProStatus()
            await loadProducts()
        }
    }

    // MARK: - Load products

    func loadProducts() async {
        let ids = ShieldProduct.allCases.map(\.rawValue)
        let fetched = await Purchases.shared.products(ids).map(PremiumProduct.init(storeProduct:))
        // The product surface is intentionally limited to three clear choices.
        products = fetched.sorted { lhs, rhs in
            let order: [String: Int] = [
                ShieldProduct.monthly.rawValue: 0,
                ShieldProduct.annual.rawValue: 1,
                ShieldProduct.lifetime.rawValue: 2,
            ]
            return (order[lhs.id] ?? 99) < (order[rhs.id] ?? 99)
        }
        await refreshTrialEligibility()
    }

    private func refreshTrialEligibility() async {
        var labels: [String: String] = [:]
        for product in products {
            guard let offer = product.storeProduct.introductoryDiscount,
                  offer.paymentMode == .freeTrial,
                  await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product.storeProduct) == .eligible
            else { continue }
            labels[product.id] = Self.trialBadgeLabel(for: offer.subscriptionPeriod)
        }
        trialLabels = labels
    }

    private static func trialBadgeLabel(for period: SubscriptionPeriod) -> String {
        switch period.unit {
        case .day:
            return LanguageManager.shared.paywall("paywall_trial_days", period.value)
        case .week:
            return LanguageManager.shared.paywall("paywall_trial_days", period.value * 7)
        case .month:
            return LanguageManager.shared.paywall("paywall_trial_months", period.value)
        case .year:
            return LanguageManager.shared.paywall("paywall_trial_months", period.value * 12)
        @unknown default:
            return LanguageManager.shared.paywall("paywall_trial_days", period.value)
        }
    }

    // MARK: - Purchase

    func purchase(_ product: PremiumProduct) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        AppState.trackEvent("purchase_started", properties: ["product_id": product.id])

        do {
            let result = try await Purchases.shared.purchase(product: product.storeProduct)
            if result.userCancelled {
                AppState.trackEvent("purchase_cancelled", properties: ["product_id": product.id])
            } else {
                apply(result.customerInfo)
                AppState.trackEvent("purchase_success", properties: ["product_id": product.id])
            }
        } catch {
            purchaseError = error.localizedDescription
            AppState.trackEvent("purchase_failed", properties: [
                "product_id": product.id,
                "error": error.localizedDescription
            ])
        }
    }

    // MARK: - Restore

    func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            apply(customerInfo)
            AppState.trackEvent("restore_success")
        } catch {
            purchaseError = error.localizedDescription
            AppState.trackEvent("restore_failed", properties: ["error": error.localizedDescription])
        }
    }

    // MARK: - Update pro status

    func updateProStatus() async {
        #if DEBUG
        if isDebugProOverride { return }
        #endif
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            logger.error("Customer info refresh failed: \(String(describing: error), privacy: .private)")
        }
    }

    private func apply(_ customerInfo: CustomerInfo) {
        #if DEBUG
        if isDebugProOverride { return }
        #endif
        let hasPro = customerInfo.entitlements[entitlementIdentifier]?.isActive == true
        isPro = hasPro
        UserDefaults.standard.set(hasPro, forKey: "shield.isPro")
    }

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor [weak self] in self?.apply(customerInfo) }
    }

    #if DEBUG
    func setDebugProOverride(_ enabled: Bool) {
        isDebugProOverride = enabled
        UserDefaults.standard.set(enabled, forKey: "shield.devProOverride")
        isPro = enabled
        UserDefaults.standard.set(enabled, forKey: "shield.isPro")
    }
    #endif

    // MARK: - Limits

    /// Max documents in free tier
    static let freeDocumentLimit = 10
    static let freeWeeklyExportLimit = 0 // Secure export is never paywalled.
    private static let exportHistoryKey = "shield.free.exportHistoryTimestamps"

    func canAddDocument(currentCount: Int) -> Bool {
        isPro || currentCount < PremiumManager.freeDocumentLimit
    }

    func canUseStyle(_ style: MaskStyle) -> Bool {
        isPro || !style.isPremium
    }

    func canExportNow() -> Bool {
        true
    }

    func freeExportsUsedThisWeek() -> Int {
        let now = Date().timeIntervalSince1970
        let weekAgo = now - (7 * 24 * 60 * 60)
        let history = UserDefaults.standard.array(forKey: PremiumManager.exportHistoryKey) as? [Double] ?? []
        let pruned = history.filter { $0 >= weekAgo }
        if pruned.count != history.count {
            UserDefaults.standard.set(pruned, forKey: PremiumManager.exportHistoryKey)
        }
        return pruned.count
    }

    func remainingFreeExportsThisWeek() -> Int {
        .max
    }

    func recordExport() {
        // Intentionally empty: verified exports are a core safety capability.
    }

    // MARK: - Helpers for display

    func annualSavings(monthly: PremiumProduct, annual: PremiumProduct, lang: AppLanguage = .en) -> String? {
        guard let pct = savingsPercent(referencePrice: monthly.price * 12, offerPrice: annual.price)
        else { return nil }
        return LanguageManager.shared.str("paywall_save_percent", table: "Paywall", args: pct)
    }

    func lifetimeSavings(annual: PremiumProduct, lifetime: PremiumProduct, lang: AppLanguage = .en) -> String? {
        guard let pct = savingsPercent(referencePrice: annual.price * 2, offerPrice: lifetime.price)
        else { return nil }
        return LanguageManager.shared.str("paywall_save_two_years_percent", table: "Paywall", args: pct)
    }

    func savingsPercent(referencePrice: Decimal, offerPrice: Decimal) -> Int? {
        guard referencePrice > 0, offerPrice < referencePrice else { return nil }
        let ratio = NSDecimalNumber(decimal: (referencePrice - offerPrice) / referencePrice).doubleValue
        let percentage = Int((ratio * 100).rounded())
        return percentage > 0 ? percentage : nil
    }
}
