# 141-premium-icon-pack-3d

- Number: 141
- Slug: premium-icon-pack-3d

## Notes

- Audited the current premium alternate-icon flow:
  - `AppIconOption` exposes six options: `MaskIDBlue` (default/free) plus Gold, Green, Ocean, Purple, and Red (Pro).
  - `AppIconPickerView` previews PNGs, gates non-default icons behind `PremiumManager.isPro`, and updates the system icon through `AppState.setAppIcon`.
  - `AppState` persists `shield.selectedAppIcon` and synchronizes with `UIApplication.alternateIconName`.
  - The project uses Xcode asset catalogs and `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES`; current icon sets contain one opaque 1024x1024 RGB PNG each, with explicit iPhone/iPad PNG entries in `Shield/Resources/Info.plist`.
- Apple compliance finding for integration: current implementation is structurally valid for alternate icons, but it does not yet provide the current iOS/iPadOS dark, clear, and tinted variants Apple documents for alternate icons. The selected designs must therefore be imported/author-composed with those variants and checked in Simulator/device before release.
- Generated preview pack (preview-only, not copied into production assets):
  - Permanent directions: Aurora, Forest/Nature, Ocean/Tide, Solar, Space, Winter/Frost.
  - Seasonal/global directions: Halloween, Christmas/Winter Holiday, Lunar New Year, Pride/Spectrum, Spring/Cherry Blossom, Earth/Planet Care.
  - A strict refined pass was generated for Aurora, Forest, Ocean, Halloween, Christmas, Lunar New Year, Pride, and Space; outputs are stored by the image-generation tool under `/Users/romerosoft/.codex/generated_images/01a04829-de58-7752-98e4-5eff20b21d37/`.
- No app-icon assets, `Info.plist`, Swift source, or Xcode project settings were changed in this proposal phase. Integration is intentionally deferred until the user selects candidates.
- Next integration phase: choose 4–8 candidates, normalize artwork on Apple’s 1024x1024 grid/safe zone, produce light/dark/clear/tinted variants, add alternate icon sets and localized names, update picker metadata/tests, then build and verify on iPhone/iPad and App Store Connect preflight.
