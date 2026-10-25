# 243-refresh-app-store-creatives-1-1-6

- Number: 243
- Slug: refresh-app-store-creatives-1-1-6

## Alcance y captura

- Entrega limitada a iPhone 18 Pro; sin vídeo para esta versión, según la última instrucción del usuario.
- Simulador dedicado: `MaskID Creative Copy - iPhone 18 Pro`, UDID `682221B4-1019-4718-9759-C515147D3912`, runtime iOS 27.0. La captura y el lanzamiento se hicieron directamente por UDID; no se usó Device Hub ni se modificaron los simuladores originales, iPad o Duo.
- Se instaló y ejecutó MaskID 1.1.6, build `1162026102502`. El tema Base se comprobó en la copia mediante la vista previa visual local DEBUG. La cuenta siguió en Free; no se simuló Pro, una compra, PIN ni cuenta.
- Las escenas usan documentos sintéticos etiquetados y pantallas actuales de la app. Para que las fixtures de ASO renderizasen las plantillas vectoriales existentes en vez de páginas en blanco, se corrigió `Shield/Views/Documents/DocumentRenderers.swift` dentro de `ASOScreenshotMode` y `#if DEBUG`. La renderización release no cambia.
- Se entregaron exactamente 10 PNG por locale en `.asc/screenshots/aso/final/{en-US,es-ES}/iphone-63/`. Cada archivo mide 1206 × 2622 px y se subió al tipo `APP_IPHONE_61`, correspondiente al grupo de pantalla de iPhone 18 Pro. Los 20 recursos aparecen `COMPLETE` en App Store Connect.
- Contact sheets revisadas: `.asc/screenshots/aso/review/contact-en-US.png` y `.asc/screenshots/aso/review/contact-es-ES.png`.
- No se generó ni se subió un vídeo nuevo para esta entrega. Tras la autorización posterior del usuario para retirar la revisión, se eliminó el preview antiguo de `en-US`; `es-ES` no tiene previews. Ambos locales quedan sin vídeos.

## Estado App Store Connect

- App ID: `6790398619`; versión iOS `1.1.6`, ID `cdd9db00-ee9f-446d-ad67-d9e4efc9ba61`.
- Build `1162026102502`, ID `1c5cf9b8-49c8-427b-ab28-e6b4218422d5`, estado `VALID` y adjunto a 1.1.6.
- La localización What's New aprobada previamente está configurada en `en-US` y `es-ES`.
- La validación reportó 0 errores, 0 warnings y 0 bloqueos. En la interfaz web de App Store Connect se confirmó que App Privacy está publicada y que el desarrollador está identificado como comerciante en el Reglamento de Servicios Digitales.
- La primera submission (`11f3c7fc-edd1-42db-9f94-5e4e0618aabd`) se canceló el 2026-10-25 para retirar el preview heredado. Se creó una submission nueva con el mismo build y las capturas actuales: `91422bbd-05c7-4306-8911-6ac525e55fcc`, estado verificado `WAITING_FOR_REVIEW`.
- La versión conserva publicación manual después de aprobación.

## Orden de capturas

1. `01-protect-before-sharing.png`
2. `02-scan-and-import.png`
3. `03-review-in-batches.png`
4. `04-compare-mask-styles.png`
5. `05-encrypted-local-vault.png`
6. `06-protect-your-id.png`
7. `07-share-travel-documents.png`
8. `08-review-on-device-suggestions.png`
9. `09-label-a-protected-copy.png`
10. `10-check-before-sharing.png`

