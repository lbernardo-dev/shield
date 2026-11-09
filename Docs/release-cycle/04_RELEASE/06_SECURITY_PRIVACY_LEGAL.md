# Seguridad, privacidad y revisión jurídica

## Componentes y datos

- Plataforma: app iOS/iPadOS, bundle com.romerodev.shield, deployment target iOS 18.0. Targets reales: Shield, Share Extension y Widget. No hay app Watch, macOS/tvOS ni Live Activities.
- SDKs bloqueados por Swift Package Manager: RevenueCat 5.102.3, Firebase 12.16.0, Lottie 4.6.1 y paquetes auxiliares en Package.resolved. Build local con Xcode/iOS SDK 27.2.
- OCR, máscaras, preparación y exportación se ejecutan en el dispositivo. Los documentos y cachés se cifran con claves locales; la Bóveda añade Face ID/PIN y permanece local.
- CloudKit es opcional para Pro y sincroniza paquetes restaurables en la base privada del Apple ID, salvo Vault. La disponibilidad depende de permisos/red/iCloud.
- Firebase Analytics está desactivado por defecto y solo se habilita en Ajustes > Privacidad. Crashlytics es una vía de diagnóstico separada. RevenueCat usa el historial de compra/ID anónimo para validar entitlement. Drive/Dropbox son integraciones OAuth opcionales y el token queda en Keychain. Datos, OCR, nombres, rutas, imágenes, comentarios libres y credenciales no se envían a analytics según Docs/PRIVACY_POLICY_PRODUCT_FACTS.md.
- El contador agregado de documentos puede sincronizarse en iCloud KVS; no contiene texto, nombre ni ID documental. La política publicada debe mantener esta distinción.

## Controles de seguridad observados

- La expiración no elimina documentos; recovery permite consulta/exportación/borrado propio y bloquea creación, importación, modificación y escritura Cloud.
- Entitlement activo prevalece sobre estado temporal. No se usa UserDefaults.isPro como autoridad de compra.
- La activación temporal guarda un registro mínimo en Keychain y no emite evento analítico.
- Exportación aplanada y comprobación local reducen contenido oculto/metadatos, pero no garantizan que el usuario haya seleccionado todos los datos. La ficha y App Review no deben prometer privacidad absoluta o redacción infalible.
- Búsqueda estática básica de patrones de secreto no encontró tokens privados ni llaves; sí identificó una clave de cliente pública RevenueCat con prefijo appl_ documentada como public SDK key. No se copiaron valores completos a este informe.
- No se modificaron permisos, entitlements, firma, OAuth, datos reales, productos o claves.

## Privacidad ASC

Estado de App Privacy en ASC: PENDIENTE. El comando/perfil disponible no proporcionó una declaración de privacidad que pueda conciliarse con los SDK y el consentimiento. No se infieren respuestas. El propietario debe abrir la app 6790398619 en App Store Connect → App Privacy, revisar categorías, finalidad, asociación a identidad y tracking para Firebase, Crashlytics, RevenueCat, CloudKit KVS/CloudKit, Analytics opt-in, soporte y OAuth; confirmar URLs y política; guardar solo después de revisión interna.

La URL de privacidad publicada es:

- EN: https://lbernardo-dev.github.io/apps/en/case-studies/shield/privacy/
- ES: https://lbernardo-dev.github.io/apps/es/casos/shield/privacidad/

Los textos de política/condiciones de suscripción de este repositorio dicen expresamente draft/pending legal review. Esta auditoría no otorga asesoramiento ni aprobación jurídica.

## Gates regulatorios/comerciales

1. Revisar términos de acceso 15d/30+30d, datos al expirar, precio/duración/renovación, lifetime, restore, desistimiento/reembolso y comunicación a instalaciones previas en España/UE.
2. Revalidar política de privacidad y App Privacy de ASC contra los SDK/consentimientos reales.
3. Al someter después del 16-11-2026, completar las nuevas descripciones de edad anunciadas por Apple. La ficha actual informa 4+; no asumir que el cuestionario anterior sigue bastando después de esa fecha.
4. Informar a Review que OCR/máscaras/export son controles asistivos y requieren revisar cada página y destinatario.

Referencias oficiales: [Apple App Privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy), [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [requisitos actuales de SDK/Xcode](https://developer.apple.com/news/upcoming-requirements/?id=04282026a) y [nuevas descripciones de edad](https://developer.apple.com/news/?id=yxkh08us).
