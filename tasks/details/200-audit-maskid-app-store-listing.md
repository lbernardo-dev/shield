# 200-audit-maskid-app-store-listing

- Number: 200
- Slug: audit-maskid-app-store-listing

## Notes

## Auditoría ASO de la ficha pública de MaskID

**Fecha:** 2 de octubre de 2026  
**App:** MaskID, ID `6790398619`  
**Locales revisados:** English (U.S.) y español (España).  
**Alcance:** página pública, metadata local hasta 1.0.11, claims aprobados, capturas locales y requisitos actuales de Apple. No se modificó App Store Connect.

### Diagnóstico

El posicionamiento es claro y diferenciador: proteger identidad y datos antes de compartir, con OCR en el dispositivo, revisión humana y exportación comprobada. La descripción explica bien el flujo y los límites del detector. La mejora prioritaria es alinear el lenguaje promocional con los claims verificables, y sincronizar la documentación interna de estado/versiones.

La ficha española pública muestra el nombre y subtítulo esperados, versión 1.0.11, una valoración de 5,0 con una sola valoración, categoría Utilidades, 4+, soporte iPhone/iPad y el texto localizado actual. La ficha estadounidense encontrada muestra el mismo nombre/subtítulo en inglés, pero el rastreo público todavía la presenta como 1.0.8 y sin valoraciones suficientes. Por tanto, hay una diferencia de propagación/caché o de estado entre escaparates que se debe confirmar en App Store Connect antes de cualquier cambio; la consulta web no prueba cuál es el estado remoto definitivo.

La página pública indica que aún no se han declarado prestaciones de accesibilidad. El repo registra dos borradores de etiquetas de accesibilidad, no publicados. Publicarlos podría mejorar la información de confianza, tras comprobar que reflejan exactamente la app distribuida. La ficha también dice «No verificada para macOS»; decidir si se verificará esa compatibilidad o si se dejará de ofrecer, y no presentarla como compatibilidad comprobada mientras siga así.

**Evidencia no disponible en esta auditoría:** App Store Connect Analytics (impresiones, visitas, conversiones, búsquedas, países, páginas y cohortes), ranking por consulta, capturas efectivamente servidas al público en cada storefront y estado remoto actual autenticado de 1.0.11. No se infiere volumen de búsqueda ni causalidad.

### Hallazgos priorizados

1. **P1 — Rebajar claims absolutos del texto promocional y de capturas antes de una próxima publicación.** La matriz de claims del proyecto prohíbe garantías de riesgo cero, privacidad absoluta o redacción universalmente irreversible. El texto promocional actual dice “total on-device security and privacy” / “total seguridad y privacidad en el dispositivo”. Las capturas locales muestran “PREVENT IDENTITY THEFT” / “EVITA EL ROBO DE DATOS”, “Surgical Precision” / “Precisión quirúrgica” y títulos asociados a exportación irreversible. Sustituirlos por beneficios concretos: enmascarar datos, añadir marcas de agua con propósito, revisar sugerencias y comprobar la copia exportada. Resultado esperado: reducir discrepancia entre promesa y uso real; medir vistas de página a descarga y reseñas/soporte sobre expectativas.
2. **P1 — Confirmar publicación y coherencia por storefront/locale.** La página española encontrada ya incluye 1.0.11; la estadounidense leída parece cacheada en 1.0.8. La fuente interna `Docs/APP_STORE_METADATA_DRAFT.md` y `Docs/APPLE_SURFACES_AND_APP_STORE_CONNECT.md` aún describen 1.0.8 publicada y 1.0.9 preparada, mientras existen JSON de 1.0.11. Revisar en App Store Connect el estado aprobado/publicado por versión y locale y actualizar esas dos referencias con evidencia autenticada. Resultado esperado: evitar corregir una ficha equivocada y facilitar futuras auditorías.
3. **P2 — Aclarar la primera intención de búsqueda en el nombre inglés.** El nombre/subtítulo actuales son claros para el beneficio, pero no usan el término de acción “redact” ni “PDF” en el título. Probar `MaskID: Redact PDFs & IDs` con el subtítulo actual, sin afirmar que mejorará ranking: es una hipótesis de relevancia para consultas “redact PDF/ID”. Resultado esperado: más visitas cualificadas desde búsqueda, sin caída de conversión. Medir por storefront y consultas de Search en App Analytics.
4. **P2 — Mejorar señales de confianza visibles.** El escaparate español solo muestra una valoración; el estadounidense no muestra un resumen. Mantener la solicitud de valoración del sistema en un momento positivo, después de una exportación revisada o una tarea completada, sin pedir una puntuación concreta ni interrumpir. Revisar las etiquetas de accesibilidad sin publicar hasta validarlas.
5. **P3 — Reevaluar “No verificada para macOS”.** No ocultar el aviso con una afirmación de soporte. Confirmar política de distribución y compatibilidad; luego verificar macOS si se desea mantenerla disponible.

