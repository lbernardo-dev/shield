# 84-ipad-adaptive-layouts

- Number: 84
- Slug: ipad-adaptive-layouts

## Notes

## Objetivo

Pasar de “sidebar + iPhone ancho” a una experiencia iPad y multitarea diseñada por tarea.

## Trabajo

- Dashboard en columnas y anchura legible; navegación lateral con selección y teclado.
- Galería con grid adaptativo real; Editor con lienzo e inspector contextual.
- Captura/revisión con preview y controles laterales cuando el ancho lo permita.
- Bóveda y Ajustes con list/detail cuando aporte valor.
- Soportar portrait, landscape, Split View y Stage Manager sin depender de `UIScreen`.

## Aceptación

- Sin solapes, stretching improductivo ni columnas vacías en anchos compact/regular.
- El documento del Editor mantiene escala útil y controles legibles.
- Navegación completa con teclado/trackpad y foco visible.
- Snapshots y pruebas UI cubren al menos ancho completo, 1/2 y 1/3.
