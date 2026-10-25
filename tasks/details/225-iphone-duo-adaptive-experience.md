# 225-iphone-duo-adaptive-experience

- Number: 225
- Slug: iphone-duo-adaptive-experience

## Scope

Audit and implement the existing MaskID project for adaptive iPhone Duo navigation/editor layouts, preserve iOS 18 compatibility and document evidence and remaining simulator checks.

## Findings

- Project is MaskID (`com.romerodev.shield`, version 1.1.4), not VitalsPath. User confirmed MaskID should be validated on the named `iPhone Duo - VitalsPath Session`; VitalsPath remains installed separately.
- The user previously directed the work to Duo. For this pass, the required iPhone 18 Pro (iOS 27.0, `1454EA8D-A019-4B07-B57C-1433E0F21BE0`) showed no foreground app in its launchd application list, so it was used first as required; MaskID was installed and launched there. The separate generic Duo remained on UpLedger and was left untouched.
- Existing Duo documentation claimed reserved-region handling and fold validation that were absent in source; it is marked historical and superseded by `Docs/iphone-duo/`.
- The attached launch report showed `CKContainer(identifier:)` trapping in `PremiumManager.init()` because an unsigned simulator process lacks the iCloud container entitlement.
- A later launch report showed UIKit aborting while presenting an alert. On unsigned simulator builds, the missing App Group inbox was misreported as a shared-import failure during ordinary startup.
- Device Hub showed the full-width lock-screen action crossing the division region in the partially open pose. The screen also enters its normal lock state after the configured inactivity timeout; no PIN or biometric credential was changed for this task.
- The supplied Duo home screenshots exposed an empty floating capsule in regular-width navigation, category chips wrapping or clipping, an unbalanced two-column hierarchy with a mostly empty recent-documents side, a missing primary Scan action, a truncated free-plan counter and privacy description at compact width, and a duplicate empty-state action competing with the persistent Scan accessory. The empty-state helper copy also referred to a `+` control that is not shown.
- Coordination: task 95 (`lock-screen-activity-summary`) also lists `Shield/Views/Onboarding/OnboardingView.swift`; this task's change is limited to Duo panel placement so the pending lock-screen work can preserve it.

## Changes

- Use one `.sidebarAdaptable` TabView on iOS 26+, with system Scan accessory/sidebar action; keep pre-iOS 26 fallback.
- Use `ArrangementView(.split)` for the iOS 27.1 editor canvas/inspector, with compact-width fallback and earlier-OS HStack.
- Lift inspector tab selection above the adaptive layout boundary and preserve Scan target dimensions.
- Make the legacy compact tab row scale with Dynamic Type and use icon-only visuals at accessibility text sizes while retaining accessibility labels.
- Add active vertical reserved-division gutter support for the home and capture two-column layouts; revert to one column at accessibility text sizes.
- Keep lock-screen authentication content and its primary action within the leading panel around an active vertical Duo division, respecting RTL layout direction.
- Skip CloudKit container construction in simulator processes without iCloud entitlements; ignore an unavailable App Group inbox during normal simulator startup instead of presenting a false error alert.
- Attach the Scan bottom accessory only in compact navigation and use the sidebar Scan action in regular width so the regular layout does not reserve an empty capsule.
- Recompose the regular-width Duo home with a shared, fold-aware page heading and primary Scan action, balanced two-column sections, a surfaced recent-documents empty state and tools card. Keep category chips on one horizontal scrolling line so labels cannot split mid-word.
- Add compact scroll-content margin for the floating accessory, remove the duplicate empty-state Scan button while preserving Clear Filters, and allow compact quota/privacy copy to wrap.
- Update empty-state copy to say “scan or import” without directing users to a missing plus button.
- Added the requested skills, baseline, design, UX, implementation, test matrix, before/after and release readiness reports.

## Verification

- Xcode 27.1 / iOS Simulator SDK 27.1 build succeeded for iPhone 18 Pro (iOS 27.0), then the resulting build was installed and launched as PID 57339.
- Rebuilt after the screenshot-driven home changes for iPhone 18 Pro, then installed and launched the same build on `iPhone Duo - VitalsPath Session` (`EBD930CD-55C3-4C41-9987-C6DB90EDCFC6`, iOS 27.1; PID 57594). Device Hub confirmed MaskID stayed in the foreground at the local-PIN setup screen, with no startup crash.
- Post-fix home appearance is not visually confirmed because the app requires a user-set local PIN before exposing the authenticated library. Credential setup/entry was left to the user. The VitalsPath app was not launched, stopped, or removed.
- The iPad Pro 13-inch (M5) is booted but has active `com.romerodev.expirely`, `com.upledger.app` and `com.romerodev.personalcare` processes. It was not taken over. No watchOS app target is present in the project, so watch installation/pairing is unavailable.
- Visually inspected Duo closed, partially open and open poses. The lock-screen action stays within one panel after the reserved-division adjustment; the device was restored to its initial closed pose.
- Verified Documentos → Estilos navigation in the authenticated home before the inactivity auto-lock. Protected scan, editor and PIN flows were not entered.
- `git diff --check`: passed.
- Existing test commands did not produce a passing test result: the UI result bundle reported `result=unknown` and zero tests. See `Docs/iphone-duo/TEST_MATRIX.md`.

