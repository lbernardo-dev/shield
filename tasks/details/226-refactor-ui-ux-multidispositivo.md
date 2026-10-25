# 226-refactor-ui-ux-multidispositivo

### Revalidación incremental — 2026-10-24

- La nota de estado anterior sobre mantener Scan en un accesorio inferior quedó superada: la shell ya no usa `.tabViewBottomAccessory` y `.capture` no forma parte de `AppTab.navigationCases`. Inicio mantiene su acción primaria y iPad su toolbar contextual.
- El resumen de Ajustes ahora abre la pantalla debajo del encabezado y precede todas las secciones; la prueba de orden pasa en iPhone 18 Pro.
- El dashboard regular lleva las métricas de biblioteca a la columna izquierda y expandir “Modos, lote y nube” cambia el estado y desplaza a la sección; `testHomeQuickAccessActionsAreVisibleAndTappable` pasa en iPhone 18 Pro.
- La acción primaria y la acción Scan contextual llaman al mismo presentador de importación. La prueba principal volvió a pasar 1/1 en iPhone 18 Pro.
- El último Duo tiene `SchoolSnap` activo; no se instala ni se interrumpe esa sesión. La última ejecución de XCUITest no finalizó el bundle. iPad sigue a la espera de repetir toolbar Scan y quick tools; véase `docs/iphone-duo/TEST_MATRIX.md`.

### Matriz después del arreglo de perfiles y versión 1.1.6 — 2026-10-25

- Sobre la fuente que contiene los arreglos de navegación, barra Scan, resumen de Ajustes y hojas de perfiles, el iPhone 18 Pro iOS 27.0 pasó 5/5 UI tests; iPhone Duo iOS 27.1 pasó 1/1 prueba focalizada de perfil; iPad Pro 13-inch (M5) iPadOS 27.0 pasó 4/4 pruebas de perfil, toolbar y navegación. Evidencia en `/private/tmp/MaskID-2402-iPhone18-ProfileFix.xcresult`, `/private/tmp/MaskID-2402-Duo-ProfileFix-Retry.xcresult` y `/private/tmp/MaskID-2402-iPad-ProfileFix.xcresult`.
- Captura del iPad confirma el resumen de Ajustes arriba, bajo el header: `/private/tmp/MaskID-2402-iPad-Settings.png`. La captura del Duo continúa negra; allí se cuenta con las aserciones UI, no una inspección visual independiente.
- La prueba localizada de Novedades pasó 1/1 en el iPhone 18 Pro con las cuatro frases aprobadas en ambos idiomas: `/private/tmp/MaskID-2402-WhatsNew-Copy-Fix.xcresult`.
- El 2026-10-25 empezó una revalidación combinada de cola, búsqueda, perfiles, Scan y Ajustes en iPhone 18 Pro. Durante el arranque apareció un runner externo `com.romerodev.repsfitness.uitests.xctrunner`; se canceló exclusivamente el `xcodebuild` de esta tarea. Su `.xcresult` `/private/tmp/MaskID-2403-iPhone18-UI-Regressions.xcresult` es incompleto y no se contabiliza como resultado.
- Pendiente: repetir el pase focalizado cuando el iPhone 18 Pro quede libre; después continuar por Duo e iPad conforme a la matriz. No existe target watchOS y no se afirmó compatibilidad con Apple Watch.

- Number: 226
- Slug: refactor-ui-ux-multidispositivo

## Objetivo

Hacer que MaskID se sienta como un producto coherente, claro y confiable en todos los dispositivos soportados. Mantener una identidad visual común y adaptar la composición al espacio real de iPhone, iPhone Duo (pantalla exterior/interior y cambios de pose) e iPad (portrait, landscape y multitarea). Preferir navegación y controles estándar de Apple donde encajen. Evitar una reescritura de golpe: migrar por flujos y conservar la funcionalidad de privacidad y seguridad.

## Auditoría inicial — 2026-10-19

### Hallazgos confirmados

1. **La biblioteca no comunica una jerarquía suficientemente clara en las capturas entregadas.** Se ven un encabezado dominante, tarjeta de privacidad/cuota, búsqueda, categorías y “Documento reciente” compitiendo en la primera pantalla. La composición regular deja mucho espacio sin función y las columnas no se sienten como un solo panel; la compacta amontona contenido. En la captura de 23:20, nombres de categorías se parten en palabras (“Identid / ad”, “Condu / cción”, “Financi / ero”), lo que afecta legibilidad y acabado. También aparece una llamada de escaneo demasiado grande y superpuesta al estado vacío en una captura anterior. Impacto: no queda claro qué hacer primero y la interfaz parece inestable entre tamaños.
2. **Ya existe un primer arreglo adaptativo de la biblioteca, pero aún no se ha podido comprobar visualmente.** `HomeView` compone de forma distinta al recibir ancho regular; la tarea 225 cambió la vista regular a categorías horizontales y añadió un CTA de escaneo en el encabezado. La pantalla autenticada del Duo sigue detrás de la configuración de PIN del usuario, por lo que no se afirma que esa versión haya corregido el resultado visual. Las capturas aportadas son la referencia del problema, no evidencia del aspecto actual.
3. **La adaptación está distribuida por vistas y varios archivos son muy grandes.** `HomeView.swift` tiene 1.887 líneas, `CaptureReviewViews.swift` 1.508, `VaultView.swift` 1.223 y `EditorView.swift` 913. El tamaño por sí solo no demuestra un bug, pero dificulta mantener una sola jerarquía, rastrear estado y prevenir regresiones entre anchos. Conviene extraer secciones y componentes con entradas pequeñas y responsabilidades claras.
4. **Hay métricas útiles disponibles, pero no están reunidas como resumen de valor en Inicio.** `AppState.updateWidgetSnapshot` ya calcula total de documentos, documentos con redacciones, documentos en Bóveda y documentos con marca de agua. La Bóveda ya calcula alertas de caducidad. El valor `securityScore` del snapshot se deriva de la fracción de documentos con redacción y devuelve 100 con cero documentos; no equivale a una evaluación real de seguridad, por lo que no se debe presentar como tal en Inicio sin redefinirlo y validarlo.
5. **La importación necesita una comprobación de extremo a extremo además del rediseño.** La captura adjunta muestra “No se pudo importar / No se pudo guardar la importación de forma segura”. El informe de la tarea 225 asocia algunos errores de persistencia del simulador sin firma a la ausencia de entitlements de Keychain/App Group. No basta para concluir que falle en distribución: hay que repetirlo con firma y entitlements válidos, y asegurar que el mensaje tenga reintento/recuperación si se reproduce.
6. **Los cambios recientes de navegación, editor, safe areas y Duo tienen cobertura incompleta.** La auditoría anterior confirma instalación y apertura en iPhone 18 Pro y Duo, pero no pudo entrar a la biblioteca autenticada tras aparecer la configuración de PIN. El resultado de UI tests era `unknown` con cero nodos y la ejecución unitaria no dejó evidencia de tests completados. El iPad se dejó intacto porque tenía otras apps activas. La rama actual usa `TabView` adaptable en iOS 26+, fallback para sistemas anteriores, y un split de canvas/inspector en Duo; son buenos cimientos, no una validación visual completa.
7. **No existe un destino de app watchOS en el proyecto.** El alcance de esta refactorización es iOS/iPadOS; Apple Watch queda fuera hasta que exista un target watchOS.

## Dirección visual y de interacción

