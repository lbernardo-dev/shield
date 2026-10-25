# 230-preserve-source-pdf-fidelity

- Number: 230
- Slug: preserve-source-pdf-fidelity

## Notes

## Objetivo

El modelo ya conserva sourceFileName, pero ExportEngine prioriza imágenes rasterizadas importadas y usa una página PDF fija de 595 puntos. Conservar el PDF inmutable como geometría y fuente canónica; editar/exportar siempre aplanado de forma segura.

## Implementación

- Definir una transformación canónica normalizada que relacione PDF mediaBox/rotación, miniaturas de edición y cajas de redacción.
- Para cada página, volver a renderizar desde el PDF original a la escala de salida seleccionada, aplicar transformaciones y redacciones en el mismo espacio canónico y aplanar la salida.
- Dimensionar cada página del PDF de salida según la página de origen, sin perder orientación, tamaño o proporción.
- Mantener compatibilidad con documentos históricos que no conservaron origen, fotos e imágenes; usar el mejor asset inmutable disponible y explicitar límites.
- Verificar con ProtectionVerifier contenido residual, metadatos, páginas, rotaciones, zonas protegidas y formato; limitar memoria en documentos extensos.

## Implementación en el árbol de trabajo — 21 de octubre de 2026

- Importación y miniaturas toman `cropBox` como geometría visible; la rotación de 90/270 grados intercambia alto y ancho en el espacio de presentación.
- La exportación PDF vuelve a renderizar el original retenido a la escala elegida, aplana la página con redacciones y marca de agua, y conserva el tamaño visible de cada página. Si existen transformaciones de revisión todavía no representables directamente en PDFKit, usa la imagen revisada como fuente.
- El verificador compara tamaño y orientación de las páginas, además de los controles existentes de texto, metadatos, anotaciones y OCR residual.
- Se añadieron fixtures de geometría recortada/rotada y rechazo de salida con dimensiones distintas. La validación de compilación y los tests queda para el gate final.
- La revisión de máscaras también se invalida cuando se confirma un nuevo crop, rotación, perspectiva o cuadrilátero. La tarea 229 mantiene una fingerprint de la geometría aprobada para impedir exportar hasta que el usuario vuelva a revisar cada página.
- El canvas del editor calcula su proporción visible después del crop y la rotación global, de modo que las cajas normalizadas se dibujan sobre toda la imagen transformada y no sobre una ventana con aspecto antiguo.

## Aceptación

- PDF de origen no se modifica y la exportación mantiene número/tamaño/orientación de páginas.
- Texto pequeño y líneas finas conservan legibilidad a escala de salida; las redacciones cubren sus regiones tras rotación/crop.
- La salida sigue siendo rasterizada y verificada; no deja texto original extraíble bajo la máscara.
- Documentos antiguos sin sourceFileName siguen exportando y se etiquetan con limitación conocida.
- Cobertura determinista para multipágina, rotación, crop y límites de memoria; ejecución de simuladores solo en el gate final del programa.

## Gate final — 2026-10-21

- La build y `ShieldTests` pasaron en iPhone 18 Pro (iOS 27.0), iPhone Duo (iOS 27.1) e iPad Pro 13-inch M5 (iPadOS 27.0): 147 pasaron por destino, 0 fallos y una integración RevenueCat omitida por configuración explícita.
- Los tests de geometría PDF, tamaños/rotación de página y verificación de salida se ejecutaron en la suite unitaria completa. Las capturas finales del editor también se renovaron tras la build validada.

