# 212-subscription-store-artwork-review

- Number: 212
- Slug: subscription-store-artwork-review

## Notes

- Reviewed the latest local App Store Connect and RevenueCat subscription records dated 8 October 2026. The three auto-renewable products are Monthly (1 month, €2.99 Spain, approved), Standard Annual (1 year, €29.99 Spain, approved, existing 7-day trial), and Event Annual (1 year, €14.99 Spain during the current campaign, `READY_TO_SUBMIT`, no introductory offer).
- Lifetime Unlock is a non-consumable one-time purchase, not an auto-renewable subscription. It appears in the local catalog at €49.99; its current ASC record was not verified in the recent project audit.
- ASC’s live catalog could not be refreshed on 9 October: `asc auth status` failed reading local credentials with macOS error `-50`, while the signed-in ASC Apps page showed no app entries. The design inventory therefore follows recent repository audit evidence and is labeled as such.
- Created four review exports in `audit/subscription-artwork-review/`: `monthly.png`, `annual-standard.png`, `event-annual.png`, and the extra non-subscription `lifetime.png`.
- All exports were checked as 1024 × 1024 PNG, RGB, no alpha, 72 dpi. The design system uses the MaskID indigo/violet/cyan palette, with distinct monthly orbit, annual ring, campaign light sweep, and lifetime infinity motifs. No text or UI; lower-left kept free of important subject detail for Apple framing.
- A generic Event Annual promotional image is already recorded in ASC; it was not overwritten. The existing App Review screenshot is separate.
- User requested preview before upload. No image was uploaded and no App Store Connect data was changed. Assets are ready for user review and possible later upload after approval.
