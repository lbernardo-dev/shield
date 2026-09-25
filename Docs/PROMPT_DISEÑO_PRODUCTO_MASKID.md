# Prompt maestro — dirección de producto, UI/UX y branding para MaskID

Actúa como un diseñador de producto senior especializado en iOS, con experiencia en UX de herramientas sensibles, privacidad documental, branding y sistemas visuales escalables. Piensa como estratega de producto, diseñador de interacción y director de arte a la vez.

Tu trabajo es proponer una dirección de diseño para MaskID que se sienta como un producto propio, maduro y confiable. No quiero una capa decorativa sobre una app genérica de iOS: quiero una experiencia coherente para proteger identidad, revisar documentos y compartir únicamente lo necesario.

## 1. Contexto confirmado del producto

### Identidad y categoría

- Nombre visible del producto: **MaskID**.
- Nombre interno heredado del proyecto, bundle y algunos documentos: **Shield**. No lo trates como una segunda marca; la marca de cara al usuario es MaskID.
- Categoría: **protección de identidad documental**. No es principalmente un editor PDF, un escáner genérico ni una app de retoque fotográfico.
- Promesa de producto: ayudar a una persona o profesional a demostrar algo con un documento sin entregar más datos personales de los necesarios.
- Trabajo principal del usuario: **importar o escanear → detectar → revisar → enmascarar → comprobar → compartir o guardar**.
- Diferenciación: el OCR y el procesamiento principal se ejecutan en el dispositivo; la revisión humana es explícita; la exportación se aplana y pasa por un Protection Check.

### Qué puede hacer actualmente

La app permite:

- Importar imágenes y PDF desde Fotos, Archivos, Share Sheet y proveedores disponibles mediante el selector nativo de Archivos.
- Capturar y escanear documentos con cámara, incluida captura multipágina.
- Detectar texto, campos de identidad, MRZ, rostros y otras entidades mediante OCR/Vision en el dispositivo, mostrando sugerencias revisables y niveles de confianza.
- Redactar manualmente zonas con un canvas interactivo, zoom, pan, mover/redimensionar, undo/redo y coordenadas normalizadas que no deben desplazarse al cambiar de tamaño o dispositivo.
- Aplicar modos de redacción por propósito: alquiler, viaje, empleo, verificación y perfiles profesionales adicionales como legal, salud y banca cuando estén disponibles para el usuario.
- Editar documentos multipágina, recortar, rotar, voltear y ajustar brillo, contraste, saturación y nitidez.
- Elegir estilos de máscara: bloque negro o blanco en Free; pixelado, desenfoque, diagonal, secure, etiqueta de redacción y otros estilos avanzados en Pro. La interfaz debe distinguir claramente apariencia visual de protección de salida.
- Configurar marcas de agua y exportar a PDF o imagen.
- Generar una exportación rasterizada/aplanada y mostrar un **Protection Check** con páginas revisadas, redacciones aplicadas, texto extraíble, anotaciones, metadatos auditados, OCR residual, marca de agua y elementos sensibles que siguen visibles.
- Guardar documentos en una Biblioteca local cifrada y en una Bóveda cifrada con Face ID/PIN y auto-lock.
- Buscar, ordenar, filtrar, categorizar y marcar documentos como favoritos.
- Usar Share Extension, App Intents/Shortcuts y un widget con métricas agregadas, sin exponer contenido documental.
- Gestionar preferencias, idioma español/inglés, apariencia clara/oscura, OCR, exportación, seguridad, privacidad, feedback y Trust Center.

### Arquitectura de navegación actual

- En iPhone compacto: cuatro áreas principales — **Documentos/Biblioteca, Estilos, Bóveda y Ajustes**— con una acción de **Escanear** prominentemente integrada en la navegación inferior.
- En ancho regular: navegación adaptable con sidebar y espacio para una experiencia más profesional.
- En iOS moderno se usa Liquid Glass como mejora progresiva, con fallback para versiones anteriores; no diseñes una interfaz que dependa exclusivamente de ese material.
- La Biblioteca/Home contiene un hero de acción, modos rápidos, búsqueda, categorías, recientes y herramientas de workspace.
- La Galería muestra estilos de máscara y previews.
- El Editor debe comportarse como una herramienta de foco: canvas central, acciones esenciales, inspector de privacidad y exportación.
- En iPad y layouts amplios, el Editor puede mostrar rail de páginas, canvas e inspector; en compacto debe priorizar operación con una mano y sheets contextuales.
- Ajustes no debe sentirse como una quinta área de trabajo ni como un cajón de features: debe organizar preferencias, seguridad, nube, exportación, soporte, legal y Trust Center con jerarquía clara.

