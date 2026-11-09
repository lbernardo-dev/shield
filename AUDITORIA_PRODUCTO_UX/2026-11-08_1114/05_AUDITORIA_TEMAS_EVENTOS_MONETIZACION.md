# Temas, eventos y monetización

## Temas y control de apariencia

El estado de `main` es sucio y la capa actual no equivale necesariamente a release. En el HEAD anterior descrito por el expediente, la apariencia estacional se resolvía por fecha con selección automática; la selección Base/manual Free era distinta. El WIP local de task 247 cambia ese comportamiento: instalación sin preferencia empieza en Base, pregunta por evento, permite Base gratis, conserva decisiones por ocurrencia y separa preferencia automática futura de aceptación puntual (`Shield/Theme/ShieldTheme.swift:282-344, 410-438, 480-590`; `HomeView.swift:59-73, 302-327`; `SettingsDestinationViews.swift:1015-1142`).

El mismo WIP deja el soundscape apagado cuando no hay preferencia (`ShieldTheme.swift:435-438`), ofrece reducción de efectos y ajustes, y conserva un evento visual condicional. Aceptar/rechazar/cerrar se registran por ocurrencia. El invitador solo se presenta en Home cuando la app está lista y no hay captura, modal o búsqueda activa. En compacto aparece antes del Hero mientras una invitación esté pendiente (`HomeView.swift:59-73, 300-327`); no hay observación visual que demuestre interferencia y no aparece para todos los lanzamientos.

Los tests unitarios históricos cubrieron preferencias, migración y sonido, dentro de rerun 34/34 de `EnhancementFeaturesTests`. No se observó un cambio de fecha real, persistencia tras cierre/reinicio de app, expiración Pro, VoiceOver ni efecto visual en evento. Mantener opcional, no penalizar Free con una apariencia impuesta y validar antes de añadir otro evento. No hay argumento para borrar el tema actual.

## Monetización y experiencia Free/Pro

El posicionamiento local describe Free con importación/captura, máscaras, OCR sugerido, exportación verificada sin watermark forzado y Vault; límite de 10 documentos procesados acumulativos. Pro se posiciona en procesamiento ilimitado, batch, modos/estilos/ajustes avanzados, marcas personalizadas y servicios de movilidad/sincronización. Las compras mensuales/anuales/lifetime y entitlements existen en código/configuración (`Shield/Premium/PremiumManager.swift`, `Shield/Views/Paywall/PaywallView.swift`).

El paywall incluye cierre, selector de plan, explicación de funciones, nota Free, FAQ y CTA; Settings permite restore y offer-code redemption. No se ejecutó compra, restauración, cancelación, fallo de StoreKit/RevenueCat ni se verificó el copy de precios actuales. No hay evidencia de que la redacción segura esté bloqueada a Free; la ruta estándar de export está documentada como disponible. Afirmación de claridad/respeto del flujo de compra queda parcialmente verificada.

## Analítica, privacidad y sincronización

El árbol WIP y los documentos locales describen Firebase Analytics desactivado por defecto, opt-in desde Settings > Privacy y separación de Crashlytics; onboarding no debe mostrar solicitud temprana. El test histórico de onboarding aprobó la ausencia de prompt/paywall antes de Home. La política externa publicada no se verificó.

`SecureQuotaStore` usa UserDefaults, Keychain e iCloud KVS para un entero agregado de cuota, sin contenido documental ni ID. La política local ahora lo revela. Apple documenta que KVS sincroniza entre dispositivos con la misma cuenta y se guarda localmente sin cifrado, y desaconseja almacenar allí información personal/sensible: [NSUbiquitousKeyValueStore](https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore). El riesgo restante es clasificación/expectativa del contador y comportamiento de sync, no exposición de documentos demostrada. La decisión registrada previamente es conservar solo el conteo agregado; validar misma cuenta, cambio de cuenta y modo offline.

## Promesas externas

Los documentos de posicionamiento y privacidad han sido actualizados localmente respecto a ejecución 2026-11-07. App Store Connect y la política ya publicada no se consultaron en este turno. Las guías de Apple exigen información de privacidad fiel y descripciones exactas de producto y compras; se usan como marco, no como dictamen de cumplimiento: [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

