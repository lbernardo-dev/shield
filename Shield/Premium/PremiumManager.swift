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
        return LanguageManager.shared.t(key, table: "Paywall", language: lang)
    }
}

struct PremiumProduct: Identifiable {
    let package: RevenueCat.Package

    var storeProduct: StoreProduct { package.storeProduct }
    var id: String { storeProduct.productIdentifier }
    var packageIdentifier: String { package.identifier }
    var analyticsName: String {
        ShieldProduct(rawValue: id)?.analyticsName ?? packageIdentifier
    }
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
    case featureLocked
    case vaultUpgrade
    case settingsUpgrade

    var localizationKey: String {
        switch self {
        case .manual:           return "paywall_trigger_manual"
        case .docLimitReached:  return "paywall_trigger_doc_limit"
        case .exportLimitReached: return "paywall_trigger_export_limit"
        case .styleLocked:      return "paywall_trigger_style_locked"
        case .featureLocked:    return "paywall_trigger_feature_locked"
        case .vaultUpgrade:     return "paywall_trigger_vault"
        case .settingsUpgrade:  return "paywall_trigger_generic"
        }
    }

    var featureKey: String? {
        switch self {
        case .docLimitReached: "document_limit"
        case .exportLimitReached: "export_limit"
        case .styleLocked: "advanced_styles"
        case .featureLocked: nil
        case .vaultUpgrade: nil
        case .settingsUpgrade: "premium_workflow"
        case .manual: nil
        }
    }
}

enum PremiumFeature: String, CaseIterable {
    case unlimitedDocuments = "unlimited_documents"
    case advancedStyles = "advanced_styles"
    case professionalModes = "professional_modes"
    case batchProcessing = "batch_processing"
    case cloudWorkflow = "cloud_workflow"
    case advancedAdjustments = "advanced_adjustments"
    case alternateIcons = "alternate_icons"
    case customWatermarks = "custom_watermarks"
}

enum SubscriptionEntitlementState: String {
    case free
    case active
    case autoRenewOff = "auto_renew_off"
    case billingIssue = "billing_issue"
    case expired
}

// MARK: - PremiumManager

@MainActor
final class PremiumManager: NSObject, ObservableObject, PurchasesDelegate {

    static let shared = PremiumManager()

    private static let entitlementFallback = "MaskID Pro"
    private let logger = Logger(subsystem: "com.romerodev.shield", category: "RevenueCat")

    @Published private(set) var isPro: Bool = false
    @Published private(set) var products: [PremiumProduct] = []
    @Published private(set) var isLoadingProducts: Bool = false
    @Published private(set) var productsLoadFailed: Bool = false
    /// Product ID → localized free-trial badge. Only populated for products with
    /// a free-trial introductory offer the user is still eligible for.
    @Published private(set) var trialLabels: [String: String] = [:]
    @Published private(set) var purchaseError: String? = nil
    @Published var isPurchasing: Bool = false
    @Published var isRestoring: Bool = false
    @Published private(set) var entitlementTier: EntitlementTier = .free
    @Published private(set) var subscriptionState: SubscriptionEntitlementState = .free
    @Published private(set) var activeProductIdentifier: String?

    @Published private(set) var freeDocumentsProcessedCount: Int = 0
    static let processedDocumentsKey = "shield.free.processedDocumentsCount"
    static let analyticsTierKey = "shield.analytics.entitlementTier"
    static let analyticsSubscriptionStateKey = "shield.analytics.subscriptionState"

    #if DEBUG && targetEnvironment(simulator)
    @Published private(set) var isDebugProOverride: Bool = false
    #endif

