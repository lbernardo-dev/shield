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
    @State private var selectedStyle: MaskStyle? = nil

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
                    LazyVStack(alignment: .leading, spacing: 24) {
                        styleSection(
                            title: LanguageManager.shared.gallery("gallery_group_essentials"),
                            subtitle: LanguageManager.shared.gallery("gallery_group_essentials_sub"),
                            styles: [.block, .blockWhite]
                        )
                        styleSection(
                            title: LanguageManager.shared.gallery("gallery_group_blur"),
                            subtitle: LanguageManager.shared.gallery("gallery_group_blur_sub"),
                            styles: [.blurStrong, .blurSoft, .pixelate]
                        )
                        styleSection(
                            title: LanguageManager.shared.gallery("gallery_group_patterns"),
                            subtitle: LanguageManager.shared.gallery("gallery_group_patterns_sub"),
                            styles: [.diagonal, .secure, .redactedTag]
                        )
                        styleSection(
                            title: LanguageManager.shared.gallery("gallery_group_special"),
                            subtitle: LanguageManager.shared.gallery("gallery_group_special_sub"),
                            styles: [.semi]
                        )
                    }
                    .frame(maxWidth: 1_100)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
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
                Text(LanguageManager.shared.gallery("gallery_title"))
                    .shieldFont(28, weight: .heavy)
                    .foregroundColor(ShieldTheme.primary(scheme))
                Text(LanguageManager.shared.gallery("gallery_subtitle"))
                    .shieldFont(13)
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        // GeometryReader already lays this view out below the top safe area.
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var docTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                docPickerGroup(
                    label: LanguageManager.shared.gallery("gallery_region_europe"),
                    kinds: [.dniESP, .drivingUK, .dniITA]
                )
                pickerDivider
                docPickerGroup(
                    label: LanguageManager.shared.gallery("gallery_region_americas"),
                    kinds: [.passportUSA, .passportMEX]
                )
                pickerDivider
                docPickerGroup(
                    label: LanguageManager.shared.gallery("gallery_region_generic"),
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
                .shieldFont(9, weight: .bold)
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
                    .shieldFont(13, weight: .bold)
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                    .textCase(.uppercase)
                    .tracking(0.6)
                if let subtitle {
                    Text(subtitle)
                        .shieldFont(11)
                        .foregroundColor(ShieldTheme.tertiary(scheme).opacity(0.7))
                }
            }
            .padding(.horizontal, 4)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 138, maximum: 260), spacing: 12)],
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(styles) { style in
                    let unlocked = !style.isPremium || pm.isPro
                    StyleCard(
                        style: style,
                        kind: selectedKind,
                        redaction: sampleRedaction(style: style),
                        isPremium: style.isPremium,
                        isUnlocked: unlocked,
                        isSelected: selectedStyle == style,
                        lang: appState.language,
                        onTapLock: {
                            paywallTrigger = .styleLocked
                            showPaywall = true
                        },
                        onSelect: {
                            withAnimation(ShieldMotion.state) {
                                selectedStyle = style
                                styleToApply = style
                            }
                        }
                    )
                }
            }
        }
    }

    private func kindLabel(_ kind: DocumentKind) -> String {
        switch kind {
        case .dniESP:      return LanguageManager.shared.gallery("gallery_doc_dni_esp")
        case .passportUSA: return LanguageManager.shared.gallery("gallery_doc_passport_usa")
        case .drivingUK:   return LanguageManager.shared.gallery("gallery_doc_driving_uk")
        case .photo:       return LanguageManager.shared.gallery("gallery_doc_photo")
        case .passportMEX: return LanguageManager.shared.gallery("gallery_doc_passport_mex")
        case .dniITA:      return LanguageManager.shared.gallery("gallery_doc_dni_ita")
        case .genericID:   return LanguageManager.shared.gallery("gallery_doc_generic_id")
        }
    }
}

// MARK: - StyleCard

