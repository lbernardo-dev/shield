# 288. Generar Build y Subir a App Store Connect

- Number: 288
- Slug: generar-build-subir-app-store-connect
- Versión: 1.1.8
- Build: 1182026112601

## Estado Actual
- **En Espera de Certificación del Usuario**: Conforme a la instrucción explícita del usuario, no se generará el archivo Release (`xcarchive`) ni se subirá a App Store Connect hasta que el usuario pruebe y certifique el correcto funcionamiento en su dispositivo físico.
- **Despliegue Físico**: Compilado y desplegado con éxito en el iPhone 15 Pro Max (`00008130-0011199026A0001C`), PID activo **32360**.

## Corrección del Ciclo Infinito de Desbloqueo y Bloqueo
- **Causa Raíz Identificada**:
  1. Durante la evaluación biométrica de Face ID (`evaluatePolicy`), iOS pasa la escena a `.inactive` de forma transitoria.
  2. `AppState.handleScenePhaseChange` y `VaultView.onChange(of: scenePhase)` evaluaban `phase != .active`, lo que provocaba que al completar Face ID y cerrar el modal del sistema, la app detectara el estado transitorio `.inactive` y volviera a bloquear la bóveda inmediatamente (`isVaultUnlocked = false`).
  3. `VaultView.onDisappear` contenía un reset de `isVaultUnlocked = false` y `shouldAuthenticateOnGateAppearance = true`, disparando re-solicitudes infinitas en transiciones de vistas.
- **Solución Aplicada**:
  1. El bloqueo por ciclo de vida de la aplicación ahora escucha estrictamente `phase == .background` (cuando la pantalla se apaga, se bloquea el teléfono con el botón lateral o se sale de la app), ignorando por completo el estado `.inactive` propio del prompt de Face ID.
  2. Eliminado el reseteo agresivo de `onDisappear` en `VaultView`. El bloqueo al cambiar de pestaña está controlado exclusivamente de forma limpia por `activeTab.didSet` en `AppState`.
  3. Se añadió control en `onChange(of: appState.activeTab)` para que al navegar de vuelta a la bóveda desde otra pestaña se reactive el auto-prompt de Face ID de forma ordenada.
  4. En cancelaciones de Face ID (gesto de cancelar o desvío intencional), no se fuerza la apertura del pad numérico y se mantiene al usuario en la pantalla de selección con los botones visibles.

## Correcciones Integradas en el Build
1. **Flujo de Acceso y Bloqueo de la Bóveda (Vault)**:
   - Al pulsar la pestaña Vault se solicita Face ID o PIN.
   - Transición atómica del PIN (`onSuccess` limpia `showPINEntry` y activa `isVaultUnlocked` simultáneamente) eliminando parpadeos o estados muertos donde Face ID no respondía.
   - Al pulsar el botón "Bloquear", regresa a la pantalla de selección (`lockGate`) permitiendo escoger desbloquear con Face ID o con PIN sin disparar prompts infinitos.
   - Al salir de la bóveda (cambio a otra pestaña como Documentos o Estilos), la bóveda se bloquea automáticamente (`isVaultUnlocked = false`).
   - Si el usuario permanece inactivo por más de 1 minuto sin realizar acciones dentro de la bóveda, o si la pantalla se apaga / el teléfono se bloquea, la bóveda se bloquea de inmediato.
2. **Miniaturas de Documentos**:
   - En documentos recientes y en el listado "Redacted" / Todos los documentos, se muestra la miniatura real procesada con sus redacciones en lugar del icono genérico de maletín.
   - Si el documento está en la bóveda, se visualiza difuminado (`blur`) con el badge cyber-violeta de protección mientras la bóveda esté bloqueada, y nítido al desbloquearla.
3. **Control de Versión y Build**:
   - `MARKETING_VERSION`: `1.1.8` en todos los targets.
   - `CURRENT_PROJECT_VERSION`: `1182026112601` en todos los targets.

## Próximos Pasos (Tras Certificación del Usuario)
1. Ejecutar el archivado Release:
   ```bash
   xcodebuild archive \
     -project Shield.xcodeproj \
     -scheme Shield \
     -configuration Release \
     -destination 'generic/platform=iOS' \
     -archivePath .asc/artifacts/MaskID-1.1.8-1182026112601.xcarchive \
     -quiet
   ```
2. Exportar IPA para App Store Connect:
   ```bash
   xcodebuild -exportArchive \
     -archivePath .asc/artifacts/MaskID-1.1.8-1182026112601.xcarchive \
     -exportPath .asc/artifacts/MaskID-1.1.8-1182026112601-export \
     -exportOptionsPlist .asc/artifacts/signing/MaskID-1.2.0-ExportOptions.plist \
     -quiet
   cp .asc/artifacts/MaskID-1.1.8-1182026112601-export/MaskID.ipa .asc/artifacts/MaskID-1.1.8-1182026112601.ipa
   ```
3. Subir a App Store Connect:
   ```bash
   asc builds upload --app 6790398619 --ipa ".asc/artifacts/MaskID-1.1.8-1182026112601.ipa" --wait
   ```
4. Solicitar confirmación explícita al usuario antes de ejecutar `./scripts/clean.sh --all` según la política de archivos temporales.
