# 169 — TestFlight release (build 10112026091301)

- Number: 169
- Slug: release-testflight-1011202609131

## Implementation

- Requested build override: `10112026091301`.
- Updated `Shield`, `ShieldShareExtension` and `ShieldWidgetExtension` in Debug and Release.
- Bumped the marketing version from `1.0.10` to `1.0.11`, required because Apple had closed the `1.0.10` train.
- Created App Store Connect iOS version `1.0.11` in `PREPARE_FOR_SUBMISSION`.
- Local verification: all three Release configurations report version `1.0.11` and build `10112026091301`.
- Archive: `.asc/artifacts/MaskID-10112026091301.xcarchive`.
- IPA: `.asc/artifacts/MaskID-10112026091301.ipa` (138.6 MB).

## App Store Connect

- App: `6790398619` (`MaskID: Protect Private Data`).
- Build ID: `297c41fd-6d67-4de5-a994-dbc8ca868ac4`.
- Processing state: `VALID`.
- TestFlight distribution: assigned to existing internal group `Shield Internal`; no testers were added or invited.
- Previous failed attempt with build `1011202609131` is retained as a historical artifact and was rejected because train `1.0.10` was closed.

## Cleanup and environment

- Restored the original Xcode custom build-location defaults after archiving.
- Temporary export/build directories generated for this task are absent.
- Cleanup dry-run found only pre-existing `build-logs` (9.5G); it was left untouched.
