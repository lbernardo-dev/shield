# Auditoría integral de MaskID

**Fecha:** 10 de septiembre de 2026  
**Alcance:** producto, UX/UI, ingeniería iOS, arquitectura, privacidad y seguridad, App Review, App Store Connect, ASO, localización, monetización, growth, soporte y release management.  
**Versión auditada:** 1.0.8 · build `108202609071` · app `6790398619`.

## Veredicto ejecutivo

MaskID ya es un producto publicable y diferencial: resuelve una necesidad concreta —ocultar datos privados antes de compartir documentos— con OCR en el dispositivo, revisión manual, exportación protegida, bóveda local, extensiones y una propuesta de privacidad comprensible. La base técnica y la presentación visual están por encima de la media de una primera versión.

La principal oportunidad no es añadir muchas más funciones. Es hacer que cada promesa sea demostrable, que cada pantalla comunique confianza sin absolutismos y que el recorrido hasta el primer export protegido sea más corto, elegante y medible.

**Valoración experta actual: 76/100.**

| Área | Nivel | Diagnóstico |
|---|---:|---|
| Problema/producto | 84 | Caso de uso claro y con valor real; faltan segmentos y casos de éxito medidos. |
| UX/UI | 78 | Identidad visual consistente y UI real en la ficha; editor iPad y estados de error necesitan refinamiento. |
| Ingeniería iOS | 79 | Buen uso de SwiftUI, Vision, File Protection, Keychain y CloudKit; deuda de modularidad y manejo de errores. |
| Privacidad/seguridad | 82 técnico / 56 comunicativo | La implementación es razonable; algunas afirmaciones públicas exceden la evidencia técnica. |
| QA/release | 68 | Preflight y build remoto correctos; las pruebas locales quedan bloqueadas por contaminación del caché. |
| App Store Connect/Review | 80 | Versión publicada, build válido, IAP/suscripciones sin errores; App Privacy web no quedó verificable. |
| ASO/creatividades | 70 | Metadata actual válida; screenshots fuertes pero con dos claims de alto riesgo y una pantalla de error visible. |
| Accesibilidad | 68 | Hay trabajo de accesibilidad en código, pero la ficha no declara prestaciones y falta validación en dispositivos. |
| Monetización/growth | 65 | Modelo coherente, pero todavía falta un embudo de activación y retención basado en eventos no sensibles. |

### Decisión de release

- **Producción 1.0.8:** estado saludable; `READY_FOR_SALE` / `READY_FOR_DISTRIBUTION`, build `VALID`, revisión completada, sin bloqueadores de envío detectados por el estado remoto.
- **Siguiente versión:** **no debe entrar en revisión todavía**. Antes hay que corregir claims, regenerar creatividades, comprobar la ficha pública española, confirmar App Privacy en la web de App Store Connect y recuperar una ejecución reproducible de tests.
- `asc metadata validate --subscription-app`: **0 errores, 0 warnings**.
- `asc validate`: el único error es que se está validando una versión ya distribuida y no editable; además, el estado de publicación de App Privacy no es verificable vía API pública. No se debe interpretar ese error como un defecto del binario 1.0.8.

## 1. Evidencia de App Store Connect

### Lo que está bien

- La ficha remota contiene nombre, subtítulo, keywords, descripción, novedades, URLs legales y marketing en `en-US` y `es-ES`, dentro de límites.
- Hay 10 screenshots de iPhone y 2 de iPad; todas aparecen en estado `COMPLETE` y con dimensiones aceptadas.
- El build remoto es válido y está marcado como exento de cifrado no exento.
- Los productos comerciales están sanos: 1 compra no consumible y 2 suscripciones, sin errores de validación.
- La política de privacidad está localizada y enlazada desde la ficha. Las páginas remotas de marketing, soporte, privacidad, términos y suscripción responden correctamente al preflight.
- La metadata canónica actual en ASC es sustancialmente mejor que la versión histórica que aún se muestra en algunas superficies públicas.

### Hallazgos que requieren acción

