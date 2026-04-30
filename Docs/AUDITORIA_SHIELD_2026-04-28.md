# Auditoría profunda Shield (técnica + producto + monetización)

Fecha: 28 de abril de 2026  
Estado de build: compila y ejecuta en simulador (`iPhone Air`, iOS 26.2)

## Estado de ejecución (actualizado)

Aplicado en código:
- Lock screen reforzado contra loop de Face ID:
  - auto-disparo biométrico controlado por fase activa y único intento por aparición.
  - opción PIN siempre visible en la misma pantalla.
  - desbloqueo exitoso centralizado (`completeSuccessfulUnlock`) para evitar relock inmediato.
- Política de seguridad para biometría:
  - se mantiene requisito de PIN para habilitar Face ID/Touch ID.
- Escaneo profesional mejorado:
  - escaneo multipágina real con VisionKit.
  - revisión intermedia por página con filtros, geometría, recorte y correctores.
  - importación desde fotos ahora acepta una o múltiples imágenes.
  - presets rápidos de escaneo y reset por página/global.

Pendiente inmediato:
- test funcional manual en simulador/dispositivo para confirmar fin definitivo del loop en todos los escenarios de foreground/background.
- añadir editor de perspectiva por 4 puntos (geometría avanzada real) para completar el alcance Pro.

## 1) Diagnóstico ejecutivo

Shield ya tiene una base valiosa: importación desde cámara/fotos/archivos, OCR local, redacción visual, exportación PDF/imagen, StoreKit 2 y cifrado local con Keychain + AES.  
El problema no es “falta total de features”; el problema es de **consistencia de seguridad, robustez de flujo y producto comercial**.

Evaluación global (0-100):
- Seguridad y privacidad: **58**
- Calidad técnica/arquitectura: **55**
- UX/UI profesional: **50**
- Fiabilidad funcional (edge cases): **48**
- Monetización y growth: **42**
- Preparación App Store/compliance: **45**
- Total ponderado: **50/100**

## 2) Hallazgos críticos de código (priorizados)

## P0 — Riesgo de acceso no autenticado (debe corregirse primero)

1. Bypass de bloqueo principal si no se puede evaluar passcode del sistema.  
   Evidencia: `authenticatePasscode()` desbloquea sin autenticar cuando `canEvaluatePolicy` falla.  
   Archivo: `Shield/Views/Onboarding/OnboardingView.swift`, líneas 424-430.

2. Bóveda se desbloquea sola si no hay biometría y no existe PIN.  
   Evidencia: fallback directo a `isUnlocked = true`.  
   Archivo: `Shield/Views/Vault/VaultView.swift`, líneas 237-243.

3. PIN sin bloqueo temporal real tras intentos fallidos.  
   Hay mensaje de error, pero no hay rate limit ni cooldown persistente.  
   Archivo: `Shield/Views/Vault/VaultView.swift` (sección `PINEntryView`).

## P1 — Riesgo funcional y de confianza del usuario

1. Scanner de documentos ignora multipágina de VisionKit (usa solo página 0).  
   Archivo: `Shield/Views/Capture/CaptureView.swift`, líneas 516-520.

2. OCR de PDFs multipágina usa solo la primera página para campos.  
   Archivo: `Shield/Views/Capture/CaptureView.swift`, líneas 327-329.

3. “Preferencias” de exportación/autolock/háptica no gobiernan la app (solo se guardan en `UserDefaults`).  
   Evidencia: claves solo aparecen en `SettingsView`.  
   Archivo: `Shield/Views/Settings/SettingsView.swift` + búsqueda global.

4. Bug lógico en háptica: siempre inicia en `true`.  
   `UserDefaults... || true`  
   Archivo: `Shield/Views/Settings/SettingsView.swift`, línea 17.

5. Cambio de estilo de redacción recrea objetos y rompe identidad (`UUID`) de la máscara seleccionada.  
   Archivo: `Shield/ViewModels/EditorViewModel.swift`, líneas 207-210.

## P2 — Profesionalización / preparación comercial

1. Paywall sin enlaces funcionales a privacidad/términos.  
   Archivo: `Shield/Views/Paywall/PaywallView.swift`, líneas 232-244.

2. Localización incompleta en pricing/paywall (hardcoded en español).  
   Archivo: `Shield/Views/Paywall/PaywallView.swift`, líneas 317-341.

3. Falta `PrivacyInfo.xcprivacy` en el target (no se encontró archivo).  
   Riesgo de rechazo con Required Reason APIs (por ejemplo `UserDefaults`).

4. Auto-lock declarado en settings pero no aplicado a ciclo de vida (`scenePhase`) ni inactivity timer.

## 3) Benchmark de mercado (abril 2026)

