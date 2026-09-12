# 167-adversarial-secure-export-fixtures

- Number: 167
- Slug: adversarial-secure-export-fixtures

## Notes

## Implementación

- `ExportVerifier` distingue propiedades técnicas de PNG (por ejemplo,
  interlace) de metadatos humanos; no marca un PNG transparente limpio sólo por
  abrirse con propiedades técnicas de ImageIO.
- `ExportVerifierTests` cubre PDF rasterizado multipágina con página rotada,
  orientaciones mixtas, baja calidad, texto multilingüe y 50 páginas; PDF con
  text layer, anotaciones y metadatos; PNG transparente; JPEG con GPS/EXIF/TIFF;
  y los artefactos de producción de Secure Export.
- Los artefactos PDF/JPEG producidos por `ExportEngine` se inspeccionan también
  por bytes: el texto ficticio redactado no aparece en el archivo, el PDF no
  conserva texto seleccionable ni anotaciones y ambos informes pasan la
  verificación posterior.

## Verificación

- Suite dirigida `ExportVerifierTests`: 11/11 tests.
- `ShieldTests` completo: 88 tests en 18 suites.
- Esquema completo: 33 UI tests ejecutadas; 4 fallos preexistentes y fuera de
  este alcance en `ShieldUITests/ShieldLaunchTests.swift` (navegación de
  Settings, placeholder de feedback, footer del paywall y navegación de tabs).

## Límites documentados

Estos fixtures prueban los formatos y casos adversariales incluidos, no todas
las codificaciones, contenedores o técnicas forenses. La UI debe mantener la
revisión humana y no presentar esta evidencia como garantía universal de que
ningún dato puede recuperarse. El dry-run de limpieza identificó artefactos de
build compartidos; no se eliminaron.
