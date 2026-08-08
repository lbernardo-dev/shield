# Tasks

## Task IDs

1. editor-ocr-ux-hardening
   Id: 1-editor-ocr-ux-hardening
   Scope: Auditar y corregir OCR, filtros, refresco y UX del editor (save, bloqueo, header, controles)
   Files: Shield/ViewModels/AppState.swift,Shield/ViewModels/EditorViewModel.swift,Shield/Views/Editor/EditorView.swift,Shield/Views/Editor/DocumentCanvas.swift,Shield/Views/Capture/CaptureView.swift
   Note: Completed OCR/editor UX hardening; build_sim ok
   Detail: tasks/details/1-editor-ocr-ux-hardening.md
   Claimed by: CODEX
   Claimed at: 2026-05-03T14:55:21Z
   Done by: CODEX
   Done at: 2026-05-03T15:04:58Z

2. integral-rebuild
   Id: 2-integral-rebuild
   Scope: Auditoria integral de producto, arquitectura y viabilidad; plan de reconstruccion por fases con validacion tecnica
   Files: Docs/*.md,Shield/**/*.swift,Shield.xcodeproj/project.pbxproj
   Note: Integral audit completed; rebuild blueprint added; root shell and OAuth anchor hardened; build_sim ok
   Detail: tasks/details/2-integral-rebuild.md
   Claimed by: CODEX
   Claimed at: 2026-05-06T13:35:30Z
   Done by: CODEX
   Done at: 2026-05-06T13:40:09Z

3. tool-flows-hardening
   Id: 3-tool-flows-hardening
   Scope: Auditar y corregir cada herramienta de captura, OCR, editor, exportacion, ajustes y boveda con validacion funcional en simulador
   Files: Shield/ViewModels/**/*.swift,Shield/Views/**/*.swift,Shield/Theme/**/*.swift,Shield/**/*.swift
   Note: Subsumido y completado por el programa profesional 4-16: captura/importación, OCR, editor, exportación, ajustes, bóveda y simulador validados; release gate y 26 ejecuciones/18 tests lógicos verdes.
   Detail: tasks/details/3-tool-flows-hardening.md
   Claimed by: CODEX
   Claimed at: 2026-05-07T06:00:21Z
   Done by: CODEX
   Done at: 2026-07-13T07:12:11Z

