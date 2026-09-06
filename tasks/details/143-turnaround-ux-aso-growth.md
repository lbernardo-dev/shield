# 143-turnaround-ux-aso-growth

- Number: 143
- Slug: turnaround-ux-aso-growth

## Summary
Auditoría y ejecución del plan de rescate y crecimiento (Turnaround UX, ASO & Growth) para MaskID tras fracaso de tracción en la App Store (0 reseñas en US, 1 en ES, sin descargas).

## Root Causes Identified
1. **Time-to-Value roto:** Splash de 1.8s + Onboarding de 7 pantallas con PIN obligatorio casi imposible de saltar.
2. **Social Proof inexistente (0 reseñas):** `minimumAppAge = 2 * day` impedía pedir valoración nativa con StoreKit a los nuevos usuarios al completar su primera exportación segura.
3. **Casos de uso estrella ocultos:** Los modos más demandados (Alquiler de piso, Nómina, Factura, Hotel) estaban escondidos al fondo de `HomeView` en un acordeón plegado.
4. **ASO desconectado de búsquedas reales:** Títulos y subtítulos genéricos ("Protect & Mask PDF") sin términos transaccionales en español ("Tachar DNI", "Censurar fotos y nómina"). Capturas desordenadas en App Store Connect.

## Changes Implemented
1. **StoreKit Aha-Moment Reviews (`Shield/App/AppReviewManager.swift`):**
   - Reducido `minimumAppAge` de 2 días a 0 para usuarios gratuitos.
   - Umbral de valor configurado en 2 puntos (1 exportación segura = 2 pts).
   - Cadencia Premium configurada con un umbral más pausado (`minimumAppAge: 3 días`, `valueThreshold: 4`).
2. **UX & Onboarding Friction Removal:**
   - Reducido el retardo de Splash de 1.8s a 400ms en `SplashView.swift` (150ms con `reduceMotion`).
   - Mejorada la visibilidad y accesibilidad del botón "Configurar más tarde" en `OnboardingSteps.swift` (`ShieldTheme.secondary`, semibold).
   - Modos rápidos elevados directamente a la cabecera de `HomeView.swift` bajo los botones de acción rápida, eliminando la duplicación en el menú inferior.
3. **ASO 1.0.7 & Posicionamiento de Protección de Identidad (`metadata/`):**
   - `metadata/app-info/es-ES.json`: `MaskID: Protege tu Identidad` / `Enmascara Datos en Documentos`
   - `metadata/app-info/en-US.json`: `MaskID: Protect Your Identity` / `Mask Sensitive Data in Docs`
   - `metadata/version/1.0.7/`: Descripciones enfocadas en protección de identidad contra el fraude y robo de datos, con keywords de 99 caracteres y textos de beneficios.
   - `scripts/compose_aso_screenshots.py`: Generador de 10 capturas de pantalla únicas (sin repetición) con titulares claros, palabra de acción en Cyan `#20C7D9`, badges temáticos de seguridad, resplandor ambiental y marco de iPhone flotante en 3D.
4. **Build & Test Toolchain (`Makefile`, `scripts/xcbuild.sh`, `.gitignore`):**
   - Agregado `COPYFILE_DISABLE=1` y rutas con comillas para evitar generación de AppleDouble `._*` en volúmenes externos ExFAT.
   - Configurado `DERIVED_BASE` automático en `/tmp/DerivedData-MaskID` para ejecución en SSD APFS rápido.
   - `ShieldUITests/ShieldLaunchTests.swift` ajustado con scroll por coordenadas suaves.

## Verification & Deployment
- `make build`: **BUILD SUCCEEDED**
- `scripts/xcbuild.sh ... test -only-testing:ShieldTests`: **TEST SUCCEEDED** (65/65 tests unitarios pasaron limpios, incluyendo `AppReviewManagerTests` y `SecurityPrivacyTests`).
- `asc versions create`: Versión 1.0.7 creada en App Store Connect (`78a395e3-84fe-4fa9-bd95-9e8c0c194435`, `PREPARE_FOR_SUBMISSION`).
- `asc metadata push`: Sincronizados al 100% `app-info` y `version 1.0.7` en `es-ES` y `en-US` (Títulos, Subtítulos, Keywords de 99 chars, Descripciones de Identidad, Promotional Text y What's New).
- `asc screenshots upload`: Subidas las 10 capturas de pantalla de iPhone por cada idioma (20 en total), con títulos de acción en Cyan y sin repetir ninguna imagen (todas en estado `COMPLETE` en servidores de Apple).
