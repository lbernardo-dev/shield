# Fase 02 — ejecución del plan de correcciones

**Fecha:** 8 de noviembre de 2026  
**Alcance:** AUD-011–AUD-021 de `12_PLAN_ACCION_EJECUTABLE.md`.  
**Estado:** correcciones y verificaciones locales completadas cuando eran seguras; validaciones con personas, cuentas de prueba y hardware quedan transferidas a fase 03. No se publicó ni se modificó App Store Connect.

## Resultado

Se ejecutaron correcciones concretas para la creación accesible de máscaras, la cancelación de borrado en Bóveda, el recorrido sintético de importación a exportación, la reconciliación de cuota, el texto explicativo de modo/perfil y las acciones finales de exportación con Dynamic Type de accesibilidad. Se corrigieron también dos problemas que reveló la propia automatización: la consulta de documento usaba una etiqueta compuesta, y la prueba de exportación no reconocía el aviso obligatorio de riesgo OCR. El estado base del roadmap se reconcilió con una lectura de ASC.

No hay evidencia para afirmar que la detección OCR cubra todos los documentos ni que la comprensión de modos, la navegación de Home o la accesibilidad por lector de pantalla mejoren para la población general. Se preparó un protocolo de estudio; no se realizaron sesiones.

## Cambios y evidencia por acción

| ID | Resultado | Evidencia y límite |
|---|---|---|
| AUD-011 | Añadido **Añadir máscara**, con nombre, hint y objetivo de 44 pt. Inserta una máscara centrada de geometría normalizada; las acciones de ajuste accesible comienzan y confirman una transacción de historial. | Test unitario comprueba geometría, ajuste, Undo y Redo. El E2E en AX5 comprueba presencia, nombre, solape/posición sobre la previsualización, Undo/Redo y exportación. No se operó VoiceOver ni Voice Control manualmente. |
| AUD-012 | El menú contextual de Bóveda abre una alerta explícita con acciones destructiva y cancelar. Cancelar limpia la selección pendiente; el borrado solo corre en la acción confirmatoria. | XCUITest con documento sintético confirma que cancelar conserva el documento. No se pulsó confirmar: `deleteDocument` programa borrado remoto cuando la sincronización está habilitada. Quedan pendientes el camino positivo y el ciclo online/offline/reintento con cuenta aislada. |
| AUD-013 | E2E ejecuta el pipeline de cola con un PNG sintético: importar, OCR, revisar, abrir editor, crear máscara, Undo/Redo, exportar PDF, verificar y terminar en Home. El test espera la pantalla de procesamiento mediante el ID accesible `capture.processing.message`. | 4 tests UI pasan juntos en iPhone Air/iOS Simulator 27.2; el E2E es uno de ellos. No equivale al selector Files con proveedor externo, compartir a otro servicio ni usar documento real. |
| AUD-014 | `SecureQuotaStore.resolveHighestCount` reconcilia entradas locales, Keychain e iCloud KVS por el máximo no negativo; no se cambió el contrato de sincronizar únicamente el entero agregado. | Test unitario cubre las tres fuentes y casos vacíos/negativos. No se borró ni se reseteó el Keychain/KVS de una cuenta personal. Faltan dos dispositivos, otra cuenta Apple y desconexión/reconexión reales. |
| AUD-015 | No se reordenó Home sin evidencia de tarea. | Protocolo de estudio preparado en `15_GUIA_ESTUDIO_USABILIDAD.md`; 0 participantes y 0 sesiones en esta fase. |
| AUD-016 | No se agrupó ni ocultó la tira de herramientas sin evidencia. | El protocolo incluye descubrimiento de máscara, localización de controles y operación con tecnología asistiva. No se realizaron sesiones. |
| AUD-017 | Añadido texto localizado que distingue la propuesta por propósito del modo de la selección de tipos de datos/opciones del perfil e indica que se revisen las máscaras. | XCUITest confirma que el texto español se expone en el selector. Comprensión y elección correcta no medidas; requieren estudio moderado. |
| AUD-018 | Se mantuvieron excepciones estrechas del gate y se documentaron con salida alternativa. | El gate sigue registrando, pero no falla por detección basada en Vision sin `XCUIElement` accionable; para `hitRegion` del buscador acepta solo issues de búsqueda cubiertos por test AX5. El E2E expone directamente la previsualización y la máscara con nombre, geometría e interacción. Ver `ShieldUITests/ShieldLaunchTests.swift`. |
| AUD-019 | Baseline consultada en App Store Connect, solo lectura. | ASC indicó versión 1.1.6 `READY_FOR_SALE` / `READY_FOR_DISTRIBUTION` y build 1162026102502 `VALID`. El proyecto local aún configura 1162026102501. No se modificó ASC ni el número local; el vínculo del binario remoto con este árbol no está probado. Fuente, comando y fecha en `13_BASELINE_RELEASE_ASO.md`. |
| AUD-020 | Actualizado `ROADMAP.md` para distinguir capacidades presentes, límites observados y trabajo pendiente. | Corrige descripciones sobre App Intents, procesamiento por lotes, superficies iPad, sincronización/privacidad y cifras no medidas. |
| AUD-021 | No se añadieron campañas ni cambios estacionales en esta ejecución. | La suite unitaria seleccionada pasó e incluye pruebas preexistentes de consentimiento, tema base, persistencia, sonido desactivado, calendario y preferencia. El WIP de tema de la tarea 247 se conservó; no se hizo una ronda manual de invitación, lector de pantalla o dispositivo físico. |

