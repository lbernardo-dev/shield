# MaskID — Plan integral del sistema de temas estacionales

Estado: plan de implementación para la tarea `191-seasonal-theme-system`.

## 1. Decisión de producto

MaskID tendrá un catálogo de temas visuales. Un tema no será sólo una paleta: incluirá identidad, icono, colores, tipografía, superficies, textura, movimiento, microinteracciones y reglas de disponibilidad.

La primera versión será local y determinista:

- Los recursos visuales viajarán dentro de la aplicación.
- El calendario inicial viajará dentro de la aplicación, sin exigir cuenta ni conexión.
- La hora de activación se resolverá en el dispositivo del usuario.
- Una futura configuración remota podrá corregir fechas o publicar nuevos calendarios, pero nunca será necesaria para que el tema base funcione.
- El tema sólo afecta a la interfaz de MaskID. No altera documentos, imágenes exportadas, OCR, redacciones ni contenido de la Bóveda.

### Comportamiento por plan

| Usuario | Modo disponible | Resultado |
|---|---|---|
| Free | Automático | Usa el tema estacional vigente en su zona horaria; vuelve al tema base cuando termina. |
| Free | Vista previa | Puede previsualizar temas y ver la propuesta Pro, pero no fijarlos manualmente. |
| Pro | Automático | Igual que Free, pero conserva acceso a toda la galería. |
| Pro | Manual | Puede activar un tema disponible aunque su evento haya terminado o volver al tema base. |
| Pro | Desactivado | Puede mantener el tema base aunque exista un evento activo. |

La selección manual Pro tiene prioridad sobre el calendario. Al perder Pro se conserva la preferencia guardada, pero el resolvedor aplica las reglas Free hasta que el usuario recupere el acceso.

## 2. Modelo de dominio

Se introducirá un módulo independiente, idealmente bajo `Shield/Theme/`, con estas piezas:

```swift
enum ThemeID: String, Codable, CaseIterable {
    case base
    case halloween2026 = "halloween-2026"
}

enum ThemeSelectionMode: Codable, Equatable {
    case automatic
    case manual(ThemeID)
    case base
}

enum ThemeSchedulePolicy: Codable, Equatable {
    case deviceLocalCalendar
    case fixedTimeZone(String)
    case absoluteUTC
}

struct ThemeSchedule: Codable, Equatable {
    let calendarIdentifier: Calendar.Identifier
    let start: DateComponents
    let end: DateComponents
    let policy: ThemeSchedulePolicy
}

struct ThemeDefinition: Identifiable, Codable {
    let id: ThemeID
    let version: Int
    let titleKey: String
    let subtitleKey: String
    let icon: AppIconOption?
    let schedule: ThemeSchedule?
    let requiresProForManualActivation: Bool
    let priority: Int
}
```

Los nombres son orientativos; la implementación debe mantener tipos pequeños, `Codable`, estables y fáciles de probar.

### Servicios

- `ThemeCatalog`: catálogo de definiciones incluidas en la build y, más adelante, definiciones remotas validadas.
- `ThemeClock`: abstracción de `now`, zona horaria y calendario. En producción usará el reloj del sistema; en tests será inyectable.
- `ThemeScheduleResolver`: transforma una definición y un instante en `upcoming`, `active` o `ended`.
- `ThemeSelectionStore`: persiste el modo elegido y la versión del catálogo.
- `ThemeResolver`: combina plan Premium, selección guardada y calendario para producir el tema efectivo.
- `ThemeCoordinator`: objeto observable de aplicación que publica el tema efectivo y reevalúa al volver a foreground o cambiar la zona horaria.
- `ThemeAssetValidator`: validación de recursos obligatorios, fuentes, iconos y compatibilidad antes de incluir un tema.

La UI leerá un `ThemeContext` desde el entorno SwiftUI. `ShieldTheme` se conservará inicialmente como compatibilidad para no hacer un cambio masivo de una vez, pero los componentes nuevos y las superficies migradas deberán leer tokens dinámicos del tema efectivo.

