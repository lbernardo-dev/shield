# Privacidad, datos y condiciones — revisión pendiente

## Datos del contador temporal

`AccessStateStore` guarda en Keychain un registro JSON mínimo: esquema/cohorte, aceptación y versión del aviso, fecha de inicio/vencimiento, último instante confiable y marcador de entitlement pagado observado. No incluye documentos, contenido OCR, identidad fiscal ni analítica. Usa `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; la misma clave estable conserva el contador en una reinstalación normal del mismo dispositivo, pero no es una identidad/copia restaurable universal.

La activación no emite evento Firebase. La telemetría Firebase existente depende del consentimiento/control de la fase previa; el consentimiento contractual/informativo del aviso no es consentimiento analítico. La auditoría de Fase 02 aún requiere validación operativa manual de opt-out/VoiceOver.

## Preservación y eliminación

- Expirar el acceso no elimina documentos locales ni datos Vault.
- Tras caducar se pueden consultar/exportar y eliminar datos personales propios desde la ruta de recuperación; el borrado local quita archivos locales y pone en cola el borrado remoto CloudKit cuando la sincronización estaba activa.
- Sync de contenido nuevo y ediciones es Premium; no se ejecuta una reconciliación que restaure o escriba documentos durante recovery.
- La disponibilidad de copias iCloud y la eliminación remota dependen de permisos/cuenta/red Apple; la prueba E2E con cuenta aislada está pendiente.
- La Bóveda conserva autenticación biométrica/PIN; las pantallas de recuperación no exponen su contenido sin desbloqueo.

## Borrador comercial

Las condiciones de [subscription-terms.html](../Docs/legal/subscription-terms.html) describen los 15 días comunes y la compra Lifetime; son un borrador y **no constituyen asesoramiento ni aprobación jurídica**. Deben revisarse antes de comunicar/publicar el cambio: condiciones Free históricas, transacciones de suscripción aún activas, derecho de desistimiento/reembolso, información de duración/precio y conservación de datos en España/UE.

`LEGAL_RELEASE_BLOCKER` permanece abierto hasta que el propietario o profesional competente apruebe los textos de transición y condiciones y se verifique el flujo de comunicación/versionado. No interpretar `noticeAcceptedAt` como autorización de analytics.

## Riesgos de identidad y reloj

No hay servidor. El Keychain está diseñado para conservar el contador tras borrar y reinstalar MaskID en el mismo dispositivo con el mismo equipo de firma y grupo de acceso; una eliminación del elemento, restauración, dispositivo nuevo o cambio de firma puede impedir la continuidad. El retroceso local no mueve `lastTrustedAt` hacia atrás; adelantar la fecha puede terminar antes el acceso. No se presenta ninguna garantía absoluta anti-reset o de hora segura.

## Referencias para revisión humana

- [BOE, TRLGDCU — versión vigente](https://www.boe.es/buscar/act.php?id=BOE-A-2007-20555)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple suscripciones](https://developer.apple.com/app-store/subscriptions/)
- [RevenueCat CustomerInfo](https://www.revenuecat.com/docs/customers/customer-info)
