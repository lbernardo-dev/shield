# Plan de acción para fase 02

Este plan no autoriza cambios. Las estimaciones son relativas, no mediciones. La fase siguiente debe confirmar el baseline y gestionar cada ID.

| ID | Severidad | Ruta / pantalla | Problema y tarea | Cambio mínimo propuesto | Aceptación verificable | Riesgo / dependencias |
|---|---|---|---|---|---|---|
| AUD-001 | P2 | Theme / audio | THEME-002; evitar sonido inesperado durante uso | Hacer audio estacional opt-in y alinear strings | Instalación limpia silenciosa; sólo suena tras acción expresa; persistencia probada | Bajo; migrar default sin invalidar preferencia existente |
| AUD-002 | P2 | Settings / privacy facts | PRIV-001; entender datos que cruzan dispositivos | Documentar contador KVS, finalidad y condiciones | Documento coincide con prueba de configuración/sync; no menciona contenido inexistente | Bajo-medio; confirmar comportamiento de iCloud |
| AUD-003 | P2 | UI tests, tarea central | ACC-001; completar trabajo con accesibilidad | Añadir E2E VoiceOver/Dynamic Type y guía manual | Fixture completado/exportado con AX5; acciones nombradas y foco utilizable | Medio; fixture seguro, destino Xcode disponible |
| AUD-004 | P2 | Home / Theme | THEME-001; controlar apariencia Free | Ofrecer Base gratuita, temporalidad opt-in y rechazo reversible | Free elige Base; persiste reinicio y fin de evento; Premium no pierde preferencia | Medio; revisar WIP task 247, migración/pricing. Testear antes de cambiar |
| AUD-005 | P3 | Home compacto | UX-001; descubrir categoría/CTA | Probar con usuarios; añadir labels si hacen falta | Usuarios objetivo identifican acción sin ensayo/error; no regresión de layout | Bajo-medio; no duplicar CTA |
| AUD-006 | P3 | Editor | UX-002; localizar herramienta | Probar banda de siete iconos; etiquetar/reagrupar si evidencia lo exige | Cada tarea encuentra máscara y puede recorrer controles con tecnologías asistivas | Medio; conservar todas las acciones |
| AUD-007 | P2 | Privacy policy, metadata y analítica | DOC-001; entender y controlar uso de Analytics | Alinear las fuentes locales con Analytics apagado y control en Ajustes; no añadir prompt inicial | Política EN/ES, metadata y plan describen el flujo real; onboarding no muestra consent sheet; test forced sigue disponible solo para QA | Bajo; la publicación externa se confirma en una fase autorizada |
| AUD-008 | P3 | Product positioning | PROD-001; entender si colaboración existe | Distinguir personas/equipos actuales y roadmap | Copy local no implica colaboración funcional no presente | Bajo; decisión de producto |
| AUD-009 | P3 | Baseline release | OPS-001; identificar versión publicada | Reconciliar docs locales tras acceso ASC/CI | Versión/build/store status registrados con fuente y fecha | Bajo; auth ASC, no modificar ficha |
| AUD-010 | P2 | SecureQuotaStore / privacidad | PRIV-002; clasificar el dato de uso en iCloud KVS | Decisión del usuario: conservar solo el contador agregado en KVS y el disclosure actualizado | Confirmar mismo dato entre dispositivos con la misma cuenta, cambio de cuenta y estado offline; no sincronizar contenido documental | Medio; la política está decidida, falta validar el comportamiento multi-dispositivo |

## Orden sugerido

1. Reproducir/confirmar AUD-001 y AUD-004 con simulador limpio; registrar versión y flags.
2. Confirmar alcance de KVS antes de editar disclosure.
3. Restaurar entorno de tests y ejecutar E2E de accesibilidad y tareas principales.
4. Validar Home/editor con usuarios antes de cambiar jerarquía.
5. Revisar/actualizar docs sólo después de comprobar estado ASC vigente.

No hay P0/P1; por ello no existe camino de bloqueo crítico. Para cambios P2, añadir pruebas de preferencia, modo Free/Premium, audio/evento y accesibilidad antes de implementar. Preservar OCR, máscaras, verificador, Vault y exportación. No retirar datos o funciones. Reversibilidad recomendada mediante preferencia migrable y rollout controlado.

