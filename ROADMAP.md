# Shield (MaskID) - Product & Technical Roadmap

> **Visión**: Convertir a Shield en la herramienta de referencia en el ecosistema Apple para la anonimización, redacción documental y protección de privacidad 100% on-device (Zero-Knowledge).

---

## Estado Actual (Baseline v1.0)
- ✅ **Motor Híbrido OCR**: Detección determinista de PII (DNI, NIE, IBAN, Pasaportes/MRZ, Emails, Teléfonos).
- ✅ **Rasterización Segura**: Exportación PDF libre de capas de texto residuales o metadatos sensibles.
- ✅ **Bóveda Cifrada**: Cifrado local con clave derivada de Secure Enclave / Biometría y sincronización privada vía CloudKit.
- ✅ **Accesibilidad & HIG**: Hit targets $\ge 44\times 44\text{ pt}$, soporte Dynamic Type AX5 y Reduced Motion en toda la suite.
- ✅ **100% Cobertura de Integración**: Suite completa de pruebas unitarias y XCUITest automatizadas.

---

## 🗺️ Roadmap de Evolución

```
                    ┌────────────────────────────────────────────────────────┐
                    │                   SHIELD ROADMAP                       │
                    └────────────────────────────────────────────────────────┘
                                               │
    ┌──────────────────────┬───────────────────┴──────────────────┬──────────────────────┐
    ▼                      ▼                                      ▼                      ▼
[ Fase 1: Q3-Q4 ]     [ Fase 2: Q1 ]                         [ Fase 3: Q2 ]         [ Fase 4: Q3+ ]
Integraciones iOS 18   IA Contextual On-Device                Automatización Avanzada Expansión Multiplataforma
• Control Center       • Redacción Semántica (CoreML/SLM)     • Acciones Atajos      • macOS Native (Metal)
• Action Button        • Perfiles Personalizados              • Watermarking Hash    • iPadOS + Apple Pencil
• App Intents          • Detección Contextual Avanzada        • Batch Background     • CloudKit Sharing
```

---

## Fase 1: Integración Profunda con iOS 18 & Nuevas APIs
**Objetivo**: Reducir la fricción de entrada al mínimo (< 2 segundos desde la intención hasta la captura protegida).

1. **Controles de Centro de Control y Pantalla de Bloqueo (iOS 18+ Controls API)**
   - Control Widget interactivo para lanzar directamente la cámara de redacción o la importación desde fototeca.
2. **Soporte de Botón de Acción (Action Button) & App Shortcuts**
   - Configuración de disparador directo para el Action Button en iPhone 15 Pro / 16.
   - Atajos parametrizados con `AppIntents` (`RedactDocumentIntent`, `QuickScanIDIntent`).
3. **Mejoras en la Share Extension**
   - Soporte para recibir múltiples imágenes/PDFs en un único envío desde Fotos, Mail o Archivos sin abrir la aplicación principal.

---

## Fase 2: Inteligencia Semántica On-Device (Zero-Knowledge AI)
**Objetivo**: Superar las limitaciones de los patrones regex fijos para detectar información confidencial por contexto.

1. **Redacción Semántica Contextual con CoreML / SLM**
   - Integración de modelos lingüísticos compactos on-device para detectar:
     - Nombres de personas en contratos o formularios.
     - Direcciones físicas no estructuradas.
     - Diagnósticos médicos y referencias de salud.
     - Importes económicos y cláusulas de confidencialidad.
   - Procesamiento 100% en el Neural Engine sin enviar datos a servidores externos.
2. **Perfiles de Anonimización Especializados**
   - Plantillas predefinidas configurables por el usuario:
     - 📋 *Perfil Inmobiliario*: Oculta salarios, cuentas bancarias y datos de terceros en nóminas y contratos.
     - 🩺 *Perfil Médico*: Oculta historiales clínicos, firmas y números de colegiado.
     - ⚖️ *Perfil Legal / RRHH*: Oculta partes no firmantes y cláusulas monetarias.
