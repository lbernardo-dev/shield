# 239-remove-floating-scan-accessory

- Number: 239
- Slug: remove-floating-scan-accessory

## Notes

### Actualización 2026-10-24

- Se retiró `.tabViewBottomAccessory` de la shell y `AppTab.navigationCases` deja fuera `.capture`; la acción Scan permanece como CTA principal de Inicio y como acción contextual en el toolbar de Inicio en iPad.
- La tarjeta resumen de Ajustes es ahora el primer elemento del contenido desplazable, inmediatamente bajo el encabezado. Las secciones van después. Se añadió `settings.summary` y una prueba de orden respecto a la primera ruta.
- Se corrigió la expansión de “Modos, lote y nube”: la sección rápida posee el binding del estado expandido y solicita el scroll a la sección después del toque. Las estadísticas de biblioteca se movieron a la columna izquierda para reducir el hueco visual en dashboard regular.
- iPhone 18 Pro, iOS 27.0: 4/4 pruebas UI focalizadas pasaron (`HomePrimaryAction`, `HomeQuickAccessActions`, `SettingsClose`, `SettingsSummaryCardPrecedesAllSettingsSections`). Bundle: `/private/tmp/MaskID-239-iPhone18-AfterHomeLayout.xcresult`.
- Después se unificó el CTA principal y el botón contextual de Scan en `openDocumentIntake()` para usar el mismo presentador estable de la app. `testHomePrimaryActionOpensDocumentIntake` volvió a pasar 1/1 en `/private/tmp/MaskID-239-iPhone18-IntakeOnly.xcresult`.
- iPhone Duo, iOS 27.1: el worker XCTest informó fin de ejecución, pero Xcode no finalizó el `.xcresult` durante la recolección de diagnóstico. Otra sesión ejecutó pruebas sobre el mismo Duo y `SchoolSnap` sigue activo; esta ejecución es inconclusa y debe repetirse cuando el destino quede libre.
- iPad Pro 13-inch (M5), iPadOS 27.0: sin proceso coincidente de app en la última inspección; falta repetir las pruebas post-fix. La captura anterior confirma el resumen arriba de las secciones, pero quick-tools y toolbar contextual aún requieren verificación en la build actual.

### Cierre y hallazgo de autenticación — 2026-10-24

- Se confirmó que `tabViewBottomAccessory` ya no forma parte de la shell y que `.capture` no es un destino persistente. Las pruebas `testSettingsCloseExitsFromRootAndDestinations` verifican que la coincidencia de Scan queda en cero en Inicio, Ajustes y sus destinos; las pruebas de CTA y barra contextual verifican que siguen existiendo las entradas de captura previstas.
- Se arregló la expansión de herramientas rápidas con un único estado en `AppState`, scroll a la sección de herramientas y una prueba que espera el valor expandido y la presencia de “Lote”. Las estadísticas pasan a la columna izquierda del dashboard regular para equilibrar sus dos columnas.
- La tarjeta `settings.summary` queda al inicio del contenido de Ajustes, inmediatamente después del encabezado; la prueba compara su orden con la primera ruta de sección.
- La inspección encontró un bloqueo al reabrir la app tras omitir PIN: el coordinador partía siempre como no autenticado y el auto-lock podía pedir un PIN nunca configurado. Se ajustó `AppSessionCoordinator`: el inicio y el auto-lock requieren un método realmente utilizable (PIN o biometría habilitada y disponible); en ausencia de ambos el espacio de trabajo se abre sin PIN. La Bóveda mantiene sus controles de autenticación propios. `SecurityPrivacyTests`: 13/13 aprobados.
- Validación final con la build recompilada: iPhone 18 Pro (iOS 27.0) 4/4 UI focalizadas; iPhone Duo (iOS 27.1) 5/5; iPad Pro 13-inch (M5, iPadOS 27.0) 4 aprobadas y 1 omitida por tratarse de un layout exclusivo de Duo. Resultado de iPhone: `/private/tmp/MaskID-239-iPhone18-Final-Focused.xcresult`; Duo: `/private/tmp/MaskID-239-Duo-OptionalPIN-Final.xcresult`; iPad: `/private/tmp/MaskID-239-iPad-OptionalPIN-Final.xcresult`; unitarios: `/private/tmp/MaskID-239-iPhone18-SecurityPrivacy-Tests.xcresult`.
- Revisión visual directa en iPhone 18 Pro mostró Inicio accesible sin PIN y sin botón Scan persistente. La visualización directa de Duo vía captura de `simctl` no estuvo disponible; las pruebas UI sí se ejecutaron en el Duo y pasaron. iOS/Xcode registró avisos de SDK/runtime (`invalidDigitCount` del build y duplicación de clases de accesibilidad) sin fallos en las pruebas.
- Apple Watch: el proyecto no contiene target/scheme watchOS instalable; no se pudo emparejar ni ejecutar un componente de reloj.
- No se borraron artefactos ni temporales; se conservan los `.xcresult` citados y el estado de Git.