- Definir un solo sistema de espaciado, tipografía, radios, superficies, elevación y color con los tokens de `ShieldTheme`. Limitar decoraciones, fondos de evento y tarjetas repetidas; el tema base debe seguir siendo el punto de referencia.
- Crear jerarquía editorial estable: título de pantalla, una acción primaria, contenido principal y acciones secundarias. No reservar espacio vacío para componentes ocultos ni repetir el mismo CTA en el footer, contenido y estado vacío.
- Alinear contenido a una cuadrícula común y limitar el ancho de lectura en iPad y en vistas regulares. El ancho extra se usa para reflujo de contenido relacionado, no para agrandar controles o estirar filas.
- Mantener botones y controles dentro de safe areas con targets accesibles. El fondo puede sangrar hasta el borde; el contenido y las acciones no.
- Usar patrones de navegación nativos y persistentes, con estado y foco que sobrevivan a apertura/cierre, rotación, cambios de ancho y cambios de pose. No identificar modelos concretos para decidir el layout.
- Preservar localización, modo claro/oscuro, Reduce Motion, Dynamic Type y privacidad local de los documentos.

## Plan de acción por fases

### Fase 0 — Baseline y contrato de diseño

- Describir el flujo principal como: Inicio/Biblioteca → Escanear o Importar → Revisar → Proteger/editar → Exportar o guardar.
- Inventariar cada superficie, estados vacío/cargando/error/éxito, puntos de salida, CTA y datos que ya existen.
- Acordar una cuadrícula base adaptable, escala tipográfica semántica, escala de espacios, superficies y reglas de safe area. Crear una hoja de referencia visual con claro/oscuro, español/inglés y tema base.
- Registrar capturas del estado actual antes de cada fase y marcar explícitamente si la captura es pre o post cambios.

**Aceptación:** existe un inventario verificable y una referencia común; cada componente puede mapearse a un token; se distingue el baseline antiguo del código Duo recién modificado.

### Fase 1 — Fundamentos compartidos y navegación

- Revisar el shell de `ContentView`: tabs, sidebar, acción de escaneo, presentación de Ajustes y retorno del editor. Mantener navegación estándar con `TabView`/`NavigationStack` donde corresponda y fallback compatible con iOS 18.
- Definir componentes reutilizables para encabezados, tarjetas, filas, filtros, estados vacíos, alertas y botones principales. Migrar componentes existentes gradualmente para evitar cambios de comportamiento en bloque.
- Normalizar safe areas, chrome superior/inferior, hit targets y accesibilidad. Eliminar cápsulas vacías, barras duplicadas y controles que se superponen al scroll.
- Mantener selección de tab, documento, herramienta, filtros y foco cuando el tamaño disponible cambie.

**Aceptación:** ninguna acción queda tapada por barras del sistema o de la app; navegación consistente en compacto y regular; ningún cambio de tamaño reinicia silenciosamente el flujo; acciones importantes tienen nombres accesibles y al menos 44 pt de objetivo táctil.

### Fase 2 — Inicio/Biblioteca y datos de valor

- Convertir Inicio en un dashboard sencillo: resumen breve del propósito, una acción primaria “Escanear”, acceso secundario a importación, documentos recientes y búsqueda/filtros en orden de prioridad.
- Presentar tarjetas de estadísticas que se puedan explicar y recalcular de los datos locales: documentos guardados, documentos con redacciones, documentos en Bóveda y documentos con marca de agua. Añadir caducidades próximas cuando el dato se pueda interpretar con fiabilidad. Cada métrica abre la lista correspondiente.
- No mostrar un “score de seguridad” basado solo en la proporción de documentos con redacciones. Si se conserva en el widget, revisar su definición y el caso cero antes de exponerlo en la app.
- Rediseñar la biblioteca vacía: una explicación breve y dos acciones claras (escanear/importar), sin CTA redundante. En bibliotecas con contenido, mostrar recientes y acceso obvio a “Ver todos”.
- Presentar categorías en una fila desplazable o en filtros accesibles según espacio; no forzar nombres largos dentro de cápsulas estrechas.
- Usar una sola columna en iPhone compacto; reflujo balanceado con orden de lectura coherente en Duo/iPad, respetando pliegues, márgenes y Dynamic Type grande.
- Completar Inicio con una sección visible de accesos rápidos a Añadir documento, Todos los documentos, Estilos y Bóveda. Cada tarjeta abre el destino o flujo ya existente, tiene nombre y pista accesibles, y se adapta a dos columnas o una columna en tamaños de accesibilidad.
- Mantener las estadísticas como widgets informativos dentro del dashboard y asegurar que sus contadores coincidan con el snapshot compartido con WidgetKit, sin convertir el número de documentos con redacciones en una puntuación de seguridad.
- Cerrar los widgets de Inicio/Bloqueo y los controles rápidos del sistema: presentar datos agregados comprensibles, estado vacío veraz, acciones claras y cadenas completas en español e inglés; no mostrar títulos, OCR ni nombres de archivos.
- Revisar el grupo plegable de Más herramientas para que modos, lote, Bóveda y nube tengan etiquetas, jerarquía y estados de disponibilidad claros; los accesos destacados no deben abrir un destino bloqueado ni omitir autenticación.

**Aceptación:** las categorías nunca cortan palabras; añadir documento, abrir biblioteca, Estilos y Bóveda son accesibles en un toque; no hay grandes huecos sin intención; las métricas coinciden con el almacén real y se actualizan al guardar, mover, proteger o borrar; widgets y controles muestran ES/EN, estados vacíos correctos y ninguna evaluación de seguridad sin fundamento.

### Fase 3 — Escaneo, importación y revisión

- Unificar cámara, Fotos, Archivos y nube bajo un flujo de entrada comprensible, dejando claro qué fuente se usa y qué ocurrirá después.
- Revisar el paso de mejora de escaneo: preview legible, herramientas agrupadas por propósito, controles completos dentro de safe areas y CTA persistente que no tape el contenido.
- Dar estados de progreso cancelables y errores accionables con conservar/reintentar/cancelar cuando corresponda. Mantener la imagen/documento staged si una escritura falla y evitar mensajes genéricos cuando se conoce la causa.
- Validar permisos, cancelación de pickers, páginas múltiples, PDFs e importación segura en un build firmado; diferenciar fallas de entitlement del simulador de fallas reales del producto.

**Aceptación:** cámara/Fotos/Archivos completan el recorrido hasta la biblioteca; errores no pierden silenciosamente la entrada; cabecera, herramientas y CTA respetan safe areas en todas las orientaciones y tamaños probados.

### Fase 4 — Editor y exportación

- Presentar el documento como foco principal y separar herramientas contextuales de metadatos y acciones de salida. En ancho amplio, canvas e inspector pueden ser regiones paralelas; en compacto, herramientas en controles nativos compactos/hojas.
- Revisar títulos, navegación entre páginas, filtros, geometría, OCR, undo/redo, guardado y exportación para que el estado activo se reconozca sin depender solo del color.
- Asegurar que el canvas conserve tamaño útil; el inspector no comprime la página por debajo de su mínimo; controles y handles no quedan bajo notch, cámara, barra de estado, home indicator o división activa del Duo.
- Probar cerrar, cancelar, deshacer y volver desde exportación sin perder ediciones o contexto.

**Aceptación:** redacciones permanecen ancladas al documento al cambiar tamaño/pose; no hay toolbar cortada ni inspector inaccesible; exportación informa con claridad qué se guardó/compartió y en qué estado.

### Fase 5 — Bóveda, Galería, Ajustes, Perfil y onboarding

- Aplicar la misma jerarquía y componentes a cada sección. Priorizar en Bóveda desbloqueo, resumen, caducidades y documentos; en Galería, selección/preview/aplicar; en Ajustes, grupos cortos y destinos con vuelta clara.
- Quitar decoraciones y paneles de relleno que no ayuden a tomar una acción. Evitar que controles secundarios compitan visualmente con la acción principal.
- Adaptar hojas y destinos a ancho iPad, teclado, trackpad y Split View; ofrecer list/detail solo cuando añade contexto.
- Verificar tono, copy y estados vacíos en onboarding, Perfil y paywall sin usar estas superficies como áreas de marketing intrusivo.

