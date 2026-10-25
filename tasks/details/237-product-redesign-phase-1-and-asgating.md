# 237-product-redesign-phase-1-and-asgating

- Number: 237
- Slug: product-redesign-phase-1-and-asgating

## Notes

### Cambio posterior — 2026-10-24

- La recomendación inicial de `tabViewBottomAccessory` quedó supersedida por la petición posterior de eliminar el Scan flotante que reaparecía en Ajustes y estados vacíos. La shell actual no presenta ese accesorio ni una quinta tab; conserva la acción primaria de Inicio y el toolbar contextual de iPad. La cobertura actual está en la task 239 y `docs/iphone-duo/TEST_MATRIX.md`.
- La promesa aprobada de PIN opcional se aplicó también al relanzamiento: `AppSessionCoordinator` ya no deja un espacio de trabajo sin PIN ni biometría utilizable en una pantalla de configuración obligatoria, y no activa auto-lock si no existe método que permita recuperar el acceso. Cobertura unitaria: test de política de autenticación en la suite Seguridad y Privacidad.

## Avance — 2026-10-23

### Cambios locales

- Onboarding de tres pantallas: promesa, demo interactiva y seguridad opcional. La cámara se solicita al iniciar una captura. El consentimiento de Analytics no cubre la primera tarea; la colección sigue desactivada por defecto y se puede activar en Ajustes.
- Inicio prioriza “Proteger un documento”; accesos secundarios sin duplicar la acción principal. `TabView` adaptable y `tabViewBottomAccessory` reemplazan la tab vacía en iOS 26+; el accesorio usa `tabViewBottomAccessoryPlacement` para contraerse a icono inline y mostrar etiqueta completa expandido, conservando la etiqueta de accesibilidad. iOS 18 conserva el fallback. La acción principal usa `.glassProminent` de SwiftUI con fallback de botón prominente.
- Biblioteca con búsqueda SwiftUI nativa; `ExportVerifier` migrado a `RecognizeTextRequest` async de Vision. Tema base como selección persistente y paleta semántica estable entre temas.
- La hoja “Añadir a Bóveda” migra el último `NavigationView` a `NavigationStack`; sus filas se operan con `Button` y anuncian el estado seleccionado.
- Se añade `batch_document_review_completed`, evento agregado con el número de páginas, cuando finaliza la revisión humana de todas las páginas de un lote. El punto de envío de Analytics solo se activa con opt-in; no incluye texto ni geometría documental.
- Metadata local propuesta para 1.1.6 en `metadata/`. Se eliminó una keyword duplicada en inglés (`redact`), se sustituyó el término ambiguo `redactar` por `ocultar` en español y se retiró `anonimizar` para no prometer desidentificación completa. Validador ASC: **0 errores, 0 avisos**; límites de campos y separación de keywords verificados.
- Los prototipos de cinco pantallas siguen siendo material sintético de diseño, no capturas válidas de la build final.

### App Store Connect y adquisición

- ASC consultado únicamente en modo lectura: la versión pública 1.1.5 está `READY_FOR_DISTRIBUTION`, la revisión terminó y la última build `1152026102101` está `VALID`. Aún no existe versión remota 1.1.6. No se tocó metadata remota ni se inició una submission.
- Línea base descargada desde la solicitud existente `ONE_TIME_SNAPSHOT`; tres segmentos (descargas estándar, descubrimiento estándar y detallado) pasaron MD5 y tamaño. Los agregados y límites están documentados en `Docs/ASO_BASELINE_MASKID_2026-10-23.md`.
- No hay Astro MCP ni app tags de Apple para MaskID. Las keywords locales se presentan como hipótesis por intención, sin puntajes inventados. No se lanzó PPO ni CPP debido al tamaño bajo de muestra; los tests deben basarse en la confianza que muestre Apple.

### Build y gate pendiente

