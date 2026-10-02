# MaskID — App Store metadata

Status: canonical metadata reference for app `6790398619`, updated 2 October 2026. App Store Connect reports version `1.1.1` as the latest published release (`READY_FOR_SALE` / `READY_FOR_DISTRIBUTION`). Version `1.1.2` (`904cc5ee-994a-48cb-84db-265013b3cd75`) is staged as `PREPARE_FOR_SUBMISSION`, manual release, with EN/ES metadata and screenshots applied. It has no attached build and no What’s New copy; it has not been submitted. Older version/build entries below are historical.

The complete iPad, WidgetKit, Siri/Shortcuts, App Review and release checklist is in [APPLE_SURFACES_AND_APP_STORE_CONNECT.md](APPLE_SURFACES_AND_APP_STORE_CONNECT.md).

## Positioning

MaskID protects identity and sensitive data before documents are shared. Its core promise is safer sharing of IDs, passports, licenses, bank documents, contracts, screenshots, photos and PDFs through on-device detection, precise masking and verified export.

It is not positioned as a generic PDF/photo editor.

## App record

- English name: `MaskID: Redact PDFs & IDs`
- Spanish name: `MaskID: Protege Datos Privados`
- Primary locale: English (U.S.)
- Bundle ID: `com.romerodev.shield` (immutable legacy identifier)
- SKU: `SHIELD-ROMERODEV-001` (immutable internal identifier)
- Primary category: Utilities
- Secondary category: Productivity
- Subcategories: none; Apple does not offer subcategories for Utilities or Productivity
- Age rating: 4+
- Latest published version observed: `1.1.1` (`READY_FOR_SALE` / `READY_FOR_DISTRIBUTION`)
- Prepared version: `1.1.2` (`PREPARE_FOR_SUBMISSION`, manual release; no build attached)
- Historical 1.0.8/1.0.9 build records are retained in version history.
- Release type: manual

## Localized ASO

Canonical metadata lives in `metadata/`.

### English (U.S.)

- Name: `MaskID: Protect Private Data`
- Subtitle: `Hide Details Before Sharing`
- Keywords for 1.1.2: `privacy,identity,passport,license,forms,watermark,vault,offline,photo,signature,ocr,metadata,iban`
- Promotional text: `Hide personal details before sharing. Review each mask and check your exported copy on device.`

### Spanish (Spain)

- Name: `MaskID: Protege Datos Privados`
- Subtitle: `Oculta Datos al Compartir`
- Keywords for 1.1.2: `identidad,privacidad,documentos,tachar,dni,pasaporte,contratos,iban,firma,metadatos,bóveda,pdf`
- Promotional text: `Oculta datos personales antes de compartir. Revisa cada máscara y comprueba la copia exportada en el dispositivo.`

The localized descriptions lead with identity protection and explain on-device OCR, manual masking, multi-page documents, encrypted Vault, metadata removal and residual-text verification. They also state that automatic suggestions require user review.

## URLs

The public pages are branded MaskID. Their existing `/shield/` paths are retained because they are live, stable compatibility URLs; changing App Store Connect to nonexistent `/maskid/` paths would break support and privacy links.

- English marketing: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/`
- English support: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/support/`
- English privacy: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/privacy/`
- English terms: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/terms/`
- Spanish base: `https://lbernardo-dev.github.io/apps/es/casos/shield/`

## Screenshots

- Corrected English iPhone 6.9-inch ASO source: `.asc/screenshots/aso/final/en-US/iphone-69`
- Corrected Spanish iPhone 6.9-inch ASO source: `.asc/screenshots/aso/final/es-ES/iphone-69`
- Corrected English iPad 13-inch ASO source: `.asc/screenshots/aso/final-ipad/en-US/ipad-13`
- Corrected Spanish iPad 13-inch ASO source: `.asc/screenshots/aso/final-ipad/es-ES/ipad-13`
- English iPad 13-inch source: `.asc/screenshots/en-US/ipad-13`
- Spanish iPad 13-inch source: `.asc/screenshots/es-ES/ipad-13`

