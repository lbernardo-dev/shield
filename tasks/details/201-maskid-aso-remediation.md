# 201-maskid-aso-remediation

- Number: 201
- Slug: maskid-aso-remediation

## Notes

## Plan de mejora ASO de MaskID

**Base:** auditoría del 2 de octubre de 2026, tarea 200.  
**Objetivo:** mejorar la claridad y la confianza de la ficha en en-US y es-ES, y medir si los cambios atraen instalaciones más cualificadas.  
**Estado inicial a confirmar:** la ficha pública ES muestra 1.0.11; la página US consultada parece atrasada en 1.0.8. La documentación del repo todavía señala 1.0.8 publicada / 1.0.9 preparada.

### Principios de ejecución

- No enviar ni publicar cambios en App Store Connect como parte de este plan sin autorización explícita.
- Verificar cada claim contra `Docs/CLAIMS_MATRIX.md`; sugerencias OCR siempre revisables, exportación verificada solo después de pasar los checks y metadatos descritos como “habituales” cuando corresponda.
- No interpretar cambios de rastreo/caché de la página pública como estado definitivo de la versión. App Store Connect autenticado es la fuente de estado.
- Separar pruebas de metadata de pruebas de assets. Product Page Optimization prueba activos elegibles (icono, capturas y previews), no nombre o keywords.
- No usar volumen estimado ni ranking de terceros como dato observado. Registrar hipótesis hasta medirlas en App Analytics.

### Fases y criterios de salida

#### Fase 0 — Conciliar el estado y fijar baseline

**Acciones**

1. En App Store Connect, en modo de consulta, comprobar para la app `6790398619` la versión aprobada y la editable, su build asociado, estado por locale, nombre/subtítulo, texto promocional, descripción, keywords y screenshots realmente aplicados.
2. Comprobar en storefront público en-US y es-ES qué versión, copy, accesibilidad, compras y capturas ve una persona usuaria. Anotar las diferencias y su fecha, no sobreescribirlas por inferencia.
3. Exportar un baseline de 28 días de App Analytics, si hay datos: impresiones, vistas de página, descargas, conversión, fuente, términos de búsqueda disponibles, territorio, dispositivo, página de producto y retención. Anotar umbrales de privacidad o celdas sin datos.
4. Registrar precio/planes, releases, cambios de metadata, campañas, PPO e In-App Events que coincidan con el intervalo.
5. Verificar el estado de etiquetas de accesibilidad y la advertencia “No verificada para macOS”; decidir internamente si mantener la disponibilidad Mac antes de redactar copy al respecto.

**Entregable:** matriz de estado `ASC vs. público vs. repo` y baseline fechado con datos faltantes explícitos.  
**Salida:** no quedan contradicciones de versión sin documentar; no se propone cambiar metadata hasta conocer la ficha remota vigente.

#### Fase 1 — Corregir copy y preparar metadata localizada

**Acciones**

1. Preparar texto promocional seguro para ambos locales. Candidato de auditoría: en-US `Hide personal details before sharing. Review each mask and check your exported copy on device.`; es-ES `Oculta datos personales antes de compartir. Revisa cada máscara y comprueba la copia exportada en el dispositivo.`
2. Evaluar el nombre candidato en-US `MaskID: Redact PDFs & IDs` frente al actual `MaskID: Protect Private Data`; mantener el subtítulo si sigue siendo vigente. Mantener por ahora nombre/subtítulo ES salvo evidencia local que sugiera otra intención.
3. Validar keywords sin repetir tokens de nombre/subtítulo, con conteo UTF-8 en bytes y términos plausibles de usuario. Punto de partida no definitivo: en-US `privacy,identity,passport,license,forms,watermark,vault,offline,photo,signature,ocr,metadata,iban` (97 bytes); es-ES `identidad,privacidad,documentos,tachar,dni,pasaporte,contratos,iban,firma,metadatos,bóveda,pdf` (95 bytes).
4. Revisar la descripción existente y conservarla salvo que Fase 0 revele un mismatch funcional o de versión. Revisar también “What’s New” por claims no demostrados, hardware específico o detalles internos poco útiles a usuarios.
5. Entregar cada copy con locale, conteos, intención, evidencia del producto, fecha y revisión de límites/claims. El idioma final debe sonar natural en cada mercado; no trasladar mecánicamente keywords EN a ES.

**Entregable:** propuesta de metadata lista para revisión humana, sin push remoto.  
**Salida:** todos los campos constrained pasan los límites de Apple y todas las promesas tienen soporte en la matriz de claims.

