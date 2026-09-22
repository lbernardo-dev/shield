# 182-coffee-button-wcag-refactor

- Number: 182
- Slug: coffee-button-wcag-refactor

## Notes

- Refactorizado `SupportCoffeeButton` (y alias compatible `SupportCoffeePrompt`) en `Packages/AppEngagementKit`.
- Contraste adaptativo de alto contraste cumpliendo WCAG AA/AAA:
  - Dark Mode: tono ámbar cálido / caramelo (`Color(red: 0.98, green: 0.72, blue: 0.30)` / `#FBB84D`), ratio > 12:1 sobre fondo oscuro.
  - Light Mode: tono café tostado / espresso (`Color(red: 0.58, green: 0.32, blue: 0.12)` / `#94521F`), ratio > 5.5:1 sobre fondo claro.
  - Título ("¿Me regalas un café?"): `.foregroundStyle(.primary)` con `.subheadline.weight(.semibold)` alcanzando contraste 21:1.
- Composición limpia y minimalista: icono y título centrados verticalmente (`VStack(spacing: 7)`), eliminando el subtítulo con importe visible (preconfigurado en la URL de donación).
- Renderizado SF Symbols: `Image(systemName: "cup.and.saucer.fill")` con `.symbolRenderingMode(.hierarchical)` y color temático.
- Estilo táctil: `CoffeeButtonStyle` con reducción de escala a `0.98` y opacidad a `0.72` con curva `.spring(response: 0.25, dampingFraction: 0.7)` sin tintes forzados, más feedback háptico ligero con `UIImpactFeedbackGenerator`.
- Accesibilidad completa con `.accessibilityElement(children: .combine)`, `accessibilityLabel` y `accessibilityHint` localizados.
- Actualizados los call sites en `PaywallView` y `SettingsView`.
- Build verificado: SwiftPM target iOS Simulator y build de Xcode para `Shield` (`** BUILD SUCCEEDED **`).
