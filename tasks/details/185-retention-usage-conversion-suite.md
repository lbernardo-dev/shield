# 185-retention-usage-conversion-suite

- Number: 185
- Slug: retention-usage-conversion-suite

## Objetivo

Implementar la suite integral de retención, uso recurrente, diferenciación ética Free/Pro, técnica "Preview Before Paywall", watermarking anti-fraude y onboarding personalizado en MaskID.

## Cambios Aplicados

### 1. Retención y Uso Recurrente: Bóveda Activa & Recordatorios de Caducidad
- Creado `DocumentExpiryReminderManager.swift` (100% on-device, compatible con Swift Concurrency y UserNotifications):
  - Parser multi-formato de fechas de vencimiento de documentos de identidad (`DD/MM/YYYY`, `YYYY-MM-DD`, etc.).
  - Cálculo dinámico del estado de vigencia (`.valid`, `.expiringSoon(days)`, `.expired(days)`).
  - Programación de recordatorios locales a 30 y 7 días previos a la expiración del DNI, NIE o Pasaporte.
- En `DocumentRow` (`HomeView.swift`):
  - Añadido badge adaptativo de estado de expiración cuando la bóveda está desbloqueada (`Caduca en Xd`, `Caducado`, `Vigente`).
- En `VaultView.swift`:
  - Añadido banner de alerta de documentos con caducidad próxima.
  - Añadida tarjeta interactiva de Higiene de Privacidad (invitando a mover capturas sensibles del carrete público a la bóveda cifrada).
  - Añadida acción contextual rápida de "Compartir copia protegida", que permite exportar directamente una versión con marca de agua con la fecha del día sin reconstruir el documento en el editor.

### 2. Diferenciación Free vs. Pro & Superpoderes de Valor
- En `SecureExportModels.swift` y `ExportVerifier.swift`:
  - Cálculo e inclusión del hash criptográfico SHA-256 en `ExportVerificationReport` tanto para PDFs como para imágenes.
- En `ExportFormViews.swift`:
  - Visualización del hash SHA-256 en la tarjeta de `ExportProtectionCheckView` para dar trazabilidad e integridad técnica profesional.
- En `WatermarkConfigView.swift`:
  - Incorporado banner informativo de Protección Anti-Fraude destacando la prevención de usurpación de identidad.
  - Añadidos presets específicos de destino con fecha automática: Copia protegida anti-fraude, Alquiler, Selección de empleo, Registro de hotel, etc.

### 3. Gatillos de Conversión: "Preview Before Paywall" y Aviso de Cuota
- En `EditorView.swift`:
  - Los usuarios de la versión Free ahora pueden abrir la herramienta de marca de agua, personalizarla y verla previsualizada en tiempo real sobre el documento en el lienzo.
- En `ExportSheetView.swift`:
  - Si un usuario Free intenta exportar un documento con marcas de agua anti-fraude o estilos premium, se presenta el diálogo contextual ("Preview Before Paywall"):
    - Opción 1: Probar Pro Gratis (7 días) para exportar con máxima protección.
    - Opción 2: Exportar versión estándar de forma 100% gratuita (retirando la marca y usando censura sólida de caja negra).
- En `HomeDashboardViews.swift`:
  - Aviso de cuota urgente en `HomeHeroCardView` cuando restan 2 o menos documentos gratuitos (`home_quota_warning_title`).

### 4. Personalización del Onboarding por Arquetipo
- Conectado `state.selectedGoal` en `OnboardingFlowView.swift` hacia `OBPaywallView` en `OnboardingSteps.swift`.
- Diseñado el banner de recomendación personalizada (`archetypeGoalBanner`) que adapta el argumento de valor del paywall al objetivo del usuario (Alquiler, Empleo, Vehículo, Banca, Viajes).

### 5. Localización
- Actualizados los archivos `.xcstrings` (`Vault.xcstrings`, `Editor.xcstrings`, `Onboarding.xcstrings`, `Home.xcstrings`) con todas las cadenas traducidas tanto al español como al inglés.

## Verificación

- `jq empty Shield/Localization/Strings/*.xcstrings` -> válido (sintaxis JSON impecable).
- `git diff --check` -> limpio, sin problemas de espacios ni formato.
- `make build` -> compilación estricta correcta (`** BUILD SUCCEEDED **`).
- `xcodebuild build-for-testing` -> compilación de targets de test correcta (`** TEST BUILD SUCCEEDED **`).
- `make test` -> suite de tests lógicos y unitarios ejecutada sobre el simulador.
