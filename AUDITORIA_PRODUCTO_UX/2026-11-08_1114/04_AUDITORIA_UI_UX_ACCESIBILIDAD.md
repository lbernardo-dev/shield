# Auditoría UI/UX y accesibilidad

## Alcance

Revisión estática de vistas, strings, configuración y UI tests; sin capturas o inspección visual de una app en ejecución. Las observaciones siguientes describen estructura/semántica en código, no percepción confirmada. Se aplican como heurísticas los principios de propósito, jerarquía, libertad y accesibilidad de Apple HIG y las heurísticas de Nielsen Norman Group; no son normas de aprobación ni sustituyen pruebas con personas.

## Pantallas principales

| Pantalla | Qué ve primero / cree que puede hacer | Qué debería poder hacer | Fricción demostrable / límite | Simplificación de menor riesgo |
|---|---|---|---|---|
| Onboarding | Bienvenida, demostración de máscara, seguridad opcional; puede continuar, volver o saltar | Entender el resultado y llegar pronto a su documento | Tres etapas; no se midió comprensión ni abandono. El PIN se solicita solo si decide configurarlo | Preservar demo/skip; probar explicación con usuarios antes de recortarla |
| Home compacto | CTA/hero, luego búsqueda, quick access, estado de índice, categorías, estadísticas, recientes y workspace; en evento invitado puede aparecer tarjeta antes del hero | Iniciar documento nuevo y recuperar uno ya trabajado | Varias vías a Biblioteca; chips compactos muestran iconos sin texto visible, con etiqueta VoiceOver; impacto de descubribilidad desconocido | Mantener CTA primero y medir qué paneles necesitan prioridad; no quitar recents/seguridad por estética |
| Home ancho/iPad | Layout divide paneles de búsqueda/organización y accesos/workspace/recents | Empezar y administrar trabajo en pantalla amplia | Adaptación por size class está en código; foco, densidad real y multitarea no observados | Preservar layout adaptativo; revisar con iPad real y tamaños grandes |
| Editor | Barra superior de cerrar/preview/más/guardar/export; banda horizontal con siete herramientas más undo/redo y selector de modos; inspector con pestañas | Revisar documento, crear máscaras y verificar | Herramientas icon-only visualmente aunque tienen labels/hints/estado accesible; curva de aprendizaje no medida. Crear rectángulo libre exige drag | Mantener herramientas; añadir alternativa no gestual para región arbitraria y ayuda progresiva si el estudio identifica confusión |
| Exportación | Preview, formato/calidad, comprobaciones, CTA; puede mostrar advertencia de página pendiente o gate de estilo | Obtener una copia segura y entender el estado | Varias decisiones antes de exportar, pero justificadas por formato/calidad. No se comprobó el orden ni longitud real en UI | Preservar preview/verificación; priorizar una configuración razonable sin ocultar controles avanzados |
| Vault | Estado de bloqueo, autenticación, lista/estado vacío, añadir, próximos vencimientos | Recuperar y guardar material privado | Acción Delete desde menú contextual no ofrece undo/confirmación en esa ruta; impacto real no reproducido | Confirmación proporcional y cancelable o recuperación temporal antes de borrado permanente |
| Ajustes/Paywall | Ajustes agrupados en personalización, workspace, suscripción, feedback y about; paywall muestra planes, beneficios, nota Free, FAQ y CTA sticky | Controlar preferencias/plan y consultar ayuda | Lista amplia y paywall denso según árbol de vistas; no hay captura que confirme saturación. Paywall tiene cierre explícito | Mantener agrupaciones, evaluar si subcategorías de uso ocasional se pueden reubicar; no ocultar privacidad/restore |

## Hallazgos de accesibilidad

### ACC-002 — Región manual arbitraria solo mediante gesto (P2, no reproducido)

