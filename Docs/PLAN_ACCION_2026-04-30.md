# Plan de Acción Shield — Auditoría + Implementación

**Fecha:** 30 de abril de 2026  
**Auditor/Ejecutor:** Claude Code (Anthropic)  
**Rama:** `main`  
**Referencias:** `Docs/AUDITORIA_SHIELD_2026-04-28.md`

---

## Resumen ejecutivo

Esta sesión ejecutó una auditoría completa sobre el código fuente actual y procedió a implementar
todas las correcciones y mejoras identificadas, incluyendo hallazgos nuevos del usuario no
documentados en auditorías anteriores.

---

## Estado final de implementación (30 abr 2026)

### ✅ Completado en esta sesión

#### Correcciones críticas (P0/P1)

| # | Corrección | Archivos afectados |
|---|-----------|-------------------|
| 1 | **RedactionMode filters no hacían nada** — filtros Alquiler/Viaje/Empleo/Verificación no aplicaban en docs `.photo`. Reescrito `applyMode()` con lógica de filtrado real para docs estructurados Y nueva función `AutoRedactions.ocrModeRects(for:fields:)` para docs foto/genérico usando posiciones normalizadas | `EditorViewModel.swift`, `Document.swift` |
| 2 | **Marco guía de escaneo por tipo** — nuevo `ScanDocumentType` (DNI, Pasaporte, Carnet, A4, Libre) con overlay interactivo, ángulo correcto, zones de campo OCR dibujadas, control de visibilidad, selector de tipo en CaptureView | `CaptureView.swift` |
| 3 | **Handles drag/resize en redacciones** — arrastrar para mover la redacción activa, 2 handles de esquina (SE + SW) para redimensionar, guardas de límites normalizados | `DocumentCanvas.swift`, `EditorViewModel.swift` |
| 4 | **Toolbar avanzado de ajuste de imagen** — herramientas: Brillo, Contraste, Saturación, Nitidez, Recorte (4 lados), Girar 90° CW, Voltear H/V; estado libre/Pro por herramienta; indicador de cambios activos en el botón | `ImageAdjustToolbar.swift` (nuevo), `EditorView.swift`, `EditorViewModel.swift` |
| 5 | **`ImageAdjustment` persistido en `DocumentItem`** — `ImageAdjustmentStore` (Codable) almacenado en el documento y restaurado al abrir el editor | `Document.swift`, `EditorViewModel.swift` |
| 6 | **Strings hardcoded en español en `PINSetupView` + `PINEntryView`** — todos los textos localizados a ES/EN via `appState.language`; añadido `@EnvironmentObject var appState` y `.environmentObject(appState)` en todos los `fullScreenCover` | `VaultView.swift`, `SettingsView.swift`, `OnboardingView.swift` |
| 7 | **Onboarding sin auth real** — "Activar Face ID" ahora llama `LAContext.evaluatePolicy` real; "Establecer PIN" abre `PINSetupView`; añadida opción "Configurar después" como escape | `OnboardingView.swift` |
| 8 | **`annualSavings` hardcoded inglés + sin guard negativo** — localizado a ES/EN, añadido `guard pct > 0` | `PremiumManager.swift`, `PaywallView.swift` |
| 9 | **Features del paywall hardcoded en español** — `features` convertido a función `features(lang:)` con 8 features bilinguales incluyendo 2 nuevas (ajuste de imagen, iCloud) | `PaywallView.swift` |
| 10 | **"Shield Pro — Activo" hardcoded español** — localizado | `SettingsView.swift` |
| 11 | **`customCategories` guardado sin cifrado** — `persistCustomCategories()` usa `SecureFileStore.shared.write`; `loadCustomCategories()` migra con fallback plain→encrypted | `AppState.swift` |
| 12 | **`AutoRedactions` incompleto para passportMEX, dniITA, genericID** — añadidos rects sugeridos para todos los tipos | `Document.swift` |

#### Nuevas funcionalidades (features completas)

