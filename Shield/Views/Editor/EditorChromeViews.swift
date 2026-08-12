import SwiftUI

struct EditorDocumentMetaBar: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let changeCount: Int
    let hasUnsavedChanges: Bool
    let lang: AppLanguage

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .shieldFont(13, weight: .bold)
                .foregroundColor(ShieldTheme.primary(scheme))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(changeCountLabel)
                .shieldFont(11, weight: .bold)
                .foregroundColor(hasUnsavedChanges ? ShieldTheme.warning : ShieldTheme.tertiary(scheme))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(hasUnsavedChanges ? ShieldTheme.warning.opacity(0.16) : ShieldTheme.rowBackground(scheme))
                .clipShape(Capsule())
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.vertical, 3)
        .background(ShieldTheme.background(scheme))
    }

    private var changeCountLabel: String {
        guard changeCount > 0 else {
            return LanguageManager.shared.editor("editor_change_count_none")
        }
        return LanguageManager.shared.editor("editor_change_count", changeCount)
    }
}

struct EditorSensitiveBanner: View {
    @Environment(\.colorScheme) private var scheme
    let isVisible: Bool
    let isAnalyzing: Bool
    let suggestedRedactionCount: Int
    let docKind: DocumentKind
    let lang: AppLanguage
    let onApply: () -> Void
    let onOpenFields: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        if isVisible {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .shieldFont(16, weight: .semibold)
                    .foregroundColor(ShieldTheme.warning)

                VStack(alignment: .leading, spacing: 1) {
                    Text(titleText)
                        .shieldFont(12, weight: .bold)
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Text(subtitleText)
                        .shieldFont(11)
                        .foregroundColor(ShieldTheme.secondary(scheme))
                }
                Spacer()

                Button(action: onApply) {
                    Text(LanguageManager.shared.common("common_apply"))
                        .shieldFont(12, weight: .bold)
                        .foregroundColor(ShieldTheme.accentText)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(ShieldTheme.warning)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(suggestedRedactionCount == 0 || isAnalyzing)
                .opacity((suggestedRedactionCount == 0 || isAnalyzing) ? 0.55 : 1)

                Button(action: onOpenFields) {
                    Text(LanguageManager.shared.editor("editor_sensitive_fields_button"))
                        .shieldFont(12, weight: .bold)
                        .foregroundColor(ShieldTheme.accent(scheme))
                        .padding(.horizontal, 10)
                        .frame(minHeight: 44)
                        .background(ShieldTheme.accentDim(scheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 0.8)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .shieldFont(13)
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(LanguageManager.shared.common("common_close"))
            }
            .padding(.horizontal, ShieldTheme.s4)
            .padding(.vertical, 4)
            .background(ShieldTheme.warning.opacity(0.10))
            .overlay(Rectangle().stroke(ShieldTheme.warning.opacity(0.35), lineWidth: 0.5))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var titleText: String {
        if isAnalyzing {
            return LanguageManager.shared.editor("editor_sensitive_analyzing")
        }
        return LanguageManager.shared.editor("editor_sensitive_suggested", suggestedRedactionCount)
    }

    private var subtitleText: String {
        if docKind == .photo || docKind == .genericID {
            return LanguageManager.shared.editor("editor_sensitive_based_on_ocr")
        }
        return LanguageManager.shared.editor("editor_sensitive_based_on_template")
    }
}

struct EditorPropagateBanner: View {
    @Environment(\.colorScheme) private var scheme
    let pageCount: Int
    let redactionCount: Int
    let onPropagate: () -> Void

    var body: some View {
        if pageCount > 1 && redactionCount > 0 {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up.fill")
                    .shieldFont(14, weight: .semibold)
                    .foregroundColor(ShieldTheme.accent(scheme))

                VStack(alignment: .leading, spacing: 1) {
                    Text(LanguageManager.shared.editor("editor_redactions_on_page", redactionCount))
                        .shieldFont(12, weight: .bold)
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Text(LanguageManager.shared.editor("editor_apply_to_all"))
                        .shieldFont(11)
                        .foregroundColor(ShieldTheme.secondary(scheme))
                }
                Spacer()

                Button(action: onPropagate) {
                    Text(LanguageManager.shared.editor("editor_find_all"))
                        .shieldFont(12, weight: .bold)
                        .foregroundColor(ShieldTheme.accentText)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .background(ShieldTheme.accent(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, ShieldTheme.s4)
            .padding(.vertical, 6)
            .background(ShieldTheme.accentDim(scheme))
            .overlay(Rectangle().stroke(ShieldTheme.accentStroke(scheme), lineWidth: 0.5))
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

struct EditorModeChips: View {
    @Environment(\.colorScheme) private var scheme
    let activeMode: RedactionMode?
    let lang: AppLanguage
    let isPro: Bool
    let onLockedTap: () -> Void
    let onSelect: (RedactionMode) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(RedactionMode.allCases, id: \.self) { mode in
                    let isActive = activeMode == mode
                    let locked = mode.requiresPro && !isPro
                    Button {
                        locked ? onLockedTap() : onSelect(mode)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: locked ? "lock.fill" : mode.icon)
                                .shieldFont(11, weight: .semibold)
                            Text(mode.label(lang: lang))
                                .shieldFont(12, weight: .semibold)
                        }
                        .foregroundColor(locked ? ShieldTheme.tertiary(scheme) : (isActive ? ShieldTheme.accentText : ShieldTheme.primary(scheme)))
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(locked ? ShieldTheme.rowBackground(scheme) : (isActive ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme)))
                        .overlay(
                            Capsule()
                                .stroke(
                                    locked ? ShieldTheme.line(scheme) : (isActive ? ShieldTheme.accentStroke(scheme) : ShieldTheme.line(scheme)),
                                    lineWidth: isActive ? 1 : 0.5
                                )
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, ShieldTheme.s4)
            .padding(.vertical, 1)
        }
    }
}

struct EditorBottomToolbar: View {
    @Environment(\.colorScheme) private var scheme
    let canUndo: Bool
    let canRedo: Bool
    let selectedTool: EditorTool
    let activeMode: RedactionMode?
    let lang: AppLanguage
    let isPro: Bool
    let watermarkActive: Bool
    let adjustActive: Bool
    let adjustDirty: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onModeSelect: (RedactionMode) -> Void
    let onLockedModeTap: () -> Void
    let onToolTap: (EditorTool) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            HStack(alignment: .center, spacing: 4) {
                toolbarActionButton(
                    icon: "arrow.uturn.backward",
                    isEnabled: canUndo,
                    action: onUndo
                )

                toolbarActionButton(
                    icon: "arrow.uturn.forward",
                    isEnabled: canRedo,
                    action: onRedo
                )

                Menu {
                    ForEach(RedactionMode.allCases, id: \.self) { mode in
                        let locked = mode.requiresPro && !isPro
                        Button {
                            locked ? onLockedModeTap() : onModeSelect(mode)
                        } label: {
                            Label(
                                mode.label(lang: lang),
                                systemImage: locked
                                    ? "lock.fill"
                                    : (activeMode == mode ? "checkmark" : mode.icon)
                            )
                        }
                    }
                } label: {
                    Image(systemName: "shield.lefthalf.filled")
                        .shieldFont(20, weight: .medium)
                        .foregroundColor(activeMode == nil ? ShieldTheme.primary(scheme) : ShieldTheme.accent(scheme))
                        .frame(width: 48, height: 48)
                        .background(ShieldTheme.rowBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .accessibilityLabel(LanguageManager.shared.home("home_quick_modes"))
                .accessibilityValue(activeMode?.label(lang: lang) ?? "")
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .center, spacing: 6) {
                    ForEach(EditorTool.allCases) { tool in
                        let isSelected = selectedTool == tool
                        let hasBadge = (tool == .watermark && watermarkActive) || (tool == .adjust && adjustDirty)
                        let effectiveSelected = isSelected || (tool == .adjust && adjustActive)
                        Button {
                            onToolTap(tool)
                        } label: {
                            VStack(spacing: 2) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: tool.icon)
                                        .shieldFont(19, weight: .medium)
                                        .foregroundColor(effectiveSelected ? ShieldTheme.accentText : ShieldTheme.primary(scheme))
                                        .frame(width: 40, height: 40)
                                        .background(effectiveSelected ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))

                                    if effectiveSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(ShieldTheme.accentText, ShieldTheme.accent(scheme))
                                            .offset(x: 3, y: -3)
                                    }

                                    if hasBadge {
                                        Circle()
                                            .fill(tool == .adjust && adjustDirty ? ShieldTheme.info : ShieldTheme.success)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 2, y: -2)
                                    }
                                }
                                Text(tool.label(lang: lang))
                                    .shieldFont(10, weight: .bold)
                                    .foregroundColor(effectiveSelected ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .frame(minWidth: 48, minHeight: 48)
                        .accessibilityValue(effectiveSelected
                            ? LanguageManager.shared.common("common_selected")
                            : "")
                        .accessibilityAddTraits(effectiveSelected ? .isSelected : [])
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.top, 8)
        .padding(.bottom, 2)
        .background(ShieldTheme.cardBackground(scheme).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { ShieldDivider() }
    }

    private func toolbarActionButton(icon: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .shieldFont(20, weight: .medium)
                .foregroundColor(isEnabled ? ShieldTheme.primary(scheme) : ShieldTheme.quaternary(scheme))
                .frame(width: 48, height: 48)
                .background(ShieldTheme.rowBackground(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!isEnabled)
    }
}
