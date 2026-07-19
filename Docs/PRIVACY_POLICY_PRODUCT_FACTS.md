# Shield privacy facts

- Document processing, OCR, masking and export run on device.
- Shield does not operate an analytics or advertising backend and does not track users.
- Imported originals, render caches and local telemetry are encrypted at rest with device-only keys.
- The Vault uses a separate device-only key and requires device authentication/PIN.
- iCloud index sync is opt-in and uploads only minimized private-database metadata; document content and user-entered titles remain local.
- Third-party storage is accessed only through Apple's Files picker. Shield receives only the file explicitly selected and stores no provider OAuth token.
- Temporary exports are protected and removed when the share/export flow ends.
- Secure export rasterizes and verifies output to prevent recoverable hidden text. No automated detector can guarantee that the user selected every sensitive region; review remains required.
