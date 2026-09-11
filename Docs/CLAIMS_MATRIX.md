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
| La copia exportada se comprueba contra un conjunto de verificaciones | `Shield/Export/ExportVerifier.swift` | App, metadata, screenshots | No usar “certificada”; mantener revisión humana y del destinatario. |
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
