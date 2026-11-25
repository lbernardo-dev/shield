# 273-validar-ui-ia-hibrida

- Number: 273
- Slug: validar-ui-ia-hibrida

## Notes

- Continuación pedida por el usuario para cerrar la validación UI que había quedado pendiente.
- Se ejecutó `ShieldUITests` en iPhone Duo y iPad Pro con resultado 0 tests; ambos fallaron al iniciar el runner porque el simulador reportó una ruta de socket `testmanagerd` que no existe.
- Se creó el simulador aislado `MaskID UI Validation` (iPhone 18 Pro, iOS 27.2 alternativo) sin alterar simuladores compartidos. El tercer intento no llegó a compilar ni a probar: Xcode no pudo escribir `DerivedData/Shield-.../info.plist` por falta de espacio (`104 MiB` disponibles).
- `ShieldUITests` tiene 65 casos y sigue pendiente. No se corrigió código porque no hubo fallo de test de producto.
- Bundles guardados en `/Volumes/SSD/tmp/codex-maskid/MaskID-AI-ui*.xcresult`. No se limpiaron bundles, caches, temporales ni el simulador creado.

