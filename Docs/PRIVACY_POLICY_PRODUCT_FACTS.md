# Shield privacy facts

- Document processing, OCR, masking and export run on device.
- Firebase Analytics is optional, disabled by default, and starts only after the user explicitly enables it in Settings > Privacy. The app does not show an analytics prompt during first launch. It sends only allowlisted, sanitized product events. Firebase Crashlytics remains a separate stability-diagnostics service; neither service receives document content, OCR fields, titles, file paths, or images.
- RevenueCat processes anonymous purchase history to validate transactions and enable entitlements.
- Imported originals, render caches and local telemetry are encrypted at rest with device-only keys.
- The Vault uses a separate device-only key and requires device authentication/PIN.
- iCloud sync is opt-in for Pro and uploads complete, restorable document packages (metadata, original/working images, extracted text fields and redaction masks) to the user's private CloudKit database; Vault documents remain local.
- Separately, MaskID keeps a numeric document-processing quota count in local UserDefaults and Keychain and mirrors the count to Apple's iCloud key-value store when available, so the quota can be reconciled across devices using the same Apple Account. The count contains no document content, filename, OCR text, or document ID; it is separate from optional Pro CloudKit document sync. Apple documents that iCloud key-value store data is stored unencrypted on device; MaskID uses it only for this aggregate count.
- Third-party storage is available through Apple's Files picker or optional direct Google Drive/Dropbox integrations. Direct integrations use OAuth 2.0 Authorization Code + PKCE and keep access/refresh tokens in the device Keychain; Shield downloads only the file the user selects.
- Temporary exports are protected and removed when the share/export flow ends.
- Secure export rasterizes and verifies output to prevent recoverable hidden text. No automated detector can guarantee that the user selected every sensitive region; review remains required.
- Optional feedback emails contain only the selected category, an optional user comment, app/build/OS/device/locale metadata, entitlement tier, and install/update/submission timestamps. They never include document contents, OCR fields, images, credentials, payment data, or analytics copies of the free-form comment.
