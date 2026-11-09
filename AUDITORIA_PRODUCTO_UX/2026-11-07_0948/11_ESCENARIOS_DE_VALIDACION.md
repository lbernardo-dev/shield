# Escenarios de validación

Estado actualizado tras fase 02: el primer ciclo runtime ejecutó 37 tests (34 aprobados, 3 fallidos); reruns firmados y sin paralelismo pasaron 34/34 unitarios y 1/1 del test editor-control anterior. Esto no significa que 35/35 escenarios de producto estén aprobados: solo corrieron tests focalizados. La migración, persistencia y alcanzabilidad del toolbar pasan en reruns; un nuevo test de exportación PDF completo requiere ejecución. Ver `15_EJECUCION_FASE_02.md`.

| # | Escenario | Estado | Evidencia / siguiente acción |
|---:|---|---|---|
| 1 | Primera apertura: comprender promesa y CTA | PARCIALMENTE APROBADO | `testShortOnboardingDeliversHomeWithoutEarlyPermissionOrPaywall` pasa en iPhone 18 Pro iOS 27.2; confirma destino Home y ausencia de paywall/consentimiento temprano, no comprensión de la promesa con personas. |
| 2 | Tarea principal con documento normal | PARCIAL | El test editor AX5 anterior pasó al repetir firmado/sin paralelismo y llegó al selector PDF. Se amplió después para generar PDF y consultar el status verificado; esa versión sigue pendiente. No se probó importación real desde archivos. |
| 3 | Tarea secundaria relevante: Vault | PENDIENTE | Validar desbloqueo, recuperación y cancelación. |
| 4 | Recurrente retoma con rapidez | PENDIENTE | Medir ruta desde Home/Vault; no cronometrado. |
| 5 | Volver atrás desde pantalla profunda | PENDIENTE | Inspeccionar rutas y preservar estado. |
| 6 | Cancelar modal y conservar estado | PENDIENTE | Probar import/export/settings modal. |
| 7 | Omitir/cerrar onboarding y avisos | REVISADO ESTÁTICAMENTE | Existe skip; verificar transición y persistencia visual. |
| 8 | Entrada errónea y recuperación | PENDIENTE | Fixture corrupto/no compatible; sin pérdida del origen. |
| 9 | Estado vacío y orientación | PENDIENTE | Capturar pantallas vacías y copy. |
| 10 | Permisos denegados/servicio no disponible | PENDIENTE | Probar archivos/fotos y recuperación sin permiso. |
| 11 | Reinicio y persistencia | PARCIAL | `documentStorePersistence` pasó en la suite firmada/sin paralelismo; prueba lectura y borrado en una ejecución, no reinicio real. Audio/tema verifican persistencia mediante suites unitarias. |
| 12 | Actualización/migraciones | CORREGIDO Y APROBADO EN TEST UNITARIO | La comparación contra reloj real durante init se trasladó a `refresh(now:timeZone:)`; el test de consentimiento legacy pasó en la suite firmada de 34/34. No se simuló una actualización instalada de App Store. |
| 13 | Free frente a Premium | REVISADO ESTÁTICAMENTE | Modelo local: límite 10, exportación disponible; verificar copy/estados. |
| 14 | Paywall, promoción, cierre y restore | PENDIENTE | No hacer compra real; usar StoreKit config/sandbox controlado. |
| 15 | Base y tema festivo | PARCIAL | Tests de consentimiento, Free/Pro, reversión y audio pasaron en la suite firmada. No se escuchó el audio manualmente ni se observó una temporada en vivo. |
| 16 | Preferencia al terminar evento | CORREGIDO Y APROBADO EN TESTS SINTÉTICOS | Migración y decisiones por fecha sintética pasaron la suite; no se observó reinicio manual ni el cambio de fecha real al finalizar un evento. |
| 17 | Dynamic Type grande/texto largo | PARCIAL | El test editor AX5 anterior pasó firmado/no paralelo y comprobó herramientas, salida a export y PDF. El nuevo test genera y verifica PDF, aún sin ejecutar; no se midió truncamiento en toda la app. |
| 18 | VoiceOver en flujo central | PENDIENTE | XCTest inspecciona accesibilidad y AX5; no se ejecutó VoiceOver manual ni se verificó navegación por foco. |
| 19 | Reduce Motion/evitar distracción | REVISADO ESTÁTICAMENTE | Wiring estático; validar animación/audio en dispositivo. |
| 20 | Claro/oscuro y traducciones | PARCIAL | UI tests focalizados ES/EN pasan; este ciclo usó el modo oscuro por defecto y no midió truncamiento visual de todos los destinos. |
| 21 | Rotación, multitarea, iPad | PENDIENTE | iPad Pro 13-inch M5 iPadOS 27.2 fue inventariado, pero permanece ocupado por otra app. |
| 22 | Offline/carga lenta/sync | PENDIENTE | CloudKit/KVS existe; conflictos y reintentos no probados. |
| 23 | Integración principal falla | PENDIENTE | OCR/export/RevenueCat; inyectar fallos sin producción. |
| 24 | Acciones irreversibles | PENDIENTE | Verificar confirmaciones/eliminación y posibilidad de recuperar. |
| 25 | Repetir tareas consecutivas | PENDIENTE | Detectar estado/clicks redundantes con ejecución real. |

No hay casos NO APLICA: todos corresponden a capacidades o plataformas declaradas, salvo que futura inspección determine lo contrario. No se infiere aprobación de escenarios a partir de tests que no ejercitan la tarea completa.

