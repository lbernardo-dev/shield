# Task 132: Apply Option 2 ASO Metadata

## Scope
Apply Option 2 (Identity & Data Protection) ASO metadata across app-info and version 1.0.4 for `es-ES` and `en-US` and push to App Store Connect.

## Metadata Details
- **Spanish (`es-ES`)**:
  - Name: `MaskID: Protege tu Identidad` (28 chars)
  - Subtitle: `Oculta Datos en Documentos` (26 chars)
  - Keywords: `dni,nie,cif,pasaporte,pdf,fotos,firma,privacidad,tachar,censurar,ocr,escaner,iban,nomina,boveda,exif` (100 chars)
- **English (`en-US`)**:
  - Name: `MaskID: Protect Your Identity` (29 chars)
  - Subtitle: `Hide Sensitive Data in Docs` (27 chars)
  - Keywords: `redact,pdf,photo,privacy,passport,license,scanner,ocr,blackout,censor,blur,offline,vault,iban,ssn` (97 chars)

## Verification
- `asc metadata validate --dir "./metadata" --subscription-app`: 0 errors, 0 warnings.
- `asc metadata push`: 4 updates succeeded in App Store Connect for version 1.0.4 and app-info.
