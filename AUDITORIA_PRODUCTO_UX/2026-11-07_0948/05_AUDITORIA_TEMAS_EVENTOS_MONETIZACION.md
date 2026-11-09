# Temas, eventos y monetización

## Temas y temporada

En HEAD el tema se programa por fecha; nuevas instalaciones usan automatic y la selección manual/base está condicionada a Pro (git show HEAD de Shield/Theme/ShieldTheme.swift:271-276, 302-305, 358-370). El comportamiento sugiere un cambio estacional sin elección previa dentro de la preferencia automática. La restauración gratuita de Base que aparece en el árbol de trabajo es parte de cambios locales no confirmados (tarea 247), no comportamiento validado o publicado.

Esto no se reprodujo visualmente. Prioridad P2 por control/previsibilidad, alcance condicionado por fecha, preferencia y versión. Propuesta: opción básica gratuita persistente y evento decorativo opcional. Aceptación: Free puede restaurar Base; rechazar evento; conservar decisión tras reinicio y fin de campaña.

## Audio Halloween

- Default true si no hay preferencia: Shield/Theme/ShieldTheme.swift:436-438.
- Se inicia con Halloween activo y app foreground (:743-751).
- Espera inicial de unos 7s y sonidos posteriores en intervalos aproximados de 16–30s (:869-877); volumen bajo y respeto de mute switch según código (:891-897).
- Localización dice “Off by default” / “Desactivado por defecto” (Settings.xcstrings:1766-1771). Comentario dice que solo corre con habilitación expresa (:861-864).
- Ajuste disponible en vista de tema y reduce efectos (SettingsDestinationViews.swift:1101-1115, 1305-1315; ShieldTheme.swift:575-579), pero requiere descubrirse. Invitación de evento describe apariencia, no audio (HomeView.swift:1122-1184).

**THEME-002 (P2):** el default, copy y comentario discrepan. Recomendación: opt-in antes de reproducir; preservar opción. Criterio: instalación limpia no emite sonido hasta elección, copy preciso y preferencia persistente.

## Free/Premium y confianza

El modelo local describe Free con límite acumulativo de 10 documentos; exportación sigue disponible; Pro escala lote/controles avanzados. No se ejecutó paywall ni ASC. No se verificó si se comunica antes del límite, ni restore/cancelación. No hay evidencia de promoción engañosa o bloqueo de exportación, pero estos estados siguen pendientes.

La revisión de Apple durante la ejecución de fase 02 añade una cautela: NSUbiquitousKeyValueStore sincroniza valores entre dispositivos de la misma cuenta y Apple indica que sus datos se guardan sin cifrar en el dispositivo; también recomienda no guardar allí datos personales o sensibles. El código usa el store solo para un entero de cuota, sin contenido ni ID documental. PRIV-002/AUD-010 requiere una decisión de producto/privacidad sobre si ese dato de uso es apropiado en KVS o si conviene una alternativa. Fuente: https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore

No se recomienda modificar el precio o abrir todo el flujo: evaluar claridad, continuidad y valor. Apple exige metadatos fieles al producto; la ficha publicada no fue verificada: https://developer.apple.com/app-store/review/guidelines/

## Consentimiento analítico

En el snapshot inicial, Firebase estaba desactivado por defecto (Shield/Observability/FirebaseIntegration.swift:7-39), el consent sheet de ContentView solo aparecía con argumento de proceso para test (ContentView.swift:223-235) y Settings > Privacy ofrecía el control (SettingsDestinationViews.swift:2749-2777). La política local y el borrador metadata afirmaban, sin embargo, elección al primer inicio. Fase 2 corrigió policy HTML EN/ES, metadata local y plan analítico; `testShortOnboardingDeliversHomeWithoutEarlyPermissionOrPaywall` pasó en iPhone 18 Pro iOS 27.2. La publicación externa sigue sin verificar por falta de ASC.

## Síntesis

Temas, sonido y monetización aplican. No hay fundamento para retirar temas. Resolver audio opt-in, restauración Base y disclosure de cuota. Compra y estado de tienda NO VERIFICADOS.