`DocumentCanvas` crea una máscara rectangular a través de `DragGesture` al seleccionar Rect (`Shield/Views/Editor/DocumentCanvas.swift:135-153`; el cierre aplica una región no degenerada en `Shield/ViewModels/EditorViewModel.swift:360-385`). El Inspector expone selección de entidades detectadas (`Shield/Views/Editor/EditorPrivacyInspector.swift:794-814`), pero no una acción general para ubicar una región libre. Hecho: la ruta de creación de región libre en el lienzo depende del arrastre. Interpretación: barrera para usuarios que no pueden usar gesto fino o VoiceOver/Voice Control; no demuestra imposibilidad de proteger campos detectados. Prioridad P2 por tarea central; probar antes de rediseñar. Alternativa conservadora: controles accesibles de crear y ajustar posición/tamaño, conservando gesto y precisión.

### ACC-003 — Alcance parcial del gate automatizado (P3)

El test de auditoría ejecuta `.elementDetection`, `.hitRegion` y `.trait`; filtra reportes de detección sin elemento y problemas de hit target de búsqueda (`ShieldUITests/ShieldLaunchTests.swift:1581-1605`). Los comentarios explican dos falsos positivos/limitaciones esperadas, pero el gate no cubre esos casos. No es una incidencia de UI confirmada; documentar exclusiones y ejecutar la tarea de búsqueda por otra vía.

### Capacidades encontradas que conviene proteger

- Tokens de texto escalable (`@ScaledMetric`) y variantes de Home para Dynamic Type; en AX el grid pasa a una columna.
- Labels, hints, selected values e identifiers en tabs, herramientas y acciones principales.
- Máscaras existentes exponen label/value/hint y acciones accesibles de selección, eliminación, movimiento y ajuste por incremento.
- Controles de zoom visibles (incluido reinicio) además de gestos; Reduce Motion y opción local para reducir efectos decorativos.
- El test de AX5 comprueba controles de varias escenas; existe un E2E nuevo para máscara → PDF → resultado de verificación, pero su ejecución sigue pendiente en el expediente del 7 de noviembre.
- Soporte declarado para iPhone/iPad, rotación y layout regular; revisión con VoiceOver, Voice Control, Switch Control, foco de teclado y iPad real pendiente.

## Complejidad por rol

- **Nuevo:** demo de tres pasos puede enseñar una tarea sensible, y puede omitirse; comprensión real pendiente.
- **Recurrente:** búsqueda, recents, Biblioteca, Vault y providers reducen pasos según situación; no se midió cuál se usa.
- **Accesibilidad:** controles de zoom y máscaras existentes ayudan; crear región no detectada permanece dependiente del gesto.
- **Free/Pro:** la ruta Free conserva tarea esencial de exportación; explicar el límite antes de alcanzar 10 procesamientos y probar el flujo en runtime.

## Localización y visual

ES y EN están representados en recursos y tests focalizados. No se verificaron truncamientos en todos los destinos, pluralizaciones completas, RTL, contraste medido, estado visual claro/oscuro ni color sin depender exclusivamente del color. No se capturaron pantallas. El tema festivo no puede calificarse visualmente; el WIP contempla reducir efectos, pero falta verificarlo en una temporada real o preview controlada.

## Marco de evaluación

Apple recomienda jerarquía reconocible, controles accesibles y alternativas para diversos métodos de entrada; Apple Accessibility también recomienda atención a acciones difíciles de recuperar. HIG y documentación actuales consultadas el 8 de noviembre de 2026: [Design principles](https://developer.apple.com/design/human-interface-guidelines/design-principles/), [Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/), [Accessible controls](https://developer.apple.com/documentation/swiftui/accessible-controls), [Performing accessibility audits](https://developer.apple.com/documentation/accessibility/performing-accessibility-audits-for-your-app). Para la revisión heurística general: [Nielsen Norman Group](https://www.nngroup.com/articles/ten-usability-heuristics/). La revisión no sustituye pruebas reales con personas.

