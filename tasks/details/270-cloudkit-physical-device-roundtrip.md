# 270-cloudkit-physical-device-roundtrip

- Number: 270
- Slug: cloudkit-physical-device-roundtrip

## Notes

- Physical-device inventory found one paired iPhone 15 Pro Max, but `devicectl` reports it `unavailable`; its last connection was 18 Nov 2026 at 18:52. No physical iPhone/iPad is currently connected for a CloudKit round-trip.
- The available iPhone 18 Pro, iPad Pro 13-inch M5, and iPhone Duo are simulators. This app deliberately returns no `CKContainer` in simulator processes without active iCloud entitlements, so they cannot validate the real sync path.
- Read-only source review confirms the UI requires Pro and explicit opt-in, then calls `setSyncEnabled` followed by `syncNow`. A valid end-to-end test also needs a physical device signed into a dedicated iCloud test account and an eligible Pro state.
- No account settings, local records, or CloudKit records were changed. Waiting for a physical device with a test account; then use only a synthetic document and remove it through MaskID's normal delete path.

