# Mapa de navegación y recorridos

## Arquitectura reconstruida (estática)

- Primer lanzamiento → onboarding de bienvenida → demostración → seguridad opcional → Home (OnboardingFlowView.swift:91-99).
- Home → importar → editor/OCR → revisión y máscaras → exportación/verificación. Ruta inferida desde módulos; requiere ejecución para confirmar pasos exactos.
- Navegación persistente por tabs hacia secciones funcionales y ajustes; tab bar oculta nombres visuales en Dynamic Type de accesibilidad, pero mantiene semántica VoiceOver (TabBar.swift:119-132).
- Ajustes → privacidad, preferencias, tema/evento y suscripciones. Hay accesos de tema y audio en SettingsDestinationViews.swift:1101-1115, 1305-1315.
- Entradas complementarias declaradas: Share Extension, WidgetKit, App Intents, Vault. Rutas exactas de retorno no observadas.
- No hay target watchOS/Catalyst detectado; universal iPhone/iPad.

## Recorridos críticos inferidos, no ejecutados

1. **Nuevo / primer documento:** abrir → completar u omitir onboarding opcional → CTA Home → importar → revisar OCR → ajustar máscara → exportar y verificar. No se midieron taps, duración ni permisos.
2. **Recurrente con prisa:** abrir → entrar a área de trabajo/Vault o importar otra fuente → editar → exportar. La ruta más corta y persistencia de contexto son no determinables sin UI.
3. **Accesibilidad:** Dynamic Type alto/VoiceOver → identificar CTA → importar → usar herramientas etiquetadas → verificar y salir. Fuente confirma adaptaciones, pero no orden de foco ni completitud E2E.
4. **Free al alcanzar cuota:** trabajar hasta límite acumulativo de 10 documentos → revisar explicación/Pro → continuar exportación o gestionar plan. La exportación disponible está documentada; flujo real y copy no ejecutados.
5. **Share Extension:** recibir archivo desde otra app → importar/editar → exportar o cancelar → regresar. Existencia del target inferida; resultado/cancelación no ejecutados.
6. **Vault:** abrir almacenamiento → autenticarse/desbloquear → recuperar o cancelar. Mecanismo de recuperación y estados erróneos pendientes.

No se reportan conteos de pasos como medición: las etapas son hipótesis derivadas del código. No se demostró callejón sin salida.

## Primeros 60 segundos

No cronometrados. La fuente de UI test afirma que Home ofrece CTA sin obligar paywall, consentimiento analítico o permiso de cámara (ShieldUITests/ShieldLaunchTests.swift:1695-1708); la prueba no se ejecutó. El onboarding tiene una demostración y seguridad opcional que podría explicar la misión. La comprensión real necesita prueba con usuarios.

## Ejercicio “me he perdido”

Sin ejecución no se verificaron back/cancel, conservación del borrador, retomar tras cierre, errores de permisos ni salida de paywall. Son pendientes de validación, no fallos reproducidos. Revisar modal de exportación, importación cancelada, edición profunda, vault bloqueado, settings y pantalla Pro.

## Recuperación y estados

- Código/tests sugieren persistencia, cuota y migraciones; ninguna recuperación se ejecutó.
- Estados offline, archivo inválido, OCR incompleto, exportación fallida y almacenamiento lleno: pendientes.
- Criterio recomendado: cancelación devuelve al punto anterior sin perder el documento de origen; fallo de exportación conserva el trabajo y muestra acción clara de reintento.

