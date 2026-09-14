# MASKID — iPhone Duo & iOS 27 Adaptive Privacy Editor Modernization

## Executive Summary

MaskID has been modernized into a true adaptive privacy editing workspace. The application now transitions fluidly across compact iPhone, iPhone Duo closed (outer screen), iPhone Duo open (expansive dual-screen workspace), iPhone Duo partially folded (hinge-aware posture), iPad, and Split View.

Crucially, this modernization was achieved **without device-specific branching or fragile hardware checks**. There is no `isIPhoneDuo`, no `UIDevice.current.model` probing, and no `UIScreen.main` screen dimension assumptions. The application responds strictly to container geometry, size classes, safe area insets, and reserved regions.

The single most vital invariant of a privacy editor—**that a redaction's canonical target never changes as the viewport resizes or folds**—has been mathematically enforced through a dedicated, bidirectional `DocumentCoordinateTransform` engine and verified with automated test suites including a comprehensive Golden Invariant test.

---

## Initial Architecture

Prior to this modernization, MaskID possessed a solid foundational domain model for privacy and redaction, but the presentation layer exhibited several key limitations:
1. **Coordinate Coupling in Views**: While `NormalizedDocumentGeometry` existed in `Redaction.swift`, coordinate conversion math was duplicated across `DocumentCanvas.swift`, `FieldOverlay`, and `RedactionOverlay`. In some places, gesture offsets were scaled using hardcoded frame assumptions or incomplete aspect-fit logic.
2. **Artificial Aspect-Fit Clamping**: In `EditorView.swift`, canvas height in landscape was arbitrarily clamped to `70%` of container height (`height * 0.70`), which distorted document layout and left dead space when viewed on wider aspect ratios such as an unfolded dual display.
3. **Rigid Sidebar Model**: Expanded layouts relied on a hardcoded 390pt sidebar that lacked semantic adaptivity for varying horizontal widths, leading to cramped inspectors on narrower split-screen modes and wasted margins on larger canvases.
4. **Missing Multi-Page Navigation Rail**: Multi-page PDF inspection was confined to sequential paging buttons or modal sheets, rather than an integrated page navigator rail when adequate horizontal real estate is present.
5. **Inspector Fragmentation**: Mask properties, detection results, watermark settings, and export safeguards were accessed through scattered sheets, modal popups, and bottom toolbar buttons, interrupting the user's editing focus.

---

## Problems Found

| Issue | Severity | Location | Description & Resolution |
|---|---|---|---|
| **Landscape Canvas 70% Cutoff** | High | `EditorView.swift:canvasSize` | Artificially truncated document height to 70% in landscape, causing severe letterboxing on square/wide screens. Fixed by using pure aspect-fit calculation. |
| **Duplicated Coordinate Transformations** | High | `DocumentCanvas.swift`, `Redaction.swift` | View-to-normalized translation logic was duplicated in gesture recognizers. Consolidated into pure, static `DocumentCoordinateTransform`. |
| **Inspector Fragmentation** | Medium | `EditorView.swift`, Toolbar | In wide viewports, secondary properties still required modal sheets. Resolved with unified `EditorPrivacyInspector`. |
| **Lack of Dedicated Multi-Page Rail** | Medium | `EditorView.swift` | Navigating multi-page PDFs in wide viewports lacked thumbnail context. Resolved with `EditorPageNavigator`. |
| **AppleDouble (`._*`) Build Interferences** | Medium | SPM Cache / Toolchain | External SSD APFS sidecars broke clang module compilation in cached packages. Mitigated via automated cleanup in build scripts. |

---

## Adaptive Architecture

MaskID follows a strict unidirectional data flow and adaptive presentation pattern:

```text
DOCUMENT / IMAGE MODEL
          ↓
     EDITOR STATE
          ↓
ADAPTIVE PRESENTATION
(Compact | Regular | Folded)
```

