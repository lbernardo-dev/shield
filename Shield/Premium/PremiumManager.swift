import SwiftUI
import OSLog
import RevenueCat
import Security
import StoreKit
import CloudKit

// MARK: - Product IDs  (match exactly what you register in App Store Connect)

enum ShieldProduct: String, CaseIterable {
    case monthly   = "com.romerodev.shield.pro.monthly"
    case annual    = "com.romerodev.shield.pro.annual"
    case annualEvent = "com.romerodev.shield.pro.annual.event"
    case lifetime  = "com.romerodev.shield.pro.lifetime.unlock"

    var analyticsName: String {
        switch self {
        case .monthly: "monthly"
        case .annual: "annual"
        case .annualEvent: "annual_event"
        case .lifetime: "lifetime"
        }
    }

    func label(lang: AppLanguage) -> String {
        let key: String
        switch self {
        case .monthly:  key = "paywall_plan_monthly"
        case .annual:   key = "paywall_plan_annual"
        case .annualEvent: key = "paywall_plan_annual_event"
        case .lifetime: key = "paywall_plan_lifetime"
        }
        return LanguageManager.shared.t(key, table: "Paywall", language: lang)
    }
}

struct PremiumProduct: Identifiable {
    let package: RevenueCat.Package
    let storeKitProduct: StoreKit.Product?
    let comparisonProduct: StoreKit.Product?
    let eventIdentifier: String?
    let campaignIdentifier: String?

    init(
        package: RevenueCat.Package,
        storeKitProduct: StoreKit.Product? = nil,
        comparisonProduct: StoreKit.Product? = nil,
        eventIdentifier: String? = nil,
        campaignIdentifier: String? = nil
    ) {
        self.package = package
        self.storeKitProduct = storeKitProduct
        self.comparisonProduct = comparisonProduct
        self.eventIdentifier = eventIdentifier
        self.campaignIdentifier = campaignIdentifier
    }

    var storeProduct: StoreProduct { package.storeProduct }
    var id: String { storeProduct.productIdentifier }
    var packageIdentifier: String { package.identifier }
    var analyticsName: String {
        if isEventAnnual { return "annual_event" }
        return ShieldProduct(rawValue: id)?.analyticsName ?? packageIdentifier
    }
    var isEventAnnual: Bool { eventIdentifier != nil }
    var displayName: String { storeProduct.localizedTitle }
    var displayPrice: String { storeKitProduct?.displayPrice ?? storeProduct.localizedPriceString }
    var price: Decimal { storeKitProduct?.price ?? storeProduct.price }
    var comparisonDisplayPrice: String? { comparisonProduct?.displayPrice }
    var renewalPeriodLabel: String? {
        guard let period = storeKitProduct?.subscription?.subscriptionPeriod else {
            return catalogRenewalPeriodLabel
        }

        if period.value == 1 {
            switch period.unit {
            case .day: return LanguageManager.shared.paywall("paywall_per_day")
            case .week: return LanguageManager.shared.paywall("paywall_per_week")
            case .month: return LanguageManager.shared.paywall("paywall_per_month")
            case .year: return LanguageManager.shared.paywall("paywall_per_year")
            @unknown default: return catalogRenewalPeriodLabel
            }
        }

        switch period.unit {
        case .day: return LanguageManager.shared.paywall("paywall_every_days", period.value)
        case .week: return LanguageManager.shared.paywall("paywall_every_weeks", period.value)
        case .month: return LanguageManager.shared.paywall("paywall_every_months", period.value)
        case .year: return LanguageManager.shared.paywall("paywall_every_years", period.value)
        @unknown default: return catalogRenewalPeriodLabel
        }
    }

