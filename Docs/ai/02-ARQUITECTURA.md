# Arquitectura de IA de MaskID

## Flujo implementado

`CaptureView` / `OCRSheetView` → `OCRService` (Vision y reglas deterministas) → `SmartFieldExtractor` (FoundationModels local si está disponible) → validador de frases contra `TextObservation` → `OCRPageEvidence` (IDs, página, caja y confianza de Vision) → inspector y revisión humana.

### Orden de autoridad

1. OCR Vision produce los caracteres, las cajas y la confianza que sirven de evidencia.
2. Las extracciones y validaciones deterministas completan lo que conocen (MRZ, dígitos de control, IBAN, tarjeta, correo y teléfonos).
3. El modelo solo recibe texto OCR acotado para sugerir seis campos ausentes; no clasifica el documento ni modifica datos ya extraídos.
4. El validador compara tokens ignorando mayúsculas y diacríticos, conserva la puntuación y busca la secuencia completa dentro de una observación. Tras validarla, toma el valor literal desde el rango de origen OCR, así que una grafía devuelta sin acentos nunca sustituye la evidencia original. No permite coincidencias por fragmento, cambio de separador (por ejemplo, reformatear una fecha), corrección, traducción o paráfrasis.
5. Una salida no respaldada se descarta. La confianza aceptada procede de la mejor observación coincidente de Vision; el modelo no estima ni aumenta confianza. Si los seis campos asistidos ya están completos, no se consulta disponibilidad ni cuota ni se inicia una sesión de modelo.
6. La evidencia aceptada se vuelve a asociar por página. La geometría del modelo no existe: las cajas proceden siempre de Vision y las acciones de máscara siguen siendo del usuario.

## Motor, disponibilidad y fallback

- iOS 18–25, dispositivo no elegible, Apple Intelligence desactivado, modelo local no disponible, texto vacío, respuesta inválida o error: continúa el resultado determinista existente sin bloquear la tarea.
- iOS 26+ compatible: `SystemLanguageModel.default` y `LanguageModelSession` con salida guiada `@Generable`. Una solicitud local como máximo por análisis; no se crea sesión por renderizado de vista. La entrada se limita usando `contextSize` reportado por el modelo.
- La instrucción del sistema trata el OCR como datos no confiables y prohíbe seguir instrucciones del documento. El prompt y la salida no se escriben en logs ni telemetría.
- No se conserva un resultado generado separado ni se crean migraciones. Solo se persisten los campos aceptados que tienen evidencia OCR; el esquema existente de documentos se conserva.

## Puerta PCC

El contrato PCC se considera opt-in, nunca fallback automático. La selección de motor es una política pura y comprobable. PCC solo podría elegirse si se cumplen todas estas condiciones: solicitud expresa en la interfaz para ese análisis, consentimiento explícito antes de enviar texto, feature flag activado tras la gestión externa, elegibilidad de cuenta/App ID/perfil verificada, modelo PCC disponible, cuota no agotada y SO/distribución compatibles. Un límite próximo se muestra antes de solicitar y la sugerencia `limitIncreaseSuggestion.show()` sigue siendo decisión del usuario. Si PCC no se habilita, el análisis local o determinista continúa.

La ruta PCC solo se ofrece al pedir explícitamente una segunda pasada cuando quedan campos OCR vacíos; exige consentimiento por análisis y solo envía el texto OCR al modelo de Apple. El SDK 27.2 contiene `PrivateCloudComputeLanguageModel`. Apple asignó el entitlement a la cuenta y la capability del App ID principal está habilitada. El perfil App Store `436DJHXKAZ` para 1.2.0 incluye `com.apple.developer.private-cloud-compute=true` y la IPA de distribución final fue verificada con firma Apple Distribution válida y `get-task-allow=false`. El build usa los flags habilitados para la prueba interna. El Account Holder debe mantener la inscripción al Small Business Program y el umbral de primeras descargas que Apple documenta; la prueba de inferencia real en hardware compatible sigue pendiente. No se altera el entitlement de widget o extensión.

## Concurrencia, límites y pruebas

El enriquecimiento es una única operación async y aprovecha la cancelación de la tarea de importación. El OCR no puede introducir herramientas, consultas a SwiftData, archivos, credenciales ni operaciones de escritura. Un error del framework no incluye datos del documento en su mensaje de usuario o logs. Los mocks prueban selección y validación sin cuota ni red. La evaluación real de FoundationModels debe ser opt-in porque depende de dispositivo, Apple Intelligence y datos sintéticos.

Si una solicitud PCC consentida falla o alcanza cuota y el modelo local sigue disponible, se intenta una sola vez el mismo enriquecimiento local. Si también falla, la captura conserva el resultado determinista. No se repite PCC ni se cambia de proveedor. Apple documenta la recuperación local ante falta de conexión y el manejo de cuotas en [Foundation Models con PCC](https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute).

## Referencias de plataforma

- [Private Cloud Compute](https://developer.apple.com/private-cloud-compute/): requisitos de elegibilidad y distribución.
- [PrivateCloudComputeLanguageModel](https://developer.apple.com/documentation/foundationmodels/privatecloudcomputelanguagemodel): disponibilidad, contexto y cuota.
- [Provisioning with managed capabilities](https://developer.apple.com/help/account/reference/provisioning-with-managed-capabilities/): incorporación de capabilities gestionadas al App ID, Xcode y perfiles.

