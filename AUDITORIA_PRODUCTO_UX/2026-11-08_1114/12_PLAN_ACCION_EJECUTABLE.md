# Traspaso de acciones para fase 02

Cada ID es estable dentro de este expediente y debe gestionarse individualmente. Las propuestas son mínimas y no implican autorización de código. P0/P1: ninguno identificado; por tanto no hay camino de reproducción/test obligatorio para un bloqueo P0/P1. Para acciones P2 se propone test de aceptación antes de implementar.

| ID | Severidad | Ruta/archivo | Hecho y tarea afectada | Modificación mínima propuesta | Aceptación verificable | Riesgo/dependencias y prueba previa |
|---|---|---|---|---|---|---|
| AUD-011 | P2 alta | Editor / DocumentCanvas | Crear región libre requiere drag; afecta a ocultar datos no detectados con acceso alternativo | Añadir control accesible para crear y mover/redimensionar máscara en coordenadas de página | VoiceOver/Voice Control pueden crear región arbitraria, corregirla y exportar; geometría y Undo coinciden con gesto | Medio; depende de zoom/transform; test con fixture y tecnologías asistivas, sin eliminar gesto |
| AUD-012 | P2 alta | Vault / VaultView / AppState.deleteDocument | Delete del contexto elimina assets y agenda remoto sin undo visible | Confirmar alcance y ofrecer cancelación; recuperación temporal solo si compatible con borrado seguro | Cancelar no cambia datos/local/remote; confirmar produce estado explícito coherente; prueba online/offline y reconexión | Medio-alto por claves, cifrado y CloudKit; no conservar copia tras borrado confirmado sin decisión explícita |
| AUD-013 | P2 alta | Capture → Editor → Export / ShieldUITests | La tarea completa no está cubierta por el E2E pendiente | Ejecutar/ajustar test de documento sintético existente | Importa, revisa, corrige, exporta, verifier informa estado y vuelve; cancelar/fallar conserva origen | Medio; runner firmado, sin paralelo, device matrix iPhone/iPad; no enviar PII |
| AUD-014 | P2 media | PremiumManager / KVS | Sincroniza solo contador agregado; falta validación multi-device/offline | Añadir pruebas de mismo Apple Account, cuenta distinta y offline; mantener disclosure | Solo el entero sincroniza; cuenta/estado corresponde; docs describen exactamente conducta | Medio; entitlement/red/cuentas de prueba; decisión previa de conservar contador permanece |
| AUD-015 | P3 | Home compact/regular | Secciones varias pueden competir visualmente; CTA aparece primero | Estudio de tarea y experimento de agrupación/orden | Primera acción y recuperación mejoran sin pérdida de acceso a Vault/recents/search | Bajo-medio; no quitar paneles por supuesto; mantener layout anterior durante piloto |
| AUD-016 | P3 | EditorBottomToolbar | Siete herramientas icon-only en tira horizontal | Probar agrupación, etiquetas visibles/progresivas o ayuda contextual | Principiante encuentra máscara; recurrente localiza herramienta; no regresión de hit target/AX | Medio; conservar herramientas; decidir con tarea moderada, no gusto visual |
| AUD-017 | P3 | RedactionMode / RedactionPreset | Vocabularios parcialmente se solapan con operaciones distintas | Añadir copy breve en contexto para explicar modo vs política/preset | Participante puede explicar elección y sabe si aplicará filtros OCR/entidades/watermark | Bajo-medio; no fusionar lógica hasta confirmar equivalencia |
| AUD-018 | P3 | ShieldUITests accessibility audit | Gate filtra dos clases de issues | Registrar exclusiones y cobertura alternativa para búsqueda/detección | Cada exclusión tiene caso manual/automático con salida legible | Bajo; falsos positivos justificados, evitar hacer gate flaky |
| AUD-019 | P3 | Xcode project / metadata / ASC | Build local e histórico de ASC divergen | Verificar baseline vigente antes de release | Versión/build y estado guardados con fuente y fecha; ficha externa no se modifica durante auditoría | Bajo; requiere ASC autenticado cuando se autorice |
| AUD-020 | P3 | ROADMAP.md | Elementos ya implementados siguen como futuro | Actualizar matriz de estado local | App Intents, batch/perfiles y superficies iPad marcados con evidencia actual | Bajo; cambios documentales trazables |
| AUD-021 | P3 | SeasonalThemeCoordinator/Home | Campaña tiene estado/calendario complejo, valor no medido; WIP ya la hace opt-in | Mantener única invitación opcional y medir; no añadir campañas hasta evidencia | Base se conserva, rechazar/dismiss persiste, Reduce Motion/audio preference y tarea primaria siguen accesibles | Medio; depender de tiempo/locale y flags; tests de fecha sintética y VoiceOver |

## Categorías de cambio

- **Mantener:** flujo de revisión humana, verificador, OCR local, máscara manual y avanzada, Vault, exportación Free y accesos alternativos.
- **Simplificar/reordenar (solo con evidencia):** Home, toolbar y nomenclatura Mode/Preset.
- **Añadir salvaguarda/recoverability:** crear máscara sin gesto, borrado Vault.
- **Hacer opcional:** apariencia/evento/sonido; el WIP actual ya lo contempla.
- **Eliminar/ocultar:** nada recomendado por esta auditoría. No se propone borrar datos o quitar capacidad avanzada.

