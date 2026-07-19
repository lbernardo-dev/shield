# Shield / GhostDoc — Auditoría profesional y plan de evolución

> Documento de diagnóstico previo a la ejecución. El estado implementado y las puertas restantes están en `RELEASE_READINESS_2026-07-13.md`.

**Fecha:** 13 de julio de 2026  
**Alcance:** producto, arquitectura, importación, captura, OCR, editor, redacción, PDF, persistencia, seguridad, privacidad, rendimiento, accesibilidad, ecosistema Apple, pruebas y preparación de distribución.  
**Estado analizado:** árbol de trabajo local actual, incluida la reconstrucción parcial no confirmada.  
**Naturaleza de esta tarea:** diagnóstico y planificación; no se han corregido los defectos de producto descritos.

## 1. Conclusión ejecutiva

Shield tiene una base con potencial, pero **no está en condiciones de presentarse todavía como una herramienta profesional de redacción segura**. El problema principal ya no es la falta de funciones. Es que el producto mezcla:

- funciones reales y valiosas;
- prototipos que parecen completos en la interfaz pero no lo están;
- transformaciones visuales que se presentan como medidas de privacidad;
- varios pipelines que representan de manera distinta el mismo documento.

La prioridad debe cambiar de “añadir capacidades” a “demostrar que cada exportación es segura, correcta y reproducible”. El producto de referencia no será el que muestre más estilos, sino el que pueda afirmar con evidencia:

> Lo que el usuario marcó se eliminó de la salida, no queda información oculta, todas las páginas fueron procesadas y el resultado fue verificado antes de compartirlo.

### Dictamen

- **Build ordinario:** compila en simulador con Xcode 26.6.
- **Build exigido por el repositorio:** falla con cuatro errores de concurrencia estricta y warnings heredados de rutas antiguas.
- **Pruebas:** no existen targets unitarios, de integración ni UI.
- **Exportación segura:** no demostrada; existe un camino PDF que superpone máscaras sobre el contenido original.
- **Accesibilidad:** prácticamente inexistente.
- **Ecosistema Apple:** limitado a iPhone, vertical, iOS 26; no hay iPad, Mac, Share Extension, Quick Look ni automatización del sistema.
- **Recomendación:** congelar nuevas funciones comerciales hasta cerrar las fases 0–2 de este documento.

## 2. Evaluación actual

| Área | Nota | Lectura |
|---|---:|---|
| Seguridad de la salida | 22/100 | El resultado no se verifica y una ruta PDF puede conservar contenido bajo la máscara. |
| Fiabilidad funcional | 30/100 | Build estricto roto, errores silenciados, operaciones pesadas en el actor principal y cero pruebas. |
| Arquitectura | 38/100 | Se ha empezado a dividir archivos, pero siguen mezclados UI, almacenamiento, OCR, procesamiento y negocio. |
| OCR y automatización | 48/100 | Hay trabajo valioso en MRZ y heurísticas, pero no corpus de evaluación ni evidencia por página/campo. |
| Editor y usabilidad | 42/100 | Buen punto de partida visual; el modelo de gestos, historial y geometría no es todavía consistente. |
| Privacidad en reposo | 62/100 | AES-GCM, Keychain y protección de archivo son una buena base; faltan threat model, migraciones y protección de snapshots. |
| Accesibilidad | 8/100 | No se encontraron modificadores de accesibilidad explícitos y predominan fuentes de tamaño fijo. |
| Ecosistema Apple | 24/100 | Usa frameworks Apple, pero el producto solo se distribuye para iPhone vertical. |
| Calidad y entrega | 10/100 | Sin tests, fixtures, métricas de rendimiento, crash reporting ni puerta de release reproducible. |
| Producto y confianza | 37/100 | La propuesta es buena, pero el lenguaje comercial supera a las garantías técnicas actuales. |

**Madurez global estimada: 32/100.** Es una base avanzada de prototipo, no un producto de referencia listo para usuarios que manejan información sensible.

## 3. Lo que merece conservarse

La reconstrucción no debe empezar desde cero. Estas piezas aportan valor:

