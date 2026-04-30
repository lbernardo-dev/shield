---
name: Shield roadmap state
description: Estado del roadmap funcional de Shield al 30-abril-2026 — qué está implementado, qué se implementó hoy, y qué queda pendiente de configuración manual
type: project
---

## Estado general (30-abr-2026)

Shield compila y ejecuta en simulador (iPhone Air, iOS 26.2). Base técnica sólida con 28 archivos Swift, StoreKit 2, Vision, VisionKit, PDFKit, CloudKit, CryptoKit, LocalAuthentication.

## Implementado en código (✅ = listo en repo)

### Hito 0 – Seguridad y cumplimiento
- ✅ PrivacyInfo.xcprivacy existe y está en el build target (verificado en project.pbxproj línea 384)
- ✅ URLs privacy/terms en PaywallView apuntan a https://shieldapp.io/privacy y /terms
- ✅ Bypass de lock screen corregido — `authenticatePasscode` falla seguro si no hay auth
- ✅ Vault falla seguro si no hay biometría ni PIN (fuerza PINSetup)
- ✅ PIN con bloqueo exponencial persistente (PINManager, backoff desde intento 3, max 6 niveles)
- ✅ Auto-lock real gobernando scenePhase e inactivity timer (AppState)
- ✅ Default auto-lock = "1 minuto" para instalaciones nuevas (implementado hoy)

### Hito 1 – Núcleo de captura y redacción
- ✅ Importación unificada: cámara (VisionKit), fotos, archivos (PDF/imagen), nube (OAuth)
- ✅ Scanner multipágina real con ScanReviewView, reordenación y revisión por página
- ✅ Overlay guía por tipo documental (DNI, Pasaporte, Carnet, A4, Libre)
- ✅ OCR local con Vision, MRZ, confianza, campos por tipo documental
- ✅ Editor con drag+resize de redacciones, 9 estilos, undo/redo
- ✅ Exportación PDF e imagen con redacciones integradas
- ✅ Ajustes de imagen persistidos en DocumentItem (brillo, contraste, saturación, nitidez, recorte, rotación, flip)
- ✅ imageAdjustment aplicado en ExportEngine tanto PDF como imagen

### Hito 2 – Automatización
- ✅ Modos rápidos: rental, travel, job, verify (Free), legal, health, banking (Pro) — legal/health/banking implementados hoy
- ✅ Redacciones por OCR para todos los tipos documentales incluyendo los 3 nuevos modos
- ✅ Presets de imagen con toolbar avanzado (Free: brillo+contraste; Pro: saturación, nitidez, recorte, flip)
- ✅ Marcadores de riesgo OCR en ExportSheetView (shouldWarnForHighRiskExport)
- ⬜ Find All / propagación de redacciones entre páginas — NO implementado

### Hito 3 – Experiencias Pro
- ✅ Bóveda cifrada (Face ID + PIN + AES-256 + FileProtection.complete)
- ✅ iCloud CloudKit sync (metadata only, no archivos)
- ✅ Conectores OAuth Google Drive / Dropbox / OneDrive (ExternalStorageManager)
- ✅ Watermark personalizable (WatermarkConfigView)
- ⬜ Share Extension — NO implementada (requiere target nuevo en Xcode)
- ⬜ Batch multi-archivo redacción — NO implementado (solo multipágina por documento)

### Hito 4 – Diferenciación competitiva
- ✅ Privacy Risk Score en ExportSheetView — implementado hoy (panel colapsable con score 0-100)
- ✅ Eliminación EXIF/GPS en imagen export — implementado hoy (imageStrippingMetadata via ImageIO)
- ✅ Metadata scrub en PDF export: UIGraphicsPDFRenderer genera PDF limpio sin metadatos del source
- ✅ Paywall contextual con triggers (doc limit, export limit, style locked, vault, manual)
- ⬜ A/B tests de paywall — NO implementado
- ⬜ Win-back offer StoreKit 2 — NO implementado

### Monetización
- ✅ StoreKit 2: monthly ($2.99), annual ($19.99), lifetime ($9.99)
- ✅ Trial 7 días en plan anual (Shield.storekit actualizado hoy)
- ✅ PlanRow localizado EN/ES, muestra badge "7 días gratis / 7-day free trial" en annual
- ✅ Free tier: 3 docs, 3 exports/semana, 2 estilos, sin batch
- ⬜ Win-back offer configurada en App Store Connect — pendiente manual
- ⬜ Promoted IAPs en App Store Connect — pendiente manual

## Pendientes que requieren acciones MANUALES (no código)

| Item | Acción | Prioridad |
|------|--------|-----------|
| CloudKit container | En Xcode: Signing & Capabilities → CloudKit → container `iCloud.com.shield.redact` | P0 |
| URL scheme `shield://` | Info.plist → URL Types → shield (para OAuth callbacks) | P0 |
| URLs legales | Publicar contenido en shieldapp.io/privacy y /terms | P0 |
| OAuth Client IDs | Registrar app en Google Cloud Console, Dropbox Dev, Azure Portal | P1 |
| Win-back offer | Configurar en App Store Connect → Subscriptions | P2 |
| Promoted IAPs | Configurar en App Store Connect → In-App Purchases | P2 |
| Trial 7 días en producción | Configurar introductory offer en App Store Connect (Shield.storekit es solo para testing local) | P0 |

## Pendientes de código (futuros sprints)

- Share Extension target (Fase C) — requiere nuevo target en Xcode (manual)
- A/B paywall anual vs mensual (Fase D)

## Implementado en sesión 30-abr (segunda parte)

- ✅ OCR multipágina con merge por página: `recognizeTextByPage` → `extractFields` por página → merge eligiendo la página con mayor confianza (MRZ wins)
- ✅ Find All / propagación: `propagateCurrentPageToAllPages()` en EditorViewModel; banner "Find All" en EditorView cuando doc tiene >1 página y hay redacciones
- ✅ Perspectiva manual 4 puntos: `ScanQuad` + `FourPointPerspectiveEditor` (handles draggables) en ScanReviewView; toggle de activación en preview; `ScanImageProcessor.applyPerspective` usa quad cuando está definido
- ✅ Batch multi-archivo Pro: `BatchRedactView` — selector de docs, selector de modo, aplica redacciones a todos los docs seleccionados; botón "Batch Pro" en HomeView modesSection con lock Free

**Why:** Contexto vivo del roadmap para no repetir análisis en próximas sesiones.
**How to apply:** Al iniciar una sesión sobre Shield, leer este archivo antes de proponer nuevas tareas para no duplicar trabajo ya hecho.
