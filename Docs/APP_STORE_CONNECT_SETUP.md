# Configuración de App Store Connect

**Estado vigente verificado:** 18 de noviembre de 2026. App ID `6790398619`. Solo se vende MaskID Lifetime: precio base de España 9,99 € y disponibilidad en 175 territorios con precios localizados/equivalentes por Apple. Las tres suscripciones se retiraron de la venta desde App Store Connect; Apple deja de ofrecer nuevas altas y renovaciones. Se aceptó prestar el servicio hasta el final de cada ciclo ya pagado.

| Product ID | ASC ID / tipo | España | Estado/acción |
|---|---|---:|---|
| `com.romerodev.shield.pro.monthly` | `6790401134`, mensual autorrenovable | €2,99 histórico | Retirada de la venta por el desarrollador el 18-11-2026; se mantienen transacciones y derechos existentes |
| `com.romerodev.shield.pro.annual` | `6790401098`, anual autorrenovable, grupo `MaskID Pro`, nivel 1 | €29,99 histórico | Retirada de la venta por el desarrollador el 18-11-2026; se mantienen transacciones y derechos existentes |
| `com.romerodev.shield.pro.lifetime.unlock` | `6791491284`, `NON_CONSUMABLE` | **€9,99 una vez** | `APPROVED`; precio base España y 175 territorios. Apple calcula los precios localizados para el resto de mercados. |
| `com.romerodev.shield.pro.annual.event` | `6820383062`, anual autorrenovable, grupo `MaskID Pro`, nivel 1 | €29,99 histórico | Retirada de la venta por el desarrollador el 18-11-2026; se mantienen transacciones y derechos existentes |

## Cambio de oferta introductoria (8 de noviembre de 2026)

El propietario autorizó retirar la oferta anual de 7 días para nuevas altas conservando derechos ya adquiridos. Se eliminaron las ofertas introductorias existentes asociadas al producto anual en todos los territorios (el snapshot previo cubría 175 territorios, incluido ES). Post-check ASC devolvió 0 ofertas introductorias. RevenueCat `get_product_store_state` del producto anual fue actualizado; `store_status=ok`, Spain `29.99 EUR`, `introductory_offers` con 0 territorios y `store_fetched_at=2026-11-08T12:49:05Z`.

El cambio no modifica los IDs, precio recurrente, suscripciones activas ni duración ya asignada por Apple. El app StoreKit fixture (`Shield.storekit`) ya no tiene `introductoryOffer`. No borrar/recrear el producto ni grupo.

## Política vigente (18 de noviembre de 2026)

- Todas las cuentas pueden activar un único periodo interno de 15 días naturales de acceso completo. No hay suscripción, trial de tienda, tarjeta ni cobro automático asociado.
- La fecha de inicio se conserva en Keychain `ThisDeviceOnly` para que reinstalar normalmente la app en el mismo dispositivo no reinicie el periodo. No ofrece garantía al borrar Keychain o migrar a otro dispositivo.
- Al vencer, la app exige Lifetime para las funciones Premium y conserva recuperación mínima de datos propios y restauración. No ofrece canje de códigos de oferta.
- Las suscripciones anteriores siguen vinculadas al entitlement de RevenueCat para reconocer sus ciclos ya pagados y transacciones históricas; no se venden desde la app ni se ofrecen renovaciones nuevas.
- Precio de `com.romerodev.shield.pro.lifetime.unlock`: base ESP 9,99 EUR, disponibilidad 175/175 territorios. La matriz de precios resuelta por Apple incluye 43 monedas y una única entrada manual en España.

## Verificación reproducible de solo lectura

```sh
asc --read-only subscriptions pricing summary --app 6790398619 --subscription-id com.romerodev.shield.pro.monthly --territory Spain --output json
asc --read-only subscriptions pricing summary --app 6790398619 --subscription-id com.romerodev.shield.pro.annual --territory Spain --output json
asc --read-only subscriptions pricing summary --app 6790398619 --subscription-id 6820383062 --territory Spain --output json
asc --read-only iap pricing summary --app 6790398619 --iap-id com.romerodev.shield.pro.lifetime.unlock --territory Spain --output json
```

La tarea 260 no asignó versión/build, no generó archive y no envió una versión a revisión. Antes de un release futuro, releer la asociación de versión/build y completar revisión legal y Sandbox; no quedan ventas de suscripción que publicar.