3. **Estilos de Máscara Dinámicos y Tematizados**
   - Opciones avanzadas de censura visual: desenfoque gaussiano de alta frecuencia, pixelado adaptable y sellos con código de redacción (ej. `[CENSURADO - ART. 9 RGPD]`).

---

## Fase 3: Automatización Avanzada y Flujos de Trabajo
**Objetivo**: Permitir a profesionales y empresas integrar Shield en sus flujos diarios de procesamiento.

1. **Acciones de Atajos (Shortcuts) para Procesamiento por Lotes**
   - Acción de Atajo: `Anonimizar Documentos con Perfil [X]` para procesar carpetas completas en segundo plano.
2. **Marcas de Agua y Hash de Integridad Criptográfica**
   - Opción de insertar sello de seguridad con código QR o hash SHA-256 en el pie de página para verificar la autenticidad y no manipulación posterior del documento exportado.
3. **Clasificación y Organización Automática en la Bóveda**
   - Etiquetado inteligente de documentos mediante metadatos locales (tipo de documento, fecha de detección, perfil aplicado) facilitando la búsqueda cifrada instantánea.

---

## Fase 4: Ecosistema Multiplataforma y Colaboración
**Objetivo**: Llevar la experiencia de privacidad de Shield a todo el ecosistema de trabajo.

1. **Shield para macOS (Pure SwiftUI / Mac Catalyst)**
   - Interfaz de escritorio con soporte de Drag & Drop para procesar lotes masivos de documentos.
   - Aceleración por hardware con Metal y procesamiento multihilo.
   - Quick Look Preview Extension para anonimizar directamente desde el Finder con la barra espaciadora.
2. **Shield para iPadOS & Apple Pencil**
   - Integración completa con PencilKit para redacción manual de precisión milimétrica en planos y esquemas técnicos.
   - Soporte multiventana (Stage Manager) para comparar documento original vs anonimizado lado a lado.
3. **Bóveda Compartida Privada (CloudKit Private Sharing)**
   - Carpetas compartidas cifradas punto a punto entre usuarios autorizados (ej. parejas, equipos de gestión o familias) utilizando CloudKit Sharing sin servidores intermediarios.

---

## 📊 Matriz de Priorización Técnica

| Iniciativa | Impacto Usuario | Complejidad | Dependencias | Prioridad |
|---|---|---|---|---|
| **Control Center & Action Button** | Alto | Baja | iOS 18 SDK | 🔥 P0 (Inmediato) |
| **Share Extension Multi-Doc** | Alto | Media | App Groups / Storage | 🔥 P0 (Inmediato) |
| **Perfiles de Anonimización** | Muy Alto | Media | OCR Pipelines | 🚀 P1 (Corto Plazo) |
| **Shortcuts / Atajos por Lotes** | Alto | Media | AppIntents API | 🚀 P1 (Corto Plazo) |
| **IA Semántica On-Device (CoreML)** | Máximo | Alta | Neural Engine / CoreML | 🧠 P2 (Medio Plazo) |
| **macOS Native App** | Muy Alto | Alta | Arquitectura Unificada | 💻 P3 (Largo Plazo) |
| **iPadOS + Apple Pencil Support** | Alto | Media | PencilKit | ✏️ P3 (Largo Plazo) |

---

## 🛡️ Principios Innegociables de Arquitectura

1. **Zero-Knowledge por Diseño**: Ni un solo byte de imagen o texto no anonimizado abandona el dispositivo hacia servidores de terceros.
2. **Presupuesto de Memoria Estricto**: El pipeline de procesamiento nunca debe exceder los 150 MB de memoria de trabajo, garantizando estabilidad incluso en terminales con recursos limitados.
3. **Compatibilidad con Lectores de Pantalla y Accesibilidad**: Toda nueva funcionalidad debe cumplir con WCAG 2.1 AA y las guías HIG de Apple para VoiceOver y Dynamic Type.
