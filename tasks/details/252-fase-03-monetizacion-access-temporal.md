# 252-fase-03-monetizacion-access-temporal

- Number: 252
- Slug: fase-03-monetizacion-access-temporal

## Notes

- Aprobación comercial vigente del propietario: España €2,99/mes, €29,99/año, €49,99 lifetime opcional; sin plan semanal. Autorizó retirar el trial anual de 7 días a nuevas compras y aplicar solo los cambios aprobados. El read-back del 8-11-2026 ya coincidía con estos precios, por lo que no hubo cambio de precio ASC que ejecutar.
- ASC verificado en lectura posterior: mensual/anual `APPROVED`; vitalicio `NON_CONSUMABLE`; Event Annual aprobado y retornado a €29,99 ES. Intro-offer anual: 0 ofertas listadas en ASC; RevenueCat store-state actualizado con 0 territorios de oferta introductoria. `default` y `event`, entitlement `MaskID Pro` e IDs existentes preservados.
- Implementación local: `AccessPolicy` de 15 días para instalaciones nuevas y 30 días full + 30 días recovery para Free preexistente corroborado; paywall obligatorio tras acceso comercial; lectura/exportación/eliminación propia, restore, soporte y legal conservados. Se migraron los gates de Premium y se eliminaron el gate semanal de exportación y el contador visible de cuota documental.
- Límite técnico documentado: Keychain `ThisDeviceOnly` más última hora confiable reduce resets locales, pero no garantiza una identidad anti-reset entre reinstalación/dispositivo; adelantar reloj puede expirar antes. Los writes se bloquean en capa de dominio; el editor activo usa lease de guardado de un solo uso para el snapshot persistido y la captura muestra resolución de acceso sin perder contexto.
- SDK RevenueCat fijado/resuelto a `purchases-ios` 5.102.3, release oficial más reciente comprobado para esta ejecución (06-11-2026). No se inicia build final, archive ni publicación.
- Legal: condiciones en borrador y release blocker hasta revisión jurídica competente. Manual Sandbox/TestFlight de compra/restore/reembolso/revocación/gracia, CloudKit online/offline y verificación física de accesibilidad permanecen pendientes; no se marcarán como pasados.
- Evidencias y matriz: `Docs/MONETIZATION_MIGRATION_SUMMARY.md`, `Docs/COMMERCIAL_PROPOSAL_ES_EUR.md`, `Docs/ACCESS_STATE_MACHINE.md`, `Docs/AUDIT_GATE_MATRIX.md`, `Docs/TEST_MATRIX.md`, `Docs/RELEASE_CHECKLIST.md`, `Docs/release-cycle/FASE_03_HANDOFF.json`.
- Suite completa cerrada: exit 0, 235 tests pasados, 7 omitidos previstos, 0 fallidos; 21 min 12 s. Resultado y siete omisiones (cuatro Duo, dos iPad, una Offering remota RC) documentados en `Docs/TEST_MATRIX.md` y `Docs/release-cycle/FASE_03_HANDOFF.json`; `.xcresult` en DerivedData.
- El `.xcresult` registra 0 errores y 0 warnings de build/runtime. Xcode imprimió `IDELaunchParametersSnapshot: debugger version lookup failed for path '<nil>'` al abrir runners, aviso interno de metadatos del depurador, no deprecación del proyecto.
- UI automation de editor, exportación PDF verificada, paywall y pruebas de accesibilidad incluidas y pasadas. Siguen pendientes los flujos E2E de expiración con editor/captura abiertos y validaciones reales de StoreKit/RevenueCat, CloudKit y revisión jurídica.

