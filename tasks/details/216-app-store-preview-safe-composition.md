# 216-app-store-preview-safe-composition

- Number: 216
- Slug: app-store-preview-safe-composition

## Corrección visual

La cabecera 21:9 cumplía las dimensiones de Apple, pero en la vista previa real de producto para iPhone en App Store Connect el contenido se veía demasiado pequeño. Se ajustó el texto y se amplió el teléfono hasta el límite vertical del lienzo, manteniendo texto y dispositivo dentro del recorte central visible. La composición evita las zonas de los controles de carrusel y compartir.

El titular del segundo corte es «Review each suggestion» en inglés y «Revisa cada sugerencia» en español. Se mantuvo el flujo de la app: inicio, sugerencias OCR, redacción manual y revisión de la exportación.

## Vista previa de App Store Connect

Se abrió la ficha de la versión 1.1.3 en App Store Connect y se comprobó el encabezado con el dispositivo **iPhone** para `en-US` y `es-ES`. Los titulares y los teléfonos quedan dentro del marco; no se recortan y mantienen margen respecto a las flechas y al botón de compartir.

## Assets actuales

| Localización | Asset ID | Placement ID | Estado |
| --- | --- | --- | --- |
| `en-US` | `61000019-4bd4-829b-810c-0f6e22552905` | `5ac00019-4bd4-829b-8f26-a5659938b7f0` | `ACTIVE` |
| `es-ES` | `a7000019-4bd4-829b-813b-e39637c0b949` | `75000019-4bd4-829b-8f05-11c94710cafa` | `ACTIVE` |

Ambos son videos H.264 silenciosos de 15 segundos a 30 fps y 3840 × 1646 px. App Store Connect generó los fotogramas de vista previa y terminó su procesamiento sin errores. Los cuatro datos se verificaron con `asc`.

Los videos de resultados de búsqueda no se modificaron; los placements `en-US` (`b4c00019-4bd4-829b-8f03-791abec0c16b`) y `es-ES` (`d4400019-4bd4-829b-8f09-4d7c514627f0`) siguen `ACTIVE`.

La versión 1.1.3 sigue `PREPARE_FOR_SUBMISSION`. No se añadió ni envió una revisión.

El CLI devolvió recibos parciales porque la espera local venció mientras Apple procesaba los videos. Se consultaron los dos assets después; ambos terminaron con fotograma `COMPLETE` y se asignaron correctamente.
