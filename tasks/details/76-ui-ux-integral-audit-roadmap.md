# 76-ui-ux-integral-audit-roadmap

- Number: 76
- Slug: ui-ux-integral-audit-roadmap

## Notes

## Resultado ejecutivo

La app tiene una identidad reconocible y una base funcional sólida, pero la UI se ha construido pantalla a pantalla y no desde un contrato común de layout. El resultado es una experiencia inconsistente: paddings inferiores manuales que duplican la safe area, headers y acciones con comportamientos distintos, superficies demasiado densas en iPhone, superficies excesivamente vacías en iPad y hojas con alturas fijadas por porcentaje.

La prioridad no es añadir decoración. Es estabilizar primero geometría, navegación y jerarquía; consolidar después el sistema visual; y finalmente rediseñar cada flujo con menos carga cognitiva, más estructura y microinteracciones semánticas.

## Evidencia y alcance

- Revisión estática de las 32 fuentes Swift de la app y de los componentes compartidos.
- Build Debug estricto correcto sobre el estado actual del workspace.
- Inspección visual determinista en español y modo oscuro:
  - iPhone 17 Pro Max, iOS 26.5: Inicio, Captura, Galería, Editor, OCR, Exportación, Lotes, Bóveda, Paywall, Ajustes y onboarding.
  - iPad Pro 13 pulgadas, iOS 26.5: Inicio, Galería, Editor, Ajustes y Bóveda.
- Revisión del shell compacto/regular, safe areas, navegación, ScrollView, sheets, Dynamic Type, estados y motion.
- Esta auditoría no sustituye la validación final en iPhone pequeño, iOS 18, modo claro, tamaños de texto de accesibilidad ni dispositivo físico; esas matrices forman parte del gate 85.

## Hallazgos priorizados

### P0 — bloqueos estructurales

1. **Galería rota en iPad.** `StyleGalleryView` calcula manualmente la altura de cada sección con `GeometryReader`, `contentWidth` y `sectionHeight`. En iPad las secciones se solapan y los encabezados quedan encima de tarjetas. Debe sustituirse por un grid adaptable cuyo contenedor determine su altura.
2. **Contrato de navegación inconsistente.** En Ajustes raíz el título/cierre viven dentro del `ScrollView`; en destinos el botón Atrás está fijo pero Cerrar forma parte del contenido desplazable; el paywall del onboarding también incluye Atrás dentro del scroll. Volver, cerrar, cancelar y confirmar deben pertenecer siempre a chrome persistente o a toolbars nativas.
3. **Espacio inferior duplicado.** El shell ya reserva la barra compacta con `safeAreaInset`, pero Inicio añade 110 pt, Galería 100 pt y Bóveda 100 pt. Ajustes, donde la barra se oculta, añade 110 pt; los destinos añaden un `Spacer` de 80 pt. Esto genera los huecos al final indicados por el usuario.
4. **Adaptación iPad incompleta.** El modo regular añade una sidebar de 92 pt, pero varias pantallas siguen siendo un layout de teléfono estirado. Galería se rompe; Editor sobredimensiona el documento y mantiene controles diminutos; Bóveda deja la mayor parte de la ventana sin función.

### P1 — problemas principales de UX

5. **Inicio tiene demasiadas prioridades simultáneas.** Hero, plan, privacidad, dos CTAs, capacidad, búsqueda, categorías, modos, recientes, bóveda y nube compiten en una sola columna. La primera pantalla comunica muchas cosas antes de permitir trabajar.
6. **Editor con carga cognitiva alta.** Acumula top bar, metadatos, banner de sugerencias, banner de propagación, paginación, lienzo, zoom, modos, estilos y toolbar. Hay controles de 24–32 pt visuales, labels pequeños y demasiados acentos simultáneos. La herramienta activa y el siguiente paso no dominan la jerarquía.
7. **Captura duplica decisiones.** Tipo de documento y estado de guía aparecen en la tarjeta principal y de nuevo en una tarjeta completa. Esto alarga el flujo antes de escanear y empuja Fotos/Archivos/Nube muy abajo.
8. **Sheets sobredimensionadas.** OCR, Exportar y Marca de agua usan fracciones fijas de 80/82/52 %, independientemente del contenido y del dispositivo. Otras hojas mezclan `.medium`, `.large` y alturas fijas. Esto produce huecos, acciones alejadas y comportamiento inconsistente.
9. **Estados vacíos y de error desaprovechan el espacio.** Bóveda y Lotes dejan grandes áreas negras sin contexto ni acciones secundarias. El paywall mantiene un CTA visualmente primario cuando no hay productos aunque esté deshabilitado, reduciendo la claridad del estado.
10. **Jerarquía visual plana o ruidosa según la pantalla.** Predominan rectángulos azul oscuro similares; en otros puntos se usan cian, verde, naranja, violeta y amarillo a la vez. Falta una regla estable para surface/elevation/selection/status.
11. **Copy y labels demasiado largos.** Subtítulos explicativos se repiten, varias labels usan mayúsculas y tracking, y textos españoles se truncan en Editor/Lotes. Las acciones deberían usar verbos breves y la ayuda pasar a estados, hints o disclosure progresivo.
12. **Paywall y onboarding no son completamente adaptativos al tema.** Varias superficies usan tokens oscuros estáticos (`textPrimary`, `surface2`) incluso cuando se fuerza el esquema preferido. Hay efectos repetitivos que no siempre consultan Reduce Motion.

