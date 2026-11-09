# Estrategia ASO — España y localizaciones presentes

## Evidencia y público

Público observable por el producto: personas que necesitan enviar una copia de DNI/pasaporte, formulario, contrato o documento con datos concretos ocultos. La conversión debe mostrar el trabajo central —seleccionar, revisar y compartir una copia protegida— sin afirmar que la herramienta decide por el usuario o garantiza redacción infalible.

El proyecto y la ficha ASC actual tienen dos idiomas de producto: español (España) e inglés (EE. UU.). No se redactan localizaciones adicionales sin evidencia en los recursos de idioma de la app.

## Posicionamiento propuesto

- Mensaje principal ES: prepara una copia de un documento para compartir, tapa solo lo que elijas y revisa cada página/exportación en el dispositivo.
- Mensaje principal EN: prepare a document copy before sharing; cover only what you choose and review every page/export on-device.
- Prueba funcional: escáner/importación, OCR local como sugerencia, estilos de máscara, Vault local y sync CloudKit opcional. Evitar “100% secure”, “AI”, “irreversible” y garantías absolutas.
- Mantener nombre/subtítulo públicos en esta entrega para no cambiar una identidad ya existente. No incluir precios exactos en texto genérico: Apple muestra precio/duración/renovación del producto para la región en el flujo de compra.

## Competencia visible (App Store España, consulta 8-11-2026)

| Listing | Funciones descritas públicamente | Lectura para MaskID |
|---|---|---|
| [Redact: difuminar y ocultar](https://apps.apple.com/es/app/redact-difuminar-y-ocultar/id6748617836) | iPhone/iPad, redacción de fotos/PDF, detección de texto on-device, exportación aplanada | El competidor ya habla de detección local y copia exportada; MaskID debe demostrar flujo de identidad y revisión, sin claim de exclusividad. |
| [Redacto — Redact & Blur Photos](https://apps.apple.com/es/app/redacto-redact-blur-photos/id6774544804) | Varias herramientas, PDF multipágina, detección Vision en dispositivo | Hace que “redacción local” no sea diferenciador suficiente por sí sola. |
| [Redact PDF: Hide the Sensitive](https://apps.apple.com/es/app/redact-pdf-hide-the-sensitive/id6773871327) | El listado describe comprobación local del PDF exportado | El posicionamiento debe explicar el control de usuario y los límites de verificación; no apropiarse de “verified” como garantía universal. |

Estas páginas sirven para comparar claims públicos, no para afirmar cuota, valoración, rendimiento, ingresos o superioridad. No se obtuvieron volúmenes de búsqueda ni resultados de Apple Ads. No se usan nombres ajenos como keywords.

## Keywords y límites

Los campos finales están en canonical JSON y se validan con asc metadata validate y scripts/validate_release_metadata.py:

- ES (94/100 bytes): dni,pasaporte,documentos,redactar,privacidad,identidad,iban,firma,escaner,pdf,contratos,boveda
- EN-US (98/100 bytes): redaction,documents,privacy,passport,identity,bank,iban,signature,scanner,pdf,contract,mask,secure

Los campos evitan repetir los términos centrales ya usados en nombre/subtítulo y no insertan marcas de competidores. La consulta no reemplaza una prueba A/B ni datos de conversión.

## Creatividades

La ficha live 1.1.6 tiene creatividades previas que no se reutilizan. Para 1.1.7 se capturaron 16 pantallas UI fuente (4 por locale/dispositivo) y se compusieron 40 creatividades con titulares, soporte de una línea y etiqueta de fortaleza: 10 por cada combinación es-ES/en-US × iPhone 6,9″/iPad 13″. El manifiesto registra orden, copy localizado, hashes de fuente/salida y dimensiones en `11_SCREENSHOTS_AND_PREVIEWS/creatives/1.1.7/`. Home se excluye porque la barra flotante cubre parcialmente el encabezado de la biblioteca. El test confirmó MaskID Original, preferencia estacional desactivada y fixtures sintéticos. Las 40 piezas pasaron validación local y se asignaron a los grupos vigentes de App Asset Library para el borrador: cada uno de los cuatro grupos tiene 10 colocaciones `ACTIVE`, imágenes `PREPARE_FOR_SUBMISSION` y orden 1–10. IDs: `16_ASC_SCREENSHOT_UPLOAD_REPORT.md`.

Tamaño objetivo de dispositivos soportados: 6,9″ iPhone 18 Pro Max 1320×2868 y iPad Pro 13″ 2064×2752. La ficha pública ya tiene preview en inglés y no en español; no reciclar el vídeo sin comprobar que es captura limpia de la app en uso, sin marcos/composición. Apple anuncia exigencia futura de capturas iPhone Duo para apps compiladas con iOS 27.1 SDK desde abril de 2027; documentar si la fecha real de revisión cae después de ese umbral. Referencia: [especificaciones de screenshots de Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).
