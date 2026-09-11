# 158-support-email-maskid

- Number: 158
- Slug: support-email-maskid

## Notes

## Changes

- Set the single runtime support source `SettingsSupportConfiguration.email` to `romerodev.app+maskid@gmail.com`.
- The Review/Feedback mail transport inherits that same source, so automatic private feedback and manual Settings feedback stay aligned.
- Updated the bilingual privacy/support copy in `SettingsInfo.xcstrings`.
- Updated English and Spanish privacy, terms, and subscription legal documents.
- Updated the support URL regression test and the previous review-system documentation/task note so the old address is not left in the repository.

## Validation

- Repository search returns no references to the previous support address in source, documentation, legal files, or tests.
- `rtk jq empty Shield/Localization/Strings/SettingsInfo.xcstrings` — passed.
- `AGENT_NAME=CODEX rtk make build` — passed with `SWIFT_STRICT_CONCURRENCY=complete`.
- Focused `SecurityPrivacyTests` — passed, including `feedbackURLIsValid`.
- `rtk git diff --check` — passed.

## Scope note

- No App Store Connect upload, submission, or external support website deployment was performed. The repository-side email configuration and all local public/legal references are aligned.