### Metadata propuesta para el próximo ciclo

Mantener la descripción actual: está alineada con el posicionamiento, cubre casos de uso, explica el procesamiento local, la revisión humana y el alcance de la sincronización. El texto exacto está en `metadata/version/1.0.11/`. Las longitudes abajo se calcularon sobre esos JSON; el límite de keyword se comprueba en bytes (Apple especifica 100 bytes en App Store Connect Help).

| Locale / campo | Propuesta | Longitud | Decisión |
|---|---|---:|---|
| en-US · Name | `MaskID: Redact PDFs & IDs` | 25/30 caracteres | Hipótesis para probar más adelante; requiere nueva versión/edición permitida. |
| en-US · Subtitle | `Hide Details Before Sharing` | 27/30 caracteres | Mantener. |
| en-US · Keywords | `privacy,identity,passport,license,forms,watermark,vault,offline,photo,signature,ocr,metadata,iban` | 97/100 bytes | Candidato; retira términos de marca redundantes y evita duplicar “redact/PDF” del nombre propuesto. |
| en-US · Promotional text | `Hide personal details before sharing. Review each mask and check your exported copy on device.` | 94/170 caracteres | Sustituir el claim “total security and privacy”. |
| es-ES · Name | `MaskID: Protege Datos Privados` | 30/30 caracteres | Mantener. |
| es-ES · Subtitle | `Oculta Datos al Compartir` | 25/30 caracteres | Mantener. |
| es-ES · Keywords | `identidad,privacidad,documentos,tachar,dni,pasaporte,contratos,iban,firma,metadatos,bóveda,pdf` | 94 caracteres / 95 bytes | Candidato; incorpora intención “tachar” y conserva margen byte para tildes. |
| es-ES · Promotional text | `Oculta datos personales antes de compartir. Revisa cada máscara y comprueba la copia exportada en el dispositivo.` | 113 caracteres / 114 bytes | Sustituir el claim “total seguridad y privacidad”. |

No repetir nombre/subtítulo en el campo de keywords. Apple documenta que nombre, subtítulo, keywords y categoría intervienen en relevancia textual; no publica pesos ni volúmenes. Los términos sugeridos derivan del trabajo real del producto: **redactar/ocultar** (acción), **DNI/pasaporte/ID** (documento), **PDF/foto** (formato) y **datos personales/privacidad** (problema). No se atribuye volumen a ninguno.

La descripción actual mide 2.054 caracteres / 2.084 bytes en en-US y 2.197 caracteres / 2.261 bytes en es-ES; ambas están dentro de 4.000 caracteres. El texto promocional propuesto queda dentro de 170 caracteres en cada locale. Name y subtitle respetan 30 caracteres. Apple explica que el campo Promotional Text admite hasta 170 caracteres y la descripción hasta 4.000; el nombre y subtítulo tienen límite de 30.

### Capturas: storyboard y cambios pedidos

Los contact sheets locales están en `.asc/screenshots/aso/review/contact-en-US.png` y `contact-es-ES.png`. El set tiene diez pantallas reales por idioma, con una narración de captura/importación → detección y control humano → protección de documentos → exportación. El comienzo con identidad/pasaporte conecta bien con la intención principal; el modo oscuro y los datos sintéticos también son adecuados.

