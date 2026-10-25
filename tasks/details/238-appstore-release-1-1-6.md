# 238-appstore-release-1-1-6

- Number: 238
- Slug: appstore-release-1-1-6

## Notes

- ASC app: `6790398619` (`com.romerodev.shield`). Created iOS version `1.1.6`, version ID `cdd9db00-ee9f-446d-ad67-d9e4efc9ba61`, state `PREPARE_FOR_SUBMISSION`, release type `MANUAL`.
- Set app, widget, and share extension Debug/Release `MARKETING_VERSION=1.1.6` and `CURRENT_PROJECT_VERSION=1162026102401` in `Shield.xcodeproj/project.pbxproj` using `asc xcode version edit` scoped per target/configuration. A broad project edit was rejected because the project defines settings only partially across configurations; the six scoped edits succeeded.
- Updated the localized in-app What's New strings in `Shield/Localization/Strings/SettingsInfo.xcstrings` and the version metadata `whatsNew` fields in `metadata/version/1.1.6/en-US.json` and `es-ES.json`. The user approved the exact English/Spanish copy; the IPA contains both compiled locales, and the two App Store Connect localization fields are updated.
- Read-only `asc metadata push --dry-run` showed that a broad metadata push would also change app name, subtitles, descriptions, keywords, and promotional text. Do not apply that broad plan for this request; use `asc localizations update --whats-new` for only `en-US` and `es-ES` after copy approval.
- Existing TestFlight group: `Shield Internal` (`ba8e0c39-76a7-4f5a-8cbe-32a1b20bfe78`). The group is now assigned to the uploaded build without submitting a beta review.
- Simulator inventory: iPhone 18 Pro, iPad Pro 13-inch (M5), and iPhone Duo are booted; Apple Watch Series 12 is shutdown. Occupancy checks show Renuvia foreground/widget processes on iPhone 18 Pro, UpLedger on iPad, and MaskID widget plus other apps on iPhone Duo. Do not stop, restart, or replace these sessions; recheck and wait before validation.
- The project has no watchOS app or extension target, so there is no watch component to install or pair for this release.
- Archive and IPA succeeded at `.asc/artifacts/MaskID-1.1.6-1162026102401.xcarchive` and `.asc/artifacts/MaskID-1.1.6-1162026102401.ipa`. `asc ipa-info --verify-signature` reports valid distribution signing, correct bundle/version/build, and both app extensions.
- ASC build `d722a578-2dce-4c98-99e4-f0903165cb1c` is `VALID`, has build number `1162026102401`, and is attached to version `cdd9db00-ee9f-446d-ad67-d9e4efc9ba61`. ASC verification confirms the `Shield Internal` group relationship and localized `whatsNew` values in `en-US` and `es-ES`.
- App Store version state remains `PREPARE_FOR_SUBMISSION` with `MANUAL` release type. No App Store review or TestFlight beta review was submitted.
- Remaining: run device validation when the three occupied simulators are released. The user has been asked whether they can free them or wants the validation to stay queued.
- Preserve existing release artifacts. No cleanup has been run.

### Reconciliation after UI and authentication fixes — 2026-10-24

- Build `1162026102401` remains VALID and attached to the prepared 1.1.6 version, with the approved `en-US`/`es-ES` What's New and the existing `Shield Internal` TestFlight group. No submission was made.
- The archive timestamp is 12:25. `Shield/App/ContentView.swift` was modified at 15:28 to remove the persistent Scan accessory, and later source fixes include the Settings summary ordering and optional-PIN relaunch/auto-lock policy. Those changes are verified in simulator runs but are not part of the existing IPA.
- The requested source state therefore cannot be delivered under build number `1162026102401`, because that build is already uploaded and VALID. A request is pending to authorize `1162026102402` for upload to the same prepared 1.1.6 version without submitting it for review. No new version/build mutation will occur before that answer.

### Authorized replacement build — 2026-10-24

