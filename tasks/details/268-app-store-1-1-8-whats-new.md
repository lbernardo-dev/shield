# 268-app-store-1-1-8-whats-new

- Number: 268
- Slug: app-store-1-1-8-whats-new

## Notes

- App Store Connect app `6790398619`: created draft version `1.1.8`, version ID `66729eb3-04f6-4f8d-81a9-5ebcd57bebc7`, state `PREPARE_FOR_SUBMISSION`. No review submission or public release was started.
- Uploaded build `1182026111901`, build ID `a49137d9-c16d-4312-a466-4e8327a4c7cb`, processing state `VALID`, minimum iOS `18.0`; attached it to the version. The version has no review submission relationship.
- Changed Xcode Release and Debug settings for `Shield`, `ShieldShareExtension`, and `ShieldWidgetExtension` to `1.1.8 (1182026111901)`. The archive and IPA both report those values for all three bundles.
- Added the 1.1.8 in-app What's New sheet with three localized highlights in the app's only supported languages, English and Spanish: verified private-feedback extension, clearer update prompts, and review prompts after successful use at a natural pause.
- Wrote the App Store What's New in `en-US` (461 chars) and `es-ES` (546 chars) under `metadata/version/1.1.8/`. Staging applied both locales. App Info names, subtitles, and privacy URLs were confirmed to match the canonical local files.
- Archive: `.asc/artifacts/MaskID-1.1.8-1182026111901-final.xcarchive`. IPA: `.asc/artifacts/MaskID-1.1.8-1182026111901-final.ipa`. IPA SHA-256: `815a55959e98414ea33448eb8de3cf022f619802a6de3e6d646f32150c8dd78b`.
- Verification: Archive succeeded; IPA ZIP, versions, embedded extensions, App Store signature, and absence of the StoreKit fixture were checked. `asc metadata validate` reported 0 errors and 0 warnings. Final `asc validate` reported 0 errors and 0 blocking issues, 1 non-blocking warning (Spanish keyword overlap with subtitle), and 2 informational items (manual release and App Privacy state unavailable through the public API). Automated tests were not run.
- Preserved release artifacts and temporary export output/logs. No cleanup was run; follow the repository's cleanup confirmation rule before removing temporary files or build caches.

