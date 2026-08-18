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

75. splash-lottie-identidad
   Id: 75-splash-lottie-identidad
   Scope: Integrar MaskID_IdentityMask_v3 en SplashView con Lottie y accesibilidad Reduce Motion
   Files: Shield/Views/Components/SplashView.swift, Shield/App/ContentView.swift, Shield/Resources/Animations/MaskID_IdentityMask_v3.json, Shield.xcodeproj/project.pbxproj
   Note: Animación v3 recuperada e integrada en SplashView con Lottie 4.6.1, callback de finalización, fallback y Reduce Motion. Build estricto correcto; JSON confirmado en bundle. Suite de tests detenida por petición del usuario; app instalada y abierta en Simulator.
   Detail: tasks/details/75-splash-lottie-identidad.md
   Claimed by: CODEX
   Claimed at: 2026-08-08T23:46:46Z
   Done by: CODEX
   Done at: 2026-08-08T23:57:36Z

76. ui-ux-integral-audit-roadmap
   Id: 76-ui-ux-integral-audit-roadmap
   Scope: Auditar integralmente UI/UX en iPhone y iPad; definir sistema visual, navegación persistente, ritmo espacial, microinteracciones, accesibilidad y roadmap ejecutable priorizado
   Files: Shield/App/**,Shield/Theme/**,Shield/Views/**,ShieldUITests/**,tasks/TASKS.md,tasks/details/76-ui-ux-integral-audit-roadmap.md
   Note: Auditoría UI/UX integral completada; 32 fuentes revisadas, 16 capturas iPhone/iPad inspeccionadas, build estricto OK, hallazgos P0-P2 y roadmap 77-85 documentados; sin cambios de producto
   Detail: tasks/details/76-ui-ux-integral-audit-roadmap.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T08:01:27Z
   Done by: CODEX
   Done at: 2026-08-09T08:12:23Z

77. ui-shell-navigation-safeareas-p0
   Id: 77-ui-shell-navigation-safeareas-p0
   Scope: Eliminar roturas P0 de layout: Galería iPad, headers persistentes, contrato de navegación, safe areas, espacios finales y detents
   Files: Shield/App/ContentView.swift,Shield/Views/Components/**,Shield/Views/Gallery/StyleGalleryView.swift,Shield/Views/Settings/**,Shield/Views/Home/HomeView.swift,Shield/Views/Vault/VaultView.swift,Shield/Views/Editor/EditorView.swift,ShieldUITests/**
   Note: Grid de Galería adaptativo sin cálculos de altura; chrome fijo en Ajustes/destinos/paywall onboarding; CTA fija y detents adaptativos en preview de estilo; safeAreaInset como única reserva del tab bar; padding final 24; Batch usa NavigationStack. Build estricto, tests UI focalizados y revisión iPhone/iPad OK.
   Detail: tasks/details/77-ui-shell-navigation-safeareas-p0.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T08:28:12Z
   Done by: CODEX
   Done at: 2026-08-09T08:34:42Z

78. design-system-clean-depth-motion
   Id: 78-design-system-clean-depth-motion
   Scope: Consolidar tokens de superficies, tipografía, espaciado, botones, cards, estados, elevación y motion accesible
   Files: Shield/Theme/ShieldTheme.swift,Shield/Views/Components/**,ShieldUITests/**
   Note: Tokens semánticos adaptativos, layout y motion añadidos; tipografía escalable con estilos relativos y mínimo legible; ShieldButton/Chip/Icon/Toggle/Card/Row/State/Status/StickyFooter consolidados; haptic UIKit retirado en favor de sensoryFeedback; Reduce Motion/Transparency e Increase Contrast integrados; catálogo dark/light AX añadido. Build estricto OK.
   Detail: tasks/details/78-design-system-clean-depth-motion.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T08:34:42Z
   Done by: CODEX
   Done at: 2026-08-09T08:39:14Z

79. home-library-ux-redesign
   Id: 79-home-library-ux-redesign
   Scope: Reestructurar Inicio y biblioteca: jerarquía, búsqueda/filtros, acciones primarias, modos, recientes, estados y densidad
   Files: Shield/Views/Home/**,Shield/App/ContentView.swift,ShieldUITests/**
   Note: Hero reducido y acciones Escanear/Importar dominantes con componentes comunes; búsqueda/categorías conducen directamente a recientes; primer documento visible en primera pantalla; modos/Bóveda/nube bajo disclosure progresivo; scroll vuelve al top al reentrar; empty/no-results consolidados; metadata sin wrap. Build, auditoría Home ES/EN y navegación primaria OK.
   Detail: tasks/details/79-home-library-ux-redesign.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T08:39:14Z
   Done by: CODEX
   Done at: 2026-08-09T08:44:31Z

80. capture-import-review-ux-redesign
   Id: 80-capture-import-review-ux-redesign
   Scope: Simplificar captura/importación/revisión: eliminar duplicidad, anclar acciones, mejorar progreso, errores y edición de escaneo
   Files: Shield/Views/Capture/**,Shield/Cloud/ExternalStorageManager.swift,ShieldUITests/**
   Note: Captura reestructurada: acción Escanear principal, Fotos/Archivos/Nube visibles sin scroll, selección de tipo única y horizontal, guide compacta; revisión conserva header/confirm persistentes; progreso cancelable y error con retry contextual; visual simulator y tests Capture/camera ES/EN OK. Recorrido de hardware físico reservado al gate 85.
   Detail: tasks/details/80-capture-import-review-ux-redesign.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T08:44:31Z
   Done by: CODEX
   Done at: 2026-08-09T08:49:44Z

81. editor-ocr-export-workspace-redesign
   Id: 81-editor-ocr-export-workspace-redesign
   Scope: Rehacer jerarquía del editor, herramientas contextuales, OCR y exportación con chrome estable y menor carga cognitiva
   Files: Shield/Views/Editor/**,Shield/ViewModels/EditorViewModel.swift,ShieldUITests/**
   Note: Editor simplificado a una sola barra de herramientas con selector de modo; banners contextuales priorizados; OCR/export con detents nativos y CTAs persistentes. Build estricto y 4 pruebas UI de Editor/OCR/Export aprobadas.
   Detail: tasks/details/81-editor-ocr-export-workspace-redesign.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T08:49:44Z
   Done by: CODEX
   Done at: 2026-08-09T08:56:45Z

82. gallery-vault-ux-redesign
   Id: 82-gallery-vault-ux-redesign
   Scope: Perfeccionar Galería y Bóveda: selección/preview, responsive grid, estados vacíos y uso del espacio
   Files: Shield/Views/Gallery/**,Shield/Views/Vault/**,Shield/Views/Documents/**,ShieldUITests/**
   Note: Galería con selección persistente/VoiceOver, transición discreta y bloqueos Pro no invasivos. Bóveda con resumen de seguridad, grid adaptable, empty state accionable y CTA persistente. Build estricto, revisión visual y 4 pruebas UI aprobadas.
   Detail: tasks/details/82-gallery-vault-ux-redesign.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T08:56:45Z
   Done by: CODEX
   Done at: 2026-08-09T09:02:53Z

83. settings-paywall-onboarding-ux
   Id: 83-settings-paywall-onboarding-ux
   Scope: Simplificar Ajustes, Paywall y onboarding; mantener navegación/CTA persistentes, adaptar estados comerciales y reducir textos
   Files: Shield/Views/Settings/**,Shield/Views/Paywall/**,Shield/Views/Onboarding/**,Shield/Premium/**,ShieldUITests/**
   Note: Ajustes con resumen compacto y chrome fijo; paywalls con CTA persistente, estado deshabilitado real, retry contextual, tokens adaptativos y Reduce Motion; onboarding verificado con controles fijos y branding animado. Build estricto, revisión visual y 5 pruebas UI aprobadas.
   Detail: tasks/details/83-settings-paywall-onboarding-ux.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T09:02:53Z
   Done by: CODEX
   Done at: 2026-08-09T09:10:58Z

84. ipad-adaptive-layouts
   Id: 84-ipad-adaptive-layouts
   Scope: Diseñar layouts iPad reales para dashboard, galería, editor, captura, bóveda, ajustes y multitarea
   Files: Shield/App/**,Shield/Views/**,ShieldUITests/**
   Note: iPad: dashboard dos columnas, captura y revisión con layouts laterales, Editor lienzo+inspector, grids adaptativos en Galería/Bóveda/Ajustes y shortcuts de teclado. Build estricto, 3 auditorías UI en iPad Pro 13 y snapshots visuales aprobados.
   Detail: tasks/details/84-ipad-adaptive-layouts.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T09:10:59Z
   Done by: CODEX
   Done at: 2026-08-09T09:18:34Z

85. ui-accessibility-visual-release-gate
   Id: 85-ui-accessibility-visual-release-gate
   Scope: Cerrar QA UI/UX: Dynamic Type, VoiceOver, Reduce Motion/Transparency, contraste, localización, snapshots y pruebas físicas
   Files: Shield/Theme/**,Shield/Views/**,ShieldUITests/**,scripts/**,Docs/**
   Note: Gate UI/UX automatizado integrado en release_gate, matriz visual claro/oscuro ES/EN iPhone/iPad, prueba AX5+Reduce Motion/Transparency/Contrast y checklist físico firmado documentado. Test AX5 aprobado; firma física queda requisito manual previo al próximo upload.
   Detail: tasks/details/85-ui-accessibility-visual-release-gate.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T09:18:34Z
   Done by: CODEX
   Done at: 2026-08-09T09:24:13Z

86. animated-brand-mark-surfaces
   Id: 86-animated-brand-mark-surfaces
   Scope: Crear un componente visual reutilizable basado en la animación Lottie de MaskID y aplicarlo en onboarding, bloqueo, privacy snapshot, Inicio y Ajustes con variantes adaptadas al contexto, fallback estático y Reduce Motion.
   Files: Shield/Views/Components/SplashView.swift,Shield/Views/Onboarding/OnboardingSteps.swift,Shield/Views/Onboarding/OnboardingView.swift,Shield/App/ContentView.swift,Shield/Views/Home/HomeDashboardViews.swift,Shield/Views/Settings/SettingsDestinationViews.swift
   Note: Componente MaskIDIdentityMark integrado en splash, onboarding, bloqueo, privacy snapshot, Inicio y Ajustes. Lottie one-shot en superficies hero, variantes estáticas compactas, Reduce Motion y VoiceOver respetados. Build estricto OK; suite completa make test OK; validación visual de onboarding en simulador OK.
   Detail: tasks/details/86-animated-brand-mark-surfaces.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T08:14:54Z
   Done by: CODEX
   Done at: 2026-08-09T08:27:01Z

87. compact-footer-navigation
   Id: 87-compact-footer-navigation
   Scope: Reducir aproximadamente a la mitad la altura visual del footer sin perder navegación, safe area ni targets accesibles.
   Files: Shield/Views/Components/TabBar.swift
   Note: Footer compactado de 88pt a 44pt de altura funcional; scan 44pt, paddings eliminados y targets accesibles conservados. Build estricto, navegación UI y revisión visual aprobadas.
   Detail: tasks/details/87-compact-footer-navigation.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T09:40:25Z
   Done by: CODEX
   Done at: 2026-08-09T09:48:41Z

88. lock-screen-value-redesign
   Id: 88-lock-screen-value-redesign
   Scope: Redesign the authentication gate to remove dead space and redundancy, communicate concrete privacy value, keep primary authentication persistently reachable, and validate accessibility/adaptive layouts.
   Files: Shield/Views/Onboarding/OnboardingView.swift,Shield/ViewModels/AppState.swift,Shield/Localization/Strings/Auth.xcstrings,ShieldUITests/ShieldLaunchTests.swift
   Note: Redesigned lock screen with compact animated access card, method-aware status, concrete local/encryption value, intentional privacy curtain, and compact sticky CTA. Strict build passed; lock EN/ES accessibility audit and AX5/reduced-motion chrome test passed; visually verified on iPhone 17 Pro Max.
   Detail: tasks/details/88-lock-screen-value-redesign.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T09:51:47Z
   Done by: CODEX
   Done at: 2026-08-09T10:03:08Z

89. storekit-review-request-policy
   Id: 89-storekit-review-request-policy
   Scope: Use StoreKit's native review request from Settings and after verified value moments, with a more frequent but compliant free-tier cadence and a lighter premium cadence.
   Files: Shield/App/AppReviewManager.swift,Shield/Views/Settings/SettingsView.swift,Shield/Views/Capture/CaptureView.swift,Shield/Views/Editor/ExportSheetView.swift,ShieldTests/AppReviewManagerTests.swift,ShieldUITests/ShieldLaunchTests.swift,Shield.xcodeproj/project.pbxproj
   Note: Implemented AppStore.requestReview(in:) from Settings and after successful import/export value moments. Free: 2d/3-point/45d/3-year cadence; Premium: 14d/8-point/120d/2-year cadence. Removed external review URL behavior. Strict build passed; 4 targeted unit/UI tests passed.
   Detail: tasks/details/89-storekit-review-request-policy.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T10:05:12Z
   Done by: CODEX
   Done at: 2026-08-09T10:11:31Z

90. elevated-central-scan-button
   Id: 90-elevated-central-scan-button
   Scope: Increase the central scan control and make it protrude above the compact tab bar without increasing the bar's layout height or safe-area footprint.
   Files: Shield/Views/Components/TabBar.swift,ShieldUITests/ShieldLaunchTests.swift
   Note: Central scan control enlarged to 64pt and overlaid 24pt above a fixed 44pt footer slot. Added separation ring/shadow and geometry regression asserting upward-only growth. Strict build passed; focused UI regression passed; visually verified on iPhone 17 Pro Max.
   Detail: tasks/details/90-elevated-central-scan-button.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T10:13:27Z
   Done by: CODEX
   Done at: 2026-08-09T10:24:39Z

91. compact-paywall-footer-links
   Id: 91-compact-paywall-footer-links
   Scope: Move restore, privacy, terms, and subscription-condition actions below the paywall CTA in an adaptive compact footer, remove them from scroll content, and reclaim trailing content space.
   Files: Shield/Views/Paywall/PaywallView.swift,ShieldUITests/ShieldLaunchTests.swift
   Note: Moved restore/privacy/terms/subscription links below CTA in adaptive footer; normal iPhone layout fits one 44pt line, with accessible fallbacks. Removed links from scroll content and reduced trailing padding. Strict build passed and visual review completed; further tests stopped at user request.
   Detail: tasks/details/91-compact-paywall-footer-links.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T10:25:39Z
   Done by: CODEX
   Done at: 2026-08-09T10:30:18Z

92. appstore-1-0-1-upload
   Id: 92-appstore-1-0-1-upload
   Scope: Create App Store Connect iOS version 1.0.1, set all local target versions/builds to 1.0.1/101202608091, archive/export/upload, wait for processing, attach the build, and update EN/ES What's New without submitting for review.
   Files: Shield.xcodeproj/project.pbxproj,metadata/version/1.0.1/en-US.json,metadata/version/1.0.1/es-ES.json,.asc/artifacts/MaskID-1.0.1-101202608091.xcarchive,.asc/artifacts/MaskID-1.0.1-101202608091.ipa
   Note: Created ASC iOS 1.0.1; updated Shield and ShieldShareExtension Debug/Release to 1.0.1 (101202608091); archived/exported/uploaded; Apple build VALID and attached; es-ES/en-US What’s New updated. No test suites run per user request; archive succeeded.
   Detail: tasks/details/92-appstore-1-0-1-upload.md
   Claimed by: CODEX
   Claimed at: 2026-08-09T10:31:36Z
   Done by: CODEX
   Done at: 2026-08-09T10:40:34Z

93. maskid-app-icon-unification
   Id: 93-maskid-app-icon-unification
   Scope: Sustituir icono antiguo por la mascara animada MaskID en Paywall, Ajustes e Inicio
   Files: Shield/Views/Components/SplashView.swift,Shield/Views/Paywall/PaywallView.swift,Shield/Views/Settings/SettingsView.swift,Shield/Views/Settings/SettingsDestinationViews.swift,Shield/Views/Home/HomeDashboardViews.swift,Shield/Views/Home/HomeView.swift,Shield/Cloud/ExternalStorageManager.swift
   Note: Finished: icono MaskID y animacion Lottie en Paywall, Ajustes, Inicio y Bóveda. Build y tests verdes
   Detail: tasks/details/93-maskid-app-icon-unification.md
   Claimed by: CODEX
   Claimed at: 2026-08-10T13:18:28Z
   Done by: CODEX
   Done at: 2026-08-10T13:45:44Z

94. lock-screen-summary-redesign
   Id: 94-lock-screen-summary-redesign
   Scope: Rediseñar LockScreenView con 3 bloques claros: Lo que tiene, Lo que necesita, Lo que hace
   Files: Shield/Views/Onboarding/OnboardingView.swift,Shield/Localization/Strings/Auth.xcstrings
   Note: Finished: rediseño ejecutivo de LockScreenView con 3 bloques (Lo que tiene, Lo que necesita, Lo que hace). Compilación y ejecución en simulador OK
   Detail: tasks/details/94-lock-screen-summary-redesign.md
   Claimed by: CODEX
   Claimed at: 2026-08-10T16:14:23Z
   Done by: CODEX
   Done at: 2026-08-10T16:15:22Z

95. lock-screen-activity-summary
   Id: 95-lock-screen-activity-summary
   Scope: Rediseño completo de LockScreenView con métricas reales de actividad (procesados, bóveda, enmascarados), Lottie hero y localización en Auth.xcstrings
   Files: Shield/Views/Onboarding/OnboardingView.swift,Shield/Localization/Strings/Auth.xcstrings
   Note: Iniciando rediseño de LockScreenView con métricas reales y Lottie
   Detail: tasks/details/95-lock-screen-activity-summary.md
   Claimed by: CODEX
   Claimed at: 2026-08-10T16:19:16Z

96. fix-settings-icon-redundancy
   Id: 96-fix-settings-icon-redundancy
   Scope: Eliminar redundancia de iconos en Ajustes y fijar ASSETCATALOG_COMPILER_APPICON_NAME a MaskID en project.pbxproj
   Files: Shield.xcodeproj/project.pbxproj,Shield/Views/Settings/SettingsView.swift
   Note: Finished: redundancia de Ajustes eliminada (tarjeta Pro usa badge de destellos) y ASSETCATALOG_COMPILER_APPICON_NAME fijado a MaskID en project.pbxproj
   Detail: tasks/details/96-fix-settings-icon-redundancy.md
   Claimed by: CODEX
   Claimed at: 2026-08-10T16:20:39Z
   Done by: CODEX
   Done at: 2026-08-10T16:21:27Z

97. fix-scan-review-ui-bugs
   Id: 97-fix-scan-review-ui-bugs
   Scope: Fix scan review header status bar overlap, auto-crop chip selection, and bottom tools layout in ScanReviewView
   Files: Shield/Views/Capture/CaptureReviewViews.swift
   Note: Fixed top header safe area, Vision quad area filtering, manual crop reset button, and scrollable controls with bottom CTA; build and tests passed
   Detail: tasks/details/97-fix-scan-review-ui-bugs.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T08:56:37Z
   Done by: CODEX
   Done at: 2026-08-12T08:57:50Z

98. fix-scan-review-layout-safearea-controls
   Id: 98-fix-scan-review-layout-safearea-controls
   Scope: Fix ScanReviewView header safe area double padding and expand bottom tools scroll height with sticky bottom action
   Files: Shield/Views/Capture/CaptureReviewViews.swift
   Note: Refactored header safe area without topInset calculation, expanded bottom controls scroll area, and added pinned bottom bar for Continue CTA
   Detail: tasks/details/98-fix-scan-review-layout-safearea-controls.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T09:05:19Z
   Done by: CODEX
   Done at: 2026-08-12T09:06:07Z

99. vibrant-apply-button-style
   Id: 99-vibrant-apply-button-style
   Scope: Enhance ScanReviewView apply buttons with vibrant electric cyan brand styling and subtle shadow glow
   Files: Shield/Views/Capture/CaptureReviewViews.swift
   Note: Applied high-contrast electric cyan brand gradient, icon and subtle glow to Apply to all pages and Continue action buttons
   Detail: tasks/details/99-vibrant-apply-button-style.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T09:07:51Z
   Done by: CODEX
   Done at: 2026-08-12T09:08:26Z

100. fix-editor-footer-toolbar-clipping
   Id: 100-fix-editor-footer-toolbar-clipping
   Scope: Fix EditorView bottom toolbar top clipping by removing layoutPriority(1) from canvasArea and adjusting EditorBottomToolbar padding
   Files: Shield/Views/Editor/EditorView.swift,Shield/Views/Editor/EditorChromeViews.swift
   Note: Removed layoutPriority(1) from canvasArea and adjusted EditorBottomToolbar top and bottom paddings to 10pt
   Detail: tasks/details/100-fix-editor-footer-toolbar-clipping.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T09:10:37Z
   Done by: CODEX
   Done at: 2026-08-12T09:11:18Z

101. add-zoom-pan-hand-tool-canvas
   Id: 101-add-zoom-pan-hand-tool-canvas
   Scope: Implement 2D drag panning on zoomed canvas and add Hand (Pan) tool to EditorTool
   Files: Shield/Views/Editor/EditorView.swift,Shield/ViewModels/EditorViewModel.swift,Shield/Localization/Strings/Editor.xcstrings
   Note: Added 2D drag panning when zoomed in and dedicated Pan (Mover / hand.raised.fill) tool to EditorTool
   Detail: tasks/details/101-add-zoom-pan-hand-tool-canvas.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T09:12:01Z
   Done by: CODEX
   Done at: 2026-08-12T09:13:24Z

102. center-align-increase-editor-footer-buttons
   Id: 102-center-align-increase-editor-footer-buttons
   Scope: Center-align EditorBottomToolbar vertically, increase tool and action button sizes, and keep outer footer height compact
   Files: Shield/Views/Editor/EditorChromeViews.swift
   Note: Increased tool and action button sizes, vertically centered all toolbar elements, and reduced outer footer padding to 4pt for compact container height
   Detail: tasks/details/102-center-align-increase-editor-footer-buttons.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T09:15:33Z
   Done by: CODEX
   Done at: 2026-08-12T09:16:11Z

103. add-undo-redo-for-image-adjustments-and-filters
   Id: 103-add-undo-redo-for-image-adjustments-and-filters
   Scope: Expand EditorViewModel history system to snapshot imageAdjustment and watermark alongside redactions, enabling complete Undo/Redo for all image filters and adjustments
   Files: Shield/ViewModels/EditorViewModel.swift,Shield/Views/Editor/ImageAdjustToolbar.swift
   Note: Expanded EditorViewModel history to snapshot imageAdjustment and watermark alongside redactions, enabling complete Undo/Redo support before saving
   Detail: tasks/details/103-add-undo-redo-for-image-adjustments-and-filters.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T09:17:51Z
   Done by: CODEX
   Done at: 2026-08-12T09:19:50Z

104. enlarge-and-lower-editor-footer-buttons
   Id: 104-enlarge-and-lower-editor-footer-buttons
   Scope: Enlarge EditorBottomToolbar action and tool buttons (48x48 / 40x40 with 20pt icons) and lower their vertical position with padding(.top, 8) and padding(.bottom, 2)
   Files: Shield/Views/Editor/EditorChromeViews.swift
   Note: Increased action buttons to 48x48 (20pt icons) and tool boxes to 40x40 (19pt icons, 10pt bold text) and set top padding 8pt, bottom padding 2pt to lower button position
   Detail: tasks/details/104-enlarge-and-lower-editor-footer-buttons.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T09:26:33Z
   Done by: CODEX
   Done at: 2026-08-12T09:27:20Z

105. fix-scan-review-header-safe-area-overlap
   Id: 105-fix-scan-review-header-safe-area-overlap
   Scope: Refactor ScanReviewView layout to place header() at top of outer VStack(spacing: 0) outside GeometryReader so it never overlaps status bar or safe area
   Files: Shield/Views/Capture/CaptureReviewViews.swift
   Note: Moved header() to outer VStack top level outside GeometryReader in ScanReviewView to permanently fix status bar overlap
   Detail: tasks/details/105-fix-scan-review-header-safe-area-overlap.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T09:33:30Z
   Done by: CODEX
   Done at: 2026-08-12T09:34:18Z

106. fix-scan-review-safe-area-inset-outside-geometry-reader
   Id: 106-fix-scan-review-safe-area-inset-outside-geometry-reader
   Scope: Move safeAreaInset(edge: .top) { header() } outside GeometryReader in ScanReviewView body so SwiftUI top safe area is respected in fullScreenCover
   Files: Shield/Views/Capture/CaptureReviewViews.swift
   Note: Moved safeAreaInset(edge: .top) { header() } outside GeometryReader in ScanReviewView body to force top safe area padding in fullScreenCover
   Detail: tasks/details/106-fix-scan-review-safe-area-inset-outside-geometry-reader.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T09:41:33Z
   Done by: CODEX
   Done at: 2026-08-12T09:42:21Z

107. remove-footer-and-fix-scan-review-header
   Id: 107-remove-footer-and-fix-scan-review-header
   Scope: Remove pinned bottom continue footer from ScanReviewView and fix header top padding using geo.safeAreaInsets.top inside GeometryReader
   Files: Shield/Views/Capture/CaptureReviewViews.swift
   Note: Removed pinned bottom continue footer from ScanReviewView and applied geo.safeAreaInsets.top padding to header inside GeometryReader
   Detail: tasks/details/107-remove-footer-and-fix-scan-review-header.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T09:48:01Z
   Done by: CODEX
   Done at: 2026-08-12T09:48:57Z

108. update-splash-and-identity-icon-assets
   Id: 108-update-splash-and-identity-icon-assets
   Scope: Actualizar vista de carga/splash y componentes de identidad MaskIDIdentityMark para usar la nueva marca e icono (anillo neón cian/verde sobre fondo de documento) en lugar del icono antiguo de robot/visera
   Files: Shield/Resources/Assets.xcassets/MaskIDMark.imageset/maskid-mark.png,Shield/Resources/Animations/MaskID_IdentityMask_v3.json,Shield/Views/Components/SplashView.swift
   Note: Actualizados activos MaskIDMark.imageset (maskid-mark.png) y recurso Lottie (MaskID_IdentityMask_v3.json img_face) con el nuevo icono de marca (anillo cian/verde sobre fondo de documento identidad) coincidente con la app de iOS. Compilación y suite completa de tests de la app superados en verde (30/30).
   Detail: tasks/details/108-update-splash-and-identity-icon-assets.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T11:56:23Z
   Done by: CODEX
   Done at: 2026-08-12T11:56:58Z

109. fix-lock-screen-ui-layout
   Id: 109-fix-lock-screen-ui-layout
   Scope: Rediseñar y corregir la interfaz de LockScreenView: estilizar el icono de identidad para integrarlo armónicamente sin cuadrado oscuro brusco, eliminar redundancias en la tarjeta de resumen de actividad, mejorar espaciados/tipografía de secciones y añadir padding inferior para evitar solapamiento con el botón flotante
   Files: Shield/Views/Onboarding/OnboardingView.swift
   Note: Finalizado rediseño de LockScreenView sin cuadrado oscuro y con distribución limpia.
   Detail: tasks/details/109-fix-lock-screen-ui-layout.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T11:59:22Z
   Done by: CODEX
   Done at: 2026-08-12T12:02:05Z

110. fix-appwide-identity-mark-clipping-and-card-layouts
   Id: 110-fix-appwide-identity-mark-clipping-and-card-layouts
   Scope: Corregir el recorte y estilo de MaskIDIdentityMark en toda la app para eliminar los cuadrados oscuros no recortados en LottieView (Home, Ajustes, Paywall) y estilizar las tarjetas de Ajustes y Paywall
   Files: Shield/Views/Components/SplashView.swift,Shield/Views/Home/HomeDashboardViews.swift,Shield/Views/Settings/SettingsDestinationViews.swift,Shield/Views/Paywall/PaywallView.swift
   Note: Corregido el problema de renderizado no recortado en MaskIDIdentityMark aplicándolo a LottieView y staticMark con esquinas redondeadas (.continuous), borde sutil y sombra. Actualizados HomeTopBarView, SettingsSummaryCard, PaywallView y LockScreenView con tratamientos compactos pulidos y padding de ScrollView adecuado. Pruebas y build estricto en verde (30/30).
   Detail: tasks/details/110-fix-appwide-identity-mark-clipping-and-card-layouts.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T12:00:36Z
   Done by: CODEX
   Done at: 2026-08-12T12:01:59Z

111. remove-pixel-visor-from-lottie-animation
   Id: 111-remove-pixel-visor-from-lottie-animation
   Scope: Remover las capas de píxeles laterales (Mask pixel 1..72) en la animación Lottie MaskID_IdentityMask_v3.json para mantener únicamente el destello animado (Scan line) sobre la marca limpia
   Files: Shield/Resources/Animations/MaskID_IdentityMask_v3.json
   Note: Removidas las 72 capas de píxeles laterales (Mask pixel 1..72) en MaskID_IdentityMask_v3.json. Conservada la marca limpia (Face/img_face) con el destello animado (Scan line). Compilación y suite completa de unit tests aprobadas en verde (29/29).
   Detail: tasks/details/111-remove-pixel-visor-from-lottie-animation.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T12:05:08Z
   Done by: CODEX
   Done at: 2026-08-12T12:05:48Z

112. clean-base-head-image-and-restore-lottie-pixel-animation
   Id: 112-clean-base-head-image-and-restore-lottie-pixel-animation
   Scope: Limpiar las alas estáticas de visera pixelada en los laterales de la imagen del modelo 3D y restaurar la animación Lottie completa para que la visera pixelada y la línea de escaneo se animen dinámicamente sobre la cabeza limpia sin dejar bloques estáticos
   Files: Shield/Resources/Assets.xcassets/MaskIDMark.imageset/maskid-mark.png,Shield/Resources/Animations/MaskID_IdentityMask_v3.json
   Note: Limpiadas las alas de visera estáticas en los laterales del modelo de cabeza 3D en la imagen base y restaurada la animación Lottie completa con la línea de escaneo y los bloques pixelados dinámicos. App reinstalada y abierta en el simulador.
   Detail: tasks/details/112-clean-base-head-image-and-restore-lottie-pixel-animation.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T12:08:46Z
   Done by: CODEX
   Done at: 2026-08-12T12:09:20Z

113. restore-original-lottie-animation
   Id: 113-restore-original-lottie-animation
   Scope: Restaurar completamente la animación Lottie original MaskID_IdentityMask_v3.json y el recurso maskid-mark.png sin modificaciones
   Files: Shield/Resources/Animations/MaskID_IdentityMask_v3.json,Shield/Resources/Assets.xcassets/MaskIDMark.imageset/maskid-mark.png
   Note: Restaurados completamente la animación Lottie original MaskID_IdentityMask_v3.json y el recurso de imagen maskid-mark.png a su estado intacto inicial. Proyecto recompilado y app reinstalada en el simulador.
   Detail: tasks/details/113-restore-original-lottie-animation.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T12:11:03Z
   Done by: CODEX
   Done at: 2026-08-12T12:11:33Z

114. archive-upload-and-attach-build-102202608124
   Id: 114-archive-upload-and-attach-build-102202608124
   Scope: Actualizar versión de build a 102202608124 en project.pbxproj, generar archivo .xcarchive e IPA, subir a App Store Connect y enlazar el build a la versión 1.0.2
   Files: Shield.xcodeproj/project.pbxproj
   Note: Actualizado el build number a 102202608124 en project.pbxproj, generado el archivo .xcarchive e IPA, subida completada a App Store Connect y build 102202608124 enlazado exitosamente a la versión 1.0.2.
   Detail: tasks/details/114-archive-upload-and-attach-build-102202608124.md
   Claimed by: CODEX
   Claimed at: 2026-08-12T12:16:57Z
   Done by: CODEX
   Done at: 2026-08-12T12:21:11Z

115. raw-captures-automation
   Id: 115-raw-captures-automation
   Scope: Capturar 10 capturas brutas de la app en español e inglés (20 en total) según los 10 requisitos de pantalla especificados
   Files: .asc/screenshots,Shield/ViewModels/AppState.swift,ShieldUITests/ShieldLaunchTests.swift,scripts
   Note: Re-captured 10 distinct raw screenshots in ES and EN using fixed CODEX binary
   Detail: tasks/details/115-raw-captures-automation.md
   Claimed by: CODEX
   Claimed at: 2026-08-16T06:23:10Z
   Done by: CODEX
   Done at: 2026-08-16T06:28:12Z

116. free-quota-icon-zoom-interaction-ui-polish
   Id: 116-free-quota-icon-zoom-interaction-ui-polish
   Scope: Fix free document quota leak, update app icon asset & identity mark, fix mask editing/interaction during zoom, and elevate main views UI/fluidity
   Files: Shield/Premium/PremiumManager.swift,Shield/ViewModels/AppState.swift,Shield/Views/Home/HomeView.swift,Shield/Views/Home/HomeDashboardViews.swift,Shield/Views/Editor/DocumentCanvas.swift,Shield/Views/Editor/EditorView.swift,Shield/Views/Components/SplashView.swift,Shield/Resources/Assets.xcassets/MaskIDMark.imageset/maskid-mark.png
   Note: Fixed free quota persistence (anti-leak on deletion), composited and updated master app icon across splash and all views, fixed zoom-aware mask handles (4-corners with accurate delta scaling), and polished UI fluidity
   Detail: tasks/details/116-free-quota-icon-zoom-interaction-ui-polish.md
   Claimed by: CODEX
   Claimed at: 2026-08-16T06:39:51Z
   Done by: CODEX
   Done at: 2026-08-16T06:48:02Z

117. ocr-precision-multienvironment-local-models
   Id: 117-ocr-precision-multienvironment-local-models
   Scope: Mejora integral de precisión y calidad del motor OCR, preprocesamiento neuro-gráfico (CLAHE, deskew, binarización adaptativa, eliminación de sombras), fusión multi-paso, corrección de PII por dígitos de control (DNI/NIE/MRZ/IBAN), gestor de motores locales y catálogo de modelos libres descargables
   Files: Shield/OCR/**,Shield/Views/Capture/CaptureOCRServices.swift,Shield/Views/Settings/**,ShieldTests/**
   Note: Implemented multi-pass OCR image preprocessor (shadows/contrast/binarization), spatial IoU fusion engine, mathematical check-digit auto-repair (DNI/NIE Modulo 23, MRZ ICAO 9303, IBAN Modulo 97), local language pack catalog and OCREngineSettingsView
   Detail: tasks/details/117-ocr-precision-multienvironment-local-models.md
   Claimed by: CODEX
   Claimed at: 2026-08-16T06:51:06Z
   Done by: CODEX
   Done at: 2026-08-16T07:02:11Z

118. lock-and-splash-redesign
   Id: 118-lock-and-splash-redesign
   Scope: Redesign lock screen and splash/privacy snapshot view with integrated lighting and minimalist unlock flow
   Files: Shield/Views/Onboarding/OnboardingView.swift,Shield/Views/Components/SplashView.swift,Shield/App/ContentView.swift
   Note: Redesigned LockScreenView to a clean, elegant layout with integrated avatar and unlock actions, and enhanced MaskIDIdentityMark/SplashView/PrivacySnapshotShield with ambient radial halo, glass bezel, and scanning sheen
   Detail: tasks/details/118-lock-and-splash-redesign.md
   Claimed by: CODEX
   Claimed at: 2026-08-16T07:10:05Z
   Done by: CODEX
   Done at: 2026-08-16T07:14:42Z

119. zoom-drawing-gesture-deconfliction
   Id: 119-zoom-drawing-gesture-deconfliction
   Scope: Resolve drag gesture conflict between canvas drawing and viewport panning when zoomed
   Files: Shield/Views/Editor/EditorView.swift,Shield/Views/Editor/DocumentCanvas.swift
   Note: Deconflicted drag-to-draw vs drag-to-pan when zoomed in EditorView by disabling scrollview during drawing and scoping 1-finger pan strictly to .pan tool
   Detail: tasks/details/119-zoom-drawing-gesture-deconfliction.md
   Claimed by: CODEX
   Claimed at: 2026-08-16T07:16:43Z
   Done by: CODEX
   Done at: 2026-08-16T07:20:36Z

120. circular-gradient-fused-avatar
   Id: 120-circular-gradient-fused-avatar
   Scope: Make avatar mark circular with feathered radial gradient edges that melt smoothly into the background
   Files: Shield/Views/Components/SplashView.swift
   Note: Made avatar round with feathered radial gradient edges that blend seamlessly into the background view, and eliminated launch splash overlay race condition
   Detail: tasks/details/120-circular-gradient-fused-avatar.md
   Claimed by: CODEX
   Claimed at: 2026-08-16T07:21:20Z
   Done by: CODEX
   Done at: 2026-08-16T07:24:40Z

121. vault-ui-and-text-overflow-improvements
   Id: 121-vault-ui-and-text-overflow-improvements
   Scope: Improve Vault UI, eliminate text wrapping/truncation on category badges and security pills, and simplify encryption labels to 'Cifrado'
   Files: Shield/Views/Vault/VaultView.swift,Shield/Views/Home/HomeView.swift,Shield/Localization/Strings/Vault.xcstrings
   Note: Refined Vault UI: simplified encryption labels to Cifrado, fixed multi-line badge wrapping and text truncation in DocumentRow, and elevated header and card styling
   Detail: tasks/details/121-vault-ui-and-text-overflow-improvements.md
   Claimed by: CODEX
   Claimed at: 2026-08-16T07:28:03Z
   Done by: CODEX
   Done at: 2026-08-16T07:37:30Z

122. recent-documents-ui-redesign
   Id: 122-recent-documents-ui-redesign
   Scope: Fix recent documents layout, unified card styling, consistent horizontal padding, and section alignment on Home screen
   Files: Shield/Views/Home/HomeView.swift,Shield/Views/Components/Components.swift,Shield/Views/Home/HomeSectionViews.swift
   Note: Unified recent documents card styling, fixed margins to 20pt, resolved SectionHeader alignment and overflow truncation
   Detail: tasks/details/122-recent-documents-ui-redesign.md
   Claimed by: CODEX
   Claimed at: 2026-08-16T07:39:46Z
   Done by: CODEX
   Done at: 2026-08-16T07:45:43Z

123. archive-upload-and-attach-build-103202608161
   Id: 123-archive-upload-and-attach-build-103202608161
   Scope: Update build number to 103202608161, archive, upload to App Store Connect and link to version 1.0.3
   Files: Shield.xcodeproj/project.pbxproj
   Note: Build 103202608161 archived, IPA exported, uploaded to App Store Connect, and attached to version 1.0.3 with 0 blockers
   Detail: tasks/details/123-archive-upload-and-attach-build-103202608161.md
   Claimed by: CODEX
   Claimed at: 2026-08-16T07:51:47Z
   Done by: CODEX
   Done at: 2026-08-16T07:57:13Z

124. fix-app-review-eula-metadata
   Id: 124-fix-app-review-eula-metadata
   Scope: Add functional Terms of Use (EULA) and Privacy links to App Store description metadata for 1.0.3 and sync to App Store Connect
   Files: metadata/version/1.0.3/en-US.json,metadata/version/1.0.3/es-ES.json
   Note: Added EULA, terms and privacy links to metadata 1.0.3, synced to App Store Connect, marked rejection item as resolved and resubmitted to review (now WAITING_FOR_REVIEW)
   Detail: tasks/details/124-fix-app-review-eula-metadata.md
   Claimed by: CODEX
   Claimed at: 2026-08-17T06:11:31Z
   Done by: CODEX
   Done at: 2026-08-17T06:12:46Z

125. audit-remediation-and-stability
   Id: 125-audit-remediation-and-stability
   Scope: Corregir bloqueos de preflight, accesibilidad 44pt, telemetria de compras, regresiones en UI tests, resiliencia CloudKit, conexion del motor OCR y alineacion de privacidad
   Files: Shield/ViewModels/AppState.swift,Shield/Views/Capture/CaptureMenuViews.swift,ShieldUITests/ShieldLaunchTests.swift,Shield/Premium/PremiumManager.swift,Shield/Cloud/CloudSyncManager.swift,Shield/Views/Capture/CaptureOCRServices.swift,Docs/legal/privacy.html
   Note: Auditoría integral completada con éxito. Hit targets >= 44pt corregidos en componentes de captura, editor y onboarding. Telemetría y error classification en StoreKit/RevenueCat completados. Diccionarios de CloudKit con duplicados blindados con uniquingKeysWith. Pipeline OCR conectado a selección de motor/preprocesamiento. Documento de privacidad actualizado con CloudKit privado. Suite completa de 29 UI Tests y 41 Unit Tests 100% verde con 0 fallos. Preflight App Store validado.
   Detail: tasks/details/125-audit-remediation-and-stability.md
   Claimed by: CODEX
   Claimed at: 2026-08-17T18:09:37Z
   Done by: CODEX
   Done at: 2026-08-17T21:34:28Z

126. premium-icon-composer-selector
   Id: 126-premium-icon-composer-selector
   Scope: Settings, AppIcon, Premium, Homogeneous UI
   Files: Shield/Models/AppIconOption.swift,Shield/ViewModels/AppState.swift,Shield/Views/Settings/AppIconPickerView.swift,Shield/Views/Settings/SettingsDestinationViews.swift,Shield/Views/Components/SplashView.swift,Shield/Resources/Info.plist,Shield.xcodeproj/project.pbxproj,ShieldTests/AppIconTests.swift
   Note: Finished: Pro icon composer alternate app icon system with free preview, settings picker, and dynamic in-app brand identity
   Detail: tasks/details/126-premium-icon-composer-selector.md
   Claimed by: CODEX
   Claimed at: 2026-08-18T17:58:12Z
   Done by: CODEX
   Done at: 2026-08-18T18:08:14Z

127. update-build-103202608181-archive-upload
   Id: 127-update-build-103202608181-archive-upload
   Scope: Update build number to 103202608181, archive, upload to App Store Connect and link to version 1.0.3
   Files: Shield.xcodeproj/project.pbxproj
   Note: Build 103202608181 archived, uploaded, processed, and successfully attached to version 1.0.3
   Detail: tasks/details/127-update-build-103202608181-archive-upload.md
   Claimed by: CODEX
   Claimed at: 2026-08-18T18:33:17Z
   Done by: CODEX
   Done at: 2026-08-18T19:05:33Z

128. update-build-103202608182-fix-appicon-zero-warnings
   Id: 128-update-build-103202608182-fix-appicon-zero-warnings
   Scope: build,assets,archive,appstore
   Files: Shield.xcodeproj/project.pbxproj,Shield/Resources/Info.plist,Shield/Resources/Assets.xcassets
   Note: Starting archive and upload with clean AppIcon and zero ITMS warnings
   Detail: tasks/details/128-update-build-103202608182-fix-appicon-zero-warnings.md
   Claimed by: CODEX
   Claimed at: 2026-08-18T19:08:07Z

