# 66-audit-cross-app-rejection-risks

- Number: 66
- Slug: audit-cross-app-rejection-risks

## Source rejection compared

StreakReps submission `8b7802a1-bb61-4eb4-9324-ea5cfa93ac2d` was rejected for:

1. Age Rating incorrectly declaring age assurance / in-app controls.
2. WeatherKit attribution uncertainty.
3. Missing distinct Restore Purchases control.
4. Unsupported `UIBackgroundModes = audio`.
5. Duplicate promotional artwork across IAP/subscription products.

## MaskID findings

### 1. Age Rating

- Remote MaskID age declaration has `parentalControls: false`.
- Remote MaskID age declaration has `ageAssurance: false`.
- All other content-rating risk fields are false or `NONE`.
- Result: not affected.

### 2. WeatherKit

- Submitted build `100202607202` build-bundle entitlements contain no WeatherKit entitlement.
- The registered MaskID bundle ID capabilities contain IAP, Push Notifications, iCloud and App Groups, but no WeatherKit.
- No WeatherKit import, service, attribution API or WeatherKit code exists in the project.
- Result: not affected.

### 3. Restore Purchases

- Main paywall has a distinct localized `Restore purchase` / `Restaurar compra` button.
- Onboarding purchase screen has the same distinct restore control.
- Both call `PremiumManager.restore()`.
- `PremiumManager.restore()` directly awaits `Purchases.shared.restorePurchases()` and reapplies the returned entitlement state.
- Automatic customer-info refresh exists only as a supplemental path.
- Result: compliant with Guideline 3.1.1.

### 4. Background audio

- Main and Share Extension Info.plist files have no `UIBackgroundModes`.
- Project/build settings contain no `UIBackgroundModes` or `audio` background-mode declaration.
- Submitted build bundle requires only the `arm64` device capability and has no audio-related entitlement.
- The app contains no persistent background-audio feature.
- Result: not affected.

### 5. Promotional images

- Annual remote image: `maskid-pro-annual-1024.png`, 1,327,136 bytes, complete.
- Monthly remote image: `maskid-pro-monthly-1024.png`, 1,328,858 bytes, complete.
- Remote sizes exactly match the local source assets.
- Local MD5 values differ:
  - Annual: `3bf21edf53746cbd33c1eeea388ac330`
  - Monthly: `1ff643b84aaf1df9f6eec7ee97321e12`
- Visual inspection confirms different concepts: annual uses a gold annual-style seal; monthly uses a lunar cycle.
- Lifetime IAP has no promotional image.
- No subscription or IAP promoted purchases are active.
- Result: not affected by duplicate promotional artwork.

## Remote hardening applied

Updated App Review Information notes (`6e2f4e37-9628-4603-ae6a-e2968cd0fc10`) without withdrawing the submission. The notes now:

- give the exact path to both Restore purchase controls;
- explain the direct RevenueCat restore call;
- confirm age assurance and parental controls are absent and declared false;
- confirm MaskID does not use WeatherKit;
- confirm MaskID does not declare background audio;
- explain that annual/monthly artwork is distinct, lifetime has no promotional image, and no promoted purchases are active.

## Final remote verification

- Submission remains `WAITING_FOR_REVIEW`.
- Build remains `VALID`.
- Submission still has five `READY_FOR_REVIEW` items.
- Strict IAP validation: zero errors and zero warnings.
- Strict subscription validation: zero errors and zero warnings.
- App Store Connect reports zero blocking issues.

## Notes
