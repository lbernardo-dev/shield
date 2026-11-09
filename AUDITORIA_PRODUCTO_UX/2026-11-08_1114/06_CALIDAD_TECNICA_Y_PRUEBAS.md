# Calidad técnica y pruebas

## Arquitectura relevante

- SwiftUI; app iOS/iPadOS universal, deployment 18.0; targets Shield, ShieldTests, ShieldUITests, ShieldShareExtension y ShieldWidgetExtension. App Intents se encuentran en el target principal. No se encontró target watchOS ni Mac Catalyst.
- Estado raíz en `AppState`/`AppSessionCoordinator`; navegación compacta por tabs y layout regular/sidebar; almacenamiento en `DocumentStore`/`SecureFileStore`; modelos de documentos, páginas y transformaciones.
- Entrada por cámara/Photos/Files, Share Extension y providers; OCR local mediante Vision; edición de máscaras y salida en `ExportVerifier`; Vault con claves/autenticación separadas; sincronización CloudKit/KVS opt-in/contadores.
- Paquetes declarados: AppEngagementKit local, Lottie, RevenueCat, Firebase Crashlytics y Firebase Analytics Core. No se validó la resolución/build actual en esta sesión.

## Evidencia técnica estática

- `ImportPipeline` impone límites visibles de tamaño/páginas/dimensiones/memoria, progreso y cancelación; `CaptureView` revierte temporales al cancelar. Esto demuestra defensas en código, no su éxito en dispositivo.
- `ExportVerifier` comprueba páginas/legibilidad, texto extraíble, anotaciones, metadatos sensibles y OCR residual, y puede reportar incompletitud. El posicionamiento pide revisar las regiones manualmente.
- `DocumentStore` cifra y valida persistencia; migración evita adoptar colecciones parciales si falla lectura. `AppState.deleteDocument` repone estado si falla guardar, luego quita archivos locales y agenda borrado remoto.
- Tests fuente: 20 archivos Swift unitarios (uno anidado en Export) y 1 archivo UI; temas de pruebas incluyen importación, OCR, entidades, geometría, export verifier, almacenamiento/migración, privacidad/seguridad, cuota/suscripción y widget. No se calculó cobertura de líneas.

## Resultados ejecutados realmente

**En esta auditoría:** `git diff --check` terminó sin errores; `xcrun simctl list devices available` devolvió dispositivos pero encontró varios simuladores booted y ocupación de otros proyectos. No se lanzó MaskID, no se hicieron capturas, no se compiló y no se ejecutaron tests. La consulta `xcodebuild -list` intentó resolver el grafo y emitió conflictos de caché de repositorios preexistentes; no se usó como prueba de compilación.

**Evidencia histórica previa, no ejecución de este turno:** el reporte 2026-11-07 documenta primer ciclo de 37 casos (34 aprobados, 3 fallidos); reruns firmados y sin paralelo aprobaron 34/34 `EnhancementFeaturesTests` y 1/1 del test anterior de controles de editor. Dos fallos iniciales no se reprodujeron con runner firmado/no paralelo; la migración dependiente de reloj real se corrigió y su test aprobó. El test AX5 ampliado actual que genera PDF, comprueba estado y vuelve a Home fue añadido después del rerun y quedó pendiente (`ShieldUITests/ShieldLaunchTests.swift:1482-1558`; `15_EJECUCION_FASE_02.md`). No equivale a un flujo completo de importación real.

## Riesgos de calidad vinculados a experiencia

1. No hay prueba E2E actual del resultado completo con archivo de entrada sintético, revisión manual y salida verificada.
2. No se observó VoiceOver/Voice Control en tarea central; la creación libre de máscara es gestual.
3. Cancelación, archivos inválidos, permisos denegados, offline/CloudKit, cuota cross-device y borrado Vault no fueron ejercitados en este turno.
4. Publicación ASC, versión/build remotos y metadata desplegada no están verificados.
5. No hay mediciones de latencia con documentos de referencia; el código por sí solo no permite afirmar rendimiento percibido.

## Baseline de fuente

HEAD `095776b` en branch `main`; árbol con cambios preexistentes en Docs, código, tests y TASKS. Esta ejecución no cambió fuente ni tests. Los artefactos reportados antes bajo `build/MaskID-AuditPhase02` no se limpiaron ni se modificaron.

