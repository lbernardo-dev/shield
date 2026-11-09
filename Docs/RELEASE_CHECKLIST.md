# Checklist previo a Fase 04 / lanzamiento

## Bloqueos

- [ ] `LEGAL_RELEASE_BLOCKER`: aprobación competente de términos, aviso de transición, precio/renovación, derechos Free previos y conservación de datos.
- [ ] Verificar con UI E2E Save/Discard del editor al vencer el reloj y el overlay de captura expirada; la mitigación está implementada, pero falta evidencia de ejecución.
- [ ] Ejecutar compra/restore mensual, anual y lifetime en StoreKit Sandbox/TestFlight con cuentas aisladas; cubrir cancelado, pendiente, error, retry/grace, refund/revoke y cambio de Apple ID permitido.
- [ ] Probar expiración/read-only con biblioteca sintética, Vault, exportación verificada y borrado CloudKit con cuenta aislada online/offline/retry.
- [ ] Releer ASC app version/build y reconciliar la discrepancia local/ASC indicada por Fase 02; no seleccionar/build final desde Fase 03.
- [ ] Verificar VoiceOver/Voice Control/Dynamic Type XXL/contraste, iPad físico, temas y retorno desde paywall en hardware.

## Catálogo / UI

- [x] Modalidades aprobadas: €2,99 mensual, €29,99 anual, €49,99 lifetime opcional; no weekly.
- [x] ASC precios España y estado de los 4 SKUs leídos; RevenueCat offering/entitlement y annual no intro refrescados.
- [x] El paywall consume precios localizados StoreKit/RevenueCat y declara renovación mensual/anual; no se hardcodean EUR en interfaz internacional.
- [x] El aviso tiene ruta a planes/precios, privacidad, términos y soporte antes de comenzar.
- [ ] Revisar textos legales final, localizaciones accesibles y clasificación de cohortes con fixtures de datos Free preexistentes.
- [ ] Confirmar que la aprobación de Event Annual corresponde al estado actual de versión y storefront; no deducir aprobación de app desde el SKU.

## Control release

- [x] No se ha cambiado el número de versión/build para lanzamiento.
- [x] No se ha creado archive, subido build, preparado TestFlight ni publicado.
- [ ] Antes de publicar, usar el flujo asc de release con la versión/build verificada y registrar resultado de revisión Apple.
- [ ] Si se preparan creatividades, confirmar en app el tema base MaskID activo antes de capturar.
- [ ] Mantener artifacts y source; solicitar aprobación explícita al propietario antes de limpiar temporales/caches de esta sesión.