**Aceptación:** mismas reglas de cabecera, navegación, superficies y safe areas en todas las secciones; cada vista tiene un propósito y una acción de salida reconocible; estados bloqueados/Pro dicen qué está disponible y qué acción procede.

### Fase 6 — Rendimiento, accesibilidad y validación visual

- Extraer vistas y estado por áreas con límites claros; usar listas/grid lazy para colecciones grandes, cargar miniaturas según visibilidad y cancelar trabajo asíncrono al salir de una vista. Medir antes de optimizar gestos, OCR, render del canvas y scroll.
- Verificar VoiceOver, Control por Voz, foco de teclado/trackpad, contraste, Increase Contrast, Reduce Motion, Dynamic Type hasta AX5 y localización ES/EN. Revisar color con tema base y los temas de evento para evitar divergencias de legibilidad.
- Crear snapshots de estados vacío, con documentos, filtro activo, error, carga y éxito; capturar inicio, centro y final del scroll.
- Ejecutar regresión funcional por el recorrido principal además de las suites existentes. No declarar verde una suite hasta que el `.xcresult` confirme que los tests se ejecutaron y terminaron.

**Aceptación:** cero recortes, solapes o botones fuera de safe areas en la matriz acordada; navegación de teclado y VoiceOver cubre los flujos principales; tiempos y consumo medidos en vistas pesadas no empeoran respecto al baseline.

## Matriz de dispositivos y compatibilidad

- **iPhone 18 Pro:** primer destino obligatorio de cada ciclo de build/prueba, usando UDID explícito; además, revisar un iPhone compacto representativo y versiones compact/regular de tamaño si el runtime las ofrece.
- **iPhone Duo:** instalar y probar la misma build después del iPhone 18 Pro; validar cerrado, parcialmente abierto y abierto, cambios en caliente, safe areas, continuidad de estado y contenido a ambos lados de la división. No hacer dependencias de modelo: layout por propuesta, contenedores y divisiones reportadas.
- **iPad:** instalar en el modelo disponible más cercano al requisito; verificar portrait/landscape, tamaño completo, Split View y Stage Manager si disponible. En la última auditoría el iPad Pro 13-inch (M5) tenía procesos de otras sesiones activos; esperar y volver a comprobar, sin cerrarlos.
- **iOS mínimo:** mantener iOS 18.0 y fallback de API donde el sistema moderno no esté disponible; validar al menos un runtime iOS 18 durante release gate.
- **Apple Watch:** fuera de alcance porque el proyecto no contiene target ni scheme watchOS.
- No borrar, reiniciar ni tomar control de un simulador que muestre otra app/sesión activa. Registrar UDID, runtime, pose/orientación, tamaño de ventana y cualquier espera.

## Criterios de cierre del proyecto

- Biblioteca, captura, revisión, editor/exportación, Bóveda, Galería, Ajustes y onboarding revisados con la misma guía visual.
- El diseño funciona en tamaños compactos y regulares sin asumir resolución, orientación o modelo.
- Los datos de métricas tienen definición trazable y no filtran títulos, OCR, imágenes o información privada.
- Build y tests ejecutados con resultados comprobables en los destinos exigidos; validación firmada para servicios que requieren Keychain/App Group/iCloud.
- Matriz visual firmada con claro/oscuro, ES/EN, tema base, estados vacío/error/éxito, Dynamic Type, safe areas, orientación, Duo abierto/plegado e iPad multitarea.
- Todo hallazgo adicional se anota con evidencia, impacto, alcance, acción y verificación.

## Estado de la auditoría inicial

El análisis estático, los informes existentes y las capturas proporcionadas constituyen el baseline previo a los cambios. La implementación de esta tarea está documentada a continuación. Los cambios locales preexistentes del proyecto, incluida la tarea 225 y sus documentos, se conservaron.

## Implementación en curso — 2026-10-19

### Cambios realizados

- Inicio: añadidas métricas locales de documentos, documentos con redacciones, documentos en Bóveda y documentos con marca de agua; cada tarjeta abre la lista que corresponde y los nombres evitan afirmar que un documento está completamente protegido solo por tener alguna redacción.
- Importación: la URL de nube ahora espera en estado de app hasta que `CaptureView` está montada; se eliminó el envío por notificación con temporizador fijo, que podía perder el archivo en la transición entre hojas.
- Persistencia: agregar y editar un documento solo publican el cambio en memoria después de escribir el snapshot cifrado. Si falla la importación, se revierten las imágenes y el original staged y no se abre el editor como si el documento estuviera guardado.
- Reajuste: los renders nuevos se escriben en archivos staged y en el directorio correcto según `isVaulted`; el snapshot apunta a ellos antes de borrar los anteriores. Esto corrige el camino que guardaba una página reajustada de Bóveda en el almacenamiento normal.
- Editor y nube: un fallo al guardar mantiene el editor y los cambios disponibles; la restauración desde CloudKit revierte assets staged si falla el snapshot.
- Procesamiento: la revisión permite cancelar el render final sin crear el documento después de cancelar; el render pesado corre fuera del hilo principal. Se ampliaron a 44 pt los hit targets de cabecera y filtros.
- Lote: el estado final distingue documentos actualizados de documentos cuyo snapshot falló, y no presenta como completo un lote parcialmente persistido.
- Cobertura añadida para carga de imagen, PDF multipágina, archivo no compatible, límite de páginas y transacciones de inserción/edición.
- Procesamiento/cancelación: cancelaciones durante OCR y enriquecimiento ya no continúan al commit; el render final de revisión se cancela junto con el cierre.
- Recuperación de importación: si falla la escritura de páginas se retiene la entrada en memoria y, si falla solo el snapshot, se retienen los assets cifrados. El diálogo permite reintentar o descartar explícitamente.
- Fotos/cámara: una selección parcial de Fotos que no se pudo leer completa se rechaza con un mensaje localizado en vez de importar silenciosamente solo algunas páginas; el fallo de VisionKit ahora informa que no se pudo iniciar el escáner y sugiere revisar permisos.
- Crash de CloudKit (informe 22:37): el stack termina en `CKContainer(identifier:)` durante `PremiumManager.init`. La fábrica lazy devuelve `nil` en Simulator para builds sin entitlement y mantiene CloudKit en dispositivo; el simulador no podrá validar sincronización CloudKit hasta instalar una build firmada con container entitlement.
- Crash de presentación (informe 22:41): UIKit abortó al resolver un `UIAlertController` durante una transición; el informe no incluye un call site Swift que identifique la vista exacta. Quité el alert nativo del flujo de captura y lo reemplacé por una tarjeta SwiftUI accesible que aparece en el propio cover al cerrar cámara/picker, con reintento o descarte.

### Validación pendiente y dispositivos

