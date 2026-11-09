# 247-seasonal-theme-consent

- Number: 247
- Slug: seasonal-theme-consent

## Notes

### Auditoría y plan

- App: MaskID (`com.romerodev.shield`), deployment iOS 18, dispositivos universales iPhone/iPad. Targets descubiertos: `Shield`, `ShieldTests`, `ShieldUITests`, `ShieldShareExtension` y `ShieldWidgetExtension`; no existe target watchOS.
- Motor existente: catálogo, calendario, resolución y persistencia en `Shield/Theme/ShieldTheme.swift`; refresco y ciclo de vida en `Shield/App/ContentView.swift`; esquema de color en `Shield/ViewModels/AppState.swift`; galería en `Shield/Views/Settings/SettingsDestinationViews.swift`.
- Antes del cambio, la preferencia por defecto era automática y el resolver aplicaba el evento a cuentas Free; la apariencia base se ofrecía solo a Pro. La oferta comercial de Halloween vive en PremiumManager y se dejó separada.
- Plan aplicado: extender el coordinador existente con política/decisión por ocurrencia y migración idempotente; mostrar invitación discreta en Home estable; exponer controles gratuitos en Apariencia; respetar efectos reducidos, idiomas existentes y el esquema claro/oscuro; adaptar las pruebas del resolver y la persistencia.

### Implementación

- La instalación nueva pregunta por evento y conserva el tema base. Aceptar aplica solo la ocurrencia actual; `automatic` se guarda como preferencia futura independiente; `never`, mantener y descartar no alteran derechos Premium.
- La migración distingue selección antigua guardada de la ausencia de datos: mantiene una preferencia explícita `automatic`, respeta la antigua selección base como exclusión y no interpreta el valor automático implícito de una instalación antigua como consentimiento.
- La aparición de la invitación queda registrada por tema/año. Al terminar el periodo, el resolver vuelve a la selección regular vigente; la base y la salida son gratuitas.
- Se añadió control localizado ES/EN para política, evento actual y reducir efectos decorativos. No se cambiaron assets, fechas, paywall, StoreKit, RevenueCat ni promociones.
- Hallazgo de auditoría corregido: el allowlist de `AppState.trackEvent` descartaba las propiedades `event` y `preference`; las nuevas métricas usan `event_id` y `mode`, claves ya permitidas y no personales.

### Verificación pendiente de simulador

- Parse de fuentes Swift, validación JSON de `Settings.xcstrings`, comprobación de las 17 claves nuevas en inglés/español y `git diff --check`: correctos.
- `xcodebuild build-for-testing` terminó correctamente para iPhone 18 Pro con los últimos cambios. Un `xcodebuild test` anterior alcanzó “Testing started”, pero quedó bloqueado al materializar el runner en iPhone 18 Pro mientras otras sesiones usaban el simulador; se canceló solo el proceso propio y no se completó ningún caso de XCTest.
- Revalidaciones hasta 2026-10-30 13:07 Europe/Madrid: iPhone 18 Pro sigue ocupado con `com.romerodev.buzzwatch` y `com.romerodev.personalcare`; el Duo y el iPad Pro 13-inch M5 muestran `com.romerodev.culmina`. Reanudar primero en `1454EA8D-A019-4B07-B57C-1433E0F21BE0` (iOS 27.0), después probar Duo (`BF5C28D6-2B6D-46FC-82E8-9A248F5C0186`, iOS 27.1) e iPad (`2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`, iOS 27.0) cuando se liberen. No hay watchOS target. No limpiar caches ni temporales sin confirmación, según la política específica de este repo.

