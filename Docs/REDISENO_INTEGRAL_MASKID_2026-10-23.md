# MaskID — propuesta integral de producto, UX/UI y APIs Apple

**Fecha:** 23 de octubre de 2026  
**Estado:** propuesta en ejecución. La fase 1 y partes del flujo de la fase 2 están implementadas en el árbol local; la build de pruebas compila. La validación interactiva está en cola por ocupación del simulador principal. App Store Connect no se ha modificado.  
**Alcance:** código y documentación del árbol local, metadata y release log del repo, ficha pública de App Store, documentación oficial de Apple y señales públicas cualitativas de usuarios.  
**Entregable visual:** cinco prototipos interactivos en el flujo adjunto a esta conversación. Son pantallas sintéticas para debatir dirección; no son capturas de la build actual ni creatividades listas para publicar.

> **Corrección de implementación — 24 de octubre de 2026:** tras la recomendación inicial de probar `tabViewBottomAccessory`, el usuario pidió eliminar el Scan flotante porque aparecía en Ajustes y estados vacíos. Esa instrucción posterior prevalece: la shell ya no usa el accesorio ni una quinta tab Scan. Inicio conserva su acción primaria y iPad una acción contextual en su toolbar. Véase la actualización de task 239 y la matriz actual en `docs/iphone-duo/`.

## 1. Decisión de producto

MaskID debe convertirse en **la forma más clara de preparar, revisar y compartir una copia documental con menos datos**, no en otro editor PDF generalista.

La ventaja propia ya existe en el producto: OCR y sugerencias en el dispositivo, control manual, una copia rasterizada separada del original y comprobaciones posteriores a la exportación. La app también dispone de biblioteca cifrada, Bóveda con Face ID/PIN, integración opcional con iCloud, entrada desde el sistema, widgets, Atajos y flujos de varios documentos en el trabajo local.

La prioridad, por tanto, es poner esa confianza delante del usuario en cuatro momentos: ficha de App Store, primera apertura, pantalla Inicio y resultado de exportar. Liquid Glass debe ordenar la navegación y las acciones. El contenido documental debe seguir siendo simple, opaco y legible.

**Propuesta de valor:** “Oculta solo lo que eliges. Revisa cada página. Comparte una copia comprobada.”  
**Límite de promesa:** las comprobaciones describen lo que MaskID inspeccionó en esa exportación; no certifican que se haya encontrado toda la información sensible ni deciden qué debe ver el destinatario.

## 2. Diagnóstico con evidencia

