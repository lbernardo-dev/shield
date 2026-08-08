# 74-fix-storekit-scheme-reference

- Number: 74
- Slug: fix-storekit-scheme-reference

## Notes

2026-08-09:
- Fixed the shared `Shield.xcscheme` StoreKit configuration file reference for both `TestAction` and `LaunchAction`.
- Previous identifier: `Shield/Resources/Shield.storekit`.
- New identifier: `../Shield/Resources/Shield.storekit`.
- Reason: StoreKit scheme identifiers are resolved relative to the `.xcodeproj` package location. The previous path resolved inside `Shield.xcodeproj`, so Xcode could show a configured-looking scheme while the launched simulator process did not receive the local StoreKit catalog.
- Verified the corrected path exists at `Shield.xcodeproj/../Shield/Resources/Shield.storekit`.
- Verification: `xcodebuild -scheme Shield -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -derivedDataPath /tmp/ShieldStoreKitSchemeFix build` succeeded.
