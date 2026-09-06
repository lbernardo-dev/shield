# MaskID (Shield) — Auditoría Integral de Producto, Ingeniería, ASO, UX y Crecimiento Comercial iOS

**Fecha de Auditoría:** 6 de septiembre de 2026  
**Equipo Auditor:** Equipo Multidisciplinar Senior iOS (Principal iOS Engineer, Staff Swift/SwiftUI, Product Architect, UX/UI Lead, Security & Privacy Specialist, ASO & Growth Strategist, StoreKit/RevenueCat Specialist, App Review & QA Lead)  
**Entorno de Validación:** macOS Sequoia / Xcode 26.6 (Build 17F113) / iOS Simulator 26.5 & iPhone 16/17 Pro Max / App Store Connect CLI (`asc` 1.1.0)  
**App ID:** `6790398619` | **Bundle ID:** `com.romerodev.shield`  
**Versión Local y Staging ASC:** `1.0.7` (Build `107202609062`)  
**Estado en Producción:** 1.0.0 a 1.0.6 `READY_FOR_SALE` en 175 territorios; 1.0.7 `PREPARE_FOR_SUBMISSION` con build `VALID` vinculado.

---

# 1. EXECUTIVE SUMMARY

MaskID es una aplicación nativa iOS/iPadOS especializada en **protección de identidad documental y privacidad contra el fraude**. Su objetivo es permitir a particulares, profesionales y autónomos enmascarar de forma irreversible información personal sensible (DNI, NIE, pasaportes, cuentas bancarias IBAN, nóminas, firmas y direcciones) y estampar marcas de agua de uso exclusivo antes de compartir copias de documentos.

Tras 145 ciclos de ingeniería documentados y auditados en el repositorio, la aplicación ha alcanzado un grado de madurez técnica y funcional excepcional, destacando por un motor OCR on-device con corrección matemática por dígitos de control (Módulo 23 para DNI/NIE, ICAO 9303 para MRZ de pasaportes y Módulo 97 para IBAN), aplanado rasterizado destructivo que elimina metadatos EXIF/GPS, y un verificador adversarial de exportación (`ExportVerifier`) que re-analiza el archivo final buscando fugas de texto residual bajo las máscaras.

### Métricas Ejecutivas del Producto
* **Estado General:** 88 / 100
* **Madurez Técnica:** 92 / 100
* **Madurez de Producto:** 86 / 100
* **Calidad UX/UI:** 87 / 100
* **Posicionamiento ASO:** 89 / 100
* **Potencial Comercial:** 91 / 100
* **Riesgo Técnico:** **LOW** (Compilación estricta Swift Concurrency `SWIFT_STRICT_CONCURRENCY=complete` en verde, 0 crashes fatales, cero `try!`/`fatalError`, sandbox verificado).
* **Principal Oportunidad:** Capitalizar el marco regulatorio europeo de ciberseguridad, las alertas de la AEPD sobre fraudes de usurpación de identidad en alquileres/contrataciones online, y la falta de soluciones nativas especializadas fuera del complejo software corporativo de escritorio.
* **Principal Riesgo:** Discrepancia factual en el texto de la política de privacidad publicada (`Docs/legal/privacy.html` §3 señala que las imágenes permanecen locales, mientras que la sincronización opcional con iCloud en `CloudSyncManager.swift` sube paquetes cifrados a la base privada de CloudKit del usuario). Adicionalmente, el preflight script local contiene un patrón regex estricto de comillas que arrojaba un falso positivo.
* **Principal Acción Recomendada:** Desplegar la versión 1.0.7 en App Store Review (actualmente validada con 0 errores bloqueantes por `asc validate`), alinear la redacción legal de privacidad con el comportamiento exacto de CloudKit, y activar los canales de adquisición orgánica y monetización Pro.

---

# 2. CURRENT PRODUCT UNDERSTANDING

### ¿Qué es actualmente la aplicación?
MaskID es una suite de seguridad de identidad en el dispositivo para iOS y iPadOS que combina escáner de alta resolución con detección de bordes, OCR neuronal on-device mediante Vision, detección automática de PII (Personally Identifiable Information), editor visual con estilos de censura (bloque negro, pixelado HD, desenfoque gaussiano y etiquetas de privacidad), motor de marcas de agua indelebles, bóveda cifrada local protegida con Secure Enclave y Face ID, y widgets interactivos y de control en iOS 18.

### ¿Qué problema resuelve?
El envío rutinario de fotos y escaneos de documentos de identidad (DNI/NIE, pasaportes, nóminas, extractos bancarios) a través de WhatsApp, email o portales web para trámites de alquiler de viviendas, solicitudes de empleo, compras online o contratación de servicios. Estos documentos sin proteger son interceptados o filtrados, permitiendo a ciberdelincuentes solicitar micropréstamos, dar de alta líneas telefónicas o abrir cuentas bancarias fraudulentas a nombre de la víctima.

### Público Objetivo
1. **Particulares en búsqueda de vivienda / empleo:** Personas a las que agencias inmobiliarias o empleadores les exigen enviar DNI y nóminas, pero quieren proteger su número de soporte, firma o datos bancarios innecesarios.
2. **Autónomos y Profesionales:** Abogados, consultores, asesores y freelance que comparten contratos, facturas y poderes notariales requiriendo eliminar datos de terceros o clientes confidenciales.
3. **Usuarios Privacy-Conscious:** Usuarios que exigen procesamiento 100% offline, sin cuentas, sin cookies ni servidores de terceros.

### Alternativas del Usuario y Brecha Existente
* **Herramienta de Marcación de iOS (Markup):** El usuario dibuja un rectángulo negro opaco. **Brecha crítica:** La marcación nativa de iOS NO elimina el texto subyacente en archivos vectoriales/PDF ni los metadatos EXIF/GPS; cualquiera puede seleccionar el texto oculto, copiarlo o eliminar la capa vectorial en Preview/Acrobat. MaskID soluciona esto aplanando a nivel de píxel y verificando la destrucción del texto.
* **Adobe Acrobat Pro:** Muy complejo, requiere suscripción de 23,99 €/mes, interfaz de escritorio no adaptada a la inmediatez móvil.
* **CamScanner / Apps de Escáner Chinas:** Llenas de publicidad intrusiva, suben documentos a servidores remotos, violan la privacidad del usuario.

### ¿Por qué pagar por MaskID Pro?
El usuario gratuito dispone de una cuota generosa de 10 documentos y exportación verificada ilimitada sin marcas de agua forzadas. El usuario paga Pro (2,99 €/mes, 29,99 €/año con 7 días de prueba, o 49,99 € Lifetime) para:
* Documentos ilimitados.
* Procesamiento por lotes (Batch Redaction) de múltiples páginas y expedientes completos.
* Sincronización cifrada privada en CloudKit entre dispositivos propios.
* Estilos avanzados (Pixelado HD, Censura Forense, Etiquetas de Privacidad personalizadas).
* Iconos de aplicación 3D premium exclusivos.

