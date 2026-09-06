# 146-audit-remediation-preflight

- Number: 146
- Slug: audit-remediation-preflight

## Notes

- **Preflight Fixes**:
  - Corrected widget bundle identifier regex in `scripts/app_store_preflight.sh` to handle optional quotation marks (`"?com\.romerodev\.shield\.widgets"?`).
  - Broadened usage descriptions check (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSFaceIDUsageDescription`) to scan both `project.pbxproj` and `Shield/Localization/Strings/InfoPlist.xcstrings`.
  - Validated both `./scripts/app_store_preflight.sh --local` and `./scripts/app_store_preflight.sh --remote` -> Exit code 0 (all OK).

- **Legal Compliance & Alignment**:
  - Updated `Docs/legal/privacy.html` §3 in English and Spanish to explicitly specify that private CloudKit sync covers restorable document packages (document metadata, original and working images, extracted text fields, and redaction masks) while Vault documents remain strictly local.
  - Aligned effective dates across `Docs/legal/privacy.html`, `Docs/legal/terms.html`, and `Docs/legal/subscription-terms.html` to September 6, 2026.

- **App Store Submission**:
  - Validated version 1.0.7 readiness via `asc review doctor --app 6790398619` -> 0 errors, 0 warnings, 0 blocking.
  - Attached build `107202609062` (ID `79426836-1bf9-418b-9648-41b2131c35d8`).
  - Executed submission via `asc review submit --app 6790398619 --version 1.0.7 --build 79426836-1bf9-418b-9648-41b2131c35d8 --confirm`.
  - Submission created (ID `61a6f3e2-a386-497d-bba2-6b14379b98ac`).
  - Verified live status in App Store Connect: state is now `WAITING_FOR_REVIEW`.

- **Engineering Verification**:
  - `AGENT_NAME=CODEX make build`: `** BUILD SUCCEEDED **` with `SWIFT_STRICT_CONCURRENCY=complete` across Shield, ShieldWidgetExtension, and ShieldShareExtension.
