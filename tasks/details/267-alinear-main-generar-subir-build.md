# 267-alinear-main-generar-subir-build

- Number: 267
- Slug: alinear-main-generar-subir-build

## Notes

- Se integraron y publicaron los cambios locales de MaskID en `main`, incluidos los detalles de tareas 259–266, con commit `73088baa05a4e4775edcebb867dcc0043e5a4def`. `main` y `origin/main` coincidían antes de compilar.
- ASC app `6790398619` confirmó como último build previo `10112026091402`; el siguiente número remoto seguro era `10112026091403`. La versión quedó en `1.2.0`.
- Xcode 27.2 archivó correctamente Release desde el commit publicado. App, Share Extension y Widget Extension llevan `1.2.0 (10112026091403)`; el IPA se verificó con firma de distribución válida del equipo `L2B56644F5` y mínimo iOS 18.0.
- Artefactos conservados: `.asc/artifacts/MaskID-1.2.0-10112026091403-final.xcarchive` y `.asc/artifacts/MaskID-1.2.0-10112026091403-final.ipa`. SHA-256 del IPA: `d9d1e581e87ab0cf4ded4f896807da118c45b1c5f269f7badb3b7880ed241780`.
- IPA cargado con ASC profile `RomeroDev`. Build ID `d2df2fa9-57ef-40c9-a979-05b483c99550`, versión TestFlight `1.2.0`, `processingState=VALID`, `expired=false`, estado interno `READY_FOR_BETA_TESTING`; ASC confirma también el ID de pre-release `eb0e6731-f7ec-47db-8e70-8e61dab217c2`.
- El build quedó cargado sin asignarlo a grupos, sin añadir/invitar testers, sin enviar a Beta App Review/App Review y sin publicar la versión. No se ejecutaron suites de tests; el archive Release y `git diff --check` sí pasaron.
- Se conservaron los artefactos y cachés; no se ejecutó limpieza.
