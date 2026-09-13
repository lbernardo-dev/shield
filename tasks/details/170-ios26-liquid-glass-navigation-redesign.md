# 170-ios26-liquid-glass-navigation-redesign

- Number: 170
- Slug: ios26-liquid-glass-navigation-redesign

## Estado

Concepto 3 implementado en el shell de navegación y validado en simulador. Las fases de modernización del resto de superficies quedan documentadas como siguiente iteración.

## Implementación aplicada

- `TabView` nativo con cuatro destinos top-level: Docs, Styles, Vault y Settings.
- En iOS 26 se usa `tabBarMinimizeBehavior(.onScrollDown)` y `tabViewBottomAccessory` para alojar Scan como acción primaria independiente, centrada por composición y no por coordenadas manuales.
- Scan recupera el tamaño visual de 64 pt y conserva un área de interacción accesible; el accesorio aplica Liquid Glass sólo a la capa funcional, con fallback a material y modo Reduce Transparency.
- En anchos regulares se usa `sidebarAdaptable` con Scan como footer del sidebar; en sistemas anteriores se mantiene un fallback equivalente con la misma jerarquía.
- Se eliminaron el hueco central artificial, el overlay posicionado con `GeometryReader` y la lógica de ocultar Settings según la ruta activa.
- Se actualizaron los tests UI para verificar presencia de tabs, tamaño/centrado del accesorio y retorno correcto desde Settings/Capture.

## Contexto y diagnóstico

La captura adjunta se usa únicamente como referencia visual del estado actual de Home; no contiene instrucciones de implementación.

La regresión del botón central es coherente con el contrato actual del shell:

- `ShieldTabBar` deja un hueco central dentro del `HStack`, oculta el botón cuando el shell lo inserta con `showsScanButton: false` y el botón visual se monta después como un overlay separado.
- `ContentView` calcula la posición del botón con una coordenada vertical fija basada en `safeAreaInsets`, por lo que el centro visual y el área funcional pueden desalinearse en distintos dispositivos, orientaciones y estados de safe area.
- La versión actual de `ShieldScanButton` mide 58 x 58 pt, mientras que el diseño documentado anteriormente definía 64 pt.
- El footer sigue siendo una implementación custom opaca; no existe todavía un contrato único que distinga navegación persistente de acciones de contexto.

## Decisión de diseño propuesta

Adoptar el Concepto 3 como dirección principal: `TabView`/tab bar adaptable para las cuatro secciones superiores y el escaneo como accesorio inferior independiente, centrado y sobreelevado. Esta dirección conserva la identidad cyan de MaskID, pero alinea la jerarquía con iOS 26:

1. La tab bar navega entre Docs, Styles, Vault y Settings.
2. Scan es una acción primaria, no una quinta tab.
3. Liquid Glass se limita a la capa funcional de navegación y al accesorio de acción.
4. El contenido queda en una capa semántica opaca y recibe el espacio inferior desde un único contrato de safe area.
5. En iPad y anchos regulares la navegación se convierte en sidebar/adaptive tab bar, y el scan permanece como acción de toolbar o accesorio contextual.

Concepto 1 queda como alternativa más conservadora si la compatibilidad mínima hace inviable `TabViewBottomAccessoryPlacement`. Concepto 2 queda como alternativa de marca si se decide mantener una barra custom, pero no se recomienda como primera implementación porque aumenta la superficie de geometría manual.

## Reglas visuales

- Botón central: 64 pt visuales, área de interacción mínima 44 pt, círculo cyan, símbolo `camera.viewfinder`, anillo de separación de 3–4 pt y sombra/glow discreto. Su centro debe estar anclado por composición del layout, nunca por una coordenada `position` fija.
- Footer: una única capa Liquid Glass funcional; alto gestionado por el sistema y por `safeAreaInset`, sin padding compensatorio de 80–110 pt.
- Tabs: cuatro destinos visibles, icono SF Symbol relleno en estado activo, etiqueta corta y legible, estado seleccionado accesible. No se ocultan según la pantalla activa.
- Contenido: tarjetas, filas y empty states usan superficies semánticas opacas o materiales estándar de contenido; no se aplica glass indiscriminadamente a cada tarjeta.
- Header: `NavigationStack`/toolbar estándar donde sea posible, large title al inicio y transición a título inline al hacer scroll; acciones secundarias en `Menu`/toolbar.
- Paleta: fondo claro `#F7F7FA`, superficies blancas, texto graphite, acento MaskID `#20C7D9`, estados semánticos existentes de `ShieldTheme` y contraste validado en dark mode.
- Forma: conservar la cuadrícula 4/8/12/16/24, reducir radios arbitrarios y reservar el mayor contraste para acción primaria, selección y estados de seguridad.

