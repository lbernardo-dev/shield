# Plan de rollback

## Principios

1. No borrar Keychain access records, bibliotecas locales, Vault, historial de compras ni productos/entitlement ASC/RevenueCat.
2. No reactivar la oferta anual por defecto sin una aprobación comercial nueva y revisión del efecto en suscriptores existentes.
3. Cualquier rollback mantiene compras pagadas/lifetime vigentes y herramientas de datos propios. No convertir rollback en borrado ni en reactivación silenciosa del modo Free indefinido.

## Si el código de acceso falla antes del release

- Revertir solo commits/archivos de monetización de Fase 03 en una rama nueva después de identificar los cambios previos Fase 01/02; no ejecutar `git reset` ni revertir archivos ajenos.
- O, preferible, corregir `AccessPolicy`/presentación conservando `AccessStateStore` y los permisos comprados. No cambiar versión/build en esta fase.
- Si se restaura transitoriamente el comportamiento previo, usar una decisión de producto explícita que impida bloquear Free existentes por error y preservar restore/recuperación.
- No restaurar assets StoreKit con un trial que no exista en ASC/RC.

## Si falla RevenueCat/StoreKit

- Mantener restauración y herramientas mínimas de recuperación; no crear acceso temporal nuevo si Keychain no puede guardar.
- Volver a consultar `CustomerInfo`, ASC/RC Offerings y estado de tienda en modo de solo lectura. No usar un booleano local como prueba de compra.
- Si la tienda no tiene productos, mostrar estado de indisponibilidad con soporte/restore, sin precio inventado ni compra StoreKit directa.

## Si hay que revertir configuración remota

Los precios no se modificaron en esta ejecución. La retirada de intro offer sí fue aplicada con autorización; reactivarla exige nueva decisión y revisión legal/comercial. No se ejecutó refund/transfer ni cambio de entitlement. Mantener los IDs y conectar cada producto aprobado al entitlement `MaskID Pro`.

## Datos y comunicación

Antes de cualquier release rollback, redactar comunicación aprobada si usuarios fueron informados del acceso temporal. No cambiar condiciones publicadas retroactivamente. Revalidar que exportar/eliminar propios datos funcione tanto con paywall como con fallo de red.