#### Fase 2 — Actualizar el storyboard y preparar los assets

**Acciones**

1. Cambiar pantalla 5 de “prevent/evita el robo de datos” a mensaje de propósito de la marca de agua.
2. Cambiar pantalla 9 de “surgical precision/precisión quirúrgica” a selector/estilos de máscara.
3. Ajustar pantalla 4 para dejar claro que OCR propone campos que requieren revisión humana.
4. Sustituir la pantalla 10, que muestra el panel antes de acabar, por una captura auténtica del estado posterior a una verificación aprobada; no usar “irreversible” ni garantía universal.
5. Conservar el hilo narrativo identidad → importación → ocultación → revisión → exportación comprobada. Revisar recorte, legibilidad a tamaño de teléfono, traducción, UI real y fixtures sintéticos en ambos locales.
6. Si es necesario volver a capturar producto, seguir las instrucciones del repo y validar en simulador iPhone 18 Pro como destino principal; comprobar también iPad representativo si se producen assets para esa familia. No apropiarse de un simulador ocupado.
7. Regenerar contacto visual, revisar cada imagen, calcular hashes y actualizar manifiesto local. No sustituir assets remotos en esta fase.

**Entregable:** storyboard aprobado internamente y sets EN/ES trazables con fuente y hashes.  
**Salida:** cada pantalla muestra UI real, copia localizada correcta y claims aprobados; la captura de exportación refleja un estado real.

#### Fase 3 — Diseñar el experimento adecuado

**Experimento A — Assets de página predeterminada (PPO)**

- **Hipótesis:** abrir la historia con identidad/importación/ocultación/revisión explica más rápido el caso de uso y puede mejorar la conversión.
- **Control:** set actual de screenshots del storefront confirmado en Fase 0.
- **Tratamiento:** solo el nuevo set de capturas; mantener icono, previews y metadata constantes.
- **Métrica primaria:** conversión de página de producto en la audiencia incluida por Apple para la prueba; observar duración/confianza según los resultados de Apple.
- No empezar hasta que control y variantes estén disponibles en App Store Connect y se confirme que cumplen los límites vigentes de PPO.

**Experimento B — Nombre de en-US (secuencial, no PPO)**

- **Hipótesis:** “Redact PDFs & IDs” hace más visible la función para consultas de redacción de documentos y puede atraer visitas más cualificadas.
- **Control:** nombre vigente confirmado en ASC. **Variante:** `MaskID: Redact PDFs & IDs`; dejar lo demás igual en el primer análisis.
- **Métrica primaria:** conversión Search por storefront en-US. Secundarias: impresiones, página vista, descargas, retención y compras cuando la privacidad permita verlas.
- Método: pre/post con ventanas comparables porque PPO no prueba metadata. No ejecutar junto a cambios de keywords, precios o capturas que impidan atribuir el resultado.

**Criterio común:** seguir las indicaciones de duración/confianza de Apple, buscar volumen suficiente y conservar resultados inconclusos como tales. No crear “ganador” a partir de variaciones pequeñas o segmentos con muy pocos datos.

#### Fase 4 — Preparar paquete de release y checklist de storefront

**Acciones**

1. Consolidar metadata y assets aprobados localmente y actualizar `Docs/APP_STORE_METADATA_DRAFT.md`, `Docs/APPLE_SURFACES_AND_APP_STORE_CONNECT.md` y manifiestos únicamente con estado verificado.
2. Validar los límites de campos, URLs por locale, descripción, textos de compra, claims, capturas por dispositivo y declaración de accesibilidad.
3. Revisar que los screenshots de iPad y iPhone coincidan con la versión binaria que se enviaría a revisión y que ninguna captura incluya precios hard-coded o pantallas obsoletas.
4. Preparar un resumen de cambios, checklist de App Review y plan de seguimiento.
5. Detenerse antes de hacer metadata push, enviar a revisión, publicar etiquetas de accesibilidad o liberar una versión; solicitar autorización explícita con el paquete concreto listo para revisar.

**Entregable:** checklist listo para decisión de envío con diferencias remotas/locales explicadas.  
**Salida:** paquete completo y consistente, sin hacer cambios públicos.

#### Fase 5 — Leer resultados y decidir iteración

**Acciones**

