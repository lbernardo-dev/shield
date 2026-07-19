# Shield — Auditoría integral de producto, ingeniería y App Store

**Fecha:** 16 de julio de 2026  
**Estado auditado:** árbol local actual, incluidos cambios sin confirmar, y App Store Connect app `6790398619`, versión `1.0.0`.  
**Alcance:** arquitectura, seguridad, privacidad, exportación, rendimiento, fluidez, SwiftUI, accesibilidad, localización, StoreKit, ecosistema Apple, ficha técnica y puertas de release.

## 0. Adenda de remediación ejecutada — 16/07/2026

El plan técnico y de metadatos derivado de esta auditoría se ha ejecutado sobre el árbol de trabajo actual. Los hallazgos P0.1, P0.2 y P0.3 quedan corregidos y verificados; P0.4 queda preparado con un nuevo build number, pero su cierre definitivo exige consolidar el árbol del propietario en un commit/tag limpio antes de crear y subir el RC.

### Correcciones implantadas

- URLs públicas ES/EN de marketing, soporte y privacidad sustituidas en App Store Connect por rutas controladas y verificadas de GitHub Pages. El preflight remoto valida ahora host final, 2xx, HTML, identidad Shield, contenido esperado y ausencia de borradores.
- Privacidad, términos y condiciones de suscripción completados con proveedor, domicilio, contacto, legislación y jurisdicción; eliminados los avisos de borrador y placeholders tanto de web como de los textos legales dentro de la app.
- Exportación PDF convertida a escritura streaming página a página con `UIGraphicsPDFRenderer`, `autoreleasepool`, cancelación, progreso, errores tipados, limpieza transaccional y verificación final obligatoria.
- Añadida prueba de exportación PDF de 50 páginas, con comprobación de número de páginas y del verificador seguro.
- App Intents y App Shortcuts localizados en inglés y español mediante `AppShortcuts.xcstrings`.
- Accesibilidad reforzada en Captura, Editor, OCR, Exportación, Home, Paywall, Vault y Ajustes: objetivos táctiles, semántica de selección, acciones de mover/redimensionar/eliminar máscaras, textos localizados y soporte de Reduce Transparency.
- Matriz automatizada de auditoría UI ampliada a 8 escenas funcionales en inglés y español. Los diagnósticos Vision sin `XCUIElement` se registran como falsos positivos no remediables; cualquier incidencia asociada a un elemento concreto continúa fallando el gate.
- CloudKit redefinido como copia privada de índice minimizado: el contenido local sigue siendo autoritativo, se eliminan registros huérfanos, desactivar limpia el índice remoto, los errores se muestran y las consultas paginan más de 500 registros.
- Build number incrementado a `100202607161`.
- Metadatos canónicos ES/EN sincronizados con App Store Connect y descripción ajustada para no prometer funciones de accesibilidad aún no declaradas formalmente.

### Evidencia final

| Comprobación posterior | Resultado |
|---|---|
| `scripts/release_gate.sh` | Verde |
| Build estricto + Swift concurrency `complete` | Verde |
| Tests unitarios, seguridad, OCR, importación y rendimiento | Verde |
| Auditoría UI, 10 tests / 8 escenas funcionales ES+EN | Verde |
| Exportación streaming de 50 páginas | Verde |
| `xcodebuild analyze`, Release | Verde |
| `scripts/app_store_preflight.sh --remote` | Verde |
| `asc metadata validate --subscription-app` | 0 errores, 0 warnings |
| `asc validate`, versión 1.0.0 | 0 errores, 0 bloqueos; 5 warnings administrativos y 2 infos |

### Límites externos que permanecen

1. Consolidar el amplio árbol de trabajo preexistente en un commit/tag limpio, generar archive/IPA desde esa revisión y registrar SHA-256. No se ha creado un commit automático para no apropiarse ni mezclar cambios del propietario.
2. Verificar en dispositivo físico iPhone/iPad, incluida cámara, Fotos limitada, biometría, Share Extension, memoria y estabilidad interna durante 72 horas.
3. Confirmar manualmente el estado publicado de App Privacy; no es verificable mediante la API pública de App Store Connect.
4. Adjuntar mensual, anual y lifetime al primer envío. Las dos imágenes promocionales de suscripción son opcionales salvo que se usen promociones, offer codes o win-back.
5. No se ha subido binario ni enviado la app/productos a revisión.

