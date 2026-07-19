# Shield — Documento de Arquitectura

**Versión:** 1.0  
**Fecha:** 30 de abril de 2026  
**Estado del build:** compila y ejecuta en simulador (iPhone Air, iOS 26.2)  
**Líneas de código Swift:** ~13.300  
**Archivos Swift:** 28

---

## Índice

1. [Visión general](#1-visión-general)
2. [Estructura de carpetas](#2-estructura-de-carpetas)
3. [Capas de la arquitectura](#3-capas-de-la-arquitectura)
4. [Modelos de datos](#4-modelos-de-datos)
5. [ViewModels](#5-viewmodels)
6. [Vistas — catálogo completo](#6-vistas--catálogo-completo)
7. [Capa Cloud](#7-capa-cloud)
8. [Seguridad y cifrado](#8-seguridad-y-cifrado)
9. [Sistema de captura e importación](#9-sistema-de-captura-e-importación)
10. [Pipeline de exportación](#10-pipeline-de-exportación)
11. [Motor OCR](#11-motor-ocr)
12. [Sistema de ajuste de imagen](#12-sistema-de-ajuste-de-imagen)
13. [Monetización y tiers Free/Pro](#13-monetización-y-tiers-freepro)
14. [Persistencia local](#14-persistencia-local)
15. [Auto-lock y ciclo de vida](#15-auto-lock-y-ciclo-de-vida)
16. [Localización](#16-localización)
17. [Telemetría local](#17-telemetría-local)
18. [Frameworks usados](#18-frameworks-usados)
19. [Convenciones de código](#19-convenciones-de-código)
20. [Pendientes técnicos conocidos](#20-pendientes-técnicos-conocidos)

---

## 1. Visión general

Shield es una app iOS de privacidad de documentos: permite importar, escanear, redactar campos sensibles, y exportar documentos sin que ningún dato salga del dispositivo. El procesamiento (OCR, ajuste de imagen, cifrado, exportación) es 100% on-device.

**Patrón arquitectónico:** MVVM + singletons de servicios  
**UI framework:** SwiftUI (iOS 17+)  
**Sin dependencias externas:** solo frameworks de Apple  
**Bundle ID:** `com.romerodev.shield`

### Principios de diseño

- **Privacy by default:** todos los archivos se cifran en reposo con AES-256-GCM. Las claves viven en Keychain con `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.
- **Singleton services:** `AppState`, `PremiumManager`, `CloudSyncManager`, `ExternalStorageManager` son singletons accedidos como `@EnvironmentObject` o `@ObservedObject`.
- **No cloud dependencies en el core:** la lógica de redacción/exportación nunca toca la red. Los conectores de nube solo mueven archivos de entrada al dispositivo.
- **Coordenadas normalizadas:** todas las redacciones se almacenan en espacio normalizado `0..1` relativo al documento, independiente del tamaño de render.

---

## 2. Estructura de carpetas

```
Shield/
├── App/
│   ├── ShieldApp.swift          — @main, observa scenePhase
│   └── ContentView.swift        — Router principal (Onboarding / LockScreen / MainInterface)
│
├── Models/
│   ├── Document.swift           — Todos los tipos de dominio del documento
│   └── Redaction.swift          — MaskStyle, Redaction, Watermark, RedactionMode
│
├── ViewModels/
│   ├── AppState.swift           — Estado global + persistencia + cifrado + L10n
│   └── EditorViewModel.swift    — Estado del editor, historial undo/redo, ajuste imagen
│
├── Cloud/
│   ├── CloudSyncManager.swift   — Sync de índice vía CloudKit (Pro)
│   └── ExternalStorageManager.swift — OAuth2 Google Drive/Dropbox/OneDrive (Pro)
│
├── Premium/
│   └── PremiumManager.swift     — StoreKit 2, límites Free/Pro, historial de exportaciones
│
├── Theme/
│   └── ShieldTheme.swift        — Design tokens, colores adaptativos, Color(hex:)
│
├── Views/
│   ├── App/
│   ├── Capture/
│   │   └── CaptureView.swift    — Importación, scanner, ScanReview, OCRService, ScanImageProcessor
│   ├── Components/
│   │   ├── Components.swift     — ScaleButtonStyle, ShieldHaptics, SectionHeader, PillButton…
│   │   └── TabBar.swift         — ShieldTabBar, AppTab
│   ├── Documents/
│   │   └── DocumentRenderers.swift — Renderers por tipo de documento + drawMask + drawWatermark
│   ├── Editor/
│   │   ├── EditorView.swift         — Vista contenedora del editor
│   │   ├── DocumentCanvas.swift     — Canvas interactivo (draw, drag, resize)
│   │   ├── MaskStylePicker.swift    — Selector horizontal de estilos de máscara
│   │   ├── OCRSheetView.swift       — Sheet de campos OCR + relectura
│   │   ├── ExportSheetView.swift    — Sheet de exportación + ExportEngine
│   │   ├── WatermarkConfigView.swift — Configurador de marca de agua
│   │   └── ImageAdjustToolbar.swift — Panel de ajuste de imagen (brillo, contraste…)
│   ├── Gallery/
│   │   └── StyleGalleryView.swift   — Galería de estilos con preview por tipo doc
│   ├── Home/
│   │   ├── HomeView.swift           — Biblioteca, modos rápidos, nube, bóveda
│   │   └── AllDocumentsView.swift   — Vista paginada de todos los documentos
│   ├── Onboarding/
│   │   └── OnboardingView.swift     — Onboarding 3 pasos + LockScreenView + PINSetupView
│   ├── Paywall/
│   │   └── PaywallView.swift        — Paywall con selector de planes + triggers contextuales
│   ├── Settings/
│   │   └── SettingsView.swift       — Preferencias, seguridad, iCloud, exportación, debug
│   └── Vault/
│       └── VaultView.swift          — Bóveda cifrada + PINManager + PINSetupView + PINEntryView
│
└── Resources/
    ├── Assets.xcassets
    ��── Shield.storekit          — Productos IAP para testing en simulador
    └── PrivacyInfo.xcprivacy    — Privacy manifest (Required Reason APIs)
```

---

## 3. Capas de la arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                           │
│  HomeView · EditorView · CaptureView · VaultView · Settings…   │
└────────────────────────┬────────────────────────────────────────┘
                         │ @EnvironmentObject / @StateObject
┌────────────────────────▼────────────────────────────────────────┐
│                       ViewModels                                │
│           AppState (global)  ·  EditorViewModel (local)        │
└──────┬─────────────────┬───────────────────┬────────────────────┘
       │                 │                   │
┌──────▼──────┐  ┌───────▼───────┐  ┌───────▼──────────────────┐
│  Premium    │  │    Cloud      │  │     Core Services        │
│  Manager   │  │  CloudSync    │  │  SecureFileStore          │
│  StoreKit2  │  │  ExternalSt. │  │  KeychainStore            │
└─────────────┘  └───────────────┘  │  OCRService              │
                                    │  ExportEngine            │
                                    │  ScanImageProcessor      │
                                    └──────────────────────────┘
                                                │
                                    ┌───────────▼──────────────┐
                                    │    Persistencia local    │
                                    │  ApplicationSupport/     │
                                    │    Shield/               │
                                    │      documents.json ─ AES│
                                    │      categories.json─ AES│
                                    │      images/ ────────AES │
                                    │      vault-images/ ───AES│
                                    │      sources/ ────────AES│
                                    │      vault-sources/ ──AES│
                                    │      telemetry.ndjson    │
                                    └──────────────────────────┘
```

---

## 4. Modelos de datos

### `DocumentItem` — entidad principal
**Archivo:** [Models/Document.swift](../Shield/Models/Document.swift)

```swift
struct DocumentItem: Identifiable, Codable {
    let id: String                          // UUID string
    var kind: DocumentKind                  // dniESP | passportUSA | drivingUK | photo | …
    var title: String
    var category: DocumentCategory
    var customCategoryID: String?           // si categoría es de usuario
    var date: Date
    var redactionCount: Int                 // total calculado de pageRedactions
    var isFavorite: Bool
    var isLocked: Bool
    var isVaulted: Bool
    var imageFileName: String?              // nombre de archivo en images/ (página 0)
    var pageFileNames: [String]?            // todas las páginas en orden
    var sourceType: ImportedDocumentSource  // .image | .pdf
    var sourceFileName: String?             // PDF original en sources/
    var fields: DocumentFields              // resultado OCR
    var pageRedactions: [DocumentPageRedactions]
    var watermark: Watermark?
    var imageAdjustment: ImageAdjustmentStore?  // ajustes brillo/contraste/recorte/rotación
}
```

**Invariante de páginas:** `pageFileNames` toma precedencia sobre `imageFileName`. `imageFileName` apunta siempre a la página 0. Si `pageFileNames == nil`, el documento es de una sola página.

### `DocumentFields` — resultado OCR
Almacena los campos extraídos de un documento, el texto completo y metadatos de confianza:

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `documentNumber` | `String` | Número de documento / pasaporte |
| `fullName` | `String` | Nombre completo detectado |
| `dateOfBirth` | `String` | Fecha de nacimiento |
| `nationality` | `String` | Nacionalidad (código ISO 3 letras) |
| `expires` | `String` | Fecha de caducidad |
| `sex` | `String` | Sexo |
| `address` | `String` | Dirección |
| `issued` | `String?` | Fecha de expedición |
| `mrz` | `String?` | Líneas MRZ completas |
| `ocrDocumentType` | `String?` | `"dni"` / `"passport"` / `"document"` |
| `ocrFullText` | `String?` | Texto completo del documento |
| `ocrPageTexts` | `[String]?` | Texto por página |
| `ocrMRZValid` | `Bool?` | Resultado de validación MRZ |
| `ocrMRZFormat` | `String?` | Formato MRZ detectado |
| `ocrFieldConfidence` | `[String: Double]?` | Confianza por campo (0..1) |
| `ocrDetectedCountry` | `String?` | Código país ISO |
| `ocrRiskLevel` | `String?` | `"low"` / `"medium"` / `"high"` |
| `ocrLowConfidenceFields` | `[String]?` | Campos con confianza baja |

### `Redaction` — zona redactada
```swift
struct Redaction: Identifiable, Equatable, Codable {
    let id: UUID
    var rect: CGRect    // normalizado 0..1 relativo al documento
    var style: MaskStyle
}
```

**`MaskStyle`** — 9 estilos:

| Estilo | Free | Descripción |
|--------|------|-------------|
| `.block` | ✅ | Rectángulo negro sólido |
| `.blockWhite` | ✅ | Rectángulo blanco sólido |
| `.pixelate` | Pro | Pixelado con CIPixellate |
| `.blurStrong` | Pro | Gaussian blur radio 20 |
| `.blurSoft` | Pro | Gaussian blur radio 10 |
| `.diagonal` | Pro | Rayado diagonal 45° |
| `.secure` | Pro | Rayado cruzado + borde |
| `.redactedTag` | Pro | Etiqueta "[REDACTED]" |
| `.semi` | Pro | Semi-transparente negro |

### `RedactionMode` — modos rápidos de redacción
4 modos predefinidos que aplican subconjuntos de redacciones según el caso de uso:

| Modo | Oculta | Para qué |
|------|--------|---------|
| `.rental` | Foto + DOB + MRZ + número | Contrato de alquiler |
| `.travel` | Número pasaporte + MRZ | Verificación de viaje |
| `.job` | Foto + DOB + número | Solicitud de empleo |
| `.verify` | Número + DOB + MRZ | Verificación de identidad |

Para documentos `.photo` / `.genericID`, los modos usan `AutoRedactions.ocrModeRects(for:fields:)` con posiciones normalizadas aproximadas.

### `ImageAdjustmentStore` — ajustes de imagen persistidos
```swift
struct ImageAdjustmentStore: Codable, Equatable {
    var brightness: Double     // -0.5 … 0.5 (CIColorControls)
    var contrast: Double       // 0.5 … 2.0
    var saturation: Double     // 0.0 … 2.0
    var sharpness: Double      // 0.0 … 1.0 (CISharpenLuminance)
    var rotation: Double       // 0 | 90 | 180 | 270
    var flipHorizontal: Bool
    var flipVertical: Bool
    var cropLeft: Double       // 0.0 … 0.4 (fracción del ancho)
    var cropRight: Double
    var cropTop: Double
    var cropBottom: Double
}
```

`ImageAdjustment` (en `EditorViewModel`) es el homólogo no-Codable usado en tiempo de edición. Se convierte a `ImageAdjustmentStore` al persistir en `DocumentItem`.

### `DocumentKind` — tipos de documento soportados

| Valor | Descripción |
|-------|-------------|
| `.dniESP` | DNI español — renderer vectorial con campos predefinidos |
| `.passportUSA` | Pasaporte USA |
| `.passportMEX` | Pasaporte México |
| `.dniITA` | Carta d'identità italiana |
| `.drivingUK` | Licencia de conducir UK |
| `.genericID` | ID genérico con photo + strip inferior |
| `.photo` | Documento importado como foto/scan — sin renderer vectorial |

---

## 5. ViewModels

### `AppState` — estado global
**Archivo:** [ViewModels/AppState.swift](../Shield/ViewModels/AppState.swift)  
**Patrón:** `@EnvironmentObject` inyectado desde `ShieldApp`

Responsabilidades:
- Estado de autenticación (`isOnboarded`, `isAuthenticated`)
- Colección de documentos (`documents: [DocumentItem]`) con CRUD completo
- Filtrado/búsqueda/ordenación (`filteredDocuments`, `searchQuery`, `sortOption`)
- Categorías de usuario (`customCategories`)
- Navegación de alto nivel (`selectedDoc`, `showCapture`, `activeTab`)
- Preferencias (`language`, `preferredScheme`)
- Persistencia cifrada de `documents.json` y `categories.json`
- Almacenamiento cifrado de imágenes via `SecureFileStore`
- Auto-lock por ciclo de vida (`handleScenePhaseChange`)
- Telemetría local (`trackEvent`)
- Localización a través de `L10nKey`

**Directorios de almacenamiento** (todos bajo `ApplicationSupport/Shield/`):

| Directorio | Contenido | Cifrado |
|-----------|-----------|---------|
| `images/` | Páginas de documentos de biblioteca | AES-256-GCM |
| `vault-images/` | Páginas de documentos en bóveda | AES-256-GCM |
| `sources/` | PDFs originales de biblioteca | AES-256-GCM |
| `vault-sources/` | PDFs originales en bóveda | AES-256-GCM |
| `documents.json` | Índice de documentos | AES-256-GCM |
| `categories.json` | Categorías de usuario | AES-256-GCM |
| `telemetry.ndjson` | Log de eventos local | Plain text |

### `EditorViewModel` — estado del editor
**Archivo:** [ViewModels/EditorViewModel.swift](../Shield/ViewModels/EditorViewModel.swift)  
**Patrón:** `@StateObject` local en `EditorView`

Responsabilidades:
- Estado de redacciones de la página actual (`redactions: [Redaction]`)
- Historial undo/redo (`history: [[Redaction]]`, `historyIdx`)
- Página actual y navegación multipágina (`currentPage`, `goToPage`)
- Herramienta activa (`tool: EditorTool`)
- Modo de redacción activo (`activeMode: RedactionMode?`)
- Estado de dibujo en canvas (`drawingStart`, `drawingCurrent`)
- Ajuste de imagen en tiempo real (`imageAdjustment: ImageAdjustment`)
- Drag & resize de redacciones (`isDraggingRedaction`, `isResizingRedaction`)
- Watermark (`watermark: Watermark?`)
- Persistencia automática de cada cambio en `doc: DocumentItem`

**Herramientas del editor (`EditorTool`):**

| Herramienta | Función |
|-------------|---------|
| `.rect` | Dibuja rectángulo de redacción por drag |
| `.fields` | Muestra overlays de campos predefinidos por tipo de documento |
| `.auto` | Aplica redacciones automáticas del template del documento |
| `.text` | Abre `OCRSheetView` para seleccionar campos OCR |
| `.watermark` | Abre `WatermarkConfigView` |
| `.adjust` | Muestra/oculta `ImageAdjustToolbar` |

---

## 6. Vistas — catálogo completo

### Flujo de navegación principal

```
ShieldApp
└── ContentView
    ├── OnboardingView        (si !isOnboarded)
    ├── LockScreenView        (si isOnboarded && !isAuthenticated)
    └── MainInterface         (si isAuthenticated)
        ├── HomeView          (tab .library)
        ├── StyleGalleryView  (tab .gallery)
        ├── VaultView         (tab .vault)
        └── SettingsView      (tab .settings)
        
        // Overlays de nivel raíz (zIndex 50/60)
        ├── CaptureView       (appState.showCapture)
        └── EditorView        (appState.selectedDoc)
```

### `HomeView`
**Archivo:** [Views/Home/HomeView.swift](../Shield/Views/Home/HomeView.swift)

Secciones verticales en orden:
1. **Sticky header** — logo, toggle idioma, toggle tema, botón settings
2. **Title section** — título "Documentos", conteo, badge Free/Pro
3. **Search** — TextField con filtro activo
4. **Category scroll** — pills de categorías built-in + usuario + botón "Nueva"
5. **Modes section** — `ModeCard` horizontal para los 4 `RedactionMode`
6. **Recents section** — lista de `DocumentRow` con context menu
7. **Vault section** — banner de acceso rápido a la bóveda
8. **Cloud storage section** — panel de almacenamientos en nube *(nuevo)*

#### Sección Cloud Storage (HomeView)
Muestra el estado de todos los proveedores de nube con indicador visual:

```
┌─────────────────────────────────────────────────────┐
│ ALMACENAMIENTO EN NUBE              Pro →            │
├─────────────────────────────────────────────────────┤
│ 🟣 iCloud          ● Sincronizado · 30 abr 15:42    │
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
│ 🔵 Google Drive    ● No conectado                  +│
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
│ 🔵 Dropbox         ● No conectado                  +│
├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┤
│ 🔵 OneDrive        ● No conectado                  +│
└─────────────────────────────────────────────────────┘
```

**Estados del indicador de color:**
- 🟢 Verde — conectado / iCloud sincronizado
- ⚪ Gris — no conectado / desactivado  
- 🟠 Naranja — configurado pero no disponible (iCloud sin entitlement)

**Comportamiento por tier:**
- **Free:** iconos semi-opacos, estado "Requiere Pro", toca → paywall
- **Pro — no conectado:** toca → OAuth2 del proveedor / settings para iCloud
- **Pro — conectado:** toca → `ExternalStoragePickerSheet` para importar archivo
- **Long press en conectado:** context menu "Desconectar"

**Flujo de importación desde Home:**
El archivo seleccionado se envía via `NotificationCenter` (`shield.importFileURL`) a `CaptureView`, que lo procesa con el mismo pipeline que una importación directa.

### `CaptureView`
**Archivo:** [Views/Capture/CaptureView.swift](../Shield/Views/Capture/CaptureView.swift)

Punto de entrada para todos los métodos de importación:

| Fuente | Flujo |
|--------|-------|
| Cámara (`VNDocumentCameraViewController`) | → `DocumentScannerOverlayView` → `ScanReviewView` → `processImportedPages` |
| Fotos (`PhotosUI`) | → `PhotoPickerView` → `ScanReviewView` → `processImportedPages` |
| Archivos (`UIDocumentPickerViewController`) | → `FilesPickerView` → `processFile` → (`ScanReviewView` o directo) → `processImportedPages` |
| Nube (Home) | → `NotificationCenter("shield.importFileURL")` → `processFile` |

#### Selector de tipo de documento (`ScanDocumentType`)
Nuevo enum con 5 casos que controla el marco guía durante el escaneo:

| Tipo | Ratio | Field hints |
|------|-------|-------------|
| `.identity` | 85.6:54 (ID-1) | Nombre, Foto, DOB, MRZ |
| `.passport` | 125:88 | Foto, Nombre, Nº pasap., MRZ |
| `.drivingLicense` | 85.6:54 | Foto, Nombre, Nº carnet |
| `.a4Document` | 210:297 | Sin hints |
| `.freeform` | 1:1 | Sin frame, sin hints |

El overlay (`DocumentScannerOverlayView`) renderiza:
- Dimming exterior con recorte even-odd (`GuideFrameCutout`)
- Borde amarillo con corner ticks (`GuideFrameBorder`)
- Zonas de campo con línea discontinua y etiqueta
- Label del tipo seleccionado sobre el frame

### `EditorView`
**Archivo:** [Views/Editor/EditorView.swift](../Shield/Views/Editor/EditorView.swift)

Composición vertical:
```
topBar          — título doc, conteo redacciones, botón exportar
sensitiveBanner — alerta de campos sensibles detectados (dismissible)
canvasArea      — DocumentCanvas con navegación multipágina
ImageAdjustToolbar — panel de ajuste (visible solo cuando tool == .adjust)
modeChips       — chips horizontales de RedactionMode
maskStylePicker — MaskStylePicker con estilos Free/Pro
bottomBar       — undo/redo + herramientas (rect, fields, auto, text, watermark, adjust)
```

### `DocumentCanvas`
**Archivo:** [Views/Editor/DocumentCanvas.swift](../Shield/Views/Editor/DocumentCanvas.swift)

Canvas interactivo sobre el documento renderizado. Gestiona tres tipos de interacción:

1. **Dibujo** (`DragGesture` sobre fondo) — crea `Redaction` normalizada
2. **Selección** (`TapGesture` sobre redacción existente) — activa handle amarillo
3. **Drag para mover** (`DragGesture` sobre redacción activa) — mueve preservando `id`
4. **Resize** (handles SE y SW de la redacción activa) — redimensiona con `CGRect` normalizado

Coordenadas: todo se normaliza dividiendo por `canvasSize.width/height`. La redacción almacena rect normalizado; el canvas escala a píxeles para render.

### `ImageAdjustToolbar`
**Archivo:** [Views/Editor/ImageAdjustToolbar.swift](../Shield/Views/Editor/ImageAdjustToolbar.swift)

Panel deslizable (transition `.move(edge: .bottom)`) con:
- **Acciones rápidas:** Girar 90°, Voltear H, Voltear V (todos Pro excepto si solo Brillo/Contraste)
- **Selector de herramienta:** Brillo, Contraste (Free), Saturación, Nitidez, Recorte (Pro)
- **Slider activo** con valor numérico, botón reset al default
- **Recorte**: 4 sliders independientes (Top/Bottom/Left/Right, 0–40%)
- **Indicador de cambios** activos: punto azul en el botón `.adjust` de la toolbar

Tier Free/Pro por herramienta:
| Herramienta | Free | Pro |
|-------------|------|-----|
| Brillo | ✅ | ✅ |
| Contraste | ✅ | ✅ |
| Saturación | ❌ | ✅ |
| Nitidez | ❌ | ✅ |
| Recorte | ❌ | ✅ |
| Girar/Voltear | ❌ | ✅ |

### `VaultView`
**Archivo:** [Views/Vault/VaultView.swift](../Shield/Views/Vault/VaultView.swift)

Acceso Pro-gated. Flujo de autenticación:
1. Biometría (`LAContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)`)
2. Si no disponible → `deviceOwnerAuthentication` (passcode del sistema)
3. Si no disponible → `PINEntryView` / `PINSetupView`

**`PINManager`** — gestión del PIN de bóveda:
- Hash SHA-256 almacenado en Keychain con `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`
- Backoff exponencial: bloqueo desde el 3er intento fallido, base 30s × 2^n (máx. 2^6 = 64× = 32min)
- Estado de lockout persistido en `UserDefaults` (sobrevive reinicios de app)

### `OnboardingView` + `LockScreenView`
**Archivo:** [Views/Onboarding/OnboardingView.swift](../Shield/Views/Onboarding/OnboardingView.swift)

**Onboarding** — 3 slides:
1. Bienvenida
2. Privacidad (sin servidores)
3. Configurar seguridad (Face ID real via `LAContext` + PIN)

`setupFaceID()` llama `LAContext.evaluatePolicy` real — si falla, muestra error y habilita "Configurar después" como escape seguro.

**LockScreen** — lógica de desbloqueo:
```
biometricEnabled && hasBiometrics && PINManager.hasPIN → Face ID automático
biometricEnabled && !PINManager.hasPIN               → Fuerza setup de PIN primero
!biometricEnabled && PINManager.hasPIN               → Solo PIN
!biometricEnabled && !PINManager.hasPIN              → authenticatePasscode (sistema)
```
Auto-disparo biométrico controlado por `didTriggerAutoBiometric` — un solo intento por aparición de la vista.

---

## 7. Capa Cloud

### `CloudSyncManager`
**Archivo:** [Cloud/CloudSyncManager.swift](../Shield/Cloud/CloudSyncManager.swift)  
**Patrón:** `@MainActor` singleton, observado con `@ObservedObject`

Sincroniza el **índice de documentos** (metadatos) vía CloudKit Private Database. Los archivos de imagen/PDF nunca salen del dispositivo.

**Container:** `iCloud.com.romerodev.shield`  
**Record type:** `ShieldDocument`

Campos sincronizados:

| Campo CKRecord | Tipo | Descripción |
|----------------|------|-------------|
| `docID` | `String` | UUID del documento |
| `title` | `String` | Título |
| `kind` | `String` | `DocumentKind.rawValue` |
| `category` | `String` | `DocumentCategory.rawValue` |
| `date` | `Date` | Fecha de creación |
| `redactionCount` | `Int` | Total de redacciones |
| `isFavorite` | `Int` | 0/1 |
| `isVaulted` | `Int` | 0/1 |
| `sourceType` | `String` | `ImportedDocumentSource.rawValue` |

**Diseño de seguridad:** `ckContainer` es lazy y solo se instancia si `shield.icloud.enabled == true`. Si el entitlement de CloudKit no está configurado, todas las operaciones retornan sin hacer nada.

**API pública:**
```swift
func pushDocuments(_ documents: [DocumentItem]) async
func fetchRemoteIndex() async -> [CloudDocumentRecord]
func deleteRemoteDocument(id: String) async
func setSyncEnabled(_ enabled: Bool)
```

**Requisito:** Capability "iCloud + CloudKit" en Xcode, container `iCloud.com.romerodev.shield` activo en developer.apple.com.

### `ExternalStorageManager`
**Archivo:** [Cloud/ExternalStorageManager.swift](../Shield/Cloud/ExternalStorageManager.swift)  
**Patrón:** `@MainActor` singleton + `NSObject` (para `ASWebAuthenticationPresentationContextProviding`)

Gestiona la autenticación OAuth 2.0 y la conexión a proveedores externos.

**Proveedores (`ExternalStorageProvider`):**

| Proveedor | Auth URL | Scope | Redirect |
|-----------|----------|-------|----------|
| Google Drive | `accounts.google.com/o/oauth2/v2/auth` | `drive.readonly` | `shield://oauth/googleDrive` |
| Dropbox | `dropbox.com/oauth2/authorize` | `files.content.read` | `shield://oauth/dropbox` |
| OneDrive | `login.microsoftonline.com/.../authorize` | `Files.Read offline_access` | `shield://oauth/oneDrive` |

**Flujo OAuth (Implicit flow):**
1. `ASWebAuthenticationSession` abre el portal del proveedor
2. Tras login, redirige a `shield://oauth/<provider>#access_token=...`
3. Se parsea el fragment de la URL de callback
4. Token almacenado en `UserDefaults` (clave `shield.cloud.<provider>.token`)
5. Estado de conexión en `UserDefaults` (clave `shield.cloud.<provider>.connected`)

**Nota de seguridad:** En producción el token debería almacenarse en Keychain, no en `UserDefaults`.

**Importación de archivos:** La importación real usa `UIDocumentPickerViewController` (selector nativo de iOS), que incluye Google Drive, Dropbox y OneDrive si sus apps están instaladas — sin necesidad de OAuth. El OAuth añade conexión directa sin app instalada.

**Requisitos de configuración:**
- URL scheme `shield` en `Info.plist` (`CFBundleURLSchemes`)
- Client IDs registrados en cada portal de desarrollador:
  - Google: `UserDefaults["shield.oauth.google.clientID"]`
  - Dropbox: `UserDefaults["shield.oauth.dropbox.appKey"]`
  - OneDrive: `UserDefaults["shield.oauth.onedrive.clientID"]`

---

## 8. Seguridad y cifrado

### `SecureFileStore`
**Archivo:** [ViewModels/AppState.swift](../Shield/ViewModels/AppState.swift) (línea ~536)

Todos los archivos de datos se cifran con AES-256-GCM antes de escribir a disco.

**Formato en disco:**
```
[SHLD1 magic (5 bytes)] + [AES-256-GCM combined ciphertext]
```

El prefijo `SHLD1` permite detectar archivos no cifrados (migración) al leer.

**Clave maestra:**
- Generada en primer uso: `SymmetricKey(size: .bits256)`
- Almacenada en Keychain: service `com.romerodev.shield.secure-store`, account `master-key`
- Accesible: `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Una sola clave compartida por toda la app (no por-documento)

**`KeychainStore`** — wrapper estático sobre Security framework:
- `save(_:service:account:accessible:)` — upsert (update si existe, add si no)
- `read(service:account:)` — devuelve `Data?`
- `delete(service:account:)` — eliminación

**Protección de archivos adicional:**
Al escribir cualquier archivo, se aplica `FileProtectionType.complete` via `FileManager.setAttributes`. Esto añade una capa de cifrado del sistema operativo sobre AES-GCM propio.

### `PINManager`
Gestión del PIN de 6 dígitos para la bóveda:
- Hash: `SHA256(pin.utf8)` — 32 bytes
- Almacenado en Keychain con `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly`
- Si el passcode del sistema se desactiva, el PIN de la bóveda se invalida automáticamente

### Política de autenticación

| Escenario | Método |
|-----------|--------|
| Lock screen principal | Face ID → PIN Shield → Passcode sistema |
| Vault | Face ID → Passcode sistema → PIN Shield |
| Activar Face ID | Requiere PIN Shield configurado primero |
| Onboarding | Face ID real + PIN + escape "configurar después" |

---

## 9. Sistema de captura e importación

### `OCRService`
**Archivo:** [Views/Capture/CaptureView.swift](../Shield/Views/Capture/CaptureView.swift) (línea ~1448)

Motor de OCR usando `Vision.VNRecognizeTextRequest`. API completamente on-device.

```swift
enum OCRService {
    static func recognizeTextByPage(in images: [UIImage]) async -> [[String]]
    static func extractFields(from lines: [String]) -> DocumentFields
    static func detectDocumentType(from lines: [String]) -> DetectedDocumentType
    static func assessRisk(fields: DocumentFields, detectedType: DetectedDocumentType, threshold: Double) -> RiskAssessment
    static func minimumConfidenceThreshold() -> Double
}
```

**Detección de tipo de documento:**
Analiza patrones MRZ, palabras clave y formato de número para clasificar en `.dni`, `.passport` o `.document`.

**Validación MRZ:**
Verifica el checksum estándar ICAO 9303 para pasaportes (MRZ-2) y documentos de identidad (MRZ-3).

**Evaluación de riesgo:**
Cruza la confianza de cada campo con el umbral configurado en Settings. Niveles: `.low`, `.medium`, `.high`.

### `ScanReviewView` + `ScanImageProcessor`
Vista intermedia entre la captura y la creación del documento, con ajustes por página antes de almacenar:

**`ScanPageAdjustment`** — ajustes de pre-procesado:
- `filterPreset`: Original / Auto / B&N / Contraste+
- `straightenDegrees`: corrección de inclinación via `CIStraightenFilter`
- `perspectiveTopInset/BottomInset/Skew/TopYOffset/BottomYOffset`: corrección de perspectiva via `CIPerspectiveCorrection`
- `cropLeft/Right/Top/Bottom`: recorte por insets normalizados
- `brightness/contrast/sharpness/noiseReduction`: controles finos via CIFilters

**`ScanImageProcessor.apply`** — aplica el pipeline en este orden:
1. Preset de filtro (ColorControls)
2. Corrección de inclinación (CIStraightenFilter)
3. Corrección de perspectiva (CIPerspectiveCorrection)
4. Recorte
5. Brillo + contraste
6. Nitidez (CISharpenLuminance)
7. Reducción de ruido (CINoiseReduction)
8. Rotación hard (90° steps)

---

## 10. Pipeline de exportación

**Archivo:** [Views/Editor/ExportSheetView.swift](../Shield/Views/Editor/ExportSheetView.swift) — `ExportEngine`

### Flujo PDF

```
ExportEngine.exportAsPDF
    │
    ├─ ¿Tiene imageAdjustment? → NO + ¿fuente PDF pura? → exportOriginalPDFIfAvailable
    │                                                      (fast path: renderiza con PDFKit)
    │
    └─ Pipeline de rasterización por página:
        1. Cargar UIImage de cada página desde SecureFileStore
        2. Aplicar imageAdjustment (si existe) con ExportEngine.applyImageAdjustment
        3. compositePageImage:
            a. Renderizar imagen base
            b. Dibujar redacciones NO-blur (CG directo)
            c. Aplicar blur redacciones (CIGaussianBlur sobre crop del CGImage)
            d. Dibujar watermark
        4. Empaquetar en UIGraphicsPDFRenderer
```

### Flujo imagen

```
ExportEngine.exportAsImage
    1. Cargar UIImage
    2. Aplicar imageAdjustment
    3. Escalar por factor de calidad (1×/2×/3×)
    4. Renderizar redacciones + blur + watermark
    5. Devolver UIImage
```

### `ExportEngine.applyImageAdjustment`

Aplica `ImageAdjustmentStore` sobre una `UIImage` usando el mismo pipeline de CIFilters que `ScanImageProcessor`. Opera sobre `CIImage` y devuelve `UIImage`.

### Watermark Free vs Pro

| Tier | Watermark |
|------|-----------|
| Free | Forzado: "Protected with Shield Free" (o en español) si el usuario no puso uno |
| Pro | Solo si el usuario configuró uno explícitamente |

### Calidad de exportación

| Setting | Scale factor | Uso |
|---------|-------------|-----|
| Alta | 3× | Documentos oficiales |
| Media | 2× | Compartir general |
| Baja | 1× | Vista previa / tamaño reducido |

---

## 11. Motor OCR

Ver sección 9. Adicionalmente, `OCRSheetView` permite:
- Ver campos detectados con nivel de confianza por campo
- Releer el documento manualmente
- Ver el texto completo extraído (colapsable)
- Ver el MRZ en monospaced
- Tocar "Ocultar" en cualquier campo → añade redacción sobre esa zona
- Ver el país detectado y la validez del MRZ

---

## 12. Sistema de ajuste de imagen

Hay **dos pipelines distintos** de ajuste de imagen en la app:

| Pipeline | Cuándo | Herramienta |
|----------|--------|-------------|
| `ScanImageProcessor` | Durante la revisión post-escaneo (`ScanReviewView`) | Pre-procesa antes de guardar el archivo |
| `ImageAdjustment` + `ExportEngine.applyImageAdjustment` | En el editor, aplicado en el export | No modifica el archivo guardado |

**Diferencia clave:** `ScanImageProcessor` modifica la imagen antes de guardarla en disco. `ImageAdjustment` almacena los parámetros en el documento y los aplica en el momento de exportar, no en la imagen guardada.

---

## 13. Monetización y tiers Free/Pro

**Archivo:** [Premium/PremiumManager.swift](../Shield/Premium/PremiumManager.swift)

### `PremiumManager` — StoreKit 2

```swift
@MainActor
final class PremiumManager: ObservableObject {
    @Published private(set) var isPro: Bool
    @Published private(set) var products: [Product]
    @Published private(set) var purchaseError: String?
    @Published var isPurchasing: Bool
    @Published var isRestoring: Bool
}
```

**Productos (`ShieldProduct`):**

| Product ID | Tipo | Precio sugerido |
|------------|------|----------------|
| `com.romerodev.shield.pro.weekly` | Suscripción autorrenovable semanal | 0,99 EUR (base España) |
| `com.romerodev.shield.pro.monthly` | Suscripción autorrenovable mensual | 2,99 EUR (base España) |
| `com.romerodev.shield.pro.annual` | Suscripción autorrenovable anual | 29,99 EUR (base España), prueba de 7 días |

**Verificación de entitlements:** `Transaction.currentEntitlements` async stream. El status de `isPro` se persiste en `UserDefaults["shield.isPro"]` como cache para el arranque de la app.

**Límites Free:**

| Límite | Valor | Clave |
|--------|-------|-------|
| Documentos máximos | 3 | `PremiumManager.freeDocumentLimit` |
| Exportaciones/semana | 3 | `PremiumManager.freeWeeklyExportLimit` |

El historial de exportaciones se guarda como array de timestamps en `UserDefaults["shield.free.exportHistoryTimestamps"]`. La ventana es de 7 días.

**Triggers de paywall (`PaywallTrigger`):**

| Trigger | Cuándo |
|---------|--------|
| `.manual` | Tap en banner Pro en Settings |
| `.docLimitReached` | Intento de importar > 3 docs |
| `.exportLimitReached` | Intento de exportar sin cuota |
| `.styleLocked` | Seleccionar estilo premium en Free |
| `.vaultUpgrade` | Acceder a Vault en Free |
| `.settingsUpgrade` | Tap en banner Pro en Settings / cloud |

**Paywall contextual:** cada trigger muestra un mensaje diferente en `contextBanner`. El array de features está localizado (ES/EN) via `features(lang:)`.

---

## 14. Persistencia local

### Estructura de directorios

```
~/Library/Application Support/Shield/
├── documents.json          ← [DocumentItem] cifrado AES-256-GCM
├── categories.json         ← [UserCategory] cifrado AES-256-GCM
├── telemetry.ndjson        ← eventos en JSON lines (plain text)
├── images/
│   ├── <docID>_p0.jpg      ← página 0 (cifrada)
│   ├── <docID>_p1.jpg      ← página 1 (cifrada)
│   └── ...
├── vault-images/
│   └── ...                 ← misma estructura, documentos en bóveda
├── sources/
│   └── <docID>.pdf         ← PDF original (cifrado)
└── vault-sources/
    └── ...
```

### Convención de nombres de archivo

`<docID>_p<pageIndex>.jpg` — donde `docID` es el UUID del documento y `pageIndex` es 0-based.

Para documentos de una sola página: `<docID>.jpg` (sin sufijo `_p0`).

### Migración de datos

`SecureFileStore.read` detecta el magic header `SHLD1`. Si no existe, devuelve los datos tal cual (plain text o JSON sin cifrar). Esto permite migración transparente de datos guardados en versiones anteriores.

`loadCustomCategories` tiene fallback análogo: intenta leer cifrado, si falla lee plain.

---

## 15. Auto-lock y ciclo de vida

**Archivo:** [ViewModels/AppState.swift](../Shield/ViewModels/AppState.swift)

### Opciones de auto-lock (índice en `UserDefaults["shield.autoLock"]`):

| Índice | Delay | Descripción |
|--------|-------|-------------|
| 0 | 0s | Inmediato (al pasar a background) |
| 1 | 60s | 1 minuto |
| 2 | 5 min | 5 minutos |
| 3 | 15 min | 15 minutos |
| 4 | nil | Nunca |

### Mecanismo dual:

1. **Por ciclo de vida** (`scenePhase`): al pasar a `.background` se guarda el timestamp. Al volver a `.active` se compara con el delay configurado.

2. **Por inactividad en foreground**: timer de 15s que compara `Date.now` con el último `markUserActivity()`. `ScaleButtonStyle.onChange(isPressed)` llama `markUserActivity()` en cada interacción.

### Secuencia al ir a background con delay = 0:
```
scenePhase → .background
    → markBackgroundTimestampAndLockIfImmediate()
    → isAuthenticated = false  (inmediato)
```

---

## 16. Localización

**Archivo:** [ViewModels/AppState.swift](../Shield/ViewModels/AppState.swift) — `L10nKey`

La app soporta ES (español) y EN (inglés). Se usa un enum `L10nKey` con `string(lang:)` en lugar de `Localizable.strings` para mantener todo en código y evitar archivos de strings externos.

`AppState.str(_:)` es el shorthand: `appState.str(.welcome)`.

El idioma se persiste en `UserDefaults["shield.language"]` y se puede cambiar en Settings o desde el sticky header del Home.

**Strings hardcoded restantes** (no bloqueantes, sin impacto en review):
- `PaywallView.PlanRow` — `planName`, `planSubtitle`, `periodLabel` (derivados de `product.displayName` vía StoreKit, ya localizado por App Store Connect)

---

## 17. Telemetría local

**Archivo:** [ViewModels/AppState.swift](../Shield/ViewModels/AppState.swift)

`AppState.trackEvent(_:properties:)` escribe JSON lines en `telemetry.ndjson`. Solo visible en `#if DEBUG`. No hay red, no hay analytics externos.

**Eventos instrumentados:**

| Evento | Cuándo |
|--------|--------|
| `import_started` | Al iniciar importación |
| `import_completed` | Documento añadido con éxito |
| `import_failed` | Error en importación |
| `risk_detected` | OCR detecta riesgo medium/high |
| `redaction_applied` | Cualquier redacción añadida |
| `export_attempted` | Botón exportar tocado |
| `export_success` | PDF/imagen generado correctamente |
| `export_failed` | Error en exportación |
| `export_blocked_free_limit` | Límite semanal Free agotado |
| `export_blocked_risk` | Riesgo OCR no confirmado |
| `scan_adjustment_opened` | ScanReviewView presentado |
| `scan_adjustment_applied` | Páginas procesadas y confirmadas |
| `paywall_viewed` | PaywallView visible |
| `paywall_dismissed` | PaywallView cerrado sin comprar |

**Eventos pendientes de instrumentar** (P2):
- `purchase_success`, `restore_success`, `vault_unlocked`, `onboarding_completed`

---

## 18. Frameworks usados

| Framework | Uso |
|-----------|-----|
| **SwiftUI** | UI completa |
| **StoreKit 2** | IAP, suscripciones, verificación de entitlements |
| **LocalAuthentication** | Face ID / Touch ID |
| **VisionKit** | `VNDocumentCameraViewController` — scanner de documentos |
| **Vision** | `VNRecognizeTextRequest` — OCR on-device |
| **CloudKit** | Sync de índice via CloudKit Private Database |
| **AuthenticationServices** | `ASWebAuthenticationSession` — OAuth2 externos |
| **PDFKit** | Render de PDFs, exportación, rasterización de páginas |
| **PhotosUI** | `PHPickerViewController` — importación desde Photos |
| **CoreImage / CIFilterBuiltins** | Filtros de imagen, blur, perspectiva, color |
| **CryptoKit** | `AES.GCM`, `SHA256` |
| **Security** | Keychain (`SecItemAdd`, `SecItemCopyMatching`, etc.) |
| **MessageUI** | `MFMailComposeViewController` — contacto/soporte |
| **UniformTypeIdentifiers** | Tipos de archivo en `UIDocumentPickerViewController` |

---

## 19. Convenciones de código

- **`// MARK: -`** para separar secciones dentro de un archivo
- `private` para todo lo que no necesita ser público
- Los tipos de dominio usan `struct` + `Codable` cuando deben persistirse, `enum` para tipos cerrados
- Los singletons de servicio son `@MainActor final class` con `static let shared`
- Las vistas usan `@ViewBuilder` para propiedades de vista complejas
- Coordenadas siempre normalizadas (0..1) en modelos; se escalan a píxeles solo en render
- Los closures de acción en views se pasan como `@escaping () -> Void`
- Ningún comentario inline sobre "qué hace el código" — solo sobre invariantes no obvias

---

## 20. Pendientes técnicos conocidos

> Estado vigente: consultar `RELEASE_READINESS_2026-07-13.md`. La tabla histórica que seguía a este encabezado describía la versión anterior a la reconstrucción y ha quedado sustituida por las puertas externas verificables de ese documento.
