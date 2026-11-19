# 266-feedback-review-trial-retention

- Number: 266
- Slug: feedback-review-trial-retention

## Notes

### Product decision

- Keep App Store reviews on Apple's standard StoreKit 2 `requestReview` path. The current eligibility policy asks only after successful, meaningful use, applies a 120-day cooldown, and avoids onboarding, errors, paywalls, payment and support flows. Add a 2-second delay after the natural pause.
- Do not reward or gate access on an App Store rating/review. StoreKit does not report whether its system sheet appeared or whether a review was submitted, so the app cannot verify that action. Apple also prohibits manipulating reviews with paid or incentivized feedback.
- Offer a separate, optional private feedback request near the end of the 15-day access window. Let users request a feature or share another category/comment. If the in-app Mail composer confirms `.sent`, add 15 calendar days to the current expiry once for that access record.
- If Mail cannot confirm sending and the app opens a `mailto:` URL, allow feedback but do not grant the extension. Explain this in Spanish and English before the user submits.

### Implementation

- Added a 24-hour trial-ending opportunity to the engagement coordinator. It waits for the next successful natural pause before presenting; it does not interrupt launch, onboarding or active work.
- Upgraded the Keychain access record to schema 3. Schema 1 migration retains its 15-day migration behavior; schema 2 records preserve their existing dates. A verified feedback extension is stored on the same record and cannot be claimed twice.
- Made the mail transport await the composer delegate result. A canceled/saved draft is not treated as submitted; a fallback email-app handoff is not treated as verified.
- Kept the feedback form and review surfaces localized in Spanish and English, including the feature-request option and explicit reward disclosure.

### Validation

- `xcodebuild -quiet -project Shield.xcodeproj -scheme Shield -configuration Debug -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` — passed.
- `jq empty Shield/Localization/Strings/SettingsInfo.xcstrings` — passed.
- `git diff --check` — passed.
- Unit/UI tests were not run.