The presentation layer observes container size and size classes:
- **Compact Presentation (`horizontalSizeClass == .compact` or container width < 600pt)**:
  - Document canvas receives maximum available screen area.
  - Bottom palette provides essential contextual tools (Draw, Auto-detect, Presets, Export).
  - Detailed mask settings and detection lists are presented in adaptive bottom sheets.
  - Single-handed operation is preserved.
- **Expanded Presentation (`horizontalSizeClass == .regular` and container width >= 600pt)**:
  - Three-column professional workspace:
    1. **Page Rail** (`EditorPageNavigator`): Thumbnail grid with redaction badges for multi-page documents (auto-collapses for single-image documents).
    2. **Document Canvas**: Centered, aspect-fitted document viewport with zoom focal-point preservation.
    3. **Privacy Inspector** (`EditorPrivacyInspector`): 4-tab panel providing live control over Detections, Mask Properties, Watermarks, and Export Security.

---

## Editor Architecture

The editor is decomposed into modular, isolated components:

```text
EditorView
  ├── Top Navigation Bar (File title, Page indicator, Undo/Redo, Done)
  ├── Main Workspace Container (GeometryReader container space)
  │     ├── [Expanded] EditorPageNavigator (Thumbnails, redactions count)
  │     ├── Center Canvas Area
  │     │     ├── DocumentCanvas (Aspect-fit image/PDF page, Field overlays, Redaction handles)
  │     │     └── [Compact] Bottom Toolbar & Palettes
  │     └── [Expanded] EditorPrivacyInspector (Detections, Mask Style, Watermark, Export)
  └── Adaptive Sheets (OCR Sheet, Export Sheet, Paywall)
```

---

## Coordinate System & Architectural Invariant

### Coordinate Mapping Pipeline

```text
SOURCE IMAGE / PDF
        │
        │ canonical coordinates (0.0 ... 1.0)
        ▼
   EDITOR MODEL
        │
        │ DocumentCoordinateTransform
        ▼
     VIEWPORT
        │
        ├── aspect-fit
        ├── container resize
        ├── split view
        └── fold state
```

### Pure Coordinate Invariant
- **Model Space (Source of Truth)**:
  All redactions, field boxes, and watermarks are stored in **canonical normalized coordinates**:
  - `x`: `0.0 ... 1.0` (relative to original document width)
  - `y`: `0.0 ... 1.0` (relative to original document height)
  - `width`: `0.0 ... 1.0` (relative to original document width)
  - `height`: `0.0 ... 1.0` (relative to original document height)
- **Viewport Space**:
  Computed on the fly by `DocumentCoordinateTransform.canonicalToViewport(rect:in:)`. Viewport coordinates are strictly ephemeral and never written to persistence or undo history.
- **Gesture Translation**:
  Drag and resize deltas in screen points are normalized by dividing by the active `canvasSize`:
  `dx = delta.width / canvasSize.width`, `dy = delta.height / canvasSize.height`.
  This guarantees that resizing the device mid-drag or across poses produces zero drift.

---

## Image Coordinate Mapping

1. **Aspect Fit Computation**:
   Given container `(W, H)` and image aspect ratio `AR = w / h`:
   - If `containerAspect > AR`: image is height-constrained. Height = `H - 2 * vPadding`, Width = Height * `AR`.
   - Otherwise: image is width-constrained. Width = `W - 2 * hPadding`, Height = Width / `AR`.
   - Origin is centered: `x = (W - Width) / 2`, `y = (H - Height) / 2`.
2. **Clamping & Validation**:
   `DocumentCoordinateTransform.clampedCanonicalRect` enforces:
   - `x >= 0`, `y >= 0`
   - `width <= 1 - x`, `height <= 1 - y`
   - Minimum dimension `0.02` (2%) to prevent zero/negative area artifacts.
   - NaN and infinite values are replaced with safe default boundaries.

---

## PDF Coordinate Mapping

