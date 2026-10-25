# 236-auditoria-redesign-producto-ui

- Number: 236
- Slug: auditoria-redesign-producto-ui

## Resultado

Informe integral redactado en `Docs/REDISENO_INTEGRAL_MASKID_2026-10-23.md`, con diagnóstico del producto y de la ficha pública, evidencia cualitativa de usuarios, matriz de servicios esenciales, auditoría UX/UI, evaluación de APIs modernas de Apple, metadata ES/EN con límites contados, experimento de adquisición y plan por fases.

Se preparó además un prototipo interactivo de cinco pantallas: Inicio, Captura, Revisión, Editor y Exportación. El artefacto usa contenido sintético y muestra el flujo propuesto; no representa una build real ni debe usarse como captura de App Store.

## Hallazgos que guían la propuesta

- La ficha pública de MaskID aún no tiene valoraciones suficientes para mostrar un resumen. La auditoría de ASC guardada en tarea 222 registró 14 descargas nuevas y 4,81 % de conversión en la ventana de 90 días visible al 16 de octubre; no es una muestra causal ni suficiente para declarar qué etapa falla.
- El release log de tarea 235 deja build 1.1.5 en `PREPARE_FOR_SUBMISSION`, válida pero no enviada a revisión. La ficha pública consultada muestra versión anterior; confirmar el estado actual antes de atribuir la falta de interés a la interfaz.
- La hoja manual de consentimiento de analítica puede presentarse antes de `sessionStage == .ready`; onboarding tiene siete pasos y un paywall al final. Se recomienda medir instalación limpia, aplazar el consentimiento y condensar la primera sesión.
- `Tab(value: .capture)` actúa como botón y contiene `Color.clear`; usar `tabViewBottomAccessory` o una acción nativa con fallback, manteniendo navegación de sistema.
- La captura ya usa Vision Swift `RecognizeTextRequest`, mientras `ExportVerifier` conserva `VNRecognizeTextRequest`; unificar API, cancelación y coordenadas.
- Liquid Glass debe usarse para controles y navegación, no para contenido del documento. La propuesta mantiene tarjetas opacas y base de marca estable.

## Límites del trabajo

- No se modificaron archivos de producto, metadata remota, App Store Connect ni release artifacts.
- No se compilaron, instalaron o probaron builds; no se usaron simuladores.
- No se limpiaron cachés, logs, temporales ni residuos.
- Se mantuvieron intactos los cambios locales preexistentes del workspace.
