# Informe Git del release

- Rama de release local actual: `release/1.1.7-20261108`; se renombró desde `release/1.2.0-20261108` tras la corrección del propietario.
- Base: commit 095776b, docs: record MaskID main push. La rama quedó en local; no se creó rama remota.
- Árbol al inicio: muy sucio por trabajo autorizado de fases 01-03, con cambios rastreados de producto/docs y artefactos no rastreados. El path raíz `-` es un JSON de 177 bytes con nombres de iconos MaskIDDefault/MaskIDHalloween; duplica entradas de `Shield/Resources/Info.plist`, pero su procedencia/uso no está documentado. Se preservó sin modificar ni borrar.
- Estado actualizado el 9-11: el árbol continúa mezclando cambios autorizados de fases anteriores, código, auditoría, documentación y creatividades. Fase 04 aporta Docs/release-cycle/04_RELEASE, CHANGELOG.md, validadores, capturas auténticas, creatives, ajustes de versión/build y test UI base-theme.
- En el cierre se hicieron las escrituras ASC autorizadas: asociación del build procesado a versión 1.1.7, notas “What to Test” en es-ES/en-US y asignación explícita al grupo `Shield Internal` después de recibir autorización. ASC confirma `IN_BETA_TESTING`; no se añadieron testers. RevenueCat no necesitó escritura: el dashboard autenticado confirmó mappings y ausencia de oferta anual activa. No se sometió a Beta App Review ni a App Review.
- No se creó commit todavía: agrupar todos los cambios de acceso/UX de fases previas, proyecto, tareas, creatividades y el JSON de iconos sin procedencia clara en un commit único reduce la trazabilidad. No se hizo stage, reset, clean, rebase ni revert. El archivo raíz `-` se conserva intacto y sin añadir al release.
- No se creó tag RC/final ni se hizo push. Permanecen gates legales, privacidad, Sandbox y pruebas físicas; no hay aprobación de publicación. El release branch queda local y con el worktree sucio.
- El último commit continúa en 095776b. Un commit de release queda pendiente de separar de forma revisable los cambios de fases previas y de resolver si el archivo `-` pertenece al producto.
- Remote sanitizado: origin apunta al repositorio GitHub lbernardo-dev/shield. No se incluyen credenciales ni URLs con tokens.
- Tag más reciente verificado: v1.0.0-rc.100202607161.
- Último commit actual: 095776b. No hay commits nuevos de Fase 04; los diffs son el artefacto de auditoría.

## Reversión

La rama release/1.1.7-20261108 se puede revisar o descartar con las herramientas locales después de que el propietario confirme qué cambios corresponden a las fases previas. No ejecutar reset/clean mientras el árbol siga mezclado. Para futuros commits: seleccionar la documentación/scripts de Fase 04 por path; después elegir explícitamente los cambios de proyecto version/build y las modificaciones autorizadas anteriores con diff revisado.
