# 215-app-store-header-safe-area

- Number: 215
- Slug: app-store-header-safe-area

## Notes

## Corrección

El archivo de cabecera respetaba la especificación de 21:9, pero su composición extendía el texto y el teléfono demasiado cerca de los laterales. Para tolerar recortes en la vista previa, se mantuvo el lienzo de Apple de 3840 × 1646 y se centraron todos los elementos importantes dentro de un área segura 16:9. Se conservaron los fondos panorámicos discretos a ambos lados.

La zona segura se comprobó visualmente con un recorte central 16:9 de ambos idiomas. Los videos finales siguen siendo MP4/H.264, silenciosos, de 15 s y 30 fps.

## App Store Connect

Se reemplazaron las cabeceras existentes en la versión 1.1.3 con `asc localizations placements swap`. Confirmación de solo lectura: ambos placements están `ACTIVE`, los fotogramas procesados están `COMPLETE` y miden 3840 × 1646. Los placements de búsqueda permanecen activos sin cambios.

| Localización | Video ID nuevo | Placement ID nuevo |
|---|---|---|
| en-US | `2b000019-4bd4-829b-8127-f124452722f7` | `5c400019-4bd4-829b-8f2a-3fbaac192514` |
| es-ES | `81800019-4bd4-829b-8137-f597dd63c9b0` | `34000019-4bd4-829b-8f1c-89105d318612` |

La carga agotó el tiempo de espera del comando CLI, pero devolvió el ID de recurso y App Store Connect completó su fotograma de vista previa. No se duplicaron cargas ni se envió ninguna revisión. La retención de App Review sobre 1.1.3 sigue intacta.