- `git diff --check` y parseo sintáctico de los Swift modificados: correctos. La build Debug para iOS 27.1 también pasó en esta sesión. Sigue pendiente completar la matriz de tests en los destinos libres y recopilar un `.xcresult` verde para el conjunto actual.
- `iPhone 18 Pro` — UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`, iOS 27.0, Booted; la reconsulta no destructiva de `launchctl list` encontró activos `com.romerodev.personalcare` y `com.romerodev.shield`. No se instaló ni alteró; validación en cola.
- `iPhone Duo - VitalsPath Session` — UDID `EBD930CD-55C3-4C41-9987-C6DB90EDCFC6`, iOS 27.1, Booted; MaskID 1.1.4 build `1142026101601` instalada y abierta. Conserva los 6 documentos de prueba y su perfil; la validación visual y funcional descrita abajo se hizo aquí.
- `iPhone Duo` — UDID `BF5C28D6-2B6D-46FC-82E8-9A248F5C0186`, iOS 27.1, Booted; UpLedger está activo. Se deja intacto.
- `iPad Pro 13-inch (M5)` — UDID `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`, iPadOS 27.0, Booted; UpLedger está activo. Se deja intacto y la validación queda en cola.
- Inventario de runtimes: iOS 27.0, iOS 27.1 y watchOS 27.0. No hay runtime iOS 18 instalado; no se afirmará compatibilidad probada con el mínimo hasta instalarlo.
- El proyecto no tiene target watchOS, por lo que no se instala ni valida una app de reloj.
- Pendiente: liberar y revalidar iPhone 18 Pro; compilar e instalar allí primero; ejecutar después en Duo y iPad; probar cámara, Fotos, Archivos, nube, procesamiento/revisión, edición/redacciones, guardado, Bóveda y exportación con build firmada; revisar Duo plegado/abierto y iPad en portrait/landscape/Split View sin interferir con sesiones activas.

### Ajustes posteriores a las capturas del Duo — 2026-10-19

- Evidencia nueva, 08:35:44: la fila de categorías muestra una cápsula cortada en el borde derecho, mientras el rail lateral ocupa esa zona. Se reemplazó la fila horizontal por una cuadrícula adaptable de cápsulas de una línea y ancho flexible; en tamaños de accesibilidad pasa a una columna y permite hasta dos líneas.
- El botón de escaneo deja de vivir entre los controles superiores. En iOS 26–27.0 usa `tabViewSidebarBottomBar`; en iOS 27.1 se añade como acción `.bottomBar` al `NavigationStack` de cada destino, con prioridad alta y preferencia vertical, porque la acción en `topBarTrailing` del `TabView` no aparecía en el rail real. En compact se conserva el `tabViewBottomAccessory`.
- En Perfil se retiró el CTA ancho “Guardar perfil” del final del formulario. Cerrar y Guardar quedan como acciones circulares icon-only en la barra inferior, con nombre accesible y color para diferenciar la acción primaria.
- Se añadieron comprobaciones UI para el escaneo en el rail inferior, un único guardado del Perfil y ausencia del botón de guardado duplicado.
- `git diff --check` y parseo Swift pasaron. La compilación `xcodebuild -quiet -project Shield.xcodeproj -scheme Shield -destination 'platform=iOS Simulator,id=EBD930CD-55C3-4C41-9987-C6DB90EDCFC6' -derivedDataPath /tmp/MaskID-226-DuoBuild build` pasó; la build se instaló y lanzó en ese UDID sin borrar datos. En `v68_Closed`, la captura confirma avatar de perfil visible y escaneo destacado entre el perfil y el grupo de destinos. Tocar el escaneo abre “Añadir documento”. Archivos abre el selector nativo; se canceló sin importar contenido. No se alteraron el iPhone 18 Pro ni el Duo genérico.
- Revisión del menú de captura en el Duo: el diseño anterior dejaba los tipos de documento solo en la columna derecha y la parte baja izquierda vacía. Se reorganizó en dos filas equilibradas: escaneo y fuentes a la misma altura; tipos en una tarjeta adaptativa a todo el ancho, que mantiene dos columnas en compacto y muestra las cinco opciones en una fila cuando hay espacio. Se añadió texto que explica que las fuentes continúan por el mismo flujo de revisión. La captura de la build instalada confirma simetría, tipos sin recorte y botones dentro del área visible.
- **Hallazgo pendiente del menú de captura:** queda espacio libre bajo la tarjeta de tipos en la pose `v68_Closed`. El contenido ya no queda desequilibrado a la derecha; en la siguiente fase revisaré la distribución vertical y validaré la misma pantalla en poses plegada y abierta, iPhone compacto e iPad Split View antes de ajustar la altura.
- Flujo funcional comprobado en el dispositivo: acción del rail → “Añadir documento” → selector de Archivos → ubicación local visible → volver sin seleccionar. El procesamiento después de elegir un documento no se ejecutó manualmente en el Duo en esta sesión. Se conservan como evidencia los tests previos de `ImportPipelineTests` (imagen y PDF multipágina, límites, transacciones) y los UI tests que abren/cancelan Fotos y abren Archivos en un simulador clonado; la ejecución actual de toda la suite sigue pendiente.
- Verificación focalizada ejecutada ahora con `xcodebuild test` en clones del VitalsPath Duo iOS 27.1: `ShieldLaunchTests.testHomeBrandAndProfileAreAvailableInToolbar` pasó; `ImportPipelineTests` pasó en sus cinco casos (imagen, PDF multipágina, límites, formato incompatible y downsampling). Resultado: **TEST SUCCEEDED**, [Test-Shield-2026.10.19_10-13-59-+0200.xcresult](/tmp/MaskID-226-DuoBuild/Logs/Test/Test-Shield-2026.10.19_10-13-59-+0200.xcresult). Los clones no modificaron los datos del Duo asignado.
- Device Hub puede cambiar el foco al Duo genérico después de interacciones en su vista emulada; una vez apareció “¿Abrir en UpLedger?”. Se canceló de inmediato, el aviso se cerró y el VitalsPath se re-seleccionó por su UDID. No se aceptó abrir UpLedger.

### Continuación: centrado en el área física del Duo — 2026-10-19

- El usuario no localizó el PIN de MaskID en el Duo VitalsPath. No se solicita ni se cambia la credencial; la comprobación de geometría se continúa en un simulador Duo de QA vacío para no bloquear el trabajo ni alterar el perfil con seis documentos.
- Evidencia de `ShieldUITests/ShieldLaunchTests.swift`: icono y título de bloqueo ya pasan el centrado en el eje físico. El botón principal conservaba un desfase de 42 pt a la izquierda porque el contenedor aplica el inset asimétrico del rail del Duo. Se aplicó `centerOffset` también al botón, se redujo su ancho a 296 pt para mantenerlo en el área segura y se añadió una aserción que exige 80 pt de separación respecto al rail.
- Verificación posterior: `ShieldUITests.ShieldLaunchTests.testLockCompositionCentersOnAvailableDisplayAxis` pasó **1/1** con la comprobación de centro y margen en `MaskID QA Duo 226`, iPhone Duo, iOS 27.1, UDID `234C17FE-1CC3-4DFE-96AB-EF15EE8EEC66`; resultado [MaskID-226-Duo-Lock-Centered-Rail.xcresult](/tmp/MaskID-226-Duo-Lock-Centered-Rail.xcresult). La ejecución previa confirmó que los tres tests focalizados de editor/exportación, selectores de Fotos/Archivos y regreso de Ajustes también pasan en un clon del Duo VitalsPath.
- `git diff --check` pasó después del ajuste. Xcode terminó esta ejecución con éxito; su log contiene advertencias de metadatos del runtime iOS 27.1 (`invalidDigitCount`) y resolución del depurador (`noURL`), sin warnings de XCTest ni fallos de test.
- La suite completa de UI y la matriz multi-dispositivo aún están pendientes. iPhone 18 Pro y iPad siguen Booted en sesiones ajenas; no se instalaron ni alteraron. El proyecto no tiene destino watchOS y no hay runtime iOS 18 instalado. La prueba en el Duo VitalsPath original sigue sin desbloquearse; las pruebas de carga y procesamiento están cubiertas por los cinco tests unitarios y los casos focalizados registrados arriba, pero el recorrido manual de punta a punta no se ha podido repetir sin el PIN.
- Revisión del inventario tras XCTest: el UDID anterior de VitalsPath (`EBD930CD-55C3-4C41-9987-C6DB90EDCFC6`) ya no aparece entre los dispositivos disponibles; no se intentó recrear un simulador con ese nombre ni modificar el Duo genérico de UpLedger. El Duo QA usado por el test quedó Shutdown al terminar. iPhone 18 Pro y iPad permanecen Booted.

### Continuación: barra adaptable y crash al entrar en Ajustes — 2026-10-20

- `iPhone 18 Pro` — UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`, iOS 27.0, Booted. Pasaron `testScanReviewHeaderStaysBelowSystemStatusBar`, `testSettingsCloseExitsFromRootAndDestinations`, `testCaptureToolbarActionOpensDocumentIntake` y `testPhotoPickerCanCancelAndFilesPickerOpens` (dos `.xcresult` del ciclo anterior en `/tmp`).
- `MaskID QA Duo 226` — UDID `234C17FE-1CC3-4DFE-96AB-EF15EE8EEC66`, iOS 27.1, Booted. Pasaron `testDuoScanReviewActionsUseReservedRightRail` y `testSettingsCloseExitsFromRootAndDestinations` en `/tmp/MaskID-226-Duo-Toolbar-Settings-Fix-2.xcresult`. El rail de acciones de la pantalla de revisión quedó a la derecha de la bisagra; no se borraron datos de simulador.
- `iPad Pro 13-inch (M5)` — UDID `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`, iPadOS 27.0. El primer pase del flujo corrigió tres supuestos del UI test para la barra lateral regular y el picker Archivos; tres casos pasaron. `testSettingsCloseExitsFromRootAndDestinations` encontró un cierre al seleccionar Ajustes.
- Evidencia del `.ips` extraído de `/tmp/MaskID-226-iPadPro-UI-Flow-Adjusted.xcresult`: SIGABRT de UIKit en `BUG_IN_CLIENT_OF_TARGETED_PREVIEW__VIEW_IS_NOT_IN_A_WINDOW`, desde `UITabBarControllerSidebar` / `_UITabContainerView` al seleccionar una fila lateral. La causa era que `AuthenticatedShellView` retiraba el `TabView` adaptable al entrar a Ajustes mientras UIKit aún animaba la selección. Se mantuvo el `TabView` montado en iOS 26+; solo se oculta la barra inferior en size class compacto, y se conserva la sidebar nativa en iPad/Duo. El test ahora espera sidebar visible en tamaño regular y ausencia de la barra inferior en compacto.
- Compilación completa de la app y `build-for-testing` para `generic/platform=iOS Simulator`: **BUILD SUCCEEDED** y **TEST BUILD SUCCEEDED**, ambos con DerivedData `/tmp/MaskID-226-iPad-Rail-Fix-Build`.
- El test funcional del arreglo aún no se pudo repetir: CoreSimulatorService y `simdiskimaged` dejaron de responder después del pase de iPad; `simctl list devices available` devuelve `Connection refused` y `launchctl list` no muestra el servicio. La inspección de solo lectura ve tres `launchd_sim` todavía activos (PIDs 14540, 28888 y 90744), por lo que no se reinició ni se arrancó ningún simulador compartido. Reintentar el test de Ajustes en iPad tras recuperación segura del servicio, seguido de iPhone 18 Pro primero y Duo QA.
- Hallazgo adicional: el `.xcresult` iPad registró cuatro warnings de SwiftUI `Modifying state during view update, this will cause undefined behavior.` en los cuatro casos ejecutados; no hay call site útil en el log exportado. Mantenerlo como investigación pendiente y localizar la mutación antes de declarar cerrado el pase de UI.
- `git diff --check` pasó tras estos cambios. No se borraron logs, temporales ni builds; se conservan diagnósticos y resultados en `/tmp` hasta terminar el trabajo y pedir confirmación antes de limpiar, como exige `AGENTS.md`.