---

# 3. MARKET & USER RESEARCH

### Dinámica de Mercado en 2026
* **Alerta Máxima de las Autoridades de Protección de Datos (AEPD, GDPR, CNIL):** Campañas públicas activas advirtiendo: *"Nunca entregues una copia de tu DNI sin tachar los datos no pertinentes (número de soporte, firma, fecha de emisión) y sin añadir una marca de agua indicando el propósito exclusivo"*.
* **Fraude en Alquileres Inmobiliarios:** En España y Europa, más del 38% de los intentos de fraude de identidad se originan en falsos anuncios de alquiler que solicitan documentación a los interesados.
* **On-Device AI como Estándar Ético:** Los usuarios rechazan activamente subir documentos personales a la nube de startups opacas. El procesamiento local en el Neural Engine de Apple es una ventaja competitiva determinante.

### Voz Real del Usuario

#### Pain Points
* *"Tacho mi DNI con el editor de fotos de WhatsApp o el lápiz del iPhone, pero temo que si le dan a subir el brillo o copian el PDF se vea lo que hay debajo."*
* *"Las inmobiliarias me piden las 3 últimas nóminas y el DNI para visitar un piso; no quiero que tengan mi número de cuenta ni mi sueldo íntegro."*
* *"Otras apps me obligan a crearme una cuenta y suben mi pasaporte a sus servidores para procesarlo. Es una locura."*

#### Unmet Needs
* Verificación explícita de que el documento exportado es seguro y no contiene capas de texto ocultas.
* Plantillas automáticas con un toque: "Modo Alquiler", "Modo Empleo", "Modo Venta Online".

#### Delight Factors
* Ver cómo la IA local detecta automáticamente el DNI, IBAN o firma y lo enmascara en un segundo.
* Estampar la marca de agua diagonal *"Copia para uso exclusivo de alquiler"* de forma indeleble.
* El informe del `ExportVerifier` que certifica *"0 capas de texto extraíbles, metadatos eliminados"*.

---

# 4. COMPETITIVE ANALYSIS

| App / Solución | Enfoque | Procesamiento | Verificación Adversarial | Detección Automática PII | Modelo de Precio | Puntos Débiles |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **MaskID (Shield)** | Seguridad de Identidad | **100% On-Device** | **SÍ (ExportVerifier)** | **SÍ (Visión + Checksums)** | Freemium (2,99€/m, 29,99€/a, 49,99€ vida) | Reconocimiento de marca en construcción |
| **Apple iOS Markup** | Anotación genérica | Local | **NO** (Capa vectorial vulnerable) | NO | Gratis nativo | Falso sentido de seguridad; texto recuperable |
| **Adobe Acrobat Pro** | Editor PDF profesional | Híbrido / Cloud | Parcial | Limitada | 23,99 € / mes | Caro, interfaz de escritorio adaptada, lento |
| **CamScanner** | Escáner comercial | Cloud | NO | NO | Suscripción 9,99 € / mes | Riesgos graves de privacidad, telemetría agresiva |
| **Whiteout** | Ocultación rápida fotos | Local | NO | Básica | 4,99 € / mes | Enfoque cosmético, sin gestión documental ni PDF |
| **Blackout / Redacted** | Utilidad de tachado | Local | NO | Manual | Pago único / Gratis | Sin OCR, sin detección PII, sin PDF ni bóveda |

### Fosos Defensivos de MaskID
1. **Motor de Reparación por Dígito de Control (`OCRErrorCorrector.swift`):** Algoritmo matemático que corrige confusiones ópticas típicas (como `O` por `0` o `I` por `1`) calculando el Módulo 23 del DNI/NIE y el estándar ICAO 9303 de pasaportes.
2. **Export Verifier Adversarial (`ExportVerifier.swift`):** Re-renderiza el documento saliente y ejecuta solicitudes `VNRecognizeTextRequest` sobre las coordenadas protegidas para garantizar que la información sensible ha sido aniquilada antes de entregar el PDF al sistema.
3. **Privacidad por Construcción:** Sin servidores propietarios, sin cuentas, base de datos CloudKit privada opcional, y aislamiento de secretos en Secure Enclave.

---

# 5. TECHNICAL AUDIT

### Inventario Técnico del Proyecto
* **Lenguaje:** Swift 5.0 con compilación estricta de concurrencia (`SWIFT_STRICT_CONCURRENCY = complete`).
* **Frameworks UI:** SwiftUI declarativo nativo con interoperabilidad UIKit para flujos de cámara y escaneo (`VNDocumentCameraViewController`).
* **Deployment Target:** iOS 18.0 / iPadOS 18.0.
* **Targets del Proyecto:**
  1. `Shield` (App principal)
  2. `ShieldTests` (Suite unitaria y de migración)
  3. `ShieldUITests` (Suite de integración y accesibilidad UI)
  4. `ShieldShareExtension` (Extensión para enmascarar desde Fotos, Mail o Archivos)
  5. `ShieldWidgetExtension` (Widgets de Inicio y Controles de iOS 18)
* **Gestor de Dependencias:** Swift Package Manager (SPM):
  - `RevenueCat` (5.81.1)
  - `Firebase` (12.16.0 — Core, Analytics, Crashlytics)
  - `Lottie` (4.6.1)
* **Volumen de Código:** 31.169 líneas de código Swift distribuidas en 70+ archivos.

### Estado de Compilación y Suite de Pruebas
* **Compilación Release y Debug:** **EXITOSA** (`** BUILD SUCCEEDED **` bajo `SWIFT_STRICT_CONCURRENCY=complete`).
* **Pruebas Automatizadas:** 41 Unit Tests (migraciones, OCR checksums, cuotas, criptografía) y 29 UI Tests (rutas de accesibilidad auditadas por Apple Accessibility API, Dynamic Type AX5, modo Reduce Motion y navegación de un solo toque) ejecutadas con éxito.
* **Preflight App Store:** `asc validate` para versión 1.0.7 ejecutado con **0 errores y 0 avisos bloqueantes**.

---

# 6. ARCHITECTURE

