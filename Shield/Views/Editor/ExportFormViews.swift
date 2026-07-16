import SwiftUI

struct ExportSheetHeader: View {
    let scheme: ColorScheme
    let title: String
    let onClose: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ShieldTheme.primary(scheme))
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                    .frame(width: 30, height: 30)
                    .background(ShieldTheme.rowBackground(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }
}

struct ExportPreviewCard: View {
    let scheme: ColorScheme
    let doc: DocumentItem
    let redactions: [Redaction]
    let watermark: Watermark?
    let currentImageFileName: String?

    var body: some View {
        HStack {
            Spacer()
            DocumentView(
                kind: doc.kind,
                size: CGSize(width: 220, height: 138),
                fields: doc.fields,
                redactions: redactions,
                watermark: watermark,
                imageFileName: currentImageFileName,
                isVaulted: doc.isVaulted
            )
            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
            Spacer()
        }
        .padding(12)
        .background(ShieldTheme.rowBackground(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(LanguageManager.shared.editor("editor_export_preview_accessibility"))
        .accessibilityAddTraits(.isImage)
    }
}

struct ExportFormatPicker: View {
    let scheme: ColorScheme
    let title: String
    let selectedFormat: ExportSheetView.ExportFormat
    let labels: [ExportSheetView.ExportFormat: String]
    let onSelect: (ExportSheetView.ExportFormat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExportSectionLabel(text: title, scheme: scheme)
            HStack(spacing: 8) {
                ForEach([ExportSheetView.ExportFormat.pdf, .image], id: \.self) { format in
                    Button {
                        onSelect(format)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: format == .pdf ? "doc.fill" : "photo.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedFormat == format ? ShieldTheme.accent(scheme) : ShieldTheme.primary(scheme))
                            Text(labels[format] ?? "")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ShieldTheme.primary(scheme))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedFormat == format ? ShieldTheme.accentDim(scheme) : ShieldTheme.rowBackground(scheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedFormat == format ? ShieldTheme.accentStroke(scheme) : ShieldTheme.line(scheme),
                                    lineWidth: selectedFormat == format ? 1 : 0.5
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel(labels[format] ?? "")
                    .accessibilityValue(
                        selectedFormat == format
                            ? LanguageManager.shared.common("common_selected")
                            : LanguageManager.shared.common("common_not_selected")
                    )
                    .accessibilityAddTraits(selectedFormat == format ? .isSelected : [])
                }
            }
        }
    }
}

struct ExportQualityPicker: View {
    let scheme: ColorScheme
    let title: String
    let selectedQuality: ExportSheetView.ExportQuality
    let labels: [ExportSheetView.ExportQuality: String]
    let onSelect: (ExportSheetView.ExportQuality) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ExportSectionLabel(text: title, scheme: scheme)
            HStack(spacing: 6) {
                ForEach(ExportSheetView.ExportQuality.allCases, id: \.self) { quality in
                    Button {
                        onSelect(quality)
                    } label: {
                        Text(labels[quality] ?? "")
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(selectedQuality == quality ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme))
                            .foregroundColor(selectedQuality == quality ? ShieldTheme.accentText : ShieldTheme.primary(scheme))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityLabel(labels[quality] ?? "")
                    .accessibilityValue(
                        selectedQuality == quality
                            ? LanguageManager.shared.common("common_selected")
                            : LanguageManager.shared.common("common_not_selected")
                    )
                    .accessibilityAddTraits(selectedQuality == quality ? .isSelected : [])
                }
            }
        }
    }
}

struct ExportRiskAcknowledgementCard: View {
    let scheme: ColorScheme
    let warningText: String
    let acknowledgeText: String
    let isAcknowledged: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(warningText)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(ShieldTheme.warning)

            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Image(systemName: isAcknowledged ? "checkmark.square.fill" : "square")
                        .foregroundColor(isAcknowledged ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
                    Text(acknowledgeText)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ShieldTheme.secondary(scheme))
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(10)
        .background(ShieldTheme.rowBackground(scheme))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct ExportSheetFooterButton: View {
    let isExporting: Bool
    let buttonTitle: String
    let onTap: () -> Void
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(spacing: 0) {
            ShieldDivider()
            Button(action: onTap) {
                HStack(spacing: 8) {
                    if isExporting {
                        ProgressView().tint(ShieldTheme.accentText).scaleEffect(0.8)
                        Text(LanguageManager.shared.editor("editor_exporting"))
                            .font(.system(size: 15, weight: .bold))
                    } else {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                        Text(buttonTitle)
                            .font(.system(size: 15, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(ShieldTheme.accent(scheme))
                .foregroundColor(ShieldTheme.accentText)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isExporting)
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.top, 12)
            .padding(.bottom, 32)
        }
    }
}

struct ExportCompletionView: View {
    let scheme: ColorScheme
    let isPro: Bool
    let summaryText: String
    let showFreeWatermarkNote: Bool
    let onDone: () -> Void
    let onShare: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(ShieldTheme.successDim)
                    .frame(width: 84, height: 84)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(ShieldTheme.success)
            }
            VStack(spacing: 4) {
                Text(LanguageManager.shared.editor("editor_exported"))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ShieldTheme.primary(scheme))
                Text(summaryText)
                    .font(.system(size: 13))
                    .foregroundColor(ShieldTheme.secondary(scheme))
                if showFreeWatermarkNote && !isPro {
                    Text(LanguageManager.shared.editor("editor_include_wm_free"))
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                }
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: onDone) {
                    Text(LanguageManager.shared.common("common_done"))
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(ShieldTheme.rowBackground(scheme))
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())

                Button(action: onShare) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text(LanguageManager.shared.common("common_share"))
                    }
                    .font(.system(size: 14, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(ShieldTheme.accent)
                    .foregroundColor(ShieldTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.bottom, 32)
        }
    }
}

