# 162-release-build-upload

- Number: 162
- Slug: release-build-upload

## Notes

## Resultado — 12 de septiembre de 2026

- Siguiente build remoto seguro: `10102026091202` para la versión `1.0.10`.
- Actualizado `CURRENT_PROJECT_VERSION=10102026091202` en Debug y Release para `Shield`, `ShieldShareExtension` y `ShieldWidgetExtension`.
- Archive Release iOS validado: `.asc/artifacts/MaskID-1.0.10-10102026091202.xcarchive`.
- Subida directa a App Store Connect completada. El helper generó temporalmente el plist de exportación en `/tmp` porque el volumen externo no admite el enlace temporal que usa el helper.
- Build procesado como `VALID`, elegible para App Store y sin cifrado no exento.
- Build ID: `7b41898f-e8c5-4023-8d64-2994366e2de1`.
- No se creó una IPA local: se usó el destino de upload directo de Xcode.
- Xcode reportó sólo warnings de aislamiento de actores ya existentes y ausencia de dSYM de `FirebaseAnalytics.framework`/`GoogleAppMeasurement.framework`; no bloquearon el procesamiento.

## Validation

- `asc builds next-build-number --app 6790398619 --version 1.0.10 --platform IOS`: `10102026091202`.
- Metadatos del archive: app `com.romerodev.shield` y build `10102026091202` también en ambas extensiones.
- `asc builds info --build-id 7b41898f-e8c5-4023-8d64-2994366e2de1`: `VALID`.
- `git diff --check`: passed.
- `scripts/cleanup_temporaries.sh --dry-run`: revisado; no propone tocar `.asc/artifacts/`. La aplicación aprobada para `build-logs` y `build-cache` fue rechazada porque había procesos de desarrollo activos de otros proyectos; no se movió ningún candidato.