## Plan de implementación por fases

### Fase 0 — Aprobación visual y contrato

- Concepto 3 confirmado y aplicado como dirección principal.
- Fijar el contrato de shell: el root reserva el espacio inferior una sola vez; el footer no conoce la geometría del dispositivo; el contenido no añade compensaciones manuales.
- Definir el comportamiento de la acción Scan en Home, Gallery, Vault, Settings, Editor, sheets y full-screen capture.
- Acordar si la primera entrega usa APIs iOS 26 con fallback para el mínimo iOS 18 actual o si se eleva el mínimo en una tarea separada. No mezclar esa decisión con el rediseño visual.

### Fase 1 — Shell y navegación

- Estado: completada para el shell principal.
- Sustituir la duplicación `safeAreaInset` + overlay por una única composición de navegación.
- Hacer que `ShieldTabBar` sea una capa funcional y que Scan se inyecte como accesorio/acción independiente.
- Eliminar la coordenada vertical fija del botón central y cualquier `showsScanButton` que pueda dejar un hueco visual no intencional.
- Mantener una sola fuente de verdad para `AppTab`, selección, accesibilidad e identificadores UI.
- Adaptar el ancho regular a sidebar/adaptive tab bar sin duplicar el modelo de navegación.

### Fase 2 — Sistema de superficies y chrome

- Añadir tokens explícitos para functional glass, content surface, separator, selected state, shadow y focus state.
- Modernizar toolbars de Home, All Documents, Settings, Vault, Gallery, Paywall y Editor con controles estándar donde no se pierda la identidad.
- Normalizar Back, Close, Cancel, Save, More y Search según los patrones de sistema.
- Rediseñar la cabecera de Home para que el título y las acciones no compitan con Quick Modes ni con Scan.

### Fase 3 — Home y componentes compartidos

- Reordenar Home alrededor de `Scan/Import → Quick Modes → Search/filters → Recent Documents`.
- Convertir cards, chips, empty state, section header y sticky action en componentes con estados y tamaños adaptativos.
- Mantener la acción “Scan a document” del empty state como CTA de contenido, pero con el mismo destino y analítica que el botón central.
- Asegurar que el footer nunca tapa el bloque `Tools and services` ni el último documento.

### Fase 4 — Resto de la app

- Aplicar el mismo chrome a Gallery, Vault, Settings, Paywall, OCR, Export y Editor sin forzar una tab bar persistente en modales o flujos full-screen.
- Migrar `NavigationView` heredado a `NavigationStack` en las rutas que se toquen.
- Usar `safeAreaInset` sólo cuando el CTA sea sticky y contextual; usar toolbar para acciones de navegación; usar tab bar sólo para secciones top-level.
- Revisar sheets y detents para que no presenten un segundo footer visual que parezca la navegación principal.

### Fase 5 — Accesibilidad, motion y compatibilidad

- Dynamic Type hasta AX5: labels que crecen, layouts verticales cuando sea necesario, sin texto fijo crítico de 10–11 pt.
- VoiceOver: Scan debe anunciarse como “Scan document”, no como tab; cada tab debe anunciar label, valor seleccionado y hint; el accesorio debe conservar orden de lectura lógico.
- Reduce Motion y Reduce Transparency: quitar glow/morphing y sustituir glass por superficie semántica de alto contraste sin perder el affordance.
- Focus de teclado/Voice Control, hit regions, Bold Text, Increase Contrast, landscape, iPad Split View y orientación portrait.
- Fallback para sistemas previos al API visual de iOS 26: misma geometría y jerarquía, material equivalente del sistema y cero duplicación de layout.

