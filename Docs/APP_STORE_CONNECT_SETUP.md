# Configuración de App Store Connect

**Lectura verificada:** 8 de noviembre de 2026. App ID `6790398619`. No se cambiaron los precios porque ya coincidían con los aprobados.

| Product ID | ASC ID / tipo | España | Estado/acción |
|---|---|---:|---|
| `com.romerodev.shield.pro.monthly` | `6790401134`, mensual autorrenovable | €2,99/mes | `APPROVED`; confirmado con `asc --read-only subscriptions pricing summary --app 6790398619 --subscription-id com.romerodev.shield.pro.monthly --territory Spain` |
| `com.romerodev.shield.pro.annual` | `6790401098`, anual autorrenovable, grupo `MaskID Pro`, nivel 1 | €29,99/año | `APPROVED`; el listado de introductory offers quedó vacío después de retirar las ofertas de nuevos compradores con autorización del propietario |
| `com.romerodev.shield.pro.lifetime.unlock` | `6791491284`, `NON_CONSUMABLE` | €49,99 una vez | `APPROVED`; confirmado con `asc --read-only iap pricing summary --app 6790398619 --iap-id com.romerodev.shield.pro.lifetime.unlock --territory Spain` |
| `com.romerodev.shield.pro.annual.event` | `6820383062`, anual autorrenovable, grupo `MaskID Pro`, nivel 1 | €29,99/año actual | `APPROVED`; precio de Halloween €14,99 finalizó el 1-11-2026 y el retorno está read-back. Requiere revalidar compatibilidad/versión de app en Fase 04. |

## Cambio de oferta introductoria

El propietario autorizó retirar la oferta anual de 7 días para nuevas altas conservando derechos ya adquiridos. Se eliminaron las ofertas introductorias existentes asociadas al producto anual en todos los territorios (el snapshot previo cubría 175 territorios, incluido ES). Post-check ASC devolvió 0 ofertas introductorias. RevenueCat `get_product_store_state` del producto anual fue actualizado; `store_status=ok`, Spain `29.99 EUR`, `introductory_offers` con 0 territorios y `store_fetched_at=2026-11-08T12:49:05Z`.

El cambio no modifica los IDs, precio recurrente, suscripciones activas ni duración ya asignada por Apple. El app StoreKit fixture (`Shield.storekit`) ya no tiene `introductoryOffer`. No borrar/recrear el producto ni grupo.

## Verificación reproducible de solo lectura

```sh
asc --read-only subscriptions pricing summary --app 6790398619 --subscription-id com.romerodev.shield.pro.monthly --territory Spain --output json
asc --read-only subscriptions pricing summary --app 6790398619 --subscription-id com.romerodev.shield.pro.annual --territory Spain --output json
asc --read-only subscriptions pricing summary --app 6790398619 --subscription-id 6820383062 --territory Spain --output json
asc --read-only iap pricing summary --app 6790398619 --iap-id com.romerodev.shield.pro.lifetime.unlock --territory Spain --output json
```

No se asignó versión/build, no se generó archive y no se envió versión a revisión desde esta fase. Fase 04 debe releer la versión, el build y estado de Event Annual en ASC; el handoff de Fase 02 marca diferencia entre número local/ASC y falta revisión empírica.
