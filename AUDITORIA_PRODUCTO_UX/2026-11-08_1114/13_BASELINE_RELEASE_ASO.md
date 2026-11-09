# Baseline de release y ASO

Estado consultado el 8 de noviembre de 2026. No se modificó App Store Connect ni se intentó publicar.

| Elemento | Estado observado | Fuente / límite |
|---|---|---|
| App / bundle | MaskID / `com.romerodev.shield` | `Shield.xcodeproj/project.pbxproj` |
| Plataforma | iOS/iPadOS; iPhone+iPad; target mínimo 18.0 | Project settings; no build actual |
| Targets | Shield, ShieldTests, ShieldUITests, ShieldShareExtension, ShieldWidgetExtension | `PBXNativeTarget` |
| Otras plataformas | No watchOS target ni Mac Catalyst | Proyecto; no declarar soporte Mac |
| Versión local | 1.1.6 | `project.pbxproj:1487,1534` |
| Build local | 1162026102501 | `project.pbxproj:1468,1515` |
| Estado remoto consultado | Versión 1.1.6 `READY_FOR_SALE` / `READY_FOR_DISTRIBUTION`; build adjunto 1162026102502 `VALID`, subido el 25 octubre | App Store Connect en modo de solo lectura, consulta 8 nov 2026: `asc versions view --app 6790398619 --version 1.1.6 --include-build` |
| Divergencia de build | El proyecto local sigue en 1162026102501, uno por debajo del build remoto; las versiones local y remota coinciden en 1.1.6 | `project.pbxproj` + consulta ASC. No se cambió build setting; no se verificó que el binario remoto corresponda al contenido del working tree |
| Git | `main`, HEAD `095776b`; working tree preexistente sucio | Estado inicial `git status --short`; esta auditoría añade carpeta y tarea 249 |
| Xcode | 27.2, build 27B52 | `xcodebuild -version`; no compilation |
| SDK/deployment | iOS/iPadOS, deployment 18.0; orientations portrait/landscape en iPhone y todas en iPad | Configuración del proyecto |
| Swift/package pins | Swift 5 mode; AppEngagementKit local, Lottie 4.6.1, RevenueCat 5.81.1, Firebase 12.16.0 | Project + `Package.resolved`; resolución/build no se validó |
| Capacidades | App Intents, Share Extension, WidgetKit, CloudKit/iCloud KVS, Keychain, StoreKit/RevenueCat, Firebase | Entitlements/código; servicios runtime no ejercitados |
| Localizaciones | Recursos en inglés/español; otras lenguas no confirmadas | `.xcstrings` y UI tests localizados |
| SDKs analítica/diagnóstico | Firebase Analytics Core y Crashlytics declarados; docs describen analytics opt-in/off por defecto | `FirebaseIntegration.swift`, docs; estado publicado no verificado |
| Modelo comercial local | Free: 10 procesamientos acumulativos y exportación estándar; Pro escala/batch/controles | `PRODUCT_POSITIONING.md`, `PremiumManager.swift`; compra/restore no ejecutados |
| Identificadores IAP | monthly, annual, lifetime y event annual en código | RevenueCat/StoreKit config local; estado de productos ASC actual NO VERIFICADO |
| URLs de privacidad/soporte | Código usa `https://lbernardo-dev.github.io/apps/` con rutas EN `en/case-studies/shield/...` y ES `es/casos/shield/...` | `ShieldPublicPage` en `SettingsDestinationViews.swift:6-46`; disponibilidad web no comprobada |
| Metadata/copy | posicionamiento actualizado WIP; `APP_STORE_METADATA_DRAFT.md` se declara snapshot histórico y advierte estado anterior | Fuente local, no ficha publicada |
| Capturas ASO | Docs apuntan a recursos iPhone/iPad ES/EN y manifest 1.1.2; no se enumeraron ni inspeccionaron visualmente en esta ejecución | No se generaron capturas; no se afirma que correspondan al binario actual |
| Métricas | No disponibles en este turno | ASC/Analytics no consultados; no hay datos de uso para justificar retiradas |
| Estado ASC | Verificación de lectura completada; no se modificaron ficha, builds, metadata ni publicación | Autenticación ASC operativa el 8 nov 2026. El error -50 registrado el 7 nov no impidió la consulta posterior. Productos IAP, precios y metadata de la ficha no se consultaron |

## Señales comerciales verificables localmente

El copy local explica revisión de máscaras, límites de detección y diferencia Free/Pro. Ningún precio o descuento actual se verificó contra storefront; no inferir urgencia engañosa ni transparencia del checkout sin ejecución. Las notas de revisión y estados de publicación requieren reconciliación externa en una tarea de release autorizada. Para el siguiente release, elevar `CURRENT_PROJECT_VERSION` por encima de 1162026102502 después de confirmar el origen del build remoto y el árbol de código que se pretende publicar.

