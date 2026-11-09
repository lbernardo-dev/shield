# Corrección de versión indicada por el propietario

El candidato inicial de Fase 04 fue 1.2.0. El propietario indicó después que la versión pública correcta debe ser **1.1.7** y fijó el build **1172026110801**.

`scripts/next_release_build_number.py --version 1.1.7` confirmó la combinación exacta para Europe/Madrid el 8-11-2026, con `checkedASC:true`, `matchedExistingNumbers:[]` y `writesPerformed:false`. Los seis ajustes Debug/Release de app y extensiones se actualizaron a `MARKETING_VERSION=1.1.7` y `CURRENT_PROJECT_VERSION=1172026110801`. La rama local se renombró a `release/1.1.7-20261108`.

Los archives/IPA locales de 1.2.0 (builds `1202026110801` y `1202026110802`) se preservan bajo `.asc/artifacts/` como artifacts reemplazados. No se subieron a ASC ni TestFlight. Sus capturas y pruebas no se atribuyen a 1.1.7: para el candidato corregido se capturaron 16 pantallas UI con tema base confirmado y fixtures sintéticos; de ellas se compusieron 40 creatividades localizadas (10 por locale/dispositivo). Se validaron localmente y se asignaron, mediante App Asset Library placements actuales, a los cuatro grupos autorizados del borrador 1.1.7. La suite completa se ejecutó para el candidato corregido, con una repetición adicional preservada en `.asc/artifacts/`.

ASC aceptó y procesó `1172026110801` como build `VALID` en TestFlight. Se sincronizaron los metadatos de versión es-ES/en-US y las 40 creatividades en App Asset Library para el borrador manual (10 colocaciones activas por grupo, imágenes `PREPARE_FOR_SUBMISSION`). No se asignaron testers, no se envió a App Review ni se publicó.
