# 277-preparar-build-y-testflight-ia

- Number: 277
- Slug: preparar-build-y-testflight-ia

## Notes

- 2026-11-21: Archive Release `.asc/artifacts/MaskID-1.2.0-10112026091404-final.xcarchive` e IPA `.asc/artifacts/MaskID-1.2.0-10112026091404-final.ipa` completados. Bundle `com.romerodev.shield`, iOS 18+, firma Apple Distribution válida; perfil app-store `436DJHXKAZ` con PCC y `get-task-allow=false`; verificación `codesign --verify --deep --strict` correcta para app/extensiones.
- ASC: build `1.2.0 (10112026091404)`, ID `37f4b70e-2273-4805-ac60-d52daad3971c`, estado `VALID`, `usesNonExemptEncryption=false`. What to Test configurado en `en-US` y `es-ES`; vínculo explícito al grupo interno existente `Shield Internal` (`ba8e0c39-76a7-4f5a-8cbe-32a1b20bfe78`). Grupo conserva un tester; no se enviaron invitaciones ni se sometió el build a revisión beta/App Store.
- Se conserva el perfil de firma y ExportOptions en `.asc/artifacts/signing/`. Queda como validación manual externa una instalación/prueba PCC con documento sintético en dispositivo elegible; el HTML legal actualizado aún debe desplegarse antes de una futura publicación pública.

