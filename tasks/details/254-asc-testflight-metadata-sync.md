# 254-asc-testflight-metadata-sync

- Number: 254
- Slug: asc-testflight-metadata-sync

## Notes

- ASC metadata version-scoped es-ES/en-US was written and read back; public shared app-info fields were preserved.
- Uploaded build `1.1.7 / 1172026110801` to ASC/TestFlight; build ID `2d9de6eb-e554-4fca-84f5-58eaccd2b88d` reached `VALID`. No beta group/testers were added, no Beta App Review or App Review submission occurred, and no public release was made.
- Prepared 40 designed ASO creatives (10 per locale/device) from authentic UI captures with the base theme verified. Current ASC Asset Library has 10 `ACTIVE` placements in each target group and 40 images in `PREPARE_FOR_SUBMISSION`; names, order and IDs are in `Docs/release-cycle/04_RELEASE/16_ASC_SCREENSHOT_UPLOAD_REPORT.md`.
- During initial work an upload attempt used Apple's deprecated screenshot-set resource. It was stopped on detection; final state was verified and corrected through current `appAssetLibraryImages` / `appAssetLibraryPlacements` operations. The report records the migration and only uses current placements as completion evidence.
- RevenueCat read-back confirms Spain prices of €2.99 monthly, €29.99 annual, €49.99 lifetime and no live annual intro offer (`trial_offer=null`, `introductory_offers={}`). `list-apps`, `list-products` and `list-entitlements` still return 403, so entitlement and cross-app generic SKU associations need a later read with restored permissions. The product object retains `trial_duration=P1W`; current API `update-product` cannot edit that field for App Store products, and no store offer is live. No RC write was needed to meet the approved prices/offer state.
- Local creative manifest check: 40 files, four folders of 10, SHA-256 verified. ASC read-back: 10/10 active, processed and ordered in all four groups; 40 report placement IDs match the live records.
- Release state and owner follow-up are summarized in `Docs/release-cycle/04_RELEASE/00_RELEASE_EXECUTIVE.md`, `13_ASC_REVENUECAT_RECONCILIATION.md`, `16_ASC_SCREENSHOT_UPLOAD_REPORT.md` and `FASE_04_HANDOFF.json`.
- Temporary files and build caches were preserved; cleanup was not performed.

