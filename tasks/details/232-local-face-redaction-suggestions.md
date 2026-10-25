# 232-local-face-redaction-suggestions

- Number: 232
- Slug: local-face-redaction-suggestions

## Notes

- Implementación local con Vision y confianza mínima de 0,55; conversión a coordenadas normalizadas de editor con margen conservador y recorte al área de la página.
- La carga de páginas conserva los huecos del origen para no desplazar índices; las cajas casi idénticas se deduplican dentro de la misma página conservando la detección con más confianza.
- El editor muestra cada sugerencia como caja revisable, y proteger/descartar requiere interacción explícita. Las cajas aceptadas se pueden ajustar como otras redacciones y la exportación conserva su verificador.
- El detector procesa una página por vez para limitar memoria. Si crop, rotación o espejo cambian la imagen, invalida las cajas y descartes anteriores, vuelve a analizarlas con la geometría nueva y guarda tanto la invalidación como el resultado.
- La carga, comparación de fingerprint y actualización de resultados pasa por el actor principal para no publicar cambios de la vista desde una tarea no aislada. El descarte cambia el snapshot y `EditorView` persiste ese identificador en cuanto cambia.
- Añadidos tests sintéticos para conversión, deduplicación y persistencia del modelo. No miden exactitud del detector; el informe de límites y la necesidad de un corpus consentido están en `Docs/FACE_SUGGESTIONS_LIMITATIONS.md`.
- La elegibilidad se determina por páginas de imagen, no por `DocumentKind`: Captura puede clasificar un DNI/pasaporte con una categoría concreta aunque siga teniendo páginas rasterizadas.
- Vision recibe la orientación UIImage/EXIF y se conserva el giro de cara. Si la API moderna falla, el fallback Apple Vision revisión 2 convierte `roll` de radianes a grados. La máscara opaca se amplía 21 % por lado horizontal y 37 % por lado vertical del eje facial, gira la caja a los ejes de página y recorta al papel. La revisión 5 invalida sugerencias antiguas.
- 2026-10-24: se encontró un desajuste mayor que el detector: los tipos reconocidos con páginas raster (`dniESP`, pasaporte, licencia, etc.) mostraban una plantilla vectorial en el editor aunque la detección y la exportación trabajaban sobre la imagen escaneada. El editor ahora prioriza la página raster y usa su relación de aspecto para alinear overlay, máscara y exportación.
- La huella de coordenadas rasterizadas tiene una versión propia: documentos antiguos de tipos reconocidos con imágenes entran en revisión de todas sus páginas antes de poder exportar; las nuevas importaciones quedan marcadas con la huella actual.
- iPhone 18 Pro iOS 27.0: test de selección raster Passed, test de migración de máscaras antiguas Passed, flujo UI aceptar/descartar Passed y suite `ShieldTests` **155 Passed, 0 Failed, 1 Skipped** (firma normal).
- iPhone Duo iOS 27.1 e iPad Pro 13-inch M5 iPadOS 27.0: flujo UI aceptar/descartar **1/1 Passed** en ambos. En iPad Xcode quedó bloqueado en `simctl diagnose` tras terminar XCTest; se interrumpió solo ese proceso hijo propio y el result bundle terminó correctamente.
- Un intento previo de suite sin firma tuvo 148 Passed y 6 fallos de Keychain/persistencia; se repitió con firma normal y quedó verde. Los avisos `noURL`/`invalidDigitCount` de IDE no impidieron las pruebas focalizadas.
- El estado “sin corpus etiquetado” quedó superado en el diagnóstico final del 2026-10-24: se añadió y ejecutó un corpus sintético local. La validación con escaneos reales consentidos sigue pendiente antes de anunciar precisión general.
- 2026-10-24, estado inicial del corpus antes del ajuste geométrico final: el conjunto sintético tiene 18 imágenes/16 rostros/3 negativos; la exploración de Vision en macOS dio 16 TP/0 FP/0 FN a IoU 0,30. La expansión inicial orientada al giro cubría 100 % con 1,23× el área facial anotada. Las pruebas de rostros girados revelaron bordes descubiertos, por lo que el margen final subió a 1,42×1,74 y el límite de área del gate a 2,0×; la medición final iOS es 1,939×. Los resultados finales de iPhone 18 Pro e iPad están más abajo.

## Gate previo — 2026-10-21

- La build y `ShieldTests` pasaron en iPhone 18 Pro, iPhone Duo e iPad Pro 13-inch M5: 147 aprobados, 0 fallos y una integración RevenueCat omitida por su configuración explícita en cada simulador.
- El gate UI se interrumpió porque Xcode no pudo resolver el debugger (`noURL`); aceptar, descartar y ajustar sugerencias necesita una repetición interactiva. No se midieron omisiones/falsos positivos sobre un corpus consentido; las pruebas sintéticas validan geometría y persistencia, no exactitud general del detector.

## Revalidación — 2026-10-24

