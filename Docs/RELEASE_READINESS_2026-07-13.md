# Shield — release readiness (13 July 2026)

## Locally complete

- Universal iPhone/iPad target with an iOS 18.0 minimum, iOS 26 feature gates and strict-concurrency builds.
- Release gate passed: 28 logical tests, 36 parameterized executions, 0 failures and 0 skipped tests.
- Release static analysis passed with warnings treated as errors.
- Secure raster export and post-export PDF verification.
- Encrypted local library, separately keyed Vault and protected temporary files.
- Bounded import pipeline, real Vision OCR fixture and evaluated evidence model.
- Validated generic PII detectors for email, telephone, IBAN (MOD-97) and payment card (Luhn).
- Share Extension with encrypted App Group inbox and a 50 MB extension budget.
- App Intents, Files/Share intake, keyboard and accessibility paths.
- MetricKit metric/diagnostic subscription with protected, bounded local retention.
- In-app privacy policy and terms, plus publishable static HTML copies.
- App Store local preflight and release gate.
- Distribution archive and export use version 1.0.0, build 100202607132 under the adopted date-based convention.
- Independent IPA audit: strict signature, Distribution entitlements, production CloudKit, App Group, Keychain Group, privacy manifests and minimum OS verified.
- Real iPhone 6.9-inch and iPad 13-inch screenshots captured in Spanish and English and accepted by the local App Store size validator.

## App Store Connect status

- App record created: `Shield` (`6790398619`), primary locale `es-ES`.
- App Store version `1.0.0` created and build `100202607132` attached.
- Metadata, categories, content rights, copyright, manual release mode and age rating are configured.
- Ten conversion-focused iPhone 6.9-inch screenshots per language (Spanish and English) are uploaded and processed; the required iPad sets remain present.
- Build `1.0.0 (100202607132)` is processed, valid, in internal beta testing and assigned to the `Shield Internal` TestFlight group.
- The production CloudKit schema contains the `ShieldDocument` record type and its nine fields, eliminating the TestFlight schema error.
- Weekly, monthly and annual subscriptions are localized, priced and available in all 175 territories.
- The annual subscription includes a seven-day free trial in all 175 territories.
- All three products have an App Review screenshot and report `READY_TO_SUBMIT`.
- App availability is initialized for all 175 territories, including future territories; Apple reports each as available when the app is published.
- App Privacy was published on 13 July 2026 as `Data Not Collected`, matching the on-device processing model and private user-owned CloudKit storage.
- App Store and TestFlight review-contact records are complete, with no demo account required.
- Canonical App Store and TestFlight validations report zero errors and zero blocking issues.

## Remaining external gates

1. Attach the three first-time StoreKit products to the app-version review in App Store Connect when the release is submitted.
2. Test camera, scanner, limited Photos access, Files providers, Share Extension and biometric behavior on physical iPhone/iPad hardware.
3. Run internal TestFlight for at least 72 hours and inspect Organizer/MetricKit crash, hang and memory signals.
4. Have an independent reviewer inspect security and adversarial PDF fixtures.

## Apple resources prepared on 13 July 2026

- Main bundle ID: `com.romerodev.shield` (`7BX79RLCY5`).
- Share Extension bundle ID: `com.romerodev.shield.ShareExtension` (`S2M5878YY9`).
- App Group, Keychain Group and production CloudKit entitlements are present and verified in the exported app.
- Invalid manually generated profiles `87RWY7CCKF` and `Z88BDSAD9J` were removed; Xcode managed the valid Distribution signing used for export.
- A valid Apple Distribution certificate is available (`42M2B75LNU`, expires 2 June 2027).
- Remote legal-endpoint preflight passed on 13 July 2026.
- Archive: `.asc/artifacts/Shield-1.0.0-100202607132.xcarchive`.
- Exported IPA: `.asc/artifacts/Shield-1.0.0-100202607132.ipa` (18.2 MB).
- IPA SHA-256: `b0e80aa647964682dcf685ce50cbc9d13ad201efb9764e7f3a53cee309daea03`.
- ASO screenshot evidence: `.asc/screenshots/aso/final/{es-ES,en-US}/iphone-69` plus the existing `.asc/screenshots/{es-ES,en-US}/ipad-13` sets.
- The local StoreKit fixture is available only from the shared development scheme and is absent from the Release IPA.
- The launch accessibility audit also passed explicitly on an iPhone 16 Pro Max simulator running iOS 18.6.

Run local readiness with:

```sh
AGENT_NAME=RELEASE scripts/release_gate.sh
```

Run the legal-endpoint check with:

```sh
scripts/app_store_preflight.sh --remote
```
