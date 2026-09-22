# 181-premium-value-alignment-and-instrumentation

- Number: 181
- Slug: premium-value-alignment-and-instrumentation

## Notes

## Objetivo

Alinear el contrato real de Free/Premium con la experiencia de producto, cerrar bypasses de capacidades Premium y añadir observabilidad suficiente para entender qué ocurre después de cancelar el trial.

## Aplicado

- Unificado el control de acceso de capacidades Premium en `PremiumManager` y en los dominios de Home, Editor, Capture, Settings y selección de iconos.
- Mantenida abierta en Free la propuesta de seguridad principal: enmascarado, exportación verificada, cifrado local y Bóveda local.
- Limitados y medidos como Premium los flujos de trabajo repetitivos o avanzados: documentos ilimitados, estilos avanzados, modos profesionales, batch, nube/proveedores, ajustes avanzados, marcas de agua personalizadas e iconos alternativos.
- Actualizado el paywall y onboarding para explicar el valor de Premium sin vender la Bóveda local como exclusiva.
- Añadidos eventos y propiedades de lifecycle, tier, estado de suscripción, feature gate, milestones de cuota y selección/inicio de compra.
- Actualizados `Docs/PRODUCT_POSITIONING.md`, `Docs/ARQUITECTURA.md` y `Docs/ANALYTICS_TRACKING_PLAN.md` con el contrato vigente y el plan de cohortes.
- Añadidas pruebas de contrato para modos profesionales, herramientas Premium y triggers del paywall.

## Verificación

- `jq empty Shield/Localization/Strings/Paywall.xcstrings` correcto.
- `git diff --check` correcto.
- Build genérico de la app correcto; se generó `MaskID.app`.
- `xcodebuild build-for-testing` correcto para `MaskID`, `ShieldTests` y `ShieldUITests` (`TEST BUILD SUCCEEDED`).
- No se ejecutaron tests en Simulator porque `CoreSimulatorService` no está disponible en este entorno.

## Decisiones deliberadas

- No se cambiaron precios ni límites sin datos de comportamiento.
- No se convirtió la exportación segura en un paywall.
- No se ejecutó limpieza de caches, logs ni sidecars; requiere confirmación explícita según las instrucciones del repositorio.
