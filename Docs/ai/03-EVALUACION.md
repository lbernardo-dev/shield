# Evaluación de la mejora OCR inteligente

Fecha: 21 de noviembre de 2026.

## Criterios definidos antes de medir

La salida del modelo es una propuesta de OCR, no una fuente de datos. Umbrales de aceptación:

- 0 valores aceptados si no aparecen como secuencia contigua y completa en una observación OCR de origen.
- 0 cambios de puntuación/separadores, traducciones, paráfrasis o coincidencias parciales de palabra.
- 0 sobrescrituras de un campo determinista ya existente.
- 0 confianza mayor que la confianza máxima de la observación que respalda el valor.
- 0 cajas o máscaras originadas por el modelo.
- 0 solicitudes PCC si falta cualquiera de las puertas: acción expresa, consentimiento por análisis, flag, elegibilidad verificada, disponibilidad o cuota.
- Cancelar el análisis no debe guardar un resultado tardío; un estado no disponible conserva el flujo OCR determinista.

## Harness sintético

`OCREvidenceTests.foundationModelCandidatesRequireExactEvidence()` contiene 32 escenarios sintéticos y verificables (dentro del rango requerido de 20–40): nombres latinos y chinos, diacríticos, identificadores, fechas, direcciones, nacionalidad, campos ausentes, valores truncados, variantes de separadores y contenido hostil dentro de OCR. El test suministra respuestas estructuradas falsas directamente al validador. **No ejecuta ni puntúa la calidad de un modelo Foundation Models real.**

Se inspeccionó el SDK iOS 27.2 instalado y no contiene un framework `Evaluations`; se usa XCTest/Swift Testing como harness determinista.

Pruebas adicionales comprueban que una sugerencia aprobada conserve el ID de observación, página 0, geometría y confianza Vision; que una salida con acentos omitidos persista el texto OCR literal; que un resultado determinista tenga prioridad; que `applying` rechace una propuesta aun si un llamador le pasa un campo ya ocupado; que cada página solo use su propio OCR; que documentos con los seis campos cubiertos no consulten modelo ni cuota; y que el router mantenga el motor local por defecto o se degrade a extracción determinista si falta una puerta.

El criterio para la matriz sintética es exactitud del validador, no precisión de reconocimiento del LLM. El umbral esperado es 32/32 decisiones correctas y las pruebas automáticas comparan cada respuesta con su resultado esperado.

## Validación ejecutada

| Validación | Resultado |
|---|---|
| `xcodebuild -list -project Shield.xcodeproj` | Correcto; esquema `Shield` y targets disponibles. |
| Build `Shield` para iOS Simulator 27.2, arquitectura arm64 | Correcto con firma normal, exit code 0. También se generó el archive Release 1.2.0 (`10112026091404`). |
| Suite `ShieldTests` completa, firmada, iPhone 18 Pro Simulator iOS 27.2 | 182 pasadas, 1 omitida, 0 fallidas (183 totales). La primera corrida sin firma había fallado en seis pruebas de almacenamiento/seguridad; la ejecución normal firmada pasó todas. |
| Suite `SecurityPrivacyTests`, firmada | 13/13 pasadas; confirma que el error `errSecMissingEntitlement` de la primera corrida se debía al modo de build sin firma. |
| Suite `OCREvidenceTests`, firmada | 22/22 pasadas, 0 fallos. El harness valida 32 salidas sintéticas adversariales y escenarios de integridad/procedencia; no ejecuta un modelo real. |
| Archive y exportación | Archive Release correcto. IPA exportada para App Store Connect; `asc ipa-info --verify-signature` reporta firma válida, y `codesign --verify --deep --strict` pasa para la app y extensiones. La entitlements del perfil y de la app exportada contienen PCC; distribución con `get-task-allow=false`. |
| UI | Las pruebas focalizadas `testEmptyEditorDetectionsOpenManualOCRFlow` y `testOCRAccessibilityInEnglishAndSpanish` pasaron 2/2 en el simulador firmado. Una corrida aislada general anterior ejecutó 3 de 65 casos: 1 pasó y 2 fallaron (una señal `term`; el runner reportó que el simulador ya no existía). No se atribuye causa al producto sin diagnóstico adicional; la suite UI completa sigue pendiente. |
| Foundation Models / PCC real | No se hizo una inferencia real: el simulador prueba router, gates y validador, pero no acredita disponibilidad/calidad en un dispositivo elegible. |
| TestFlight / prueba física | La IPA se subió para procesamiento de Apple; falta confirmar que quede procesada, asociarla al grupo interno y validar la interacción PCC en un dispositivo compatible. |

La primera suite completa se ejecutó con `CODE_SIGNING_ALLOWED=NO`, lo que produjo errores de Keychain y guardado de archivos en el simulador. Al repetir con firma normal pasó la suite completa (182/183, 1 omitida). Para UI, intentos anteriores reportaron `testmanagerd` ausente y un problema de espacio; el intento aislado más reciente ejecutó solo tres casos y terminó cuando el simulador se retiró. La causa de la caída de `testAnalyticsConsentIsExplicitAndOffByDefault()` no está determinada. Los 65 casos UI no se consideran validados.

## Comparación de motores y límites de la medición

- **Determinista:** sigue siendo la fuente de verdad para extracción con formato conocido, reglas, MRZ y entidades con verificadores. Da cobertura predecible sin modelo.
- **Foundation Models local:** queda como mejora opcional para campos vacíos de formatos variables. Las reglas sintéticas prueban que una salida no grounded se descarta; no hay medición de tasa de campos correctos, latencia, memoria o batería de un modelo real.
- **PCC:** pruebas puras de enrutamiento cubren solicitud explícita, consentimiento, flag, elegibilidad, disponibilidad, cuota agotada y fallback. La capability administrada está configurada para el App ID y el perfil/IPA App Store incluye PCC. No hubo inferencia ni consumo de cuota real: resta probar en dispositivo compatible y confirmar que la cuenta mantiene las condiciones de elegibilidad de Apple.

No se dispone de corpus anonimizado revisado ni de un dispositivo compatible y opt-in que permita comparar local frente a PCC. No se inventan porcentajes de calidad, ahorro de tiempo, latencia o recursos. Antes de activar PCC se necesita una evaluación opt-in con documentos sintéticos, aprobados y variados, sin registrar prompts ni texto personal.