- Captura multipágina mediante `VNDocumentCameraViewController`.
- Importación desde Fotos y Archivos con acceso security-scoped.
- Representación normalizada de rectángulos de redacción.
- OCR local, análisis MRZ, validadores por país y datos de confianza por campo.
- Corrección de perspectiva de cuatro puntos y filtros mediante Core Image.
- Cifrado AES-GCM de documentos e imágenes, clave en Keychain y `FileProtectionType.complete`.
- Persistencia de redacciones por página.
- StoreKit 2, localización ES/EN y privacy manifest incluido en el target.
- Primer esfuerzo de extracción de servicios y subviews desde archivos monolíticos.

Estas fortalezas deben convertirse en servicios probables y probados, no desecharse.

## 4. Hallazgos que bloquean un lanzamiento profesional

### P0.1 — Una máscara PDF puede ser solo una superposición

`ExportEngine` intenta primero reutilizar el PDF original cuando no hay ajustes ni blur (`ExportServices.swift:15-18`). Ese camino dibuja la página original en un nuevo contexto y después pinta rectángulos (`ExportServices.swift:356-404`). No existe una fase que elimine objetos de texto, imágenes, formularios, anotaciones, capas, adjuntos o contenido oculto dentro de las zonas.

El resultado puede verse censurado y, aun así, conservar información recuperable. Esto contradice el requisito central del producto.

**Acción inmediata:** desactivar esa optimización. Hasta disponer de un motor PDF probado, exportar una versión rasterizada y aplanada, con resolución controlada, seguida de verificación adversarial.

### P0.2 — La “puntuación de privacidad” no mide seguridad

El score comienza en 40, añade 15 puntos afirmando que los metadatos siempre se eliminan y valora cualquier máscara por igual (`ExportSheetView.swift:177-190`). Una máscara semitransparente o blur suma lo mismo que un bloque opaco. El usuario puede recibir “seguro para compartir” sin que el archivo haya pasado una prueba.

**Acción inmediata:** retirar el score actual. Sustituirlo por un `VerificationReport` basado en comprobaciones reales y resultados explicables.

### P0.3 — Blur, píxel y semitransparencia se confunden con redacción segura

El producto ofrece estilos visuales cuya finalidad es obfuscación, no eliminación. Además, `pixelate` y `secure` se ven de una forma en el editor pero se exportan como un bloque negro por el `default` de `drawRedactionCG`. Esta discrepancia rompe la expectativa del usuario.

**Modelo recomendado:**

- `secureRedaction`: salida opaca, contenido eliminado/aplanado y verificado.
- `visualObfuscation`: blur, píxel o semitransparencia, con aviso explícito “no apto para protección fuerte”.
- La exportación “verificada” solo acepta redacciones seguras.

### P0.4 — No existe ninguna prueba de regresión ni corpus de seguridad

No hay targets `ShieldTests` ni `ShieldUITests`. No se prueba:

- que el texto redactado no sea seleccionable ni extraíble;
- que no aparezca al copiar/pegar, buscar o reabrir el PDF;
- que no permanezca en metadatos, anotaciones, formularios, capas o adjuntos;
- que las coordenadas sigan alineadas tras rotar, recortar o corregir perspectiva;
- que todas las páginas se exporten;
- que una cancelación o fallo parcial no corrompa un proyecto.

Sin estas pruebas, cualquier cambio visual puede reintroducir una fuga.

### P0.5 — El build de calidad está roto

`make build`, que activa warnings como errores y concurrencia estricta, falla en:

- `SecureFileStore.shared`;
- `LanguageManager.shared`;
- `AppSessionCoordinator.lastActivityWrite`;
- `WidthKey.defaultValue`.

El build ordinario compila porque no aplica la misma política. También aparecen warnings de artefactos generados bajo una ruta anterior del repositorio.

**Criterio profesional:** solo cuenta como verde el mismo comando que ejecutará CI y el release.

### P0.6 — Las afirmaciones de privacidad de iCloud no coinciden con el código