- The user authorized build `1162026102402` for the existing prepared 1.1.6 version, with no App Review submission.
- App, widget, and share extension Debug/Release settings now consistently use `MARKETING_VERSION=1.1.6` and `CURRENT_PROJECT_VERSION=1162026102402`.
- `xcodebuild build-for-testing` succeeded for the explicit iPhone 18 Pro simulator destination using DerivedData at `build/MaskID-1.1.6-1162026102402`. Xcode reported only the existing deprecated `SKPaymentTransactionState` use from StoreKitTest.
- The required iPhone 18 Pro remains in use by `com.romerodev.repsfitness`; the user said they will release it and notify us. No simulator test run is being started until availability is confirmed.
- Build 2402 has not yet been archived, exported, uploaded, or attached. Preserve VALID build 2401 and all existing release artifacts.
- Historical Duo run `/private/tmp/MaskID-iPhoneDuo-20261024-0814.xcresult` contains tests and assertions from an older source revision (including `testDuoHomeKeepsBrandProfileAndScanVisible`, absent from current source). Its Scan rail failures are stale. The custom-profile scroll failure also needs a current-build recheck before deciding whether a source change is warranted.

### Authorized replacement build 2403 — 2026-10-24

- The user approved build `1162026102403` to replace 2402 in prepared version 1.1.6, with no App Store or beta review submission.
- Corrected in-app What's New entries to match the approved English/Spanish wording exactly. `ShieldUITests.ShieldLaunchTests.testWhatsNewMatchesApprovedEnglishAndSpanishCopy` passed 1/1 on the explicit iPhone 18 Pro simulator after checking both locales and both approved sentences.
- Set `CURRENT_PROJECT_VERSION=1162026102403` in Debug and Release for `Shield`, `ShieldWidgetExtension`, and `ShieldShareExtension`. All three bundle identifiers in the archive report version `1.1.6` and build `1162026102403`.
- Archive succeeded at `.asc/artifacts/MaskID-1.1.6-1162026102403.xcarchive`; export succeeded at `.asc/artifacts/MaskID-1.1.6-1162026102403.ipa`. The IPA is 53,868,800 bytes, minimum iOS 18.0, contains both extensions, and `asc ipa-info --verify-signature` verifies the distribution CMS signature and chain to Apple Root CA. Crashlytics dSYMs remain in the archive; the upload-symbol build phase was skipped for this invocation only.
- `asc builds upload --dry-run` succeeded. Actual upload was committed; upload/build ID `d5b25362-36a7-4817-9e8b-d14c13318169` reached `VALID`.
- Build `1162026102403` is attached to version ID `cdd9db00-ee9f-446d-ad67-d9e4efc9ba61`, which remains `PREPARE_FOR_SUBMISSION`. Dry run and final membership lookup confirmed the build belongs explicitly to `Shield Internal` group `ba8e0c39-76a7-4f5a-8cbe-32a1b20bfe78`.
- ASC localization readback confirms the exact approved `whatsNew` strings remain set for `en-US` and `es-ES`. `asc builds beta-app-review-submission view` found no beta review submission for build 2403. No App Store review submission command was run.
- UI copy test result: `/private/tmp/MaskID-2402-WhatsNew-Copy-Fix.xcresult`, iPhone 18 Pro iOS 27.0, 1/1 passed. The tested app source matches 2403; only the build number changed before archiving.
- The long upload wait process eventually reported an expired bearer token. Fresh authenticated reads confirmed upload completion, `VALID` processing, version attachment, group membership, and localization state; no duplicate IPA upload was needed.
- A local `codesign --verify --deep --strict` invocation reported `CSSMERR_TP_NOT_TRUSTED`; the ASC offline verifier independently validated the IPA's main executable signature and Apple certificate chain. `asc ipa-info` does not verify nested bundle signatures or resource files.
- No cleanup has been run. Keep all prior valid release artifacts and the new 2403 archive/IPA.

### Corrección del número diario — 2026-10-25

- Por la regla de numeración acordada, la build correspondiente al 25-10-2026 termina en `2501`: `1162026102501`. El archive y el IPA fueron generados localmente con versión 1.1.6.
- Verificación: bundle principal `com.romerodev.shield`, build 2501; `ShieldShareExtension` y `ShieldWidgetExtension` también 2501; las seis configuraciones `CURRENT_PROJECT_VERSION` del proyecto se actualizaron a 2501. `codesign --verify --deep --strict` válido y `get-task-allow=false`. SHA-256 IPA: `1b77f16c397873195d2d43202736376d7c2691eb8497a86bb7cbd3f7cc358a6e`.
- Upload autorizado completado: build ID `c1064f9d-11bf-4c2e-9306-84fca1eada69` alcanzó `VALID`, reemplazó la asociación de 2403 como build seleccionado de la versión 1.1.6 y quedó en `Shield Internal`. La versión sigue `PREPARE_FOR_SUBMISSION`; no se envió a revisión.
