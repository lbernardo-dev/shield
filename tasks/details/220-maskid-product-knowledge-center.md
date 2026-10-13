# 220-maskid-product-knowledge-center

- Number: 220
- Slug: maskid-product-knowledge-center

## Resultado

- La landing pública de Apps de MaskID ahora enlaza una guía completa en español e inglés con tutoriales, flujo de protección/exportación, FAQ, notas aclaratorias, privacidad, planes, proveedores y límites verificados. Las correcciones de marca, cuota Gratis, plataformas, política/contacto y sitemap están publicadas.
- PR [#1](https://github.com/lbernardo-dev/apps/pull/1) se fusionó como `dec557fa9a9689990f9cfc576f21b54250e7f510`; Pages workflow `38402032624` terminó con éxito. El ajuste de cambio de idioma de PR [#4](https://github.com/lbernardo-dev/apps/pull/4) se fusionó como `25fc5749a962e9f50e5062b19e01707ba885ae01`; workflow `38403009617` terminó con éxito. Se verificaron en vivo las rutas ES/EN de guía, privacidad, términos y soporte.
- La auditoría adicional detectó metadatos CloudKit de versiones antiguas (`ShieldDocument`, que históricamente incluía el título real) que podían permanecer después de mover un documento a la Bóveda. La app ahora consulta y elimina esos registros obsoletos antes de reconciliar el esquema V2, con borrado por lotes e idempotencia si otro dispositivo ya eliminó el registro. Se añadió cobertura en `SecurityPrivacyTests`.
- Se creó la versión iOS 1.1.4 en App Store Connect (versión `af839c46-5770-407d-9226-1c7d47e79c08`, lanzamiento manual). La versión tiene los dos locales existentes, `en-US` y `es-ES`; ambos What's New fueron actualizados y releídos desde ASC (709 y 866 caracteres). ASC informa total 2 localizaciones.
- El build `1142026101302` (build ID `38dec38a-eaf0-4bbe-bade-6004abf5188d`) fue subido, procesado como `VALID` y enlazado a 1.1.4. La versión sigue en `PREPARE_FOR_SUBMISSION`; no se envió a revisión. `asc validate` informa 0 errores, 0 advertencias, 0 bloqueos y 2 avisos informativos (lanzamiento manual y estado de publicación de App Privacy no verificable por API pública).
- Release artifacts preservados en `.asc/artifacts/`: archivo `.302`, IPA `.302`, opciones de exportación y resultados `.xcresult`. La IPA mide 53,241,027 bytes; SHA-256 `1b5bf1bf79422c329d0e520c6bd6791af5a5f81031ee3f9aeca744358875b03a`.

## Validación

- Simulador principal: iPhone 18 Pro, iOS 27.0, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`. Suite de unidad: 117 aprobadas, 1 omitida y 0 fallidas. `testSettingsNavigationRespondsToSingleTaps` pasó; `testPaywallCanDismissToWorkspace` pasó al repetirse con MaskID confirmado en primer plano.
- iPad representativo: iPad Pro 13-inch (M5), iPadOS 27.0, UDID `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`. La navegación de Ajustes pasó en vertical; el paywall horizontal pasó a 1376×1032 y conservó compra, restauración y enlaces legales. El test de cierre del paywall pasó en vertical.
- Un test de iPad falló inicialmente porque buscaba `app.buttons["tab.0"]`, que devuelve dos botones con el mismo identificador en el TabView adaptable aunque el tab seleccionado sí es hittable. Se corrigió el selector del test a `firstMatch`; el test pasó en iPhone y iPad. La grabación confirmó que la biblioteca/workspace seguía visible y no había una regresión de cierre.
- iPhone Duo no está disponible; el proyecto no contiene target de watchOS. No se reinició ni borró ningún simulador. Cuando PersonalCare/VitalsPath volvió a ocupar iPhone 18 Pro, no se lo terminó tras la validación final.
- iOS 27 mostró el aviso no bloqueante de clase duplicada `UIAccessibilityLoaderWebShared` en WebKit/WebCore. Los tests finalizaron correctamente.
- El host local no tiene identidades de firma listadas (`security find-identity` devolvió 0) y `codesign --verify` devuelve `CSSMERR_TP_NOT_TRUSTED`, también con el IPA/archive .301 previo. La IPA .302 incluye perfil de distribución App Store (`get-task-allow=false`, sin `ProvisionedDevices`) y ASC la procesó como `VALID` y `APP_STORE_ELIGIBLE`.

## Cambios preparados para commit

- App: `Shield/Cloud/CloudSyncManager.swift`, `ShieldTests/SecurityPrivacyTests.swift`, `Shield.xcodeproj/project.pbxproj`, `metadata/version/1.1.4/en-US.json`, `metadata/version/1.1.4/es-ES.json`.
- Test UI: selector portable para pestañas duplicadas del TabView de iPad en `ShieldUITests/ShieldLaunchTests.swift`.
- Backlog: `tasks/TASKS.md` y este detalle.
- El checkout contiene además cambios preexistentes y ajenos en `Marketing/30-Day-Social-Campaign/**`, `scripts/build_30_day_social_campaign.py` y `scripts/clean.sh`; no deben incluirse en el commit.
