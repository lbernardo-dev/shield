# Shield privacy facts

- Document processing, OCR, masking and export run on device.
- Firebase Analytics is optional, disabled by default, and starts only after explicit in-app consent. It sends only allowlisted, sanitized product events. Firebase Crashlytics remains a separate stability-diagnostics service; neither service receives document content, OCR fields, titles, file paths, or images.
- RevenueCat processes anonymous purchase history to validate transactions and enable entitlements.
- Imported originals, render caches and local telemetry are encrypted at rest with device-only keys.
- The Vault uses a separate device-only key and requires device authentication/PIN.
- iCloud sync is opt-in for Pro and uploads complete, restorable document packages (metadata, original/working images, extracted text fields and redaction masks) to the user's private CloudKit database; Vault documents remain local.
- Third-party storage is available through Apple's Files picker or optional direct Google Drive/Dropbox integrations. Direct integrations use OAuth 2.0 Authorization Code + PKCE and keep access/refresh tokens in the device Keychain; Shield downloads only the file the user selects.
- Temporary exports are protected and removed when the share/export flow ends.
- Secure export rasterizes and verifies output to prevent recoverable hidden text. No automated detector can guarantee that the user selected every sensitive region; review remains required.