    static func configureRevenueCat() {
        guard !Purchases.isConfigured else { return }
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
              !apiKey.isEmpty else { return }
        #if DEBUG && targetEnvironment(simulator)
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
        freeDocumentsProcessedCount = UserDefaults.standard.integer(forKey: Self.processedDocumentsKey)
        entitlementTier = EntitlementTier(
            rawValue: UserDefaults.standard.string(forKey: Self.analyticsTierKey) ?? "free"
        ) ?? (isPro ? .premium : .free)
        subscriptionState = SubscriptionEntitlementState(
            rawValue: UserDefaults.standard.string(forKey: Self.analyticsSubscriptionStateKey) ?? "free"
        ) ?? (isPro ? .active : .free)
        #if DEBUG && targetEnvironment(simulator)
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
        isLoadingProducts = true
        productsLoadFailed = false
        defer { isLoadingProducts = false }
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let currentOffering = offerings.current else {
                products = []
                trialLabels = [:]
                productsLoadFailed = true
                logger.error("RevenueCat returned no current Offering")
                return
            }

            products = currentOffering.availablePackages.map(PremiumProduct.init(package:))
            productsLoadFailed = products.isEmpty
            if products.isEmpty {
                logger.error(
                    "RevenueCat Offering \(currentOffering.identifier, privacy: .public) contains no available packages"
                )
            } else {
                logger.info(
                    "Loaded \(self.products.count) packages from RevenueCat Offering \(currentOffering.identifier, privacy: .public)"
                )
            }
            await refreshTrialEligibility()
        } catch {
            products = []
            trialLabels = [:]
            productsLoadFailed = true
            logger.error("RevenueCat Offering load failed: \(String(describing: error), privacy: .private)")
        }
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
        AppState.trackEvent("purchase_started", properties: [
            "product_id": product.id,
            "plan": product.analyticsName
        ])

        do {
            let result = try await Purchases.shared.purchase(package: product.package)
            if result.userCancelled {
                AppState.trackEvent("purchase_cancelled", properties: [
                    "product_id": product.id,
                    "plan": product.analyticsName
                ])
            } else {
                apply(result.customerInfo)
                AppState.trackEvent("purchase_success", properties: [
                    "product_id": product.id,
                    "plan": product.analyticsName
                ])
                ReviewFeedbackCoordinator.shared.track(.purchaseCompleted(productID: product.id))
            }
        } catch {
            purchaseError = error.localizedDescription
            AppState.trackEvent("purchase_failed", properties: [
                "product_id": product.id,
                "plan": product.analyticsName,
                "error_type": Self.errorType(for: error)
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
            AppState.trackEvent("restore_failed", properties: [
                "error_type": Self.errorType(for: error)
            ])
        }
    }

    private static func errorType(for error: Error) -> String {
        if let purchasesError = error as? RevenueCat.ErrorCode {
            switch purchasesError {
            case .purchaseCancelledError: return "cancelled"
            case .storeProblemError: return "store_problem"
            case .networkError: return "network"
            case .receiptAlreadyInUseError: return "receipt_in_use"
            case .invalidReceiptError: return "invalid_receipt"
            case .missingReceiptFileError: return "missing_receipt"
            case .productNotAvailableForPurchaseError: return "product_unavailable"
            case .paymentPendingError: return "payment_pending"
            default: return "rc_\(purchasesError.rawValue)"
            }
        }
        let ns = error as NSError
        return "err_\(ns.code)"
    }

    // MARK: - Update pro status

    func updateProStatus() async {
        #if DEBUG && targetEnvironment(simulator)
        if isDebugProOverride { return }
        #endif
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            logger.error("Customer info refresh failed: \(String(describing: error), privacy: .private)")
        }
    }

