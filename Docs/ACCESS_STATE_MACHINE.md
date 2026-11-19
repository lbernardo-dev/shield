# Máquina de estados de acceso

## Precedencia

1. Entitlement de pago activo verificado por RevenueCat, o derecho vitalicio CloudKit validado en producción → `purchased` / FULL.
2. RevenueCat mantiene activo el entitlement durante cualquier gracia real confirmada → FULL. Un billing retry sin entitlement activo no lo crea.
3. Acceso temporal FULL aún vigente.
4. Paywall obligatorio al superar los 15 días. No hay una ventana temporal de solo lectura; la recuperación mínima de datos propios está disponible desde el hard paywall.
5. Problemas de persistencia/verificación usan estados seguros que nunca crean otro periodo.

## Flujo

```mermaid
stateDiagram-v2
    [*] --> verifying
    verifying --> purchased: CustomerInfo / derecho verificado
    verifying --> newUserNotice: sin compra + cohorte nueva + almacenamiento disponible
    verifying --> existingUserNotice: sin compra + cohorte Free anterior
    verifying --> storageUnavailable: Keychain inaccesible/corrupto
    newUserNotice --> temporaryFullAccess: aceptar y guardar registro · 15 días
    existingUserNotice --> temporaryFullAccess: aceptar y guardar registro · 15 días
    temporaryFullAccess --> purchased: compra / restore válida
    temporaryFullAccess --> mandatoryPaywall: expiran los 15 días
    mandatoryPaywall --> purchased: compra / restore válida
    mandatoryPaywall --> mandatoryPaywall: recuperar/ver/exportar/eliminar datos
    storageUnavailable --> purchased: restauración verificada
    storageUnavailable --> storageUnavailable: recuperar datos en solo lectura
```

## Capacidades

| Estado | FULL de producto | Ver/exportar/eliminar datos propios | Compra/restore/gestión | Legal/soporte/apariencia | Escrituras del producto y sync |
|---|---:|---:|---:|---:|---:|
| `purchased` | Sí | Sí | Sí | Sí | Sí, según capacidades contratadas |
| `temporaryFullAccess` | Sí | Sí | Sí | Sí | Sí, igual que Premium pagado |
| `mandatoryPaywall` | No | Sí, con herramientas mínimas | Lifetime y restore | Sí | No |
| `verifying` | No hasta confirmar | Sí por ruta de recuperación | Sí | Sí | No |
| `storageUnavailable` | No se inicia acceso nuevo | Sí cuando haya datos legibles | Sí | Sí | No |
| Aviso nuevo/legacy | Aún no | Sí, con ruta propia | Sí | Sí | No hasta que se guarde la aceptación |

`AccessPolicy` resuelve autorización; `AccessCapability` es la matriz común. `PremiumManager.isPro` es una proyección del acceso FULL y solo se usa para mostrar/coordinar funciones, no como autorización persistida. Las operaciones de `AppState` y `CloudSyncManager` también guardan capacidades.

## Tiempo y persistencia

- `AccessConfiguration` concede 15 días naturales a todas las cohortes. El paywall obligatorio empieza al caducar ese único periodo; la recuperación mínima de documentos sigue disponible desde el paywall.
- `Date` almacena un instante absoluto (UTC internamente); el vencimiento suma días calendario usando el calendario/zona local al activar para respetar días naturales/DST. Se guarda una sola vez en Keychain.
- `lastTrustedAt` solo avanza (`max(candidate, lastTrustedAt)`) y se persiste como máximo una vez por hora para reducir escrituras. El adelanto del reloj puede caducar antes el periodo; el retroceso no lo reinicia.
- `noticeVersion` y `noticeAcceptedAt` versionan el aviso aceptado. El inicio se guarda en Keychain antes de conceder acceso. No se emite un evento de analítica al pulsar activar.
- El estado de compra es distinto al estado temporal. El botón de acceso temporal no llama a StoreKit ni a RevenueCat para comprar.
- La migración de esquema v1 conserva el inicio ya guardado, ajusta la caducidad a inicio + 15 días y borra la antigua fecha de recuperación. Reinstalar o aceptar otra vez no crea una fecha de inicio nueva.
- Los usuarios con una ventana anterior de 30 días migran usando el inicio original; quienes ya cumplieron 15 días pasan directamente al hard paywall. No se concede una ventana nueva por migración.
