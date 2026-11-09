# Matriz de puntuación

Escala orientativa 0–4: 0 fracaso grave demostrado, 1 problemas sustanciales, 2 cumplimiento parcial con fricción, 3 buen soporte con mejoras concretas, 4 sólido/verificado dentro del alcance. Las cifras son evaluación heurística basada en evidencia local, no satisfacción de usuarios.

| Dimensión | Peso | Nota | Evidencia y cobertura | Confianza |
|---|---:|---:|---|---|
| Claridad de la promesa/enfoque | 15 | 3 provisional | Posicionamiento, README y flujo local coinciden; sin investigación de público ni ficha externa actual | Media |
| Eficacia/completitud/fluidez de tareas críticas | 20 | 2 provisional | Implementación alineada; hay tests parciales históricos, pero la tarea real completa no tiene E2E aprobado en el estado documentado | Baja |
| Navegación/arquitectura/recuperación | 15 | 3 provisional | Tabs/sidebar, stacks y salidas identificables estáticamente; no se comprobó conservación de estado ni se observó navegación real | Media-baja |
| Valor del catálogo frente a complejidad | 15 | 2 provisional | Funciones apoyan trabajo individual y avanzado; Home/editor/temas añaden capas. No hay uso ni tareas de participantes | Baja |
| Claridad visual, microcopy y coherencia UI | 10 | NO VERIFICADO | No hubo captura ni inspección runtime; el orden de componentes no permite afirmar densidad percibida |
| Accesibilidad y adaptación | 10 | 2 provisional | Escalado, layouts, labels y tests parciales en código; máscara libre gestual; sin VoiceOver/Voice Control real ni auditoría visual actual | Media-baja |
| Calidad técnica/fiabilidad/preservación | 5 | 3 provisional | Verificador, límites, cifrado y tests presentes; test histórico parcial; no build/test actual ni export real ejecutado | Media |
| Libertad/control/personalización | 5 | 3 provisional | WIP opt-in/Base gratuita/audio off y decisión reversible; unit tests históricos; comportamiento de temporada/reinicio no observado |
| Transparencia monetización/confianza | 5 | 2 provisional | Free/Pro documentado y cierre/restore en código; paywall, compra, ASC y comunicación del límite no observados |

## Resultado

No se calcula ni publica una puntuación global. No existe soporte suficiente en más del 60 % del peso evaluable para síntesis de calidad de experiencia: no se observó UI, la dimensión visual está sin verificar y la tarea central carece de E2E completo aprobado en los resultados disponibles. No se descartan dimensiones como NO APLICA; todas corresponden a capacidades del producto.

Alertas separadas: 0 P0, 0 P1; P2: ACC-002, DATA-001, QA-001, PRIV-003; P3: UX-003, UX-004, UX-005, TECH-001, REL-001, ROADMAP-001, THEME-003. Una nota global no cancelaría estos riesgos.

