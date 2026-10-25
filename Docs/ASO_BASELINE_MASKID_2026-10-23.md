# Línea base de adquisición de MaskID — 23 de octubre de 2026

## Estado de la ficha

- App Store Connect app: `6790398619` (`com.romerodev.shield`).
- La versión vigente observada en App Store Connect es **1.1.5**, en estado `READY_FOR_DISTRIBUTION`; su revisión aparece completada. La metadata local 1.1.6 es una propuesta y todavía no se ha aplicado a App Store Connect.
- La solicitud de Analytics disponible es `ONE_TIME_SNAPSHOT`. No es una serie continua y la fecha de procesamiento más reciente en la instantánea es **2026-10-12**.
- Se descargaron los informes `App Downloads Standard`, `App Store Discovery and Engagement Standard` y `App Store Discovery and Engagement Detailed`. Sus tres segmentos comprimidos pasaron las verificaciones de tamaño y MD5 de Apple. Los originales permanecen en el directorio privado `/private/tmp/asc-maskid-analytics.cxHvVb/` y no se incluyeron en el repositorio.

## Datos que sí se pueden afirmar

El informe estándar de descargas contiene **14 primeras descargas** en las filas disponibles del **6 de agosto al 9 de octubre de 2026**. La distribución agregada de esas 14 descargas es:

| Fuente y dispositivo | Primeras descargas |
|---|---:|
| Búsqueda del App Store · iPhone | 6 |
| Referencia web · iPhone | 3 |
| Referencia de otra app · iPhone | 2 |
| Referencia de otra app · escritorio | 1 |
| Navegación del App Store · iPad | 1 |
| Navegación del App Store · escritorio | 1 |

El informe estándar de descubrimiento registra, sumadas sus filas disponibles entre el **6 de agosto y el 12 de octubre**, **597 eventos de impresión**, **109 visitas a página** y **47 toques**. Esos son conteos de eventos desglosados por dimensiones. No los convierto en una tasa del funnel porque el denominador que Apple usa para conversión es el total de descargas dividido entre impresiones de dispositivos únicos; sumar los `Unique Counts` de filas desglosadas puede contar el mismo dispositivo en más de una dimensión.

La extracción detallada tiene nueve filas visibles, todas para impresiones de búsqueda del App Store en iPhone y Estados Unidos. Es demasiado escasa para atribuir preferencias por país, consulta o perfil de cliente. Las dimensiones y filas disponibles están condicionadas por los umbrales de privacidad de Apple.

La auditoría autenticada anterior, guardada en la tarea 222, había registrado para **17 de julio–14 de octubre** una conversión de ficha del **4,81 %** y 14 primeras descargas. Conservo ese valor como lectura del dashboard de ese intervalo; no lo recalculo con los `Unique Counts` de los segmentos descargados. El número de descargas coincide con el conteo del informe disponible, pero el periodo y las definiciones de cada extracción no son idénticos.

## Lectura del funnel

- La ficha tiene poca exposición y una muestra pequeña. El dato no permite atribuir el resultado a una pantalla concreta ni separar de forma fiable problemas de descubrimiento y de conversión.
- Seis de las 14 primeras descargas observadas atribuyen fuente a Búsqueda del App Store; las demás proceden de navegación o referencias. Mantener relevancia de metadata y página, y medir por fuente y territorio en ventanas comparables.
- La prueba más útil ahora es corregir la primera impresión y el mensaje de valor, publicar una build coherente con la ficha y medir de nuevo. No arrancar un PPO con esta muestra; Apple recomienda decidir por el estado/confianza del test y puede marcar variantes como inconclusas.
- El informe no contiene eventos internos de onboarding, importación, revisión o exportación. La calidad de activación posterior a la descarga debe medirse por separado, con consentimiento opcional y sin texto OCR, imagen, nombre de archivo, identificadores documentales ni coordenadas de máscaras.

## Auditoría local de metadata 1.1.6

La metadata está preparada en inglés estadounidense y español de España. La validación de App Store Connect para los 30 archivos canónicos devuelve **0 errores y 0 avisos**. En la propuesta 1.1.6, los nombres ocupan 26/30 y 20/30 caracteres, los subtítulos 26/30 y 25/30, y keywords 98/100 y 95/100 bytes para EN/ES. No hay duplicaciones exactas entre título/subtítulo y keywords ni separadores incorrectos; descripción, promocional y novedades respetan sus límites.

La revisión offline retiró la duplicación exacta de `redact` entre subtítulo y keywords en inglés; se sustituyó por `documents`. En español se reemplazó `redactar` —ambiguo fuera del contexto de privacidad— por `ocultar` y se retiró `anonimizar`, que puede sugerir una desidentificación total. Se amplió la descripción con términos naturales de búsqueda como documentos de identidad, IBAN y escáner, además de aclarar el límite de la censura. El contador de 100 bytes y el validador ASC se volvieron a ejecutar después del cambio.

No hay Astro MCP conectado ni etiquetas de descubrimiento de Apple para esta app, así que esta propuesta no asigna popularidad, dificultad ni ranking estimado a palabras clave. El análisis de keywords es una hipótesis editorial basada en los trabajos reales de la app, no una lectura de volumen de búsqueda.

## Próximo ciclo de medición

1. Tras aprobar y publicar una build con claims coincidentes, volver a leer el dashboard de App Analytics en una ventana completa de 90 días y registrar impresiones únicas, visitas únicas, descargas totales, primeras descargas, conversión y cortes por fuente/territorio/dispositivo.
2. Registrar la fecha de release, metadata y cambios de capturas junto al baseline para evitar atribuir a UI variaciones debidas a fuente, territorio o disponibilidad de la nueva versión.
3. Medir la primera importación, revisión y exportación comprobada con eventos agregados y opt-in; comparar cohortes de la build anterior y la nueva sin telemetría documental.
4. Plantear una prueba PPO de una sola hipótesis creativa solo cuando el volumen y el panel de Apple permitan obtener una señal interpretable. Apple muestra resultados después de al menos cinco primeras descargas atribuidas a una prueba y solo marca “Performing Better/Worse” al alcanzar 90 % de confianza; cinco descargas no garantizan significancia.
5. Crear páginas de producto personalizadas únicamente cuando haya un canal/campaña identificable y una deep link coherente con cada intención. No se han creado CPP, campañas ni pruebas en App Store Connect.

## Límites de esta lectura

Apple explica que App Analytics mide adquisición desde impresiones hasta descargas, que la conversión usa impresiones únicas y descargas totales, y que los datos de Analytics Reports están agregados, sujetos a umbrales de privacidad y a ruido estadístico. Por eso no inferimos tasas no presentes en el dashboard ni demanda de mercado a partir de 14 descargas.

Fuentes oficiales consultadas:

- [Definiciones de métricas de App Store Connect Analytics](https://developer.apple.com/help/app-store-connect-analytics/reference/metrics-definitions/)
- [Acquisition: impresión, vistas y descargas](https://developer.apple.com/help/app-store-connect-analytics/acquisition/acquisition/)
- [API de Analytics Reports, disponibilidad y privacidad](https://developer.apple.com/help/app-store-connect-analytics/overview/analytics-reports-api/)
- [Product Page Optimization y niveles de confianza](https://developer.apple.com/help/app-store-connect-analytics/acquisition/product-page-optimization)
