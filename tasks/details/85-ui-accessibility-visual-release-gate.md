# 85-ui-accessibility-visual-release-gate

- Number: 85
- Slug: ui-accessibility-visual-release-gate

## Notes

## Objetivo

Convertir la calidad UI/UX en un gate de release repetible.

## Trabajo

- Matriz iOS 18/26, iPhone pequeño/estándar/grande, iPad y multitarea.
- Capturas de referencia claro/oscuro, ES/EN, empty/loading/error/success y top/bottom de scroll.
- XCUITest para chrome persistente, contenido no tapado, sheets, focus restoration y navegación.
- VoiceOver, Voice Control, Switch Control, teclado, Dynamic Type XS–AX5, Reduce Motion/Transparency e Increase Contrast.
- Recorrido físico de cámara, Photos, Files, biometría, teclado, haptics y compra/restauración sandbox.

## Aceptación

- Cero solapes, recortes, acciones inaccesibles o regresiones visuales críticas.
- Accessibility Inspector sin errores no justificados.
- Build estricto y suites unit/UI verdes.
- Checklist físico firmado antes de enviar una nueva versión a App Store Connect.
