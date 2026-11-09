# Calidad técnica y pruebas

## Arquitectura observada

SwiftUI, targets universales iPhone/iPad, iOS 18.0; no aparece target watchOS ni Catalyst (Shield.xcodeproj/project.pbxproj:1468-1501). Existen WidgetKit, Share Extension, App Intents, CloudKit/iCloud KVS, Firebase, RevenueCat y Lottie en fuentes/configuración. Integraciones no ejercitadas. Versión local 1.1.6; bundle com.romerodev.shield; build configurado 1162026102501.

SecureQuotaStore lee/escribe contador de documentos procesados en Keychain, UserDefaults local y NSUbiquitousKeyValueStore (PremiumManager.swift:279-281, 817-830, 921-995). Es contador escalar, no contenido de documentos. Riesgo: expectativa/disclosure multi-device, no fuga de contenido demostrada.

## Evidencia inicial (fase 1)

Hay 19 archivos de tests unitarios y un archivo UI en inventario estático; no se recalculó cobertura de líneas. Se ven casos de export verifier, importación, OCR, migraciones, seguridad, cuota, suscripciones, widget y UI. Hay tests ES/EN, AX5 limitado y aserción de Home sin gate inicial. Suite no ejecutada en esta fase.

- Xcode 27.2 (27B52).
- xcrun simctl list devices available falló: CoreSimulatorService “connection became invalid”. UDID, runtime y ocupación no determinables.
- xcodebuild -list -project Shield.xcodeproj no completó resolución de paquetes por cachés/servicio CoreSimulator.
- En esta fase no se compiló, instaló ni lanzó.
- asc auth status no pudo listar credenciales (error -50); ASC no consultado.
- No se logró verificar una ficha pública.

En esta fase no se usó simulador alternativo. La matriz de proyecto exige descubrir iPhone 18 Pro y confirmar ocupación antes de validación. Duo, iPad y Watch tampoco pudieron inventariarse.

## Riesgos a verificar

Integridad de redacción en PDF/metadatos/capas; conservación ante fallo o cancelación; sincronización de cuota offline y entre cuentas; migración de preferencias; restore de RevenueCat; accesibilidad de tarea central y Share Extension.

## Higiene y estado Git

Estado inicial: main en 095776b con cambios previos en ContentView, Settings.xcstrings, ShieldTheme, AppState, SplashView, HomeDashboardViews, HomeView, SettingsDestinationViews, EnhancementFeaturesTests y tasks/TASKS.md; sin seguimiento: archivo “-” y tasks/details/247-seasonal-theme-consent.md. Esa fase no tocó producto/tests. No se limpiaron temporales ni se alteraron artefactos ASC.

## Ejecución posterior (fase 2)

El primer ciclo real se ejecutó en iPhone 18 Pro (`CCC41661-BB97-41D2-87E2-D47FC51B1C6B`, iOS 27.2): 37 tests, 34 aprobados y 3 fallidos. Home quick access, onboarding sin gate y el nuevo default de audio aprobaron. Se reprodujo un toolbar editor no hittable en AX5; un error de migración por reloj real, ya corregido para usar reloj inyectado; y un test de persistencia que debe repetirse con firma de simulador porque el primer build usó `CODE_SIGNING_ALLOWED=NO`. El comando dejó paralelismo activo y XCTest ejecutó en un clon.

El siguiente ciclo debe usar el UDID principal explícito, `-parallel-testing-enabled NO` y firma ad-hoc habilitada; solo cuando el simulador vuelva a estar libre. En el recheck siguiente Expirely ocupa el iPhone 18 Pro y `personalcare` sigue en Duo/iPad. No se aprobó la tarea completa importar → máscara → exportar. Ver `15_EJECUCION_FASE_02.md` y el `.xcresult` citado allí.

