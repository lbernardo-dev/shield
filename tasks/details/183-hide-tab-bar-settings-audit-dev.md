# 183-hide-tab-bar-settings-audit-dev

- Number: 183
- Slug: hide-tab-bar-settings-audit-dev

## Notes

- En `Shield/App/ContentView.swift`, se actualizó `compactNavigation` para que `ShieldTabBar` solo se renderice cuando `appState.activeTab != .settings`, con transición combinada `.move(edge: .bottom).combined(with: .opacity)` y animación controlada respetando `reduceMotion`.
- De este modo, en la vista de configuración (`SettingsView`), la barra inferior del menú (footer tab bar) queda completamente oculta y no interfiere con el contenido ni con el botón de café/derechos reservados. Al pulsar el botón de cerrar ("X"), se regresa a `.library` y la barra inferior vuelve a mostrarse fluidamente.
- Se auditó todo el proyecto confirmando que las herramientas y opciones de desarrollo (`SettingsRoute.developer`, `DeveloperSettingsView`, sección de Desarrollador en `SettingsView` y overrides en `PremiumManager`) están estrictamente encapsuladas bajo `#if DEBUG && targetEnvironment(simulator)`, garantizando que el compilador de Swift las excluya al 100% de cualquier compilación para dispositivos físicos reales (App Store, TestFlight y dispositivos en general).
- Verificación de compilación: `** BUILD SUCCEEDED **` mediante `scripts/xcbuild.sh`.
- Instalación y ejecución verificada en el simulador iPhone 18 Pro (PID 91429).
