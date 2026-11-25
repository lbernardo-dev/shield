# Shield — pasos externos de publicación

> Estado actualizado: 21 de noviembre de 2026. La línea base histórica de publicación sigue debajo; consulta primero el estado vigente del ciclo IA/PCC.

## Entrega IA híbrida 1.2.0 — estado vigente

| Puerta | Estado | Acción pendiente |
|---|---|---|
| Capability PCC | Asignada por Apple, habilitada en `com.romerodev.shield` (`7BX79RLCY5`) y presente en el perfil/IPA de distribución | El Account Holder debe mantener las condiciones de elegibilidad de Apple; validar una inferencia real en hardware compatible |
| Build | `1.2.0 (10112026091404)`, App Store Connect `VALID`, firma Apple Distribution válida | Prueba de producto en TestFlight |
| TestFlight | Añadido al grupo interno existente `Shield Internal`; What to Test en `en-US` y `es-ES`; el grupo conserva su único tester actual | Instalarlo en dispositivo compatible y enviar feedback privado si se desea |
| Revisión/publicación | No se envió a revisión de App Store ni a revisión beta externa; no se notificó ni invitó a nuevos testers | Decidir aparte cualquier envío público futuro |
| Política de privacidad | El HTML local actualizado explica el uso local y el envío opcional de texto OCR mínimo a PCC tras consentimiento | Publicar la versión remota actualizada antes de una futura publicación pública y revisar App Privacy |
| Pruebas | `ShieldTests` 182 pasadas, 1 omitida, 0 fallidas; OCR focalizado 22/22; UI OCR/accesibilidad focalizada 2/2 | Completar los 65 casos UI e inferencia PCC en hardware; revisar los dos fallos del intento UI general |

Archive, IPA, perfiles PCC firmados y opciones de exportación se conservan en `.asc/artifacts/`. La UI PCC requiere la acción explícita y consentimiento por análisis; si el servicio o cuota no está disponible se conserva la ruta local/determinista. No se limpiaron los resultados de test ni el simulador aislado de esta validación.

---

> Línea base histórica: 11 de septiembre de 2026. Este documento sustituyó entonces las instrucciones de creación de ficha y primera publicación.

## Estado rápido

| Puerta | Estado local | Acción externa |
|---|---|---|
| Privacy manifest | Completado y validado | App Privacy publicada y verificada en sesión autenticada |
| Firma Distribution | Archive, export y auditoría IPA superados | Ninguna antes del upload |
| iCloud/CloudKit | Container, entitlements de la IPA 1.1.8 y schema `ShieldDocumentV2` verificados en Development y Production (19 nov 2026) | Probar la sincronización opt-in en un dispositivo físico con una cuenta iCloud de prueba |
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

Los dos bundle IDs, el App Group y los entitlements ya están reflejados en el IPA firmado. En CloudKit Console se verificó el 19 de noviembre de 2026 el contenedor correcto `iCloud.com.romerodev.shield` —no `iCloud.com.romerodev.expirely`—. `ShieldDocumentV2` está presente tanto en Development como en Production, con `docID` (`String`), `modifiedAt` (`Date/Time`) y `package` (`Asset`); Production no muestra cambios de esquema pendientes. La IPA 1.1.8 firmada para distribución declara el mismo contenedor. La sincronización en producción debe probarse en un dispositivo físico con una cuenta iCloud de prueba; la app desactiva deliberadamente CloudKit en procesos de simulador sin entitlements activos.

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
