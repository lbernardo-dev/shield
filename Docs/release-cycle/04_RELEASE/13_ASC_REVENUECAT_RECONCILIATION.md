# Reconciliación App Store Connect / RevenueCat / StoreKit

**Read-back actualizado:** 9-11-2026. **ASC:** app `6790398619`, bundle `com.romerodev.shield`. **RevenueCat:** proyecto `bbe3f3db`, app App Store `appf8e763274c`.

## Catálogo comercial

| Elemento | App Store Connect / App Store | RevenueCat | Estado probado |
|---|---|---|---|
| Mensual | `com.romerodev.shield.pro.monthly`; 2,99 €/mes; aprobado | Producto de App Store MaskID Pro Monthly vinculado al paquete Monthly del offering `default` y al entitlement `MaskID Pro` | Precio España confirmado por `get_product_store_state` el 8-11; ficha actual de RevenueCat muestra Approved y 1 entitlement. No se ejecutó compra real. |
| Anual | `com.romerodev.shield.pro.annual`; 29,99 €/año; aprobado | Producto de App Store MaskID Pro Annual vinculado a Yearly/`$rc_annual`, `default` y `MaskID Pro` | Ficha y pestaña Pricing de RevenueCat consultadas el 9-11: Approved, 29,99 EUR para España, “This product has no offers attached”. `trial_offer=null`, `introductory_offers={}` y no hay ofertas promocionales, de recuperación ni códigos. No existe trial de 7 días activo en StoreKit. |
| Vitalicio | `com.romerodev.shield.pro.lifetime.unlock`; 49,99 €; no consumible aprobado | Producto de App Store MaskID Pro Lifetime vinculado a Lifetime/`$rc_lifetime` y al entitlement `MaskID Pro` | Precio España confirmado por `get_product_store_state` el 8-11; ficha actual muestra Approved y 1 entitlement. No se ejecutó compra ni restauración real. |
| Annual Event | `com.romerodev.shield.pro.annual.event`; precio actual 29,99 €; aprobación ya existente | Producto de App Store separado dentro del offering `event`, que está activo pero no es el offering actual | La oferta promocional anterior terminó el 1-11 según la conciliación de Fase 03. Se conserva el SKU y su asociación. No se hizo una nueva compra. |
| Entitlement | ASC no mantiene entitlements de RevenueCat | RevenueCat muestra `MaskID Pro`, con 7 productos: cuatro productos de App Store y tres de Test Store. Los productos de App Store visibles tienen una asociación cada uno. | Confirmado en la sesión autenticada del dashboard el 9-11. El detalle de MaskID Pro Annual muestra explícitamente `MaskID Pro` y `default`. |

## Offering y productos de prueba

- `default` es el offering actual y contiene tres paquetes: Monthly, Yearly y Lifetime.
- Los paquetes muestran asociaciones paralelas por store: mensual con `com.romerodev.shield.pro.monthly`, anual con `com.romerodev.shield.pro.annual` y vitalicio con `com.romerodev.shield.pro.lifetime.unlock`.
- El mismo proyecto tiene una app `Test Store` separada (`app4e70b8108a`) con productos de prueba `monthly`, `yearly` y `lifetime`, asociados a esos paquetes. Esto explica los SKU genéricos que aparecían junto a los SKU de MaskID; la evidencia visual no los identifica como productos de otra app de producción.
- El offering `event` está activo y tiene dos paquetes; no es el offering actual. Se mantiene separado del catálogo predeterminado.
- La ficha del producto anual muestra la suscripción `MaskID Pro` con los SKU mensual, anual y anual Event. No se cambió la configuración de RevenueCat: el offering y las asociaciones esperadas ya estaban publicados.

## Discrepancia del trial

