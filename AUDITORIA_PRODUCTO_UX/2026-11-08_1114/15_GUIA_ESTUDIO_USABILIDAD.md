# Guía de estudio moderado para el siguiente ciclo

## Estado

Este protocolo prepara las validaciones AUD-015, AUD-016 y AUD-017. No se han reclutado participantes ni se han realizado sesiones en esta fase. No se presentan hipótesis como resultados.

## Objetivo y preguntas

1. ¿Una persona nueva reconoce en Home cómo iniciar la protección de un documento y cómo recuperar una tarea interrumpida?
2. ¿Una persona nueva encuentra y corrige una máscara libre en el editor? ¿Una persona recurrente localiza sus herramientas habituales sin recorrer la barra completa?
3. ¿Las personas distinguen qué propone un modo según el propósito y qué configura un perfil de protección (tipos de datos y opciones de salida)? ¿Entienden que deben revisar cada máscara?

La sesión es cualitativa y exploratoria. Una muestra pequeña sirve para encontrar barreras y lenguaje confuso, no para estimar adopción ni demostrar una mejora estadística.

## Muestra sugerida

- 6–8 personas: al menos 3 que no hayan usado MaskID y 2 usuarias recurrentes, si están disponibles.
- Incluir al menos una persona que use VoiceOver o Voice Control habitualmente. No sustituir su experiencia por una auditoría automática.
- Repartir entre iPhone y iPad si el reclutamiento lo permite; anotar tamaño y orientación.
- No recopilar documentos, nombres, credenciales, direcciones, capturas de documentos reales ni datos de cuenta.

## Preparación

- Usar un build interno de prueba con fixtures sintéticos. Desactivar sync/servicios externos y no iniciar sesión con cuentas personales de iCloud, RevenueCat o proveedores de archivos.
- Confirmar modo Base antes de cualquier captura del material de sesión. No conservar capturas para marketing ni App Store.
- Preparar dos fixtures sintéticos: uno con datos ficticios visibles y otro con texto que el OCR no detecte para exigir máscara manual.
- Moderar sin enseñar primero dónde están los controles. Pedir permiso antes de grabar audio/pantalla; la grabación es opcional y se borra al cerrar el análisis.
- Usar el mismo guion, dispositivos comparables y orden contrabalanceado cuando se compare un prototipo alternativo. Si no hay alternativa lista, estudiar solo la experiencia actual y no declarar preferencia comparativa.

## Guion y tareas

### Home — AUD-015

**Tarea:** «Una persona te ha pedido una copia de prueba de este documento. Empieza a prepararla y vuelve a Home sin perder el documento si cambias de idea».

Observar si identifica la acción primaria, busca o abre el elemento esperado, distingue Biblioteca/Bóveda y encuentra cómo volver. No indicar el nombre de las secciones antes de la tarea.

### Editor y herramientas — AUD-016

**Tarea:** «Oculta la línea central del documento de prueba que no quedó marcada automáticamente; ajusta la zona para cubrirla y deshaz un cambio».

Observar descubrimiento de creación manual, selección, movimiento, tamaño, Undo/Redo y exportación. Con tecnología asistiva, pedir que realice la misma tarea con el método que usa habitualmente y permitirle explorar las acciones del elemento. Registrar etiquetas o acciones que necesiten interpretación, navegación horizontal y controles no encontrados.

### Modo y perfil — AUD-017

**Tarea:** «El destinatario solo necesita comprobar que el documento es válido. Configura la propuesta que usarías y explícame qué datos crees que se ocultarán, qué hará falta revisar y qué cambia al elegir un perfil».

No corregir ni completar la respuesta. Preguntar después: «¿Qué parte depende del propósito? ¿Qué parte selecciona los tipos de datos? ¿Qué comprobarías antes de compartir?».

## Registro por tarea

Registrar sin datos personales:

- código anónimo de sesión, tipo de experiencia (nueva/recurrente), dispositivo, tamaño de texto, tecnología asistiva y versión de build;
- resultado (completa / completa con ayuda / no completa), tiempo aproximado, primer control elegido, errores críticos, retrocesos, controles no encontrados y cita breve anónima;
- en modo/perfil, si identifica correctamente propuesta por propósito, categorías procesadas, opciones de salida y revisión humana;
- en accesibilidad, método de operación, orden de foco, nombre/hint entendido, éxito al ajustar y estado final tras Undo/Redo.

No inferir satisfacción a partir de rapidez. No contar como éxito una máscara visual que cubra mal el dato o una exportación no revisada.

## Regla de decisión previa

- Cualquier participante que exporte una máscara incorrecta sin detectar el error bloquea una simplificación que reduzca revisión.
- Una barrera que impida a la persona del grupo de accesibilidad crear, ajustar y deshacer una máscara requiere corrección antes de cerrar accesibilidad.
- Si 2 o más participantes nuevos no encuentran la acción primaria o la herramienta manual sin ayuda, prototipar una alternativa y comparar antes de cambiar el orden de Home o del toolbar.
- Si 2 o más describen modo y perfil como la misma operación, iterar el texto explicativo y repetir una ronda breve; no fusionar lógica sin evidencia de equivalencia.
- Con 6–8 sesiones, estas reglas activan investigación y un siguiente prototipo; no justifican afirmaciones de mejora poblacional.

## Resultado de esta fase

Sesiones realizadas: **0**. Hallazgos de participantes: **ninguno disponible**. Las recomendaciones de rediseño siguen pendientes hasta ejecutar el protocolo.