- `xcodebuild build-for-testing -project Shield.xcodeproj -scheme Shield -destination 'id=1454EA8D-A019-4B07-B57C-1433E0F21BE0' -derivedDataPath build/MaskID-Redesign-237 CODE_SIGNING_ALLOWED=NO`: **BUILD SUCCEEDED**. `git diff --check`: limpio. Aviso visible: deprecación en headers `StoreKitTest` del SDK.
- `xcodebuild -configuration Release build` también terminó correctamente con el mismo destino explícito. Ambos builds fueron de compilación solamente, con code signing desactivado; no representan el gate de instalación/ejecución con entitlements.
- No instalar/arrancar aún: CoreSimulator no respondió en la primera lectura; luego el inventario y los procesos se consultaron con comandos `simctl` de solo lectura. iPhone 18 Pro `1454EA8D-A019-4B07-B57C-1433E0F21BE0` (iOS 27.0) está booted con `com.upledger.app` activo; la tarea 211 también espera a que quede libre. iPhone Duo `BF5C28D6-2B6D-46FC-82E8-9A248F5C0186` (iOS 27.1) e iPad Pro 13-inch M5 `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1` (iPadOS 27.0) mantienen procesos de otras apps, incluido MaskID. No se instalaron apps ni se interrumpieron sesiones.
- La compilación no ejecuta tests. El gate final sigue pendiente: comprobar el estado libre del iPhone 18 Pro, instalar/probar esa build, continuar Duo e iPad, verificar permisos/onboarding/búsqueda/revisión/exportación/tema/accesibilidad, y registrar captura de tema base. No existe target watchOS ni runtime iOS 18.

### API Apple aplicada

- Controles nativos `NavigationStack`, `TabView`, toolbar y `.searchable` dejan al sistema presentar su Liquid Glass. `tabViewBottomAccessory` mantiene una acción cercana a navegación sin simular un destino de tab.
- `.glassProminent` se reserva para la acción primaria; el contenido de documentos y resultados sigue opaco. La guía actual de Apple recomienda limitar el vidrio a controles de alta prioridad y probar Reduce Transparency/Reduce Motion.
- `RecognizeTextRequest` unifica la API Swift async de Vision que ya usa Captura con la verificación OCR de la salida exportada. No se añade `RecognizeDocumentsRequest` hasta medir mejora y precisión en un corpus consentido.

### Reauditoría del objetivo — 2026-10-23, 05:52 UTC

- Releído el plan integral y los registros 226, 229 y 231–234. La implementación de navegación, primera sesión, cola por página, fidelidad PDF, búsqueda local, perfiles y sugerencias de rostros está en el árbol. El PDF seleccionable permanece en no-go hasta contar con reconstrucción y verificador adversarial; los diccionarios/regex, Mac y colaboración siguen siendo propuestas condicionadas a evidencia de demanda, como especifica la fase 4.
- La suite UI del árbol contiene `testShortOnboardingDeliversHomeWithoutEarlyPermissionOrPaywall`, `testAnalyticsConsentIsExplicitAndOffByDefault` y flujos de accesibilidad ES/EN. `build-for-testing` los compila; no hay resultado de ejecución de esta build.
- La tarea 234 ya conserva capturas creativas anteriores en AppDesigns con tema base comprobado, pero son de una build anterior y documentan un elemento de Biblioteca que queda parcialmente bajo la barra inferior. Deben renovarse desde la build instalada antes de usar el conjunto para una nueva ficha.
- A las 05:52 UTC la consulta de solo lectura confirma el proceso `com.upledger.app` (PID 14673) activo en el iPhone 18 Pro. Duo e iPad siguen teniendo procesos de otras apps. No se instala, cierra ni cambia de dispositivo hasta que cada uno quede libre, comenzando por iPhone 18 Pro.
- Fase 3 sigue a la espera de build y capturas verificadas antes de aplicar metadata en ASC; no se lanza PPO/CPP con la muestra actual. La fase 4 es deliberadamente condicional a entrevistas/retención y amenaza de privacidad, no una implementación omitida de esta tanda.
- Dos builds `build-for-testing` adicionales con signing habilitado compilaron y pasaron `codesign --verify --deep --strict`; Xcode sigue creando firma ad hoc para Simulator pese a indicar el certificado de distribución del equipo. El `.app-Simulated.xcent` contiene application-group, keychain-access-groups y CloudKit configurados; la firma Mach-O no incluye esos claims. El runtime aún debe confirmar los entitlements simulados cuando el dispositivo esté libre.

### Estado de la cola — 2026-10-23, 06:01 UTC

- La tarea activa de UpLedger terminó a las 06:01 UTC, pero una lectura inmediatamente posterior aún encuentra `com.upledger.app` en los tres simuladores y `com.romerodev.repsfitness` activo también en iPhone 18 Pro. La tarea UI de StreakReps sigue activa. El iPad conserva MaskID activo.
- Por lo tanto, el iPhone 18 Pro no está libre aunque el hilo de UpLedger haya terminado. No se modifica ni se cierra ninguna app. Se mantiene el orden de validación y se espera a que el proceso del destino principal desaparezca antes de instalar.

### Refuerzo técnico del verificador de exportación — 2026-10-23, 06:13 UTC

