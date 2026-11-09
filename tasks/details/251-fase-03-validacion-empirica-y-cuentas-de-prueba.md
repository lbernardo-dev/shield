# 251-fase-03-validacion-empirica-y-cuentas-de-prueba

- Number: 251
- Slug: fase-03-validacion-empirica-y-cuentas-de-prueba

## Notes

## Objetivo

Completar las validaciones que fase 02 no podía fundamentar sin personas, hardware o cuentas aisladas. No reinterpretar pruebas de simulador como evidencia de uso o sincronización real.

## Paquetes de trabajo

1. **AUD-011 / AUD-016 / AUD-018 — accesibilidad manual:** VoiceOver y Voice Control para crear, seleccionar, redimensionar, mover, deshacer y exportar una máscara; AX5 en iPhone e iPad; documentar etiquetas, foco y hit targets.
2. **AUD-012 — borrado:** con fixture sintético y CloudKit test-only, probar cancelar, confirmar, falta de red, cola remota y reintento. Cancelar debe dejar assets y estado local/remoto intactos.
3. **AUD-014 — cuota:** dos dispositivos en una misma cuenta de prueba, otra cuenta y ciclos offline/online; confirmar que el entero agregado es lo único sincronizado.
4. **AUD-015 / AUD-016 / AUD-017 — sesiones:** 6–8 personas, nuevas y recurrentes, y tecnología asistiva habitual si hay reclutamiento. Usar exactamente el guion y reglas de `15_GUIA_ESTUDIO_USABILIDAD.md`; cero documentos o PII reales.
5. **AUD-021 — preferencias estacionales:** consentimiento, reversión a tema base, persistencia, audio apagado y Reduce Motion con fecha/zona horaria controladas.
6. **Release:** el baseline ASC del 8 nov 2026 es build 1162026102502; el local permanece en 1162026102501. No cambiar número, metadata ni estado de ASC en esta tarea.

## Criterios de salida

- Resultados separados por entorno (simulador, hardware, cuenta de prueba, participantes); fallos con reproducción y estado antes/después.
- Confirmación destructiva no ejecutada sobre datos reales; sincronización acotada a fixtures.
- Hallazgos de sesiones codificados y anónimos, limitaciones de muestra indicadas y recomendaciones ligadas a reglas previas.
- ROADMAP actualizado con lo observado y lo aún desconocido; sin afirmaciones de certificación ni garantía OCR.

## Límites y seguridad

- No usar Cuenta de Apple, Keychain/KVS, CloudKit o RevenueCat personales para pruebas destructivas.
- No resetear Keychain/KVS compartidos. No editar App Store Connect ni publicar.
- Si una prueba requiere compartir un documento externo o datos de cuenta, detener y sustituir por fixture sintético.

Guía de ejecución: `AUDITORIA_PRODUCTO_UX/2026-11-08_1114/17_TRASPASO_FASE_03.md` y `FASE_02_HANDOFF.json`.

