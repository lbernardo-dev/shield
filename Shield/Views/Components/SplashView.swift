import SwiftUI

struct SplashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulseScale: CGFloat = 0.96
    @State private var scanlineOffset: CGFloat = -100
    @State private var ringScale1: CGFloat = 0.6
    @State private var ringOpacity1: Double = 0.0
    @State private var ringScale2: CGFloat = 0.6
    @State private var ringOpacity2: Double = 0.0
    @State private var ringScale3: CGFloat = 0.6
    @State private var ringOpacity3: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    
    // Animated glowing background dots
    @State private var dotPositions: [CGPoint] = (0..<15).map { _ in
        CGPoint(x: CGFloat.random(in: 0.05...0.95), y: CGFloat.random(in: 0.05...0.95))
    }
    @State private var dotOpacities: [Double] = Array(repeating: 0.0, count: 15)

    var body: some View {
        ZStack {
            // Dark mysterious background
            Color.black
                .ignoresSafeArea()
            
            // Cyber/digital privacy theme backdrop
            GeometryReader { geo in
                ZStack {
                    // Slow pulsing deep radial gradient
                    RadialGradient(
                        colors: [
                            ShieldTheme.accent.opacity(0.12),
                            ShieldTheme.surface0.opacity(0.85),
                            Color.black
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: max(geo.size.width, geo.size.height) * 0.7
                    )
                    .ignoresSafeArea()
                    
                    // Subtle glowing pixel blocks in the background
                    if !reduceMotion {
                        ForEach(0..<dotPositions.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(ShieldTheme.accent.opacity(0.05))
                                .frame(width: CGFloat.random(in: 12...24), height: CGFloat.random(in: 12...24))
                                .position(
                                    x: dotPositions[index].x * geo.size.width,
                                    y: dotPositions[index].y * geo.size.height
                                )
                                .opacity(dotOpacities[index])
                        }
                    }
                }
                .opacity(backgroundOpacity)
            }
            .ignoresSafeArea()

            // Concentric radiating cyber-rings
            if !reduceMotion {
                ZStack {
                    Circle()
                        .stroke(ShieldTheme.accent.opacity(ringOpacity1), lineWidth: 1.5)
                        .scaleEffect(ringScale1)
                    
                    Circle()
                        .stroke(ShieldTheme.accent.opacity(ringOpacity2), lineWidth: 1.0)
                        .scaleEffect(ringScale2)
                    
                    Circle()
                        .stroke(ShieldTheme.accent.opacity(ringOpacity3), lineWidth: 0.6)
                        .scaleEffect(ringScale3)
                }
                .frame(width: 280, height: 280)
            }

            // Central Icon (MaskIDMark)
            VStack {
                ZStack {
                    // Pulsing glow behind the icon
                    RoundedRectangle(cornerRadius: 44)
                        .fill(ShieldTheme.accent.opacity(0.14))
                        .frame(width: 176, height: 176)
                        .blur(radius: 24)
                        .scaleEffect(pulseScale)
                    
                    // Main Logo Asset
                    Image("MaskIDMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                        .overlay(
                            RoundedRectangle(cornerRadius: 40)
                                .stroke(ShieldTheme.accent.opacity(0.35), lineWidth: 1.5)
                        )
                        .scaleEffect(pulseScale)
                        .shadow(color: ShieldTheme.accent.opacity(0.4), radius: 18, x: 0, y: 0)

                    // Cyber horizontal scanline/mask beam sweeping vertically
                    if !reduceMotion {
                        GeometryReader { geo in
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.clear, ShieldTheme.accent.opacity(0.85), Color.clear],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 5)
                                .shadow(color: ShieldTheme.accent, radius: 4, x: 0, y: 0)
                                .offset(y: scanlineOffset)
                                .mask(
                                    RoundedRectangle(cornerRadius: 40)
                                        .frame(width: 160, height: 160)
                                )
                        }
                        .frame(width: 160, height: 160)
                    }
                }
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Fade in background elements
        withAnimation(.easeIn(duration: 0.6)) {
            backgroundOpacity = 1.0
        }
        
        if reduceMotion {
            // Simpler static breathing animation
            withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                pulseScale = 1.02
            }
            return
        }

        // 1. Icon breath pulse
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.04
        }

        // 2. Scanline sweep animation
        scanlineOffset = -80
        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
            scanlineOffset = 80
        }

        // 3. Staggered radiating rings animations
        animateRing1()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            animateRing2()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            animateRing3()
        }

        // 4. Subtle background dots twinkle animation
        for index in 0..<dotOpacities.count {
            let delay = Double.random(in: 0...2.0)
            let duration = Double.random(in: 1.5...3.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    dotOpacities[index] = Double.random(in: 0.15...0.6)
                }
            }
        }
    }
    
    private func animateRing1() {
        ringScale1 = 0.6
        ringOpacity1 = 0.55
        withAnimation(.easeOut(duration: 2.7)) {
            ringScale1 = 2.4
            ringOpacity1 = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            animateRing1()
        }
    }
    
    private func animateRing2() {
        ringScale2 = 0.6
        ringOpacity2 = 0.55
        withAnimation(.easeOut(duration: 2.7)) {
            ringScale2 = 2.4
            ringOpacity2 = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            animateRing2()
        }
    }
    
    private func animateRing3() {
        ringScale3 = 0.6
        ringOpacity3 = 0.55
        withAnimation(.easeOut(duration: 2.7)) {
            ringScale3 = 2.4
            ringOpacity3 = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) {
            animateRing3()
        }
    }
}
