# 78-design-system-clean-depth-motion

- Number: 78
- Slug: design-system-clean-depth-motion

## Notes

## Objetivo

Convertir `ShieldTheme` y los componentes en un sistema visual compacto, adaptable y coherente.

## Trabajo

- Tokens semánticos de surface, elevation, stroke, selection, success/warning/error y scrim para claro/oscuro.
- Escala tipográfica basada en estilos del sistema; eliminar microtexto no esencial y alturas incompatibles con AX.
- Componentes: primary/secondary/destructive button, icon button, chip, card, row, section header, empty/error/loading state y sticky footer.
- Tokens de motion (rápido/normal/contextual) y feedback sensorial declarativo; retirar haptic UIKit del estilo base.
- Reglas de padding interno de botones y cards, foco, disabled/pressed/loading y contraste.

## Aceptación

- Catálogo de componentes verificable en claro/oscuro y XS/AX5.
- Ninguna acción comunica estado sólo por color.
- Reduce Motion/Transparency e Increase Contrast alteran correctamente los componentes.
- Las superficies posteriores consumen tokens y no recrean estilos locales equivalentes.
