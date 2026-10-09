# MaskID Event Subscription Campaigns

## Campaign registry

The registry is `SeasonalThemeCatalog.definitions` in `Shield/Theme/ShieldTheme.swift`. Each monetized event reuses the single Event Annual SKU `com.romerodev.shield.pro.annual.event` and the RevenueCat Offering `event`; do not create an event-specific product or an enable/disable toggle.

| Event | Start | End | Monetized | Shared Event SKU | Target price | ASC price schedule | RevenueCat Offering |
|---|---|---|---|---|---|---|---|
| Halloween 2026 | 1 Oct 2026 00:00 device local | 1 Nov 2026 00:00 device local (exclusive) | Yes, while the window is active | `com.romerodev.shield.pro.annual.event` | 50% target; €14.99 Spain (actual localized discount is calculated from StoreKit prices) | €14.99 through 31 Oct; Standard-equivalent scheduled 1 Nov with current-price preservation, verified in all 175 storefronts | `event` configured in RevenueCat with Monthly + Event Annual |

The current Event price is €14.99/year in Spain, equalized across 175 storefronts for the active Halloween campaign. App dates control which annual plan the paywall presents; ASC independently controls what a customer can buy and what it renews at. The ASC price increase to the Standard-equivalent price on 1 Nov 2026 is scheduled with Apple’s “keep current price for existing subscribers” option and was verified in 175 storefronts. A campaign buyer keeps the `MaskID Pro` entitlement after the event and renews at the preserved Event price while eligible under Apple’s rules; someone who subscribes after the scheduled increase pays the Standard-equivalent price. The same generic product and `event` Offering serve future monetized events.

## Automatic, dynamic paywall behavior

- `SeasonalThemeResolver` derives the active event from its date window, independently of the user’s selected visual theme. There is no daily activation/deactivation task and no manual campaign switch.
- At a scheduled start/end, `SeasonalThemeCoordinator` publishes the new campaign state and `ContentView` refreshes RevenueCat packages. An already open paywall updates after product and StoreKit validation finishes; an inactive window uses the standard Offering.
- Foregrounding the app, midnight, a significant clock change, and a time-zone change also recalculate the schedule.
- The paywall changes which purchase plan it presents; it does not open itself as an unsolicited popup.
- Event Annual is shown only when the `event` Offering and expected packages exist, StoreKit returns the shared Event and Standard Annual products, and the product/group/level/term/price checks pass. Any failure falls back to Standard.
- Campaign dates and metadata currently ship in the app catalog. Adding a future event means adding its window and monetization metadata and releasing an app update. Once that schedule is installed, transitions are automatic. There is not yet a remote campaign service that lets a dashboard change the app’s event dates without an app release.

## Shared product and renewal behavior

Every event uses the same ASC product, RevenueCat product, Offering, annual package, and `MaskID Pro` entitlement. Event Annual and Standard Annual are in the same subscription group and service level. Campaign IDs remain separate for attribution.

The shared SKU can have one live App Store price at a time. For each event, schedule the Event price for its start and a Standard-equivalent price after its end. At the end increase, preserve existing subscribers. Apple permits only one pending change per storefront and billing plan. A later price decrease automatically lowers renewals for all active subscribers on that product; Apple does not let the developer preserve the higher price for existing subscribers on a decrease. Thus one reusable product cannot guarantee separate renewal-price cohorts if later campaigns use a lower price than some current subscribers. Keep the campaign target stable and verify each territory before activating its paywall. Apple’s [subscription pricing rules](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/) govern these effects.

Apple also lets customers view and change subscriptions from the system/App Store subscription management page. Since Standard and Event are same-group, same-level, one-year plans, do not assume hiding Event in the app removes it from Apple’s subscription-management path. The price schedule is what prevents a discounted new acquisition outside the campaign: Event is Standard-priced between events. Apple’s subscription groups enable plan changes within a group; see [subscription plan and group behavior](https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/auto-renewable-subscription-information/) and [managing subscriptions on iPhone](https://support.apple.com/en-by/guide/iphone/iph4e3e7324f/ios).

## Campaign runbook

1. Add the event window, campaign ID, and shared Event Offering/discount target to the app catalog. An installed schedule switches the paywall automatically at its boundaries; new campaign dates currently require an app release.
2. Before the start, set the shared ASC product to the Event target in every available storefront. Before the end, schedule the Standard-equivalent price with “keep current price for existing subscribers.” Check the one-future-change-per-storefront limit and avoid replacing another pending change.
3. Confirm ASC review readiness/availability and RevenueCat’s product attachment to `MaskID Pro` and Offering `event` alongside Monthly.
4. Check StoreKit’s localized Event and Standard prices, annual term, matching group/level, and absence of an Event introductory offer. Do not show a fabricated discount if the actual localized price misses the target guard band.
5. Validate Sandbox purchase, entitlement, restore, price cohort, and automatic start/end transition before publicizing the schedule. Keep the product and entitlement mapping after an event ends so existing renewals continue.

ASC price changes do **not** follow the app’s date schedule by themselves. The paywall switch is automatic after the app has the dates; the product price schedule must separately be entered in ASC in advance. The app falls back to Standard if price and campaign dates are out of sync.

## Current external state (8 October 2026)

- App Store Connect product `6820383062` exists as `com.romerodev.shield.pro.annual.event`, one year, group level 1, €14.99 in Spain, 175 storefronts, no introductory offer, and Family Sharing off. The promotional image and genuine 1206×2622 iPhone 18 Pro App Review screenshot are uploaded (`COMPLETE`). Product state is `READY_TO_SUBMIT`; strict validation has one blocker: the first subscription must be attached to a new app-version review. Evidence: [`event-review-screenshot-upload.json`](../audit/event-review-screenshot-upload.json) and [`subscriptions-validation-event-review.json`](../audit/subscriptions-validation-event-review.json).
- RevenueCat product `prod2ef37965ba` in project `bbe3f3db` is attached to the `MaskID Pro` entitlement and Offering `event` (`ofrngbe0d32124e`). The Offering has `$rc_annual` → Event Annual and `$rc_monthly` → existing Monthly; `default` remains current. RevenueCat reports `Ready to Submit`; there are no transactions yet.
- The campaign paywall path is configured, but sales and full production verification still await Apple review, a new app-version submission, and Sandbox purchase/renewal tests. Until StoreKit exposes the approved product with matching price, the client safely falls back to Standard.

## Failure behavior

| Condition | Paywall behavior |
|---|---|
| Schedule inactive, upcoming, or ended | Standard Offering |
| User already has active `MaskID Pro` | No Event acquisition offer |
| RevenueCat `event` Offering missing or missing Monthly/Event package | Standard Offering |
| StoreKit product unavailable, wrong ID/term/group/level, or Event intro offer configured | Standard Offering |
| Localized price misses campaign guard band | Standard Offering with fallback reason |
| StoreKit or RevenueCat unavailable | Cached Standard packages if available; otherwise retry/unavailable state |

## Next campaign template

Add a catalog entry with campaign ID, explicit time zone, start/end, seasonal definition, compatible discount target, and Offering ID `event`. Reuse `com.romerodev.shield.pro.annual.event`. An installed schedule switches the paywall automatically, but a new schedule currently requires an app release and coordinated ASC price changes. Do not enable the Event paywall until its StoreKit price matches the target.
