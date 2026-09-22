# Análisis de uso Free vs Premium

## Dictamen

El comportamiento observado tiene dos explicaciones compatibles:

1. Si el usuario cancela el trial a las pocas horas, normalmente solo está desactivando la renovación automática. El entitlement Premium sigue activo hasta que termina el periodo de prueba. Por tanto, puede seguir utilizando la app como Premium sin que exista una anomalía.
2. Una vez expirado el trial, Free todavía resuelve de principio a fin el caso de uso ocasional: importar, enmascarar, exportar de forma verificada y guardar localmente. El límite real actual es de 10 documentos procesados acumulados, mientras que la exportación segura no está limitada.

Conclusión: Free no parece excesivamente permisivo para un usuario recurrente que necesita escala, automatización o nube; sí puede ser suficientemente completo para un usuario ocasional. El riesgo de monetización no se resuelve degradando la seguridad básica, sino haciendo visible y consistente el valor recurrente de Premium.

## Alcance real actual

| Capacidad | Free actual | Premium actual o previsto |
|---|---|---|
| Importación, cámara y escáner | Sí | Sí |
| Enmascarado manual y OCR conservador | Sí | Sí |
| Exportación segura/verificada | Sí, sin límite efectivo | Sí |
| Biblioteca local cifrada y Bóveda | Sí en el código actual | Sí, aunque el paywall la presenta como exclusiva |
| Documentos procesados | 10 acumulados; borrar no recupera cuota | Ilimitados |
| Estilos avanzados | Algunos estilos bloqueados | Deberían ser Premium |
| Modos legal/salud/banca | Deberían ser Premium | Sí, pero existe una ruta de acceso sin gate desde Home |
| Batch, nube, iCloud y proveedores externos | Bloqueados correctamente en los puntos revisados | Sí |
| Ajustes avanzados | Algunas funciones bloqueadas | Sí |
| Iconos alternativos | Bloqueados | Sí |

El núcleo “proteger un documento y obtener una salida segura” está deliberadamente abierto. Esto es coherente con el posicionamiento de producto, pero reduce la urgencia de pagar en el segmento de uso esporádico.

## Hallazgos críticos

### 1. El límite Free no es el único problema

`PremiumManager` define 10 documentos procesados y una cuota de exportación semanal igual a cero, pero `canExportNow()` siempre devuelve `true`. La exportación segura no está actuando como palanca de conversión.

Además, el contador de documentos es acumulado y se incrementa al añadir documentos incluso cuando el usuario es Premium. Al terminar el trial, un usuario que haya usado más de 10 documentos puede quedar bloqueado inmediatamente; otro que esté por debajo seguirá teniendo una experiencia Free muy completa.

### 2. Hay inconsistencias entre producto, paywall y código

- `PRODUCT_POSITIONING.md` trata la Bóveda local y la exportación verificada sin marca obligatoria como parte de Free.
- `VaultView` no comprueba Premium, pero el paywall vende “Vault with Face ID” como beneficio Pro.
- Los modos rápidos de Home se pueden seleccionar sin comprobar `requiresPro`; el modo se aplica después en el editor sin un segundo gate.
- El watermark personalizado y varias herramientas del editor se muestran sin bloqueo claro, mientras que el paywall las presenta de forma ambigua.
- La documentación arquitectónica aún menciona reglas antiguas, como 3 documentos, límite de exportación y watermark Free obligatorio.

Esto es más grave que una lista de beneficios incompleta: enseña al usuario que algunas promesas Premium son opcionales o evitables.

### 3. El paywall no explica el valor que más probablemente convierte

El paywall principal y el de onboarding muestran esencialmente cuatro filas: documentos ilimitados, estilos, Bóveda e iCloud. No destacan de forma clara batch, modos profesionales, nube/proveedores, ajustes avanzados ni el ahorro de tiempo por flujo repetitivo. Tampoco explican qué permanece gratis y por qué Premium es útil para quien protege documentos con frecuencia.

El paywall de onboarding aparece antes del primer resultado útil. Eso favorece que el trial se use como prueba general del producto, se cancele para evitar una renovación y no se llegue a formar una percepción de valor recurrente.

### 4. No se puede saber todavía qué hacen los cancelados

No hay datos históricos en el repositorio que permitan afirmar si esos usuarios exportan, usan la Bóveda, prueban estilos, alcanzan el límite o utilizan funciones Pro durante el trial. Solo se pueden formular hipótesis:

- necesidad puntual resuelta con Free;
- cancelación preventiva del auto-renewal, manteniendo el trial activo;
- falta de descubrimiento de batch, nube y automatización;
- funciones Premium que no están realmente bloqueadas;
- valor de privacidad y seguridad alto, pero poca necesidad de uso recurrente;
- precio o modelo de suscripción inadecuado para un uso ocasional.

## Observabilidad que falta

La allowlist de analytics descarta campos que el flujo ya intenta enviar, entre ellos `plan` y `started_checkout`. Además, los eventos no llevan de forma consistente el tier real del usuario. El runtime distingue esencialmente `isPro`, aunque el modelo contempla trial, premium y lifetime.

