# Adaptive design — iPhone Duo

## Principles

- Keep MaskID's existing library, capture, redaction and export tasks intact.
- Use available view size and system containers; do not detect Duo by model or screen pixels.
- Keep the selected destination and editor data in app/editor state above the compact/expanded presentation boundary.
- Use the system's Duo-aware navigation and layout APIs where they express the existing relationship. Keep the iOS 18 fallback.

## Navigation

On iOS 26 and later, the authenticated shell now keeps one `.sidebarAdaptable` `TabView` alive. SwiftUI selects its tab-bar or sidebar presentation from the environment as the window changes. Scan remains a primary action accessory on compact presentation and a sidebar bottom-bar action on regular presentation. Settings keeps its previous compact behavior of hiding the tab bar and Scan action. The pre-iOS 26 implementation retains the custom compact tab bar and legacy regular sidebar.

## Editor

- Compact width keeps the existing canvas, contextual tools and bottom toolbar.
- A regular-width proposal uses the expanded editor only when the editor has at least 640 pt for single-page content or 760 pt for a multi-page document. Below that, the same edit state uses the compact composition.
- In the expanded layout, the canvas and its contextual tools form the primary region; the privacy inspector is the supplementary region. On iOS 27.1+, `ArrangementView` with `.split` lets SwiftUI adapt this existing two-region relationship to the Duo division. Earlier OS versions use the existing HStack layout.
- Inspector selection now lives in `EditorView` and is passed as a binding, so it survives when the inspector is temporarily removed in compact width.
- Document edits, page selection, zoom and redactions remain owned by `EditorView` / `EditorViewModel`; no document schema or business rule changed.
- On iOS 27.1+, the editor keeps the `NavigationStack` vertical toolbar behavior automatic. Native actions such as Close, Export, Inspector and Save can use the Duo's trailing rail; SwiftUI reserves that region from the custom canvas, style picker, zoom and tool controls. The compact editor keeps its `More` menu beside the document metadata in the content area, because opening it from the system rail placed menu rows over the reserved rail.
- Keep full-bleed backgrounds separate from interactive content. The closed-display UI test checks that the canvas, tools, zoom, style control, `More` button and its menu rows stay inside the content region while native toolbar actions remain reachable in the rail. The test passed on iPhone Duo with iOS 27.1; see the [2026-10-21 reference](https://blakecrosley.com/blog/prepare-your-app-for-iphone-duo) for the system-managed rail and reserved regions.
- A follow-up user capture exposed crowded trailing margins and overlapping DNI sample-header text. Interactive editor surfaces add a small gutter only when `toolbarVerticalEdge` reports a vertical system bar, so conventional iPhones keep their full width. The DNI header fonts shrink to fit separately measured columns. The Duo UI test measures the actual native rail action frames to derive its content boundary. The visual pass for this follow-up is pending.

## Library and capture

The existing home dashboard and capture/import menu retain their two-column regular-width composition. A small shared `DuoVerticalDivisionReader` queries only active vertical `.division` reserved regions and adds the reported frame width to the column gutter. It ignores inactive regions and horizontal divisions. At accessibility Dynamic Type sizes both views return to their existing single-column ordering to keep text and controls readable. Other scroll content is not displaced based only on hinge presence.

## Fold and safe areas

System-managed `TabView` and iOS 27.1 `ArrangementView` are used for the navigation rail and the canvas/inspector split. The home and capture two-column gutters use the active division's width. The full-screen authentication view uses the active division frame to keep its cohesive content and primary action within the leading panel; layout direction selects the leading panel for RTL locales. No fixed hinge coordinates or device-model checks were added. Device Hub visually verified the lock screen in closed, partially open and fully open poses. Camera occlusion, editor handles and other authenticated views still need runtime inspection.

## Accessibility and visual system

The system tab labels replace the custom compact row on current iOS, and Scan retains its accessibility label, hint and identifier. The accessory preserves a 64 pt-class control target expected by the existing UI tests. On older iOS fallback, tab labels use scalable `shieldFont`; visual text labels are omitted at accessibility Dynamic Type sizes while their VoiceOver labels remain. Existing localized labels and theme typography remain in place. No color, paid feature, or product label was changed.
