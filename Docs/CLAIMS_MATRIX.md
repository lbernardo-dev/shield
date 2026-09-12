# MaskID — matriz de claims verificables

**Propósito:** una frase entra en código, metadata, web, preview, screenshot o soporte únicamente si tiene una evidencia técnica y una superficie de revisión asignada.

**Estado de esta revisión:** 11 de septiembre de 2026.  
**Producto:** MaskID 1.0.9 · build `1092026091101` (staged en App Store Connect; no enviado a revisión).

| Claim aprobado | Evidencia técnica | Superficies permitidas | Límites obligatorios |
|---|---|---|---|
| El OCR y las sugerencias se ejecutan en el dispositivo | `Shield/OCR/`, Vision y flujo de captura | App, metadata, screenshots, web | Presentar sugerencias como revisables; no prometer detección completa. |
| El procesamiento principal puede funcionar sin conexión | Captura/importación local, OCR y exportación | App, metadata, screenshots, web | No equivale a “toda la app nunca se conecta”. |
| La sincronización Pro de iCloud es opcional | `Shield/Cloud/CloudSyncManager.swift` y política | App, metadata, soporte | Afecta documentos fuera de la Bóveda; describe que son paquetes restaurables completos. |
| Los documentos de la Bóveda permanecen locales | Flujo de Vault y política | App, metadata, soporte | No extender esta afirmación a Biblioteca, Archivos, Google Drive o Dropbox. |
| La Bóveda usa AES-GCM local y acceso por Face ID/PIN | `Shield/Security/`, Keychain y LocalAuthentication | App, metadata, screenshots, web | No usar “Secure Enclave” ni “hardware encryption” sin una implementación y migración aprobadas. |
| La exportación aplana las máscaras y elimina metadatos habituales | `Shield/Views/Editor/ExportServices.swift` | App, metadata, screenshots, web | Especificar “metadatos habituales”; no afirmar eliminación universal. |
| La copia exportada se comprueba contra un conjunto de verificaciones | `Shield/Export/ExportVerifier.swift`, `SecureExportModels.swift` | App, metadata, screenshots | PDF e imagen pasan comprobaciones de bytes, metadatos y OCR residual; no usar “certificada”; mantener revisión humana y del destinatario. |
| El Share Sheet entrega el archivo al flujo local de MaskID mediante un handoff cifrado | `ShareExtension/ShareViewController.swift`, `Shield/Share/SharedImportStore.swift`, `Shield/App/ShieldApp.swift` | App, metadata, soporte | El límite actual es un elemento por activación; el fallback de datos no implica compatibilidad batch ni elimina los controles del sistema. |
| MaskID explica cómo protege los archivos | `SettingsArticleView`, `SettingsInfo.xcstrings`, `ExportProtectionCheckView` | Describir detección en dispositivo, revisión humana, exportación rasterizada y checks de salida; no prometer detección completa ni riesgo cero. |
| No hay tracking entre apps y no se envía contenido documental a telemetría | `Shield/PrivacyInfo.xcprivacy`, Firebase, política | App Privacy, metadata, web, soporte | Declarar Analytics, Crashlytics y RevenueCat según su uso real. |
| Firebase Analytics es opcional y está desactivada por defecto | `FirebaseIntegration`, consentimiento persistido, `Info.plist` | App, política, soporte, QA | Sólo se activa después de una autorización expresa; Crashlytics se mantiene como diagnóstico separado. |

## Claims retirados

No reutilizar estas frases ni sus equivalentes traducidos:

- “Hardware encryption”, “Secure Enclave” o “cifrado de hardware”.
- “Zero cloud servers”, “100% offline” como promesa de producto completo o “sin nube”.
- “Certified privacy”, “privacidad certificada” o certificaciones no demostradas.
- “Masked data cannot be recovered” como garantía absoluta.
- “Sin recopilación de datos” mientras exista la telemetría declarada.

## Procedimiento de aprobación

1. Producto redacta la frase y el caso de uso.
2. Ingeniería/Seguridad enlaza la prueba y sus límites.
3. Privacy comprueba política, manifest y App Privacy.
4. ASO/localización revisa longitud, intención y traducción nativa.
5. Design comprueba que la UI visible respalda la frase.
6. Release verifica binario, metadata y storefront después de propagación.

Una creative sin fixture reproducible, locale y hash no se considera lista para publicación.

## Evidencia de salida (desde 1.0.10)

La ruta de exportación de imagen escribe un artefacto temporal con protección de
archivo y devuelve el mismo ExportVerificationReport que PDF. El informe
comprueba que la imagen abre, que no conserva grupos EXIF/GPS/TIFF/IPTC/cámara,
y que las zonas ocultas no contienen texto OCR detectable en una segunda pasada.
Esto demuestra una diferencia técnica frente a dibujar un rectángulo en la
interfaz; no constituye una garantía universal ni sustituye la revisión final.

## Fixture adversarial de Secure Export (desde 1.0.10)

`ShieldTests/Export/ExportVerifierTests.swift` mantiene una regresión local para
PDF rasterizado multipágina (incluidos página rotada, orientación mixta, baja
calidad, varios idiomas y 50 páginas), PDF con text layer/anotaciones/metadatos,
PNG transparente y JPEG con GPS/EXIF/TIFF. La suite también comprueba a nivel de
bytes que el texto ficticio marcado para ocultar no aparece en el PDF ni en el
JPEG producidos por Secure Export, y que el PDF resultante no conserva texto
seleccionable ni anotaciones.

La evidencia cubre estos formatos y fixtures, no todas las codificaciones,
contenedores o técnicas forenses posibles. Por eso el producto debe conservar
la revisión humana, mostrar los elementos sensibles restantes y describir la
limpieza de metadatos como limitada a los grupos auditados, nunca como una
garantía universal de irrecuperabilidad.
