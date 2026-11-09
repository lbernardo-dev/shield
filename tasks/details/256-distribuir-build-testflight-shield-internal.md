# 256-distribuir-build-testflight-shield-internal

- Number: 256
- Slug: distribuir-build-testflight-shield-internal

## Notes

- El usuario respondió afirmativamente a la consulta sobre asignar el build 1172026110801 al grupo `Shield Internal`, aceptando que podía generarse una notificación. Dry-run de `asc builds add-groups` verificó build VALID/no expirado y grupo correcto; luego la asignación devolvió `added`.
- Read-back: `asc testflight groups list --build-id` muestra 1 grupo, `Shield Internal`, `internal`, relación explícita. `asc builds info` muestra `betaGroups.total=1`; `buildBetaDetails.internalBuildState=IN_BETA_TESTING`, `autoNotifyEnabled=true`; `betaAppReviewSubmission=null`. ASC no expone confirmación de entrega de notificación.
- `asc validate testflight`: 0 errores, 0 warnings, 0 bloqueos. No se enviaron a Beta App Review/App Review, no se publicaron builds y no se añadieron/invitaron testers.
- Informes actualizados en 00, 01, 02, 07, 13, 15, 17 y `RELEASE_MANIFEST.json`. Siguientes gates: transacciones Sandbox reales y verificación legal/privacidad/accesibilidad/CloudKit.

