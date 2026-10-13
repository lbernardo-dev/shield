# 218-subscription-trial-price-disclosure

- Number: 218
- Slug: subscription-trial-price-disclosure

## Notes

- Motivo del rechazo: el paywall mostraba la duración de la prueba y el precio anual por separado, pero no decía junto al botón que se cobraría ese precio al terminar la prueba ni que la suscripción se renovaría automáticamente.
- Añadido `SubscriptionTrialDisclosure` compartido en el paywall de Ajustes y el del onboarding. Cuando StoreKit/RevenueCat confirma una prueba gratuita elegible, el aviso muestra su duración, el siguiente importe y periodo de cobro, y que la suscripción se renueva hasta cancelarla. El CTA refleja «Start free trial» cuando corresponde. Copia localizada en inglés y español; el periodo de renovación se deriva de StoreKit y usa catálogo como fallback.
- Claridad visual del paywall: mayor contraste para textos secundarios, enlaces y términos del plan; periodicidad escrita completa; selección anual más visible; panel de prueba destacado; botones legales con área táctil de 44 pt; arte de temporada atenuado para dar prioridad al contenido.
- Auditoría incidental: se eliminó el alias duplicado `"03"` en `AppState` que hacía inalcanzable la ruta de watermark. La ruta de captura conserva ese alias.
- Validación final: build Debug para iOS Simulator; `git diff --check`; JSON de `Paywall.xcstrings` válido. iPhone 18 Pro, iOS 27.0, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`: 7 pruebas aprobadas (suite `SubscriptionExperienceTests`, accesibilidad del paywall EN/ES, enlaces y footer). iPad Pro 13-inch (M5), iOS 27.0, UDID `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`: 8 pruebas aprobadas, incluida visibilidad y capacidad de pulsar CTA y enlaces en horizontal. Ambos simuladores quedaron apagados/libres; espera en cola: 0.
- El inventario no contiene iPhone Duo ni iPad Air 11-inch (M3). Hay runtime watchOS 27.0, pero el proyecto no contiene destino/scheme watchOS de MaskID. No se realizó emparejamiento Watch.
- Hallazgo al tomar la captura: el paywall actual del simulador seleccionó «Annual Event Offer» ($12.99/año, precio anual comparativo $24.99) y su producto no ofrece prueba introductoria; por eso ese flujo muestra «Get MaskID Pro» y no necesita el aviso de prueba. La captura de revisión de Apple corresponde al anual estándar con prueba de 7 días, cuyo flujo sí presenta ahora el aviso. No se inició ninguna compra.
- Quedan advertencias de compilación ajenas a este cambio: referencias a estáticos aislados por `MainActor` desde contextos no aislados en `AppReviewManager.swift` (líneas 489, 578 y 712), además de la advertencia de invalidación de dependencias por la closure `@Entry closeSettings` en `SettingsDestinationViews.swift:5`. Plan: revisar aislamiento y anotaciones de esas APIs en una tarea de concurrencia/SwiftUI, volver a ejecutar el build estricto y verificar que desaparezcan sin introducir saltos de actor.
