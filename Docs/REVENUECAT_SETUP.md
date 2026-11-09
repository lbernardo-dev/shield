# RevenueCat — configuración y verificación

**Proyecto:** `bbe3f3db` (`projbbe3f3db`). **Entitlement:** `MaskID Pro`. **SDK local:** `purchases-ios` 5.102.3 en `Package.resolved` y mínimo del proyecto. La versión de SDK se comprobó con la release oficial publicada el 6-11-2026.

## Catálogo existente preservado

| SKU | Product ID | Entitlement | Offering/Package |
|---|---|---|---|
| Mensual | `com.romerodev.shield.pro.monthly` | `MaskID Pro` | `default` / `$rc_monthly`; también package mensual de `event` |
| Anual estándar | `com.romerodev.shield.pro.annual` | `MaskID Pro` | `default` / `$rc_annual` |
| Lifetime | `com.romerodev.shield.pro.lifetime.unlock` | `MaskID Pro` | `default` / `$rc_lifetime` |
| Anual Event | `com.romerodev.shield.pro.annual.event` | `MaskID Pro` | `event` / `$rc_annual`; producto `prod2ef37965ba`, Offering `ofrngbe0d32124e` |

`default` sigue siendo current. No se creó weekly ni un entitlement nuevo. Event Offering solo se selecciona con ventana/campaña y validación del precio/producto; el producto está aprobado en ASC, pero el flujo de compra aún necesita Sandbox.

## Introductory offer y acceso temporal

ASC retiró la oferta anual; la lectura posterior de StoreKit en RC muestra `ok`, 29,99 EUR en ES y cero territorios con introductory offers. No hay código paywall que intente mostrar trial. `CustomerInfo` aún interpreta `.trial` si Apple informa un periodo histórico actualmente activo; esto preserva el estado real del usuario sin ofrecer un nuevo trial.

Los 15/30/30 días son acceso interno de MaskID, no entitlement, StoreKit transaction, RevenueCat trial ni estado de facturación. PremiumManager no modifica CustomerInfo para otorgarlos: `AccessPolicy` concede las mismas capacidades FULL como causa separada.

## Identidad, restore y gracia

- Purchases se originan desde el Package de la Offering y se procesan con RevenueCat. CustomerInfo y entitlement activo son la autoridad para acceso pagado.
- Restore sigue en Settings y paywall; oferta Apple code nativa se reconcilia con `syncPurchases()` solo después de redención verificada.
- La app usa App User ID anónimo y no tiene login/logout propio. No se hizo cambio de restore behavior ni fusión de identidad.
- RevenueCat y StoreKit Sandbox no se usaron para comprar, cancelar, renovar, reembolsar ni probar restore en esta fase. Gracia solo se concede mientras RevenueCat informa entitlement activo; un retry sin acceso activo no equivale a grace.
- Dashboard placements/experiments, webhook delivery, API key de App Store, restore behavior y transferencias entre IDs/Apple IDs siguen por verificar en el gate previo de Fase 04 si afectan al release.
