# 21-pricing-restructure

- Number: 21
- Slug: pricing-restructure

## Notes

- Replaced Lifetime with Weekly in StoreKit code, the local StoreKit configuration and the paywall.
- App Store Connect prices verified for Spain: Weekly EUR 0.99, Monthly EUR 2.99 and Annual EUR 29.99; all three subscriptions are `READY_TO_SUBMIT` in 175 territories. Lifetime was deleted.
- Fixed manual Vault locking, Style Gallery header positioning and CloudKit missing-schema handling.
- Deployed the `ShieldDocument` schema and its nine fields to the production CloudKit environment.
- Release gate passed with strict compilation, unit/security/OCR/export tests and two UI tests.
- Archived, exported and uploaded `1.0.0 (100202607132)`; Apple reports `VALID` and `IN_BETA_TESTING` in `Shield Internal`.
- Tester `lbernardo.cu@gmail.com` is active (`INSTALLED`). The build is attached to App Store version 1.0.0, but the version and first-time subscriptions were not submitted for review.
