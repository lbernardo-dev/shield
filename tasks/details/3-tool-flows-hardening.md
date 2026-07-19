# 3-tool-flows-hardening

- Number: 3
- Slug: tool-flows-hardening

## Notes

- 2026-05-07:
  - Propagado `scenePhase` real desde `ContentView` hacia `AppState` para que autolock y reentrada no queden desincronizados.
  - Corregido `AppSessionCoordinator`: el chequeo periódico en foreground ya no renueva actividad artificialmente; ahora bloquea si se supera el umbral real.
  - Forzada reconstrucción del shell al cambiar idioma con `.id(appState.language.rawValue)` para que vistas que usan `LanguageManager.shared` rehagan su copy.
  - Selector de idioma en ajustes endurecido para escribir en `appState.language` directamente al tocar.
  - `EditorView` e `ImageAdjustToolbar` rehechos en claro/oscuro con tokens adaptativos; mejor contraste en acciones, sliders, chips y canvas.
  - `EditorViewModel` ahora sanea recortes extremos para no romper preview, OCR ni exportación.
  - `LockScreenView` rehacida con tokens adaptativos y fondo claro/oscuro coherente; la pantalla de bloqueo ya no queda forzada en tema oscuro cuando la app está en claro.
  - Añadidos helpers generales de safe area en `ShieldTheme` y aplicados a cabeceras de captura, onboarding y galería para un top chrome más consistente.
  - `ScanReviewView` endurecida: cabecera superior reordenada para alejar título y navegación de la isla dinámica.
  - `FourPointPerspectiveEditor` corregido para usar coordenadas absolutas del gesto en el espacio del editor, evitando la acumulación errónea de traslación que lanzaba las esquinas fuera del lienzo.
  - La edición manual de perspectiva ahora queda confinada al rectángulo real de la imagen renderizada, no a todo el contenedor del preview.
  - Eliminadas duplicidades funcionales en la vista de mejora: se quita el botón flotante duplicado de perspectiva y se dejan rotación/perspectiva en un único bloque operativo.
  - La rotación rápida de página ahora invalida y limpia el estado de perspectiva manual/automática incompatible, para evitar previews en blanco o geometrías corruptas tras girar.
  - Reestructurada la cabecera de `ScanReviewView` con `safeAreaInset(edge: .top)` para que la navegación superior no quede por debajo de la isla dinámica.
  - Añadido CTA explícito de `Aplicar recorte` durante la perspectiva manual, en vez de obligar al usuario a salir del modo de edición sin una acción clara.
  - Corregida la matemática de `rotate(image:degrees:)`: el nuevo lienzo se centra con el tamaño rotado absoluto, evitando que las rotaciones a 90º/180º/270º dejen la previsualización en blanco.
  - Movida la acción de aplicar recorte al header superior cuando la perspectiva manual está activa; `Continuar` queda deshabilitado mientras el recorte no se confirma.
  - El preview de ajustes ya no salta al original en cada cambio: se conserva el último frame válido mientras entra el nuevo render.
  - Los sliders de geometría, recorte e imagen ahora renderizan preview continuo en una resolución de trabajo más ligera durante el arrastre y rematan a resolución completa al soltar, para dar feedback inmediato.
  - Verificación: `xcodebuild` Debug iOS Simulator del esquema `Shield` compila limpio después de los cambios.
