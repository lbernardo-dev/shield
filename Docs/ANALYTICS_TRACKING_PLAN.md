# MaskID — plan de analítica y consentimiento

Estado: implementado localmente el 11 de septiembre de 2026.

## Principio de consentimiento

Firebase Analytics es opcional y está desactivada por defecto. La aplicación no envía eventos de producto antes de una autorización expresa. La decisión se guarda en `UserDefaults` con la clave `shield.analyticsConsent` y se puede cambiar en `Ajustes > Privacidad`.

La elección inicial se registra con `shield.analyticsConsentPromptAnswered`. Tanto permitir como rechazar cierra el aviso; rechazar mantiene Analytics desactivada. El modo de pruebas puede forzar la pantalla con `-show-analytics-consent`, sin activar la analítica.

Firebase Crashlytics permanece separado para diagnósticos de estabilidad. La telemetría local limitada y MetricKit no se envían a Firebase Analytics.

## Eventos permitidos

Los eventos proceden de la lista existente de `AppState.trackEvent`. Todos los nombres y propiedades pasan por saneamiento y allowlist antes de cualquier envío.

| Evento | Decisión que informa | Propiedades permitidas |
|---|---|---|
| `onboarding_completed` | Dónde se abandona o completa la activación | `last_step` |
| `import_completed` / `import_failed` | Fiabilidad de importación | `source`, `format`, `pages`, `error_type` |
| `redaction_applied` | Uso de protección automática/manual | `source`, `kind`, `count`, `pages` |
| `export_success` / `export_failed` | Calidad del flujo de exportación | `format`, `pages`, `error_type` |
| `purchase_success` / `purchase_failed` | Salud del embudo de compra | `product_id`, `error_type` |
| `vault_unlocked` / `vault_locked` | Uso de la Bóveda | `method` |
| `entitlement_snapshot` / `subscription_state_changed` | Separar Free, trial, Premium, lifetime y cancelación de renovación | `tier`, `subscription_state`, `product_id` |
| `feature_gate_shown` / `feature_gate_tapped` | Qué capacidad genera interés o fricción | `feature`, `trigger`, `user_tier` |
| `quota_milestone` | Cuándo se acerca el usuario al límite de documentos | `quota`, `user_tier` |
| `paywall_plan_selected` / `paywall_purchase_started` | Plan y contexto de decisión | `plan`, `trigger` |

La tabla es representativa; la allowlist de código es la autoridad. No se envían documentos, imágenes, OCR, nombres, títulos, rutas, identificadores documentales, PIN, correo, texto de errores ni identificadores de cuenta.

`AppState.trackEvent` añade automáticamente `user_tier` y `subscription_state` desde un snapshot local. El tier puede ser `free`, `trial`, `premium` o `lifetime`; la cancelación del auto-renewal se observa como `auto_renew_off` mientras el entitlement siga activo. Firebase continúa siendo opcional y la telemetría local sigue funcionando sin consentimiento.

## Validación y control de calidad

1. Instalar una build limpia y comprobar que `shield.analyticsConsent` no existe o es `false`.
2. Rechazar el aviso inicial y confirmar en Firebase DebugView que no aparece ningún evento de producto.
3. Activar Analytics desde Privacidad y confirmar sólo un evento allowlisted, sin PII.
4. Desactivarla de nuevo y confirmar que los eventos posteriores no se envían.
5. Verificar que OCR, máscaras, exportación, Bóveda, compras e iCloud siguen funcionando con Analytics desactivada.
6. Revisar la declaración de App Privacy y la política publicada cada vez que cambie el SDK, la allowlist o Crashlytics.

## Conversiones

Las decisiones comerciales deben usar App Store Connect Analytics y RevenueCat como fuentes de compra. Firebase Analytics sólo debe complementar el análisis de activación y uso cuando exista consentimiento; no debe convertirse en requisito funcional ni en requisito para acceder a la protección documental.

## Cohortes recomendadas

- Trial iniciado → renovación desactivada → trial expirado → conversión.
- Uso durante el trial frente a uso después de expirar: importación, redacción, exportación verificada, Vault y funciones Premium.
- Conversión por trigger: documentos, estilos, modos, batch, nube, ajustes e iconos.
- Hitos de cuota: 1, 3, 5, 8 y 10 documentos procesados.
