# 281-mejoras-ui-header-tabbar-intake-tintes

- Number: 281
- Slug: mejoras-ui-header-tabbar-intake-tintes
- Status: Completed (Tests 100% Passed, Device Binary Built)

## Resumen de Ejecución

1. **Botón Settings en Header junto al Avatar**:
   - Movido de la barra inferior (footer) a la barra superior derecha contiguo al avatar (`HomeProfileToolbarButton`).
   - Implementado en `HomeView`, `StyleGalleryView`, `VaultView` y la pantalla de bloqueo de la bóveda.
   - Preserva `accessibilityIdentifier("tab.3")` para compatibilidad total con tests de interfaz existentes.
   - Presenta el `SettingsView` de manera limpia mediante sheet con `NavigationStack`.

2. **Botón Vault en Footer con estilo Prominent y Tinte Cyber-Violet**:
   - En `ContentView.swift`, configurado con `Tab(value: AppTab.vault, role: .prominent)` y comprobación de versión de plataforma.
   - En `TabBar.swift`, extraído con `prominentVaultTabItem` con botón circular elevado (50x50), gradiente Cyber-Violet (`#6366F1` a `#4F46E5`) y resplandor luminoso que le otorga jerarquía superior frente a Docs y Styles.

3. **Accesos directos de entrada inmediata (Scan, Photos, Files)**:
   - Añadido `CaptureDirectLaunchSource` (`.camera`, `.photos`, `.files`) y `pendingCaptureSource` en `AppState`.
   - Modificado `CaptureView.swift` para que al presentarse con una fuente pendiente lance inmediatamente el picker nativo correspondiente (VNDocumentCameraViewController/cámara, PHPicker/PhotosPicker, o UIDocumentPickerViewController/fileImporter).
   - En caso de cancelación por parte del usuario, se descarta `showCapture = false` retornando instantáneamente a la Home sin pasos intermedios.

4. **Paleta de Tintes Cristalinos Glassmórficos en toda la App**:
   - Asignación rigurosa y unificada de tintes identificativos:
     - **Docs / Library**: Azul Azure (`#0EA5E9`).
     - **Vault / Identity**: Cyber Violet (`#6366F1`).
     - **Tools**: Teal (`#14B8A6`).
     - **Alquiler Seguro (Rental)**: Indigo (`#5E5CE6`).
     - **Nómina Laboral (Job)**: Amber (`#FF9F0A`).
     - **Extracto Bancario (Banking)**: Mint / Emerald (`#34C759`).
     - **Viajes y Vuelos (Travel)**: Sky Blue (`#64D2FF`).
     - **Lote Masivo (Batch)**: Cyan (`#20C7D9`).
     - **Atajos Directos**: Scan (`#10B981`), Fotos (`#0EA5E9`), Archivos (`#F59E0B`).
   - Aplicado en `HomeHeroCardView`, `HomeLibraryStatisticsView`, `HomeRecurringActionsSection`, `HomeQuickAccessSection`, `HomeVaultCard` y `ModeCard`.
   - Cada card incorpora fondo `ZStack` de tarjeta con tinte translúcido (`0.14 - 0.02`) y borde con degradado cristalino (`0.38 - 0.10`).

5. **Validación y Compilación**:
   - Suite completa `ShieldTests` en simulador: 100% Passed.
   - Build de `MaskID.app` para iPhone 15 Pro Max (`Debug-iphoneos`): 100% Exitoso (código 0).
