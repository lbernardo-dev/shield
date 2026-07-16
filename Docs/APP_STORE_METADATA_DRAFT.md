# Shield — App Store metadata draft

Status: synchronized with App Store Connect for app `6790398619`, version `1.0.0`. Review submission remains explicitly unauthorized.

## App record

- Platforms: iOS and iPadOS
- Name: `Shield`
- Primary language: Spanish (Spain)
- Bundle ID: `com.romerodev.shield`
- SKU: `SHIELD-ROMERODEV-001`
- User access: Full Access
- Primary category: Productivity
- Secondary category: Utilities
- Version: `1.0.0`
- Current release candidate build: `100202607132`
- Build convention: `<major><minor-two-digits><YYYYMMDD><daily-increment>`; this build is `1` + `00` + `20260713` + `2`.

## URLs

English primary references:

- Marketing: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/`
- Support: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/support/`
- Privacy: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/privacy/`
- Terms: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/terms/`
- Subscription terms: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/subscriptions/`
- FAQ: `https://lbernardo-dev.github.io/apps/en/case-studies/shield/faq/`

Spain localization uses the equivalent URLs below `https://lbernardo-dev.github.io/apps/es/casos/shield/`. Compatibility routes remain available below `https://lbernardo-dev.github.io/apps/apps/shield/`.

## Screenshot assets

- Spanish iPhone 6.9-inch ASO set: `.asc/screenshots/aso/final/es-ES/iphone-69` (10 files).
- English iPhone 6.9-inch ASO set: `.asc/screenshots/aso/final/en-US/iphone-69` (10 files).
- Spanish iPad 13-inch: `.asc/screenshots/es-ES/ipad-13` (2 files).
- English iPad 13-inch: `.asc/screenshots/en-US/ipad-13` (1 file).

The iPhone sets use real simulator UI with synthetic, non-personal document fixtures and a deterministic Shield marketing composition. They cover home, capture, precision editing, OCR, verified export, style gallery, Vault, batch processing, Pro and privacy controls. All 20 iPhone assets are `1320×2868`, pass `asc screenshots validate` with zero errors and zero warnings, and report `COMPLETE` in App Store Connect. The existing required iPad sets remain uploaded.

## Spanish (Spain)

### Subtitle

`Oculta datos con seguridad`

### Promotional text

`Importa, escanea y revisa documentos. Detecta datos sensibles en el dispositivo, aplica máscaras y exporta una copia verificada antes de compartirla.`

### Description

Shield es un espacio profesional para ocultar información sensible en documentos antes de compartirlos.

Importa archivos PDF e imágenes desde Archivos, Fotos o la extensión Compartir. También puedes capturar páginas con la cámara o utilizar el escáner integrado. Shield procesa el contenido en el dispositivo y te permite revisar cada resultado antes de exportarlo.

Funciones principales:

- Máscaras manuales precisas y editables.
- Sugerencias OCR para documentos, correos, teléfonos, IBAN y tarjetas.
- Plantillas semánticas para flujos repetitivos.
- Documentos multipágina y procesamiento por lotes.
- Exportación rasterizada con comprobación de texto residual.
- Biblioteca local cifrada y Vault con autenticación del dispositivo.
- Extensión Compartir para recibir documentos desde otras apps.
- Compatibilidad con iPhone, iPad, teclado, VoiceOver y Dynamic Type.
- Sin publicidad ni seguimiento entre apps.

La detección automática puede cometer errores. Shield siempre requiere que revises las zonas seleccionadas antes de compartir el documento exportado.

### Keywords

`privacidad,documentos,ocultar datos,OCR,PDF,escáner,DNI,IBAN,redacción,seguridad`

### What’s New

`Primera versión de Shield: importación y escaneo, OCR en el dispositivo, máscaras manuales y automáticas, Vault cifrado y exportación verificada.`

## English (U.S.)

### Subtitle

`Private document redaction`

### Promotional text

`Import, scan, and review documents. Detect sensitive data on device, apply masks, and export a verified copy before sharing.`

### Description

Shield is a professional workspace for hiding sensitive information in documents before sharing them.

Import PDF files and images from Files, Photos, or the Share Extension. You can also capture pages with the camera or use the built-in document scanner. Shield processes content on device and lets you review every result before export.

Key features:

- Precise, editable manual masks.
- OCR suggestions for identity documents, email addresses, phone numbers, IBANs, and payment cards.
- Semantic templates for repeated workflows.
- Multi-page documents and batch processing.
- Rasterized export with residual-text verification.
- Encrypted local library and a device-authenticated Vault.
- Share Extension for receiving documents from other apps.
- iPhone, iPad, keyboard, VoiceOver, and Dynamic Type support.
- No advertising or cross-app tracking.

Automatic detection can make mistakes. Shield always requires you to review selected regions before sharing an exported document.

### Keywords

`privacy,documents,redaction,OCR,PDF,scanner,identity,IBAN,mask,secure`

### What’s New

`The first Shield release: import and scanning, on-device OCR, manual and suggested masks, encrypted Vault, and verified export.`

## App Review notes

Shield does not require an account or demo credentials.

Suggested review path:

1. Tap Import or Scan and select/capture a document.
2. Review and confirm the pages.
3. Open OCR to inspect suggested sensitive fields, or draw a mask manually.
4. Open Export, acknowledge the review warning, and export a verified PDF or image.
5. The Share Extension can be tested from Photos or Files using Share > Shield.

Camera is used only to photograph or scan pages selected by the user. Photos and Files access are user initiated. Face ID or Touch ID protects the encrypted Vault. App Groups transfer user-selected documents from the Share Extension through an encrypted inbox. CloudKit is optional and synchronizes only a minimized private index; document images, imported files, OCR text, and user-entered titles remain on device.

## StoreKit products

| Product ID | Type | Reference name | Initial price intent |
|---|---|---|---|
| `com.romerodev.shield.pro.monthly` | Auto-renewable subscription | Shield Pro Monthly | 2.99 EUR base in Spain |
| `com.romerodev.shield.pro.weekly` | Auto-renewable subscription | Shield Pro Weekly | 0.99 EUR base in Spain |
| `com.romerodev.shield.pro.annual` | Auto-renewable subscription | Shield Pro Annual | 29.99 EUR base in Spain; 7-day trial |

The monthly and annual products belong to the `Shield Pro` subscription group. Apple-equivalent prices and availability are configured for all 175 territories. Descriptions and public screenshots do not hard-code regional prices.

## App Privacy working declaration

- Tracking: No.
- Advertising: No.
- Third-party analytics: No.
- Documents, images, OCR text, titles, telemetry, and Vault contents: not transmitted to the developer.
- Optional CloudKit private index: document UUID, generic protected title, document kind, built-in category, date, redaction count, favorite state, and source type; used only for App Functionality, not tracking or advertising.

Before publishing App Privacy, choose the conservative CloudKit disclosure offered by App Store Connect for product interaction/private app content, marked as linked to the user only if Apple’s questionnaire treats private iCloud records as developer-collected data. Preserve “Data Not Collected” only if the questionnaire explicitly excludes private CloudKit data inaccessible to the developer.