La documentación dice que los archivos no salen del dispositivo, pero CloudKit sube título, tipo, categoría, fecha, estado de bóveda y otros metadatos (`CloudSyncManager.swift:69-89`). El título puede ser el nombre completo extraído por OCR. El “pull” se descarga y se descarta; las eliminaciones locales no invocan `deleteRemoteDocument`, por lo que no existe sincronización bidireccional real.

**Acción:** desactivar esta función en producción hasta definir consentimiento, minimización, cifrado extremo a extremo, política de borrado y reconciliación real.

## 5. Hallazgos de alta prioridad

### 5.1 Importación y memoria

- Fotos permite selección ilimitada (`selectionLimit = 0`) y carga todos los `UIImage` completos en paralelo (`CaptureImportViews.swift:206-280`). Un lote moderado de fotos de 12–48 MP puede agotar memoria.
- Archivos solo permite una selección (`allowsMultipleSelection = false`), por lo que el batch anunciado no existe para PDFs.
- Un PDF se carga entero con `Data(contentsOf:)` y todas sus páginas se rasterizan antes de avanzar (`CaptureView.swift:549-569`).
- Se guardan todas las páginas, luego se hace OCR sobre todas, manteniendo simultáneamente imágenes originales, normalizadas, ajustadas y renderizadas.
- Si una página falla al guardarse, el flujo continúa con un documento parcial. Los fallos se convierten frecuentemente en `nil` o se silencian con `try?`.

**Corrección:** pipeline streaming, límites explícitos, downsampling por destino, operaciones por página, progreso, cancelación, limpieza transaccional y errores tipados.

### 5.2 Trabajo pesado en el actor principal

Las operaciones se lanzan desde `Task {}` creado por vistas y, en varios casos, conservan aislamiento del actor principal:

- cifrado y JPEG de cada página;
- render de todas las páginas PDF;
- OCR síncrono con `VNImageRequestHandler.perform`;
- filtros finales de todas las páginas;
- exportación y composición a gran resolución.

El uso de `Task` no garantiza ejecución en background. Esto explica bloqueos, interfaz congelada y cancelaciones poco fiables.

**Corrección:** actores/servicios dedicados (`ImportPipeline`, `OCRPipeline`, `RenderPipeline`, `DocumentStore`) con valores `Sendable`, límites de concurrencia y actualizaciones UI únicamente en `MainActor`.

### 5.3 El editor descifra y procesa imágenes dentro de `body`

`PhotoDocumentView.body` carga, descifra, decodifica y aplica Core Image (`DocumentRenderers.swift:127-132`). `EditorView.canvasSize` vuelve a cargar la imagen. Durante drag/resize cambian propiedades publicadas continuamente, así que el coste puede repetirse en el hot path del gesto.

**Corrección:** caché de páginas y previews, carga asíncrona, estado de render inmutable por revisión y ninguna E/S ni transformación dentro de `body`.

### 5.4 OCR multipágina incompleto para redacción precisa

El texto se guarda por página, pero los bounding boxes solo se persisten para la página 0. El editor mantiene un único `DocumentFields` global. Al aplicar automatización en otra página puede reutilizar geometría de la primera o no disponer de evidencia.

El modelo debe ser:

```text
DocumentProject
  └─ Page[]
      ├─ source asset
      ├─ transform
      ├─ OCR observations[] (texto, quad, confianza, revisión)
      ├─ detected entities[] (tipo, valor normalizado, evidencia)
      └─ redactions[]
```

### 5.5 Presets basados en geometría aproximada

Los modos alquiler, viaje, empleo, legal, salud y banca filtran rectángulos por posición y tamaño. Esto no expresa el significado del campo y cambia entre países, caras de un documento, fotografías y páginas.

**Corrección:** una plantilla debe declarar entidades requeridas/permitidas y condiciones, no coordenadas mágicas. Cada sugerencia debe apuntar a observaciones OCR concretas y mostrar confianza.

### 5.6 Reajuste destructivo y geometría inconsistente

