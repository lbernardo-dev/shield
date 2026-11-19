# 261-lifetime-no-offer-code-and-base-theme

- Number: 261
- Slug: lifetime-no-offer-code-and-base-theme

## Notes

- Eliminada la entrada de canje del paywall principal, del paywall de onboarding y de Ajustes. Quitados `offerCodeRedemption`, sus estados/eventos y `PremiumManager.reconcileAfterOfferCodeRedemption()` con la sincronización `syncPurchases()` que solo servía para esa vía.
- El paywall conserva Lifetime como única compra, restauración y enlaces legales. El texto de producto no disponible y los catálogos EN/ES ya no mencionan códigos; las descripciones de App Store, los términos, el posicionamiento, la arquitectura y la documentación de configuración se alinearon con Lifetime y restauración solamente.
- El tema se resuelve como base en instalaciones sin selección persistida; el sonido estacional no se activa por defecto y `updateSoundscape()` lo detiene salvo que el usuario lo habilite con el tema Halloween activo. La ventana Halloween 2026 terminó el 1 de noviembre, antes de la revisión del 18 de noviembre.
- Revisión de los simuladores iPhone Duo, iPhone 18 Pro e iPad Pro 13: `shield.selectedAppIcon` es `MaskIDDefault` y `shield.theme.lastAppliedIcon` está confirmado. En iPhone no hay selección estacional persistida (el default es base); iPad persiste selección base y preferencia de eventos `never`. Ninguno tiene preferencia de audio activa.
- El build principal está configurado con `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon`; `AppIcon.appiconset/icon_1024.png` y `MaskIDDefault.appiconset/icon_1024.png` tienen el mismo SHA-256. `Info.plist` define `MaskIDDefault` como icono primario.
- Verificación: `xcodebuild -quiet -project Shield.xcodeproj -scheme Shield -destination 'platform=iOS Simulator,id=CCC41661-BB97-41D2-87E2-D47FC51B1C6B' CODE_SIGNING_ALLOWED=NO build` terminó con código 0. `git diff --check`, validación JSON de los catálogos y metadata, y búsqueda de referencias ejecutables de canje en `Shield` pasaron. No se ejecutaron pruebas automatizadas ni se publicó el build.
- El acceso visual a la app Simulator no respondió al intento de CUA; la revisión del estado base se hizo mediante preferencias persistidas de los simuladores, recursos, `Info.plist` y configuración de Xcode.
