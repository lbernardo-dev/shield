# Privacidad, datos y condiciones — revisión pendiente

## Datos del contador temporal

`AccessStateStore` guarda en Keychain un registro JSON mínimo: esquema/cohorte, aceptación y versión del aviso, fecha de inicio/vencimiento, vencimiento recovery, último instante confiable y marcador de entitlement pagado observado. No incluye documentos, contenido OCR, identidad fiscal ni analítica. Usa `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`; no es una identidad o copia restaurable universal.

La activación no emite evento Firebase. La telemetría Firebase existente depende del consentimiento/control de la fase previa; el consentimiento contractual/informativo del aviso no es consentimiento analítico. La auditoría de Fase 02 aún requiere validación operativa manual de opt-out/VoiceOver.

## Preservación y eliminación

- Expirar el acceso no elimina documentos locales ni datos Vault.
- Durante recovery/expiración se pueden consultar/exportar y eliminar datos personales propios; el borrado local quita archivos locales y pone en cola el borrado remoto CloudKit cuando la sincronización estaba activa.
- Sync de contenido nuevo y ediciones es Premium; no se ejecuta una reconciliación que restaure o escriba documentos durante recovery.
- La disponibilidad de copias iCloud y la eliminación remota dependen de permisos/cuenta/red Apple; la prueba E2E con cuenta aislada está pendiente.
- La Bóveda conserva autenticación biométrica/PIN; las pantallas de recuperación no exponen su contenido sin desbloqueo.

## Borrador comercial

Las condiciones de [subscription-terms.html](../Docs/legal/subscription-terms.html) reflejan el catálogo y la política implementada, pero **no son asesoramiento ni aprobación jurídica**. Deben ser revisadas antes de comunicar o publicar el cambio. Confirmar condiciones Free históricas, promesas anteriores, derecho de desistimiento/reembolso, información de duración/precio, cese de función comercial y conservación de datos en España/UE. El plazo de 30+30 días es una decisión de producto, no certificación de cumplimiento.

`LEGAL_RELEASE_BLOCKER` permanece abierto hasta que el propietario o profesional competente apruebe los textos de transición y condiciones y se verifique el flujo de comunicación/versionado. No interpretar `noticeAcceptedAt` como autorización de analytics.

## Riesgos de identidad y reloj

No hay servidor. Keychain, UserDefaults y RevenueCat anonymous ID tienen límites de restauración/reinstalación. El retroceso local no mueve `lastTrustedAt` hacia atrás; adelantar la fecha puede terminar antes el acceso. No se presenta ninguna garantía absoluta anti-reset o de hora segura.

## Referencias para revisión humana

- [BOE, TRLGDCU — versión vigente](https://www.boe.es/buscar/act.php?id=BOE-A-2007-20555)
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Apple suscripciones](https://developer.apple.com/app-store/subscriptions/)
- [RevenueCat CustomerInfo](https://www.revenuecat.com/docs/customers/customer-info)
