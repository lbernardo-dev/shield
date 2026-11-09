# Migración de usuarios y recuperación

## Evidencia de instalación previa

`AppSessionCoordinator` conserva `shield.access.preMigrationInstallEvidence` antes de que una instalación migrada marque `shield.installed` por primera vez. La evidencia heredada usa `shield.installed`, `shield.onboarded` y el contador `shield.free.processedDocumentsCount`; `AppState` refuerza el marcador si carga documentos y todavía no existe un registro Keychain. `AccessMigrationClassifier` clasifica como existente cuando hay cualquiera de esas señales o contenido guardado. La clasificación se captura en el gestor antes de activar el periodo.

No se infiere una identidad universal del dispositivo. Una instalación nueva sin señales se presenta como nueva y recibe el aviso antes de empezar el reloj. Una señal ambigua no autoriza un periodo nuevo por cada actualización: el registro versionado de Keychain es la fuente posterior.

## Idempotencia

- `AccessStateStore` carga un registro `Codable` con `schemaVersion`; el registro se escribe una única vez al aceptar. Si ya existe, `startTemporaryAccess()` no concede otra ventana.
- El estado heredado `shield.isPro` en UserDefaults se ignora para autorizar compras. CustomerInfo activo y el allowlist CloudKit ya existente siguen siendo las autoridades de pago.
- Un acceso pagado observado se persiste como marcador para que una expiración posterior no sea interpretada como elegible para el periodo de migración.
- Actualizar, cambiar idioma/tema, reiniciar la app, cerrar el paywall o aceptar varias veces no cambia una fecha existente.

## Alcance de recuperación

En los días 31–60 para Free migrado, los documentos locales se listan en solo lectura. Se permite abrir/exportar y eliminar explícitamente contenido propio; Vault mantiene su autenticación biométrica/PIN. Después del día 60 la lista amplia de recovery cede al paywall, pero el enlace “Mis documentos” vuelve a exponer la recuperación mínima, incluidos exportar/eliminar y restore. Expirar nunca borra el snapshot local.

La sincronización completa es Premium y no corre en solo lectura. Las eliminaciones CloudKit explícitas se encolan y tienen ruta de reintento independiente de Premium en foreground; no se empujan nuevas creaciones/ediciones durante recovery. CloudKit real/offline y reintentos requieren prueba manual con cuenta aislada.

## Límites técnicos y riesgos

- No hay backend o cuenta de MaskID. El registro usa Keychain `WhenUnlockedThisDeviceOnly`; puede sobrevivir a algunas reinstalaciones en algunos contextos, pero no hay garantía de persistencia entre reinstalación, restauración, dispositivo nuevo, borrado de Keychain o cambio de Apple ID.
- No se hace fingerprinting ni se identifica al usuario RevenueCat anónimo como una cuenta estable. Restore sigue delegándose a RevenueCat/Apple.
- Reloj: `lastTrustedAt` limita el retroceso; adelantar el reloj puede reducir el periodo de acceso. Sin servidor no es posible certificar el tiempo real.
- Si Keychain falla/corrompe, no se inicia reloj nuevo; se presenta recuperación local y restore.
- **P1 pre-release:** si la ventana acaba mientras un documento abierto conserva cambios del editor aún no guardados, el shell puede desmontarse y perder ese estado de memoria. Los datos ya guardados permanecen. Diseñar guardado de frontera y añadir test UI antes de lanzar.
