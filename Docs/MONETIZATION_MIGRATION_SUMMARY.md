# Fase 03 — migración de monetización

**App:** MaskID · `com.romerodev.shield`  
**Fecha:** 8 de noviembre de 2026  
**Estado:** implementación local y configuración comercial verificadas; release bloqueado por revisión jurídica, pruebas Sandbox y comprobación de build/versionado.

## Resultado

- Se añadió una única política tipada para acceso temporal, recuperación y paywall obligatorio. El inicio interno no ejecuta StoreKit ni crea una renovación.
- Los nuevos usuarios reciben 15 días naturales Premium tras leer el aviso y activarlo. Instalaciones Free anteriores corroboradas reciben 30 días Premium y 30 días adicionales de solo lectura.
- Se retiraron el contador visible de cuota Free, el gate semanal de exportación, los textos de prueba anual de 7 días y la CTA de prueba de exportación. El contador histórico de documentos permanece solo como evidencia de migración/uso.
- Operaciones de dominio protegen las escrituras además de ocultar/inhabilitar controles. La exportación, recuperación y eliminación de datos propios siguen disponibles al caducar.
- Se conservaron IDs, entitlement `MaskID Pro`, Offerings `default`/`event`, compras ya reconocidas y acceso vitalicio.
- Se eliminó en ASC la oferta introductoria anual para nuevas compras. StoreKit fixture y copy de la app ya no la declaran. ASC/RevenueCat no mostraron ofertas introductorias activas tras el cambio.
- Se actualizó `purchases-ios` a 5.102.3 y `Package.resolved`; la nueva variante de ownership `.assigned` se maneja exhaustivamente.
- No se cambió la versión pública/build final, no se creó archive, no se subió a TestFlight ni se publicó.

## Catálogo aprobado y evidencia

| Producto | Precio ES aprobado | Estado verificado |
|---|---:|---|
| Mensual `com.romerodev.shield.pro.monthly` | 2,99 €/mes | ASC `APPROVED`; RC asignado al entitlement existente |
| Anual `com.romerodev.shield.pro.annual` | 29,99 €/año | ASC `APPROVED`; oferta introductoria activa: 0 territorios/listados en ASC y en la lectura actualizada de RC |
| Vitalicio `com.romerodev.shield.pro.lifetime.unlock` | 49,99 una vez | ASC `NON_CONSUMABLE`, precio ES 49,99 €; entitlement existente |
| Event Annual `com.romerodev.shield.pro.annual.event` | 29,99 €/año actualmente | ASC `APPROVED`, precio ES read-back 29,99 €; RC `event`/`MaskID Pro` |

Precios leídos el 8-11-2026 con `asc --read-only subscriptions pricing summary` y `asc --read-only iap pricing summary`; no fue necesario cambiar precios porque ya coincidían con la aprobación del propietario. No hay producto semanal en la Offering estándar.

## Bloqueos y riesgos que siguen abiertos

- `LEGAL_RELEASE_BLOCKER`: la transición Free→pago es una política de producto, no una validación jurídica. El borrador de condiciones requiere revisión competente y aprobación antes de publicar/comunicar.
- No se compraron productos de Sandbox/TestFlight ni se probó restore/renovación/reembolso de punta a punta.
- La versión/build local y ASC tenían discrepancia registrada en el handoff de Fase 02; Fase 04 debe releer ASC antes de seleccionar el build.
- El reloj usa Keychain `ThisDeviceOnly` y el mayor `lastTrustedAt` visto; no hay backend ni identidad estable de cuenta. Reinstalación, borrado de Keychain y adelanto del reloj no tienen garantía anti-reset universal.
- Para el vencimiento con editor abierto se implementó una alerta Save/Discard y un lease de un solo uso que solo permite guardar la instantánea del documento persistido que estaba abierto. Para captura activa, un overlay conserva el contexto y ofrece planes o recuperación. La UI E2E aún no se ha ejecutado y sigue siendo gate previo a release.
- La accesibilidad manual con VoiceOver/Voice Control y iPad físico sigue pendiente según Fase 02; no se afirma verificación manual.

## Validación automatizada

- Suite completa `Shield` en iPhone 18 Pro / Simulator iOS 27.2: 235 tests pasaron, 7 omitidos y 0 fallaron (242 tests; 21 min 12 s; exit code 0). `.xcresult`: `/Users/romerodev/Library/Developer/Xcode/DerivedData/Shield-emunowwqdzukpfbkshmbfqbgsvss/Logs/Test/Test-Shield-2026.11.08_15-17-39-+0100.xcresult`.
- Los omitidos fueron cuatro verificaciones del iPhone Duo, dos del destino iPad y la prueba de Offering RevenueCat que requiere el catálogo remoto. No equivalen a fallos ni se declaran verificados.
- El resultado registra 0 errores y 0 warnings de build/runtime. Xcode imprimió un aviso de metadatos del depurador con ruta nula al iniciar runners; no corresponde a deprecación de API del proyecto.
- La UI automation cubre editor, exportación PDF verificada, paywall, áreas táctiles y accesibilidad de controles. Las transacciones Sandbox, expiración con editor/captura activos, CloudKit real, revisión legal y hardware asistivo siguen como gates de release.

## Referencias

- [Máquina de estados](ACCESS_STATE_MACHINE.md)
- [Matriz de gates](AUDIT_GATE_MATRIX.md)
- [Pruebas](TEST_MATRIX.md)
- [Handoff Fase 04](release-cycle/FASE_03_HANDOFF.json)
