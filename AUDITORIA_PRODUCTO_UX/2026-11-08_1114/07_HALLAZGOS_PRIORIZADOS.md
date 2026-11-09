# Hallazgos priorizados

Se separan hechos de interpretación. No hay P0 ni P1 confirmados. Severidad refleja impacto posible y evidencia, no cantidad de código.

## P2 — impacto medio/alto que requiere validación o cambio acotado

### ACC-002 — Crear región libre requiere arrastrar

- **Hecho:** con Rect seleccionado, el lienzo crea máscara mediante `DragGesture`; cerrar el gesto aplica rectángulo (`Shield/Views/Editor/DocumentCanvas.swift:135-153`; `Shield/ViewModels/EditorViewModel.swift:360-385`). El Inspector permite seleccionar entidades detectadas, no cualquier región (`EditorPrivacyInspector.swift:794-814`).
- **Interpretación/impacto:** riesgo de bloqueo para usuarios que no realizan gesto fino y para redacción manual de contenido que OCR no detectó. No se ha comprobado que toda persona no pueda completar su tarea: existe ruta para entidades identificadas.
- **Reproducción estática:** abrir editor → elegir Rect → única creación general encontrada es arrastre del lienzo. Runtime con VoiceOver/Voice Control pendiente.
- **Confianza:** alta sobre la implementación; media sobre alcance de bloqueo.
- **Alternativa:** controles accesibles para crear/mover/redimensionar región, manteniendo precisión por gesto.
- **Criterio:** completar una máscara arbitraria y corregirla con VoiceOver y control motor sin degradar ubicación/tamaño ni cobertura de regiones existentes.

### DATA-001 — Eliminar un documento del Vault no ofrece undo visible

- **Hecho:** menú contextual de cada documento ofrece Delete y llama directamente a `appState.deleteDocument` (`Shield/Views/Vault/VaultView.swift:340-359`). La función persiste ausencia, elimina archivos locales y agenda eliminación remota (`Shield/ViewModels/AppState.swift:784-800`). No aparece alerta/undo en esa ruta.
- **Interpretación/impacto:** un error de selección puede retirar copia local y sincronizada; no hay evidencia de un borrado accidental reproducido. La acción sí es deliberada dentro de menú contextual.
- **Reproducción estática:** Vault desbloqueado → menú contextual → Delete → flujo de código elimina assets y agenda remote deletion.
- **Confianza:** alta en consecuencia del código; media en ocurrencia/daño para usuarios.
- **Alternativa:** confirmación clara y cancelable, o retención reversible si el modelo seguro permite recuperación sin conservar datos que el usuario esperaba borrar.
- **Criterio:** cancelar no altera storage/local/remote; confirmar explica alcance; recuperación/deshacer comprobados con CloudKit offline y online antes de prometerlo.

### QA-001 — Falta cierre E2E de tarea central

- **Hecho:** existe test de editor→PDF verificado AX5 pero el propio registro anterior lo marca pendiente; el 1/1 histórico cubrió test anterior parcial, no la versión ampliada (`ShieldUITests/ShieldLaunchTests.swift:1482-1558`; `AUDITORIA_PRODUCTO_UX/2026-11-07_0948/15_EJECUCION_FASE_02.md`).
- **Impacto:** no se puede confirmar que captura/import real, revisión, salida y recuperación funcionen como una tarea completa. Riesgo de confianza en un producto de privacidad.
- **Confianza:** alta sobre cobertura incompleta; no es bug funcional demostrado.
- **Criterio:** fixture sintético entra por Files, requiere revisión manual, exporta, el verificador muestra resultado y la app conserva el original ante error/cancelación; ejecutar en iPhone y iPad soportados.

### PRIV-003 — Validar alcance de iCloud KVS para cuota agregada

- **Hecho:** KVS replica el integer `processedDocumentsCount`; el disclosure local ya describe la sincronización. No almacena contenido ni ID de documento (`PremiumManager.swift:923-995`; `Docs/PRIVACY_POLICY_PRODUCT_FACTS.md`). Apple dice que KVS se comparte en dispositivos con la misma cuenta y se almacena localmente sin cifrado.
- **Interpretación/impacto:** decisión de privacidad ya registrada: conservar solo este contador agregado. Falta confirmar misma cuenta, cuenta distinta y offline; no se demuestra fuga de documentos.
- **Confianza:** alta sobre código y guía de Apple; media sobre clasificación/expectativa.
- **Criterio:** los escenarios confirman que solo existe el entero y disclosure/conducta coinciden; no ampliar datos enviados a KVS.

## P3 — oportunidad de claridad/documentación, no defecto confirmado

