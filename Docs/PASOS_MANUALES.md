# Shield — pasos externos de publicación

> Revisión: 13 de julio de 2026. El trabajo local verificable se documenta en `RELEASE_READINESS_2026-07-13.md`.

## Estado rápido

| Puerta | Estado local | Acción externa |
|---|---|---|
| Privacy manifest | Completado y validado | Hacer coincidir App Privacy de App Store Connect |
| Firma Distribution | Archive, export y auditoría IPA superados | Ninguna antes del upload |
| iCloud/CloudKit | Entitlement de producción verificado en el IPA | Confirmar schema de producción antes de TestFlight |
| App Group/Keychain Group | Verificados en app y Share Extension exportadas | Ninguna antes del upload |
| URL scheme `shield` | Completado | Ninguna |
| StoreKit | Implementación y fixture local | Crear productos, precios, trial y probarlos en sandbox/TestFlight |
| Privacidad/términos | Contenido local, HTML publicable y endpoints remotos validados | Mantener las URLs publicadas y registrarlas en App Store Connect |
| Icono y marca | Integrados como Shield | Confirmar render en Archive/App Store |
| App Store metadata | Borrador ES/EN y screenshots reales validados | Iniciar sesión y crear ficha/localizaciones |
| Archive | `Shield-1.0-2.xcarchive` e IPA Distribution válidos | Subir build 2 solo con autorización expresa |
| TestFlight | No puede simularse localmente | Beta física de 72 horas como mínimo |

## Configuración del Developer Portal

Los dos bundle IDs, el App Group y los entitlements ya están reflejados en el IPA firmado. Antes de TestFlight solo queda confirmar visualmente que el schema de `iCloud.com.romerodev.shield` está desplegado en producción. El identificador principal todavía aparece con Push Notifications en una consulta remota aunque no existe entitlement ni uso de push en el binario; puede retirarse manualmente como limpieza del portal, pero no afecta al artefacto exportado.

## App Store Connect

1. Iniciar sesión como Account Holder/Admin y crear Shield con bundle ID `com.romerodev.shield`; actualmente no existe ficha.
2. Crear los productos que coincidan exactamente con `Shield/Resources/Shield.storekit` y probar compra, restauración, cancelación y error.
3. Registrar las URLs inglesas de `https://lbernardo-dev.github.io/apps/en/case-studies/shield/` como referencias principales y las equivalentes de `https://lbernardo-dev.github.io/apps/es/casos/shield/` en la localización española. Usar las rutas `https://lbernardo-dev.github.io/apps/apps/shield/` solo como compatibilidad.
4. Declarar que no existe tracking ni analítica remota. Declarar iCloud privado según los hechos de privacidad documentados.
5. Revisar y cargar los screenshots ya capturados en `.asc/screenshots`; los cuatro conjuntos ES/EN para iPhone 6.9 e iPad 13 pasan la validación local de dimensiones.
6. Ejecutar `scripts/app_store_preflight.sh --remote` antes del upload.
7. Con autorización expresa, subir el IPA de build 2, distribuir a TestFlight interno y revisar MetricKit/Organizer durante al menos 72 horas.

## Pruebas físicas obligatorias

- Cámara, escáner y permisos denegados/limitados.
- Fotos con acceso limitado y Files providers instalados.
- Share Extension desde Fotos, Archivos, Mail y Safari.
- Face ID/Touch ID, cambio de biometría y dispositivo bloqueado.
- iPad Split View, teclado, VoiceOver, Voice Control, Dynamic Type XXXL y Reduce Motion.
- PDFs adversariales, multipágina y grandes, comprobados también con herramientas externas.
