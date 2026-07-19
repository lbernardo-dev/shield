# 2-integral-rebuild

- Number: 2
- Slug: integral-rebuild

## Notes

- 2026-05-06 CODEX: Documentacion revisada (`Docs/AUDITORIA_SHIELD_2026-04-28.md`, `Docs/PLAN_ACCION_2026-04-30.md`, `Docs/ARQUITECTURA.md`, `memory/project_shield_state.md`).
- 2026-05-06 CODEX: Estado real validado con build iOS Simulator. Compila en `Debug` para esquema `Shield`.
- 2026-05-06 CODEX: Hallazgos estructurales principales:
  - `Shield/Views/Capture/CaptureView.swift` tiene 3756 lineas.
  - `Shield/Views/Home/HomeView.swift` tiene 1695 lineas.
  - `Shield/Views/Editor/ExportSheetView.swift`, `Shield/Views/Documents/DocumentRenderers.swift`, `Shield/ViewModels/AppState.swift` y `Shield/ViewModels/EditorViewModel.swift` concentran demasiada responsabilidad.
  - Existe al menos una ruta con fragilidad de produccion detectada en OAuth/cloud import (`ExternalStorageManager.presentationAnchor`).
- 2026-05-06 CODEX: Benchmark rapido de mercado contrastado con App Store/web:
  - El baseline competitivo ya incluye OCR on-device, redaccion irreversible, metadata scrub y batch.
  - El diferenciador de Shield no puede ser solo “todo en el dispositivo”.
  - La oportunidad real esta en un flujo rapido sobre documentos de identidad y pruebas documentales, con confianza verificable antes de compartir.
- 2026-05-06 CODEX: Primera refactorizacion aplicada:
  - `ContentView` reorganizado para separar shell autenticado de overlays de onboarding/bloqueo y reducir root swaps.
  - `ExternalStorageManager` deja de usar `fatalError` en ausencia de `UIWindowScene`.
  - warning menor corregido en `CaptureView` por variable sin uso.
- 2026-05-06 CODEX: Arquitectura objetivo propuesta:
  - Shell raiz pequena y estable.
  - Flujos separados por feature: Library, Capture, Editor, Export, Vault, Paywall.
  - Extraer servicios puros para OCR, import, export, auth gating y entitlement gating.
  - Reducir el rol de `AppState` a sesion, navegacion global y persistencia coordinada.
  - Descomponer vistas gigantes en subviews y pantallas especializadas.
- 2026-05-06 CODEX: Orden recomendado de reconstruccion:
  1. Shell/AppState/navigation/auth gates
  2. Capture flow
  3. Editor/export pipeline
  4. Home/library information architecture
  5. Monetizacion/paywall/settings
  6. Vault/cloud import hardening