## 3. Política horaria y zonas del mundo

### Decisión para Halloween

Halloween será un evento de calendario local: cada usuario verá el tema entre las fechas y horas configuradas en la zona horaria actual de su dispositivo.

Ventana recomendada para la primera edición:

- Inicio: 1 de octubre de 2026 a las 00:00 hora local.
- Fin: 1 de noviembre de 2026 a las 00:00 hora local.
- Duración: 31 días exactos de calendario, dentro del límite de App Store Connect.
- Calendario: gregoriano.

Esta política es la más natural para un evento cultural como Halloween: el usuario de Madrid, Nueva York o Tokio entra en el evento al comenzar su propio día local. El tema no depende de una cuenta ni expone la ubicación.

### Qué se guarda y qué no

No se guardará una fecha absoluta calculada con la zona actual, porque quedaría incorrecta cuando el usuario viaje o cambie la configuración del dispositivo. Se guardarán:

- componentes de fecha y hora (`DateComponents`);
- identificador del calendario;
- política temporal (`deviceLocalCalendar`, `fixedTimeZone` o `absoluteUTC`);
- versión del calendario;
- identificador estable del tema.

Para Halloween, el resolvedor utilizará `TimeZone.autoupdatingCurrent` y reconstruirá los límites cada vez que evalúe el evento.

### Cambios de zona horaria

El coordinador debe reevaluar el tema cuando ocurra cualquiera de estos hechos:

- la app se inicia;
- la app vuelve a `active` desde background;
- se recibe `NSSystemTimeZoneDidChange`;
- cambia el calendario relevante;
- cambia el estado de Premium;
- se actualiza la configuración remota, en el futuro.

Los temporizadores sólo servirán para refrescar una cuenta atrás visual. La verdad del sistema será siempre una evaluación nueva de `ThemeClock`; no se confiará en un `Timer` que haya permanecido suspendido en background.

### Horario de verano y horas ambiguas

El resolvedor deberá usar `Calendar` con la zona efectiva, no sumar segundos a una fecha anterior.

- Si una hora no existe por el salto de horario, se moverá a la siguiente hora válida y se registrará una advertencia de configuración.
- Si una hora aparece dos veces por el retroceso horario, se elegirá de forma determinista la primera ocurrencia.
- Los límites de Halloween estarán a las 00:00 para evitar ambigüedades habituales.
- El catálogo rechazará ventanas con fin anterior o igual al inicio.
- Las ventanas con eventos solapados deberán tener prioridad explícita; si empatan, gana el tema de versión más reciente. Idealmente el validador marcará el solapamiento como error editorial.

### Políticas futuras

El modelo soportará otros casos sin cambiar la UI:

- `deviceLocalCalendar`: celebraciones locales, recomendado para Halloween.
- `fixedTimeZone("Europe/Madrid")`: lanzamiento editorial anclado a una región concreta.
- `absoluteUTC`: lanzamiento simultáneo global.

La elección debe ser parte de cada tema, no una preferencia oculta del usuario.

### Casos de reloj incorrecto

La personalización no es una función de seguridad. Si el reloj del dispositivo no es fiable o la fecha no se puede interpretar, la app debe fallar de forma segura en el tema base y seguir funcionando sin bloquear captura, OCR, edición, exportación o Bóveda.

## 4. Arquitectura visual

### Tokens dinámicos

Cada definición proporcionará, como mínimo:

- `ThemePalette`: fondos, tarjetas, líneas, texto primario/secundario, acento, estados y selección;
- `ThemeTypography`: familia display opcional, pesos y estilos; el cuerpo seguirá siendo legible y Dynamic Type-aware;
- `ThemeTexture`: textura o patrón de bajo coste, con alternativa sólida para reducir transparencia;
- `ThemeMotion`: duración, curva, stagger, intensidad y si admite partículas;
- `ThemeIcon`: icono de la aplicación y reglas para aplicar/restaurar el icono;
- `ThemeSoundPolicy`: inicialmente desactivada; no se añadirán sonidos sin una decisión separada de producto y accesibilidad.

