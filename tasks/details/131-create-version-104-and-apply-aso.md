# Task 131: Create Version 1.0.4 and Apply ASO Metadata

## Scope
1. Create new iOS App Store version `1.0.4` (`PREPARE_FOR_SUBMISSION`) in App Store Connect for app `6790398619`.
2. Update and organize canonical version metadata in `metadata/version/1.0.4/` (`en-US.json` and `es-ES.json`).
3. Push optimized ASO metadata (Title, Subtitle, Keywords, What's New) to App Store Connect.
4. Set up promoted purchases for subscriptions and validate readiness.

## Execution Details
- **Created Version**: `1.0.4` (ID: `c8b6a076-eeee-45a3-9874-045000e651ff`, state `PREPARE_FOR_SUBMISSION`).
- **Metadata Pushed to ASC**:
  - `app-info:en-US:name`: `MaskID: Redact PDF & Documents`
  - `app-info:en-US:subtitle`: `Hide Identity, PII & Photos`
  - `app-info:es-ES:name`: `MaskID: Oculta DNI y Datos PDF`
  - `app-info:es-ES:subtitle`: `Tacha Firma, NIE y Pasaporte`
  - `version:1.0.4:en-US:keywords`: `privacy,passport,license,scanner,ocr,blackout,censor,blur,offline,vault,iban,exif,ssn,clean,secure`
  - `version:1.0.4:es-ES:keywords`: `privacidad,seguro,fotos,censurar,escaner,ocr,iban,nomina,borrar,blanquear,contrato,boveda,exif,sello`
  - `version:1.0.4:en-US:whatsNew` and `es-ES:whatsNew` updated.
- **Promoted Purchases Created**:
  - Annual Subscription (`6790401098`) -> Promoted Purchase ID `cb14018c-6e78-4f99-947b-07da921e7d1e` (`APPROVED`).
  - Monthly Subscription (`6790401134`) -> Promoted Purchase ID `6bd023fe-e5f4-449f-ad00-01bb97084ef3` (`APPROVED`).
  - Lifetime Unlock (`6791491284`) -> Promoted Purchase ID `c9c274c0-cfd1-4970-bc4b-3a88ab1ef0f5`.

## Validation
- `asc metadata validate --dir "./metadata" --subscription-app` -> 0 errors, 0 warnings.
- `asc validate --app "6790398619" --version "1.0.4" --platform IOS` -> Metadata and screenshots valid; ready for build attachment.