## Matriz de validación

### Geometría y safe area

- iPhone pequeño, estándar y Pro Max; iOS 18 y iOS 26; portrait y landscape.
- Dynamic Island/notch, home indicator, teclado y sheets con detents.
- El centro del botón coincide con el centro del ancho útil, no con un frame accidental.
- El círculo mide 64 pt en reposo y conserva un área accesible válida al pulsar.
- Ningún contenido queda bajo el footer; no aparecen espacios finales artificiales.

### Navegación funcional

- Cada tab cambia de sección en un toque y conserva su navegación interna.
- Scan funciona desde cada sección permitida y no altera la selección de tab.
- Presentar/cerrar Capture vuelve al estado previo sin overlay residual ni editor superpuesto.
- Back/Close/Cancel/Save se comportan como acciones de navegación del sistema.

### Visual y accesibilidad

- Light/dark, Increase Contrast, Reduce Transparency, Reduce Motion, Bold Text y AX5.
- VoiceOver recorre tabs y Scan en un orden estable; no repite etiquetas ni anuncia el botón como destino de navegación.
- Screenshots de referencia para Home, Gallery, Vault, Settings, Capture y Editor antes/después.

### Rendimiento

- Medir scroll y transición de tab con y sin glass en dispositivo de referencia.
- Evitar blur y morphing en superficies de contenido repetidas.
- Verificar que el footer no fuerce recomposición excesiva ni use `GeometryReader` global para posicionar acciones.

## Criterios de aceptación para implementar después

Los criterios 1, 2, 3, 4 y 7 quedan cubiertos para el shell principal por la implementación y los tests descritos arriba. Los criterios 5 y 6 requieren la iteración transversal de superficies y accesibilidad.

1. El botón central ya no aparece pequeño, desplazado ni separado de su capa funcional en ningún tamaño soportado.
2. Existe una única reserva de safe area para la navegación inferior y una única fuente de verdad para la acción Scan.
3. Las cuatro tabs permanecen visibles y navegables; Scan no se presenta como tab.
4. iPhone e iPad adoptan la variante apropiada de navegación sin duplicar overlays.
5. El contenido de Home y los últimos elementos de listas quedan completamente accesibles.
6. La apariencia light/dark, accesibilidad y fallback pre-iOS 26 mantienen la misma jerarquía.
7. Los tests UI cubren identificación, selección, presentación de Capture, retorno y geometría del footer.

## Riesgos y límites

- Liquid Glass es una capa de navegación, no un tratamiento global de toda la app; extenderlo a cards degradaría legibilidad y podría afectar rendimiento.
- El mínimo actual del proyecto es iOS 18 aunque existe trabajo específico para iOS 26; la decisión de elevar deployment target requiere una tarea de compatibilidad y release independiente.
- El render visual sirve para dirección y proporción, no sustituye un snapshot real de SwiftUI ni garantiza textos exactos de la generación raster.
- No se debe corregir el botón central de forma aislada antes de aprobar el contrato de shell, porque volvería a introducir dos fuentes de posicionamiento.

## Validación realizada

- Build Debug del proyecto `Shield.xcodeproj`: correcto.
- Test UI de centrado y tamaño de Scan: correcto.
- Tests UI de navegación de tabs, cierre de Settings y presentación/cierre de Capture: correctos.
- La validación se ejecutó con `SYMROOT`/`OBJROOT` temporales porque la configuración global del workspace apunta a productos de otro proyecto; no se modificó esa configuración persistente.

## Referencias

- Apple HIG — Tab bars: navegación top-level, etiquetas, tab bar visible y adaptación a sidebar.
- Apple HIG — Materials / Liquid Glass: glass para la capa funcional de navegación, no para llenar el content layer.
- Apple HIG — Toolbars: acciones de contexto, Back/Close estándar y agrupación deliberada.
- Apple SwiftUI — `tabBarMinimizeBehavior`, `TabViewBottomAccessoryPlacement`, `sidebarAdaptable`, `glassEffect` y `backgroundExtensionEffect`.