Patrones observados en competidores:
- **On-device + no cloud** ya es “baseline”, no diferenciador suficiente.
- Las apps top comunican “**redacción irreversible**”, no solo overlay visual.
- Se está moviendo el mercado hacia **pre-share workflow** (desde Share Sheet) y **batch**.
- Pricing dominante para apps niche privacy:
  - freemium con límites fuertes + suscripción anual (ej. ShareWipe)
  - o one-time low ticket (ej. pxCut, NIX Pro)

Referencias clave:
- ShareWipe: plan Free con límites y watermark; Pro anual `39.99` USD, y posicionamiento “pre-share privacy layer”.  
  <https://sharewipe.com/en>
- NIX Redaction App (App Store): free + IAP “NIX Redaction Pro”; mensaje fuerte de no recolección de datos y redacción PDF con destrucción de capa de texto.  
  <https://apps.apple.com/in/app/nix-redaction/id6758555124>
- PDF Redact App (App Store): “3 free exports”, presets por caso (PII, bank, tax, medical, legal), OCR + flattened PDF.  
  <https://apps.apple.com/us/app/pdf-redact/id6761928221>
- pxCut: one-time Pro `4.99` USD y watermark en Free.  
  <https://pxcut.com/>
- Adobe Acrobat pricing + redacción en suite Pro (competidor macro de referencia de valor percibido).  
  <https://www.adobe.com/acrobat/pricing.html>

Implicación directa para Shield:
- Si solo ofreces “blur/blackout + export”, compites por precio bajo.
- Para ganar margen, debes vender **confianza verificable + automatización real + flujo ultra rápido**.

## 4) Estrategia Free vs Premium recomendada

Modelo recomendado: **Freemium product-led + Pro anual principal + Lifetime opcional**.

## Free (debe dar valor real, no demo inútil)

Incluye:
- Importar foto/PDF/cámara.
- Redacción manual básica (2 estilos).
- OCR básico local.
- 3 exportaciones/semana (no por vida, para reenganche continuo).
- Watermark “Protected with Shield Free”.
- Edición básica de escaneo por página (auto-enhance + recorte simple).
- Sin batch, sin presets avanzados, sin Share Extension.

Objetivo:
- Activación rápida y percepción de utilidad real en el primer uso.

## Pro (core)

Incluye:
- Exportaciones ilimitadas.
- Todos los estilos.
- Presets por caso de uso (alquiler, viaje, laboral, legal, salud, banca).
- Batch multipágina/multiarchivo.
- Share Extension para limpiar “justo antes de compartir”.
- PDF hardening: flatten/raster + limpieza metadatos + password + permisos.
- Vault completo + auditoría local de acciones.
- Plantillas de reglas guardables (“si detectas IBAN + email + teléfono => redacta”).
- Scan Pro completo: geometría avanzada, filtros pro y ajustes por lote.

Pricing recomendado (testable):
- Mensual: `4.99`
- Anual: `34.99` (ancla principal)
- Lifetime: `79.99` (ancla alta, opcional)

Racional:
- Posiciona por debajo de suites grandes (Adobe/Xodo/PDF Expert), por encima de utilidades simples.
- Mantiene margen para campañas de descuento intro sin degradar marca.

## 5) Roadmap de corrección y terminación (12 semanas)

## Fase 0 (Semana 1) — Seguridad y cumplimiento mínimo viable

Entrega:
- Corregir bypasses P0 (lock screen + vault).
- Lockout de PIN (backoff exponencial + cooldown persistente).
- Implementar `PrivacyInfo.xcprivacy`.
- Añadir links reales de Privacy/Terms en app y paywall.

KPI de salida:
- 0 rutas de desbloqueo sin autenticación.
- Build con privacy manifest válido.

## Fase 1 (Semanas 2-4) — Robustez funcional y calidad percibida

Entrega:
- Scanner multipágina real (VisionKit full scan).
- OCR multipágina + consolidación de entidades.
- Pipeline Scan Pro:
  - Corrección de perspectiva/geometría (deskew + transform).
  - Recorte manual y automático por página.
  - Filtros de legibilidad (B/N documento, contraste, brillo, nitidez, reducción de ruido).
  - Rotación/reordenado antes de guardar/exportar.
- Aplicar de verdad defaults de settings (export quality/format, auto-lock).
- Mejoras UX editor: estabilidad de IDs de redacciones, manejo de errores de export, estados vacíos coherentes.

KPI:
- Crash-free sessions > 99.5%
- Export success rate > 99%

## Fase 2 (Semanas 5-8) — Diferenciadores competitivos

Entrega:
- Share Extension (“clean before share”).
- Redacción por reglas (PII entities + regex packs).
- Hardening PDF verificable (metadata scrub + irreversible apply report).
- “Privacy Check Score” antes de exportar.
- Presets de escaneo por tipo documental (DNI/pasaporte/licencia/comprobante) y aplicar ajustes a todas las páginas.