    private var catalogRenewalPeriodLabel: String? {
        return switch ShieldProduct(rawValue: id) {
        case .monthly: LanguageManager.shared.paywall("paywall_per_month")
        case .annual, .annualEvent: LanguageManager.shared.paywall("paywall_per_year")
        case .lifetime, nil: nil
        }
    }
    var eventDiscountPercent: Int? {
        guard let comparisonProduct, comparisonProduct.price > 0, price < comparisonProduct.price else {
            return nil
        }
        let discount = (comparisonProduct.price - price) / comparisonProduct.price
        return Int(NSDecimalNumber(decimal: discount * Decimal(100)).doubleValue.rounded())
    }
}
// MARK: - PaywallTrigger (why are we showing the paywall)
enum PaywallTrigger: String, CaseIterable {
    case manual
    case accessRequired
    case styleLocked
    case featureLocked
    case vaultUpgrade
    case settingsUpgrade

    var localizationKey: String {
        switch self {
        case .manual:           return "paywall_trigger_manual"
        case .accessRequired:   return "paywall_trigger_access_required"
        case .styleLocked:      return "paywall_trigger_style_locked"
        case .featureLocked:    return "paywall_trigger_feature_locked"
        case .vaultUpgrade:     return "paywall_trigger_vault"
        case .settingsUpgrade:  return "paywall_trigger_generic"
        }
    }