### Continuación: editor y hojas adaptativas — 2026-10-20

- Capturas Duo QA de las 09:10 y 15:02–15:03: la banda inferior de herramientas puede mostrar nombres recortados al terminar el ancho disponible; las herramientas restantes dependen de un gesto horizontal sin un estado activo visible. El listado ahora usa iconos y color de selección, conserva nombres y estado accesibles, ofrece nombre al pasar el puntero y desplaza la herramienta activa a la zona visible al cambiar de selección. Se mantiene el desplazamiento horizontal para pantallas compactas.
- Capturas 09:57:37 y 15:03:06: el panel de detecciones queda vacío cuando no hay resultados del análisis automático, sin un camino evidente a OCR manual; “Proteger todos” y “Limpiar” aparecían accionables aunque no podían realizar trabajo. El estado vacío ahora explica qué hacer y abre OCR, y las acciones en lote se deshabilitan cuando no aplican. Las cadenas están localizadas en ES/EN.
- Captura 09:17:25: la hoja Exportar deja un bloque lateral transparente porque `SheetContainer` limitaba manualmente su ancho a la primera división reservada. Se retiró el ancho derivado de la bisagra y se devolvió el tamaño, el fondo y el indicador de arrastre a la presentación nativa de SwiftUI, que ya adapta hojas a regiones de hardware y sistema. La misma corrección aplica a OCR y configuración de marca de agua.
- Añadidos identificadores de accesibilidad para cerrar OCR y para cada herramienta. Nuevos UI tests cubren acciones del rail de Duo, herramientas dentro del viewport, y la ruta de inspector vacío → OCR.
- `xcodebuild ... -destination 'generic/platform=iOS Simulator' ... build-for-testing` terminó en **TEST BUILD SUCCEEDED** después de estos cambios. `git diff --check` y parseo JSON de los catálogos de localización pasaron. Esto compila las pruebas; no afirma que se hayan ejecutado.
- La ejecución visual sigue bloqueada: `CoreSimulatorService connection refused` y `simdiskimaged` no responde. La comprobación delegada de dispositivos se detuvo sin iniciar, reiniciar, borrar ni instalar en ningún simulador. No se puede confirmar el estado actual ni usar con seguridad el iPhone 18 Pro, Duo QA o iPad hasta recuperar CoreSimulator.
- Reintento después de que el usuario desbloqueara el Mac, 15:26:32: `xcrun simctl list devices available` sigue devolviendo `Connection refused`, no detecta runtimes y `simdiskimaged` no responde. La comprobación delegada se detuvo sin modificar simuladores; no se pudo validar el estado de ocupación actual.
- Pendiente de verificación en simulador: anchura y presentación de OCR/Exportar en Duo y iPhone; scroll de herramientas y selección; acciones del rail y safe areas; hojas de Ajustes/Ajuste; pase de UI en iPhone 18 Pro primero, luego Duo e iPad. Mantener también la investigación de los cuatro warnings SwiftUI del pase iPad anterior. No se ha limpiado ningún resultado, temporal ni build.

### Continuación: panel derecho y barra de herramientas en Duo — 2026-10-20

