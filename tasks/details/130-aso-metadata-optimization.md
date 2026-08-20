# Task 130: ASO Metadata Optimization

## Scope
Optimize App Store Connect metadata for MaskID (`en-US` and `es-ES`) following Apple ranking factors and ASO best practices:
- Eliminate non-ranking filler words ("What You Share", "tus").
- Place high-intent, highest-weight search terms in Title and Subtitle (`Redact`, `PDF`, `DNI`, `NIE`, `Firma`, `Tacha`, `PII`, `Identity`).
- Remove cross-field duplicate keywords between Title, Subtitle, and Keywords fields.
- Expand the 100-character keyword bank to maximize indexation and combinatorial reach without duplication.
- Validate local metadata using `asc metadata validate --subscription-app`.

## Changes
- Updated `metadata/app-info/en-US.json`:
  - Name: `MaskID: Redact PDF & Documents` (30 chars)
  - Subtitle: `Hide Identity, PII & Photos` (27 chars)
- Updated `metadata/app-info/es-ES.json`:
  - Name: `MaskID: Oculta DNI y Datos PDF` (30 chars)
  - Subtitle: `Tacha Firma, NIE y Pasaporte` (28 chars)
- Updated `metadata/version/1.0.3/en-US.json`:
  - Keywords: `privacy,passport,license,scanner,ocr,blackout,censor,blur,offline,vault,iban,exif,ssn,clean,secure` (98 chars)
- Updated `metadata/version/1.0.3/es-ES.json`:
  - Keywords: `privacidad,seguro,fotos,censurar,escaner,ocr,iban,nomina,borrar,blanquear,contrato,boveda,exif,sello` (99 chars)

## Validation
`asc metadata validate --dir "./metadata" --subscription-app` -> 0 errors, 0 warnings.
Note: Remote application to App Store Connect requires creating the next version (e.g., 1.0.4 / `PREPARE_FOR_SUBMISSION`), as version 1.0.3 is live (`READY_FOR_DISTRIBUTION`) and locked against title/keyword modification.
