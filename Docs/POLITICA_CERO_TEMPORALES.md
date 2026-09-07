# Política de cero temporales

## Objetivo

Al finalizar cada sesión de trabajo de MaskID no deben quedar residuos temporales o regenerables del proceso de desarrollo, validación, UI gate, archive o carga a App Store Connect.

Esta política se aplica al material generado por el proyecto. No autoriza borrar datos personales, código fuente, documentación, credenciales, material de firma ni artefactos de release.

## Allowlist de material limpiable

El único material que puede entrar en la limpieza de cierre es:

- `build/logs/`
- `build/cache/`
- `build/tmp/`
- `build/DerivedData/`
- `build/ui-ux-release-gate/`
- Directorios o ficheros temporales de `/tmp` cuyo nombre empiece por `MaskID-`, además de `/tmp/DerivedData-MaskID`.
- Sidecars AppleDouble `._*` fuera de `.git/`, `.asc/` y `build/`, siempre identificados por ruta exacta.

Las raíces de `build/` son regenerables. Los elementos de `/tmp` son temporales de ejecución y deben identificarse por su nombre exacto antes de moverlos.

## Material protegido

Nunca se elimina como parte de esta política:

- `.asc/artifacts/`, incluidos `.xcarchive`, `.dSYM`, IPA y evidencias de publicación.
- `.git/`, incluido cualquier sidecar o metadato interno del repositorio.
- Código fuente, `metadata/`, `Docs/`, `tasks/` y configuración del proyecto.
- Certificados, perfiles, claves, credenciales, Keychain, caches globales de Xcode o datos de usuario.
- Procesos, simuladores o artefactos pertenecientes a otro proyecto.

## Procedimiento obligatorio de cierre

1. Terminar Xcode, builds, tests, archives y cargas de App Store Connect. Un Simulator que esté abierto no se modifica ni se elimina; solo se verifica que no haya una operación de build activa.
2. Ejecutar una auditoría de solo lectura:

   ```bash
   scripts/cleanup_temporaries.sh --dry-run
   ```

3. Revisar los IDs y tamaños exactos que devuelve la auditoría.
4. Mover únicamente los IDs aprobados a la Papelera, sin vaciarla:

   ```bash
   scripts/cleanup_temporaries.sh --apply <id-exacto> [<id-exacto> ...]
   ```

5. Verificar que cada ruta aprobada ya no existe y que las rutas protegidas siguen intactas.

La limpieza no usa comodines destructivos ni `rm -rf`. Si hay un proceso activo de Xcode, build, test, archive, resolución de paquetes o carga, la aplicación se detiene y no modifica nada. Los servicios persistentes de CoreSimulator no son candidatos y se dejan intactos. La ausencia de candidatos se considera el estado correcto de cierre: **0 temporales pendientes**.

## Criterio de sesión completada

Una sesión solo se considera cerrada cuando:

- no hay procesos de build/archivo/carga activos;
- la auditoría no muestra candidatos pendientes, o todos los candidatos exactos han sido aprobados y enviados a la Papelera;
- los artefactos de release protegidos permanecen disponibles;
- no se ha vaciado la Papelera automáticamente.
