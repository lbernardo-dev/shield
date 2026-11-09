# Cierre de ciclo — MaskID 1.1.7

**Estado del release: build preparado y validado; envío/publicación aún no autorizados.** El candidato 1.1.7 / build 1172026110801 pasó la suite integral, fue archivado, firmado, cargado y procesado por ASC. En este cierre se corrigió la asociación del build a la versión y se añadieron notas “What to Test” para TestFlight en es-ES y en-US. La versión sigue en `PREPARE_FOR_SUBMISSION` con liberación manual. `asc validate --strict --ipa` y `asc validate testflight` terminan con cero bloqueos. La metadata de versión se escribió en ASC para es-ES y en-US; el nombre/subtítulo de la ficha pública no se tocó. Las 40 creatividades ASO se colocaron en los cuatro grupos correspondientes de App Asset Library. No se envió a App Review ni se publicó.

## Candidato y artifacts locales

- App Store: MaskID, bundle `com.romerodev.shield`.
- Versión/build: `1.1.7 / 1172026110801` = `117` + fecha de España `20261108` + consecutivo diario `01`. El generador consultó ASC en modo solo lectura y no encontró colisión.
- Archive: `.asc/artifacts/MaskID-1.1.7-1172026110801-final.xcarchive`.
- IPA: `.asc/artifacts/MaskID-1.1.7-1172026110801-final.ipa`; SHA-256 e identidad de firma constan en `15_BUILD_ARCHIVE_TESTFLIGHT.md`.
- App, Share Extension y Widget Extension dentro de archive e IPA coinciden en versión y build. Archive e IPA pasan `codesign --verify --deep --strict`; IPA con perfil App Store Connect y `get-task-allow=false`. UUID arm64 de ejecutables y dSYMs coinciden.
- Los candidatos 1.2.0/builds `1202026110801` y `1202026110802` se conservan como artifacts reemplazados, sin upload.
- Rama local `release/1.1.7-20261108`. El worktree mantiene cambios acumulados de fases anteriores y el archivo no rastreado `-`; no se hizo commit, tag, push, reset ni limpieza.

## QA y experiencia

- Suite completa final en iPhone 18 Pro / iOS 27.2: **236 PASS, 7 SKIP, 0 FAIL**; XCResult confirma cero runtime warnings, build warnings, analyzer warnings y errores. El pase focalizado de los cinco tests afectados por el helper de scroll dio 5/5 PASS. El helper quedó acotado a la lista raíz de Ajustes; no se cambió el comportamiento de producción.
- QA comercial posterior: el test focalizado resolvió el offering `default` y los tres SKU en StoreKit local (3 PASS). El intento de purchase/restore local no concluyó y no se considera evidencia transaccional; Sandbox/TestFlight real sigue pendiente.
- Captura base-theme: 1/1 PASS en iPhone 18 Pro Max y 1/1 PASS en iPad Pro de 13″; en es-ES y en-US el test confirmó `MaskID Original` y la preferencia estacional desactivada.
- Hay 16 capturas UI auténticas de origen de 1.1.7, con fixtures sintéticos y tema base verificado. A partir de ellas se compusieron 40 creatividades con titulares y beneficios localizados para los sets ASO, en iPhone 1320 × 2868 e iPad 2064 × 2752. Orden, copy y SHA-256: `11_SCREENSHOTS_AND_PREVIEWS/creatives/1.1.7/CREATIVE_SET_MANIFEST.json`; hojas de contacto en el mismo directorio `review/`. Se excluyó Home por solapamiento del encabezado con la tab bar; la exportación explica la revisión obligatoria previa, como funciona la app.
- Metadata canónica es-ES/en-US pasa límites y validación ASC local sin errores ni warnings. No hay evidencia para declarar soporte ASO de más idiomas.
- No se observaron diagnósticos de APIs deprecadas en la suite ni en el archive; la lista de versiones de dependencias y el detalle de firma quedan en el informe del build.

## Sincronización remota realizada

