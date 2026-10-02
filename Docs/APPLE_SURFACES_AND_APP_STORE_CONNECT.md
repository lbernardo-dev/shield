# MaskID — superficies Apple y entrega en App Store Connect

Estado: actualizado el 2 de octubre de 2026. App Store Connect mostró 1.1.1 como último release publicado (`READY_FOR_SALE` / `READY_FOR_DISTRIBUTION`). La versión editable 1.1.2 (`904cc5ee-994a-48cb-84db-265013b3cd75`) está en `PREPARE_FOR_SUBMISSION`, con lanzamiento manual, metadata EN/ES, 40 capturas y previews copiados y procesados. Aún no tiene build ni What’s New, no se ha enviado a revisión y no se ha publicado.

Este documento es la especificación de producto y release. La metadata canónica que se valida y se sincroniza con App Store Connect vive en:

- metadata/app-info/en-US.json
- metadata/app-info/es-ES.json
- metadata/version/1.1.2/en-US.json
- metadata/version/1.1.2/es-ES.json

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
- Version 1.1.1: último release publicado observado (`READY_FOR_SALE` / `READY_FOR_DISTRIBUTION`).
- Version 1.1.2: `PREPARE_FOR_SUBMISSION`, sin build; no se ha enviado a revisión.
- `asc validate --app 6790398619 --version 1.1.2 --check-urls`: un bloqueo (build ausente), dos avisos (What’s New vacío EN/ES), dos informativos (lanzamiento manual; publicación de App Privacy no verificable por API). URLs y capturas no presentaron errores.
- Metadata EN/ES y URLs actuales comprobadas en sesión web autenticada.
- App Privacy publicada; Accessibility tiene borradores sin publicar para iPhone/iPad.
- Firebase Analytics queda desactivada por defecto y requiere consentimiento explícito en la app; Crashlytics se mantiene como diagnóstico separado.
- Productos MaskID Pro Monthly, MaskID Pro Annual y MaskID Pro Lifetime aprobados.
- Billing Grace Period no configurado; Mac Apple-silicon habilitado pero sin verificación; no existen PPO ni Custom Product Pages. El In-App Event Halloween 2026 está guardado como borrador remoto (`6816385632`) en `Marketing/AppStore-Connect/InAppEvents/halloween-2026/`; incluye metadata EN/ES, media, deep link y programación, pero todavía no se ha enviado a revisión ni publicado.
- En 1.1.2 constan 10 capturas iPhone y 10 iPad `COMPLETE` para cada locale (40 en total); el App Preview `MaskID-Identity-Protection.mov` también está `COMPLETE` para en-US y es-ES.
- `What to Test` de TestFlight está configurado en `en-US` y `es-ES` para el build `1092026091101`, con instrucciones de consentimiento explícito y datos sintéticos.
- Auditoría final pública: `asc validate --strict --check-urls`, `asc validate testflight --strict`, `asc validate iap --strict`, `asc validate subscriptions --strict`, `asc review doctor` y `scripts/app_store_preflight.sh --remote` no detectan errores, warnings ni bloqueos. La única información es que la API pública no puede verificar el estado de publicación de App Privacy; la evidencia previa de sesión web autenticada la marca como publicada.

## Configuración de App Store Connect

Checklist antes de subir:

- mantener 1.1.2 como borrador hasta asociar una build correspondiente y completar What’s New EN/ES;
- comprobar que el build contiene ShieldWidgetExtension.appex y ShieldShareExtension.appex;
- asociar el Bundle ID principal y los targets de extensión con sus perfiles de distribución;
- mantener group.com.romerodev.shield en la app, Share Extension y Widget Extension;
- mantener App Privacy publicada y alineada con Firebase/Crashlytics, RevenueCat y CloudKit según el uso real;
- conservar los screenshots iPhone corregidos desde `.asc/screenshots/aso/final/` y los iPad ASO desde `.asc/screenshots/aso/final-ipad/`; revisar el resultado final antes de enviar;
- usar descripción, keywords y promotional text de `metadata/version/1.1.2/` como fuente canónica aplicada; redactar What’s New al conocer los cambios reales de la build;
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
