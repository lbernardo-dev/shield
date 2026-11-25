# 272-auditoria-ia-hibrida-foundation-models

- Number: 272
- Slug: auditoria-ia-hibrida-foundation-models

## Resultado

- Auditoría y priorización específicas de MaskID en `Docs/ai/00-AUDITORIA.md` y `01-OPORTUNIDADES_Y_PRIORIZACION.md`; arquitectura, evaluación y entrega en `02-ARQUITECTURA.md`, `03-EVALUACION.md` y `04-ENTREGA_Y_ROLLOUT.md`.
- Endurecimiento del enriquecimiento OCR local: respuestas estructuradas solo rellenan campos vacíos si reproducen una secuencia completa del OCR, conservan la puntuación, retienen evidencia/página/caja Vision y usan confianza OCR. El tipo documental, los valores deterministas y las máscaras no se delegan al modelo.
- UI del inspector localizada ES/EN para procesamiento local y ruta PCC opt-in, con consentimiento por análisis, cuota, cancelación y fallback PCC→local→determinista. PCC queda apagado hasta verificar eligibility, App ID y perfil.
- El correo de Apple aportado confirma la asignación del entitlement a la cuenta. El IPA 1.1.8 existente no incluye la clave PCC en el perfil embebido; la API pública App Store Connect no expone la capability gestionada y `asc web auth status` no tiene sesión de Developer Portal. Requiere acción externa de Account Holder/Admin; ver entrega manual.
- En continuación de la auditoría se revisó ASC Analytics en modo de solo lectura. Hay solicitudes existentes, pero la recuperación de instancias App Downloads fue limitada por HTTP 429 con espera de 37m59s antes de recoger segmentos o filas. No se creó ninguna solicitud nueva; el total de primeras descargas y el estado Small Business Program siguen pendientes de verificación.
- La suite focalizada compiló y ejecutó la app en el simulador iOS 27.2. `OCREvidenceTests`: 21/21 pasadas; harness contiene 32 escenarios sintéticos. `ShieldTests`: 180 pasadas, 1 omitida, 1 fallo en `renewalDisclosureMakesTheNextChargeClear` por el texto de renovación existente y ajeno al diff. `ShieldUITests` (65 tests) quedó pendiente por espacio/runner; se documentaron tres intentos sin tests ejecutados en task 273 y en `Docs/ai/03-EVALUACION.md`.
- `git diff --check` y parseo JSON de localizaciones editadas pasaron.
- Result bundles y temporales conservados; no se limpió ningún cache ni archivo.

## Notes

