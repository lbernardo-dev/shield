# Sign-off de monetización

## Política aprobada

| Cohorte / estado | Acceso | Después del periodo | Preservación |
|---|---|---|---|
| Usuario nuevo | 15 días naturales de funciones completas, desde la aceptación/activación guardada | Paywall obligatorio para las funciones comerciales | No crea una transacción, tarjeta, trial Apple ni renovación automática |
| Usuario Free anterior a la migración | 30 días de funciones completas | 30 días adicionales de consulta/exportación/eliminación en read-only; después paywall con recuperación mínima | No borra biblioteca local ni Bóveda |
| Suscriptor / lifetime verificado | FULL por entitlement; lifetime no consumible | Estado verificado por StoreKit 2/RevenueCat | Restore y compra prevalecen sobre periodo local |
| Periodo de gracia | FULL solo mientras Apple/RevenueCat entreguen entitlement activo confirmado | Retry sin entitlement activo no concede FULL | Refund/revoke real no probado en Sandbox |

La fuente local de acceso usa AccessPolicy, AccessStateStore y Keychain WhenUnlockedThisDeviceOnly. Es fail-closed ante almacenamiento no disponible; el reloj adelanta lastTrustedAt, pero un reloj local adelantado puede caducar antes. No existe backend o cuenta MaskID que garantice elegibilidad universal tras reinstalar, borrar Keychain o cambiar de dispositivo.

## Catálogo aprobado en España

| Plan | Product ID | Precio ES | Tipo | Estado de comprobación |
|---|---|---:|---|---|
| Mensual | com.romerodev.shield.pro.monthly | 2,99 €/mes | Suscripción autorrenovable | ASC APPROVED; validación estricta sin avisos/errores |
| Anual | com.romerodev.shield.pro.annual | 29,99 €/año | Suscripción autorrenovable | ASC APPROVED; sin introductory offer real en la consulta de App Store/RevenueCat store-state |
| Vitalicio | com.romerodev.shield.pro.lifetime.unlock | 49,99 € pago único | IAP NON_CONSUMABLE | ASC APPROVED; strict IAP sin avisos/errores |
| Evento anual | com.romerodev.shield.pro.annual.event | 29,99 €/año actual | Suscripción autorrenovable vinculada al offering event | Precio de evento Halloween 14,99 € terminó el 1-11-2026; retorno leído en ASC |
| Semanal | — | — | No ofrecer | No existe plan semanal aprobado |

La aprobación corregida del propietario es mensual 2,99 €, anual 29,99 €, lifetime opcional 49,99 €. Los precios aprobados ya estaban reflejados en ASC y en los productos visibles de RevenueCat, por lo que no se editó el catálogo. ASC continúa reportando cero ofertas introductorias para el producto anual; los derechos/trials ya asignados a usuarios se preservan.

## StoreKit / RevenueCat y pruebas

- Shield.storekit conserva IDs y no define trial anual. StoreKit 2 provee transacciones/metadatos de precio; RevenueCat entrega entitlements/offerings.
- ASC strict validators: 3 suscripciones y 1 IAP, 0 errores/avisos/bloqueos.
- RevenueCat Store State del producto anual, 9-11-2026 07:41 UTC: app_store, status ok/APPROVED, España 29.990.000 micros EUR y cero ofertas introductorias/promocionales/de recuperación/códigos.
- RevenueCat Dashboard, sesión autenticada el 9-11-2026, muestra `default` como offering actual con paquetes Monthly, Yearly y Lifetime y los SKU de MaskID de App Store; el offering `event` está separado. La ficha anual muestra `MaskID Pro` y `default`; el grupo de suscripción contiene mensual, anual y anual Event. El entitlement `MaskID Pro` enumera siete productos, incluidos tres productos de Test Store.
- En el mismo dashboard, el producto anual cuesta 29,99 € en España y Offers indica “This product has no offers attached”. El campo `trial_duration:P1W` de la respuesta previa del API de catálogo no coincide con una oferta de StoreKit; se conserva como metadata residual, no como trial comercial activo.
- La página Products distingue la app `MaskID (App Store)` de la app `Test Store`. Los SKU genéricos `monthly/yearly/lifetime` son productos de prueba en los paquetes comunes; la asociación de producción usa los SKU explícitos `com.romerodev.shield.*`. Las asociaciones visibles y el entitlement esperado están confirmados. Las llamadas MCP a `list-apps/products/entitlements` y a Store State de mensual/vitalicio siguen devolviendo 403, por lo que los últimos precios de estos dos productos son el refresh del 8-11 (2,99 €/49,99 €), no un refresh nuevo.
- No hay trial anual de App Store activo; los 15 días internos nuevos no generan transacción de tienda.
- Hay entitlement comprado/lifetime y restore priorizados en código y tests de política. No se hizo ninguna compra, restore, cancelación, refund/revoke, grace period o prueba pendiente en Sandbox/TestFlight. No se presenta cobertura real de pagos.
- Sí se creó el borrador de versión ASC 1.1.7 y se sincronizó metadata ASO version-scoped en en-US/es-ES con read-back correcto. En el cierre del 9-11 se asoció el build a la versión y se añadieron las notas TestFlight. No se tocaron precios/intro offers, productos, entitlements, webhooks, grupos ni testers; App Privacy no se editó.

Resultado: política local aprobada e implementada con cobertura de boundaries unitarios; el read-back comercial confirma el catálogo y las asociaciones del dashboard, aunque faltan las transacciones Sandbox. No enviar a App Review hasta completar aprobación jurídica, revisión de App Privacy y las pruebas requeridas.
