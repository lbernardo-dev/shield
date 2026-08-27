# Task 139: Personal PIN Setup, Face ID Unlocking & Dev PIN Purging

## Problem Solved
1. **Residual Development PIN in Keychain**: In iOS, Keychain items persist across app reinstalls. If a developer or previous build saved a PIN to Keychain, a fresh install would inherit that unknown PIN upon closing and reopening the app, locking the user out.
2. **Missing Personal PIN Configuration**: The onboarding flow previously did not include a PIN setup step or Face ID prompt, leaving users without a configured PIN.
3. **Biometrics Inactive by Default**: `UserDefaults` for `shield.biometric` was not enabled by default or in onboarding, preventing Face ID unlocks on devices supporting biometrics.

## Solutions Implemented
1. **Fresh Install Sanitization** (`AppSessionCoordinator.swift`):
   - Added an install detection marker (`shield.installed`).
   - If the app is launched on a fresh install before completing onboarding, `PINManager.clear()` purges any orphaned Keychain data.
2. **Onboarding Security Step** (`OBSecuritySetupView` in `OnboardingSteps.swift`, `OnboardingFlowView.swift`, `OnboardingState.swift`):
   - Users configure their personal 6-digit PIN with digit confirmation.
   - If biometrics is supported (`LAContext`), offers immediate Face ID enablement.
   - Saves personal credentials via `PINManager.save(pin:)`.
3. **Smart Biometric & PIN Unlocking** (`LockScreenView` in `OnboardingView.swift`):
   - Automatically detects device biometric support (`hasBiometrics`).
   - Defaults to Face ID as primary unlock if available, with auto-prompt on appear.
   - Fallback button allows unlocking with personal PIN or configuring a new PIN if none is present.
   - Retry button available if Face ID evaluation fails or is dismissed.
4. **Localization** (`Onboarding.xcstrings`, `Auth.xcstrings`):
   - Added complete Spanish and English localized strings for PIN setup, confirmation, mismatch, Face ID prompt, and skip actions.
5. **Automated Testing** (`SecurityPrivacyTests.swift`, `ShieldLaunchTests.swift`):
   - Added unit test `freshInstallPurgesOrphanedKeychainData()` verifying Keychain cleanup on fresh installs.
   - Updated PIN lifecycle unit tests and UI launch tests. Full test suite passing.