KPI:
- Tiempo mediano “importar->exportar seguro” < 45s
- Uso semanal de presets > 40% de sesiones de edición

## Fase 3 (Semanas 9-12) — Monetización y growth

Entrega:
- Reescritura del paywall por contexto (trigger-based).
- Eventos de producto (funnel completo).
- Experimentos A/B en oferta y mensaje.
- Promoted IAP + ofertas intro/win-back.

KPI:
- Free->Pro trial start rate: +30%
- Trial->paid conversion: +20%
- D30 retention de Pro: +15%

## 6) Plan de conversión a Premium (operativo)

Triggers de upsell (sin dark patterns):
- Al agotar exportaciones semanales.
- Al intentar batch/multipágina.
- Al intentar exportar sin watermark.
- Al usar Share Sheet para tercer archivo del día.

Mensajería por contexto:
- “Necesitas quitar marca de agua para envío profesional”.
- “Este PDF aún contiene metadatos identificables; Pro los limpia automáticamente”.
- “Ahorra X min por documento con reglas automáticas”.

Experimentos A/B prioritarios:
1. Annual-first vs Monthly-first.
2. Trial 7 días vs descuento intro 40%.
3. Paywall por “riesgo evitado” vs “features”.
4. Oferta win-back en día 7 post-cancelación.

Implementación técnica recomendada:
- Mantener StoreKit 2.
- Añadir instrumentación de eventos en embudo:
  - `import_started`, `import_completed`
  - `risk_detected`, `redaction_applied`
  - `export_attempted`, `export_success`
  - `paywall_viewed`, `purchase_started`, `purchase_success`, `restore_success`

## 7) Backlog priorizado (acción inmediata)

Top 10:
1. Bloquear bypass en `authenticatePasscode`.
2. Bloquear fallback abierto de bóveda sin auth.
3. Implementar PIN rate limit persistente.
4. Añadir `PrivacyInfo.xcprivacy`.
5. Activar links de privacidad/términos en paywall.
6. Scanner multipágina real.
7. OCR multipágina consolidado.
8. Aplicar defaults de export/auto-lock/háptica.
9. Corregir preservación de ID al cambiar estilo de máscara.
10. Implementar tracking de embudo de conversión.

## 10) Requerimiento nuevo incorporado: Escaneo + Corrección visual

Objetivo:
- Transformar la captura en flujo “scan-to-clean” profesional antes de redactar.

Alcance:
- Escaneo de 1 o N páginas.
- Herramientas por página: geometría, recorte, filtros/correctores.
- Aplicación individual o por lote a todo el documento.

Implementación:
1. Modelo `ScanPageAdjustment` por página (crop, rotation, preset, sliders).
2. Pantalla intermedia `ScanReviewView` antes de crear `DocumentItem`.
3. Procesado con CoreImage/CIFilter + transformaciones geométricas.
4. Persistir páginas corregidas para OCR/redacción/export.
5. Instrumentar eventos: `scan_adjustment_opened`, `scan_adjustment_applied`, `scan_batch_applied`.

Empaquetado Free/Pro:
- Free: auto-enhance + recorte básico.
- Pro: geometría manual avanzada, filtros pro y aplicar a todas las páginas.

## 8) Riesgos si no se ejecuta este plan

- Riesgo real de fuga de confianza por rutas de desbloqueo débiles.
- Diferenciación insuficiente frente a apps “privacy utility” más simples y baratas.
- Conversión baja por paywall genérico sin gatillos contextuales.
- Riesgo de rechazo/retrabajo App Store por compliance incompleto.

## 9) Fuentes externas usadas (mercado y políticas)

- ShareWipe (pricing/features): <https://sharewipe.com/en>  
- NIX Redaction (App Store): <https://apps.apple.com/in/app/nix-redaction/id6758555124>  
- PDF Redact App (App Store): <https://apps.apple.com/us/app/pdf-redact/id6761928221>  
- pxCut (pricing/features): <https://pxcut.com/>  
- Adobe Acrobat pricing: <https://www.adobe.com/acrobat/pricing.html>  
- App Review Guidelines (Apple): <https://developer.apple.com/appstore/resources/approval/guidelines.html>  
- Required Reason API (Apple): <https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api>  
- Privacy manifest overview (Apple): <https://developer.apple.com/documentation/bundleresources/adding-a-privacy-manifest-to-your-app-or-third-party-sdk>  
- Third-party SDK privacy requirements (Apple): <https://developer.apple.com/support/third-party-SDK-requirements/>  
- Promoted IAP (Apple): <https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/promote-in-app-purchases/>  
- Win-back offers (Apple): <https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-win-back-offers>