- Auditoría de `Shield/Export/ExportVerifier.swift`: las excepciones de Vision, los recortes no válidos y la falta de `CGImage` se ignoraban con `continue`. Como `isVerified` solo mira residual OCR/issues, un error de OCR podía producir un reporte vacío y aprobar una región sin inspeccionarla.
- Ahora el verificador acumula regiones no verificables y añade `ocr_verification_incomplete`. También rechaza geometría faltante, desfasada con `redactionsApplied` o asociada a páginas fuera del documento. Se aplica a exportación PDF e imagen; los residuos de texto siguen usando `ocr_residual_found`.
- Añadidas pruebas deterministas para fallo del reconocedor OCR en PDF e imagen y para geometría ausente. Se inyecta un reconocedor `@Sendable` solo como dependencia interna del verificador; producción sigue usando `RecognizeTextRequest` async de Vision, que Apple documenta como `async throws` ([API](https://developer.apple.com/documentation/vision/recognizetextrequest)).
- `xcodebuild -quiet build-for-testing -project Shield.xcodeproj -scheme Shield -destination 'id=1454EA8D-A019-4B07-B57C-1433E0F21BE0' -derivedDataPath build/MaskID-Redesign-237 CODE_SIGNING_ALLOWED=NO`: exit code 0; compiló app, `ShieldTests` y `ShieldUITests`, pero no ejecutó ningún test.
- Inventario actualizado de solo lectura: iPhone 18 Pro iOS 27.0 sigue con `com.upledger.app`, `com.romerodev.repsfitness` y `com.apple.testmanagerd`; Duo iOS 27.1 tiene MaskID y UpLedger activos; iPad Pro M5 iPadOS 27.0 tiene MaskID y UpLedger activos. No se instaló ni lanzó la nueva build. El test unitario y el gate de ejecución siguen esperando el iPhone 18 Pro libre.
- No se modificó ninguna vista, flujo visual, localización visible ni captura.

### Validación de la build y del detector — 2026-10-24

- El iPhone 18 Pro quedó disponible y se usó el UDID requerido `1454EA8D-A019-4B07-B57C-1433E0F21BE0` (iOS 27.0); build explícita y **18/18 tests aprobados**.
- iPhone Duo `BF5C28D6-2B6D-46FC-82E8-9A248F5C0186` (iOS 27.1): build explícita y **2/2 tests UI aprobados**. Scan se conserva en el accesorio inferior nativo, alineado al borde derecho del área de contenido cuando Duo presenta un rail lateral.
- iPad Pro 13-inch M5 `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1` (iPadOS 27.0): build explícita y salida de XCTest **2/2 aprobada**. Scan aparece en la toolbar real de Inicio; el modificador `tabViewSidebarBottomBar` no se expuso en la jerarquía accesible, así que no se dejó como vía única.
- La detección de rostro corrigió orientación, elegibilidad de documentos con imagen y separación entre caja de Vision y margen de máscara; detalle en `tasks/details/232-local-face-redaction-suggestions.md`.
- En distintos momentos XCUITest de otra app ocupó iPhone 18 Pro y iPad. Se detuvo solo esa suite cuando el destino requerido estaba ocupado, según la autorización explícita del usuario. Dos sesiones propias de Xcode quedaron esperando a cerrar logs después de informar tests completos; se terminaron esos procesos sin borrar datos.
- `Shield.xcodeproj` no contiene target watchOS, así que no hay componente instalable para Apple Watch Series 12. La matriz Watch queda pendiente por ausencia de target.
- La tarea general sigue activa por verificaciones pendientes de lotes/búsqueda/perfiles y decisiones de sincronización entre dispositivos; no se sometió una release ni se tocó metadata remota.

### Revalidación del ciclo 1.1.6 — 2026-10-25

- Fuente de la entrega: regresión focalizada en iPhone 18 Pro 7/7 (`/private/tmp/MaskID-2403-iPhone18-RegressionMatrix.xcresult`), Duo 4/4 en resultados de ajustes/cola/búsqueda/perfiles, e iPad Pro M5 4/4. La prueba localizada de Novedades pasó 1/1 en iPhone 18 Pro.
- El resumen de Ajustes aparece debajo del header y antes de las secciones; Inicio y superficies no relacionadas con captura ya no presentan el botón Scan flotante.
- Pendientes de producto/matriz: recorrido de reintento/cancelación de lote, ciclo CRUD y persistencia de perfiles, multitarea iPad, sincronización compartida y ausencia de target watchOS. El build 2501 es solo el número diario de la preparación local; la asociación de App Store Connect se lleva en la task 240 y espera autorización del usuario.
