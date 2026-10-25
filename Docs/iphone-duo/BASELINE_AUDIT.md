# Baseline audit — MaskID

Date: 2026-10-18. Repository: `/Volumes/SSD/DESARROLLO/iOS/MaskID`.

## Product and targets

- Display name: MaskID; Xcode scheme: `Shield`; app bundle identifier: `com.romerodev.shield`.
- Marketing version/build: 1.1.4 (1142026101601).
- App minimum deployment: iOS 18.0; device families iPhone and iPad; Swift language mode 5. Xcode 27.1 / iOS Simulator SDK 27.1 are installed.
- Main app is SwiftUI (`Shield/App/ShieldApp.swift`, `Shield/App/ContentView.swift`) with `ObservableObject` state in `AppState` and an `EditorViewModel`. The app target embeds a Share extension and Widget extension. `ShieldTests` and `ShieldUITests` are present. No watchOS app target or watch scheme was found.
- Resolved packages include Firebase 12.16.0, RevenueCat 5.81.1, Lottie 4.6.1 and the local AppEngagementKit package.

## User-facing areas found in source

1. Library and document dashboard; document details and import.
2. Capture through camera, Files/photos import, document review and on-device OCR.
3. Privacy editor: redaction rectangles and field selection, mask styles, image adjustments, watermark, page navigation, undo/redo and secure export.
4. Secure Vault, style gallery, settings, onboarding, profile and premium/paywall flows.
5. Share extension, widget and App Intents to reopen the app or Vault.

These are source-derived capabilities, not a measured frequency ranking. The high-impact Duo flow selected was library → capture/import → redact → secure export, because it combines the app's primary task and its custom canvas controls.

## Initial compatibility findings

| Severity | Evidence | Impact before changes |
|---|---|---|
| High | `Shield/App/ContentView.swift` chose two different navigation trees from `horizontalSizeClass`. The compact branch used a custom bottom inset while the regular branch used a system `TabView`. | A size-class change replaced navigation presentation during an open/close/resize transition. Tab selection lived in `AppState`, but native container continuity and system Duo chrome were not used in compact width. |
| High | `Shield/Views/Editor/EditorView.swift` showed its three-region HStack whenever horizontal size class was regular. The inspector had a 300 pt minimum while the multi-page rail consumed at least 110 pt; there was no available-width fallback. | In narrow regular windows (Split View or resized windows), the canvas could be squeezed below a useful width. |
| Medium | `HomeView` and `CaptureMenuViews` reflowed to two columns for every regular size class with an 8/18 pt gap, without accounting for an active vertical division or large accessibility text. | Cards and controls could sit too close to the Duo fold; large Dynamic Type remained unnecessarily dense. The current implementation adds an active-division gutter and uses one column at accessibility text sizes. |
| Medium | `EditorPrivacyInspector` owned its selected tab in local `@State` and was removed in the compact layout. | Switching into compact layout discarded the inspector tab selection. |
| Low | `Shield/Views/Components/TabBar.swift` rendered legacy compact tab labels with a fixed 10 pt font inside a fixed-height bar. | Text could remain too small under Dynamic Type; the fallback now uses scalable type and hides visual labels at accessibility text sizes while keeping VoiceOver labels. |
| Medium | `Docs/IPHONE_DUO_ADAPTATION.md` claimed reserved-region handling, hinge-aware displacement and pose validation, while the source contained no `ArrangementView` or `GeometryProxy.reservedRegions` usage. | The existing document overstated implementation and validation. It also described coordinate-delta behavior as resize-stable without runtime evidence. |
| Low | The previous compact `ShieldTabBar` used a fixed-height custom horizontal bar; the existing `ShieldScanAccessory` was not attached to a `TabView`. | Custom chrome could conflict with the system's compact/vertical tab controls on newer Duo presentations. |

Source search found no `UIScreen.main`, screen-resolution layout conditions, or model-based layout branching. `UIDevice.current.model` appears in `AppReviewManager` analytics/review code, not in layout decisions.

## Test baseline

The repository contains 118 Swift Testing unit tests across 18 source files and 34 UI tests, based on source inventory. Existing coordinate tests cover normalized geometry, not Duo system bars, reserved regions, fold transitions, or state continuity. A baseline simulator test run was not completed before edits: the required iPhone 18 Pro simulator was already occupied by another app session, and repository instructions forbid taking it over. The pre-edit generic build was started but its exit status was not retained, so it is not reported as a pass. Post-edit build and simulator results are recorded in `TEST_MATRIX.md`.

## Initial repository state

Before this task's workflow entry was created, `git status --short` was clean. The task ledger entry and detail note are task-workflow records; they are not pre-existing user edits.
