# MaskID Subscription Architecture

## Authority and boundaries

```text
SeasonalThemeCatalog schedule + campaign config
                 │
                 ▼
PremiumManager.loadProducts()
       ┌─────────┴─────────┐
       │                   │
RevenueCat Offerings   StoreKit Product metadata
       │                   │
RevenueCat Package      localized price, duration,
for purchase            group, level, intro offer
       └─────────┬─────────┘
                 ▼
AnnualEventPriceValidator + campaign resolver
         valid → Event paywall     invalid → Standard
                 │
                 ▼
RevenueCat purchase / restore / syncPurchases
                 │
                 ▼
RevenueCat CustomerInfo entitlement “MaskID Pro”
                 │
                 ▼
PremiumManager.isPro → feature gates and app state
```

- **Keep:** `PremiumManager`, RevenueCat `Package` purchases, `CustomerInfo` delegate, custom SwiftUI paywalls, `SeasonalThemeCoordinator`, and the `MaskID Pro` entitlement.
- **Do not add:** a second subscription manager, StoreKit purchase flow, local premium ledger, login identity or backend entitlement service.
- `RevenueCat CustomerInfo.entitlements[MaskID Pro].isActive` is the only production authorization source. Ignore the legacy `shield.isPro` UserDefaults value on startup. RevenueCat’s SDK cache can provide an offline `CustomerInfo` response; local booleans do not grant access.
- StoreKit 2 is used to fetch native product metadata and localized `displayPrice`, compare the Event and Standard annual products, and display Apple’s offer-code redemption sheet. RevenueCat remains responsible for purchase transactions, restore, identity and Premium entitlement.

## Product loading and campaign resolution

1. Read the current RevenueCat Offering for Standard Annual, Monthly and Lifetime.
2. Resolve the single currently scheduled campaign from `SeasonalThemeResolver`, independent of the user’s selected visual theme. Its start and end dates automatically control paywall merchandising; there is no campaign on/off toggle.
3. If the event is active, look up its RevenueCat Offering and the shared `ShieldProduct.annualEvent` product.
4. Require the expected Monthly and Event Annual packages. Fetch Standard and Event StoreKit Products.
5. Validate IDs, one-year duration, same non-empty subscription group, same group level, no Event introductory offer, and a price within five percentage points of the active event’s configured discount target (50% by default).
6. Require a resolved RevenueCat CustomerInfo snapshot that confirms Free access. An unresolved status is not assumed Free; purchases and Event merchandising remain disabled until retry/restore resolves it.
7. For a confirmed Free user only, show Monthly + Event Annual + the existing Lifetime package. Display StoreKit localized prices, the actual computed discount, and the standard price as a comparison. Do not show Standard Annual in that event selector.
8. If any campaign condition fails, show the normal current Offering. RevenueCat or StoreKit failures never cause a fabricated discount or StoreKit-only purchase.

`SubscriptionExperience.swift` contains value snapshots and pure validation/resolution. `PremiumManager` coordinates the existing services. `SeasonalThemeCoordinator.activeScheduledThemeID` changes at schedule boundaries even when a Pro user selected a different theme; `ContentView` refreshes product configuration, allowing an already-open paywall to switch to Standard when an event ends.

## Product/entitlement map

| Product | Entitlement | Duration | Same group/level | Trial/offer |
|---|---|---|---|---|
| `com.romerodev.shield.pro.monthly` | `MaskID Pro` | 1 month | Existing group; live level must be confirmed | No fixture intro offer |
| `com.romerodev.shield.pro.annual` | `MaskID Pro` | 1 year | Baseline for Event; confirm live level | Local 7-day free-trial fixture; eligibility from RevenueCat |
| `com.romerodev.shield.pro.lifetime.unlock` | `MaskID Pro` | Non-consumable | Not a subscription group product | One-time purchase |
| `com.romerodev.shield.pro.annual.event` | `MaskID Pro` | 1 year | Must match Standard Annual | One shared ordinary auto-renewable product for all events; no intro offer |

