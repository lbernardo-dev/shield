# 52-verify-revenuecat-production-key

- Number: 52
- Slug: verify-revenuecat-production-key

## Notes

- Audited the exact uploaded artifact: `.asc/artifacts/MaskID-1.0.0-100202607193.ipa` (bundle `com.romerodev.shield`, version `1.0.0`, build `100202607193`).
- The IPA and matching `.xcarchive` both embed `RevenueCatAPIKey = appl_cJuegsqbihOvDkhDESnUPrekHTJ`, the Apple platform-specific public SDK key.
- No RevenueCat Test Store API key (`test_` followed by a key-length token) is present. A broad binary scan found only SDK/internal symbols: `test_attribution`, `test_customerinfo`, `test_purchase`, and `test_stogalaxy`.
- The local `Shield.storekit` fixture is attached only to the scheme's Launch action and is not embedded in the submitted app.
- RevenueCat automatically distinguishes Apple sandbox and production transactions from their receipts; the Apple `appl_` key is correct for App Review and production.
- No app source or project configuration change was required.
