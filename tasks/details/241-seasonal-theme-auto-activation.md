# 241-seasonal-theme-auto-activation

- Number: 241
- Slug: seasonal-theme-auto-activation

## Notes

- Regla resuelta: durante la ventana local de Halloween, el tema automático aplica Halloween y su icono tanto a Free como a Pro. `.base` solo lo conserva una selección explícita persistida por un usuario Pro; para Free se ignora una preferencia Base heredada y sigue el evento. Las instalaciones nuevas empiezan en `.automatic`.
- El arranque mantiene provisionalmente el tema del evento mientras se resuelve la suscripción si hay una selección Base guardada; al confirmarse Pro se respeta esa salida consciente, y si la cuenta es Free se aplica Halloween.
- Corregida una carrera en la sincronización del icono: peticiones consecutivas se serializan y solo la más reciente publica el resultado, evitando que una tarea antigua vuelva a dejar Base después de Halloween. El indicador del Lock Screen y la cortina de privacidad ahora usan el acento del tema activo.
- Regresión: resolver Free/Pro en ventana activa, instalación nueva, selección Base explícita Pro, pérdida de Pro, resolución de suscripción y peticiones rápidas de icono.
- Validación: `EnhancementFeaturesTests` + `AppIconTests` pasaron en iPhone 18 Pro, iOS 27.0, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`: 35/35. La suite de test se ejecutó; no se configuró PIN ni se continuó la inspección interactiva porque después se detectó StreakReps en primer plano. Duo también mostró StreakReps; no se tocó. iPad Pro 13-inch (M5), iOS 27.0, quedó sin instalar/validar. Apple Watch Series 12, watchOS 27.0, estaba apagado y el proyecto no aporta un destino de app watchOS para este flujo.
- Archive y export locales actualizados: `1.1.6 (1162026102502)`, bundle `com.romerodev.shield`; IPA con iconos alternativos `MaskIDDefault` y `MaskIDHalloween`, extensiones en la misma versión/build. La firma pasó `codesign --verify --deep --strict` con acceso de verificación. 2502 sigue local: no se subió ni enlazó a App Store Connect; el build 2501 existente permanece sin cambios.
- Los simuladores de marketing no se capturaron para creatividades: la regla de `AGENTS.md` exige confirmar visualmente el tema Base y desactivar el evento antes de conservar capturas.

