# Auditoría integral de MaskID — 2026-10-16

## Alcance y método

Revisión estática de persistencia, ciclo de vida de documentos, importación/exportación y controles de privacidad. Consulta de solo lectura a App Store Connect (Analytics y TestFlight). No se modificó código de producto ni se ejecutaron builds o pruebas; la tarea era una auditoría previa a decidir correcciones.

## Hallazgos priorizados

### P1 — Los metadatos del documento y el OCR se persisten también en JSON legible

`DocumentStore` guarda el `DocumentItem` entero con `JSONEncoder` y `Data.write` sin pasar por `SecureFileStore`, en `Documents/shield_documents/<id>.json` ([DocumentStore.swift:15-18, 59-69](../../Shield/Models/DocumentStore.swift)). `DocumentFields` incluye número, nombre, fecha de nacimiento, dirección, MRZ, OCR de páginas, texto completo y evidencia de OCR ([Document.swift:113-160, 222-246](../../Shield/Models/Document.swift)). `AppState.persistDocuments()` hace esa escritura y luego una segunda escritura cifrada del archivo maestro ([AppState.swift:839-845](../../Shield/ViewModels/AppState.swift)). Por tanto, la copia granular permanece fuera del cifrado a nivel de app, aunque iOS pueda aplicar Data Protection al contenedor.

**Impacto:** una copia extraíble del contenedor puede exponer datos personales reconocidos por OCR; el Vault tampoco convierte esos JSON en almacenamiento cifrado.

**Corrección:** fijar un único almacén canónico cifrado; migrar el formato granular y el maestro con lectura compatible, verificación de decodificación/round-trip y escritura confirmada antes de retirar copias antiguas. No borrar el origen de una migración fallida.

**Verificación:** usar datos sintéticos con marcadores únicos (nombre, MRZ y dirección), comprobar que ningún archivo persistido contiene esos marcadores en claro, que el round-trip conserva los datos y que documentos del Vault siguen legibles solo mediante el almacén protegido.

### P1 — Borrar documentos no borra su JSON; pueden reaparecer al abrir la app

`deleteDocument` y `deleteAllDocuments` eliminan imágenes y actualizan la lista en memoria, pero luego solo llaman a `persistDocuments()` ([AppState.swift:524-533, 558-573](../../Shield/ViewModels/AppState.swift)). `saveAllDocuments` escribe lo que recibe y no elimina ficheros ausentes ([DocumentStore.swift:81-87](../../Shield/Models/DocumentStore.swift)); al iniciar, `loadAllDocuments()` vuelve a leer todos los JSON encontrados y `AppState.loadDocuments()` los prefiere cuando hay alguno ([DocumentStore.swift:29-54](../../Shield/Models/DocumentStore.swift), [AppState.swift:880-906](../../Shield/ViewModels/AppState.swift)). Existe `DocumentStore.deleteDocument(id:)`, pero el flujo de `AppState` no lo invoca.

**Impacto:** el usuario puede creer que eliminó documentos sensibles cuando persisten y reaparecen tras relanzar la app. Esto también contradice la expectativa de “eliminar todo”.

**Corrección:** resolver junto con el almacén cifrado: hacer transaccional el borrado de metadatos, originales, derivados y referencias cloud; `deleteAll` debe dejar vacíos los almacenes locales canónicos y legados.

**Verificación:** importar un documento sintético, borrarlo desde el flujo real, reconstruir el estado y confirmar que no reaparece y que ningún fichero asociado queda en disco; repetir con “eliminar todo” y con Vault.

### P1 — Se puede compartir el resultado aunque queden detecciones sensibles pendientes

El informe distingue `isVerified` de `isReadyToShare`: el segundo exige cero detecciones restantes. La interfaz muestra un aviso y el recuento ([ExportFormViews.swift:299-311, 348-353](../../Shield/Views/Editor/ExportFormViews.swift)), pero tras generar el archivo se entra al estado de finalización ([ExportSheetView.swift:331-347](../../Shield/Views/Editor/ExportSheetView.swift)) y el botón de compartir invoca directamente el share sheet ([ExportSheetView.swift:184-202](../../Shield/Views/Editor/ExportSheetView.swift)).

**Impacto:** una persona puede compartir en un toque pese a que la propia comprobación indica que hay datos detectados visibles; el aviso puede pasar inadvertido. La exportación puede ser intencional, pero la consecuencia de privacidad merece una decisión explícita.

**Corrección:** con detecciones pendientes, destacar “Revisar campos restantes” y requerir confirmación expresa antes de “Compartir de todos modos”, mostrando el número de detecciones. Permitir continuar si la persona decide mantener esos campos.

**Verificación:** probar cero detecciones, una o más detecciones y campos mantenidos intencionalmente; validar el orden de acciones, VoiceOver y traducciones.

### P2 — Errores de escritura se silencian y la interfaz puede aparentar que guardó