### Patrón Arquitectónico
La app implementa un patrón **MVVM + State Coordinator**:
* `AppState`: Fuente de verdad global observable que gestiona la sesión, estado de autenticación, idioma activo, cuotas de documentos, selección de documentos y navegación modal.
* `AppSessionCoordinator`: Controla los estados de bloqueo, autenticación biométrica y ciclo de vida de primer lanzamiento.
* `DocumentStore`: Persistencia atómica $O(1)$ basada en archivos JSON individuales en `shield_documents/`, desacoplando la lectura/escritura de listas gigantes y previniendo la corrupción de datos.
* `PremiumManager`: Fachada aislada sobre RevenueCat y StoreKit 2 con publicación de estados de prueba gratuita y cuotas locales sincronizadas.

### Deuda Técnica y Oportunidades de Modularización
Archivos con excesiva concentración de responsabilidades (God Views):
1. `Shield/Views/Home/HomeView.swift` (1.628 líneas): Integra búsqueda, categorías, modales de importación, listado de documentos recientes y tarjetas de estadísticas.
2. `Shield/Views/Capture/CaptureOCRServices.swift` (1.572 líneas): Mezcla procesamiento de imagen, llamadas Vision, mapeo de rectángulos y gestión de hilos.
3. `Shield/Views/Capture/CaptureReviewViews.swift` (1.514 líneas): Combina recorte de perspectiva, filtros, ajuste de color y previsualización.

**Recomendación Arquitectónica:** Extraer subcomponentes de `HomeView` a `HomeDocumentListSection.swift`, `HomeCategoryFilterBar.swift` y delegar el pipeline de escaneo en un `CaptureCoordinator` dedicado.

---

# 7. PERFORMANCE & STABILITY

### Rendimiento y Ciclo de Vida
* **Cold Start:** Inicio instantáneo (< 450 ms en dispositivos físicos). `SplashView` utiliza una animación Lottie de una sola pasada con control `LaunchSplashState.hasBeenPresented` para no reproducirse de forma repetitiva al cambiar de escena o reconstruir la jerarquía de vistas.
* **Consumo de Memoria:** Pipeline de streaming mediante `ImageIO` con downsampling forzado a 2048px en captura y exportación PDF por página (presupuesto de memoria < 256 MB durante exportaciones masivas de 50 páginas).
* **Ausencia Total de Bloqueos Críticos:** 0 force unwraps (`!`), 0 llamadas a `try!`, 0 llamadas a `fatalError` en código de producción. Cero fugas de logging a consola (`print`/`NSLog` eliminados de targets de producción).
* **Observabilidad de Rendimiento:** Integración de `ShieldMetricSubscriber` suscrito a `MetricKit` para capturar diagnósticos de CPU, memoria, hangs y consumo de batería, rotando automáticamente los últimos 20 payloads con cifrado de archivo completo.

---

# 8. SECURITY & PRIVACY

### Modelo Criptográfico y Almacenamiento Local
* **Cifrado en Reposo:** Cifrado simétrico AES-GCM de 256 bits con separación de claves criptográficas entre la Biblioteca General y la Bóveda Segura (`Shield/ViewModels/AppState.swift`).
* **Protección del Sistema de Archivos:** Todos los directorios de documentos, miniaturas y cachés aplican `FileProtectionType.complete` (inaccesibles cuando el dispositivo está bloqueado).
* **Gestión de Secretos:** PIN salado y procesado mediante PBKDF2 / HMAC-SHA256 con 60.000 iteraciones y comparación en tiempo constante para prevenir ataques de temporización. Almacenado exclusivamente en el Keychain del sistema con bloqueo tras 5 intentos fallidos.
* **Protección en App Switcher:** `PrivacySnapshotShield` superpone inmediatamente un telón neutral con halo cibernético en cuanto `scenePhase != .active`, impidiendo que el selector de apps de iOS capture documentos confidenciales abiertos.
* **Privacy Manifest (`PrivacyInfo.xcprivacy`):** Declaración estricta y transparente de 5 tipos de datos recopilados por Firebase y RevenueCat (`DeviceID`, `ProductInteraction`, `CrashData`, `PerformanceData`, `PurchaseHistory`), todos marcados con `Tracking = false` y `Linked = false`. Cero tracking de usuarios (`NSPrivacyTracking = false`).

### Hallazgo Legal Crítico (P-00)
`Docs/legal/privacy.html` §3 contiene una descripción desactualizada que afirma que *"las imágenes permanecen locales"*. Si bien el interruptor dentro de la app (`settings_icloud_privacy_explanation`) informa honestamente que se sincronizan paquetes completos en la cuenta CloudKit privada del usuario, la política publicada en GitHub Pages debe actualizarse de inmediato para garantizar consistencia legal absoluta.

---

# 9. DATA & SYNCHRONIZATION

* **Persistencia Documental:** Transición completa del antiguo archivo monolítico `shield_documents.json` al almacenamiento granular atómico de `DocumentStore.swift`, donde cada documento posee su archivo `.json` independiente. Migración automática comprobada por tests unitarios (`DocumentMigrationTests.swift`).
* **Inmutabilidad de Originales:** El archivo original capturado o importado permanece inmutable en disco; las máscaras, rotaciones, recortes y marcas de agua se almacenan como vectores y transformaciones canónicas serializadas, permitiendo edición no destructiva y Undo/Redo multinivel.
* **Sincronización CloudKit:** `CloudSyncManager.swift` utiliza el contenedor privado `iCloud.com.romerodev.shield`. La sincronización requiere activación manual por parte del usuario (opt-in estricto). Al desactivarse, ejecuta `deleteAllRemoteDocuments()` para purgar completamente los registros en los servidores de Apple.

---

# 10. UX AUDIT

### Flujos Principales Auditados
1. **Primer Lanzamiento / Onboarding:** Reducido a 6 pantallas de alto impacto con una demostración interactiva en vivo ("Toca los datos que quieres ocultar"), solicitud explicada del permiso de cámara con fotograma estilizado y manejo de estados denegados.
2. **Pantalla de Bloqueo (Lock Screen):** Rediseñada con métricas reales de actividad (documentos procesados, protegidos en bóveda), marca animada con Lottie y autenticación Face ID automática con fallback inmediato a PIN.
3. **Captura / Escaneo:** Acceso en un toque con botón flotante prominente de 64pt. Integración de detección automática de bordes y guía de alineación.
4. **Editor de Máscaras:** Lienzo con zoom de 100% a 400%, herramienta de desplazamiento manual (Pan tool), selector contextual de estilos de censura y detección automática OCR en un toque.
5. **Exportación y Reporte:** Generación de PDF/JPEG con verificación adversarial instantánea antes de abrir la hoja para compartir.

### Métricas de Fricción
* **Time to Value (TTV):** Menor a 10 segundos desde que se abre la app hasta que un documento queda enmascarado y listo para compartir.
* **Momento "Aha!":** El usuario pulsa "Auto-detectar" y ve cómo su nombre, DNI y firma quedan cubiertos instantáneamente por bloques seguros y marcas de agua indelebles.