### Integración con SwiftUI

1. Crear el contexto de tema en la raíz de la app.
2. Inyectar el tema efectivo con un `EnvironmentKey` estable.
3. Migrar primero componentes compartidos: tarjetas, botones, navegación, tab bar, cabeceras y ajustes.
4. Migrar después Home, Gallery, Vault, Capture y Editor.
5. Mantener el render de documentos y las exportaciones con tokens neutros para que un tema nunca contamine el archivo de salida.
6. Mantener los límites de invalidación: el cambio de tema debe redibujar la superficie visual, no provocar trabajo innecesario en OCR, documentos o almacenamiento.

No se adoptará Liquid Glass como parte de este plan salvo que se solicite explícitamente; el tema debe funcionar en las superficies actuales y tener fallback sólido.

### Accesibilidad y movimiento

- Dynamic Type se mantiene en todos los textos.
- VoiceOver describirá el tema activo y el estado automático/manual.
- `accessibilityReduceMotion` desactiva partículas, parallax y transiciones intensas.
- `accessibilityReduceTransparency` usa superficies opacas.
- Contraste aumentado usa bordes y texto reforzados.
- No habrá flashes, estrobos ni animaciones que dificulten la lectura.
- Toda acción tendrá un `Button` con área mínima de 44 pt.
- Las microinteracciones serán decorativas y no la única forma de comunicar un estado.

## 5. Primera implementación: Halloween

Identificador inicial: `halloween-2026`.

### Lenguaje visual

- Fondo: carbón/azul nocturno para conservar la identidad de privacidad de MaskID.
- Acento: naranja calabaza.
- Secundarios: violeta oscuro y verde ácido con uso moderado.
- Textura: grano, niebla o patrón de telaraña muy sutil, nunca sobre documentos.
- Display: fuente con carácter estacional, incluida sólo si tiene licencia compatible; fallback a `.rounded` o `.serif` del sistema.
- Cuerpo: tipografía del sistema para legibilidad y accesibilidad.
- Icono: reutilizar `MaskIDHalloween` ya presente en los recursos.

### Superficies y animación

- Cabecera de Home y Ajustes con halo naranja/violeta.
- Partículas o motas de baja densidad en superficies de navegación, con semilla determinista para evitar cambios visuales constantes.
- Entrada de tarjetas con una aparición suave y un desplazamiento mínimo.
- Estado de activación con una microinteracción de brillo corto y feedback háptico si la preferencia háptica está habilitada.
- Editor y Capture recibirán como máximo un tratamiento muy contenido para no distraer del documento ni de la revisión de redacciones.
- La Bóveda mantendrá prioridad visual de seguridad y no se decorará con elementos que puedan reducir claridad.

### Política del icono

El icono estacional forma parte del tema, pero debe convivir con el selector de iconos Pro existente:

- Free: mientras Halloween automático esté activo, se intenta usar `MaskIDHalloween`; al terminar se restaura el icono base.
- Pro en automático: igual que Free, salvo que haya elegido explícitamente conservar un icono manual.
- Pro en manual: activar Halloween selecciona el icono del tema por defecto; el usuario puede mantener su icono manual con una opción explícita.
- Si el sistema no permite cambiar el icono, el resto del tema sigue activo y no se muestra un error bloqueante.
- Al cambiar de tema se debe evitar una cascada de cambios repetidos de icono.

## 6. Galería y configuración

Se añadirá una ruta de Ajustes dentro de Personalización: `settings.route.themes`.

### Free

- Muestra el tema activo y una etiqueta “Automático”.
- Muestra una vista previa de Halloween cuando está disponible.
- Permite ver la galería en modo lectura.
- Al intentar fijar un tema, presenta el paywall con `PaywallTrigger.styleLocked` o un trigger específico de temas.

### Pro

- Selector `Automático`, `Tema base` y temas manuales.
- Filtros o estados: activo, próximo, disponible, archivado.
- Vista previa antes de aplicar.
- Activar/desactivar con persistencia inmediata.
- Información de fechas y zona horaria sólo como texto comprensible, por ejemplo “Automático según la hora local de este dispositivo”.
- No mostrar un identificador técnico de zona horaria como `Europe/Madrid` salvo en una pantalla de diagnóstico.

