# 276-cerrar-ia-hibrida-pcc

- Number: 276
- Slug: cerrar-ia-hibrida-pcc

## Notes

- 2026-11-21: Apple Developer Relations confirmó la asignación del entitlement PCC; `PRIVATE_CLOUD_COMPUTE` aparece habilitada en el App ID `7BX79RLCY5`. La IPA final y el perfil App Store `436DJHXKAZ` contienen `com.apple.developer.private-cloud-compute=true`; firma de distribución verificada.
- Validación firmada: `ShieldTests` 182 pasadas, 1 omitida, 0 fallidas; `OCREvidenceTests` 22/22; `SecurityPrivacyTests` 13/13; UI OCR y accesibilidad ES/EN 2/2.
- `ShieldUITests` completa no está cerrada: una corrida general ejecutó 3/65 casos (1 pasada, 2 fallidos por terminación/retiro del simulador); los dos casos focalizados posteriores pasaron. PCC real no se invocó en hardware; condiciones agregadas de elegibilidad de la cuenta no se comprobaron independientemente. Resultados en `Docs/ai/03-EVALUACION.md` y `04-ENTREGA_Y_ROLLOUT.md`.

