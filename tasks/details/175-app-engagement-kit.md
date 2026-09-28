# 175-app-engagement-kit

- Number: 175
- Slug: app-engagement-kit

## Notes

- Audit: reused the existing `ReviewFeedbackCoordinator` as MaskID's only review/feedback orchestrator; RevenueCat remains the entitlement source and StoreKit 2 remains the subscription-status source. No second coordinator or transaction observer was introduced.
- Added local `Packages/AppEngagementKit` with `AppEngagementConfig`, `FeedbackManager`, `ReviewPromptManager`, and `AppInstallMetadataStore`.
- Extended feedback email metadata with app/device/install/update/submission context and documented the privacy contract; mail composer uses `MFMailComposeViewController` with `mailto:` fallback.
- Verification: package compiles in isolation; `engagement-build-cleaned` succeeds; `engagement-tests-build` succeeds; `project.pbxproj`, localization JSON, and `git diff --check` pass. Runtime XCTest execution was unavailable because CoreSimulatorService could not be reached in this environment.
