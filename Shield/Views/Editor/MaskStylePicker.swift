import SwiftUI

// MARK: - MaskStylePicker

struct MaskStylePicker: View {
    @Binding var selected: MaskStyle
    let lang: AppLanguage
    var isUnlocked: (MaskStyle) -> Bool = { _ in true }
    var onLockedSelect: ((MaskStyle) -> Void)? = nil
    var onSelect: ((MaskStyle) -> Void)? = nil
    @Environment(\.colorScheme) var scheme
    @State private var showingEndOfStyles = false

    var body: some View {
        ScrollViewReader { proxy in
            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(MaskStyle.allCases) { style in
                            let unlocked = isUnlocked(style)
                            StyleCell(
                                style: style,
                                isSelected: selected == style,
                                isUnlocked: unlocked,
                                lang: lang
                            ) {
                                if unlocked {
                                    selected = style
                                    onSelect?(style)
                                } else {
                                    onLockedSelect?(style)
                                }
                            }
                            .id(style.id)
                        }
                    }
                    .padding(.leading, ShieldTheme.s4)
                    .padding(.trailing, ShieldTheme.s2)
                    .padding(.vertical, 2)
                }

                Button {
                    let styles = MaskStyle.allCases
                    let target = showingEndOfStyles ? styles[0] : styles[styles.count - 1]
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(target.id, anchor: showingEndOfStyles ? .leading : .trailing)
                        showingEndOfStyles.toggle()
                    }
                } label: {
                    Image(systemName: showingEndOfStyles ? "chevron.left" : "chevron.right")
                        .shieldFont(11, weight: .bold)
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                        .frame(width: 36, height: 48)
                        .background {
                            LinearGradient(
                                colors: [ShieldTheme.background(scheme).opacity(0.15), ShieldTheme.background(scheme)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    lang == .es
                        ? (showingEndOfStyles ? "Primeros estilos de máscara" : "Más estilos de máscara")
                        : (showingEndOfStyles ? "First mask styles" : "More mask styles")
                )
                .accessibilityIdentifier("editor.maskStyle.scroll")
            }
            .onChange(of: selected) { _, newStyle in
                let styles = MaskStyle.allCases
                if let index = styles.firstIndex(of: newStyle) {
                    showingEndOfStyles = index >= styles.count - 3
                }
                withAnimation(.easeInOut(duration: 0.18)) {
                    proxy.scrollTo(newStyle.id, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ShieldTheme.background(scheme), ignoresSafeAreaEdges: [])
        .overlay(alignment: .top) {
            ShieldDivider()
        }
    }
}

// MARK: - StyleCell

private struct StyleCell: View {
    let style: MaskStyle
    let isSelected: Bool
    let isUnlocked: Bool
    let lang: AppLanguage
    let action: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) { // Reduced from 4
                ZStack(alignment: .topTrailing) {
                    StylePreviewMini(style: style)
                        .frame(width: 56, height: 22)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .shieldFont(8, weight: .bold)
                            .foregroundColor(ShieldTheme.accentText)
                            .padding(4)
                            .background(ShieldTheme.accent)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }

                Text(style.label(lang: lang))
                    .shieldFont(10, weight: .semibold)
                    .foregroundColor(isSelected ? ShieldTheme.accent : (isUnlocked ? ShieldTheme.secondary(scheme) : ShieldTheme.tertiary(scheme)))
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3) // Reduced from 6
            .background(isSelected ? ShieldTheme.accentDim : ShieldTheme.cardBackground(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? ShieldTheme.accent : ShieldTheme.line(scheme), lineWidth: isSelected ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(minWidth: 60)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("editor.maskStyle.\(style.id)")
    }
}

// MARK: - StylePreviewMini
// Small 56×22 preview showing the mask applied over sample text

struct StylePreviewMini: View {
    let style: MaskStyle

    var body: some View {
        Canvas { context, size in
            // Background (document color)
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(hex: "E8E4D8")))
            // Sample text behind
            let t = Text("12345678Z")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "333333"))
            context.draw(t, at: CGPoint(x: 3, y: 5), anchor: .topLeading)
            // Mask over text
            let maskRect = CGRect(x: 2, y: 4, width: size.width - 4, height: size.height - 8)
            drawMask(context: &context, rect: maskRect, style: style, id: "preview-\(style.rawValue)")
        }
    }
}