### Flujos que debes considerar

1. Splash/identidad y elección de consentimiento de analítica, separada de los permisos de cámara, Fotos y Face ID.
2. Onboarding progresivo: bienvenida, objetivo de uso, preocupación principal, demostración del producto, captura/importación, seguridad/PIN y oferta posterior a la entrega de valor.
3. Pantalla de bloqueo al volver de background, con privacidad visual del App Switcher y autenticación Face ID/PIN.
4. Home vacía, Home con documentos recientes y Home con cuota Free visible.
5. Captura, permisos, escaneo, importación, revisión de páginas y estados de error/cancelación/reintento.
6. OCR con sugerencias, confianza, evidencia por página y advertencia de revisión humana.
7. Editor de imagen y PDF multipágina, incluyendo selección, redimensión, estilos, presets, ajustes, marca de agua y undo/redo.
8. Exportación previa, elección de formato/calidad, advertencia de riesgo, comprobación y estado final antes de compartir.
9. Bóveda bloqueada, desbloqueo, contenido vacío, documento guardado y auto-lock.
10. Paywall contextual cuando el usuario intenta usar batch, estilos avanzados, perfiles Pro, controles avanzados o automatizaciones. La compra no debe bloquear la corrección de seguridad.
11. Share Sheet/Archivos y retorno correcto a la app.
12. Trust Center: explicar qué detecta MaskID, qué debe revisar la persona, qué se aplana, qué metadatos se eliminan y cuáles son los límites.

### Público objetivo y situaciones de uso

Diseña para una combinación de estos segmentos, sin reducirlos a “usuarios tech”:

- **Persona con urgencia puntual:** le piden un DNI, pasaporte, permiso de conducir o comprobante para un alquiler, hotel, viaje, compraventa, recuperación de cuenta o proceso KYC. Tiene poco tiempo y necesita entender en segundos qué ocultar y qué puede compartir.
- **Persona preocupada por la privacidad:** no quiere subir documentos sensibles a un servidor, valora el procesamiento local, la ausencia de cuenta obligatoria y el control explícito sobre cada salida.
- **Autónomo o profesional:** comparte contratos, nóminas, facturas, extractos, informes, formularios y PDF multipágina. Necesita repetir tareas, trabajar por lotes, guardar plantillas o presets y confiar en una salida revisable.
- **Usuario con nivel técnico mixto:** conoce iOS, pero no necesariamente OCR, metadatos, capas PDF, EXIF o rasterización. La app debe enseñar lo suficiente sin convertir cada pantalla en un manual de seguridad.

Expectativas visuales del público:

- Confianza, control, claridad y ausencia de sorpresas antes que espectacularidad.
- Señales familiares de iOS para cámara, importación, compartir, navegación, Face ID, permisos, undo, cancelación y estados de progreso.
- Una identidad propia que no parezca un banco, una app policial, una herramienta de hacking ni un editor de fotos juguetón.
- Lenguaje y jerarquía que permitan actuar rápido sin ocultar riesgos importantes.

### Free, Pro y límites de producto

Free ofrece captura/importación, OCR conservador, redacción manual, exportación segura con verificación y Bóveda local cifrada. Tiene un límite acumulado de documentos procesados —actualmente 10—, pero no debe hacer que la seguridad o la verificación parezcan funciones de pago.

Pro se posiciona alrededor de la repetición y la escala: procesamiento ilimitado, batch, modos profesionales, estilos avanzados, ajustes de imagen, marcas de agua personalizadas, automatizaciones y flujos opcionales con iCloud para documentos fuera de la Bóveda. Las integraciones externas pasan por los flujos de archivos y consentimiento del sistema; no inventes una nube propia ni estados de conexión ficticios.

Regla de diseño: **privacidad, accesibilidad, revisión humana, exportación verificable y explicación honesta de los límites son garantías del producto, no premios Pro**. El paywall debe aparecer en el momento en que se percibe el valor de la capacidad ampliada y debe explicar qué se desbloquea sin usar miedo.

