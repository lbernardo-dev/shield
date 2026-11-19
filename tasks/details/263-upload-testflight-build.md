# 263-upload-testflight-build

- Number: 263
- Slug: upload-testflight-build

## Notes

- Release App Store Connect: versión `1.2.0`, build `10112026091402`.
- Archive Release corregido y exportado; los tres targets (app, Share Extension y Widget Extension) usan la misma versión/build.
- IPA cargado en ASC; build ID `d37c8a8b-1f96-477d-92fa-47ab312caec0`, `processingState=VALID`, `expired=false`, mínimo iOS 18.0.
- Build asociado al grupo interno `Shield Internal` (ID `ba8e0c39-76a7-4f5a-8cbe-32a1b20bfe78`). El grupo ya contiene un tester interno en estado `INSTALLED`; no fue necesario invitar ni notificar a nadie.
- Notas “What to Test” verificadas en `es-ES` y `en-US`, con comprobaciones de los 15 días, Lifetime, restauración, tema/icono base y ausencia de canje de códigos/audio estacional.
- No se envió la versión a revisión de App Store. Artefactos conservados en `.asc/artifacts/`:
  - `MaskID-1.2.0-10112026091402-final.xcarchive`
  - `MaskID-1.2.0-10112026091402.ipa`
- La validación final incluyó `git diff --check` (correcto). No se ejecutaron suites automatizadas en esta tarea.
- ASC conserva un registro `AWAITING_UPLOAD` creado durante el dry-run, además del registro de carga real `COMPLETE`; el build distribuible es el que está procesado como `VALID`.
