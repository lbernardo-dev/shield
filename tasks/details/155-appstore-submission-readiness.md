# 155-appstore-submission-readiness

- Number: 155
- Slug: appstore-submission-readiness

## Notes

## Cierre de capturas iPad — 11 de septiembre de 2026

- Ante la comprobación del usuario, se auditó el estado remoto real de la versión `1.0.9`; no se tomó como evidencia suficiente el estado local.
- Se ejecutó un reemplazo explícito del set `APP_IPAD_PRO_3GEN_129` usando `.asc/screenshots/aso/final-ipad/` como fuente. Los PNG locales fueron validados a `2064×2752` y sus MD5 coinciden con los assets entregados por Apple.
- Estado remoto final `en-US`: 10/10 assets `COMPLETE`, desde `01-identity-protection.png` hasta `10-verified-export.png`.
- Estado remoto final `es-ES`: 10/10 assets `COMPLETE`, desde `01-proteccion-identidad.png` hasta `10-exportacion-verificada.png`.
- La sustitución final dejó 20 creatividades ASO iPad, sin capturas crudas `home.png`/`editor.png` ni duplicados.
- No se tocaron los 20 screenshots iPhone ni se envió la versión a revisión.

## Resultado de readiness

- Versión `1.0.9` (`PREPARE_FOR_SUBMISSION`) y build `1092026091101` (`VALID`) asociados.
- `What to Test` de TestFlight completo en `en-US` y `es-ES`.
- Metadata local validada: 18 archivos, 0 errores y 0 warnings; `metadata push --dry-run`: sin cambios.
- Validaciones estrictas de versión, TestFlight, IAP y suscripciones: 0 errores, 0 warnings y 0 bloqueos.
- `asc review doctor`: 0 bloqueos y 0 warnings; review detail configurado. App Privacy queda como información no verificable mediante API pública; había sido confirmada como publicada en sesión web autenticada previa. La cobertura web de declaraciones de App Store Regulations permanece `NOT_CHECKED` por sesión Apple caducada.
- `scripts/app_store_preflight.sh --remote`: superado.
- La versión queda preparada para que el propietario inicie el envío manual a revisión; no se ejecutó `asc review submit`.

## Confirmación de destino — 11 de septiembre de 2026

- `asc apps view --id 6790398619` devuelve exactamente `MaskID: Protect Private Data`, bundle `com.romerodev.shield`, SKU `SHIELD-ROMERODEV-001` y locale principal `en-US`.
- `asc apps list` no devuelve otra app coincidente con `MaskID` o `com.romerodev.shield`.
- El proyecto local `Shield.xcodeproj` contiene `PRODUCT_BUNDLE_IDENTIFIER = com.romerodev.shield`, `PRODUCT_NAME = MaskID`, `MARKETING_VERSION = 1.0.9` y `CURRENT_PROJECT_VERSION = 1092026091101` para el target principal y sus extensiones.
- El número visible de assets iPad es deliberadamente 10 por locale: `en-US` 10/10 y `es-ES` 10/10. Son 10 escenas iPad reales por locale, compuestas con tratamiento ASO y aplicadas a la versión `1.0.9`.