La galería debe usar identidad estable para `ForEach`, filas unitarias y componentes pequeños para que el cambio de tema no invalide toda la pantalla.

### Deep link

El evento de App Store Connect apuntará a un deep link del tipo `maskid://theme/halloween-2026`. La app deberá:

- abrir la pantalla de detalle del tema si ya está instalada;
- mostrar el tema activo y su estado Free/Pro;
- caer en Home si el tema no existe en la build;
- no activar automáticamente un tema manual Pro sólo por abrir el enlace.

## 7. Persistencia, migración y degradación

Claves propuestas:

- `shield.theme.selectionMode`
- `shield.theme.selectedID`
- `shield.theme.catalogVersion`
- `shield.theme.manualIconOverride`

La persistencia debe ser local en la primera entrega. No se enviará a CloudKit hasta decidir si la preferencia de tema debe sincronizarse entre dispositivos; si se añade después, la zona horaria siempre se resolverá localmente en cada dispositivo.

Si el tema guardado no existe, está corrupto o requiere una versión no disponible:

1. se intenta el tema automático si el usuario es Pro;
2. se intenta el tema estacional vigente si el usuario es Free;
3. se usa el tema base;
4. se corrige la preferencia persistida para no repetir el fallo.

## 8. Configuración remota futura

No se incluirá un backend como dependencia de Halloween. Para futuras ediciones se podrá añadir un manifiesto remoto firmado que contenga sólo:

- versión del catálogo;
- identificadores de temas ya incluidos en la app;
- ventanas de calendario;
- prioridades;
- fecha de expiración del manifiesto.

Los assets nuevos seguirán requiriendo una build o un canal de distribución seguro explícito. Si falla la red, se usa el manifiesto local incluido en la app. No se enviarán imágenes, OCR, documentos, ubicación ni identificadores personales.

## 9. App Store Connect: In-App Event

El In-App Event es una superficie de adquisición y descubrimiento separada de la lógica interna del tema. Debe configurarse y aprobarse en App Store Connect, pero la app debe seguir funcionando aunque el evento no esté publicado.

### Propuesta inicial

- Nombre interno: `MaskID Halloween 2026 Theme Event`.
- Badge: `Special Event`.
- Propósito: mantener informados a usuarios activos y atraer usuarios nuevos.
- Compra requerida: ninguna; el evento visual no debe presentarse como una compra obligatoria.
- Disponibilidad: todos los storefronts donde esté disponible MaskID, salvo decisión comercial distinta.
- Deep link: `maskid://theme/halloween-2026`.

### Metadata preliminar

La metadata final debe mantenerse dentro de los límites oficiales: nombre hasta 30 caracteres, descripción corta hasta 50 y larga hasta 120. Apple recomienda describir el evento real, evitar claims no verificables, precios y exceso de texto en las imágenes.

**English (U.S.)**

- Event name: `Halloween in MaskID`
- Short description: `A spooky seasonal privacy theme`
- Long description: `Give MaskID a seasonal look with a spooky icon, colors, textures, and gentle motion.`

**Español (España)**

- Nombre: `Halloween en MaskID`
- Descripción corta: `Un tema de privacidad espeluznante`
- Descripción larga: `Dale a MaskID un aspecto de temporada con icono, colores, texturas y movimiento sutiles.`

Estas cadenas son un borrador y deben pasar revisión de tono, localización y App Review antes de cargarse.

### Calendario recomendado

- Publicación: entre 1 y 14 días antes del inicio, según el tiempo real de revisión.
- Inicio: 1 de octubre de 2026 a las 00:00 en cada zona objetivo.
- Fin: 1 de noviembre de 2026 a las 00:00 en cada zona objetivo.
- Las fechas internas de la app y las fechas del evento deben probarse contra el mismo contrato editorial.

