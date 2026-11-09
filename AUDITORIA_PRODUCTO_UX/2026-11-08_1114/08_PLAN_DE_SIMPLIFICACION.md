# Plan de simplificación sin código

Las acciones son propuestas para una fase posterior; no autorizan implementación ni publicación. Esfuerzo/impacto/riesgo son estimaciones relativas, no mediciones.

## Acciones rápidas y seguras

| ID | Acción | Impacto | Esfuerzo | Riesgo | Validación/reversibilidad |
|---|---|---|---|---|---|
| AUD-019 / REL-001 | Reconciliar build local con registro ASC autenticado antes de preparar release | Medio | Bajo | Bajo | Registrar fuente y fecha; no modificar ficha externa durante auditoría |
| AUD-020 / ROADMAP-001 | Corregir estados “futuro” de funciones ya implementadas | Bajo | Bajo | Bajo | Comparar cada claim con target/código; revertible como documentación |
| AUD-014 / PRIV-003 | Verificar el contador KVS en misma cuenta, cuenta distinta y offline | Medio | Medio | Medio | Solo datos sintéticos; preservar decisión anterior de sincronizar únicamente el contador; sin migración antes de evidencia |

## Ajustes de flujos principales

| ID | Acción | Impacto | Esfuerzo | Riesgo | Validación/reversibilidad |
|---|---|---|---|---|---|
| AUD-013 / QA-001 | Completar test importar → revisión humana → máscara → PDF → resultado del verificador → regreso a Home | Alto | Medio | Medio | Fixture sintético; preservar el original y comprobar cancelación/error. Ejecutar en iPhone/iPad, firma de simulador y sin paralelo |
| AUD-011 / ACC-002 | Diseñar una ruta accesible para crear y ubicar una región arbitraria sin arrastrar | Alto | Medio-alto | Medio | VoiceOver, Voice Control, Switch Control y teclado; conservar gesto actual como alternativa; medir geometría antes/después |
| AUD-012 / DATA-001 | Añadir recuperación o confirmación explícita antes de borrar un documento del Vault | Alto | Bajo-medio | Medio-alto | Cancelar confirma cero cambios; confirmar alinea eliminación local y remota. Reversibilidad depende de política criptográfica/seguridad |

## Racionalización funcional

- **Mantener capacidades:** OCR con revisión humana, máscara arbitraria, verificador, Vault cifrado, búsqueda, importaciones por Files/Share, edición multipágina y exportación estándar Free. No hay fundamento para retirar herramientas de protección.
- **Simplificar exposición, no el catálogo:** estudiar Home (CTA, búsqueda, quick access, categorías, estadísticas, recents, workspace) y editor (siete herramientas, modos e Inspector). Reordenar/agrupar solo tras observar errores y comparar tareas.
- **Aclarar antes de fusionar:** diferenciar el alcance de RedactionMode y RedactionPreset en el momento de uso. Conservar operaciones separadas mientras no se demuestre equivalencia.
- **Hacer opcional:** apariencia/evento y audio; el WIP ya recoge Base, rechazo/reversión y control de efectos. No ampliar campaña sin evidencia de uso/aceptación.
- **Conservar entradas para recurrentes:** batch, providers, widgets y App Intents permanecen disponibles; su baja frecuencia, si la hubiera, no se midió.

## Validación posterior

1. Prueba moderada con participantes nuevos, recurrentes, Free/Pro y al menos una persona usuaria de VoiceOver/control alternativo. No tratar una muestra pequeña como estadística de adopción.
2. Medir por tarea: primera acción encontrada, finalización, máscara omitida o corregida, formato/export entendido, regreso tras cancelación, tiempo por recorrido y errores de navegación.
3. Usar documentos sintéticos y registrar consentimiento. Analítica opcional solo con allowlist, sin OCR, nombre de archivo, ruta, imagen ni comentario libre.
4. Definir aceptación antes de prototipar: máscara arbitraria accesible; copia exportada pasa los checks estructurales; persona distingue el estado de verificación de la revisión de contenido; eliminación puede cancelarse.
5. Probar con toggles/piloto reversible las reorganizaciones de Home; conservar acceso anterior mientras se comparan resultados.

## Dependencias y protección

La ruta de máscara depende de geometría normalizada, zoom y coordenadas de página; no construir una alternativa accesible sobre una transformación distinta. Undo/confirmación de Vault debe coordinarse con cifrado, borrado de claves, CloudKit y la expectativa de eliminación definitiva. Test de cuotas requiere datos aislados y dos dispositivos/cuentas de prueba. Cambios comerciales requieren datos de producto/ASC y no forman parte de esta auditoría.