El reajuste del editor carga archivos, reaplica el ajuste persistido, sobrescribe los originales y no limpia `imageAdjustment` (`EditorView.swift:117-164`). Después el render y export pueden volver a aplicar el mismo ajuste. Tampoco transforma las máscaras existentes al nuevo espacio.

**Corrección:** conservar siempre un asset original inmutable y una cadena de transformaciones no destructiva. Las redacciones deben vivir en coordenadas del documento canónico y transformarse con una matriz explícita.

### 5.7 Historial parcial

Undo/redo solo registra arrays de máscaras de la página actual. Mover/redimensionar persiste en cada frame sin crear un comando de historial; los ajustes de imagen, propagaciones multipágina, watermark y OCR quedan fuera.

**Corrección:** historial por comandos (`add`, `remove`, `move`, `resize`, `style`, `transform`, `propagate`, `template`) con coalescing de gestos y alcance documental.

### 5.8 Conectores cloud de demostración

Los OAuth usan client IDs placeholder y flujo implícito (`response_type=token`), pero después el token ni siquiera se usa para navegar o descargar: se abre el picker nativo de Archivos. Existe además un `preconditionFailure` si no se obtiene ventana (`ExternalStorageManager.swift:325-327`).

**Corrección:** eliminar los botones de conexión directa y usar exclusivamente `UIDocumentPickerViewController`, que ya integra proveedores instalados. Solo construir integraciones API propias si existe un caso de uso que Archivos no cubra, con Authorization Code + PKCE, configuración segura y tests.

### 5.9 Errores no accionables

Muchos fallos se reducen a `nil`, cierran el flujo o muestran una cadena genérica. No hay distinción entre:

- archivo corrupto o protegido con contraseña;
- formato no soportado;
- falta de memoria/espacio;
- permiso revocado;
- OCR no disponible;
- página concreta fallida;
- exportación incompleta.

Un producto profesional debe preservar el trabajo y ofrecer reintento, omisión de página, diagnóstico y limpieza segura.

## 6. Seguridad y privacidad

### Aciertos

- AES-GCM para archivos.
- Clave simétrica almacenada en Keychain como `ThisDeviceOnly`.
- protección de archivo `.complete`.
- PIN en Keychain y backoff persistente.
- OCR y Foundation Models se ejecutan on-device.
- privacy manifest incluido en recursos.

### Riesgos y mejoras

1. **Threat model ausente.** Definir adversarios: pérdida del dispositivo, app snapshot, backup, malware con sandbox comprometido, PDF receptor hostil y usuario que comparte por error.
2. **PIN débilmente derivado.** Se guarda SHA-256 directo de seis dígitos. Usar un secreto aleatorio protegido por Keychain/biometría; el PIN debe controlar acceso, no convertirse en una clave fácil de atacar offline.
3. **Bóveda principalmente lógica.** Biblioteca y bóveda usan el mismo almacén criptográfico y clave. Clarificar qué garantía adicional ofrece la bóveda o separar claves/acceso.
4. **Snapshots del app switcher.** Añadir cubierta de privacidad al pasar a inactive/background y política frente a screen capture/mirroring.
5. **Temporales de exportación.** Aplicar protección, nombre no identificable, borrado programado y limpieza al siguiente arranque.
6. **Telemetría local sin cifrar.** Serializar escrituras, minimizar propiedades, proteger el archivo y ofrecer borrado/exportación transparente.
7. **Cloud opt-in explícito.** Mostrar exactamente qué sale del dispositivo; no usar títulos derivados de OCR en claro.
8. **Documentos con contraseña.** Detectar PDFs bloqueados y solicitar la contraseña sin persistirla.
9. **Informe verificable.** Guardar hash de entrada/salida, versión del motor, páginas verificadas y pruebas realizadas, sin incluir PII.

## 7. Accesibilidad y diseño adaptable

No se encontraron usos explícitos de `accessibilityLabel`, `accessibilityHint`, `accessibilityValue`, acciones personalizadas o agrupación. La mayoría del texto usa `.font(.system(size: ...))`, lo que limita Dynamic Type. El canvas depende de drag y pequeños handles.

