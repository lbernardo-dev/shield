# MaskID App Store creative videos

Four silent, localized creative videos for the new App Store placements:

| Locale | Placement | File | Output |
| --- | --- | --- | --- |
| en-US | Product page header | `en-US/product-page-header.mp4` | 3840 × 1646, 21:9 |
| en-US | Search results | `en-US/search-results.mp4` | 2880 × 1920, 3:2 |
| es-ES | Product page header | `es-ES/product-page-header.mp4` | 3840 × 1646, 21:9 |
| es-ES | Search results | `es-ES/search-results.mp4` | 2880 × 1920, 3:2 |

Every video is 15 seconds, 30 fps, MP4/H.264, without an audio track. Each follows the actual product flow: home, OCR suggestions, manual redaction, and verified export. Source screens come from the bilingual simulator-capture set in `Marketing/30-Day-Social-Campaign/source-captures/` and use synthetic examples.

The header and search versions are separate cuts because Apple requires different aspect ratios. These are **creative assets**, not App Previews. Apple's current specifications support 5–30-second videos at 21:9 for the product page header and 3:2 for search results.

Header exports remain 21:9 at Apple's required 3840 × 1646 resolution. The actual iPhone product-page preview in App Store Connect crops to a narrower central frame and overlays carousel and share controls near the upper corners. The EN and ES headlines and phones are sized for that frame, clear of the controls, and were checked in ASC's iPhone preview. Only the quiet background treatment extends into the panoramic side areas.

## Render

Requirements: Python 3 with Pillow and FFmpeg with `libx264`.

```sh
python3 Marketing/AppStore-Connect/CreativeAssets/render.py
```

The renderer writes the four deliverables under this directory. It does not modify the source captures.

## App Store Connect

The `asc` 5.14 CLI supports uploading these as `CREATIVE_ASSETS` to the Asset Library and assigning the resulting video IDs with placement types `PRODUCT_PAGE_HEADER_ASSET` and `APP_STORE_SEARCH_RESULTS_ASSET` on each version localization. Uploading and assigning assets does not submit a review. The existing App Review hold for version 1.1.3 remains in effect; do not create or submit a review submission as part of this task.