## 1. Dictamen ejecutivo

Shield ha evolucionado desde un prototipo avanzado a una candidata de producto seria. El build estricto, tests, exportación rasterizada, verificador, cifrado, Share Extension, iPad, App Intents y configuración de App Store Connect son mejoras sustanciales y verificables.

**No se recomienda enviar todavía la versión 1.0.0 a revisión.** Hay tres puertas críticas:

1. Las URL publicadas actualmente en App Store Connect bajo `shieldapp.io` redirigen a un dominio ajeno (`30fsw.uk.com`). La URL de privacidad deja de ser una política de Shield. Esto es un riesgo directo de rechazo, confianza y cumplimiento.
2. La exportación PDF multipágina conserva todas las páginas rasterizadas en memoria antes de escribir el PDF. En calidad alta, 50 páginas pueden acercarse a 900 MB de memoria decodificada, aunque el presupuesto declarado sea 256 MB.
3. El build remoto `100202607132` no tiene trazabilidad reproducible frente al árbol local actual, que contiene una reconstrucción extensa sin confirmar y metadatos posteriores. Antes de presentar, debe generarse un nuevo RC desde un commit limpio e inmutable.

La madurez global estimada es **68/100**. La base técnica es buena; el nivel de release sigue limitado por distribución, accesibilidad real, rendimiento extremo y disciplina de artefactos.

## 2. Evidencia ejecutada

| Comprobación | Resultado |
|---|---|
| `scripts/release_gate.sh` | Verde |
| Build con warnings como errores | Verde |
| Swift strict concurrency `complete` | Verde |
| Tests unitarios/integración/rendimiento | 40 casos verdes |
| UI tests | 2 casos verdes |
| Auditoría UI automatizada | Verde solo en pantalla de arranque |
| `xcodebuild analyze`, Release | Verde |
| Preflight plist/entitlements/privacy manifest | Verde |
| App Store Connect build | `VALID`, iOS 18.0, cifrado exento |
| `asc validate` | 0 errores, 0 bloqueos, 5 warnings, 2 infos |
| Metadatos ASC ES/EN | 0 errores, 0 warnings offline |
| Screenshots | 10 iPhone por idioma; 2 iPad ES y 1 iPad EN; todos `COMPLETE` |
| App Accessibility en ASC | 0 declaraciones |
| Privacidad publicada | Verificada manualmente el 13/07; no reconfirmable hoy porque caducó la sesión web ASC |
| URLs ASC | HTTP 200 final, pero redirección fuera de `shieldapp.io` a `30fsw.uk.com` |

## 3. Evaluación por área

| Área | Nota | Lectura |
|---|---:|---|
| Seguridad local | 82/100 | AES-GCM, Keychain, separación de claves, protección de archivos y snapshot shield son una base sólida. |
| Seguridad de exportación | 80/100 | PDF rasterizado, estilos normalizados y verificación residual; falta estrés multipágina y mayor cobertura adversarial. |
| Calidad de build y tests | 84/100 | Build/analyze estrictos y 42 pruebas; la cobertura UI y de dispositivo físico sigue siendo pequeña. |
| Rendimiento y fluidez | 60/100 | Importación acotada; exportación y algunos hot paths aún pueden exceder memoria o MainActor. |
| Accesibilidad | 38/100 | Mejoras puntuales, pero la ficha promete más de lo demostrado. Dynamic Type no está adoptado de forma general. |
| Arquitectura/mantenibilidad | 59/100 | Servicios y tests nuevos, pero persisten archivos de 700–1.600 líneas y estado global amplio. |
| Localización | 70/100 | Catálogos ES/EN extensos; quedan strings y accesibilidad hardcodeados, y App Shortcuts no traducidos. |
| Ecosistema Apple | 78/100 | iPhone/iPad, Share Extension, teclado y App Intents ya existen. No hace falta añadir superficies sin utilidad real. |
| App Store Connect | 55/100 | Configuración casi completa; URLs rotas, productos de primera versión pendientes y declaraciones a11y ausentes. |
| Trazabilidad de release | 45/100 | El artefacto remoto no queda ligado de forma demostrable a un commit limpio y al informe de verificación. |

## 4. Hallazgos P0 — bloquear envío

### P0.1 — Las URL públicas de ASC salen de Shield

ASC contiene actualmente:

- `https://shieldapp.io/`
- `https://shieldapp.io/support`
- `https://shieldapp.io/privacy`
- `https://shieldapp.io/terms`

