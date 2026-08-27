# 136-universal-apple-surfaces

- Number: 136
- Slug: universal-apple-surfaces

## Notes

- Added the universal iPad/iPhone release surface documentation and aligned version 1.0.4 English/Spanish metadata with iPad, WidgetKit, Siri, Apple Shortcuts and App Review flows.
- Added ShieldWidgetExtension with Home Screen and Lock Screen families, aggregate-only App Group snapshot storage, privacy manifest and widget snapshot tests.
- Re-enabled ShieldAppShortcuts and routed App Intents through a shared App Group command channel without bypassing Vault authentication.
- Added project embedding and release preflight/IPA checks for both Share Extension and Widget Extension.
- Validation: metadata validate passed with 0 errors/0 warnings; local App Store Connect dry-run planned 8 localization updates; make build passed; explicit iPad Pro 13-inch simulator build passed; full make test passed with 29 UI tests and the new WidgetSnapshotTests passing.