1. **Desfase entre ASC y la ficha pública española.** La página pública española observada el 10/09 sigue mostrando el título, descripción y claims antiguos, incluyendo lenguaje equivalente a “100% offline”, “sin nube” y “Secure Enclave”. La metadata canónica descargada de ASC ya contiene una redacción más precisa. Hay que verificar la localización en la web de ASC, esperar la propagación y comprobar el resultado desde App Store y un dispositivo limpio.

2. **App Privacy no confirmable desde la API.** La herramienta informa `privacy.publish_state.unverified` y el acceso web estaba caducado; la reautenticación devolvió un error 503. La declaración debe revisarse manualmente antes de la próxima entrega. El código y `Shield/PrivacyInfo.xcprivacy` indican analítica, crashes, rendimiento, identificadores y compras, sin tracking ni contenido documental.

3. **Accesibilidad no indicada en la ficha.** La página pública muestra que el desarrollador no ha indicado prestaciones de accesibilidad. Esto no demuestra que la app sea inaccesible, pero sí que se está perdiendo una señal de calidad y confianza.

4. **Historial de versiones con claims antiguos.** Las notas y descripciones de versiones previas siguen mostrando promesas más absolutas. No siempre se pueden editar retrospectivamente; sí se debe evitar repetirlas y, si ASC lo permite, corregir la metadata visible de la versión actual.

5. **Trazabilidad creativa incompleta.** El repositorio contiene plan y previews, pero no una fuente local inequívoca para todas las screenshots actualmente subidas. Cada asset debe quedar asociado a un fixture, versión de UI, locale y fecha de aprobación.

