# Auditoría integral de MaskID

Fecha: 23 de septiembre de 2026  
Alcance: auditoría read-only del repositorio y de la build local. No se ha modificado código de la app, configuración de firma, cuentas ni servicios externos.

## 1. Evaluación ejecutiva

La app tiene una base funcional amplia y razonablemente estructurada: target principal SwiftUI, extensiones de Share y Widget, almacenamiento de imágenes cifrado con AES-GCM, claves en Keychain vinculadas al dispositivo, límites explícitos para importaciones, consentimiento de analítica opcional y una suite de pruebas moderna con Swift Testing.

El estado actual no debe considerarse listo para una nueva distribución sin resolver al menos estos bloqueadores:

1. `DocumentStore` escribe metadatos de documentos en JSON legible dentro de `Documents` y `AppState.persistDocuments()` lo ejecuta en cada cambio. Esto contradice el modelo de privacidad y expone títulos, OCR, redacciones y metadatos si el contenedor se extrae.
2. El flujo principal de abrir y cerrar Captura falla de forma reproducible en iPhone 18 Pro: no aparece `capture.close` cinco segundos después de entrar en Captura.
3. La suite de localización falla en el caso de retención/conversión por un contrato de claves que no coincide con los catálogos actuales; además, el resultado cambia al aislar un único test, señal de fragilidad del arnés.
4. La compilación produce advertencias de aislamiento de actor que ya indican “this is an error in the Swift 6 language mode” en procesamiento/exportación, además de capturas no `Sendable` en Share Extension.

No se ha confirmado ningún P0. Los P1 anteriores sí son suficientemente importantes para bloquear una fase de correcciones y una nueva validación de release.

## 2. Alcance y método

Se revisaron las instrucciones del repositorio y el backlog mediante `AGENTS.md`, `README.md`, `Docs/ARQUITECTURA.md`, `tasks/TASKS.md` y la tarea de auditoría 187. Se aplicaron las guías relevantes de:

- `swiftui-expert:swiftui-expert-skill`.
- `swiftui-specialist` y `swiftui-whats-new-27`.
- `uikit-app-modernization`.
- `modernize-tests`.
- `audit-xcode-security-settings`.
- `app-intents-specialist` y `app-intents-whats-new-27`.
- `device-interaction`.

No se aplicaron `adopt-c-bounds-safety` porque no hay fuentes C, C++, Objective-C ni Objective-C++; tampoco `building-document-based-swiftui-applications` porque no hay `DocumentGroup`, `FileDocument`, `ReferenceFileDocument`, `DocumentReader` ni `DocumentWriter`. El `Document.swift` del dominio no es una app basada en documentos.

Las etiquetas usadas son:

- **Confirmado:** observado en código, compilación, prueba o ejecución.
- **Riesgo por verificar:** indicio técnico que necesita una prueba dirigida antes de convertirlo en defecto.
- **Mejora opcional:** beneficio concreto, pero no un fallo demostrado.

## 3. Arquitectura y superficie verificada

### Targets y producto

- `Shield`: app iOS, bundle `com.romerodev.shield`, producto `MaskID`, versión 1.1.0, build 1102026092201.
- `ShieldShareExtension`: extensión de compartir.
- `ShieldWidgetExtension`: WidgetKit y App Intents de widget.
- `ShieldTests`: pruebas unitarias/integración.
- `ShieldUITests`: 33 pruebas UI XCTest.
- No hay target watchOS. El emparejamiento del simulador Apple Watch existe, pero no hay binario watchOS que instalar.
- No hay Mac Catalyst.
- App y extensiones declaran iOS 18.0 en sus configuraciones de target. Las configuraciones de proyecto Debug/Release conservan `IPHONEOS_DEPLOYMENT_TARGET = 17.0` en `Shield.xcodeproj/project.pbxproj:1422` y `:1470`; es una deriva de configuración que debe normalizarse o documentarse.
- El proyecto usa Swift 5 mode con `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` en la app y extensiones. El compilador usado fue Swift 6.4 de Xcode 27.

### Dependencias

Según `Package.resolved`:

