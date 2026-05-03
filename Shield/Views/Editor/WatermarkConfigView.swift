import SwiftUI

// MARK: - WatermarkConfigView

struct WatermarkConfigView: View {
    let lang: AppLanguage
    let defaultText: String
    @Binding var isPresented: Bool
    let onSave: (Watermark?) -> Void

    @State private var text: String
    @State private var opacity: Double
    @State private var isRepeating: Bool
    @State private var selectedColor: Color

    init(watermark: Watermark?, lang: AppLanguage, defaultText: String, isPresented: Binding<Bool>, onSave: @escaping (Watermark?) -> Void) {
        self.lang = lang
        self.defaultText = defaultText
        self._isPresented = isPresented
        self.onSave = onSave
        self._text = State(initialValue: watermark?.text ?? defaultText)
        self._opacity = State(initialValue: watermark?.opacity ?? 0.18)
        self._isRepeating = State(initialValue: watermark?.isRepeating ?? true)
        self._selectedColor = State(initialValue: watermark != nil ? Color(hex: watermark!.colorHex) : .black)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(LanguageManager.shared.editor("editor_watermark_title"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Spacer()
                Button {
                    onSave(nil)
                    isPresented = false
                } label: {
                    Text(LanguageManager.shared.editor("editor_watermark_remove"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(ShieldTheme.danger)
                }
                Button {
                    isPresented = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.top, 18)
            .padding(.bottom, 14)

            ShieldDivider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Text field
                    VStack(alignment: .leading, spacing: 8) {
                        label(LanguageManager.shared.editor("editor_watermark_text"))
                        TextField(LanguageManager.shared.editor("editor_watermark_placeholder"), text: $text)
                            .font(.system(size: 14))
                            .foregroundColor(ShieldTheme.textPrimary)
                            .padding(.horizontal, 12)
                            .frame(height: 40)
                            .background(ShieldTheme.surface3)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(ShieldTheme.surfaceLine, lineWidth: 0.5)
                            )
                    }

                    // Opacity
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            label(LanguageManager.shared.editor("editor_watermark_opacity"))
                            Spacer()
                            Text("\(Int(opacity * 100))%")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ShieldTheme.textSecondary)
                        }
                        Slider(value: $opacity, in: 0.05...0.6, step: 0.01)
                            .tint(ShieldTheme.accent)
                    }

                    // Color
                    HStack {
                        label(LanguageManager.shared.editor("editor_watermark_color"))
                        Spacer()
                        ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 32, height: 32)
                    }

                    // Repeat toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LanguageManager.shared.editor("editor_watermark_tile_title"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ShieldTheme.textPrimary)
                            Text(LanguageManager.shared.editor("editor_watermark_tile_desc"))
                                .font(.system(size: 11))
                                .foregroundColor(ShieldTheme.textTertiary)
                        }
                        Spacer()
                        Toggle("", isOn: $isRepeating)
                            .labelsHidden()
                            .tint(ShieldTheme.accent)
                    }

                    // Live preview
                    VStack(alignment: .leading, spacing: 8) {
                        label(LanguageManager.shared.editor("editor_preview"))
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "E8E4D8"))
                                .frame(height: 70)
                            if !text.isEmpty {
                                Canvas { context, size in
                                    drawWatermark(context: &context, size: size, watermark: previewWatermark)
                                }
                                .frame(height: 70)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(ShieldTheme.surfaceLine, lineWidth: 0.5))
                    }
                }
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.vertical, 16)
            }

            // Save button
            VStack(spacing: 0) {
                ShieldDivider()
                Button {
                    onSave(previewWatermark)
                    isPresented = false
                } label: {
                    Text(LanguageManager.shared.editor("editor_watermark_apply"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ShieldTheme.accentText)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(text.isEmpty ? ShieldTheme.surface3 : ShieldTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(text.isEmpty)
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
    }

    private var previewWatermark: Watermark {
        let uiColor = UIColor(selectedColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let hex = String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        return Watermark(text: text, opacity: opacity, isRepeating: isRepeating, colorHex: hex)
    }

    @ViewBuilder
    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(ShieldTheme.textTertiary)
            .tracking(0.5)
    }
}