- El panel inspector del `ArrangementView(.split)` ya no limita su ancho a 340 pt y usa fondo de tarjeta en toda la región secundaria asignada por el sistema. El reparto físico de regiones permanece bajo SwiftUI/`ArrangementView`; no se introdujeron coordenadas ni offsets dependientes del modelo.
- La barra inferior del editor usa objetivos de 44 pt y espaciado compacto. La herramienta activa se desplaza al viewport cuando cambia, para que las acciones principales sigan siendo alcanzables en la región izquierda cuando el Duo tiene navegador de páginas.
- Build Debug y `build-for-testing` para iPhone 18 Pro terminaron correctamente. Pasaron tres UI tests focalizados en iPhone 18 Pro (header de revisión bajo la barra de estado, cerrar Ajustes y entrada al selector de importación). En QA Duo pasaron las pruebas de home y acciones de revisión; la prueba del editor detectó inicialmente que “Auto” no era alcanzable y pasó tras compactar la barra. Resultados conservados bajo `/tmp/MaskID-226-*`.
- La build más reciente se instaló en QA Duo y en iPad Pro 13-inch (M5). El lanzamiento en iPad fue confirmado por `simctl get_app_container`. Una ejecución UI en iPad quedó detenida en la autorización de `testmanagerd`; se interrumpieron solo los procesos Xcode/`simctl diagnose` iniciados por esta sesión, sin tocar el simulador ni sesiones ajenas.
- La inspección visual final sigue bloqueada: CUA reporta que macOS está bloqueado y las capturas del Duo salen negras. Además, CoreSimulatorService ha vuelto a devolver `Connection refused` y `simdiskimaged` está indisponible. No se reinició ni se modificó ningún simulador; no se afirma que el hueco del panel haya quedado visualmente resuelto hasta revisar una captura real.
- No hay target ni scheme watchOS. No se realizó emparejamiento de sesiones compartidas en este ciclo. Se conservan resultados, builds y capturas temporales; no se limpió nada.

### Instalación solicitada en QA Duo — 2026-10-20

- Se compiló `MaskID.app` desde el estado local actual con `xcodebuild build-for-testing`; **BUILD SUCCEEDED** y **TEST BUILD SUCCEEDED**. Metadatos instalados: versión `1.1.4`, build `1142026101601`.
- Se instaló primero en `iPhone 18 Pro` (`1454EA8D-A019-4B07-B57C-1433E0F21BE0`, iOS 27.0) y después en `MaskID QA Duo 226` (`234C17FE-1CC3-4DFE-96AB-EF15EE8EEC66`, iOS 27.1). `simctl get_app_container` confirmó la ruta del bundle en ambos destinos; MaskID arrancó en Duo con PID `36753`.
- La primera ejecución en QA Duo mostró el aviso nativo de iOS sobre el cambio de icono; se cerró en Device Hub. La app quedó en su pantalla de bloqueo “Tu espacio privado está bloqueado”. No se introdujo ni modificó el PIN; la inspección visual de las vistas autenticadas en este dispositivo requiere que el usuario lo desbloquee.
- En iPhone 18 Pro se ejecutaron cuatro UI tests focalizados: tres pasaron (`testScanReviewHeaderStaysBelowSystemStatusBar`, `testCaptureToolbarActionOpensDocumentIntake`, `testPhotoPickerCanCancelAndFilesPickerOpens`) y uno falló (`testSettingsCloseExitsFromRootAndDestinations`). El fallo es `XCTAssertFalse` porque `libraryTab(in: app).exists` devuelve verdadero durante Ajustes. La captura posterior al runner muestra SpringBoard, por lo que no confirma si la barra está visible o si solo queda un elemento en el árbol de accesibilidad. Resultado: `/tmp/MaskID-226-iPhone18-PostInstall.xcresult`; investigar con captura/hierarquía antes de cambiar la implementación o debilitar la aserción.
- El QA Duo queda instalado y en ejecución, pero el diálogo de PIN impide validar manualmente las vistas protegidas en esta sesión. No se alteró ni reinició ningún simulador ajeno. Se conservaron DerivedData y `.xcresult`; la limpieza queda pendiente de confirmación según las instrucciones del proyecto.

### Validación tras abrir Device Hub — 2026-10-20

- Device Hub (`com.apple.dt.Devices`) está abierto y muestra los destinos `iPhone 18 Pro` (iOS 27.0, `1454EA8D-A019-4B07-B57C-1433E0F21BE0`), `iPhone Duo` (iOS 27.1, `BF5C28D6-2B6D-46FC-82E8-9A248F5C0186`) y `iPad Pro 13-inch (M5)` (iPadOS 27.0, `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`). No hubo espera en cola. La app instalada fue versión 1.1.4, build `1142026101601`; `simctl get_app_container` confirmó respectivamente los bundles `.../1454EA8D-A019-4B07-B57C-1433E0F21BE0/Application/AB8F6512-77A6-4686-A1F1-07DFD0A16D85/MaskID.app`, `.../BF5C28D6-2B6D-46FC-82E8-9A248F5C0186/Application/F07D0955-1DB6-452D-874C-46FADC55A953/MaskID.app` y `.../2F44FF69-62E3-471E-AFEB-6690BDA4ADC1/Application/88761E2A-850B-4525-A25E-4A46B553EC73/MaskID.app`. La última compilación local declara mínimo iOS 18.0 y SDK 27.1.
- Pasaron las pruebas focalizadas finales: Ajustes en iPhone 18 Pro (`/private/tmp/MaskID-226-iPhone18-TabGuard-Final.xcresult`), Duo (`/private/tmp/MaskID-226-iPhoneDuo-TabGuard-Settings.xcresult`) e iPad (`/private/tmp/MaskID-226-iPad-TabGuard-Settings.xcresult`); Inicio en iPad (`/private/tmp/MaskID-226-iPad-TabGuard-Home.xcresult`). En Duo también pasó el flujo de Inicio en pose cerrada (`/private/tmp/MaskID-226-iPhoneDuo-Theme-Deferred-Final.xcresult`). La suite de UI de editor/orientación, importación y revisión tiene resultados previos registrados arriba.
- La suite completa de `ShieldTests` terminó con 124 pruebas y 11 incidencias en `/private/tmp/MaskID-226-iPhone18-Unit-Suite-Rerun.xcresult`. Los fallos abarcan `DocumentStorePersistence` (cuatro aserciones tras no encontrar lo guardado), `secureExportRemovesSourceTextFromOutput`, `maximumBatchStreamingExport`, `encryptedStorageUsesSeparateKeyDomains`, `pinLifecycle` y `freshInstallPurgesOrphanedKeychainData`. La evidencia en el resultado señala `OSStatus -34018` para las operaciones de Keychain. Esta ejecución usó `CODE_SIGNING_ALLOWED=NO`; el binario no contiene entitlements y `security find-identity -v -p codesigning` no encontró identidades válidas. Por tanto, los fallos que dependen de `SecureFileStore`/Keychain no validan el comportamiento de la build firmada y no se deben presentar como regresiones confirmadas. Está pendiente repetir la suite con firma y entitlements válidos.
- Los resultados de Ajustes e Inicio en iPad aún contienen el warning SwiftUI `Modifying state during view update, this will cause undefined behavior`; no tiene backtrace asociado en el informe y las dos mitigaciones probadas no lo eliminaron. Mantener abierta su localización.
- Tras cerrar los diagnósticos de la suite unitaria, `simctl` pasó a devolver `CoreSimulatorService connection became invalid` / `Connection refused` y no puede enumerar destinos. Device Hub sigue abierto y muestra los simuladores, pero no se reinició ningún servicio ni dispositivo. No se hizo otra instalación después de esa pérdida de conexión.
- No hay runtime iOS 18 instalado, así que la compatibilidad con el mínimo declarado no se ejecutó en ese runtime. No hay target/scheme watchOS. La validación de CloudKit, grupos compartidos e iCloud tampoco se completó en esta build sin firma ni con sesiones autenticadas concurrentes. No afirmar la aceptación global del proyecto hasta cerrar estas validaciones y los criterios restantes del plan.
- `git diff --check` pasó. Los resultados, logs, capturas y DerivedData de `/private/tmp` se conservan; no se limpió nada. La tarea 226 permanece activa.

### Hallazgo visual del usuario — editor Duo — 2026-10-21