4. audit-profesional-shield
   Id: 4-audit-profesional-shield
   Scope: Auditar arquitectura, flujos de importación/captura/escaneo, editor y máscaras, OCR, PDF, persistencia, seguridad, rendimiento, accesibilidad, pruebas y UX; producir diagnóstico y roadmap profesional priorizado
   Files: tasks/TASKS.md,tasks/details/*,Shield/**,ShieldTests/**,ShieldUITests/**,Shield.xcodeproj/**
   Note: Auditoría profesional completada; informe y roadmap 5-16 creados. Build ordinario OK; build estricto falla por 4 errores de concurrencia; no hay tests
   Detail: tasks/details/4-audit-profesional-shield.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T05:41:46Z
   Done by: CODEX
   Done at: 2026-07-13T05:52:43Z

5. release-baseline-concurrency
   Id: 5-release-baseline-concurrency
   Scope: Restaurar el build estricto, eliminar warnings de rutas antiguas y crear targets unit/UI con CI reproducible
   Files: Shield.xcodeproj/**,Shield/**/*.swift,ShieldTests/**,ShieldUITests/**,Makefile,scripts/**
   Note: Baseline completada: build estricto Swift concurrency verde, targets Swift Testing y XCUITest creados, agent-verify correcto
   Detail: tasks/details/5-release-baseline-concurrency.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T05:55:57Z
   Done by: CODEX
   Done at: 2026-07-13T06:04:40Z

6. secure-export-verifier
   Id: 6-secure-export-verifier
   Scope: Sustituir overlays PDF inseguros por exportación segura, sanitización, verificación adversarial e informe de salida
   Files: Shield/Views/Editor/ExportServices.swift,Shield/Views/Editor/ExportSheetView.swift,Shield/Export/**,ShieldTests/Export/**
   Note: Exportación PDF original eliminada; raster seguro, protección completa, VerificationReport y rechazo por texto extraíble, anotaciones, metadatos, páginas u OCR residual; tests verdes
   Detail: tasks/details/6-secure-export-verifier.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T06:04:40Z
   Done by: CODEX
   Done at: 2026-07-13T06:14:07Z

7. document-model-nondestructive
   Id: 7-document-model-nondestructive
   Scope: Introducir proyecto/página versionados, asset original inmutable, transforms canónicos, persistencia transaccional y migraciones
   Files: Shield/Models/**,Shield/Storage/**,Shield/ViewModels/AppState.swift,ShieldTests/Storage/**
   Note: Modelo schema v2 con originales inmutables, caché renderizada y transformaciones canónicas por página; migración v1 cubierta por Swift Testing; build estricto y suite completa OK.
   Detail: tasks/details/7-document-model-nondestructive.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T06:14:07Z
   Done by: CODEX
   Done at: 2026-07-13T06:21:22Z

8. import-processing-pipeline
   Id: 8-import-processing-pipeline
   Scope: Crear importación streaming y cancelable con downsampling, límites, batch real, progreso, limpieza y errores tipados
   Files: Shield/Views/Capture/**,Shield/Import/**,Shield/Storage/**,ShieldTests/Import/**
   Note: Pipeline único cancelable con progreso; downsampling ImageIO, límites 200 MB/50 páginas/2048 px/256 MB, PDF por página, HTTPS mediante download, rollback y errores tipados; tests y suite verdes.
   Detail: tasks/details/8-import-processing-pipeline.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T06:25:24Z
   Done by: CODEX
   Done at: 2026-07-13T06:31:44Z

9. ocr-entity-evaluation
   Id: 9-ocr-entity-evaluation
   Scope: Modelar OCR/entidades por página con evidencia y confianza, corpus evaluable, Vision moderno, validadores y plantillas semánticas
   Files: Shield/Views/Capture/CaptureOCRServices.swift,Shield/OCR/**,Shield/Models/**,ShieldTests/OCR/**
   Note: Vision moderno async con confianza; observaciones/entidades por página y vínculos de evidencia; umbral 0,55; eliminación total de grid fallback en importados; evaluador P/R/F1 y tests verdes.
   Detail: tasks/details/9-ocr-entity-evaluation.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T06:31:44Z
   Done by: CODEX
   Done at: 2026-07-13T06:36:27Z

10. editor-geometry-history
   Id: 10-editor-geometry-history
   Scope: Rehacer editor con caché de preview, geometría canónica, zoom/pan, selección fiable y undo/redo por comandos
   Files: Shield/Views/Editor/**,Shield/ViewModels/EditorViewModel.swift,Shield/Rendering/**,ShieldTests/Editor/**
   Note: Geometría normalizada central, gestos move/resize como transacciones undo/redo, zoom 100–400 %, caché de imagen en vista; build estricto y suite completa OK.
   Detail: tasks/details/10-editor-geometry-history.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T06:21:22Z
   Done by: CODEX
   Done at: 2026-07-13T06:25:24Z

11. privacy-vault-hardening
   Id: 11-privacy-vault-hardening
   Scope: Definir threat model y reforzar claves/PIN, bóveda, snapshots, temporales, telemetría local, borrado y PDFs protegidos
   Files: Shield/Security/**,Shield/ViewModels/AppState.swift,Shield/ViewModels/AppSessionCoordinator.swift,Shield/Views/Vault/**,ShieldTests/Security/**
   Note: Privacidad reforzada: PIN salado e iterado + migración legacy y lockout en Keychain; claves separadas Biblioteca/Bóveda y relocalización transaccional; cifrado de telemetría local; privacy shield; limpieza de exportes temporales; threat model; build estricto y suite completa OK.
   Detail: tasks/details/11-privacy-vault-hardening.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T06:36:27Z
   Done by: CODEX
   Done at: 2026-07-13T06:42:59Z

12. accessibility-ipad
   Id: 12-accessibility-ipad
   Scope: Hacer universal iPhone/iPad y completar VoiceOver, Dynamic Type, contraste, Reduce Motion, teclado, trackpad y alternativas a gestos
   Files: Shield.xcodeproj/**,Shield/Views/**,Shield/Theme/**,ShieldUITests/Accessibility/**
   Note: Target universal iPhone/iPad, orientaciones y layout regular con sidebar; anchura de contenido; Reduce Motion; controles base accesibles; máscaras ajustables por VoiceOver; teclado/zoom/páginas; gate XCUITest de hit regions, descripciones, recorte y traits; contraste onboarding corregido.
   Detail: tasks/details/12-accessibility-ipad.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T06:43:12Z
   Done by: CODEX
   Done at: 2026-07-13T06:58:42Z

13. apple-workflows
   Id: 13-apple-workflows
   Scope: Añadir Share Extension, App Intents, drag/drop, multiwindow y Quick Look con intercambio seguro mediante App Group
   Files: ShieldShare/**,ShieldIntents/**,Shield/App/**,Shield.xcodeproj/**,ShieldUITests/Extensions/**
   Note: Flujos Apple integrados: App Intents/Shortcuts para captura y bóveda autenticada, apertura segura de archivos desde Files/Share Sheet, navegación universal/teclado; metadatos AppIntents compilan sin warning; build estricto OK.
   Detail: tasks/details/13-apple-workflows.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T06:58:42Z
   Done by: CODEX
   Done at: 2026-07-13T07:00:05Z

14. cloud-integrations-correctness
   Id: 14-cloud-integrations-correctness
   Scope: Retirar OAuth de demostración y decidir/implementar correctamente Archivos e iCloud con consentimiento, minimización, reconciliación y borrado
   Files: Shield/Cloud/**,Shield/Views/Settings/**,Shield/Views/Capture/**,ShieldTests/Cloud/**
   Note: OAuth demo/implicit flow y tokens propios eliminados; proveedores externos pasan por Files security-scoped selection; iCloud sólo con opt-in y metadatos minimizados sin título ni estado de bóveda; build estricto OK.
   Detail: tasks/details/14-cloud-integrations-correctness.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T07:00:05Z
   Done by: CODEX
   Done at: 2026-07-13T07:01:47Z

15. release-observability-compliance
   Id: 15-release-observability-compliance
   Scope: Crear quality gates, performance budgets, crash/hang observability sin PII, privacy report, legal y checklist App Store/TestFlight
   Files: Shield.xcodeproj/**,Shield/Resources/**,Docs/**,scripts/**,.github/**
   Note: Gate de release ejecutable/CI; build+tests estrictos, lint privacy y bloqueo de OAuth demo; budgets de rendimiento, observabilidad sin PII, política factual y checklist TestFlight/App Store.
   Detail: tasks/details/15-release-observability-compliance.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T07:01:47Z
   Done by: CODEX
   Done at: 2026-07-13T07:02:41Z

16. product-positioning-monetization
   Id: 16-product-positioning-monetization
   Scope: Unificar Shield/GhostDoc, redefinir Free/Pro, paywall, pricing, onboarding y mensajes alrededor de redacción verificada
   Files: Shield/Premium/**,Shield/Views/Paywall/**,Shield/Views/Onboarding/**,Shield/Localization/**,Docs/**
   Note: Marca Shield unificada; Free ofrece bóveda cifrada y exportación verificada ilimitada sin watermark forzado; Pro se posiciona en escala, batch, plantillas, estilos e iCloud; claims y reglas documentados.
   Detail: tasks/details/16-product-positioning-monetization.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T07:02:41Z
   Done by: CODEX
   Done at: 2026-07-13T07:04:07Z

17. release-candidate-closeout
   Id: 17-release-candidate-closeout
   Scope: Cerrar todo lo ejecutable localmente: Share Extension segura, corpus/benchmarks OCR-PDF, seguridad/accesibilidad/rendimiento, documentación, archive y preparación App Store
   Files: Shield.xcodeproj Shield ShareExtension ShieldTests ShieldUITests scripts Docs tasks
   Note: Cierre local completo: Share Extension cifrada, OCR PII validado, MetricKit local, cumplimiento/legal, portal Apple preparado, 25 pruebas lógicas/33 ejecuciones + UI, análisis estático y preflight remoto OK. Archive bloqueado únicamente por asociación web del App Group y cuenta Xcode; documentado.
   Detail: tasks/details/17-release-candidate-closeout.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T07:24:54Z
   Done by: CODEX
   Done at: 2026-07-13T07:47:41Z

18. current-release-state
   Id: 18-current-release-state
   Scope: Auditar estado actual local, firma Apple, archive y App Store Connect sin publicar
   Files: Shield.xcodeproj Shield ShareExtension Docs tasks
   Note: Estado auditado: auth sana; release gate 25 tests/33 executions + UI OK; Archive Release y export App Store Distribution OK; entitlements App Group/Keychain/CloudKit verificados. Pendientes: ficha ASC inexistente, productos/metadata/TestFlight, perfiles manuales antiguos INVALID, StoreKit fixture incluido en IPA, decisión mínimo iOS 26.
   Detail: tasks/details/18-current-release-state.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T10:42:27Z
   Done by: CODEX
   Done at: 2026-07-13T10:45:39Z

19. release-action-execution
   Id: 19-release-action-execution
   Scope: Ejecutar correcciones locales, compatibilidad, calidad, firma y preparación App Store del plan aprobado
   Files: Shield.xcodeproj Shield ShareExtension ShieldTests ShieldUITests scripts Docs .github tasks
   Note: Trabajo local completado: iOS 18, release gate 28/28, UI audit iOS 18/26, analyze, Archive/IPA build 2, auditoría, preflight remoto y screenshots ES/EN. Pendiente externo: login App Store Connect, creación de ficha/IAP, upload/TestFlight y pruebas físicas.
   Detail: tasks/details/19-release-action-execution.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T10:48:31Z
   Done by: CODEX
   Done at: 2026-07-13T11:16:16Z

20. app-store-connect-setup
   Id: 20-app-store-connect-setup
   Scope: Crear ficha de Shield, configurar metadatos, disponibilidad, IAP y preparar TestFlight mediante ASC
   Files: Docs/APP_STORE_METADATA_DRAFT.md,.asc/screenshots,.asc/artifacts/Shield-1.0-2.ipa
   Note: Ficha ASC completa: versión 1.0.0/build 100202607131, metadata/capturas, disponibilidad 175 territorios, privacidad publicada, productos READY_TO_SUBMIT, TestFlight interno y contactos de revisión; validaciones App Store/TestFlight sin bloqueos. No enviado a revisión.
   Detail: tasks/details/20-app-store-connect-setup.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T11:18:51Z
   Done by: CODEX
   Done at: 2026-07-13T11:59:49Z

21. pricing-restructure
   Id: 21-pricing-restructure
   Scope: Sustituir Lifetime por Weekly, fijar Weekly 0.99 EUR, Monthly 2.99 EUR, Annual 29.99 EUR, actualizar paywall/StoreKit/ASC y publicar build TestFlight 100202607132
   Files: Shield/Premium/PremiumManager.swift,Shield/Views/Paywall/PaywallView.swift,Shield/Resources/Shield.storekit,Shield/Localization/Strings/Paywall.xcstrings,ShieldTests,Shield.xcodeproj/project.pbxproj,.asc
   Note: Monetización semanal/mensual/anual aplicada localmente y en ASC; Lifetime eliminado; fallos de Bóveda, Galería e iCloud corregidos; esquema CloudKit Producción desplegado; release gate completo OK; build 1.0.0 (100202607132) VALID, IN_BETA_TESTING, asignada a Shield Internal y vinculada a versión 1.0.0. Sin envío a revisión.
   Detail: tasks/details/21-pricing-restructure.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T12:19:11Z
   Done by: CODEX
   Done at: 2026-07-13T12:52:23Z

22. external-storage-files-flow
   Id: 22-external-storage-files-flow
   Scope: Corregir los botones de Google Drive, Dropbox y OneDrive para abrir un flujo funcional mediante el selector nativo de Archivos, eliminar estados de conexión ficticios y añadir cobertura de regresión.
   Files: Shield/Cloud/ExternalStorageManager.swift,Shield/Views/Home/HomeView.swift,Shield/Localization/Strings/Common.xcstrings,Shield/Localization/Strings/Home.xcstrings,ShieldTests
   Note: Corregidos botones inertes: Inicio y selector cloud abren UIDocumentPicker/Archivos; eliminados estados OAuth simulados; añadidas instrucciones ES/EN para habilitar proveedores. Build Debug iOS Simulator OK. Suite ShieldTests: resto pasa, persisten fallos ajenos en SecurityPrivacyTests.encryptedStorageUsesSeparateKeyDomains y pinLifecycle.
   Detail: tasks/details/22-external-storage-files-flow.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T12:41:05Z
   Done by: CODEX
   Done at: 2026-07-13T12:44:50Z

23. aso-screenshot-set
   Id: 23-aso-screenshot-set
   Scope: Diseñar, capturar, validar y cargar 10 screenshots ASO en español y 10 en inglés para la ficha App Store 1.0.0
   Files: .asc/screenshots,ShieldUITests,scripts,Docs/APP_STORE_METADATA_DRAFT.md
   Note: 20 capturas ASO creadas (10 ES + 10 EN), 1320x2868, interfaz real y datos sintéticos; validación local 0 errores/avisos; juegos iPhone 6.9 reemplazados en ASC, 20 assets COMPLETE y iPad preservado; release gate completo OK; sin envío a revisión.
   Detail: tasks/details/23-aso-screenshot-set.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T12:53:36Z
   Done by: CODEX
   Done at: 2026-07-13T13:08:57Z

24. top-header-safe-area
   Id: 24-top-header-safe-area
   Scope: Auditar y corregir cabeceras desplazadas por suma duplicada del safe area superior en vistas SwiftUI, con protección de regresión.
   Files: Shield/Theme/ShieldTheme.swift,Shield/Views/Capture/CaptureMenuViews.swift,Shield/Views/Onboarding/OnboardingFlowView.swift,ShieldTests
   Note: Eliminada la doble suma de safeAreaInsets.top en Captura y Onboarding; padding superior centralizado en tokens fijos para contenedores que ya respetan safe area. Auditoría del resto de cabeceras sin más duplicados. Build Debug iOS Simulator OK; git diff --check OK.
   Detail: tasks/details/24-top-header-safe-area.md
   Claimed by: CODEX
   Claimed at: 2026-07-13T12:54:46Z
   Done by: CODEX
   Done at: 2026-07-13T12:56:09Z

25. camera-permission-onboarding
   Id: 25-camera-permission-onboarding
   Scope: Adaptar el onboarding de permiso de camara al patron animado del tutorial, crear arte propio de Shield y manejar todos los estados de autorizacion
   Files: Shield/Views/Onboarding/OnboardingSteps.swift,Shield/Localization/Strings/Onboarding.xcstrings,Shield/Resources/Assets.xcassets/OnboardingCamera.imageset/**,ShieldTests/**
   Note: Implemented tutorial-inspired camera permission onboarding with generated Shield artwork, keyframe/scan animation, Reduce Motion and VoiceOver support, full authorization-state handling and Settings recovery. Strict build and full test suite succeeded; simulator visual and native permission prompt verified.
   Detail: tasks/details/25-camera-permission-onboarding.md
   Claimed by: CODEX
   Claimed at: 2026-07-16T07:02:03Z
   Done by: CODEX
   Done at: 2026-07-16T07:13:48Z

26. camera-permission-exact-rebuild
   Id: 26-camera-permission-exact-rebuild
   Scope: Reconstruir la pantalla de permiso de camara replicando con precision la implementacion visual y de keyframes del tutorial, y sustituir el arte por una fotografia coherente sin efectos de escaner
   Files: Shield/Views/Onboarding/OnboardingSteps.swift,Shield/Localization/Strings/Onboarding.xcstrings,Shield/Resources/Assets.xcassets/OnboardingCamera.imageset/**
   Note: Rebuilt from downloaded 4K tutorial: exact phone ratio and keyframe timing, 3D pan animation, Dynamic Island, camera shutter UI, brand-aligned panorama, permission/settings states. Verified iOS Simulator build, live animation screenshots, system camera prompt, and denied state.
   Detail: tasks/details/26-camera-permission-exact-rebuild.md
   Claimed by: CODEX
   Claimed at: 2026-07-16T07:28:17Z
   Done by: CODEX
   Done at: 2026-07-16T07:40:54Z

27. onboarding-professional-audit
   Id: 27-onboarding-professional-audit
   Scope: Audit and implement a professional, value-first, interactive onboarding and post-value paywall
   Files: Shield/Views/Onboarding,Shield/ViewModels/OnboardingState.swift,Shield/Services,Shield/Localization/Strings/Onboarding.xcstrings,Shield/Resources,Shield.xcodeproj
   Note: Professional value-first onboarding reduced to 6 steps; Back/progress accessibility, interactive demo, camera permission race fix, haptics/motion/analytics, post-value paywall, StoreKit monthly+annual+lifetime, ASC lifetime READY_TO_SUBMIT; build and ShieldTests pass.
   Detail: tasks/details/27-onboarding-professional-audit.md
   Claimed by: CODEX
   Claimed at: 2026-07-16T07:45:55Z
   Done by: CODEX
   Done at: 2026-07-16T08:28:34Z

28. lifetime-price-49-99
   Id: 28-lifetime-price-49-99
   Scope: Change lifetime pricing to 49.99 in StoreKit and App Store Connect; recalculate paywall savings dynamically
   Files: Shield/Resources/Shield.storekit,Shield/Views/Paywall,Shield/Views/Onboarding,Shield/Premium,ShieldTests
   Note: Lifetime changed to EUR 49.99 locally and in ASC; annual savings now dynamically computes 16% vs monthly, lifetime 17% vs two annual years; localized labels added; targeted catalog/savings tests pass.
   Detail: tasks/details/28-lifetime-price-49-99.md
   Claimed by: CODEX
   Claimed at: 2026-07-16T08:31:04Z
   Done by: CODEX
   Done at: 2026-07-16T08:34:43Z

29. settings-information-architecture
   Id: 29-settings-information-architecture
   Scope: Rebuild Shield settings with summary card, grouped subviews, feedback, FAQ, About, legal/support content, Apple review flow, footer, and complete English/Spanish localization
   Files: Shield/Views/Settings/SettingsView.swift, Shield/Views/Settings/SettingsDestinationViews.swift, Shield/Localization/Strings/Settings.xcstrings, Docs/legal
   Note: Rebuilt settings IA with summary and Pro cards, navigable preferences/security/iCloud/export subviews, feedback + Apple review flow, About/What's New/privacy/terms/subscription/support/FAQ, bilingual EN/ES catalogs, and publication-ready legal drafts. Strict build and full test suite succeeded; final support email, legal identity/address/jurisdiction, and public URLs remain intentionally configurable.
   Detail: tasks/details/29-settings-information-architecture.md
   Claimed by: CODEX
   Claimed at: 2026-07-16T09:10:23Z
   Done by: CODEX
   Done at: 2026-07-16T09:32:53Z

30. configure-shield-support-email
   Id: 30-configure-shield-support-email
   Scope: Configure the final Shield support/privacy email in feedback and legal drafts
   Files: Shield/Views/Settings/SettingsView.swift, Docs/legal/privacy.html, Docs/legal/terms.html, Docs/legal/subscription-terms.html
   Note: Configured romerodev.app+shield@gmail.com for feedback mail composer/mailto fallback and as the bilingual privacy/support contact in the app catalog and legal drafts; strict build succeeded.
   Detail: tasks/details/30-configure-shield-support-email.md
   Claimed by: CODEX
   Claimed at: 2026-07-16T09:43:20Z
   Done by: CODEX
   Done at: 2026-07-16T09:44:32Z

31. connect-settings-public-urls
   Id: 31-connect-settings-public-urls
   Scope: Connect localized Shield public pages to every Settings destination, add compatibility fallbacks, and align App Store metadata URLs
   Files: Shield/Views/Settings/SettingsDestinationViews.swift, Shield/Localization/Strings/SettingsInfo.xcstrings, metadata/**/*.json, Docs/PASOS_MANUALES.md
   Note: Connected localized public pages in Settings legal/info/support/FAQ destinations, onboarding paywall, and main paywall; added compatibility fallbacks; updated EN/ES App Store metadata and release docs; verified all 18 URLs return HTTP 200; strict build and full tests including URL mapping tests succeeded.
   Detail: tasks/details/31-connect-settings-public-urls.md
   Claimed by: CODEX
   Claimed at: 2026-07-16T09:58:23Z
   Done by: CODEX
   Done at: 2026-07-16T10:08:13Z

