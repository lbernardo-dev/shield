# 233-selectable-pdf-output-safety-evaluation

- Number: 233
- Slug: selectable-pdf-output-safety-evaluation

## Notes

## Pregunta de viabilidad

¿Puede ofrecerse texto seleccionable conservando una garantía verificable de que el texto sensible, sus grafemas, glifos, objetos, anotaciones, capas y metadatos ya no aparecen en la salida?

## Evaluación

- Revisar capacidades actuales de PDFKit/Vision y límites del formato; no crear un overlay visual que deje texto original debajo.
- Preparar fixtures sintéticos con ligaduras, texto vectorial, rotaciones, anotaciones, imágenes rasterizadas y OCR residual.
- Comparar una estrategia de reconstrucción segura (recrear solo bloques permitidos) con la salida rasterizada actual en fidelidad, tamaño y rendimiento.
- Definir un verificador adversarial. La ausencia de texto por búsqueda simple no prueba ausencia de glifos/objetos sensibles.
- Producir decisión go/no-go. Si no se puede verificar con el mismo umbral, conservar raster como única salida segura.

## Aceptación

- Informe documenta capacidades, riesgos, fixtures, métricas y recomendación.
- Ninguna ruta experimental llega a usuarios ni al paywall sin un verificador que pase fixtures adversariales.
- El resultado no cambia la salida rasterizada por defecto.

## Gate final — 2026-10-21

- La build y `ShieldTests` pasaron en iPhone 18 Pro, iPhone Duo e iPad Pro 13-inch M5: 147 aprobados, 0 fallos y una integración RevenueCat omitida por configuración explícita en cada destino.
- La decisión no-go documentada en `Docs/SELECTABLE_PDF_OUTPUT_SAFETY.md` mantiene PDF plano como única salida protegida. La comparación sintética de fidelidad, tamaño y rendimiento se completó el 2026-10-24; no demuestra la seguridad de la reconstrucción basada en OCR de producción.

### Benchmark sintético — 2026-10-24

- Ejecutado `scripts/benchmark_selectable_pdf.swift` con 12 páginas sintéticas de tamaños mezclados, texto CoreText seleccionable multilingüe, frases con ligaduras, tabla vectorial, sello, firma y marca tipo código de barras. Cada salida elimina una línea de cuenta sensible; no se usaron documentos reales.
- Flatten raster 2×: 776,182 bytes, 0.0824 s de generación, error RGB absoluto medio 10.04/255 frente al origen renderizado y enmascarado, sin texto seleccionable y sin la cadena sintética sensible.
- Prototipo seleccionable reconstruido desde el texto y geometría exactos del fixture: 32,398 bytes, 0.00739 s, error 1.09/255, conserva búsqueda de texto seguro y no incluye la cadena sensible. Es una cota superior deliberadamente idealizada: comparte el código/datos de composición del fixture y no ejecuta OCR ni procesa PDFs arbitrarios.
- Se conserva el no-go para producto: el benchmark no valida reconocimiento, ligaduras/offsets de glifos, fuentes o gráficos desconocidos, capas, formularios, anotaciones, adjuntos, historial incremental ni OCR independiente. El gate de producción y sus fixtures adversariales siguen sin evidencia suficiente.
- Reproducibilidad y límites en `Docs/SELECTABLE_PDF_OUTPUT_SAFETY.md`; los artefactos sintéticos quedan bajo `build/selectable-pdf-benchmark/`.

