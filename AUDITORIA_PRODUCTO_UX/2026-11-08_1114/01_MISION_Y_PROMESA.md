# Misión y promesa

## Identidad del producto

| Campo | Determinación | Estado y evidencia |
|---|---|---|
| Problema | Evitar compartir datos personales que el destinatario no necesita al enviar documentos. | DOCUMENTADO: `Docs/PRODUCT_POSITIONING.md:3-38`, README. |
| Público prioritario | Personas que comparten identificaciones, contratos, formularios, justificantes, imágenes o PDFs. | DOCUMENTADO; el posicionamiento WIP dice que el producto actual es individual y que colaboración de equipos es futura. No hay investigación de usuarios en el repositorio. |
| Contexto | Seleccionar un archivo o capturarlo, decidir qué ocultar y compartir una copia revisable. | INFERIDO desde Capture, Editor y Export. No se observó una sesión. |
| Trabajo principal | «Preparar y comprobar una copia de un documento que pueda compartir sin revelar datos personales innecesarios». | Síntesis del auditor, no cita de usuario. |
| Tareas críticas | Importar/capturar; revisar sugerencias OCR; ocultar datos necesarios; comprobar/exportar la copia; guardar o recuperar el original de trabajo de forma privada. | Derivado del producto y código. La eficacia real no está medida. |
| Criterio de éxito | El usuario entrega la información necesaria, oculta los datos elegidos y puede revisar la copia antes de compartirla. | Criterio objetivo propuesto; no medido con participantes. |
| Diferenciación | OCR local más revisión manual y verificación técnica del archivo exportado. | DOCUMENTADO/IMPLEMENTADO en el repositorio. Ventaja comparativa frente al mercado: NO DETERMINABLE. |
| Dependencias | Vision/OCR del dispositivo, APIs de cámara/Files, StoreKit/RevenueCat, iCloud/CloudKit, Files providers y disponibilidad de permisos/servicios cuando se usan. | Confirmado en código/configuración; fallo/latencia de cada dependencia no probado aquí. |

## Funciones de apoyo y valor

- **Directas:** captura/importación, OCR y detección, máscaras manuales, modos de protección, exportación segura y comprobación del resultado.
- **Habilitadoras:** biblioteca, búsqueda, categorías, recents, Vault, recordatorios de caducidad, persistencia y reentrada desde Share Sheet/Shortcuts.
- **Comerciales:** límite de procesamiento Free y Pro para escala, lotes, estilos/ajustes avanzados, marcas personalizadas y sincronización/servicios avanzados.
- **Complementarias:** galería de estilos, widget, accesos App Intents, temas/eventos, sonido y feedback/reseñas.
- **Ornamentales:** los elementos de ambientación no tienen relación directa con la protección documental; el evento actual es opcional en el WIP. No hay evidencia para declarar que interfiera con la tarea.

## Riesgo de promesa

El proyecto distingue sugerencias de una redacción completa: requiere que la persona revise cada región y no afirma anonimato ni detección al 100 %. Esto es una fortaleza. El término «verified output» debe limitarse a lo que el verificador comprobó (rasterización, texto/capas/metadatos y OCR residual según las reglas implementadas); no debe leerse como garantía de que se identificaron todos los datos que el usuario quería ocultar.

No se accedió a una ficha App Store actual ni se contrastó el copy publicado. El documento de metadata local se declara histórico y remite a una referencia de ASC anterior; por tanto la promesa externa actual queda NO VERIFICADA.

