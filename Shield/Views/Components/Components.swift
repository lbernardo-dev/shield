import SwiftUI
import UIKit

// MARK: - ShieldButton

struct ShieldButton: View {
    enum Style { case primary, secondary, ghost, danger }

    let label: String
    var icon: String? = nil
    var style: Style = .primary
    var height: CGFloat = 44
    var action: () -> Void

    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(bgColor)
            .foregroundColor(fgColor)
            .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var bgColor: Color {
        switch style {
        case .primary:   return ShieldTheme.accent(scheme)
        case .secondary: return ShieldTheme.rowBackground(scheme)
        case .ghost:     return .clear
        case .danger:    return ShieldTheme.dangerDim
        }
    }
    private var fgColor: Color {
        switch style {
        case .primary:   return ShieldTheme.accentText
        case .secondary: return ShieldTheme.primary(scheme)
        case .ghost:     return ShieldTheme.primary(scheme)
        case .danger:    return ShieldTheme.danger
        }
    }
}

// MARK: - ScaleButtonStyle

struct ScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                guard isPressed else { return }
                AppState.markUserActivity()
                ShieldHaptics.impactLight()
            }
    }
}

enum ShieldHaptics {
    static var isEnabled: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "shield.haptic") == nil { return true }
        return defaults.bool(forKey: "shield.haptic")
    }

    static func impactLight() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - PillButton

struct PillButton: View {
    let label: String
    var icon: String? = nil
    var isActive: Bool = false
    var action: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isActive ? ShieldTheme.accentDim(scheme) : ShieldTheme.cardBackground(scheme))
            .foregroundColor(isActive ? ShieldTheme.accent(scheme) : ShieldTheme.primary(scheme))
            .overlay(
                Capsule()
                    .stroke(isActive ? ShieldTheme.accentStroke(scheme) : ShieldTheme.line(scheme), lineWidth: isActive ? 1 : 0.5)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(minHeight: 44)
        .accessibilityValue(LanguageManager.shared.common(isActive ? "common_selected" : "common_not_selected"))
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - IconButton

struct IconButton: View {
    let icon: String
    var accessibilityName: String? = nil
    var size: CGFloat = 32
    var color: Color? = nil
    var background: Color? = nil
    var action: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(color ?? ShieldTheme.primary(scheme))
                .frame(width: size, height: size)
                .background {
                    if #available(iOS 26, *) {
                        Color.clear
                            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: ShieldTheme.rSM))
                    } else {
                        RoundedRectangle(cornerRadius: ShieldTheme.rSM)
                            .fill(background ?? ShieldTheme.cardBackground(scheme))
                    }
                }
                .overlay {
                    if #available(iOS 26, *) {
                        EmptyView()
                    } else {
                        RoundedRectangle(cornerRadius: ShieldTheme.rSM)
                            .stroke(ShieldTheme.line(scheme), lineWidth: 0.5)
                    }
                }
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityName ?? icon.replacingOccurrences(of: ".", with: " "))
    }
}

// MARK: - ShieldToggle

struct ShieldToggle: View {
    @Binding var isOn: Bool
    var accessibilityName: String = "Opción"
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .frame(width: 44, height: 26)
                    .foregroundColor(isOn ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme))
                    .overlay(
                        Capsule()
                            .stroke(isOn ? ShieldTheme.accentStroke(scheme) : ShieldTheme.line(scheme), lineWidth: 1)
                    )
                Circle()
                    .frame(width: 22, height: 22)
                    .foregroundColor(isOn ? ShieldTheme.accentText : ShieldTheme.primary(scheme))
                    .padding(2)
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel(accessibilityName)
        .accessibilityValue(LanguageManager.shared.common(isOn ? "common_enabled" : "common_disabled"))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See all"
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(ShieldTheme.tertiary(scheme))
                .tracking(0.4)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 4)
            Spacer()
            if let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(ShieldTheme.accent(scheme))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - ShieldProgressDots

struct ShieldProgressDots: View {
    let count: Int
    let current: Int
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .frame(width: i == current ? 22 : 6, height: 6)
                    .foregroundColor(i == current ? ShieldTheme.accent : ShieldTheme.rowBackground(scheme))
                    .animation(.spring(response: 0.3), value: current)
            }
        }
    }
}

// MARK: - StatusBarSpacer

struct StatusBarSpacer: View {
    var body: some View {
        Color.clear.frame(height: 50)
    }
}

// MARK: - ShieldDivider

struct ShieldDivider: View {
    @Environment(\.colorScheme) var scheme
    var body: some View {
        Rectangle()
            .frame(height: 0.5)
            .foregroundColor(ShieldTheme.line(scheme))
    }
}

// MARK: - ShieldSheet

struct ShieldSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let heightFraction: CGFloat
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) var scheme

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                if isPresented {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture { withAnimation { isPresented = false } }
                        .transition(.opacity)

                    VStack(spacing: 0) {
                        // Handle
                        Capsule()
                            .frame(width: 36, height: 4)
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                            .padding(.top, 10)
                            .padding(.bottom, 4)

                        content()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: geo.size.height * heightFraction)
                    .background(ShieldTheme.cardBackground(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rXL))
                    .transition(.move(edge: .bottom))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
        }
        .ignoresSafeArea()
    }
}

// MARK: - On-device badge

struct OnDeviceBadge: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ShieldTheme.success)
            Text(LanguageManager.shared.common("common_on_device"))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ShieldTheme.success)
        }
    }
}
