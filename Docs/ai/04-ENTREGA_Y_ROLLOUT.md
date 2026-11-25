# Entrega y rollout de IA híbrida en MaskID

Fecha: 21 de noviembre de 2026.

## Función y valor para el usuario

La app ya ofrece OCR asistido por Foundation Models en la importación y en la relectura OCR del inspector. Esta entrega lo convierte en una ayuda más segura: completa campos vacíos con frases verificables, mantiene la página y evidencia reales, y deja la revisión y las máscaras bajo control de la persona. La app conserva OCR Vision y reglas deterministas como su ruta esencial.

En `CaptureView`, el modelo puede completar campos ausentes a partir de observaciones de todas las páginas, pero el tipo de documento, el título y la geometría siguen bajo autoridad determinista/Vision. En `OCRSheetView`, el análisis local opera sobre la página que posee las cajas que usa el inspector. La UX muestra una nota de procesamiento local; cancelación e identificadores de solicitud impiden que un análisis viejo aplique cambios después de cancelar o salir.

PCC incluye contrato de motor, comprobación de disponibilidad/cuota, consentimiento por análisis, control de cancelación y presentación de fallback. Apple confirmó por correo la asignación del entitlement a la cuenta; la capability administrada se habilitó para el App ID `com.romerodev.shield`, y se verificaron tanto el perfil App Store como la firma final de la IPA. Los flags locales de PCC ya están habilitados; cada solicitud sigue condicionada a la acción explícita de la persona, consentimiento por análisis, disponibilidad del sistema y cuota.

## Compatibilidad, datos y compras

- Deployment target sin cambios: iOS 18. La extracción actual y las reglas deterministas siguen funcionando desde el target mínimo; la mejora local usa `#available(iOS 26.0, *)` y `SystemLanguageModel.isAvailable`.
- PCC usa APIs del SDK instalado y requiere iOS 27, elegibilidad/distribución admitida, Apple Intelligence/red, cuota y consentimiento. Sus llamadas están bajo `#available(iOS 27.0, *)`. En dispositivos o cuentas no elegibles, o si el sistema/cuota no está disponible, se conserva la extracción local/determinista.
- App universal iPhone/iPad; no hay targets macOS, watchOS ni tvOS. La prueba de compilación fue en simulador iOS, no en hardware plegable o dispositivo físico.
- El modelo recibe el texto OCR mínimo necesario y acotado por el `contextSize` reportado. Prompt, respuesta y OCR no se escriben en telemetría. El texto aceptado se guarda en los campos del documento ya existentes, sin migración ni entidad persistente nueva.
- Vault, CloudKit, exportación y selección manual de máscaras conservan sus límites. La IA no ejecuta máscaras ni comparte/exporta documentos.
- StoreKit 2, RevenueCat, trial, derechos, precios y paywall sin cambios.

## Archivos de esta entrega

- `Shield/Views/Capture/CaptureOCRServices.swift`: contrato `@Generable`, router comprobable, puertas PCC, uso de context size/cuota, validación grounded que conserva el texto OCR literal y omite modelos/cuota si no quedan campos vacíos.
- `Shield/Views/Capture/CaptureView.swift`: integra candidatos validados sin permitir al modelo cambiar clasificación/título y reconstruye evidencia por página.
- `Shield/Views/Editor/OCRSheetView.swift`: nota local, acción PCC condicionada, explicación/consentimiento de datos sensibles, cuotas, cancelación y resultados localizados.
- `Shield/Localization/Strings/Editor.xcstrings` y `ShieldTests/LocalizationLanguageTests.swift`: cadenas ES/EN y comprobaciones de presencia.
- `ShieldTests/OCREvidenceTests.swift`: 32 escenarios de grounding y pruebas de integridad, procedencia, router y fallback.
- `Docs/ai/00-AUDITORIA.md`, `01-OPORTUNIDADES_Y_PRIORIZACION.md`, `02-ARQUITECTURA.md`, `03-EVALUACION.md` y este documento.
- `tasks/TASKS.md` y `tasks/details/272-auditoria-ia-hibrida-foundation-models.md`: registro del trabajo mediante `scripts/task.sh`.

## Riesgos residuales y rollback

- OCR puede omitir o leer mal texto; una frase grounded todavía podría pertenecer a un campo distinto. Los campos siguen siendo sugerencias revisables; no se afirma cobertura total ni se generan máscaras desde el modelo.
- El corpus sintético prueba el validador, no la precisión del modelo. Evaluar con set anonimizado/sintético antes de promocionar utilidad.
- `onDeviceFeatureEnabled`, `privateCloudFeatureEnabled` y `privateCloudEligibilityVerified` son flags locales de rollback. Poner el flag local o los dos flags PCC en `false` retorna a extracción determinista, sin quitar OCR ni cambiar permisos o datos. PCC solo se intenta en la acción explícita desde el inspector y con consentimiento por análisis; el fallback no transmite a terceros.
- Un fallo o límite PCC, si la ruta se activa con consentimiento válido, da lugar a un único intento local; si local también falla se conserva el OCR determinista. No hay reintento remoto automático.
- Sin migración, rollback del binario no requiere conversión de datos. Los campos aceptados siguen siendo campos OCR existentes.

