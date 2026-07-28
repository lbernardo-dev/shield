# 57-firebase-analytics-crashlytics

- Number: 57
- Slug: firebase-analytics-crashlytics

## Notes

- Added Firebase iOS SDK through Swift Package Manager at `12.16.0`.
- Linked `FirebaseAnalyticsCore` and `FirebaseCrashlytics` to the main app target.
- Added `FirebaseIntegration.configure()` at app startup, with a safe no-op when `GoogleService-Info.plist` is not present locally.
- Routed the existing allowlisted telemetry events to Firebase Analytics; document contents, OCR fields, paths, identifiers, and error messages remain excluded.
- Added build phases to copy `Shield/Resources/GoogleService-Info.plist` when present and upload Crashlytics dSYMs for Release builds.
- Documented the manual Firebase console setup for `lbernardo.dev@gmail.com` in `Docs/FIREBASE_SETUP.md`.
- Created Firebase project `MaskID` (`maskid-b2c07`) under `lbernardo.dev@gmail.com`, with Google Analytics enabled and Gemini disabled.
- Registered the iOS app `com.romerodev.shield` and installed its official `GoogleService-Info.plist` locally at `Shield/Resources/` (ignored by Git).
- Updated the Crashlytics symbol phase to skip simulator builds while continuing to upload symbols for Release device and archive builds.
- Verification: strict Debug and Release builds passed with the official configuration bundled. A device Release archive passed, validating the Crashlytics dSYM upload path. The full suite passed 55 tests and had three known intermittent Settings UI failures; the isolated foreground launch test passed.
