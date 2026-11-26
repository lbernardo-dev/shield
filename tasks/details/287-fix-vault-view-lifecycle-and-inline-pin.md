# 287-fix-vault-view-lifecycle-and-inline-pin

- Number: 287
- Slug: fix-vault-view-lifecycle-and-inline-pin

## Problem
1. **VaultView Constantly Resetting & Flickering**:
   - In `ContentView.swift`, `nativeTabRoot(for:)` wrapped each tab inside a dynamically computed `NavigationStack { tabContent(for: tab) }`. On any state change, SwiftUI destroyed and recreated the entire `NavigationStack` and its contained `VaultView`, wiping all `@State`.
   - Dynamic `.tint(...)` on `TabView` based on `appState.activeTab == .vault` caused UIKit's `UITabBarController` to invalidate and recreate the tab hierarchy when entering Vault.
   - In `VaultView.swift`, `PINEntryView` and `PINSetupView` were presented as `.fullScreenCover` modals. Presenting full-screen modal covers caused presenting views in tabs to unmount and trigger lifecycle re-evaluations, dismissing the PIN pad and re-locking.
   - `lockGate.onAppear` was calling `authenticate()`, which upon biometric failure or cancellation immediately called `presentPINFallback()`, triggering modal presentation thrashing and recursive Face ID / PIN loops.

## Fix
1. **Direct Tab Content Hosting in `ContentView.swift`**:
   - Mounted `HomeView`, `StyleGalleryView`, and `VaultView` directly as children of their `Tab` without intermediate anonymous `NavigationStack` wrappers.
   - Kept a stable `.tint(ShieldTheme.accent(appState.preferredScheme))` on `TabView` to avoid `UITabBarController` reloads.
2. **In-Place PIN Entry Transition in `VaultView.swift`**:
   - Replaced modal `.fullScreenCover` for PIN entry with an in-place `ZStack` view transition (`lockGate` <-> `PINEntryView` / `PINSetupView` <-> `vaultContent`). This guarantees zero modal dismissals, zero unmounting, and rock-solid state persistence.
   - Added `isAutoPrompt: Bool` to `authenticate()`. When auto-prompting on appear, failures do not force open the PIN pad; instead, the user stays on the clean lock gate with the visible "Unlock with Face ID" and "Use PIN" buttons.
   - Guarded `authenticate()` against running while PIN entry or setup is active.
   - Cleanly reset state only on true application background (`phase == .background`).

## Verification
- Run full test suite `ShieldTests`.
- Build for device and deploy to iPhone 15 Pro Max (`00008130-0011199026A0001C`).
- Verify Vault opens cleanly without flicker, Face ID prompts once, PIN pad opens stably in-place and allows PIN entry without closing.
