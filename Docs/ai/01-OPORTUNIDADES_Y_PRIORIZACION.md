# Oportunidades y priorización de IA

## Criterios

Escala 0–5. Los pesos reflejan que MaskID debe minimizar omisiones y errores antes de ampliar conveniencia: impacto 20 %, frecuencia 15 %, adecuación de datos 15 %, fiabilidad 15 %, viabilidad 15 %, privacidad 10 %, mantenibilidad (5 significa poco coste) 5 % y claridad UX 5 %. La suma ponderada se expresa sobre 100.

| Oportunidad específica | I | F | D | R | V | P | M | UX | Puntos | Evaluación |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Completar campos OCR ausentes con frases exactas de evidencia local | 4 | 4 | 5 | 4 | 5 | 5 | 4 | 5 | 89 | Seleccionada: reduce edición manual y no deja al modelo inventar valores o cajas. |
| Asociar cada sugerencia a una observación OCR de su página y caja reales | 4 | 4 | 5 | 5 | 4 | 5 | 4 | 5 | 90 | Seleccionada como requisito técnico de la primera función: impide aceptar campos globales sin procedencia espacial. No se añade una pantalla independiente de cobertura. |
| Explicar riesgos del Protection Check usando solo verificaciones reales del archivo exportado | 3 | 3 | 5 | 5 | 5 | 5 | 5 | 5 | 89 | Ya existe en `ExportProtectionCheckView`: recuentos verificados, páginas, metadata, watermark, detecciones restantes y nota de límites. Se descarta ampliar esta entrega porque no hay fricción incremental demostrada y no necesita IA. |
| Encontrar posibles datos sensibles no reconocidos por patrones mediante etiquetas semánticas locales | 4 | 3 | 4 | 3 | 4 | 4 | 3 | 3 | 72 | Pospuesta: cada etiqueta debe recuperar la frase y caja exactas; el valor incremental sobre la extracción prioritaria necesita corpus. |
| Búsqueda semántica local entre documentos ya indexados | 3 | 3 | 4 | 3 | 3 | 4 | 3 | 4 | 67 | Pospuesta: hay búsqueda OCR local; un índice vectorial aumenta superficie y retención de datos sensibles. |
| Analizar con PCC documentos extensos o de estructura atípica | 4 | 2 | 4 | 3 | 2 | 2 | 2 | 3 | 58 | No se habilita como fallback automático ni función independiente; PCC queda integrado únicamente como segunda pasada opt-in de la mejora OCR seleccionada, tras verificar capability/firma y pedir consentimiento por análisis. |
| Comandos en lenguaje natural para crear, mover o eliminar máscaras | 4 | 3 | 3 | 1 | 3 | 3 | 2 | 4 | 58 | Descartada para esta entrega: geometría ambigua y acciones con efectos requieren interpretación y confirmación adicional. |
| Alertas generativas de páginas o campos omitidos antes de compartir | 5 | 3 | 4 | 2 | 3 | 4 | 2 | 4 | 69 | Pospuesta: puede dar falsa seguridad; la cobertura debe medirse primero con detección y reglas verificables. |
| Consejos o resúmenes generales sobre documentos personales | 2 | 2 | 2 | 2 | 3 | 2 | 2 | 2 | 43 | Descartada: no ayuda al objetivo de enmascarar y puede introducir consejos incorrectos o sensibles. |

## Selección

1. **Extracción asistida local con grounding determinista.** Mantener Foundation Models como complemento de Vision. El resultado es elegible solo si el campo estaba vacío y la secuencia completa de tokens (con puntuación conservada) coincide con una observación OCR. La comparación puede ignorar mayúsculas y diacríticos, pero el valor almacenado siempre se recupera literalmente de la frase OCR coincidente; no se persisten variantes ortográficas del modelo ni se reformatean fechas o identificadores. El campo queda asociado a evidencia, página y confianza real de Vision. Ninguna máscara se crea desde texto generado sin una caja real.
2. **Evidencia por página y caja.** Seleccionada como componente técnico, no como una superficie nueva: el inspector ya presenta los campos editables y la extracción debe conservar la procedencia espacial correcta. El test verifica la página, el ID de observación, la caja y la confianza de Vision.

PCC no constituye un chatbot ni una función autónoma: es una ruta de escalado explícita de la mejora OCR seleccionada. Solo recibe texto OCR mínimo después del consentimiento; no hay comparación empírica de calidad PCC frente al modelo local, por lo que su valor real debe medirse con documentos sintéticos en hardware compatible.

El umbral de aceptación de la primera entrega es: cero valores generados que no estén contenidos como frase completa en texto OCR de origen; cero valores de modelo con confianza superior a la mayor confianza de la evidencia que los respalda; cero cajas o máscaras generadas por el LLM; cero solicitudes a PCC sin consentimiento por uso, disponibilidad, feature flag y cuota válida; fallback determinista sin bloquear la captura. La evaluación automática verifica estas condiciones con datos sintéticos. No se afirmará utilidad/precisión del modelo real sin ejecutar corpus representativo en un dispositivo compatible.

