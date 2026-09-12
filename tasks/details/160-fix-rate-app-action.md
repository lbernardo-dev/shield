# 160-fix-rate-app-action

- Number: 160
- Slug: fix-rate-app-action

## Notes
# Notes

- Root cause: the manual Settings action was routed through SwiftUI's `RequestReviewAction`; Apple does not display that review prompt in TestFlight builds.
- Fix: the manual action now opens `AppStoreConfiguration.writeReviewURL` with `action=write-review`, with a localized fallback alert if the URL cannot be opened. Automatic natural-pause review opportunities continue using the native StoreKit request action.
- Validation: `ShieldTests/AppReviewManagerTests` passed, `ShieldUITests/ShieldLaunchTests/testRateAppOpensManualStoreReviewPage` passed, and `git diff --check` passed.