App Store Connect permite personalizar las horas por país o región usando zonas horarias; si se escalonan los inicios, deben respetar las restricciones de Apple. La configuración debe conservarse como evidencia en el repositorio, pero no se ejecutará un cambio remoto automáticamente desde una build.

### Recursos requeridos

- Imagen de tarjeta: PNG/JPEG 16:9, recomendado `1920×1080`.
- Imagen de detalle: PNG/JPEG 9:16, recomendado `1080×1920`.
- Opcionalmente vídeo corto en formatos y especificaciones de Apple.
- Recursos sin texto excesivo ni logos incrustados; el nombre y el badge ya aparecen en la tarjeta.
- La imagen debe representar el tema realmente disponible en la build enviada.

Referencias oficiales:

- [Offer In-App Events](https://developer.apple.com/help/app-store-connect/offer-in-app-events/offer-in-app-events)
- [Manage events](https://developer.apple.com/help/app-store-connect/offer-in-app-events/manage-events)
- [In-App Event badges](https://developer.apple.com/help/app-store-connect/reference/in-app-events/in-app-event-badges)
- [Media and audio specifications](https://developer.apple.com/help/app-store-connect/reference/in-app-events/in-app-event-media-and-audio-specifications)
- [Creating effective metadata](https://developer.apple.com/app-store/in-app-events/)

## 10. Analítica y privacidad

Sólo se registrarán eventos de producto sin contenido sensible:

- `theme_gallery_opened`
- `theme_previewed`
- `theme_activation_started`
- `theme_activation_completed`
- `theme_activation_failed`
- `theme_automatic_applied`
- `theme_automatic_ended`

Propiedades permitidas: identificador del tema, modo (`automatic`, `manual`, `base`) y resultado. No se enviarán zona horaria, ubicación, fecha de nacimiento, documentos, nombres, OCR ni contenido de la Bóveda. Si el consentimiento de analítica está desactivado, el estado puede observarse sólo en logs locales de Debug.

## 11. Plan de implementación por fases

### Fase 0 — Contrato y catálogo

- Confirmar fechas editoriales y política `deviceLocalCalendar`.
- Definir `ThemeID`, `ThemeDefinition`, selección y estados.
- Añadir `ThemeClock` inyectable y validación del calendario.
- Crear fixtures de Halloween y del tema base.

**Salida:** modelo compilable y tests de calendario sin UI.

### Fase 1 — Motor de resolución

- Implementar catálogo, store, resolver y coordinador.
- Integrar estado Premium y downgrade seguro.
- Reevaluar en foreground, cambio de zona horaria y cambio de entitlement.
- Añadir migración de preferencias y fallback base.

**Salida:** `effectiveTheme` correcto en todos los modos y zonas probadas.

### Fase 2 — Tokens dinámicos

- Crear contexto de tema y tokens visuales.
- Migrar componentes compartidos y Settings.
- Asegurar que Editor/Capture no cambian los documentos exportados.
- Añadir Reduce Motion, contraste, transparencia y Dynamic Type.

**Salida:** el cambio entre tema base y Halloween es visible y accesible.

### Fase 3 — Arte y Halloween

- Completar icono, paleta, textura, fuente licenciada o fallback, animaciones y microinteracciones.
- Aplicar el lenguaje visual también a ambientación global, splash, onboarding, bloqueo, cargas, transiciones y estados vacíos; no limitarlo a una tarjeta de galería.
- Incorporar un selector DEBUG exclusivo del simulador para forzar cualquier tema del catálogo y revisar la experiencia sin esperar al calendario.
- Añadir vista previa de alta fidelidad.
- Integrar cambio de icono con el selector Pro actual.
- Crear recursos de marketing para tarjeta y detalle del evento.

**Salida:** tema Halloween completo y coherente en la app.

### Fase 4 — Galería y navegación

- Añadir ruta de Ajustes y galería.
- Resolver estados Free/Pro, paywall, activación y desactivación.
- Añadir deep link del evento.
- Añadir localización ES/EN y accesibilidad.

**Salida:** flujo de usuario completo desde Ajustes y desde App Store.

### Fase 5 — App Store Connect

- Crear el In-App Event en borrador.
- Cargar metadata ES/EN, media y deep link.
- Configurar disponibilidad y calendario por storefront.
- Validar que el evento describe exactamente lo que existe en la build.
- Añadir a revisión sólo con autorización explícita y después de la validación local.

**Salida:** evento listo para revisión, sin envío accidental.

### Fase 6 — Quality gate y lanzamiento

- Tests unitarios de calendario y precedencia.
- XCUITest de galería, paywall, activación, downgrade y deep link.
- Pruebas visuales base/Halloween en oscuro y claro.
- Validación de contraste, Dynamic Type, VoiceOver y Reduce Motion.
- Build Archive y release gate del repositorio.
- Validación en los simuladores exigidos por `AGENTS.md`.

**Salida:** build preparada y evidencia de App Store Connect, sin limpiar caches ni temporales hasta pedir confirmación al usuario.

## 12. Matriz de pruebas horarias

El suite debe usar un reloj falso y comprobar como mínimo:

| Caso | Zona | Instante | Resultado esperado |
|---|---|---|---|
| Antes del inicio | `Europe/Madrid` | 30/09 23:59 | Base |
| Inicio exacto | `Europe/Madrid` | 01/10 00:00 | Halloween |
| Durante el evento | `America/New_York` | 15/10 12:00 | Halloween |
| Fin exacto | `Asia/Tokyo` | 01/11 00:00 | Base |
| Cambio de zona | Madrid → Nueva York | Durante el evento | Reevaluación con fecha local nueva |
| DST primavera | `America/New_York` | Ventana con hora inexistente | Siguiente hora válida |
| DST otoño | `Europe/Madrid` | Ventana con hora repetida | Primera ocurrencia determinista |
| Sin red | Cualquier zona | Manifiesto remoto ausente | Catálogo local |
| Tema corrupto | Cualquier zona | Recurso faltante | Base sin bloquear la app |
| Downgrade Pro | Cualquier zona | Tema manual activo | Automático/Free |
| Upgrade Pro | Cualquier zona | Preferencia manual guardada | Restauración sólo si el tema sigue disponible |

## 13. Validación en dispositivos

La matriz obligatoria del proyecto se aplicará cuando exista una build:

- iPhone 18 Pro: destino principal, explícito y obligatorio.
- iPhone Duo: también si está disponible, incluyendo sesiones compartidas si el runtime lo permite.
- iPad representativo: layout regular, orientación y multitarea.
- Apple Watch: sólo si se detecta un target watchOS en el proyecto; actualmente el inventario revisado no muestra un componente watchOS, por lo que no se debe inventar una validación.

En cada destino se comprobará que la build instalada corresponde al UDID correcto y que el cambio de zona horaria se puede simular sin alterar datos de otras sesiones.

## 14. Criterios de aceptación

- Free cambia automáticamente al tema correcto según la zona horaria local y vuelve al tema base al terminar.
- Un cambio de zona horaria no deja el tema congelado ni requiere reinstalación.
- Pro puede usar automático, tema base o Halloween fuera de sus fechas.
- Un downgrade no rompe la UI ni deja un tema manual no permitido.
- Halloween contiene icono, tokens, tipografía/fallback, textura, motion y microinteracciones visibles.
- Halloween se refleja en vistas principales, transiciones y cargas mediante una capa ambiental y componentes compartidos, manteniendo la decoración fuera de documentos exportados e imágenes procesadas.
- El simulador tiene un selector DEBUG para activar manualmente cualquier tema del catálogo y volver al comportamiento real.
- Reduce Motion, contraste aumentado, transparencia reducida, Dynamic Type y VoiceOver funcionan.
- Los documentos exportados y las imágenes procesadas no incorporan decoración del tema.
- La app funciona sin red y sin cuenta.
- El deep link abre la galería o una pantalla de detalle segura.
- La metadata del In-App Event coincide con la build y cumple límites de Apple.
- No se envía a revisión ningún evento ni build sin autorización explícita.
