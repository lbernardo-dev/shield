# 223-correcciones-prioritarias-auditoria

- Number: 223
- Slug: correcciones-prioritarias-auditoria

## Notes

### Implementación

- `AppState` usa ahora `Application Support/documents.json` como fuente canónica única y lo escribe mediante `SecureFileStore` (AES-GCM). Verifica que el archivo tenga el encabezado cifrado y que el round-trip devuelva los mismos bytes antes de retirar metadatos legados.
- La migración admite el maestro antiguo y los JSON por documento. Los JSON granulares legados se leen a través de `SecureFileStore` y se vuelven a escribir cifrados; ante un error de lectura/escritura no se borran los archivos fuente. Si el maestro válido es más antiguo que un registro granular (posible cierre entre las dos escrituras de versiones anteriores), se intenta recuperar ese registro comparando fechas de modificación antes de limpiar el formato antiguo.
- `deleteDocument` y `deleteAllDocuments` persisten y verifican primero el nuevo snapshot; si falla la escritura, restauran la lista y conservan los ficheros del documento. Tras una escritura correcta, se retiran las referencias legadas y se borran los recursos asociados.
- Compartir una exportación con detecciones pendientes abre una confirmación localizada en inglés y español con el recuento, opción para volver al editor y opción destructiva explícita para compartir igualmente. En exportación rápida desde Vault, “Revisar campos” abre el editor al cerrar la hoja.

### Verificación

- `ShieldTests`: 118 pruebas pasadas en iPhone 18 Pro, iOS 27.0.
- `ShieldUITests` en iPhone 18 Pro: 149 pruebas pasadas, 2 omitidas y 1 fallo. Falló `testPrimaryTabNavigationAndCaptureDismissal` en `ShieldUITests/ShieldLaunchTests.swift:280`: tras volver de Ajustes y tocar `tab.capture`, no apareció `capture.close`. El test independiente de captura sí pasó. Xcode agotó su espera de 600 s al recopilar diagnósticos; el paquete fue `/private/tmp/MaskID-223-iPhone18Pro.xcresult` y se movió a la Papelera al cerrar la sesión.
- `testPaywallControlsRemainVisibleInIPadLandscape`: pasado en iPad Pro 13-inch (M5), iOS 27.0, UDID `2F44FF69-62E3-471E-AFEB-6690BDA4ADC1`. Xcode instaló y lanzó la build en ese simulador; el resultado `/private/tmp/MaskID-223-iPadPro13M5.xcresult` se movió a la Papelera al cerrar la sesión.
- Tras ajustar el mensaje singular/plural: compilación genérica de iOS Simulator, `swiftc -frontend -parse`, validación JSON del catálogo y `git diff --check`: correctos.
- Revalidación final en iPhone 18 Pro, iOS 27.0, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`: `testExportAccessibilityInEnglishAndSpanish` pasó (1/1); la app quedó instalada en ese UDID.
- Revalidación del recorrido general: `ShieldTests` pasó 118 pruebas; `ShieldUITests` ejecutó 34 casos en iPhone (32 pasaron, 1 se omitió por iPad y 1 falló en `testPrimaryTabNavigationAndCaptureDismissal`, línea 280). El fallo ocurrió tras volver de Ajustes y tocar el botón de escaneo, cuando `capture.close` no apareció. El test aislado `testCaptureGuideCanToggleAndDismiss` sí pasó. Xcode agotó la espera de 600 s al recopilar diagnósticos; no se observó un crash de la app.
- En la última localización, la suite completa no se repitió por coste; se compilaron todos los targets del esquema de forma genérica y se ejecutó la suite de exportación localizada en el iPhone obligatorio.
- `iPhone Duo` no aparece en el inventario disponible. No hay destino/watch app en el proyecto, por lo que no procede emparejar un Apple Watch.
- Un primer `xcodebuild -list` no llegó a resolver paquetes porque el sandbox bloqueó escrituras en las cachés globales de Xcode. El `.xcresult` temporal generado en `/var/folders/9s/t5s1r6tj1vz7fmd90ls1xqq40000gn/T/ResultBundle_2026-16-10_08-43-0053.xcresult` se movió a la Papelera al cerrar la sesión.

### Seguimiento de Crash Triage en App Store Connect — 2026-10-16

- La autenticación de `asc` ya responde correctamente. App: `MaskID: Protects files and IDs`, bundle `com.romerodev.shield`, ASC ID `6790398619`.
- El último build procesado es `1.1.4 (1142026101302)`, UUID `38dec38a-eaf0-4bbe-bade-6004abf5188d`, estado `VALID`, subido el 2026-10-13.
- `asc testflight crashes list`: 0 informes. `asc performance diagnostics list` para el build: 0 diagnósticos. `asc testflight feedback list`: 0 entradas.
- No hay stack trace individual disponible en los datos actuales de App Store Connect; queda pendiente solo si el informe que recibió el usuario está en otro canal o aún no se ha sincronizado. En ese caso hace falta el `.ips`/`.crash` original o el evento de Crashlytics para atribuir causa.
