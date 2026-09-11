# 157-app-review-feedback-intelligence-system

- Number: 157
- Slug: app-review-feedback-intelligence-system

## Notes

## Audit

- Existing review behavior was a score-based `AppReviewManager` with direct UIKit StoreKit presentation from import/export flows; there was no independent feedback policy or subscription lifecycle model.
- RevenueCat 5.81.1 remains the entitlement source of truth for Pro. StoreKit 2 is used only for verified subscription status and the native manage-subscriptions sheet.
- Existing support destination `romerodev.app+maskid@gmail.com`, Firebase opt-in analytics, English/Spanish String Catalogs, and App Store ID `6790398619` were reused.

## Implementation

- Replaced the old score model with `ReviewFeedbackCoordinator`, `EngagementEvent`, persisted `EngagementState`, pure review eligibility rules, pure subscription transition rules, and contextual feedback triggers.
- Added free and premium thresholds, 72-hour relationship age, 24-hour post-purchase deferral, 120-day automatic cooldown, per-version attempt guard, negative-signal suppression, and feedback cooldown.
- Added event instrumentation for launch/session/onboarding/import/export/premium results/purchase/entitlement transitions/failures and natural-pause arbitration at completed export.
- Added hard presentation gates for onboarding, paywalls, busy/error/destructive/sensitive flows, support/cancellation contexts, and immediate post-payment states.
- Kept the only `requestReview()` call inside a SwiftUI `@Environment(\.requestReview)` bridge. No rating question, star filter, review outcome claim, or custom StoreKit transaction listener was added.
- Added a native localized feedback sheet with contextual categories, optional privacy-warning comment, Dynamic Type/VoiceOver-compatible controls, mail transport, and a minimal thank-you confirmation.
- Added English/Spanish localization, event map, architecture/privacy documentation, and regression tests for thresholds, deferral, cooldown/version, gates, cancellation-vs-billing classification, categories, and data minimization.

## Validation

- `AGENT_NAME=CODEX rtk make build` — passed with `SWIFT_STRICT_CONCURRENCY=complete`.
- Focused `AppReviewManagerTests` — 11 tests passed.
- `AGENT_NAME=CODEX rtk make test` — passed: 32 UI tests with 0 failures plus the full unit-test bundle; result at `build/logs/CODEX/test.xcresult`.
- `rtk git diff --check` and `rtk jq empty Shield/Localization/Strings/SettingsInfo.xcstrings` — passed.

## Follow-up / external configuration

- The current production transport is email because the repository has no feedback backend. A future HTTPS/Supabase transport can conform to `FeedbackTransport` without changing policy.
- RevenueCat dashboard product identifiers and App Store Connect subscription-group status still need to be verified in the release environment; no external submission or upload was performed by this task.
- The existing StoreKit fixture still contains the repository's lifetime product; the runtime tier model supports lifetime without treating purchase completion alone as review value.
