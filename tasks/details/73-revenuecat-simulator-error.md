# 73-revenuecat-simulator-error

- Number: 73
- Slug: revenuecat-simulator-error

## Notes

2026-08-09:
- User still sees the paywall error state in the iPhone 17 Pro Max simulator.
- Current installed app logs confirm the code path is using `Purchases.shared.offerings()` and failing with RevenueCat `CONFIGURATION_ERROR` / code 23.
- RevenueCat successfully reaches the remote offerings endpoint (`GET /offerings` returns 304), then asks StoreKit for:
  - `com.romerodev.shield.pro.monthly`
  - `com.romerodev.shield.pro.annual`
  - `com.romerodev.shield.pro.lifetime.unlock`
- StoreKit returns no local products for that launched app process, so RevenueCat reports that none of the dashboard products could be fetched from App Store Connect or the StoreKit Configuration file.
- `Shield/Resources/Shield.storekit` contains the three matching product IDs.
- The shared `Shield.xcscheme` has `Shield/Resources/Shield.storekit` attached to both Test and Launch actions.
- Re-ran the gated integration test:
  `RUN_REVENUECAT_INTEGRATION_TESTS=1 xcodebuild -scheme Shield -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -derivedDataPath /tmp/ShieldRevenueCatOffering test -only-testing:ShieldTests/ShieldProductCatalogTests/revenueCatOfferingPackages`
  Result: `TEST SUCCEEDED`.
- Conclusion: RevenueCat/offering/product IDs are consistent. The visible simulator error occurs when the app is launched without an active StoreKit local testing session. Do not add a direct `products(ids)` fallback; that would violate the required offering-based path and still would not provide a RevenueCat `Package` for `purchase(package:)`.
