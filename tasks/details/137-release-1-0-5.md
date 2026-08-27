# 137-release-1-0-5

- Number: 137
- Slug: release-1-0-5

## Notes

- Creado en App Store Connect el registro iOS 1.0.5: `beac1d9c-c5dd-4cc7-91f4-ef2ee48d7db7`, estado `PREPARE_FOR_SUBMISSION`.
- Actualizados `Shield`, `ShieldShareExtension` y `ShieldWidgetExtension` a marketing version `1.0.5` y build `105202608261` en Debug/Release.
- Validada la metadata local de `metadata/version/1.0.5` sin errores ni avisos.
- Archive Release universal generado en `.asc/artifacts/MaskID-1.0.5-105202608261.xcarchive`.
- Creado el Bundle ID del widget y perfiles App Store para los tres targets. La exportación está bloqueada porque el perfil del widget aún no tiene asignado `group.com.romerodev.shield`; esa asignación requiere reautenticar una sesión web del Apple Developer Portal.
- Reautenticada la sesión web y verificada la asignación del App Group `BSP24PFN9N`; regenerado e instalado el perfil del widget `7XPA32FG3P`.
- IPA exportado y auditado en `.asc/artifacts/MaskID-1.0.5-105202608261.ipa`. Subido y procesado como `VALID`; build ID `5eda3c23-53a9-4b2f-af1d-987f3905112b`.
- Asociado el build a la versión 1.0.5 y aplicada la metadata en App Store Connect. Validación final: 0 errores, 0 avisos, 0 bloqueos.
- La versión permanece en `PREPARE_FOR_SUBMISSION`; no se ha creado ni enviado ninguna submission/revisión.