Trabajo requerido:

- etiquetas, valores, hints y estado seleccionado para todos los iconos y controles;
- orden de foco y headings semánticos;
- alternativa al drag: seleccionar máscara y ajustar posición/tamaño con controles accesibles;
- handles de al menos 44×44 pt reales, no solo visuales;
- Dynamic Type hasta tamaños de accesibilidad;
- Reduce Motion, Increase Contrast, Differentiate Without Color y Voice Control;
- pruebas con VoiceOver, Switch Control, teclado y tamaños extremos;
- no depender solo de color para riesgo, selección o confianza.

## 8. Ecosistema Apple: estado y dirección

El target actual declara iOS 26, `TARGETED_DEVICE_FAMILY = 1`, portrait y sin Mac Catalyst. Eso excluye gran parte del objetivo original.

### Secuencia recomendada

1. **iPhone + iPad universal:** navegación adaptable, landscape, teclado, trackpad, drag & drop, multiwindow y `NavigationSplitView` en iPad.
2. **Share Extension:** recibir una imagen/PDF desde Fotos, Archivos, Mail o Safari y devolver una copia redactada.
3. **Action/App Intent:** “Redactar con Shield”, abrir último proyecto, escanear y ejecutar plantilla confirmada. Nunca exportar PII sin revisión explícita.
4. **Mac Catalyst o macOS:** editor de precisión con sidebar, inspector, menús, shortcuts, undo manager y drop de archivos.
5. **Quick Look y Files:** previews seguras y nombres de exportación consistentes.
6. **iCloud opcional:** solo después de definir cifrado, reconciliación, borrado y consentimiento.

Vision ofrece una mejora útil: `RecognizeDocumentsRequest` permite estructura de palabras, líneas, párrafos, tablas, listas y códigos. Debe alimentar el modelo de evidencia por página, no sustituir la validación de entidades. `DataScannerViewController` puede ofrecer detección en vivo, pero el scanner multipágina de VisionKit sigue siendo la base correcta para documentos.

## 9. Arquitectura objetivo

```text
AppShell
├─ Session & PrivacyShield
├─ LibraryFeature
├─ ImportFeature
├─ ScanReviewFeature
├─ EditorFeature
├─ ExportFeature
└─ Settings / Entitlements

Domain
├─ DocumentProject
├─ DocumentPage
├─ PageTransform
├─ OCRObservation / SensitiveEntity
├─ RedactionMark / RedactionPolicy
└─ VerificationReport

Services (protocolos inyectables)
├─ DocumentStore actor
├─ AssetStore actor
├─ ImportPipeline actor
├─ ImagePipeline actor
├─ OCRPipeline actor
├─ DetectionPipeline actor
├─ SecureExportPipeline actor
├─ ExportVerifier actor
├─ EntitlementProvider
└─ EventSink
```

### Principios obligatorios

- Asset original inmutable; transforms y redacciones no destructivos.
- Una única geometría canónica con transformaciones explícitas.
- Estado UI separado del modelo persistido.
- Servicios sin dependencia de SwiftUI.
- Errores tipados; no usar `nil` como diagnóstico.
- Escrituras transaccionales y migraciones versionadas.
- Cada pipeline acepta cancelación y reporta progreso.
- Las funciones premium no cambian el nivel de seguridad de la salida; la seguridad base no se bloquea tras un paywall.
- Toda afirmación “seguro” procede del verificador, nunca de una heurística visual.

## 10. Flujo profesional propuesto

1. **Importar** desde cámara, Fotos, Archivos, Share Extension o URL explícita.
2. **Preparar** páginas: rotar, recortar, perspectiva, ordenar, eliminar y añadir.
3. **Analizar** con OCR por página y detección de entidades con evidencia/confianza.
4. **Revisar sugerencias** en una lista clara: aplicar, ignorar, corregir o marcar falso positivo.
5. **Editar** manualmente con zoom, pan, selección, handles, teclado y undo completo.
6. **Aplicar política/plantilla** semántica y revisar excepciones.
7. **Preflight**: páginas sin revisar, entidades sensibles sin cubrir, estilos no seguros, baja confianza y calidad insuficiente.
8. **Exportar copia** sin alterar el original.
9. **Verificar salida**: reabrir, extraer texto, inspeccionar metadatos/objetos, OCR visual residual y comprobar páginas/zonas.
10. **Compartir** junto a un resumen verificable comprensible.

