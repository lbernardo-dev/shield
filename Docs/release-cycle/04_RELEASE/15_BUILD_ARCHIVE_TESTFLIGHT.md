# Archive, IPA y TestFlight

## Candidato local

- Proyecto/scheme/configuración: `Shield.xcodeproj` / Shield / Release.
- Bundle: `com.romerodev.shield`; Xcode 27.2, SDK iOS 27.2, deployment target iOS 18.0.
- Versión/build: `1.1.7 / 1172026110801` = `117` + fecha España `20261108` + consecutivo diario `01`.
- Archive: `.asc/artifacts/MaskID-1.1.7-1172026110801-final.xcarchive` (144 MB).
- IPA local: `.asc/artifacts/MaskID-1.1.7-1172026110801-final.ipa` (55,232,054 bytes; SHA-256 `027804d9d27daf93e04e8f0869eb6f07b6db4d247081a4cd3734ab9284d437e9`).
- ExportOptions: `.asc/artifacts/MaskID-1.1.7-1172026110801-final-ExportOptions-94cb72b7968d426a.plist`.
- `asc xcode archive` y `asc xcode export` finalizaron correctamente. El IPA se cargó a App Store Connect con `asc publish testflight --upload-only --wait` y el build terminó `VALID`.
- `codesign --verify --deep --strict --verbose=2` pasó tanto para el app archivado como para el app extraído del IPA (`valid on disk`, `satisfies its Designated Requirement`). La firma IPA declara `iPhone Distribution: Lester Romero Bernardo (L2B56644F5)`, Team ID `L2B56644F5`.
- ExportOptions usa `method=app-store-connect`, `signingStyle=automatic` y Team `L2B56644F5`. El IPA tiene perfil `iOS Team Store Provisioning Profile: com.romerodev.shield`, `get-task-allow=false`, `beta-reports-active=true` y cero dispositivos registrados; el app ID coincide con el bundle esperado. El archive intermedio está firmado por Apple Development, pero la exportación convierte y firma el IPA para distribución de App Store Connect.
- Archive e IPA confirman `1.1.7 / 1172026110801` en MaskID, Share Extension y Widget Extension. UUIDs arm64 de ejecutables app/extensions coinciden con los dSYMs; hay dSYMs de MaskID, Share, Widget y Lottie.
- SHA y manifestes de artefactos pueden reproducirse con `shasum -a 256` y `plutil`/`codesign`; las carpetas previas 1.2.0 se preservan como candidatos reemplazados, no subidos.

## QA y APIs

- Suite integral 1.1.7: **236 PASS, 7 SKIP, 0 FAIL**; `result=Passed`, cero runtime warnings, cero errores, cero build warnings y cero analyzer warnings. XCResult persistente: `.asc/artifacts/MaskID-1.1.7-1172026110801-final-tests.xcresult`. El bundle registra iPhone 18 Pro, iOS Simulator 27.2; 244 ejecuciones de dispositivo/configuración incluyen 9 runs de un test con parámetros dinámicos.
- Los siete skips se explican en el resultado: cuatro comprobaciones de iPhone Duo que requieren otras pantallas, dos casos de layout iPad cubiertos en la corrida focalizada 2/2, y la lectura integrada del offering RevenueCat deshabilitada por guardia de entorno.
- En una ejecución focalizada posterior, la lectura del offering de RevenueCat contra el catálogo StoreKit local pasó junto a las dos comprobaciones de catálogo (3 PASS, 0 SKIP, 0 FAIL) en iPhone 18 Pro/iOS 27.2; XCResult: `.asc/artifacts/MaskID-1.1.7-Product-Catalog-Integration-Enabled.xcresult`. Esto confirma el mapeo y la carga de productos; no es una transacción.
- Se intentó ampliar la integración a compra/restauración simuladas. El worker de XCTest se bloqueó/reinició durante la operación y xcodebuild se interrumpió a los 190 s (exit 75); las dos pruebas de catálogo pasaron, pero el caso de integración no produjo resultado verificable y su XCResult quedó incompleto: `.asc/artifacts/MaskID-1.1.7-StoreKit-Purchase-Restore.xcresult`. No se trata como PASS ni se afirma si la compra simulada llegó a registrarse. El test source quedó restaurado a su guardia opt-in original y no se cambió el código de la app ni el archive.
- La regresión detectada en navegación de Ajustes se reprodujo/aisló; el helper de scroll quedó limitado a la lista raíz de Settings y conserva gestos previos en scroll views identificadas. Los 5 tests focalizados de Settings, editor y exportación pasaron, seguidos por la suite íntegra final.
- El test de capturas `testASOCaptureScreensUseBaseThemeInBothStoreLocales` pasó en iPhone 18 Pro Max y iPad Pro 13″ con `MaskID Original` y preferencia estacional desactivada. Resultados y evidencia están referenciados en `11_SCREENSHOTS_AND_PREVIEWS/README.md` y su manifiesto 1.1.7.
- Las 16 capturas auténticas de 1.1.7 son fuentes de UI, con tema base confirmado y fixtures sintéticos. Sobre ellas se compusieron 40 creatividades ASO, 10 por combinación es-ES/en-US × iPhone 6,9″/iPad 13″, en 1320×2868 y 2064×2752. Pasaron validación local; las 40 están asignadas con APIs actuales de App Asset Library: cuatro grupos, 10 colocaciones `ACTIVE` por grupo, imágenes `PREPARE_FOR_SUBMISSION` y orden 1–10. IDs/estados: `16_ASC_SCREENSHOT_UPLOAD_REPORT.md`. Home se excluyó por superposición visible de la barra flotante sobre el encabezado.
- Metadata canónica es-ES/en-US pasa `scripts/validate_release_metadata.py` y `asc metadata validate --dir metadata --subscription-app`; ASC offline indicó 32 archivos, 0 errores y 0 warnings. No equivale a validación remota.
- No se observaron diagnósticos de APIs deprecadas en los resultados de build/test revisados. El build informó un aviso del procesador de App Intents porque la app no enlaza `AppIntents.framework`; no es una deprecación. Paquetes resueltos: RevenueCat 5.102.3, Firebase 12.16.0, Lottie 4.6.1.