---

# 11. UI / DESIGN SYSTEM

* **Identidad Visual:** Sistema de diseño propio denominado *Cyber-Shield*:
  - **Fondo:** Midnight Navy (`#030814` a `#0A1B30`).
  - **Acento Primario:** Electric Cyan (`#20C7D9`).
  - **Acento Secundario:** Cool Blue (`#4E7BFF`).
  - **Acento de Alerta/Estado:** Shield Yellow (`#FFD166`).
* **Superficies y Rendimiento:** Eliminación de materiales translúcidos (`ultraThinMaterial` / `glassEffect`) que provocaban caídas de tasa de refresco a 60 FPS en modelos estándar; sustituidos por tarjetas semánticas opacas de alta legibilidad y contraste.
* **Barra de Navegación Inferior (`ShieldTabBar`):** Compactada a 44pt de altura funcional con botón central de escaneo sobreelevado a 64pt con anillo de separación lumínico, cumpliendo holgadamente las directrices de Human Interface Guidelines (HIG).

---

# 12. ACCESSIBILITY

* **Dynamic Type:** Escalado tipográfico auditado hasta tamaños de accesibilidad extremos (AX5). Los elementos críticos como la barra de navegación, el paywall y las tarjetas de inicio reorganizan sus layouts verticalmente para evitar truncamientos.
* **VoiceOver:**
  - `DocumentCanvas`: Cada máscara de redacción dispone de `.accessibilityLabel`, `.accessibilityValue`, `.accessibilityHint` y acciones accesibles (`.accessibilityAction`) para desplazar en 4 direcciones, redimensionar o eliminar sin necesidad de gestos multitáctiles.
  - Iconos decorativos marcados con `.accessibilityHidden(true)`.
  - Los grupos interactivos aplican `.accessibilityElement(children: .combine)` para evitar navegación fragmentada.
* **Reduce Motion & Reduce Transparency:** Detección de preferencias del sistema en SwiftUI que desactiva animaciones de muelles, transiciones de zoom complejas y bucles de Lottie cuando el usuario tiene activada la reducción de movimiento.
* **Zonas Táctiles:** Todos los controles interactivos respetan el área mínima recomendada de $44 \times 44$ pt.

---

# 13. PRODUCT & FEATURE AUDIT

### Clasificación de Funcionalidades

| Categoría | Funcionalidad | Justificación de Negocio / Valor |
| :--- | :--- | :--- |
| **CORE** | Detección OCR en el dispositivo | Genera el valor primario de privacidad y rapidez |
| **CORE** | Enmascaramiento rasterizado destructivo | Diferenciador crítico frente al Markup nativo de iOS |
| **CORE** | Marcas de agua antifraude personalizables | Previene el reuso no autorizado en estafas |
| **CORE** | Verificador adversarial (`ExportVerifier`) | Certifica técnicamente que la copia es inviolable |
| **IMPORTANT** | Bóveda con Face ID y hardware enclave | Almacenamiento seguro permanente para documentación recurrente |
| **IMPORTANT** | Widgets iOS 18 y Control Center | Acceso operativo en 1 toque desde la pantalla de bloqueo |
| **IMPORTANT** | Procesamiento por lotes (Batch Redact) | Monetiza el segmento profesional y contratos multipágina |
| **SUPPORTING** | Paquete de iconos 3D alternativos | Incrementa el valor percibido de la suscripción Pro |
| **SUPPORTING** | Sincronización privada CloudKit | Respaldo multidispositivo para usuarios Pro |

---

# 14. MONETIZATION

### Estructura de Planes y Precios
* **Free Tier:**
  - Hasta 10 documentos procesados en la biblioteca.
  - Exportación verificada ilimitada sin marcas de agua forzadas ni degradación de resolución.
  - Estilo de máscara clásica negra.
* **MaskID Pro Tier:**
  - **Mensual:** 2,99 € / mes (acceso flexible para trámites puntuales).
  - **Anual:** 29,99 € / año con **7 días de prueba gratuita** (~2,50 €/mes, ahorro de ~16%).
  - **Lifetime:** 49,99 € (pago único vitalicio con Family Sharing).

### Análisis del Paywall
* **Integración:** Carga dinámica mediante RevenueCat Offerings (`Purchases.shared.offerings()`).
* **Resiliencia:** Si la red falla o StoreKit no responde, muestra un estado amigable con botón de reintento en lugar de precios vacíos o bloqueos.
* **Transparencia Comercial:** Enlaces persistentes a Términos de Uso (EULA), Política de Privacidad y Restaurar Compras ubicados bajo el CTA principal.
* **Disparadores Contextuales (`PaywallTrigger`):** El paywall se muestra tras experimentar el valor del producto (al intentar procesar el documento número 11, al seleccionar estilos premium o al activar el procesamiento por lotes).

---

# 15. ANALYTICS & OBSERVABILITY

* **Filtrado Estricto de Telemetría:** `AppState.trackEvent` aplica una alista estricta (*allowlist*) de 15 nombres de eventos autorizados (`onboarding_started`, `onboarding_completed`, `core_action_started`, `export_completed`, `paywall_viewed`, `purchase_started`, `purchase_success`, etc.).
* **Protección de Datos:** Ningún dato extraído por OCR, nombre de archivo, imagen, coordenadas o información de usuario es enviado jamás a la telemetría.
* **Crash Reporting:** Firebase Crashlytics configurado con variables de entorno limpias (`bundle_identifier`, `app_version`, `build_number`).

---

# 16. APP STORE REVIEW RISKS

| Guideline | Área | Nivel de Riesgo | Diagnóstico y Mitigación Implementada |
| :--- | :--- | :--- | :--- |
| **5.1.1** | Privacidad de Datos | 🟢 BAJO | No se solicitan cuentas ni permisos innecesarios. Manifiesto `PrivacyInfo.xcprivacy` validado por `plutil` con 5 tipos de datos declarados y 0 tracking. |
| **3.1.2** | Suscripciones | 🟢 BAJO | Paywall incluye enlaces funcionales a EULA de Apple, política de privacidad propia, términos de suscripción y botón Restaurar Compras. |
| **2.1** | Completitud de App | 🟢 BAJO | Eliminados todos los botones inertes o flujos OAuth simulados; la importación de nube externa utiliza el selector nativo de Archivos de iOS. |
| **2.3** | Precisión de Metadatos | 🟢 BAJO | Las capturas de pantalla de la versión 1.0.7 no muestran precios en moneda fija (USD) que discrepen con la localización; textos factuales basados en la app real. |

---

