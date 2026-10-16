# 168-ui-regression-gate

- Number: 168
- Slug: ui-regression-gate

## Notes

### Cierre pendiente — 2026-10-16

- En la ejecución anterior del suite de `ShieldUITests` pasaron la navegación de Ajustes (`testSettingsNavigationRespondsToSingleTaps`), la accesibilidad del formulario de feedback (`testManualFeedbackFormIsLocalizedAndHasFreeText`) y el footer del paywall (`testPaywallFooterGroupsCTAAndLegalActions`). Falló únicamente el retorno de Captura tras Ajustes, línea 280.
- En `AuthenticatedShellView.openCapture()` se evitó publicar `selectedDoc = nil` cuando no hay editor abierto; al abrir desde una pestaña se presenta directamente el cover raíz. Al salir desde un editor se conserva el cierre previo y el defer de un ciclo de ejecución.
- La app compiló con `xcodebuild ... generic/platform=iOS Simulator build` y `build-for-testing` terminó con código 0.
- **Pendiente de verificación final en dispositivo:** el iPhone 18 Pro, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`, runtime iOS 27.0, permaneció ocupado durante la cola por runners activos de `schoolsnap`/`repsfitness`. No se instaló ni lanzó MaskID sobre ese dispositivo. Reejecutar los cuatro casos de UI de esta compuerta cuando quede libre y actualizar este archivo antes de marcar la tarea como terminada.

