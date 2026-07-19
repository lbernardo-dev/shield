import SwiftUI

// MARK: - ExportSheetView

struct ExportSheetView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @Environment(\.colorScheme) var scheme

    let doc: DocumentItem
    let redactions: [Redaction]
    let pageRedactions: [Int: [Redaction]]
    let watermark: Watermark?
    let lang: AppLanguage
    let currentPage: Int
    let currentImageFileName: String?
    @Binding var isPresented: Bool
    var onDone: () -> Void

    enum ExportFormat: Hashable { case pdf, image }
    enum ExportQuality: String, CaseIterable { case high, medium, low }

    @State private var format: ExportFormat = .pdf
    @State private var quality: ExportQuality = .high
    @State private var isExporting: Bool = false
    @State private var isExported: Bool = false
    @State private var exportedURL: URL? = nil
    @State private var exportedImage: UIImage? = nil
    @State private var verificationReport: ExportVerificationReport? = nil
    @State private var showShareSheet: Bool = false
    @State private var showPaywall: Bool = false
    @State private var shareItem: Any? = nil
    @State private var hasLoadedDefaults = false
    @State private var exportErrorMessage: String? = nil
    @State private var acknowledgeHighRiskExport = false
    @State private var showVerificationDetails = false

    var body: some View {
        Group {
            if isExported {
                exportedState
            } else {
                exportForm
            }
        }
        .onDisappear {
            cleanupTemporaryExport()
        }
    }

    // MARK: - Export form

    private var exportForm: some View {
        VStack(spacing: 0) {
            ExportSheetHeader(
                scheme: scheme,
                title: LanguageManager.shared.editor("editor_export"),
                onClose: { isPresented = false }
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ExportPreviewCard(
                        scheme: scheme,
                        doc: doc,
                        redactions: redactions,
                        watermark: watermark,
                        currentImageFileName: currentImageFileName
                    )

                    ExportFormatPicker(
                        scheme: scheme,
                        title: LanguageManager.shared.editor("editor_export_format"),
                        selectedFormat: format,
                        labels: exportFormatLabels,
                        onSelect: { format = $0 }
                    )

                    ExportQualityPicker(
                        scheme: scheme,
                        title: LanguageManager.shared.editor("editor_export_quality"),
                        selectedQuality: quality,
                        labels: exportQualityLabels,
                        onSelect: { quality = $0 }
                    )

                    Text(LanguageManager.shared.editor("editor_export_baked_note"))
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    verificationPreflightPanel

                    if let exportErrorMessage {
                        Text(exportErrorMessage)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ShieldTheme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if shouldWarnForHighRiskExport {
                        ExportRiskAcknowledgementCard(
                            scheme: scheme,
                            warningText: LanguageManager.shared.editor("editor_ocr_risk_warning"),
                            acknowledgeText: LanguageManager.shared.editor("editor_ocr_risk_acknowledge"),
                            isAcknowledged: acknowledgeHighRiskExport,
                            onToggle: { acknowledgeHighRiskExport.toggle() }
                        )
                    }

                }
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.bottom, 16)
            }

            ExportSheetFooterButton(
                isExporting: isExporting,
                buttonTitle: exportActionTitle,
                onTap: doExport
            )
        }
        .sheet(isPresented: $showShareSheet) {
            if let item = shareItem {
                ShareSheetView(items: [item])
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: .exportLimitReached)
                .environmentObject(appState)
        }
        .onAppear {
            applyExportDefaultsIfNeeded()
        }
    }

    // MARK: - Exported state

    private var exportedState: some View {
        ExportCompletionView(
            scheme: scheme,
            isPro: pm.isPro,
            summaryText: exportSummaryText,
            showFreeWatermarkNote: true,
            onDone: onDone,
            onShare: {
                shareItem = exportedURL ?? exportedImage
                showShareSheet = true
            }
        )
        .sheet(isPresented: $showShareSheet) {
            if let item = shareItem {
                ShareSheetView(items: [item])
            }
        }
    }

    // MARK: - Verifiable preflight

    private var verificationPreflightPanel: some View {
        ExportVerificationPreflightPanel(
            scheme: scheme,
            totalRedactionCount: totalRedactionCount,
            visualObfuscationCount: visualObfuscationCount,
            isPDF: format == .pdf,
            language: lang,
            isExpanded: $showVerificationDetails
        )
    }

    private var totalRedactionCount: Int {
        format == .pdf
            ? pageRedactions.values.reduce(0) { $0 + $1.count }
            : redactions.count
    }

    private var visualObfuscationCount: Int {
        let marks = format == .pdf ? pageRedactions.values.flatMap { $0 } : redactions
        return marks.count(where: { $0.style.isVisualObfuscation })
    }

    // MARK: - Helpers

    private var exportFormatLabels: [ExportFormat: String] {
        [
            .pdf: LanguageManager.shared.editor("editor_export_pdf"),
            .image: LanguageManager.shared.editor("editor_export_image")
        ]
    }

    private var exportQualityLabels: [ExportQuality: String] {
        [
            .high: LanguageManager.shared.model("model_quality_high"),
            .medium: LanguageManager.shared.model("model_quality_medium"),
            .low: LanguageManager.shared.model("model_quality_low")
        ]
    }

    private var exportActionTitle: String {
        format == .pdf
            ? LanguageManager.shared.model("model_export_pdf")
            : LanguageManager.shared.model("model_export_image")
    }

    private var redactionsCountLabel: String {
        let n = format == .pdf
            ? pageRedactions.values.reduce(0) { $0 + $1.count }
            : redactions.count
        return LanguageManager.shared.t("editor_export_count_label", table: "Editor", args: n)
    }

    private var watermarkApplied: Bool {
        watermark != nil
    }

    private var exportSummaryText: String {
        let verificationNote: String
        if verificationReport?.isVerified == true {
            verificationNote = LanguageManager.shared.editor("editor_export_verified_pdf_note")
        } else {
            verificationNote = LanguageManager.shared.editor("editor_export_flattened_image_note")
        }
        let watermarkNote = watermarkApplied
            ? " · \(LanguageManager.shared.editor("editor_wm_applied_note"))"
            : ""
        return "\(verificationNote) · \(redactionsCountLabel)\(watermarkNote)"
    }

    private var shouldWarnForHighRiskExport: Bool {
        guard doc.fields.ocrRiskLevel == "high" else { return false }
        return UserDefaults.standard.object(forKey: "shield.ocr.warnLowConfidence") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "shield.ocr.warnLowConfidence")
    }

    // MARK: - Real export

    private func doExport() {
        cleanupTemporaryExport()
        exportErrorMessage = nil
        guard pm.canExportNow() else {
            exportErrorMessage = LanguageManager.shared.editor("editor_export_free_limit_reached")
            AppState.trackEvent("export_blocked_free_limit")
            showPaywall = true
            return
        }

        if shouldWarnForHighRiskExport && !acknowledgeHighRiskExport {
            exportErrorMessage = LanguageManager.shared.editor("editor_export_risk_acknowledge_error")
            AppState.trackEvent("export_blocked_risk", properties: ["risk": "high"])
            return
        }

        let effectiveWatermark = watermark

        let formatName = format == .pdf ? "pdf" : "image"
        let pageCount = String(max(doc.pageCount, 1))
        let redactionCount = String(format == .pdf
            ? pageRedactions.values.reduce(0) { $0 + $1.count }
            : redactions.count)
        AppState.trackEvent("export_attempted", properties: [
            "format": formatName,
            "pages": pageCount,
            "redactions": redactionCount
        ])
        withAnimation { isExporting = true }

        Task {
            let scale: CGFloat = quality == .high ? 3 : (quality == .medium ? 2 : 1)

            if format == .pdf {
                do {
                    let artifact = try await ExportEngine.exportAsPDF(
                        doc: doc,
                        pageRedactions: pageRedactions,
                        watermark: effectiveWatermark,
                        scale: scale
                    )
                    await MainActor.run {
                        isExporting = false
                        verificationReport = artifact.report
                        exportedURL = artifact.url
                        isExported = true
                        pm.recordExport()
                        AppState.trackEvent("export_success", properties: ["format": "pdf", "pages": pageCount])
                    }
                } catch {
                    await MainActor.run {
                        isExporting = false
                        exportErrorMessage = LanguageManager.shared.editor("editor_export_secure_export_failed")
                        AppState.trackEvent("export_failed", properties: ["format": "pdf"])
                    }
                }
            } else {
                let image = await ExportEngine.exportAsImage(
                    doc: doc,
                    imageFileName: currentImageFileName,
                    redactions: redactions,
                    watermark: effectiveWatermark,
                    scale: scale
                )
                await MainActor.run {
                    isExporting = false
                    if let image {
                        exportedImage = image
                        isExported = true
                        pm.recordExport()
                        AppState.trackEvent("export_success", properties: ["format": "image", "pages": pageCount])
                    } else {
                        exportErrorMessage = LanguageManager.shared.editor("editor_export_error_image_retry")
                        AppState.trackEvent("export_failed", properties: ["format": "image"])
                    }
                }
            }
        }
    }

    private func applyExportDefaultsIfNeeded() {
        guard !hasLoadedDefaults else { return }
        hasLoadedDefaults = true

        let defaults = UserDefaults.standard
        let savedFormat = defaults.integer(forKey: "shield.exportFormat")
        let savedQuality = defaults.integer(forKey: "shield.exportQuality")

        format = savedFormat == 1 ? .image : .pdf
        switch savedQuality {
        case 1: quality = .medium
        case 2: quality = .low
        default: quality = .high
        }
    }

    private func cleanupTemporaryExport() {
        if let exportedURL {
            try? FileManager.default.removeItem(at: exportedURL)
            self.exportedURL = nil
        }
    }
}
