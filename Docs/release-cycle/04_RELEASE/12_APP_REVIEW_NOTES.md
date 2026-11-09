# Notas privadas para App Review — borrador 1.1.7

Este archivo es texto local para revisión; no se ha escrito en ASC. Confirmar campos de contacto y notas de la nueva versión cuando se cree 1.1.7 en App Store Connect.

## English — reviewer note

MaskID helps users prepare a copy of a personal document before sharing it. The core workflow does not require a MaskID account. From Home, choose “Protect a document”, scan or import a PDF/image, review the pages, adjust each redaction, export, then inspect the generated copy. Redaction and text recognition run on-device. Please inspect every page and the recipient; the check is an aid and cannot confirm that every sensitive area was selected.

The app offers an internal 15-calendar-day full-access period to new users. It is not an App Store introductory trial and does not start a transaction or automatic renewal. Users classified as Free before this change receive 30 full-access days followed by 30 days of read-only recovery. Expiration does not delete saved documents; users retain ways to restore purchases and view, export, or delete their data. The screen shows the Apple localized price and renewal terms before purchase.

Products are a monthly subscription, an annual subscription, and an optional non-consumable lifetime purchase. Restore purchases from the in-app purchase/restore control. Apple Sandbox test products must be used for transaction validation. There is no login or demo account.

Optional iCloud sync requires an Apple account and is separate from the local Vault. The Vault remains on-device and uses device authentication. Optional Google Drive/Dropbox import requires the user's own provider sign-in.

The production app has no review-only date-advance control for days 15/30/60. Access boundary dates are covered with deterministic local policy tests; changing the review device clock is not a supported test method. If a screen-specific expiry test is required, contact the developer before review rather than treating a different real date as proof.

## Español — nota para el equipo revisor

MaskID prepara una copia de un documento antes de compartirla. El flujo principal no requiere cuenta MaskID: en Inicio, elige “Proteger un documento”, escanea o importa un PDF/imagen, revisa todas las páginas, ajusta cada máscara, exporta y comprueba la copia. El reconocimiento y la redacción se procesan en el dispositivo. La verificación ayuda, pero no confirma que el usuario haya seleccionado todos los datos; revisa cada página y el destinatario.

Los usuarios nuevos pueden activar 15 días naturales de acceso completo interno. No es una prueba introductoria de App Store ni crea una compra o renovación automática. Los usuarios Free anteriores al cambio reciben 30 días completos y después 30 días de recuperación en solo lectura. La caducidad no borra documentos y quedan rutas para restaurar compras, consultar, exportar o eliminar los datos propios. La pantalla de compra muestra el precio localizado y la renovación antes de confirmar.

Hay suscripción mensual, anual y compra vitalicia opcional no consumible. Restaura desde el control de compra/restauración de la app. Para probar transacciones se necesita Sandbox de Apple; no hay cuenta de MaskID ni credenciales demo.

La sincronización iCloud es opcional y requiere cuenta Apple; es independiente de la Bóveda local. La Bóveda permanece en el dispositivo y usa autenticación del sistema. Drive/Dropbox requieren inicio de sesión del propio usuario.

La versión de producción no tiene control de Review para avanzar días 15/30/60. Las fronteras de acceso están cubiertas con pruebas deterministas locales; cambiar el reloj no es un procedimiento compatible. Si hace falta verificar una expiración concreta en pantalla, contactar con el desarrollador antes de revisar.

## Datos a confirmar antes de enviar

- ASC no tiene todavía versión 1.1.7 ni build cargado. Esta nota no acredita que la haya leído Apple.
- Verificar contact name/email/phone y cualquier campo de cuenta demo desde la ficha de Review; no copiar datos personales de la versión 1.1.6.
- Seleccionar solo un grupo Sandbox interno si el propietario autoriza cargar la build. No invitar testers reales desde esta fase.
- Para review después del 16-11-2026, completar el cuestionario de edad vigente.
