# Matriz de pruebas Fase 03

## Evidencia local

**Entorno de ejecución:** iOS Simulator `CCC41661-BB97-41D2-87E2-D47FC51B1C6B` (iPhone 18 Pro; iOS Simulator 27.2 en la configuración observada), Xcode, scheme `Shield`. SDK RevenueCat resuelto en `purchases-ios` 5.102.3.

Comando ejecutado para las suites de monetización:

```sh
xcodebuild test -quiet -project Shield.xcodeproj -scheme Shield \
  -destination 'platform=iOS Simulator,id=CCC41661-BB97-41D2-87E2-D47FC51B1C6B' \
  -only-testing:ShieldTests/AccessPolicyTests \
  -only-testing:ShieldTests/SubscriptionExperienceTests \
  -only-testing:ShieldTests/FreeQuotaTests
```

**Suite completa (8-11-2026):** `xcodebuild test -quiet -project Shield.xcodeproj -scheme Shield -destination 'platform=iOS Simulator,id=CCC41661-BB97-41D2-87E2-D47FC51B1C6B'` terminó con exit code 0: 235 pasaron, 7 se omitieron y 0 fallaron (242 tests; 21 min 12 s). El `.xcresult` registra 0 errores, 0 warnings de build y 0 warnings runtime: `/Users/romerodev/Library/Developer/Xcode/DerivedData/Shield-emunowwqdzukpfbkshmbfqbgsvss/Logs/Test/Test-Shield-2026.11.08_15-17-39-+0100.xcresult`. Se omitieron cuatro pruebas iPhone Duo, dos pruebas específicas de iPad y una resolución de Offering RevenueCat que requiere el catálogo remoto. La salida de Xcode sí emitió `IDELaunchParametersSnapshot: debugger version lookup failed for path '<nil>'`; es un aviso del lanzador de tests, separado de warnings del proyecto y de deprecaciones.

## Escenarios (PASS solo indica evidencia realmente disponible)

