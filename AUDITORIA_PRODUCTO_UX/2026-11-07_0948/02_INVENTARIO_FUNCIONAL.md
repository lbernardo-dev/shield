# Inventario funcional

Inventario estático por familias de funciones detectadas en código, documentación y tests. No equivale a verificación de pantallas activas ni a inventario visual exhaustivo: falta ejecutar la app.

| Área / entrada | Trabajo que habilita | Relación | Beneficiarios | Fricción/coste visible | Decisión |
|---|---|---|---|---|---|
| Onboarding: bienvenida, demo, seguridad opcional | Entender y empezar | Habilitadora | Nuevo | Tres etapas, con omisión; no pide cámara ni paywall en la ruta observada | Conservar; medir comprensión |
| Home y CTA importar | Iniciar trabajo | Directa | Todos | Categorías compactas sin texto visible | Simplificar/etiquetar si pruebas muestran baja comprensión |
| Importación de archivos/fotos | Traer material | Directa | Todos | Permisos y variedad de estados no ejecutados | Conservar; probar denegación y recuperación |
| OCR local | Detectar datos | Directa | Todos | Requiere revisión humana; precisión desconocida | Conservar; comunicar incertidumbre |
| Editor y herramientas de máscara | Corregir y proteger | Directa | Todos/avanzados | Siete iconos en tira desplazable, etiquetados en accesibilidad | Conservar capacidad; evaluar jerarquía |
| Exportación + verificador | Obtener copia segura | Directa/confianza | Todos | Resultado y manejo de fallo no ejecutados | Conservar; prioridad de QA |
| Vault cifrado | Guardar/retomar | Habilitadora | Recurrentes | Estados de bloqueo/recuperación no ejecutados | Conservar; no retirar por baja frecuencia |
| Cuota Free / Pro / compras y restauración | Financiación y mayor escala | Comercial | Free/Pro | Límite 10 documentos; exportación sigue disponible | Conservar con comunicación anticipada y prueba de claridad |
| Temas, programación estacional y sonido | Personalizar | Complementaria | Quien desea ambientación | Cambios por fecha; default de audio contradice copy | Hacer efectos opt-in y simplificar control |
| Ajustes de privacidad/analytics | Control de datos | Confianza | Todos | La pantalla de consentimiento inicial solo aparece con argumento de proceso de test | Conservar acceso en Settings; corregir docs internos |
| Sincronización iCloud/KVS | Replicar ciertos datos | Habilitadora | Multi-device | Contador de cuota se replica; disclosure local incompleto | Aclarar y validar alcance |
| Widget | Acceso/resumen | Complementaria | Recurrentes | No verificado | Conservar; revisar accesibilidad |
| Share Extension | Iniciar desde compartir | Directa/entrada alternativa | Recurrentes | No ejecutada; estados de cancelación desconocidos | Conservar; prueba E2E |
| App Intents | Acceso del sistema | Complementaria | Usuarios de atajos/sistema | No se verificó comportamiento | Conservar si las acciones son útiles |
| Localización ES/EN | Usar app en ambos idiomas | Habilitadora | ES/EN | Cobertura más amplia no verificada | Conservar; revisar largos/consistencia |
| Firebase analytics, RevenueCat, CloudKit, Lottie | Servicios transversales | Habilitadora/comercial | Operación | Configuración real y disponibilidad no probadas | Mantener; documentar datos y fallos |

### Decisiones del catálogo

- **Conservar:** OCR local, edición manual, exportación y verificador; son el núcleo de la promesa.
- **Simplificar:** Home compacto y banda de herramientas solo si pruebas de descubribilidad confirman coste. Alternativa conservadora: etiquetas visibles en tamaños compactos o herramientas agrupadas sin quitar acciones.
- **Reubicar:** opciones avanzadas de tema/efectos dentro de Ajustes; validar que el control de apariencia básica siga encontrable.
- **Hacer opcional:** sonido y adornos estacionales; preferencia expresa antes de reproducir.
- **Fusionar:** no se demostró duplicación perjudicial; investigar rutas de importación repetidas antes de unificarlas.
- **Experimentar:** comparar Home actual con etiquetas/jerarquía simplificada en prueba moderada; evaluar tarea completada y errores.
- **Candidata a retirar:** ninguna con evidencia suficiente. La baja frecuencia no se midió y no es justificación.