Las cuatro redirigen a `https://30fsw.uk.com/`; `/privacy` pasa por `https://30fsw.uk.com/privacy` y termina en la portada tras otro `301`. Un reviewer no recibe una política o soporte inequívocos de Shield.

**Corrección:** restaurar el dominio y sus rutas, o volver temporalmente a las rutas GitHub Pages ya verificadas con respuesta 200 y host estable. Modificar `scripts/app_store_preflight.sh` para validar también `url_effective`, host final, contenido/branding esperado y todas las rutas, no solo status 2xx de privacidad/términos.

### P0.2 — Documentación legal todavía en modo borrador

`Docs/legal/privacy.html`, `terms.html` y `subscription-terms.html` incluyen avisos de “Publication draft” y placeholders como `[FINAL LEGAL ADDRESS]`, `[TO BE COMPLETED]` y `[POR COMPLETAR]`.

**Corrección:** completar identidad del responsable/proveedor, domicilio o información legal aplicable, jurisdicción, email definitivo, fecha efectiva y URLs canónicas. Validar coherencia con CloudKit, MetricKit local, compras y eliminación de datos. Revisión jurídica final recomendada; esta auditoría no sustituye asesoramiento legal.

### P0.3 — Exportación de 50 páginas puede superar la memoria razonable

`ExportEngine.exportAsPDF` acumula `[(UIImage, CGRect)]` y escribe el PDF solo después de rasterizar todas las páginas. Una página A4 aproximada a escala 3 ocupa unos 18 MB RGBA; 50 páginas pueden rondar 900 MB, sin contar origen, Core Image, PDFKit, OCR y copias temporales.

**Corrección:** render y escritura streaming por página, `autoreleasepool`, límite de concurrencia 1–2, liberación inmediata, cancelación y progreso. Añadir tests/mediciones de exportación de 20/50 páginas en Release y dispositivo real con techo de memoria.

### P0.4 — El RC remoto no es reproducible desde el estado actual

El build ASC `100202607132` fue subido el 13/07. El árbol del 16/07 está ampliamente modificado y sin commit limpio; se mantiene el mismo build number. No existe evidencia criptográfica que vincule el IPA remoto con una revisión concreta del código y metadatos actuales.

**Corrección:** consolidar el árbol, ejecutar revisión de diff, commit/tag, incrementar build, archive Release desde ese commit, ejecutar `audit_ipa.sh`, registrar checksum SHA-256, validar en TestFlight y adjuntar el build nuevo a 1.0.0.

## 5. Hallazgos P1 — antes de declarar nivel profesional

### P1.1 — La accesibilidad declarada en la descripción supera la evidencia

- 488 usos de `.font(.system(size: ...))` con tamaño fijo.
- 79 usos de modificadores de accesibilidad, concentrados en determinadas pantallas.
- 8 lecturas de Reduce Motion.
- 0 lecturas de Reduce Transparency, Increase Contrast, Bold Text o Differentiate Without Color.
- Varias etiquetas/hints de VoiceOver están hardcodeadas en español (`DocumentCanvas`, `TabBar`, componentes), incluso con la app en inglés.
- El editor ofrece acción ajustable para cambiar tamaño de una máscara, pero no una alternativa equivalente para moverla en cuatro direcciones.
- `FieldOverlay` usa `onTapGesture` sobre una forma y no presenta un control accesible equivalente completo.
- El único `performAccessibilityAudit` se ejecuta en la pantalla inicial; no recorre onboarding, biblioteca, captura, editor, OCR, exportación, paywall, Vault y ajustes.

Apple exige que todas las tareas comunes puedan completarse con la función declarada. Hoy no es honesto publicar aún etiquetas de VoiceOver o Larger Text para iPhone/iPad.

**Corrección:** migrar texto funcional a estilos semánticos, usar `@ScaledMetric` donde corresponda, layouts adaptativos a tamaños de accesibilidad, localización de labels, acciones completas de mover/redimensionar, foco tras sheets, avisos accesibles, matriz UI por flujo y auditoría en iPhone/iPad. Publicar declaraciones ASC solo después.

### P1.2 — App Shortcuts funciona, pero el español recibe frases inglesas

El analizador de App Intents entrena:

`Mask a document...` y `Open my secure vault...` para locales `en` y `es`.

