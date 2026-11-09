# Plan de simplificación sin código

## Acciones rápidas y seguras

1. Audio estacional opt-in y copy coherente. Esfuerzo bajo, regresión baja, impacto potencial medio. Validar instalación limpia, preferencia, mute y relanzamiento.
2. Tras confirmar semántica, ampliar facts de privacidad del contador KVS. Esfuerzo bajo-medio, riesgo editorial bajo; requiere revisión de producto/privacidad.
3. Resolver AUD-010: valorar si el contador agregado de cuota es apropiado para KVS, que Apple describe como no cifrado localmente. Mantener el límite entre dispositivos y probar sincronización/offline si se decide una alternativa.
4. Corregir documento interno sobre consentimiento analítico.

## Flujos principales

1. Añadir E2E importación → revisión OCR → corrección manual → exportación/verificación con Dynamic Type AX5 y VoiceOver. Esfuerzo medio, riesgo bajo.
2. Validar cancelación, errores y reintento en import/OCR/export; asegurar conservación de documento de origen.
3. Probar Home compacto con usuarios nuevos. Si hay errores, añadir etiquetas o bajar competencia visual conservando entradas.
4. Probar editor para principiante y recurrente; si cuesta hallar herramienta, agrupar/reordenar progresivamente sin quitar capacidades.
5. Probar continuidad Free al límite de 10 y transparencia del plan sin compras reales.

## Racionalización funcional

- Reordenar: distinguir apariencia base de efectos/evento.
- Hacer opcional: sonido y cambio decorativo estacional.
- Mantener: OCR, máscaras manuales, Vault, verificador y Share Extension; alineados con misión o continuidad.
- No retirar widgets, App Intents, Share Extension ni herramientas sin datos de valor/frecuencia.
- Investigar si “equipos” es público actual o visión futura antes de invertir en colaboración.

## Validación posterior

Prueba moderada exploratoria con usuarios nuevos, recurrentes, Free/Pro y necesidades accesibles; medir tareas completas, omisiones, reintentos y comprensión, sin tratar muestra pequeña como estadística. Instrumentación mínima opt-in, sin texto OCR/documento y con retención limitada. Criterio: resultado exportado verificable, recuperación tras error, audio sin consentimiento nunca, cuota/sync comprensibles.

Cambios de preferencias deben ser reversibles/migrables; conservar datos y rutas anteriores durante piloto; usar fixture sintético y rollback. Sin publicación ni cambio comercial dentro de auditoría.

## Dependencias y riesgos

Integridad de PDF exige fixtures sin datos personales y lectura de contenido subyacente. Sync y disclosure dependen de confirmar cuenta/KVS. Tests dependen de CoreSimulator operativo y dispositivo objetivo permitido. Preferencias necesitan migración sin borrar elección previa. No ejecutar compras o alterar App Store Connect.