| Hallazgo | Evidencia | Impacto y lectura |
|---|---|---|
| Poca señal pública de confianza | La ficha estadounidense de [MaskID en App Store](https://apps.apple.com/us/app/maskid-protect-your-identity/id6790398619?platform=ipad) indica que todavía no hay suficientes valoraciones o reseñas para mostrar un resumen. | Falta prueba social. La ausencia de reseñas no demuestra que quienes instalaron la app estén insatisfechos; la muestra es muy pequeña. |
| Descubrimiento y conversión son problemas distintos | La revisión autenticada de App Store Connect documentada el 16 de octubre registró 14 descargas por primera vez y conversión de ficha del 4,81 % para el intervalo visible de 90 días (17 jul.–14 oct.). [Informe de auditoría](../tasks/details/222-auditoria-integral-app.md#L59). | La muestra no permite atribuir el resultado a UI, onboarding, precio o keywords. Hay que separar impresiones, visitas de ficha, descargas, origen, territorio y activación antes de elegir una causa. |
| Las capacidades recientes no se veían aún en la release pública consultada | El log de release local registra build 1.1.5 válida, vinculada a `PREPARE_FOR_SUBMISSION`, y señala que no fue enviada a revisión el 21 de octubre. [Release 1.1.5](../tasks/details/235-appstore-release-1-1-5.md#L8). La ficha pública que consulté muestra una versión anterior. | Si el estado de App Store Connect sigue igual, usuarios nuevos no ven todavía las funciones recientes que describen los metadatos locales de 1.1.5. Antes de una campaña, verificar el estado y alinear ficha, versión pública y funciones visibles. La página pública puede tardar en actualizarse. |
| El Inicio concentra demasiadas tareas | En iPhone, `HomeView` apila hero, accesos rápidos, búsqueda, estado de índice, categorías, estadísticas, recientes y espacio de trabajo ([código](../Shield/Views/Home/HomeView.swift#L46)). | Hay amplitud funcional, pero el primer vistazo no necesariamente comunica un único trabajo. La pantalla debe empezar por “Proteger un documento” y dejar biblioteca, bóveda y estilos como destinos secundarios. |
| El permiso de analítica puede interrumpir onboarding | `presentAnalyticsConsentIfNeeded()` solo comprueba la aparición del splash y la respuesta anterior; no espera a `sessionStage == .ready` ([ContentView](../Shield/App/ContentView.swift#L92), [guard actual](../Shield/App/ContentView.swift#L194)). | En una instalación limpia el root permite mostrar una hoja de consentimiento antes de completar onboarding. Es una fricción verificable en código, no una causa demostrada de abandono. Conviene diferirla o integrarla como decisión secundaria después de mostrar valor. |
| Onboarding tiene siete pasos y un paywall al final | La navegación contiene bienvenida, objetivo, inquietudes, demo, permiso de cámara, seguridad y paywall ([OnboardingFlowView](../Shield/Views/Onboarding/OnboardingFlowView.swift#L96)). | La demo interactiva ayuda, pero pedir objetivo, permiso y seguridad antes de que la persona complete su primer documento alarga el camino. Mantener la demo; reducir pasos y dejar cámara, Face ID y nube para cuando se necesiten. |
| El CTA de captura está representado como destino vacío | En iOS 26+, `Tab(value: .capture)` muestra una etiqueta, el `Binding` intercepta la selección y su contenido es `Color.clear` ([ContentView](../Shield/App/ContentView.swift#L367)). | Capturar es una acción, no una ubicación. La tab semántica vacía puede producir estados de navegación confusos y no sigue el patrón moderno de barra como navegación. Apple ofrece `tabViewBottomAccessory` para acciones persistentes que se compactan junto a la tab bar. |
| La app adopta parte del sistema nuevo, no una capa de vidrio propia | El proyecto declara iOS 18 mínimo y usa `TabView` adaptable en iOS 26+; no se encontraron usos de `glassEffect`, `GlassEffectContainer` o `ToolbarSpacer` en las vistas. | El shell puede recibir el estilo de sistema al compilar con el SDK actual. El trabajo no consiste en cubrir todas las tarjetas de vidrio: Apple reserva Liquid Glass para navegación y controles, no para contenido. |
| Vision está dividido entre API Swift y API heredada | Captura usa `RecognizeTextRequest` async ([CaptureOCRServices](../Shield/Views/Capture/CaptureOCRServices.swift#L228)); `ExportVerifier` usa `VNRecognizeTextRequest` y `VNImageRequestHandler` ([ExportVerifier](../Shield/Export/ExportVerifier.swift#L207)). | Unificar el reconocimiento, errores, cancelación y normalización de coordenadas hace más coherente el OCR de producción y el que comprueba la salida. |
| El tema de temporada cambia partes del lenguaje de interfaz | `ShieldTheme.accent`, éxito, aviso e información dependen del tema Halloween ([ShieldTheme.swift](../Shield/Theme/ShieldTheme.swift#L33)); Home añade un fondo estacional ([HomeView.swift](../Shield/Views/Home/HomeView.swift#L36)). | Eso debilita la estandarización si también cambia colores semánticos y foco visual. Mantener el tema base como identidad persistente; si se conservan eventos, limitarlos a decoración opcional que no reinterprete estados, máscaras ni CTA.

### Lo que ya es una fortaleza

- App universal para iPhone/iPad, biblioteca local cifrada y Bóveda autenticada.
- Importación desde VisionKit, Fotos, Archivos y Share Extension; conexión optativa con Google Drive/Dropbox y sincronización privada de iCloud según configuración.
- OCR local mediante la API Swift de Vision; las sugerencias son revisables y el usuario controla las máscaras.
- Exportación rasterizada de PDF o imagen, copia separada del original y comprobaciones de texto, anotaciones y metadatos habituales.
- App Intents, widgets, lenguaje ES/EN, accesibilidad multidispositivo y un flujo de revisión por lotes presente en el trabajo local.

Varias de esas funciones se describen en el release log y metadata local de 1.1.5, que todavía constan como no enviadas a revisión. En esta auditoría no reconstruí ni ejecuté la app; por eso describo estas capacidades como estado de código/documentación y no como una verificación funcional de la build.

## 3. Qué pide el público objetivo

Las conversaciones públicas consultadas son señales cualitativas de comunidades pequeñas; no representan porcentajes del mercado.

| Necesidad observada | Evidencia pública | Implicación de producto |
|---|---|---|
| Redacción real, no una caja que solo parece ocultar texto | En [una discusión sobre redacción de PDF local](https://www.reddit.com/r/macapps/comments/1r62r0r/is_there_an_app_to_redact_text_or_images_from/), las respuestas preguntan si el texto queda eliminado o si solo se tapa. | Mostrar el flujo de copia aplanada y el informe de salida. Nunca anunciar garantía absoluta o “certificación”. |
| Procesamiento local para documentos sensibles | Peticiones de herramientas sin carga a servidores aparecen en [r/pdf](https://www.reddit.com/r/pdf/comments/1qgdg1n/pdf_redaction_app_that_runs_locally/) y en [comentarios de PrivacyCam](https://www.reddit.com/r/iosapps/comments/1x1jfkv/appopen_source_privacycam_hide_sensitive_info/). | Poner “OCR en el dispositivo” antes que “IA”; explicar por separado biblioteca local e iCloud opcional. |
| Revisión de falsos positivos, precisión y zoom | Un usuario profesional describe problemas de selección fina y zoom en [una app móvil de redacción](https://www.reddit.com/r/iosapps/comments/1lfe2dr/); otra conversación sobre detectores comenta falsos positivos en [una discusión de redacción automática](https://www.reddit.com/r/ProductivityApps/comments/1w5270i/ai_pdf_tool_needed_for_hiding_sensitive/). | No aplicar máscaras automáticamente. Dar zoom, pan, selección accesible, corrección sencilla y estado pendiente por página. |
| Búsqueda en el contenido, organización y búsqueda de notas | Una petición de usuarios de PDF solicita nombre, contenido, carpetas y anotaciones en [r/pdf](https://www.reddit.com/r/pdf/comments/1x96l7i/app_request/). | La búsqueda local y los perfiles reutilizables son más valiosos que añadir funciones de edición general sin foco. Excluir la Bóveda bloqueada de la indexación. |
| Cobertura de zonas olvidadas y metadatos | En la publicación de PrivacyCam, usuarios preguntan por MRZ de pasaporte y GPS de la foto ([hilo](https://www.reddit.com/r/iosapps/comments/1x1jfkv/appopen_source_privacycam_hide_sensitive_info/)). | Diseñar recordatorios de revisión por tipo de documento y explicar cuáles metadatos se inspeccionan. No presentar el detector como exhaustivo. |
| Lotes sin sacrificar exactitud | El registro interno de tareas 229–232 prioriza la cola revisable, perfiles, búsqueda y sugerencias; el feedback público sobre OCR suele exigir precisión y corrección manual. | Tratar cada archivo y página con su estado, progreso, error, cancelación y verificación propia; no aplicar una misma geometría a páginas distintas. |

### Segmentos prioritarios

1. **Uso ocasional de identidad:** alquiler, empleo, viaje, alojamiento, seguro, banca o KYC. Quiere resolver un único envío con instrucciones claras y control de la copia.
2. **Trabajo recurrente de oficina pequeña:** autónomos, administración, gestoría, selección o equipos que preparan expedientes. Necesitan reglas reutilizables, búsqueda dentro del PDF, lotes y recuperación de errores.
3. **Archivo personal:** guardar originales por separado y localizar copias protegidas sin exponer nombres o documentos en widgets, notificaciones o analítica.

No recomiendo abrir ahora cuentas de equipo, colaboración ni un backend de OCR. No hay suficiente señal de demanda y complicarían permisos, claves, revocación y borrado.

## 4. Servicios y funciones que no deben faltar

La base está en gran parte en el árbol actual. El siguiente salto está en hacerla fácil de encontrar y cerrar de extremo a extremo.

| Servicio esencial | Nivel esperado | Situación observada / prioridad |
|---|---|---|
| Entrada natural | Escáner de varias páginas; importar imagen/PDF; Fotos, Archivos y Share Sheet; cancelar, reintentar y ver progreso. | Ya hay VisionKit `VNDocumentCameraViewController`, Fotos/Archivos y Share Extension. El límite documentado de Share Extension es un elemento por activación; completar una cola de importación coherente. |
| Motor de protección | OCR con coordenadas y confianza; categorías útiles; filtros/búsqueda; máscara manual precisa, zoom, undo/redo y revisión por página. | OCR y herramientas existen. Alinear el verificador con Vision Swift; evaluar la API estructurada de documentos para tablas/formularios, sin convertir su salida en “PII detectada” automáticamente. |
| Exportación confiable | PDF e imagen; original separado; rasterización de la máscara; comprobaciones en la copia; fallo comprensible y reintento. | Diferenciador central ya presente. La salida PDF queda no seleccionable; conservarla como predeterminada hasta poder demostrar otra salida segura. |
| Biblioteca privada | Búsqueda por título y contenido, categorías, favoritos, perfiles cifrados y estado de cada copia. | Biblioteca, Vault, búsqueda local y perfiles están en el trabajo local. Verificar en la build pública y mantener Vault fuera del índice mientras esté cerrada. |
| Continuidad Apple | Files, Share Sheet, Shortcuts, widgets agregados, Face ID/PIN, iCloud privado solo con opt-in y estado visible. | La app ya ofrece la mayor parte. Los Atajos deben iniciar una tarea o abrir la Vault autenticada; nunca omitir la revisión ni compartir una exportación sin confirmar. |
| Confianza y soporte | Explicación breve de procesamiento; política y límites; asistencia accesible; localización natural; analítica sin contenido documental. | Mantener el enfoque local-first y los eventos agregados. No enviar OCR, texto detectado, nombres de archivo, miniaturas, contenido del documento ni identificadores estables a Firebase o soporte. |
| Compras honestas | Prueba, precio inicial, periodicidad, renovación, restauración y valor Free antes de comprar. | El sistema StoreKit y la divulgación de precio existen. No bloquear la primera exportación útil con un paywall; reservar Pro para uso ilimitado, lotes y repetición avanzada. |

“Todo lo que tiene un editor PDF” no es un servicio esencial para MaskID. Firmar, editar texto libre, formularios, chat con documentos o convertir a docx desplazarían la propuesta sin mejorar la copia segura.

## 5. Dirección UX/UI y cinco prototipos

### Reglas visuales

- **Jerarquía:** un CTA primario visible por pantalla; navegación secundaria estable; el estado de revisión siempre visible.
- **Paleta base:** fondo neutral claro/oscuro, texto de alto contraste, cian/turquesa como acento funcional. Negro sólido para redacción real. Verde reservado a comprobaciones superadas; ámbar/rojo con etiqueta y forma además del color.
- **Liquid Glass:** usar controles estándar de sistema en tab bar, barras de navegación y toolbar. Una acción flotante de captura puede usar `.buttonStyle(.glassProminent)` o `glassEffect`; no aplicar vidrio a tarjetas, fondos de texto, documento escaneado o máscaras.
- **Superficie documental:** páginas sin transparencia ni gradientes detrás; zoom, miniaturas y estado de página fáciles de tocar; no poner controles encima de texto sin contraste.
- **Movimiento:** transiciones breves de navegación, feedback táctil solo para cambios de estado, respetar Reduce Motion y no animar loops llamativos en captura/exportación.
- **Accesibilidad:** controles de al menos 44 pt, VoiceOver para tipo/página/estado/confianza, Dynamic Type, contraste aumentado, Voice Control, teclado/trackpad y alternativas a dibujar con gesto.
- **Adaptación:** mismo modelo de información en iPhone, iPhone Duo e iPad; en ancho regular, documento y herramientas pueden convivir en dos paneles. No estirar un teléfono al tamaño iPad.
- **Marca:** tema base consistente en la app y en cualquier material de tienda. Mantener variantes estacionales fuera de la jerarquía de acciones, semántica de estados y capturas de marketing.

Apple explica que Liquid Glass crea la capa funcional de navegación/controles, pide no usarlo en el contenido y recomienda limitar efectos personalizados; `glassEffect` y `GlassEffectContainer` sirven para controles custom agrupados ([HIG Materials](https://developer.apple.com/design/human-interface-guidelines/materials), [API SwiftUI](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views)).

### Prototipos de pantalla

| # | Pantalla | Qué comunica | Decisión UX |
|---|---|---|---|
| 1 | **Inicio** | “Comparte solo lo necesario”, CTA “Proteger un documento”, fuentes Cámara/Archivos/Fotos y recientes. | El propósito aparece antes que las estadísticas, estilos o servicios; la actividad de lotes muestra una página pendiente. |
| 2 | **Captura/importación** | Encuadre documental, borde detectado y selección alternativa desde Fotos o Archivos. | Scanner y selector de archivo pertenecen a la misma entrada; el primer uso no requiere crear cuenta. |
| 3 | **Revisión de sugerencias** | Página con máscaras confirmadas, sugerencias sin marcar, número de página y progreso de revisión. | La máquina sugiere, la persona decide. No hay un botón “ocultar todo” como acción por defecto. |
| 4 | **Editor** | Página sintética, máscara opaca seleccionada, mover/buscar/deshacer y contador 3/4 páginas revisadas. | Acciones precisas y accesibles; revisión por página evita completar un lote con zonas desalineadas. |
| 5 | **Exportación** | Copia nueva, informe de máscaras/texto/metadatos inspeccionados y acción “Compartir copia protegida”. | La comprobación se explica con alcance y límites; la hoja de compartir recibe la copia exportada, no el original. |

El artefacto interactivo permite recorrer estas cinco pantallas con pestañas y botones. Los nombres, textos y documentos son sintéticos; antes de usar cualquier diseño como screenshot de App Store habría que implementarlo y capturarlo desde la app real con el tema base activo.

## 6. Auditoría de APIs modernas de Apple

| Área | APIs y estado | Recomendación concreta |
|---|---|---|
| Shell, tabs y adaptabilidad | Ya se usa `TabView` con `.sidebarAdaptable` desde iOS 26 y un fallback para versiones anteriores. Apple diseñó `tabViewBottomAccessory` para una acción que acompaña/colapsa con tab bar. | Mantener la tab bar del sistema; convertir Captura de un `Tab` vacío en bottom accessory o toolbar action con fallback iOS 18. Elegir pocos destinos reales. Validar inline/expanded en iPhone y eje vertical de iPhone Duo. |
| Liquid Glass | `glassEffect(_:in:)`, `GlassEffectContainer`, `.interactive()`, `glassEffectID` y `glassEffectTransition` permiten efectos y morphing; los controles estándar adoptan el look automáticamente. | Dejar sistema dibujar navegación. Aplicar efecto custom solo a la acción de Captura o una toolbar flotante. Si varios efectos se funden, envolverlos en `GlassEffectContainer`; no duplicar blur/material en cada fila. Usar IDs de transición solo si representan el mismo control que se transforma. |
| Toolbars adaptables 2027 | SwiftUI añade `visibilityPriority`, `toolbarOverflowMenu`, `topBarPinnedTrailing` y minimización al desplazar. En iOS 27 release notes, el nombre pasa a `toolbarMinimizationBehavior` en lugar de `toolbarMinimizeBehavior`. [SwiftUI What’s New](https://developer.apple.com/swiftui/whats-new/) y [release notes iOS 27](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes). | Usar prioridades para conservar Compartir/Exportar y mover acciones menos frecuentes al overflow en iPad/ventanas estrechas. Verificar disponibilidad exacta en el SDK instalado; no subir deployment target para adoptar un modifier puntual. |
| Búsqueda | SwiftUI `.searchable` y las experiencias de búsqueda de `TabView` colocan el campo en el lugar del sistema según el dispositivo. WWDC25 explica barra de búsqueda adaptativa y rol de search tab ([video](https://developer.apple.com/videos/play/wwdc2025/323/)). | Poner búsqueda por título y texto dentro de Biblioteca con `.searchable`. Usar una search tab solo si es un destino frecuente, no para añadir otra tab. Preservar exclusión de Vault bloqueada, búsqueda local y apertura controlada de coincidencias. |
| Captura | App usa VisionKit `VNDocumentCameraViewController`; `PhotosPicker` y selector de Archivos cubren medios existentes. | Mantener las superficies de sistema y mejorar handoff/progreso propio después del selector. No recrear un scanner custom solo por estilo. |
| OCR y estructura | `RecognizeTextRequest` es la API Swift async moderna de Vision, disponible desde la familia iOS 18; `RecognizeDocumentsRequest` agrupa contenido de documento, tablas/listas y códigos, y ofrece observaciones con ubicación/confianza ([Vision](https://developer.apple.com/documentation/vision), [RecognizeDocumentsRequest](https://developer.apple.com/documentation/vision/recognizedocumentsrequest)). | Unificar `CaptureOCRServices` y `ExportVerifier` en Vision Swift; considerar `RecognizeDocumentsRequest` para preservar contexto de formularios y tablas. Su salida es estructura/texto, no un juicio de sensibilidad. Mantener las reglas de MaskID, umbrales explícitos y confirmación humana. |
| Document API | SwiftUI document APIs de la generación Xcode 27 amplían `ReadableDocument`, `WritableDocument`, `DocumentReader/Writer`, progreso incremental y `DocumentCreationSource` ([documentación](https://developer.apple.com/swiftui/whats-new/), [DocumentCreationSource](https://developer.apple.com/documentation/swiftui/documentcreationsource)). | Evaluar un adaptador en importación/abrir desde Archivos y exportación directa. No migrar el archivo privado interno a `DocumentGroup` sin diseñar primero AES-GCM, originales inmutables, Bóveda y permisos de URL. Comprobar disponibilidad concreta contra SDK antes de planear adopción. |
| Compartir y automatizar | Share Extension, App Intents, WidgetKit y StoreKit 2 ya están en el proyecto. | Usar APIs de sistema, App Shortcuts y hoja de compartir estándar. Un intent puede abrir captura o preparar el inicio; el usuario confirma las máscaras y la salida antes de compartir. No introducir Live Activities con nombres de archivos ni datos sensibles. |
| Seguridad y cloud | LocalAuthentication, Keychain y CloudKit opt-in ya dan los bloques adecuados. | No añadir backend de documentos. Explicar por separado cifrado local, Bóveda y sincronización iCloud; el consentimiento cloud debe ser explícito, revocable y describir qué contenido se sincroniza. |

Apple afirma que las apps compiladas con SDK actual reciben el look Liquid Glass en componentes de sistema. La guía de materiales pide no poner ese material en la capa de contenido. El [video WWDC25 “Build a SwiftUI app with the new design”](https://developer.apple.com/videos/play/wwdc2025/323/) cubre tabs adaptables, bottom accessory, toolbar, búsqueda y custom glass; la [novedad SwiftUI 2027](https://developer.apple.com/videos/play/wwdc2026/269/) describe cambios adicionales y APIs de documentos.

## 7. App Store, posicionamiento y adquisición

### Lectura de ficha

El nombre español actual, “MaskID: Protege Datos Privados”, usa los 30 caracteres disponibles; el subtítulo “Oculta Datos al Compartir” describe el beneficio, pero repite “datos” y deja fuera una intención concreta de búsqueda. La ficha inglesa también comunica privacidad de forma amplia. Recomiendo probar un término de problema/archivo en título y mostrar el mecanismo de confianza en screenshots.

Apple documenta que la búsqueda considera coincidencias de nombre, subtítulo, keywords y categoría junto con comportamiento de usuarios; no publica pesos que permitan prometer posicionamiento. Nombre y subtítulo admiten hasta 30 caracteres; keywords, 100 bytes; promotional text, 170 caracteres ([Search](https://developer.apple.com/app-store/search/), [límites de metadata](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/), [campos por versión](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)). Las siguientes opciones son hipótesis en ES-ES y EN-US; deben compararse con Analytics y no implican volumen de búsqueda conocido.

| Campo | es-ES propuesta | Conteo | en-US propuesta | Conteo |
|---|---|---:|---|---:|
| Nombre | `MaskID: Oculta datos` | 20/30 caracteres | `MaskID: Hide Personal Data` | 26/30 caracteres |
| Subtítulo | `DNI y PDF antes de enviar` | 25/30 caracteres | `Redact PDFs before sharing` | 26/30 caracteres |
| Keywords | `pasaporte,redactar,tachar,anonimizar,privacidad,iban,firma,nómina,contrato,metadatos,ocr,escáner` | 98/100 bytes | `passport,redact,redaction,privacy,identity,iban,signature,paystub,contract,metadata,scanner,OCR` | 95/100 bytes |
| Texto promocional | `Tapa solo lo que sobra. Revisa cada página y comprueba la copia antes de compartirla, con procesamiento en el dispositivo.` | 122/170 caracteres | `Hide only what is not needed. Review every page and check the exported copy on your device before sharing.` | 106/170 caracteres |
| Primeras líneas de descripción | `¿Te piden una copia de tu DNI, nómina o pasaporte? Tapa solo los datos que no hacen falta; revisa cada página y comprueba la copia antes de compartirla.` | 152/4.000 caracteres | `Need to share an ID, payslip, or passport? Mask only what you choose. Review every page and check the exported copy before sharing. OCR runs on your device; you stay in control.` | 177/4.000 caracteres |

**Categoría:** mantener Utilities como principal mientras el uso sea preparar una copia de privacidad. No repetir en keywords los términos ya usados en el título/subtítulo; revisar tokenización y bytes desde metadata local antes de sincronizar.

### Relato de screenshots de tienda

Secuencia inicial de cinco piezas para la ficha, en tema base y con datos sintéticos:

1. **Comparte solo lo necesario** — documento antes/después; beneficio legible de inmediato.
2. **Revisa cada sugerencia** — sugerencias visibles sin autoaplicar.
3. **Comprueba la copia exportada** — checks verificables y nota de límites.
4. **Protege todas las páginas** — contador/revisión multipágina y lote por archivo.
5. **Mantén tus documentos bajo tu control** — OCR en el dispositivo, bóveda local, cuenta no obligatoria e iCloud opcional explicado con precisión.

Usar UI real de la build pública, no estos prototipos sintéticos. No usar “100 % privado”, “nunca sale del teléfono”, “irrecuperable”, “certificado” ni “la IA oculta todo”; algunos flujos pueden usar proveedores cloud elegidos por la persona y el detector no es exhaustivo.

### Experimentos

1. **Primero liberar la historia funcional:** comprobar estado de 1.1.5 y publicar solo después de validar release y metadatos. Asegurar que cada claim de la ficha coincide con una función accesible en esa build.
2. **PPO de una sola hipótesis:** ficha actual como control frente a una variante que cambia solo la historia de capturas —“editor/funciones” frente a “copia revisada y comprobada”—. Apple PPO admite hasta tres tratamientos y prueba icono, screenshots y previews; no prueba título ni keywords. Esperar a que App Analytics estime confianza suficiente y detener si la muestra no puede decidir ([PPO](https://developer.apple.com/help/app-store-connect/create-product-page-optimization-tests/overview-of-product-page-optimization/)).
3. **Custom Product Pages cuando haya canal:** páginas y deep links separados para compartir DNI/alquiler, documentos de empleo y documentación bancaria; asignar keywords solo si intención, copy y destino coinciden. Apple permite páginas con assets/localización propios y medirlas por separado ([CPP](https://developer.apple.com/app-store/custom-product-pages/)).
4. **Solicitar reseña con criterio:** después de una o más exportaciones comprobadas satisfactorias, sin incentivos, filtros ni pedir reseña antes de la tarea. Complementar con feedback privado en un momento opcional.

## 8. Medición del rediseño

| Etapa | Métrica | Pregunta que responde |
|---|---|---|
| Descubrimiento | Impresiones únicas y fuente: Search, Browse, web/referral, territorio y dispositivo. | ¿La gente objetivo encuentra MaskID? |
| Ficha | Visitas únicas, descargas y conversión por producto/página/localización. | ¿La ficha convierte la exposición en una instalación? |
| Activación | Inicio/completitud de onboarding, primera importación, primera revisión y tiempo hasta primera exportación comprobada. | ¿La persona entiende el producto y obtiene valor sin fricción? |
| Calidad de flujo | Importación fallida/cancelada, páginas con revisión pendiente, exportación que falla checks, recuperación de lote. | ¿Dónde se corta el trabajo seguro? |
| Retención | Sesión y regreso por cohorte de descarga, uso recurrente de búsqueda/perfiles/lotes. | ¿La app sirve de nuevo o es una utilidad de una sola vez? |
| Negocio | Vista de paywall, selección, trial, compra, renovación, cancelación y restauración. | ¿Pro aumenta capacidad sin bloquear el uso básico? |

App Store Connect define impresiones, visitas de ficha, conversiones, descargas, fuentes, retención y páginas custom; los datos de uso pueden tener umbrales de privacidad ([Analytics](https://developer.apple.com/app-store-connect/analytics/), [acquisition funnel](https://developer.apple.com/help/app-store-connect-analytics/acquisition/acquisition/)). Evaluar tasas por cohortes comparables y no usar un benchmark universal. Mantener medición sin datos de OCR, ID, documentos ni identificadores que permitan reconstruir el expediente; el Analytics de terceros sigue opt-in.

## 9. Plan de ejecución y criterios de aceptación

### Fase 0 — Comprobar release y línea base

- Confirmar la versión pública y el estado real de 1.1.5 en App Store Connect; comparar metadata, capturas, privacidad y build.
- Revisar impresiones/fuentes/territorios y producto-pages; fijar una ventana de comparación. No inferir causa de 14 descargas.
- Confirmar en primera ejecución si la hoja de analítica tapa onboarding; medir cómo se llega a valor en una instalación limpia.

**Aceptación:** release y ficha coherentes; línea base de impresiones → visita → descarga y primer export; consentimiento no interrumpe el primer valor.

### Fase 1 — Primera sesión y UI principal

- Comprimir onboarding a tres momentos: promesa y ejemplo, demo breve revisable, seguridad/permisos opcionales cuando se usan. Mover el paywall después de una exportación útil o de una acción Pro.
- Inicio con CTA “Proteger un documento”, acceso Cámara/Archivos/Fotos, cola pendiente y recientes; quitar redundancia de estadísticas/atajos del primer viewport.
- Reemplazar el destino Tab vacío por bottom accessory/acción de Captura; conservar navegación nativa y alternativas para iOS 18.
- Formalizar tema base y replegar el tratamiento estacional a decoración no semántica.

**Aceptación:** desde la primera apertura se entiende qué hace MaskID y se inicia un documento en un solo toque; el consentimiento de analítica no bloquea onboarding; VoiceOver y Dynamic Type conservan estructura y CTA.

### Fase 2 — Flujo de redacción coherente

- Diseñar estados de página y archivo: sin revisar, revisado, exportando, comprobado, fallo y reintento.
- Unificar API Vision de detección y verificación; añadir `RecognizeDocumentsRequest` solo si mejora tablas/formularios en corpus etiquetado y sin elevar falsos positivos.
- Ubicar `.searchable` en Biblioteca y el inspector en el editor; mantener perfiles, búsqueda y queue en almacenamiento local cifrado.
- Preservar rasterización predeterminada, resolución original, metadatos inspeccionados y checks actuales. Una exportación no completada no se abre en Share Sheet.

**Aceptación:** cada máscara se asocia a página y evidencia; cada página requiere su estado de revisión; el lote falla de forma aislada por archivo y retoma el resto; no se comparte una salida que no pasó su verificador.

### Fase 3 — Tienda y adquisición

- Una vez publicada la build y sincronizados claims, experimentar primero solo con storyboard de screenshots; probar metadata ES/EN en un cambio separado.
- Crear CPP por intención únicamente con un canal que pueda medir tráfico y una deep link al destino correcto.
- Solicitar reseñas tras éxito real y recoger feedback de salida sin datos documentales.

**Aceptación:** App Analytics separa la ficha original y variantes/páginas, atribución por origen y conversión; se aplican solo cambios respaldados por una tendencia y por una lectura de confianza del test.

### Fase 4 — Evolución con demanda

- Evaluar reglas personales/regex, selección de muchos elementos en Share Sheet, PDF buscable reconstruido, app Mac o colaboración solo con entrevistas, métricas de retención y threat model correspondiente.
- No añadir reloj, servidor propio, login obligatorio, IA remota ni editor de PDF genérico como respuesta automática al bajo número de descargas.

## 10. Ejecución y validación — 23 de octubre de 2026

### Hecho en el árbol local

- Primera sesión reducida a tres momentos: promesa, demo interactiva y seguridad opcional. La cámara ya no se solicita durante el onboarding; el permiso se pide al empezar a capturar. El consentimiento de analítica no aparece antes de que la persona llegue a Inicio y sigue desactivado por defecto, con control en Privacidad.
- Inicio prioriza una sola acción “Proteger un documento”; se eliminaron atajos duplicados y la CTA de captura dejó de ser una tab semántica vacía. En iOS 26+ se usa `TabView` adaptable y `tabViewBottomAccessory`; la versión anterior conserva sus controles existentes.
- El botón principal usa el estilo de sistema `.glassProminent` en iOS 26+ y un estilo compatible en versiones anteriores. El accesorio de captura lee `tabViewBottomAccessoryPlacement`: se reduce a icono cuando va inline y mantiene icono más texto cuando está expandido, con etiqueta accesible estable. El vidrio se limita a acciones de navegación/jerarquía; no se ha aplicado a tarjetas de contenido. Apple recomienda reservar Liquid Glass para controles prioritarios y agrupar los efectos personalizados cuando haya varios.
- La Biblioteca incorpora búsqueda nativa con `.searchable`; el verificador de exportación usa `RecognizeTextRequest` de Vision y mantiene la ruta OCR en el dispositivo.
- La hoja “Añadir a Bóveda” elimina el último `NavigationView` del proyecto en favor de `NavigationStack`; cada fila seleccionable ahora es un `Button` con estado seleccionado anunciado a VoiceOver.
- El tema base es la selección estable inicial. Los colores de éxito, aviso e información mantienen el mismo significado entre temas. Los temas estacionales quedan como elección decorativa de Pro, sin reinterpretar estados de privacidad.
- Se preparó metadata local 1.1.6 en ES/EN. Tras la auditoría ASO, se retiró una keyword duplicada con el subtítulo en inglés y se cambió “redactar” por “ocultar” en español. No se ha enviado la metadata a App Store Connect.
- La lógica de cola por archivo/página, fidelidad geométrica de PDF, búsqueda OCR y perfiles cifrados, y sugerencias locales de rostros se encuentran implementadas en las tareas 229–232 del árbol. El PDF rasterizado sigue siendo la única salida protegida; la decisión no-go para texto seleccionable está documentada en la tarea 233.

### Evidencia y límites actuales

- `xcodebuild build-for-testing -project Shield.xcodeproj -scheme Shield -destination 'id=1454EA8D-A019-4B07-B57C-1433E0F21BE0' -derivedDataPath build/MaskID-Redesign-237 CODE_SIGNING_ALLOWED=NO`: **BUILD SUCCEEDED**. `git diff --check` no reportó errores. La única advertencia observada procede de headers deprecados de `StoreKitTest` incluidos por el SDK; no procede del código de MaskID.
- La configuración `Release` también compila con el destino explícito iPhone 18 Pro y `CODE_SIGNING_ALLOWED=NO`. Ninguno de los dos builds instaló ni lanzó la app; todavía no equivalen a una validación funcional.
- Se prepararon dos builds adicionales `build-for-testing` con code signing habilitado. Xcode las firmó ad hoc para Simulator aunque se indicó la identidad de distribución disponible; `codesign --verify --deep --strict` pasó para la app y el runner UI. Los `*.app-Simulated.xcent` generados sí contienen los grupos de App Group/Keychain y los claims de CloudKit del proyecto, pero la firma Mach-O reporta un diccionario de entitlements vacío. No se afirma que esos claims funcionen en runtime hasta instalarlos y probarlos en el simulador libre.
- Ese build solo compiló. No se instaló ni lanzó ninguna app ni se ejecutaron tests en esta sesión. CoreSimulator no respondió en la primera lectura; después se pudo leer el inventario y los procesos con `simctl` de solo lectura. El iPhone 18 Pro `1454EA8D-A019-4B07-B57C-1433E0F21BE0` (iOS 27.0) está booted con `com.upledger.app` activo; la tarea 211 también espera ese dispositivo. El iPhone Duo `BF5C28D6-2B6D-46FC-82E8-9A248F5C0186` (iOS 27.1) y el iPad Pro 13-inch M5 `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1` (iPadOS 27.0) mantienen procesos de otras apps, incluido MaskID. No se tomó control ni se instaló sobre ellos; la matriz exige empezar por el iPhone 18 Pro y continuar solo cuando cada destino esté libre.
- El proyecto no tiene target watchOS; no corresponde instalar una app en Apple Watch. El mínimo del target principal sigue siendo iOS 18.0 y no hay runtime iOS 18 disponible para validar el comportamiento en ese mínimo.
- App Store Connect leído en modo lectura confirma que 1.1.5 está disponible para distribución y la revisión quedó completada. La nota histórica “no enviada a revisión” de la tarea 235 describe un estado anterior y queda corregida en su registro.
- La línea base de Analytics y sus límites se documentan en [ASO_BASELINE_MASKID_2026-10-23.md](ASO_BASELINE_MASKID_2026-10-23.md). La solicitud existente es una foto histórica, no un feed continuo; no se ha creado otra solicitud ni se ha lanzado PPO/CPP.
- La validación visual pendiente debe recorrer iPhone 18 Pro primero, luego iPhone Duo y después iPad. Incluir onboarding fresco, búsqueda, importación, cola por archivo, detecciones y falsos positivos, zoom/VoiceOver, PDF multipágina, fallo/reintento, exportación adversarial, modo oscuro, Dynamic Type, Reduce Motion/Transparency y Split View/Stage Manager. Para capturas de tienda, confirmar tema base dentro de la app antes de capturar.

### Criterio de adopción de Liquid Glass

La app conserva `NavigationStack`, `TabView`, toolbars, búsqueda y controles de SwiftUI para que el sistema aplique su presentación nativa. Se usa `tabViewBottomAccessory` para una acción persistente, no para crear una quinta ubicación vacía. El `.glassProminent` se aplica a la CTA principal y los materiales de contenido siguen opacos y legibles. Para cualquier componente personalizado posterior, seguir la recomendación de Apple de uso escaso, probar Reduce Transparency/Reduce Motion y utilizar `GlassEffectContainer` solo cuando existan varios efectos de vidrio que deban combinarse.

## Fuentes principales

- Apple: [Materiales y Liquid Glass](https://developer.apple.com/design/human-interface-guidelines/materials), [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/SwiftUI/Applying-Liquid-Glass-to-custom-views), [SwiftUI What’s New](https://developer.apple.com/swiftui/whats-new/), [SwiftUI WWDC26](https://developer.apple.com/videos/play/wwdc2026/269/).
- Apple: [`tabViewBottomAccessory`](https://developer.apple.com/documentation/swiftui/view/tabviewbottomaccessory%28content%3A%29), [`TabViewBottomAccessoryPlacement`](https://developer.apple.com/documentation/swiftui/TabViewBottomAccessoryPlacement), [`RecognizeTextRequest`](https://developer.apple.com/documentation/vision/recognizetextrequest).
- Apple: [Vision](https://developer.apple.com/documentation/vision), [`RecognizeDocumentsRequest`](https://developer.apple.com/documentation/vision/recognizedocumentsrequest), [App Store search](https://developer.apple.com/app-store/search/), [metadata limits](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/).
- Apple: [App Analytics](https://developer.apple.com/app-store-connect/analytics/), [definiciones de métricas](https://developer.apple.com/help/app-store-connect-analytics/reference/metrics-definitions/), [Analytics Reports API](https://developer.apple.com/help/app-store-connect-analytics/overview/analytics-reports-api/), [Product Page Optimization y confianza](https://developer.apple.com/help/app-store-connect-analytics/acquisition/product-page-optimization), [Custom Product Pages](https://developer.apple.com/app-store/custom-product-pages/).
- Usuarios: [consulta de redacción local](https://www.reddit.com/r/macapps/comments/1r62r0r/is_there_an_app_to_redact_text_or_images_from/), [petición de búsqueda/organización PDF](https://www.reddit.com/r/pdf/comments/1x96l7i/app_request/), [comentarios sobre precisión y MRZ/metadata](https://www.reddit.com/r/iosapps/comments/1x1jfkv/appopen_source_privacycam_hide_sensitive_info/), [zoom y selección fina](https://www.reddit.com/r/iosapps/comments/1lfe2dr/).

La evidencia comunitaria es cualitativa y sesgada a personas que publican en foros. Las decisiones de prioridad deben actualizarse con datos de App Store Connect, pruebas de tareas y feedback de usuarios de MaskID.
