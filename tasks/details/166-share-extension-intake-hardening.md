# 166-share-extension-intake-hardening

- Number: 166
- Slug: share-extension-intake-hardening

## Notes

- `SharedImportStore` valida en una única frontera que el handoff solo admite
  familias PDF o imagen y normaliza PDF a `public.pdf` antes de cifrarlo.
- `ShareViewController` intenta primero `loadFileRepresentation` y usa
  `loadDataRepresentation` si el proveedor no mantiene disponible el archivo
  temporal. Ambos caminos aplican el límite de 50 MB y no registran PII.
- El handoff conserva el cifrado AES-GCM en App Group y
  `.completeFileProtection`; `ShieldApp` ya no ignora silenciosamente errores
  de descifrado o acceso y los entrega como mensaje genérico en CaptureView.
- El flujo distingue `share_sheet` de importación normal y registra solo
  eventos agregados de inicio, finalización del handoff y fallo.
- Si el usuario ha alcanzado el límite de documentos, un temporal recibido por
  Share Sheet se elimina antes de mostrar el paywall.

## Pruebas y límites

- `SharedImportStoreTests` cubre familias de tipos permitidas y rechazo de audio
  antes de tocar el inbox, además del round-trip y autenticación anti-tamper.
- El `Info.plist` mantiene explícitamente un máximo de un elemento: la UI no
  afirma batch desde Share Sheet. La validación manual pendiente para dispositivo
  debe probar Fotos/Archivos, proveedor que solo entrega bytes, cancelación,
  archivo >50 MB, PDF e imagen válidos y recuperación tras fallo.