El objeto de catálogo anual de RevenueCat entregado anteriormente por la API mostraba `trial_duration=P1W`. Sin embargo, el estado de App Store leído por API el 9-11 a las 07:41 UTC y el dashboard de RevenueCat consultado el mismo día no muestran ninguna oferta asociada al producto anual: `trial_offer=null`, `introductory_offers={}` y la tabla Offers dice “This product has no offers attached”. Por ello, `P1W` es metadata residual del catálogo y **no** un trial activo de App Store.

No se intentó borrar `P1W` mediante una operación no compatible: el endpoint actual `update-product` sólo expone `display_name` y `type` para este recurso de producto App Store, y el campo antiguo de trial del store state es de sólo lectura. Tampoco se creó un plan de cambios de StoreKit, porque el read-back actual ya coincide con la oferta comercial aprobada: sin trial anual para nuevas altas.

## Evidencia actual de ASC y TestFlight

- App Store Connect: versión `1.1.7`, ID `a900074d-07ef-4368-b6b9-8007c437bba1`, `PREPARE_FOR_SUBMISSION`, liberación manual.
- Build `1172026110801`, ID `2d9de6eb-e554-4fca-84f5-58eaccd2b88d`, estado de procesamiento `VALID`, no expirado, `READY_FOR_BETA_TESTING`.
- La lectura inicial detectó que el build no estaba asociado a la versión. Bajo la autorización expresa del propietario para completar escrituras en ASC, `asc versions attach-build` lo asoció; el read-back posterior confirma el ID del build en la relación `build` de 1.1.7.
- Se crearon las notas “What to Test” para es-ES y en-US. `asc validate testflight` posterior: 0 errores, 0 avisos, 0 bloqueos.
- `asc validate --strict` posterior, con el IPA final: 0 errores, 0 avisos, 0 bloqueos; 2 observaciones informativas: publicación de App Privacy no verificable por API pública y release manual.
- El build está asignado a `Shield Internal` por relación explícita, y ASC confirma `IN_BETA_TESTING`. El grupo contiene un tester existente (`INSTALLED`); no se invitaron testers adicionales. `autoNotifyEnabled=true`; ASC no expone confirmación de entrega de notificación.
- No hay beta review, App Review ni publicación en curso. No se ejecutaron acciones de publicación.

## Límites de lectura y pruebas restantes

- La sesión autenticada del dashboard permitió leer el catálogo y el entitlement. Las llamadas MCP `list-apps`, `list-products` y `list-entitlements` continúan respondiendo 403 `access token revoked`; en la nueva lectura `get_product_store_state` funcionó para el producto anual y devolvió 403 para mensual y vitalicio. Por eso, los últimos importes de mensual y vitalicio se citan con la lectura confirmada del 8-11, no como un nuevo refresh de hoy.
- `asc validate --deep` no pudo leer un Apple web session cacheado. La publicación de App Privacy y el estado de acuerdos de Apple siguen sin verificación remota; la declaración de privacidad no se modificó.
- Una prueba focalizada posterior pasó la resolución del offering `default` y sus tres productos comerciales contra `Shield.storekit` (3/3 casos de la suite, incluye dos assertions de catálogo). Un intento posterior de compra/restauración local se interrumpió durante el worker de XCTest y no produjo resultado verificable; no se cuenta como transacción completada y no puede descartarse que StoreKit haya iniciado una operación parcial.
- ASC devuelve un tester Sandbox existente en territorio ESP; la identidad no se incluyó en informes. No se pudo usar una sesión física de TestFlight/Sandbox desde este entorno. Compra/restore verificados por Apple y los escenarios cancelación, pending, grace/billing retry, refund/revoke y renovación siguen pendientes. La distribución interna está activa.

## Referencias de API vigentes

- [RevenueCat Product API](https://www.revenuecat.com/docs/api-v2/product)
- [RevenueCat Product Store State Plan](https://www.revenuecat.com/docs/api-v2/product-store-state-plan)
- [RevenueCat subscription offers](https://www.revenuecat.com/docs/subscription-guidance/subscription-offers)