### Plataforma y restricciones técnicas

- SwiftUI como framework principal; UIKit solo donde sea necesario para cámara, autenticación, compartir o APIs del sistema.
- Despliegue del target principal: iOS 18; el proyecto se adapta a SDKs modernos y a patrones visuales de iOS 26/27 con fallback.
- iPhone y iPad universales, portrait/landscape, Split View y Stage Manager.
- No hay target watchOS ni app de Mac en el producto actual. No diseñes pantallas de reloj como si fueran una entrega existente.
- La interfaz debe responder a tamaño de contenedor, size class, safe areas y regiones reservadas; no uses dimensiones fijas ni ramas por modelo de dispositivo.
- Dynamic Type, VoiceOver, Voice Control, Switch Control, Increase Contrast, Reduce Motion y Reduce Transparency son requisitos de producto.
- Controles táctiles de al menos 44 pt, foco de teclado/trackpad donde aplique y alternativas a gestos complejos.
- Localización real en español e inglés; evita copy que dependa de que una frase tenga una longitud fija.
- No asumas que un documento es una sola foto: el modelo incluye PDF, multipágina, rotación, orientación mixta y documentos de baja calidad.

La base actual es amplia, pero no la trates como una build sin deuda: la auditoría más reciente dejó pendientes de release relacionados con la persistencia de metadatos documentales, el cierre/retorno del flujo de Captura, el contrato de localización y warnings de aislamiento que serán errores en Swift 6. Si propones una interacción que dependa de corregir alguno de ellos, márcala como requisito de implementación y no la presentes como capacidad ya garantizada.

## 2. Identidad visual existente que debes auditar, no ignorar

Existe una base de marca que puedes conservar, evolucionar o cuestionar explícitamente:

- Marca MaskID basada en una identidad humana neutral con una franja/máscara pixelada; evita sustituirla automáticamente por un candado o escudo genérico.
- Paleta actual: Midnight Navy `#071426`, superficies profundas como `#050D18` y `#0E2038`, Electric Cyan `#20C7D9`/`#42DCEA`, Cool Blue cercano a `#4E7BFF`, blanco cálido y estados semánticos verde `#30D158`, ámbar `#FF9F0A`, rojo `#FF453A` y azul informativo `#64D2FF`.
- Existe modo oscuro como experiencia histórica de marca y modo claro adaptativo con fondos suaves `#F4F4F8`/`#F7F7FA`; no trates el claro como una conversión automática del oscuro.
- Tipografía actual: San Francisco con pesos y tamaños sensibles a Dynamic Type.
- Motion actual: aparición/máscara de identidad, microinteracciones de presión, navegación y estados con movimiento suave; todo debe tener alternativa con Reduce Motion.
- Hay variantes de icono y temas visuales ya preparados, incluyendo Blue, Ocean, Purple, Green, Gold, Red y variantes estacionales como Aurora, Christmas, Forest, Halloween, Lunar, Pride, Space y Tide.

Para cada dirección propuesta, declara qué parte de esta base mantienes, qué parte reinterpretas y qué parte descartarías. No propongas un rebranding completo sin explicar el coste de romper reconocimiento, iconografía, capturas de App Store y temas existentes.

## 3. Reglas de lenguaje, confianza y privacidad

Estas reglas son obligatorias en todo el diseño y el copy:

- Di “procesamiento en el dispositivo” o “on-device” para OCR/redacción; no prometas detección completa.
- Di “sugerencias” y “campos detectados”, no “IA infalible” ni “100 % automático”.
- Di “copia verificada” o “verified output” solo después de que el Protection Check haya pasado.
- No uses “anónimo”, “privacidad certificada”, “hardware encryption”, “Secure Enclave” ni “irreversible” como garantías no demostradas.
- No ocultes la obligación de revisar todas las páginas y los elementos sensibles que siguen visibles.
- No llames “seguro” a una máscara visual transparente, blur o pixelado sin explicar el comportamiento de la exportación.
- No presentes la eliminación de metadatos como universal: describe “metadatos habituales/auditados” cuando corresponda.
- Los estados de éxito deben distinguir entre “exportado”, “verificado técnicamente” y “listo para compartir tras revisión humana”.
- Los errores no deben culpar al usuario ni revelar OCR o datos sensibles en telemetría, logs o mensajes de diagnóstico.