private struct StyleCard: View {
    let style: MaskStyle
    let kind: DocumentKind
    let redaction: [Redaction]
    let isPremium: Bool
    let isUnlocked: Bool
    let isSelected: Bool
    let lang: AppLanguage
    let onTapLock: () -> Void
    let onSelect: () -> Void
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    var body: some View {
        Button {
            if isUnlocked { onSelect() } else { onTapLock() }
        } label: {
            VStack(spacing: 8) {
                ViewThatFits(in: .horizontal) {
                    stylePreview(size: CGSize(width: 220, height: 138))
                    stylePreview(size: CGSize(width: 180, height: 113))
                    stylePreview(size: CGSize(width: 140, height: 88))
                    stylePreview(size: CGSize(width: 116, height: 73))
                }

                HStack(alignment: .center, spacing: 4) {
                    Text(style.label(lang: lang))
                        .shieldFont(12, weight: .semibold)
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .lineLimit(1)
                    Spacer()
                    if isPremium && isUnlocked {
                        Text(LanguageManager.shared.common("common_pro"))
                            .shieldFont(9, weight: .bold)
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
            .background(isSelected ? ShieldTheme.selectedBackground(scheme) : ShieldTheme.cardBackground(scheme))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? ShieldTheme.accent : ShieldTheme.line(scheme),
                        lineWidth: isSelected ? 2 : 0.5
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("gallery.style.\(style.rawValue)")
        .accessibilityValue(isUnlocked
            ? (isSelected ? LanguageManager.shared.common("common_selected") : "")
            : LanguageManager.shared.common("common_pro"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func stylePreview(size: CGSize) -> some View {
        ZStack {
            DocumentView(kind: kind, size: size, redactions: redaction)
                .saturation(isUnlocked ? 1 : 0.7)
                .frame(width: size.width, height: size.height)
                .clipped()

            if !isUnlocked {
                Label(LanguageManager.shared.common("common_pro"), systemImage: "lock.fill")
                    .shieldFont(10, weight: .bold)
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(6)
            } else {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "arrow.right.circle.fill")
                    .shieldFont(16)
                    .foregroundColor(isSelected ? ShieldTheme.accent : .white.opacity(0.85))
                    .shadow(radius: 3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(5)
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(.rect(cornerRadius: 6))
    }
}

// MARK: - StyleSourceSheet

struct StyleSourceSheet: View {
    @EnvironmentObject var appState: AppState
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
            HStack {
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .shieldFont(13, weight: .medium)
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .frame(width: 44, height: 44)
                        .background(ShieldTheme.rowBackground(scheme))
                        .clipShape(Circle())
                }
                .accessibilityLabel(LanguageManager.shared.common("common_close"))
                .accessibilityIdentifier("gallery.styleSource.close")
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
            .background(ShieldTheme.background(scheme))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 4) {
                        Text(LanguageManager.shared.gallery("gallery_selected_style_header"))
                            .shieldFont(11, weight: .semibold)
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                            .tracking(0.6)
                        Text(style.label(lang: lang))
                            .shieldFont(24, weight: .heavy)
                            .foregroundColor(ShieldTheme.primary(scheme))
                    }
                    .frame(maxWidth: .infinity)

                    DocumentView(kind: kind, size: previewDocSize, redactions: previewRedaction)
                        .frame(width: previewDocSize.width, height: previewDocSize.height)
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(ShieldTheme.line(scheme), lineWidth: 0.5)
                        }
                        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
                        .padding(.vertical, 16)

                    Text(LanguageManager.shared.gallery("gallery_load_source_title"))
                        .shieldFont(14)
                        .foregroundColor(ShieldTheme.secondary(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button(action: onConfirm) {
                Label(
                    LanguageManager.shared.gallery("gallery_load_source_button"),
                    systemImage: "camera.viewfinder"
                )
                .shieldFont(15, weight: .bold)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(ShieldTheme.accent)
                .foregroundColor(ShieldTheme.accentText)
                .clipShape(.rect(cornerRadius: 14))
            }
            .accessibilityIdentifier("gallery.styleSource.continue")
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(ShieldTheme.background(scheme))
        }
        .background(ShieldTheme.background(scheme).ignoresSafeArea())
        .colorScheme(scheme)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(ShieldTheme.background(scheme))
    }
}