## 11. Roadmap de ejecución

### Fase 0 — Contención y baseline (1 semana)

Objetivo: dejar de acumular incertidumbre.

- Hacer verde `make build` con concurrencia estricta.
- Crear targets de test y CI reproducible.
- Congelar/ocultar Cloud OAuth y el score de privacidad.
- Desactivar el camino PDF por superposición.
- Añadir fixtures mínimos: PDF con texto, imagen, multipágina, rotado, protegido y corrupto.
- Registrar métricas baseline de memoria, tiempo y tamaño.

**Salida:** build y tests verdes; ninguna ruta conocida exporta una superposición insegura.

### Fase 1 — Núcleo de redacción segura (2–3 semanas)

- Implementar `SecureExportPipeline` rasterizado y determinista.
- Implementar `ExportVerifier` y `VerificationReport`.
- Separar redacción segura de obfuscación visual.
- Limpiar metadatos, anotaciones, formularios, adjuntos, acciones y temporales.
- Tests adversariales por zona y por página.

**Salida:** 100% de fixtures sensibles no recuperables mediante extracción, búsqueda, copiar/pegar ni OCR residual por encima del umbral definido.

### Fase 2 — Modelo documental y editor estable (3–4 semanas)

- Introducir `DocumentProject`/`DocumentPage` versionados.
- Original inmutable + transforms no destructivos.
- OCR y redacciones por página.
- Historial de comandos completo y autosave transaccional.
- Caché de preview; eliminar E/S y Core Image de `body`.
- Zoom/pan/selección/resize coherentes y test de matrices geométricas.

**Salida:** reabrir un proyecto reproduce exactamente la misma vista y exportación; undo/redo cubre todas las operaciones.

### Fase 3 — Importación, OCR y automatización certera (3–4 semanas)

- Pipeline streaming con límites y cancelación.
- Downsampling y thumbnails progresivos.
- `RecognizeDocumentsRequest` donde esté disponible y fallback probado.
- Entidades semánticas con evidencia, normalización y validadores.
- Corpus anonimizado/sintético por idioma, país y calidad.
- Plantillas semánticas configurables.

**Salida:** precision/recall medidos por entidad; cero aplicación silenciosa de plantillas sin evidencia.

### Fase 4 — UX profesional y accesibilidad (2–3 semanas)

- Rediseñar Home alrededor de Importar → Revisar → Exportar.
- Preflight central y mensajes accionables.
- iPad/landscape/teclado/trackpad.
- VoiceOver, Dynamic Type, Reduce Motion y contraste.
- Estados de carga, cancelación, retry y recuperación.

**Salida:** auditoría de accesibilidad sin bloqueantes y pruebas UI de los flujos críticos.

### Fase 5 — Integración Apple (3–5 semanas)

- Share Extension con App Group seguro.
- App Intents/Shortcuts con confirmación.
- drag & drop, multiwindow y Quick Look.
- evaluar Mac Catalyst tras estabilizar iPad.
- decidir iCloud: implementar correctamente o retirarlo.

**Salida:** importar desde Share Sheet y devolver una copia verificada funciona en dispositivo real.

### Fase 6 — Producto, monetización y lanzamiento (2–3 semanas)

- Unificar marca Shield/GhostDoc, bundle copy, URLs legales y soporte.
- Revisar Free/Pro: la exportación segura básica debe ser siempre segura.
- Paywall contextual sin bloquear recuperación ni privacidad.
- App Store metadata, capturas, privacy nutrition labels y revisión legal.
- TestFlight por cohortes y monitorización de crash/hang sin PII.

**Salida:** checklist de release, 0 P0/P1 abiertos, crash-free >99,8%, export success >99,5% y memoria dentro del presupuesto.

