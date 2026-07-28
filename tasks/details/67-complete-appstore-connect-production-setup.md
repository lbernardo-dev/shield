# 67-complete-appstore-connect-production-setup

- Number: 67
- Slug: complete-appstore-connect-production-setup

## Notes

## Outcome

- Kept the active submission in `WAITING_FOR_REVIEW`. Withdrawing it would only
  discard its queue position: App Store Connect reports no blocking issues and
  none of the corrections require a different binary or a resubmission.
- App: `MaskID: Protect Your Identity` (`6790398619`)
- Version: `1.0.0` (`d49e36c8-3182-4f27-9189-b5c86647c1a7`)
- Build: `100202607202` (`d19733d2-3df9-400f-af0f-c745b34cf572`), `VALID`
- Submission: `308efc39-f0d9-43ab-9add-b7cb159f7239`, submitted
  `2026-07-20T15:44:11.075Z`

## App Store Connect audit

- Version, build, three in-app purchase products, and subscription group are
  included in the five-item submission and all report `READY_FOR_REVIEW`.
- English and Spanish metadata, screenshots/app previews, review information,
  URLs, age rating, content rights, privacy publication, pricing, and
  availability in 175 territories are populated and valid.
- Commercial and legal agreements are active.
- Strict in-app purchase and subscription validation: 0 errors, 0 warnings.
- Metadata validation: 0 errors; metadata push dry-run: no changes.
- Final submission health check: `WAITING_FOR_REVIEW`, `blockingIssues: []`.

## RevenueCat and StoreKit corrections

- Configured the production and sandbox App Store Server Notification URLs from
  RevenueCat into App Store Connect.
- Enabled RevenueCat's “Track new purchases from server-to-server
  notifications” option.
- Corrected the default offering package mapping:
  - Monthly: `com.romerodev.shield.pro.monthly`
  - Annual: `com.romerodev.shield.pro.annual`
  - Lifetime: `com.romerodev.shield.pro.lifetime.unlock`
- Verified the `MaskID Pro` entitlement, bundle identifier, In-App Purchase key,
  and App Store Connect API key.
- Left the app-specific shared secret empty intentionally. It is deprecated and
  only required for legacy StoreKit 1 receipt validation; this app targets iOS
  18 and uses RevenueCat 5.81.1 with StoreKit 2.
- RevenueCat will continue to show “No notifications received” until the first
  sandbox or production purchase event reaches the endpoint.

## Accessibility

- Prepared truthful draft accessibility declarations for iPhone and iPad:
  VoiceOver, dark interface, and reduced motion.
- Apple rejects publication of these declarations until the app is available
  on the App Store. They must be published immediately after version 1.0.0 goes
  live.

## Local verification

- Strict project build succeeded.
- Unit tests passed.
- The full UI run exposed four test-harness assumptions rather than release
  defects. The debug-only ASO overlay dismissal and UI test navigation logic
  were hardened.
- Targeted iOS 18.6 regressions passed for paywall dismissal, primary
  tab/capture navigation, editor export/dismissal, and all Settings routes.
- The test/debug changes do not alter the submitted release binary, so a new
  archive is not required.
