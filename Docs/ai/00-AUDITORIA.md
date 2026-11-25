# Auditoría de IA de MaskID

Fecha de auditoría: 21 de noviembre de 2026.

## Alcance y línea base

Se revisaron README, esquema y configuración de Xcode, targets y deployment targets, OCR, captura/importación, editor, persistencia de documentos, exportación segura, privacidad, StoreKit/RevenueCat, CloudKit, extensiones y pruebas existentes. El proyecto contiene cambios locales previos en archivos de publicación, localización, documentación y tareas; se conservaron.

La app de usuario es MaskID (`com.romerodev.shield`), una herramienta local para importar o escanear documentos, detectar texto, revisar y ajustar máscaras, y exportar una copia protegida. El flujo principal es importar/capturar → OCR → revisar y ajustar máscaras → verificar la exportación → compartir.

- Xcode 27.2, SDK iOS 27.2; targets de app, widgets, extensión de compartir, pruebas unitarias y UI.
- App, widget y Share Extension tienen deployment target iOS 18.0; familia universal iPhone/iPad. No hay targets de macOS, watchOS, tvOS ni Live Activities.
- Swift está configurado en modo 5.0. SwiftUI/UIKit, Vision, almacenamiento local cifrado propio, StoreKit 2 y RevenueCat, CloudKit opcional, Firebase con controles existentes de consentimiento/diagnóstico, App Intents, Share Extension y widget.
- El producto ya usa FoundationModels desde iOS 26.0 cuando `SystemLanguageModel.default.isAvailable`; en versiones/dispositivos incompatibles sigue usando OCR y reglas deterministas.
- La app no usa SwiftData/Core Data como almacén principal. La fuente de verdad son sus modelos y almacenamiento local cifrado existentes. El contenido de Vault permanece local; la sincronización CloudKit es opcional y limitada a documentos fuera de Vault.

La línea de comandos `xcodebuild -list -project Shield.xcodeproj` resolvió paquetes y mostró los cinco targets de producto/pruebas esperados. El simulador iOS 27.2 muestra un warning de Xcode (`invalidDigitCount(91016)`) al leer el build 24B91016s, pero llegó a ejecutar las pruebas. La línea base previa no pudo terminar antes de los cambios; la validación final firmada se registra en `03-EVALUACION.md` e incluye el pase de `ShieldTests` (182 pasadas, 1 omitida, 0 fallidas).

## Inventario de datos y límites

La app puede procesar imágenes/PDF, nombre, dirección, fecha de nacimiento, nacionalidad, números de documento, texto MRZ, correo, teléfono, IBAN, tarjeta, códigos de barras, fotos de rostros, anotaciones del usuario y geometría de máscaras. Es información de identidad, financiera, sanitaria o familiar según el documento. OCR, máscaras y exportación se ejecutan en el dispositivo. Las declaraciones actuales excluyen documento, imágenes y texto OCR de Analytics.

Vision conserva texto, confianza y cajas normalizadas. `OCRService` hace extracción estructurada y reglas de formato/checksum para categorías conocidas. `OCRPageEvidence` vincula entidades a observaciones reales. El usuario revisa la propuesta y la exportación rasterizada se inspecciona con `ExportVerifier`; esas comprobaciones no prueban que se hayan seleccionado todos los datos sensibles.

### Inteligencia existente y hallazgos

`SmartFieldExtractor` ya declara una salida estructurada `@Generable` y llama a `LanguageModelSession` con `SystemLanguageModel` desde iOS 26. Se invoca durante importación y al releer OCR en el inspector. Por tanto, la oportunidad no es añadir un chat ni una segunda integración de modelo.

El flujo previo presenta riesgos concretos que justifican endurecerlo:

1. El prompt pide valores, pero no aclara que el OCR sea contenido no confiable ni prohíbe seguir instrucciones encontradas dentro del documento.
2. Las salidas no se comparan con observaciones OCR antes de guardarse. El código rellena campos vacíos incluso cuando el modelo inventa, normaliza o reinterpreta un valor.
3. A los valores del modelo se asigna una confianza constante de 0,68–0,72 en lugar de la confianza de Vision que respalda el texto.
4. El tipo documental también puede venir del modelo aunque el clasificador determinista sea la fuente de verdad.
5. En importación multipágina se envía un prefijo de texto agregado y se mezclan campos escogidos globalmente con geometría OCR por página. Esa combinación puede mostrar un valor sin evidencia espacial correspondiente.
6. La extracción asistida no informa un número de resultados validados y no tiene pruebas unitarias específicas de grounding, entradas adversariales ni fallback.

### Fricciones y oportunidad

Las reglas y OCR son adecuados para IDs conocidos, MRZ, teléfonos, correos e identificadores con validación formal. Sus huecos son documentos no estándar, idiomas y distribución de campos variables, donde la posición y el significado dependen del contexto. La inferencia puede reconocer un nombre o una dirección que las reglas no extraigan, pero un modelo no puede ser autoridad para crear datos, corregirlos o certificar que un documento quedó anonimizado.

La mejora debe limitarse a sugerir campos que ya aparezcan literalmente en una observación OCR real, mantener su página y caja, y asignar la confianza observada por Vision. Las reglas deterministas siguen primero y el modelo solo completa huecos. Un candidato no validado se descarta; el usuario conserva la revisión manual y la exportación verificada.

## PCC y compatibilidad

FoundationModels local está disponible desde iOS 26.0 en dispositivos compatibles con Apple Intelligence. El deployment target de iOS 18 se conserva y la ruta sin Foundation Models queda activa. El SDK instalado declara `PrivateCloudComputeLanguageModel` desde iOS 27.0, `contextSize`, disponibilidad, estados de cuota, aviso de límite próximo y sugerencia gestionada por el sistema.

El correo de Apple Developer Relations confirma la asignación del entitlement PCC a la cuenta. El 20 de noviembre de 2026, con Developer Portal autenticado, se habilitó `PRIVATE_CLOUD_COMPUTE` para el App ID principal `com.romerodev.shield` (`7BX79RLCY5`); ASC también la lista entre las capabilities del App ID. `Shield/Shield.entitlements` declara el entitlement. Para la build 1.2.0 se creó el perfil App Store `436DJHXKAZ`, que contiene `com.apple.developer.private-cloud-compute = true` y `get-task-allow=false`; la IPA exportada se verificó con firma Apple Distribution válida. La concesión de Apple y la firma PCC son evidencia del acceso gestionado para esta prueba interna. Apple también exige mantener la inscripción al Small Business Program y menos de dos millones de primeras descargas en el conjunto de apps de la cuenta. El informe Analytics consultado solo aporta datos de MaskID y no prueba el agregado de cuenta ni la inscripción; esas condiciones siguen bajo control del Account Holder. Los flags PCC están habilitados para la build TestFlight, con bloqueos de uso por acción expresa, consentimiento por análisis, disponibilidad, cuota y versión compatible. Como OCR puede contener identidad y datos potencialmente financieros, sanitarios o familiares, no hay uso automático. El prompt de PCC solo contiene texto OCR; imagen y archivo original permanecen en el dispositivo.

El sistema de compras vigente y los niveles/derechos no intervienen en OCR inteligente; no se añade paywall ni cuota comercial para modelos.

