# 58-ui-experience-audit

- Number: 58
- Slug: ui-experience-audit

## Notes

## Scope audited

- Application shell, compact tab bar and regular-width sidebar.
- Library, capture/import, editor, vault, gallery, settings, onboarding and both purchase surfaces.
- Existing XCUITest accessibility coverage in English and Spanish for all ASO scenes.

## Remediations

- Removed window-scene safe-area probing from the compact tab bar and let the shell's `safeAreaInset` own the bottom layout.
- Enlarged editor chrome actions to the 44 pt interactive target and exposed the scan-adjustment action to VoiceOver.
- Represented custom toggles as native accessibility toggles and added purposeful labels/hints for protected document rows.
- Prevented the main and onboarding paywalls from exposing a checkout action for an unavailable product; each now selects an available SKU or disables checkout.
- Removed negative tracking from display text to preserve legibility with Dynamic Type and Spanish strings.
- Removed dead capture presentation state.

## Validation

- Debug simulator build, iPhone 16: passed.
- Full `ShieldLaunchTests` accessibility suite: passed.
- Focused onboarding/paywall accessibility regressions, English and Spanish: passed.

## Residual validation

- Complete a manual pass on a physical iPhone with the largest accessibility text size, VoiceOver, Reduce Motion, an active RevenueCat offering, camera access, and a real document import. Those dependencies cannot be fully exercised by the deterministic simulator scenes.
