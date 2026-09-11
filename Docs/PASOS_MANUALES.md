# Shield — pasos externos de publicación

> Estado verificado: 11 de septiembre de 2026. Este documento sustituye las instrucciones históricas de creación de ficha y primera publicación.

## Estado rápido

| Puerta | Estado local | Acción externa |
|---|---|---|
| Privacy manifest | Completado y validado | App Privacy publicada y verificada en sesión autenticada |
| Firma Distribution | Archive, export y auditoría IPA superados | Ninguna antes del upload |
| iCloud/CloudKit | Entitlement de producción y schema `ShieldDocumentV2` verificados | Probar sync opt-in en TestFlight/dispositivo físico |
| App Group/Keychain Group | Verificados en app y Share Extension exportadas | Ninguna antes del upload |
| URL scheme `shield` | Completado | Ninguna |
| StoreKit | Implementación y productos aprobados | Configurar Billing Grace Period sólo si se decide |
| Privacidad/términos | Contenido local, HTML publicable y endpoints remotos validados | Mantener las URLs publicadas y registrarlas en App Store Connect |
| Icono y marca | Integrados como Shield | Confirmar render en Archive/App Store |
| App Store metadata | 1.0.8 publicada; 1.0.9 en preparación con copy EN/ES aplicado | Completar gates externos y revisar antes de enviar |
| Screenshots | 20 iPhone + 20 iPad ASO corregidos, revisados y aplicados a 1.0.9 | Revisar el resultado visual final antes de enviar |
| Archive | Build 1.0.9 `1092026091101` válido y enlazado | Distribuir a TestFlight y hacer validación física |
| TestFlight | `What to Test` EN/ES configurado para `1092026091101` | Beta física de 72 horas como mínimo |

## Estado actual de App Store Connect

- App: `6790398619`, bundle ID `com.romerodev.shield`.
- Versión publicada: `1.0.8`; build `108202609071`; estado `READY_FOR_DISTRIBUTION`; build `VALID`; revisión completada.
- Versión en preparación: `1.0.9`; build `1092026091101`; estado `PREPARE_FOR_SUBMISSION`; build `VALID` y enlazado.
- Metadata actual EN/ES, URLs, App Review notes, App Privacy y productos aprobados se han comprobado en la sesión web autenticada.
- App Privacy está publicada y declara la telemetría real de Firebase/Crashlytics, RevenueCat y CloudKit; no hay tracking publicitario.
- Accessibility tiene borradores sin publicar para iPhone e iPad: VoiceOver, Dark Interface y Reduced Motion.
- La ficha pública contiene copy actual; el historial de versiones antiguas conserva copy histórico que Apple no permite editar retroactivamente.
- Los screenshots iPhone corregidos están en `.asc/screenshots/aso/final/` y los iPad ASO en `.asc/screenshots/aso/final-ipad/`; su manifiesto es `Docs/ASO_SCREENSHOT_MANIFEST_2026-09-11.md`. Los 40 assets están aplicados a 1.0.9 (20 iPhone + 20 iPad); los assets históricos de 1.0.8 no se modifican.
- `What to Test` está completo en `en-US` y `es-ES` para TestFlight y cubre el consentimiento explícito de analítica, los flujos principales y el uso exclusivo de datos sintéticos.
- La validación final pública de la versión no tiene errores, warnings ni bloqueos; IAP, suscripciones, TestFlight, URLs y preflight remoto también pasan en modo estricto. El único aviso informativo es la publicación de App Privacy, cuyo estado no es legible mediante la API pública de Apple.
- Suscripciones e IAP están aprobados. Billing Grace Period no está configurado; Mac Apple-silicon está habilitado pero sin verificación; no hay PPO, Custom Product Pages ni In-App Events.

## Decisiones externas que desbloquean el siguiente ciclo

1. Mantener la versión `1.0.9` en preparación hasta completar la prueba física de TestFlight y la comprobación final de las URLs legales. El build y la ficha ya están asociados; esto no implica enviarla a revisión.
2. Autorizar o no publicar los borradores de Accessibility existentes.
3. Decidir si se activa Billing Grace Period y si se mantiene disponible Mac Apple-silicon mientras no haya verificación física.
4. Política de analítica resuelta: Firebase Analytics queda desactivada por defecto y sólo se activa tras consentimiento explícito; Crashlytics permanece separado como diagnóstico de estabilidad. Hay que publicar la nueva versión que contiene este cambio y comprobar la política remota.

## Configuración del Developer Portal

Los dos bundle IDs, el App Group y los entitlements ya están reflejados en el IPA firmado. En CloudKit Console, el contenedor correcto es `iCloud.com.romerodev.shield` —no `iCloud.com.romerodev.expirely`— y `ShieldDocumentV2` está desplegado en Development y Production con `docID`, `modifiedAt` y `package`. El identificador principal todavía aparece con Push Notifications en una consulta remota aunque no existe entitlement ni uso de push en el binario; puede retirarse manualmente como limpieza del portal, pero no afecta al artefacto exportado.

## App Store Connect

1. Mantener `1.0.9` en `PREPARE_FOR_SUBMISSION` y revisar el build `1092026091101` asociado.
2. La metadata y los screenshots corregidos ya están asociados; no reutilizar el plan histórico `.asc/metadata/review/1.0.8/plan.json` como fuente.
3. Ejecutar `scripts/app_store_preflight.sh --remote` y `asc metadata validate` antes de cualquier push.
4. Probar compra, restauración, cancelación y error en sandbox/TestFlight cuando se cambie StoreKit o se prepare una nueva entrega.
5. Con autorización expresa, subir el nuevo IPA, distribuir a TestFlight interno y revisar MetricKit/Organizer durante al menos 72 horas.

## Pruebas físicas obligatorias

- Cámara, escáner y permisos denegados/limitados.
- Fotos con acceso limitado y Files providers instalados.
- Share Extension desde Fotos, Archivos, Mail y Safari.
- Face ID/Touch ID, cambio de biometría y dispositivo bloqueado.
- iPad Split View, teclado, VoiceOver, Voice Control, Dynamic Type XXXL y Reduce Motion.
- PDFs adversariales, multipágina y grandes, comprobados también con herramientas externas.
