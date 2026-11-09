# Ejecución del plan — fase 02

Fecha: 2026-11-07. El usuario autorizó ejecutar el plan de correcciones y mejoras. Esta nota conserva la auditoría original como fotografía estática y registra el estado real de implementación y validación.

## Cambios aplicados

| ID | Cambio local | Estado y límite |
|---|---|---|
| AUD-001 | Sonido del tema estacional apagado si no existe preferencia; preferencias guardadas respetadas. Prueba para opt-in, opt-out y persistencia. | Implementado; el test de default y persistencia aprobó en el primer runtime. |
| AUD-002 | Facts de privacidad y política EN/ES explican que un entero de cuota se replica por iCloud KVS cuando está disponible y lo separan de la sincronización CloudKit Pro. | Disclosure corregido. No se hizo prueba entre dos cuentas/dispositivos. |
| AUD-003 | El test editor AX5 confirma nombres/tamaños de siete controles y acceso al sheet PDF; versión previa pasó 1/1 en rerun firmado y sin paralelismo. | La falta de `hittable` del primer intento no se reprodujo con el runner corregido. Se amplió después el E2E para generar PDF y exponer estado verificado a tecnologías asistivas; esa versión requiere rerun. VoiceOver manual sigue pendiente. |
| AUD-004 | Se preservó WIP task 247: Base gratuita, elección por evento, preferencias y salida/reversión. La migración ahora usa el reloj inyectado en `refresh(now:timeZone:)`. | `EnhancementFeaturesTests` firmado/sin paralelismo pasó 34/34, incluidas migración y sonido. No se observó reinicio manual ni el fin real de un evento. |
| AUD-005 / AUD-006 | No se alteró la jerarquía visual sin evidencia de descubribilidad. | Requiere estudio moderado con personas nuevas; no se presenta como resuelto. |
| AUD-007 | Política, plan analítico, metadata local y lógica de UI dejan claro que Analytics está apagado por defecto y el control está en Ajustes > Privacidad; se eliminó un estado de consentimiento inicial no usado. | Implementado; test de onboarding que verifica ausencia de prompt aprobó. La versión publicada de la política es desconocida. |
| AUD-008 | El posicionamiento distingue uso individual actual de trabajo futuro de equipos. | Implementado en documentación local. |
| AUD-009 | Metadata histórica marcada como snapshot y alineada con la última referencia local de build. | Local actualizado. ASC sigue sin autenticación (`asc auth status`: error -50); estado externo no verificado. |
| AUD-010 / PRIV-002 | Se clasificó y explicó el dato sincronizado en el disclosure: contador agregado, sin contenido ni ID de documento; se registró la limitación de almacenamiento local no cifrado de KVS documentada por Apple. El usuario decidió conservar solo ese contador en KVS. | Decisión cerrada; validar todavía sincronización en misma cuenta, cambio de cuenta y comportamiento offline. Fuente: https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore |

## Validación de runtime

- Destino principal explícito: iPhone 18 Pro, `CCC41661-BB97-41D2-87E2-D47FC51B1C6B`, iOS 27.2; el test runner lanzó la build recién compilada. El primer comando no desactivó el paralelismo y Xcode ejecutó la suite en un clon del dispositivo.
- Primer intento: 37 casos, 34 aprobados y 3 fallidos con firma desactivada y paralelismo activo. Reruns: 34/34 `EnhancementFeaturesTests` firmados/sin paralelismo y 1/1 del test anterior de editor AX5 firmado/sin paralelismo. Home quick access y onboarding sin gate aprobaron en el primer intento.
- Fallos del primer intento: (1) la máscara principal no fue `hittable`; no se reprodujo en el rerun firmado/sin paralelismo y su causa no está aislada. (2) la migración dependía de `Date()` real; tras cambiar al reloj inyectado, el test pasó en el rerun unitario. (3) `documentStorePersistence` dio `nil`; ignoraba el resultado de escritura y falló con firma desactivada, pero pasó en la suite firmada. Causa ambiental probable, no aislada.
- Después de esos reruns se añadió un E2E AX5 que genera PDF, lee el resultado de verificación y vuelve a Home; esa nueva versión aún requiere ejecución.
- Resultado local: `build/MaskID-AuditPhase02/Logs/Test/Test-Shield-2026.11.07_10-41-50-+0100.xcresult`.
- Revisión estática posterior a la corrección de migración: `git diff --check` y `swiftc -frontend -parse` aprobaron.

## Matriz de simuladores y bloqueos

| Destino | UDID / runtime | Estado de validación |
|---|---|---|
| iPhone 18 Pro | `CCC41661-BB97-41D2-87E2-D47FC51B1C6B`, iOS 27.2 | Primer ciclo y reruns focalizados ejecutados. Reps Fitness con su UI-test runner volvió a ocupar el dispositivo después; el E2E PDF ampliado está en cola. |
| iPhone Duo | `F00C5C84-FA78-4090-A927-DAB7723A891C`, iOS 27.2 | No probado; `personalcare` permanece activo. |
| iPad Pro 13-inch M5 | `6745B14E-02FE-4071-AC91-CE88EE57EB36`, iPadOS 27.2 | No probado; `personalcare` permanece activo. |
| Apple Watch Series 12 | Simuladores 42 mm/46 mm visibles | No hay target/componente watchOS en el proyecto; no se instaló ni se emparejó. |

No se usaron dispositivos alternativos. No se cerraron apps ajenas ni se limpiaron caches/temporales. Sin entrevista/estudio moderado, VoiceOver manual, matriz multi-dispositivo real ni acceso ASC, esos puntos siguen pendientes.

## Siguiente ciclo

1. Esperar y volver a consultar la ocupación del iPhone 18 Pro; ejecutar el nuevo test PDF con `-parallel-testing-enabled NO` y firma de simulador habilitada.
2. Corregir el toolbar solo si el nuevo test reproduce falta de alcance; revisar exportación, verificación y regreso a Home.
3. Ejecutar el flujo de editor en iPhone 18 Pro; luego Duo e iPad solo si cada destino queda libre, en el orden del proyecto.
4. Probar VoiceOver manual y validar accesibilidad con usuarios; no rediseñar Home/editor por inferencia.
5. Validar el contador KVS que el usuario decidió conservar: misma cuenta en dos dispositivos, cambio de cuenta y estado offline; no migrar ni ampliar los datos.
6. Recuperar ASC para confirmar el baseline local sin modificar/publicar nada externo.
