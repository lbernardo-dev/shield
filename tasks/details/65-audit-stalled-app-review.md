# 65-audit-stalled-app-review

- Number: 65
- Slug: audit-stalled-app-review

## Remote state

- App: `MaskID: Protect Your Identity` (`6790398619`)
- Version: `1.0.0` (`d49e36c8-3182-4f27-9189-b5c86647c1a7`)
- Build: `100202607202` (`d19733d2-3df9-400f-af0f-c745b34cf572`), `VALID`
- Submission: `308efc39-f0d9-43ab-9add-b7cb159f7239`
- Submitted: `2026-07-20T15:44:11.075Z`
- State at final check: `WAITING_FOR_REVIEW`
- App Store Connect summary: no blockers; next action is to wait for App Review.
- Apple is the last actor recorded on the active submission.

## Checks completed

- Active submission contains five ready review items: the app version, subscription group, annual subscription, monthly subscription, and lifetime non-consumable.
- Attached build is processed and valid, targets iOS 18.0, and declares no non-exempt encryption.
- English and Spanish app-info and version metadata are complete.
- Canonical metadata validation with subscription heuristics returned zero errors and zero warnings.
- Metadata push dry run returned `no changes`.
- Review contact and reviewer instructions are populated; no demo account is required.
- Content rights are `DOES_NOT_USE_THIRD_PARTY_CONTENT`.
- Age rating is complete and resolves to 4+.
- Availability exists in all 175 returned territories and includes future territories.
- Strict IAP validation: zero errors and zero warnings.
- Strict subscription validation: zero errors and zero warnings.
- Both locales have complete 6.9-inch iPhone and 12.9-inch iPad screenshot sets.
- Both locales have a fully processed 6.9-inch App Preview.
- Privacy, support, marketing, and Terms URLs return HTTP 200.
- Published privacy policy describes Firebase Analytics, Crashlytics, RevenueCat, optional private CloudKit use, and no cross-app tracking.
- Prior release audit records that the matching Firebase/RevenueCat App Privacy declaration was published before this submission.

## Non-blocking limitations and decisions

- The public API cannot read the App Privacy publish flag or account-level agreement state.
- The cached App Store Connect web session is expired and the available browser is not authenticated.
- App Privacy publication is nevertheless supported by the prior authenticated audit and by the current accepted in-flight submission with no blocking issues.
- Accessibility declarations are absent but optional and not a submission blocker.
- Release type is intentionally `MANUAL`.
- No remote mutation was made. Canceling and resubmitting would reset the queue without fixing any detected problem.

## Conclusion

The App Store Connect record is complete and internally consistent. The current delay is an Apple review queue delay, not a missing ficha field. If the state remains unchanged after seven full days from the active submission timestamp, contact App Review Support from the App Review page; do not withdraw the submission first.

## Notes

### Authenticated App Store Connect verification — 2026-07-26

- App Privacy is explicitly marked `Published 6 days ago`.
- The published declaration contains six data types: Device ID, Product Interaction, Crash Data, Performance Data, Other Diagnostic Data, and Purchase History.
- The product-page preview reports no tracking category; diagnostics, identifiers, and usage data are linked to the user, while purchases and part of diagnostics are not linked.
- The privacy-policy URL is populated.
- Free Apps Agreement and Paid Apps Agreement are both `Active`.
- Bank account, U.S. tax forms, Digital Services Act, and DAC7 compliance are all `Active`.
- The App Review page shows the active submission from July 20, 2026 at 5:44 PM with five items, all `Waiting for Review`.
- No reviewer message, unresolved issue, or required action is displayed.
- Authenticated conclusion: the delay is not caused by an unpublished privacy declaration, an inactive commercial agreement, or a hidden review action.
