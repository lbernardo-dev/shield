# Gate de calidad inicial para fase 02

## Riesgos vs incidencias reproducidas

| Tema | Estado | Gate recomendado |
|---|---|---|
| Redacción manual de región arbitraria mediante gesto | Riesgo accesible inferido; no reproducido con tecnología asistiva | Demostrar alternativa de entrada con VoiceOver/Voice Control y fixture no detectado |
| Delete en Vault | Código confirma borrado local y borrado remoto programado al elegir; no se reprodujo error accidental | Decidir confirmación/recuperación y probar cancelar/confirmar, red y almacenamiento |
| Protección de exportación | Verifier estático y tests unitarios presentes; flujo completo no aprobado | E2E sintético de importación, revisión manual, exportación y resultado antes de afirmar end-to-end |
| Páginas/datos originales | Persistencia cifrada, transacciones y rollback identificables | Fallo/cancelación no debe perder original ni dejar metadata/assets divergentes |
| KVS de cuota | Solo entero agregado; KVS local sin cifrar según Apple; disclosure local ya actualizado | Confirmar mismo Apple Account, cuenta distinta, offline; no agregar contenido/IDs |
| Navegación sin salida | No hay callejón confirmado; close/back existentes | Ejecutar cancelación y regreso desde captura, inspector, export, paywall, PIN y Settings |
| Accesibilidad | labels/targets y layout escalable presentes; creación libre es gestual; VoiceOver manual pendiente | Completar VoiceOver y Dynamic Type en tarea de documento, no solo test de controles |
| Temas/eventos | WIP opt-in/Base gratis/audio opt-in; runtime/temporada real pendiente | Probar persistencia, fin de ventana, Reduce Motion y que la invitación no desplace la acción crítica |
| Free/Pro/Store | límites y rutas en código/docs; compra/restore/estado ASC no verificados | Probar StoreKit sandbox/config y copy; no hacer compra real ni cambiar ASC en fase auditada |
| Release baseline | build local 1162026102501 vs referencia histórica 1162026102502 | Reconciliar antes de construir/subir; no afirmar estado publicado actual |

## Pruebas que faltan

1. Importar un documento sintético real por Files y terminar el recorrido de protección.
2. Ejecutar el E2E AX5 actualizado y recorrerlo con VoiceOver/Voice Control.
3. Verificar cancelación, archivo inválido, permiso denegado y recuperación sin perder original.
4. Probar eliminación desde Vault, incluida la cola de borrado remoto, online/offline.
5. Probar sincronización KVS y CloudKit en cuentas/dispositivos de prueba separados.
6. Probar iPhone/iPad, orientaciones, tamaño AX5, contraste, transparencia, Reduce Motion, foco y localización extensa.
7. Probar paywall/restore con StoreKit de prueba; no transacción de producción.

## Bloqueos para cerrar la siguiente fase

- No hay P0/P1 de producto reproducidos. La fase 02 puede planificar cambios P2, pero no debería marcar como validada la misión completa hasta cerrar QA-001 y accesibilidad de creación de máscara.
- Antes de cambiar Delete, definir semántica: confirmación cancelable vs recuperación, y compatibilidad con borrado criptográfico remoto.
- El WIP debe revisarse como trabajo local, no asumirse en un binario publicado. Reconciliar el baseline de versión/build con fuente ASC antes de tarea de distribución.
- Se conserva sin modificar el código, tests, metadata externa y cualquier cambio preexistente.

