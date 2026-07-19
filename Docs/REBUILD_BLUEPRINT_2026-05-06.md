# Shield — Rebuild Blueprint

**Fecha:** 2026-05-06  
**Autor:** CODEX  
**Objetivo:** convertir Shield de una base funcional pero inconsistente en un producto iOS mantenible, verificable y comercializable.

## Diagnostico real

Shield no esta “sin hacer”, pero tampoco esta cerca de un producto cerrado. El repo compila y contiene muchas funciones, pero la app sigue penalizada por tres problemas de base:

1. **Arquitectura demasiado concentrada**
   - `CaptureView.swift`: 3756 lineas
   - `HomeView.swift`: 1695 lineas
   - `ExportSheetView.swift`: 1077 lineas
   - `DocumentRenderers.swift`: 983 lineas
   - `AppState.swift`: 707 lineas
   - `EditorViewModel.swift`: 701 lineas

2. **Responsabilidades mezcladas**
   - UI, logica de negocio, coordinacion de flujos, gating de premium, OCR, importacion y side effects viven juntos.
   - La app depende de estado global amplio y de vistas gigantes con demasiadas rutas internas.

3. **Diferenciacion de producto insuficiente**
   - El benchmark actual de mercado ya ofrece OCR on-device, redaccion plana/irreversible, scrub de metadatos y batch.
   - Shield solo puede competir si el flujo es mas claro, mas rapido y transmite mas confianza que las alternativas.

## Hallazgos de mercado

Contrastado el 2026-05-06 con App Store y Adobe:

- `On-Device PDF: OCR & Redact` posiciona OCR local, metadata cleanup, export seguro y batch como baseline.
- `PDF Redact App` vende presets por caso de uso y export PDF aplanado permanente.
- `NIX Redaction` enfatiza batch, metadata strip y destruccion del texto subyacente.
- Adobe Acrobat sigue siendo el referente macro de valor percibido para redaccion profesional y manejo documental.

## Implicacion de producto

Shield no debe intentar ganar por “tener muchas pantallas”. Debe ganar por un flujo corto:

1. importar o escanear
2. detectar riesgo
3. aplicar redaccion sugerida o manual
4. verificar que la salida es segura
5. exportar o compartir

Todo lo que no sirva claramente a ese flujo debe simplificarse, relegarse o eliminarse.

## Arquitectura objetivo

### 1. Shell estable
- `ShieldApp`
- `AppSessionCoordinator`
- `RootShellView`

Responsabilidad:
- onboarding
- autenticacion
- estado global minimo
- rutas principales

### 2. Modulo Library
- listado
- filtros
- categorias
- resumen de riesgo

### 3. Modulo Capture
- importacion camara/fotos/archivos/nube
- review multipagina
- ajustes y perspectiva
- pipeline OCR

### 4. Modulo Editor
- canvas
- seleccion de mascaras
- redacciones sugeridas
- propagacion multipagina

### 5. Modulo Export
- export image/pdf
- hardening
- metadata scrub
- password/options
- risk report

### 6. Modulo Vault
- acceso protegido
- bloqueo temporal
- persistencia cifrada

### 7. Modulo Monetization
- entitlement gating
- paywall contextual
- limits del tier Free

## Estrategia de reconstruccion

### Fase A — Fundacion
- reducir `AppState`
- limpiar el routing raiz
- centralizar auth gating y premium gating
- extraer coordinadores y servicios

### Fase B — Capture
- partir `CaptureView` en varias vistas y servicios
- aislar scanner, importers, review y OCR
- mantener multipagina y corregir puntos fragiles

### Fase C — Editor y export
- dividir editor en subcomponentes reales
- convertir el pipeline de export a servicio testeable
- unificar la aplicacion irreversible de redacciones

### Fase D — Home y producto
- rehacer `HomeView` alrededor del job-to-be-done
- simplificar discovery de funciones
- hacer visibles riesgo, estado de seguridad y siguiente accion

### Fase E — Comercializacion
- rehacer paywall contextual
- validar pricing y tiering
- preparar App Store/landing/legal

## Intervenciones hechas en esta sesion

- `ContentView` reorganizado para separar shell autenticado de overlays de onboarding/bloqueo.
- `ExternalStorageManager` deja de crashear con `fatalError` en una ruta de presentacion OAuth.
- warning menor de `CaptureView` corregido.
- build de simulador verificado despues de cambios.

## Criterio de exito

Shield estara “realmente terminado” cuando cumpla esto:

- la app compila sin warnings relevantes
- no hay vistas monstruo de 1000+ lineas
- el flujo import -> redact -> verify -> export funciona de forma consistente
- los fallos de auth, OCR y export estan contenidos y son recuperables
- el producto comunica una promesa clara y competitiva