    var featureKey: String? {
        switch self {
        case .accessRequired: "document_processing"
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
    case seasonalThemes = "seasonal_themes"
}

enum SubscriptionEntitlementState: String {
    case free
    case active
    case autoRenewOff = "auto_renew_off"
    case gracePeriod = "grace_period"
    case billingIssue = "billing_issue"
    case billingRetry = "billing_retry"
    case familyShared = "family_shared"
    case pending
    case expired
    case legacy
    case unknown
}

enum SubscriptionOwnership: String {
    case purchased
    case familyShared = "family_shared"
    case assigned
    case unknown
}

/// Resolves app access without changing StoreKit or RevenueCat entitlements.
enum PremiumAccessResolver {
    static let permanentCloudKitUserRecordNames: Set<String> = [
        "_ac0fee5ea87e7f0ef40eb34f24ac8d11",
        "_55d90a302b843b29baf181bb21263103"
    ]

    static func grantsPermanentCloudKitAccess(
        verifiedUserRecordName: String?,
        isProductionBuild: Bool
    ) -> Bool {
        guard isProductionBuild,
              let verifiedUserRecordName,
              permanentCloudKitUserRecordNames.contains(verifiedUserRecordName)
        else {
            return false
        }
        return true
    }

    static func hasPremiumAccess(
        storeEntitlementIsActive: Bool,
        verifiedCloudKitUserRecordName: String?,
        isProductionBuild: Bool
    ) -> Bool {
        storeEntitlementIsActive || grantsPermanentCloudKitAccess(
            verifiedUserRecordName: verifiedCloudKitUserRecordName,
            isProductionBuild: isProductionBuild
        )
    }
}

// MARK: - PremiumManager

@MainActor
final class PremiumManager: NSObject, ObservableObject, PurchasesDelegate {

    static let shared = PremiumManager()

    private static let entitlementFallback = "MaskID Pro"
    private let logger = Logger(subsystem: "com.romerodev.shield", category: "RevenueCat")
    private lazy var cloudKitPremiumContainer = CloudKitContainerFactory.make(
        identifier: CloudSyncManager.cloudKitContainerIdentifier
    )
    private var cloudAccountChangeObserver: NSObjectProtocol?
    private var cloudKitIdentityRefreshGeneration: UInt = 0
    private var verifiedCloudKitUserRecordName: String?
    private var hasRevenueCatPremium = false
    private let accessStateStore = AccessStateStore()
    private var accessRecord: AccessRecord?
    private var accessStorageAvailable = true
    private let missingAccessRecordCohort: AccessCohort

    @Published private(set) var isPro: Bool = false
    @Published private(set) var accessState: AppAccessState = .verifying
    @Published private(set) var accessExpiresAt: Date?
    @Published private(set) var products: [PremiumProduct] = []
    @Published private(set) var isLoadingProducts: Bool = false
    @Published private(set) var productsLoadFailed: Bool = false
    @Published private(set) var purchaseError: String? = nil
    @Published var isPurchasing: Bool = false
    @Published var isRestoring: Bool = false
    @Published private(set) var entitlementTier: EntitlementTier = .free
    @Published private(set) var subscriptionState: SubscriptionEntitlementState = .unknown
    @Published private(set) var activeProductIdentifier: String?
    @Published private(set) var expirationDate: Date?
    @Published private(set) var willRenew: Bool?
    @Published private(set) var ownership: SubscriptionOwnership = .unknown
    @Published private(set) var isResolvingSubscription = true
    @Published private(set) var hasResolvedSubscription = false
    @Published private(set) var isEventPaywall = false
    @Published private(set) var eventAnnualProductIdentifier: String?
    @Published private(set) var eventAnnualPricing: AnnualEventPricing?
    @Published private(set) var activeEventIdentifier: String?
    @Published private(set) var activeCampaignIdentifier: String?

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
        missingAccessRecordCohort = AccessMigrationClassifier.cohort(
            preMigrationInstallEvidence: UserDefaults.standard.bool(forKey: "shield.access.preMigrationInstallEvidence"),
            wasOnboarded: UserDefaults.standard.bool(forKey: "shield.onboarded"),
            savedDocumentCount: 0,
            previouslyProcessedDocumentCount: UserDefaults.standard.integer(forKey: Self.processedDocumentsKey)
        )
        super.init()
        switch accessStateStore.load() {
        case .record(let record):
            accessRecord = record
        case .missing:
            accessRecord = nil
        case .unavailable:
            accessStorageAvailable = false
        }
        // RevenueCat CustomerInfo is the only persisted entitlement authority.
        // Legacy UserDefaults booleans are deliberately ignored for access.
        isPro = false
        let localDocCount = UserDefaults.standard.integer(forKey: Self.processedDocumentsKey)
        freeDocumentsProcessedCount = SecureQuotaStore.loadHighestCount(localCount: localDocCount)
        UserDefaults.standard.set(freeDocumentsProcessedCount, forKey: Self.processedDocumentsKey)
        entitlementTier = .free
        subscriptionState = .unknown
        UserDefaults.standard.set(EntitlementTier.free.rawValue, forKey: Self.analyticsTierKey)
        UserDefaults.standard.set(
            SubscriptionEntitlementState.unknown.rawValue,
            forKey: Self.analyticsSubscriptionStateKey
        )
        #if DEBUG && targetEnvironment(simulator)
        let override = UserDefaults.standard.bool(forKey: "shield.devProOverride")
            || ProcessInfo.processInfo.arguments.contains("-ui-testing")
            || ProcessInfo.processInfo.arguments.contains("-aso-screenshots")
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        isDebugProOverride = override
        #endif
        refreshResolvedPremiumAccess()
        observeCloudKitAccountChanges()
        Purchases.shared.delegate = self
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let current = self.freeDocumentsProcessedCount
                let updated = SecureQuotaStore.loadHighestCount(localCount: current)
                if updated > current {
                    self.freeDocumentsProcessedCount = updated
                    UserDefaults.standard.set(updated, forKey: Self.processedDocumentsKey)
                }
            }
        }
        Task {
            await refreshCloudKitPremiumAccess()
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
                isEventPaywall = false
                eventAnnualPricing = nil
                activeEventIdentifier = nil
                activeCampaignIdentifier = nil
                eventAnnualProductIdentifier = nil
                productsLoadFailed = true
                logger.error("RevenueCat returned no current Offering")
                return
            }

            let standardPackages = currentOffering.availablePackages
            let standardMonthly = standardPackages.first {
                $0.storeProduct.productIdentifier == ShieldProduct.monthly.rawValue
            }
            let standardAnnual = standardPackages.first {
                $0.storeProduct.productIdentifier == ShieldProduct.annual.rawValue
            }
            let lifetime = standardPackages.first {
                $0.storeProduct.productIdentifier == ShieldProduct.lifetime.rawValue
            }