An Event Annual purchaser keeps that subscription and its entitlement after the app’s campaign window ends. The campaign hides Event Annual from the app’s paywall after expiry; it does not cancel or replace a customer’s subscription.

## Purchase, restore and lifecycle

- Purchases use the RevenueCat `Package` from the relevant Offering. The app does not directly call StoreKit `Product.purchase()`.
- Restore uses `Purchases.shared.restorePurchases()` from the paywall or Settings. Manage/cancel/upgrade is handed to Apple’s subscription-management sheet.
- Verified in-app offer-code redemption invokes RevenueCat `syncPurchases()` and applies the returned CustomerInfo. An unverified result is not synced or granted access.
- On foreground, re-fetch CustomerInfo and refresh lifecycle data. The SDK delegate also applies changed CustomerInfo.
- `expirationDate`, `willRenew`, and `ownership` are status display/telemetry facts; feature access still follows active entitlement.
- A billing issue does not revoke access while RevenueCat says the entitlement is active. Do not report “grace period” unless RevenueCat/Apple data actually confirms it.
- Family Sharing uses the same entitlement when the App Store transaction is identified by RevenueCat as family-shared. It is not a separate paid family plan.

## Identifiers and configuration

Current product IDs are centralized in `ShieldProduct`; every monetized campaign uses the same `com.romerodev.shield.pro.annual.event` ID and the same local StoreKit product. Keep the ID identical to ASC and RevenueCat. For a new campaign, add its schedule, campaign ID and discount target to the catalog; reuse the `event` Offering and existing product mapping. The time window selects the paywall automatically. Never create an event-specific product ID or mutate a shipped Product ID.

The shared App Store product now exists at €14.99/year in Spain, but is not approved because ASC still needs its review screenshot. The RevenueCat product exists but is not attached to the `MaskID Pro` entitlement and is not in Offering `event`. Until those external steps and Sandbox verification finish, the app correctly falls back to Standard. See [ASC checklist](APP_STORE_CONNECT_SUBSCRIPTIONS.md) and [RevenueCat configuration](REVENUECAT_CONFIGURATION.md).

## Automatic transitions, rollout and rollback

1. Upload the genuine ASC review screenshot and obtain an approved/available state. The 1 Nov Standard-price return and subscriber price preservation are already scheduled and verified.
2. In RevenueCat, attach the Event product to the existing entitlement and add it to Offering `event` with Monthly. Keep `default` current and unchanged.
3. Confirm Sandbox product lookup, one-year term, group/level, price and Family Sharing.
4. The app automatically selects Event when an installed schedule becomes active and all product checks pass. At the window end, it returns to Standard. The App Store price and active Event subscriptions continue independently.
5. Run the test matrix in Sandbox and TestFlight before publishing marketing; observe paywall impressions, fallback reasons, purchases, cancellations, renewals and refunds.
6. No daily campaign action is needed. Campaign dates/metadata ship in the app catalog, so adding a new event currently requires an app release. Keep the ASC product and RC entitlement mapping for existing renewals; do not delete them.

## Known limitation

ASC price schedules apply to the product and storefront, independently of the app paywall. For each campaign, the Event product needs a discounted price at campaign start and a standard-equivalent price after campaign end for new purchases. On the end increase, select Apple’s “keep current price for existing subscribers” behavior so event buyers retain their recorded price while their subscription remains eligible. Apple allows one future change at a time per storefront and billing plan, so configure the next campaign transition only after checking the current schedule. Price cohorts are product-level, not per campaign. App dates switch the paywall automatically, but they do not change App Store prices. If the StoreKit price is out of the campaign guard band, the app falls back to Standard instead of advertising a false discount. See [campaign price scheduling](SUBSCRIPTION_EVENT_CAMPAIGNS.md).