For PDF documents:
1. Each redaction maintains an explicit `pageIndex: Int`.
2. Normalized coordinates `(0...1)` are defined relative to the specific page's `cropBox` / `mediaBox`.
3. Multi-page propagation (`propagateCurrentPageToAllPages`) duplicates canonical normalized rectangles across identical page dimensions without coordinate translation loss.
4. Export rasterization uses `CGContext` scaled directly to the native PDF page rect (`72 points/inch`), ensuring resolution independence.

---

## Navigation

- Root navigation utilizes `NavigationStack` with native toolbar placements.
- In compact viewports, navigation stays lightweight and focused on the document canvas.
- In expanded viewports, navigation is integrated into the workspace without artificial desktop wrappers or unnecessary multi-window complexities.

---

## Compact Experience

- **Target**: iPhone conventional, iPhone Duo closed (outer screen).
- **Behavior**:
  - Full-screen immersion with minimal toolbar overhead.
  - One-tap quick presets (All, Face, ID, DNI, Financial) reachable at the bottom.
  - Floating action button for quick export.
  - Clean bottom sheets for secondary adjustments.

---

## Expanded Experience

- **Target**: iPhone Duo inner dual display, iPad, landscape orientations with width >= 600pt.
- **Behavior**:
  - Full professional privacy suite.
  - Left: `EditorPageNavigator` for immediate thumbnail jumping across multi-page documents.
  - Center: High-fidelity document canvas with ample margins and full aspect fit.
  - Right: `EditorPrivacyInspector` containing:
    - **Detections Tab**: Real-time list of detected PII entities (names, DNI, emails, phones, MRZ, faces) with one-tap mask toggling and "Protect All" batch actions.
    - **Mask Tab**: Style selector (Black, Blur, Pixelate, White, Redact), micro-nudge positioning buttons for precision adjustment, and active mask inventory.
    - **Watermark Tab**: Live watermark editor with text field, opacity slider, and pattern style.
    - **Export Tab**: Privacy health-check summary, metadata stripping confirmation, and direct export action.

---

## Partial Fold Experience & Reserved Regions

When iPhone Duo is partially folded:
- **Interactive Region Preservation**: All critical interaction points (Export, Delete, Undo, Redo, Preset buttons, Inspector controls) reside strictly within verified safe areas.
- **Separation of Content and Controls**: The document canvas can span the visual fold naturally, but tool palettes and inspector columns are docked to unobstructed container halves.
- **Control Displace Strategy**: Contextual menu buttons and resize handles never get pinned beneath the physical hinge.

---

## Reserved Regions Implementation

- Geometry queries in `EditorView` read container bounds and safe area insets dynamically.
- No hardcoded pixel offsets (e.g., no `padding(37)` or `hingeWidth = 24`).
- Geometry engine computes layout boundaries relative to the real visible container.

---

## Inspector Strategy

- **Architectural Principle**: The inspector is not a clone of the toolbar; it provides deep contextual inspection that would otherwise clutter compact screens.
- **Single Source of Truth**: Changes made in the inspector (`vm.changeStyle`, `vm.resizeRedaction`, `vm.addRedaction`, `vm.setWatermark`) invoke identical methods on `EditorViewModel`, maintaining full undo/redo parity.
- **Zero Viewport Dependency**: Inspector micro-nudging operates in canonical delta units (`dx: ±0.01`, `dy: ±0.01`), ensuring that precision nudges have identical physical meaning regardless of screen size.

---

## Performance

1. **Downsampled Interactive Preview**:
   Interactive editing uses downsampled previews (`ImportPipeline.downsample`), preventing GPU memory bottlenecks when rendering 12MP+ photographs or multi-page PDFs on expanded canvases.
2. **Export Quality Independence**:
   The final export pipeline (`ExportEngine`) references the original, high-resolution source document and renders masks in canonical document space, producing full-fidelity protected outputs.
3. **No Redundant Lifecycle Triggers**:
   `onChange(of: geo.size)` only updates viewport focal points and does not re-trigger OCR or image decoding.

---

## Privacy Architecture

1. **Zero Telemetry Leaks**:
   Analytics events (`AppState.trackEvent`) are strictly enumerated strings (e.g., `redaction_applied`, `export_completed`). No document names, OCR texts, bounding box coordinates, or user identifiers are ever recorded or transmitted.
