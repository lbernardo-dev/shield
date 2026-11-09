# 257-qa-sandbox-storekit-1-1-7

- Number: 257
- Slug: qa-sandbox-storekit-1-1-7

## Notes

- ASC `sandbox list` devolvió un tester existente para territorio ESP. No se imprimieron emails ni otros atributos de cuenta; no se creó ni modificó ninguna cuenta Sandbox.
- `Shield.storekit` contiene mensual (`com.romerodev.shield.pro.monthly`, 2,99), anual (`com.romerodev.shield.pro.annual`, 29,99), anual de evento (`com.romerodev.shield.pro.annual.event`, 29,99) y vitalicio (`com.romerodev.shield.pro.lifetime.unlock`, 49,99); el offering `default` resuelve mensual/anual/vitalicio, sin evento.
- En iPhone 18 Pro/iOS 27.2 Simulator, `ShieldProductCatalogTests` corrió 3/3: los dos tests de SKU/precios y el test opt-in de resolución del offering de RevenueCat contra el catálogo StoreKit local pasaron. XCResult: `.asc/artifacts/MaskID-1.1.7-Product-Catalog-Integration-Enabled.xcresult`. No se realizó ninguna compra en esta corrida.
- Se añadió temporalmente a la prueba opt-in una compra mensual simulada y `restorePurchases`; el worker de XCTest se bloqueó/reinició durante esa operación. Xcode se interrumpió a los 190 s (exit 75); las dos pruebas de catálogo sí quedaron PASS, pero la integración transaccional no devolvió resultado. El XCResult quedó incompleto y `xcresulttool` no pudo abrir su base de datos: `.asc/artifacts/MaskID-1.1.7-StoreKit-Purchase-Restore.xcresult`. No se puede excluir que StoreKit iniciara una operación parcial, así que no se repitió la compra. El cambio temporal del test se revirtió y la prueba opt-in existente conserva su cuerpo original.
- No hay sesión física confirmada de TestFlight/Sandbox disponible desde este entorno. La asignación a `Shield Internal` completada en tarea 256 queda activa, con un tester instalado y sin nuevos testers.
- Estado de cierre de tarea: compra/restore Sandbox real, cancelación, pending, grace/billing retry, refund/revoke y renovación siguen sin evidencia. No modificar ni borrar el historial de Sandbox; no limpiar artefactos temporales sin pedir autorización.

