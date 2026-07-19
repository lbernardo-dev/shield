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
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.primary(scheme))
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(changeCountLabel)
                .font(.system(size: 11, weight: .bold))
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ShieldTheme.warning)

                VStack(alignment: .leading, spacing: 1) {
                    Text(titleText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Text(subtitleText)
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.secondary(scheme))
                }
                Spacer()

                Button(action: onApply) {
                    Text(LanguageManager.shared.common("common_apply"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShieldTheme.accentText)
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .background(ShieldTheme.warning)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(suggestedRedactionCount == 0 || isAnalyzing)
                .opacity((suggestedRedactionCount == 0 || isAnalyzing) ? 0.55 : 1)

                Button(action: onOpenFields) {
                    Text(LanguageManager.shared.editor("editor_sensitive_fields_button"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShieldTheme.accent(scheme))
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(ShieldTheme.accentDim(scheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 0.8)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .padding(4)
                }
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ShieldTheme.accent(scheme))

                VStack(alignment: .leading, spacing: 1) {
                    Text(LanguageManager.shared.editor("editor_redactions_on_page", redactionCount))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Text(LanguageManager.shared.editor("editor_apply_to_all"))
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.secondary(scheme))
                }
                Spacer()

                Button(action: onPropagate) {
                    Text(LanguageManager.shared.editor("editor_find_all"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShieldTheme.accentText)
                        .padding(.horizontal, 12)
                        .frame(height: 28)
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
                                .font(.system(size: 11, weight: .semibold))
                            Text(mode.label(lang: lang))
                                .font(.system(size: 12, weight: .semibold))
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
    let lang: AppLanguage
    let watermarkActive: Bool
    let adjustActive: Bool
    let adjustDirty: Bool
    let toolHelpText: String
    let onUndo: () -> Void
    let onRedo: () -> Void
    let onToolTap: (EditorTool) -> Void

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                HStack(spacing: 4) {
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
                }

                Spacer()

                HStack(spacing: 8) {
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
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(effectiveSelected ? ShieldTheme.accentText : ShieldTheme.primary(scheme))
                                        .frame(width: 32, height: 32)
                                        .background(effectiveSelected ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    if hasBadge {
                                        Circle()
                                            .fill(tool == .adjust && adjustDirty ? ShieldTheme.info : ShieldTheme.success)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 2, y: -2)
                                    }
                                }
                                Text(tool.label(lang: lang))
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(effectiveSelected ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: selectedTool == .rect ? "hand.draw" : "info.circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                Text(toolHelpText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                Spacer()
            }
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(ShieldTheme.rowBackground(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.top, 6)
        .padding(.bottom, 0)
        .background(ShieldTheme.cardBackground(scheme).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { ShieldDivider() }
    }

    private func toolbarActionButton(icon: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isEnabled ? ShieldTheme.primary(scheme) : ShieldTheme.quaternary(scheme))
                .frame(width: 32, height: 32)
                .background(ShieldTheme.rowBackground(scheme))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .disabled(!isEnabled)
    }
}
