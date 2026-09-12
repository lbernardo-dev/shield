# 165-trust-center-protection-explainer

- Number: 165
- Slug: trust-center-protection-explainer

## Notes

- Converted the existing information article into a direct Trust Center entry:
  “How MaskID protects your files” / “Cómo protege MaskID tus archivos”.
- Added factual localized explanation of on-device OCR, human review, secure
  rasterized export, output checks, and explicit non-guarantee boundaries.
- Added localized regression coverage in `LocalizationLanguageTests`.
- Verification: catalog JSON and `git diff --check` passed; full isolated
  `ShieldTests` suite passed.
