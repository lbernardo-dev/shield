# 285-fix-vault-infinite-faceid-and-launch-stutter

- Number: 285
- Slug: fix-vault-infinite-faceid-and-launch-stutter

## Root Cause Analysis
1. **Vault Infinite Face ID Loop**: In `VaultView.swift`, `.onChange(of: scenePhase)` was checking `if phase != .active { isUnlocked = false }`. When iOS evaluates biometrics via `LAContext.evaluatePolicy`, it displays the system Face ID alert, shifting `scenePhase` from `.active` to `.inactive`. This immediately re-locked the vault, which re-mounted `lockGate`, whose `.onAppear` called `authenticate()`, triggering an infinite re-entrant loop.
2. **App Launch Stutter & Duplicate Splash Animation**:
   - `LockScreenView.autoPromptIfNeeded()` ran 350ms after launch, while `SplashView` was still playing its 1.5s intro animation, interrupting the splash with Face ID.
   - When `LockScreenView` presented Face ID, `scenePhase` became `.inactive`. In `ContentView.swift`, `if scenePhase != .active { PrivacySnapshotShield().zIndex(10_000) }` popped up on top of `SplashView` (`zIndex(9_000)`).
   - `PrivacySnapshotShield` rendered `MaskIDIdentityMark(size: 200, presentation: .animatedLoop, treatment: .splash)`—the exact same splash animation a second time.
3. **Cloud Connection Robustness**:
   - Google Drive: In Google Cloud Console, OAuth consent screen is in "Testing" mode, returning `Error 403: access_denied` for accounts not in the Test Users list.
   - Dropbox: In `DirectCloudStorageManager.swift`, `withCheckedThrowingContinuation` could potentially be resumed more than once if session completion and startup error raced, which in Swift concurrency triggers a fatal crash.

## Changes Implemented
1. **`Shield/Views/Vault/VaultView.swift`**:
   - Added `isAuthenticating` state flag to prevent concurrent/re-entrant authentication calls.
   - Changed `.onChange(of: scenePhase)` to check `if phase == .background` rather than `!= .active`.
   - Guarded `lockGate.onAppear` with `guard shouldAuthenticateOnGateAppearance, !isUnlocked, !isAuthenticating else { return }`.
   - Added gear shortcut in the header overlay for direct access to Settings.
2. **`Shield/Views/Onboarding/OnboardingView.swift`**:
   - Added `isBlockedBySplash: Bool = false` to `LockScreenView`.
   - Guarded `autoPromptIfNeeded()` with `guard !isBlockedBySplash else { return }`.
   - Added `.onChange(of: isBlockedBySplash) { _, blocked in if !blocked { autoPromptIfNeeded() } }`.
3. **`Shield/App/ContentView.swift`**:
   - Passed `isBlockedBySplash: showSplash` to `LockScreenView`.
   - Gated `PrivacySnapshotShield` to `if scenePhase == .background && sessionStage == .ready && !showSplash`.
   - Changed `MaskIDIdentityMark` presentation in `PrivacySnapshotShield` to `.staticMark`.
4. **`Shield/Cloud/DirectCloudStorageManager.swift`**:
   - Protected `withCheckedThrowingContinuation` in `authorize(at:callbackScheme:)` with an `NSLock` and `hasResumed` guard to guarantee single-resumption safety.

## Verification
- Unit test suite (`ShieldTests`) execution on simulator.
- Physical device build and deployment to iPhone 15 Pro Max (`00008130-0011199026A0001C`).
