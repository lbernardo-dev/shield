# 260-acceso-15-dias-lifetime

- Number: 260
- Slug: acceso-15-dias-lifetime

## Notes

- Confirmación comercial del propietario: 15 días para todas las cuentas; conservar el inicio existente al migrar; retirar ventas y renovaciones de suscripción manteniendo el servicio ya pagado; Lifetime base 9,99 € para España, con localización de Apple en otros mercados.
- Implementado acceso temporal uniforme de 15 días con vencimiento obligatorio, migración de esquema v1 anclada al inicio original, Keychain `WhenUnlockedThisDeviceOnly` y sin periodo read-only adicional. La reinstalación normal en el mismo dispositivo conserva el registro; el comportamiento al borrar Keychain o cambiar de dispositivo está fuera de la garantía sin backend.
- Paywalls de app y onboarding presentan solo el paquete Lifetime; se añadieron canje nativo de códigos Apple y restaurar compras. El hard paywall no se puede cerrar y mantiene acceso mínimo a documentos propios, más restauración, canje y enlaces legales.
- StoreKit local contiene solo `com.romerodev.shield.pro.lifetime.unlock`, tipo no consumible, a 9,99 €. El CTA de Lifetime está disponible desde Ajustes durante los 15 días.
- ASC IAP `6791491284`: lectura final muestra `NON_CONSUMABLE`, territorio base `ESP`, precio actual 9.99 EUR. El plan de precios fue creado desde España y resuelto para 175 territorios (43 monedas; una fila manual de España y precios localizados por Apple).
- ASC subscriptions `6790401134` (mensual), `6790401098` (anual), `6820383062` (anual Event): UI confirma los tres como “Retirada de la venta por el desarrollador”. Se aceptó la atestación de servir a clientes existentes hasta el fin de su ciclo pagado actual. No se borraron IDs ni historial.
- RevenueCat proyecto `projbbe3f3db`: `default` current conserva solo Lifetime en el paquete `$rc_lifetime`; paquetes mensual/anual vacíos. Offering `event` archivada y sus paquetes vacíos. Se conservan los 7 productos históricos en `MaskID Pro` para entitlement/restore.
- Documentación vigente, condiciones de compra draft y metadata local 1.2.0 actualizadas. No se envió una versión a App Review ni se publicó metadata desde ASC.
- Verificación: `xcodebuild -project Shield.xcodeproj -scheme Shield -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build` terminó `BUILD SUCCEEDED`. Catálogos JSON/StoreKit y `git diff --check` pasan. No se ejecutaron pruebas ni se publicó un build. Tras la confirmación del usuario, `./scripts/clean.sh --all` se ejecutó; los directorios de build del proyecto y sidecars quedaron ausentes y `.asc/artifacts/` se conservó.


## Corrección posterior (tarea 261, 18-11-2026)

El canje de Offer Codes mencionado en esta implementación intermedia se retiró por decisión del propietario: Lifetime es la única compra y el flujo de códigos no está disponible para este producto. La tarea 261 elimina el botón/sheet de paywall, onboarding y Ajustes, además de la reconciliación `syncPurchases()` asociada. El paywall conserva compra Lifetime, restaurar y enlaces legales.
