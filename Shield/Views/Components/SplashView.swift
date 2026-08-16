import SwiftUI

/// Shared MaskID identity treatment with circular form, feathered gradient edges, and integrated ambient lighting.
struct MaskIDIdentityMark: View {
    enum Presentation {
        case animatedOnce
        case animatedLoop
        case staticMark
    }

    enum Treatment {
        case splash
        case hero
        case feature
        case card
        case compact
    }

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false
    @State private var scanPhase: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var rotationAngle: Double = 0

    let size: CGFloat
    var presentation: Presentation = .animatedOnce
    var treatment: Treatment = .hero
    var isEmphasized = false
    var onAnimationFinished: ((Bool) -> Void)?

    var body: some View {
        ZStack {
            if showsHalo {
                ambientHaloLayers
            }

            markContainer
                .scaleEffect(isEmphasized && !reduceMotion ? 1.04 : 1)
                .animation(.smooth(duration: 0.22), value: isEmphasized)
        }
        .frame(width: size, height: size)
        .scaleEffect(usesEntranceMotion && !hasAppeared ? 0.94 : 1)
        .opacity(usesEntranceMotion && !hasAppeared ? 0 : 1)
        .animation(
            reduceMotion ? nil : .spring(response: 0.52, dampingFraction: 0.82),
            value: hasAppeared
        )
        .onAppear {
            hasAppeared = true
            startAnimations()
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    // MARK: - Ambient Halo Layers (Concentric Circular Energy)

    @ViewBuilder
    private var ambientHaloLayers: some View {
        let isDark = scheme == .dark

        // Deep soft radial glow backlight
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hex: "00B4D8").opacity(isDark ? 0.38 : 0.24),
                        Color(hex: "0077B6").opacity(isDark ? 0.18 : 0.10),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: size * 0.56
                )
            )
            .scaleEffect(pulseScale)

        // Outer slow-rotating dashed orbital ring
        Circle()
            .stroke(
                ShieldTheme.accent(scheme).opacity(isDark ? 0.20 : 0.14),
                style: StrokeStyle(lineWidth: 1.2, dash: [6, 12])
            )
            .padding(size * 0.04)
            .rotationEffect(.degrees(rotationAngle))

        // Mid dynamic neon energy ring
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        ShieldTheme.accent(scheme).opacity(isDark ? 0.45 : 0.30),
                        Color.clear,
                        ShieldTheme.accent(scheme).opacity(isDark ? 0.30 : 0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .padding(size * 0.12)

        // Inner soft rim ring
        Circle()
            .stroke(
                ShieldTheme.accent(scheme).opacity(isDark ? 0.28 : 0.16),
                lineWidth: 1
            )
            .padding(size * 0.20)
    }

    // MARK: - Circular Sculpted Icon Container with Feathered Gradient Edges

    @ViewBuilder
    private var markContainer: some View {
        let markSize = staticMarkSize
        let isCircular = treatment != .compact

        ZStack {
            // Glassmorphic Base with Deep Radial Lighting
            if isCircular {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(hex: "071E36").opacity(scheme == .dark ? 0.95 : 0.6),
                                Color(hex: "030E1B").opacity(scheme == .dark ? 0.98 : 0.4),
                                Color(hex: "01050A").opacity(scheme == .dark ? 1.0 : 0.2)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: markSize * 0.5
                        )
                    )
                    .frame(width: markSize, height: markSize)
            } else {
                RoundedRectangle(cornerRadius: markSize * 0.28, style: .continuous)
                    .fill(Color(hex: "071E36"))
                    .frame(width: markSize, height: markSize)
            }

