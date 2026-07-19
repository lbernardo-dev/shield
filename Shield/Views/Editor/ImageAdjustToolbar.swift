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

    @Environment(\.colorScheme) private var scheme
    @State private var activeTool: AdjustTool = .brightness

    enum AdjustTool: String, CaseIterable, Identifiable {
        case brightness, contrast, saturation, sharpness, crop
        var id: String { rawValue }

        func label() -> String {
            let key: String
            switch self {
            case .brightness:  key = "editor_adjust_brightness"
            case .contrast:    key = "editor_adjust_contrast"
            case .saturation:  key = "editor_adjust_saturation"
            case .sharpness:   key = "editor_adjust_sharpness"
            case .crop:        key = "editor_adjust_crop"
            }
            return LanguageManager.shared.editor(key)
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
                Text(LanguageManager.shared.editor("editor_adjust_title"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(ShieldTheme.primary(scheme))
                Spacer()
                if !vm.imageAdjustment.isDefault {
                    Button {
                        withAnimation { vm.resetAdjustment() }
                    } label: {
                        Text(LanguageManager.shared.common("common_reset"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ShieldTheme.danger)
                    }
                }
                Button {
                    withAnimation { vm.showAdjustPanel = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .frame(width: 26, height: 26)
                        .background(ShieldTheme.rowBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)

            ShieldDivider()

            // Quick action row: rotate + flip
            HStack(spacing: 8) {
                quickActionButton(icon: "rotate.right", label: LanguageManager.shared.editor("editor_adjust_rotate_90")) {
                    vm.rotateImage90CW()
                }
                quickActionButton(icon: "arrow.left.and.right.righttriangle.left.righttriangle.right", label: LanguageManager.shared.editor("editor_adjust_flip_h")) {
                    vm.flipImageHorizontal()
                }
                quickActionButton(icon: "arrow.up.and.down.righttriangle.up.righttriangle.down", label: LanguageManager.shared.editor("editor_adjust_flip_v")) {
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
                                Text(tool.label())
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(
                                isSelected
                                    ? ShieldTheme.accentText
                                    : (locked ? ShieldTheme.tertiary(scheme) : ShieldTheme.primary(scheme))
                            )
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(isSelected ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme))
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
                        label: LanguageManager.shared.editor("editor_adjust_brightness"),
                        value: Binding(get: { vm.imageAdjustment.brightness },
                                       set: { var a = vm.imageAdjustment; a.brightness = $0; vm.updateAdjustment(a) }),
                        range: -0.5...0.5, defaultValue: 0, format: "%.2f"
                    )
                case .contrast:
                    adjustSlider(
                        label: LanguageManager.shared.editor("editor_adjust_contrast"),
                        value: Binding(get: { vm.imageAdjustment.contrast },
                                       set: { var a = vm.imageAdjustment; a.contrast = $0; vm.updateAdjustment(a) }),
                        range: 0.5...2.0, defaultValue: 1.0, format: "%.2f"
                    )
                case .saturation:
                    adjustSlider(
                        label: LanguageManager.shared.editor("editor_adjust_saturation"),
                        value: Binding(get: { vm.imageAdjustment.saturation },
                                       set: { var a = vm.imageAdjustment; a.saturation = $0; vm.updateAdjustment(a) }),
                        range: 0...2.0, defaultValue: 1.0, format: "%.2f"
                    )
                case .sharpness:
                    adjustSlider(
                        label: LanguageManager.shared.editor("editor_adjust_sharpness"),
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
        .background(ShieldTheme.cardBackground(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
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
                    .foregroundColor(ShieldTheme.primary(scheme))
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(ShieldTheme.rowBackground(scheme))
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
                    .foregroundColor(ShieldTheme.secondary(scheme))
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(ShieldTheme.accent(scheme))
                    .frame(minWidth: 44, alignment: .trailing)

                Button {
                    value.wrappedValue = defaultValue
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .frame(width: 26, height: 26)
                        .background(ShieldTheme.rowBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            Slider(value: value, in: range)
                .tint(ShieldTheme.accent(scheme))
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private var cropSliders: some View {
        VStack(spacing: 10) {
            Text(LanguageManager.shared.editor("editor_adjust_crop_desc"))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ShieldTheme.tertiary(scheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)

            cropSide(LanguageManager.shared.editor("editor_adjust_top"),
                     binding: Binding(get: { vm.imageAdjustment.cropTop },
                                      set: { var a = vm.imageAdjustment; a.cropTop = $0; vm.updateAdjustment(a) }))
            cropSide(LanguageManager.shared.editor("editor_adjust_bottom"),
                     binding: Binding(get: { vm.imageAdjustment.cropBottom },
                                      set: { var a = vm.imageAdjustment; a.cropBottom = $0; vm.updateAdjustment(a) }))
            cropSide(LanguageManager.shared.editor("editor_adjust_left"),
                     binding: Binding(get: { vm.imageAdjustment.cropLeft },
                                      set: { var a = vm.imageAdjustment; a.cropLeft = $0; vm.updateAdjustment(a) }))
            cropSide(LanguageManager.shared.editor("editor_adjust_right"),
                     binding: Binding(get: { vm.imageAdjustment.cropRight },
                                      set: { var a = vm.imageAdjustment; a.cropRight = $0; vm.updateAdjustment(a) }))
        }
    }

    @ViewBuilder
    private func cropSide(_ label: String, binding: Binding<Double>) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ShieldTheme.secondary(scheme))
                .frame(width: 70, alignment: .leading)
            Slider(value: binding, in: 0...0.4, step: 0.005)
                .tint(ShieldTheme.accent(scheme))
            Text("\(Int((binding.wrappedValue * 100).rounded()))%")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(ShieldTheme.accent(scheme))
                .frame(width: 32, alignment: .trailing)
        }
    }
}
