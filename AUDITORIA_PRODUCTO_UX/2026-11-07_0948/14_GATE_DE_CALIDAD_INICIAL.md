# Gate de calidad inicial

## Riesgos observados frente a incidencias

- **P0 pérdida/corrupción:** ninguna incidencia reproducida. Integridad semántica de exportación PDF y preservación durante fallo siguen pendientes.
- **P1 navegación sin salida/tarea bloqueada:** ninguno demostrado. Back/cancel no ejecutados.
- **P2:** default de sonido vs copy, control de tema base en HEAD, falta E2E accesible, disclosure KVS.
- **P3:** descubribilidad de categorías/herramientas, copy interno de analítica, público equipos ambiguo y baseline de release inconsistente.

## Datos y estado

No se modificó código/datos de usuario. Los tests no se ejecutaron y no se verificó una migración. Antes de autorizar fase de corrección, disponer de fixtures sintéticos, copia recuperable del proyecto, prueba de exportación que inspeccione contenido subyacente y caso de sincronización multi-dispositivo.

## Pruebas que faltan

- Tarea primaria en iPhone 18 Pro explícito.
- iPad representativo; Duo si disponible; Watch no aplica al no existir target.
- Importar/editar/exportar, cancelación/error y persistencia.
- Free/Pro/restore con entorno de sandbox, sin compra real.
- VoiceOver/Dynamic Type AX5, Reduce Motion, contraste, ES/EN y texto largo.
- Temas, preferencia Base Free y audio en estado limpio/evento.
- Offline, KVS y cambios de cuenta.
- Smoke de Share Extension y widget.

## Bloqueo para siguiente fase

Antes de marcar cualquier comportamiento como corregido, restablecer CoreSimulator y cumplir el inventario/ocupación obligatorio de dispositivos. Priorizar confirmar si el WIP task 247 se conserva, pero no sobrescribirlo; es trabajo local preexistente. ASC requiere recuperar autenticación para reconciliar versiones. No publicar cambios ni tocar metadata externa. No existe gate P0/P1 que impida planificar, pero las tareas de implementación y release deben esperar evidencia de baseline runtime.