No hay traducciones específicas de titles, descriptions, dialogs, short titles y frases de `ShieldAppIntents.swift`.

**Corrección:** catálogo de localización para App Intents/App Shortcuts, frases naturales españolas que incluyan `\(.applicationName)`, y tests manuales en Siri/Atajos con ambos locales.

### P1.3 — “iCloud sync” no es una sincronización funcional completa

La implementación sube un índice privado minimizado, pero el pull devuelve registros que luego se descartan. `deleteRemoteDocument` no está conectado al borrado local y desactivar iCloud no limpia el índice remoto. Esto crea estado obsoleto sin beneficio visible equivalente.

**Corrección:** para 1.0, renombrar con precisión como “copia/índice privado” o retirar la opción. Si se conserva, implementar reconciliación, tombstones/borrado, consentimiento y explicación de qué campos salen del dispositivo. Reconfirmar App Privacy después de decidir.

### P1.4 — Cobertura de tests insuficiente en tareas críticas

Las 40 pruebas actuales son valiosas, pero faltan:

- flujo UI completo importar → OCR → máscara → exportar → compartir;
- cancelación/fallo transaccional por página;
- estrés de exportación y memoria;
- StoreKit: compra, restore, pending, revocation, grace/billing retry;
- Share Extension end-to-end;
- App Intents ES/EN;
- rutas con PDF cifrado/protegido, corrupto y proveedores Files;
- iPad Split View, teclado, VoiceOver y tamaños de texto extremos;
- ejecución en dispositivo físico con cámara, Fotos limitada y biometría.

### P1.5 — El preflight remoto produce falsos positivos

`scripts/app_store_preflight.sh --remote` acepta cualquier cadena de redirecciones que termine en 2xx. Esa lógica habría aprobado el estado actual ajeno a Shield.

**Corrección:** bloquear cambio de host, validar content-type, título, texto identificador de la app, ausencia de placeholders, idioma y rutas de marketing/support/FAQ/subscription terms.

### P1.6 — Metadatos canónicos locales y ASC han divergido

Los JSON locales apuntan a GitHub Pages; ASC apunta a `shieldapp.io`. `asc metadata validate` pasa en ambos porque valida esquema y límites, no equivalencia ni disponibilidad.

**Corrección:** elegir una fuente canónica, hacer pull después de reparar URLs y guardar los mismos valores que ASC. Añadir diff de metadata al release gate.

### P1.7 — Deuda de mantenibilidad y silenciamiento de errores

Persisten archivos muy grandes: `OnboardingSteps.swift` 1.625 líneas, `CaptureOCRServices.swift` 1.579, `HomeView.swift` 1.498, `CaptureReviewViews.swift` 1.425 y `SettingsDestinationViews.swift` 1.216. Se contabilizan 75 usos de `try?`; varios son cleanup tolerable, pero otros ocultan fallos de persistencia/importación.

**Corrección:** dividir por feature/service, introducir errores tipados y logging local sin PII, y reservar `try?` a operaciones explícitamente best-effort documentadas.

## 6. App Store Connect — estado y acciones

### Estado verificado

- App: `Shield`, ID `6790398619`, bundle `com.romerodev.shield`.
- Versión `1.0.0`: `PREPARE_FOR_SUBMISSION`.
- Build `100202607132`: `VALID`, mínimo iOS 18.0, non-exempt encryption `false`.
- Validación: 0 errores, 0 bloqueos.
- Suscripción mensual `6790401134`: `READY_TO_SUBMIT`.
- Suscripción anual `6790401098`: `READY_TO_SUBMIT`.
- Lifetime `6791491284`: `READY_TO_SUBMIT`.
- Release manual: correcto y recomendable para la primera versión.

### Pendientes ASC

1. Reparar URLs antes de cualquier envío.
2. Completar y publicar textos legales finales.
3. Reconfirmar App Privacy mediante sesión web. El public API no permite verificar el publish state.
4. Adjuntar mensual, anual y lifetime a la primera revisión de la app. No enviar sin autorización explícita.
5. Las imágenes promocionales de mensual/anual son opcionales para review, pero recomendables si se usarán promociones, offer codes o win-back.
6. No publicar etiquetas de accesibilidad hasta completar la matriz de tareas comunes.
7. Generar y adjuntar un RC nuevo trazable.
8. Validar screenshots iPad más allá del mínimo: 1 EN y 2 ES cumplen, pero una secuencia profesional debería contar la historia completa también en iPad.

