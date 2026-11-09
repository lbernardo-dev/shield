# Escenarios de validación

Estados usados: APROBADO CON PRUEBA solo cuando existe resultado identificable; FALLIDO REPRODUCIDO requiere reproducción; REVISADO ESTÁTICAMENTE significa inspección de código/documentación sin interacción real; PENDIENTE significa falta de prueba suficiente; NO APLICA solo si la capacidad no existe. Los resultados históricos no son ejecuciones de esta auditoría.

| # | Escenario | Estado | Evidencia/condición/siguiente paso |
|---:|---|---|---|
| 1 | Primera apertura: entender propósito y encontrar CTA | APROBADO CON PRUEBA (parcial) | Test histórico onboarding llega a Home sin gate inicial. Comprensión y tiempo no medidos |
| 2 | Tarea principal con documento normal | PENDIENTE | No se ejecutó importación real → revisión → máscara → exportación verificada |
| 3 | Tarea secundaria: Vault | REVISADO ESTÁTICAMENTE | Auth, lock, lista, export y acciones detectados; desbloqueo/recuperación no probado |
| 4 | Usuario recurrente retoma rápido | PENDIENTE | No se midió camino desde Home, recents o Vault |
| 5 | Volver atrás desde pantalla profunda | REVISADO ESTÁTICAMENTE | Back/close existen en stacks/modales; conservación de estado pendiente |
| 6 | Cancelar modal y conservar estado | PENDIENTE | No se probó cancelación de import/export/settings ni reanudación |
| 7 | Cerrar onboarding/avisos | REVISADO ESTÁTICAMENTE | Skip/back en onboarding; test histórico confirma ruta sin paywall/prompt, no cada dismiss |
| 8 | Archivo erróneo y recuperación | PENDIENTE | Import pipeline tiene errores tipados; fixture inválido y conservación del origen no se ejecutaron |
| 9 | Estado vacío y orientación | REVISADO ESTÁTICAMENTE | Hay vistas vacías de biblioteca/Vault con CTA; copy visual no observado |
| 10 | Permiso denegado/servicio no disponible | PENDIENTE | Cámara, Files, Photos/providers; alternativas y recuperación no probadas |
| 11 | Reinicio y persistencia | PENDIENTE | Tests históricos de DocumentStore/prefs pasaron en rerun; no hubo reinicio real de app en esta ejecución |
| 12 | Actualización/migración | APROBADO CON PRUEBA (unitario histórico) | Test de migración de preferencia de evento con reloj inyectado pasó en suite firmada 34/34; no se instaló actualización real |
| 13 | Free frente a Premium | REVISADO ESTÁTICAMENTE | Posicionamiento y gates muestran límite 10 y exportación estándar; contraste UX/paywall runtime pendiente |
| 14 | Paywall/promo/cierre/restore | PENDIENTE | Cierre/restore en código; no se probó compra, fallo de StoreKit ni estado de ASC |
| 15 | Apariencia Base y tema evento | APROBADO CON PRUEBA (resolutor unitario histórico) | Tests de ask-first, Free/Pro y preferencia pasaron; visual runtime del evento no observado |
| 16 | Persistencia de decisión al acabar evento | REVISADO ESTÁTICAMENTE | Resolver tiene decisión por ocurrencia/ventana; tests con reloj sintético, no se observó fecha/reinicio real |
| 17 | Dynamic Type grande/texto largo | PENDIENTE | Test AX5 anterior probó controles/select PDF; nuevo E2E de export PDF sigue pendiente; truncamiento global no medido |
| 18 | VoiceOver en tarea central | PENDIENTE | Labels y semantics en código; recorrido manual VoiceOver no ejecutado |
| 19 | Reduce Motion/evitar efectos | REVISADO ESTÁTICAMENTE | Wiring de Reduce Motion y control decorativo presentes; respuesta real no probada |
| 20 | Claro/oscuro y traducciones | REVISADO ESTÁTICAMENTE | ES/EN en recursos/tests; lectura visual y cadenas largas en todas las rutas no probadas |
| 21 | Rotación, multitarea, iPad | PENDIENTE | Target universal y orientación declarados; simulador iPad enumerado, ninguna interacción actual |
| 22 | Offline/carga lenta/conflictos | PENDIENTE | CloudKit/KVS/RevenueCat/providers existen; retry y reconciliación no probados |
| 23 | Fallo en integración principal | PENDIENTE | No se inyectaron fallos OCR, Files, RevenueCat, CloudKit ni verifier |
| 24 | Acción irreversible | REVISADO ESTÁTICAMENTE | Delete Vault agenda borrado local/remoto sin confirmación/undo visible en esa ruta; no se borró documento |
| 25 | Repetición consecutiva | PENDIENTE | No se ejecutaron tareas repetidas para observar estados/taps superfluos |

## Resumen descriptivo

- En este turno: 0 escenarios de producto ejecutados, 25 revisados según su evidencia; algunos están clasificados como revisión estática o prueba histórica parcial.
- Evidencia histórica que sí se conserva: 34/34 unit tests de EnhancementFeaturesTests y 1/1 test anterior de editor en reruns firmados/sin paralelismo; un primer ciclo tuvo 34/37 aprobados. Ninguno equivale a 25 escenarios completos aprobados.
- Pendientes críticos de cierre de experiencia: tarea de documento completa, VoiceOver/control alternativo para máscara libre, cancelación/error, borrado y recuperación del Vault, iPad, offline y compra/restore.

