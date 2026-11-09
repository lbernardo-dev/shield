# Resumen ejecutivo

## Identidad y veredicto

MaskID (bundle `com.romerodev.shield`) es una app SwiftUI para iPhone y iPad que prepara copias de documentos con menos datos personales expuestos. Su flujo central —importar, revisar detecciones, enmascarar y exportar una copia verificable— coincide con la promesa local. **Veredicto: cumple parcialmente; la alineación está documentada y el flujo está implementado, pero no se comprobó de extremo a extremo en esta ejecución ni se midió con usuarios.** La verificación del PDF no demuestra que el usuario haya detectado cada dato que quería ocultar.

El estado auditado es el *working tree* de `main` en `095776b`, con cambios locales sustanciales que ya existían al inicio. Los cambios de temas y consentimiento están en WIP y no deben tratarse como release. Esta auditoría fue una revisión paralela con cinco roles; no hubo observación visual directa ni entrevista.

## Fortalezas confirmadas que conviene preservar

1. **Control humano de la redacción:** OCR local propone datos, pero el flujo conserva revisión y máscara manual. La documentación prohíbe prometer detección completa.
2. **Resultado revisable:** la exportación rasteriza y el verificador comprueba texto extraíble, anotaciones, metadatos y señales de OCR residual. No equivale a certificar que no se omitió una región sensible.
3. **Privacidad y continuidad:** biblioteca local cifrada, Vault separado con autenticación, protección de la interfaz al pasar a segundo plano y rutas alternativas de importación. No hay evidencia que justifique retirar estas capacidades.

## Cinco problemas o riesgos principales

| Prioridad | Hallazgo | Evidencia y alcance |
|---|---|---|
| P2 | La máscara rectangular manual requiere arrastrar sobre el lienzo; no se encontró una vía equivalente para una región arbitraria con VoiceOver/control por voz. | `DocumentCanvas.swift:135-153`; el Inspector puede seleccionar entidades detectadas, no cualquier región (`EditorPrivacyInspector.swift:794-814`). Barrera inferida, no probada con tecnología asistiva. |
| P2 | El menú contextual del Vault elimina sin confirmación ni deshacer visible en esa ruta. | `VaultView.swift:344-359` llama a `AppState.deleteDocument`, que elimina archivos locales y agenda borrado remoto (`AppState.swift:784-800`). Riesgo de error, no borrado accidental reproducido. |
| P2 | La tarea completa importar → revisar → redactar → verificar/exportar no tiene un E2E aprobado en el estado documentado. | El E2E AX5 actual está en `ShieldLaunchTests.swift:1482-1558` y quedó pendiente; el test anterior parcial sí pasó en un rerun histórico. |
| P2 | El contador Free se replica en iCloud KVS, cuyo almacenamiento local Apple describe como no cifrado. | Solo se almacena un entero de cuota, sin contenido ni ID documental; disclosure local actualizado. Falta confirmar comportamiento multi-dispositivo/offline (`PremiumManager.swift:923-995`). |
| P3 | La versión/build del proyecto no coincide con la referencia local histórica de ASC. | Proyecto: 1.1.6 / build 1162026102501; documento local cita build 1162026102502 en revisión. ASC no se consultó en esta ejecución, por lo que no se afirma un conflicto publicado. |

## Complejidad y decisiones

No hay evidencia suficiente para concluir que el catálogo completo sea exceso. Home ofrece el CTA de protección antes de varios paneles y mantiene accesos para uso recurrente; el editor presenta siete herramientas en una banda horizontal. Son señales para estudiar descubribilidad, no prueba de que la app confunda. La complejidad funcional avanzada (OCR, estilos, Vault, lotes, proveedores y sincronización) tiene casos de uso plausibles y no debe retirarse por baja frecuencia supuesta.

La capa estacional añade lógica de calendario, consentimiento, preferencias, persistencia, iconos, audio y presentación. El WIP actual mejora el control: Base gratuita, invitación por evento, decisión reversible y audio apagado por defecto. Se recomienda mantenerla opcional y no ampliar variantes hasta medir su valor y su efecto en la tarea principal.

## Puntuación y prioridades

No se publica una nota global: la interfaz no se observó en ejecución y la tarea central no cuenta con E2E completo aprobado; menos del 60 % del peso evaluable está suficientemente sustentado para una síntesis global. No se identificó ningún P0 ni P1 demostrado.

Las tres prioridades de mayor retorno son: (1) validar una alternativa accesible para crear máscaras arbitrarias; (2) hacer recuperable o confirmar el borrado desde Vault; (3) cerrar el E2E con documento sintético antes de afirmar eficacia end-to-end. Las estimaciones y pruebas propuestas están en `12_PLAN_ACCION_EJECUTABLE.md`.

## Alcance de la ejecución

Se inspeccionaron fuentes, documentación, configuración, tests existentes y el expediente anterior; se registró el estado Git inicial/final y se validó `git diff --check`. No se compiló, no se ejecutó ningún test ni se capturó UI en esta sesión. Se conservaron todos los cambios preexistentes. No se modificó código de producto. `scripts/task.sh` añadió/reclamó/completó la tarea 249 y su nota, tal como exige `AGENTS.md`.

