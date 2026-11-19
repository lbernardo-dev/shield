# RevenueCat — configuración y verificación

**Proyecto:** `bbe3f3db` (`projbbe3f3db`). **Entitlement:** `MaskID Pro`. **SDK local:** `purchases-ios` 5.102.3 en `Package.resolved` y mínimo del proyecto. La versión de SDK se comprobó con la release oficial publicada el 6-11-2026.

## Catálogo vigente (18 de noviembre de 2026)

La Offering actual `default` expone únicamente el paquete `$rc_lifetime`, con los productos Lifetime de App Store y Test Store. Los paquetes mensuales/anuales quedaron vacíos y se retiraron las asociaciones de sus productos. La Offering `event` se archivó. Los productos históricos de suscripción siguen asociados al entitlement `MaskID Pro` para conservar el acceso pagado y permitir restaurar compras existentes.

El precio base de App Store para Lifetime es 9,99 € en España; Apple localiza los precios para los demás mercados.

### Asociaciones históricas preservadas

| SKU | Product ID | Entitlement | Offering/Package |
|---|---|---|---|
| Mensual | `com.romerodev.shield.pro.monthly` | `MaskID Pro` | Antes en `default` / `$rc_monthly` y `event`; ahora sin package de compra |
| Anual estándar | `com.romerodev.shield.pro.annual` | `MaskID Pro` | Antes en `default` / `$rc_annual`; ahora sin package de compra |
| Lifetime | `com.romerodev.shield.pro.lifetime.unlock` | `MaskID Pro` | `default` / `$rc_lifetime`; único producto vendido |
| Anual Event | `com.romerodev.shield.pro.annual.event` | `MaskID Pro` | Antes en `event` / `$rc_annual`; Offering archivada y sin package |

`default` sigue siendo current. No se creó weekly ni un entitlement nuevo. Todos los productos de suscripción siguen asociados al entitlement solo como historial de compras existentes; la app ya no solicita ni presenta Offerings de evento.

## Introductory offer y acceso temporal

ASC retiró de la venta las suscripciones anual, mensual y anual de evento. La antigua lectura StoreKit de RevenueCat informaba 29,99 EUR y cero ofertas introductorias en el anual; es estado histórico, no oferta activa. `CustomerInfo` sigue interpretando `.trial` si Apple informa un periodo histórico vigente, para reconocer los términos ya otorgados.

Los 15 días son acceso interno de MaskID igual para todas las cuentas, no entitlement, transacción StoreKit, trial de RevenueCat ni estado de facturación. PremiumManager no modifica CustomerInfo para otorgarlos: `AccessPolicy` concede las capacidades FULL como causa separada. La fecha se guarda en Keychain `ThisDeviceOnly` para mantener el contador tras una reinstalación normal en el mismo dispositivo.

## Identidad, restore y gracia

- Purchases se originan desde el Package de la Offering y se procesan con RevenueCat. CustomerInfo y entitlement activo son la autoridad para acceso pagado.
- Restore sigue en Settings y paywall; oferta Apple code nativa se reconcilia con `syncPurchases()` solo después de redención verificada.
- La app usa App User ID anónimo y no tiene login/logout propio. No se hizo cambio de restore behavior ni fusión de identidad.
- RevenueCat y StoreKit Sandbox no se usaron para comprar, cancelar, renovar, reembolsar ni probar restore en esta fase. Gracia solo se concede mientras RevenueCat informa entitlement activo; un retry sin acceso activo no equivale a grace.
- Dashboard placements/experiments, webhook delivery, API key de App Store, restore behavior y transferencias entre IDs/Apple IDs siguen por verificar en el gate previo de Fase 04 si afectan al release.