## Validación ejecutada

### Hallazgos surgidos al ejecutar las pruebas

- En AX5, Home coloca el buscador fuera del área visible inicial y carga el resultado en una sección perezosa más abajo. La aserción pasó al desplazarse hasta el control y el resultado; no se cambió el orden de Home sin estudio.
- La etiqueta del botón de Bóveda combina título y metadatos. La prueba usa coincidencia por prefijo; la primera confirmación no exponía Cancelar de forma accesible, así que se sustituyó por una alerta con botones explícitos. El test final confirma que cancelar conserva el fixture.
- El test de importación encontró una vista de editor detrás de la pantalla de OCR. Ahora espera a que el procesamiento termine, reconoce el consentimiento de riesgo OCR y mantiene “Listo”/“Compartir” visibles en AX Dynamic Type mediante contenido desplazable y acciones fijas.
- La primera corrida consolidada no arrancó porque Xcode ya no encontraba el ID del simulador iPhone 17e. Se repitió en iPhone Air/iOS Simulator 27.2 y los cuatro casos pasaron en una sola corrida.

Los bundles intermedios de esas iteraciones permanecen en `build/MaskID-AuditPhase02/` para trazabilidad; el resultado consolidado final es `Phase02-UI-All-Pass-Air.xcresult`. No se borraron DerivedData, simuladores ni resultados.

- `xcodebuild test ... -only-testing:ShieldTests/EnhancementFeaturesTests`: **36/36** tests, 0 fallos, 0 omitidos, iPhone 17e / iOS Simulator 27.2. Resultado: `build/MaskID-AuditPhase02/Phase02-Unit-Final.xcresult`.
- `xcodebuild test ... -only-testing:<4 casos UI AUD-011–018>`: **4/4** tests, 0 fallos, 0 omitidos, iPhone Air / iOS Simulator 27.2. Resultado consolidado: `build/MaskID-AuditPhase02/Phase02-UI-All-Pass-Air.xcresult`.
- Los cuatro casos UI fueron: `testHomeSearchAccessibilityExceptionHasDirectCoverageAtAX5`, `testVaultDeleteRequiresConfirmationAndCancelKeepsDocument`, `testPresetExplanationIsReachableInEditor` y `testSyntheticFileImportAccessibleMaskUndoAndVerifiedExportAtAX5`.
- `git diff --check`: pasa.
- Estos son objetivos unitarios y UI seleccionados, no la suite completa de release ni un porcentaje global de cobertura.

### APIs obsoletas y advertencias

La aplicación no contiene llamadas directas a `SKPaymentTransactionState`, `SKPaymentQueue`, `SKProduct` ni `SKPayment`; el flujo de compra productivo usa StoreKit 2 (`StoreKit.Product`). La primera compilación de tests sí emitió una advertencia dentro del header de Apple `StoreKitTest.framework/Headers/SKTestTransaction.h`, cuyo miembro legado declara `SKPaymentTransactionState`. El test importa `StoreKitTest` para `SKTestSession`; no llama a ese enum obsoleto. No se suprimió la advertencia. Apple marca ese enum como deprecated y recomienda `PurchaseResult` para código que procese compras [documentación de Apple](https://developer.apple.com/documentation/storekit/skpaymenttransactionstate?language=objc). No se puede afirmar “build sin warnings” mientras el SDK importe esa declaración.

## Pendientes transferidos

1. Operar creación, selección, movimiento, redimensionado, Undo/Redo y exportación con VoiceOver y Voice Control; repetir en iPad físico o un simulador iPad.
2. Probar el borrado positivo y conservación al cancelar en un fixture aislado, después probar borrado remoto, falta de red y reintento con cuenta de prueba. No usar documentos reales.
3. Validar la cuota con dos dispositivos de la misma cuenta de prueba, una cuenta separada y ciclos offline/online; verificar que solo se replica el agregado.
4. Realizar las sesiones moderadas de 6–8 personas descritas en `15_GUIA_ESTUDIO_USABILIDAD.md`. Mantener las conclusiones exploratorias y anónimas.
5. Revisar invitación estacional, preferencia persistida, tema base y Reduce Motion con personas y tecnología asistiva.

El detalle operativo está en `17_TRASPASO_FASE_03.md` y `FASE_02_HANDOFF.json`. La tarea preparada en `tasks/TASKS.md` es la 251.
