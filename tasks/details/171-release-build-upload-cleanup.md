# 171-release-build-upload-cleanup

- Number: 171
- Slug: release-build-upload-cleanup

## Notes

## Resultado

- App Store Connect: `MaskID: Protect Private Data` (`com.romerodev.shield`, app ID `6790398619`).
- Marketing version: `1.0.11`.
- Build aplicado a `Shield`, `ShieldShareExtension` y `ShieldWidgetExtension`, en Debug y Release: `10112026091302`.
- Archive Release generado y conservado en `.asc/artifacts/MaskID-1.0.11-10112026091302.xcarchive`.
- Upload completado mediante export directo a App Store Connect.
- Build ID: `70a6fcab-f7f6-48b2-91e0-2d30a4bf5056`.
- Estado remoto verificado: `VALID`.

## Validación y cleanup

- `asc xcode archive` terminó con `ARCHIVE SUCCEEDED` y validación para store.
- `asc xcode export` terminó con `EXPORT SUCCEEDED` y upload al 100%.
- Se movieron a la Papelera, de forma reversible, `build-logs` (10 GB), `build-cache` (35 GB) y los temporales de validación bajo `/tmp`.
- Se preservó `.asc/artifacts/` y no se eliminó ningún artefacto de release.
- El exportador reportó avisos no bloqueantes de símbolos dSYM ausentes para `FirebaseAnalytics.framework` y `GoogleAppMeasurement.framework`; App Store Connect aceptó y procesó el build como válido.
