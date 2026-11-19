# 265-update-prompt-official-app-store-icon

- Number: 265
- Slug: update-prompt-official-app-store-icon

## Notes

- Descargué `apps.aaa485a7.png`, el asset visual “App Store Icon” que aparece en la herramienta de marketing oficial de Apple, enlazada desde la guía indicada. Fuente: https://developer.apple.com/app-store/marketing/guidelines/ y https://toolbox.marketingtools.apple.com/en-us/app-store/us. PNG original de 200 × 200 px con transparencia; se conserva sin edición en `Shield/Resources/Assets.xcassets/AppStoreIcon.imageset/app-store-icon.png`.
- El aviso usa el asset del catálogo mediante `Image("AppStoreIcon")`; el catálogo `Assets.xcassets` ya forma parte del target Shield.
- Compilación Debug para iPhone 18 Pro Simulator: correcta, exit 0. El JSON del asset catalog es válido; no se ejecutaron tests ni se limpiaron cachés/temporales.
