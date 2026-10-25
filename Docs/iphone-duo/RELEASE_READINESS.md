# Release readiness — iPhone Duo

**Status: VALIDACIÓN PARCIAL — REQUIERE PRUEBAS ADICIONALES.**

## Completed

- iOS 27.1 SDK build succeeds with the iOS 18 deployment target unchanged.
- Compact/regular navigation and editor layout changes are implemented with availability fallbacks.
- The two supplied simulator launch failures were traced and addressed: CloudKit container construction without simulator entitlements, and a false App Group import alert during startup.
- Device Hub confirmed a live MaskID launch and a hinge-safe authentication action in closed, partially open and fully open Duo poses. The requested Duo was restored to its starting closed pose; VitalsPath remained running.
- Document/business logic, subscription identifiers and existing product behavior were left unchanged.
- Source audit, adaptive design, skills audit and test limitations are documented.
- The supplied home screenshots' layout defects have source fixes and a successful Duo build/install. Their post-fix appearance still needs a visual check after the user completes PIN setup.

## Remaining gates

1. iPhone 18 Pro was built, installed and launched first. The generic Duo remains occupied by UpLedger, and the iPad Pro 13-inch (M5) has active Expirely, UpLedger and Personal Care processes; both were left untouched. Recheck the iPad when those sessions release it.
2. Complete authenticated Duo flows (Scan, document editor/inspector continuity, library and capture fold gutters, accessibility Dynamic Type, Split View and camera/fold occlusion). MaskID entered its inactivity lock during this pass; no PIN or credential was configured or bypassed.
3. Run the existing unit and UI suites with a working Xcode test runner and record actual test nodes/results. The UI `.xcresult` reported `result=unknown` and zero tests, so no tests are claimed as passing.
4. Validate the iPad Pro 13-inch (M5) after its current apps release it. The repository has no watchOS app target; watch app flow validation is not applicable.
5. For marketing/App Store creative, activate the base MaskID theme and verify it before capturing. Current Device Hub screenshots were QA inspection only and were not used as creative assets.

## App Store Connect assessment

At the time of the original Duo audit, no release action had been made. The later task 238 upload created and linked build `1162026102401` to prepared version 1.1.6 and the existing TestFlight group, without submitting a review. The latest UI corrections came after that archive and are not in build 2401; include them only in a follow-up build after device validation. Apple's current [screenshot specification](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) lists iPhone Duo outer and inner screenshot sizes and says that Duo screenshots will be required starting April 2027 for apps built with the iOS 27.1 SDK; submitting them will mark a product page as optimized for Duo. Before submission, check the then-current App Store Connect requirements and prepare truthful outer/inner screenshots from a validated build. Apple also currently says iOS/iPadOS submissions must use the iOS 27 SDK or later in its [submission requirements](https://developer.apple.com/app-store/submitting/); task 238's archive and signing status is recorded separately in `tasks/details/238-appstore-release-1-1-6.md`.

## Risk notes

- Xcode's Apple App Resizability skill export was unavailable through `xcrun agent skills export`; see `SKILLS_AUDIT.md`.
- The iOS 27.1 reserved-division layout is visually verified for the lock screen in Device Hub. Other custom layouts still need runtime evidence. User-provided home screenshots are QA evidence only and are not marketing captures; confirm the base MaskID theme before creating any marketing asset.
- The simulator build is unsigned and lacks iCloud, App Group and Keychain access groups. CloudKit and Firebase/Keychain integrations require a correctly entitled signed run.
- The repository includes no watchOS app target; no watch app validation is applicable.
- Build caches were generated under `build/iphone-duo-derived-data`. Repository instructions require user confirmation before cleaning caches or temporary artifacts. No cleanup was performed.

## Incremental revalidation — 2026-10-24

- The floating Scan bottom accessory was removed from the app shell. Four navigation destinations remain; Scan stays on Home as its primary action, with a contextual toolbar entry on iPad Home.
- Settings now begins its scroll content with the summary card immediately below the navigation header; all settings sections follow it.
- iPhone 18 Pro iOS 27.0 passed four focused UI tests after these changes: Home intake, quick-tools expansion, Settings close, and summary-card order (`/private/tmp/MaskID-239-iPhone18-AfterHomeLayout.xcresult`). After unifying the primary and contextual Scan routes, Home intake passed again 1/1 (`/private/tmp/MaskID-239-iPhone18-IntakeOnly.xcresult`).
- The latest Duo test attempt did not finalize its `.xcresult`; no pass is claimed. A separate project's test session then used the same simulator, and SchoolSnap remained foregrounded at the latest check. Wait for Duo to become free before repeating.
- The iPad currently has no matching foreground app process, but its post-fix UI tests have not yet been rerun. Earlier failures in quick-tools expansion and the iPad Scan toolbar action must be checked against the latest build.
