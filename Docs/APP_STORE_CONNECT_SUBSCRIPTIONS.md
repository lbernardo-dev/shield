# App Store Connect Subscription Configuration

**Status (8 October 2026):** The generic Event Annual subscription has been created and its App Review screenshot is uploaded with delivery `COMPLETE`. ASC now reports `READY_TO_SUBMIT`, not approved/available for sale. Strict validation has no metadata or pricing defects; its one blocking warning says the first subscription must be included in the next app-version review. There is no draft app version yet (`1.1.2` is already live).

## Existing products and the shared Event SKU

| Product ID | Type / duration | Group / level | Spain price | Availability / sharing | Current status |
|---|---|---|---:|---|---|
| `com.romerodev.shield.pro.monthly` | Auto-renewable / 1 month | `MaskID Pro` | €2.99 | Existing product; Family Sharing off in fixture | Approved |
| `com.romerodev.shield.pro.annual` | Auto-renewable / 1 year | `MaskID Pro`, level 1 | €29.99 | 175 storefronts; Family Sharing off | Approved; existing 7-day trial |
| `com.romerodev.shield.pro.lifetime.unlock` | Non-consumable | Outside group | €49.99 listing/fixture | Existing local product; ASC not audited here | Existing |
| `com.romerodev.shield.pro.annual.event` | Auto-renewable / 1 year | `MaskID Pro`, level 1 | **€14.99** | 175 storefronts; Family Sharing off | `READY_TO_SUBMIT`; awaiting app-version review, not approved |

Event Annual ASC subscription ID: `6820383062`. Group ID: `22231170`. Reference name: **MaskID Pro Annual Event**; subscription display name: **MaskID Pro Annual Event** (en-US) / **MaskID Pro Anual de Evento** (es-ES). The product has no introductory offer. Its current price was equalized from Spain at €14.99 in 175 storefronts for the active Halloween event. A 1 November 2026 price increase back to the Standard Annual price was scheduled with Apple’s current-price preservation option and read-back verified for all 175 storefronts. Localizations, availability, price coverage, and screenshot delivery are complete.

The Event product’s Spanish and US localizations have been added. A generic 1024×1024 MaskID promotional image is uploaded to the subscription version (`a8396cf8-e9e0-47cd-9225-b08aecc1be8a`, delivery `COMPLETE`). The genuine 1206×2622 paywall screenshot from the iPhone 18 Pro is uploaded as review screenshot `c9f241d9-f194-4178-8661-0db687092bc6` (delivery `COMPLETE`); source: [`event-annual-review-iphone-18-pro.png`](../audit/event-annual-review-iphone-18-pro.png). Do not claim the product is approved or available for sale until Apple finishes review.

## Product configuration already applied

- Product ID: `com.romerodev.shield.pro.annual.event`.
- Reference name: **MaskID Pro Annual Event**.
- Duration: **1 year**.
- Group and level: **MaskID Pro**, level **1**, matching Standard Annual.
- Current Spain price: **€14.99/year**; equalized availability/price points across 175 storefronts.
- Family Sharing: **off**, matching Standard Annual.
- Introductory offer: **none**.
- Promotional image: generic MaskID app artwork uploaded and delivery verified.
- App Review screenshot: real Event Annual paywall uploaded and delivery verified (`COMPLETE`).
- Availability includes 175 storefronts, including new territories.

## Remaining App Store Connect work

1. Create and stage a new iOS app version with the build containing the generic automatic Event paywall, then attach Event Annual to that first app-version review. The live version `1.1.2` is already `READY_FOR_SALE`; no editable draft exists.
2. Submit the assembled app version and subscription for review, then wait for Apple’s decision. The product is `READY_TO_SUBMIT`, not approved or live yet.
3. **Complete:** Standard-equivalent price is scheduled for 1 Nov 2026 across 175 storefronts with current-price preservation; ASC read-back verified 175/175. Evidence: [`event-end-price-apply.json`](../audit/event-end-price-apply.json).
4. Do not remove or change the existing Monthly, Standard Annual, or Lifetime Product IDs.

Apple’s review screenshot is a review artifact for the subscription. See [Subscription App Store Review Screenshots](https://developer.apple.com/documentation/appstoreconnectapi/subscription-app-store-review-screenshots?changes=l_1).

Apple requires the first auto-renewable subscription to be submitted together with a new app version. See [Submit an In-App Purchase](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/).

## Price and campaign behavior

The app paywall schedule changes annual product presentation automatically at event boundaries; it does not change the App Store price. ASC needs a separate price schedule prepared in advance. For Halloween 2026, the €14.99 Event price runs through the campaign end; the Standard-equivalent price starts 1 Nov for new buyers while preserving the price for existing subscribers. ASC read-back verified the change in all 175 storefronts.

Apple allows one future price change per storefront and plan. A price decrease lowers renewals for all current subscribers, with no option to preserve a higher price; an end-of-event price increase can preserve each current subscriber’s price. A preserved-price subscriber who expires may resubscribe at that price within 60 days; after that, the then-current price applies. See [Manage pricing for auto-renewable subscriptions](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/).

## Campaign date alignment

The app catalog currently uses 1 Oct 2026 00:00 through 1 Nov 2026 00:00 in each device’s local calendar. A previous project record described the App Store In-App Event as 1 Oct through 31 Oct 2026 23:00 Europe/Madrid; that is historical project evidence, not verified live ASC state. App paywall boundaries are therefore determined by the shipped catalog’s device-local dates, not by an ASC price schedule.

### Apple references

- [Manage pricing for auto-renewable subscriptions](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/)
- [Subscription App Store Review Screenshots](https://developer.apple.com/documentation/appstoreconnectapi/subscription-app-store-review-screenshots?changes=l_1)
- [Turn on Family Sharing for in-app purchases](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases/)
- [App Store subscriptions](https://developer.apple.com/app-store/subscriptions/)
