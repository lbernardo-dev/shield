# 274-verificar-elegibilidad-pcc-analytics

- Number: 274
- Slug: verificar-elegibilidad-pcc-analytics

## Notes

- Correo de Apple recibido por el usuario confirma la asignación del entitlement a la cuenta, no la capability del App ID ni la inclusión en perfiles firmados.
- `asc` autenticado permite consultas de App Store Connect API. El App ID `com.romerodev.shield` aparece en la cuenta; la API pública de capabilities no muestra PCC (capability gestionada/portal-only). `asc web auth status` permanece sin sesión; no se inició login ni se mutó Developer Portal.
- Inspección local del IPA 1.1.8 confirma ausencia de `com.apple.developer.private-cloud-compute` en el profile embebido.
- Se consultaron en modo solo lectura solicitudes Analytics existentes. El endpoint de instancias App Downloads devolvió rate limit 429 indicando esperar 37m59s; no se descargaron segmentos/filas ni se creó acceso Analytics nuevo. No se puede confirmar el umbral de primeras descargas ni Small Business Program con la evidencia disponible.
- Sigue pendiente confirmación de Account Holder/Admin para la configuración del App ID, verificación de eligibility del programa/descargas y sesión web Apple Developer Portal. No se tocaron firma, entitlement, profile ni datos.
- Los JSON de inventario se guardaron fuera del repo con permisos privados en `/Volumes/SSD/tmp/asc-maskid-analytics.FOmkwr`; contienen metadata confidencial y no se copiaron a documentación. No se han eliminado.

