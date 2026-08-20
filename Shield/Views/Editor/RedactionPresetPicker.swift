import SwiftUI

// MARK: - RedactionPresetPickerSheet

struct RedactionPresetPickerSheet: View {
    let lang: AppLanguage
    let onSelect: (RedactionPreset) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .frame(width: 36, height: 4)
                .foregroundColor(ShieldTheme.textTertiary.opacity(0.5))
                .padding(.top, 10)

            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lang == .es ? "Plantillas de Trámite" : "Smart Procedure Presets")
                        .shieldFont(18, weight: .bold)
                        .foregroundColor(ShieldTheme.textPrimary)

                    Text(lang == .es ? "Aplica censura y marca de agua con 1 toque" : "1-tap masking and watermark protection")
                        .shieldFont(13, weight: .regular)
                        .foregroundColor(ShieldTheme.textSecondary)
                }

                Spacer()

                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .shieldFont(13, weight: .semibold)
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(ShieldTheme.surface3)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(RedactionPreset.allCases) { preset in
                        Button {
                            onSelect(preset)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: preset.iconColorHex).opacity(0.15))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: preset.icon)
                                        .shieldFont(18, weight: .semibold)
                                        .foregroundColor(Color(hex: preset.iconColorHex))
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(preset.title(lang: lang))
                                        .shieldFont(15, weight: .semibold)
                                        .foregroundColor(ShieldTheme.textPrimary)

                                    Text(preset.subtitle(lang: lang))
                                        .shieldFont(12, weight: .regular)
                                        .foregroundColor(ShieldTheme.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .shieldFont(12, weight: .semibold)
                                    .foregroundColor(ShieldTheme.textTertiary)
                            }
                            .padding(14)
                            .background(ShieldTheme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(ShieldTheme.surfaceLine, lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .background(ShieldTheme.surface1.ignoresSafeArea())
        .presentationDetents([.medium, .large])
    }
}
