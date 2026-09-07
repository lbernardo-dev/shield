# Auditoría Integral Maestra de MaskID — 2026-09-07

Auditoría posterior al build 1.0.7 (107202609062), con revisión de código, producto, UX/UI, seguridad, privacidad, App Review, ASO, capturas y documentación. El informe conserva el orden exigido por el prompt maestro.

**Leyenda de evidencia:** **FACT** = comprobado en repositorio, artefacto o resultado de prueba; **INFERENCE** = conclusión razonada; **HYPOTHESIS** = debe medirse o validarse externamente; **RECOMMENDATION** = acción propuesta. Las afirmaciones de mercado se consideran direccionales cuando no existe una muestra pública suficiente.

# 1. EXECUTIVE SUMMARY

- **Estado general:** 79/100.
- **Madurez técnica:** 82/100.
- **Madurez de producto:** 78/100.
- **UX/UI:** 78/100.
- **ASO:** 65/100.
- **Potencial comercial:** 77/100.
- **Riesgo técnico de la siguiente publicación:** HIGH hasta corregir copy/creativos y validar hardware real; el código compilado no muestra un bloqueo crítico inmediato.
- **Principal oportunidad:** convertir la combinación `on-device OCR + redacción precisa + exportación verificada` en la categoría mental “compartir documentos de identidad sin exponer datos innecesarios”.
- **Principal riesgo:** la ficha y dos creativos prometen “sin nube” y “Secure Enclave” mientras el producto implementa iCloud opcional con paquetes completos y guarda sus claves de datos en Keychain convencional.
- **Principal acción recomendada:** congelar claims de seguridad/privacidad, publicar una metadata corregida en la próxima versión, reemplazar las capturas 6 y 10, y después medir activación y exportación real.

**FACT:** `scripts/app_store_preflight.sh --remote` pasó; `xcodebuild` Debug con `SWIFT_STRICT_CONCURRENCY=complete` compiló; el result bundle local registra 93 pruebas pasadas, 1 omitida y 0 fallidas. **FACT:** el gate UI/UX pasó en iPhone y iPad (12 pruebas por dispositivo, 0 fallos). **FACT:** la revisión enviada de 1.0.7 figura como `WAITING_FOR_REVIEW` en `tasks/details/146-audit-remediation-preflight.md`. **INFERENCE:** el cuello de botella inmediato es de veracidad comercial/compliance y no una reescritura de arquitectura.

# 2. CURRENT PRODUCT UNDERSTANDING

**Qué es:** MaskID (bundle histórico `com.romerodev.shield`, App Store ID `6790398619`) es un espacio de trabajo para proteger datos de identidad antes de compartir documentos, imágenes y PDFs. Captura/importa, detecta texto sensible con Vision/OCR on-device, permite máscaras manuales y semánticas, añade marcas de agua, guarda proyectos y exporta una copia rasterizada que pasa por `ExportVerifier`.

**Superficies comprobadas:**

- iPhone y iPad; targets con iOS 18.0, familia `1,2`, orientación portrait/landscape declarada.
- SwiftUI dominante con wrappers UIKit para cámara, Files y Share Sheet.
- Widgets WidgetKit; App Intents/Siri/Shortcuts (el build genera metadata de App Intents en inglés y español).
- Share Extension con App Group y bandeja cifrada.
- Face ID/PIN para la Bóveda.
- Files picker; importación directa opcional de Google Drive y Dropbox mediante OAuth 2.0 Authorization Code + PKCE.
- iCloud/CloudKit opcional para backup/restauración de paquetes completos no pertenecientes a la Bóveda.

**No comprobado como superficie soportada:** Apple Watch, Mac/Mac Catalyst, Live Activities, Notification Service Extension y una experiencia Spotlight específica. `SUPPORTS_MACCATALYST=NO` y sólo existen targets de app, Share Extension y Widget Extension.

**Stack:** Swift 5.0 configurado, SwiftUI/Combine, `@MainActor` por defecto en la app y extensiones; Keychain/Security, CryptoKit AES-GCM, LocalAuthentication, Vision, CloudKit, MetricKit, OSLog, Firebase Analytics/Crashlytics, RevenueCat 5.81.1, Firebase 12.16.0, Lottie 4.6.1. La persistencia principal es por archivos cifrados y metadatos serializados; no usa SwiftData/Core Data.

# 3. MARKET & USER RESEARCH

**FACT — contexto Apple:** Apple limita nombre y subtítulo a 30 caracteres, descripción a 4.000, keywords a 100 bytes y permite 1–10 screenshots por dispositivo/localización. La referencia vigente está en [App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information), [Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information) y [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/). Las imágenes iPhone 6.9 aceptadas incluyen 1320×2868, exactamente el tamaño de los 20 PNG finales inspeccionados.

**FACT — patrones de mercado observados:**

- La categoría se está fragmentando entre herramientas de redacción local de pago único, freemium con límites, utilidades de privacidad PII y suites PDF grandes.
- La importación desde Files/Photos, PDF multipágina, aplanado, búsqueda/OCR y controles de privacidad son expectativas estándar.
- On-device/local, ausencia de cuenta y eliminación de metadatos son diferenciadores de confianza, no sustitutos de un flujo de revisión comprensible.
- iPad, batch y proveedores cloud aparecen como señales de producto Pro en competidores emergentes.

**Voz real disponible:** no hay en el repositorio una base pública de reseñas de MaskID, ni volumen/rating fiable de la app propia. Las reseñas de competidores son muestras pequeñas y se usan como señales, no como estadística de mercado.

**Pain points:**

- **FACT:** productos comparables muestran que el usuario necesita ocultar datos concretos de DNI, pasaporte, nómina, contrato y PDF sin perder el documento útil.
- **INFERENCE:** el mayor dolor es “¿puedo demostrar que lo oculto no se puede recuperar?”; por eso `ExportVerifier` tiene más valor que una simple brocha.
- **HYPOTHESIS:** el flujo de 10 capturas comunica demasiadas capacidades antes de demostrar una exportación útil; debe medirse el abandono entre importación, primera máscara y primer export.

**Unmet needs:** revisión asistida pero no automática en exceso, explicación de qué se envía a iCloud/proveedores, exportación verificable, buen soporte multipágina y un modo profesional que reduzca errores repetidos.

**Delight factors:** resultado visual limpio, presets para alquiler/empleo/viaje, marcas de agua de propósito único, Bóveda rápida y Share Extension sin cuenta.

**Switching reasons:** mayor confianza local, mejor soporte PDF, menor fricción de exportación, precio de por vida frente a suscripción o mejor batch/iPad.

**Payment drivers:** uso repetido profesional, batch, presets reutilizables, Bóveda y backup/restauración. **Churn drivers probables:** detecciones que requieren demasiada corrección manual, paywall antes del primer valor, fallos con PDFs grandes, claims de privacidad que no coinciden con el comportamiento y precios poco transparentes.

# 4. COMPETITIVE ANALYSIS

