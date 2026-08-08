# 71-revenuecat-offerings-diagnosis

- Number: 71
- Slug: revenuecat-offerings-diagnosis

## Notes

- RevenueCat is configured at app launch with the public iOS SDK key from `Info.plist`.
- `PremiumManager.loadProducts()` calls `Purchases.shared.products(ids)` with three hardcoded App Store product IDs. It never calls `Purchases.shared.offerings()` and therefore does not consume the current RevenueCat Offering or its package order/configuration.
- `PremiumManager.purchase(_:)` purchases a `StoreProduct` directly rather than a RevenueCat `Package`, consistent with the direct-product path.
- Empty product responses are reduced to `productsLoadFailed = true`; the load path has no error/log diagnostics, and RevenueCat debug logging is simulator-only. Production/TestFlight failures therefore have no actionable recorded cause.
- App Store Connect live read-only validation: monthly and annual subscriptions and lifetime non-consumable all exist with exact matching IDs and are APPROVED. Subscription/IAP validators report zero errors, warnings, or blockers. App version 1.0.0 is READY_FOR_DISTRIBUTION.
- Local StoreKit configuration contains all three matching IDs and is attached to the shared scheme. Debug simulator build succeeded and `testPaywallCanDismissToWorkspace` passed.
- Root cause in the client architecture: dashboard Offering changes cannot drive this paywall. Recommended implementation is to load `offerings().current.availablePackages`, retain the `Package` for checkout, purchase via `purchase(package:)`, and emit structured logs/errors for nil current Offering, empty packages, and SDK failures. A direct StoreKit-ID fallback can remain only if explicitly desired.
