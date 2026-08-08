# 72-revenuecat-offering-integration

- Number: 72
- Slug: revenuecat-offering-integration

## Notes

- Replaced direct `Purchases.shared.products(ids)` loading with `Purchases.shared.offerings().current.availablePackages`.
- `PremiumProduct` now retains its RevenueCat `Package`; checkout uses `Purchases.shared.purchase(package:)` so RevenueCat preserves the presented Offering context.
- Package display order now follows the current Offering. Paywall selection uses the remotely supplied product ID, allowing new Offering packages to remain selectable without adding an enum case first.
- Added structured OSLog diagnostics for missing current Offering, empty available packages, successful package loads, and SDK errors.
- Confirmed the live `default` Offering contains `$rc_monthly`, `$rc_annual`, and `$rc_lifetime`, mapped to the same three IDs in `Shield.storekit`.
- Added an opt-in StoreKitTest integration test. It creates `SKTestSession(contentsOf:)`, fetches the live current RevenueCat Offering, and verifies all three packages resolve against the local StoreKit catalog. Enable with `RUN_REVENUECAT_INTEGRATION_TESTS=1`.
- Simulator nuance: launching an already-installed app or launching it from `XCUIApplication` does not inherit the Xcode scheme's StoreKit Configuration. Use Run from the shared `Shield` scheme, or the opt-in integration test, for local product resolution.
- Verification: clean Debug simulator build passed; opt-in RevenueCat/StoreKit integration test passed; Shield product catalog suite passed with integration test skipped by default; `testPaywallCanDismissToWorkspace` passed.
