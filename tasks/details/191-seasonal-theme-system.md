# 191-seasonal-theme-system

- Number: 191
- Slug: seasonal-theme-system

## Notes

Plan integral documentado en [Docs/SEASONAL_THEME_SYSTEM_PLAN.md](../../Docs/SEASONAL_THEME_SYSTEM_PLAN.md). La política recomendada para Halloween es calendario local del dispositivo, con límites guardados como componentes de fecha y reevaluación al cambiar de zona horaria, volver a foreground o cambiar el entitlement.

## Producto

- Un tema es un paquete visual completo: identidad/icono, colores, tipografía, superficies, textura, motion y microinteracciones.
- Precedencia propuesta: selección manual Pro > tema estacional automático activo > tema base MaskID.
- Free no muestra selector manual: recibe el tema que corresponda al calendario y vuelve al tema base al terminar el evento.
- Pro puede elegir cualquier tema disponible en la galería, incluido uno cuyo evento ya terminó, o volver a `Automático`/tema base.
- Los temas permanecen instalados en la galería después de su ventana temporal; el calendario sólo gobierna el modo automático.

## Primera entrega: Halloween

- Reutilizar `MaskIDHalloween` como icono del tema, sin confundir el icono de aplicación con el sistema visual completo.
- Añadir tokens de Halloween para paleta, superficies, tipografía/fallback, textura y motion respetando Dynamic Type, contraste y Reduce Motion.
- Añadir una galería dentro de Ajustes con estado bloqueado/Pro, vista previa, activar/desactivar y estado automático.
- Persistir la preferencia de tema y resolver las fechas con una fuente de tiempo inyectable para poder probar límites de inicio/fin sin depender del reloj real.
- Cubrir con tests la precedencia Free/Pro, el cambio exacto de fecha, el fallback y el comportamiento con Reduce Motion.

## App Store Connect

- Preparar el evento como In-App Event independiente del calendario interno de la app.
- Propuesta inicial: badge `Special Event`, porque Halloween es una experiencia temporal de personalización y no una competición o desafío.
- Mantener fecha de publicación, inicio y fin alineadas con la configuración interna; Apple exige aprobación previa, permite publicar como máximo 14 días antes del inicio y limita el evento a 31 días.
- Preparar metadata ES/EN, imagen de tarjeta 16:9 y detalle vertical 9:16. La creación/envío remoto queda separado de la implementación local y requiere sesión/rol autorizado en App Store Connect.

## Ejecución realizada

- Implementado el catálogo, resolver, persistencia, galería Free/Pro, ambient layer, icono estacional y deep link `maskid://theme/halloween-2026`.
- Añadida política de calendario local por dispositivo, soporte de zona fija/UTC para casos administrativos y reevaluación al cambiar zona horaria, volver a foreground o cambiar entitlement.
- Añadidos tests de zona local, precedencia Pro y transición DST; `EnhancementFeaturesTests` pasó.
- Build Debug de iOS Simulator pasó con `scripts/xcbuild.sh`; se usó una copia limpia del caché SPM para evitar un sidecar AppleDouble ajeno.
- Preparados y verificados los assets `event-card-16x9.png` (1920×1080) y `event-details-9x16.png` (1080×1920).
- Creado y guardado en App Store Connect el evento remoto `6816385632` con EN/ES, badge Special Event, propósito de usuarios activos y zona `Europe/Madrid`: publicación el 30/09/2026 00:00, inicio el 01/10/2026 00:00 y fin el 31/10/2026 23:00. Se dejó sin enviar a revisión.

## Validación de dispositivos

- iPhone 18 Pro, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`, runtime iOS 27.0: build instalada y proceso lanzado; `EnhancementFeaturesTests` pasó en ese destino.
- La inspección visual del proceso mostró una superficie negra con la etiqueta de la app, sin crash observable; queda anotada como limitación de la sesión visual, no como evidencia positiva de layout.
- En la revalidación posterior CoreSimulatorService dejó de responder. No se reinició, borró ni apropió el simulador; la comprobación quedó en cola conforme a las instrucciones de la sesión.
- No existe iPhone Duo disponible. Hay iPadOS 27.0 y watchOS 27.0 instalados, pero el esquema no tiene target watchOS y los iPad estaban en otra sesión; no se interrumpieron.