| # | Escenario | Estado | Evidencia / limitación |
|---:|---|---|---|
| 1 | Instalación nueva se clasifica y requiere aviso antes del reloj | PASS unit | `AccessPolicyTests/freshInstallRequiresNotice` |
| 2 | Activar acceso interno no llama a StoreKit purchase | PASS inspección | `startTemporaryAccess` solo crea/salva `AccessRecord`; flujo transaccional no invocado |
| 3 | Nuevo usuario permanece FULL en día 14 | PASS unit | `newUserExpiry` |
| 4 | Vencimiento nuevo en día 15 | PASS unit | `newUserExpiry` |
| 5 | Aceptación y versión del aviso persisten en record | PASS unit | `freshInstallRequiresNotice` |
| 6 | Existing Free detectado por marcador previo | PASS unit | `freshInstallRequiresNotice` |
| 7 | Existing Free detectado por uso/contador existente | PASS unit | `freshInstallRequiresNotice` |
| 8 | Legacy permanece FULL en día 29 | PASS unit | `existingFreeMigrationWindow` |
| 9 | Legacy cambia a recovery al día 30 | PASS unit | `existingFreeMigrationWindow` |
| 10 | Legacy sigue en recovery en día 59 | PASS unit | `existingFreeMigrationWindow` |
| 11 | Recovery termina al día 60 | PASS unit | `existingFreeMigrationWindow` |
| 12 | Defaults centrales son 15/30/30 | PASS unit | `configurableAccessPeriods` (run final pendiente de registrar) |
| 13 | Duraciones pueden variar desde configuración central | PASS unit | `configurableAccessPeriods` (run final pendiente de registrar) |
| 14 | Día calendario local a través de DST Europe/Madrid | PASS unit | `calendarDaysAcrossDaylightSaving` (run final pendiente de registrar) |
| 15 | Compra vigente toma precedencia incluso ante error de storage | PASS unit | `paidEntitlementsTakePrecedence` |
| 16 | Derecho pagado ya observado no crea ventana temporal tras expirar | PASS unit | `paidEntitlementsTakePrecedence` |
| 17 | Read-only permite ver documentos propios | PASS policy unit | `readOnlyCapabilityMatrix` |
| 18 | Read-only permite exportar datos propios | PASS policy unit | `readOnlyCapabilityMatrix` |
| 19 | Recovery/expiry permite eliminar datos propios | PASS policy unit | `readOnlyCapabilityMatrix` |
| 20 | Recovery bloquea creación | PASS policy unit | `readOnlyCapabilityMatrix` |
| 21 | Recovery bloquea modificación | PASS policy unit | `readOnlyCapabilityMatrix` |
| 22 | Recovery bloquea importación | PASS policy unit | `readOnlyCapabilityMatrix` |
| 23 | Recovery bloquea Cloud writes | PASS policy unit | `readOnlyCapabilityMatrix` |
| 24 | Restauración/legal siguen accesibles | PASS policy unit | `readOnlyCapabilityMatrix` |
| 25 | Retroceso local no reabre tiempo | PASS unit | `clockRollbackClampsToLastTrustedValue` |
| 26 | Fallo real de Keychain al guardar el inicio | NOT RUN | requiere Keychain/device test controlado |
| 27 | Reset de UserDefaults no duplica el periodo | NOT RUN | idempotencia de código/Keychain inspeccionada; sin UI/device test |
| 28 | Reinstalación conserva tiempo bajo Keychain persistente | NOT RUN | comportamiento varía por dispositivo/backup; no se promete garantía |
| 29 | Reinstalación tras expiry no vuelve a conceder acceso | NOT RUN | requiere hardware/estado Keychain aislado |
| 30 | Cambio a dispositivo nuevo restaura compra | NOT RUN | requiere Apple ID de Sandbox y transacción |
| 31 | RevenueCat offline devuelve entitlement cacheado | NOT RUN | CustomerInfo E2E en Sandbox pendiente |
| 32 | Restore mensual/anual/lifetime | NOT RUN | no se realizaron transacciones |
| 33 | Compra cancelada | NOT RUN | StoreKit Sandbox pendiente |
| 34 | Compra pendiente | NOT RUN | StoreKit Sandbox pendiente |
| 35 | Compra con error/red restringida | NOT RUN | StoreKit Sandbox pendiente |
| 36 | Compra durante tiempo temporal pasa inmediatamente a FULL pagado | PARTIAL | precedencia de policy test; transacción/CustomerInfo no probados |
| 37 | Periodo de gracia real de Apple/RC | NOT RUN | requiere estado billing Sandbox y CustomerInfo real |
| 38 | Retry sin entitlement activo no concede FULL | PASS por regla | `apply` y `isActive` son autoridad; caso RC real no ejecutado |
| 39 | Refund/revocation conserva documentos y reevalúa acceso | NOT RUN | requiere StoreKit server/sandbox |
| 40 | ASC precios mensuales/anuales ES leídos | PASS externo read-only | 2,99 €/mes, 29,99 €/año; 8-11-2026 |
| 41 | Lifetime ES y no-consumible leídos | PASS externo read-only | 49,99 €, ASC type `NON_CONSUMABLE`; 8-11-2026 |
| 42 | Event Annual retorno a €29,99 y estado aprobado | PASS externo read-only | ASC pricing summary España; 8-11-2026 |
| 43 | Annual intro offers no aparecen para nuevas altas | PASS config readback | ASC list 0; RC store state 0 territorios |
| 44 | Comprador antiguo conserva transacción/terms tras borrar oferta | NOT RUN | no se alteraron compras; verificación Apple customer-level pendiente |
| 45 | Renewal disclosure muestra precio localizado y periodo | PASS unit | `SubscriptionExperienceTests/renewalDisclosureMakesTheNextChargeClear` |
| 46 | No hay CTA/copy de trial nuevo en paywall/onboarding/export | PASS static | búsquedas en Swift/localizaciones; prueba visual pendiente |
| 47 | Sin producto disponible, restore/support no desaparecen | NOT RUN | error-state UI automation pendiente |
| 48 | Editor readonly bloquea gestos/acciones y conserva exportación | PARTIAL | guards inspeccionados; UI recovery no automatizada |
| 49 | Expiración con captura activa no confirma nuevo documento; ofrece resolver el borrador | PARTIAL | overlay de vencimiento conserva el flujo abierto y ofrece planes o recuperación; test de UI/dispositivo pendiente |
| 50 | Expiración con editor abierto y cambios sin guardar | PARTIAL | alerta Save/Discard y lease de guardado de un solo uso añadidos; UI E2E pendiente |
| 51 | Delete propio en CloudKit se reintenta sin sync Premium | PARTIAL | ruta de queue inspeccionada; no se probó CloudKit real/offline |
| 52 | Bóveda conserva Face ID/PIN en recovery | NOT RUN | flujo local preservado; UI física pendiente |
| 53 | Deep link/Shortcut captura entra por gate | NOT RUN | intent solo abre app; navegación E2E pendiente |
| 54 | Widget no crea ni modifica documento | PASS inspección | snapshot agregado de lectura; no existe gate de compra/acción |
| 55 | Firebase no recibe consentimiento contractual como analytics consent | PASS por código | inicio no emite evento; opt-out manual sigue pendiente |
| 56 | VoiceOver/Voice Control manual, contraste físico y dispositivos reales | NOT RUN | Las pruebas UI automatizadas de Dynamic Type XXL, movimiento reducido, contraste aumentado, nombres y áreas táctiles sí pasan; uso físico/manual aún pendiente |
| 57 | iPad/multiventana | NOT RUN | iPad físico pendiente; Fase 02 notifica pendiente |
| 58 | Cancelar/volver a recovery desde paywall obligatorio | PARTIAL | CTA y callback implementados; navegación UI no automatizada |
| 59 | Temas voluntarios no se alteran por elegibilidad Premium temporal | PASS unit | `EnhancementFeaturesTests/seasonalThemeConsentDoesNotDependOnEntitlement` |
| 60 | Todos los unit tests del proyecto y UI tests del scheme | PASS | 235 pasaron, 7 omitidos, 0 fallidos; exit code 0, bundle indicado arriba |
| 61 | Lease de cierre guarda solo una vez el documento persistido actualmente abierto | PASS unit | `AccessPolicyTests/accessBoundarySaveLeaseEligibility` |

Las pruebas `NOT RUN` no se representan como PASS y exigen los entornos anotados. Este informe no constituye aprobación de publicación.
