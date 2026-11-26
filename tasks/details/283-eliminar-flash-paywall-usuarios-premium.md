# 283. Eliminar flash de Paywall para usuarios Premium

## Contexto y Causa Raíz
El usuario reportó que usuarios premium podían llegar a ver momentáneamente la pantalla de Paywall en transiciones o relanzamientos.
Se identificaron 4 causas raíz arquitectónicas:
1. **Invalidación innecesaria en segundo plano (`ContentView.swift`)**: Al pasar la app a segundo plano (`.background`), se ejecutaba `premium.invalidateCloudKitPremiumAccess()`, lo cual reseteaba en memoria la identidad verificada de CloudKit y recalculaba el estado de acceso. Si el usuario tenía su período de prueba caducado, el estado cambiaba a `.mandatoryPaywall`. Al reactivar la app, la vista mostraba la pantalla de paywall mientras se ejecutaba la llamada asíncrona de red a CloudKit.
2. **Inicialización asíncrona no sincronizada en `PremiumManager.init()`**: Al arrancar la app, `isPro` se establecía en `false` por defecto y no leía inmediatamente el identificador permanente de CloudKit ni los datos en caché de RevenueCat (`Purchases.shared.cachedCustomerInfo`) o `accessRecord?.paidEntitlementObservedAt`. Esto creaba una ventana de milisegundos donde el usuario era considerado temporalmente como no premium.
3. **Comportamiento permisivo de `AccessGateRootView` en `ContentView.swift`**: Si `accessState` estaba en `.verifying` o `.mandatoryPaywall` mientras se resolvía la suscripción, `ContentView` inyectaba directamente `AccessGateRootView()`, que renderizaba `PaywallView(isPresented: .constant(true), ...)`.
4. **Falta de guarda a nivel de vista en `PaywallView.swift`**: `PaywallView` no comprobaba si `pm.isPro` ya era verdadero antes de renderizar la UI completa del paywall.

## Cambios Implementados
1. **`Shield/Premium/PremiumManager.swift`**:
   - Se crearon los métodos estáticos `readCachedCloudKitRecordName()` y `writeCachedCloudKitRecordName(_:)` para persistir y leer de forma unificada el record ID tanto en App Group (`group.com.romerodev.shield`) como en `UserDefaults.standard`.
   - En `init()`, se restauró sincrónicamente la identidad CloudKit en caché contra la lista de IDs permanentes (`grantsPermanentCloudKitAccess`), la información en caché de RevenueCat (`Purchases.shared.cachedCustomerInfo`) y el registro histórico `paidEntitlementObservedAt`.
   - Si el usuario cuenta con acceso premium pagado o CloudKit verificado, se establecen de inmediato en el frame 0: `isPro = true`, `accessState = .purchased`, `hasResolvedSubscription = true`, `isResolvingSubscription = false` y `entitlementTier = .lifetime`.
   - En `refreshCloudKitPremiumAccess()`, se guarda el ID verificado con `writeCachedCloudKitRecordName`.
2. **`Shield/App/ContentView.swift`**:
   - Eliminada la llamada a `premium.invalidateCloudKitPremiumAccess()` en `.background` dentro de `handleScenePhaseChange`.
   - En `ContentView.body` para `sessionStage == .ready`, si el usuario es `premium.isPro || premium.accessState.hasFullAccess`, se presenta directamente el `AuthenticatedShellView`. Mientras se resuelve la suscripción (`isResolvingSubscription` o `accessState == .verifying`), se muestra una pantalla de carga neutral y NUNCA el `AccessGateRootView`.
   - En `AccessGateRootView`, si `premium.isPro` o `hasFullAccess` está activo, se devuelve `Color.clear`.
3. **`Shield/Views/Paywall/PaywallView.swift`**:
   - Al inicio del `body`, si `pm.isPro && !ASOScreenshotMode.isEnabled`, devuelve `Color.clear` y ejecuta `isPresented = false` inmediatamente en `.onAppear`.
   - Se añadió `.onChange(of: pm.isPro)` para auto-descartar de inmediato si la condición se vuelve verdadera en tiempo de ejecución.
4. **`ShieldTests/SecurityPrivacyTests.swift`**:
   - Añadido test unitario `cachedCloudKitRecordNamePersistence` para verificar la lectura y escritura sincrónica de la identidad en caché.

## Verificación
- **Unit Tests**: Ejecutados los tests de `ShieldTests` en el simulador iPhone 18 Pro (`CCC41661-BB97-41D2-87E2-D47FC51B1C6B`). Todos los tests pasaron exitosamente (`Testing started completed: 63.802s`).
- **Compilación e Instalación**: Compilación Debug limpia para el iPhone 15 Pro Max físico (`00008130-0011199026A0001C`).
- **Despliegue**: Instalada y lanzada exitosamente la aplicación en el iPhone 15 Pro Max con `xcrun devicectl`.