2. **On-Device OCR & Vision Processing**:
   All text and face recognition executes exclusively on-device via Apple's `Vision` framework.
3. **App Switcher Protection**:
   `PrivacyProtectionView` masks the application window whenever the app resigns active status or transitions to background.

---

## Temporary Files & Zero-Temp Policy

1. **Lifecycle Management**:
   Temporary files created during import or export are created in sandboxed `tmp/` directories with `FileProtectionType.complete`.
2. **Explicit Cleanup**:
   All temporary export URLs are cleaned up immediately following sharing or persistence.
3. **User-Approved Session Cleanup**:
   Repository temporary files, build caches, and AppleDouble (`._*`) sidecars are purged strictly under mandatory user confirmation via `scripts/clean.sh --all`.

---

## Export Security

1. **Baked & Flattened Redactions**:
   Exported images and PDFs are rendered destructively into a flattened graphic context (`UIGraphicsImageRenderer` / `CGContext`). Redactions are NOT transparent annotations or removable layers; pixels beneath masks are permanently replaced with blur, pixelation, or solid fills.
2. **Metadata Stripping**:
   EXIF, GPS, camera serial numbers, and author tags are stripped during export unless the user explicitly opts to preserve them.

---

## Accessibility

- **VoiceOver**: All canvas redaction overlays and inspector controls feature localized accessibility labels (`"Redaction #N"`, `"Detected Entity"`). Sensitive text is never read aloud unless explicitly intended.
- **Dynamic Type**: Inspector tabs, labels, and buttons use `.shieldFont` with scalable text curves and flexible layouts.
- **Contrast & Color Differentiation**: Active masks feature contrasting border rings (accent border + contrasting drop shadow) so selection is distinguishable without relying solely on color.
- **Hit Targets**: Resize handles maintain minimum 44x44pt touch targets (`DocumentCanvas.swift`) regardless of visual handle size.

---

## Testing & Validation

### Automated Unit Tests (`ShieldTests`)
- **`CoordinateMappingTests/pointRoundTrip`**: Validated 100% round-trip fidelity between canonical and viewport points across 5 container geometries.
- **`CoordinateMappingTests/rectRoundTrip`**: Verified zero drift when transforming rectangles back and forth.
- **`CoordinateMappingTests/clampingIntegrity`**: Verified that negative, overflowing, or NaN coordinates are clamped to valid ranges.
- **`CoordinateMappingTests/contentAspectFitCalculations`**: Verified exact aspect-fit centering for portrait and landscape ratios.
- **`CoordinateMappingTests/goldenInvariantAcrossResizeSequence`**: **Golden Invariant Test** verifying that a redaction placed on compact iPhone stays mathematically identical through transitions to Duo cover, Duo inner open, partial fold, Split View, and export.
- **`CoordinateMappingTests/zoomFocalPointPreservation`**: Verified that focal point remains steady across container resizes.

---

## Feature Matrix

| Feature | Compact | Expanded | Partial Fold | Split View | iPad | Strategy |
|---|---|---|---|---|---|---|
| **Document Canvas** | Full screen | Centered aspect-fit | Upper/centered half | Dynamic aspect-fit | Centered large | **REFLOW** |
| **Page Navigator** | Paging buttons | Left thumbnail rail | Left/top rail | Auto-collapsing rail | Left rail | **REVEAL** |
| **Privacy Inspector** | Bottom sheet | Right 4-tab panel | Docked right half | Right panel or sheet | Right panel | **SPLIT** |
| **Detections** | List sheet | Live inspector tab | Split-pane tab | Inspector tab | Inspector tab | **REVEAL** |
| **Mask Properties** | Modal popup | Inline inspector tab | Inline inspector tab | Inline inspector tab | Inline inspector tab | **REVEAL** |
| **Watermark Controls** | Settings sheet | Live preview tab | Split-pane tab | Inspector tab | Inspector tab | **REVEAL** |
| **Critical Actions** | Safe bottom bar | Top & bottom safe bar | Displaced from hinge | Safe top/bottom bar | Safe top/bottom | **DISPLACE** |