### UX-003 — Muchas entradas de organización en Home

- **Hecho:** secuencia compacta incluye CTA, búsqueda, quick access, estado de índice, categorías, estadísticas, recents y workspace (`HomeView.swift:50-85,342-365,439-615,702-777`). CTA aparece antes (`HomeDashboardViews.swift:390-410`); quick access y otros paneles sirven trabajos diferentes.
- **Impacto:** carga visual potencial, sin observación de pantalla, tasas de descubrimiento ni abandono. La duplicación aparente puede ser acceso útil para perfiles distintos.
- **Confianza:** alta en estructura, baja en impacto.
- **Criterio:** usuarios nuevos completan primera tarea y recurrentes recuperan documentos; reordenar solo si el tiempo/error observado mejora.

### UX-004 — Siete herramientas icon-only en barra desplazable

- **Hecho:** Rect, Pan, Fields, Auto, Text, Watermark y Adjust están en `ScrollView(.horizontal)`; label/hint/value/identifiers se proporcionan a tecnología asistiva (`EditorChromeViews.swift:338-405`).
- **Impacto:** descubribilidad visual posible, no validada. Herramientas necesarias justifican densidad para uso avanzado.
- **Confianza:** alta en estructura, baja en fricción real.
- **Criterio:** medir que principiante halle máscara y recurrente localice funciones; cambiar orden/agrupación sin retirar acciones si hay errores.

### UX-005 — “Modo” y “preset” comparten algunos contextos/nombres

- **Hecho:** hay 7 `RedactionMode` y 9 `RedactionPreset`; `applyMode` filtra plantillas/rectángulos OCR y `applyPreset` evalúa entidades y puede añadir watermark (`Redaction.swift:138-214`; `RedactionPresets.swift:6-62`; `EditorViewModel.swift:442-565`).
- **Impacto:** dos vocabularios pueden exigir aprendizaje; operaciones distintas descartan llamarlo duplicación funcional.
- **Confianza:** alta sobre diferencia de lógica, media sobre confusión.
- **Criterio:** prueba moderada confirma comprensión; entonces añadir explicación contextual/renombrar, sin fusionar reglas.

### TECH-001 — Excepciones explícitas en accessibility audit

- **Hecho:** auditoría XCTest excluye detección sin XCUIElement y hit target de búsqueda (`ShieldUITests/ShieldLaunchTests.swift:1581-1605`). El comentario explica falsos positivos conocidos.
- **Impacto:** cobertura del gate incompleta en esos casos; no demuestra que una vista sea inaccesible.
- **Confianza:** alta.
- **Criterio:** casos omitidos documentados y prueba manual/automatizada alternativa de búsqueda y visual recognition.

### REL-001 — Reconciliar versión/build local con referencia histórica

- **Hecho:** proyecto declara 1.1.6/build 1162026102501 (`Shield.xcodeproj/project.pbxproj:1468-1492`); documento de metadata menciona 1162026102502 visto en registro de 25 octubre (`Docs/APP_STORE_METADATA_DRAFT.md:1-4`).
- **Impacto:** riesgo operativo de preparar un paquete o metadata contra un build equivocado. No se consultó ASC actual; no se afirma conflicto remoto vivo.
- **Confianza:** alta sobre referencias locales, nula sobre estado ASC actual.
- **Criterio:** verificar con ASC/artefacto firmado y registrar fuente+fecha antes de una tarea de release.

### ROADMAP-001 — Roadmap local desactualizado

- **Hecho:** `ROADMAP.md:25-90` aún enumera App Intents, batch/perfiles y varias mejoras iPad como futuro aunque existen en target/código (`ShieldAppIntents.swift`, `HomeView.swift:1971+`, modelos preset y sidebar).
- **Impacto:** puede desorientar planificación interna; no afecta directamente a usuarios.
- **Confianza:** alta en diferencias de repositorio.
- **Criterio:** marcar estado actual y separar completado/futuro con referencias.

### THEME-003 — Coste de mantenimiento de campaña estacional

- **Hecho:** catálogo y coordinación incluyen calendario, política, decisiones/migración, audio, icono, adornos, localización y oferta comercial; existe una campaña programada actual. El WIP hace opt-in, Base gratuita y audio opt-in.
- **Impacto:** coste de ramas/QA y presencia condicional en Home; beneficio de uso no medido. No hay evidencia para llamarla imposición ni para retirarla.
- **Confianza:** alta en estados/estructura; baja en retorno o interferencia.
- **Criterio:** mantener una opción reversible; añadir otra campaña solo con plan de medición y tests de calendario/accesibilidad.

