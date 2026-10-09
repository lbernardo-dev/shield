# 206-subscription-financial-monetization-architecture

- Number: 206
- Slug: subscription-financial-monetization-architecture

## Notes

- Audited the existing RevenueCat-based `PremiumManager`, custom main/onboarding paywalls, StoreKit fixture, subscription lifecycle observer, seasonal theme catalog, app Storefront listing and task history. Kept the existing purchase/entitlement architecture; no second manager or StoreKit purchase path.
- Current Spain prices confirmed from the public listing and local fixture: €2.99 monthly, €29.99 annual and €49.99 lifetime. Existing Product IDs remain unchanged. Historical RevenueCat Offering details are labeled historical; current ASC/RevenueCat dashboards could not be verified.
- Initially added Halloween 2026 Event Annual locally at €14.99 in `Shield.storekit`; one year, same local subscription group, Family Sharing parity with Annual, no introductory offer. Follow-up task 207 changes this to the reusable `com.romerodev.shield.pro.annual.event` product for all campaigns.
- Added pure StoreKit metadata validation for ID, annual period, group/level, no Event introductory offer and actual 45–55% discount. Event paywall is for confirmed Free users only; standard fallback covers missing RC Offering/packages, StoreKit data or price/group mismatch. The displayed price and rounded saving come from StoreKit localized Product data.
- Hardened entitlement source: ignored legacy `shield.isPro` UserDefaults on startup; only RevenueCat CustomerInfo entitlement grants production Premium. CustomerInfo verification failure is rejected. Foreground reconciliation, Settings restore, native offer-code sheet and verified RevenueCat `syncPurchases()` reconciliation were added.
- Added schedule boundary publication independent of selected visual theme so an open paywall refreshes when a campaign starts/ends. Added conditional trial disclosure based on RevenueCat’s eligibility result.
- The initial audit proposed campaign-specific products for price-cohort isolation. Follow-up task 207 supersedes that decision at the user's direction: all events reuse one Event Annual Product ID, accepting that Apple price decreases apply at product level to active subscribers across cohorts.
- Added the seven requested audit/configuration/financial/architecture/event/test documents in `Docs/` and unit coverage in `ShieldTests/SubscriptionExperienceTests.swift`.
- Manual actions remain: create/approve Event Annual in App Store Connect; configure same group/level, price schedule and preservation; add product/entitlement/package/`event` Offering in RevenueCat; verify restore behavior, In-App Purchase key and notifications.
- ASC credential query failed; no external dashboard mutation was attempted.
- Simulator discovery was retried before any build/install. `xcrun simctl list devices available` and `xcrun simctl list runtimes` failed because CoreSimulatorService refused/invalidated the connection and no runtimes were discoverable. Per repository instructions, do not restart or substitute a device; iPhone 18 Pro, iPhone Duo, iPad/Watch and required build/test validation remain pending device availability.
- No cache, temporary-file or build-cache cleanup has been performed.
- Final static checks passed: Swift parser accepted all changed Swift/test sources; StoreKit and localization JSON parsed; `plutil -lint` accepted the Xcode project; `git diff --check` reported no whitespace errors.
- No app build or test suite was run. Repository instructions require resolving iPhone 18 Pro/runtime before compiling; `simctl` and `xcdevice` both failed on CoreSimulatorService, and `xcdevice` returned only the connected Mac. No alternate device was substituted and no simulator was rebooted/reset. iPhone 18 Pro build/install, iPhone Duo/iPad checks, StoreKit Sandbox purchases and the remaining manual lifecycle cases are unverified.
