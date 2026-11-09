# Auditoría UI/UX y accesibilidad

## Alcance

Inspección de SwiftUI, strings y tests. No se obtuvieron capturas ni observación directa de interfaz. Las heurísticas sirven como señales, no prueban fracaso de usuarios. NN/g explica que son reglas generales, no requisitos rígidos: https://www.nngroup.com/articles/ten-usability-heuristics/

## Home

- Primero: CTA principal más accesos categóricos y paneles secundarios (estructura inferida).
- Qué puede creer: elegir categoría o comenzar una tarea.
- Qué debería poder: importar/proteger documento con baja indecisión.
- Fricción verificable: en layout compacto, los chips muestran solo iconos (HomeView.swift:531-538; HomeCategoryChip :1221-1256). Hay accessibilityLabel; en Dynamic Type accesible Home pasa a una columna y muestra etiquetas (:539-548). No hay pérdida de etiqueta visible en ese tamaño.
- Simplificación conservadora: mostrar texto en los chips compactos si prueba moderada evidencia errores de descubrimiento; mantener dominante el CTA principal.
- Severidad P3; impacto no medido.

## Barra de tabs

Los títulos visibles se ocultan en Dynamic Type de accesibilidad; labels, values y traits siguen presentes (TabBar.swift:119-132). No se demuestra pérdida de navegación con VoiceOver. Riesgo potencial para baja visión sin VoiceOver. Validar Zoom y tamaños antes de cambiar.

## Editor

Siete botones icon-only en banda desplazable (EditorChromeViews.swift:338-390). Tienen labels, hints y estado seleccionado; el activo se desplaza a la vista según código. La primera ejecución AX5 con build sin firma y paralelismo activo devolvió `editor.tool.rect` no `hittable`; el rerun firmado y sin paralelismo pasó los controles y el acceso al selector PDF. No se cambió el toolbar porque la falla no se reprodujo con configuración controlada. Se amplió después el E2E para exportar PDF y consultar el resultado accesible; falta correr esa versión. La descubribilidad visual sigue sin medirse con personas nuevas.

## Onboarding y monetización

Tres etapas: bienvenida, demo y seguridad opcional, con opción de saltar (OnboardingFlowView.swift:91-99). El test runtime `testShortOnboardingDeliversHomeWithoutEarlyPermissionOrPaywall` pasó en iPhone 18 Pro iOS 27.2; verifica llegada a Home sin paywall/consentimiento temprano, pero no sustituye una prueba de comprensión.

## Capacidades accesibles encontradas

- @ScaledMetric en medidas (Shield/Theme/ShieldTheme.swift:1891-1944).
- Controles de contraste y transparencia (:1949-1970).
- Reduce Motion conectado en componentes revisados.
- Labels de VoiceOver en chips, editor y tabs.
- Layout adaptativo para iPad y Dynamic Type.
- Recursos/test visibles en ES/EN.

## Brechas

- No se ejecutó VoiceOver en tarea completa ni se comprobó orden de foco; labels aislados no prueban una tarea accesible. ACC-001.
- Se añadió E2E editor→export en AX5, pero el primer runtime falló en el control rect antes de llegar al export. No se completó importación → corrección → verificación/exportación ni Vault/paywall.
- Tamaño táctil, contraste real, truncamiento, Voice Control, Switch Control, RTL, rotación y multitarea no medidos.
- Audio estacional ahora empieza desactivado si no hay preferencia; la prueba de default y persistencia aprobó. Escucha manual y audio real siguen pendientes.
- Sin capturas; no se verificó claro/oscuro ni evento visual.

## Validación de menor riesgo

1. E2E con VoiceOver, Dynamic Type AX5, Increase Contrast, Reduce Motion y Voice Control.
2. Medir tamaño táctil, foco y lectura del editor/Vault, incluyendo error y cancelación.
3. Prueba moderada de Home compacto antes de añadir etiquetas.
4. Confirmar copy y default de audio con preferencias limpias.

