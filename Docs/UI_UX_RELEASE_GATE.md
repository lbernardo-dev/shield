# UI/UX release gate

Este gate convierte la auditoría visual y de accesibilidad de MaskID en un control repetible antes de cada release.

## Ejecución automática

```sh
scripts/ui_ux_release_gate.sh all
```

Modos disponibles:

- `test`: build estricto y auditorías XCUITest en un iPhone y un iPad.
- `capture`: genera la matriz visual en `build/ui-ux-release-gate/screenshots`.
- `all`: ejecuta ambos.

Si hay varios simuladores, fija los destinos con `UI_IPHONE_ID` y `UI_IPAD_ID`. La matriz cubre ES/EN, claro/oscuro, iPhone/iPad, navegación persistente y AX5 con Reduce Motion, Reduce Transparency e Increase Contrast.

## Revisión visual obligatoria

Comparar cada captura con el release anterior y bloquear el envío ante:

- headers, botón Atrás/Cerrar o CTA fuera de pantalla;
- contenido tapado por tab bars, safe areas, sheets o teclado;
- truncado que elimine significado, textos sobre bordes o controles menores de 44 pt;
- huecos artificiales, grids rotos o estiramiento improductivo;
- selección indicada solo por color;
- contraste insuficiente en claro, oscuro o Increase Contrast;
- animación esencial que no tenga alternativa con Reduce Motion.

Revisar además empty/loading/error/success, inicio y final de cada scroll, teclado abierto, rotación, Split View 1/2 y 1/3 y Stage Manager. Estas variantes requieren inspección manual cuando el simulador no pueda reproducir el estado externo.

## Matriz física — firma requerida

Antes de subir una versión a App Store Connect, completar en al menos un iPhone y un iPad reales:

| Área | Verificación | Resultado / firma |
|---|---|---|
| Cámara | permiso inicial, denegado, Ajustes, escaneo multipágina y cancelación | |
| Photos / Files | importar, cancelar, error, reintentar y archivo temporal | |
| Biometría / PIN | Face ID/Touch ID, fallback, bloqueo al background y reentrada | |
| Editor | gestos, zoom, teclado/trackpad, undo/redo, OCR y exportación | |
| Accesibilidad | VoiceOver, Voice Control, Switch Control, AX5 y contraste | |
| Movimiento | Reduce Motion y Reduce Transparency sin loops ni pérdida de contexto | |
| Feedback | haptics adecuados y sin repetición molesta | |
| Compra | productos, compra, cancelación, error y restauración en sandbox | |
| Multitarea | portrait/landscape, Split View 1/2 y 1/3, Stage Manager | |

Release owner: ____________________  Fecha: __________  Build: __________

La firma física es un requisito de publicación; el script no la sustituye.
