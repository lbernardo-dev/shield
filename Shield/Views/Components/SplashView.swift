import SwiftUI

/// A short, static launch cover. Animations belong in product flows, not over the app shell.
struct SplashView: View {
    var body: some View {
        ZStack {
            ShieldTheme.surface0
                .ignoresSafeArea()

            Image("MaskIDMark")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 30))
                .overlay {
                    RoundedRectangle(cornerRadius: 30)
                        .stroke(ShieldTheme.accent.opacity(0.28), lineWidth: 1)
                }
                .accessibilityHidden(true)
        }
        .accessibilityHidden(true)
    }
}