| Producto | Evidencia pública | Patrón útil | Brecha frente a MaskID |
|---|---|---|---|
| [Redact Zero](https://apps.apple.com/us/app/redact-zero/id6794126915) | Freemium/Pro, multi página, batch, iPad y proveedores Files/OneDrive/Google Drive/Dropbox; ratings todavía reducidos | Enseña el paquete “redacción + batch + multiplataforma” | MaskID puede diferenciarse con verificación y menor exposición de datos |
| [Redact PDF: Hide the Sensitive](https://apps.apple.com/us/app/redact-pdf-hide-the-sensitive/id6773871327) | Pago único, local, redaction check, PDF image-only | La privacidad simple y el pago único son argumentos fuertes | Menos alcance de workflow, presets y ecosistema |
| [Redactr](https://apps.apple.com/us/app/redactr-pdf-image-privacy/id6782254078) | Scanner inteligente, redacción manual, workspace local | Simplicidad y promesa local | Menor evidencia de verificación/automatización contextual |
| [PrivacyRedactor](https://apps.apple.com/us/app/privacyredactor-ai-pdf-mask/id6760299753) | PII y “offline AI”, iPhone/iPad/Mac | El lenguaje PII/local ya es competitivo | MaskID debe evitar claims técnicos no demostrables y explicar su ventaja verificable |
| [Redact Document & PDF](https://apps.apple.com/us/app/redact-document-pdf/id6761928221?platform=ipad) | OCR/on-device, presets, PDF aplanado, export inicial y suscripción/pack | Presets, onboarding y monetización por valor | MaskID necesita una prueba de conversión y pricing propia |
| [Adobe Acrobat](https://apps.apple.com/us/app/acrobat-reader-pdf-editor/id469337564) | Suite de escala masiva con enorme base de ratings e IAP | Confianza, compatibilidad y amplitud | No competir como editor PDF genérico; ganar en privacidad antes de compartir |

**INFERENCE:** el espacio defendible no es “otro editor PDF con IA”, sino “copias de identidad revisables y verificadas, con procesamiento local por defecto”. **RECOMMENDATION:** posicionar iCloud como opt-in transparente y no como contradicción; el usuario debe entender “procesamiento local por defecto, backup cloud sólo si lo activas”.

# 5. TECHNICAL AUDIT

**Fortalezas comprobadas:** build estricto; no aparecen credenciales demo ni `response_type=token`; exportación y OCR tienen tests de dominio; App Groups y entitlements están definidos; los targets y callbacks son explícitos; la app usa cancelación/async en importación y CloudKit.

**Hallazgos:**

- **TECH-001 — HIGH / M:** el proyecto usa Swift 5.0 y varios singletons `ObservableObject` (`AppState`, `PremiumManager`, Cloud managers). Funciona hoy, pero mezcla estado global, persistencia y side effects; las vistas grandes amplifican el acoplamiento.
- **TECH-002 — MEDIUM / M:** `HomeView.swift` (1.628 líneas), `CaptureOCRServices.swift` (1.572) y `CaptureReviewViews.swift` (1.514) son unidades sobredimensionadas. La deuda es de mantenibilidad y testabilidad, no motivo para reescritura inmediata.
- **TECH-003 — MEDIUM / S:** existen `try?` en persistencia, limpieza temporal, thumbnails, MetricKit y migraciones. Algunos son tolerables para limpieza; en writes críticos pueden ocultar pérdida de datos.
- **TECH-004 — MEDIUM / XS:** hay force unwraps reales en URLs constantes y callbacks (`DirectCloudStorageManager.swift:274-275,305-306,340`, `SharedImportStore.swift:70`), pese a que la auditoría anterior afirmaba cero. Deben eliminarse en las rutas de producción.
- **TECH-005 — LOW / S:** la configuración heredada del proyecto conserva iOS 17.0, mientras los tres targets fijan 18.0. Es una fuente de confusión para CI y futuras extensiones.

**Swift/SwiftUI:** `@MainActor` reduce riesgos de acceso, pero el manager de red/cloud y el estado global deberían separar actor de dominio, transporte y presentación. `Task` y `async/await` son apropiados; se necesita una política explícita de cancelación para OCR, descargas y exportaciones. La aplicación ya usa `@Entry` moderno en algunas dependencias de entorno, pero conserva `foregroundColor` y un `.colorScheme` raíz que se puede modernizar a `.foregroundStyle`/`.preferredColorScheme` cuando no cambie el comportamiento.

# 6. ARCHITECTURE

**Arquitectura actual:** composición SwiftUI con `ContentView` como shell, `AppState` como estado global, `DocumentItem`/`DocumentStore` como dominio/persistencia, `EditorViewModel` para edición, managers singleton para CloudKit/direct cloud/premium y servicios estáticos para OCR/export.

**Lo que escala bien:** pipeline local, tipos Codable, servicios de exportación y tests de seguridad aislables; las extensiones comparten sólo App Group/Keychain necesario. El uso de `DocumentStore` por documento reduce el riesgo de una migración monolítica.

**Lo que no escala bien:** `AppState` conoce UI, localización, archivos, telemetry y WidgetCenter; los managers globales dificultan previews y escenarios simultáneos; `HomeView` y captura mezclan composición con coordinación de operaciones; `CloudSyncManager` serializa el paquete completo dentro de un CKAsset y no dispone de una cola/background transfer dedicada.

**RECOMMENDATION:** evolución incremental: extraer primero `DocumentRepository`, `TelemetryClient` y `CloudSyncRepository` detrás de protocolos; añadir `@Observable` sólo a nuevos modelos; no migrar todo a Observation ni SwiftData en una sola versión. Proteger la compatibilidad de `DocumentItem`, Keychain services, App Group, bundle IDs, IAP IDs y CloudKit record types.

# 7. PERFORMANCE & STABILITY

**FACT:** hay límites y tests para downsampling, 20/50 páginas, exportación streaming, OCR real y pipeline cancelable; `PerformanceBudgetTests` y `ImportPipelineTests` pasan. **FACT:** el gate UI/UX de iPhone y iPad ejecutó 12 pruebas por dispositivo con 0 fallos. **FACT:** los tests no equivalen a medición de p95 en hardware físico.

**Riesgos priorizados:**

- **PERF-001 — HIGH / M:** CloudKit sube un paquete con originales, imágenes de trabajo, texto extraído y máscaras; documentos grandes pueden presionar memoria, tamaño de asset, cuota iCloud y tiempo de foreground. Medir bytes por proyecto, p95 upload/download y cancelación.
- **PERF-002 — MEDIUM / M:** OCR adaptativo de dos pasadas y vistas con imágenes de alta resolución pueden recomputar más de lo necesario. Instrumentar signposts por página y memoria decodificada.
- **PERF-003 — MEDIUM / M:** cold start inicializa Firebase, RevenueCat, MetricKit y managers globales. Medir `process launch → first interactive` en un iPhone de referencia antes de optimizar.
- **STAB-001 — HIGH / S:** `try?` en rutas de almacenamiento puede convertir un error de escritura en estado aparentemente guardado. Mostrar error accionable y registrar sólo el tipo de operación, nunca contenido.
- **STAB-002 — MEDIUM / S:** `CloudSyncManager` requiere que el schema `ShieldDocumentV2` esté desplegado; una instalación con schema ausente recibe error manejable, pero la release debe probar entitlement, cuota, cuenta ausente y reset de iCloud.

**Validación recomendada:** MetricKit para hang/crash/CPU/memoria; OSLog signposts para importar/OCR/export/sync; fixtures de 1, 12, 20 y 50 páginas; prueba física en dispositivo antiguo y actual; comparar p50/p95 y tasa de cancelación.

# 8. SECURITY & PRIVACY

| Control | Estado observado | Juicio |
|---|---|---|
| Cifrado local | AES-GCM en `SecureFileStore`, claves separadas biblioteca/Bóveda en Keychain, `completeFileProtection` | Fuerte base local |
| PIN | Sal + HMAC-SHA256 iterado 60k, comparación constante y lockout | Adecuado como KDF propio, no llamarlo PBKDF2 formal |
| Biometría | `LocalAuthentication` gates UI | No liga la clave de datos a Face ID/Secure Enclave |
| OAuth directo | Authorization Code + PKCE, `state`, refresh y Keychain `AfterFirstUnlockThisDeviceOnly` | Diseño razonable; eliminar force unwraps y probar revocación |
| iCloud | Private CloudKit, paquete completo en CKAsset, opt-in | Apple access control/at-rest; no es E2EE de aplicación |
| Telemetría | allowlist/sanitización local; Firebase Analytics/Crashlytics habilitados al configurar | Coherente con manifest, pero sin elección in-app visible |
| Secretos | IDs públicos de Google/Dropbox y API key pública de RevenueCat en plist | No son client secrets; aun así revisar rotación, scopes y exposición |

**P1 de veracidad:** no hay uso de `SecureEnclave` ni `SecAccessControl` con `biometryAny` para la clave de datos. Apple documenta que el acceso de una clave Keychain puede condicionarse a biometría y que Secure Enclave evita manejar la clave privada en texto plano ([Protecting keys with the Secure Enclave](https://developer.apple.com/documentation/Security/protecting-keys-with-the-secure-enclave), [Accessing Keychain Items with Face ID or Touch ID](https://developer.apple.com/documentation/localauthentication/accessing-keychain-items-with-face-id-or-touch-id)). El copy debe decir “AES-GCM local + Keychain + Face ID/PIN como gate”, no “hardware-encrypted/Secure Enclave”. Implementar esa mejora sólo con migración, fallback y plan de recuperación.

**Privacidad:** `PrivacyInfo.xcprivacy` declara no tracking, dominios vacíos, DeviceID/ProductInteraction/Crash/Performance/PurchaseHistory no vinculados y `UserDefaults` razón `CA92.1`. Apple exige que la app y SDKs declaren correctamente APIs con razones requeridas ([Privacy manifest files](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files?changes=_8), [required reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api?changes=_2_8&language=objc)). Falta una comprobación autenticada de que las respuestas App Privacy publicadas coinciden con el archive final.

**P1 de documentación corregido en esta auditoría:** se alinearon `privacy.html`, `PRIVACY_POLICY_PRODUCT_FACTS.md`, `PRODUCT_POSITIONING.md`, `ARQUITECTURA.md`, SettingsInfo y el draft de App Store con iCloud completo/direct cloud. La metadata versionada 1.0.7 ya enviada no se reescribe para fingir que cambió el binario; la copy final de la sección 19 es para la próxima versión.

# 9. DATA & SYNCHRONIZATION

**Local:** documentos, originales, renders, categorías y telemetría local se almacenan en rutas protegidas; `SecureFileStore` antepone un magic header y cifra con AES-GCM. `DocumentStore` conserva documentos por archivo. La Bóveda usa directorios/clave separados.

**Migración:** `AppState.loadDocuments` y `loadCustomCategories` intentan cifrado y después lectura JSON plana como compatibilidad de migración (`AppState.swift:781-819`). **HYPOTHESIS:** si quedara un archivo plano legado, el fallback lo lee pero no garantiza por sí solo que se elimine y reescriba de inmediato; probar una copia de datos reales y añadir un test que confirme re-cifrado/limpieza.

**iCloud:** al activar Pro y existir cuenta, `CloudSyncManager` reconcilia por `modifiedAt`, maneja tombstones de borrado y usa la base privada. `CloudDocumentPackage` incluye `DocumentItem` y assets de imágenes/source. Esto ofrece restauración en otro dispositivo con la misma cuenta, excepto documentos de Bóveda que permanecen locales.

**Riesgos:** paquetes grandes, cuota, conflictos de edición simultánea, schema CloudKit aún dependiente de despliegue, pérdida de claves iCloud y ausencia de E2EE de aplicación. **RECOMMENDATION:** instrumentar tamaño y estados, definir límite de proyecto, reintento/backoff y prueba de schema antes de prometer “backup”. No cambiar record types ni formato sin migración dual y rollback.

# 10. UX AUDIT

| Flujo | Fricción/confusión | Aha | Riesgo | Acción |
|---|---|---|---|---|
| First launch/onboarding | Permisos y paywall aparecen antes de que el usuario tenga una copia exportada | Primer documento protegido | Medio | Llevar al primer import/capture y explicar permisos justo antes de usarlos |
| Capture/import | Buen abanico Camera/Photos/Files/Cloud, pero “nube” puede contradecir “local” | Documento encuadrado y listo | Medio | Etiquetar Files/direct cloud/iCloud por separado |
| OCR | Sugiere campos, pero el usuario debe revisar todos | Lista de campos con confidence | Alto | Hacer explícito “revisar antes de compartir” y mostrar páginas pendientes |
| Editor | Potente, denso y con muchas herramientas | Máscara aplicada visualmente | Medio | Mantener presets, agrupar herramientas por tarea y conservar undo |
| Export | Verificación es diferencial, pero el resultado debe explicar qué comprobó | “Verified output” | Bajo/medio | Mostrar resumen de verificación y permitir compartir sólo tras éxito |
| Vault | Gate Face ID/PIN claro; copy de hardware es confuso | Biblioteca protegida | Medio | Corregir claim y explicar recovery/clave de dispositivo |
| Batch | Propuesta de valor clara para Pro | Aplicar a varios documentos | Medio | Mostrar progreso, cancelación y elementos fallidos |
| Paywall | Free/Pro existe y core export no está paywalled; precios reales no están evidenciados en repo | Upgrade por capacidad | Medio | QA de productos, trial, restore, cancelación y copy localizada |
| Sync | Desactivar iCloud borra registros remotos según código | Control del usuario | Alto | Confirmación destructiva, estado de quota y texto exacto en settings |

**Time to value objetivo:** primera máscara o export protegido en ≤90 s para un usuario nuevo, sin obligar a crear cuenta ni activar iCloud. **HYPOTHESIS:** debe validarse con funnel real, no inferirse desde UI tests.

# 11. UI / DESIGN SYSTEM

La identidad visual neon azul/cian sobre superficies oscuras es reconocible y consistente con “protección”. La jerarquía de screenshots es fuerte: titular grande, badge, teléfono y una idea por imagen. La app tiene tokens `ShieldTheme`, componentes de botones/cards/estado y layout iPad con sidebar.

**Problemas:** custom tab bar y algunos controles usan valores fijos; abundan `.foregroundColor`; la raíz usa `.colorScheme` donde el estilo preferido del sistema puede ser más apropiado; varias vistas gigantes concentran estados; el detalle de listas puede resultar denso en pantallas pequeñas y Dynamic Type. No se recomienda convertir la app en un clon de HIG: mantener la marca y adaptar sólo patrones de interacción, accesibilidad y legibilidad.

**RECOMMENDATION:** documentar un sistema pequeño: semantic colors, type scale, spacing 4/8/12/16/24, radius 8/12/16, estados loading/error/empty, hit area mínima, reduce-motion y reglas de contraste. Migrar componentes por oportunidad, no por barrido cosmético.

# 12. ACCESSIBILITY

**FACT:** existen identificadores estables (`settings.back`, `editor.export`, `vault.unlock`), pruebas UI para home/onboarding/lock/capture/gallery/editor/OCR/export/batch/vault/settings/paywall en inglés y español, y una prueba de reduced motion/AX5. El gate UI/UX pasó en iPhone y iPad con 12 pruebas por dispositivo y 0 fallos. El result bundle de la suite actual tiene 0 fallos.

**Riesgos a validar físicamente:** custom tab bar, previews de documentos, chips de estilos, canvas/gestos, numer keypad, contraste de cian sobre navy, texto fijo de 11–14 pt, lectura de estado de progreso, VoiceOver en sheets y iPad Split View. `foregroundColor` no implica automáticamente mala accesibilidad, pero debe probarse con Increase Contrast, Bold Text, Dynamic Type XXXL, Voice Control y Reduce Motion.

**RECOMMENDATION:** cada campo detectado debe exponer label/value/hint y estado de confidence; las máscaras deben poder revisarse sin depender sólo del color; los estados de export/sync deben anunciarse; no solicitar rating durante captura/export. Añadir snapshot/AX audits de tamaño grande y un dispositivo físico antes de release.

# 13. PRODUCT & FEATURE AUDIT

| Clasificación | Funciones |
|---|---|
| CORE | Importar/capturar, OCR on-device, detección conservadora, máscara manual, presets de identidad, aplanado/exportación verificada |
| IMPORTANT | PDF multipágina, Vault local, watermarks de propósito, undo/redo, revisión de campos, iPad |
| SUPPORTING | Share Extension, Widgets/App Intents, categorías/búsqueda, estilos, MetricKit, Files provider |
| LOW VALUE | Variantes estacionales de icono si no elevan retención; pulido de microanimación antes de medir activación |
| REDUNDANT / REMOVE CANDIDATE | Cualquier UI o documento que siga hablando de OneDrive/OAuth implícito; no reintroducirlo sin demanda y configuración Entra validada |
| FUTURE | Revisión compartida, reportes de auditoría, export presets versionados, equipo sólo cuando exista evidencia de usuarios profesionales |

**No añadir ahora:** “AI” sin mejora medible, editor PDF genérico, red social, backend propietario para OCR, sincronización automática por defecto, más proveedores cloud por completitud. Cada feature nueva debe mejorar seguridad, tiempo a exportación o retención profesional.

# 14. MONETIZATION

**FACT:** `PremiumManager` define mensual/anual/lifetime con RevenueCat; Free limita documentos procesados a 10 y Pro elimina ese límite; `canExportNow()` devuelve siempre true y el export verificado no se usa como paywall. Batch, estilos premium, presets/automatizaciones y cloud se presentan como palancas Pro.

**Fortalezas:** no bloquear la garantía central de exportación segura; restore purchases existe; productos se cargan desde Offering y se muestran con precio localizado. **Riesgos:** no se ha comprobado aquí el catálogo remoto, trial, precios por territorio, grace period, refund/pending ni textos de suscripción; el precio visto en capturas antiguas puede no coincidir con StoreKit.

**RECOMMENDATION:** probar StoreKit Configuration y sandbox en todos los productos; mantener mensual/anual/lifetime sólo si cada uno tiene una razón clara; mostrar “qué desbloquea Pro”, período, precio y restore antes del pago; no usar dark patterns. Medir `paywall_viewed → purchase_started → purchase_completed → restore_success`, no sólo ingresos.

# 15. ANALYTICS & OBSERVABILITY

**FACT:** `AppState.trackEvent` usa allowlist, sanitiza valores y guarda NDJSON local limitado; Firebase se configura con `Analytics.setAnalyticsCollectionEnabled(true)` y Crashlytics con `setCrashlyticsCollectionEnabled(true)` si existe `GoogleService-Info.plist`; no se observan títulos/OCR/URLs/imagen en el payload permitido.

**Funnel mínimo:** `onboarding_started → onboarding_completed → import_started → import_completed → ocr_started → review_opened → mask_applied → export_started → export_verified → share_started`; ramas `paywall_viewed → purchase/restore`, `cloud_sync_started → success/error`, `error_encountered` con código categórico.

**Métricas:** activation = primer `export_verified` en 24 h; core completion = export verificado/imports; retention = documento protegido en D7/D30; conversion = Pro por cohortes de límite/batch/cloud; churn = cancelación/refund y ausencia de uso posterior. **HYPOTHESIS:** el evento de mayor valor predictor será `export_verified`, no `app_open`.

**Riesgo de consentimiento:** si se requieren opt-out o consentimiento regional, debe existir una decisión de producto y una UI/estado antes de habilitar Analytics; la política debe seguir describiendo la implementación real. No enviar nombres, documentos, OCR, filenames, IDs, PIN state ni texto de error.

# 16. APP STORE REVIEW RISKS

| Severidad | Riesgo | Guideline/razón | Evidencia | Solución |
|---|---|---|---|---|
| 🔴 HIGH | “100% private/no cloud/never leave device” con iCloud Pro opcional | [2.3 Accurate Metadata](https://developer.apple.com/app-store/review/guidelines/) | `metadata/version/1.0.7/*.json` | Copy corregida para siguiente versión; no subir metadata contradictoria |
| 🔴 HIGH | “Hardware-encrypted / Secure Enclave” sin Secure Enclave | 2.3, seguridad y confianza del usuario | screenshots 6, metadata y código | Re-renderizar claims; implementar hardware binding sólo después de migración validada |
| 🟠 MODERATE | Privacy URL/docs históricamente decían index-only y Files-only | 5.1.1/5.1.2 | docs corregidos en este commit | Verificar que la URL pública desplegada contiene la versión corregida |
| 🟠 MODERATE | CloudKit `ShieldDocumentV2` depende de schema desplegado | Funcionalidad incompleta en review | `CloudSyncManager.swift` y task 36 | Probar cuenta/no cuenta, quota, schema y fallback antes de activar |
| 🟠 MODERATE | Direct OAuth real requiere proveedor configurado y redirect correcto | 2.1/2.3; flujo debe funcionar o estar claramente opcional | `DirectCloudStorageManager.swift` | QA real Google/Dropbox, revocación, error y no mostrar OneDrive |
| 🟠 MODERATE | App Privacy publicada vs manifest/SDK | 5.1.2 | Firebase/RevenueCat y manifest | Comparar archive final con respuestas App Store Connect autenticadas |
| 🟢 LOW | No account/demo credentials | Review path simple | App Review notes de task 146 | Mantener review path reproducible |
| 🟢 LOW | IAP con restore y core export no paywalled | 3.1.1 | `PremiumManager` y tests | Validar estados StoreKit remotos |

Apple indica que la metadata debe ser precisa y que puede rechazar/retirar apps por representación engañosa; las [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) son la fuente normativa. El preflight técnico verde no sustituye esa revisión de contenido.

# 17. ASO AUDIT

**Estado actual:** nombres EN/ES válidos y orientados a intención; descripción EN 1.852 caracteres y ES 2.012; 20 PNG finales, 10 por idioma, 1320×2868. El campo de keywords es razonable en longitud, pero EN desperdicia espacio en `shield` y `safe`, y ES no cubre con claridad `censurar/tachar/redacción` según intención local.

**Problemas de conversión:**

- claim “never leave device” contradictorio con iCloud opcional;
- claim Secure Enclave no demostrado;
- descripción empieza bien, pero tarda en llevar al beneficio de exportar una copia revisable;
- 10 screenshots pueden ser una historia completa, pero la secuencia actual introduce “hardware encryption” antes de explicar el output;
- el App Preview final sólo está inventariado en en-US;
- no hay rating/review propio fiable con el que optimizar social proof.

**RECOMMENDATION:** mantener nombre/subtitle por ahora, corregir description/promotional/what’s new y priorizar el test de screenshot 1/2. Apple explica cómo gestionar tamaños y escalado en [Upload app previews and screenshots](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots).

# 18. ASO KEYWORD STRATEGY

| Cluster | EN | ES | Tipo |
|---|---|---|---|
| Problema | privacy, redact, protect, sensitive | privacidad, proteger, ocultar, sensibles | PRIMARY/PROBLEM |
| Objeto | document, passport, pdf, photo | documentos, pasaporte, dni, pdf, fotos | PRIMARY/FEATURE |
| Resultado | blackout, blur, metadata, vault | ofuscar, firma, metadatos, bóveda | SECONDARY |
| Intento profesional | secure sharing, identity protection | compartir seguro, protección identidad | LONG-TAIL en description/creative |
| Marca | MaskID | MaskID | BRAND en nombre, no repetir en keywords |

**Campos propuestos:**

- EN: `privacy,redact,protect,sensitive,document,passport,pdf,photo,vault,offline,metadata,blackout,blur`
- ES: `privacidad,redactar,proteger,sensibles,documentos,pasaporte,dni,pdf,fotos,bóveda,ofuscar,metadatos,firma`

No usar nombres de competidores ni keyword stuffing. Revisar bytes reales con App Store Connect tras la transcreación, no asumir que caracteres acentuados ocupan un byte.

# 19. FINAL APP STORE METADATA

Propuesta corregida para una próxima versión (no afirmar que modifica el binario 1.0.7 que ya está en review).

## English (U.S.)

**APP NAME:** `MaskID: Protect Your Identity`

**SUBTITLE:** `Mask Sensitive Data in Docs`

**PROMOTIONAL TEXT:** `Protect your identity before you share. Mask sensitive details on-device and export a copy you can review.`

**KEYWORDS:** `privacy,redact,protect,sensitive,document,passport,pdf,photo,vault,offline,metadata,blackout,blur`

**DESCRIPTION:**

```text
MaskID helps you protect identity and sensitive data before sharing documents, IDs, passports, photos and PDFs.

PROTECT BEFORE YOU SHARE
Cover private details, add a purpose-limited watermark and keep the useful parts of a document visible.

ON-DEVICE PROCESSING
• Capture or import from Camera, Photos, Files, or an optional direct Google Drive/Dropbox connection.
• OCR and redaction suggestions run on your device and can work without an internet connection.
• Review every suggested field before sharing. Automated recognition can miss sensitive information.

VERIFIED EXPORT
• Flatten masked content into a rasterized PDF or image.
• Verify that hidden text and recoverable layers are not present in the exported copy.
• Remove common GPS, camera and timestamp metadata during export.

USEFUL EVERY DAY
• Protect IDs, passports, licenses, payslips, rental documents, invoices and contracts.
• Apply solid blackout, pixelation, blur and privacy labels.
• Process multipage documents and use reusable presets for common situations.

LOCAL VAULT
• AES-GCM encrypted local Vault protected by Face ID or PIN.
• No account required for core use, with no advertising or cross-app tracking.
• Optional Pro iCloud sync stores complete restorable non-Vault document packages in your private CloudKit database; Vault documents remain local.

MaskID is a privacy tool, not a guarantee that every sensitive region was selected. Review the final copy and recipient before sharing.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://lbernardo-dev.github.io/apps/en/case-studies/shield/privacy/
```

**WHAT’S NEW:** `MaskID 1.0.8 adds a faster protection flow, clearer field review, improved multipage export feedback, and more transparent optional iCloud backup for non-Vault documents. OCR and redaction continue to run on-device.`

**PRIMARY CATEGORY:** Utilities

**SECONDARY CATEGORY:** Productivity

## Español (España)

**APP NAME:** `MaskID: Protege tu Identidad`

**SUBTITLE:** `Enmascara Datos en Documentos`

**PROMOTIONAL TEXT:** `Protege tu identidad antes de compartir. Oculta datos sensibles en el dispositivo y exporta copias que puedes revisar.`

**KEYWORDS:** `privacidad,redactar,proteger,sensibles,documentos,pasaporte,dni,pdf,fotos,bóveda,ofuscar,metadatos,firma`

**DESCRIPTION:**

```text
MaskID te ayuda a proteger tu identidad y tus datos sensibles antes de compartir documentos, DNI, pasaportes, fotografías y PDF.

PROTEGE ANTES DE COMPARTIR
Oculta datos privados, añade una marca de agua con el propósito de la copia y conserva visible la información útil.

PROCESAMIENTO EN EL DISPOSITIVO
• Captura o importa desde Cámara, Fotos, Archivos o una conexión directa opcional con Google Drive/Dropbox.
• El OCR y las sugerencias de redacción se ejecutan en el dispositivo y pueden funcionar sin conexión.
• Revisa cada campo sugerido antes de compartir. El reconocimiento automático puede omitir información sensible.

EXPORTACIÓN VERIFICADA
• Aplana el contenido oculto en un PDF o imagen rasterizada.
• Comprueba que la copia exportada no conserva texto oculto ni capas recuperables.
• Elimina metadatos habituales de GPS, cámara y fecha durante la exportación.

PARA EL DÍA A DÍA
• Protege DNI, pasaportes, carnés, nóminas, alquileres, facturas y contratos.
• Elige bloques sólidos, pixelado, desenfoque y etiquetas de privacidad.
• Procesa documentos multipágina y usa presets reutilizables para situaciones frecuentes.

BÓVEDA LOCAL
• Bóveda local cifrada con AES-GCM y protegida por Face ID o PIN.
• Sin cuenta para las funciones principales, sin publicidad ni seguimiento entre apps.
• La sincronización Pro opcional de iCloud guarda paquetes completos y restaurables de documentos fuera de la Bóveda en tu base privada de CloudKit; los documentos de la Bóveda permanecen locales.

MaskID es una herramienta de privacidad, no una garantía de que se hayan seleccionado todas las zonas sensibles. Revisa la copia final y el destinatario antes de compartir.

Términos de uso (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Política de privacidad: https://lbernardo-dev.github.io/apps/es/casos/shield/privacidad/
```

**WHAT’S NEW:** `MaskID 1.0.8 mejora el flujo de protección, la revisión de campos, el feedback de exportación multipágina y la explicación de la copia opcional de iCloud para documentos fuera de la Bóveda. El OCR y el enmascaramiento siguen ejecutándose en el dispositivo.`

**PRIMARY CATEGORY:** Utilidades

**SECONDARY CATEGORY:** Productividad

**LOCALIZATION STRATEGY:** español de España transcreado (DNI/NIE, nóminas, alquileres, facturas); inglés U.S. con “ID/passport/payslip”; no traducir literalmente el campo de keywords; mantener nombres de proveedores y URLs oficiales.

# 20. SCREENSHOT STRATEGY

**Diagnóstico visual:** los 20 PNG finales usan 1320×2868 portrait, dark navy y una composición de teléfono con interfaz real. Se pueden reutilizar 1–5 y 7–9 tras verificar que el texto visible coincide con la build. Re-renderizar 6 por “HARDWARE ENCRYPTION/Secure Enclave” y 10 por “CERTIFIED PRIVACY” si el badge pretende una certificación formal. El orden debe llevar de problema → beneficio → prueba → control.

| N | Objetivo | Headline/subheadline propuesta | Estado de app | Composición / CTA implícito |
|---|---|---|---|---|
| 1 | Value proposition | **PROTECT YOUR IDENTITY** / Mask sensitive details before sharing | Editor con DNI y máscaras visibles | Titular inmediato, documento grande, foco en “share safely” |
| 2 | Caso universal | **SHARE ONLY WHAT’S NEEDED** / IDs and passports, ready for safer sharing | Pasaporte con MRZ/datos protegidos | Crop al documento; provoca importar el primer ID |
| 3 | Captura | **SCAN & CAPTURE** / Align documents with live guidance | Scanner con guía y botones Camera/Files | Mostrar origen de entrada y baja fricción |
| 4 | Diferenciador | **SMART FIELD SUGGESTIONS** / Review OCR findings on-device | Lista de campos con confidence y Apply | La revisión humana debe verse, no prometer automatismo |
| 5 | Antifraude | **ADD A PURPOSE** / Watermark a copy for one authorized use | Sheet de watermark aplicado | El copy debe conectar con alquiler/trámite |
| 6 | Trust/control | **LOCAL ENCRYPTED VAULT** / Face ID or PIN protects your local Vault | Bóveda desbloqueada con badges AES/local | Eliminar “hardware encryption”; mostrar control local |
| 7 | Retención | **KEEP DOCUMENTS ORGANIZED** / A private workspace for protected copies | Home con categorías, search y progress | Producto recurrente, no sólo utilidad de una vez |
| 8 | Pro batch | **PROTECT IN BATCH** / Apply a reviewed style to multiple pages | Batch Pro con selección y botón Apply | Justifica Pro sin bloquear export básico |
| 9 | Personalización | **CHOOSE YOUR MASK STYLE** / Blackout, pixelate or blur | Galería real de estilos | Comparación visual; CTA implícito “make it readable and safe” |
| 10 | Prueba final | **VERIFY BEFORE YOU SHARE** / Rasterized export with residual-text checks | Export sheet con resultado verificado | Cambiar badge “Certified” por “Verified export” |

**Compatibilidad:** mantener 10 como máximo, usar el set 1320×2868 de iPhone 6.9; aportar iPad específico si la ficha lo necesita; no incluir transparencias/alpha. Apple confirma que se aceptan de 1 a 10 y que los tamaños grandes se escalan a otros dispositivos.

# 21. CREATIVE / IMAGE PLAN

**Assets inspeccionados:** contact sheets EN/ES, icono principal y alternativos; 10 screenshots por idioma. La dirección actual —navy, cyan, tarjetas redondeadas, badges pequeños, UI real— es válida para una marca premium de privacidad.

**Reutilizar:** 1–5, 7–9 como base; conservar fixtures sintéticos, datos ficticios y la consistencia de idioma. **Rehacer:** 6 y 10 desde la fuente de captura/overlay, no retocando texto a mano sobre un PNG comprimido. Revalidar el screenshot ES 7: visualmente aparece una fecha tipo “Sep 6”, que debe salir con locale español o no mostrarse.

**App Preview:** existe `MaskID-Identity-Protection.mov` EN de 17 s, 886×1920, H.264 30 fps con AAC; existen además dos tomas raw de 38,8 s y 56,3 s. No se inspeccionó un final ES equivalente. Storyboard recomendado: 0–3 s problema/ID, 3–7 s scan/import, 7–11 s sugerencias revisables, 11–14 s máscara + watermark, 14–17 s export verified. No usar “AI magic” ni claims de Secure Enclave.

**A/B creativo:** A = beneficio inmediato “protect before sharing”; B = prueba “verified export”. Cambiar una variable por experimento: headline, primer estado de UI o background, no las tres a la vez. Medir product-page view → install → first export.

# 22. ICON REVIEW

El icono principal 1024×1024 es una máscara azul neón dentro de un escudo, con alto contraste sobre fondo negro. **Fortaleza:** comunica protección/identidad y funciona como símbolo de marca. **Riesgo:** ojos, cubos y glow crean detalle fino a tamaño pequeño; el negro puro puede perder presencia en modo claro y las 14 variantes (Ocean/Aurora/seasonal, etc.) pueden diluir reconocimiento.

**RECOMMENDATION:** mantener el azul como default; probar una variante reducida a máscara+escudo sin cubos en 60–120 px; reservar alternativos para Pro/retención, no rotarlos automáticamente. Medir reconocimiento en grid y conversión de ficha, no elegir por preferencia interna.

# 23. LOCALIZATION

**FACT:** existen catálogos EN/ES, URLs localizadas, metadata y tests de integridad de idioma. La UI cubre onboarding, settings, vault, capture y paywall en ambos idiomas.

**Hallazgos:** muchos `extractionState` aparecen como `stale`, aunque el build resuelve valores; mantener el catálogo sincronizado para evitar regresiones. “Privacy”, “Vault”, “CloudKit”, “OCR” y nombres de proveedores deben conservar terminología estable. Validar fechas, separadores, moneda de StoreKit y pluralización con locale real, no strings manuales.

**P2:** la metadata ES usa actualmente “100% privado y sin nube” y “hardware Secure Enclave”; la propuesta de sección 19 transcrea los claims correctamente. Probar textos largos, Dynamic Type, iPad Split View, RTL técnico y screenshots por idioma. No añadir RTL artificialmente a la ficha española: sólo si se incorpora árabe/hebreo.

# 24. CURRENT vs TARGET STATE

| Área | Estado actual | Estado objetivo | Brecha |
|---|---|---|---|
| Arquitectura | SwiftUI + singletons y vistas grandes | Servicios inyectables y módulos por dominio | Extraer repository/telemetry/cloud gradualmente |
| Código | Compila strict concurrency; force unwraps y `try?` | Cero crashes evitables y errores críticos observables | Refactor acotado |
| Rendimiento | Tests de presupuesto, sin p95 físico | P95 medido en hardware y sync acotado | Instrumentación/QA físico |
| Estabilidad | 93 pass/1 skip/0 fail en result bundle | Gate UI iPhone+iPad reproducible | Corregir autodetección de simulador y cerrar gate |
| Seguridad | AES-GCM, Keychain, File Protection | Claims exactos; opción futura de key access control | No prometer Secure Enclave hoy |
| Privacidad | Manifest no tracking; Firebase/RC; iCloud completo opcional | App Privacy pública igual al archive y elección clara | Verificación ASC autenticada |
| UX | Flujo completo, editor potente | Primer export ≤90 s y revisión inequívoca | Funnel/UX testing |
| UI | Marca fuerte, dark-first, tokens | Legible con Dynamic Type/contrast y menor densidad | AX/device QA |
| Producto | Redacción local + Vault + export verificado | Trusted sharing workspace | Posicionamiento y retención |
| Monetización | Free 10 docs, Pro, mensual/anual/lifetime | Paywall transparente y catálogo remoto probado | StoreKit/sandbox QA |
| ASO | 2 locales, 20 screenshots, claims contradictorios | Metadata veraz y story de 10 pantallas | Próximo envío |
| Marketing | URLs y copy base existentes | Prueba de output verificado y casos de uso | App Preview ES/experimentos |
| Analytics | Allowlist y Firebase activo | Funnel, cohorts y consent/opt-out decidido | Eventos/medición |

# 25. SCORECARD

| Dimensión | Current | Target | Principal gap |
|---|---:|---:|---|
| Architecture | 7.5 | 9.0 | Singletons/vistas grandes |
| Code Quality | 7.5 | 8.8 | `try?`/force unwraps |
| Performance | 7.5 | 8.7 | Falta p95 físico y sync grande |
| Stability | 8.0 | 9.0 | Errores de storage/cloud observables |
| Security | 8.0 | 9.0 | Claim Secure Enclave vs implementación |
| Privacy | 7.5 | 9.0 | Copy/ASC/direct cloud alineados |
| Accessibility | 7.5 | 8.8 | QA físico, Dynamic Type y canvas |
| UX | 7.8 | 8.8 | Time-to-value y cloud clarity |
| UI | 8.2 | 9.0 | Densidad/adaptación |
| Product Value | 8.0 | 9.0 | Evidenciar repetición y output |
| Differentiation | 8.0 | 9.0 | Poseer “verified sharing” |
| Monetization | 7.5 | 8.7 | Pricing/trial/territory data |
| ASO | 6.5 | 8.5 | Claims, keywords, creative proof |
| Store Conversion | 6.8 | 8.5 | Sin ratings propias y primer screenshot |
| Analytics | 7.0 | 8.7 | Funnel/cohort/consent |
| Maintainability | 7.0 | 8.5 | God views/AppState |
| Scalability | 6.8 | 8.5 | Cloud payload, modules, provider growth |

# 26. TOP PROBLEMS

1. **P0/P1 — Truth gap in App Store copy:** “100% private/no cloud” contradice iCloud Pro completo.
2. **P1 — Unsupported Secure Enclave/hardware claim:** metadata y screenshot 6 no reflejan el código.
3. **P1 — Public privacy/docs drift:** Files-only/index-only/OneDrive/implicit OAuth aparecían en fuentes internas; corregido en esta auditoría, pendiente verificar despliegue público.
4. **P1 — Full CloudKit asset payload:** riesgo de tamaño, cuota, coste de latencia y recovery complejo.
5. **P1 — Silent critical writes:** `try?` puede ocultar que un documento no se guardó.
6. **P1 — Release UI gate bug:** autodetección tomó “M5” en vez del UUID del iPad.
7. **P2 — Oversized views and global state:** ralentizan mantenimiento y pruebas aisladas.
8. **P2 — OAuth force unwraps / real-provider edge cases:** requieren pruebas de expiración, revocación y callback.
9. **P2 — No evidencia pública propia de ratings/reviews/retention:** ASO y monetización no pueden optimizarse por intuición.
10. **P2 — Screenshot/app-preview gaps:** claims visuales obsoletos y App Preview final sólo documentado en EN.

# 27. TOP OPPORTUNITIES

1. Hacer de `export_verified` la prueba de valor y el mensaje principal.
2. Ofrecer “privacy by default, backup by choice” con explicación iCloud clara.
3. Crear presets de casos (alquiler, empleo, viaje, banking) con nombres locales.
4. Reducir primer flujo a una máscara y export en ≤90 s.
5. Capturar cohortes por caso de uso, no sólo por apertura.
6. Convertir batch/plantillas/backup en Pro justificable sin bloquear seguridad básica.
7. Mejorar el modo iPad para profesionales con proyectos multipágina.
8. Publicar App Preview EN/ES con output real y sin marketing técnico no soportado.
9. Añadir export report opcional que indique páginas revisadas, verifier result y metadata strip.
10. Validar icono y primer screenshot con experimento de conversión antes de rediseñar toda la marca.

# 28. QUICK WINS

- **QW-01:** usar metadata corregida de la sección 19 en la próxima versión (XS, alto impacto, bajo riesgo).
- **QW-02:** re-renderizar screenshots 6/10 con “AES-GCM local / Face ID or PIN” y “Verified export” (S, alto impacto).
- **QW-03:** añadir una confirmación explícita al desactivar iCloud indicando que elimina registros remotos (S, alto impacto).
- **QW-04:** reemplazar force unwraps de URLs constantes por `guard let`/URL estática segura (XS, medio impacto).
- **QW-05:** convertir errores críticos de escritura en estado observable y mensaje recuperable (S, alto impacto).
- **QW-06:** mantener un checklist ASC de manifest, App Privacy, URLs, IAP, screenshot y schema firmado (XS, alto impacto).
- **QW-07:** completar App Preview español y revisar fechas de screenshots (S, medio impacto).

# 29. IMPACT / EFFORT MATRIX

## HIGH IMPACT / LOW EFFORT

Claims metadata/privacy, screenshots 6/10, fix selector de iPad del gate, URL force unwraps, confirmation de borrado iCloud.

## HIGH IMPACT / HIGH EFFORT

Observabilidad de persistencia, CloudKit payload/transfer policy, extracción de repositories, hardware-bound key migration, funnel/experimentation.

## LOW IMPACT / LOW EFFORT

Migrar `.foregroundColor` por componentes, ajustar stale catalogs, polish de badges y nombres de iconos.

## LOW IMPACT / HIGH EFFORT

OneDrive sin demanda, SwiftData rewrite, backend propio de OCR, editor PDF genérico, más variantes decorativas de icono.

# 30. PRIORITIZED BACKLOG

| ID | Prioridad | Área | Acción | Motivo | Impacto | Esfuerzo | Riesgo | Dependencias | Validación | Métrica |
|---|---|---|---|---|---|---|---|---|---|---|
| AUD-001 | P0 | App Review/ASO | Sustituir claims “no cloud/100%” por copy con iCloud opt-in | Evitar metadata engañosa | Alto | XS | Bajo | URLs/policy | `jq` + revisión ASC | 0 claims contradictorios |
| SEC-001 | P0 | Security/Creative | Retirar Secure Enclave/hardware de metadata y screenshots | Código no lo soporta | Alto | S | Bajo | Nuevas capturas | Screenshot/content review | 100% claims trazables |
| PRIV-001 | P1 | Privacy | Verificar URL pública, manifest y App Privacy del archive | 5.1.2/coherencia | Alto | S | Medio | Acceso ASC | Review doctor + revisión autenticada | 0 divergencias |
| DATA-001 | P1 | CloudKit | Medir y limitar paquete completo; probar quota/schema/conflict | Evitar sync frágil | Alto | M | Medio | schema V2 | fixtures 1/20/50 páginas | p95 sync y bytes/proyecto |
| STAB-001 | P1 | Persistence | Propagar errores de writes críticos y reintento seguro | No ocultar pérdida | Alto | M | Medio | repository boundary | tests fault injection | 0 saves silenciosamente fallidos |
| QA-001 | P1 | Release | Cerrar UI gate iPhone+iPad con UUID robusto | Gate reproducible | Medio | XS | Bajo | simuladores | `ui_ux_release_gate.sh test` | 0 invalid devices |
| ASO-001 | P1 | Creative | Re-render 6/10 y export App Preview ES | Conversión/veracidad | Alto | S | Bajo | build final | 10 assets/localización | CTR/install uplift |
| PERF-001 | P1 | Performance | Signposts cold start/OCR/export/cloud + memoria | Optimizar con evidencia | Alto | M | Bajo | MetricKit | Instruments/fixtures | p95 dentro de budgets |
| UX-001 | P1 | UX | Medir y reducir a primer export ≤90 s | Activación | Alto | M | Medio | funnel events | 5–10 usability sessions | activation rate |
| OAUTH-001 | P2 | Security | Eliminar force unwraps, probar expiry/revoke/cancel y direct download | Edge cases reales | Medio | S | Bajo | provider apps | sandbox/manual | 0 crashes/callback errors |
| ARCH-001 | P2 | Architecture | Extraer `DocumentRepository`, `TelemetryClient`, `CloudSyncRepository` | Testabilidad/mantenibilidad | Alto | L | Medio | tests de migración | unit/integration | reducción líneas AppState |
| AX-001 | P2 | Accessibility | Hardware audit VoiceOver, Dynamic Type XXXL, contrast, gestures | Inclusión y review | Alto | M | Bajo | physical devices | AX checklist | 0 critical AX findings |
| MON-001 | P2 | Monetization | Test catálogo, trial, restore, pending, prices/territories | Conversión honesta | Alto | M | Medio | ASC products | StoreKit sandbox | purchase/restore success |
| LOC-001 | P2 | Localization | Corregir fechas ES, stale extraction y long strings | Calidad internacional | Medio | S | Bajo | locale fixtures | UI/screenshot audit | 0 truncations |
| ICON-001 | P3 | Brand | Test icon simplificado en grid | Legibilidad | Medio | S | Bajo | asset variants | blind preference/conversion | recognition/CTR |
| FUT-001 | P3 | Product | Explorar review report/pro workflows con entrevistas | Diferenciación profesional | Medio | M | Medio | research sample | 10 interviews + prototype | willingness-to-pay |

# 31. IMPLEMENTATION ROADMAP

## FASE 0 — ESTABILIZACIÓN (0–1 semana)

Cerrar QW-01/QW-06, re-render claims, validar App Privacy/URLs, cerrar UI gate y no tocar IDs/CloudKit/IAP sin backup/rollback.

## FASE 1 — FUNDAMENTOS (1–3 semanas)

Propagar errores críticos, eliminar force unwraps, instrumentar performance y ejecutar pruebas de migración en copias de datos. Mantener `DocumentItem` y services compatibles.

## FASE 2 — UX/UI (2–5 semanas)

Test de primer documento/export, revisión explícita de sugerencias, estados de sync y Dynamic Type/VoiceOver físico. Refactorizar componentes grandes sólo después de observar fricción.

## FASE 3 — PRODUCTO (4–8 semanas)

Presets transcreados, export report y mejoras multipágina; no añadir proveedores o “AI” sin evidencia.

## FASE 4 — MONETIZACIÓN (paralela, 2–4 semanas)

StoreKit sandbox, pricing por territorio, trial/restore/pending, paywall transparente y eventos de conversión.

## FASE 5 — ASO (antes de cada release)

Metadata de sección 19, keywords por mercado, App Privacy/Support/Marketing/Privacy URL y App Review notes verificadas.

## FASE 6 — CREATIVE OPTIMIZATION (2–4 semanas)

10 screenshots EN/ES con 6/10 corregidas, App Preview ES y A/B del primer mensaje.

## FASE 7 — ANALYTICS (2 semanas)

Funnel de activación/export, cohorts D7/D30, errores categóricos, consent/opt-out decidido y revisión mensual de minimización.

## FASE 8 — EXPERIMENTACIÓN (continuo)

Un experimento por vez: primer screenshot, headline, onboarding o paywall; stop si baja export verificado o aumentan errores.

## FASE 9 — EVOLUCIÓN (trimestre a trimestre)

Review report, workspace profesional y colaboración sólo después de demostrar demanda, retención y modelo de permisos.

# 32. PRODUCT VISION 12-24 MONTHS

**Versión actual:** una utilidad local de redacción y exportación verificada con Bóveda, widgets, Share Extension y sync opcional.

**Versión profesional inmediata:** el producto que comunica exactamente su modelo de privacidad, guía la revisión humana, ofrece una prueba clara de exportación segura, funciona de forma robusta en iPhone/iPad y convierte Pro sin esconder la garantía básica.

**Next major version:** “MaskID Reviewable Sharing”: presets versionados por caso, informe de exportación, historial de verificaciones, tratamiento multipágina más transparente, backup opt-in con límites visibles y controles de equipo sólo si las entrevistas confirman necesidad.

**12–24 meses:** posible workspace de compliance ligero para autónomos, alquileres, RR. HH. y pequeñas operaciones: plantillas, políticas de retención locales, export audit trail y revisión entre personas sin subir OCR/imágenes a un backend propio por defecto. La evolución depende de retención, willingness-to-pay y demanda real; no se debe inventar una red social ni un SaaS de documentos sin evidencia.

# 33. FINAL ACTION PLAN

1. **Corregir claims:** actualizar metadata next-release, screenshots 6/10 y App Preview; dónde: `metadata/`, `.asc/screenshots/aso/final/`, `.asc/app-previews/`; por qué: exactitud 2.3; dependencia: ninguna; riesgo bajo; esfuerzo XS/S; resultado: claims trazables; comprobar con revisión textual/visual.
2. **Cerrar política pública:** desplegar `Docs/legal/privacy.html` actualizado y revisar Support/Marketing/Privacy URLs; por qué: 5.1.2; dependencia: hosting; riesgo medio; esfuerzo S; resultado: iCloud/direct OAuth coherentes; comprobar URL pública y ASC.
3. **Cerrar release gate:** usar selector UUID corregido y ejecutar build/test/UI iPhone+iPad; por qué: evidencia reproducible; dependencia: simuladores; riesgo bajo; esfuerzo XS; resultado: 0 fallos de infraestructura; comprobar artifacts.
4. **QA de hardware:** Camera/Photos/Files, Face ID/PIN, Share Extension, iCloud account/quota/schema, Google/Dropbox OAuth y iPad Split View; por qué: simulador no cubre permisos/secure hardware; riesgo medio; esfuerzo M; comprobar checklist firmado.
5. **Auditar persistencia:** test de error de write, migración plana→cifrada, cancelación y borrado; por qué: evitar pérdida silenciosa; dependencia: fixtures; riesgo medio; esfuerzo M; métrica 0 writes críticos ignorados.
6. **Instrumentar rendimiento:** cold start/OCR/export/sync con signposts, memoria y p95; por qué: decidir con datos; dependencia: hardware; riesgo bajo; esfuerzo M; métrica dentro de budgets.
7. **Validar monetización:** StoreKit/RevenueCat products, trials, restore, pending, territory pricing y paywall; por qué: dinero/Apple Review; riesgo medio; esfuerzo M; comprobar sandbox y eventos.
8. **Medir activación:** implementar funnel y sesiones moderadas; por qué: confirmar ≤90 s al primer export; riesgo bajo; esfuerzo M; métrica `export_verified` D0/D7.
9. **Refactor incremental:** extraer repositories/clientes de `AppState` y dividir Home/Capture sólo cuando haya tests de comportamiento; por qué: mantenibilidad; riesgo medio; esfuerzo L; comprobar migración/feature parity.
10. **Decidir expansión:** sólo iniciar review report/pro workflows, nueva plataforma o proveedor tras datos de demanda, retención y pago; por qué: evitar feature creep; riesgo bajo; esfuerzo M; comprobar research + experimento.

**Orden de ejecución:** 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10. No cambiar bundle IDs, App Groups, Keychain groups, IAP IDs, CloudKit record types ni formato de persistencia sin migración, backup, pruebas y rollback documentados.
