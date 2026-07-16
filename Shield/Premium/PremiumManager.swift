import StoreKit
import SwiftUI
import OSLog

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
final class PremiumManager: ObservableObject {

    static let shared = PremiumManager()

    private let logger = Logger(subsystem: "com.romerodev.shield", category: "StoreKit")

    @Published private(set) var isPro: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseError: String? = nil
    @Published var isPurchasing: Bool = false
    @Published var isRestoring: Bool = false

    #if DEBUG
    @Published private(set) var isDebugProOverride: Bool = false
    #endif

    private var updateListenerTask: Task<Void, Error>? = nil

    private init() {
        // Restore from cache immediately
        isPro = UserDefaults.standard.bool(forKey: "shield.isPro")
        #if DEBUG
        let override = UserDefaults.standard.bool(forKey: "shield.devProOverride")
        isDebugProOverride = override
        if override { isPro = true }
        #endif
        // Start listener
        updateListenerTask = listenForTransactions()
        Task {
            await processUnfinishedTransactions()
            await updateProStatus()
            await loadProducts()
        }
    }

    deinit { updateListenerTask?.cancel() }

    // MARK: - Load products

    func loadProducts() async {
        do {
            let ids = ShieldProduct.allCases.map(\.rawValue)
            let fetched = try await Product.products(for: ids)
            // The product surface is intentionally limited to three clear choices.
            products = fetched.sorted { lhs, rhs in
                let order: [String: Int] = [
                    ShieldProduct.monthly.rawValue: 0,
                    ShieldProduct.annual.rawValue: 1,
                    ShieldProduct.lifetime.rawValue: 2,
                ]
                return (order[lhs.id] ?? 99) < (order[rhs.id] ?? 99)
            }
        } catch {
            logger.error("Product loading failed: \(String(describing: error), privacy: .private)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }
        AppState.trackEvent("purchase_started", properties: ["product_id": product.id])

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateProStatus()
                AppState.trackEvent("purchase_success", properties: ["product_id": product.id])
                await transaction.finish()
            case .pending:
                AppState.trackEvent("purchase_pending", properties: ["product_id": product.id])
                break
            case .userCancelled:
                AppState.trackEvent("purchase_cancelled", properties: ["product_id": product.id])
                break
            @unknown default:
                break
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
            try await AppStore.sync()
            await updateProStatus()
            AppState.trackEvent("restore_success")
        } catch {
            purchaseError = error.localizedDescription
            AppState.trackEvent("restore_failed", properties: ["error": error.localizedDescription])
        }
    }

    // MARK: - Listen for transactions

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateProStatus()
                    await transaction.finish()
                } catch {
                    self.logger.error("Transaction verification failed: \(String(describing: error), privacy: .private)")
                }
            }
        }
    }

    private func processUnfinishedTransactions() async {
        for await result in Transaction.unfinished {
            do {
                let transaction = try checkVerified(result)
                await updateProStatus()
                await transaction.finish()
            } catch {
                logger.error("Unfinished transaction verification failed: \(String(describing: error), privacy: .private)")
            }
        }
    }

    // MARK: - Update pro status

    func updateProStatus() async {
        #if DEBUG
        if isDebugProOverride { return }
        #endif
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.revocationDate == nil
            else { continue }
            if ShieldProduct.allCases.map(\.rawValue).contains(transaction.productID) {
                if let expiry = transaction.expirationDate {
                    if expiry > Date() {
                        hasPro = true
                        break
                    }
                } else {
                    // Non-consumable lifetime entitlement.
                    hasPro = true
                    break
                }
            }
        }
        isPro = hasPro
        UserDefaults.standard.set(hasPro, forKey: "shield.isPro")
    }

    #if DEBUG
    func setDebugProOverride(_ enabled: Bool) {
        isDebugProOverride = enabled
        UserDefaults.standard.set(enabled, forKey: "shield.devProOverride")
        isPro = enabled
        UserDefaults.standard.set(enabled, forKey: "shield.isPro")
    }
    #endif

    // MARK: - Verify

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }

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

    func annualSavings(monthly: Product, annual: Product, lang: AppLanguage = .en) -> String? {
        guard let pct = savingsPercent(referencePrice: monthly.price * 12, offerPrice: annual.price)
        else { return nil }
        return LanguageManager.shared.str("paywall_save_percent", table: "Paywall", args: pct)
    }

    func lifetimeSavings(annual: Product, lifetime: Product, lang: AppLanguage = .en) -> String? {
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