## 7. ¿Widget, atajo, Control Center o Live Activity?

### Decisión recomendada

**No implementar un widget informativo tradicional en 1.0.** Shield trabaja con documentos sensibles y no tiene una métrica o estado periódico que justifique ocupar Home/Lock Screen. Mostrar nombres, miniaturas, recuentos o documentos recientes aumenta exposición y aporta poca agilidad.

**Mantener y mejorar las superficies ya correctas:**

1. **Share Extension — alta utilidad:** es la vía más rápida desde Fotos, Archivos, Mail y otras apps. Debe recibir mayor inversión en tests y feedback de progreso/error.
2. **App Shortcut “Proteger documento” — alta utilidad:** reduce navegación y no expone datos. Localizar ES/EN y validar Siri.
3. **App Shortcut “Abrir Vault” — utilidad media:** correcto si siempre conserva autenticación y no revela títulos en la respuesta del sistema.
4. **Atajos de teclado en iPad — alta utilidad:** ya existen en editor; añadir discoverability, comandos para máscara, undo/redo, página anterior/siguiente y exportación.

### Superficie nueva opcional, después de 1.0

Un **Control Center control** “Escanear y proteger” puede reducir un paso y abrir directamente captura. Es preferible a un widget porque es una acción explícita, sin contenido sensible persistente. Implementarlo solo después de medir que captura/importación es una tarea frecuente y tras completar accesibilidad/localización.

### No recomendado

- Live Activity/Dynamic Island: no existe un proceso largo útil que deba permanecer visible; exportaciones deben ser cortas y cancelables.
- Spotlight con títulos/documentos: riesgo de exposición en búsquedas y sugerencias.
- Widget de documento reciente o contador: baja utilidad y riesgo de privacidad.
- App Clip: la funcionalidad requiere permisos, edición, almacenamiento seguro y revisión; no encaja en una experiencia efímera.

## 8. Roadmap recomendado

### Fase A — bloqueo de release (2–4 días)

1. Reparar dominio/URLs y fortalecer preflight.
2. Completar legales definitivos.
3. Convertir exportación PDF a streaming y añadir benchmark 20/50 páginas.
4. Congelar código en commit limpio, incrementar build y generar nuevo RC.
5. TestFlight interno en iPhone/iPad físicos y smoke test de todos los flujos.

### Fase B — calidad profesional (1–2 semanas)

1. Dynamic Type y matriz de accesibilidad de tareas comunes.
2. Localización completa de a11y y App Intents.
3. Decidir/retirar/reconstruir iCloud index.
4. UI tests de importación, editor, exportación, StoreKit y Share Extension.
5. Instrumentación con Instruments: SwiftUI, Time Profiler, Hangs, Allocations y Memory Graph en Release.

### Fase C — crecimiento posterior al lanzamiento

1. Mejorar screenshots iPad y ASO con datos reales de conversión.
2. Control Center “Escanear y proteger” si la telemetría local/agregada permitida justifica el caso.
3. Mejoras de teclado/trackpad y multiwindow en iPad.
4. Evaluar macOS/Catalyst solo después de estabilizar el editor y el modelo documental.

## 9. Puerta final de aprobación

El envío será recomendable cuando:

- todas las URL permanezcan en un dominio controlado y muestren contenido final de Shield;
- no existan placeholders legales;
- el export de 50 páginas respete memoria/cancelación o el límite se reduzca de forma honesta;
- el RC provenga de un commit/tag limpio con checksum y `audit_ipa.sh` verde;
- App Privacy se reconfirme y coincida con la decisión sobre CloudKit;
- productos first-time estén adjuntos;
- VoiceOver/Larger Text se retiren de la descripción o se demuestren en todos los flujos comunes;
- TestFlight físico no presente crashes, hangs ni pérdida de trabajo durante al menos 72 horas de uso interno.

## 10. Referencias Apple vigentes

- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- App Privacy Details: https://developer.apple.com/app-store/app-privacy-details/
- Accessibility Nutrition Labels: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/
- Larger Text criteria: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/larger-text-evaluation-criteria/
- VoiceOver criteria: https://developer.apple.com/help/app-store-connect/manage-app-accessibility/voiceover-evaluation-criteria/
- Privacy manifests / required reasons: https://developer.apple.com/documentation/technotes/tn3183-adding-required-reason-api-entries-to-your-privacy-manifest