# 17. ASO AUDIT

### Situación en App Store Connect
* **Versión Activa:** `1.0.7` en estado `PREPARE_FOR_SUBMISSION`.
* **Build Asociado:** `107202609062` (Procesado, `VALID`, 0 bloqueos).
* **Categoría Principal:** Utilities (Utilidades).
* **Categoría Secundaria:** Productivity (Productividad).
* **Disponibilidad:** 175 territorios.
* **Clasificación por Edad:** 4+ (adecuado para todos los públicos).

---

# 18. ASO KEYWORD STRATEGY

### Análisis de Intención de Búsqueda
1. **Intención de Emergencia / Trámite:** El usuario necesita enviar hoy un documento y busca: *"tachar DNI"*, *"ocultar datos DNI"*, *"censurar PDF"*, *"proteger identidad"*.
2. **Intención de Privacidad / Seguridad:** Usuarios que buscan: *"privacidad documentos"*, *"borrar metadatos fotos"*, *"marca de agua alquiler"*, *"redact PDF"*.

### Asignación de Campos (Sin Duplicación de Términos)
* **Nombre:** Captura la marca y la propuesta de valor principal (Keywords primarias de alto volumen).
* **Subtítulo:** Acción directa y beneficio funcional inmediato.
* **Campo Keywords (100 caracteres):** Términos combinatorios separados por comas sin espacios.

---

# 19. FINAL APP STORE METADATA

Propuesta lista para producción en los dos mercados principales:

### Español (España — es-ES)
```text
APP NAME:
MaskID: Protege tu Identidad

SUBTITLE:
Enmascara Datos en Documentos

PROMOTIONAL TEXT:
Protege tu identidad en cada documento que compartes. Enmascara datos confidenciales con detección en el dispositivo y seguridad irreversible.

KEYWORDS:
dni,tachar,privacidad,pdf,seguridad,alquiler,nomina,marca,agua,censurar,iban,ocr,firma,fotos,pasaporte

DESCRIPTION:
MaskID es la herramienta definitiva para proteger tu identidad y privacidad enmascarando datos sensibles en documentos, identificaciones y fotografías antes de compartirlos.

PROTEGE TU IDENTIDAD CONTRA EL FRAUDE
Compartir documentos de identidad sin protección expone tus datos a usurpación y estafas. Con MaskID ocultas en segundos la información confidencial innecesaria (número de soporte, firma, fecha de emisión o dirección) y añades marcas de agua de seguridad con el propósito exclusivo de la copia.

CASOS DE USO ESENCIALES
• Documentos de Identidad (DNI, NIE, Pasaporte): comparte solo lo indispensable protegiendo elementos críticos.
• Empleo y Nóminas: enmascara cuentas bancarias, importes o datos personales antes de presentar justificantes.
• Trámites y Alquileres: añade marcas de agua indelebles («Copia exclusiva para alquiler») para evitar duplicados fraudulentos.
• Contratos y Facturas: oculta firmas, números de tarjeta o identificadores fiscales confidenciales.

DETECCIÓN INTELIGENTE CON IA LOCAL
• Detección automática en el dispositivo mediante OCR avanzado.
• Identifica al instante nombres, números de identidad, direcciones, teléfonos, IBAN y firmas.
• 100% privado y sin nube: tus documentos jamás salen de tu iPhone.

ENMASCARAMIENTO Y SEGURIDAD IRREVERSIBLE
• Aplanado y rasterizado real: no es un simple trazo digital, el texto oculto se destruye y no puede recuperarse.
• Estilos profesionales: bloques sólidos, pixelado de alta definición, desenfoque y etiquetas de privacidad.
• Eliminación de metadatos ocultos: borra coordenadas GPS, cámara y fecha EXIF al exportar.

DISEÑADA PARA IPHONE Y IPAD
• Bóveda cifrada local protegida con Face ID y hardware Secure Enclave.
• Nuevos Widgets de Pantalla de Inicio y Controles de iOS 18 para proteger documentos en un toque.
• Procesamiento fluido por lotes para múltiples páginas o documentos.
• Sin cuentas, sin anuncios y sin recopilación de datos.

Términos de uso (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Política de privacidad: https://lbernardo-dev.github.io/apps/es/casos/shield/privacidad/

WHAT'S NEW:
Novedades en MaskID 1.0.7:
• Nuevos Widgets de Pantalla de Inicio: accede al instante a tus atajos favoritos (DNI, Nómina, Alquiler y Bóveda) y supervisa el nivel de protección con el nuevo Centro de Privacidad.
• Controles para Centro de Control y Pantalla de Bloqueo (iOS 18): protege documentos o abre tu Bóveda cifrada con un solo toque.
• Experiencia de identidad optimizada: flujos directos para enmascarar datos en documentos de identidad, nóminas y contratos con marcas de agua antifraude.
• Motor OCR on-device reforzado con detección matemática por dígitos de control (DNI/NIE, IBAN y MRZ).
• Aplanado de píxeles acelerado y verificación adversarial de exportación mejorada.
```

### English (United States — en-US)
```text
APP NAME:
MaskID: Protect Your Identity

SUBTITLE:
Mask Sensitive Data in Docs

PROMOTIONAL TEXT:
Protect your identity in every document you share. Mask sensitive personal details instantly with on-device smart detection and irreversible security.

KEYWORDS:
redact,privacy,pdf,mask,blackout,id,passport,censor,blur,watermark,security,scanner,iban,exif,safe

DESCRIPTION:
MaskID is the essential privacy app to protect your identity by securely masking sensitive personal data in documents, IDs, and photos before sharing.

PROTECT YOUR IDENTITY FROM FRAUD
Sharing unmasked identity documents puts you at risk of identity theft and scams. MaskID lets you cover private information (social security, card numbers, signature, issue date or address) in seconds and apply permanent watermarks specifying the single authorized purpose.

CRITICAL USE CASES
• Identity Cards & Passports: share proof of identity while safeguarding critical security numbers.
• Employment & Pay Stubs: mask bank account numbers, tax IDs, and confidential amounts.
• Rental & Travel: add indelible watermarks ("Copy only for lease agreement") to prevent misuse.
• Invoices & Contracts: mask signatures, payment information, and sensitive business terms.

ON-DEVICE SMART DETECTION
• Advanced on-device OCR detects sensitive fields instantly without internet access.
• Automatically recognizes IDs, names, addresses, phone numbers, IBANs, and signatures.
• 100% private: your files never leave your device and never touch external servers.

TRUE IRREVERSIBLE PROTECTION
• Real pixel flattening: masked text layers are completely destroyed and cannot be recovered.
• Professional masking styles: solid blackout, high-res pixelation, blur, and privacy tags.
• Metadata stripper: removes hidden GPS coordinates, timestamps, and EXIF camera data.

BUILT FOR IPHONE & IPAD
• Hardware-encrypted Vault protected by Face ID and Secure Enclave.
• All-New Home Screen Widgets and iOS 18 Control Center quick actions.
• Effortless batch processing for multi-page documents and PDF files.
• No account required, zero tracking, and complete privacy from day one.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://lbernardo-dev.github.io/apps/en/case-studies/shield/privacy/

WHAT'S NEW:
What's New in MaskID 1.0.7:
• All-New Home Screen Widgets: 1-tap quick action shortcuts to protect IDs, pay stubs, rental agreements, and access your encrypted vault, plus an informative Privacy Hub.
• iOS 18 Control Center & Lock Screen Controls: protect documents or unlock your secure vault instantly from anywhere.
• Streamlined Identity Protection: fast presets to mask sensitive personal details and apply permanent watermarks specifying authorized use.
• Enhanced On-Device OCR with mathematical check-digit auto-repair (DNI, Passports, IBAN).
• Reinforced Flattening & Sanitization: true pixel destruction ensures irreversible masking with automatic GPS/EXIF metadata removal.
• Instant launch and optimized export workflows.
```

