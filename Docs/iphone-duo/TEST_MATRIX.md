# Test matrix — iPhone Duo

Date: 2026-10-18. Simulator inventory and foreground app processes were inspected before installing or launching. The required iPhone 18 Pro was used first, then the exact Duo named by the user. The generic Duo and occupied iPad were left untouched.

| Target | Runtime | UDID / state | Result |
|---|---|---|---|
| iPhone 18 Pro | iOS 27.0 | `1454EA8D-A019-4B07-B57C-1433E0F21BE0`; booted | **Used first.** No foreground application process appeared in the launchd app list before the run. Built, installed and launched MaskID (PID 57339). |
| iPhone Duo — VitalsPath Session | iOS 27.1 | `EBD930CD-55C3-4C41-9987-C6DB90EDCFC6`; booted | **Used.** Installed the same build and launched MaskID (PID 57594). Device Hub confirmed MaskID remained in the foreground at the local PIN setup lock screen, with no startup crash. The app requires local PIN setup before the authenticated home can be opened; no credential was entered or changed. |
| iPhone Duo — VitalsPath Session, partially open | iOS 27.1 | Same UDID | **Inspected.** The primary authentication action and supporting text remain inside the leading display panel and do not cross the active division after the fix. |
| iPhone Duo — VitalsPath Session, fully open | iOS 27.1 | Same UDID | **Inspected.** Lock content remains grouped within one panel, avoiding the center division. |
| iPhone Duo — VitalsPath Session, closed | iOS 27.1 | Same UDID | **Inspected and restored to the initial pose.** Lock content fits the outer display without an active vertical division. |
| iPhone Duo (generic) | iOS 27.1 | `BF5C28D6-2B6D-46FC-82E8-9A248F5C0186`; booted | Not used; Device Hub showed UpLedger in this simulator, so it was left untouched. |
| iPad Pro 13-inch (M5) | iOS 27.0 | `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`; booted | Not used; active foreground processes included `com.romerodev.expirely`, `com.upledger.app` and `com.romerodev.personalcare`, so it was left untouched. |
| Apple Watch Series 12 (46 mm) | watchOS 27.0 | Booted | Not applicable: the repository has no watchOS app target or scheme. No pairing was changed. |

## Executed

- Built the `Shield` Debug scheme for the explicit iPhone 18 Pro destination with Xcode 27.1 / iOS Simulator SDK 27.0:
  `xcodebuild -quiet -project Shield.xcodeproj -scheme Shield -configuration Debug -destination 'platform=iOS Simulator,id=1454EA8D-A019-4B07-B57C-1433E0F21BE0' -derivedDataPath build/iphone-duo-derived-data CODE_SIGNING_ALLOWED=NO build` — **BUILD SUCCEEDED** after the home layout changes.
- Installed and launched that build on iPhone 18 Pro (PID 57339), then on the exact Duo target (PID 57594). Device Hub showed MaskID's local-PIN setup screen and the process remained live in the Duo logs; no startup crash appeared.
- The regular-width home now uses a shared title/Scan row aligned to the two columns, a surfaced recent-documents empty state and tools card, and a single-line horizontal category strip to prevent broken labels. Compact layout remains stacked.
- Earlier in the same session, while the app was already authenticated, Device Hub showed the Documents home and the Documentos → Estilos navigation transition completed. The UI then entered its configured inactivity lock. Scan, editor, PIN setup, and protected data were not opened.
- Device Hub, rather than `simctl io screenshot`, provided the visual screenshots; `simctl` screenshots were black while Device Hub rendered the live app correctly.
- The user-provided closed/open home screenshots exposed a blank regular-width bottom accessory, clipped/wrapped category chips, unbalanced columns, an unclear primary Scan action, a truncated free-plan label and processing description, and an empty-state CTA competing with the persistent Scan accessory. Source now conditionally attaches the Scan accessory only in compact width, keeps categories on one horizontal line, permits compact text to wrap, reserves compact scroll-content margin, surfaces the regular-width document panel, and removes the duplicate empty-state Scan CTA.
- Those home changes are **build- and install-verified but not visually rechecked**: after relaunch, Device Hub showed the local PIN setup lock screen. Unlock/setup is a user hand-off, so no authentication flow was attempted.
- `git diff --check` passed.
- VitalsPath was never launched, terminated, or removed by this visual-fix pass. Only MaskID was installed on iPhone 18 Pro and `EBD930CD-55C3-4C41-9987-C6DB90EDCFC6`; the generic Duo and occupied iPad were not changed.

## Crash diagnosis and verification limits

- The first supplied crash report showed `EXC_BREAKPOINT` in `CKContainer.__allocating_init(identifier:)`, reached during `PremiumManager.init()`. The simulator build had no active iCloud entitlement. CloudKit container creation now returns unavailable in simulator processes and callers fail gracefully; physical production builds retain the configured container.
- The later supplied report showed a UIKit assertion while presenting an alert at startup. In an unsigned simulator build, the App Group inbox is unavailable. `consumeSharedImport()` now treats that condition as an absent inbox and does not show a misleading error alert.
- The Duo build and launch remained live after both changes. This is a simulator smoke check, not a passing automated test-suite result.
- The existing test attempts did not verify test execution: the UI `.xcresult` summary returned `result=unknown`, `totalTestCount=0`, and no test nodes. The earlier unit-test attempt did not leave a result bundle proving tests ran. No test is reported as passing.
- The unsigned simulator also logged Firebase keychain access failures (`SecItemCopyMatching`, status `-34018`) in a previous run because the process lacks its configured Keychain access group. Those logs were nonfatal, but Firebase/Keychain behavior needs a correctly entitled signed run for validation.
- After the app's inactivity timeout, it asked for local authentication/PIN setup. No credential was entered, changed, or bypassed, so protected Scan/editor and authenticated fold-continuity scenarios remain unverified.
- No visual home result on iPhone 18 Pro, iPad result, watch result, camera-permission, accessibility-size, Split View, editor, or redaction/export result is claimed by this pass.

