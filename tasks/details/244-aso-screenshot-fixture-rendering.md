# 244-aso-screenshot-fixture-rendering

- Number: 244
- Slug: aso-screenshot-fixture-rendering

## Resultado

- Corregido `Shield/Views/Documents/DocumentRenderers.swift`: cuando se ejecuta el modo de capturas ASO DEBUG con un documento sintético `aso-*`, la vista utiliza la plantilla vectorial existente en lugar de dejar la página en blanco.
- El cambio está limitado por `#if DEBUG` y `ASOScreenshotMode`; no altera el renderer de producción.
- Verificado en la copia dedicada iPhone 18 Pro, iOS 27.0, con el build 1.1.6 (`1162026102502`). Se capturaron y revisaron las 10 escenas por locale; ambos sets finales contienen exactamente 10 capturas 1206 × 2622 px y la validación de carga registró 10/10 completas para cada locale.
- Evidencia visual en `.asc/screenshots/aso/review/contact-en-US.png` y `.asc/screenshots/aso/review/contact-es-ES.png`.
