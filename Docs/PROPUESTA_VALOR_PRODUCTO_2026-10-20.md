# MaskID — análisis de producto y propuesta para ampliar valor

**Fecha:** 20 de octubre de 2026  
**Alcance de la auditoría inicial:** lectura del código y documentación del repositorio, revisión de la ficha pública de App Store e investigación competitiva y comunitaria. Esa fase fue de análisis; la ampliación posterior de Inicio y widgets se registra en la tarea 226.

## Resumen ejecutivo

MaskID resuelve una necesidad concreta: compartir un DNI, pasaporte, nómina, formulario o PDF sin entregar todos los datos que contiene. Su valor diferencial es combinar OCR local, revisión humana, máscaras editables, una copia exportada aplanada y comprobaciones posteriores a la exportación. La bóveda cifrada, el uso sin cuenta y la sincronización de iCloud opcional completan la propuesta.

La mejor dirección es hacer que MaskID sea **el flujo de trabajo más fiable para preparar, revisar y entregar una copia documental segura**, en vez de crecer ahora hacia un editor PDF general. El núcleo ya existe; el principal margen de valor está en completar las operaciones repetidas y de varios documentos sin debilitar la revisión ni la privacidad.

Las prioridades son:

1. Corregir la aplicación de máscaras por lotes para que cada página use sus propias detecciones. Actualmente se reutilizan las mismas coordenadas en todas las páginas.
2. Conservar la resolución del PDF de origen durante la exportación.
3. Convertir el modo por lotes actual —que aplica sugerencias a documentos ya guardados— en una cola completa de entrada, revisión individual y exportación verificada por archivo.
4. Añadir búsqueda dentro del documento por texto, listas y términos definidos por el usuario, con resultados que siempre requieren revisión.
5. Permitir guardar perfiles de protección propios y volver a aplicarlos.
6. Ampliar la entrada desde la hoja Compartir y los Atajos después de asegurar la cola por lotes.
7. Ofrecer una salida con texto seleccionable como opción avanzada solo cuando pueda reconstruirse y verificarse con el mismo nivel de cuidado que la salida rasterizada actual.

## Plan de ejecución acordado — 21 de octubre de 2026

La implementación autorizada se organiza en este orden. La validación de dispositivo se reserva para cuando todas las funcionalidades de esta tanda estén integradas.

1. **Completar el núcleo seguro:** cola de importación con progreso, cancelación y reintento por archivo; evidencia OCR estrictamente por página; revisión manual antes de exportar; y exportación que conserva tamaño y orientación del PDF fuente. Tareas 229–230.
2. **Cerrar la repetición de políticas:** búsqueda local del contenido OCR con coincidencias por página y revelado explícito; OCR bajo demanda para documentos antiguos sin índice; perfiles editables cifrados con máscara, marca de agua y salida preferida. La Bóveda queda fuera de indexación. Tarea 231.
3. **Añadir sugerencias visuales acotadas:** detección de rostros local, deduplicada por página y siempre confirmada por el usuario. Mantener visible la falta de un corpus consentido para medir falsos positivos y omisiones. Tarea 232.
4. **Mantener la salida PDF rasterizada:** decisión “no-go” para texto seleccionable hasta poder reconstruir y verificar de forma adversarial todos los objetos de salida. Tarea 233.
5. **Cerrar la experiencia y comprobarla:** terminar los últimos ajustes multidispositivo y accesibilidad de la tarea 226; compilar e instalar una sola build en iPhone 18 Pro, después Duo e iPad, y validar watchOS solo si existe un destino. Confirmar runtimes/UDID/ocupación antes de usar cada simulador; ejecutar pruebas focalizadas, unitarias y UI sobre la build instalada.

**Estado previo a la matriz final:** las tareas 229–233 tienen la implementación principal en el árbol de trabajo y cobertura preparada. Quedan la ejecución de compilación/pruebas de esta tanda, la inspección visual por dispositivo, y el cierre de los hallazgos que dependan de esa evidencia. El alcance no incluye compartir perfiles de protección entre cuentas: el proyecto no implementa sesiones compartidas ni sincroniza estos perfiles. El benchmark de rostros también queda pendiente de un corpus con permisos y etiquetas.

