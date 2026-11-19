# RevenueCat Configuration — MaskID

**Current status (18 November 2026):** The MaskID project is `bbe3f3db`. The `default` Offering remains current and contains only the `$rc_lifetime` package for sale. Monthly and annual subscription products were detached from purchase packages. The `event` Offering (`ofrngbe0d32124e`) was archived and its packages detached. The existing `MaskID Pro` entitlement and all historic product associations remain intact, so current paid periods, prior purchases, and restores continue to resolve. Sandbox purchase/restore checks remain outstanding.

## Store and project

- RevenueCat SDK in `Package.resolved`: `purchases-ios` 5.102.3 (latest release checked on 8 November 2026). The app configures it from `RevenueCatAPIKey` in Info.plist and uses an anonymous App User ID; never put the secret App Store key in app code.
- RevenueCat 5.x StoreKit 2 transaction processing uses the App Store In-App Purchase key configured in the RevenueCat App Store app connection. Confirm its status and server notifications in the dashboard.
- Keep entitlement identifier `MaskID Pro` matched to `RevenueCatEntitlementIdentifier` in the shipped app configuration.
- Inspect restore behavior against the no-login identity model before changing it. “Transfer to new App User ID” is a likely fit for anonymous app users, but inspect ownership history first.

## Product and entitlement map

| App Store product | RevenueCat entitlement | Offering/package | Current state |
|---|---|---|---|
| `com.romerodev.shield.pro.monthly` | `MaskID Pro` | No purchase package | Historical subscription; ASC retired from sale; retained in entitlement |
| `com.romerodev.shield.pro.annual` | `MaskID Pro` | No purchase package | Historical subscription; ASC retired from sale; retained in entitlement |
| `com.romerodev.shield.pro.lifetime.unlock` | `MaskID Pro` | `default` / `$rc_lifetime` | Only product offered for sale; ASC non-consumable, Spain base price €9.99 |
| `com.romerodev.shield.pro.annual.event` | `MaskID Pro` | No purchase package | Historical subscription; ASC retired from sale; retained in entitlement |

Monthly, Annual, and Event Annual Product IDs remain only for historical entitlement recognition. The app purchase resolver now accepts only Lifetime.

## Offerings

### `default`

`default` stays current with the Lifetime package only. Its former monthly and annual packages are empty and detached so the app cannot retrieve those plans for a new purchase.

### `event`

The historical Offering `event` (`ofrngbe0d32124e`, display name `MaskID Pro Event`) in project `bbe3f3db` is archived and has no purchase packages. The historical product associations remain on the entitlement to preserve already-granted access.

Before retirement, Offering `event` contained:

- the existing Monthly product `com.romerodev.shield.pro.monthly`;
- the shared Event Annual product `com.romerodev.shield.pro.annual.event`.

Event Annual is attached to the existing `MaskID Pro` entitlement. It is not attached to a new entitlement, Standard Annual is unchanged, and `event` is not the project’s current Offering. The app requests `event` only while a monetized event schedule is active; outside that window it uses `default`. Lifetime remains available from the existing default package in the Event paywall.

RevenueCat Paywall UI is not required; MaskID uses custom SwiftUI paywalls. Placements, targeting, experiments, Customer Center, webhooks, App Store key state, and restore behavior remain unverified.

## Trial and offer behavior

- The annual introductory offer was removed from ASC on 8 November 2026 after owner approval; ASC list verification and RevenueCat's refreshed store state both show no current introductory offer. The checked-in StoreKit fixture also has no intro offer.
- Removing an offer prevents it from being presented to new eligible purchasers; it does not rewrite completed purchases, existing subscriptions or transactions already granted an introductory period. Apple continues to control each existing transaction's terms.
- No subscription products are exposed through an active Offering. ASC has retired all three subscription products from sale; RevenueCat keeps their entitlement mappings for existing customers only.
- Lifetime uses Apple's localized storefront price. Its Spain base price is €9.99.
- Lifetime is a non-consumable and has no in-app offer-code redemption path. Restore purchases remains available from Settings and the paywall.

## Restore and identity

- Keep `restorePurchases()` behind explicit user actions in Settings and on the paywall.
- Do not add RevenueCat `logIn`/`logOut` unless MaskID adds a real account system and a deliberate identity migration.
- Verify anonymous-to-new-ID restore transfers and family-shared ownership without changing live behavior blindly.
- Keep the RevenueCat entitlement ID stable. Existing Product IDs remain unchanged.

## Required completion checks

1. **Complete:** current `default` Offering exposes only Lifetime; the event Offering is archived with empty packages.
2. **Complete:** all three ASC subscriptions are retired from sale and the `MaskID Pro` entitlement mappings are preserved.
3. Before release, run Sandbox Lifetime purchase, historical entitlement restore, and hard-paywall scenarios. Confirm no offer-code redemption control is present.
4. Verify App Store key, notifications, restore behavior, and any webhook destinations; record unknowns instead of inferring them from app code.

### RevenueCat references

- [Offerings overview](https://www.revenuecat.com/docs/offerings/overview)
- [Restoring purchases](https://www.revenuecat.com/docs/getting-started/restoring-purchases)
- [Restore Behavior](https://www.revenuecat.com/docs/projects/restore-behavior)
- [CustomerInfo caching](https://www.revenuecat.com/docs/test-and-launch/debugging/caching)
- [App Store In-App Purchase key configuration](https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret/in-app-purchase-key-configuration)
