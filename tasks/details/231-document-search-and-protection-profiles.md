# 231-document-search-and-protection-profiles

- Number: 231
- Slug: document-search-and-protection-profiles

## Notes

## Objetivo

Completar el descubrimiento y la repetición de políticas sin subir texto OCR ni aplicar automatizaciones sin confirmación. La búsqueda actual filtra títulos; RedactionPreset.custom pone una marca de agua y termina sin guardar una política.

## Implementación

- Añadir búsqueda en la biblioteca y el documento sobre evidencia OCR guardada por página. Si un documento antiguo sin texto OCR se consulta, ejecutar OCR local con debounce, mantener índices de página incluso si falta una imagen y guardar la evidencia dentro del snapshot cifrado del documento; la Bóveda no entra en el trabajo.
- Normalizar mayúsculas, diacríticos, espacios y saltos de línea; aceptar frases/listas propias y después patrones acotados, con límites de tiempo.
- Mostrar coincidencias con página, caja y confianza; ocultar los fragmentos de OCR por defecto y revelarlos solo con una acción explícita en el inspector. El texto revelado y las cajas no entran en analítica.
- Guardar perfiles editables en un archivo AES-GCM a través de `SecureFileStore`; migrar el formato previo de `UserDefaults` solo después de verificar escritura y lectura cifradas. Si el archivo protegido no se puede leer, las operaciones de escritura fallan sin reemplazarlo con datos predeterminados.
- Los perfiles configuran entidades a ocultar, estilo gratuito permitido, marca de agua y salida PDF rasterizada o imagen de la página actual. Las reglas se aplican sobre evidencia real de la página activa; no se guardan rectángulos como plantilla.
- El editor permite crear, editar, renombrar, duplicar, seleccionar y eliminar perfiles; mantiene visible cuál está activo. Las máscaras siguen necesitando revisión antes de exportar.
- Un perfil nuevo parte de la política de privacidad conservadora ya incluida en MaskID y permite ajustar las entidades antes de guardarlo, evitando empezar con una configuración vacía.
- Cuando crop, rotación, espejo o geometría de escaneo cambia la imagen, se invalidan observaciones OCR espaciales y texto indexado antiguo; el editor vuelve a calcular la evidencia local antes de ofrecer coincidencias nuevas.

## Límites

- No se persiste un índice separado: la evidencia OCR se conserva en el modelo documental cifrado y se puede reconstruir a partir de sus imágenes.
- Esta iteración acepta frases, listas con coma/punto y coma/salto de línea y variantes normalizadas; no implementa todavía diccionarios persistentes del usuario ni expresiones regulares.
- La Bóveda no se busca ni se indexa, aunque sus tarjetas pueden seguir apareciendo en la lista normal enmascarada según el diseño existente.
- La verificación de compilación, suites y flujos en simulador está pendiente para la matriz final.

## Gate final — 2026-10-21

- La build y `ShieldTests` pasaron en los tres UDID de la matriz: 147 tests aprobados, 0 fallos y una integración RevenueCat omitida por su variable de activación en cada destino. La cobertura incluye búsqueda local y persistencia del perfil cifrado.
- El gate UI no terminó por la resolución de debugger de Xcode (`noURL`); las interacciones de crear/editar perfiles y localizar resultados deben repetirse cuando el runner UI vuelva a funcionar. La app no implementa sincronización de perfiles entre dispositivos, así que no existe una sesión compartida que validar en simuladores.

## Reintento de matriz — 2026-10-25

- `testHomeSearchFindsLocalOCRTextWithoutShowingUnmatchedDocuments` y `testCustomProtectionProfileExposesItsCompleteSafePolicy` se incluyeron en la suite UI focalizada del iPhone 18 Pro para comprobar la interacción sobre el source actual.
- Al iniciar, apareció el runner ajeno `com.romerodev.repsfitness.uitests.xctrunner` en el UDID obligatorio. Se canceló exclusivamente el `xcodebuild` iniciado por esta tarea para evitar dos runners en el mismo simulador. El resultado `/private/tmp/MaskID-2403-iPhone18-UI-Regressions.xcresult` quedó incompleto; estas dos pruebas no se cuentan como pasadas.
- La evidencia previa de búsqueda/OCR y almacenamiento cifrado en `ShieldTests` permanece válida; falta el gate UI completo cuando el iPhone quede libre, y después la matriz Duo/iPad. El producto no sincroniza perfiles de protección entre dispositivos; esa capacidad no está implementada ni se da por validada.

## Aceptación

- Búsquedas cubren texto OCR, acentos, separadores, saltos de línea y resultados multipágina, con evidencia correcta por página.
- Ninguna ocurrencia se enmascara hasta confirmación; la salida pasa las verificaciones existentes.
- Los perfiles se crean, duplican, renombran, editan y eliminan, y sobreviven relanzamientos/migraciones.
- Contenido sensible permanece cifrado localmente, fuera de analítica; la Bóveda bloqueada no filtra resultados ni índices.
- Localización ES/EN, VoiceOver, Dynamic Type y estados vacíos están completos.

### Revalidación UI — 2026-10-25

- Búsqueda local y perfil personalizado pasaron en iPhone 18 Pro dentro de `/private/tmp/MaskID-2403-iPhone18-RegressionMatrix.xcresult`, en Duo `/private/tmp/MaskID-2403-Duo-SearchProfile-signed.xcresult` y en iPad `/private/tmp/MaskID-2403-iPad-FeatureRegression-signed.xcresult`.
- Las pruebas focalizadas no cubren el ciclo UI completo de crear/duplicar/renombrar/editar/eliminar ni la persistencia tras relanzamiento y migración. No existe sincronización de perfiles entre dispositivos; queda fuera de la validación hasta implementar ese servicio.
