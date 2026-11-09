# Traspaso a fase 03 — validación empírica y cuentas de prueba

**Tarea:** 251, `fase-03-validacion-empirica-y-cuentas-de-prueba`.  
**Punto de partida:** fase 02 añadió las salvaguardas y pasó 36 tests unitarios y 4 recorridos UI dirigidos. El código ya no debe tratarse como hipótesis de usabilidad: validar el comportamiento con personas, lectores de pantalla, dispositivos y cuentas aisladas.

## Trabajo ordenado

### 1. Tecnología asistiva y iPad — AUD-011, AUD-016, AUD-018

- Probar con VoiceOver que el control “Añadir máscara” se encuentra, se activa, se selecciona y se ajusta; comprobar el nombre y el hint, y verificar que Undo/Redo anuncian el estado correcto.
- Repetir con Voice Control y Dynamic Type AX5: creación, corrección geométrica, cambio de herramienta y exportación con confirmación de riesgo OCR cuando aparezca.
- Registrar etiquetas pronunciadas, orden de foco, foco atrapado, hit targets que no se puedan activar y posición de la máscara respecto a la página.
- Ejecutar en iPhone y iPad; no inferir navegación en pantalla grande desde un único simulador iPhone.
- Revisar los issues que el gate marca como no accionables. Mantener la excepción solo si se sigue registrando el diagnóstico y existe cobertura directa para la interacción equivalente.

### 2. Borrado de Bóveda — AUD-012

- Mantener documentos sintéticos y una cuenta CloudKit de prueba sin otros datos.
- Verificar tres estados: cancelar deja documento/assets/cola remota intactos; confirmar completa el borrado local con estado visible; si CloudKit falla, el estado de reintento no presenta el documento como sincronizado.
- Ejecutar online y offline, reconectar y revisar que la cola remota converge sin duplicar ni recuperar el documento borrado.
- No usar la cuenta personal del entorno ni activar sincronización sobre documentos reales.

### 3. Cuota agregada — AUD-014

- Preparar dos dispositivos de prueba en la misma Cuenta de Apple y una cuenta distinta, todas sin documentos personales.
- Probar incrementos, estado sin red, reconexión y reinicio de app; comprobar que el agregado no disminuye por una réplica atrasada y que no se transfieren título, contenido ni estado de Bóveda.
- Registrar claramente los límites de cada corrida. No usar rutinas de reset que limpien Keychain/KVS compartidos fuera de un contenedor de test aislado.

### 4. Estudio moderado de Home, editor y modelo mental — AUD-015, AUD-016, AUD-017

- Usar el protocolo existente `15_GUIA_ESTUDIO_USABILIDAD.md`: 6–8 sesiones exploratorias, personas nuevas y recurrentes, al menos una persona con tecnología asistiva habitual si es posible.
- Medir éxito, éxito con ayuda, error crítico, control que intentaron primero, retrocesos y tiempo aproximado; no recolectar documentos ni PII.
- No rediseñar ni esconder controles por preferencia interna. Aplicar las reglas de decisión previas del protocolo y documentar qué resultado cambiaría la recomendación.
- Si una persona exporta una máscara incorrecta sin detectar el error, no simplificar el control de revisión.

### 5. Preferencia de temas estacionales — AUD-021

- Verificar que tema base permanece disponible, que aceptar/rechazar/posponer se persiste por ocurrencia y que sonido sigue apagado hasta elección explícita.
- Probar Reduce Motion y anuncio del banner con VoiceOver; registrar zona horaria y fecha sintética, no esperar al calendario real.
- El WIP está protegido en tareas 247/248; revisar su estado antes de cambiarlo.

### 6. Release baseline

- La consulta ASC del 8 nov 2026 encontró build remoto 1162026102502 y build local 1162026102501. Confirmar qué binario corresponde al árbol antes de decidir un nuevo release.
- Cualquier cambio de build number o publicación pertenece a un flujo de release separado. La consulta de fase 02 fue de solo lectura; no actualizar ficha, build remoto, precios ni metadata desde esta tarea.

## Criterio de salida

Fase 03 puede cerrarse cuando haya: resultados documentados de sesiones; operación asistiva completa o correcciones trazables; cancelación y confirmación de borrado probadas con el ciclo remoto aislado; reconciliación de cuota en las combinaciones descritas; revisión estacional; y baseline ASC con fecha/fuente. Un test verde aislado no equivale a aceptación de usuarios, certificación de accesibilidad, ni garantía de detección OCR.
