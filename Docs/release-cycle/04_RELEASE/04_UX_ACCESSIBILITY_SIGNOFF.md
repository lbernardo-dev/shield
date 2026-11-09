# Sign-off de producto, UI/UX y accesibilidad

## Propósito y tarea primaria

MaskID prepara una copia de documentos de identidad, formularios e imágenes/PDF para compartir: importar o escanear, elegir las zonas que se ocultan, revisar cada página y comprobar la copia exportada. El usuario conserva el original y decide cada máscara. La comprobación ayuda a detectar texto/metadatos residuales, pero no demuestra que se hayan seleccionado todas las zonas sensibles.

## Experiencia y complejidad

- Home presenta una acción primaria de protección y accesos a documentos, Bóveda y herramientas. XCTest verifica nombre/área táctil, búsqueda local y navegación contextual en iPhone.
- Importación, revisión de máscaras, deshacer y exportación verificada tienen cobertura UI con archivo sintético; la ejecución más reciente incluye Dynamic Type AX5 y ajustes de movimiento/transparencia/contraste.
- La edición avanzada expone varias herramientas en una fila desplazable. En iPhone Duo la fila necesita desplazamiento físico para llegar a Auto; el test se ajustó a un gesto lento con retención, no se ocultó el control. La prueba de pantalla exterior plegada no se puede dar por aprobada porque Simulator dirige la escena al display interior.
- Preferencias de tema se encuentran en Settings. Los tests de captura en iPhone 18 Pro Max y iPad Pro de 13″ confirmaron MaskID Original y Never use seasonal themes en ambos locales. Se conservaron capturas y evidencia del tema en ambos formatos. Home 1.1.7 muestra el encabezado de biblioteca parcialmente cubierto por la barra flotante; queda como problema visual P2 y se excluyó del set ASO.
- El esquema, accesos y documentos siguen disponibles en inglés (EE. UU.) y español (España). No se encontraron otras traducciones completas de ficha.
- No se detectó una calle sin salida principal en los casos automatizados ejecutados. El bloqueo/restore sin catálogo, flujos físicos de permisos y sincronización real aún precisan validación externa.

## Matriz de cobertura

| Área | Evidencia | Estado |
|---|---|---|
| Home, primer acceso y onboarding | Suite final: 236 PASS, 7 SKIP, 0 FAIL; XCResult de 1.1.7 en el reporte de build | PASS automatizado |
| Importar, editar, deshacer y exportar | testSyntheticFileImportAccessibleMaskUndoAndVerifiedExportAtAX5 | PASS automatizado con datos de prueba |
| Búsqueda OCR local | testHomeSearchFindsLocalOCRTextWithoutShowingUnmatchedDocuments | PASS automatizado |
| iPad 13″ horizontal | dos tests focalizados, toolbar y paywall | PASS automatizado |
| iPhone Duo editor | editor/tools pasa en corrida focalizada; layout exterior plegado omite por display incorrecto del simulador | PARCIAL |
| Dynamic Type, etiquetas y objetivos táctiles | AX5, reduce motion/transparency y contraste en UI suite | PASS automatizado |
| Tema base de capturas | `testASOCaptureScreensUseBaseThemeInBothStoreLocales`: XCResults 19:31:10 (iPhone 18 Pro Max) y 19:34:30 (iPad 13″); Settings confirma tema y preferencia estacional en ambos locales | PASS 1/1 por dispositivo; evidencia raw preservada |
| Home, barra flotante y jerarquía | Captura es-ES-home del build 1172026110801 en `11_SCREENSHOTS_AND_PREVIEWS/raw/iphone-6.9/build-1172026110801/manifest.json` | P2 observado: el encabezado de biblioteca queda bajo la barra al abrir Home |
| VoiceOver real, Control por voz, Switch Control/Zoom | no se usó hardware/asistencia real | NOT RUN |
| Sync CloudKit, offline y conflicto | requiere cuenta aislada y otro dispositivo | NOT RUN |
| Creatividades ASO iPhone 1.1.7 | 20 PNG compuestos, 10 por locale; 1320 × 2868; SHA-256 verificado, fuentes con tema base confirmado; 20 colocaciones ASC activas | PASS local y ASC; assets `PREPARE_FOR_SUBMISSION` |
| Creatividades ASO iPad 1.1.7 | 20 PNG compuestos, 10 por locale; 2064 × 2752; SHA-256 verificado, fuentes con tema base confirmado; 20 colocaciones ASC activas | PASS local y ASC; assets `PREPARE_FOR_SUBMISSION` |

Resultado: sign-off parcial. No hay fallo P0/P1 de interfaz observado en la suite ejecutada; no se certifica accesibilidad física ni Duo plegado. El estado global queda BLOCKED por gates jurídicos, pagos y privacidad, no por una aprobación visual presumida.
