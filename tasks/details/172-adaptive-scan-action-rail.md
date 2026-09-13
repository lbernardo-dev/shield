# 172-adaptive-scan-action-rail

- Number: 172
- Slug: adaptive-scan-action-rail

## Resultado

Implementada la propuesta 2: la acción Scan queda separada de la navegación y se adapta a un iPhone convencional o a una navegación lateral de ancho regular, sin una quinta tab ni coordenadas manuales.

## Implementación

- En iOS 26 se usa `TabView` nativo con `tabViewBottomAccessory` para el iPhone compacto.
- El accesorio usa `glassProminent`, `controlSize(.large)`, un área mínima de interacción y una variante icon-only cuando el sistema lo compacta.
- En ancho regular se usa `sidebarAdaptable` y `tabViewSidebarBottomBar`; `ViewThatFits` conserva el texto cuando hay espacio y reduce la acción al símbolo cuando el rail es estrecho.
- Se eliminó la dependencia del overlay con `GeometryReader` y de offsets fijos para el control de captura.
- En versiones anteriores a iOS 26 se mantiene un fallback con material del sistema y la misma jerarquía funcional.
- Se conservaron identificadores y anuncios de accesibilidad para VoiceOver y UI tests: `tab.capture` y `sidebar.capture`.

## Verificación

- Build Debug para `generic/platform=iOS Simulator` con el SDK iOS 27: `BUILD SUCCEEDED`.
- `testApplicationReachesForeground`: `TEST SUCCEEDED`.
- El test geométrico de `tab.capture` se ejecutó, pero el simulador tenía un estado residual de importación compartida que mostraba el alerta `Could not access the shared secure container` por encima de la app. El elemento existía en el árbol de accesibilidad, pero no era hittable por quedar cubierto por ese modal. No se modificó la lógica de producción para ocultar ese problema ambiental.

## Límites conocidos

- La variante iPhone Duo se cubre mediante los componentes adaptativos estándar de SwiftUI (`sidebarAdaptable` y `tabViewSidebarBottomBar`); no se introducen offsets específicos de bisagra ni un simulador físico Duo en esta validación.
- El despliegue mínimo continúa siendo iOS 18; las APIs iOS 26 están protegidas con `#available`.