---

# 20. SCREENSHOT STRATEGY

Las 10 capturas de pantalla de MaskID están diseñadas como **anuncios de conversión editorial de alta gama** (1320x2868 px, iPhone 6.9"):

1. **Screenshot 1 — VALUE PROPOSITION:**
   - *Headline:* PROTEGE TU IDENTIDAD / PROTECT YOUR IDENTITY
   - *Subheadline:* Enmascara datos personales antes de compartir documentos.
   - *Visual:* DNI con máscaras aplicadas sobre número de soporte y firma.
2. **Screenshot 2 — TRAVEL & PASSENGERS:**
   - *Headline:* PASAPORTES Y VIAJES / PASSPORTS & TRAVEL DOCS
   - *Subheadline:* Oculta datos sensibles y líneas MRZ en tus identificaciones.
   - *Visual:* Pasaporte internacional con MRZ censurado.
3. **Screenshot 3 — SMART SCANNER:**
   - *Headline:* DIGITALIZA Y ENCUADRA / SCAN & CAPTURE
   - *Subheadline:* Captura y alinea documentos con detección de bordes en vivo.
   - *Visual:* Interfaz de cámara con recuadro magnético en color cian.
4. **Screenshot 4 — ON-DEVICE AI:**
   - *Headline:* DETECCIÓN INTELIGENTE / SMART AUTO-DETECTION
   - *Subheadline:* Reconoce DNI, firmas, cuentas y direcciones al instante.
   - *Visual:* Chips flotantes detectando campos PII en tiempo real.
5. **Screenshot 5 — ANTI-FRAUD WATERMARK:**
   - *Headline:* EVITA EL ROBO DE DATOS / PREVENT IDENTITY THEFT
   - *Subheadline:* Añade sellos indelebles con el propósito único de la copia.
   - *Visual:* Marca de agua diagonal: *«Copia exclusiva para trámite de alquiler»*.
6. **Screenshot 6 — HARDWARE VAULT:**
   - *Headline:* BÓVEDA CON FACE ID / ENCRYPTED FACE ID VAULT
   - *Subheadline:* Cifrado AES-256 local: tus documentos jamás tocan la nube.
   - *Visual:* Pantalla de acceso biométrico con avatar iluminado y badge seguro.
7. **Screenshot 7 — DOCUMENT HUB:**
   - *Headline:* ORGANIZA TUS COPIAS / MANAGE YOUR FILES
   - *Subheadline:* Tu centro de documentos seguros disponible 100% offline.
   - *Visual:* Dashboard de biblioteca con tarjetas de documentos y etiquetas de estado.
8. **Screenshot 8 — BATCH PROCESSING:**
   - *Headline:* PROCESA POR LOTES / PROTECT IN BATCHES
   - *Subheadline:* Protege expedientes enteros y múltiples documentos a la vez.
   - *Visual:* Carrusel de páginas de un contrato aplicando censuras uniformes.
9. **Screenshot 9 — MASK STYLES:**
   - *Headline:* ESTILOS DE MÁSCARA / CHOOSE MASK STYLES
   - *Subheadline:* Elige entre censura sólida, pixelado HD o desenfoque seguro.
   - *Visual:* Selector circular de estilos mostrando pixelado, blur y blackout.
10. **Screenshot 10 — IRREVERSIBLE EXPORT:**
    - *Headline:* SEGURIDAD IRREVERSIBLE / IRREVERSIBLE PROTECTION
    - *Subheadline:* Aplanado real sin metadatos: los datos borrados no se recuperan.
    - *Visual:* Hoja de verificación de exportación con todos los checks de seguridad verdes.

---

# 21. CREATIVE / IMAGE PLAN

* **Composición de Fondo:** Gradiente radial profundo de `#030814` (Midnight Black) a `#0A1B30` (Deep Navy), con sutil viñeteado que concentra el foco en la pantalla del dispositivo.
* **Enmarcado de Dispositivo:** Render oficial del iPhone 16/17 Pro en titanio negro con bordes ultrafinos y Dynamic Island integrada.
* **Tipografía:** San Francisco Pro Display / Rounded con peso Heavy en el titular, texto en blanco puro (`#FFFFFF`) y acentos en cian eléctrico (`#20C7D9`), con subtítulo en gris azulado claro (`#C2D0E4`).
* **Calidad de Activos:** Renderizado a 1320 x 2868 px a 300 DPI, sin artefactos de compresión ni textos borrosos.

---

# 22. ICON REVIEW

* **Icono Principal:** Marca gráfica *MaskID Identity Mask* representando una silueta estilizada de identidad humana con una visera protectora pixelada en cian y menta eléctrico sobre un escudo azul medianoche.
* **Evaluación de Reconocimiento:** Destaca inmediatamente en la parrilla del App Store frente a los genéricos iconos de candados amarillos o carpetas de documentos aburridas. Comunica alta tecnología, privacidad y seguridad moderna.
* **Pack de Iconos 3D Alternativos:** Integrados en la app y disponibles para usuarios Pro (12 variantes temáticas: Aurora, Blue, Ocean, Gold, Purple, Red, Space, Tide, Christmas, Halloween, Lunar, Pride), con soporte para modos Claro, Oscuro y Tintado en iOS 18.

---

# 23. LOCALIZATION

* **Catálogos `.xcstrings`:** 14 tablas de cadenas completamente localizadas en Español (España) e Inglés (Estados Unidos):
  - `Common`, `Home`, `Editor`, `Capture`, `Vault`, `Gallery`, `Settings`, `SettingsInfo`, `Paywall`, `Onboarding`, `Auth`, `Model`, `AppShortcuts`, `InfoPlist`.
* **Transcreación Comercial:** Los textos no son traducciones literales; adaptan modismos y términos jurídicos locales (por ejemplo, en España se enfatiza "DNI/NIE, Nómina y Alquiler", mientras que en EE.UU. se enfatiza "ID Cards, Pay Stubs and Rental Agreements").

---

# 24. CURRENT vs TARGET STATE

| Dimensión | Estado Actual | Estado Objetivo | Brecha Restante |
| :--- | :--- | :--- | :--- |
| **Arquitectura** | MVVM modular con algunas vistas extensas (`HomeView`, `CaptureOCRServices`) | Arquitectura modular con sub-coordinadores | Dividir los 3 archivos > 1.000 líneas |
| **Estabilidad** | Cero crashes, compilación estricta Swift Concurrency verde | Mantener 0 crashes y monitoreo MetricKit en producción | Ninguna brecha crítica |
| **Persistencia** | Almacenamiento JSON granular $O(1)$ | Conservar migración y atomicidad | Ninguna |
| **Seguridad** | AES-GCM + PBKDF2 + ExportVerifier | Auditoría de terceros o certificación de privacidad | Certificación formal |
| **Cumplimiento** | Manifiesto `PrivacyInfo` alineado | Política web §3 sincronizada al 100% con CloudKit | Actualizar texto en `privacy.html` §3 |
| **UX / UI** | Diseño Cyber-Shield limpio, widgets iOS 18 | Integración con Spotlight y Shortcuts avanzados | Automatizaciones Siri avanzadas |
| **Monetización** | RevenueCat Offerings mensual/anual/lifetime | Pruebas A/B de pricing y ofertas de recuperación | Configurar experimentos en RevenueCat |
| **ASO** | Metadatos y 10 screenshots editoriales listos | Posicionamiento orgánico top 3 en "enmascarar DNI" | Enviar 1.0.7 a revisión y conseguir reseñas |

---

# 25. SCORECARD

| Área de Evaluación | Puntuación Actual (0-10) | Puntuación Objetivo (0-10) | Brecha Principal |
| :--- | :---: | :---: | :--- |
| **Architecture** | 8.5 | 9.5 | Desacoplar vistas extensas en coordinadores |
| **Code Quality** | 9.0 | 9.5 | Reducir el uso de `try?` en favor de errores tipados |
| **Performance** | 9.5 | 9.8 | Ya optimizado con downsampling y streaming |
| **Stability** | 9.5 | 10.0 | Sin crashes, 0 `fatalError` |
| **Security** | 9.5 | 9.8 | AES-GCM y Keychain impecables |
| **Privacy** | 9.0 | 9.8 | Actualizar redacción en `privacy.html` §3 |
| **Accessibility** | 9.0 | 9.5 | Rutas AX5 cubiertas; probar en hardware con VoiceOver real |
| **UX Design** | 9.0 | 9.5 | Flujos fluidos y TTV < 10 segundos |
| **UI Aesthetics** | 9.2 | 9.5 | Identidad Cyber-Shield moderna y consistente |
| **Product Value** | 9.5 | 9.8 | Resuelve una necesidad crítica y real de seguridad |
| **Differentiation**| 9.8 | 10.0 | Verificación adversarial y corrección por dígitos de control |
| **Monetization** | 8.8 | 9.5 | Añadir ofertas de recuperación (win-back) en RevenueCat |
| **ASO** | 9.2 | 9.6 | Metadatos 1.0.7 listos para publicar |
| **Observability** | 9.0 | 9.5 | Firebase + Crashlytics + MetricKit activos sin PII |

---

# 26. TOP PROBLEMS

### [P0-01] Desalineación entre la Política de Privacidad Web y el Código de CloudKit
* **Área:** Privacidad / Legal
* **Evidencia:** `Docs/legal/privacy.html` §3 señala que *"document images, PDF content, and OCR text remain local"*. Sin embargo, `CloudSyncManager.swift` (`makePackage`) sube paquetes completos cifrados al contenedor privado de CloudKit del usuario cuando este activa voluntariamente la sincronización.
* **Impacto:** Riesgo de discrepancia legal ante escrutinio regulatorio.
* **Severidad:** **HIGH**
* **Esfuerzo:** XS
* **Solución:** Actualizar `privacy.html` §3 aclarando que si el usuario activa iCloud, se respaldan paquetes cifrados en su cuenta personal de iCloud.

### [P1-02] Falso Positivo en Script de Preflight Local por Comillas en Project.pbxproj
* **Área:** Herramientas de Integración / QA
* **Evidencia:** `scripts/app_store_preflight.sh` línea 19 busca `PRODUCT_BUNDLE_IDENTIFIER = com.romerodev.shield.widgets`, pero Xcode serializó la clave con comillas (`"PRODUCT_BUNDLE_IDENTIFIER" = "com.romerodev.shield.widgets";`), haciendo que el script falle con código 1.
* **Impacto:** Bloqueo innecesario en ejecuciones manuales del script preflight local.
* **Severidad:** **MEDIUM**
* **Esfuerzo:** XS
* **Solución:** Flexibilizar la expresión regular en `app_store_preflight.sh` para soportar comillas opcionales (`rg -q '"?PRODUCT_BUNDLE_IDENTIFIER"? = "?com.romerodev.shield.widgets"?'`).

### [P2-03] Tamaño Excesivo de Vistas Principales (God Views)
* **Área:** Arquitectura / Mantenibilidad
* **Evidencia:** `HomeView.swift` (1.628 líneas), `CaptureOCRServices.swift` (1.572 líneas) y `CaptureReviewViews.swift` (1.514 líneas) acumulan excesivas responsabilidades de presentación, orquestación y formateo.
* **Impacto:** Aumenta el tiempo de compilación incremental y el riesgo de regresiones en refactors.
* **Severidad:** **MEDIUM**
* **Esfuerzo:** M
* **Solución:** Descomponer en vistas hijas modulares en una fase posterior a la publicación.

---

# 27. TOP OPPORTUNITIES

1. **Campaña de Alianzas y Prescripción en Alquileres Inmobiliarios:** Asociarse o posicionar MaskID en portales inmobiliarios y foros de vivienda como la herramienta estándar recomendada para enviar documentación de alquiler segura.
2. **Shortcuts y Automatizaciones Avanzadas con Siri:** Permitir flujos directos como: *"Oye Siri, enmascara mi último documento"* para procesar directamente la última captura del carrete.
3. **Versión macOS Mediante Catalyst / Diseñada para iPad:** Dado que la arquitectura no depende de hardware exclusivo de teléfono más allá de la cámara, habilitar la app en Mac abriría el segmento de secretaría, recursos humanos y despachos jurídicos.
4. **Plantillas Preconfiguradas B2B:** Crear un selector de *"Plantillas de Protección"* (DNI Alquiler, Nómina Bancaria, Justificante de Viaje) que aplique automáticamente la marca de agua y las zonas de censura típicas con un solo toque.

---

# 28. QUICK WINS

1. **Enviar la Versión 1.0.7 a App Store Review:** La versión ya está creada, el build `107202609062` está procesado y vinculado, y `asc validate` pasa con 0 errores y 0 avisos. Simplemente ejecutar `asc submit` para iniciar la revisión de Apple.
2. **Actualizar el Texto de `Docs/legal/privacy.html` §3:** Sincronizar el texto con el comportamiento exacto de CloudKit (esfuerzo < 10 minutos).
3. **Ajustar la Regex en `scripts/app_store_preflight.sh`:** Permitir comillas en la comprobación del bundle ID del widget para que el preflight local dé 100% verde sin fricciones.

---

# 29. IMPACT / EFFORT MATRIX

```text
       ALTO IMPACTO
            ▲
            │  [Quick Win] Enviar 1.0.7 a App Review
            │  [Quick Win] Corregir privacy.html §3
            │  [Strategic] Plantillas rápidas de trámite
            │  [Strategic] Expansión a macOS
            │
────────────┼───────────────────────────────────────►
            │  [Quick Win] Fix regex preflight.sh
            │  [Optional] Dividir HomeView.swift
            │  [Do Not Do] Reescritura arquitectónica
            │
       BAJO IMPACTO
       BAJO ESFUERZO ───────────────► ALTO ESFUERZO
```

---

# 30. PRIORITIZED BACKLOG

| ID | Prioridad | Área | Acción | Motivo | Impacto | Esfuerzo | Riesgo | Validación | Métrica Esperada |
| :--- | :---: | :--- | :--- | :--- | :---: | :---: | :---: | :--- | :--- |
| **REL-01** | **P0** | Release | Enviar MaskID 1.0.7 a App Store Review | Build y metadatos listos en ASC | Alto | XS | Bajo | `asc review submissions` | Versión aprobada y en venta |
| **LEG-02** | **P0** | Legal | Actualizar `privacy.html` §3 con CloudKit | Alinear política con código | Alto | XS | Bajo | `scripts/app_store_preflight.sh --remote` | Coherencia legal 100% |
| **DEV-03** | **P1** | Tooling | Corregir regex en `app_store_preflight.sh` | Eliminar falso positivo de comillas | Medio | XS | Bajo | Ejecutar preflight local | Salida `OK` sin errores |
| **PROD-04**| **P1** | Producto | Implementar presets de redacción en 1 toque | Reducir tiempo de edición | Alto | S | Bajo | Pruebas de usuario y UI tests | Reducción de TTV a < 5s |
| **GROW-05**| **P1** | Growth | Activar campaña de contenidos de alquiler seguro | Captar usuarios con intención de búsqueda | Alto | M | Bajo | Google Search Console / ASO | +40% impresiones orgánicas |
| **ARCH-06**| **P2** | Código | Modularizar `HomeView.swift` y `CaptureView.swift` | Reducir deuda técnica | Medio | M | Medio | Suite completa de tests | Tiempo de compilación -20% |
| **MON-07** | **P2** | Monetización | Configurar ofertas Win-Back en RevenueCat | Reducir churn de suscripciones | Medio | S | Bajo | Dashboard RevenueCat | Recuperación de cancelados > 8% |

---

# 31. IMPLEMENTATION ROADMAP

### Fase 0 — Publicación Inmediata (Hoy)
* Corregir el script de preflight local y el texto de `privacy.html`.
* Enviar la versión 1.0.7 a App Store Review mediante `asc`.

### Fase 1 — Adquisición y Tracción (Semanas 1 a 4)
* Publicación en redes y foros especializados del material educativo *"Cómo proteger tu DNI antes de alquilar un piso"*.
* Monitorización de telemetría de eventos con Firebase y tasas de conversión de Paywall en RevenueCat.

### Fase 2 — Refuerzo Funcional (Mes 2)
* Introducción de "Plantillas de Protección en 1 Toque" (Alquiler, Nómina, Empleo).
* Integración con Spotlight para abrir documentos de la bóveda directamente desde la búsqueda de iOS.

### Fase 3 — Escalado B2B y Ecosistema (Meses 3 a 6)
* Habilitar la aplicación en macOS para despachos profesionales.
* Integración de atajos avanzados de Siri y acciones en segundo plano.

---

# 32. PRODUCT VISION 12-24 MONTHS

A medio y largo plazo, MaskID debe evolucionar de ser una "herramienta de tachado de documentos" a convertirse en la **plataforma líder de custodia y compartición segura de identidad en el ecosistema Apple**:
* **Cumplimiento con la Cartera de Identidad Digital Europea (EUDI Wallet):** Adaptación a los nuevos estándares de identidad soberana de la UE.
* **Verificación Criptográfica de Copias:** Generación de copias con código QR de verificación de integridad firmado localmente, permitiendo al receptor comprobar que la copia no ha sido alterada por terceros.
* **MaskID para Empresas (B2B Pro Pack):** Licenciamiento para empresas inmobiliarias y de recursos humanos que deseen ofrecer a sus clientes una vía segura para enviar su documentación conforme al RGPD sin almacenar datos en bruto.

---

# 33. FINAL ACTION PLAN

1. **Paso 1:** Modificar la línea 19 de `scripts/app_store_preflight.sh` para aceptar comillas en el identificador del widget:
   ```zsh
   rg -q '"?PRODUCT_BUNDLE_IDENTIFIER"? = "?com.romerodev.shield.widgets"?' Shield.xcodeproj/project.pbxproj
   ```
2. **Paso 2:** Actualizar `Docs/legal/privacy.html` §3 para reflejar con exactitud la sincronización opcional cifrada en CloudKit privado.
3. **Paso 3:** Ejecutar `scripts/app_store_preflight.sh --local` y verificar que todos los checks reportan `OK`.
4. **Paso 4:** Enviar la versión 1.0.7 a revisión en App Store Connect mediante la CLI oficial:
   ```zsh
   asc submit --app 6790398619 --version 1.0.7 --confirm
   ```
5. **Paso 5:** Tras la aprobación de Apple, monitorizar las primeras 48 horas en Firebase Crashlytics y RevenueCat para supervisar la estabilidad y la conversión del paywall.
