# 77-ui-shell-navigation-safeareas-p0

- Number: 77
- Slug: ui-shell-navigation-safeareas-p0

## Notes

## Objetivo

Establecer un contrato único de shell antes de rediseñar superficies.

## Trabajo

- Reemplazar el grid de Galería basado en alturas calculadas por `LazyVGrid` adaptable y eliminar solapes en iPad.
- Crear chrome persistente reutilizable o usar toolbars nativas para Volver/Cerrar/Cancelar/Guardar.
- Sacar el cierre de Ajustes y el back del paywall onboarding fuera del contenido desplazable.
- Eliminar compensaciones inferiores 80/90/100/110 y dejar que `safeAreaInset`/toolbars reserven el espacio.
- Unificar sheets con detents adecuados al contenido y CTA mediante `safeAreaInset(edge: .bottom)` cuando corresponda.
- Sustituir `NavigationView` de Lotes por `NavigationStack`.

## Aceptación

- Galería sin solapes en iPhone/iPad, portrait/landscape y Split View.
- Acciones de navegación visibles en top, middle y bottom del scroll.
- Margen final 16–24 pt más safe area; sin huecos de compensación.
- Pruebas UI verifican top/bottom de Inicio, Galería, Bóveda, Ajustes y destinos largos.
