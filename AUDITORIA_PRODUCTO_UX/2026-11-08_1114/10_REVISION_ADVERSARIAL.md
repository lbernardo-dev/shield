# Revisión adversarial

El revisor E intentó refutar hallazgos de producto, UX, accesibilidad y QA usando el mismo estado local. El análisis no encontró base para eliminar capacidades del catálogo.

| Tema inicialmente cuestionado | Contraprueba / objeción | Decisión final |
|---|---|---|
| Máscara arbitraria requiere gesto | Inspector sí ofrece selección accesible de entidades detectadas; no equivale a crear cualquier región desconocida | Mantener como P2 acotado a regiones no detectadas y control motor; no afirmar bloqueo universal |
| Borrado Vault sin confirmación/undo | El usuario invoca acción destructiva desde menú contextual; no se reprodujo tap accidental | Mantener P2 de recuperación, no bug confirmado; evaluar cancelación y borrado remoto |
| Densidad de Home | CTA se presenta antes; búsqueda, recents y Vault sirven tareas distintas | Rebajar a P3 de investigación; no reordenar por intuición |
| Siete herramientas del editor | Los controles tienen label/hint/estado y test AX5 anterior aprobó rerun | Mantener P3; descubrir facilidad visual solo con participante nuevo; E2E actualizado sigue pendiente |
| Modes y Presets duplicados | Operan de forma distinta (filtros OCR/rectángulos frente a entidades/watermark) | No fusionar; P3 de posible vocabulario ambiguo |
| Temas estacionales son imposición | WIP actual Base gratuita, ask-first, rechazo persistente/reversible y sonido apagado por defecto; tests unitarios históricos cubren parte | No sostener imposición actual; documentar coste/retorno como P3 condicional y mantener opcional |
| Excepciones de accesibilidad XCTest esconden defectos | El test explica falsos positivos sin elemento/área de búsqueda; ninguna falla real se vincula al filtro | Limitación del gate P3, no incidencia de producto |
| Roadmap/build son fallos de release | Roadmap y referencias de build son inconsistencias locales; estado ASC actual no consultado | Mantener como tareas documentales/operativas P3, no afirmar problema de usuario o build publicado |

## Sesgos revisados

- No equiparar cantidad de funciones/código con exceso, ni baja frecuencia desconocida con bajo valor.
- No recomendar retirar Vault, máscara manual, OCR, verificadores, export, batch, widget, Share Extension o accesos alternativos sin medir valor/coste.
- No confundir verificador de archivo con garantía de que todas las áreas deseadas fueron seleccionadas.
- No tratar el WIP como release ni tests históricos como observación de la versión publicada.
- No usar una calificación global cuando faltan ejecución y percepción visual.

## Desacuerdos/limitaciones pendientes

La severidad de la barrera gestual y del borrado puede cambiar al probar con VoiceOver/control motor y participantes; no se conoce incidencia real. La legibilidad de Home/editor en tamaños/contextos reales, el valor de tema/campaña y claridad del paywall requieren observación o datos. No hay analítica ni entrevista usada para estimar demanda.

