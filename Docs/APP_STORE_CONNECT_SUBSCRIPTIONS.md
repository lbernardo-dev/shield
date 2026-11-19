# App Store Connect Subscription Configuration

**Current status (18 November 2026):** Lifetime (`6791491284`) is the only product offered in the app: a non-consumable priced at €9.99 in Spain and available in 175 territories with Apple's localized pricing. ASC shows Standard Monthly (`6790401134`), Standard Annual (`6790401098`), and Event Annual (`6820383062`) as **Developer Removed from Sale**. The owner confirmed Apple's service-through-current-paid-period attestation for existing subscribers. The historical IDs and `MaskID Pro` entitlement remain intact so existing transactions continue to grant access.

The catalog tables and campaign details below record historical configuration as of 8 November; they no longer describe products available for new purchase.

## Existing products and the shared Event SKU

| Product ID | Type / duration | Group / level | Spain price | Availability / sharing | Current status |
|---|---|---|---:|---|---|
| `com.romerodev.shield.pro.monthly` | Auto-renewable / 1 month | `MaskID Pro` | €2.99 historical | Retired from sale; existing subscribers are served through current paid period |
| `com.romerodev.shield.pro.annual` | Auto-renewable / 1 year | `MaskID Pro`, level 1 | €29.99 historical | Retired from sale; existing subscribers are served through current paid period |
| `com.romerodev.shield.pro.lifetime.unlock` | Non-consumable | Outside group | **€9.99** | Base Spain price; 175 territories with Apple localized prices | Approved/current; only in-app purchase offered |
| `com.romerodev.shield.pro.annual.event` | Auto-renewable / 1 year | `MaskID Pro`, level 1 | €29.99 historical | Retired from sale; existing subscribers are served through current paid period |

Event Annual ASC subscription ID: `6820383062`. Group ID: `22231170`. Reference name: **MaskID Pro Annual Event**; subscription display name: **MaskID Pro Annual Event** (en-US) / **MaskID Pro Anual de Evento** (es-ES). This is historical setup only; it was retired from sale on 18 November 2026.

The Event product’s Spanish and US localizations have been added. A generic 1024×1024 MaskID promotional image is uploaded to the subscription version (`a8396cf8-e9e0-47cd-9225-b08aecc1be8a`, delivery `COMPLETE`). The genuine 1206×2622 paywall screenshot from the iPhone 18 Pro is uploaded as review screenshot `c9f241d9-f194-4178-8661-0db687092bc6` (delivery `COMPLETE`); source: [`event-annual-review-iphone-18-pro.png`](../audit/event-annual-review-iphone-18-pro.png). Do not claim the product is approved or available for sale until Apple finishes review.

## Product configuration already applied

- Product ID: `com.romerodev.shield.pro.annual.event`.
- Reference name: **MaskID Pro Annual Event**.
- Duration: **1 year**.
- Group and level: **MaskID Pro**, level **1**, matching Standard Annual.
- Current Spain price: **€29.99/year**; post-event price return is effective and verified.
- Family Sharing: **off**, matching Standard Annual.
- Introductory offer: **none**.
- Promotional image: generic MaskID app artwork uploaded and delivery verified.
- App Review screenshot: real Event Annual paywall uploaded and delivery verified (`COMPLETE`).
- Availability includes 175 storefronts, including new territories.

## Previous release backlog (historical)

The following Event Annual steps were part of the previous subscription launch and are superseded by the 18 November retirement. No subscription sale or subscription app-version submission is pending from this task.

1. A future app version with current Lifetime-only purchase flow still requires legal review, Sandbox validation, and release checks. Do not infer app-version review readiness from product status.
2. The app version/build association remains a separate release task; this monetization change did not publish a version.
3. **Complete:** Standard-equivalent price is scheduled for 1 Nov 2026 across 175 storefronts with current-price preservation; ASC read-back verified 175/175. Evidence: [`event-end-price-apply.json`](../audit/event-end-price-apply.json).
4. Do not remove or change the existing Monthly, Standard Annual, or Lifetime Product IDs.

Apple’s review screenshot is a review artifact for the subscription. See [Subscription App Store Review Screenshots](https://developer.apple.com/documentation/appstoreconnectapi/subscription-app-store-review-screenshots?changes=l_1).

Apple requires the first auto-renewable subscription to be submitted together with a new app version. See [Submit an In-App Purchase](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase/).

## Historical price and campaign behavior (before 18 November 2026)

The app paywall schedule changes annual product presentation automatically at event boundaries; it does not change the App Store price. For Halloween 2026, Event Annual was priced at €14.99 in Spain and returned to €29.99 on 1 Nov for new buyers; ASC's scheduled change used Apple's current-price preservation option for existing subscribers and was read back across 175 storefronts.

Apple allows one future price change per storefront and plan. A price decrease lowers renewals for all current subscribers, with no option to preserve a higher price; an end-of-event price increase can preserve each current subscriber’s price. A preserved-price subscriber who expires may resubscribe at that price within 60 days; after that, the then-current price applies. See [Manage pricing for auto-renewable subscriptions](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/).

## Historical campaign date alignment

The app catalog currently uses 1 Oct 2026 00:00 through 1 Nov 2026 00:00 in each device’s local calendar. A previous project record described the App Store In-App Event as 1 Oct through 31 Oct 2026 23:00 Europe/Madrid; that is historical project evidence, not verified live ASC state. App paywall boundaries are therefore determined by the shipped catalog’s device-local dates, not by an ASC price schedule.

### Apple references

- [Manage pricing for auto-renewable subscriptions](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/)
- [Subscription App Store Review Screenshots](https://developer.apple.com/documentation/appstoreconnectapi/subscription-app-store-review-screenshots?changes=l_1)
- [Turn on Family Sharing for in-app purchases](https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases/)
- [App Store subscriptions](https://developer.apple.com/app-store/subscriptions/)