**Siguiente ciclo de producto, fuera de esta validación:** diccionarios de términos personales persistentes, expresiones regulares seguras, importación múltiple desde Share Sheet/Atajos, salida reconstruida y compartición en equipo. Priorizarlo según uso y comentarios consentidos, sin presentarlo como terminado.

La ficha pública de App Store describe correctamente la filosofía de MaskID: revisar cada sugerencia y cada página, compartir la copia protegida y no afirmar que el detector encuentre todo. La ficha estadounidense muestra una sola valoración; por ahora no hay volumen público suficiente para tratarla como una muestra representativa de satisfacción o demanda. Las referencias a necesidades comunitarias en este informe son señales cualitativas, no estadísticas de mercado.

## Qué ofrece MaskID hoy

La propuesta y el inventario se contrastaron con la ficha pública de App Store y con el estado del código disponible en el repositorio. El directorio ya contiene una refactorización multidispositivo sin confirmar; por eso este informe describe el estado del árbol de trabajo y diferencia las funciones comprobadas de las oportunidades.

| Parte del flujo | Estado actual comprobado | Lectura de producto |
|---|---|---|
| Entrada | Escáner/cámara, Fotos y Archivos; importación PDF e imagen; importación OAuth directa desde Google Drive y Dropbox cuando están configurados. La Share Extension admite un archivo o imagen por envío ([límite configurado](../ShareExtension/Info.plist#L23)). | La persona puede entrar desde varias fuentes, pero un expediente con varios archivos requiere repetir el inicio. |
| OCR y detección | Reconocimiento en el dispositivo y evidencia espacial para 13 tipos estructurados, entre ellos nombre, documento, MRZ, fecha, dirección, email, teléfono, IBAN, tarjeta y código de barras ([inventario del modelo](../Shield/Models/Document.swift#L97)). | El producto mantiene a la persona en control. El detector es una ayuda y la cobertura depende del tipo de dato, idioma y calidad de imagen. |
| Protección | Edición manual, máscaras visuales y nueve intenciones predefinidas —alquiler, empleo, hotel, banca, marketplace, viajes, escuela, seguro y personalizada— más texto de marca de agua. | Hay buena cobertura de casos frecuentes. Las intenciones son fijas y no forman todavía una biblioteca de políticas personales reutilizables. |
| Bóveda y biblioteca | Almacén local cifrado, bóveda con Face ID/PIN, categorías, favoritos, ordenación y búsqueda por título. La sincronización privada de CloudKit es opcional para documentos fuera de la Bóveda. | Satisface custodia individual y continuidad entre dispositivos Apple; no es un espacio compartido de equipo. |
| Exportación | PDF rasterizado o imagen, comprobaciones de texto extraíble, anotaciones, metadatos conocidos y OCR residual dentro de las zonas protegidas. El informe cuenta páginas revisadas y elementos pendientes. | Es un diferenciador de confianza. La rasterización impide que el texto protegido siga debajo de una capa, aunque el PDF deja de ser seleccionable o buscable. |
| Automatización | Controles/widgets y Atajos que abren Captura o Bóveda ([App Intents](../Shield/App/ShieldAppIntents.swift#L4)). | La integración del sistema reduce pasos de entrada, pero los Atajos no ejecutan todavía una política de protección y exportación. |
| Procesamiento por lotes | Pro permite seleccionar documentos ya guardados y añadirles máscaras con un modo elegido ([flujo actual](../Shield/Views/Home/HomeView.swift#L1945)). | Es una primera herramienta de lote, no una cola completa de importación, revisión y salida verificada. |
| Plataforma | App iOS/iPadOS en español e inglés; las adaptaciones de iPhone Duo/iPad aparecen activas en la tarea 226. No hay un destino nativo de macOS ni watchOS en el proyecto. | El alcance Apple móvil es coherente. Una app de escritorio sería una ampliación posterior para expedientes grandes y flujos profesionales. |

La ficha pública también explica que el usuario debe revisar todas las páginas y el destinatario, que el procesamiento OCR puede funcionar sin internet y que la sincronización de CloudKit almacena paquetes restaurables completos fuera de la Bóveda. Mantener esa claridad es parte del valor del producto, no solo cumplimiento.

En la oferta actual, Free incluye máscaras manuales, sugerencias OCR, exportación protegida y Bóveda local, con un máximo acumulado de 10 documentos procesados. Pro añade procesamiento ilimitado, herramientas por lotes, estilos y controles adicionales, flujos por intención y funciones de nube opcionales. La ficha muestra compras dentro de la app; los precios varían por región y no son el centro de esta propuesta.

## Brechas comprobadas que conviene resolver primero

### P0 — El lote puede aplicar una máscara incorrecta en páginas distintas

En BatchRedactView, las sugerencias y rectángulos del modo se calculan una vez por documento y luego se agregan a todas sus páginas ([cálculo y aplicación](../Shield/Views/Home/HomeView.swift#L1956)). La detección usada para decidir esas coordenadas no se recalcula para cada página. En un contrato multipágina con encabezados, tablas o diseños distintos, una máscara puede tapar una zona inocua en una página y dejar visible un dato sensible en otra.

**Impacto:** la persona puede interpretar “lote completado” como una protección consistente cuando la geometría no coincide con todas las páginas. Es el riesgo de producto más importante porque el lote opera en el núcleo de privacidad.

**Propuesta ejecutable:**

1. Ejecutar OCR y detección por página; asociar cada sugerencia con su página y evidencia.
2. Presentar una cola que permita revisar y corregir cada página antes de aplicar.
3. Mantener un estado individual por archivo: pendiente, revisado, exportado, verificado o necesita atención.
4. Permitir cancelar, reintentar y volver a un documento sin perder el avance.
5. No declarar el lote listo para compartir hasta que cada archivo haya generado y pasado su propia verificación.

**Aceptación:** un PDF de prueba con plantillas diferentes por página produce rectángulos distintos donde corresponde; el historial permite identificar qué páginas se revisaron; un archivo fallido no se mezcla con los terminados.

### P1 — Los PDF importados pierden detalle fino

El importador renderiza cada página de un PDF a un máximo de 2.048 píxeles ([límite de importación](../Shield/Views/Capture/ImportPipeline.swift#L36)) y guarda esas imágenes para editar. El exportador prioriza esas imágenes guardadas cuando existen ([selección de fuente](../Shield/Views/Editor/ExportServices.swift#L42)); por esa ruta no vuelve a renderizar el PDF original con la escala elegida para la exportación.

**Impacto:** texto pequeño, sellos y líneas finas pueden perder nitidez al ampliar o imprimir, justo en nóminas, contratos y formularios que deben seguir siendo legibles después de ocultar datos.

**Propuesta ejecutable:** conservar el PDF original como fuente canónica de renderizado; mapear cada máscara a las coordenadas originales de página; producir la imagen a la escala seleccionada y verificar que el resultado conserve dimensiones, páginas y cobertura de máscaras. Mantener imágenes reducidas solo para vistas previas y OCR cuando sea apropiado.

**Aceptación:** comparativa visual de texto pequeño y líneas finas en entrada y salida a varios niveles de zoom, con redacciones y marcas de agua verificadas; medición de memoria en documentos largos.

### P1 — La búsqueda actual encuentra títulos, no datos dentro del documento

La búsqueda de biblioteca compara el término con el título del documento ([filtro actual](../Shield/ViewModels/AppState.swift#L497)). El editor no ofrece una búsqueda de texto o de varias expresiones a través de las páginas. Tampoco hay una lista de términos propios para nombres de terceros, códigos de expediente o identificadores recurrentes.

**Impacto:** en contratos, extractos y expedientes largos, la persona debe encontrar cada aparición manualmente o confiar solo en la clasificación OCR.

**Propuesta ejecutable:** búsqueda local por frase, lista de términos y, en una segunda iteración, expresiones regulares con límites de tiempo. En PDFs escaneados, usar OCR por página. Mostrar ocurrencias y página, agrupar duplicados y dejar todo sin seleccionar hasta que la persona confirme. Guardar términos o patrones únicamente a petición del usuario y en almacenamiento protegido.

**Aceptación:** pruebas con variantes de mayúsculas, acentos, separadores de dígitos, saltos de línea y OCR; ninguna coincidencia se aplica hasta ser revisada.

### P1 — Los perfiles son fijos; el modo personalizado no guarda una política propia

Las nueve intenciones incorporadas son útiles, pero no se pueden adaptar y guardar como perfiles del usuario. En el código, la intención “Personalizada” establece el texto de marca de agua y termina ([aplicación de la intención](../Shield/ViewModels/EditorViewModel.swift#L425)); la selección de campos sigue dependiendo de la edición manual posterior.

**Impacto:** quien comparte documentos con los mismos requisitos repite configuración y puede olvidar una regla entre sesiones.

**Propuesta ejecutable:** perfiles editables con campos que se ocultan o conservan, tipo de máscara, watermark, formato de salida y detector habilitado. Separar la sugerencia de la acción destructiva: al aplicar un perfil, mostrar las sugerencias por página y permitir aceptar, descartar o añadir zonas antes de exportar. Añadir una explicación breve de por qué el perfil mantiene cada campo visible.

**Aceptación:** perfiles duplicables, renombrables y eliminables; perfil “Personalizado” realmente configurable; campos protegidos nunca se incorporan a telemetría.

### P2 — Falta una detección sugerida para caras visibles

No encontré en el código un flujo de detección de caras o de firmas visuales. La máscara manual permite cubrir una fotografía o firma, pero obliga al usuario a detectarlas por su cuenta. Las alternativas móviles ya anuncian sugerencias locales para caras y texto.

**Propuesta ejecutable:** usar detección local de caras como una sugerencia revisable, no como una redacción automática. Priorizar la detección de cara para documentos o imágenes de terceros y permitir elegir mantenerla visible. Tratar la detección de firmas como una fase de investigación posterior: su variabilidad hace que un resultado automático requiera una evaluación de calidad independiente.

**Aceptación:** evaluación local por documento y condición de imagen, con tasas de omisión y falsas sugerencias publicadas internamente; ninguna cara se cubre sin confirmación.

## Comparativa útil

La comparación se limita a capacidades observables en fichas o páginas oficiales y no intenta inferir cuota de mercado, ventas o calidad de detección.

| Producto | Capacidades públicas relevantes | Implicación para MaskID |
|---|---|---|
| **MaskID** | OCR y redacción local, intenciones, salida rasterizada revisada, bóveda cifrada, iCloud opcional y controles de privacidad. | La confianza del flujo seguro es su posición más propia. Cerrar el lote multipágina y conservar calidad de salida tiene más valor que añadir edición PDF genérica. |
| **Redacted** | Share Sheet, importación desde Fotos/Archivos, sugerencias locales de texto y caras, edición multipágina y Apple Pencil en iPad, flujo de carpetas por lotes en Mac; una compra universal según su web. | La entrada desde el punto de origen y el apoyo visual local son expectativas visibles en una alternativa móvil. [Fuente](https://redacted.app/ios) |
| **Resecta** | Busca términos, listas o regex; escanea PII localmente; deja las sugerencias sin seleccionar; vuelve a buscar en la salida; ofrece rasterización segura y una opción de PDF buscable reconstruido. | La persona necesita controlar falsos positivos y reusar reglas, además de recibir una confirmación basada en comprobaciones concretas. [Funciones](https://resecta.app/features/) y [ficha de App Store](https://apps.apple.com/us/app/resecta-redact-pdfs/id6786922787). |
| **Adobe Acrobat** | Busca texto o patrones para marcar resultados y documenta Action Wizard para acelerar lotes en escritorio. | Búsqueda, repetición de reglas y procesamiento de series forman parte de los flujos profesionales. No se toma como comparativa de su app iOS. [Documentación](https://experienceleague.adobe.com/en/docs/document-cloud-learn/acrobat-learning/advanced-tasks/protect/redact) |
| **PDF Expert** | Ofrece herramientas iOS de edición, OCR y eliminación de contenido sensible; una historia editorial de App Store describe Find & Redact para coincidencias de texto. | Una persona puede preferir el editor PDF que ya utiliza; MaskID debe destacar la revisión local y verificación de la copia. [Ayuda de Readdle](https://support.readdle.com/pdfexpert/es_ES/edit-pdfs/remove-sensitive-content) y [artículo editorial de App Store](https://apps.apple.com/us/iphone/story/id1495449194). |
| **OfflinePDF** | En su ficha anuncia OCR, chequeos de texto y metadatos, Safe Copy, historial, presets y Batch Cleanup. | Los usuarios comparan el flujo completo —organizar, limpiar, revisar y repetir—, no solo la herramienta de máscara. [Ficha de App Store](https://apps.apple.com/us/app/offlinepdf-redact-ocr/id6757002225) |

La salida buscable merece una decisión explícita. MaskID hoy aplana el PDF y elimina la capa textual; eso hace más fácil razonar sobre la eliminación, pero complica buscar, seleccionar y leer el contenido con tecnologías de asistencia. Una salida que reconstruye el texto no censurado podría resolver ese coste, aunque incorpora una superficie de riesgo más amplia. Debe ser opcional y llegar después de una verificación extensa.

## Señales de usuarios y límites de la evidencia

Los hilos públicos revisados muestran cuatro necesidades recurrentes, con muestras pequeñas y sesgo hacia personas que participan en comunidades técnicas:

- **Una salida que no oculte texto recuperable.** En una consulta de r/privacy del 2 de octubre de 2026, varias respuestas distinguen redacción real de un rectángulo visual y recomiendan aplanar o usar herramientas de redacción; las personas siguen describiendo flujos manuales con GIMP, impresión y reescaneo. [Hilo de r/privacy](https://www.reddit.com/r/privacy/comments/1wvmgef/how_do_i_safely_redact_sensitive_info_in_pdfs_and/)
- **Procesamiento local cuando los documentos son sensibles.** En r/pdf, una petición del 18 de enero de 2026 solicita una aplicación local para preparar documentos antes de compartirlos con clientes o herramientas de IA y rechaza subirlos a servicios externos. [Hilo de r/pdf](https://www.reddit.com/r/pdf/comments/1qgdg1n/pdf_redaction_app_that_runs_locally/)
- **Lotes y calidad de OCR para muchos archivos.** Una conversación sobre OCR documenta interés por procesar diez o más archivos y por manejar adjuntos en serie. [Hilo sobre lotes de OCR](https://www.reddit.com/r/pdf/comments/1lg32in)
- **Control de falsos positivos y revisión humana.** Un hilo de 2026 sobre redacción automática en planos técnicos describe que algunas detecciones ocultaban números y dimensiones necesarios, y recomienda revisar resultados. [Discusión de r/ProductivityApps](https://www.reddit.com/r/ProductivityApps/comments/1w5270i/ai_pdf_tool_needed_for_hiding_sensitive/)

Estas señales coinciden con el diseño actual de MaskID —sugerir y dejar revisar— y apoyan las propuestas de búsqueda y lote con validación por página. No justifican por sí solas invertir en funciones para empresas o ampliar a todos los países. La ficha estadounidense de MaskID muestra una valoración pública; el análisis interno de App Store Connect del 16 de octubre registró solo 14 descargas por primera vez en los 90 días observados, una muestra demasiado pequeña para concluir dónde abandona la mayoría ([auditoría del ciclo](../tasks/details/222-auditoria-integral-app.md)). Ya existe un sistema de comentarios privado en la app; conviene usar esas respuestas y métricas de activación consentidas para validar la prioridad antes de comenzar las fases de mayor coste.

## Plan propuesto por fases

Las duraciones son orientativas para descomponer el trabajo, no fechas de entrega. La tarea 226 de UI/UX multidispositivo sigue activa en el backlog; conviene coordinar los cambios de biblioteca y captura con esa línea de trabajo.

### Fase 0 — Cerrar fiabilidad del núcleo (1–2 ciclos)

- Corregir el lote para detectar por página y mostrar previsualización revisable antes de aplicar.
- Corregir el renderizado de PDF a resolución de salida y añadir un conjunto fijo de documentos sintéticos de regresión.
- Invalidar la revisión de máscaras cuando cambie el recorte, la orientación o la perspectiva, y volver a exigir la revisión de todas las páginas antes de exportar.
- Revisar el informe de Protección para separar claramente “comprobaciones aprobadas” de “áreas que la herramienta no puede descartar”.
- Registrar errores de forma agregada y sin texto OCR ni identificadores de documentos.

**Métrica:** exportaciones verificadas sin fallos por página; omisiones y falsas sugerencias por tipo de documento; tiempo mediano hasta una exportación protegida.

### Fase 1 — Reglas reutilizables y revisión potente (2–4 ciclos)

- Añadir búsqueda local por frase y varias palabras, con OCR para páginas escaneadas.
- Añadir diccionarios y patrones propios guardados con cifrado local.
- Hacer que la intención Personalizada permita configurar y guardar reglas.
- Mostrar página, texto reconocido, nivel de confianza y motivo de cada sugerencia; no preseleccionar coincidencias.
- Añadir sugerencias locales para caras con confirmación manual.

**Métrica:** proporción de ocurrencias revisadas, tiempo de edición por expediente y tasa de corrección del usuario por categoría de detección.

### Fase 2 — De lote parcial a expediente protegido (3–6 ciclos)

- Seleccionar varios archivos desde Archivos y la Share Extension.
- Procesarlos como trabajos cancelables con progreso y estado individual.
- Aplicar un perfil, revisar páginas discrepantes y exportar una copia segura por documento.
- Ofrecer un resumen del lote con número de archivos y páginas revisados, fallidos y verificados.

**Métrica:** éxito de lotes por tamaño y formato; duración por página; recuperación tras cancelar o fallar; porcentaje de archivos terminados que pasan todas las verificaciones.

### Fase 3 — Acceso, búsqueda y continuidad profesional (según adopción)

- Probar una modalidad opcional de PDF con texto seleccionable, manteniendo por defecto el formato rasterizado.
- Mejorar la biblioteca con búsqueda OCR dentro del contenido y colecciones/perfiles, manteniendo indexación cifrada y excluyendo Vault bloqueada.
- Publicar benchmarks de detección para España/UE primero y añadir paquetes regionales con muestras y límites documentados antes de ampliar idiomas y documentos nacionales.
- Si aumenta la demanda profesional, evaluar app macOS con navegación de teclado, drag-and-drop, lotes grandes y revisión cómoda de dos páginas.
- Evaluar compartir en equipo solo después de decidir un modelo de acceso, revocación, claves, auditoría y borrado que no exponga originales sin consentimiento explícito.

**Métrica:** usuarios que usan la búsqueda o exportación seleccionable, calidad por idioma/documento, activación de perfiles guardados y demanda real de uso de escritorio.

### Línea transversal — Inicio, widgets y accesos rápidos

Completar la superficie de acceso diario dentro de la app y en el sistema, como una mejora transversal del trabajo de UI/UX:

- En Inicio, ofrecer tarjetas de acceso de un toque a añadir un documento, la biblioteca completa, Estilos y Bóveda. Usar los flujos existentes y respetar la autenticación de Bóveda; adaptar el grid a iPhone, Duo, iPad y Dynamic Type.
- Conservar las tarjetas de biblioteca como datos agregados que abren la lista filtrada correspondiente; alinear sus contadores con el mismo snapshot que consumen los widgets del sistema.
- Completar widgets informativos y acciones de Inicio/Bloqueo y controles del sistema con resúmenes comprensibles, accesos útiles y localización ES/EN. Mantener los datos del widget agregados y privados.
- Sustituir el porcentaje actual llamado “seguridad” por métricas descriptivas (por ejemplo, documentos con redacciones), corregir el caso de biblioteca vacía y evitar afirmaciones absolutas como “todo seguro” cuando el dato no las demuestra.
- Presentar modos de protección, lote, Bóveda y conexiones de nube como herramientas con disponibilidad y requisitos visibles, sin duplicar CTAs principales ni prometer revisión automática completa.

**Métrica:** uso de cada acceso, aperturas desde widget y proporción de personas que llega a Añadir documento/Bóveda en un toque; incidencias de destino incorrecto o etiquetas localizadas incompletas.

## Hallazgo de calidad en el trabajo multidispositivo activo

La tarea 226 contiene cambios locales extensos de navegación y UI que todavía están sin confirmar. Su nota del 20 de octubre registra una compilación genérica y una compilación para pruebas correctas, pero la repetición del test funcional del arreglo de navegación de Ajustes en iPad quedó pendiente porque CoreSimulatorService dejó de responder. El mismo informe documenta cuatro avisos de SwiftUI sobre modificación de estado durante una actualización de vista, sin localizar todavía la llamada responsable ([detalle de la tarea 226](../tasks/details/226-refactor-ui-ux-multidispositivo.md)).

**Plan:** cuando los simuladores vuelvan a estar disponibles, reproducir primero el cierre/navegación de Ajustes en iPhone 18 Pro y luego en iPad/Duo según la matriz del proyecto; localizar y corregir las mutaciones de estado durante el renderizado; cerrar la regresión con pruebas focalizadas y actualizar la evidencia de la tarea. Hasta entonces, el refactor no debe darse por validado en todos los dispositivos.

## Qué conviene mantener

- Exportación segura y sus comprobaciones disponibles en Free; la seguridad básica no debe quedar detrás del paywall.
- Procesamiento OCR y máscaras en el dispositivo; CloudKit y proveedores externos deben permanecer opcionales y explicarse antes de usar.
- Revisión explícita de las sugerencias, con posibilidad de conservar campos que el receptor necesita.
- Una salida rasterizada como opción por defecto, con lenguaje que describa los controles que se ejecutaron y sus límites.
- Precios transparentes y una opción de compra permanente visible en la región; evitar promesas de automatización absoluta.

## Decisión recomendada

Priorizar la Fase 0 y validar después la Fase 1 con expedientes sintéticos y comentarios privados existentes. No empezar por una colaboración de equipo o una expansión mundial del detector: ambas aumentan costes, superficie de privacidad y carga de validación antes de haber completado el flujo personal de varios documentos.

### Fuentes consultadas

- [Ficha pública de MaskID en App Store](https://apps.apple.com/us/app/maskid-protects-files-and-ids/id6790398619), consultada el 20 de octubre de 2026.
- [Redacted para iPhone y iPad](https://redacted.app/ios), consultada el 20 de octubre de 2026.
- [Funciones de Resecta](https://resecta.app/features/) y [ficha de App Store](https://apps.apple.com/us/app/resecta-redact-pdfs/id6786922787), consultadas el 20 de octubre de 2026.
- [Documentación de Adobe Acrobat sobre redacción](https://experienceleague.adobe.com/en/docs/document-cloud-learn/acrobat-learning/advanced-tasks/protect/redact), consultada el 20 de octubre de 2026.
- [Ayuda de PDF Expert sobre eliminación de contenido sensible](https://support.readdle.com/pdfexpert/es_ES/edit-pdfs/remove-sensitive-content) y [artículo editorial de App Store sobre Find & Redact](https://apps.apple.com/us/iphone/story/id1495449194), consultados el 20 de octubre de 2026.
- [Ficha de OfflinePDF en App Store](https://apps.apple.com/us/app/offlinepdf-redact-ocr/id6757002225), consultada el 20 de octubre de 2026.
- [Consultas de r/privacy, r/pdf y r/ProductivityApps enlazadas arriba](https://www.reddit.com/r/privacy/comments/1wvmgef/how_do_i_safely_redact_sensitive_info_in_pdfs_and/), consultadas el 20 de octubre de 2026.
