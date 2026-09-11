# MaskID — superficies Apple y entrega en App Store Connect

Estado: actualizado el 11 de septiembre de 2026. La versión publicada es 1.0.8 con build 108202609071; la versión editable 1.0.9 está en `PREPARE_FOR_SUBMISSION` con el build `1092026091101` (`VALID`) asociado y lista para iniciar el envío a revisión.

Este documento es la especificación de producto y release. La metadata canónica que se valida y se sincroniza con App Store Connect vive en:

- metadata/app-info/en-US.json
- metadata/app-info/es-ES.json
- metadata/version/1.0.9/en-US.json
- metadata/version/1.0.9/es-ES.json

## Compatibilidad de dispositivos

MaskID usa un único target universal (com.romerodev.shield) con iOS/iPadOS 18 como mínimo y TARGETED_DEVICE_FAMILY = 1,2.

En iPad están cubiertos:

- interfaz adaptativa para clases de tamaño regular y compacta;
- barra lateral para navegación y espacio de trabajo de dos columnas;
- edición con lienzo y panel de herramientas persistente;
- retrato, paisaje, teclado, puntero, Dynamic Type y VoiceOver;
- importación desde Fotos/Archivos, captura con cámara, exportación y compartir;
- Share Extension disponible también desde los flujos del sistema en iPad.

No se publicita soporte para una función que no exista. Live Activities, Control Center y watchOS no forman parte de esta entrega.

## WidgetKit

Target y bundle:

- Target: ShieldWidgetExtension
- Bundle ID: com.romerodev.shield.widgets
- Widget kind: ShieldProtectionStatusWidget
- App Group: group.com.romerodev.shield

El widget muestra únicamente un resumen agregado y no expone documentos, OCR, títulos, nombres de archivo ni imágenes:

- total de documentos;
- documentos protegidos;
- documentos guardados en la Bóveda;
- botón de una pulsación para iniciar Captura.

Familias implementadas:

- Home Screen: systemSmall, systemMedium, systemLarge, systemExtraLarge;
- Lock Screen: accessoryCircular, accessoryRectangular, accessoryInline.

El contenido usa privacySensitive, se actualiza al persistir cambios y vuelve a cargar el timeline como máximo cada hora. El acceso directo sólo solicita abrir Captura; la Bóveda mantiene su autenticación.

## Siri, Atajos y App Intents

El proveedor ShieldAppShortcuts expone:

1. MaskDocumentIntent: “Protect/Mask a Document”, para iniciar la captura y protección.
2. OpenVaultIntent: “Open Secure Vault”, para abrir la Bóveda autenticada.

El widget también incluye ShieldWidgetOpenCaptureIntent. Las acciones están preparadas para aparecer en Siri, Atajos de Apple y superficies compatibles con App Intents. Ningún Atajo salta Face ID, Touch ID o código.

## App Review

Ruta de revisión recomendada:

1. Importar o capturar un documento.
2. Revisar detecciones y ajustar manualmente una redacción.
3. Añadir una marca de agua y exportar PDF o imagen.
4. Comprobar el resultado verificado y los metadatos eliminados.
5. Probar el widget en iPhone y iPad.
6. Probar Siri/Atajos para Captura y Bóveda; verificar que la Bóveda exige autenticación.
7. Probar Share > MaskID desde Fotos o Archivos.

No se necesitan credenciales de demo. Los datos de prueba deben ser sintéticos.

## Estado verificado de App Store Connect

- App `6790398619`, bundle ID `com.romerodev.shield`: `READY_FOR_DISTRIBUTION`.
- Build `108202609071`: `VALID`, asociado a 1.0.8; revisión completada.
- Build `1092026091101`: `VALID`, asociado a 1.0.9; la versión sigue en `PREPARE_FOR_SUBMISSION` y no se ha enviado a revisión.
- Metadata EN/ES y URLs actuales comprobadas en sesión web autenticada.
- App Privacy publicada; Accessibility tiene borradores sin publicar para iPhone/iPad.
- Firebase Analytics queda desactivada por defecto y requiere consentimiento explícito en la app; Crashlytics se mantiene como diagnóstico separado.
- Productos MaskID Pro Monthly, MaskID Pro Annual y MaskID Pro Lifetime aprobados.
- Billing Grace Period no configurado; Mac Apple-silicon habilitado pero sin verificación; no existen PPO, Custom Product Pages ni In-App Events.
- Los 20 screenshots iPhone corregidos están aplicados a 1.0.9, con 10 assets `COMPLETE` por locale; además, el set iPad ASO contiene 10 assets `COMPLETE` por locale a `2064×2752` (20 creatividades en total). El set histórico de 1.0.8 permanece sin cambios.
- `What to Test` de TestFlight está configurado en `en-US` y `es-ES` para el build `1092026091101`, con instrucciones de consentimiento explícito y datos sintéticos.
- Auditoría final pública: `asc validate --strict --check-urls`, `asc validate testflight --strict`, `asc validate iap --strict`, `asc validate subscriptions --strict`, `asc review doctor` y `scripts/app_store_preflight.sh --remote` no detectan errores, warnings ni bloqueos. La única información es que la API pública no puede verificar el estado de publicación de App Privacy; la evidencia previa de sesión web autenticada la marca como publicada.

## Configuración de App Store Connect

Checklist antes de subir:

- conservar la versión 1.0.9 en `PREPARE_FOR_SUBMISSION` hasta cerrar las puertas externas y la validación física;
- comprobar que el build contiene ShieldWidgetExtension.appex y ShieldShareExtension.appex;
- asociar el Bundle ID principal y los targets de extensión con sus perfiles de distribución;
- mantener group.com.romerodev.shield en la app, Share Extension y Widget Extension;
- mantener App Privacy publicada y alineada con Firebase/Crashlytics, RevenueCat y CloudKit según el uso real;
- conservar los screenshots iPhone corregidos desde `.asc/screenshots/aso/final/` y los iPad ASO desde `.asc/screenshots/aso/final-ipad/`; revisar el resultado final antes de enviar;
- usar las descripciones, keywords, promotional text y What’s New de `metadata/version/1.0.9/` como fuente canónica aplicada;
- no subir imágenes de widget o funciones no capturadas en una build real;
- adjuntar los productos StoreKit vigentes y revisar sus precios/localizaciones en App Store Connect;
- revisar Privacy Policy, Terms of Use, Subscription Terms y Support URLs en cada locale;
- conservar evidencia de App Privacy publicada en una sesión autenticada de App Store Connect;
- completar las notas de revisión y enviar manualmente cuando el build esté procesado.

La validación local no publica cambios remotos. Ejecutar asc metadata validate --subscription-app y un asc metadata push --dry-run cuando el CLI esté autenticado; sólo ejecutar un push real con autorización explícita.

## Validaciones del repositorio

- scripts/app_store_preflight.sh --local: Info.plist, entitlements, privacy manifests, targets, App Group, permisos y marcadores legales.
- scripts/app_store_preflight.sh --remote: además verifica las páginas públicas.
- scripts/audit_ipa.sh <ruta.ipa>: comprueba firma, entitlements de app/extensiones, minimum OS y presencia de los dos appex.
- WidgetSnapshotTests: comprueba que el estado compartido del widget sólo contiene agregados seguros.