## 12. Métricas de referencia

| Métrica | Objetivo de lanzamiento |
|---|---:|
| Fugas detectadas en corpus de exportación | 0 |
| Páginas omitidas silenciosamente | 0 |
| Exportaciones verificadas correctamente | 100% |
| Éxito de exportación | >99,5% |
| Sesiones sin crash | >99,8% |
| Sesiones sin hang | >99,5% |
| Memoria pico, PDF 20 páginas A4 | presupuesto definido y validado en dispositivo base |
| Tiempo a primera preview | <1 s para imagen normal; progresivo para PDF |
| Tiempo importación→salida segura, documento 1 página | <30 s mediana |
| Precision de entidades críticas | >95% en corpus soportado |
| Cobertura de tests del dominio/pipelines | >80% en lógica crítica; 100% de casos de seguridad definidos |
| Bloqueantes VoiceOver/Dynamic Type | 0 |

## 13. Decisiones de producto recomendadas

1. **Promesa central:** “Redacción verificada en el dispositivo”.
2. **No vender estilos como seguridad.** Estética y seguridad deben separarse.
3. **La automatización propone; el usuario confirma.** La confianza baja nunca se aplica en silencio.
4. **Free siempre exporta de forma segura.** Pro monetiza batch, plantillas, productividad, iPad/Mac, workflows y personalización; no la ausencia de fugas.
5. **Archivos antes que OAuth propio.** Menos superficie de fallo, mejor integración y mayor confianza.
6. **Original protegido, copia explícita.** Nunca sobrescribir el único original del usuario.
7. **Explicabilidad visible.** Cada sugerencia debe indicar qué detectó, dónde y con qué confianza.

## 14. Definition of Done del producto profesional

Shield solo debería declararse listo cuando:

- `make agent-verify` es verde en local y CI;
- hay pruebas con documentos reales/sintéticos y PDFs hostiles;
- toda exportación “verificada” genera un informe real;
- no se conserva texto/imagen sensible bajo una máscara;
- los estilos no seguros están claramente diferenciados;
- ninguna página se omite sin consentimiento;
- todas las operaciones críticas son cancelables y recuperables;
- la app protege su snapshot y temporales;
- VoiceOver y Dynamic Type permiten completar el flujo;
- iPhone e iPad están soportados correctamente;
- claims, privacy manifest, App Privacy y comportamiento Cloud coinciden;
- no hay placeholders, `preconditionFailure` alcanzables ni features simuladas en producción;
- no quedan P0/P1 abiertos.

## 15. Fuentes de referencia

- Apple, `RecognizeDocumentsRequest`: https://developer.apple.com/documentation/vision/recognizedocumentsrequest
- Apple, `VNDocumentCameraViewController`: https://developer.apple.com/documentation/visionkit/vndocumentcameraviewcontroller
- Apple, `DataScannerViewController`: https://developer.apple.com/documentation/visionkit/datascannerviewcontroller
- Apple, `PDFMarkupType.redact`: https://developer.apple.com/documentation/pdfkit/pdfmarkuptype/redact
- Apple, App Extensions: https://developer.apple.com/documentation/uikit/app-extensions
- Apple, Privacy manifests y Required Reason APIs: https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api
- Apple, Keychain y Secure Enclave: https://developer.apple.com/documentation/security/using-the-keychain-to-manage-user-secrets y https://developer.apple.com/documentation/security/protecting-keys-with-the-secure-enclave
- Adobe, redacción y sanitización como benchmark funcional: https://helpx.adobe.com/acrobat/desktop/protect-documents/redact-pdfs/redacting-sanitizing.html

## 16. Resultado esperado

La evolución propuesta reduce deliberadamente el número de promesas visibles al principio para aumentar la confianza real. Tras las fases 0–2, Shield tendrá un núcleo defendible. Tras las fases 3–5, podrá diferenciarse por precisión, velocidad e integración Apple. Solo entonces tiene sentido escalar monetización y posicionarlo como herramienta profesional de referencia.
