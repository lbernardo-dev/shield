import SwiftUI
import StoreKit

// MARK: - PaywallView

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openURL) private var openURL
    @StateObject private var pm = PremiumManager.shared
    @Binding var isPresented: Bool
    var trigger: PaywallTrigger = .manual
    @State private var selectedProduct: ShieldProduct = .annual
    @State private var didStartCheckout = false
    private let privacyURL = URL(string: "https://shieldapp.io/privacy")
    private let termsURL = URL(string: "https://shieldapp.io/terms")

    private func features(lang: AppLanguage) -> [(icon: String, color: String, title: String, subtitle: String)] {
        let es = lang == .es
        return [
            ("doc.stack.fill",       "64D2FF",
             es ? "Documentos ilimitados"   : "Unlimited documents",
             es ? "Sin límite de 3 docs"    : "No 3-doc limit"),
            ("eye.slash.fill",       "FFD60A",
             es ? "9 estilos de redacción"  : "9 redaction styles",
             es ? "Pixelado, blur, diagonal…" : "Pixelate, blur, diagonal…"),
            ("lock.rectangle.stack", "30D158",
             es ? "Bóveda cifrada"          : "Encrypted vault",
             "Face ID + AES-256"),
            ("doc.fill",             "FF9F0A",
             es ? "Export PDF real"         : "Real PDF export",
             es ? "PDFKit + aplanar"        : "PDFKit + flatten"),
            ("drop.halffull",        "5E5CE6",
             es ? "Marca de agua custom"    : "Custom watermark",
             es ? "Texto, posición, opacidad" : "Text, position, opacity"),
            ("slider.horizontal.3",  "FF453A",
             es ? "Ajustes de imagen"       : "Image adjustments",
             es ? "Brillo, contraste, recorte" : "Brightness, contrast, crop"),
            ("wand.and.stars",       "BF5AF2",
             es ? "Auto-redacción IA"       : "AI auto-redaction",
             es ? "Detección de campos OCR" : "OCR field detection"),
            ("icloud",               "30D158",
             es ? "Sincronización iCloud"   : "iCloud sync",
             es ? "Accede en todos tus dispositivos" : "Access across all your devices"),
        ]
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0D0D10"), Color(hex: "0A0A0B")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close
                HStack {
                    Spacer()
                    Button { isPresented = false } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ShieldTheme.textTertiary)
                            .frame(width: 30, height: 30)
                            .background(ShieldTheme.surface3)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Hero
                        heroSection

                        // Context banner
                        contextBanner

                        // Features grid
                        featuresGrid

                        // Plan selector
                        planSelector

                        // CTA
                        ctaSection

                        // Footer
                        footerLinks
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .preferredColorScheme(.dark)
        .task {
            AppState.trackEvent("paywall_viewed", properties: ["trigger": trigger.rawValue])
            await pm.loadProducts()
        }
        .onDisappear {
            if !pm.isPro {
                AppState.trackEvent("paywall_dismissed", properties: [
                    "trigger": trigger.rawValue,
                    "started_checkout": didStartCheckout ? "true" : "false"
                ])
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(ShieldTheme.accentDim)
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(ShieldTheme.accent)
            }
            Text("Shield Pro")
                .font(.system(size: 30, weight: .heavy))
                .foregroundColor(ShieldTheme.textPrimary)
                .tracking(-0.6)
            Text(appState.language == .es
                 ? "Protege sin límites. Comparte con confianza."
                 : "Protect without limits. Share with confidence.")
                .font(.system(size: 15))
                .foregroundColor(ShieldTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private var contextBanner: some View {
        let msgES: String
        let msgEN: String

        switch trigger {
        case .docLimitReached:
            msgES = "Has alcanzado el límite gratuito de documentos."
            msgEN = "You reached the free document limit."
        case .exportLimitReached:
            msgES = "Has agotado tus exportaciones semanales en Free."
            msgEN = "You used all weekly exports on Free."
        case .styleLocked:
            msgES = "Ese estilo de redacción está incluido en Pro."
            msgEN = "That redaction style is included in Pro."
        case .vaultUpgrade:
            msgES = "La bóveda cifrada está disponible con Shield Pro."
            msgEN = "Encrypted vault is available with Shield Pro."
        case .settingsUpgrade:
            msgES = "Desbloquea todas las funciones avanzadas."
            msgEN = "Unlock all advanced features."
        case .manual:
            msgES = "Elige un plan para protección profesional."
            msgEN = "Choose a plan for professional-grade protection."
        }

        return HStack(spacing: 8) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(ShieldTheme.accent)
            Text(appState.language == .es ? msgES : msgEN)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ShieldTheme.textSecondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(ShieldTheme.accentDim)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ShieldTheme.accent.opacity(0.35), lineWidth: 0.8))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Features

    private var featuresGrid: some View {
        VStack(spacing: 10) {
            ForEach(Array(features(lang: appState.language).enumerated()), id: \.offset) { _, f in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: f.color).opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: f.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: f.color))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(f.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ShieldTheme.textPrimary)
                        Text(f.subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(ShieldTheme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShieldTheme.success)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(ShieldTheme.surface2)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(ShieldTheme.surfaceLine, lineWidth: 0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Plan selector

    private var planSelector: some View {
        VStack(spacing: 10) {
            if pm.products.isEmpty {
                // Loading skeleton
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 14)
                        .fill(ShieldTheme.surface2)
                        .frame(height: 72)
                        .opacity(0.5)
                }
            } else {
                ForEach(pm.products, id: \.id) { product in
                    PlanRow(
                        product: product,
                        isSelected: selectedProduct.rawValue == product.id,
                        savingsLabel: savingsLabel(for: product),
                        onTap: {
                            if let sp = ShieldProduct(rawValue: product.id) {
                                withAnimation { selectedProduct = sp }
                            }
                        }
                    )
                }
            }
        }
    }

    private func savingsLabel(for product: Product) -> String? {
        guard product.id == ShieldProduct.annual.rawValue,
              let monthly = pm.products.first(where: { $0.id == ShieldProduct.monthly.rawValue })
        else { return nil }
        return pm.annualSavings(monthly: monthly, annual: product, lang: appState.language)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    guard let product = pm.products.first(where: { $0.id == selectedProduct.rawValue })
                    else { return }
                    didStartCheckout = true
                    await pm.purchase(product)
                    if pm.isPro { isPresented = false }
                }
            } label: {
                HStack(spacing: 8) {
                    if pm.isPurchasing {
                        ProgressView().tint(ShieldTheme.accentText)
                    } else {
                        Image(systemName: "crown.fill")
                        Text(appState.language == .es ? "Activar Shield Pro" : "Get Shield Pro")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(ShieldTheme.accent)
                .foregroundColor(ShieldTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(pm.isPurchasing)

            if let err = pm.purchaseError {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(ShieldTheme.danger)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Footer

    private var footerLinks: some View {
        HStack(spacing: 20) {
            Button {
                Task {
                    await pm.restore()
                    if pm.isPro { isPresented = false }
                }
            } label: {
                Group {
                    if pm.isRestoring {
                        ProgressView().tint(ShieldTheme.textTertiary).scaleEffect(0.7)
                    } else {
                        Text(appState.language == .es ? "Restaurar compra" : "Restore purchase")
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(ShieldTheme.textTertiary)
            }

            Text("·").foregroundColor(ShieldTheme.textQuaternary)

            Button {
                if let privacyURL { openURL(privacyURL) }
            } label: {
                Text(appState.language == .es ? "Privacidad" : "Privacy")
                    .font(.system(size: 12))
                    .foregroundColor(ShieldTheme.textTertiary)
            }

            Text("·").foregroundColor(ShieldTheme.textQuaternary)

            Button {
                if let termsURL { openURL(termsURL) }
            } label: {
                Text(appState.language == .es ? "Términos" : "Terms")
                    .font(.system(size: 12))
                    .foregroundColor(ShieldTheme.textTertiary)
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - PlanRow

private struct PlanRow: View {
    let product: Product
    let isSelected: Bool
    let savingsLabel: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Radio
                ZStack {
                    Circle()
                        .stroke(isSelected ? ShieldTheme.accent : ShieldTheme.surfaceLine, lineWidth: isSelected ? 2 : 1)
                        .frame(width: 20, height: 20)
                    if isSelected {
                        Circle()
                            .fill(ShieldTheme.accent)
                            .frame(width: 10, height: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(planName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(ShieldTheme.textPrimary)
                        if let s = savingsLabel {
                            Text(s)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(ShieldTheme.accentText)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(ShieldTheme.accent)
                                .clipShape(Capsule())
                        }
                    }
                    Text(planSubtitle)
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.textTertiary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 1) {
                    Text(product.displayPrice)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(ShieldTheme.textPrimary)
                    Text(periodLabel)
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.textTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(isSelected ? ShieldTheme.accentDim : ShieldTheme.surface2)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? ShieldTheme.accent : ShieldTheme.surfaceLine,
                            lineWidth: isSelected ? 1.5 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var planName: String {
        switch ShieldProduct(rawValue: product.id) {
        case .monthly:  return "Mensual"
        case .annual:   return "Anual"
        case .lifetime: return "De por vida"
        case nil:       return product.displayName
        }
    }

    private var planSubtitle: String {
        switch ShieldProduct(rawValue: product.id) {
        case .monthly:  return "Facturación mensual"
        case .annual:   return "Facturación anual"
        case .lifetime: return "Pago único"
        case nil:       return ""
        }
    }

    private var periodLabel: String {
        switch ShieldProduct(rawValue: product.id) {
        case .monthly:  return "/mes"
        case .annual:   return "/año"
        case .lifetime: return "una vez"
        case nil:       return ""
        }
    }
}
