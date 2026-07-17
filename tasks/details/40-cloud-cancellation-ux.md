# 40-cloud-cancellation-ux

- Number: 40
- Slug: cloud-cancellation-ux

## Notes

- OAuth cancellation is now a neutral, reassuring state rather than a technical
  error. It never shows the raw `ASWebAuthenticationSession` message.
- Added a provider-branded SwiftUI illustration with a gentle floating motion,
  SF Symbol feedback, and a static Reduce Motion alternative.
- Added explicit recovery actions for reconnecting and choosing a different
  provider, with stable accessibility identifiers.
- Other cloud failures are classified into unavailable, expired session,
  unsupported file, and connection states with localized, actionable copy.
- Validation: Debug build succeeded on iPhone 16 / iOS 18.6 simulator. Dropbox
  cancellation, reconnect, and choose-provider actions were exercised manually.
