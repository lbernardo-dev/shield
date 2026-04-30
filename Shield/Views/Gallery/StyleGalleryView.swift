import SwiftUI

// MARK: - StyleGalleryView

struct StyleGalleryView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @Environment(\.colorScheme) var scheme
    @State private var selectedKind: DocumentKind = .dniESP
    @State private var showPaywall = false
    @State private var paywallTrigger: PaywallTrigger = .manual
    @State private var styleToApply: MaskStyle? = nil
    @State private var contentWidth: CGFloat = 0

    private func sampleRedaction(style: MaskStyle) -> [Redaction] {
        [Redaction(rect: CGRect(x: 0.30, y: 0.75, width: 0.25, height: 0.10), style: style)]
    }

    var body: some View {
        ZStack {
            ShieldTheme.pageBackground(scheme).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                docTypePicker

                ScrollView(showsIndicators: false) {
                    GeometryReader { geo in Color.clear.preference(key: WidthKey.self, value: geo.size.width) }
                        .frame(height: 0)

                    LazyVStack(alignment: .leading, spacing: 24, pinnedViews: []) {
                        styleSection(
                            title: appState.language == .es ? "Esenciales" : "Essentials",
                            subtitle: appState.language == .es ? "Compatibles con todos los documentos" : "Compatible with all document types",
                            styles: [.block, .blockWhite]
                        )
                        styleSection(
                            title: appState.language == .es ? "Difuminados" : "Blur",
                            subtitle: appState.language == .es ? "Ocultación suave y natural" : "Soft and natural concealment",
                            styles: [.blurStrong, .blurSoft, .pixelate]
                        )
                        styleSection(
                            title: appState.language == .es ? "Patrones" : "Patterns",
                            subtitle: appState.language == .es ? "Mayor visibilidad de redacción" : "High-visibility redaction marks",
                            styles: [.diagonal, .secure, .redactedTag]
                        )
                        styleSection(
                            title: appState.language == .es ? "Especiales" : "Special",
                            subtitle: appState.language == .es ? "Efectos únicos" : "Unique effects",
                            styles: [.semi]
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 100)
                }
                .onPreferenceChange(WidthKey.self) { width in
                    contentWidth = width
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: paywallTrigger)
                .environmentObject(appState)
        }
        .sheet(item: $styleToApply) { (style: MaskStyle) in
            StyleSourceSheet(
                style: style,
                kind: selectedKind,
                lang: appState.language,
                isPresented: Binding(
                    get: { styleToApply != nil },
                    set: { if !$0 { styleToApply = nil } }
                )
            ) {
                appState.pendingMaskStyle = style
                styleToApply = nil
                appState.showCapture = true
            }
            .environmentObject(appState)
        }
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(appState.language == .es ? "Galería de estilos" : "Style gallery")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .tracking(-0.5)
                Text(appState.language == .es
                     ? "Toca un estilo para aplicarlo a un documento"
                     : "Tap a style to apply it to a document")
                    .font(.system(size: 13))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var docTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                docPickerGroup(
                    label: appState.language == .es ? "Europa" : "Europe",
                    kinds: [.dniESP, .drivingUK, .dniITA]
                )
                pickerDivider
                docPickerGroup(
                    label: appState.language == .es ? "América" : "Americas",
                    kinds: [.passportUSA, .passportMEX]
                )
                pickerDivider
                docPickerGroup(
                    label: appState.language == .es ? "Genérico" : "Generic",
                    kinds: [.genericID]
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    @ViewBuilder
    private func docPickerGroup(label: String, kinds: [DocumentKind]) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(ShieldTheme.tertiary(scheme).opacity(0.7))
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.leading, 4)
            HStack(spacing: 6) {
                ForEach(kinds, id: \.self) { kind in
                    PillButton(label: kindLabel(kind), isActive: selectedKind == kind) {
                        withAnimation { selectedKind = kind }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private var pickerDivider: some View {
        Rectangle()
            .frame(width: 0.5, height: 36)
            .foregroundColor(ShieldTheme.line(scheme))
            .padding(.horizontal, 8)
            .padding(.top, 14)
    }

    @ViewBuilder
    private func styleSection(title: String, subtitle: String? = nil, styles: [MaskStyle]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                    .textCase(.uppercase)
                    .tracking(0.6)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.tertiary(scheme).opacity(0.7))
                }
            }
            .padding(.horizontal, 4)

            GeometryReader { geo in
                let cardWidth = (geo.size.width - 12) / 2
                let docSize = CGSize(width: cardWidth - 20, height: (cardWidth - 20) * 0.628)

                LazyVGrid(
                    columns: [GridItem(.fixed(cardWidth)), GridItem(.fixed(cardWidth))],
                    spacing: 12
                ) {
                    ForEach(styles) { style in
                        let unlocked = !style.isPremium || pm.isPro
                        StyleCard(
                            style: style,
                            kind: selectedKind,
                            docSize: docSize,
                            redaction: sampleRedaction(style: style),
                            isPremium: style.isPremium,
                            isUnlocked: unlocked,
                            lang: appState.language,
                            onTapLock: {
                                paywallTrigger = .styleLocked
                                showPaywall = true
                            },
                            onSelect: {
                                styleToApply = style
                            }
                        )
                    }
                }
            }
            .frame(height: sectionHeight(count: styles.count))
        }
    }

    private func sectionHeight(count: Int) -> CGFloat {
        let rows = CGFloat((count + 1) / 2)
        let gridWidth = max((contentWidth > 0 ? contentWidth : 375) - 32, 220)
        let cardW = (gridWidth - 12) / 2
        let docH = (cardW - 20) * 0.628
        let cardH = docH + 20 + 28
        return rows * cardH + (rows - 1) * 12
    }

    private func kindLabel(_ kind: DocumentKind) -> String {
        switch kind {
        case .dniESP:      return appState.language == .es ? "DNI España" : "Spanish ID"
        case .passportUSA: return appState.language == .es ? "Pasaporte USA" : "US Passport"
        case .drivingUK:   return appState.language == .es ? "Licencia UK" : "UK Licence"
        case .photo:       return appState.language == .es ? "Foto" : "Photo"
        case .passportMEX: return appState.language == .es ? "Pasaporte MX" : "MX Passport"
        case .dniITA:      return appState.language == .es ? "CI Italia" : "Italian ID"
        case .genericID:   return appState.language == .es ? "Genérico" : "Generic"
        }
    }
}

