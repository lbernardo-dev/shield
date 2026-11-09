# Mapa de navegación y recorridos

## Arquitectura reconstruida desde código

```text
Primer inicio → bienvenida/demo/PIN opcional → Home
Home / Biblioteca → Captura e importación → OCR/revisión → Editor → Exportación/verificación → compartir o volver
Shell compacto: Biblioteca · Estilos · Vault · Ajustes
Shell regular (iPad): sidebar/adaptación por size class; Captura como acción contextual
Vault → autenticar → lista → detalle / export protegido / mover fuera / eliminar
Ajustes → Personalización, preferencias, OCR, Seguridad/Privacidad, Cloud, Exportación,
          suscripción/restaurar/offer code, feedback/reseña, información/ayuda/legal
Entradas alternas → Share Extension / URL de archivo / App Intents / Widget
Gates Pro → paywall cerrable → compra o seguir por ruta Free cuando la operación lo permite
```

La captura no es uno de los cuatro tabs visibles: se abre desde CTA/toolbar. Settings usa un `NavigationStack`; `ContentView` presenta onboarding, bloqueo o shell según estado de sesión. Se identificaron sheets/covers de importación, filtros, categorías, PIN, detalle, export, tema, paywall y diálogo destructivo. Existencia estática; no se recorrieron todos en runtime.

## Recorridos representativos

Todos los siguientes son **RECORRIDO INFERIDO (NO EJECUTADO en esta auditoría)** salvo la evidencia histórica indicada. Los conteos son etapas funcionales aproximadas, no taps medidos.

| Perfil/objetivo | Camino desde código | Decisiones/prerrequisitos | Salida, errores y recuperación | Estado |
|---|---|---|---|---|
| Nuevo: proteger primer documento | bienvenida → demo interactiva → PIN opcional o saltar → CTA “Proteger un documento” → elegir cámara/escáner/Photos/Files → revisar OCR → ajustar máscaras → exportar PDF/imagen → revisar estado | Tres pantallas de onboarding; elegir fuente, revisar hallazgos, formato/calidad; permiso si usa cámara | Onboarding tiene back/skip; import/export contienen rutas de cancelar/error. Retención de estado tras fallo no observada | Tests históricos confirmaron llegada a Home sin paywall ni consentimiento inicial; no probaron comprensión ni tarea completa |
| Recurrente con prisa: abrir documento existente | Biblioteca/Home → recents, búsqueda/categoría o acceso Biblioteca → abrir → editar → exportar; Vault como acceso directo separado | Elección de documentos/ruta; zoom/mascarado/formato | Recents y biblioteca existen. Reapertura real, contexto conservado y pasos no medidos | Estático |
| Usuario que necesita ocultar una región no detectada | Editor → herramienta Rect → arrastrar región → revisar páginas → exportar y comprobar | Requiere arrastre; controles del Inspector ayudan a entidades detectadas, pero no sustituyen una región arbitraria | Undo/redo presentes para cambios; operación por VoiceOver/control por voz no verificada | Riesgo accesible P2; no se probó con dispositivo asistivo |
| Free llega al límite acumulativo | procesar documentos hasta cuota → aviso/entrada Pro → continuar con exportación estándar donde aplique o gestionar plan | 10 documentos Free según posicionamiento; compra requiere StoreKit/RevenueCat | La exportación estándar se mantiene según el modelo local. Copy antes del límite, cierre/restore y persistencia no observados | Revisado en código/docs; sin paywall runtime |
| Usuario Vault: recuperar y compartir | tab Vault → Face ID/Touch ID o PIN → elegir documento → detalle/quick export protegido → compartir, mover fuera o eliminar | Autenticación; seleccionar operación | Bloqueo al background presente. El borrado no muestra confirmación/undo en la ruta contextual y elimina archivos | Static; riesgo P2 de recuperación |
| Usuario desde otra app | Share Sheet → Share Extension → inbox de App Group → Capture → Editor → Exportar o cancelar | Extensión disponible; permisos del host/archivo | Transferencia protegida descrita; retorno/cancelación/errores no observados | Existencia estática |
| Free/Pro que compra/restaura | Settings/paywall o gate de función → elegir mensual/anual/lifetime → compra; Settings → restore/offer code | Entitlement StoreKit/RevenueCat y red | Paywall contiene cierre; producto disponible, compra fallida, restore y caída de red no probados | Estático, sin compra ni ASC |

## Primeros 60 segundos

No se midieron segundos. El onboarding activo tiene tres etapas con skip/back y un PIN opcional; la demostración enseña la idea de ocultar campos antes de llegar a Home. El test histórico `testShortOnboardingDeliversHomeWithoutEarlyPermissionOrPaywall` aprobó que no aparezcan paywall o consentimiento de analítica antes de Home. Eso no demuestra que una persona entienda el propósito ni complete una acción útil en un minuto. La primera acción útil visible es iniciar “Proteger un documento”; elegir fuente y revisar antes de exportar continúa siendo obligatorio.

## Ejercicio «me he perdido»

En código hay close/cancel en Settings, export, paywall y captura; la navegación Settings tiene back y cierre de shell. No se confirmó en ejecución que esas salidas mantengan borrador, foco o selección. No se halló un callejón sin salida confirmado. Pendiente probar: modal de filtro, OCR, PIN incorrecto/cancelado, export fallida, red denegada, reanudación tras background y regreso desde Share Extension.

## Estados a comprobar

Archivo inválido, OCR vacío/parcial, permiso denegado, almacenamiento lleno, error de verificador, sincronización offline/conflictiva, expiración de sesión, restauración de compra y cancelación deben conservar el origen o explicar la pérdida de estado. Esta auditoría los deja pendientes; el diseño de error en código por sí solo no prueba recuperación.

