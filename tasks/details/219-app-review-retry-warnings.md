# 219-app-review-retry-warnings

- Number: 219
- Slug: app-review-retry-warnings

## Completed

- Updated the subscription purchase flow for Guideline 3.1.2(c): eligible annual offers disclose the trial duration, the StoreKit-localized charge and billing period after the trial, and automatic renewal before the CTA. The CTA distinguishes a free trial from a direct purchase. English and Spanish copy are covered by `SubscriptionExperienceTests`.
- Improved paywall contrast, selected-plan treatment, pricing, disclosure hierarchy, CTA, and legal-link clarity. Simulator review found the annual offer and fixed footer readable without overlap or truncation.
- Fixed the project Swift concurrency warning in `SettingsDestinationViews.swift`. Release build has no project Swift warnings. Xcode reports the informational App Intents metadata extraction notice because this target does not use App Intents.
- Validation: iPhone 18 Pro, iOS 27.0, 9 tests passed; iPad Pro 13-inch (M5), iPadOS 27.0, 10 tests passed. Both destinations were explicit. Subscription tests cover the 7-day trial, exact next charge, automatic renewal, Spanish wording, and recurring renewal without a trial. No runtime warnings.
- Archived version 1.1.3 build `1132026100802` at `.asc/artifacts/MaskID-1.1.3-1132026100802.xcarchive`. Xcode Organizer used the signed-in Admin account's cloud signing assets and confirmed upload to Apple. App Store Connect accepted the upload and reports build `VALID`.
- Replaced the rejected version's attached build with `1132026100802`; updated App Review notes with the corrected subscription disclosure and reviewer path.
- Resubmitted the existing review submission `3643c8c8-61df-491d-a360-84d3876b2c07` through App Store Connect. It contains the corrected app build and `MaskID Pro Annual Event`; both items are `WAITING_FOR_REVIEW`. Current review state: `WAITING_FOR_REVIEW`.
- Removed the empty draft created during API-path diagnosis. App Store Connect now reports no stray `READY_FOR_REVIEW` drafts.
- Xcode's upload log showed non-blocking missing-dSYM warnings for FirebaseAnalytics and GoogleAppMeasurement. They do not block upload or App Review; those binary SDKs did not include matching dSYM bundles in this archive. This is separate from the resolved subscription rejection.
- Cleanup was run after the build and tests. The release archive under `.asc/artifacts/` was preserved.