    private func apply(_ customerInfo: CustomerInfo) {
        #if DEBUG && targetEnvironment(simulator)
        if isDebugProOverride { return }
        #endif
        let wasPro = isPro
        let previousState = subscriptionState
        let entitlement = customerInfo.entitlements[entitlementIdentifier]
        let hasPro = entitlement?.isActive == true
        let productIdentifier = entitlement?.productIdentifier
        let nextTier: EntitlementTier
        if hasPro, productIdentifier == ShieldProduct.lifetime.rawValue {
            nextTier = .lifetime
        } else if hasPro, entitlement?.periodType == .trial {
            nextTier = .trial
        } else if hasPro {
            nextTier = .premium
        } else {
            nextTier = .free
        }
        let nextState: SubscriptionEntitlementState
        if hasPro {
            if entitlement?.billingIssueDetectedAt != nil {
                nextState = .billingIssue
            } else if entitlement?.willRenew == false {
                nextState = .autoRenewOff
            } else {
                nextState = .active
            }
        } else if entitlement?.expirationDate != nil {
            nextState = .expired
        } else {
            nextState = .free
        }
        isPro = hasPro
        entitlementTier = nextTier
        subscriptionState = nextState
        activeProductIdentifier = productIdentifier
        UserDefaults.standard.set(hasPro, forKey: "shield.isPro")
        UserDefaults.standard.set(nextTier.rawValue, forKey: Self.analyticsTierKey)
        UserDefaults.standard.set(nextState.rawValue, forKey: Self.analyticsSubscriptionStateKey)

        var snapshot: [String: String] = [
            "tier": nextTier.rawValue,
            "subscription_state": nextState.rawValue
        ]
        if let productIdentifier {
            snapshot["product_id"] = productIdentifier
        }
        AppState.trackEvent("entitlement_snapshot", properties: snapshot)
        if previousState != nextState {
            AppState.trackEvent("subscription_state_changed", properties: snapshot)
        }
        if !wasPro, hasPro {
            ReviewFeedbackCoordinator.shared.track(.subscriptionActivated(productID: productIdentifier ?? "revenuecat"))
        }
    }

    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor [weak self] in self?.apply(customerInfo) }
    }

    #if DEBUG && targetEnvironment(simulator)
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

    func syncProcessedDocumentCountIfNeeded(existingCount: Int) {
        if existingCount > freeDocumentsProcessedCount {
            freeDocumentsProcessedCount = existingCount
            UserDefaults.standard.set(existingCount, forKey: Self.processedDocumentsKey)
        }
    }

    func recordDocumentProcessed() {
        freeDocumentsProcessedCount += 1
        UserDefaults.standard.set(freeDocumentsProcessedCount, forKey: Self.processedDocumentsKey)
        if [1, 3, 5, 8, Self.freeDocumentLimit].contains(freeDocumentsProcessedCount) {
            AppState.trackEvent("quota_milestone", properties: [
                "quota": String(freeDocumentsProcessedCount)
            ])
        }
    }

    func canAddDocument(currentCount: Int? = nil) -> Bool {
        if isPro { return true }
        let count = max(freeDocumentsProcessedCount, currentCount ?? 0)
        return count < PremiumManager.freeDocumentLimit
    }

    var remainingFreeDocuments: Int {
        max(0, PremiumManager.freeDocumentLimit - freeDocumentsProcessedCount)
    }

    #if DEBUG
    func resetFreeProcessedCountForTesting(to value: Int = 0) {
        freeDocumentsProcessedCount = value
        UserDefaults.standard.set(value, forKey: Self.processedDocumentsKey)
    }
    #endif

    func canUseStyle(_ style: MaskStyle) -> Bool {
        isPro || !style.isPremium
    }

    func canUseMode(_ mode: RedactionMode) -> Bool {
        isPro || !mode.requiresPro
    }

    static func recordFeatureGate(_ feature: PremiumFeature, trigger: PaywallTrigger? = nil) {
        var properties = ["feature": feature.rawValue]
        if let trigger {
            properties["trigger"] = trigger.rawValue
        }
        AppState.trackEvent("feature_gate_tapped", properties: properties)
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
        guard let pct = Self.savingsPercent(referencePrice: monthly.price * 12, offerPrice: annual.price)
        else { return nil }
        return LanguageManager.shared.str("paywall_save_percent", table: "Paywall", args: pct)
    }

    func lifetimeSavings(annual: PremiumProduct, lifetime: PremiumProduct, lang: AppLanguage = .en) -> String? {
        guard let pct = Self.savingsPercent(referencePrice: annual.price * 2, offerPrice: lifetime.price)
        else { return nil }
        return LanguageManager.shared.str("paywall_save_two_years_percent", table: "Paywall", args: pct)
    }

    nonisolated static func savingsPercent(referencePrice: Decimal, offerPrice: Decimal) -> Int? {
        guard referencePrice > 0, offerPrice < referencePrice else { return nil }
        let ratio = NSDecimalNumber(decimal: (referencePrice - offerPrice) / referencePrice).doubleValue
        let percentage = Int((ratio * 100).rounded())
        return percentage > 0 ? percentage : nil
    }
}
