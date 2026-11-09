# 255-cierre-autonomo-bloqueos-release

- Number: 255
- Slug: cierre-autonomo-bloqueos-release

## Notes

- 2026-11-09: RevenueCat Safari session authenticated. Dashboard read-back confirms `default` offering current with MaskID App Store monthly/yearly/lifetime SKUs, `MaskID Pro` entitlement, and three generic products under the project’s separate Test Store app. Annual SKU is Approved, Spain €29.99, and has no offers attached; Store State at 07:41 UTC returns `trial_offer=null` and empty introductory offers. No RevenueCat write required. MCP reads for list-apps/products/entitlements and Store State monthly/lifetime still return 403; monthly/lifetime prices remain last confirmed 2026-11-08.
- ASC read-back found build 1172026110801 processed `VALID` but not attached to version 1.1.7. Attached under the user’s explicit authorization; verified the version relationship.
- Added TestFlight What to Test notes for es-ES and en-US. `asc validate testflight`: 0 errors/warnings/blockers. `asc validate --strict --ipa`: 0 errors/warnings/blockers; two info items are documented (manual release and public API cannot verify App Privacy).
- `Shield Internal` exists and has one `INSTALLED` tester; the build remains unassigned to avoid distributing the beta or triggering an automatic notification without authorization. No App Review, public release, cleanup, git stage/commit/tag/push occurred.
- Updated release executive, monetization reconciliation, owner actions, Git report, QA matrix and release manifest. No application source code changed in this continuation. Remaining external/physical gates are legal review, App Privacy reconciliation, authorized TestFlight group distribution/Sandbox lifecycle, active-editor/capture expiry E2E, physical assistive-tech and multi-device CloudKit validation.

