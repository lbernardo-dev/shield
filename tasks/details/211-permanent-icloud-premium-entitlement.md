# 211-permanent-icloud-premium-entitlement

- Number: 211
- Slug: permanent-icloud-premium-entitlement

## Notes

- CloudSyncManager uses the entitled `iCloud.com.romerodev.shield` container but previously only queried account availability; it did not retrieve a user record ID. `CKContainer.userRecordID()` supplies `CKRecord.ID.recordName`, the exact string form of the requested CloudKit User Record Name.
- Added an exact two-name allowlist to `PremiumAccessResolver`. Access requires an available CloudKit account and successful `userRecordID()` retrieval, and the exception is enabled only in non-simulator Release builds. A failed or unavailable lookup clears the in-memory verified identity.
- RevenueCat and StoreKit state remain separate. The central `isPro` result unions verified allowlist access with active RevenueCat access; purchase metadata, ownership, dates, and transaction state remain populated only from RevenueCat.
- Existing screens and feature gates already consume `PremiumManager.isPro`. The widget snapshot now shares the resolved Boolean through its existing App Group and shows a crown marker; legacy snapshots decode as non-Premium. The Share Extension only enqueues imports and delegates processing/gates to the app. The project has no watchOS target.
- This workspace contains only MaskID. Apple's docs describe CloudKit data and user records within app containers, so reusing these names in other apps is not verified here; each app would need to compare against its own configured container.
- Validation: Debug iPhone 18 Pro (UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`, iOS 27.0) build succeeded; `build-for-testing` for the same destination exited 0 and produced the unit/UI test bundles. Release generic iOS device build exited 0 and produced `MaskID.app`, exercising the non-simulator production branch. Release emitted existing Swift concurrency/actor warnings in unrelated files. Runtime tests remain pending: iPhone 18 Pro is booted with another app (`UpLedger`), and the iPad Pro is running several apps including MaskID in screenshot mode, so neither device has been installed to or launched for this task.
