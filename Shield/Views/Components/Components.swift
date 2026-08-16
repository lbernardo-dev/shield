import SwiftUI

// MARK: - ShieldButton

struct ShieldButton: View {
    enum Style { case primary, secondary, ghost, danger }

    let label: String
    var icon: String? = nil
    var style: Style = .primary
    var height: CGFloat = ShieldTheme.controlHeight
    var isLoading = false
    var action: () -> Void

    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .tint(fgColor)
                        .accessibilityHidden(true)
                } else if let icon {
                    Image(systemName: icon)
                        .shieldFont(15, weight: .semibold)
                }
                Text(label)
                    .shieldFont(15, weight: .semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: max(ShieldTheme.minimumTapTarget, height))
            .padding(.horizontal, ShieldTheme.s4)
            .background(bgColor)
            .foregroundColor(fgColor)
            .overlay {
                RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                    .stroke(borderColor, lineWidth: contrast == .increased ? 1.5 : 0.75)
            }
            .clipShape(.rect(cornerRadius: ShieldTheme.rMD))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isLoading)
        .accessibilityValue(isLoading ? LanguageManager.shared.common("common_loading") : "")
    }

    private var bgColor: Color {
        guard isEnabled && !isLoading else { return ShieldTheme.rowBackground(scheme) }
        switch style {
        case .primary:   return ShieldTheme.accent(scheme)
        case .secondary: return ShieldTheme.rowBackground(scheme)
        case .ghost:     return .clear
        case .danger:    return ShieldTheme.dangerDim
        }
    }
    private var fgColor: Color {
        guard isEnabled && !isLoading else { return ShieldTheme.tertiary(scheme) }
        switch style {
        case .primary:   return ShieldTheme.accentText
        case .secondary: return ShieldTheme.primary(scheme)
        case .ghost:     return ShieldTheme.primary(scheme)
        case .danger:    return ShieldTheme.danger
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: .clear
        case .secondary, .ghost: ShieldTheme.line(scheme)
        case .danger: ShieldTheme.danger.opacity(0.42)
        }
    }
}

// MARK: - ScaleButtonStyle

struct ScaleButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.97 : 1))
            .opacity(isEnabled ? 1 : 0.62)
            .animation(reduceMotion ? nil : ShieldMotion.press, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                guard isPressed else { return }
                AppState.markUserActivity()
            }
            .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, isPressed in
                isPressed && isEnabled && ShieldHaptics.isEnabled
            }
    }
}

enum ShieldHaptics {
    static var isEnabled: Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "shield.haptic") == nil { return true }
        return defaults.bool(forKey: "shield.haptic")
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
                        .shieldFont(12, weight: .semibold)
                }
                Text(label)
                    .shieldFont(13, weight: .semibold)
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
                .background(background ?? ShieldTheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: ShieldTheme.rSM))
                .overlay(
                    RoundedRectangle(cornerRadius: ShieldTheme.rSM)
                        .stroke(ShieldTheme.line(scheme), lineWidth: 0.5)
                )
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : ShieldMotion.state) { isOn.toggle() }
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
        .accessibilityRepresentation {
            Toggle(accessibilityName, isOn: $isOn)
        }
    }
}

// MARK: - SectionHeader