### P2 — calidad transversal

13. **Motion sin sistema común.** Conviven springs, ease, symbol effects repetitivos, haptics declarativos y `UIImpactFeedbackGenerator`. Deben existir tokens de duración/curva y reglas por intención: selección, inserción, éxito, error y navegación.
14. **Dynamic Type en riesgo.** Aunque `shieldFont` escala, muchas filas mantienen alturas fijas de 28–40 pt y grids rígidos. Escalar el texto dentro de contenedores fijos puede recortar o solapar.
15. **Accesibilidad incompleta como experiencia.** Hay buena cobertura de labels/hit regions, pero el gate actual no cubre navegación completa con VoiceOver, foco tras sheets, Reduce Transparency, Increase Contrast, tamaños AX ni alternativas de teclado/trackpad por superficie.
16. **APIs y patrones heredados.** Lotes sigue usando `NavigationView`; hay temporización con `DispatchQueue.main.asyncAfter` y haptics UIKit en vistas SwiftUI. Deben modernizarse al intervenir cada flujo.

## Principios del rediseño

1. **Clean con jerarquía, no vacío.** Cada pantalla tendrá una acción primaria, una secundaria clara y contenido agrupado por tarea.
2. **Chrome persistente.** Volver, cerrar, cancelar, guardar y confirmar nunca dependerán de la posición del scroll.
3. **Safe area como fuente única.** `safeAreaInset`, toolbar o footer persistente reservarán el espacio; no habrá compensaciones mágicas de 80–110 pt.
4. **Profundidad semántica.** Máximo tres niveles de superficie por pantalla; el color de acento indica selección/acción y los colores semánticos sólo estado.
5. **Progressive disclosure.** Opciones avanzadas, ayuda y metadatos aparecen cuando son relevantes, no todas a la vez.
6. **Responsive por intención.** iPad no será un iPhone ancho: dashboard en columnas, editor con inspector, grids adaptativos y anchuras legibles.
7. **Motion discreto.** Microinteracciones de 120–320 ms, haptic sólo cuando confirma una decisión, y alternativa sin desplazamiento con Reduce Motion.
8. **Contenido adaptable.** Labels cortas, system text styles, filas que crecen y ninguna información importante truncada en ES/EN.

## Roadmap de ejecución

| Orden | Tarea | Resultado | Prioridad |
|---|---|---|---|
| 1 | 77 | Shell, navegación, safe areas, detents y Galería iPad estabilizados | P0 |
| 2 | 78 | Sistema visual y de motion compartido | P0/P1 |
| 3 | 79 | Inicio/Biblioteca con jerarquía y densidad corregidas | P1 |
| 4 | 80 | Captura/Importación/Revisión más directas | P1 |
| 5 | 81 | Editor/OCR/Exportación convertidos en workspace contextual | P1 |
| 6 | 82 | Galería y Bóveda perfeccionadas | P1 |
| 7 | 83 | Ajustes, Paywall y onboarding simplificados | P1 |
| 8 | 84 | Adaptación iPad y multitarea por superficie | P1 |
| 9 | 85 | Gate final visual, accesible y localizado | P0 release gate |

Las tareas de superficies pueden solaparse únicamente después de cerrar los contratos 77–78. La tarea 85 no debe empezar como “pulido final”: sus pruebas deben añadirse incrementalmente en cada fase y ejecutarse de forma completa al cierre.

## Definición global de terminado

- Ninguna pantalla requiere volver al inicio del scroll para volver, cerrar, cancelar, guardar o confirmar.
- Ningún root añade padding inferior fijo para compensar una barra ya insertada por safe area.
- Al llegar al final de cualquier scroll sólo queda el margen de diseño (16–24 pt) más la safe area real.
- Sin solapes, recortes ni contenido inaccesible en iPhone SE/16/17 Pro Max e iPad, portrait/landscape y Split View.
- ES y EN pasan sin truncar títulos, labels de acciones ni valores importantes.
- Dynamic Type pasa de XS a AX5; los targets interactivos son de al menos 44×44 pt.
- Reduce Motion elimina desplazamientos/repeticiones; Reduce Transparency e Increase Contrast mantienen legibilidad.
- Estados loading/empty/error/offline/disabled/success tienen estructura, copy y acción coherentes.
- Capturas visuales de referencia y pruebas XCUITest cubren roots, destinos largos, top/bottom de scroll y sheets.
- Build estricto, tests unitarios/UI, Accessibility Inspector y recorrido físico quedan verdes antes de release.

## Validación de esta auditoría

- `make build SIM_NAME="iPhone 16 Pro Max"` con `AGENT_NAME=CODEX`: correcto; el resolver utilizó iPhone 17 Pro Max iOS 26.5.
- Se generaron 16 capturas diagnósticas nuevas fuera del repositorio.
- No se modificó código de producto durante esta tarea.