## 4. Qué debes hacer

### A. Analizar el público y la categoría

Explica:

1. Qué espera cada segmento en una app que protege documentos.
2. Qué convenciones de escáner, visor PDF, editor y gestor de archivos son obligatorias.
3. Qué patrones se pueden romper sin generar desconfianza y cuáles no.
4. Qué jerarquía reduce el tiempo entre “me han pedido este documento” y “tengo una copia revisada para compartir”.
5. Cómo se comunica control sin convertir la app en una interfaz alarmista o de alta seguridad teatral.

Separa claramente hechos confirmados, recomendaciones de diseño y supuestos que habría que validar con usuarios.

### B. Proponer exactamente 3 direcciones conceptuales + 1 combinada

Las tres primeras deben ser genuinamente distintas, no tres paletas del mismo dashboard. Como referencia de contraste, explora al menos:

- una dirección de confianza serena y editorial;
- una dirección de precisión técnica y evidencia;
- una dirección humana, cálida y cotidiana que reduzca ansiedad sin perder rigor.

Puedes renombrarlas y reinterpretarlas, pero cada una debe tener una tesis visual y de UX reconocible.

Para cada dirección entrega:

1. Nombre corto.
2. Frase de posicionamiento.
3. 3–5 adjetivos de personalidad.
4. Público y momento de uso donde encaja mejor.
5. Qué conserva/evoluciona/descarta de la identidad actual MaskID.
6. Sistema de color completo, no solo una paleta:
   - tokens semánticos para fondo, superficie, texto, borde, acción, selección, detección, advertencia, error y éxito;
   - hex para claro y oscuro;
   - contraste esperado y uso permitido de cada acento;
   - comportamiento en Increase Contrast y Reduce Transparency.
7. Tipografía, pesos, escala, Dynamic Type y reglas para textos largos localizados.
8. Iconografía: SF Symbols, símbolo de marca, iconos propios y reglas para no confundir protección, detección, bloqueo y estado de exportación.
9. Ilustración/fotografía: cuándo usarla, cuándo no y cómo evitar mostrar documentos reales o datos legibles.
10. Espaciado, radios, bordes, materiales, sombras, profundidad y densidad. Justifica cada decisión con la personalidad.
11. Motion y haptics: aparición de detecciones, confirmación, progreso, verificación, cambio de máscara y navegación; incluye comportamiento con Reduce Motion.
12. Arquitectura de navegación: tabs/sidebar, acción Escanear, Home, Galería, Bóveda, Ajustes, editor compacto y editor amplio.
13. Flujo de onboarding, permisos, lock screen, captura, OCR, editor, Protection Check, Bóveda y paywall.
14. Estados vacíos, carga, progreso, cancelación, error, reintento y éxito con ejemplos de copy en español.
15. Diferencia entre señal de “campo detectado”, “zona seleccionada”, “máscara aplicada”, “verificación técnica” y “revisión pendiente”. Nunca dependas solo del color.
16. Cómo se ve una pantalla clave en un mockup: elige Home, Scan Review, Editor o Protection Check y explica la composición de arriba abajo.
17. Ventajas, riesgos y señales que revelarían que la dirección se ha convertido en un MVP genérico.

### C. Crear una cuarta dirección combinada

Construye una dirección única combinando únicamente los elementos más fuertes de las tres anteriores. No hagas un collage.

Incluye:

- una tesis central;
- personalidad y reglas de decisión;
- tokens visuales principales;
- arquitectura de UX;
- una pantalla mockup equivalente;
- qué sacrificios hace frente a cada dirección original;
- qué elementos no deben combinarse porque generarían contradicción.

No elijas una ganadora por mí. Presenta las cuatro opciones, sus trade-offs y una tabla de comparación para que pueda decidir.

## 5. Temas, personalización y evolución

Diseña el sistema como tokens desacoplados de la lógica de producto:

- tema base de MaskID;
- modo claro/oscuro y preferencias del usuario;
- posibles variantes de identidad/icono;
- temas estacionales como Halloween, Navidad, Pride, Lunar o Space;
- futuros temas de campaña sin alterar navegación, jerarquía, accesibilidad o semántica de estados.