            let clock = SeasonalThemeClock()
            let activeScheduledThemeID = SeasonalThemeResolver.activeScheduledTheme(at: clock)
            let eventDefinition = activeScheduledThemeID.flatMap {
                SeasonalThemeCatalog.definition(for: $0)
            }
            let monetization = eventDefinition?.monetization
            let eventOffering = monetization.flatMap { offerings.all[$0.revenueCatOfferingIdentifier] }
            // All active campaigns share the same Annual Event subscription.
            let eventProductIdentifier = ShieldProduct.annualEvent.rawValue
            let eventAnnual = eventOffering?.availablePackages.first {
                $0.storeProduct.productIdentifier == eventProductIdentifier
            }
            let eventMonthly = eventOffering?.availablePackages.first {
                $0.storeProduct.productIdentifier == ShieldProduct.monthly.rawValue
            }

            var storeKitProductIdentifiers = [
                ShieldProduct.monthly.rawValue,
                ShieldProduct.annual.rawValue,
                ShieldProduct.lifetime.rawValue
            ]
            storeKitProductIdentifiers.append(eventProductIdentifier)
            let storeKitProducts = (try? await StoreKit.Product.products(for: Array(Set(storeKitProductIdentifiers)))) ?? []
            let storeKitProductsByID = Dictionary(
                uniqueKeysWithValues: storeKitProducts.map { ($0.id, $0) }
            )
            let pricing = Self.validatedAnnualEventPricing(
                standard: storeKitProductsByID[ShieldProduct.annual.rawValue],
                event: storeKitProductsByID[eventProductIdentifier],
                expectedEventProductIdentifier: eventProductIdentifier,
                targetDiscountPercent: monetization?.targetDiscountPercent ?? 50
            )
            let expectedEventProductsAvailable = standardMonthly != nil
                && standardAnnual != nil
                && eventMonthly != nil
                && eventAnnual != nil
            let showEvent = SubscriptionPaywallExperienceResolver.shouldUseEvent(
                eventIsActive: eventDefinition != nil,
                monetizationConfigured: monetization != nil,
                userIsNotConfirmedFree: isPro || !hasResolvedSubscription,
                eventOfferingAvailable: eventOffering != nil,
                expectedProductsAvailable: expectedEventProductsAvailable,
                validatedPricing: pricing
            )

            if eventDefinition != nil, !showEvent {
                let fallbackReason: String
                if isPro {
                    fallbackReason = "premium_subscriber"
                } else if monetization == nil {
                    fallbackReason = "campaign_monetization_missing"
                } else if eventOffering == nil {
                    fallbackReason = "event_offering_missing"
                } else if !expectedEventProductsAvailable {
                    fallbackReason = "event_products_missing"
                } else {
                    fallbackReason = "storekit_price_or_group_mismatch"
                }
                AppState.trackEvent("event_paywall_fallback", properties: [
                    "event_id": eventDefinition?.id.rawValue ?? "unknown",
                    "campaign_id": monetization?.campaignIdentifier ?? "unknown",
                    "reason": fallbackReason
                ])
            }

            isEventPaywall = showEvent
            eventAnnualPricing = showEvent ? pricing : nil
            activeEventIdentifier = showEvent ? eventDefinition?.id.rawValue : nil
            activeCampaignIdentifier = showEvent ? monetization?.campaignIdentifier : nil
            eventAnnualProductIdentifier = showEvent ? eventProductIdentifier : nil