The 1.1.2 iPhone and iPad ASO sets contain 40 localized creatives (10 per device family and locale), composed from authentic simulator UI and synthetic identity-document fixtures at `1320×2868` and `2064×2752`. All 40 assets are `COMPLETE` in App Store Connect. Contact sheets, filenames and SHA-256 values are recorded in `Docs/ASO_SCREENSHOT_MANIFEST_1.1.2.md`. Earlier 1.0.9 assets remain historical.

The App Store sets use real simulator UI with synthetic identity-document fixtures. The sequence focuses on protecting identity, capture/import, precise masking, OCR, verified export, masking styles, encrypted Vault, batch processing and privacy controls. The paywall screenshot is intentionally excluded because it hard-codes USD pricing and weakens the identity-protection narrative. Claims in the screenshot plan must remain aligned with `Docs/CLAIMS_MATRIX.md`.

Both en-US and es-ES 1.1.2 preview sets contain the existing approved `MaskID-Identity-Protection.mov` (17 seconds, 886×1920, H.264 High, 30 fps, stereo AAC), inherited from 1.1.1 and verified `COMPLETE`. The same UI recording was already used for both storefront locales.

## App Review notes

MaskID does not require an account or demo credentials.

Suggested review path:

1. Import, photograph or scan a document.
2. Review the detected pages.
3. Inspect OCR suggestions or draw a mask manually.
4. Export a rasterized PDF or image and inspect the verification result.
5. Test the Share Extension from Photos or Files using Share > MaskID.

Camera access is used only for user-initiated capture and scanning. Photos and Files access is user initiated. Face ID or Touch ID gates the encrypted Vault. App Groups move user-selected documents from the Share Extension through an encrypted inbox. Optional Pro iCloud sync stores complete restorable non-Vault document packages in the user's private CloudKit database. Google Drive and Dropbox direct import use OAuth 2.0 + PKCE and device Keychain tokens; the local pipeline receives only the selected file.

On first launch, an optional product-analytics choice is shown. Firebase Analytics is off unless the user explicitly allows it; the choice can be changed later from Settings > Privacy. Declining analytics does not limit document protection, OCR, export, Vault or iCloud controls.

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
- Optional Firebase Analytics is disabled by default and requires explicit in-app consent; Firebase Crashlytics remains separate for stability diagnostics
- RevenueCat processes anonymous purchase history to validate transactions and enable entitlements
- Documents, images, OCR text, titles, Vault contents, file paths, and error-message text are not transmitted to Firebase or RevenueCat
- Optional private CloudKit backup is used only for app functionality and non-Vault document restoration

App Privacy is published in the authenticated App Store Connect session. It currently declares Device ID, Product Interaction, Crash Data, Performance Data, Purchase History and Other Diagnostic Data, with no tracking. The declaration remains required even though optional Firebase Analytics is off by default, because it can collect those categories after explicit consent. The public API cannot verify the publish flag, so the authenticated-session observation remains the audit evidence.

## Current external status (2 October 2026)

- Version 1.1.2 is still a draft and is not submission-ready: a build must be attached and What’s New must be supplied in en-US and es-ES after the release changes are known. `asc validate` reports only that blocking build error, those two What’s New warnings, manual release info, and an App Privacy publish-state check that the public API cannot verify.
- No baseline App Analytics was available in the audit; the name and creative choices remain hypotheses without measured conversion results.

- Accessibility has two unpublished drafts (iPhone and iPad) for VoiceOver, Dark Interface and Reduced Motion. Publishing them is intentionally not automatic because it changes public App Store metadata.
- MaskID Pro Monthly, MaskID Pro Annual and MaskID Pro Lifetime are approved. Billing Grace Period is not configured.
- Apple-silicon Mac availability is enabled but unverified. The public listing still says the app is not verified for macOS.
- No Custom Product Pages, In-App Events or Product Page Optimization tests exist yet.