- Reescribir la pantalla 5: reemplazar `PREVENT IDENTITY THEFT` / `EVITA EL ROBO DE DATOS` por `ADD A PURPOSE WATERMARK` / `INDICA EL PROPÓSITO DE LA COPIA`. La UI muestra una marca de agua, no puede prometer que prevendrá robo/fraude.
- Reescribir la pantalla 9: reemplazar `SURGICAL PRECISION` / `PRECISIÓN QUIRÚRGICA` por `CHOOSE A MASK STYLE` / `ELIGE EL ESTILO DE MÁSCARA`.
- Revisar la pantalla 4: “smart auto-detection” y “instant” no deben hacer pensar que las sugerencias son completas; hacer explícito que son sugerencias revisables y mantener la UI que permite revisarlas.
- La pantalla 10 muestra el panel de exportación antes de terminar, aunque el claim habla de verificación. Preferir una captura auténtica del resultado posterior a la comprobación, con estado visible, y describirla como comprobación del archivo. Evitar “irreversible”, “recover-proof” o garantía universal. Mantener aviso de revisión humana.
- Mantener capturas 1–3 como apertura y probar el orden 1 identidad, 2 importación/escaneo, 3 controles de ocultación, 4 revisión OCR y 5 copia comprobada. No se afirma que el texto en capturas mejore el ranking; se busca comprensión en pantalla y congruencia con la intención.

### Experimento y medición

**Hipótesis de copy:** “Redact PDFs & IDs” atrae más búsquedas con intención de proteger documentos que “Protect Private Data”, sin reducir la descarga por visita.  
**Control:** nombre actual en-US + subtítulo actual. **Variante:** nombre propuesto + mismo subtítulo; preservar icono, descripción, keywords y capturas para reducir variables.  
**Métrica primaria:** tasa de conversión de página de producto para tráfico de Search. **Cortes:** storefront (EE. UU./España), locale, dispositivo y fuente; revisar impresiones, vistas, descargas y adquisición. **Decisión:** comparar ventanas equivalentes antes/después con volumen suficiente y registrar el cambio; no declarar ganador por un resultado pequeño. Esta no es una prueba PPO: Apple PPO se limita a variantes de activos elegibles de icono, capturas y previews, no a nombre/keywords. Si se quiere aislar activos visuales en la página predeterminada, usar PPO por separado.

**Ritmo:** establecer baseline de 28 días antes de cualquier metadata; revisar semanalmente solo errores/propagación, y hacer lectura de resultados tras 28 días equivalentes o cuando App Analytics muestre señal suficiente. Anotar release, cambios de metadata, precio, campañas e In-App Events. Añadir retención y compras por cohorte cuando estén disponibles para descartar conversiones de baja calidad. No hay datos de ASC en esta auditoría, así que no se fijan benchmarks.

### Fuentes

- [Ficha pública EE. UU.](https://apps.apple.com/us/app/maskid-protect-private-data/id6790398619) y [ficha pública España](https://apps.apple.com/es/app/maskid-protege-datos-privados/id6790398619).
- [Apple: App Store search](https://developer.apple.com/app-store/search/) — relevancia, keyword field y consejos de selección.
- [Apple: Platform version information](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/) — límites de metadata.
- [Apple: App information](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/) — nombre y subtítulo.
- [Apple: Product Page Optimization](https://developer.apple.com/app-store/product-page-optimization/) — alcance de PPO.
- Evidencia del repo: `metadata/app-info/*.json`, `metadata/version/1.0.11/*.json`, `Docs/CLAIMS_MATRIX.md`, `Docs/APP_STORE_METADATA_DRAFT.md`, `Docs/ASO_SCREENSHOT_MANIFEST_2026-09-11.md` y los contact sheets citados arriba.

### Estado

Auditoría terminada. No se editaron textos de publicación ni se realizaron cambios en App Store Connect. No se ejecutaron builds o tests; no son necesarios para esta auditoría. No se borraron temporales ni caches.