## PCC: evidencia observada y gestión manual pendiente

1. El correo de Apple Developer Relations confirma la asignación del entitlement a la cuenta. Apple documenta Small Business Program y menos de dos millones de primeras descargas conforme a sus reglas como condiciones de elegibilidad. No se verificó por separado el estado de inscripción ni el total agregado de la cuenta; los informes accesibles no ofrecieron evidencia suficiente del agregado. La asignación y la capability habilitada son evidencia directa de configuración aceptada por Apple, pero el Account Holder debe mantener las condiciones externas vigentes.
2. El App ID principal `com.romerodev.shield` (`7BX79RLCY5`) lista `PRIVATE_CLOUD_COMPUTE` entre sus capabilities. `Shield/Shield.entitlements` declara `com.apple.developer.private-cloud-compute = true` solo para la app principal.
3. Se crearon perfiles App Store gestionados desde ASC con distribución para la app y extensiones. El perfil principal `436DJHXKAZ` incluye PCC, bundle ID `com.romerodev.shield` y `get-task-allow=false`. La exportación firmada se verificó: `asc ipa-info --verify-signature` reporta `valid`, y `codesign --verify --deep --strict` valida app y extensiones. El perfil PCC se conserva en `.asc/artifacts/signing/MaskID-AppStore-PCC-436DJHXKAZ.mobileprovision`.
4. La IPA 1.2.0/build `10112026091404` (ASC build `37f4b70e-2273-4805-ac60-d52daad3971c`) se subió a App Store Connect y el build está `VALID`. Está asignado al grupo interno `Shield Internal` (un tester existente); What to Test está configurado en `en-US` y `es-ES`. No se enviaron invitaciones ni se envió la versión a revisión de App Store.

Antes de activar la UI PCC, un Account Holder/Admin debe:

1. El Account Holder debe mantener la inscripción y el umbral de primeras descargas requeridos por Apple; que el entitlement y los perfiles estén configurados no sustituye esas condiciones continuas.
2. Instalar la build interna `1.2.0 (10112026091404)` y probar el flujo PCC en dispositivo compatible con iOS 27/Apple Intelligence/red, con documentos sintéticos. Confirmar consentimiento, cancelación, cuota, disponibilidad y fallback local/determinista.
3. Revisar el aviso de privacidad y publicar la actualización de la política legal alojada antes de una futura publicación pública. La versión local de `Docs/legal/privacy.html` documenta que solo se envía texto OCR mínimo después del consentimiento; la página remota no se publicó en esta tarea.
4. Si Apple retira la elegibilidad o se decide pausar PCC, poner `privateCloudFeatureEnabled` o `privateCloudEligibilityVerified` en `false` en una build posterior; no se requiere SKU ni límite de uso comercial.

La ruta local/determinista permanece utilizable mientras estos pasos estén pendientes. Apple detalla elegibilidad y las pruebas admitidas en [Private Cloud Compute](https://developer.apple.com/private-cloud-compute/) y la gestión del entitlement en [Provisioning with managed capabilities](https://developer.apple.com/help/account/reference/provisioning-with-managed-capabilities/). No se publicó, subió ni envió nada a revisión.

## Privacidad, ASO y creatividades

La nota añadida explica el procesamiento local y que PCC es opcional, requiere consentimiento y transmite texto OCR mínimo a Apple. No se modificaron ni publicaron Privacy Nutrition Labels ni metadata de la ficha de App Store Connect. La página remota de privacidad tampoco se publicó. Antes de una futura liberación pública, aplicar la política actualizada y revisar las declaraciones App Privacy con el flujo real de envío y consentimiento.

Texto opcional para una futura ficha, cuando se libere y revise la UX:

- ES: “Completa campos OCR que el reconocimiento no detectó. Revisa el texto de origen antes de aplicar máscaras.”
- EN: “Fill OCR fields that recognition missed. Review the source text before applying redactions.”

No promete detección completa ni presenta el contenido como consejo. No se generaron capturas de marketing; si se preparan, el repositorio exige activar y verificar el tema base de MaskID antes de capturar.

## Criterio de salida

`ShieldTests` firmada pasó 182 tests y omitió 1 (183 totales); `OCREvidenceTests` pasó 22/22 y `SecurityPrivacyTests` 13/13. El archive y la IPA de distribución fueron validados. Las pruebas UI focalizadas para abrir el flujo OCR vacío y auditar accesibilidad ES/EN pasaron 2/2. `ShieldUITests` completa sigue pendiente: el intento aislado general solo ejecutó 3 de 65 casos (1 pasó, 2 fallaron al retirarse el simulador/terminar una prueba). El build `1.2.0 (10112026091404)` está `VALID`, asignado a `Shield Internal`, y tiene notas ES/EN. No se enviaron invitaciones ni una revisión beta o de App Store. La interacción PCC en hardware real no se ha ejecutado.
