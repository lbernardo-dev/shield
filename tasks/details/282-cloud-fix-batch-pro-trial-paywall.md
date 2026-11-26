# 282-cloud-fix-batch-pro-trial-paywall

- Number: 282
- Slug: cloud-fix-batch-pro-trial-paywall
- Status: Completed (100% Tests Passed, Installed & Launched on iPhone 15 Pro Max)

## Resumen de Ejecución

1. **Diagnóstico y Corrección de Conexión Cloud (Dropbox y Google Drive)**:
   - **Dropbox Crash Fix**:
     - En `DirectCloudStorageManager.swift`, la implementación previa de `presentationAnchor` utilizaba `?? ASPresentationAnchor()`, lo cual devolvía una instancia de `UIWindow()` vacía y desvinculada de cualquier escena (`UIWindowScene`) cuando se producía una animación o transición modal. En iOS 17/18/26, intentar presentar un `ASWebAuthenticationSession` sobre un `UIWindow` sin escena provocaba una excepción no capturada de UIKit (`NSInternalInconsistencyException`) cerrando la app abruptamente.
     - Se reforzó `presentationAnchor` para resolver activamente la escena en primer plano (`foregroundActive`), su ventana clave (`keyWindow`) o cualquier ventana con `rootViewController` válido.
     - Se habilitó `session.prefersEphemeralWebBrowserSession = true`, lo que evita que la app nativa de Dropbox intercepte la URL mediante Universal Links cerrando la sesión de autenticación interna de MaskID.
     - En `ExternalStoragePickerSheet`, se eliminó el conflicto de presentación anidada (`.sheet` dentro de `.sheet`), integrando directamente la vista del explorador de proveedores (`CloudProviderBrowserView`).
   - **Google Drive Error 403 (access_denied)**:
     - El proyecto en Google Cloud Console se encuentra en estado "Testing" (En pruebas). Google bloquea a cualquier usuario que no esté registrado explícitamente en la lista de "Test users" de la consola de Google OAuth.
     - Se añadió un aviso de diagnóstico en `CloudConnectionRecoveryView` informando sobre la necesidad de registrar `lbernardo.cu@gmail.com` como tester en la consola de Google Cloud.
     - Se integró un botón de acción rápida directo para **"Importar desde Archivos de iOS"**, permitiendo importar de Google Drive o Dropbox inmediatamente sin restricciones de API ni de consola.

2. **Lógica del Botón "Batch Pro" en Header de Modos**:
   - En `HomeSectionViews.swift`, se actualizó la etiqueta del botón de lote en la sección de modos rápidos:
     - Si el usuario **ya es Pro**: Muestra `"Lote"` (en español) o `"Batch"` (en inglés).
     - Si el usuario **no es Pro**: Muestra `"Lotes Pro"` o `"Batch Pro"`.

3. **Período de Acceso Completo Reducido a 3 Días y Forzado de Paywall con Ventajas**:
   - En `SubscriptionExperience.swift`:
     - Se actualizó `AccessConfiguration.fullAccessDays = 3` (reemplazando los 15 días previos).
     - Se actualizó `noticeVersion` a `"commercial-access-2026-11-v3"`.
   - En `PaywallView.swift`:
     - Se eliminó la restricción `if !isMandatoryAccess` que ocultaba las tarjetas de valor, de modo que cuando el paywall forzado se activa tras vencer los 3 días de prueba, el usuario tiene acceso a toda la información detallada de las ventajas de MaskID:
       - Badges de confianza (100% On-Device, Cero Nube, Verificado por Apple StoreKit).
       - Comparativa de valor Free vs Pro.
       - Cuadrícula de características completas (documentos ilimitados, estilos avanzados, procesamiento por lotes, herramientas de ajuste, modos profesionales y sincronización iCloud).
       - Sección de Preguntas Frecuentes (FAQ) explicando que la compra Lifetime es de pago único para siempre sin cargos recurrentes.
     - Se actualizaron las cadenas descriptivas en `SettingsInfo.xcstrings` y en las preguntas frecuentes del paywall para reflejar fielmente los 3 días de acceso completo.
   - En `SubscriptionExperienceTests.swift`:
     - Se actualizaron los tests unitarios para verificar el ciclo de 3 días naturales y la resolución de paywall obligatorio al vencer el día 3.

4. **Validación y Despliegue en Hardware**:
   - Suite `ShieldTests` en simulador: 100% superada sin fallos.
   - Compilación exitosa en `Debug-iphoneos`.
   - Instalación y lanzamiento exitoso en el iPhone 15 Pro Max (`00008130-0011199026A0001C`).