Define qué tokens puede sobrescribir un tema y cuáles son inmutables:

- colores de marca y superficies;
- ilustración/icono/marca;
- textura o detalle de fondo;
- motion decorativo;
- tono de copy;
- estados semánticos y colores de error/éxito, que deben conservar legibilidad y significado.

Da un ejemplo conceptual, por ejemplo Halloween sobre la dirección técnica: cambia atmósfera, icono y un detalle de motion, pero no cambia el contraste, el comportamiento de protección, la ubicación de Escanear ni el significado de Protection Check.

## 6. Requisitos de los mockups

Genera o describe cuatro mockups coherentes —uno por dirección— sobre una pantalla clave realista de MaskID. Si tienes capacidad de generación de imágenes, crea una imagen por dirección más una para la combinada; si no, entrega un brief visual suficientemente preciso para producirlas después.

Los mockups deben:

- mostrar UI iOS plausible y no una landing page;
- usar textos cortos, legibles y localizados en español;
- mostrar documentos ficticios sin nombres, números, direcciones ni datos reales legibles;
- hacer visible la diferencia entre detección, selección, máscara y verificación;
- respetar safe areas, tamaños táctiles y Dynamic Type razonable;
- evitar un marco de iPhone ornamental que oculte la interfaz;
- incluir una versión clara u oscura cuando sea importante para evaluar el sistema;
- no representar como completada una verificación que la pantalla no haya demostrado.

## 7. Checklist de “esto no debería verse así” vs. “esto sí”

Incluye al final una checklist provisional, aunque la dirección final todavía no se haya elegido. Debe cubrir:

- Home y navegación;
- onboarding y permisos;
- captura/revisión;
- OCR y confianza;
- editor y estilos de máscara;
- exportación y Protection Check;
- Bóveda y bloqueo;
- paywall Free/Pro;
- claro/oscuro, Dynamic Type, VoiceOver y Reduce Motion;
- iPad, landscape, Split View y anchos reducidos;
- temas estacionales.

Cada fila debe tener una señal observable, no una frase abstracta de diseño.

## 8. Cosas que debes evitar explícitamente

No hagas lo siguiente:

- No uses azul de sistema, candados, escudos o gradientes genéricos sin una decisión de marca.
- No conviertas MaskID en un dashboard de métricas si la acción principal es proteger y compartir un documento.
- No uses estética “hacker”, vigilancia, burocracia bancaria o juguete de edición fotográfica.
- No diseñes un onboarding de tres pantallas genéricas centradas en texto ni pidas todos los permisos sin contexto.
- No escondas Escanear, Importar, Deshacer, Revisar, Exportar o Compartir en menús ambiguos.
- No uses solo blur, pixelado, transparencia o color para comunicar protección.
- No muestres “seguro”, “completo” o “verificado” antes de tener evidencia del estado correspondiente.
- No presentes la revisión humana como un fallo del producto: es parte del control que MaskID promete.
- No hagas que una suscripción parezca necesaria para proteger correctamente un documento.
- No uses un tema estacional que reduzca contraste, legibilidad, accesibilidad o confianza.
- No dependas de tamaños de pantalla, coordenadas fijas o layouts de un solo iPhone.
- No uses texto en mayúsculas pequeñas, etiquetas truncadas, iconos sin nombre accesible ni estados comunicados solo por color.
- No inventes target watchOS, funciones de equipo, sincronización universal o integraciones OAuth que no estén confirmadas.

## 9. Formato final obligatorio de tu respuesta

Responde en español con esta estructura:

1. Lectura del producto y del usuario.
2. Principios de diseño no negociables.
3. Dirección A completa.
4. Dirección B completa.
5. Dirección C completa.
6. Tabla comparativa A/B/C.
7. Dirección D combinada completa.
8. Especificación de los cuatro mockups.
9. Arquitectura de tokens y temas.
10. Checklist provisional “esto no / esto sí”.
11. Decisiones que necesito tomar yo y preguntas de validación que no deben resolverse inventando datos.

No entregues una guía de tendencias genéricas. Cada elección debe conectarse con la situación de uso, el documento que se protege, la necesidad de confianza, las capacidades reales de MaskID y sus límites técnicos y de comunicación. No implementes código todavía: primero necesito comparar las cuatro direcciones y elegir una base.
