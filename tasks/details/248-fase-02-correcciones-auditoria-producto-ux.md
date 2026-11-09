# 248-fase-02-correcciones-auditoria-producto-ux

- Number: 248
- Slug: fase-02-correcciones-auditoria-producto-ux

## Notes

### Ejecución — 2026-11-07

- AUD-001: el sonido Halloween ahora queda apagado en instalaciones sin preferencia. Añadida prueba unitaria de default, opt-in y persistencia opt-out/opt-in.
- AUD-002: añadida a privacy facts y política HTML EN/ES la sincronización del contador numérico por iCloud KVS, separada de paquetes CloudKit Pro. El comportamiento multi-dispositivo sigue sin ejecución real.
- AUD-003: añadida prueba UI del editor→export a Dynamic Type AX5; comprueba nombre y tamaño de las siete herramientas, la acción de exportar, la opción PDF y la salida del sheet. Añadidas aserciones de nombre accesible para chips compactos. Aún debe correrse en simulador y con VoiceOver real.
- AUD-004: los cambios WIP preexistentes de task 247 ya aportan Base gratuita, invitación/decisión por evento y persistencia/rechazo reversible. Se preservaron y se añadieron tests de sonido; la matriz actual no permitió revalidarlos en runtime.
- AUD-005/AUD-006: no se cambió jerarquía visual sin participantes/evidencia de descubribilidad. Se añadieron verificaciones de nombre accesible y hit targets; prueba moderada sigue pendiente.
- AUD-007: corregidas privacy facts, política HTML EN/ES, metadata y plan analítico. Se eliminó el estado de “prompt inicial respondido” sin flujo de producción; el consentimiento forzado permanece como ruta de QA.
- AUD-008: el posicionamiento local ahora identifica el uso actual individual y deja herramientas de equipo como trabajo futuro.
- AUD-009: metadata anterior identificada como snapshot histórico; incorporada la última referencia local ASC (task 245, 2026-10-25) y el conflicto entre build remoto 1162026102502 y build de proyecto 1162026102501. El estado ASC actual queda sin verificar.
- Hallazgo adicional PRIV-002/AUD-010: Apple indica que KVS se almacena sin cifrar en el dispositivo y recomienda no guardar allí datos personales o sensibles. El dato de MaskID es solo un entero de cuota sin contenido documental; se actualizó el disclosure y se dejó una decisión de producto/privacidad pendiente antes de release, sin migrar el enforcement de Free.

### Verificación y bloqueos

- Pasaron `git diff --check`, parse sintáctico Swift de los cinco archivos cambiados, parse JSON de Settings.xcstrings y parse HTML básico de privacy.html.
- En modo restringido, `xcrun simctl list devices available` falló con CoreSimulatorService “connection became invalid”. La lectura elevada de solo lectura posterior sí enumeró los destinos, pero encontró ocupación ajena; no se compiló, instaló ni ejecutó la suite. No se usó otro simulador.
- Con lectura elevada de solo lectura se obtuvo el inventario exacto: iPhone 18 Pro CCC41661-BB97-41D2-87E2-D47FC51B1C6B, Duo F00C5C84-FA78-4090-A927-DAB7723A891C e iPad Pro 13-inch M5 6745B14E-02FE-4071-AC91-CE88EE57EB36, runtime 27.2. Siguen ocupados por repsfitness (iPhone) y personalcare (Duo/iPad), además de testmanagerd. No instalé ni cerré procesos ajenos; la validación sigue en cola.
- Reconciliación ASC y publicación de la política no se realizaron; la autenticación actual no está confirmada. No se hicieron compras, submits ni cambios externos.
- El cierre completo depende de recuperar CoreSimulator para compilar y ejecutar primero en iPhone 18 Pro, después Duo/iPad disponibles; probar VoiceOver manualmente; y recuperar lectura ASC para confirmar el baseline.

### Validación de ejecución — 2026-11-07

- `xcodebuild test` alcanzó iPhone 18 Pro (`CCC41661-BB97-41D2-87E2-D47FC51B1C6B`, iOS 27.2) y completó 37 casos: 34 aprobados, 3 fallidos. El destino usó un clon de XCTest porque no se desactivó el paralelismo.
- Aprobados: test de onboarding sin consentimiento temprano/paywall y quick access de Home; también pasaron los tests de tema/audio excepto la migración indicada abajo.
- Fallo 1: `testEditorToExportControlsRemainAccessibleAtAX5` encuentra nombre y hit target mínimo para las siete herramientas, pero la máscara principal no resulta `hittable`. La aserción ahora adjunta frame y jerarquía accesible para aislar solapamiento/recorte; revisar y corregir la UI si el rerun lo confirma.
- Fallo 2: `seasonalThemeMigrationDistinguishesPersistedConsentFromForcedDefault` detectó que el código de migración comparaba contra `Date()` real antes de que el refresco recibiera el reloj inyectado. Se trasladó la reconciliación de consentimiento manual al `refresh(now:timeZone:)` y se mantiene pendiente su rerun.
- Fallo 3: `documentStorePersistence` obtuvo `nil` tras ignorar el resultado booleano de `saveDocument`. El primer intento usó `CODE_SIGNING_ALLOWED=NO`; se añadió una aserción explícita y se repetirá con firma ad-hoc de simulador para separar limitación del runner de defecto real.
- Tras finalizar, otra sesión lanzó Expirely en el iPhone 18 Pro. El Duo sigue ocupado por `personalcare` y Safari; el iPad por `personalcare`. No se cerró ni se alteró ningún proceso ajeno. Retomar solo tras revalidar disponibilidad y usar `-parallel-testing-enabled NO`.
- `git diff --check` y parse sintáctico Swift volvieron a pasar tras la corrección de migración.
- Decisión AUD-010 confirmada por el usuario: conservar solo el entero agregado de cuota en KVS y el disclosure actualizado. Falta prueba de misma cuenta/dispositivos, cambio de cuenta y modo offline; no hacer una migración.
- Recheck posterior a la decisión: Reps Fitness con su UI-test runner volvió a ocupar el iPhone 18 Pro; Duo/iPad siguen con `personalcare`. Se mantiene la espera en cola.

