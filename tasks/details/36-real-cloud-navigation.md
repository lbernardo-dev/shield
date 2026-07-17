# 36-real-cloud-navigation

- Number: 36
- Slug: real-cloud-navigation

## Notes

- Confirmed the old Google Drive, Dropbox and OneDrive rows all opened the same
  system Files picker; no provider API or OAuth token was used.
- Added direct OAuth 2.0 Authorization Code + PKCE, Keychain token persistence,
  refresh-token handling, remote folder listing and file downloads for Google
  Drive API and Dropbox API. A missing OAuth registration is reported explicitly
  and never falls back to local Files.
- Rebuilt iCloud sync around complete restorable `CKAsset` document packages,
  bidirectional modified-date reconciliation, encrypted local restoration and
  durable deletion tombstones. The new `ShieldDocumentV2` production schema
  still requires deployment through CloudKit management tooling.
- Added an explicit `settings.back` action to every Settings destination and
  made the UI test require that exact hittable control. The complete Settings
  route test passes on iOS 18.6.
- Debug simulator build passes. Document migration and security/privacy suites
  pass. The wider suite currently has unrelated public-URL network failures.
- Registered the real Google iOS OAuth client and Dropbox scoped app, enabled
  their read-only API scopes, and added their public client IDs plus official
  mobile callback schemes to the app. No client secrets are embedded.
- OneDrive was removed from the product at the user's explicit request after
  Microsoft required an Entra directory/Azure signup; it is deferred until
  there is demonstrated user demand. No Microsoft UI, OAuth branch, Graph call,
  or configuration placeholder remains.
