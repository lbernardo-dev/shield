# 138-cleanup-xcode-and-project-storage

- Number: 138
- Slug: cleanup-xcode-and-project-storage

## Notes

- Auditoría de solo lectura completada el 2026-08-26. No se ha borrado ningún dato.
- Espacio libre del volumen: 6.7 GiB; el proyecto ocupa aproximadamente 37 GiB lógicos.
- Candidatos regenerables locales detectados: `build/DerivedData` 13.45 GiB, `build/home` 12.88 GiB, `build/cache` 4.89 GiB, `build/logs` 2.06 GiB, `.build` 0.26 GiB, `build/ui-preview` 0.11 GiB y `build/tmp` 0.3 MiB.
- El auditador Xcode detectó además `XCTestDevices` 4.45 GiB y DerivedData huérfano de Expirely 0.20 GiB.
- Preservados por defecto: `.asc/artifacts` 2.32 GiB (archives/IPAs de releases), screenshots, metadata, DeviceSupport, runtimes activos, Xcode, documentación, perfiles de firma y credenciales.
- Aprobados los nueve IDs regenerables de la propuesta. En la revalidación, las ocho rutas grandes y `XCTestDevices` ya no estaban presentes; `.build` coincidía con la auditoría y fue movido a la Papelera mediante el limpiador auditado.
- Espacio disponible posterior: 79 GiB. El espacio de `.build` queda retenido en la Papelera hasta vaciarla.
- Candidato regenerable adicional no incluido en la aprobación original: `project-build:xcodeproj-build`, ruta `Shield.xcodeproj/build/cache` (52 MiB). Pendiente de aprobación explícita.