            if showEvent, let standardMonthly, let eventAnnual {
                var eventProducts = [
                    PremiumProduct(
                        package: standardMonthly,
                        storeKitProduct: storeKitProductsByID[ShieldProduct.monthly.rawValue]
                    ),
                    PremiumProduct(
                        package: eventAnnual,
                        storeKitProduct: storeKitProductsByID[eventProductIdentifier],
                        comparisonProduct: storeKitProductsByID[ShieldProduct.annual.rawValue],
                        eventIdentifier: eventDefinition?.id.rawValue,
                        campaignIdentifier: monetization?.campaignIdentifier
                    )
                ]
                if let lifetime {
                    eventProducts.append(PremiumProduct(
                        package: lifetime,
                        storeKitProduct: storeKitProductsByID[ShieldProduct.lifetime.rawValue]
                    ))
                }
                products = eventProducts
            } else {
                products = standardPackages.map { package in
                    PremiumProduct(
                        package: package,
                        storeKitProduct: storeKitProductsByID[package.storeProduct.productIdentifier]
                    )
                }
            }

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
        } catch {
            products = []
            isEventPaywall = false
            eventAnnualPricing = nil
            activeEventIdentifier = nil
            activeCampaignIdentifier = nil
            eventAnnualProductIdentifier = nil
            productsLoadFailed = true
            logger.error("RevenueCat Offering load failed: \(String(describing: error), privacy: .private)")
        }
    }

    private static func validatedAnnualEventPricing(
        standard: StoreKit.Product?,
        event: StoreKit.Product?,
        expectedEventProductIdentifier: String,
        targetDiscountPercent: Int
    ) -> AnnualEventPricing? {
        guard let standard = subscriptionSnapshot(for: standard),
              let event = subscriptionSnapshot(for: event) else {
            return nil
        }
        return AnnualEventPriceValidator.validate(
            standard: standard,
            event: event,
            expectedEventProductIdentifier: expectedEventProductIdentifier,
            targetDiscountPercent: targetDiscountPercent
        )
    }

    private static func subscriptionSnapshot(
        for product: StoreKit.Product?
    ) -> SubscriptionProductSnapshot? {
        guard let product, let subscription = product.subscription else { return nil }
        let durationUnit: SubscriptionDurationUnit
        switch subscription.subscriptionPeriod.unit {
        case .day: durationUnit = .day
        case .week: durationUnit = .week
        case .month: durationUnit = .month
        case .year: durationUnit = .year
        @unknown default: durationUnit = .other
        }
        return SubscriptionProductSnapshot(
            productIdentifier: product.id,
            price: product.price,
            displayPrice: product.displayPrice,
            durationUnit: durationUnit,
            durationValue: subscription.subscriptionPeriod.value,
            subscriptionGroupIdentifier: subscription.subscriptionGroupID,
            subscriptionGroupLevel: subscription.groupLevel,
            hasIntroductoryOffer: subscription.introductoryOffer != nil
        )
    }

    // MARK: - Purchase

    func purchase(_ product: PremiumProduct) async {
        guard hasResolvedSubscription, !hasPaidPremiumAccess else { return }
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
                    "plan": product.analyticsName,
                    "event_id": product.eventIdentifier ?? "none",
                    "campaign_id": product.campaignIdentifier ?? "none",
                    "event_price": product.eventIdentifier == nil ? "none" : NSDecimalNumber(decimal: product.price).stringValue,
                    "standard_price": product.comparisonProduct.map { NSDecimalNumber(decimal: $0.price).stringValue } ?? "none",
                    "discount": product.eventDiscountPercent.map(String.init) ?? "none"
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
        purchaseError = nil
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

    /// Reconciles a verified StoreKit offer-code transaction with RevenueCat.
    /// This is only called after the system redemption sheet reports success.
    func reconcileAfterOfferCodeRedemption() async {
        purchaseError = nil
        do {
            apply(try await Purchases.shared.syncPurchases())
            AppState.trackEvent("offer_code_reconciled", properties: [
                "result": isPro ? "entitled" : "no_entitlement"
            ])
        } catch {
            purchaseError = error.localizedDescription
            AppState.trackEvent("offer_code_reconciled", properties: [
                "result": "failed",
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
        isResolvingSubscription = true
        defer { isResolvingSubscription = false }
        #if DEBUG && targetEnvironment(simulator)
        if isDebugProOverride { return }
        #endif
        guard Purchases.isConfigured else {
            hasResolvedSubscription = true
            refreshTemporalAccess()
            return
        }
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            logger.error("Customer info refresh failed: \(String(describing: error), privacy: .private)")
        }
    }

    /// Fetches the CloudKit identity from the same container used by private sync.
    /// The record name is kept in memory only and is discarded before every refresh.
    func refreshCloudKitPremiumAccess() async {
        cloudKitIdentityRefreshGeneration &+= 1
        let refreshGeneration = cloudKitIdentityRefreshGeneration
        verifiedCloudKitUserRecordName = nil
        refreshResolvedPremiumAccess()

        guard Self.isProductionBuild else { return }
        guard let cloudKitPremiumContainer else { return }

        do {
            guard try await cloudKitPremiumContainer.accountStatus() == .available else { return }
            let userRecordID = try await cloudKitPremiumContainer.userRecordID()
            guard refreshGeneration == cloudKitIdentityRefreshGeneration else { return }
            verifiedCloudKitUserRecordName = userRecordID.recordName
            refreshResolvedPremiumAccess()
        } catch {
            logger.error("CloudKit identity verification failed; permanent Premium access remains unavailable")
        }
    }

    func invalidateCloudKitPremiumAccess() {
        cloudKitIdentityRefreshGeneration &+= 1
        verifiedCloudKitUserRecordName = nil
        refreshResolvedPremiumAccess()
    }

    private static var isProductionBuild: Bool {
        #if DEBUG || targetEnvironment(simulator)
        false
        #else
        true
        #endif
    }

    private func refreshResolvedPremiumAccess() {
        refreshTemporalAccess()
    }

    private var hasPaidPremiumAccess: Bool {
        var storeEntitlementIsActive = hasRevenueCatPremium
        #if DEBUG && targetEnvironment(simulator)
        storeEntitlementIsActive = storeEntitlementIsActive || isDebugProOverride
        #endif
        return PremiumAccessResolver.hasPremiumAccess(
            storeEntitlementIsActive: storeEntitlementIsActive,
            verifiedCloudKitUserRecordName: verifiedCloudKitUserRecordName,
            isProductionBuild: Self.isProductionBuild
        )
    }

    @discardableResult
    func startTemporaryAccess(at now: Date = Date()) -> Bool {
        guard hasResolvedSubscription,
              !hasPaidPremiumAccess,
              accessStorageAvailable,
              accessRecord == nil,
              accessState == .newUserNotice || accessState == .existingUserNotice,
              let record = AccessRecord.start(cohort: missingAccessRecordCohort, at: now),
              accessStateStore.save(record)
        else { return false }
        accessRecord = record
        refreshTemporalAccess(now: now)
        return accessState.hasFullAccess
    }

    func refreshTemporalAccess(now: Date = Date()) {
        if hasPaidPremiumAccess {
            #if DEBUG && targetEnvironment(simulator)
            let isTestOverride = isDebugProOverride
            #else
            let isTestOverride = false
            #endif
            if accessRecord == nil, accessStorageAvailable, !isTestOverride {
                let paidRecord = AccessRecord.paidAccessObserved(
                    cohort: missingAccessRecordCohort,
                    at: now
                )
                if accessStateStore.save(paidRecord) {
                    accessRecord = paidRecord
                } else {
                    // Never replace a verified paid entitlement with a trial.
                    // If its status later changes, storage failure stays fail-closed.
                    accessStorageAvailable = false
                }
            }
            accessState = .purchased
            accessExpiresAt = nil
            isPro = true
            return
        }
        guard hasResolvedSubscription else {
            accessState = .verifying
            accessExpiresAt = nil
            isPro = hasPaidPremiumAccess
            return
        }

        if let record = accessRecord {
            let refreshed = AccessPolicy.refreshed(record, at: now)
            let lastTrustedAt = record.lastTrustedAt ?? .distantPast
            if refreshed != record, now.timeIntervalSince(lastTrustedAt) >= 60 * 60 {
                guard accessStateStore.save(refreshed) else {
                    accessStorageAvailable = false
                    accessState = AccessPolicy.resolve(
                        record: accessRecord,
                        missingRecordCohort: missingAccessRecordCohort,
                        now: now,
                        hasPaidAccess: hasPaidPremiumAccess,
                        storageAvailable: false
                    )
                    isPro = accessState.hasFullAccess
                    return
                }
                accessRecord = refreshed
            }
        }

        accessState = AccessPolicy.resolve(
            record: accessRecord,
            missingRecordCohort: missingAccessRecordCohort,
            now: now,
            hasPaidAccess: hasPaidPremiumAccess,
            storageAvailable: accessStorageAvailable
        )
        switch accessState {
        case .temporaryFullAccess(let date, _), .readOnlyRecovery(let date):
            accessExpiresAt = date
        default:
            accessExpiresAt = nil
        }
        isPro = accessState.hasFullAccess
    }

    var canModifyProductData: Bool {
        accessState.allows(.modifyContent)
    }

    var canCreateOrImportProductData: Bool {
        accessState.allows(.createContent) && accessState.allows(.importContent)
    }

    private func observeCloudKitAccountChanges() {
        guard Self.isProductionBuild,
              let cloudKitPremiumContainer
        else { return }

        cloudAccountChangeObserver = NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: cloudKitPremiumContainer,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.verifiedCloudKitUserRecordName = nil
                self.refreshResolvedPremiumAccess()
                await self.refreshCloudKitPremiumAccess()
            }
        }
    }

    private func apply(_ customerInfo: CustomerInfo) {
        #if DEBUG && targetEnvironment(simulator)
        if isDebugProOverride { return }
        #endif
        guard customerInfo.entitlements.verification != .failed else {
            logger.error("RevenueCat entitlement verification failed; retaining the last known app state")
            return
        }
        let previouslyHadRevenueCatPremium = hasRevenueCatPremium
        let previousState = subscriptionState
        let entitlement = customerInfo.entitlements.active[entitlementIdentifier]
        let inactiveEntitlement = customerInfo.entitlements.all[entitlementIdentifier]
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
            } else if entitlement?.ownershipType == .familyShared {
                nextState = .familyShared
            } else {
                nextState = .active
            }
        } else if inactiveEntitlement?.expirationDate.map({ $0 <= Date() }) == true {
            nextState = .expired
        } else {
            nextState = .free
        }
        hasRevenueCatPremium = hasPro
        refreshResolvedPremiumAccess()
        entitlementTier = nextTier
        subscriptionState = nextState
        activeProductIdentifier = productIdentifier
        expirationDate = hasPro ? entitlement?.expirationDate : inactiveEntitlement?.expirationDate
        willRenew = hasPro ? entitlement?.willRenew : nil
        let ownershipType = hasPro ? entitlement?.ownershipType : inactiveEntitlement?.ownershipType
        switch ownershipType {
        case .some(.purchased): ownership = .purchased
        case .some(.familyShared): ownership = .familyShared
        case .some(.assigned): ownership = .assigned
        case .some(.unknown), .none: ownership = .unknown
        @unknown default: ownership = .unknown
        }
        hasResolvedSubscription = true
        isResolvingSubscription = false
        refreshTemporalAccess()
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
        if !previouslyHadRevenueCatPremium, hasPro {
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
        refreshResolvedPremiumAccess()
        UserDefaults.standard.set(enabled, forKey: "shield.isPro")
    }
    #endif

    // MARK: - Limits

    /// Historical counter retained only as migration evidence/usage analytics.
    private static let legacyUsageMilestones = [1, 3, 5, 8, 10]

    func syncProcessedDocumentCountIfNeeded(existingCount: Int) {
        let highest = max(freeDocumentsProcessedCount, existingCount)
        let resolved = SecureQuotaStore.loadHighestCount(localCount: highest)
        if resolved > freeDocumentsProcessedCount {
            freeDocumentsProcessedCount = resolved
            UserDefaults.standard.set(resolved, forKey: Self.processedDocumentsKey)
            SecureQuotaStore.persistCount(resolved)
        }
    }

    func recordDocumentProcessed() {
        freeDocumentsProcessedCount += 1
        UserDefaults.standard.set(freeDocumentsProcessedCount, forKey: Self.processedDocumentsKey)
        SecureQuotaStore.persistCount(freeDocumentsProcessedCount)
        if Self.legacyUsageMilestones.contains(freeDocumentsProcessedCount) {
            AppState.trackEvent("quota_milestone", properties: [
                "quota": String(freeDocumentsProcessedCount)
            ])
        }
    }

    func canAddDocument(currentCount: Int? = nil) -> Bool {
        accessState.allows(.createContent)
    }

    #if DEBUG
    func resetFreeProcessedCountForTesting(to value: Int = 0) {
        freeDocumentsProcessedCount = value
        UserDefaults.standard.set(value, forKey: Self.processedDocumentsKey)
        if value == 0 {
            SecureQuotaStore.resetForTesting()
        } else {
            SecureQuotaStore.persistCount(value)
        }
    }
    #endif

    func canUseStyle(_ style: MaskStyle) -> Bool {
        accessState.hasFullAccess
    }

    func canUseMode(_ mode: RedactionMode) -> Bool {
        accessState.hasFullAccess
    }

    static func recordFeatureGate(_ feature: PremiumFeature, trigger: PaywallTrigger? = nil) {
        var properties = ["feature": feature.rawValue]
        if let trigger {
            properties["trigger"] = trigger.rawValue
        }
        AppState.trackEvent("feature_gate_tapped", properties: properties)
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

// MARK: - Secure Quota Persistence (Keychain + iCloud KVS)

enum SecureQuotaStore {
    private static let service = "com.romerodev.shield.quota"
    private static let account = "shield.free.processedDocumentsCount"
    private static let iCloudKey = "shield.free.processedDocumentsCount"

    /// Reads the maximum recorded processed count across Keychain, iCloud KVS, and local storage.
    static func loadHighestCount(localCount: Int) -> Int {
        let keychainCount = readKeychainCount()
        let iCloudCount = readICloudCount()
        let resolvedMax = resolveHighestCount(
            localCount: localCount,
            keychainCount: keychainCount,
            iCloudCount: iCloudCount
        )

        if resolvedMax > 0 {
            persistCount(resolvedMax)
        }
        return resolvedMax
    }

    /// Reconciles the aggregate count without ever reducing a device's local
    /// record when iCloud is unavailable or belongs to a different account.
    static func resolveHighestCount(localCount: Int, keychainCount: Int, iCloudCount: Int) -> Int {
        max(0, max(localCount, max(keychainCount, iCloudCount)))
    }

    static func persistCount(_ count: Int) {
        guard count > 0 else { return }
        writeKeychainCount(count)
        writeICloudCount(count)
    }

    private static func readKeychainCount() -> Int {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8),
              let count = Int(string) else {
            return 0
        }
        return count
    }

    private static func writeKeychainCount(_ count: Int) {
        let countString = String(count)
        guard let data = countString.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            newItem[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }

    private static func readICloudCount() -> Int {
        Int(NSUbiquitousKeyValueStore.default.longLong(forKey: iCloudKey))
    }

    private static func writeICloudCount(_ count: Int) {
        NSUbiquitousKeyValueStore.default.set(Int64(count), forKey: iCloudKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }

    #if DEBUG
    static func resetForTesting() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        NSUbiquitousKeyValueStore.default.removeObject(forKey: iCloudKey)
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    #endif
}