- Firebase iOS SDK 12.16.0, incluyendo Analytics Core y Crashlytics.
- RevenueCat 5.81.1.
- Lottie 4.6.1.
- `AppEngagementKit` como paquete local, iOS 16.
- Dependencias transitivas de Firebase y Google quedan fijadas en el lockfile.

`Docs/ARQUITECTURA.md` dice que no hay dependencias externas y que la app usa iOS 17+, por lo que está desactualizado respecto al proyecto real. No se tomó ese documento como evidencia de configuración.

### Flujos principales identificados

- Onboarding, elección de analítica y objetivo de uso.
- Home y navegación por pestañas.
- Captura, importación de imágenes/PDF, revisión, OCR, edición, redacción y exportación.
- Biblioteca y Bóveda con autenticación/biometría.
- Categorías, ajustes, feedback y paywall/StoreKit.
- Share Extension para enviar imágenes/PDF a la app.
- Widget con métricas agregadas y accesos de App Intent.
- Sincronización CloudKit opt-in y proveedores OAuth externos.

### Datos y seguridad observados

Hay dos diseños simultáneos para documentos:

- `SecureFileStore` usa AES-GCM, claves de 256 bits en Keychain con `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` y `FileProtectionType.complete` (`Shield/ViewModels/AppState.swift:881-1000`).
- `DocumentStore` usa JSON sin cifrar en `Documents/shield_documents` (`Shield/Models/DocumentStore.swift:15-18,42-47,59-66`).

La existencia del segundo camino es el problema principal de privacidad descrito abajo. Los activos de imagen, el buzón de Share Extension y los payloads de métricas presentan controles de cifrado/protección mejores, pero no sustituyen la corrección del almacén de metadatos.

## 4. Validación realizada

### Herramientas y dispositivo

