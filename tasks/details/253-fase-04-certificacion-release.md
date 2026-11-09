# 253-fase-04-certificacion-release

- Number: 253
- Slug: fase-04-certificacion-release

## Resultado

- Release candidato local: `1.1.7` / `1172026110801` = versión sin puntos `117` + fecha Europe/Madrid `20261108` + consecutivo `01`.
- Rama local: `release/1.1.7-20261108`; base HEAD `095776b`. La versión/build están alineadas en app y extensiones.
- Estado release: `BLOCKED`; sin P0 observados, quedan bloqueos P1 comerciales, legales y ASC detallados en `Docs/release-cycle/04_RELEASE/00_RELEASE_EXECUTIVE.md` y `02_RELEASE_QUALITY_MATRIX.md`.

## Evidencia local

- Suite final: **236 PASS, 7 SKIP, 0 FAIL**, cero runtime warnings; `.asc/artifacts/MaskID-1.1.7-1172026110801-final-tests.xcresult`. Incluye UI, políticas de acceso/migración, persistencia local, seguridad, exportación, Dynamic Type AX5 y controles de tema. Los siete skips están explicados en el XCResult y `03_QA_TEST_MATRIX.csv`.
- La navegación de Settings tuvo una regresión reproducible; el helper de scroll se ajustó solo para la lista raíz. Focalizados Settings/editor/exportación: 5/5 PASS; suite posterior: PASS.
- Capturas base-theme: test `testASOCaptureScreensUseBaseThemeInBothStoreLocales` PASS en iPhone 18 Pro Max y iPad Pro 13″. 16 PNG auténticos es-ES/en-US, sin edición, tema MaskID Original, fixtures sintéticos; tamaños/hashes coinciden con `11_SCREENSHOTS_AND_PREVIEWS/final/1.1.7/SCREENSHOT_SET_MANIFEST.json`. Home queda fuera por solape visible entre el encabezado y la barra flotante (P2).
- Metadatos JSON es-ES/en-US: `python3 scripts/validate_release_metadata.py metadata --version 1.1.7` PASS en longitud/codificación. `asc metadata validate --dir metadata --subscription-app --output table`: 32 archivos, 0 errores y 0 warnings.
- Archive Release: `.asc/artifacts/MaskID-1.1.7-1172026110801-final.xcarchive`, 144 MB. IPA local: `.asc/artifacts/MaskID-1.1.7-1172026110801-final.ipa`, 55,232,054 bytes, SHA-256 `027804d9d27daf93e04e8f0869eb6f07b6db4d247081a4cd3734ab9284d437e9`.
- Archive e IPA validan firma strict. IPA exportado con método `app-store-connect`, profile de tienda correcto, `get-task-allow=false`; app/Share/Widget confirman bundle/version/build y dSYMs disponibles. No se envió a ASC.
- No se observaron diagnósticos de API deprecada en build/test. Xcode 27.2, iOS SDK 27.2; el aviso App Intents fue ausencia de framework en extracción metadata, no deprecación.

## Límites y pendientes

- No hubo commit, tag, push, upload, escritura ASC/RevenueCat, TestFlight ni publicación. Worktree mezcla las fases previas y el path no rastreado `-` permanece sin modificar; screenshots y artefactos locales se preservan.
- StoreKit Sandbox compra/restore/refund/grace/renewal: NOT RUN. RevenueCat read token revocado para catálogo completo; `default` aún contiene `trial_duration:P1W`, mientras estado vivo de ASC reportó cero ofertas introductorias. No hubo cambios RC.
- App Privacy ASC, revisión jurídica, expiración UI con editor/captura abiertos, VoiceOver/Control por voz/Switch Control en hardware y CloudKit multi-dispositivo permanecen pendientes.
- ASC aún no aceptó el build `1172026110801` de 13 cifras. No se subió porque la aceptación del formato no se demuestra con el archive local.
- Release y handoff: `Docs/release-cycle/04_RELEASE/RELEASE_MANIFEST.json`, `FASE_04_HANDOFF.json` y reports enumerados en ese directorio.
- No se ejecutó limpieza de temporales, sidecars o caches. Requiere confirmación explícita del propietario según `AGENTS.md`.