- ASC borrador de versión `1.1.7`: `PREPARE_FOR_SUBMISSION`, liberación manual. ID `a900074d-07ef-4368-b6b9-8007c437bba1`.
- Metadata 1.1.7: en-US y es-ES escritas y leídas de vuelta por `asc metadata push`; descripción, keywords, texto promocional y novedades actualizados. No se gestionó el scope `app-info`.
- TestFlight: build ID `2d9de6eb-e554-4fca-84f5-58eaccd2b88d`, estado de procesamiento `VALID` y vinculado a la versión 1.1.7. Se añadieron notas es-ES/en-US, se asignó a `Shield Internal` con autorización del propietario y ASC confirma `IN_BETA_TESTING`. El grupo contiene un tester existente `INSTALLED`; no se añadieron testers. `autoNotifyEnabled=true`, pero ASC no ofrece confirmación de entrega del aviso.
- RevenueCat: el dashboard autenticado confirmó `default` como offering actual, los paquetes mensual/anual/vitalicio, sus SKU de MaskID, el entitlement `MaskID Pro` y tres productos separados de la app Test Store para pruebas. El annual cuesta 29,99 € en España y no tiene ofertas asociadas; el Store State confirma `trial_offer=null` e `introductory_offers={}`. `trial_duration=P1W` es metadata residual y no una prueba de trial activo. MCP sigue devolviendo 403 para parte de las lecturas. Los últimos precios leídos para mensual y vitalicio (2,99 €/49,99 €) son del 8-11; en este cierre no se obtuvo refresh de esos dos productos. No se cambiaron precios ni ofertas porque los importes aprobados coinciden con ASC.
- Creatividades: los grupos `IPHONE_DYNAMIC_ISLAND_LARGE_PROFILE` y `IPAD_13_PROFILE` de es-ES/en-US contienen 10 colocaciones cada uno, todas `ACTIVE`; las 40 imágenes están en `PREPARE_FOR_SUBMISSION` y ordenadas 1–10. Se preservaron los grupos de iPhone 6,1″ y iPhone Duo. IDs y estado por asset: `16_ASC_SCREENSHOT_UPLOAD_REPORT.md`.
- API de imágenes: la comprobación final usa App Asset Library y placements actuales. Se detectó y detuvo el flujo anterior de screenshot sets obsoleto; la evidencia de finalización se basa exclusivamente en placements vigentes. Una colocación incompleta es-ES/iPad se retiró y se sustituyó por los assets procesados 09 y 10.

## Bloqueos antes de envío

1. Revisión y aprobación jurídica de privacidad, términos y condiciones del acceso temporal.
2. Revisión manual de App Privacy publicada frente a SDKs, consentimientos y documentación. `asc validate --deep` no pudo usar una sesión web de Apple; la declaración no se modificó.
3. StoreKit Sandbox: ejecutar compra/restauración mensual, anual y vitalicia, cancelación, pending, grace/retry, refund/revoke y renovación con la cuenta Sandbox del tester interno. Se verificó el catálogo RC/StoreKit local (3/3); la prueba local de transacción se interrumpió sin resultado verificable. ASC lista un tester en ESP, pero desde este entorno no se pudo validar una sesión física TestFlight/Sandbox.
4. Completar E2E de expiración mientras editor/captura están abiertos, pase manual de VoiceOver/Control por voz/Switch Control/Zoom/Dynamic Type y CloudKit multi-dispositivo.
5. MCP RevenueCat: sólo requiere renovar permisos si se necesitan endpoints API que devuelven 403; el dashboard autenticado ya confirmó catálogo y entitlement. No se requiere cambio de precio ni oferta.

El detalle está en `02_RELEASE_QUALITY_MATRIX.md`, `03_QA_TEST_MATRIX.csv`, `13_ASC_REVENUECAT_RECONCILIATION.md`, `15_BUILD_ARCHIVE_TESTFLIGHT.md`, `17_OWNER_ACTIONS.md` y `RELEASE_MANIFEST.json`. El estado actual es apto en las validaciones automatizadas; siguen pendientes la aprobación jurídica, revisión de privacidad y pruebas Sandbox/físicas. La beta interna está distribuida; no se envió a Beta App Review ni a App Review y no se publicó.