            // High-Resolution Master Icon
            Image("MaskIDMark")
                .resizable()
                .scaledToFill()
                .frame(width: markSize, height: markSize)
                // Feathered radial mask to blend edges smoothly into the view
                .mask {
                    if isCircular {
                        RadialGradient(
                            stops: [
                                .init(color: .white, location: 0.0),
                                .init(color: .white, location: 0.74),
                                .init(color: .white.opacity(0.85), location: 0.86),
                                .init(color: .white.opacity(0.35), location: 0.94),
                                .init(color: .clear, location: 1.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: markSize * 0.50
                        )
                    } else {
                        RoundedRectangle(cornerRadius: markSize * 0.28, style: .continuous)
                    }
                }

            // Active Laser Scan Sheen Wave
            if (presentation == .animatedOnce || presentation == .animatedLoop) && !reduceMotion {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        // Soft vertical beam blur
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(hex: "00E5FF").opacity(0.12),
                                Color(hex: "00E5FF").opacity(0.42),
                                Color.white.opacity(0.90),
                                Color(hex: "00E5FF").opacity(0.42),
                                Color(hex: "00E5FF").opacity(0.12),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: max(14, geo.size.height * 0.18))
                        .overlay {
                            // Bright horizontal laser line
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.clear,
                                            Color(hex: "00E5FF").opacity(0.7),
                                            Color.white,
                                            Color(hex: "00E5FF").opacity(0.7),
                                            Color.clear
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 1.8)
                        }
                    }
                    .offset(y: (geo.size.height + 20) * scanPhase - 10)
                }
            }
        }
        .frame(width: markSize, height: markSize)
        .compositingGroup()
        .clipShape(isCircular ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: markSize * 0.28, style: .continuous)))
        .overlay {
            // Soft Radial-Fading Neon Rim Lighting
            if isCircular {
                Circle()
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.55), location: 0.0),
                                .init(color: ShieldTheme.accent(scheme).opacity(0.75), location: 0.40),
                                .init(color: Color(hex: "00B4D8").opacity(0.20), location: 0.75),
                                .init(color: Color.clear, location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: borderWidth
                    )
            }
        }
        .shadow(
            color: ShieldTheme.accent(scheme).opacity(shadowOpacity),
            radius: shadowRadius,
            y: shadowRadius * 0.2
        )
        .shadow(
            color: Color.black.opacity(scheme == .dark ? 0.65 : 0.15),
            radius: shadowRadius * 0.8,
            y: shadowRadius * 0.4
        )
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        if showsHalo {
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.06
            }
        }

        if presentation == .animatedLoop {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                scanPhase = 1
            }
        } else if presentation == .animatedOnce {
            withAnimation(.easeInOut(duration: 1.25)) {
                scanPhase = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                onAnimationFinished?(true)
            }
        }
    }

    private var showsHalo: Bool {
        treatment == .splash || treatment == .hero || treatment == .feature
    }

    private var usesEntranceMotion: Bool {
        treatment == .hero || treatment == .feature
    }

    private var staticMarkSize: CGFloat {
        switch treatment {
        case .splash:
            min(160, size * 0.52)
        case .hero:
            size * 0.68
        case .feature:
            size * 0.76
        case .card, .compact:
            size
        }
    }

    private var borderWidth: CGFloat {
        treatment == .compact ? 0.8 : 1.2
    }

    private var shadowOpacity: Double {
        switch treatment {
        case .splash, .hero, .feature:
            0.40
        case .card:
            0.18
        case .compact:
            0.10
        }
    }

    private var shadowRadius: CGFloat {
        switch treatment {
        case .splash, .hero, .feature:
            18
        case .card:
            6
        case .compact:
            2
        }
    }
}

// MARK: - SplashView

/// The animated handoff between the static iOS launch screen and the app shell.
struct SplashView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didFinish = false

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            // Atmospheric deep radial background for seamless launch
            RadialGradient(
                colors: [
                    Color(hex: "061E33"),
                    Color(hex: "030E1A"),
                    Color(hex: "01050A")
                ],
                center: .center,
                startRadius: 20,
                endRadius: 420
            )
            .ignoresSafeArea()

            GeometryReader { proxy in
                let availableSize = min(proxy.size.width, proxy.size.height) - 48
                let markSize = max(140, min(availableSize, 380))

                MaskIDIdentityMark(
                    size: markSize,
                    presentation: .animatedOnce,
                    treatment: .splash
                ) { completed in
                    guard completed else { return }
                    finish()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityHidden(true)
        .task {
            let delay = reduceMotion ? 500_000_000 : 1_800_000_000
            try? await Task.sleep(nanoseconds: UInt64(delay))
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinished()
    }
}

#Preview {
    SplashView(onFinished: {})
}
