# 214-app-store-creative-videos

- Number: 214
- Slug: app-store-creative-videos

## Notes

## Entregable

Se crearon cuatro videos originales, silenciosos y bilingües para la ficha de MaskID. La pieza cuenta el flujo de protección de documentos: abrir la app, detectar datos con OCR, aplicar redacciones manuales y revisar la copia antes de compartirla. Se usaron capturas reales de la app con documentos sintéticos y una dirección visual cinematográfica en azul tinta y cian.

Cada video dura 15 segundos, está codificado en H.264 a 30 fps y cumple las dimensiones publicadas por Apple:

- Cabecera de página: 3840 × 1646 px.
- Resultados de búsqueda: 2880 × 1920 px.

Fuentes editables y renders:

- `Marketing/AppStore-Connect/CreativeAssets/render.py`
- `Marketing/AppStore-Connect/CreativeAssets/DESIGN.md`
- `Marketing/AppStore-Connect/CreativeAssets/README.md`
- `Marketing/AppStore-Connect/CreativeAssets/en-US/product-page-header.mp4`
- `Marketing/AppStore-Connect/CreativeAssets/en-US/search-results.mp4`
- `Marketing/AppStore-Connect/CreativeAssets/es-ES/product-page-header.mp4`
- `Marketing/AppStore-Connect/CreativeAssets/es-ES/search-results.mp4`

## App Store Connect

La CLI `asc` 5.14.0 pudo cargar y asignar los videos en la versión 1.1.3, localizaciones `en-US` y `es-ES`. Verificación de solo lectura: los cuatro placements están `ACTIVE`; los cuatro videos están en `CREATIVE_ASSETS`, con estado `PREPARE_FOR_SUBMISSION`, sin errores y con la extracción de fotograma en `COMPLETE`.

| Localización | Espacio | Video ID | Placement ID |
|---|---|---|---|
| en-US | Cabecera de página | `6a800019-4bd4-829b-8113-9e5f8918f782` | `a2000019-4bd4-829b-8f2b-525a743124e5` |
| en-US | Resultados de búsqueda | `7f800019-4bd4-829b-812e-b994799598ae` | `b4c00019-4bd4-829b-8f03-791abec0c16b` |
| es-ES | Cabecera de página | `34c00019-4bd4-829b-810e-5abaae1541db` | `02c00019-4bd4-829b-8f10-f293d41236f9` |
| es-ES | Resultados de búsqueda | `50800019-4bd4-829b-810e-ab3dd8138e1e` | `d4400019-4bd4-829b-8f09-4d7c514627f0` |

Las cargas tardaron más que `ASC_UPLOAD_TIMEOUT` en devolver el recibo del CLI, aunque App Store Connect sí las aceptó. Se consultó la biblioteca antes de repetir la última carga y se reutilizó su ID, evitando duplicados.

No se creó ni envió ninguna revisión. La versión 1.1.3 queda en borrador conforme a la retención de App Review existente; los videos no estarán publicados hasta que se apruebe y publique la versión.

Las cabeceras se reencuadraron en la tarea 215 y volvieron a ajustarse en la tarea 216 a partir de la vista previa real de iPhone en App Store Connect. Los placements de búsqueda de esta tarea permanecen vigentes.
