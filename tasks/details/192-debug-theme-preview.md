# 192-debug-theme-preview

- Number: 192
- Slug: debug-theme-preview

## Notes

- Añadido selector DEBUG exclusivo del simulador en Ajustes > Personalización > Temas. Incluye “Comportamiento real” y todos los temas del catálogo; la selección se persiste sólo en `UserDefaults` DEBUG y se puede restablecer sin afectar producción.
- Integrado Halloween como experiencia transversal: icono alternativo `MaskIDHalloween`, capa ambiental Canvas con telaraña, brasas, luna y estrellas, partículas animadas, tipografía redondeada, superficie de splash/lock/onboarding, banner de transición, indicador de carga temático y microinteracción de pulsación con rotación sutil.
- La transición global aplica el icono y muestra una confirmación accesible al cambiar de tema. Se respetan Reduce Motion, transparencia reducida, contraste y localización ES/EN.
- La ruta del selector DEBUG está explícitamente fuera del gate Premium: una cuenta Free puede escoger Halloween o cualquier tema y volver a automático/base desde el simulador.
- Build `theme-build-debug-preview-v2` completada correctamente.
- `theme-tests-debug-preview-v2`: 8/8 tests de `EnhancementFeaturesTests` correctos en `Clone 1 of iPhone 18 Pro - MaskID`, incluido `seasonalThemeSimulatorPreviewOverride()`.
- Revalidación posterior `theme-tests-free-preview`: 8/8 correctos; el test fuerza `isPro = false` y confirma que la previsualización activa Halloween y restaura el comportamiento real.
- Actualización final del simulador completada con acceso de Simulator: build instalada y lanzada en `1454EA8D-A019-4B07-B57C-1433E0F21BE0`; `simctl listapps` confirma `MaskID` versión `1.1.0`, build `1102026092201`, en el contenedor correcto.
- La revisión visual interactiva quedó limitada porque el iPhone 18 Pro estaba compartido: después del arranque otra sesión recuperó el primer plano con `SchoolSnap`. No se navegó, reinició, borró ni apropió esa sesión.

## Evidencia

- Build: `build/logs/CODEX/theme-build-debug-preview-v2.log` y `.xcresult`.
- Tests: `build/logs/CODEX/theme-tests-debug-preview-v2.log` y `.xcresult`.
- Destino exacto: UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`, iOS 27.0; Xcode ejecutó los tests en el clon `47599` del iPhone 18 Pro.
