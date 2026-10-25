# 228-dashboard-widgets-in-app-quick-access

- Number: 228
- Slug: dashboard-widgets-in-app-quick-access

## Notes

## Objetivo

Hacer visibles y utilizables desde Inicio los destinos habituales de MaskID y completar la superficie informativa de WidgetKit con datos agregados precisos, vacíos veraces, protección de privacidad y traducción al español e inglés.

## Hallazgos

- Inicio ya tenía estadísticas locales, un grupo plegable con modos, lote, Bóveda y nube, y tabs para Biblioteca, Estilos y Bóveda. Faltaba una puerta de entrada visible para ir a esos destinos sin recorrer el dashboard o desplegar herramientas.
- WidgetKit ya ofrecía acciones, métricas y controles del sistema, pero llamaba “seguridad” a la proporción de documentos con redacciones y mostraba 100% cuando no había documentos. El texto “No exposed documents” interpretaba la biblioteca vacía como si se hubiera comprobado la exposición.
- Los contadores de marcas de agua no coincidían: Inicio contaba cualquier objeto watermark y el snapshot del widget solo uno con texto no vacío.
- El snapshot compartido por App Group contenía solo agregados; esa frontera de privacidad se conserva. Se mantiene lectura del campo antiguo `protectedDocuments` para que el widget pueda actualizarse desde datos guardados por versiones anteriores.

## Implementación

- Añadir a Inicio accesos de un toque para añadir un documento, abrir Todos los documentos, entrar en Estilos y abrir Bóveda. Un acceso adicional despliega y desplaza a Modos, lote y nube. La cuadrícula se reduce a una columna para Dynamic Type de accesibilidad.
- Alinear la definición del contador de marca de agua entre Biblioteca y snapshot.
- Renombrar el dato del widget a `documentsWithRedactions`, retirar el score derivado y los timestamps no usados, limitar los contadores a subconjuntos del total y migrar snapshots antiguos sin conservar el score.
- Rediseñar el widget informativo pequeño/mediano/grande y Lock Screen con conteos descriptivos, estado vacío explícito, actualización en el dispositivo y retorno al Inicio de Biblioteca. Mantener las acciones rápidas existentes y retirar estados absolutos no respaldados.
- Completar traducciones ES/EN de los textos nuevos de Home y de WidgetKit.
- Añadir pruebas de persistencia/migración del snapshot y de accesibilidad, tamaño y localización de los accesos de Inicio.

## Aceptación

- Cada acceso lleva a la superficie o flujo que indica y mantiene los requisitos de autenticación existentes.
- Los títulos y pistas son localizables, todos los objetivos táctiles de Inicio miden al menos 44 pt y el contenido admite anchos compactos, regulares y Dynamic Type de accesibilidad.
- Widgets muestran solamente agregados; ninguna cifra se presenta como una evaluación general de seguridad; el caso vacío muestra 0 o una invitación veraz, nunca 100% o documentos expuestos.
- Contadores de Biblioteca y widget coinciden en la semántica de redacciones, Bóveda y marcas de agua.
- Al final se compila, se instalan builds explícitas y se prueban los flujos en la matriz disponible según `AGENTS.md`.

## Progreso

- Plan incorporado a la Fase 2 de `tasks/details/226-refactor-ui-ux-multidispositivo.md` y a la propuesta en `Docs/PROPUESTA_VALOR_PRODUCTO_2026-10-20.md`.
- Implementación completada: Inicio incluye accesos localizados, widgets muestran métricas agregadas verificables y el estado vacío no afirma una seguridad que no se haya medido.
- `git diff --check` pasó y los catálogos ES/EN compilaron al construir los targets de app y widget.
- iPhone 18 Pro (UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`, iOS 27.0): build instalada; 5 pruebas de snapshot y la prueba UI de accesos rápidos/localización pasaron.
- iPhone Duo (UDID `BF5C28D6-2B6D-46FC-82E8-9A248F5C0186`, iOS 27.1): build instalada; las mismas 6 pruebas pasaron.
- iPad Pro 13-inch (M5) (UDID `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`, iOS 27.0): build instalada; las 5 pruebas de snapshot pasaron. Device Hub confirmó que el acceso rápido expande la sección y expone Modos, Lotes y nube. El runner UI de XCTest quedó bloqueado al cerrar la sesión (`Blocking finish to clean up test session`) y no generó un resultado completo; no se cuenta como pasada automatizada en iPad.
- Xcode emitió warnings no bloqueantes `invalidDigitCount` para los builds del runtime 27.0/27.1. El test UI en iPad había mostrado una advertencia SwiftUI de actualización de estado; el desplazamiento ahora se difiere un ciclo del actor principal. El intento posterior no dejó un resultado de XCTest válido para confirmar formalmente esa advertencia.
- No existe target watchOS en el proyecto. Tampoco hay flujo/modelo de sesiones con perfiles compartidos, y el build de simulador desactiva CloudKit por falta de entitlements; esas dos validaciones no aplican a las funcionalidades actuales.

