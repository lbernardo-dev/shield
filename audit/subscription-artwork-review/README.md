# MaskID subscription artwork review

**Created:** 9 October 2026
**Status:** The three auto-renewable subscription images are uploaded and verified as `COMPLETE` in App Store Connect draft versions. They have not been submitted for App Review. The Lifetime image is a preview only.

## Product inventory used

Territory pricing below comes from the 8 October project audit. Product versions and image delivery states were read live from App Store Connect on 9 October 2026.

| Product | ASC type and term | Spain price (8 Oct audit) / current ASC version status | Artwork |
|---|---|---|---|
| `com.romerodev.shield.pro.monthly` | Auto-renewable, one month | €2.99/month; v1 `APPROVED`; v2 `PREPARE_FOR_SUBMISSION` with new image | [monthly.png](monthly.png) |
| `com.romerodev.shield.pro.annual` | Auto-renewable, one year | €29.99/year; v1 `APPROVED`; v2 `PREPARE_FOR_SUBMISSION` with new image; existing 7-day trial | [annual-standard.png](annual-standard.png) |
| `com.romerodev.shield.pro.annual.event` | Auto-renewable, one year | €14.99/year during the current event; product `READY_TO_SUBMIT`; draft v1 `PREPARE_FOR_SUBMISSION` with new image; no introductory offer | [event-annual.png](event-annual.png) |
| `com.romerodev.shield.pro.lifetime.unlock` | Non-consumable, one-time purchase; not a subscription | €49.99 in the local catalog; artwork not uploaded | [lifetime.png](lifetime.png) |

## App Store Connect upload

| Product | Draft version ID | Image ID | Uploaded asset | Delivery |
|---|---|---|---|---|
| Monthly v2 | `b0805e36-f64c-46d4-9bad-4cbee7923c25` | `25e02a39-8a6f-441e-b810-2b6e77ec7c5e` | `monthly.png` | `COMPLETE`, 1024 × 1024 |
| Standard Annual v2 | `98d8d480-8c9f-4e11-8acd-d0ab9a029243` | `144e4b25-72a3-4995-a929-527a19d7aa78` | `annual-standard.png` | `COMPLETE`, 1024 × 1024 |
| Event Annual v1 | `8508f73b-dc0e-4a1b-ae13-ea5ead17b0cb` | `4d0f2052-65ff-414c-a074-48f01907b726` | `event-annual.png` | `COMPLETE`, 1024 × 1024 |

The approved Monthly and Standard Annual v1 versions and their images were left unchanged. Each draft retains its existing Spanish and English localizations. Subscription-version metadata changes go through App Review before becoming live; no review submission was created.

The Event Annual product is a generic campaign SKU shared across events, so its artwork uses a campaign accent without a Halloween-specific symbol. The existing `icon_1024.png` image in the Event draft was replaced. The actual App Review screenshot for that subscription is a separate artifact.

RevenueCat maps Monthly, Standard Annual, and Lifetime into the `default` Offering; Event Annual shares the existing Pro entitlement and appears in the `event` Offering alongside Monthly.

## Visual system and export

All four pieces use MaskID's indigo, violet, electric blue, and cyan palette. The silhouettes distinguish the options at thumbnail size: a single orbit for Monthly, a complete orbit for Standard Annual, a warm amber/orchid campaign sweep for Event Annual, and an infinity loop for the one-time Lifetime unlock.

Each export is PNG, 1024 × 1024 px, RGB, flattened, without transparency, and 72 dpi. The images contain no copy, prices, UI, logo, watermark, border, or rounded corners. The lower-left area stays visually quiet for Apple's framing treatment.

Apple describes these as subscription promotion images that represent a subscription on the App Store, distinct from App Review screenshots. Apple specifies 1024 × 1024 promotional artwork, recommends no overlaid text, and advises against using a screenshot or making the image look like the app icon:
- [Subscription images — App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi/subscription-images?changes=_10)
- [Promoting your Apple In-App Purchases](https://developer.apple.com/app-store/promoting-in-app-purchases/)

## Provenance

Artwork was generated with built-in ImageGen using the current MaskID paywall screenshot and app icon as palette and mood references only. The project exports are deterministic 1024 × 1024 resamples where needed; source generations remain preserved under the local Codex generated-images directory. The three auto-renewable images were uploaded after preview approval. The non-consumable Lifetime artwork was not uploaded as a subscription image.