## Incremental validation — 2026-10-24

| Target | Runtime | Latest result |
|---|---|---|
| iPhone 18 Pro (`1454EA8D-A019-4B07-B57C-1433E0F21BE0`) | iOS 27.0 | Four focused UI tests passed after the Scan accessory removal, Home tools expansion fix, and Settings summary-card reorder. The latest shared intake route also passed 1/1. Results: `/private/tmp/MaskID-239-iPhone18-AfterHomeLayout.xcresult` and `/private/tmp/MaskID-239-iPhone18-IntakeOnly.xcresult`. |
| iPhone Duo (`BF5C28D6-2B6D-46FC-82E8-9A248F5C0186`) | iOS 27.1 | A six-test run's worker logged successful test execution, but Xcode did not finalize the result bundle while collecting simulator diagnostics. A separate Reps test then used Duo; `SchoolSnap` was foregrounded at the latest check. Treat this run as inconclusive and queue a clean rerun until the simulator is free. |
| iPad Pro 13-inch (M5) (`2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`) | iPadOS 27.0 | No active MaskID/Expirely/UpLedger/Personal Care process at the latest check. Post-fix UI rerun pending; earlier results exposed Home quick-tools expansion and contextual Scan toolbar issues that now have source changes and must be rechecked. |
| Apple Watch Series 12 | watchOS 27.0 | No watchOS target or scheme exists in this project; not applicable. |

The current implementation has no `.tabViewBottomAccessory` and excludes `.capture` from `AppTab.navigationCases`. The Settings summary card is the first scroll-content item, and `testSettingsSummaryCardPrecedesAllSettingsSections` checks that it appears before the first settings route.

## Revalidated after Scan and Settings fixes — 2026-10-24

| Target | Runtime | Result |
|---|---|---|
| iPhone 18 Pro (`1454EA8D-A019-4B07-B57C-1433E0F21BE0`) | iOS 27.0 | Final focused UI suite: **4/4 passed**. The security/privacy unit suite: **13/13 passed**, including optional PIN startup and auto-lock policy. The app opened without a configured PIN, and the screenshot showed no persistent Scan accessory. |
| iPhone Duo (`BF5C28D6-2B6D-46FC-82E8-9A248F5C0186`) | iOS 27.1 | Final focused UI suite: **5/5 passed** after the user authorized taking control of the Duo session. The earlier non-final Xcode result collection is superseded. |
| iPad Pro 13-inch (M5) (`2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`) | iPadOS 27.0 | Final focused UI suite: **4 passed, 1 Duo-only test skipped**. |
| Apple Watch Series 12 (46 mm) (`3A4C4C8C-BFDC-4E8C-95AE-596329243EAB`) | watchOS 27.0 | Simulator exists and is booted, but this project has no watchOS app target or scheme to install/pair. |

- Result bundles: `/private/tmp/MaskID-239-iPhone18-Final-Focused.xcresult`, `/private/tmp/MaskID-239-iPhone18-SecurityPrivacy-Tests.xcresult`, `/private/tmp/MaskID-239-Duo-OptionalPIN-Final.xcresult` and `/private/tmp/MaskID-239-iPad-OptionalPIN-Final.xcresult`.
- Current source and UI tests also compile successfully with `xcodebuild build-for-testing` for the explicit iPhone 18 Pro UDID. Xcode reports the existing StoreKitTest deprecation warning from the iOS 27.1 SDK.
- The focused revalidation covered Home, quick tools, Settings dismissal and Settings-summary ordering. The separate UI cases for batch review, OCR search and custom protection profiles remain queued for the required iPhone-first run.
- At the latest read-only occupancy check, iPhone 18 Pro still had `com.romerodev.repsfitness` active. Duo and iPad showed only system UIKit processes. No app or simulator was changed in that check; the next UI run must wait for iPhone 18 Pro to be released.
- Direct simulator screenshot inspection was available on iPhone 18 Pro. Duo UI tests passed, but a fresh direct screenshot is still needed to visually inspect the latest build after the user confirms the Mac is unlocked.

### Historical Duo result audit — 2026-10-24

- `/private/tmp/MaskID-iPhoneDuo-20261024-0814.xcresult` ran a test revision older than the checked-in source: its test `testDuoHomeKeepsBrandProfileAndScanVisible` is absent now, and its rail-placement assertions conflict with the current Home Scan-removal design. Do not count these two failures against the current build; repeat the current suite after the required iPhone 18 Pro-first pass.
- The same result reports that eight swipe gestures in the custom-profile form did not reveal the mask-style picker in the open Duo pose, although the form reported a multi-page vertical scrollbar and the same case passed in the closed pose. Recheck with the exact current build before making a code change.
- The exported home screenshot from that run is all black and is not visual evidence.
