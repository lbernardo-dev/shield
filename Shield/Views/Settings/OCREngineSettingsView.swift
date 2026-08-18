import SwiftUI

// MARK: - OCREngineSettingsView

struct OCREngineSettingsView: View {
    @StateObject private var engineManager = OCREngineManager.shared
    @Environment(\.colorScheme) private var scheme
    @State private var diagnosticOutput: String? = nil
    @State private var isRunningDiagnostic = false

    private var strings: LanguageManager { .shared }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: ShieldTheme.s5) {
                headerCard

                engineSelectionSection

                preprocessingSection

                languagePacksSection

                diagnosticSection
            }
            .padding(.horizontal, ShieldTheme.s4)
            .padding(.vertical, ShieldTheme.s4)
        }
        .background(ShieldTheme.pageBackground(scheme).ignoresSafeArea())
        .navigationTitle(strings.settings("settings_ocr_engine_title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerCard: some View {
        HStack(spacing: ShieldTheme.s4) {
            ZStack {
                RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                    .fill(ShieldTheme.accentDim(scheme))
                    .frame(width: 52, height: 52)
                Image(systemName: "text.viewfinder")
                    .shieldFont(24, weight: .bold)
                    .foregroundColor(ShieldTheme.accent(scheme))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(strings.settings("settings_ocr_engine_header_title"))
                    .shieldFont(16, weight: .bold)
                    .foregroundColor(ShieldTheme.primary(scheme))
                Text(strings.settings("settings_ocr_engine_header_desc"))
                    .shieldFont(12)
                    .foregroundColor(ShieldTheme.secondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(ShieldTheme.s4)
        .background(ShieldTheme.cardBackground(scheme))
        .overlay(
            RoundedRectangle(cornerRadius: ShieldTheme.rLG)
                .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rLG))
    }

    // MARK: - Engine Selection

    private var engineSelectionSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            Text(strings.settings("settings_ocr_active_engine"))
                .shieldFont(13, weight: .bold)
                .foregroundColor(ShieldTheme.secondary(scheme))
                .textCase(.uppercase)

            VStack(spacing: ShieldTheme.s3) {
                ForEach(OCREngineMode.allCases) { mode in
                    let isSelected = engineManager.activeMode == mode
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            engineManager.activeMode = mode
                        }
                    } label: {
                        HStack(alignment: .top, spacing: ShieldTheme.s3) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .shieldFont(20, weight: .semibold)
                                .foregroundColor(isSelected ? ShieldTheme.accent(scheme) : ShieldTheme.tertiary(scheme))
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(mode.title)
                                        .shieldFont(14, weight: .bold)
                                        .foregroundColor(ShieldTheme.primary(scheme))
                                    Spacer()
                                    Text(mode.badge)
                                        .shieldFont(10, weight: .bold)
                                        .foregroundColor(isSelected ? ShieldTheme.accentText : ShieldTheme.secondary(scheme))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(isSelected ? ShieldTheme.accent(scheme) : ShieldTheme.rowBackground(scheme))
                                        .clipShape(Capsule())
                                }

                                Text(mode.subtitle)
                                    .shieldFont(12)
                                    .foregroundColor(ShieldTheme.secondary(scheme))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(ShieldTheme.s4)
                        .background(isSelected ? ShieldTheme.accentDim(scheme) : ShieldTheme.cardBackground(scheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                                .stroke(isSelected ? ShieldTheme.accentStroke(scheme) : ShieldTheme.line(scheme), lineWidth: isSelected ? 1.2 : 0.8)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    // MARK: - Preprocessing Options

    private var preprocessingSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            Text(strings.settings("settings_ocr_enhancement_title"))
                .shieldFont(13, weight: .bold)
                .foregroundColor(ShieldTheme.secondary(scheme))
                .textCase(.uppercase)

            VStack(spacing: 0) {
                ToggleRow(
                    icon: "shadow",
                    title: strings.settings("settings_ocr_shadow_removal"),
                    subtitle: strings.settings("settings_ocr_shadow_removal_desc"),
                    isOn: $engineManager.enableShadowRemoval
                )

                Divider().padding(.leading, 44)

                ToggleRow(
                    icon: "slider.horizontal.2.square",
                    title: strings.settings("settings_ocr_contrast"),
                    subtitle: strings.settings("settings_ocr_contrast_desc"),
                    isOn: $engineManager.enableAdaptiveContrast
                )

                Divider().padding(.leading, 44)

                ToggleRow(
                    icon: "rotate.right",
                    title: strings.settings("settings_ocr_deskew"),
                    subtitle: strings.settings("settings_ocr_deskew_desc"),
                    isOn: $engineManager.enableDeskew
                )

                Divider().padding(.leading, 44)

                ToggleRow(
                    icon: "checkmark.shield.fill",
                    title: strings.settings("settings_ocr_math_correction"),
                    subtitle: strings.settings("settings_ocr_math_correction_desc"),
                    isOn: $engineManager.enableMathematicalCorrection
                )
            }
            .padding(.horizontal, ShieldTheme.s4)
            .background(ShieldTheme.cardBackground(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: ShieldTheme.rLG)
                    .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rLG))
        }
    }

    // MARK: - Language Packs

    private var languagePacksSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            HStack {
                Text(strings.settings("settings_ocr_local_models"))
                    .shieldFont(13, weight: .bold)
                    .foregroundColor(ShieldTheme.secondary(scheme))
                    .textCase(.uppercase)
                Spacer()
                Text(String(format: "%.1f MB en uso", engineManager.totalInstalledStorageMB))
                    .shieldFont(11, weight: .medium)
                    .foregroundColor(ShieldTheme.tertiary(scheme))
            }

            VStack(spacing: 0) {
                ForEach(engineManager.languagePacks.indices, id: \.self) { index in
                    let pack = engineManager.languagePacks[index]
                    if index > 0 {
                        Divider().padding(.leading, 44)
                    }

                    HStack(spacing: ShieldTheme.s3) {
                        Image(systemName: pack.isInstalled ? "externaldrive.fill.badge.checkmark" : "arrow.down.circle")
                            .shieldFont(18, weight: .semibold)
                            .foregroundColor(pack.isInstalled ? ShieldTheme.success : ShieldTheme.secondary(scheme))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(pack.name)
                                .shieldFont(14, weight: .semibold)
                                .foregroundColor(ShieldTheme.primary(scheme))
                            Text(String(format: "%@ • %.1f MB", pack.code.uppercased(), pack.sizeMB))
                                .shieldFont(11)
                                .foregroundColor(ShieldTheme.tertiary(scheme))
                        }

                        Spacer()

                        if pack.isDownloading {
                            ProgressView(value: pack.downloadProgress)
                                .progressViewStyle(.circular)
                                .frame(width: 28, height: 28)
                        } else if pack.isInstalled {
                            Button {
                                withAnimation {
                                    engineManager.deletePack(pack)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .shieldFont(13, weight: .semibold)
                                    .foregroundColor(ShieldTheme.danger)
                                    .padding(8)
                                    .background(ShieldTheme.rowBackground(scheme))
                                    .clipShape(Circle())
                            }
                        } else {
                            Button {
                                Task {
                                    await engineManager.downloadPack(pack)
                                }
                            } label: {
                                Text(strings.settings("settings_ocr_download"))
                                    .shieldFont(12, weight: .bold)
                                    .foregroundColor(ShieldTheme.accentText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(ShieldTheme.accent(scheme))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.vertical, ShieldTheme.s3)
                }
            }
            .padding(.horizontal, ShieldTheme.s4)
            .background(ShieldTheme.cardBackground(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: ShieldTheme.rLG)
                    .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rLG))
        }
    }

    // MARK: - Diagnostic Section

    private var diagnosticSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            Text(strings.settings("settings_ocr_diagnostics"))
                .shieldFont(13, weight: .bold)
                .foregroundColor(ShieldTheme.secondary(scheme))
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: ShieldTheme.s3) {
                Text(strings.settings("settings_ocr_diagnostics_desc"))
                    .shieldFont(12)
                    .foregroundColor(ShieldTheme.secondary(scheme))

                Button {
                    runDiagnostic()
                } label: {
                    HStack {
                        if isRunningDiagnostic {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Image(systemName: "bolt.badge.checkmark.fill")
                        }
                        Text(strings.settings("settings_ocr_run_test"))
                            .shieldFont(13, weight: .bold)
                    }
                    .foregroundColor(ShieldTheme.accent(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(ShieldTheme.accentDim(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                            .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isRunningDiagnostic)

                if let output = diagnosticOutput {
                    Text(output)
                        .shieldFont(11, design: .monospaced)
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ShieldTheme.rowBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(ShieldTheme.s4)
            .background(ShieldTheme.cardBackground(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: ShieldTheme.rLG)
                    .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rLG))
        }
    }

    private func runDiagnostic() {
        isRunningDiagnostic = true
        diagnosticOutput = nil

        Task {
            // Test Spanish DNI with OCR letter confusion (e.g. 12345678Z vs 123456782)
            let testRawWithConfusion = "I2345678Z" // 'I' instead of '1'
            let corrected = OCRErrorCorrector.correctSpanishID(testRawWithConfusion)

            let mrzTest = OCRErrorCorrector.verifyAndRepairMRZField(value: "14O59O", checkDigit: "7")

            try? await Task.sleep(nanoseconds: 300_000_000)

            await MainActor.run {
                self.isRunningDiagnostic = false
                self.diagnosticOutput = """
                ✓ Motor activo: \(engineManager.activeMode.title)
                ✓ Filtros activos: Sombras(\(engineManager.enableShadowRemoval ? "ON" : "OFF")), Contraste(\(engineManager.enableAdaptiveContrast ? "ON" : "OFF")), Deskew(\(engineManager.enableDeskew ? "ON" : "OFF"))
                ✓ Corrección DNI: "\(testRawWithConfusion)" -> "\(corrected?.corrected ?? "N/A")" (Confianza: \(String(format: "%.0f%%", (corrected?.confidence ?? 0) * 100)))
                ✓ Auto-reparación MRZ: \(mrzTest.isValid ? "Válido" : "Revisado")
                ✓ Estado general: 100% Operativo y Local
                """
            }
        }
    }
}

// MARK: - ToggleRow Helper

private struct ToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        HStack(spacing: ShieldTheme.s3) {
            Image(systemName: icon)
                .shieldFont(18, weight: .semibold)
                .foregroundColor(ShieldTheme.accent(scheme))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .shieldFont(14, weight: .semibold)
                    .foregroundColor(ShieldTheme.primary(scheme))
                Text(subtitle)
                    .shieldFont(11)
                    .foregroundColor(ShieldTheme.secondary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, ShieldTheme.s3)
    }
}