- Xcode 27.0 (`27A266a`), SDK iOS 27.0, Swift 6.4.
- Dispositivo principal obligatorio: **iPhone 18 Pro**, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`, runtime iOS 27.0. Estaba disponible; no hubo espera en cola.
- iPad representativo: **iPad Pro 13-inch (M5)**, UDID `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`, runtime iOS 27.0.
- No existe un simulador **iPhone Duo**.
- Existe emparejamiento Apple Watch Series 12 42 mm + iPhone 18 Pro, runtime watchOS/iOS 27.0, pero el proyecto no contiene target watchOS.
- Las pruebas UI de Xcode ejecutaron el destino solicitado usando un clon del iPhone 18 Pro (`Clone 1 of iPhone 18 Pro` en el resultado). La instalación y ejecución manual del iPad usaron el UDID exacto indicado.

### Compilación y pruebas

Se ejecutó el flujo del repositorio con `scripts/xcbuild.sh`, configuración Debug, esquema `Shield`, destino explícito de iPhone 18 Pro y `SWIFT_STRICT_CONCURRENCY=complete`.

Resultado:

- La app y sus targets compilan.
- La suite completa termina con estado 65 por fallos de tests.
- `ShieldUITests`: 32 pruebas pasan y 1 falla: `ShieldLaunchTests.testPrimaryTabNavigationAndCaptureDismissal`.
- `ShieldTests`: la suite de localización falla en `LocalizationLanguageTests.retentionAndConversionLocalizationKeys`; el resto de las pruebas observadas pasa. El informe de la suite aislada enumera repetidamente el mismo caso.
- Una invocación que seleccionó solo ese método devolvió éxito, mientras que la suite de la clase y la suite completa fallaron. Esto no invalida el fallo de la suite; evidencia una interacción o no determinismo del arnés que debe corregirse.
- El test de productos StoreKit quedó omitido porque no había un producto disponible en el entorno local. No se verificó el flujo real de compra.
- La compilación emite advertencias de concurrencia/actor isolation detalladas en la sección de hallazgos.

También pasaron:

- `scripts/app_store_preflight.sh --local`.
- Validación `plutil -lint` de plist y entitlements revisados.

### Ejecución visual

La build compilada se instaló y lanzó en el iPad Pro 13-inch (M5). La app llegó a la pantalla de onboarding de elección de analítica y se capturó pantalla; no se observaron fallos de arranque. No se completó manualmente todo el flujo en iPad ni se validaron rotación, multitarea, Dynamic Type o VoiceOver en ese dispositivo.

El flujo de navegación principal sí se ejercitó por UI test en iPhone 18 Pro y el cierre de Captura falló de manera reproducible.

No se modificaron fuentes, dependencias, firma, cuentas ni servicios externos. Se conservaron los logs, bundles de resultados y caches de build; no se ejecutó limpieza destructiva.

## 5. Hallazgos priorizados

### Errores confirmados

#### AUD-001 — P1 alto — Metadatos de documentos guardados en texto plano

**Evidencia:** `Shield/Models/DocumentStore.swift:15-18` crea `Documents/shield_documents`; `:42-47` lee JSON directo y `:59-66` escribe JSON pretty-printed sin cifrar. `Shield/ViewModels/AppState.swift:765-769` llama a `DocumentStore.shared.saveAllDocuments(documents)` en cada persistencia y, además, escribe una copia cifrada.

**Escenario y efecto:** al crear, editar, proteger o borrar un documento se actualiza el almacén plano. El contenido estructural de `DocumentItem` —título, categoría, OCR, redacciones, marcas de tiempo y otros metadatos— queda recuperable aunque las imágenes estén cifradas. Esto contradice el mensaje de protección local y amplía la superficie de exposición en copias, diagnóstico o extracción del contenedor.

**Corrección recomendada:** definir un único almacén canónico cifrado; conservar una migración explícita y versionada para instalaciones existentes; verificar la lectura de datos antiguos, reescribirlos cifrados y eliminar el JSON plano solo después de confirmar la migración. Retirar el fallback plano una vez agotada la ventana de compatibilidad. Auditar también categorías y cualquier archivo legado.

**Validación:** prueba de migración con documentos representativos; comprobar que los bytes de los archivos persistidos no contienen títulos/OCR conocidos; comprobar atributos de protección; reiniciar la app y verificar lectura, actualización, borrado y recuperación de datos migrados.

**Esfuerzo/dependencias:** L, 2–4 días. Depende de decidir la política de migración y de añadir fixtures de datos v1/legacy; no requiere servicios externos.

#### AUD-002 — P1 alto — El flujo principal no muestra el cierre de Captura

**Evidencia:** `ShieldUITests/ShieldLaunchTests.swift:248-285` abre Home, recorre pestañas, entra en Captura y espera `app.buttons["capture.close"]` en `:279-280`. La prueba aislada falló en esa línea con `XCTAssertTrue failed`; la suite completa registró el mismo fallo en `build/logs/CODEX/test.log:14952`.

**Escenario y efecto:** tras tocar `tab.capture`, el usuario no dispone del control de cierre que el flujo y la prueba esperan dentro de cinco segundos. Puede quedar atrapado en Captura o la pantalla puede estar en un estado incompleto. La causa exacta —presentación, onboarding, estado de permisos, carga o accesibilidad— todavía necesita diagnóstico dirigido.

**Corrección recomendada:** reproducir con logs de navegación y árbol de accesibilidad; separar explícitamente estados de carga, error y contenido de Captura; asegurar que el botón de cierre exista y tenga identidad estable en todos los estados que el usuario puede alcanzar. No aumentar el timeout sin entender la causa.

**Validación:** repetir el test aislado y la suite completa en un simulador limpio y en una segunda ejecución; cubrir entrada desde Home, cancelación, permisos no concedidos, importación y retorno a Home. El criterio es que el botón aparezca, sea hittable, cierre Captura y restaure la barra de pestañas.

**Esfuerzo/dependencias:** M, 1–2 días para diagnóstico/corrección y 0.5–1 día para pruebas. Depende de la causa concreta.

#### AUD-003 — P1 alto — Contrato de localización roto y suite no determinista

**Evidencia:** `ShieldTests/LocalizationLanguageTests.swift:68-107` exige claves como `editor_sha256_hash`, `editor_pro_features_title`, `editor_try_pro_free`, `home_quota_warning` y `ob_goal_pro_*`. Los catálogos actuales contienen `home_quota_warning_title`/`_desc` en `Shield/Localization/Strings/Home.xcstrings:1772-1789` y `editor_reset_zoom` en `Shield/Localization/Strings/Editor.xcstrings:3687`, pero no las claves exigidas con esos nombres. La suite aislada de la clase falla; el log lo refleja en `build/logs/CODEX-localization-suite/test.log:13573-13581`.

**Escenario y efecto:** CI o una puerta de release puede quedar bloqueada aunque el producto compile. Si una clave llega a una pantalla en producción, `LanguageManager` puede devolver la propia clave como texto visible. El hecho de que seleccionar solo un método haya pasado y ejecutar la clase haya fallado muestra además que la prueba depende del contexto de ejecución.

**Corrección recomendada:** decidir por cada clave si falta implementación o si el test quedó obsoleto; alinear catálogo, código y test con nombres canónicos. Hacer el test determinista: evitar compartir/mutar `LanguageManager.shared.current` entre tests, serializar la suite si es imprescindible o inyectar un resolver aislado. No “arreglar” el test simplemente aceptando claves inexistentes.

**Validación:** ejecutar la clase y la suite completa varias veces; verificar ES y EN con una lista derivada de los catálogos o del código real; comprobar que ninguna pantalla muestra el identificador de una clave.

**Esfuerzo/dependencias:** M, 1–2 días. Depende de producto para decidir el copy que falta y de confirmar si las claves representan features retiradas.

#### AUD-004 — P1 alto — Advertencias de aislamiento que serán errores en Swift 6

**Evidencia de compilación con `SWIFT_STRICT_CONCURRENCY=complete` en `build/logs/CODEX/test.log`:

- `Shield/Views/Capture/CaptureImportViews.swift:136`: la conformidad de `GuideFrameCutout` con `Shape` cruza aislamiento de MainActor y el compilador avisa que será error en Swift 6 (`:11140-11144`).
- `Shield/Export/ThumbnailManager.swift:42`: llamada a método estático aislado en MainActor desde fuera del actor (`:11162-11166`).
- `Shield/Export/DocumentProcessor.swift:20` y `:72`: llamadas a métodos MainActor desde contexto actor síncrono (`:11170-11190`).

**Escenario y efecto:** al migrar el lenguaje o endurecer el proyecto, la app puede dejar de compilar; antes de eso, el diseño actual mezcla trabajo de UI, procesamiento de imágenes y aislamiento de actores de forma difícil de razonar. El riesgo incluye bloqueos de UI o carreras si se relajan anotaciones para silenciar el compilador.

**Corrección recomendada:** clasificar cada función como UI/MainActor o trabajo puro no aislado; mover procesamiento de imagen a tipos `Sendable`/actores apropiados; cruzar actores con `await`; evitar `@unchecked Sendable` salvo invariantes demostradas. Corregir la Shape con una conformidad compatible con el aislamiento del SDK.

**Validación:** volver a compilar con concurrencia estricta y warnings tratados como errores en una rama de validación; probar importación, thumbnails, exportación y cancelación; usar Thread Sanitizer cuando el flujo lo permita.

**Esfuerzo/dependencias:** L, 2–4 días. Depende de separar correctamente la frontera de UI y de procesamiento.

### Riesgos por verificar

#### AUD-005 — P2 — Importación y guardado pesado ejecutados desde una tarea de UI

**Evidencia:** `Shield/Views/Capture/CaptureView.swift:539-587` crea una `Task` y recorre todas las páginas llamando a `appState.saveImage`; `Shield/ViewModels/AppState.swift:524-537` ejecuta `UIImage.jpegData` y escritura cifrada de forma síncrona. La app fuerza aislamiento MainActor en el target (`Shield.xcodeproj/project.pbxproj:1519`), por lo que el trabajo puede quedar en el hilo principal. `Shield/Views/Capture/ImportPipeline.swift:32-39,89-107` sí limita tamaño, páginas, píxeles, memoria y cancelación.

**Escenario y efecto:** PDFs de muchas páginas pueden congelar animaciones, retrasar la navegación o parecer bloqueados aunque la importación tenga progreso.

**Corrección recomendada:** medir primero con Time Profiler y signposts; después mover codificación/escritura a una frontera no-UI cancelable, manteniendo solo estado/progreso en MainActor.

**Validación:** importar 1, 10 y 50 páginas en iPhone 18 Pro; registrar tiempo de primera respuesta, memoria, FPS aproximado y cancelación. No aceptar una regresión de cifrado ni de recuperación parcial.

**Esfuerzo/dependencias:** M/L, 2–4 días después de la medición.

#### AUD-006 — P2 — Cobertura de accesibilidad con señales de elementos potencialmente inaccesibles

**Evidencia:** los tests UI de auditoría imprimieron avisos `ACCESSIBILITY AUDIT ... Potentially inaccessible ... <no element>` y avisos OCR ES/EN, pero no convierten esas señales en fallos. La suite pasó esos casos.

**Escenario y efecto:** botones, controles decorativos o labels pueden ser invisibles a VoiceOver, tener un tamaño insuficiente o perder significado con Dynamic Type aunque el test visual básico pase.

**Corrección recomendada:** convertir los avisos relevantes en aserciones dirigidas; revisar agrupación, labels, hints, traits, contraste, escalado de texto y orden de navegación. Mantener elementos decorativos fuera del árbol.

**Validación:** auditoría de accesibilidad en Home, Captura, Revisión, Editor, Bóveda, Paywall y Ajustes en ES/EN, tamaños de texto grandes, VoiceOver y modo oscuro en iPhone y iPad.

**Esfuerzo/dependencias:** M, 1–3 días. Depende de priorizar los escenarios de lanzamiento.

#### AUD-007 — P2 — Anchor de OAuth dependiente de una selección global de escenas

**Evidencia:** `Shield/Cloud/DirectCloudStorageManager.swift:89-94` recorre `UIApplication.shared.connectedScenes`, todas sus ventanas y el primer `isKeyWindow`.

**Escenario y efecto:** en multi-window, durante una transición o con más de una escena activa, la autenticación puede intentar presentarse desde una ventana incorrecta y fallar o mostrarse fuera de contexto.

**Corrección recomendada:** inyectar el `UIWindowScene`/anchor asociado a la acción actual y devolver un error controlado si no hay una escena válida; conservar el camino UIKit porque aquí sí es apropiado para `ASWebAuthenticationSession`.

**Validación:** probar login desde la escena activa, con dos ventanas y después de background/foreground; probar cancelación y retorno de error.

**Esfuerzo/dependencias:** S/M, 0.5–1.5 días.

#### AUD-008 — P2 — Ajustes de seguridad de Xcode no establecen una línea base explícita

**Evidencia:** el proyecto tiene `ENABLE_USER_SCRIPT_SANDBOXING = YES` y varios warnings Clang, pero no declara explícitamente `SWIFT_STRICT_CONCURRENCY`, `ENABLE_ENHANCED_SECURITY`, `ENABLE_POINTER_AUTHENTICATION` ni warnings-as-errors en `project.pbxproj`. La compilación actual ya muestra warnings de concurrencia.

**Escenario y efecto:** la postura de diagnóstico puede depender de defaults de Xcode y cambiar al actualizar el toolchain; los warnings críticos pueden no bloquear una build de release.

**Corrección recomendada:** definir una política por configuración y target: concurrencia estricta progresiva, warnings críticos como errores cuando el código esté preparado, Static Analyzer y opciones de hardening compatibles con iOS 18 y el hardware soportado. No activar flags a ciegas ni convertir esta recomendación en un cambio de firma.

**Validación:** comparar Debug/Release en CI, ejecutar analyzer, revisar el diff de warnings y verificar archivado sin alterar provisioning.

**Esfuerzo/dependencias:** M, 1–2 días de baseline más correcciones derivadas. Depende del umbral de warnings que el equipo quiera aceptar.

#### AUD-009 — P2 — App Intents usa una API obsoleta en el SDK actual

**Evidencia:** `Shield/App/ShieldAppIntents.swift:15,34` y `ShieldWidgetExtension/ShieldWidgetExtension.swift:23,34,45` usan `static let openAppWhenRun = true`.

**Escenario y efecto:** el código funciona con el target actual, pero queda expuesto a deprecación/compatibilidad en SDK 26/27 y puede no expresar correctamente qué intents necesitan foreground. El preset del widget usa `String` (`ShieldWidgetExtension/ShieldWidgetExtension.swift:47-55`) en lugar de una selección tipada.

**Corrección recomendada:** migrar a `supportedModes` y las APIs de continuación/foreground solo bajo disponibilidad compatible; conservar fallback para el mínimo real iOS 18. Considerar `AppEnum` para presets si mejora el discoverability. No elevar el mínimo de iOS solo para eliminar esta advertencia.

**Validación:** compilar con SDK 27 y mínimo iOS 18; ejecutar Shortcuts/widget en foreground, background y con autenticación; revisar metadatos de App Intents.

**Esfuerzo/dependencias:** M, 1–2 días. Depende de definir el comportamiento esperado cuando la app está bloqueada.

#### AUD-010 — P2 — Deriva de API y configuración SwiftUI/UIKit

**Evidencia:** `Shield/Views/Vault/VaultView.swift:431` usa `NavigationView`, API que conviene modernizar para el SDK actual. Hay usos `ForEach(Array(...enumerated()), id: \.offset)` en `Shield/Views/Capture/CaptureImportViews.swift:87`, `Shield/Views/Paywall/PaywallView.swift:187` y `Shield/Views/Capture/CaptureReviewViews.swift:762`.

**Escenario y efecto:** `NavigationView` mantiene semántica menos explícita en iPad y puede complicar rutas futuras. Los índices como identidad son seguros solo mientras la colección sea fija y no reordenable; si cambia durante una actualización, pueden reutilizarse filas incorrectamente.

**Corrección recomendada:** migrar a `NavigationStack`/`NavigationSplitView` cuando el flujo lo justifique; dar identidad estable a modelos que puedan mutar. No cambiar cada `ForEach` por preferencia estilística: hacerlo solo donde la colección tenga ciclo de vida dinámico.

**Validación:** pruebas de navegación en iPhone/iPad, rotación y retorno; insertar/quitar/reordenar elementos en las vistas afectadas.

**Esfuerzo/dependencias:** S/M, 1–2 días y solo después de estabilizar P1.

### Mejoras opcionales

#### AUD-011 — P3 — Reducir ruido de compilación y actualizar documentación

**Evidencia:** `Shield/ViewModels/AppState.swift:168` contiene un case duplicado; `Shield/Views/Settings/SettingsDestinationViews.swift:6` almacena una closure en `@Entry` y Xcode advierte de invalidación en cada actualización; `Shield/ViewModels/HomeViewModel.swift:52` tiene una captura weak/strong inconsistente. `Docs/ARQUITECTURA.md` no refleja targets, dependencias ni mínimo real.

**Recomendación:** eliminar warnings triviales después de los P1, revisar si el `@Entry` requiere otra forma de comunicación y actualizar la documentación arquitectónica a partir del proyecto. Son mejoras de mantenimiento, no defectos de usuario confirmados.

**Validación/esfuerzo:** build limpia sin esos warnings; revisión documental. S, 0.5–1 día.

#### AUD-012 — P3 — Modernizar y ampliar la estrategia de pruebas

**Evidencia:** hay aproximadamente 98 usos de `@Test` y 33 pruebas UI XCTest, una base buena, pero el flujo de compra está omitido en este entorno y Share Extension, CloudKit/OAuth, migraciones y fallos de permisos no tienen cobertura end-to-end visible en esta auditoría.

**Recomendación:** añadir fixtures de StoreKit local, pruebas de migración cifrada, pruebas de cancelación/error de importación, matriz ES/EN, Share Extension y escenarios de escena múltiple. Mantener pruebas rápidas unitarias y reservar UI para contratos de usuario.

**Validación/esfuerzo:** cobertura de los criterios de aceptación de las fases; M/L, 2–5 días distribuidos.

## 6. Aspectos positivos que deben conservarse

- `CaptureImportPipeline` impone límites de archivo, páginas, dimensión, memoria y cancelación (`Shield/Views/Capture/ImportPipeline.swift:32-39,52-107`).
- `SecureFileStore` cifra con AES-GCM, separa claves de biblioteca y bóveda y usa Keychain device-only (`Shield/ViewModels/AppState.swift:881-1000`).
- `SharedImportStore` cifra el payload compartido y aplica protección completa al archivo temporal (`Shield/Share/SharedImportStore.swift:13-27,120-133`).
- La analítica de producto se presenta como opcional y desactivada por defecto en el flujo observado; el código de métricas mantiene límites de almacenamiento.
- Widget y App Intents exponen datos agregados, no el contenido de documentos, según el modelo revisado.
- La adopción de Swift Testing es significativa y el repositorio ya tiene preflight local para App Store.

Estos puntos reducen riesgo, pero no compensan el almacén de metadatos plano ni los P1 de pruebas/concurrencia.

## 7. Plan de correcciones por fases

### Fase 0 — Bloqueadores de seguridad, funcionalidad y release

**Objetivo:** eliminar los P1 antes de ampliar la superficie de cambios.

| Tarea | Archivos principales | Dependencias | Esfuerzo | Criterio de aceptación |
|---|---|---|---:|---|
| Diseñar y ejecutar migración a almacenamiento canónico cifrado | `Shield/Models/DocumentStore.swift`, `Shield/ViewModels/AppState.swift`, tests de persistencia | Decisión de compatibilidad con instalaciones existentes | L, 2–4 días | No quedan metadatos legibles en `Documents`; migración, reinicio, CRUD y borrado pasan; no se pierde ningún documento |
| Diagnosticar y corregir presentación/cierre de Captura | `ShieldUITests/ShieldLaunchTests.swift`, vistas/view models de Captura | Reproducción con árbol de accesibilidad y logs | M, 1–3 días | Test aislado y suite completa pasan dos veces; botón close visible/hittable y retorno a Home |
| Alinear localización, catálogos y pruebas | `ShieldTests/LocalizationLanguageTests.swift`, `Shield/Localization/Strings/*.xcstrings`, vistas que consumen las claves | Decidir copy y features vigentes | M, 1–2 días | Suite de la clase y suite completa pasan; no aparece una clave como texto en ES/EN |
| Corregir aislamiento Swift 6 | `Shield/Views/Capture/CaptureImportViews.swift`, `Shield/Export/ThumbnailManager.swift`, `Shield/Export/DocumentProcessor.swift`, `ShareExtension/ShareViewController.swift` | Diseño de fronteras actor/UI | L, 2–4 días | Concurrencia estricta sin warnings de error futuro; import/export/share pasan con cancelación |

### Fase 1 — Estabilidad y seguridad de distribución

**Objetivo:** convertir los controles de seguridad y release en garantías verificables.

| Tarea | Archivos principales | Dependencias | Esfuerzo | Criterio de aceptación |
|---|---|---|---:|---|
| Añadir pruebas de migración, cifrado y file protection | `ShieldTests`, fixtures de documentos, `AppState`/`SecureFileStore` | Fase 0 | M, 1–2 días | Fixture legacy migra una vez, queda cifrado y no se regenera plano |
| Revisar CloudKit, OAuth y política de privacidad | `Shield/Cloud/*`, `Info.plist`, `PrivacyInfo.xcprivacy`, entitlements | Decidir si el cifrado extremo a extremo es requisito | M, 1–3 días | La documentación y los controles reflejan exactamente qué datos salen del dispositivo, cuándo y cómo se recuperan errores |
| Establecer baseline de Xcode Security/Analyzer | `Shield.xcodeproj/project.pbxproj`, CI/scripts | Aceptación del umbral de warnings | M, 1–2 días | Debug/Release tienen settings explícitos; analyzer ejecutado; no se rompe firma ni archivado |
| Completar cobertura de StoreKit, permisos y Share Extension | `ShieldTests`, `ShieldUITests`, configuración StoreKit local | Fixtures y datos locales, sin servicios externos | M/L, 2–4 días | Compra, cancelación, permisos denegados y share offline tienen resultados deterministas |

### Fase 2 — Experiencia, accesibilidad y rendimiento

**Objetivo:** mejorar el comportamiento percibido sin introducir refactors de estilo.

| Tarea | Archivos principales | Dependencias | Esfuerzo | Criterio de aceptación |
|---|---|---|---:|---|
| Medir y desacoplar I/O de imágenes del MainActor | `CaptureView.swift`, `AppState.swift`, `Export/*` | Fase 0; mediciones Time Profiler | M/L, 2–4 días | Importación de 1/10/50 páginas mantiene UI responsiva, progreso y cancelación |
| Resolver accesibilidad de pantallas críticas | vistas Home/Captura/Revisión/Editor/Bóveda/Paywall/Ajustes | Decidir matriz de tamaños y VoiceOver | M, 1–3 días | Auditoría sin elementos críticos inaccesibles; labels/hints/traits, Dynamic Type, contraste y modo oscuro verificados |
| Corregir anchor multi-window OAuth | `Shield/Cloud/DirectCloudStorageManager.swift`, coordinador de escena | Definir ownership de `UIWindowScene` | S/M, 0.5–1.5 días | Login/cancelación funcionan en escena única, dos escenas y retorno de background |
| Adaptar App Intents al SDK vigente sin subir mínimo | `Shield/App/ShieldAppIntents.swift`, `ShieldWidgetExtension/ShieldWidgetExtension.swift` | Confirmar comportamiento foreground/auth | M, 1–2 días | Compila con mínimo iOS 18, comportamiento correcto en SDK 27, metadata sin warnings relevantes |

### Fase 3 — Mantenimiento y deuda técnica

**Objetivo:** reducir fragilidad futura después de la estabilización.

| Tarea | Archivos principales | Dependencias | Esfuerzo | Criterio de aceptación |
|---|---|---|---:|---|
| Normalizar deployment targets y actualizar arquitectura | `Shield.xcodeproj/project.pbxproj`, `Docs/ARQUITECTURA.md`, `README.md` | Decisión oficial de mínimo iOS | S, 0.5–1 día | Target/project settings coherentes y documentación veraz |
| Migrar `NavigationView` donde aporte valor y revisar identidades | `Shield/Views/Vault/VaultView.swift`, `CaptureImportViews.swift`, `PaywallView.swift`, `CaptureReviewViews.swift` | Fases 0–2 | S/M, 1–2 días | Navegación iPad y listas dinámicas mantienen estado e identidad correctos |
| Limpiar warnings menores y cerrar gaps de tests | `AppState.swift`, `SettingsDestinationViews.swift`, `HomeViewModel.swift`, suites de tests | Fases 0–2 | M, 2–5 días | Warnings explicados o eliminados; flujos críticos cubiertos y CI estable |

## 8. Primeras cinco acciones recomendadas

1. Tratar `AUD-001` como prioridad de privacidad: diseñar la migración y detener la escritura plana en cuanto exista la ruta segura.
2. Abrir un diagnóstico específico del fallo `capture.close`, con captura del árbol de accesibilidad y estado de presentación, antes de tocar timeouts.
3. Alinear el contrato de localización y hacer la suite determinista para recuperar una puerta de release fiable.
4. Corregir los warnings de aislamiento que ya anuncian errores de Swift 6 y los `Sendable` de Share Extension.
5. Ejecutar una medición de importación en 1/10/50 páginas y una auditoría de accesibilidad en iPhone/iPad para ordenar la Fase 2 con datos, no con suposiciones.

## 9. Decisiones que requieren criterio del equipo

- ¿La app exige cifrado extremo a extremo para CloudKit/proveedores externos o basta con almacenamiento protegido en dispositivo y el modelo actual de backend?
- ¿Cuál es la política de retención y borrado para Crashlytics, analítica opcional, compras y datos de sincronización? Debe coincidir con `PrivacyInfo.xcprivacy` y la copy visible.
- ¿Se mantiene iOS 18 como mínimo? La recomendación es no subirlo solo por `supportedModes`, `NavigationStack` u otras APIs nuevas; usar disponibilidad y fallback.
- Para localización, ¿las claves faltantes representan features que aún deben implementarse o tests obsoletos que deben retirarse?
- ¿Se quiere conservar soporte de iPad como superficie completa, incluyendo multitarea/rotación, o solo compatibilidad de arranque y layout básico?
- ¿El reloj está fuera de alcance? Actualmente no hay target watchOS, por lo que el emparejamiento del simulador no puede validar un producto de reloj.

## 10. Estado final de esta fase

- Informe y plan preparados en este archivo.
- Código de la app sin modificaciones.
- Firma, cuentas y servicios externos sin cambios.
- No se ejecutó limpieza de temporales, logs ni caches; quedan conservados para reproducibilidad. Según las instrucciones del repositorio, cualquier limpieza requiere confirmación explícita antes de ejecutarse.
- La implementación de correcciones queda pendiente de aprobación del usuario.