| # | Feature | Archivos |
|---|---------|---------|
| 13 | **iCloud CloudKit sync** — `CloudSyncManager` sincroniza el índice de documentos (metadata only, sin archivos) vía CloudKit private database; sección iCloud en Settings (Pro only) con toggle, "Sincronizar ahora", última fecha de sync, estado de error | `CloudSyncManager.swift` (nuevo), `SettingsView.swift` |
| 14 | **Conectores de almacenamiento externo** — `ExternalStorageManager` con OAuth 2.0 (ASWebAuthenticationSession) para Google Drive, Dropbox, OneDrive; `ExternalStoragePickerSheet` Pro-gated con lista de proveedores; opción "Desde la nube" en CaptureView | `ExternalStorageManager.swift` (nuevo), `CaptureView.swift` |
| 15 | **Free tier usage badge** — barra de progreso "X/3 documentos" en HomeView para usuarios Free; roja al límite; toca para abrir paywall | `HomeView.swift` |
| 16 | **Marco guía tipo-documento en scanner** — overlay con marco, esquinas amarillas, zonas de campo OCR, label del tipo seleccionado | `CaptureView.swift` |

---

## Arquitectura de nuevas funciones

### iCloud Sync (CloudSyncManager)
- **Privacidad:** Solo sincroniza metadatos (título, fecha, categoría, conteo de redacciones). Los archivos de imagen/PDF nunca salen del dispositivo.
- **Implementación:** CloudKit Private Database → record type `ShieldDocument` → `CKModifyRecordsOperation` con `savePolicy: .changedKeys`.
- **Configuración requerida:** Añadir capability "CloudKit" en Xcode → target → Signing & Capabilities. Container ID: `iCloud.com.romerodev.shield`.
- **Pro-only:** El toggle solo aparece si `pm.isPro`.

### External Storage (ExternalStorageManager)
- **OAuth 2.0 Implicit flow** via `ASWebAuthenticationSession`. Redirect URI: `shield://oauth/<provider>`.
- **Google Drive:** scope `drive.readonly`
- **Dropbox:** scope `files.content.read`
- **OneDrive:** scope `Files.Read offline_access`
- **Configuración requerida:**
  1. Registrar app en Google Cloud Console, Dropbox Developer Console, Azure Portal.
  2. Guardar Client IDs en `UserDefaults` (o mejor: en un archivo de config plistado no en repo).
  3. Añadir URL schemes en `Info.plist`: `shield` para el redirect.
  4. El selector nativo de archivos iOS (`UIDocumentPickerViewController`) ya incluye Google Drive, Dropbox y OneDrive si sus apps están instaladas — esto funciona sin OAuth adicional.
- **Pro-only:** `ExternalStoragePickerSheet` muestra paywall gate si `!pm.isPro`.

### ImageAdjustment (ImageAdjustToolbar + ImageAdjustmentStore)
- **Free:** Brillo + Contraste
- **Pro:** Saturación, Nitidez, Recorte, Girar, Voltear
- **Persistencia:** `ImageAdjustmentStore` (Codable) en `DocumentItem.imageAdjustment`
- **Render:** El export debe aplicar `ScanImageProcessor.apply` con los ajustes al exportar. TODO: conectar en `ExportEngine`.

### Scan Frame Guide (DocumentScannerOverlayView)
- Overlay over `VNDocumentCameraViewController` usando `ZStack` + `GeometryReader`
- `GuideFrameCutout` con even-odd fill rule para el dimming con recorte
- `GuideFrameBorder` con línea + 4 corner ticks en amarillo Shield
- Field hint labels por tipo (Nombre, Foto, MRZ, DOB, Nº)

---

## Pendiente — Requiere trabajo adicional

### P0 — Bloqueantes antes de App Store

| # | Item | Acción |
|---|------|--------|
| A | `PrivacyInfo.xcprivacy` no está en el build target | En Xcode: seleccionar `PrivacyInfo.xcprivacy` → Target Membership → marcar `Shield` |
| B | URLs `shieldapp.io/privacy` y `shieldapp.io/terms` sin verificar | Crear o activar dominio con los documentos legales. Mínimo: redirect a Notion/GitHub Pages |
| C | URL schemes OAuth no registrados en Info.plist | Añadir `shield` como URL scheme en Info.plist para callback OAuth |
| D | CloudKit container no configurado | Añadir capability CloudKit en Xcode con container `iCloud.com.romerodev.shield` |
| E | Client IDs OAuth vacíos | Registrar apps en Google Cloud, Dropbox Dev, Azure y hardcodear o cargar desde config |

### P1 — Funcional

