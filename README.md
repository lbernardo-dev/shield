# MaskID

MaskID is a local-first iOS workspace for masking sensitive document data,
reviewing the result, and exporting a protected copy. Import PDFs and images,
use on-device text recognition as a review aid, adjust each mask, and inspect
the exported result before sharing it.

## Development

- Xcode 27.2 and the iOS 27.2 SDK were used for the current release candidate.
- The app target is `Shield` (`com.romerodev.shield`) and the minimum iOS target
  is 18.0. The project also contains a share extension and a widget extension;
  it has no Watch, macOS, tvOS, or Live Activities target.
- Resolve packages with `xcodebuild -resolvePackageDependencies -project Shield.xcodeproj -scheme Shield`.
- Run the simulator suite with `xcodebuild test -project Shield.xcodeproj -scheme Shield -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.2'`.
- Product code is organized around SwiftUI views, view models, local encrypted
  document storage, StoreKit 2/RevenueCat access, and optional CloudKit sync.
  Keep document contents out of logs and analytics.

## Monetization and access

- New installs may activate 15 calendar days of internal Premium access. This is
  not an App Store trial and does not create a purchase or automatic renewal.
- Free installs that predate the migration receive 30 days of full access plus
  30 days of read-only data recovery.
- When temporary access ends, commercial workflows require a purchase. Users
  keep minimum access to restore/manage purchases, contact support, read legal
  terms, and view/export/delete their own data.
- Verified RevenueCat entitlement or an existing lifetime entitlement takes
  precedence over the temporary access clock.
- Spain prices approved for the current catalog: €2.99 monthly, €29.99 annual,
  and €49.99 optional lifetime. No weekly plan and no new annual introductory
  trial. International price strings come from StoreKit/RevenueCat.

Implementation notes and the Fase 03 handoff are in
[`Docs/MONETIZATION_MIGRATION_SUMMARY.md`](Docs/MONETIZATION_MIGRATION_SUMMARY.md)
and [`Docs/release-cycle/FASE_03_HANDOFF.json`](Docs/release-cycle/FASE_03_HANDOFF.json).
The Fase 04 certification package is in
[`Docs/release-cycle/04_RELEASE/00_RELEASE_EXECUTIVE.md`](Docs/release-cycle/04_RELEASE/00_RELEASE_EXECUTIVE.md).
The current local candidate is 1.1.7; it has not been submitted to App Store
Connect. Legal review, purchase Sandbox verification, and remaining external
release checks are still required.

## Product limits

The access period is stored locally and is not backed by a MaskID account.
Keychain state and local clock changes do not provide an absolute anti-reset or
trusted-time guarantee. CloudKit document sync is optional and requires an
Apple account; Vault documents remain local. The export review helps surface
issues but cannot prove that every sensitive area was selected, so users must
review the full document and destination.

## Review and feedback

The reusable, event-driven App Store review and private feedback system is
documented in [Docs/REVIEW_FEEDBACK_SYSTEM.md](Docs/REVIEW_FEEDBACK_SYSTEM.md).
The product-specific event catalog is in
[Docs/REVIEW_FEEDBACK_EVENT_MAP.md](Docs/REVIEW_FEEDBACK_EVENT_MAP.md).

Review and feedback remain independent. RevenueCat is the purchase entitlement
authority, StoreKit 2 supplies product metadata and Apple-managed purchase UI,
and feedback telemetry excludes document and OCR content.
