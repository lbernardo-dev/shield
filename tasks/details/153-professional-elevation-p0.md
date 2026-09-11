# 153-professional-elevation-p0

- Number: 153
- Slug: professional-elevation-p0

## Notes

### Ejecutado — 11 de septiembre de 2026

- Corregida la matriz de claims en `Docs/CLAIMS_MATRIX.md` y alineado el copy de los creatives ASO con la implementación real: procesamiento local, sincronización opcional, Bóveda local AES-GCM con Face ID/PIN y exportación verificada sin promesas absolutas.
- Ajustado `.asc/aso-screenshot-plan.json` para retirar `Secure Enclave`, `hardware encryption`, `100% offline`, `zero cloud` y `certified privacy`.
- Capturado y compuesto el set de 20 screenshots (10 `es-ES` + 10 `en-US`) en iPhone Air, dark mode, con 1320×2868 px; revisión visual de contact sheets completada. Manifiesto y hashes: `Docs/ASO_SCREENSHOT_MANIFEST_2026-09-11.md`.
- Corregido el flujo de fixture ASO OCR para no mostrar `No hay imagen disponible` cuando el documento sintético no tiene imagen en disco; añadido test UI `testASOOCRFixtureDoesNotSurfaceMissingImageError`.
- Mejorada la reproducibilidad de build eliminando únicamente sidecars `._*` de resource fork dentro de caches generadas por el workflow en `scripts/xcbuild.sh`; captura ASO con selección determinista de simulador, terminación previa, espera configurable, reintentos y validación de screenshot en `scripts/capture_raw_10_scenes.sh`.
- `AGENT_NAME=CODEX make build`: correcto.
- `AGENT_NAME=CODEX make test`: compilación correcta; la suite UI global terminó con 3 fallos por inestabilidad del recorrido completo y tiempos de espera largos, no relacionados con la lógica OCR corregida. Los tres casos se verificaron después de forma aislada en iPhone Air: OCR ASO, permiso de cámara y navegación de Ajustes pasaron; también pasó el flujo de valoración in-app.
- Validaciones aisladas en iPhone Air: `testASOOCRFixtureDoesNotSurfaceMissingImageError`, `testCameraPermissionContinueAdvancesToPaywall`, `testSettingsNavigationRespondsToSingleTaps` y `testRateAppUsesInAppStoreKitFlow` pasaron; la suite `OCREnginePrecisionTests` pasó con 7 tests y 0 fallos.
- Cambiada la política de analítica: Firebase Analytics queda desactivada por defecto mediante `FIREBASE_ANALYTICS_COLLECTION_ENABLED=false`, sólo registra después de consentimiento explícito persistido y ofrece decisión inicial más control posterior en Ajustes > Privacidad. Se mantiene la separación con Crashlytics.
- Añadido `Docs/ANALYTICS_TRACKING_PLAN.md` con eventos, propiedades permitidas, decisiones que informan y checklist de DebugView/QA; actualizadas la política legal EN/ES, la ficha operativa y las cadenas localizadas.
- Verificación de consentimiento: `SecurityPrivacyTests` pasó con 7 casos; `testAnalyticsConsentIsExplicitAndOffByDefault` y `testAnalyticsConsentCanBeRevokedFromPrivacySettings` pasaron en iPhone Air. El build estricto continúa correcto.
- App Store Connect se revalidó en sesión web autenticada: App Privacy figura como publicada; Accessibility conserva dos borradores sin publicar; las suscripciones y el IAP están aprobados; Billing Grace Period no está configurado; Mac Apple-silicon está habilitado pero sin verificación; no hay PPO, Custom Product Pages ni In-App Events.

### Corrección de build y staging ASC — 11 de septiembre de 2026

- Todos los targets y configuraciones de `Shield.xcodeproj` quedaron en `MARKETING_VERSION=1.0.9` y `CURRENT_PROJECT_VERSION=1092026091101`: app, `ShieldWidgetExtension` y `ShieldShareExtension`, Debug y Release.
- Archive/export completados y auditados: `.asc/artifacts/MaskID-1.0.9-1092026091101.xcarchive` y `.asc/artifacts/MaskID-1.0.9-1092026091101.ipa`. La auditoría del IPA confirmó firma Distribution, entitlements de producción, minimum OS y extensiones; el binario conserva `FIREBASE_ANALYTICS_COLLECTION_ENABLED=false`.
- IPA subido a App Store Connect con build ID `4f393fed-c778-4635-80cf-527409388e68`; procesamiento `VALID`, `APP_STORE_ELIGIBLE`, iOS mínimo 18.0 y sin cifrado no exento.
- Build `1092026091101` enlazado a la versión `1.0.9` (version ID `56072990-e50d-4e16-b7df-26498613d05c`), que permanece en `PREPARE_FOR_SUBMISSION`; no se ha enviado a revisión.
- `What’s New` completo aplicado en `en-US` y `es-ES` desde `metadata/version/1.0.9/`; validación de metadata: 18 archivos, 0 errores y 0 warnings.
- Screenshots corregidos reemplazados en ASC: 10 `COMPLETE` para `en-US` y 10 `COMPLETE` para `es-ES` (display type `APP_IPHONE_67`, 1320×2868); los assets iPad existentes no se tocaron.
- `asc validate` final: 0 errores, 0 warnings y 1 aviso informativo no bloqueante porque el estado de publicación de App Privacy no es verificable mediante la API pública; ya había sido confirmado como publicado en sesión web autenticada.
- El build incorrecto `108202609072` permanece cargado pero separado de 1.0.9; no se eliminó para conservar trazabilidad.

### Decisiones pendientes

El build, la metadata y los screenshots ya están preparados en 1.0.9 sin enviar a revisión. Antes de la submission siguen abiertas las decisiones de publicar Accessibility y las decisiones comerciales (Billing Grace Period, disponibilidad Mac, PPO, Custom Product Pages e In-App Events). También queda por desplegar/verificar públicamente el contenido legal local antes de enviar.
