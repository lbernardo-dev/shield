# Firebase setup

Firebase Analytics and Crashlytics are integrated through Swift Package Manager for the main iOS app target. Analytics uses `FirebaseAnalyticsCore`, avoiding Firebase's Identity Support wrapper.

The Firebase project is `MaskID` (`maskid-b2c07`) and its registered iOS app uses bundle ID `com.romerodev.shield`.

Product events use the existing allowlist in `AppState.trackEvent`. Only named, sanitized product properties are sent; the app does not send document contents, OCR fields, titles, file paths, account IDs, or error messages to Firebase.

Configuration replacement:

1. Sign in to Firebase with `lbernardo.dev@gmail.com`.
2. Open the `MaskID` project and its iOS app.
3. Download `GoogleService-Info.plist`.
4. Place it at `Shield/Resources/GoogleService-Info.plist`.

The Xcode project copies that file into the app bundle when it exists. If the file is missing, the app safely skips Firebase configuration instead of crashing at launch.

Validate the configured project after installing the app on a real device: use Firebase Analytics DebugView to verify a product event and induce a non-production test crash to verify Crashlytics. Do not test crashes in a production build.

Crashlytics dSYM upload is configured for Release device and archive builds using the Firebase SPM script. Simulator builds are intentionally skipped:

```sh
${BUILD_DIR%Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run
```
