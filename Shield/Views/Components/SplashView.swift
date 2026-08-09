import SwiftUI
import Lottie

/// Shared MaskID identity treatment for hero, feature and compact surfaces.
struct MaskIDIdentityMark: View {
    enum Presentation {
        case animatedOnce
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

    let size: CGFloat
    var presentation: Presentation = .animatedOnce
    var treatment: Treatment = .hero
    var isEmphasized = false
    var onAnimationFinished: ((Bool) -> Void)?

    var body: some View {
        ZStack {
            if showsHalo {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                ShieldTheme.accent.opacity(scheme == .dark ? 0.18 : 0.12),
                                ShieldTheme.accent.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: size * 0.5
                        )
                    )

                Circle()
                    .stroke(ShieldTheme.accent.opacity(0.14), lineWidth: 1)
                    .padding(size * 0.07)

                Circle()
                    .stroke(ShieldTheme.accent.opacity(0.24), lineWidth: 1)
                    .padding(size * 0.17)
            }

            mark
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
        .onAppear { hasAppeared = true }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var mark: some View {
        if presentation == .animatedOnce && !reduceMotion {
            LottieView(animation: .named("MaskID_IdentityMask_v3"))
                .configure { animationView in
                    animationView.shouldRasterizeWhenIdle = true
                }
                .playing()
                .animationDidFinish { completed in
                    onAnimationFinished?(completed)
                }
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            staticMark
        }
    }

    private var staticMark: some View {
        let markSize = staticMarkSize
        let radius = markSize * cornerRadiusRatio

        return Image("MaskIDMark")
            .resizable()
            .scaledToFill()
            .frame(width: markSize, height: markSize)
            .compositingGroup()
            .clipShape(.rect(cornerRadius: radius))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(ShieldTheme.accentStroke(scheme), lineWidth: borderWidth)
            }
            .shadow(
                color: ShieldTheme.accent.opacity(shadowOpacity),
                radius: shadowRadius,
                y: shadowRadius * 0.2
            )
    }

    private var showsHalo: Bool {
        treatment == .hero || treatment == .feature
    }

    private var usesEntranceMotion: Bool {
        treatment == .hero || treatment == .feature
    }

    private var staticMarkSize: CGFloat {
        switch treatment {
        case .splash:
            min(120, size * 0.38)
        case .hero:
            size * 0.625
        case .feature:
            size * 0.74
        case .card, .compact:
            size
        }
    }

    private var cornerRadiusRatio: CGFloat {
        treatment == .compact ? 0.3 : 0.24
    }

    private var borderWidth: CGFloat {
        treatment == .compact ? 0.75 : 1
    }

    private var shadowOpacity: Double {
        switch treatment {
        case .splash, .hero, .feature:
            0.3
        case .card:
            0.16
        case .compact:
            0.1
        }
    }

    private var shadowRadius: CGFloat {
        switch treatment {
        case .splash, .hero, .feature:
            10
        case .card:
            5
        case .compact:
            2
        }
    }
}

/// The animated handoff between the static iOS launch screen and the app shell.
struct SplashView: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var didFinish = false

    let onFinished: () -> Void

    var body: some View {
        ZStack {
            ShieldTheme.pageBackground(scheme)
                .ignoresSafeArea()

            GeometryReader { proxy in
                let availableSize = min(proxy.size.width, proxy.size.height) - 48
                let markSize = max(120, min(availableSize, 380))

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
            let delay = reduceMotion ? 650_000_000 : 3_000_000_000
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
