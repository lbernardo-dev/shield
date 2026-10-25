# Sugerencias locales de rostros: alcance y evaluación sintética

**Fecha:** 24 de octubre de 2026

## Comportamiento implementado

- Vision procesa en el dispositivo cualquier documento que tenga páginas de imagen, aunque OCR lo clasifique como DNI, pasaporte o licencia. Los documentos vectoriales sin imagen se omiten. No se envían imágenes, cajas ni texto OCR a servicios externos.
- Si el documento tiene una página rasterizada, el editor renderiza esa imagen real aunque el OCR la haya clasificado como DNI, pasaporte o permiso; la plantilla vectorial se reserva para documentos sin imagen. El tamaño del lienzo también sigue el aspecto de la página raster, de modo que las cajas superpuestas y las máscaras usan las mismas coordenadas que la exportación.
- Las máscaras guardadas en versiones anteriores para tipos de documento rasterizados quedan pendientes de revisión, porque entonces la previsualización del editor usaba una plantilla vectorial mientras la exportación usaba la imagen escaneada. Las nuevas importaciones registran el espacio de coordenadas raster y no reciben esa revisión de migración.
- Se guardan regiones normalizadas y una confianza de Vision dentro del registro cifrado del documento.
- La detección produce sugerencias. El usuario acepta cada máscara, puede ajustar la redacción en el editor o descartar la sugerencia.
- Las sugerencias se calculan sobre las páginas renderizadas que usa el editor, incluidas las rotaciones y recortes ya aplicados; no se propagan entre páginas.
- La orientación EXIF/UIImage se pasa explícitamente a Vision. La sugerencia almacena también el giro de cara de Vision. Si la petición Swift moderna falla, se usa `VNDetectFaceRectanglesRequest` con revisión 2 como compatibilidad; el giro de esta API se convierte de radianes a grados. El bloque opaco aceptado crece 21 % por lado a lo ancho y 37 % por lado a lo alto en los ejes de la cara, se vuelve a alinear según el giro y se recorta a la página.
- La previsualización punteada y la máscara que se acepta usan la misma caja propuesta, para que el área a cubrir sea visible antes de confirmar.
- La revisión 5 invalida cajas anteriores para recalcularlas con giro y expansión actuales, habilita imágenes clasificadas como tipos concretos de documento y reintenta documentos cuyo análisis previo no terminó correctamente.
- Un error de Vision ya no se convierte en una lista vacía marcada como análisis terminado. Se registra el fallo, se conserva la revisión pendiente y el editor puede volver a intentarlo en una apertura posterior; una página que no se pudo cargar tampoco se considera analizada.
- Exportar sigue dependiendo de la verificación protegida existente y no se presenta el detector como una garantía de encontrar todos los rostros.

## Límites conocidos

- El umbral actual de sugerencia es confianza Vision ≥ 0,55. No es un umbral calibrado para documentos de identidad ni una estimación de probabilidad de privacidad.
- El corpus de regresión es enteramente sintético: 18 imágenes, 16 rostros etiquetados y 3 controles sin rostro. Contiene tres identidades generadas, documentos con retrato, dos rostros en una página, giro de 90°, espejo, compresión JPEG, baja resolución, gafas, oclusión parcial y distractores geométricos/textuales. Las cajas de las imágenes fuente son anotaciones humanas aproximadas; no son ground truth profesional.
- Ejecución exploratoria en macOS Vision, umbral IoU ≥ 0,30: 16 TP, 0 FP y 0 FN (precisión/recall/F1 = 1,000). La máscara antigua cubría en promedio solo 0,586 de la caja facial etiquetada; la primera expansión orientada por giro dio cobertura media 1,000 y área propuesta 1,230×. Esa medida era preliminar y corresponde a una iteración anterior del margen.
- En iPhone 18 Pro (iOS 27.0, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`), la petición moderna de rostros falla con `VisionError.internalError("Could not create inference context")` y el runtime declara solo revisión 3. `VNDetectFaceRectanglesRequest` revisión 2 sí ejecuta; las revisiones 1 y 2 detectaron el rostro de control y la 3 falló igual que la petición moderna. El fallback logró en el corpus iOS **16 TP, 0 FP, 0 FN** (precisión/recall/F1 = 1,000), **100 %** de cobertura de las cajas anotadas y área media de máscara de **1,939×** el área facial. Umbral IoU ≥ 0,30. La anotación es aproximada y sintética, no una garantía de rendimiento en documentos reales.
- Validación final en **iPhone 18 Pro (iOS 27.0, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`)**: `OCREvidenceTests` y el corpus, **18/18 aprobados**; el flujo UI de aceptar/descartar, **1/1 aprobado**. El corpus dio 16 TP, 0 FP y 0 FN a IoU ≥ 0,30; las 16 IoU emparejadas quedaron entre **0,708 y 0,816** (media 0,781), cobertura media 1,000 y área media de máscara 1,939×.
- Validación final en **iPad Pro 13-inch M5 (iPadOS 27.0, UDID `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`)**: `OCREvidenceTests` y el corpus, **18/18 aprobados**; el flujo UI de aceptar/descartar, **1/1 aprobado**. La salida de XCTest informó `** TEST SUCCEEDED **`; las IoU emparejadas fueron las mismas que en iPhone 18 Pro (0,708–0,816, media 0,781).
- **iPhone Duo (iOS 27.1, UDID `BF5C28D6-2B6D-46FC-82E8-9A248F5C0186`)** no se pudo revalidar con la versión final: después de la prueba de iPad, `simctl` informó que `CoreSimulatorService`/`simdiskimaged` no respondía y devolvió `Connection refused`. No se reinició ni se detuvo ningún proceso o simulador ajeno. Apple Watch Series 12 (watchOS 27.0) no tiene una app/target de Watch en este proyecto.
- Un retrato pequeño impreso en un documento puede ser una sugerencia válida, aunque el usuario decida mantenerlo visible; logotipos, ilustraciones o artefactos pueden causar falsos positivos. La UI conserva la decisión humana.
- El filtro anterior por tipo de documento omitía imágenes que OCR ya había clasificado como DNI, pasaporte o permiso; la elegibilidad ahora se determina por la presencia de páginas de imagen.
- Las omisiones siguen siendo posibles, en especial en rostros pequeños, parcialmente ocultos, borrosos o con orientación inusual.

## Evaluación necesaria antes de ampliar la promesa

1. Repetir corpus y flujo UI en iPhone Duo cuando `CoreSimulatorService` vuelva a estar disponible.
2. Validar más adelante con un iPhone físico y material de prueba consentido antes de publicar una promesa de precisión real.
3. Ampliar el conjunto con perfiles y fuentes de licencia/consentimiento, y separar ajuste de evaluación antes de calibrar el umbral.
4. Mantener confirmación humana en todas las variantes y no presentar el corpus sintético como cobertura de uso real.

La suite ahora mide la calidad sobre fixtures sintéticos y bloquea regresiones severas de detección y cobertura de máscara. Esa medición no representa precisión general en documentos reales; la app tampoco aplica una máscara sin confirmación explícita.
