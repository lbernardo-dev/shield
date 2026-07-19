# MaskID — App Store metadata

Status: synchronized with App Store Connect for app `6790398619`, version `1.0.0`. The app has not been submitted for review.

## Positioning

MaskID protects identity and sensitive data before documents are shared. Its core promise is safer sharing of IDs, passports, licenses, bank documents, contracts, screenshots, photos and PDFs through on-device detection, precise masking and verified export.

It is not positioned as a generic PDF/photo editor.

## App record

- English name: `MaskID: Protect Your Identity`
- Spanish name: `MaskID: Protege tu identidad`
- Primary locale: English (U.S.)
- Bundle ID: `com.romerodev.shield` (immutable legacy identifier)
- SKU: `SHIELD-ROMERODEV-001` (immutable internal identifier)
- Primary category: Utilities
- Secondary category: Productivity
- Subcategories: none; Apple does not offer subcategories for Utilities or Productivity
- Age rating: 4+
- Version: `1.0.0`
- Current valid build: `100202607191`
- Release type: manual

## Localized ASO

Canonical metadata lives in `metadata/`.

### English (U.S.)

- Name: `MaskID: Protect Your Identity`
- Subtitle: `Hide sensitive data safely`
- Keywords: `privacy,passport,license,scanner,OCR,PII,documents,photo,PDF,redact,blackout,offline,vault,metadata`

### Spanish (Spain)

- Name: `MaskID: Protege tu identidad`
- Subtitle: `Oculta datos antes de enviar`
- Keywords: `privacidad,DNI,NIE,pasaporte,escáner,OCR,IBAN,firma,dirección,fotos,PDF,tachar,censurar,bóveda`

The localized descriptions lead with identity protection and explain on-device OCR, manual masking, multi-page documents, encrypted Vault, metadata removal and residual-text verification. They also state that automatic suggestions require user review.

## URLs

The public pages are branded MaskID. Their existing `/shield/` paths are retained because they are live, stable compatibility URLs; changing App Store Connect to nonexistent `/maskid/` paths would break support and privacy links.

- English marketing: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/`
- English support: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/support/`
- English privacy: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/privacy/`
- English terms: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/terms/`
- Spanish base: `https://lbernardo-dev.github.io/apps/es/casos/shield/`

## Screenshots

- English iPhone 6.9-inch ASO source: `.asc/screenshots/aso/final/en-US/iphone-69`
- Spanish iPhone 6.9-inch ASO source: `.asc/screenshots/aso/final/es-ES/iphone-69`
- English iPad 13-inch source: `.asc/screenshots/en-US/ipad-13`
- Spanish iPad 13-inch source: `.asc/screenshots/es-ES/ipad-13`

The App Store sets use real simulator UI with synthetic identity-document fixtures. The sequence focuses on protecting identity, capture/import, precise masking, OCR, verified export, redaction styles, encrypted Vault, batch processing and privacy controls. The paywall screenshot is intentionally excluded because it hard-codes USD pricing and weakens the identity-protection narrative.

The English product page also includes `MaskID-Identity-Protection.mov`, a real 17-second iPhone 16 simulator recording showing document selection, protected-document editing and export. It is delivered as an App Preview at 886×1920, H.264 High, 30 fps with stereo AAC audio.

## App Review notes

MaskID does not require an account or demo credentials.

Suggested review path:

1. Import, photograph or scan a document.
2. Review the detected pages.
3. Inspect OCR suggestions or draw a mask manually.
4. Export a rasterized PDF or image and inspect the verification result.
5. Test the Share Extension from Photos or Files using Share > MaskID.

Camera access is used only for user-initiated capture and scanning. Photos and Files access is user initiated. Face ID or Touch ID protects the encrypted Vault. App Groups move user-selected documents from the Share Extension through an encrypted inbox. CloudKit is optional and synchronizes only a minimized private index; document images, imported files, OCR text and user-entered titles remain on device.

## StoreKit products

| Product ID | Type | Public name |
|---|---|---|
| `com.romerodev.shield.pro.monthly` | Auto-renewable subscription | MaskID Pro Monthly / MaskID Pro Mensual |
| `com.romerodev.shield.pro.annual` | Auto-renewable subscription | MaskID Pro Annual / MaskID Pro Anual |
| `com.romerodev.shield.pro.lifetime.unlock` | Non-consumable | MaskID Pro Lifetime / MaskID Pro de por vida |

Product IDs are immutable legacy identifiers and are never shown as the customer-facing product names. All three products are ready to submit and must be attached to the first app review submission.

## App Privacy

- Tracking: no
- Advertising: no
- Third-party analytics: no
- Documents, images, OCR text, titles, telemetry and Vault contents are not transmitted to the developer
- Optional private CloudKit index is used only for app functionality

App Privacy publication must be confirmed using an authenticated App Store Connect web session before review submission; the public API cannot verify its publish state.
