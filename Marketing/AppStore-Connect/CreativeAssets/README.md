# MaskID App Store creatives

## Release 1.1.6 · 25 October 2026

The iPhone screenshot package contains exactly 10 localized screenshots in each of `en-US` and `es-ES`. It was captured from MaskID 1.1.6 (build `1162026102502`) on the dedicated iPhone 18 Pro simulator copy running iOS 27.0.

- Final files: `.asc/screenshots/aso/final/{en-US,es-ES}/iphone-63/`
- Preview sheets: `.asc/screenshots/aso/review/contact-{en-US,es-ES}.png`
- Native image size: 1206 × 2622 px. App Store Connect display type: `APP_IPHONE_61`.
- Base theme was verified through the local DEBUG visual preview on the dedicated simulator copy. Synthetic documents are used throughout.
- App Store Connect reports all 10 screenshots for each locale as `COMPLETE`.
- No app preview or app-use video is included in this release. The legacy `en-US` preview was removed after the previous review submission was canceled. App Store Connect now has no preview videos in `en-US` or `es-ES`.
- Submission `91422bbd-05c7-4306-8911-6ac525e55fcc` for build `1162026102502` is `WAITING_FOR_REVIEW` as of 25 October 2026. The previous submission was canceled to remove the legacy preview.

## Capture order

1. Protect before sharing
2. Scan and import
3. Review in batches
4. Compare mask styles
5. Encrypted local Vault
6. Protect your ID
7. Share travel documents
8. Review on-device suggestions
9. Label a protected copy
10. Check before sharing

## Rebuild the package

```sh
python3 scripts/compose_aso_screenshots.py
```

The current scene plan and localized copy are in `.asc/aso-screenshot-plan.json`. Raw simulator captures are in `.asc/screenshots/raw_captures/`.

## Apple requirements checked

- Apple lists iPhone 18 Pro in the 6.3-inch screenshot group; 1206 × 2622 px is an accepted size. The corresponding App Store Connect screenshot display type used here is `APP_IPHONE_61`.
- Apple screenshot requirements: [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).

The archived source video assets under `en-US/` and `es-ES/` are not part of this screenshot delivery and were not uploaded with build 1162026102502.