`persistDocuments()` usa `try?` para codificar/escribir y actualiza el widget sin comunicar el resultado ([AppState.swift:839-845](../../Shield/ViewModels/AppState.swift)). `DocumentStore.saveDocument` captura el error y solo lo registra; su API no devuelve éxito/fallo ([DocumentStore.swift:59-69](../../Shield/Models/DocumentStore.swift)).

**Impacto:** disco lleno, protección de datos no disponible u otro error de E/S puede dejar estado en memoria distinto del estado que sobrevivirá al cierre de la app.

**Corrección:** hacer que la persistencia devuelva un resultado tipado y solo mostrar éxito después de confirmar la escritura cifrada; ofrecer reintento y conservar una señal de cambios pendientes.

**Verificación:** inyectar fallos de escritura en una implementación de almacenamiento de prueba y comprobar que la UI no informa éxito, que el usuario puede reintentar y que una escritura normal persiste tras reconstruir el estado.

### P2 — La exportación de PDF importado se rasteriza a resolución de previsualización

La importación limita cada página a 2.048 px ([ImportPipeline.swift:32-36, 77-108](../../Shield/Views/Capture/ImportPipeline.swift)); `CaptureView` persiste esas páginas en `pageFileNames` ([CaptureView.swift:548-591, 672-691](../../Shield/Views/Capture/CaptureView.swift)). El exportador prioriza `pageFileNames` y solo usa el PDF original si no hay imágenes de página ([ExportServices.swift:42-58, 78-103](../../Shield/Views/Editor/ExportServices.swift)). Así, el PDF original guardado no evita la rasterización en la exportación normal.

**Impacto:** texto fino puede verse borroso al ampliar o imprimir; elegir una escala de salida mayor no restaura detalle que se descartó al importar.

**Corrección:** mantener el PDF original como fuente de renderizado y aplicar redacciones/ajustes al renderizar cada página a la resolución de salida. Conservar la ruta actual para documentos que no tengan PDF fuente.

**Verificación:** comparar exportaciones de PDFs con texto pequeño y líneas finas a varias escalas; comprobar legibilidad, aplicación de máscaras y watermark, y uso de memoria en documentos de 1, 20 y 50 páginas.

### P2 — Reducir fricción inicial y medir activación antes de añadir más funciones

El onboarding actual recorre siete pantallas ([OnboardingFlowView.swift:96-106](../../Shield/Views/Onboarding/OnboardingFlowView.swift)); la analítica de App Store Connect del periodo visible de 90 días mostró una muestra inicial reducida (14 descargas por primera vez y conversión de ficha del 4,81%). No es evidencia suficiente para concluir que onboarding cause abandono.

**Oportunidad:** mostrar antes un resultado útil —por ejemplo, una demo breve de importación, detección y redacción— y aplazar solicitudes/permisos que no sean necesarios para ese primer valor. Instrumentar pasos completados y tiempo hasta primera exportación protegida, con consentimiento y privacidad respetados.

**Verificación:** experimento de onboarding con métricas de activación y finalización por cohorte; no tomar decisiones con la muestra actual sin acumular volumen suficiente.

## App Store Connect — crash report solicitado

- En Analytics > Usage > Errors, tanto el intervalo visible de 90 días (2026-07-17 a 2026-10-14) como el intervalo desde el lanzamiento mostraron “No hay datos suficientes”; la tabla por versiones tenía valores `–`. Esto **no demuestra ausencia de crashes** ni permite identificar causa, versión afectada o stack trace.
- En TestFlight, los builds 1.1.4 `1142026101302` y `1142026101301` no tenían grupo, instalaciones ni errores visibles. El build 1.1.3 `1132026100801` mostraba 2 instalaciones internas y errores `–`; tampoco aporta un informe individual.
- La consulta de API con `asc` no pudo autenticarse desde CLI porque Keychain devolvió `One or more parameters passed to the function were not valid. (-50)`. La consulta de navegador a ASC sí permitió ver los datos agregados anteriores. No se hizo ningún cambio en App Store Connect.
- Para hacer triage del crash hace falta el `.ips`/`.crash` original o el stack trace/evento de Crashlytics con versión, modelo y versión de iOS. Sin ese artefacto no es fiable atribuir el crash a un subsistema concreto.

## Orden recomendado

1. Corregir almacenamiento cifrado y borrado en una misma migración segura; son los dos riesgos más graves para privacidad y confianza.
2. Añadir protección de confirmación en la ruta de compartir cuando quedan detecciones visibles.
3. Resolver errores de persistencia y mejorar la fuente/resolución de exportación PDF.
4. Recibir el `.ips`/stack trace para una investigación de crash basada en evidencia y revisar activación con más datos.

## Límites de la auditoría

Revisión estática y consulta de consola; no se ejecutaron builds, pruebas ni simuladores. No se inspeccionó un crash individual porque no había muestra suficiente ni informe descargable visible. No se hizo limpieza de artefactos. Las modificaciones locales preexistentes del directorio Marketing y `scripts/clean.sh` se conservaron.
