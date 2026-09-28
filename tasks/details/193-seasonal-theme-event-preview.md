# 193-seasonal-theme-event-preview

- Number: 193
- Slug: seasonal-theme-event-preview

## Notes

### Implementación

- Se completó la previsualización de evento en Ajustes para `halloween-2026`:
  - banner 16:9 existente;
  - artwork vertical 9:16 incorporado al catálogo de assets;
  - icono de app y snapshot compacto de Home tematizada;
  - descripción del evento y ventana de fechas localizada;
  - zona editorial IANA (`Europe/Madrid`) visible, manteniendo la resolución real en calendario local del dispositivo.
- La galería y la hoja de preview ahora distinguen `base`, `upcoming`, `active` y `archived`.
- Un tema futuro se puede abrir para inspección, pero no puede activarse antes de su ventana; el botón queda deshabilitado con explicación accesible.
- Las cuentas Free conservan el modo automático durante el evento y abren el paywall al intentar desbloquear un tema activo; la selección manual sigue reservada a Pro.
- Se añadieron textos EN/ES para el estado programado, fechas, zona horaria, artwork y comportamiento automático.
- Se añadieron pruebas deterministas para impedir activación anticipada, validar metadatos de zona horaria/artwork y conservar la cobertura DST.

### Verificación

- `git diff --check`: correcto.
- `xcodebuild ... build` mediante `scripts/xcbuild.sh`: **BUILD SUCCEEDED** con SDK/runtime iOS Simulator 27.0.
- `xcodebuild ... build-for-testing -only-testing:ShieldTests/EnhancementFeaturesTests`: **TEST BUILD SUCCEEDED**.
- La ejecución dirigida sobre el UDID de iPhone 18 Pro (`1454EA8D-A019-4B07-B57C-1433E0F21BE0`) no pudo iniciar casos: `simctl` y Xcode reportaron CoreSimulatorService no disponible (`Connection refused` / `destinationSet`). No se reinició, borró ni modificó el simulador.
- La validación visual/instalación queda pendiente hasta que CoreSimulatorService vuelva a estar disponible.

### Reintento de validación 2026-09-27

- El volumen externo volvió a montarse, pero CoreSimulatorService siguió rechazando conexiones.
- El iPhone 18 Pro requerido continuó ocupado por otras sesiones (`SchoolSnap`, después `SnapInbox`/`VitalsBud`); no se interrumpieron.