32. app-audit-professional-readiness
   Id: 32-app-audit-professional-readiness
   Scope: Auditoría integral de código, UX, rendimiento, accesibilidad, privacidad, seguridad y preparación App Store Connect; evaluar widgets, App Intents y atajos
   Files: Shield/**,Shield.xcodeproj/**,Configuration/**,scripts/**,tasks/details/**
   Note: Auditoría completada. Informe Docs/AUDITORIA_INTEGRAL_SHIELD_2026-07-16.md; release gate + 40 code tests + 2 UI tests + Release analyze verdes; ASC 0 blockers. P0: URLs ASC redirigen a dominio ajeno, legales con placeholders, export PDF 50 páginas no streaming y RC no trazable.
   Detail: tasks/details/32-app-audit-professional-readiness.md
   Claimed by: CODEX
   Claimed at: 2026-07-16T10:18:09Z
   Done by: CODEX
   Done at: 2026-07-16T10:35:46Z

33. release-remediation
   Id: 33-release-remediation
   Scope: Resolve all audit P0/P1 findings: release URLs/legal/preflight, streaming export, accessibility/localization/App Intents, CloudKit semantics, tests, release provenance and ASC metadata readiness
   Files: Shield/**, ShareExtension/**, ShieldTests/**, ShieldUITests/**, scripts/**, metadata/**, Docs/**, Shield.xcodeproj/**
   Note: Remediación integral completada: legales y URLs ASC, PDF streaming 50 páginas, App Intents ES/EN, accesibilidad 8 escenas ES/EN, CloudKit paginado/limpieza, metadata ASC aplicada. release_gate, analyze Release, preflight remoto y metadata validate verdes. Pendientes externos documentados: commit/tag limpio del árbol preexistente, dispositivo físico/App Privacy y envío.
   Detail: tasks/details/33-release-remediation.md
   Claimed by: CODEX
   Claimed at: 2026-07-16T10:40:26Z
   Done by: CODEX
   Done at: 2026-07-16T11:41:24Z

34. release-candidate-upload
   Id: 34-release-candidate-upload
   Scope: Consolidar RC 1.0.0, archive/IPA, auditoría, upload/TestFlight y staging ASC sin omitir validaciones
   Files: Shield.xcodeproj Shield ShareExtension ShieldTests ShieldUITests metadata scripts Docs
   Note: Build 100202607171 VALID y enlazado a 1.0.0; 0 bloqueos; no enviado a revision
   Detail: tasks/details/34-release-candidate-upload.md
   Claimed by: CODEX
   Claimed at: 2026-07-16T11:44:33Z
   Done by: CODEX
   Done at: 2026-07-17T03:36:12Z

35. interaction-navigation-audit
   Id: 35-interaction-navigation-audit
   Scope: Auditar y corregir botones de retroceso, envío de evacuación y demás acciones táctiles que requieran pulsación larga
   Files: Shield/Views Shield/App ShieldUITests ShieldTests
   Note: Eliminados LongPressGesture y DragGesture(minimumDistance: 0) globales que competían con botones; feedback crea mailto seguro y cae a soporte web; añadidos tests unitario y UI. Validado ShieldTests completo y regresión UI de toque/atrás/soporte en iOS 18.6 e iOS 26.5.
   Detail: tasks/details/35-interaction-navigation-audit.md
   Claimed by: CODEX
   Claimed at: 2026-07-16T12:04:47Z
   Done by: CODEX
   Done at: 2026-07-16T12:15:09Z

36. real-cloud-navigation
   Id: 36-real-cloud-navigation
   Scope: Corregir todos los botones Volver y sustituir cualquier integración de almacenamiento simulada por flujos reales, completos y verificables
   Files: Shield/ ShieldTests/ ShieldUITests/
   Note: Navegación real y retorno desde destinos completados; pruebas unitarias y UI focalizada superadas; incluido en build TestFlight interno 100202607195.
   Detail: tasks/details/36-real-cloud-navigation.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T14:44:38Z
   Done by: CODEX
   Done at: 2026-07-19T15:30:22Z

37. tab-bar-layout-and-size
   Id: 37-tab-bar-layout-and-size
   Scope: UI
   Files: Shield/Views/Components/TabBar.swift,Shield/App/ContentView.swift
   Note: Fixed footer tab bar height, lowered position, and increased scan button size to 72x72; build succeeds
   Detail: tasks/details/37-tab-bar-layout-and-size.md
   Claimed by: CODEX
   Claimed at: 2026-07-17T05:41:12Z
   Done by: CODEX
   Done at: 2026-07-17T05:57:13Z

38. tab-bar-height-reduction
   Id: 38-tab-bar-height-reduction
   Scope: UI
   Files: Shield/Views/Components/TabBar.swift
   Note: Tab bar fitted cleanly to bottom with ignoresSafeArea on safeAreaInset parent. Buttons padded to 16pt (safe area) / 6pt (non-safe area) to reduce height. UI tests updated and verified.
   Detail: tasks/details/38-tab-bar-height-reduction.md
   Claimed by: CODEX
   Claimed at: 2026-07-17T06:00:51Z
   Done by: CODEX
   Done at: 2026-07-17T06:20:13Z

39. paywall-ux-pricing-cards
   Id: 39-paywall-ux-pricing-cards
   Scope: UI
   Files: Shield/Views/Paywall/PaywallView.swift,Shield/Views/Onboarding/OnboardingSteps.swift
   Note: Redesigned PlanRow with spacious vertical stacked layout, separate badges row, custom radio selection animation, floating recommended badge for Annual plan, and increased layout spacing. Verified build and tests.
   Detail: tasks/details/39-paywall-ux-pricing-cards.md
   Claimed by: CODEX
   Claimed at: 2026-07-17T06:18:43Z
   Done by: CODEX
   Done at: 2026-07-17T06:19:38Z

40. cloud-cancellation-ux
   Id: 40-cloud-cancellation-ux
   Scope: UX
   Files: Shield/Cloud/ExternalStorageManager.swift,Shield/Localization/Strings/Common.xcstrings
   Note: Implemented provider-branded animated cancellation/recovery view, localized friendly failures, Reduce Motion support; Debug simulator build passed and both recovery actions manually verified on iPhone 16 iOS 18.6
   Detail: tasks/details/40-cloud-cancellation-ux.md
   Claimed by: CODEX
   Claimed at: 2026-07-17T06:25:53Z
   Done by: CODEX
   Done at: 2026-07-17T06:30:33Z

41. aso-app-store-connect
   Id: 41-aso-app-store-connect
   Scope: Investigación profunda de mercado, ASO profesional EN/ES y configuración integral de App Store Connect
   Files: Docs/ APP_STORE_METADATA_DRAFT.md metadata/ screenshots/ tasks/
   Note: MaskID rebrand complete: new pixelated-face icon, in-app EN/ES identity and cyan/navy system, market/ASO strategy, App Store metadata and 20 screenshots applied, subscriptions/IAP renamed; simulator build passed. App review submission intentionally not triggered.
   Detail: tasks/details/41-aso-app-store-connect.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T06:23:35Z
   Done by: CODEX
   Done at: 2026-07-19T06:49:58Z

42. 30-day-social-campaign
   Id: 42-30-day-social-campaign
   Scope: Create a bilingual 30-day, platform-organized social media campaign using only verified MaskID features and authentic simulator captures
   Files: Marketing/30-Day-Social-Campaign/ tasks/
   Note: Created bilingual 30-day campaign for Instagram, LinkedIn, X, Facebook and TikTok: 300 publish-ready post files, 156 1080x1350 assets derived only from 20 authentic simulator captures, calendar, strategy, provenance and claim guardrails; automated validation passed
   Detail: tasks/details/42-30-day-social-campaign.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T08:12:48Z
   Done by: CODEX
   Done at: 2026-07-19T08:18:22Z

43. campaign-feature-infographics
   Id: 43-campaign-feature-infographics
   Scope: Add multiple bilingual, simulator-based feature infographics to the 30-day social campaign and integrate them into platform schedules
   Files: Marketing/30-Day-Social-Campaign/ scripts/build_30_day_social_campaign.py tasks/
   Note: Added 10 bilingual six-slide feature infographic guides (120 new simulator-based assets), integrated them into selected campaign days across five networks, added 20 platform-copy files and a feature calendar; link, size and X-thread validation passed
   Detail: tasks/details/43-campaign-feature-infographics.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T08:26:35Z
   Done by: CODEX
   Done at: 2026-07-19T08:29:38Z

44. maskid-app-icon
   Id: 44-maskid-app-icon
   Scope: Configurar y verificar MaskID como icono principal de la app
   Files: Shield/MaskID.icon,Shield.xcodeproj/project.pbxproj
   Note: MaskID.icon confirmado como icono principal en Debug y Release; paquete incluido en Resources; build de simulador completado correctamente
   Detail: tasks/details/44-maskid-app-icon.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T09:45:51Z
   Done by: CODEX
   Done at: 2026-07-19T09:46:32Z

45. maskid-complete-asc-rebrand
   Id: 45-maskid-complete-asc-rebrand
   Scope: Auditar y corregir toda la ficha App Store Connect y ASO de MaskID, incluidas categorías, localizaciones, URLs, screenshots e IAP
   Files: metadata/,Docs/,tasks/
   Note: Rebranding ASC completo aplicado: nombres y subtítulos EN/ES orientados a protección de identidad, keywords optimizadas, Utilities/Productivity, notas de review corregidas, paywall screenshots con USD retiradas; metadata validada y sincronizada, 0 errores/bloqueos. Privacidad web pendiente de confirmación por sesión Apple caducada; IAP listos para adjuntar en primer envío.
   Detail: tasks/details/45-maskid-complete-asc-rebrand.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T09:49:11Z
   Done by: CODEX
   Done at: 2026-07-19T09:55:07Z

46. maskid-build-and-app-preview
   Id: 46-maskid-build-and-app-preview
   Scope: Grabar App Preview real en iPhone 16, crear build 100202607191, archivar, subir y enlazar a App Store 1.0.0 sin enviar a revisión
   Files: Shield.xcodeproj/project.pbxproj,.asc/,Docs/,tasks/
   Note: Build 100202607191 aplicado a Shield y ShieldShareExtension; archive e IPA creados; build subido y VALID en App Store Connect; enlazado a la versión 1.0.0; App Preview real de iPhone 16 subido y COMPLETE; validación sin errores bloqueantes; no se creó ni envió submission a revisión.
   Detail: tasks/details/46-maskid-build-and-app-preview.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T10:15:35Z
   Done by: CODEX
   Done at: 2026-07-19T10:30:56Z

47. restore-aso-screenshots-with-preview
   Id: 47-restore-aso-screenshots-with-preview
   Scope: Restaurar las 10 capturas ASO en en-US y es-ES manteniendo el App Preview, verificar convivencia y no enviar a revisión
   Files: .asc/screenshots/aso/final metadata tasks
   Note: Corregido: 10 capturas ASO iPhone 6.7 en orden 01-10 y COMPLETE en en-US y es-ES; App Preview real COMPLETE en ambos locales; sets iPad preservados; no existe submission de revisión.
   Detail: tasks/details/47-restore-aso-screenshots-with-preview.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T11:42:05Z
   Done by: CODEX
   Done at: 2026-07-19T11:47:12Z

48. publish-pending-and-merge-main
   Id: 48-publish-pending-and-merge-main
   Scope: Commit and push all pending repository changes, then merge the release branch into main and push main
   Files: entire repository
   Note: Finished: release branch committed and pushed; clean no-conflict merge prepared into current origin/main. Git diff validation passed; build/tests not rerun for repository integration-only operation.
   Detail: tasks/details/48-publish-pending-and-merge-main.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T13:03:40Z
   Done by: CODEX
   Done at: 2026-07-19T13:04:23Z

49. fix-aso-preview-and-upload-build
   Id: 49-fix-aso-preview-and-upload-build
   Scope: Move EN/ES App Preview from iPhone 6.5-inch to iPhone 6.9-inch, set build 100202607192 for all targets, archive/export/upload, attach to version 1.0.0, and audit submission readiness without submitting
   Files: Shield.xcodeproj/project.pbxproj .asc/app-previews tasks/
   Note: Finished: EN/ES App Preview moved from IPHONE_65 to the App Store 6.9-inch slot (API legacy type IPHONE_67), build 100202607192 committed/pushed, archive and IPA exported, uploaded build 6c8d40ca-e58e-4463-b128-95339dd8fb44 VALID and attached to version 1.0.0. Audit: 0 standard blockers; subscriptions/IAP need first-review inclusion, promotional subscription images recommended, App Privacy web publish state requires manual or renewed-session confirmation. No review submission created.
   Detail: tasks/details/49-fix-aso-preview-and-upload-build.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T13:09:10Z
   Done by: CODEX
   Done at: 2026-07-19T13:16:42Z

50. integrate-revenuecat-custom-paywall
   Id: 50-integrate-revenuecat-custom-paywall
   Scope: Integrate RevenueCat purchases and entitlements while preserving the existing custom SwiftUI paywall
   Files: Shield/Premium/PremiumManager.swift Shield/Views/Paywall/PaywallView.swift Shield/Views/Onboarding/OnboardingSteps.swift Shield/App/ShieldApp.swift Shield/Resources/Info.plist Shield.xcodeproj/project.pbxproj ShieldTests/ tasks/ Docs/
   Note: RevenueCat project/app configured with valid Apple credentials; 3 production products imported and attached to MaskID Pro; SDK 5.81.1 integrated with existing Swift paywalls, purchase/restore/entitlement/trial eligibility; simulator build passes. Unit test runner blocked by local LLDB DebuggerVersionStore error.
   Detail: tasks/details/50-integrate-revenuecat-custom-paywall.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T13:32:05Z
   Done by: CODEX
   Done at: 2026-07-19T13:54:13Z

51. prepare-appstore-1-0-0
   Id: 51-prepare-appstore-1-0-0
   Scope: Increment all target builds, archive/export/upload, attach to App Store version 1.0.0, audit readiness without submitting
   Files: Shield.xcodeproj/project.pbxproj,Shield/Resources/Info.plist,ShareExtension/Info.plist,tasks/TASKS.md,tasks/details
   Note: Build 100202607193 archived, uploaded and attached to 1.0.0; privacy/product metadata audited; review draft READY_FOR_REVIEW with app, group, annual, monthly and lifetime IAP; not submitted.
   Detail: tasks/details/51-prepare-appstore-1-0-0.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T13:57:54Z
   Done by: CODEX
   Done at: 2026-07-19T14:12:35Z

52. verify-revenuecat-production-key
   Id: 52-verify-revenuecat-production-key
   Scope: Verify the submitted Release build embeds the RevenueCat Apple production app key and no Test Store key
   Files: Shield/Resources/Info.plist Shield/Premium/PremiumManager.swift Shield.xcodeproj/
   Note: Verified submitted build 1.0.0 (100202607193), IPA and archive embed Apple platform key appl_cJuegsqbihOvDkhDESnUPrekHTJ; no RevenueCat test_ key and no .storekit fixture embedded. Release config uses this Info.plist. No code change required.
   Detail: tasks/details/52-verify-revenuecat-production-key.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T14:35:55Z
   Done by: CODEX
   Done at: 2026-07-19T14:36:46Z

53. release-regression-audit
   Id: 53-release-regression-audit
   Scope: Auditar y corregir navegación, miniaturas cifradas, identidad MaskID y regresiones; compilar, probar y subir solo a TestFlight sin App Review
   Files: Shield/ ShieldTests/ ShieldUITests/ Shield.xcodeproj/ tasks/
   Note: Correcciones completadas: navegación atrás verificada con UI test de un toque; miniaturas de bóveda corregidas; branding/binario MaskID y recurso de icono antiguo retirado; ShieldTests completos y UI test focalizado superados; build 100202607195 procesado VALID y distribuido solo a TestFlight interno; no enviado a App Review.
   Detail: tasks/details/53-release-regression-audit.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T14:45:50Z
   Done by: CODEX
   Done at: 2026-07-19T15:30:22Z

54. fix-settings-navigation-real-device
   Id: 54-fix-settings-navigation-real-device
   Scope: Reproducir y corregir todos los retornos y navegación interna de Configuración en el binario real
   Files: Shield/Views/Settings ShieldUITests Shield.xcodeproj
   Note: Fixed Settings back navigation and untranslated common_back label. Removed zero-distance global drag gesture. Added UI assertions for physical-coordinate back taps and untranslated key regression. Tests: Settings route UI test passed on iOS 26.5 sim; simulator build passed; Release archive/export succeeded; TestFlight build 100202607196 uploaded VALID and assigned to beta group. Not submitted to App Review.
   Detail: tasks/details/54-fix-settings-navigation-real-device.md
   Claimed by: CODEX
   Claimed at: 2026-07-19T16:17:52Z
   Done by: CODEX
   Done at: 2026-07-20T06:12:09Z

55. fix-lock-screen-icon
   Id: 55-fix-lock-screen-icon
   Scope: Corregir el icono incorrecto en la pantalla bloqueada de autenticación
   Files: Shield/App/ContentView.swift Shield/Assets.xcassets
   Note: Reemplazado el escudo de LockScreenView por MaskIDMark; build Debug generic iOS OK
   Detail: tasks/details/55-fix-lock-screen-icon.md
   Claimed by: CODEX
   Claimed at: 2026-07-20T06:05:59Z
   Done by: CODEX
   Done at: 2026-07-20T06:08:24Z

56. animated-mysterious-splash-view
   Id: 56-animated-mysterious-splash-view
   Scope: Reorganizar y potenciar la vista de Splash para que sea animada y misteriosa, con el icono central más grande y sin el nombre de la app
   Files: Shield/App/ContentView.swift,Shield/Views/Components/SplashView.swift
   Note: Upgraded the Splash View with a larger, animated icon and a mysterious cyber-mask radiating rings theme; verified compilation and tests successfully
   Detail: tasks/details/56-animated-mysterious-splash-view.md
   Claimed by: CODEX
   Claimed at: 2026-07-20T06:09:00Z
   Done by: CODEX
   Done at: 2026-07-20T06:23:21Z

57. firebase-analytics-crashlytics
   Id: 57-firebase-analytics-crashlytics
   Scope: Integrar Firebase Analytics y Crashlytics en la app iOS principal
   Files: Shield/App, Shield.xcodeproj, Shield/Resources
   Note: Integrated Firebase Analytics and Crashlytics via SPM, startup configuration, official local GoogleService-Info.plist, Crashlytics dSYM archive upload, and setup docs. Debug, Release, and device archive builds passed. Full test run had known flaky Settings UI failures; isolated foreground launch passed.
   Detail: tasks/details/57-firebase-analytics-crashlytics.md
   Claimed by: CODEX
   Claimed at: 2026-07-20T11:54:26Z
   Done by: CODEX
   Done at: 2026-07-20T12:13:35Z

58. ui-experience-audit
   Id: 58-ui-experience-audit
   Scope: Auditar y mejorar toda la UI de MaskID: shell, inicio, captura/importación, editor, bóveda, galería, ajustes, onboarding y paywall; corregir flujos, claridad, accesibilidad y fluidez
   Files: Shield/Views/**/*.swift,Shield/App/**/*.swift,Shield/Theme/**/*.swift,Shield/ViewModels/**/*.swift,ShieldUITests/**,tasks/**
   Note: UI audit and remediation completed; Debug iPhone 16 build plus full accessibility suite and focused onboarding/paywall regressions passed
   Detail: tasks/details/58-ui-experience-audit.md
   Claimed by: CODEX
   Claimed at: 2026-07-20T13:23:45Z
   Done by: CODEX
   Done at: 2026-07-20T13:28:46Z

59. ui-functional-validation
   Id: 59-ui-functional-validation
   Scope: Ejecutar validación funcional exhaustiva y reproducible de botones, navegación, flujos y estados UI; ampliar pruebas de regresión donde sea necesario
   Files: Shield/Views/**/*.swift,ShieldUITests/**,tasks/**
   Note: Functional validation completed; full ShieldTests, functional UI routes, full UI/accessibility regression suite passed
   Detail: tasks/details/59-ui-functional-validation.md
   Claimed by: CODEX
   Claimed at: 2026-07-20T13:33:06Z
   Done by: CODEX
   Done at: 2026-07-20T13:37:18Z

60. ui-visual-simulator-walkthrough
   Id: 60-ui-visual-simulator-walkthrough
   Scope: Recorrer visualmente la app en simulador, inspeccionar pantallas y flujos principales mediante interacción directa y documentar hallazgos
   Files: Shield/Views/**/*.swift,ShieldUITests/**,tasks/**
   Note: Visual simulator walkthrough and Home accessibility/navigation regressions completed; no release-blocking visual defects found.
   Detail: tasks/details/60-ui-visual-simulator-walkthrough.md
   Claimed by: CODEX
   Claimed at: 2026-07-20T13:38:50Z
   Done by: CODEX
   Done at: 2026-07-20T15:20:31Z

61. shell-stability-fix
   Id: 61-shell-stability-fix
   Scope: Eliminate recurring launch overlay and restore anchored mobile tab bar
   Files: Shield/App/ContentView.swift,Shield/Views/Components/SplashView.swift
   Note: Removed recurring animated splash behavior, enforce one launch overlay per process, restored the compact-shell bottom-edge treatment. Build passed: AGENT_NAME=CODEX make build. Simulator visual recheck deferred because the foreground device is now running the user's StreakReps app.
   Detail: tasks/details/61-shell-stability-fix.md
   Claimed by: CODEX
   Claimed at: 2026-07-20T13:55:44Z
   Done by: CODEX
   Done at: 2026-07-20T13:56:11Z

62. modal-surface-visual-regression
   Id: 62-modal-surface-visual-regression
   Scope: Audit and correct opaque readability and safe-area behavior for paywall and modal UI surfaces
   Files: Shield/Views/Paywall/PaywallView.swift,Shield/Views/Components/**/*.swift,Shield/Views/**/*.swift
   Note: Removed every glassEffect, GlassEffectContainer, glassProminent and ultraThinMaterial surface from the app. Paywall plan rows, CTA, bottom navigation, home controls, editor zoom, vault lock and PIN pad now use opaque semantic backgrounds. Build passed twice: AGENT_NAME=CODEX make build. Visual simulator recheck pending because user is actively using the simulator with another app.
   Detail: tasks/details/62-modal-surface-visual-regression.md
   Claimed by: CODEX
   Claimed at: 2026-07-20T13:57:04Z
   Done by: CODEX
   Done at: 2026-07-20T14:00:08Z

