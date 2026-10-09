# Subscription, Finance & Monetization Audit — MaskID

**Audit date:** 7 October 2026; dashboard follow-up: 8 October 2026
**Scope:** repository, local StoreKit configuration, public Spain storefront, RevenueCat integration code and available project history.
**Evidence:** repository and public storefront review; App Store Connect and RevenueCat setup/verification on 8 October. Event Annual is in RevenueCat with its entitlement and `event` Offering; ASC has a complete review screenshot and reports `READY_TO_SUBMIT`. First app-version review/approval and Sandbox purchase verification remain pending.

## A. Executive summary

MaskID is a privacy utility for preparing identity and other sensitive documents for sharing. The existing system already uses a single `PremiumManager`, RevenueCat Offerings/Packages, a custom SwiftUI paywall, and `SeasonalThemeCoordinator`. Keep and evolve these components; do not introduce another purchase manager or run StoreKit purchases independently of RevenueCat.

The Spain listing and local StoreKit fixture show €2.99/month, €29.99/year, and €49.99 lifetime. Preserve these identifiers and prices. The local annual fixture has a seven-day introductory trial; eligibility is checked by RevenueCat. The old paywall text claimed that every visitor received a trial even when they were not eligible; it now shows the trial disclosure only for a selected product RevenueCat confirms eligible.

The campaign system uses one generic Annual Event product shared by Halloween 2026 and future events. The app automatically selects it only for confirmed Free users during an event’s catalog time window, after StoreKit confirms a one-year term, the same group/level as Standard Annual, no introductory offer, and a discount within five percentage points of the campaign target. It displays StoreKit’s localized prices and computed discount. Any missing Offering/product, StoreKit lookup failure, or mismatch falls back to Standard. The app calendar controls paywall presentation; App Store Connect separately schedules the campaign price and its post-event return to Standard for new buyers.

**The campaign is not commercially live.** ASC product `6820383062` is `READY_TO_SUBMIT`, with the review screenshot, localizations, 175 storefront prices and availability complete. Strict validation now reports one review blocker: the first subscription must join the next app-version review; no draft version exists, and `1.1.2` is already live. The 1 Nov Standard-equivalent price return is scheduled with current-price preservation and verified in all 175 storefronts. RevenueCat product `prod2ef37965ba` is attached to entitlement `MaskID Pro` and Offering `event`. The app should continue falling back to Standard until Apple approves the product and StoreKit confirms the live price.

## B. Business model and product fit

| Dimension | Assessment |
|---|---|
| Category | Privacy, document scanning and sensitive-data redaction utility |
| Target user | Individuals and independent professionals who share identity, financial, health, employment or administrative documents |
| Core value | Detect or select sensitive regions, redact them locally, inspect the result, and export a safer copy |
| Use frequency | Low to medium for consumers; medium to high for recruiters, landlords, legal/financial administrators and small businesses. Validate with product analytics. |
| Time to value | Immediate, in the first document workflow |
| Retention | Naturally episodic; annual renewal depends on repeat document needs and saved workflow value, not continuous content consumption |
| Marginal cost | Core OCR/redaction runs on device. Optional iCloud sync has storage/support cost. No per-document AI API cost was found in the audited core flow. Cloud and support costs still need actual account data. |
| Premium value | Higher document allowance, batch processing, premium styles/modes, image adjustments, optional cloud workflow, seasonal themes and customization |
| Price sensitivity | Medium/high for occasional personal use; lower for users who repeatedly handle sensitive paperwork |
| Family potential | Low. Documents and privacy workflows are personal. Keep existing Family Sharing where already enabled; do not add a Family tier without demand evidence. |

These are product hypotheses. Measure repeat use, renewal, churn, refund, trial conversion and segment-level willingness to pay before changing the catalog.

