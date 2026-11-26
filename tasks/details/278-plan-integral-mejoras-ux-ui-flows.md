# 278. Plan integral de mejoras UI/UX, Editor, Vault, Splash y Exportación

## Contexto y Objetivo
Implementación completa de las mejoras propuestas para elevar el valor, calidad, fluidez y atractivo de MaskID:
1. **Fase 1: Editor y Ergonomía del Canvas + Vault Safety**
   - **Lupa de Precisión (Magnifying Loupe)**: Proporcionar una lupa circular flotante de 2x de aumento al dibujar o redimensionar máscaras para evitar que el dedo del usuario obstruya el texto a enmascarar (`DocumentCanvas.swift`).
   - **Smart Suggestion Chips ("One-Tap Smart Redact")**: Añadir chips rápidos flotantes en el Editor (`EditorView.swift` / `EditorChromeViews.swift`) para enmascarar de un solo toque campos detectados no protegidos (DNI, Nombre, Caras, IBAN, etc.).
   - **Confirmación de Borrado en Biblioteca/Home**: Prevenir borrado accidental de documentos en `HomeView.swift` y `AllDocumentsView.swift` mediante alerta de confirmación (`DATA-001`).
   - **Accesibilidad en regiones**: Controles de ajuste fino accesibles para máscaras sin obligar a gestos de arrastre fino (`ACC-002`).

2. **Fase 2: Splash, Exportación y Propuesta de Valor**
   - **Splash Handoff Instantáneo**: Eliminar el retardo artificial bloqueante en `SplashView.swift` para conseguir un inicio rápido y fluido.
   - **Sello de Garantía Criptográfica / Anti-Fuga**: Mejorar la visualización del informe de verificación en `ExportSheetView.swift` convirtiéndolo en un certificado visual con estados interactivos.
   - **Valor Diferencial en Paywall**: Destacar en `PaywallView.swift` la destrucción real e irreversible a nivel de píxel frente a las cajas negras cosméticas de competidores.

3. **Verificación y Pruebas**:
   - Compilación limpia sin errores ni advertencias de tipo en `Shield` para iOS Simulator.
   - Verificación de la suite de pruebas unitarias (`ShieldTests`) en iPhone 18 Pro Simulator: 100% test suites pasadas (incluyendo `ExportVerifierTests`, `SecurityPrivacyTests`, `EnhancementFeaturesTests`, `PerformanceBudgetTests`, `OCREvidenceTests`, etc.).

## Estado de la Ejecución
- `PrecisionLoupeView` integrado en `DocumentCanvas.swift` (aumento 2.0x, retícula de precisión, auto-posicionamiento dinámico).
- Acción accesible de añadir máscara al centro y `.accessibilityAdjustableAction` para ajuste de máscaras integradas (`ACC-002`).
- `SmartSuggestionChipsView` implementado en `EditorChromeViews.swift` e integrado en `EditorView.swift` tanto para compact como regular workspace.
- `pendingDeleteDoc` y confirmación de borrado implementados en `HomeView.swift` y `AllDocumentsView.swift` (`DATA-001`).
- `SplashView.swift` optimizado con bypass de retardo en reduceMotion y reducción de 400ms a 250ms con tap-to-skip.
- `ExportProtectionCheckView` en `ExportFormViews.swift` transformado en Sello de Garantía Criptográfica / Anti-Fuga (triple garantía de texto 0 bytes, EXIF purgado, y capa rasterizada).
- `PaywallView.swift` enriquecido con `comparisonValueCard` destacando la destrucción irreversible a nivel de píxel vs cajas negras cosméticas.