63. settings-modal-navigation
   Id: 63-settings-modal-navigation
   Scope: Ocultar la barra de navegación inferior en Ajustes y sus destinos; añadir cierre superior alineado al título
   Files: Shield/App/ContentView.swift,Shield/Views/Settings/SettingsView.swift,Shield/Views/Settings/SettingsDestinationViews.swift
   Note: Footer hidden throughout Settings; close control added to root and destinations; Debug build and targeted UI test passed
   Detail: tasks/details/63-settings-modal-navigation.md
   Claimed by: CODEX
   Claimed at: 2026-07-20T14:02:35Z
   Done by: CODEX
   Done at: 2026-07-20T14:05:26Z

64. appstore-submission-readiness
   Id: 64-appstore-submission-readiness
   Scope: Auditar y corregir configuración local, RevenueCat, Firebase y superficie DEBUG para preparar el envío a App Store Review
   Files: Shield.xcodeproj/**,Shield/**,ShieldTests/**,ShieldUITests/**,Docs/**,tasks/**
   Note: Build 100202607202 VALID, App Store version and 4 review items READY_FOR_REVIEW; Firebase/RevenueCat App Privacy published; simulator-only developer controls verified; preflight passed.
   Detail: tasks/details/64-appstore-submission-readiness.md
   Claimed by: CODEX
   Claimed at: 2026-07-20T14:05:45Z
   Done by: CODEX
   Done at: 2026-07-20T15:20:15Z

65. audit-stalled-app-review
   Id: 65-audit-stalled-app-review
   Scope: Auditar estado real de la revisión de MaskID y completar/corregir toda la ficha App Store Connect, incluyendo metadata, build, privacidad, productos, disponibilidad y datos de revisión
   Files: metadata/**,Marketing/AppStore-Connect/**,Docs/**,tasks/**
   Note: Auditoría remota completa: submission WAITING_FOR_REVIEW desde 2026-07-20 15:44 UTC, build VALID, 5 items READY_FOR_REVIEW, metadata EN/ES y URLs correctas, 175 territorios, IAP/subscriptions sin errores ni warnings, cero bloqueos y dry-run sin cambios; no se retiró el envío
   Detail: tasks/details/65-audit-stalled-app-review.md
   Claimed by: CODEX
   Claimed at: 2026-07-26T16:06:34Z
   Done by: CODEX
   Done at: 2026-07-26T16:11:01Z

66. audit-cross-app-rejection-risks
   Id: 66-audit-cross-app-rejection-risks
   Scope: Comparar los cinco motivos de rechazo de StreakReps con MaskID y corregir cualquier riesgo equivalente en el binario enviado o App Store Connect
   Files: Shield/**,Shield.xcodeproj/**,metadata/**,Marketing/AppStore-Connect/**,Docs/**,tasks/**
   Note: Comparados los 5 motivos del rechazo de StreakReps: MaskID no está afectada; age assurance/parental controls false, sin WeatherKit ni audio background, Restore Purchases visible y funcional, imágenes anual/mensual distintas y sin promo lifetime. Notas de App Review reforzadas sin retirar el envío; validaciones strict 0 errores/0 warnings.
   Detail: tasks/details/66-audit-cross-app-rejection-risks.md
   Claimed by: CODEX
   Claimed at: 2026-07-26T16:14:30Z
   Done by: CODEX
   Done at: 2026-07-26T16:17:48Z

67. complete-appstore-connect-production-setup
   Id: 67-complete-appstore-connect-production-setup
   Scope: Audit and complete all App Store Connect, RevenueCat, StoreKit, privacy, accessibility, review and release configuration; rebuild/resubmit only if required
   Files: Shield/**,Shield.xcodeproj/**,.asc/**,Docs/**,tasks/**
   Note: Configuración de producción completada: notificaciones App Store Server y tracking de RevenueCat activados, offering mensual/anual/lifetime corregido, credenciales y entitlement validados, ficha/privacidad/IAP/subscriptions sin errores ni bloqueos, borradores de accesibilidad preparados y regresiones iOS 18.6 superadas. El envío permanece WAITING_FOR_REVIEW; no se canceló porque no requiere otro binario y retirarlo perdería la cola.
   Detail: tasks/details/67-complete-appstore-connect-production-setup.md
   Claimed by: CODEX
   Claimed at: 2026-07-27T06:27:02Z
   Done by: CODEX
   Done at: 2026-07-27T07:01:24Z

68. fase-a-ui-pro-evolucion
   Id: 68-fase-a-ui-pro-evolucion
   Scope: UI de producto profesional: tipografia Dynamic Type, dark mode, localizacion, estados vacios
   Files: Shield/Theme/**,Shield/Views/**,Shield/Localization/**
   Note: Cierre ampliado Fase A:+dark mode preview/surfaces semanticos, label(lang:) respeta idioma (10 modelos + subtree), tests LocalizationLanguageTests, gate OAuth refinado (falso positivo CodingKeys). agent-verify y release gate verdes.
   Detail: tasks/details/68-fase-a-ui-pro-evolucion.md
   Claimed by: CODEX
   Claimed at: 2026-08-08T08:54:32Z
   Done by: CODEX
   Done at: 2026-08-08T09:39:47Z

69. paywall-storekit-fix
   Id: 69-paywall-storekit-fix
   Scope: RevenueCat products empty + paywall resilience
   Files: Shield.xcodeproj/xcshareddata/xcschemes/Shield.xcscheme, Shield/Premium/PremiumManager.swift, Shield/Views/Paywall/PaywallView.swift, Shield/Views/Onboarding/OnboardingSteps.swift, Shield/Localization/Strings/Paywall.xcstrings
   Note: StoreKit config path fixed (LaunchAction+TestAction), paywall error/retry state added, productsLoadFailed + isLoadingProducts published, onboarding iCloud feature row, temp probe removed. Verify: make build green, 3 UI tests pass (camera x2 + paywall dismiss), extension builds
   Detail: tasks/details/69-paywall-storekit-fix.md
   Claimed by: CODEX
   Claimed at: 2026-08-08T14:53:28Z
   Done by: CODEX
   Done at: 2026-08-08T14:53:28Z

70. home-paywall-audit-fixes
   Id: 70-home-paywall-audit-fixes
   Scope: Empty states + pagination + misc audit fixes
   Files: Shield/ViewModels/AppState.swift, Shield/Views/Home/HomeView.swift, Shield/Views/Home/AllDocumentsView.swift, Shield/Models/Redaction.swift, Shield/Share/SharedImportStore.swift, Shield/Localization/Strings/Home.xcstrings
   Note: All above applied. Verify: make build green, app+extension build, UI tests pass
   Detail: tasks/details/70-home-paywall-audit-fixes.md
   Claimed by: CODEX
   Claimed at: 2026-08-08T14:58:59Z
   Done by: CODEX
   Done at: 2026-08-08T14:58:59Z

71. revenuecat-offerings-diagnosis
   Id: 71-revenuecat-offerings-diagnosis
   Scope: Diagnosticar por qué la app no carga los planes de suscripción desde RevenueCat, sin aplicar cambios
   Files: Shield/Premium/PremiumManager.swift Shield/App/ShieldApp.swift Shield.xcodeproj/project.pbxproj Shield/Config/*.xcconfig ShieldTests
   Note: Diagnóstico terminado: el cliente usa products(ids) hardcoded y no RevenueCat Offerings; ASC confirma 2 suscripciones + lifetime APPROVED, validadores sin bloqueos; build Debug y UI paywall test OK. Sin cambios funcionales.
   Detail: tasks/details/71-revenuecat-offerings-diagnosis.md
   Claimed by: CODEX
   Claimed at: 2026-08-08T22:59:53Z
   Done by: CODEX
   Done at: 2026-08-08T23:04:08Z

72. revenuecat-offering-integration
   Id: 72-revenuecat-offering-integration
   Scope: Cargar y comprar planes exclusivamente desde el current Offering de RevenueCat, manteniendo compatibilidad del paywall y pruebas en simulador
   Files: Shield/Premium/PremiumManager.swift Shield/Views/Paywall/PaywallView.swift Shield/Views/Onboarding/OnboardingSteps.swift ShieldTests ShieldUITests
   Note: Offering integration complete: load current.availablePackages, retain/purchase Package, dynamic selection/logging. Debug build, gated live Offering+SKTestSession test, catalog suite, and paywall UI test pass.
   Detail: tasks/details/72-revenuecat-offering-integration.md
   Claimed by: CODEX
   Claimed at: 2026-08-08T23:04:55Z
   Done by: CODEX
   Done at: 2026-08-08T23:22:36Z

73. revenuecat-simulator-error
   Id: 73-revenuecat-simulator-error
   Scope: Investigate persistent simulator paywall error after offering-based RevenueCat integration
   Files: Shield/Premium/PremiumManager.swift Shield/Views/Paywall/PaywallView.swift Shield/Resources/Shield.storekit Shield.xcodeproj/xcshareddata/xcschemes/Shield.xcscheme
   Note: Diagnosed persistent simulator error: RevenueCat offering path is correct; StoreKit local products are unavailable because launched app has no active StoreKit configuration session. Gated SKTestSession integration passes.
   Detail: tasks/details/73-revenuecat-simulator-error.md
   Claimed by: CODEX
   Claimed at: 2026-08-08T23:26:33Z
   Done by: CODEX
   Done at: 2026-08-08T23:29:53Z

74. fix-storekit-scheme-reference
   Id: 74-fix-storekit-scheme-reference
   Scope: Fix shared Xcode scheme StoreKit configuration reference so simulator Run/Test resolves local RevenueCat offering products
   Files: Shield.xcodeproj/xcshareddata/xcschemes/Shield.xcscheme tasks/details
   Note: Fixed shared scheme StoreKit path to ../Shield/Resources/Shield.storekit for Run/Test; build succeeded with /tmp/ShieldStoreKitSchemeFix
   Detail: tasks/details/74-fix-storekit-scheme-reference.md
   Claimed by: CODEX
   Claimed at: 2026-08-08T23:31:37Z
   Done by: CODEX
   Done at: 2026-08-08T23:32:57Z

