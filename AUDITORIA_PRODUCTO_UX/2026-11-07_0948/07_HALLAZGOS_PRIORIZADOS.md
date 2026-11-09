# Hallazgos priorizados

Prioridad considera impacto, alcance y evidencia. No hay P0/P1 demostrados.

## THEME-002 — Sonido estacional activo por defecto (P2)

Hecho: preferencia sin valor almacenado produce true; Halloween activo + foreground inicia soundscape. Copy dice apagado por defecto y comentario dice habilitación explícita. Ruta: Shield/Theme/ShieldTheme.swift:436-438, 743-751, 861-897; Shield/Localization/Strings/Settings.xcstrings:1766-1771. Reproducción estática: preferencia vacía durante periodo Halloween → código programa audio; no ejecutado. Impacto potencial en personas sensibles; alcance condicional. Confianza alta en código/copy, media en alcance. Propuesta: default false y opt-in. Aceptación: instalación limpia no emite audio y preferencia persiste.

## PRIV-001 — Disclosure del contador sincronizado (P2)

Hecho: contador de cuota escrito en Keychain, UserDefaults e iCloud KVS. Facts de privacidad describen documentos cifrados y sync opcional pero omiten el contador. Ruta: PremiumManager.swift:279-281, 817-830, 921-995; Docs/PRIVACY_POLICY_PRODUCT_FACTS.md:6-8. No demuestra exposición de contenido. Impacto: expectativa de sincronización/alcance de datos. Confianza alta en almacenamiento, media en impacto editorial. Propuesta: explicar contador, finalidad y comportamiento de sync desactivada. Aceptación: disclosure y conducta coinciden.

## PRIV-002 — Clasificación del contador en iCloud KVS (P2; detectado durante ejecución)

- **Hecho:** SecureQuotaStore escribe un entero de cuota en NSUbiquitousKeyValueStore. Apple documenta que KVS comparte datos entre dispositivos de la misma cuenta y almacena el valor local sin cifrar; recomienda no usarlo para información personal o sensible.
- **Ruta:** Shield/Premium/PremiumManager.swift:925-995; [documentación de Apple](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore).
- **Alcance:** solo el contador entero, sin contenido ni ID documental. No hay evidencia de exposición de documentos. Si el contador de actividad se considera dato personal, el tratamiento requiere revisión.
- **Confianza:** alta en la conducta de plataforma/código; media en la clasificación del contador.
- **Decisión:** el usuario autorizó conservar KVS únicamente para el entero de cuota agregado, manteniendo disclosure explícito. No se sincroniza contenido documental por este mecanismo.
- **Siguiente verificación:** confirmar con iCloud disponible que el valor continúa siendo solo el contador; probar misma cuenta en dos dispositivos, cambio de cuenta y comportamiento offline. No se necesita migración mientras esos escenarios y el criterio de privacidad se mantengan.
- **Aceptación:** decisión documentada (hecho) y consistencia entre dispositivos/offline confirmada (pendiente).

## ACC-001 — Falta E2E accesible de tarea central (P2)

Hecho: el primer intento AX5 sin firma y con paralelismo activo declaró `editor.tool.rect` no `hittable`; el rerun firmado/sin paralelismo pasó el toolbar y el acceso a PDF. No se aisló la causa inicial ni se cambió el layout. El E2E se amplió después para generar un PDF, exponer el estado verificado a tecnologías asistivas y volver a Home; la nueva versión sigue pendiente de ejecución. Ruta: ShieldUITests/ShieldLaunchTests.swift y Shield/Views/Editor/ExportFormViews.swift. Impacto: la causa de prueba inicial no quedó confirmada; aún falta validar la tarea de exportación y estado accesible completos. Confianza media. Propuesta: ejecutar test ampliado y luego hacer recorrido VoiceOver manual. Aceptación: fixture completa exportación en AX5 con status de verificación accesible y VoiceOver confirma recorrido/foco.

## THEME-001 — Control de apariencia base (P2)

HEAD programa temas por fecha; nueva instalación automática, selección manual/base Pro. Ruta HEAD: Shield/Theme/ShieldTheme.swift:271-276, 302-305, 358-370. El WIP task 247 añade preferencias/consentimiento, pero no es HEAD ni runtime verificado: Shield/Theme/ShieldTheme.swift, AppState.swift, HomeView.swift, SplashView.swift, SettingsDestinationViews.swift, tasks/details/247-seasonal-theme-consent.md. Impacto en predictibilidad y control Free, dependiente de evento. Confianza alta en HEAD. Propuesta: Base gratuita, eventos reversibles. Aceptación: elección persiste tras reinicio/fin de evento.

## UX-001 — Categorías compactas sin texto visible (P3)

HomeView.swift:531-538; HomeCategoryChip :1221-1256 omite texto con showsLabel=false pero conserva accessibilityLabel. Dynamic Type accesible sí muestra texto (:539-548). Impacto no medido, confianza alta en implementación. Probar descubribilidad antes de modificar.

## UX-002 — Herramientas del editor icon-only (P3)

EditorChromeViews.swift:338-390: siete herramientas en banda desplazable; labels/hints/estado seleccionado presentes. La prueba AX5 confirmó nombres/altura, pero reprodujo el botón rect no hittable. Riesgo de descubribilidad visual sigue sin medir; mantener acciones y corregir primero el alcance táctil.

## DOC-001 — Consentimiento analítico descrito como primer inicio (P2)

En el snapshot de fase 1, `APP_STORE_METADATA_DRAFT.md`, `Docs/legal/privacy.html` y `Docs/ANALYTICS_TRACKING_PLAN.md` afirmaban elección al primer inicio, mientras la hoja solo aparecía con argumento de test. En fase 2 se corrigieron esas fuentes y el test runtime de onboarding confirmó Home sin prompt temprano. La política publicada sigue sin verificarse; mantener pendiente la reconciliación ASC/publicación. Confianza alta en corrección local, desconocida en publicación externa.

## PROD-001 — Público “equipos” ambiguo (P3)

PRODUCT_POSITIONING.md:5 y :23 menciona equipos aunque colaboración figura como futuro. Aclarar copy/alcance; no inferir necesidad colaborativa actual.

## OPS-001 — Baseline local de release inconsistente (P3)

APP_STORE_METADATA_DRAFT.md:3,24-26 habla de 1.1.1/1.1.2; ASO_BASELINE_MASKID_2026-10-23.md:5-7 refiere 1.1.5; task 245 cita 1162026102502 en revisión; proyecto contiene 1.1.6/1162026102501. ASC inaccesible. Está demostrada la inconsistencia local, no el estado externo actual. Sin impacto de usuario afirmado.

