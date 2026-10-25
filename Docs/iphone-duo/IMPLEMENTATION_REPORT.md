# Implementation report

## Source changes

- `Shield/App/ContentView.swift`: one `.sidebarAdaptable` TabView on iOS 26+ with four persistent destinations. There is no persistent Scan tab or `.tabViewBottomAccessory`; Home keeps its primary Scan action, and iPad Home keeps a contextual toolbar action.
- `Shield/Views/Home/HomeView.swift`: recompose the regular-width Duo dashboard with a shared heading and primary Scan action, a fold-aware gutter between balanced columns, a surfaced recent-documents empty state and a tools card. Keep categories in a single horizontal scrolling strip so labels stay intact. Preserve bottom breathing room in scroll content and remove the duplicate Scan CTA from the empty state while retaining Clear Filters.
- `Shield/Views/Home/HomeDashboardViews.swift`: allow the free-plan counter to wrap and show an additional line of on-device privacy copy at compact width.
- `Shield/Localization/Strings/Home.xcstrings`: remove the stale “Tap +” instruction; the empty-state copy now says to scan or import without pointing to a nonexistent plus button.
- `Shield/Views/Components/TabBar.swift`: keep the four-destination legacy tab bar free of a floating bottom Scan accessory. Keep Scan as a separate Home action and retain Dynamic Type behavior for navigation labels.
- `Shield/Views/Components/Components.swift`, `Shield/Views/Home/HomeView.swift`, `Shield/Views/Capture/CaptureMenuViews.swift`: read active vertical reserved-division width on iOS 27.1+ and widen the two-column gutter; use a one-column layout at accessibility text sizes.
- `Shield/Views/Editor/EditorView.swift`: add width-based compact fallback, lift selected inspector tab state, use an iOS 27.1 `ArrangementView` split for canvas and inspector, and keep HStack fallback for iOS 18–27.0.
- `Shield/Views/Onboarding/OnboardingView.swift`: query the active vertical division on iOS 27.1 and keep the authentication flow within the leading panel, respecting RTL layout direction.
- `Shield/Cloud/CloudSyncManager.swift` and `Shield/Premium/PremiumManager.swift`: avoid constructing CloudKit containers in simulator processes without the configured iCloud entitlement; physical production behavior remains enabled.
- `Shield/App/ShieldApp.swift`: treat an unavailable App Group inbox on an unsigned simulator build as absent input, instead of presenting a false shared-import error during ordinary startup.
- `Shield/Views/Editor/EditorPrivacyInspector.swift`: consume selected tab as a binding instead of owning ephemeral local state.
- `Docs/iphone-duo/`: this audit and validation set.

## Architecture and compatibility

The existing SwiftUI + `ObservableObject` app architecture and editor view model remain. No database/document schema, export rules, Vault security, analytics payloads, premium features, bundle identifiers, dependencies, or minimum deployment target changed. New APIs are guarded by availability and the project still deploys to iOS 18.0.

The editor uses a horizontal two-region relationship because the document canvas and privacy inspector are peers. `ArrangementView` is used on iOS 27.1+; the pre-27.1 regular layout is preserved. iOS 26+ navigation uses standard tab/sidebar presentation. The Duo guidance and these APIs are beta-era per the installed SwiftUI Expert reference; their behavior must be confirmed on the configured simulator.

## Verification status

- Explicit iPhone 18 Pro build, Xcode 27.1 / iOS Simulator SDK 27.0: **BUILD SUCCEEDED**. The device showed no foreground application process before the run; MaskID was installed and launched as PID 57339.
- Rebuilt for iPhone 18 Pro after the home changes: **BUILD SUCCEEDED**. Installed and launched the same build on `iPhone Duo - VitalsPath Session` (`EBD930CD-55C3-4C41-9987-C6DB90EDCFC6`, iOS 27.1); PID 57594 remained visible in Device Hub at the local PIN setup screen, with no startup crash.
- The supplied Duo home screenshots were used as pre-fix visual evidence. The updated library presentation is build/install verified but not visually verified because the app requires PIN setup; credential entry is left to the user.
- Device Hub visual checks: Documentos → Estilos worked in the authenticated home. In closed, partially open and fully open poses, the lock-screen primary action stayed within one display panel. The Duo was returned to its initial closed pose.
- `git diff --check`: passed.
- After removing the floating Scan accessory and moving Settings' summary card to the top, iPhone 18 Pro iOS 27.0 passed four focused UI tests: Home intake, quick-tools expansion, Settings close, and summary-card order. Result: `/private/tmp/MaskID-239-iPhone18-AfterHomeLayout.xcresult`. After unifying the primary and contextual Scan routes, Home intake passed again 1/1 in `/private/tmp/MaskID-239-iPhone18-IntakeOnly.xcresult`.
- The current six-test Duo run executed its test worker but did not produce a finalized `.xcresult` summary: Xcode remained in simulator diagnostics, and another project's UI-test process then used the same Duo. No result is claimed for that run. Re-run on Duo only after the simulator is free. Earlier Duo evidence and pose-specific failures are listed in `TEST_MATRIX.md`.
- The iPad Pro 13-inch (M5) has not yet had a post-fix test run. Earlier results showed quick-tools expansion failing and the contextual Scan toolbar action not opening intake; the Home state-binding fix now passes on iPhone 18 Pro, but the iPad cases must be repeated before closing the matrix.
- After the configured inactivity timeout, the app entered its authentication screen. No PIN was configured or bypassed, leaving Scan, editor, redaction/export and authenticated resize continuity untested.
- At the latest occupancy check, the iPad Pro 13-inch (M5) had no active MaskID/Expir(e)ly/UpLedger/PersonalCare app processes; its post-fix validation remains pending. The project has no watchOS app target, so watch installation and pairing are unavailable.
- The unsigned simulator lacks iCloud/App Group/Keychain entitlements. CloudKit is unavailable in this environment, and Firebase previously logged nonfatal Keychain access errors (`SecItemCopyMatching`, `-34018`); validate those integrations in a correctly entitled signed run.
- `xcrun agent skills export`: attempted; blocked by its Xcode launch/corrupt-app diagnostic, despite `xcodebuild` being usable.
- App Store Connect release 1.1.6 build `1162026102401` is already uploaded and linked to the prepared version and TestFlight group; no review was submitted. The latest local UI corrections were made after that archive, so a distributable build containing them needs a new build number after the simulator gate passes.