## Estado remoto actualizado el 9-11-2026

- App Store Connect versión `1.1.7`, ID `a900074d-07ef-4368-b6b9-8007c437bba1`, estado `PREPARE_FOR_SUBMISSION`, `releaseType=MANUAL`. Metadata es-ES/en-US fue escrita y leída de vuelta. Build `1172026110801`, ID `2d9de6eb-e554-4fca-84f5-58eaccd2b88d`, está `VALID` y `READY_FOR_BETA_TESTING`.
- El read-back de ASC descubrió que el build no estaba asociado a la versión 1.1.7. Se corrigió con `asc versions attach-build`; `asc versions view --include-build` confirma ahora la relación build-version correcta.
- Se guardaron notas “What to Test” para es-ES (`7d0d42c1-e7c5-4545-861f-1914389e0af9`) y en-US (`5164b807-e8c2-4e07-8b72-743c6843012b`). Validación posterior `asc validate testflight`: **0 errores, 0 avisos, 0 bloqueos**.
- Validación posterior de envío `asc validate --strict --ipa ...`: **0 errores, 0 avisos, 0 bloqueos**; siguen dos datos informativos: App Privacy no verificable mediante la API pública y liberación manual.
- El build está asignado al grupo interno `Shield Internal` (relación explícita confirmada por ASC); el grupo cuenta con una persona existente en estado `INSTALLED`. El estado interno pasó a `IN_BETA_TESTING`. `autoNotifyEnabled=true`; la asignación pudo activar una notificación, aunque ASC no devuelve evidencia de entrega del mensaje. No se invitó a nuevas personas, no se envió a Beta App Review ni a App Review y no se publicó.
- Las creatividades ocupan cuatro grupos autorizados de App Asset Library; se conservaron los otros grupos. Detalles en `16_ASC_SCREENSHOT_UPLOAD_REPORT.md`.
- StoreKit Sandbox/TestFlight real no se ejecutó: faltan compra y restore verificables, pending, cancelación, reembolso/revocación, grace/retry y renovación para mensual, anual y vitalicio. ASC muestra un tester Sandbox existente en territorio ESP (sin exponer su identidad); no se pudo operar su sesión desde este entorno. El pase local de offering no sustituye estas pruebas.
- La sesión de RevenueCat confirmó el offering `default`, el entitlement `MaskID Pro`, las asociaciones de los SKU y que no hay ninguna oferta activa en el producto anual. Su `trial_duration=P1W` es metadata residual; el estado de App Store devuelve cero ofertas introductorias. Ver `13_ASC_REVENUECAT_RECONCILIATION.md`.
- Legal, App Privacy, E2E de expiración durante edición/captura y pase físico de accesibilidad siguen pendientes. Ver `00_RELEASE_EXECUTIVE.md` y `17_OWNER_ACTIONS.md`.

**Estado:** archive, IPA, upload, processing, asociación build-version y validaciones automatizadas completos. El build está distribuido al grupo interno `Shield Internal`; no se ha enviado a Beta App Review ni a App Review ni se ha publicado.
