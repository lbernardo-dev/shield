# Playbook de rollback y hotfix

## Antes de distribución

1. No publicar ni subir a TestFlight hasta cerrar los bloqueos jurídicos, RC, privacy label, screenshots y Sandbox.
2. Mantener 1.1.7 en rama local; no revertir en el árbol mezclado actual. Un rollback de código se prepara en una rama aparte y con diff por fase.
3. No eliminar AccessStateStore/Keychain, documentos locales, archivos Vault, purchases, receipts, entitlement MaskID Pro ni SKUs. La ventana temporal y marcador de compra son persistentes.
4. Si archive o export falla, arreglar configuración local antes de asignar otro build; si un build ya se hubiese distribuido, asignar NN mayor después de releer ASC y archives.

## Si aparece un fallo en TestFlight después de autorización

- Detener nuevas invitaciones y la distribución del grupo autorizado; no someter App Store.
- Reproducir en Sandbox con el estado afectado. Conservar crash logs mínimos redaccionados y diagnóstico sin documentos ni datos del usuario.
- Priorizar hotfix por encima de reversión destructiva. El hotfix conserva la lectura de los registros de acceso, transacciones pagadas/restauradas y rutas para consultar/exportar/eliminar documentos.
- Una versión previa de App Store no vuelve a instalarse automáticamente sobre la nueva. Preparar una build hotfix con versión/build nuevos y validar de nuevo gates, purchase/restore y migración.
- No crear un kill-switch remoto ficticio. La lógica de acceso es local y no se encontró feature flag de emergencia validado.

## Si una configuración remota falla

- No bajar precio, reactivar una oferta introductoria, alterar grupo/suscripción, cambiar entitlement ni borrar producto para resolver un estado de app.
- Diagnosticar por separado: ASC pricing/availability, RevenueCat product/entitlement/offering, StoreKit product list y customer entitlement.
- Si StoreKit/RC no entrega catálogo, conservar soporte, restore y recuperación mínima; no inventar precio ni compra directa.
- Cualquier reversión de precios/ofertas requiere aprobación comercial/legal y read-back de transacciones/renovaciones existentes.

## Comunicación y datos

Preparar comunicación revisada antes de afectar cohortes ya informadas. No presentar una reversión de gate como borrado de datos ni quitar derechos pagados. Tras hotfix, repetir pruebas de expiración día 15/30/60, editor/captura abiertos, restore/lifetime, export/delete y sync.
