# 195-halloween-immersive-theme

- Number: 195
- Slug: halloween-immersive-theme

## Notes

Implemented the immersive Halloween theme and the accompanying UI stabilization work.

- Added a managed seasonal visual system with a generated dark Halloween backdrop, masks, pumpkins, candle/candelabra accents, webs, bats, insects, atmospheric fog and restrained blood-red/orange highlights. Decorative layers hide themselves for Reduce Transparency and remain non-interactive/non-accessible.
- Added optional Halloween soundscape support with an explicit user toggle, reduced volume, randomized macabre stingers, and serial audio-session work off the main thread.
- Managed themes now own their appearance and icon assets. While a non-standard managed theme is active, manual color-scheme and app-icon controls remain visible but disabled. Standard remains fully editable for Premium users. Applying Halloween synchronizes the modern seasonal icon automatically; applying Standard restores the modern default icon. Removed the obsolete legacy icon asset and runtime references.
- Repaired adaptive layout constraints across Home, Settings, Gallery, Vault, Lock/PIN, Capture, Editor and Paywall. Content is capped to the actual viewport, keeps horizontal padding, uses responsive grids where horizontal scrollers previously overflowed, and avoids vertical metadata wrapping.
- Stabilized the root-level Capture presentation and reinforced the central scan button's 72pt hit region/z-order. Removed the bottom-bar insertion transition that could leave it visually present but untappable after returning from Settings.
- Added/retained accessibility labels, 44pt action targets, readable contrast, dynamic-type-safe chrome, reduced-motion handling and screen audits in English and Spanish. No coffee/donation/support prompt references remain in runtime or project documentation scans.

Validation:

- Build succeeded with `scripts/xcbuild.sh` on iPhone 18 Pro, iOS 27.0, UDID `1454EA8D-A019-4B07-B57C-1433E0F21BE0`.
- Accessibility audits passed for Home, Onboarding, Lock, Capture, Gallery, OCR, Export, Vault and Settings in English and Spanish.
- Persistent chrome passed at Accessibility XXXL with Reduce Motion, Reduce Transparency and Darker System Colors.
- Critical flows passed: navigation, Settings routes/back/close, Capture guide and dismissal, Gallery preview, Editor export, Paywall, Vault lock and the complete tab-to-Capture flow.
- Asset JSON validation and `git diff --check` passed. iPhone Duo is not available in the installed runtimes; iPad and Apple Watch remain unvalidated because their required devices are shutdown and no compatible paired runtime was available. No simulator reset, erase or reboot was performed.