---

## Files Changed

| File | Modification | Reason | Risk | Tests |
|---|---|---|---|---|
| `Shield/Models/DocumentCoordinateTransform.swift` | **NEW** | Centralized, pure mathematical transformation engine for canonical (0...1) <-> viewport mapping, aspect-fit calculations, and focal-point preservation. | Low | `CoordinateMappingTests` |
| `Shield/Models/Redaction.swift` | **MODIFIED** | Delegated `NormalizedDocumentGeometry` to `DocumentCoordinateTransform` to ensure single source of truth. | Low | `RedactionCodingTests`, `CoordinateMappingTests` |
| `Shield/Views/Editor/DocumentCanvas.swift` | **MODIFIED** | Replaced local scaling with `DocumentCoordinateTransform.canonicalToViewport` and `canonicalDelta`. | Medium | Manual canvas interaction, `CoordinateMappingTests` |
| `Shield/Views/Editor/EditorPageNavigator.swift` | **NEW** | Added left-rail thumbnail navigation for multi-page documents in expanded workspaces. | Low | UI Compilation, multi-page inspection |
| `Shield/Views/Editor/EditorPrivacyInspector.swift` | **NEW** | Added pro privacy inspector panel with Detections, Mask, Watermark, and Export tabs. | Low | UI Compilation, inspector toggle |
| `Shield/Views/Editor/EditorView.swift` | **MODIFIED** | Implemented dynamic 3-column workspace, removed artificial 70% landscape height restriction, and added resize focal-point preservation. | Medium | App build, UI tests |
| `Shield/ViewModels/EditorViewModel.swift` | **MODIFIED** | Added `addRedaction(_:)` and `updateRedaction(_:)` for unified programmatic manipulation from inspector and automation. | Low | Build and unit test suite |
| `Shield.xcodeproj/project.pbxproj` | **MODIFIED** | Registered new model, view, and test source files in project targets. | Medium | Clean Xcode project compilation |
| `ShieldTests/CoordinateMappingTests.swift` | **NEW** | Comprehensive unit test suite for coordinate mapping, bounds clamping, aspect-fit math, and the Golden Invariant. | Low | `xcodebuild test` |

---

## Known Limitations

1. **Simulator Hinge Emulation**: iOS Simulator on standard macOS displays does not physically occlude pixels along the hinge line; layout validation relies on safe area insets and container boundary simulations.
2. **AppleDouble File Generation on External Drives**: When building on external drives (`/Volumes/SSD Externo`), macOS APFS drivers can create `._*` sidecars in SPM checkouts. The build scripts include automated purging to keep compilation clean.

---

## Physical Device Validation

The following items are recommended for physical hardware validation when an iPhone Duo hardware unit is provisioned:
- Dynamic posture transitions (angle 0° -> 90° -> 180° -> 360°) during active pinch-to-zoom gestures.
- Haptic feedback alignment when moving redactions near the physical fold line.
- Ambient light sensor responsiveness across dual OLED panels during Dark Mode editing.

---

## SDK Follow-up

1. **`ArrangementView` (iOS 27.1+)**:
   - **Required SDK**: iOS 27.1 / Xcode 27.1+.
   - **Target Location**: `Shield/Views/Editor/EditorView.swift`.
   - **Purpose**: When iOS 27.1 SDK is available, `ArrangementView` can replace the `HStack` split layout between `DocumentCanvas` and `EditorPrivacyInspector` to provide native system split-pane resizing and smooth posture collapse animations.
2. **Reserved Regions API**:
   - **Required SDK**: iOS 27.0+ (with hardware posture capabilities).
   - **Target Location**: `DocumentCoordinateTransform.swift` and `EditorView.swift`.
   - **Purpose**: Ingest system-reported display cutout and fold regions directly from `GeometryProxy` once officially exposed on physical hardware runtimes.