struct ExportVerificationPreflightPanel: View {
    let scheme: ColorScheme
    let totalRedactionCount: Int
    let visualObfuscationCount: Int
    let isPDF: Bool
    let language: AppLanguage
    @Binding var isExpanded: Bool

    var body: some View {
        let color: Color = totalRedactionCount > 0 ? ShieldTheme.success : ShieldTheme.warning

        Button {
            withAnimation(.spring(response: 0.3)) { isExpanded.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: isExpanded ? 10 : 0) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(color.opacity(0.18)).frame(width: 36, height: 36)
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(language == .es ? "Verificación de salida" : "Output verification")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ShieldTheme.primary(scheme))
                        Text(isPDF
                             ? (language == .es ? "Se verificará antes de compartir" : "Verified before sharing")
                             : (language == .es ? "Salida rasterizada y aplanada" : "Rasterized and flattened output"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(color)
                    }
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                }

                if isExpanded {
                    VStack(alignment: .leading, spacing: 6) {
                        ExportPrivacyScoreRow(
                            scheme: scheme,
                            icon: "scissors",
                            label: LanguageManager.shared.editor("editor_export_redactions_applied"),
                            value: totalRedactionCount > 0 ? "\(totalRedactionCount)" : LanguageManager.shared.editor("editor_export_none"),
                            ok: totalRedactionCount > 0
                        )
                        ExportPrivacyScoreRow(
                            scheme: scheme,
                            icon: "doc.badge.minus",
                            label: language == .es ? "Contenido original" : "Original content",
                            value: language == .es ? "No se reutiliza" : "Not reused",
                            ok: true
                        )
                        ExportPrivacyScoreRow(
                            scheme: scheme,
                            icon: "eye.slash",
                            label: language == .es ? "Obfuscaciones visuales" : "Visual obfuscations",
                            value: visualObfuscationCount > 0
                                ? (language == .es ? "\(visualObfuscationCount) → opacas" : "\(visualObfuscationCount) → opaque")
                                : (language == .es ? "Ninguna" : "None"),
                            ok: true
                        )
                        ExportPrivacyScoreRow(
                            scheme: scheme,
                            icon: "checkmark.seal",
                            label: language == .es ? "Comprobaciones PDF" : "PDF checks",
                            value: isPDF
                                ? (language == .es ? "Texto, páginas y metadatos" : "Text, pages and metadata")
                                : (language == .es ? "No aplicable" : "Not applicable"),
                            ok: true
                        )
                    }
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .background(ShieldTheme.rowBackground(scheme))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(language == .es ? "Verificación de salida" : "Output verification")
        .accessibilityValue(
            isPDF
                ? (language == .es ? "Se verificará antes de compartir" : "Verified before sharing")
                : (language == .es ? "Salida rasterizada y aplanada" : "Rasterized and flattened output")
        )
        .accessibilityHint(
            isExpanded
                ? (language == .es ? "Contraer detalles" : "Collapse details")
                : (language == .es ? "Mostrar detalles" : "Show details")
        )
    }
}

struct ExportPrivacyScoreRow: View {
    let scheme: ColorScheme
    let icon: String
    let label: String
    let value: String
    let ok: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ok ? ShieldTheme.success : ShieldTheme.warning)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(ShieldTheme.secondary(scheme))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ok ? ShieldTheme.success : ShieldTheme.warning)
        }
    }
}

struct ExportSectionLabel: View {
    let text: String
    let scheme: ColorScheme

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(ShieldTheme.tertiary(scheme))
            .textCase(.uppercase)
            .tracking(0.4)
    }
}
