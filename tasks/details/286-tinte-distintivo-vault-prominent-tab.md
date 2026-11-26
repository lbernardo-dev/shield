# 286-tinte-distintivo-vault-prominent-tab

- Number: 286
- Slug: tinte-distintivo-vault-prominent-tab

## Overview
Applied a distinctive Cyber Violet tint (`#7C3AED` / `#8B5CF6`) to the prominent Vault button in the footer navigation across both native iOS 18+ TabView and custom fallback TabBar.

## Changes
1. **`Shield/App/ContentView.swift`**:
   - In `nativeTabView`, updated `Tab(value: AppTab.vault, role: .prominent)` to use a custom label with `.symbolRenderingMode(.hierarchical)` and `.foregroundStyle(Color(hex: "8B5CF6"))`, `.tint(Color(hex: "7C3AED"))`.
   - Updated `TabView.tint` dynamically: when `appState.activeTab == .vault`, the tint changes to `Color(hex: "7C3AED")`, distinguishing it from the cyan/mint accent of the documents and gallery tabs.
2. **`Shield/Views/Components/TabBar.swift`**:
   - In `prominentVaultTabItem`, updated the gradient to `[Color(hex: "8B5CF6"), Color(hex: "7C3AED"), Color(hex: "5B21B6")]`.
   - Added an outer aura ring `vaultColor.opacity(isActive ? 0.35 : 0.15)` and enhanced shadow.
   - Tinted label text with `Color(hex: "A78BFA")`.

## Verification
- Unit tests suite (`ShieldTests`).
- Build and deployment to physical iPhone 15 Pro Max (`00008130-0011199026A0001C`).
