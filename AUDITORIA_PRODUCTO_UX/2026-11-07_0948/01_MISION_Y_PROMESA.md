# Misión y promesa

## Identidad

- Nombre: MaskID (nombre detectado en el proyecto; App Store vigente no verificada).
- Bundle ID: com.romerodev.shield.
- Plataformas declaradas: iPhone e iPad, deployment target iOS 18.0.
- Fuentes: Docs/PRODUCT_POSITIONING.md:3-38; Shield.xcodeproj/project.pbxproj:1468-1501.
- Certeza: alta para intención local; no verificada contra ficha publicada vigente.

## Expediente

| Campo | Determinación | Evidencia |
|---|---|---|
| Problema | Ocultar información personal de documentos antes de compartirlos. | DOCUMENTADO; PRODUCT_POSITIONING.md:3-38. |
| Público | Personas con documentos sensibles; el posicionamiento también menciona equipos. | DOCUMENTADO, pero con ambigüedad: el mismo documento sitúa herramientas de equipo en el futuro (:5, :23). |
| Contexto | Importar documento, identificar datos, revisar máscaras y producir una copia segura. | INFERIDO a partir de flujos y módulos; no observado en ejecución. |
| Primary job | “Preparar y verificar una copia de un documento que pueda compartir sin revelar datos personales.” | SÍNTESIS basada en documentación y rutas, no cita literal. |
| Éxito | Documento exportado; datos que se debían proteger quedan ocultos y el usuario puede revisar el resultado. | Criterio derivado de la misión; no se midió con usuarios. |
| Diferenciación | OCR en dispositivo más revisión manual y verificación de la exportación. | DOCUMENTADO/IMPLEMENTADO en el repositorio; valor comparativo de mercado NO DETERMINABLE. |

## Tareas críticas

1. Importar un documento desde una fuente admitida.
2. Localizar y revisar datos sensibles reconocidos.
3. Corregir o añadir máscaras manualmente.
4. Exportar y verificar la copia final.
5. Recuperar documentos de trabajo protegidos o gestionarlos en Vault, si el usuario necesita retomar.

Las rutas son inferidas estáticamente, no recorridos ejecutados. El criterio de éxito no equivale a una garantía legal o de anonimización perfecta.

## Catálogo según propósito

- Directas: OCR, revisión, máscara manual, exportación y verificación.
- Habilitadoras/confianza: Vault cifrado, persistencia, permisos y controles de privacidad.
- Comerciales: nivel Free con cuota acumulativa de 10 documentos y opciones Pro; exportación permanece disponible.
- Complementarias: temas estacionales, widgets, extensión de compartir e integraciones del sistema.
- No se halló evidencia suficiente para clasificar una función como candidata a retirar.

## Límites y contradicciones

La mención de “personas y equipos” amplía el público, pero el documento aclara que las herramientas colaborativas están previstas para futuro. No se debe presentar la colaboración en equipo como capacidad vigente. La ficha actual de App Store no fue accesible; no se afirma contradicción pública.

Dependencias de OCR, archivos, almacenamiento y sincronización existen en el proyecto; disponibilidad y comportamiento bajo fallo/offline requieren ejecución.

## Criterios de éxito para siguiente fase

Validar con usuarios nuevos y recurrentes que pueden iniciar la importación, detectar omisiones, revisar el resultado y recuperar/cancelar sin pérdida. Medir tiempo y errores mediante prueba moderada, no inferirlos del número de líneas. Confirmar que documentos exportados realmente eliminan contenido subyacente, no solo lo cubren visualmente, usando casos de prueba controlados.