struct SectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String = "See all"
    @Environment(\.colorScheme) var scheme

    var body: some View {
        HStack(alignment: .center) {
            Text(title.uppercased())
                .shieldFont(11, weight: .bold)
                .foregroundColor(ShieldTheme.tertiary(scheme))
                .tracking(0.6)
                .lineLimit(1)
            Spacer()
            if let action {
                Button(action: action) {
                    Text(actionLabel)
                        .shieldFont(13, weight: .bold)
                        .foregroundColor(ShieldTheme.accent(scheme))
                        .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.vertical, 4)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - ShieldProgressDots

struct ShieldProgressDots: View {
    let count: Int
    let current: Int
    @Environment(\.colorScheme) var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .frame(width: i == current ? 22 : 6, height: 6)
                    .foregroundColor(i == current ? ShieldTheme.accent : ShieldTheme.rowBackground(scheme))
                    .animation(reduceMotion ? nil : ShieldMotion.state, value: current)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                if isPresented {
                    ShieldTheme.scrim(scheme)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(reduceMotion ? nil : ShieldMotion.state) {
                                isPresented = false
                            }
                        }
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
            .animation(reduceMotion ? nil : ShieldMotion.navigation, value: isPresented)
        }
        .ignoresSafeArea()
        .accessibilityAddTraits(isPresented ? .isModal : [])
        .accessibilityAction(.escape) { isPresented = false }
    }
}

// MARK: - Shared surface primitives

struct ShieldRow<Leading: View, Content: View, Trailing: View>: View {
    @ViewBuilder let leading: Leading
    @ViewBuilder let content: Content
    @ViewBuilder let trailing: Trailing

    init(
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder content: () -> Content,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.leading = leading()
        self.content = content()
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: ShieldTheme.s3) {
            leading
            content
                .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(ShieldTheme.s4)
        .contentShape(.rect)
    }
}

struct ShieldStateView: View {
    enum Kind {
        case empty
        case loading
        case error
        case success
    }

    let kind: Kind
    let title: String
    var message: String? = nil
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: ShieldTheme.s3) {
            stateIcon
                .font(.title.weight(.semibold))
                .frame(width: 56, height: 56)
                .background(iconColor.opacity(0.14), in: Circle())
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            Text(title)
                .font(.headline)
                .foregroundStyle(ShieldTheme.primary(scheme))
                .multilineTextAlignment(.center)

            if let message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionLabel, let action {
                ShieldButton(label: actionLabel, style: .secondary, action: action)
                    .frame(maxWidth: 320)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(ShieldTheme.s6)
        .accessibilityElement(children: action == nil ? .combine : .contain)
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch kind {
        case .loading:
            ProgressView()
        default:
            Image(systemName: iconName)
        }
    }

    private var iconName: String {
        switch kind {
        case .empty: "tray"
        case .loading: "hourglass"
        case .error: "exclamationmark.triangle.fill"
        case .success: "checkmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch kind {
        case .empty, .loading: ShieldTheme.accent(scheme)
        case .error: ShieldTheme.danger
        case .success: ShieldTheme.success
        }
    }
}

struct ShieldStickyFooter<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(.horizontal, ShieldTheme.s4)
            .padding(.vertical, ShieldTheme.s3)
            .background(
                reduceTransparency
                    ? ShieldTheme.elevatedBackground(scheme)
                    : ShieldTheme.cardBackground(scheme).opacity(0.96)
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(ShieldTheme.line(scheme))
                    .frame(height: 0.5)
            }
    }
}

struct ShieldStatusLabel: View {
    enum Kind { case info, success, warning, error }

    let text: String
    let kind: Kind
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Label(text, systemImage: icon)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(color)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, ShieldTheme.s3)
            .padding(.vertical, ShieldTheme.s2)
            .background(background, in: Capsule())
    }

    private var icon: String {
        switch kind {
        case .info: "info.circle.fill"
        case .success: "checkmark.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    private var color: Color {
        switch kind {
        case .info: ShieldTheme.accent(scheme)
        case .success: ShieldTheme.success
        case .warning: ShieldTheme.warning
        case .error: ShieldTheme.danger
        }
    }

    private var background: Color {
        switch kind {
        case .info: ShieldTheme.accentDim(scheme)
        case .success: ShieldTheme.successBackground(scheme)
        case .warning: ShieldTheme.warningBackground(scheme)
        case .error: ShieldTheme.errorBackground(scheme)
        }
    }
}

// MARK: - On-device badge

struct OnDeviceBadge: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.fill")
                .shieldFont(11, weight: .semibold)
                .foregroundColor(ShieldTheme.success)
            Text(LanguageManager.shared.common("common_on_device"))
                .shieldFont(12, weight: .semibold)
                .foregroundColor(ShieldTheme.success)
        }
    }
}

#if DEBUG
private struct ShieldComponentCatalog: View {
    @State private var toggle = true
    @State private var selectedChip = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: ShieldTheme.s5) {
                SectionHeader(title: "Actions")
                ShieldButton(label: "Primary action", icon: "sparkles") {}
                ShieldButton(label: "Secondary action", style: .secondary) {}
                ShieldButton(label: "Delete securely", icon: "trash", style: .danger) {}
                ShieldButton(label: "Processing", isLoading: true) {}

                HStack {
                    PillButton(label: "Selected", isActive: selectedChip) {
                        selectedChip.toggle()
                    }
                    IconButton(icon: "slider.horizontal.3", accessibilityName: "Filters") {}
                    ShieldToggle(isOn: $toggle, accessibilityName: "Example toggle")
                }

                ShieldStatusLabel(text: "Stored on this device", kind: .success)

                ShieldStateView(
                    kind: .empty,
                    title: "No documents yet",
                    message: "Scan or import a document to start protecting it.",
                    actionLabel: "Add document"
                ) {}
                .shieldCard()
            }
            .frame(maxWidth: 520)
            .padding(ShieldTheme.s5)
        }
        .background(ShieldTheme.pageBackground(.dark).ignoresSafeArea())
    }
}

#Preview("Components · Dark") {
    ShieldComponentCatalog()
        .preferredColorScheme(.dark)
}

#Preview("Components · Light · AX") {
    ShieldComponentCatalog()
        .preferredColorScheme(.light)
        .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
