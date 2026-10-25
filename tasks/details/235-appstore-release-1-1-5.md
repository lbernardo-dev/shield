# 235-appstore-release-1-1-5

- Number: 235
- Slug: appstore-release-1-1-5

## Notes

- App Store Connect app `6790398619` (`com.romerodev.shield`), version `1.1.5` (`90975a3c-402b-42c9-8c4d-a273372b8be6`), status `PREPARE_FOR_SUBMISSION`, manual release.
- What's New approved and uploaded for the two current ASC locales: en-US and es-ES.
- Build `1152026102101` was set on Shield, ShieldWidgetExtension and ShieldShareExtension, uploaded, processed as `VALID` (build ID `6da93b4a-4383-47b4-91f3-32b1b56a0974`) and attached to version 1.1.5. It was not submitted for review.
- Current release artifacts retained: `.asc/artifacts/MaskID-1.1.5-1152026102101.xcarchive` and `.asc/artifacts/MaskID-1.1.5-1152026102101.ipa`.
- Simulator validation remains queued: the required iPhone 18 Pro UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0` on iOS 27.0 is booted but reserved by task 168 (Safari/repsfitness). It was not touched. iPhone Duo is available on iOS 27.1; iPad Pro 13-inch M5 is available on iOS 27.0; Apple Watch Series 12 (46 mm) is shutdown, and this project has no watchOS target. No install or runtime test was performed for this build.
- No temporary-file cleanup was run; repository policy requires user confirmation first.

## Estado ASC actualizado — 2026-10-23

- La lectura actual de App Store Connect confirma que 1.1.5 pasó a `READY_FOR_DISTRIBUTION` y la submission figura `COMPLETE`. La build `1152026102101` permanece `VALID` como última build de la versión pública.
- La nota histórica de que la versión estaba en `PREPARE_FOR_SUBMISSION` y no se había enviado corresponde al estado de la sesión anterior; no describe el estado actual.
- No existe versión ASC 1.1.6. La metadata 1.1.6 preparada en el repositorio es local y no se ha creado ni sincronizado con ASC. No se ha iniciado otra submission ni se ha enviado a revisión.

