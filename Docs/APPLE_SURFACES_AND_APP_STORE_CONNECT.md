# MaskID — superficies Apple y entrega en App Store Connect

Estado: preparado localmente para la versión 1.0.4 y el build 104202608260.

Este documento es la especificación de producto y release. La metadata canónica que se valida y se sincroniza con App Store Connect vive en:

- metadata/app-info/en-US.json
- metadata/app-info/es-ES.json
- metadata/version/1.0.4/en-US.json
- metadata/version/1.0.4/es-ES.json

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

## Configuración de App Store Connect

Checklist antes de subir:

- crear/procesar el build 1.0.4 (104202608260) del target principal;
- comprobar que el build contiene ShieldWidgetExtension.appex y ShieldShareExtension.appex;
- asociar el Bundle ID principal y los targets de extensión con sus perfiles de distribución;
- mantener group.com.romerodev.shield en la app, Share Extension y Widget Extension;
- publicar el App Privacy actualizado: sin tracking ni publicidad; documentar Firebase/Crashlytics, RevenueCat y CloudKit según el uso real;
- subir screenshots reales de iPhone y iPad desde .asc/screenshots/;
- usar las descripciones, keywords, promotional text y What’s New de metadata/version/1.0.4/;
- no subir imágenes de widget o funciones no capturadas en una build real;
- adjuntar los productos StoreKit vigentes y revisar sus precios/localizaciones en App Store Connect;
- revisar Privacy Policy, Terms of Use, Subscription Terms y Support URLs en cada locale;
- confirmar el estado de publicación de App Privacy en una sesión autenticada de App Store Connect;
- completar las notas de revisión y enviar manualmente cuando el build esté procesado.

La validación local no publica cambios remotos. Ejecutar asc metadata validate --subscription-app y un asc metadata push --dry-run cuando el CLI esté autenticado; sólo ejecutar un push real con autorización explícita.

## Validaciones del repositorio

- scripts/app_store_preflight.sh --local: Info.plist, entitlements, privacy manifests, targets, App Group, permisos y marcadores legales.
- scripts/app_store_preflight.sh --remote: además verifica las páginas públicas.
- scripts/audit_ipa.sh <ruta.ipa>: comprueba firma, entitlements de app/extensiones, minimum OS y presencia de los dos appex.
- WidgetSnapshotTests: comprueba que el estado compartido del widget sólo contiene agregados seguros.