Public source for current Spain prices and MaskID positioning: [MaskID — App Store Spain](https://apps.apple.com/es/app/maskid-protege-datos-privados/id6790398619).

## C. Current monetization inventory

| Element | Repository/public evidence | Status and action |
|---|---|---|
| Monthly | `com.romerodev.shield.pro.monthly`, €2.99 Spain; one month; local fixture is not Family Shareable | KEEP; do not change ID |
| Standard Annual | `com.romerodev.shield.pro.annual`, €29.99 Spain; one year; 7-day trial; Family Sharing off | KEEP; ASC inspection verified approved, group `MaskID Pro` ID `22231170`, level 1, all regions, no upcoming price changes |
| Lifetime | `com.romerodev.shield.pro.lifetime.unlock`, €49.99 Spain; non-consumable; local fixture Family Shareable | KEEP; preserve current owners and restore path |
| Annual Event (shared across events) | `com.romerodev.shield.pro.annual.event`, €14.99/year Spain, one year, no intro offer, Family Sharing off | ASC `READY_TO_SUBMIT`, level 1, 175 storefronts and screenshot complete; RevenueCat attached to `MaskID Pro` and shared Offering `event` |
| Subscription Group | `MaskID Pro`, ASC ID `22231170` | Event product verified at the same level 1 as Standard Annual |
| Entitlement | Code reads RevenueCat entitlement `MaskID Pro` (Info.plist can override) | Existing entitlement; both standard and Event products attached |
| Default Offering | RevenueCat dashboard shows active `default` with three packages | KEEP; preserve standard purchase path |
| Event Offering | Code requests identifier `event`; expects Monthly and shared Event Annual packages | Configured as `ofrngbe0d32124e`; `default` remains current |
| Paywalls | Custom SwiftUI paywalls in main app and onboarding | KEEP; Event Annual replaces Standard Annual only when validated |
| Restore/manage | RevenueCat restore in paywall; Settings now has restore and Apple offer-code entry; Settings also opens Apple subscription management | KEEP and exercise both paths |
| Placements, experiments, Customer Center, webhooks | No definitive live dashboard evidence available | Dashboard state unverified; do not claim configured |
| Intro/promotional/win-back offers | Seven-day annual introductory offer exists in the local fixture; other live offers unverified | No Event Annual intro offer; disclose only live eligibility |

## D. Findings and disposition

| Finding | Classification | Action |
|---|---|---|
| Existing RevenueCat purchase/restore and custom paywalls | KEEP | Reuse current `PremiumManager` and package purchase path |
| Boolean `shield.isPro` persisted in UserDefaults | REFACTOR | Ignore it for authorization. RevenueCat CustomerInfo entitlement is the only Premium authority; keep a boolean only for legacy cleanup if needed |
| StoreKit and RevenueCat could otherwise become competing authorities | IMPROVE | StoreKit 2 supplies product metadata/prices and its system offer-code sheet; RevenueCat purchases and CustomerInfo grant Premium |
| Trial FAQ promised seven days to all viewers | FIXED | Show only when RevenueCat reports eligibility for the selected package and use its actual duration and price |
| Restore was not available from Settings | FIXED | Add Settings restore action through RevenueCat |
| Offer-code redemption/reconciliation absent | FIXED IN APP | Add Apple’s native redemption sheet and call RevenueCat `syncPurchases()` only after a verified redemption |
| RevenueCat was not refreshed on foreground | FIXED | Re-read CustomerInfo when app returns active |
| Seasonal schedule did not refresh monetization while the paywall was open | FIXED | Publish the scheduled event independently of the selected visual theme; refresh products on boundary changes |
| No Event Annual catalog/validation | IMPLEMENTED LOCALLY | Add one shared one-year Event product, strict StoreKit validator, price comparison, discount label and standard fallback |
| ASC review state is `READY_TO_SUBMIT` | BLOCKS SALE | Include the first subscription in a new app-version review; wait for Apple’s decision |
| RevenueCat Event mapping is complete | DONE | Product is attached to `MaskID Pro` and Offering `event`; keep `default` current |
| One reusable product serves recurring events | MANAGED WITH APPLE LIMIT | Scheduled Event → Standard increase preserves current subscribers. A future decrease cannot preserve higher prices for active subscribers, so the generic product cannot guarantee separate cohorts for every campaign |
| Product is hidden from the in-app paywall outside an event | NOT A STORE-LEVEL SALES GATE | Apple’s subscription-management page exposes same-group plan changes; the Event SKU must return to Standard price outside campaign dates |

## E. Pricing and plan recommendation

Keep the existing catalog and price points pending conversion/renewal data. The annual plan costs about 16.4% less than twelve monthly payments. Lifetime recoups about 1.67 annual payments at the current prices; preserve it because it already exists and serves users who reject renewal.

Do not add Weekly: document-preparation demand is irregular, and weekly billing would likely increase churn and weaken the annual offer. Do not add a paid Family tier: the core document workflows are personal. Standard Annual and Event Annual have Family Sharing off; Lifetime remains Family Shareable in the local fixture. Keep Monthly as a lower-commitment entry, Annual as Best Value on the standard paywall, and Lifetime as a one-time alternative.

Current Event price for Spain is €14.99 against Standard Annual at €29.99, approximately 50.02% off. The display is derived from StoreKit’s localized Event and Standard products; the code never asserts 50% when another storefront yields a different value. The validator accepts prices within five percentage points of the campaign’s configured target; at the current 50% target, that is 45–55%. Event windows change product visibility in the paywall, not its Store price.

## F. Market benchmark (Spain storefront, observed listings)

| App | Observed annual range/price | Other observed price | Comparison |
|---|---:|---:|---|
| [Redacto](https://apps.apple.com/es/app/redacto-redact-blur-photos/id6774544804) | €22.99 | €2.99/month; €44.99 lifetime | Closest direct redaction comparator; product scope and offer terms differ |
| [Adobe Scan](https://apps.apple.com/es/app/adobe-scan-esc%C3%A1ner-pdf-y-ocr/id1199564834) | €22.99–€74.99 | €4.49–€10.99/month | Multiple tiers and Adobe ecosystem; not like-for-like |
| [PDF Scanner, Editor OCR](https://apps.apple.com/es/app/pdf-scanner-editor-ocr-scan/id1552902248) | €29.99–€44.99 | €7.49/month | Broader scanner/OCR bundle |
| [PDF Expert](https://apps.apple.com/es/app/pdf-expert-editar-documentos/id743974925) | €44.99–€52.99 iOS tiers; €84.99 Mac+iOS bundle | €10.99/month | Full PDF editing and cross-platform tiers |

In this observed sample, the annual low is €22.99, the median of selected annual tiers is approximately €39.99, and the high is €84.99 for a cross-platform bundle (about €59.99 for a standalone upper annual tier). Prices, currencies, promotions and product bundles can change; storefront listings are not equivalent products. MaskID’s €29.99 sits below the selected sample median and above the closest direct competitor’s €22.99. Keep it unless conversion/retention data show a problem; no automatic 5–20% undercut is justified.

## G. Family, account, legacy and lifecycle

- The app has a local user profile, not a subscription account identity. No RevenueCat `logIn`/`logOut` path was found; purchases use RevenueCat’s anonymous App User ID.
- Preserve the `MaskID Pro` entitlement and all three current product IDs. Do not delete/rename them or require repurchase.
- The Standard Annual fixture and live ASC both have Family Sharing off. The generic Event fixture should match that setting. Lifetime is locally Family Shareable; its live ASC setting was not audited here. Apple does not let a developer disable Family Sharing after enabling it.
- With no app account switch, “account switch” means a different Apple ID or a RevenueCat identity reset. Confirm RevenueCat Restore Behavior. For an anonymous app, RevenueCat’s Transfer-to-new-App-User-ID behavior is the likely recovery setting, but do not change the live dashboard without inspecting existing user history.
- RevenueCat CustomerInfo entitlement is authoritative for active access. StoreKit Product is used to validate duration/group/level and display localized pricing. Expiration, renewal and ownership are read from RevenueCat CustomerInfo; the app does not infer access from a UserDefaults Boolean.
- RevenueCat exposes billing issue and ownership metadata. The app continues access only while the entitlement is active; it does not invent a grace period when CustomerInfo does not identify one.

## H. Source links and manual boundary

- Apple subscription price schedules and subscriber price handling: [Manage pricing for auto-renewable subscriptions](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/)
- Apple group and subscription behavior: [Auto-renewable subscriptions](https://developer.apple.com/app-store/subscriptions/)
- Apple Family Sharing: [Turn on Family Sharing for in-app purchases](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases/)
- Apple commission terms and qualifying subscription renewals: [Apple Developer Program License Agreement](https://developer.apple.com/support/terms/apple-developer-program-license-agreement/), [App Store subscriptions](https://developer.apple.com/app-store/subscriptions/)
- StoreKit product/group/price data: [Product.SubscriptionInfo](https://developer.apple.com/documentation/storekit/product/subscriptioninfo), [groupLevel](https://developer.apple.com/documentation/storekit/product/subscriptioninfo/grouplevel), [Product.displayPrice](https://developer.apple.com/documentation/storekit/product/displayprice)
- Apple offer-code redemption: [SwiftUI offerCodeRedemption](https://developer.apple.com/documentation/swiftui/view/offercoderedemption%28options%3Aispresented%3Aoncompletion%3A%29)
- RevenueCat Offerings: [Offerings overview](https://www.revenuecat.com/docs/offerings/overview)
- RevenueCat restore and transfers: [Restoring purchases](https://www.revenuecat.com/docs/getting-started/restoring-purchases), [Restore Behavior](https://www.revenuecat.com/docs/projects/restore-behavior)
- RevenueCat cached CustomerInfo: [Caching](https://www.revenuecat.com/docs/test-and-launch/debugging/caching)

ASC setup is partial: the Event product exists, but strict validation blocks mapping until a genuine App Review screenshot is uploaded and the subscription is approved. RevenueCat setup is partial: the product exists, but the entitlement attachment and `event` Offering are not complete. See [ASC checklist](APP_STORE_CONNECT_SUBSCRIPTIONS.md) and [RevenueCat checklist](REVENUECAT_CONFIGURATION.md).