| # | Item | Impacto |
|---|------|---------|
| F | `ExportEngine` no aplica `imageAdjustment` al exportar | Las correcciones de imagen no se ven en el PDF/imagen exportado |
| G | OCR multipágina: `extractFields` recibe texto aplanado sin contexto de página | Para docs 2+ páginas los campos pueden mezclarse |
| H | Corrección de perspectiva manual (4 handles draggables) en `ScanReviewView` | La UI de revisión tiene sliders pero no un editor de 4 puntos visual |
| I | Default auto-lock es "Inmediato" (index 0) para usuarios nuevos | Fricción innecesaria en primer uso |

### P2 — Comercial

| # | Item |
|---|------|
| J | Eventos de tracking faltantes: `export_success`, `purchase_success`, `restore_success` |
| K | Paywall no disponible en inglés sin traducir en `PlanRow.planName` / `planSubtitle` |
| L | Win-back offer (día 7 post-cancelación) via StoreKit 2 |
| M | Promoted IAPs en App Store Connect |

---

## Segmentación Free vs Pro — Estado actual

| Feature | Free | Pro |
|---------|------|-----|
| Importar foto/PDF/cámara | ✅ | ✅ |
| 3 exportaciones/semana | ✅ | — |
| Exportaciones ilimitadas | — | ✅ |
| Estilos Block + Blanco | ✅ | ✅ |
| 7 estilos premium (blur, pixelate…) | ❌ | ✅ |
| OCR local básico | ✅ | ✅ |
| Bóveda cifrada | ❌ | ✅ |
| Filtros de modo (rental/viaje/empleo) | ✅ | ✅ |
| Ajuste imagen Brillo+Contraste | ✅ | ✅ |
| Ajuste imagen Saturación+Nitidez+Recorte+Flip | ❌ | ✅ |
| iCloud sync | ❌ | ✅ |
| Import desde Google Drive/Dropbox/OneDrive | ❌ | ✅ |
| Export sin marca de agua | ❌ | ✅ |
| Watermark custom | ❌ | ✅ |
| Marco guía escaneo (todos los tipos) | ✅ | ✅ |
| Handles drag+resize en redacciones | ✅ | ✅ |
| Badge de uso (X/3 docs) | ✅ Free | — |

---

## Pricing recomendado (sin cambios desde auditoría anterior)

- Mensual: `4.99` USD
- Anual: `34.99` USD (ancla principal, "Ahorra X%")
- Lifetime: `79.99` USD

---

## Roadmap simplificado

### Semana 1 (Fase 0) — Lo que debe hacerse manualmente
1. Añadir `PrivacyInfo.xcprivacy` al target en Xcode (1 click)
2. Activar URLs de privacidad/términos
3. Añadir URL scheme `shield` en Info.plist
4. Configurar CloudKit container en Xcode
5. Conectar `imageAdjustment` en `ExportEngine`

### Semanas 2-4 (Fase 1)
- OCR multipágina con merge por página
- Perspectiva manual 4 puntos en ScanReviewView
- Fix default auto-lock a "1 minuto"
- Eventos de tracking faltantes

### Semanas 5-8 (Fase 2)
- Share Extension
- PDF hardening + metadata scrub
- Presets de privacidad por caso (alquiler, médico, legal…)
- Privacy Risk Score antes de exportar

### Semanas 9-12 (Fase 3)
- Win-back offer StoreKit 2
- Promoted IAPs
- A/B paywall anual vs mensual
- Trial 7 días

---

## Archivos nuevos creados en esta sesión

```
Shield/Cloud/CloudSyncManager.swift
Shield/Cloud/ExternalStorageManager.swift
Shield/Views/Editor/ImageAdjustToolbar.swift
```

## Archivos modificados en esta sesión

```
Shield/Models/Document.swift
Shield/ViewModels/AppState.swift
Shield/ViewModels/EditorViewModel.swift
Shield/Views/Capture/CaptureView.swift
Shield/Views/Editor/DocumentCanvas.swift
Shield/Views/Editor/EditorView.swift
Shield/Views/Home/HomeView.swift
Shield/Views/Onboarding/OnboardingView.swift
Shield/Views/Paywall/PaywallView.swift
Shield/Views/Settings/SettingsView.swift
Shield/Views/Vault/VaultView.swift
Shield/Premium/PremiumManager.swift
```