private struct WidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

// MARK: - StyleCard

private struct StyleCard: View {
    let style: MaskStyle
    let kind: DocumentKind
    let docSize: CGSize
    let redaction: [Redaction]
    let isPremium: Bool
    let isUnlocked: Bool
    let lang: AppLanguage
    let onTapLock: () -> Void
    let onSelect: () -> Void
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button {
            if isUnlocked { onSelect() } else { onTapLock() }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    DocumentView(kind: kind, size: docSize, redactions: redaction)
                        .saturation(isUnlocked ? 1 : 0.3)
                        .frame(width: docSize.width, height: docSize.height)
                        .clipped()

                    if !isUnlocked {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.55))
                        VStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 18))
                                .foregroundColor(ShieldTheme.accent)
                            Text("Pro")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(ShieldTheme.accent)
                        }
                    } else {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white.opacity(0.85))
                                    .shadow(radius: 3)
                                    .padding(5)
                            }
                            Spacer()
                        }
                    }
                }
                .frame(width: docSize.width, height: docSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                HStack(alignment: .center, spacing: 4) {
                    Text(style.label(lang: lang))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .lineLimit(1)
                    Spacer()
                    if isPremium && isUnlocked {
                        Text("Pro")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(ShieldTheme.accentText)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(ShieldTheme.accent)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(ShieldTheme.cardBackground(scheme))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(ShieldTheme.line(scheme), lineWidth: 0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - StyleSourceSheet

struct StyleSourceSheet: View {
    let style: MaskStyle
    let kind: DocumentKind
    let lang: AppLanguage
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    @Environment(\.colorScheme) var scheme

    private let previewDocSize = CGSize(width: 220, height: 138)

    private var previewRedaction: [Redaction] {
        [Redaction(rect: CGRect(x: 0.30, y: 0.75, width: 0.25, height: 0.10), style: style)]
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .frame(width: 36, height: 4)
                .foregroundColor(ShieldTheme.tertiary(scheme).opacity(0.5))
                .padding(.top, 10)

            HStack {
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .frame(width: 28, height: 28)
                        .background(ShieldTheme.rowBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)

            VStack(spacing: 4) {
                Text(lang == .es ? "ESTILO SELECCIONADO" : "SELECTED STYLE")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                    .tracking(0.6)
                Text(style.label(lang: lang))
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .tracking(-0.4)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 14)

            DocumentView(kind: kind, size: previewDocSize, redactions: previewRedaction)
                .frame(width: previewDocSize.width, height: previewDocSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(ShieldTheme.line(scheme), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                .padding(.top, 16)
                .padding(.bottom, 20)

            Text(lang == .es
                 ? "¿Desde dónde quieres cargar el documento?"
                 : "Where do you want to load the document from?")
                .font(.system(size: 14))
                .foregroundColor(ShieldTheme.secondary(scheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 20)

            Button(action: onConfirm) {
                HStack(spacing: 10) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 17, weight: .semibold))
                    Text(lang == .es ? "Escanear o importar documento" : "Scan or import document")
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(ShieldTheme.accent)
                .foregroundColor(ShieldTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 36)
        }
        .background(ShieldTheme.background(scheme).ignoresSafeArea())
        .colorScheme(scheme)
        .presentationDetents([.height(480)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(ShieldTheme.background(scheme))
    }
}
