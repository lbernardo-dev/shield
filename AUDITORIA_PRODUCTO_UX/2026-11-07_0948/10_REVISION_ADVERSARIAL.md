# Revisión adversarial

## Revisión de hallazgos

- **UX-001 categorías icon-only:** confirmado en layout compacto, pero se rebaja a P3. Los labels de accesibilidad existen y Home cambia a etiquetas visibles en Dynamic Type de accesibilidad (HomeView.swift:539-548). Falta prueba de descubribilidad.
- **UX-002 herramientas icon-only:** confirmado como patrón visual, no como bloqueo. Siete controles tienen labels, hints y estado seleccionado, y el activo se hace visible. No recomendar retirar ni fusionar sin prueba.
- **“Teams” como promesa incumplida:** no confirmado. La documentación incluye personas/equipos pero aclara que colaboración es futura; solo se recomienda aclarar posicionamiento (P3).
- **Complejidad/feature creep global:** hipótesis no demostrada. La variedad funcional tiene relación razonable con flujo sensible, almacenamiento y entradas de sistema. Sin uso/observación no procede llamar relleno a widgets, App Intents, Vault ni herramientas.
- **Falta de consentimiento analítico inicial:** inicialmente se describió solo como borrador interno; al ampliar la búsqueda se encontró la misma afirmación en la fuente local de política de privacidad en inglés y español. ContentView fuerza la hoja únicamente para QA y Settings permite el control. DOC-001 se eleva a P2; no se verificó qué HTML está publicado externamente.
- **Accesibilidad de navegación:** no se afirma que tabs sean inaccesibles. Solo se observa que nombres visuales se ocultan en AX Dynamic Type mientras semántica persiste. Se eleva como prueba faltante de E2E, no incumplimiento demostrado.
- **Privacidad de documentos:** no se halló evidencia de filtración. KVS contiene contador de cuota escalar; impacto es transparencia/expectativa, no fuga.
- **Tema estacional:** HEAD programa el tema y limita elección manual/base a Pro; existe WIP local tarea 247 con cambios de consentimiento. El WIP no se confunde con release ni se validó. Riesgo temporal/contextual, no P1.
- **Sonido:** default/copy/comentario se contradicen en fuentes. Reproducción es inferida por código; volumen bajo y mute switch reducen exposición. Se mantiene P2 condicional, no P1.
- **Baseline de versión:** hay archivos locales desactualizados, pero ASC no se consultó; no afirmamos que publicación actual sea 1.1.5 ni que la revisión siga activa.

## Evidencia a favor de conservar

OCR local, revisión humana, máscaras manuales, verificador de salida y Vault protegen exactitud, control o continuidad. Su eliminación podría debilitar el trabajo central. No hay analítica de uso ni entrevistas que permitan discriminar funciones complementarias de bajo valor.

## Desacuerdos pendientes

Sin observación de interfaz no puede establecerse densidad real, tiempo de tarea, descubribilidad, prominencia del paywall, tamaño de toque ni salida de flujos profundos. Las prioridades P2 de apariencia, audio y test de accesibilidad son evidencia de diseño/código o brecha preventiva, con impacto real incierto.

## Sesgos/limitaciones

Inspección favorece lo explícito en fuentes; no ve estado visual, errores de integración ni comportamiento de versiones publicadas. Auditoría no incluye usuarios, reseñas o analítica. Cinco roles paralelos aportan contraste, pero no son investigación de mercado. No se concede certeza por acuerdo entre auditores cuando falta ejecución.