- La captura facilitada por el usuario identifica controles del editor demasiado próximos al límite del rail vertical reservado; el carrusel de estilos presenta una tarjeta parcialmente visible y la toolbar inferior queda cerca del borde del panel.
- Se conservó el comportamiento automático del toolbar vertical de `NavigationStack`. El sistema coloca las acciones nativas de navegación en el rail y mantiene el canvas, banner, zoom, selector de estilos y herramientas dentro del contenido seguro.
- La comprobación adicional del menú encontró un desbordamiento concreto: una fila del menú “Más”, abierta desde el rail, llegaba a x=442 pt cuando el contenido de la ventana de 466 pt terminaba en x=382 pt. En pantallas compactas, “Más” ahora vive junto a los metadatos del documento dentro del contenido; en tamaño regular sigue en el toolbar nativo.
- Los UI tests verifican en Duo cerrado que lienzo, scroll de herramientas, herramienta activa, selector de estilos, zoom, botón “Más” y las opciones abiertas del menú quedan fuera del rail reservado; también comprueban que Cerrar, Exportar y el resto de controles nativos sigan accesibles.

### Revisión de captura aportada — 2026-10-21

- La imagen `/Users/romerodev/Desktop/Screenshot iPhone Duo 21-10-2026 at 07.37.33.png` confirma dos defectos visuales: los controles de la banda inferior quedan demasiado cerca del borde del rail y, en la plantilla de DNI, “REINO DE ESPAÑA” se solapa con “DOCUMENTO NACIONAL DE IDENTIDAD”.
- El solapamiento se origina en `DNISpainView`: ambas cadenas se dibujaban con tamaños fijos relativos a la altura de la tarjeta y sin límites de columna. Ahora se mide cada cadena con su fuente y se reduce hasta caber en columnas separadas; se añadió cobertura unitaria de esa geometría.
- Se amplió el margen trailing seguro de la metadata, banners, selector de estilos, barra de herramientas y área del canvas. El color de fondo sigue a sangre y el contenido interactivo recibe el margen.
- El test Duo ya no estima la zona reservada como 80 pt desde el borde de la ventana. Calcula el límite a partir del frame real de las acciones nativas Cerrar/Exportar y exige 12 pt de margen antes de comprobar controles, zoom, canvas, selector y menú.
- Pendiente para el cierre: compilar el estado completo y capturar el editor en iPhone 18 Pro, iPhone Duo y iPad; revisar especialmente la cabecera del DNI y el margen visual respecto al rail en la captura Duo. La captura suministrada es evidencia previa, no una validación posterior a estos cambios.

### Validación final del editor Duo — 2026-10-21

- Device Hub estuvo abierto. Los tres simuladores estaban booted y libres, sin espera: iPhone 18 Pro `1454EA8D-A019-4B07-B57C-1433E0F21BE0` / iOS 27.0; iPhone Duo `BF5C28D6-2B6D-46FC-82E8-9A248F5C0186` / iOS 27.1; iPad Pro 13-inch (M5) `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1` / iPadOS 27.0. `simctl appinfo` confirmó `MaskID` 1.1.4 (1142026101601) en cada destino tras la instalación final.
- Debug y `build-for-testing` terminaron con éxito. Se corrigió además el warning de aislamiento del helper `PDFPageDisplayGeometry.size` con `nonisolated`; la compilación posterior dejó de reportarlo.
- Pasaron los UI tests finales: iPhone 18 Pro 1/1 (`/private/tmp/MaskID-228-iPhone18-Final-20261021-03.xcresult`); iPhone Duo 2/2 (`/private/tmp/MaskID-228-Duo-Final-20261021-05.xcresult`), incluyendo menú cerrado y acciones adaptativas; iPad 1/1 (`/private/tmp/MaskID-228-iPad-Final-20261021-03.xcresult`), incluyendo rotación/inspector.
- Captura final del Duo: `/private/tmp/MaskID-228-Duo-Final-attachments-20261021-05/15C36F84-A1FF-48D4-B3A8-7E8820965537.png`. Muestra el botón de menú dentro del encabezado de contenido y el rail negro libre para reloj, widgets y navegación del sistema.
- El test de iPad aún registra un warning SwiftUI `Modifying state during view update, this will cause undefined behavior.` al iniciar la app antes del cambio de orientación; el `.xcresult` no incluye backtrace. La mitigación del bootstrap OCR no lo quitó. Siguiente paso: localizar la mutación de estado desde el diagnóstico de runtime y repetir el test iPad.
- La prueba de UI corre sin firma (`CODE_SIGNING_ALLOWED=NO`); un error de almacenamiento seguro puede mostrar una tarjeta que cubre el editor. Los tests Duo la descartan antes de medir layout. Los fallos de Keychain sin firma siguen sin validar la build firmada.
- No hay runtime iOS 18 disponible ni target/scheme watchOS; no se instaló ni emparejó Apple Watch. No se validaron sesiones compartidas concurrentes en este ciclo. Estos puntos y la investigación SwiftUI siguen abiertos para la tarea global 226; no se marca completa.
- `git diff --check` pasa. Se conservan los resultados, captura y DerivedData bajo `/private/tmp`; no se limpió nada a la espera de la confirmación requerida por `AGENTS.md`.

### Estado de acceso a simuladores — 2026-10-21, 09:54 UTC

- `xcrun simctl list devices available` y `xcrun simctl list runtimes` fallaron con `CoreSimulatorService connection became invalid` / `Connection refused`; Xcode indicó que no podía descubrir runtimes.
- La consulta de solo lectura de CUA informó que macOS está bloqueado y no puede desbloquearse automáticamente. No se iniciaron, apagaron, reiniciaron ni modificaron simuladores.
- `xcodebuild -showdestinations` tampoco pudo enumerar destinos; además, el resolver SPM no pudo escribir en la caché global del usuario bajo el sandbox actual. No se ejecutó build ni prueba, y los resultados de simulador siguen pendientes hasta recuperar el acceso con el Mac desbloqueado.
- La comprobación estática de cierre pasó: `swiftc -frontend -parse` en los ocho Swift modificados, `git diff --check` y parseo JSON de los cuatro catálogos de localización.

### Cierre de la corrección visual y gate final — 2026-10-21

- `DuoVerticalToolbarGutter` consulta `toolbarVerticalEdge` y añade margen solo en el lado donde el sistema coloca la barra vertical; en iPhone convencional mantiene el ancho completo. La cabecera DNI reduce su tipografía al ancho real de cada columna.
- La captura del usuario permitió detectar que las máscaras sugeridas cubrían etiquetas, no siempre el valor completo. Se corrigieron la geometría, los márgenes y las zonas de retrato de DNI ESP, pasaporte USA/MEX, DNI italiano, permiso UK y documento genérico. Se añadió la fecha de nacimiento a los modelos UK y genérico.
- El fallback de la hoja OCR dejó de depender de índices fijos que apuntaban a otros campos en varias plantillas. Ahora resuelve por clave semántica; los nombres separados se cubren juntos, y las etiquetas nuevas se localizan mediante cadenas existentes.
- `xcodebuild test` para `ShieldTests` pasó en los UDID exactos: iPhone 18 Pro (iOS 27.0), iPhone Duo (iOS 27.1) e iPad Pro 13-inch M5 (iPadOS 27.0). En cada destino: 147 pasaron, 0 fallos, 1 omitido. La omisión es `revenueCatOfferingPackages`, desactivada salvo `RUN_REVENUECAT_INTEGRATION_TESTS=1`.
- Capturas de la build final: `/tmp/MaskID-final-validation-20261021/iPhone18Pro-editor-final.png`, `/tmp/MaskID-final-validation-20261021/iPhoneDuo-editor-final.png` y `/tmp/MaskID-final-validation-20261021/iPadPro13-editor-final.png`. En Duo, el contenido termina antes del rail reservado y ambos títulos del DNI quedan separados; en iPhone convencional no aparece la franja lateral vacía.
- El gate completo con `ShieldUITests` no produjo un resultado utilizable: Xcode repitió `debugger version lookup failed ... noURL` y `invalidDigitCount(94232)`; el bundle quedó sin `Info.plist` y se interrumpió solo el proceso de prueba de esta tarea. Las capturas manuales sí confirman el editor, pero no sustituyen la suite UI.
- Sigue pendiente repetir XCUITest en iPad para rotación/multitarea y en Duo para rails/menús. El proyecto no incluye target o scheme watchOS; tampoco contiene sincronización/sesiones compartidas de perfiles que permitan ejecutar esa parte de la matriz. No se emparejó Apple Watch ni se inventa resultado para esas funciones ausentes.
- `git diff --check` pasa. No se borraron cachés, resultados, logs ni capturas: las instrucciones del proyecto exigen pedir confirmación antes de limpiar temporales.

