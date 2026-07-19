# 34-release-candidate-upload

- Number: 34
- Slug: release-candidate-upload

## Notes

- Audited onboarding, authenticated shell, home, gallery, batch flow, settings routes,
  legal/support destinations, feedback and App Store rating behavior in English and Spanish.
- Fixed deterministic App Store rating navigation, compact tab-bar hit testing,
  automation auto-lock interference, competing root gestures and undersized accessibility targets.
- Expanded unit/UI regression coverage for rating URLs, all Settings destinations,
  onboarding, gallery and batch selection.
- Validation: App Store preflight (including remote) passed; Release analyze passed;
  40 unit/code tests passed and all UI scenarios passed, including targeted reruns for
  the final batch/onboarding accessibility corrections.
- Release candidate: version 1.0.0, build 100202607171, commit `db0fe0f`.
- IPA SHA-256: `ca98e0edd15aa579a3c3dbac894b6e1b1b6d3dd4ed148791e2d94aff584c7bf3`.
- App Store Connect build ID: `5cc6cec8-522a-4d30-bdd2-28dff76d806e`, processing state `VALID`.
- Attached to App Store version ID `d49e36c8-3182-4f27-9189-b5c86647c1a7` (1.0.0).
  Version remains `PREPARE_FOR_SUBMISSION`, with no submission ID; no review submission was made.
- App Store validation: 0 errors, 0 blocking issues, 5 non-blocking warnings related
  to optional subscription promotional images and IAP/subscription review readiness.
