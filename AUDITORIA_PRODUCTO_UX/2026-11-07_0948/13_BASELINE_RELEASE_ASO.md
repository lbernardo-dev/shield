# Baseline de release y ASO

Fecha de captura: 2026-11-07. Fuentes locales; ASC externo NO VERIFICADO.

| Elemento | Estado observado | Fuente / limitación |
|---|---|---|
| App / bundle | MaskID / com.romerodev.shield | Xcode project |
| Versión local | 1.1.6 | Shield.xcodeproj/project.pbxproj |
| Build local | 1162026102501 | Valor del proyecto; tarea local cita 1162026102502 en revisión, no confirmado |
| Git | main, HEAD 095776b, preexistían modificaciones y untracked | Registro del audit; no se modificó |
| Xcode | 27.2 (27B52) | xcodebuild -version |
| SDK/deployment | iOS/iPadOS, deployment 18.0 | Proyecto; no build efectivo |
| Targets/capacidades | iPhone/iPad universal; WidgetKit, Share Extension, App Intents | Proyecto; no ejecución |
| watchOS/Catalyst | No se encontró target | Inspección de proyecto |
| Paquetes | Lottie y dependencias de servicios declaradas | Resolución xcodebuild no completó |
| Localizaciones | Recursos ES y EN; idiomas adicionales no verificados | Tests/resources |
| Analítica | Firebase; collection off por defecto según integración | FirebaseIntegration.swift |
| Compras | RevenueCat y reglas locales Free/Pro | No ASC/StoreKit execution |
| Privacidad/sync | CloudKit/iCloud KVS; contador cuota replicado | PremiumManager.swift; comportamiento de cuenta no probado |
| URLs soporte/privacidad | NO VERIFICADO | No se identificó valor canónico confiable en sesión |
| Copy comercial local | 10 documentos Free; Pro amplía escala/lote/controles; exportación disponible | Docs/product facts y metadata local |
| Ficha App Store actual | NO VERIFICADO | ASC auth status error -50; búsqueda no concluyente |
| Estado de revisión | NO VERIFICADO | task 245 cita estado histórico de 25 Oct; no confirmar activo |
| Recursos de capturas | Hay ASO baseline local, pero creative assets publicados no identificados | No generar capturas |
| Métricas ASC | NO DISPONIBLES | Sin autenticación, no se consultaron instalaciones/conversión/reseñas |
| Eventos/tareas pendientes | task 247 en árbol de trabajo, WIP no confirmado | No atribuir al release |

El snapshot interno ASO de 23 Oct refiere 1.1.5, un borrador de metadata actualizado en octubre conserva 1.1.1/1.1.2 y el proyecto está en 1.1.6. Eso demuestra que el corpus local no es una fuente única actual; no demuestra el estado publicado. Próxima fase debe leer ASC y reconciliar fuentes sin modificar la ficha externa hasta la autorización correspondiente.

