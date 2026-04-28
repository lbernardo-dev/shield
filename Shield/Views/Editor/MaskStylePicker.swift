import SwiftUI

// MARK: - MaskStylePicker

struct MaskStylePicker: View {
    @Binding var selected: MaskStyle
    let lang: AppLanguage
    var isUnlocked: (MaskStyle) -> Bool = { _ in true }
    var onLockedSelect: ((MaskStyle) -> Void)? = nil
    var onSelect: ((MaskStyle) -> Void)? = nil

    var body: some View {
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
                }
            }
            .padding(.horizontal, ShieldTheme.s4)
            .padding(.vertical, 6)
        }
        .background(ShieldTheme.surface1)
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

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    StylePreviewMini(style: style)
                        .frame(width: 56, height: 22)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    if !isUnlocked {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(ShieldTheme.accentText)
                            .padding(4)
                            .background(ShieldTheme.accent)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }

                Text(style.label(lang: lang))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? ShieldTheme.accent : (isUnlocked ? ShieldTheme.textSecondary : ShieldTheme.textTertiary))
                    .lineLimit(1)
            }
            .padding(6)
            .background(isSelected ? ShieldTheme.accentDim : ShieldTheme.surface2)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? ShieldTheme.accent : ShieldTheme.surfaceLine, lineWidth: isSelected ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(minWidth: 60)
        }
        .buttonStyle(ScaleButtonStyle())
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
