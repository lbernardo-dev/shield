# MaskID — App Store metadata

Status: canonical metadata reference for app `6790398619`; version `1.0.7`, build `107202609062`, is approved and published (`READY_FOR_DISTRIBUTION`). Version `1.0.8` is in `PREPARE_FOR_SUBMISSION` with ASO metadata applied and build `108202609071` attached and `VALID`; it has not been submitted to review. The public listing will reflect app-info changes as Apple propagates them.

The complete iPad, WidgetKit, Siri/Shortcuts, App Review and release checklist is in [APPLE_SURFACES_AND_APP_STORE_CONNECT.md](APPLE_SURFACES_AND_APP_STORE_CONNECT.md).

## Positioning

MaskID protects identity and sensitive data before documents are shared. Its core promise is safer sharing of IDs, passports, licenses, bank documents, contracts, screenshots, photos and PDFs through on-device detection, precise masking and verified export.

It is not positioned as a generic PDF/photo editor.

## App record

- English name: `MaskID: Protect Private Data`
- Spanish name: `MaskID: Protege Datos Privados`
- Primary locale: English (U.S.)
- Bundle ID: `com.romerodev.shield` (immutable legacy identifier)
- SKU: `SHIELD-ROMERODEV-001` (immutable internal identifier)
- Primary category: Utilities
- Secondary category: Productivity
- Subcategories: none; Apple does not offer subcategories for Utilities or Productivity
- Age rating: 4+
- Published version: `1.0.7`
- Published build: `107202609062`
- Prepared next version: `1.0.8`, build `108202609071` (`VALID`)
- Release type: manual

## Localized ASO

Canonical metadata lives in `metadata/`.

### English (U.S.)

- Name: `MaskID: Protect Private Data`
- Subtitle: `Hide Details Before Sharing`
- Keywords: `privacy,identity,documents,passport,license,forms,watermark,vault,offline,photo,signature,mask,id`

### Spanish (Spain)

- Name: `MaskID: Protege Datos Privados`
- Subtitle: `Oculta Datos al Compartir`
- Keywords: `identidad,privacidad,documentos,ocultar,compartir,dni,pasaporte,trámites,marca,bóveda,offline,pdf`

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

The App Store sets use real simulator UI with synthetic identity-document fixtures. The sequence focuses on protecting identity, capture/import, precise masking, OCR, verified export, masking styles, encrypted Vault, batch processing and privacy controls. The paywall screenshot is intentionally excluded because it hard-codes USD pricing and weakens the identity-protection narrative.

The English product page also includes `MaskID-Identity-Protection.mov`, a real 17-second iPhone 16 simulator recording showing document selection, protected-document editing and export. It is delivered as an App Preview at 886×1920, H.264 High, 30 fps with stereo AAC audio.

## App Review notes

MaskID does not require an account or demo credentials.

Suggested review path:

1. Import, photograph or scan a document.
2. Review the detected pages.
3. Inspect OCR suggestions or draw a mask manually.
4. Export a rasterized PDF or image and inspect the verification result.
5. Test the Share Extension from Photos or Files using Share > MaskID.

Camera access is used only for user-initiated capture and scanning. Photos and Files access is user initiated. Face ID or Touch ID gates the encrypted Vault. App Groups move user-selected documents from the Share Extension through an encrypted inbox. Optional Pro iCloud sync stores complete restorable non-Vault document packages in the user's private CloudKit database. Google Drive and Dropbox direct import use OAuth 2.0 + PKCE and device Keychain tokens; the local pipeline receives only the selected file.

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
- Third-party analytics: Firebase Analytics and Crashlytics, with sanitized technical/product telemetry only
- RevenueCat processes anonymous purchase history to validate transactions and enable entitlements
- Documents, images, OCR text, titles, Vault contents, file paths, and error-message text are not transmitted to Firebase or RevenueCat
- Optional private CloudKit backup is used only for app functionality and non-Vault document restoration

App Privacy publication must be confirmed using an authenticated App Store Connect web session before review submission; the public API cannot verify its publish state.