- Se corrigió la causa de omisiones en documentos de identidad reconocidos: `.dniESP`, `.passportUSA`, `.drivingUK`, `.passportMEX` y `.dniITA` podían conservar páginas de imagen, pero el filtro anterior solo analizaba `.photo` y `.genericID`. Ahora analiza documentos con imágenes y omite documentos vectoriales sin imágenes.
- `DetectFaceRectanglesRequest.perform(on:orientation:)` recibe las ocho orientaciones UIImage, incluidas las reflejadas. La caja de Vision, cuyo origen está abajo a la izquierda, se convierte explícitamente a las coordenadas normalizadas de origen superior izquierdo del editor.
- La caja punteada muestra el área observada sin padding. Al aceptar, se añade una máscara opaca ligeramente expandida para no dejar bordes descubiertos; se mantiene la decisión humana, no hay máscara automática.
- iPhone 18 Pro iOS 27.0: build explícita y **18/18 tests aprobados** (16 `OCREvidenceTests`, aceptar/descartar en UI y navegación Scan).
- iPhone Duo iOS 27.1: build explícita y **2/2 tests UI aprobados** (rail/accesorio Scan y aceptar/descartar máscara facial).
- iPad Pro 13-inch M5 iPadOS 27.0: build explícita; la salida de XCTest registra **2/2 tests UI aprobados** (Scan en toolbar y aceptar/descartar rostro). Xcode quedó bloqueado finalizando logs tras ambos tests; se cerró solo ese proceso propio y el result bundle no quedó finalizado.
- En el momento de esta etapa todavía no había corpus etiquetado; ese pendiente quedó resuelto en el diagnóstico de precisión añadido más abajo. La validación con escaneos reales consentidos sigue pendiente antes de afirmar precisión general.

## Objetivo

Detectar rostros localmente como sugerencias revisables, sin redacción automática. Mantener las imágenes y rectángulos en el dispositivo y respetar los límites de escala/transformaciones del documento.

## Implementación

- Usar el framework Vision ya presente en el proyecto y producir regiones normalizadas por página.
- Mapear regiones a coordenadas canónicas después de orientación, recorte y rotación; no confundir un retrato impreso en un documento con una cara fuera de contexto.
- Presentar cada detección en el editor como sugerencia que se puede aceptar, descartar o ajustar; dejar la exportación protegida existente como gate.
- Evaluar con imágenes sintéticas/locales representativas, separando omisiones y falsos positivos; no declarar cobertura general hasta documentar corpus y límites.
- No ampliar a firmas automáticamente en este alcance.

## Diagnóstico de precisión — 2026-10-24

- Corpus sintético aprobado por el usuario: 18 imágenes, 16 rostros anotados y tres controles negativos. La ejecución de Vision en macOS obtuvo 16 TP, 0 FP y 0 FN a IoU ≥ 0,30; es evidencia preliminar del host y no demuestra rendimiento en iPhone.
- En iPhone 18 Pro (iOS 27.0, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`), `DetectFaceRectanglesRequest` y la revisión 3 de `VNDetectFaceRectanglesRequest` dieron `Could not create inference context`. `VNDetectFaceRectanglesRequest` revisión 2 sí funcionó en el runtime; el detector de producción ahora conserva la API moderna como ruta principal y recurre a revisión 2 solo si aquella lanza error.
- La ruta fallback midió **16 TP, 0 FP y 0 FN**, precisión/recall/F1 **1,000**, cobertura de máscara **1,000** y relación área máscara/caja etiquetada **1,939×**, con umbral de matching IoU ≥ 0,30. Las 16 IoU observadas fueron **0,708–0,816** (media 0,781); todas las cajas sintéticas quedaron cubiertas.
- El margen menor 1,38×1,58 dejó bordes descubiertos en dos pruebas geométricas de cara girada/erguida; el definitivo 1,42×1,74 pasa la geometría y el gate de corpus con tope de área 2,0×.
- La implementación dejó de ocultar errores con `try?`. Si la carga o Vision fallan, captura/editor no guardan una lista vacía como análisis finalizado; el documento queda elegible para reintento. Se subió la revisión a 5 para invalidar resultados vacíos de la versión anterior.
- `OCREvidenceTests` y el corpus suman **18/18 pruebas verdes** en iPhone 18 Pro y también **18/18** en iPad Pro 13-inch M5; el flujo UI aceptar/descartar pasó **1/1** en ambos con la corrección del hit target de 44×44 pt. En los dos simuladores: 16 TP, 0 FP, 0 FN; IoU observada 0,708–0,816 (media 0,781); cobertura media 1,000 y área media de máscara 1,939×.
- iPhone Duo no se pudo revalidar con la revisión final: después de la prueba de iPad, `simctl` reportó que `CoreSimulatorService`/`simdiskimaged` no respondía (`Connection refused`). No se reinició ni se detuvo ningún proceso ajeno. Repetir allí al restaurarse el servicio. Apple Watch Series 12 (watchOS 27.0) no tiene una app/target de Watch en este proyecto.

## Aceptación

- El detector corre en local y no añade frameworks de red ni telemetría con imagen/texto/rectángulos.
- Sugerencias correctas bajo rotación/crop y en multipágina; detecciones repetidas no se duplican.
- Ninguna región se aplica hasta interacción explícita y la exportación mantiene verificaciones.
- Accesibilidad y ES/EN completas; falsos positivos/omisiones reportados de forma medible.