Durante un trial deberían poder reconstruirse, de forma agregada y con consentimiento:

- inicio, cancelación de renovación, expiración y renovación;
- uso durante el trial y después de expirar;
- feature que provocó cada paywall;
- documento procesado, redacciones, exportación verificada y uso de Vault por tier;
- hitos de cuota: 1, 3, 5, 8 y 10 documentos;
- conversión por contexto: límite, batch, estilo, modo, nube o ajustes;
- uso posterior a cancelación separado entre “entitlement aún activo” y “trial expirado”.

Eventos mínimos recomendados:

| Evento | Propiedades principales |
|---|---|
| `entitlement_snapshot` | `tier` free/trial/premium/lifetime, estado de renovación, producto |
| `feature_gate_shown` / `feature_gate_tapped` | feature, tier, trigger, cuota aproximada |
| `quota_milestone` | documentos procesados y bucket de cuota |
| `import_completed`, `redaction_applied`, `export_success`, `vault_unlocked` | `user_tier`, modo, formato y contexto seguro |
| `trial_lifecycle` | iniciado, auto-renew off, expirado, convertido |

No conviene registrar contenido de documentos ni PII. Basta con el contexto de producto necesario para comparar cohortes.

## Plan recomendado

### P0 — Reconciliar el contrato del producto

1. Decidir y documentar si la Bóveda local sigue siendo Free. El posicionamiento actual indica que sí; en ese caso debe salir del paywall y el valor Premium debe ser nube, escala y flujo.
2. Cerrar el bypass de los modos legal/salud/banca en la capa de dominio o de acción, no solo en la UI.
3. Decidir qué ocurre con presets, watermark, rotación, flip y ajustes. Cada capacidad debe estar en una de tres categorías: Free, Premium o no disponible; código, paywall y documentación deben coincidir.
4. Actualizar la documentación antigua para que no contradiga el comportamiento actual.

### P1 — Mostrar valor Premium en el momento correcto

Replantear el mensaje alrededor de productividad recurrente:

- “Protege documentos ilimitados, más allá de los 10 de Free”.
- “Procesa varios documentos de una vez”.
- “Reutiliza modos y plantillas para no empezar de cero”.
- “Continúa el flujo entre dispositivos y proveedores cloud”.
- “Accede a estilos y ajustes avanzados”.

La Bóveda local, el cifrado, la exportación verificada y la seguridad básica deben comunicarse como valor Free que genera confianza, no como beneficios Premium falsamente exclusivos.

El primer paywall útil debería aparecer después de que el usuario haya visto un resultado correcto o al acercarse a una restricción, con un mensaje contextual. El paywall de onboarding puede seguir existiendo, pero no debería ser el principal argumento de venta.

### P1 — Instrumentar antes de cambiar límites o precio

Corregir la allowlist de analytics y añadir tier/trial state a los eventos de uso. Después, observar al menos dos o cuatro semanas antes de concluir que el límite de 10 es demasiado generoso.

### P2 — Experimentos

Solo con datos:

- comparar conversión por trigger y por feature usada durante el trial;
- probar presentación anual frente a mensual;
- evaluar una cuota de documentos activos o mensual solo si los usuarios llegan al límite y siguen necesitando la app;
- considerar una compra lifetime para el segmento de uso ocasional si el patrón confirma que la suscripción no encaja.

No recomiendo limitar la exportación segura ni introducir una marca de agua coercitiva: dañaría el principal argumento de confianza y seguridad de la app.

## Métricas de decisión

- Trial iniciado → auto-renew desactivado → trial expirado → conversión.
- Porcentaje de trials que usan 0, 1, 2 o más funciones Premium reales.
- Activación: primera exportación verificada en 24 horas.
- Retención: documento protegido en D7 y D30.
- Uso Free después de expirar: imports, redacciones, exports y Vault.
- Distribución de paywalls por trigger y conversión por trigger.
- Tiempo hasta alcanzar 10 documentos y proporción que llega al límite.

Regla de interpretación:

- Si los cancelados solo usan exportación, Vault y protección manual, Free está resolviendo bien el caso puntual; hay que vender workflows recurrentes o reconsiderar el modelo de suscripción.
- Si intentan funciones Premium pero no compran, el problema está en valor percibido, copy, precio o UX.
- Si usan batch, nube, estilos o modos Premium durante el trial y aun así cancelan, el problema es probablemente ROI, frecuencia de uso o modelo de cobro.

## Archivos de referencia

- `Shield/Premium/PremiumManager.swift`
- `Shield/Views/Paywall/PaywallView.swift`
- `Shield/Views/Home/HomeSectionViews.swift`
- `Shield/Views/Home/HomeView.swift`
- `Shield/Views/Vault/VaultView.swift`
- `Shield/Views/Editor/EditorChromeViews.swift`
- `Shield/ViewModels/AppState.swift`
- `Shield/App/AppReviewManager.swift`
- `Docs/PRODUCT_POSITIONING.md`
- `Docs/ANALYTICS_TRACKING_PLAN.md`
- `Docs/ARQUITECTURA.md`

