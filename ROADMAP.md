# MaskID — estado y evolución del producto

> Estado del repositorio revisado el 8 de noviembre de 2026. Esta página describe código y pruebas presentes en esta rama; no acredita la versión publicada, despliegues de servicios ni resultados de uso real.

## Estado observado en el repositorio

| Área | Estado observado | Evidencia principal |
|---|---|---|
| Captura e importación | Flujos de cámara, fotos y archivos; revisión antes de guardar; cola de importación con reintento/cancelación; límites configurados de tamaño, páginas, dimensión y bytes decodificados. | `Shield/Views/Capture/`, `Shield/Views/Capture/ImportPipeline.swift`, `ShieldTests/ImportPipelineTests.swift` |
| OCR y máscaras | OCR local, sugerencias por plantilla/evidencia, modos, perfiles de protección, máscaras manuales y revisión humana. La exactitud de detección requiere corpus representativo y no se deduce de que existan reglas o tests. | `Shield/OCR/`, `Shield/Models/RedactionPresets.swift`, `Shield/ViewModels/EditorViewModel.swift` |
| Exportación | Salida rasterizada y verificación posterior de la copia; la prueba sintética de extremo a extremo cubre la ruta principal, pero no sustituye la matriz de formatos/dispositivos ni validación de documentos reales. | `Shield/Views/Editor/ExportServices.swift`, `Shield/Export/`, `ShieldTests/Export/` |
| Bóveda | Bóveda local con autenticación biométrica/PIN y operaciones de archivo cifrado. El borrado debe confirmarse desde la interfaz; el alcance de la copia CloudKit depende de la sincronización del documento fuera de la Bóveda. | `Shield/Views/Vault/VaultView.swift`, `Shield/ViewModels/AppState.swift`, `Shield/Security/` |
| Cuota Free | Contador agregado local/Keychain que se replica como entero en iCloud KVS para reconciliar dispositivos. No se sincroniza contenido mediante esa clave. La separación entre cuentas y el modo sin red requieren validación con cuentas/dispositivos de prueba. | `Shield/Premium/PremiumManager.swift`, `Docs/PRIVACY_POLICY_PRODUCT_FACTS.md`, `Docs/legal/privacy.html` |
| Atajos de sistema | App Intents y App Shortcuts para iniciar captura y abrir la Bóveda autenticada; no hay un intent de procesamiento por lotes configurado por perfil. | `Shield/App/ShieldAppIntents.swift` |
| Lotes y perfiles | Hay flujo local de lote con cola de revisión y perfiles configurables. Esto no equivale a automatización de carpetas en segundo plano ni a una API de atajo para lote. | `Shield/Views/Home/HomeView.swift`, `Shield/Models/Document.swift`, `Shield/Models/RedactionPresets.swift` |
| iPad | El target incluye iPhone e iPad y hay navegación/adaptación de tamaño regular. Apple Pencil/PencilKit, ventanas simultáneas y comparación de proyectos en Stage Manager no se acreditan en el código revisado. | `Shield.xcodeproj/project.pbxproj`, `Shield/App/ContentView.swift`, `Shield/Views/Editor/EditorView.swift` |
| Calidad y accesibilidad | Hay pruebas Swift Testing/XCUITest, casos AX5 y auditorías de accesibilidad con excepciones documentadas en el informe de fase 02. No se conserva un porcentaje global de cobertura ni una certificación WCAG. | `ShieldTests/`, `ShieldUITests/`, `AUDITORIA_PRODUCTO_UX/2026-11-08_1114/16_FASE_02_EJECUCION.md` |

La aplicación procesa localmente por defecto. Cuando una persona activa la sincronización Pro de iCloud, se transfieren paquetes restaurables de documentos fuera de la Bóveda a su base privada de CloudKit. Esto no es una arquitectura “zero-knowledge” frente a Apple ni cifrado de extremo a extremo administrado por MaskID. El producto y su documentación deben mantener esa distinción.

Los límites configurados del importador incluyen 200 MB por archivo, hasta 50 páginas, dimensión máxima de 2.048 px y un presupuesto de bytes de imagen decodificada de 256 MB. Son límites de entrada del pipeline, no una medición de memoria máxima del proceso. No se afirma un límite de RAM en tiempo de ejecución sin profiling.

## Trabajo próximo, ordenado por evidencia y riesgo

### Verificación pendiente del plan de correcciones

1. Validar con VoiceOver y Voice Control la creación, selección, movimiento, ajuste, borrado y exportación de una máscara; la UI test comprueba su representación accesible, hit target, geometría de inicio e historial, pero no sustituye la operación manual con tecnologías asistivas.
2. Probar importación, cancelación y recuperación con archivos sintéticos en iPhone y iPad; los resultados del simulador no cubren cámara, Files con proveedores externos, biometría física o fallos de cuenta.
3. Probar reconciliación de cuota con dos dispositivos de la misma Cuenta de Apple, otra cuenta y sin red. Usar cuentas de prueba; no resetear el Keychain/iCloud KVS de una cuenta personal.
4. Ejecutar sesiones moderadas para la jerarquía de Home, descubrimiento de herramientas y comprensión de modos/perfiles antes de reordenar o esconder controles.
5. **Verificado en lectura el 8 nov 2026:** ASC indica 1.1.6 `READY_FOR_SALE` y build 1162026102502 `VALID`; el proyecto local aún configura 1162026102501. La relación del binario remoto con este working tree no está acreditada; reconciliar antes del próximo release. Detalle en `AUDITORIA_PRODUCTO_UX/2026-11-08_1114/13_BASELINE_RELEASE_ASO.md`.

El estado, guion y límites de esas validaciones están en `AUDITORIA_PRODUCTO_UX/2026-11-08_1114/16_FASE_02_EJECUCION.md` y `AUDITORIA_PRODUCTO_UX/2026-11-08_1114/15_GUIA_ESTUDIO_USABILIDAD.md`.

### Evolución después de completar esas verificaciones

- Evaluar detección semántica local solo después de fijar corpus, métricas de precisión/recobrado, revisión humana, presupuesto de memoria/latencia y límites de privacidad. No presentar sugerencias como garantía de que toda la PII fue encontrada.
- Añadir Atajos de lote o automatización de carpetas únicamente con un contrato claro de revisión humana, límites y resultados observables; el flujo local existente no prueba demanda ni seguridad de un flujo sin intervención.
- Investigar mejoras de lápiz/precisión en iPad y multiventana después de validar tareas reales; no describir soporte PencilKit o Stage Manager como existente.
- Mantener fuera del alcance actual macOS nativo, Vault compartida y almacenamiento de contenido sensible en servicios propios. Cualquier ampliación requerirá threat model, modelo de claves, costos y pruebas independientes.

## Criterios de decisión

- No cambiar una navegación o jerarquía basándose solo en densidad visual o preferencia interna: medir éxito de tarea, errores, tiempo, recuperación y acceso por lector de pantalla.
- No equiparar número de tests con porcentaje de cobertura, ni un build correcto con calidad de detección.
- No priorizar una función solo por ser técnicamente posible. Usar riesgo de exposición, bloqueos de tarea y evidencia de uso.
- Cada cambio de exportación o persistencia debe conservar revisión humana, Undo/Redo, manejo de errores y pruebas negativas.
- Toda afirmación de privacidad y sincronización debe coincidir con el paquete que el código realmente transfiere y con la política vigente.