### Corrección del ancho seguro Duo tras revisión del usuario — 2026-10-21

- El usuario señaló que la captura de las 11:56 ya respetaba el rail, pero dejaba una franja vacía mayor que la reservada. La revisión del cambio confirmó que `DuoVerticalToolbarGutter` imponía 24 pt adicionales: en la captura suministrada, el contenido acababa aproximadamente en x=1074 px y el rail empezaba en x=1147 px (unos 73 px extra, aproximadamente 24 pt a escala 3x).
- Se retiró el gutter fijo y sus usos del editor. El contenido horizontal ahora toma la propuesta de ancho segura del contenedor (`NavigationStack`), mientras sus fondos no ignoran los bordes seguros (`ignoresSafeAreaEdges: []`). Así el límite cambia con la pose y el dispositivo; iPhone convencional e iPad no reciben un inset específico de Duo.
- La captura Duo posterior `/private/tmp/MaskID-final-validation-20261021/DuoAttachments-dynamic/79A13E0C-3D08-4BC4-A91D-2A65C544F21D.png` (1398×2034) muestra el borde del banner en x=1145–1146 y el rail comenzando en x=1147. La diferencia es el trazo antialias del borde, sin una banda vacía adicional.
- Pasaron 2/2 UI tests Duo en iOS 27.1, UDID `BF5C28D6-2B6D-46FC-82E8-9A248F5C0186`: `testDuoClosedEditorKeepsContentInsideTheSafeArea` y `testDuoEditorActionsAndToolsStayInTheirAdaptiveRegions`. Resultado: `/tmp/MaskID-final-validation-20261021/DerivedData/Logs/Test/Test-Shield-2026.10.21_12-00-18-+0200.xcresult`.
- La misma build se instaló y lanzó en iPhone 18 Pro (iOS 27.0, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`) y iPad Pro 13-inch (M5, iPadOS 27.0, UDID `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`). Capturas: `/tmp/MaskID-final-validation-20261021/iPhone18Pro-editor-dynamic-final.png` y `/tmp/MaskID-final-validation-20261021/iPadPro13-editor-dynamic-final.png`. Esto confirma lanzamiento y revisión de layout; no sustituye pruebas específicas de rotación/multitarea iPad.
- `git diff --check` pasa y no quedan usos de `DuoVerticalToolbarGutter` ni de `safeAreaPadding` en las superficies del editor. La tarea 226 permanece activa por verificaciones globales pendientes. No se limpiaron artefactos temporales: el `AGENTS.md` del proyecto exige confirmación previa.

### Revalidación tras las correcciones de Scan, Inicio y Ajustes — 2026-10-24

- La tarea 239 cerró la eliminación del accesorio Scan persistente; conserva la acción principal de Inicio y la acción contextual del toolbar de iPad. La tarjeta `settings.summary` vuelve inmediatamente debajo del encabezado de Ajustes y precede a las secciones.
- En la build actual pasaron 4/4 UI tests focalizados en iPhone 18 Pro (iOS 27.0), 5/5 en iPhone Duo (iOS 27.1) y 4/4 en iPad Pro 13-inch M5 (iPadOS 27.0); iPad omitió un caso exclusivo de Duo. Seguridad/Privacidad pasó 13/13, incluida la política de PIN opcional. Ver `Docs/iphone-duo/TEST_MATRIX.md` y la task 239 para los `.xcresult`.
- `xcodebuild build-for-testing` volvió a compilar la app y las suites para el UDID explícito de iPhone 18 Pro. Solo reapareció la advertencia deprecada de `StoreKitTest` proveniente del SDK.
- Queda pendiente correr los casos UI específicos de lote revisable, búsqueda OCR y perfiles de protección (tasks 229 y 231), además de capturar visualmente el estado actual del Duo tras confirmar que macOS está desbloqueado. La inspección previa de CoreSimulator encontró `com.romerodev.repsfitness` activo en iPhone 18 Pro; el orden obligatorio mantiene los demás recorridos en cola hasta que ese destino quede libre.
- No hay target/scheme watchOS ni sesión colaborativa/perfiles compartidos entre iPhone en el producto actual; esas pruebas no se pueden ejecutar sin ampliar el alcance funcional. Se conserva la limitación documentada y no se afirma sincronización inexistente.
- El artefacto de App Store Connect 1.1.6 build `1162026102401` se archivó antes de los cambios actuales de shell y autenticación. La build está VALID y enlazada; una entrega que incluya el código actual necesita un número nuevo. Se ha pedido decisión antes de crear o cargar otra build.

### Revisión de evidencia Duo — 2026-10-24

- Un `.xcresult` histórico de Duo abierto contiene dos fallos sobre la posición de Scan en una rail lateral. Sus pruebas (`testDuoHomeKeepsBrandProfileAndScanVisible` y la aserción en `testHomeBrandAndProfileAreAvailableInToolbar`) no existen en la fuente actual, que elimina el accesorio flotante y comprueba que `home.primaryAction` permanezca visible. Se considera evidencia obsoleta y se volverá a validar con 2402.
- El mismo resultado conserva un fallo de desplazamiento en el formulario de perfiles personalizados en pose abierta: ocho gestos no hicieron aparecer `editor.customProfile.maskStyle`. El formulario muestra un scroll vertical de varias páginas, pero el resultado es anterior al último estado de fuente; se reejecutará en 2402 antes de cambiar su presentación.
- Una captura antigua exportada para esa ejecución es completamente negra, por lo que no sirve para inspección visual.

### Revalidación de la fuente 2403 — 2026-10-25

- iPhone 18 Pro iOS 27.0: 7/7 pruebas de regresión UI pasaron en `/private/tmp/MaskID-2403-iPhone18-RegressionMatrix.xcresult`, incluidas ausencia del accesorio Scan y orden de la tarjeta de resumen en Ajustes.
- iPhone Duo iOS 27.1: 4/4 pruebas focalizadas pasaron en resultados de Ajustes, cola, búsqueda y perfiles; DeviceHub confirmó el resumen bajo el header. Resultados: `/private/tmp/MaskID-2403-Duo-SettingsSummary-final.xcresult`, `/private/tmp/MaskID-2403-Duo-BatchQueue-signed.xcresult`, `/private/tmp/MaskID-2403-Duo-SearchProfile-signed.xcresult`.
- iPad Pro 13-inch M5 iPadOS 27.0: 4/4 pruebas focalizadas pasaron en `/private/tmp/MaskID-2403-iPad-SettingsSummary-final.xcresult` y `/private/tmp/MaskID-2403-iPad-FeatureRegression-signed.xcresult`; la captura confirma resumen de Ajustes bajo el título.
- Sigue pendiente inspección de Stage Manager/Split View, el target watchOS no existe y el producto no ofrece sincronización de perfiles compartidos. La tarjeta de Ajustes y la eliminación del Scan flotante sí están validadas en los destinos anteriores.
