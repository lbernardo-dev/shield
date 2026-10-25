# 229-secure-batch-review-queue

- Number: 229
- Slug: secure-batch-review-queue

## Notes

## Objetivo y riesgos

Reemplazar el comportamiento actual de `BatchRedactView` que calcula un conjunto de rectángulos por documento y lo copia a todas las páginas. La detección almacenada ya contiene `OCRPageEvidence` con página, entidades y cajas; debe usarse por página. Ninguna coincidencia se exporta o se declara verificada automáticamente.

## Fases

1. Extraer un generador determinista de sugerencias por `OCRPageEvidence` y modo. No usar geometría de plantillas para PDFs/importaciones genéricas ni evidencia de otra página.
2. Crear estado por archivo y página (pendiente, con sugerencias, revisado, error); omitir acceso a Bóveda y manejar documentos sin OCR con revisión manual explícita.
3. Convertir el diálogo de lote en cola revisable: mostrar páginas afectadas/sin evidencia, abrir documento en el editor, permitir reintento/cancelación sin perder el trabajo, y dejar claro que las sugerencias requieren revisión antes de compartir.
4. Unificar la entrada de varios archivos mediante `CaptureImportPipeline`, con progreso y aislamiento de error por archivo; conservar temporales y hacer rollback al cancelar.
5. Solo cerrar un elemento como exportado/verificado al recibir un informe de exportación satisfactorio para todas sus páginas; un error en un elemento no debe ocultar los éxitos ni mezclarlos.

## Aceptación

- Un PDF multipágina con valores y coordenadas distintos por página recibe únicamente cajas de la evidencia de esa página.
- Páginas sin evidencia no heredan rectángulos y aparecen como revisión manual necesaria.
- El usuario puede revisar/editar cada elemento; cancelar/reintentar no pierde otros resultados.
- La UI distingue sugerido, revisado, exportado y verificado, y no afirma “seguro” o “completado” antes de la verificación.
- La entrada múltiple respeta límites del pipeline y permisos security-scoped; errores y cancelación conservan estado coherente.
- Todo contenido nuevo está localizado ES/EN y tiene nombres/estados accesibles.

## Validación diferida

Añadir cobertura unitaria y UI durante la implementación, pero no ejecutar builds/tests de simulador hasta que todas las tareas 226 y 229–233 estén implementadas. La matriz final comienza por iPhone 18 Pro y continúa Duo e iPad.

## Implementación en curso

- El plan de lote toma `OCRPageEvidence` de la página exacta; no rellena con plantillas ni propaga cajas entre páginas.
- El OCR local conserva posiciones vacías cuando una imagen de página no se puede cargar; las observaciones siguientes no cambian de índice ni se asocian a la página equivocada.
- El documento conserva páginas con sugerencias y páginas sin evidencia como pendientes de revisión. El editor permite confirmar cada página y la exportación queda bloqueada mientras quede alguna pendiente.
- El selector de Archivos ya permite múltiples elementos y la importación avanza de forma secuencial; un fallo puede reintentarse u omitirse sin descartar documentos que ya se guardaron.
- Cobertura unitaria escrita para coordenadas distintas por página, páginas sin evidencia y normalización de la cola persistida. No ejecutada todavía por la validación diferida.
- La exportación rasterizada como imagen ahora calcula los hallazgos sin proteger usando el índice de la página actual. Antes comparaba las máscaras con la página 0 de cualquier PDF, lo que podía dar un recuento ajeno a la página exportada.
- Se añadió una prueba unitaria que comprueba el recuento del export de imagen para una página concreta frente al PDF completo. Pendiente ejecutar en el ciclo final.
- Los cambios de recorte, orientación, espejo o geometría de escaneo vuelven a poner todas las páginas en la cola de revisión antes de exportar. Una fingerprint persistida conserva las revisiones parciales y fuerza una primera revisión para documentos antiguos con transformaciones guardadas.
- La copia localizada pide inspeccionar cada página y ajustar máscaras si hace falta antes de confirmarla; los filtros tonales no bloquean la exportación.
- Cobertura unitaria escrita para fingerprints, cola completa, geometría legacy y reanudación de una cola parcial. Pendiente ejecutar en el ciclo final.

### Gate final — 2026-10-21

- Build de simulador y suite `ShieldTests` pasaron en iPhone 18 Pro, iPhone Duo e iPad Pro 13-inch M5: 147 tests verdes, 0 fallos y 1 integración RevenueCat omitida por su condición de entorno en cada destino.
- La suite de interfaz, que cubre la cola y la navegación de revisión, no terminó: Xcode no resolvió la versión del debugger (`noURL`) y dejó un xcresult incompleto. La aceptación interactiva queda pendiente de repetir esa suite.

### Reintento de matriz — 2026-10-25

- `testBatchPendingReviewQueueOpensTheAffectedDocument` se incluyó en un pase UI explícito del iPhone 18 Pro junto con búsqueda, perfiles y regresiones de navegación. Durante el arranque se detectó activo el runner de otra app, `com.romerodev.repsfitness.uitests.xctrunner`, en el mismo UDID.
- Se canceló solo el `xcodebuild` iniciado para MaskID; el runner y proceso RepsFitness quedaron intactos. La ejecución terminó con `BUILD INTERRUPTED` y su `.xcresult` `/private/tmp/MaskID-2403-iPhone18-UI-Regressions.xcresult` no contiene un resultado final fiable. La cola UI sigue pendiente hasta liberar el iPhone 18 Pro; no se ejecutó el pase en Duo/iPad antes del destino obligatorio.
- Las verificaciones unitarias registradas previamente (147/148 por el ciclo, con una integración RevenueCat omitida) siguen siendo evidencia de lógica, no sustituyen el flujo de interfaz de abrir el elemento pendiente.

### Revalidación UI — 2026-10-25

- `testBatchPendingReviewQueueOpensTheAffectedDocument` pasó en iPhone 18 Pro (incluido en `/private/tmp/MaskID-2403-iPhone18-RegressionMatrix.xcresult`), Duo (`/private/tmp/MaskID-2403-Duo-BatchQueue-signed.xcresult`) e iPad (`/private/tmp/MaskID-2403-iPad-FeatureRegression-signed.xcresult`), 1/1 por dispositivo. Esto reemplaza el intento interrumpido anterior.
- Aún falta el flujo end-to-end de reintentar y cancelar elementos de la cola; esta pasada solo valida abrir el documento afectado.