1. Revisar la propagación por storefront después de cualquier publicación autorizada.
2. Revisar App Analytics semanalmente para errores de propagación y, al final de una ventana comparable de 28 días (o cuando Apple indique suficiencia), analizar conversiones, adquisición y retención.
3. Anotar en el registro las fechas exactas de metadata, release, precio, campañas, PPO e In-App Events.
4. Comparar calidad de la adquisición y compras/retención disponibles junto a instalaciones; no optimizar descargas si empeora la adecuación del usuario.
5. Elegir una sola siguiente hipótesis respaldada por los datos, o mantener control si el resultado no es concluyente.

**Entregable:** nota de resultados por locale, fuente y dispositivo, con limitaciones y decisión siguiente.

### Dependencias y riesgos a resolver

- Hace falta acceso de consulta a App Store Connect para estado real y Analytics; la búsqueda pública no basta.
- Un cambio de nombre requiere que el estado de la versión permita editarlo y seguir el flujo de revisión de Apple; no es una variante PPO.
- Las capturas finales necesitan build y escenas válidas del producto real; los claims de screenshots deben seguir `Docs/CLAIMS_MATRIX.md`.
- La estrategia debe respetar la diferencia de intención y vocabulario entre EE. UU. y España.
- El tamaño actual reducido de valoraciones hace que reseñas, rankings y segmentos pequeños sean señales ruidosas; no pedir ni incentivar valoraciones positivas.

### Fuentes de trabajo

- Auditoría base: `tasks/details/200-audit-maskid-app-store-listing.md`.
- Fuente de producto/claims: `Docs/CLAIMS_MATRIX.md`, `Docs/PRODUCT_POSITIONING.md`, `Docs/APP_STORE_METADATA_DRAFT.md`.
- Metadata: `metadata/app-info/` y `metadata/version/1.0.11/`.
- Creatividades: `Docs/ASO_SCREENSHOT_MANIFEST_2026-09-11.md` y `.asc/screenshots/aso/review/`.
- Reglas Apple vigentes: búsqueda, límites de campos, PPO y Analytics enlazados en la auditoría 200.

### Ejecución autorizada — 2 de octubre de 2026

El usuario autorizó crear la versión 1.1.2 en App Store Connect y aplicar el paquete ASO de esta auditoría. Se completó lo siguiente:

- Confirmado en ASC que 1.1.1 era el release publicado (`READY_FOR_SALE` / `READY_FOR_DISTRIBUTION`); creada 1.1.2 con lanzamiento manual, estado `PREPARE_FOR_SUBMISSION`, ID `904cc5ee-994a-48cb-84db-265013b3cd75` y metadata base copiada de 1.1.1.
- Actualizado el nombre en-US a `MaskID: Redact PDFs & IDs`; nombre/subtítulo es-ES y subtítulos en-US se mantienen. Texto promocional localizado sustituye claims absolutos y sigue la propuesta auditada. Se actualizaron keywords y descripciones EN/ES para reflejar redactar/ocultar, revisión OCR humana, límites Free/Pro, verificación de exportación y límites de sync. URLs legales, soporte y marketing se conservaron.
- Recompuestas las capturas iPhone/iPad EN/ES desde escenas reales ya existentes, con fixtures sintéticos; se corrigieron claims de prevención de fraude, precisión absoluta y exportación irreversible. Los 40 assets remotos terminaron `COMPLETE`, diez por cada combinación de idioma y familia de dispositivo.
- Los App Previews heredados de 1.1.1 quedaron presentes y `COMPLETE` en ambas localizaciones de 1.1.2: mismo vídeo real de 17 s.
- Añadidos manifiesto de capturas y estado verificado en `Docs/ASO_SCREENSHOT_MANIFEST_1.1.2.md`, `Docs/APP_STORE_METADATA_DRAFT.md` y `Docs/APPLE_SURFACES_AND_APP_STORE_CONNECT.md`.
- Validación ASC/URLs: 1 bloqueo por build ausente, avisos por What’s New vacío en ambos locales, informativo de lanzamiento manual y estado de publicación de App Privacy no comprobable por API. No se inventaron notas de versión porque faltan los cambios/build 1.1.2.
- No se compiló ni instaló la app; no se envió a revisión ni se publicó. Las capturas proceden de fuentes reales existentes. No se eliminaron temporales, caches ni sidecars.

**Estado:** metadata y assets aplicados a la versión borrador 1.1.2; entrega de ASO completada. Para enviar, falta asociar una build 1.1.2 y redactar What’s New EN/ES con los cambios confirmados. La hipótesis del nombre en-US y los cambios visuales quedan pendientes de medición; la auditoría no disponía de baseline de App Analytics.
