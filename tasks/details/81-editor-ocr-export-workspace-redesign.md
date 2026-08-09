# 81-editor-ocr-export-workspace-redesign

- Number: 81
- Slug: editor-ocr-export-workspace-redesign

## Notes

## Objetivo

Transformar el editor en un workspace donde lienzo, herramienta activa y siguiente acción sean inequívocos.

## Trabajo

- Unificar el chrome superior y reducir banners simultáneos.
- Mantener Cancelar/Guardar/Exportar persistentes y dar prioridad visual coherente.
- Toolbar contextual: herramienta activa + inspector; opciones no relacionadas permanecen ocultas.
- Simplificar paginación/zoom y evitar tres filas permanentes en iPhone.
- OCR con resumen primero, lista después y CTA persistente; Exportar con preview proporcionada y estados claros.
- Adaptar detents al contenido y preservar el contexto al cerrar sheets.

## Aceptación

- La herramienta activa se identifica sin depender sólo de color.
- Ningún control esencial mide menos de 44×44 pt.
- Sin truncamiento de banners o acciones en ES/EN y AX5.
- Undo/redo, OCR, watermark, ajustes, guardado y exportación pasan regresión funcional y visual.
