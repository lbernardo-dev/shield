import StoreKit
import SwiftUI

// MARK: - Product IDs  (match exactly what you register in App Store Connect)

enum ShieldProduct: String, CaseIterable {
    case monthly   = "com.shield.redact.pro.monthly"
    case annual    = "com.shield.redact.pro.annual"
    case lifetime  = "com.shield.redact.pro.lifetime"

    var displayName: String {
        switch self {
        case .monthly:  return "Shield Pro Monthly"
        case .annual:   return "Shield Pro Annual"
        case .lifetime: return "Shield Pro Lifetime"
        }
    }
}

// MARK: - PremiumManager

@MainActor
final class PremiumManager: ObservableObject {

    static let shared = PremiumManager()

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
        Task { await loadProducts() }
    }

    deinit { updateListenerTask?.cancel() }

    // MARK: - Load products

    func loadProducts() async {
        do {
            let ids = ShieldProduct.allCases.map(\.rawValue)
            let fetched = try await Product.products(for: ids)
            // Sort: monthly → annual → lifetime
            products = fetched.sorted { lhs, rhs in
                let order: [String: Int] = [
                    ShieldProduct.monthly.rawValue: 0,
                    ShieldProduct.annual.rawValue: 1,
                    ShieldProduct.lifetime.rawValue: 2,
                ]
                return (order[lhs.id] ?? 99) < (order[rhs.id] ?? 99)
            }
        } catch {
            print("Shield: failed to load products: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updateProStatus()
                await transaction.finish()
            case .pending:
                break
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Restore

    func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
            await updateProStatus()
        } catch {
            purchaseError = error.localizedDescription
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
                    print("Shield: transaction verification failed: \(error)")
                }
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
            guard case .verified(let transaction) = result else { continue }
            if ShieldProduct.allCases.map(\.rawValue).contains(transaction.productID) {
                if let expiry = transaction.expirationDate {
                    hasPro = expiry > Date()
                } else {
                    hasPro = true  // lifetime
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
    static let freeDocumentLimit = 3

    func canAddDocument(currentCount: Int) -> Bool {
        isPro || currentCount < PremiumManager.freeDocumentLimit
    }

    func canUseStyle(_ style: MaskStyle) -> Bool {
        isPro || !style.isPremium
    }

    // MARK: - Helpers for display

    func annualSavings(monthly: Product, annual: Product) -> String? {
        let m = monthly.price * 12
        let a = annual.price
        guard m > 0 else { return nil }
        let ratio = NSDecimalNumber(decimal: (m - a) / m).doubleValue
        let pct = Int((ratio * 100).rounded())
        return "Save \(pct)%"
    }
}