Fuentes oficiales para los límites y requisitos: [información de app en App Store Connect](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information), [límites de información de versión](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information), [especificaciones de screenshots](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) y [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

## 2. Auditoría de la propuesta y del producto

### Núcleo diferencial

La propuesta debe concentrarse en esta frase:

> **Prepara una copia segura de un documento antes de compartirla: detecta, revisa y oculta únicamente lo que la otra persona no necesita.**

La combinación que debe defenderse es:

- detección OCR local asistida por Vision;
- revisión humana obligatoria antes de exportar;
- máscaras manuales y estilos de protección;
- exportación aplanada y verificada;
- bóveda local con Face ID/PIN;
- importación desde cámara, Fotos, Archivos y proveedores autorizados;
- flujo iPad, Share Extension y widget como extensiones del mismo trabajo.

No conviene posicionar MaskID como un editor PDF genérico, una solución forense o un servicio de “anonimato certificado”. Su territorio es **compartir documentos cotidianos con menos exposición accidental**.

### Fricciones de producto

- El onboarding recorre demasiados conceptos —objetivo, privacidad, demo, permisos, seguridad y paywall— antes de consolidar el primer resultado. Debe llevar al primer documento protegido en tres decisiones simples y pedir cada permiso justo cuando aporta valor.
- El paywall aparece demasiado cerca de la introducción. El usuario debe poder vivir un “aha moment” completo: importar, ocultar un dato y exportar una copia protegida, con límites claros y sin sensación de bloqueo prematuro.
- El editor es potente, pero la densidad de controles, chips y estados puede intimidar a alguien que solo necesita ocultar un DNI o una dirección.
- La detección automática está bien planteada como sugerencia, pero la jerarquía debe hacer imposible confundir “sugerido” con “protegido”.
- La sincronización opcional y los proveedores externos requieren un centro de confianza visible: qué sale del dispositivo, qué permanece local, qué se puede borrar y qué no se sincroniza.

### Experiencia objetivo

1. **Entrada:** “¿Qué vas a compartir?” con Cámara, Fotos, Archivos y proveedor conectado.
2. **Detección:** sugerencias agrupadas por tipo, con contador “pendientes de revisar”.
3. **Revisión:** un gesto para aceptar una sugerencia, otro para corregirla; siempre visible el original frente a la copia protegida.
4. **Verificación:** informe breve con páginas, texto extraíble, anotaciones, metadatos y comprobaciones de residuales.
5. **Salida:** Compartir / Guardar / Añadir a bóveda, con una explicación mínima de la protección aplicada.

## 3. Privacidad y seguridad: la prioridad estratégica

### Evidencia técnica favorable

- El procesamiento de OCR, máscaras y exportación ocurre localmente en el flujo principal.
- La bóveda usa cifrado AES-GCM y Keychain/Face ID como control de acceso; se aplican protecciones de archivo.
- Firebase Analytics y Crashlytics están limitados a telemetría declarada; la política excluye títulos, OCR, nombres de archivo, URLs e imágenes.
- CloudKit es opcional para documentos fuera de la bóveda y almacena paquetes restituibles completos en la base privada de iCloud. La bóveda permanece local.
- La exportación PDF se aplana y se verifica; el verificador comprueba aspectos concretos, no una garantía universal de ausencia de información.

### Claims que deben corregirse

| Claim observado | Problema | Claim aprobado recomendado |
|---|---|---|
| “Hardware encryption” / “Secure Enclave” | El código mostrado usa AES-GCM, Keychain y Face ID; no hay evidencia de una clave de bóveda respaldada directamente por Secure Enclave. | “Bóveda local cifrada con AES-GCM y protegida por Face ID/PIN”. |
| “Zero cloud servers” / “100% offline” | Existe sincronización opcional con CloudKit y conexión a Google Drive/Dropbox iniciada por el usuario. | “El procesamiento principal ocurre en el dispositivo. La sincronización y los proveedores externos son opcionales.” |
| “Certified privacy” | No consta certificación externa ni un esquema de conformidad que permita esa palabra. | “Exportación verificada” o “Copia aplanada y revisada”. |
| “Masked data cannot be recovered” | El verificador cubre comprobaciones definidas, no todos los canales de metadatos, OCR o imágenes posibles. | “Diseñada para impedir la recuperación de las áreas ocultas; revisa siempre la copia final.” |
| “Sin recopilación de datos” | Contradice el nutrition label y la configuración de Firebase/RevenueCat. | “Sin tracking entre apps y sin contenido documental en la telemetría.” |

Debe existir una **matriz de claims** versionada que relacione cada frase de la app, web, screenshots, preview, metadata y soporte con una prueba técnica y una fecha de revisión. Un claim que no tenga prueba no entra en producción.

### Mejoras de seguridad recomendadas

1. Añadir un informe de verificación unificado para PDF **e imagen**. Hoy la imagen se exporta y limpia metadatos, pero no expone el mismo reporte de verificación que el PDF.
2. Ampliar la verificación de PDF: XMP y metadatos adicionales, objetos/streams, texto fuera de las regiones protegidas y pruebas de extracción con más de un lector.
3. Mostrar límites honestos: “verificado contra estas comprobaciones”, fecha, formato y advertencia de revisión humana.
4. Añadir control de tamaño, progreso, cancelación, reintento con backoff y diagnóstico de cuota para paquetes CloudKit completos.
5. Hacer explícita la consecuencia de desactivar iCloud: la implementación elimina documentos remotos; la UI debe enseñar alcance, cantidad y confirmación inequívoca.
6. Revisar las operaciones silenciosas `try?` en bóveda, CloudKit, exportación y colas de importación. El usuario debe recibir un estado recuperable y el sistema debe registrar un error técnico sin incluir contenido privado.

## 4. Ingeniería iOS y calidad técnica

### Fortalezas

- Separación funcional razonable entre captura, OCR, editor, exportación, bóveda, nube, premium, Share Extension y widget.
- Uso de frameworks Apple adecuados: Vision/VisionKit, CloudKit, Keychain, File Protection y SwiftUI.
- Preflight local y remoto correcto para plist, entitlements, privacy manifests, URLs legales, ATS y residuos de build.
- La configuración de App Store Connect y productos comerciales está suficientemente madura para operar 1.0.8.

### Riesgos técnicos

- Hay varios singletons/global managers y archivos de tamaño excesivo. Por ejemplo, `HomeView.swift`, `CaptureOCRServices.swift`, `CaptureReviewViews.swift`, `SettingsDestinationViews.swift` y `AppState.swift` concentran cientos o más de mil líneas. Esto aumenta el coste de cambios, regresiones y revisión.
- Se localizaron force unwraps en `CloudSyncManager.swift`, `CaptureOCRServices.swift` y `WatermarkConfigView.swift`. Aunque algunos están protegidos por lógica previa, deben convertirse en optional binding o errores tipados.
- CloudKit serializa paquetes completos de documentos con imágenes. Sin guardas de tamaño, streaming, progreso y política de reintento, el riesgo aumenta con documentos multipágina y redes inestables.
- La prueba `AGENT_NAME=CODEX make test` terminó con status 65 por archivos sidecar `._*` dentro de `build/cache/CODEX`, al compilar `third_party_IsAppEncrypted`. Se observaron 50 sidecars. Es un problema de higiene/reproducibilidad del caché, no evidencia de un fallo funcional de MaskID, pero bloquea la confianza en CI local.
- Hay estados `stale` en recursos de localización; se debe completar una exportación/importación de strings y una revisión nativa de español e inglés.

### Plan de arquitectura

**Ahora:** corregir errores silenciosos, unwraps, límites CloudKit y verificación de imagen.  
**Después:** extraer módulos `Capture`, `Redaction`, `Export`, `Vault`, `Sync`, `Billing` y `Telemetry` con protocolos pequeños y dependencias inyectables.  
**Más adelante:** separar estado de navegación de estado de dominio, reducir singletons y crear fixtures de documentos sintéticos para tests, screenshots y App Review.

El objetivo no es reescribir la app: es que cada parte crítica pueda probarse sin cámara, iCloud, RevenueCat ni red real.

## 5. UX/UI, accesibilidad y localización

### Correcciones de alta prioridad en screenshots

- **Screenshot 04 — Auto-detection:** muestra “No image available” y un estado donde solo 2 de 7 campos están protegidos. Es una señal visual de fallo. Regenerar con un fixture determinista y un estado “sugerencias listas para revisar”.
- **Screenshot 06 — Vault:** sustituir “HARDWARE ENCRYPTION” y “ZERO CLOUD SERVERS” por copy compatible con la implementación.
- **Screenshot 07 — Library:** sustituir “always offline” por una afirmación que admita las funciones opcionales de nube/proveedores.
- **Screenshot 10 — Export:** retirar “CERTIFIED PRIVACY” y la garantía absoluta de no recuperación; presentar el resultado como exportación aplanada y verificada.
- Revisar truncamientos de subtítulos en batch y el tamaño de textos/controles del editor iPad.
- Reordenar las primeras cinco imágenes para narrar resultado: identidad protegida → importación → revisión OCR → exportación verificada → bóveda. Dejar batch, estilos y funciones avanzadas después.
- Crear una serie iPad comercial completa, no solo home/editor: captura, revisión, exportación y batch.
- Crear preview en español y registrar la procedencia local de cada asset.

### Accesibilidad

Antes de declarar prestaciones en ASC hay que verificar en dispositivo real:

- VoiceOver en onboarding, captura, lista de sugerencias, editor, paywall y exportación;
- Dynamic Type hasta tamaños grandes sin truncar acciones críticas;
- contraste y estados de color que no dependan solo del color;
- objetivos táctiles, rotación, teclado/trackpad y split view en iPad;
- reducción de movimiento y lectura de estados de progreso/error;
- localización de números, precios, pluralización y términos legales.

El resultado debe ser una checklist reproducible y una declaración de accesibilidad coherente con la ficha.

## 6. ASO, posicionamiento y ficha comercial

### Metadata

La metadata actual pasa los límites y está mejor alineada en inglés y español. Para la próxima iteración:

- Mantener el beneficio principal en nombre/subtítulo; evitar que keywords repitan términos ya indexados.
- Retirar `id` de las keywords inglesas por ser demasiado corto y de poco valor semántico; probar términos de intención como `redact`, `pii` o `pdf` solo tras revisar volumen y competencia en Search Ads.
- No introducir “certified”, “secure enclave”, “100% offline”, “zero cloud” ni garantías legales/absolutas.
- Escribir la descripción por casos de uso: DNI/pasaporte, trámites, contratos, comprobantes, recursos humanos y documentación de alquiler/viaje.
- Mantener una sección visible de límites del detector automático y revisión final humana.
- Alinear cada locale con la política de privacidad real; en particular, no decir “sin recopilación” si se mantienen Analytics, Crashlytics y RevenueCat.

### Ficha pública y confianza

La ficha pública estadounidense ya refleja una redacción más precisa; la española observada no. Este desfase es prioritario porque erosiona la confianza justo en el mercado de idioma nativo de la app. La comprobación final debe hacerse en tres capas: ASC web, URL pública del storefront y dispositivo/App Store con locale español.

La ficha indica iOS/iPadOS 18.0+, 154,2 MB, categoría Utilities, edad 4+ y Mac no verificado. Hay que decidir si “Mac no verificado” es una oportunidad de producto futura o una superficie que no se quiere promocionar; no debe quedar como una promesa implícita.

## 7. Monetización y growth

El modelo mensual/anual/de por vida es comprensible y los productos están válidos. El paywall debe vender una progresión, no miedo:

- **Gratis:** primer flujo completo, exportación protegida suficiente para demostrar valor, límites transparentes.
- **Pro:** documentos ilimitados, batch, estilos/presets, bóveda avanzada, sincronización iCloud opcional y automatizaciones; comunicar qué permanece local.
- **Anual:** mostrar ahorro efectivo y periodo de prueba/renovación en lenguaje local.
- **Lifetime:** indicar de forma inequívoca “pago único”; separar de la suscripción visualmente.
- **Siempre:** restaurar compras, términos, privacidad, precio localizado, fecha de renovación y soporte accesible.

Instrumentar solamente eventos sin PII ni contenido documental:

`onboarding_started`, `onboarding_completed`, `import_started`, `ocr_completed`, `suggestion_reviewed`, `redaction_applied`, `export_started`, `export_verified`, `share_completed`, `paywall_viewed`, `purchase_started`, `purchase_completed`, `restore_completed`, `cloud_sync_enabled`, `export_failed`.

Embudo mínimo:

`instalación → primer import → primera máscara → primer export verificado → primera compartición → D7/D30 retorno → paywall → compra → renovación`.

Objetivos iniciales —hipótesis, no resultados actuales—: más del 60% de usuarios que importan un documento llegan a un export verificado; menos del 5% de exports falla; crash-free users >99,5%; todos los eventos están libres de OCR, imágenes, nombres, URLs y texto introducido por el usuario. Medir primero y fijar objetivos definitivos después de dos semanas de baseline.

## 8. Plan de perfeccionamiento priorizado

### P0 — 0 a 48 horas: confianza y bloqueo de release

**Responsables:** Product, Privacy/Security, ASO, Design, Release.

1. Crear matriz de claims y retirar todos los absolutismos no demostrables.
2. Regenerar screenshots 04, 06, 07 y 10 con fixtures deterministas; hacer revisión cruzada producto/seguridad/legal.
3. Comprobar y corregir la localización española publicada; repetir en ASC web, storefront público y dispositivo.
4. Confirmar manualmente App Privacy y declaraciones regulatorias en ASC web cuando la sesión esté disponible.
5. Actualizar el documento de metadata local, que todavía describe 1.0.8 como si estuviera en preparación, para que no contradiga el estado distribuido.
6. Guardar en el repositorio el manifiesto de screenshots, fixture, hash, locale y copy aprobado.

**Salida P0:** cero claims de certificación/hardware/nube absoluta; ficha pública coherente; creatives sin estados de error; evidencia de App Privacy revisada.

### P1 — 1 a 2 semanas: calidad profesional medible

**Responsables:** iOS, QA, Accessibility, Privacy, Monetization.

1. Corregir la contaminación `._*` en cachés y hacer que `make test` cree/consuma un caché limpio y reproducible.
2. Completar tests unitarios para OCR, geometría de máscaras, exportación PDF/imagen, metadatos, CloudKit conflict resolution y límites de tamaño.
3. Unificar el `ExportVerificationReport` para PDF e imagen y mostrarlo en UI.
4. Sustituir force unwraps y `try?` críticos por errores tipados, estados de retry y logging sin datos sensibles.
5. Pruebas físicas de iPhone/iPad con VoiceOver, Dynamic Type, sin red, poco espacio, documentos grandes, rotación y memoria baja.
6. Revisar paywall, restauración, compras pendientes, productos no disponibles, cancelación, trial y modo avión.
7. Decidir si Analytics arranca con consentimiento explícito o si se añade un control claro de privacidad; alinear implementación, política y nutrition label.

**Salida P1:** tests reproducibles; exportación con reporte consistente; cero errores silenciosos en caminos críticos; checklist de accesibilidad y monetización firmada.

### P2 — 2 a 6 semanas: elevar la experiencia

**Responsables:** Product, UX, iOS, Cloud, Content.

1. Reducir onboarding y posponer permisos al contexto de uso.
2. Diseñar la revisión de sugerencias como una bandeja de “pendientes” con diff original/protegido.
3. Añadir presets por caso de uso: identidad, dirección, pago, firma, viaje y contrato.
4. Hacer CloudKit resistente: límites, compresión medida, progreso, cancelación, retry/backoff, resolución de conflictos y borrado explicado.
5. Descomponer archivos y singletons por dominio sin cambiar comportamiento de una vez.
6. Crear app preview ES y campaña de screenshots iPad completa.

### P3 — 6 a 12 semanas: crecimiento defendible

**Responsables:** Growth, CRM/Support, Product Marketing, Data.

1. Crear páginas de aterrizaje por intención y locale, con ejemplos sintéticos y claims auditados.
2. Lanzar Search Ads con hipótesis de keywords, no con una lista saturada.
3. Pedir valoración solo después de un export verificado y una compartición satisfactoria; nunca interrumpir un flujo de privacidad.
4. Construir centro de ayuda con límites del detector, nube, borrado, restauración y exportación.
5. Experimentar con onboarding, orden de paywall, anual vs lifetime y presets; una variable por experimento.
6. Decidir con datos si merece la pena Mac Catalyst, no como extensión automática.

## 9. Gate de salida para la próxima versión

La versión no entra en revisión hasta cumplir todos estos puntos:

- `scripts/app_store_preflight.sh --local` y `--remote` en verde.
- `asc metadata validate --subscription-app` con 0 errores y 0 warnings.
- `asc validate` sobre la nueva versión editable sin bloqueadores; App Privacy publicada/verificada desde ASC web.
- Build archivado y auditado; `make test` en caché limpio; UI/release gate en iPhone y iPad reales.
- Ningún screenshot contiene “No image available”, estado de fallo o copy que exceda la evidencia técnica.
- Claim matrix firmada por producto, seguridad, legal/privacy y marketing.
- Export PDF e imagen con verificación consistente y pruebas de redacción de múltiples páginas.
- Crash-free users objetivo >99,5% y errores de exportación medidos; no se envía PII a telemetría.
- Accesibilidad revisada y declaración de ASC actualizada.
- Storefront EN/ES comprobado tras propagación; política, términos, soporte y suscripción enlazan a páginas válidas y localizadas.

## Conclusión

MaskID tiene una base suficientemente buena para convertirse en una referencia de “privacy-by-design” para documentos cotidianos. El salto a un nivel exquisito depende de disciplina: promesas más sobrias, verificación más explícita, menos fricción, mejores estados de error, accesibilidad demostrada y una operación de release reproducible. La prioridad inmediata es que la experiencia real, el binario, la política, las screenshots y la ficha digan exactamente lo mismo.

### Evidencia local consultada

- `Shield/Observability/FirebaseIntegration.swift` — configuración de Analytics/Crashlytics.
- `Shield/PrivacyInfo.xcprivacy` y `ShieldWidgetExtension/PrivacyInfo.xcprivacy` — manifests de privacidad.
- `Shield/Cloud/CloudSyncManager.swift` — sincronización CloudKit y paquetes completos.
- `Shield/Views/Editor/ExportServices.swift` y `Shield/Export/ExportVerifier.swift` — exportación y verificación.
- `Shield/Premium/PremiumManager.swift` y `Shield/Views/Paywall/PaywallView.swift` — productos y paywall.
- `Shield/App/ContentView.swift` y `Shield/Views/Onboarding/OnboardingSteps.swift` — shell y onboarding.
- `scripts/app_store_preflight.sh`, `Makefile`, `tasks/TASKS.md` — gates y workflow.

### Evidencia remota consultada

- App Store Connect app `6790398619`, versión 1.0.8, build `108202609071`.
- [Ficha pública española de MaskID](https://apps.apple.com/es/app/maskid-protege-tu-identidad/id6790398619).
- [Ficha pública estadounidense de MaskID](https://apps.apple.com/us/app/maskid-protect-private-data/id6790398619).
