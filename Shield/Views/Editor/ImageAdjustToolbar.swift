import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - ImageAdjustToolbar
// Full-featured image adjustment panel: brightness, contrast, saturation,
// sharpness, rotation (90° steps), flip H/V, and crop insets.

struct ImageAdjustToolbar: View {
    @ObservedObject var vm: EditorViewModel
    let lang: AppLanguage
    let isPro: Bool
    var onShowPaywall: () -> Void

    @State private var activeTool: AdjustTool = .brightness

    enum AdjustTool: String, CaseIterable, Identifiable {
        case brightness, contrast, saturation, sharpness, crop
        var id: String { rawValue }

        func label(lang: AppLanguage) -> String {
            let key: String
            switch self {
            case .brightness:  key = "editor_adjust_brightness"
            case .contrast:    key = "editor_adjust_contrast"
            case .saturation:  key = "editor_adjust_saturation"
            case .sharpness:   key = "editor_adjust_sharpness"
            case .crop:        key = "editor_adjust_crop"
            }
            return LanguageManager.shared.str(key, table: "Editor")
        }

        var icon: String {
            switch self {
            case .brightness:  return "sun.max"
            case .contrast:    return "circle.lefthalf.filled"
            case .saturation:  return "paintpalette"
            case .sharpness:   return "wand.and.rays"
            case .crop:        return "crop"
            }
        }

        var isPremium: Bool {
            switch self {
            case .brightness, .contrast: return false
            default: return true
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Text(LanguageManager.shared.str("editor_adjust_title", table: "Editor"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Spacer()
                if !vm.imageAdjustment.isDefault {
                    Button {
                        withAnimation { vm.resetAdjustment() }
                    } label: {
                        Text(LanguageManager.shared.str("common_reset", table: "Common"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ShieldTheme.danger)
                    }
                }
                Button {
                    withAnimation { vm.showAdjustPanel = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 26, height: 26)
                        .background(ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            ShieldDivider()

            // Quick action row: rotate + flip
            HStack(spacing: 8) {
                quickActionButton(icon: "rotate.right", label: LanguageManager.shared.str("editor_adjust_rotate_90", table: "Editor")) {
                    vm.rotateImage90CW()
                }
                quickActionButton(icon: "arrow.left.and.right.righttriangle.left.righttriangle.right", label: LanguageManager.shared.str("editor_adjust_flip_h", table: "Editor")) {
                    vm.flipImageHorizontal()
                }
                quickActionButton(icon: "arrow.up.and.down.righttriangle.up.righttriangle.down", label: LanguageManager.shared.str("editor_adjust_flip_v", table: "Editor")) {
                    vm.flipImageVertical()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            ShieldDivider()

            // Tool picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(AdjustTool.allCases) { tool in
                        let isSelected = activeTool == tool
                        let locked = tool.isPremium && !isPro
                        Button {
                            if locked { onShowPaywall(); return }
                            withAnimation(.easeInOut(duration: 0.15)) { activeTool = tool }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: locked ? "lock.fill" : tool.icon)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(tool.label(lang: lang))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(isSelected ? .black : (locked ? ShieldTheme.textTertiary : ShieldTheme.textPrimary))
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(isSelected ? ShieldTheme.accent : ShieldTheme.surface3)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }

            // Active slider
            Group {
                switch activeTool {
                case .brightness:
                    adjustSlider(
                        label: LanguageManager.shared.str("editor_adjust_brightness", table: "Editor"),
                        value: Binding(get: { vm.imageAdjustment.brightness },
                                       set: { var a = vm.imageAdjustment; a.brightness = $0; vm.updateAdjustment(a) }),
                        range: -0.5...0.5, defaultValue: 0, format: "%.2f"
                    )
                case .contrast:
                    adjustSlider(
                        label: LanguageManager.shared.str("editor_adjust_contrast", table: "Editor"),
                        value: Binding(get: { vm.imageAdjustment.contrast },
                                       set: { var a = vm.imageAdjustment; a.contrast = $0; vm.updateAdjustment(a) }),
                        range: 0.5...2.0, defaultValue: 1.0, format: "%.2f"
                    )
                case .saturation:
                    adjustSlider(
                        label: LanguageManager.shared.str("editor_adjust_saturation", table: "Editor"),
                        value: Binding(get: { vm.imageAdjustment.saturation },
                                       set: { var a = vm.imageAdjustment; a.saturation = $0; vm.updateAdjustment(a) }),
                        range: 0...2.0, defaultValue: 1.0, format: "%.2f"
                    )
                case .sharpness:
                    adjustSlider(
                        label: LanguageManager.shared.str("editor_adjust_sharpness", table: "Editor"),
                        value: Binding(get: { vm.imageAdjustment.sharpness },
                                       set: { var a = vm.imageAdjustment; a.sharpness = $0; vm.updateAdjustment(a) }),
                        range: 0...1.0, defaultValue: 0, format: "%.2f"
                    )
                case .crop:
                    cropSliders
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(ShieldTheme.surface1)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ShieldTheme.surfaceLine, lineWidth: 0.5)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Subviews

    @ViewBuilder
    private func quickActionButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(ShieldTheme.textPrimary)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(ShieldTheme.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(ShieldTheme.surface3)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func adjustSlider(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        defaultValue: Double,
        format: String
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ShieldTheme.textSecondary)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(ShieldTheme.accent)
                    .frame(minWidth: 44, alignment: .trailing)

                Button {
                    value.wrappedValue = defaultValue
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 26, height: 26)
                        .background(ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            Slider(value: value, in: range)
                .tint(ShieldTheme.accent)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var cropSliders: some View {
        VStack(spacing: 10) {
            Text(LanguageManager.shared.str("editor_adjust_crop_desc", table: "Editor"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ShieldTheme.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

            cropSide(LanguageManager.shared.str("editor_adjust_top", table: "Editor"),
                     binding: Binding(get: { vm.imageAdjustment.cropTop },
                                      set: { var a = vm.imageAdjustment; a.cropTop = $0; vm.updateAdjustment(a) }))
            cropSide(LanguageManager.shared.str("editor_adjust_bottom", table: "Editor"),
                     binding: Binding(get: { vm.imageAdjustment.cropBottom },
                                      set: { var a = vm.imageAdjustment; a.cropBottom = $0; vm.updateAdjustment(a) }))
            cropSide(LanguageManager.shared.str("editor_adjust_left", table: "Editor"),
                     binding: Binding(get: { vm.imageAdjustment.cropLeft },
                                      set: { var a = vm.imageAdjustment; a.cropLeft = $0; vm.updateAdjustment(a) }))
            cropSide(LanguageManager.shared.str("editor_adjust_right", table: "Editor"),
                     binding: Binding(get: { vm.imageAdjustment.cropRight },
                                      set: { var a = vm.imageAdjustment; a.cropRight = $0; vm.updateAdjustment(a) }))
        }
    }

    @ViewBuilder
    private func cropSide(_ label: String, binding: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ShieldTheme.textSecondary)
                .frame(width: 70, alignment: .leading)
            Slider(value: binding, in: 0...0.4, step: 0.005)
                .tint(ShieldTheme.accent)
            Text("\(Int((binding.wrappedValue * 100).rounded()))%")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(ShieldTheme.accent)
                .frame(width: 32, alignment: .trailing)
        }
    }
}
