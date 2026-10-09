# RevenueCat Configuration — MaskID

**Status (8 October 2026):** The MaskID project is `bbe3f3db`. Its existing `default` Offering and `MaskID Pro` entitlement were preserved. Event product `prod2ef37965ba` (`com.romerodev.shield.pro.annual.event`) is attached to `MaskID Pro` and included in Offering `event` (`ofrngbe0d32124e`). That Offering contains `$rc_annual` → Event Annual and `$rc_monthly` → the existing Monthly product. `default` remains current. ASC reports Event Annual `READY_TO_SUBMIT`; RevenueCat shows `Ready to Submit`, so Apple review and Sandbox purchase verification remain pending.

## Store and project

- RevenueCat SDK in `Package.resolved`: `purchases-ios` 5.81.1. The app configures it from `RevenueCatAPIKey` in Info.plist and uses an anonymous App User ID; never put the secret App Store key in app code.
- RevenueCat 5.x StoreKit 2 transaction processing uses the App Store In-App Purchase key configured in the RevenueCat App Store app connection. Confirm its status and server notifications in the dashboard.
- Keep entitlement identifier `MaskID Pro` matched to `RevenueCatEntitlementIdentifier` in the shipped app configuration.
- Inspect restore behavior against the no-login identity model before changing it. “Transfer to new App User ID” is a likely fit for anonymous app users, but inspect ownership history first.

## Product and entitlement map

| App Store product | RevenueCat entitlement | Offering/package | Current state |
|---|---|---|---|
| `com.romerodev.shield.pro.monthly` | `MaskID Pro` | `default` / `$rc_monthly`; also `event` | Existing product; keep standard flow |
| `com.romerodev.shield.pro.annual` | `MaskID Pro` | `default` / `$rc_annual` | Existing Standard Annual; preserve trial eligibility |
| `com.romerodev.shield.pro.lifetime.unlock` | `MaskID Pro` | `default` / `$rc_lifetime` | Existing one-time product; preserve |
| `com.romerodev.shield.pro.annual.event` | `MaskID Pro` | `event` / `$rc_annual` | Attached; store status `Ready to Submit`, awaiting Apple review |

The client selects Event Annual by the underlying Store product ID and validates StoreKit metadata. Package identifiers should be stable and compatible with the existing resolver.

## Offerings

### `default`

Keep `default` assigned as the current Offering with the existing Monthly, Standard Annual, and Lifetime packages. Do not replace its standard purchase path.

### `event`

Offering `event` (`ofrngbe0d32124e`, display name `MaskID Pro Event`) in project `bbe3f3db` contains:

- the existing Monthly product `com.romerodev.shield.pro.monthly`;
- the shared Event Annual product `com.romerodev.shield.pro.annual.event`.

Event Annual is attached to the existing `MaskID Pro` entitlement. It is not attached to a new entitlement, Standard Annual is unchanged, and `event` is not the project’s current Offering. The app requests `event` only while a monetized event schedule is active; outside that window it uses `default`. Lifetime remains available from the existing default package in the Event paywall.

RevenueCat Paywall UI is not required; MaskID uses custom SwiftUI paywalls. Placements, targeting, experiments, Customer Center, webhooks, App Store key state, and restore behavior remain unverified.

## Trial and offer behavior

- The checked-in StoreKit fixture has a seven-day trial for Standard Annual. The paywall shows a trial only when RevenueCat reports eligibility for the selected package.
- Event Annual has no introductory offer. Its €14.99 Spain price is the current Halloween campaign price. App Store price schedules must separately return the product to the Standard-equivalent price after an event for new buyers; end-of-event price increases preserve the current subscriber price under Apple’s rules. RevenueCat Offering selection only changes which product the app presents and cannot alter App Store pricing.
- Offer codes and promotional/win-back offers are separate App Store/RevenueCat features; they are not needed to switch the seasonal paywall.
- In-app Apple offer-code redemption syncs with RevenueCat only after a verified transaction. External redemption recovery uses CustomerInfo refresh and the explicit Restore Purchases action.

## Restore and identity

- Keep `restorePurchases()` behind explicit user actions in Settings and on the paywall.
- Do not add RevenueCat `logIn`/`logOut` unless MaskID adds a real account system and a deliberate identity migration.
- Verify anonymous-to-new-ID restore transfers and family-shared ownership without changing live behavior blindly.
- Keep the RevenueCat entitlement ID stable. Existing Product IDs remain unchanged.

## Required completion checks

1. **Complete:** Event product is attached to `MaskID Pro`; Offering `event` has the existing Monthly and shared Event Annual packages. `default` is still current.
2. **Complete:** Event Annual has no trial/introductory offer and matches Standard Annual’s group/level/term in ASC.
3. After Apple approves the product and a compatible app build is available, run Sandbox purchase, CustomerInfo entitlement, restore, and renewal-after-window checks.
4. Verify App Store key, notifications, restore behavior, and any webhook destinations; record unknowns instead of inferring them from app code.

### RevenueCat references

- [Offerings overview](https://www.revenuecat.com/docs/offerings/overview)
- [Restoring purchases](https://www.revenuecat.com/docs/getting-started/restoring-purchases)
- [Restore Behavior](https://www.revenuecat.com/docs/projects/restore-behavior)
- [CustomerInfo caching](https://www.revenuecat.com/docs/test-and-launch/debugging/caching)
- [iOS subscription offers and offer-code redemption](https://www.revenuecat.com/docs/subscription-guidance/subscription-offers/ios-subscription-offers)
- [App Store In-App Purchase key configuration](https://www.revenuecat.com/docs/service-credentials/itunesconnect-app-specific-shared-secret/in-app-purchase-key-configuration)
