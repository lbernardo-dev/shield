import SwiftUI
import UIKit
import PDFKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - ExportSheetView

struct ExportSheetView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared

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
    @State private var showShareSheet: Bool = false
    @State private var showPaywall: Bool = false
    @State private var shareItem: Any? = nil
    @State private var hasLoadedDefaults = false
    @State private var exportErrorMessage: String? = nil
    @State private var acknowledgeHighRiskExport = false
    @State private var showPrivacyScore = false

    var body: some View {
        if isExported {
            exportedState
        } else {
            exportForm
        }
    }

    // MARK: - Export form

    private var exportForm: some View {
        VStack(spacing: 0) {
            HStack {
                Text(lang == .es ? "Exportar" : "Export")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.top, 20)
            .padding(.bottom, 14)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Preview
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
                    .background(ShieldTheme.surface3)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Format picker
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel(lang == .es ? "Formato" : "Format")
                        HStack(spacing: 8) {
                            ForEach([ExportFormat.pdf, .image], id: \.self) { f in
                                Button { format = f } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: f == .pdf ? "doc.fill" : "photo.fill")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(format == f ? ShieldTheme.accent : ShieldTheme.textPrimary)
                                        Text(f == .pdf ? "PDF" : (lang == .es ? "Imagen" : "Image"))
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(ShieldTheme.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(format == f ? ShieldTheme.accentDim : ShieldTheme.surface3)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(format == f ? ShieldTheme.accent : ShieldTheme.surfaceLine,
                                                    lineWidth: format == f ? 1 : 0.5)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }

                    // Quality picker
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel(L10nKey.quality.string(lang: lang))
                        HStack(spacing: 6) {
                            ForEach(ExportQuality.allCases, id: \.self) { q in
                                Button { quality = q } label: {
                                    Text(qualityLabel(q))
                                        .font(.system(size: 13, weight: .semibold))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 36)
                                        .background(quality == q ? ShieldTheme.accent : ShieldTheme.surface3)
                                        .foregroundColor(quality == q ? ShieldTheme.accentText : ShieldTheme.textPrimary)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }

                    Text(lang == .es
                         ? "Las redacciones se integran directamente en el archivo exportado."
                         : "Redactions are baked directly into the exported file.")
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // Privacy Score panel
                    privacyScorePanel

                    if let exportErrorMessage {
                        Text(exportErrorMessage)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ShieldTheme.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if shouldWarnForHighRiskExport {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(lang == .es
                                     ? "Riesgo OCR alto detectado. Revisa campos críticos antes de exportar."
                                     : "High OCR risk detected. Review critical fields before exporting.")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(ShieldTheme.warning)

                            Button {
                                acknowledgeHighRiskExport.toggle()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: acknowledgeHighRiskExport ? "checkmark.square.fill" : "square")
                                        .foregroundColor(acknowledgeHighRiskExport ? ShieldTheme.accent : ShieldTheme.textTertiary)
                                    Text(lang == .es
                                         ? "Entiendo el riesgo y quiero exportar"
                                         : "I understand the risk and want to export")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(ShieldTheme.textSecondary)
                                }
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                        .padding(10)
                        .background(ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    if !pm.isPro {
                        Text(
                            lang == .es
                                ? "Exportaciones Free restantes esta semana: \(pm.remainingFreeExportsThisWeek())"
                                : "Free exports remaining this week: \(pm.remainingFreeExportsThisWeek())"
                        )
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.bottom, 16)
            }

            // Pinned footer
            VStack(spacing: 0) {
                ShieldDivider()
                Button { doExport() } label: {
                    HStack(spacing: 8) {
                        if isExporting {
                            ProgressView().tint(ShieldTheme.accentText).scaleEffect(0.8)
                            Text(lang == .es ? "Exportando…" : "Exporting…")
                                .font(.system(size: 15, weight: .bold))
                        } else {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 16, weight: .semibold))
                            Text(format == .pdf
                                 ? L10nKey.exportPDF.string(lang: lang)
                                 : L10nKey.exportImage.string(lang: lang))
                                .font(.system(size: 15, weight: .bold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(ShieldTheme.accent)
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
        return VStack(spacing: 16) {
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
                Text(lang == .es ? "Exportado" : "Exported")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Text("\(redactionsCountLabel)\(watermarkApplied ? " · \(lang == .es ? "con marca de agua" : "with watermark")" : "")")
                    .font(.system(size: 13))
                    .foregroundColor(ShieldTheme.textSecondary)
                if !pm.isPro {
                    Text(lang == .es
                         ? "Incluye marca de agua en Shield Free"
                         : "Includes watermark on Shield Free")
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.textTertiary)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                Button { onDone() } label: {
                    Text(L10nKey.done.string(lang: lang))
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(ShieldTheme.surface3)
                        .foregroundColor(ShieldTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                    shareItem = exportedURL ?? exportedImage
                    showShareSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text(L10nKey.share.string(lang: lang))
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
        .sheet(isPresented: $showShareSheet) {
            if let item = shareItem {
                ShareSheetView(items: [item])
            }
        }
    }

    // MARK: - Privacy Score

    private var privacyScorePanel: some View {
        let score = computePrivacyScore()
        let color: Color = score >= 80 ? ShieldTheme.success : (score >= 50 ? ShieldTheme.warning : ShieldTheme.danger)
        let label: String = score >= 80
            ? (lang == .es ? "Seguro para compartir" : "Safe to share")
            : (score >= 50
               ? (lang == .es ? "Riesgo moderado" : "Moderate risk")
               : (lang == .es ? "Riesgo alto" : "High risk"))

        return Button {
            withAnimation(.spring(response: 0.3)) { showPrivacyScore.toggle() }
        } label: {
            VStack(alignment: .leading, spacing: showPrivacyScore ? 10 : 0) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(color.opacity(0.18)).frame(width: 36, height: 36)
                        Text("\(score)")
                            .font(.system(size: 13, weight: .black))
                            .foregroundColor(color)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang == .es ? "Privacy Score" : "Privacy Score")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(ShieldTheme.textPrimary)
                        Text(label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(color)
                    }
                    Spacer()
                    Image(systemName: showPrivacyScore ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ShieldTheme.textTertiary)
                }

                if showPrivacyScore {
                    VStack(alignment: .leading, spacing: 6) {
                        privacyScoreRow(
                            icon: "scissors",
                            label: lang == .es ? "Redacciones aplicadas" : "Redactions applied",
                            value: totalRedactionCount > 0
                                ? "\(totalRedactionCount)"
                                : (lang == .es ? "Ninguna" : "None"),
                            ok: totalRedactionCount > 0
                        )
                        privacyScoreRow(
                            icon: "doc.badge.minus",
                            label: lang == .es ? "Metadatos EXIF/GPS eliminados" : "EXIF/GPS metadata stripped",
                            value: lang == .es ? "Siempre" : "Always",
                            ok: true
                        )
                        privacyScoreRow(
                            icon: "text.magnifyingglass",
                            label: lang == .es ? "Riesgo OCR" : "OCR risk",
                            value: (doc.fields.ocrRiskLevel ?? "").capitalized,
                            ok: doc.fields.ocrRiskLevel != "high"
                        )
                        privacyScoreRow(
                            icon: pm.isPro ? "drop.slash" : "drop.fill",
                            label: lang == .es ? "Sin marca de agua" : "No watermark",
                            value: pm.isPro
                                ? (lang == .es ? "Sí (Pro)" : "Yes (Pro)")
                                : (lang == .es ? "No (Free)" : "No (Free)"),
                            ok: pm.isPro
                        )
                    }
                    .padding(.top, 2)
                }
            }
            .padding(12)
            .background(ShieldTheme.surface3)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func privacyScoreRow(icon: String, label: String, value: String, ok: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(ok ? ShieldTheme.success : ShieldTheme.warning)
                .frame(width: 16)
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(ShieldTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(ok ? ShieldTheme.success : ShieldTheme.warning)
        }
    }

    private var totalRedactionCount: Int {
        format == .pdf
            ? pageRedactions.values.reduce(0) { $0 + $1.count }
            : redactions.count
    }

    private func computePrivacyScore() -> Int {
        var score = 40
        // Redactions applied
        if totalRedactionCount > 0 { score += 25 }
        if totalRedactionCount >= 3 { score += 5 }
        // Metadata always stripped (guaranteed by ExportEngine)
        score += 15
        // OCR risk
        if doc.fields.ocrRiskLevel != "high" { score += 10 }
        if doc.fields.ocrRiskLevel == "low" || doc.fields.ocrRiskLevel == "" { score += 5 }
        // No watermark (Pro)
        if pm.isPro { score += 5 }
        // Cap
        return min(score, 100)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(ShieldTheme.textTertiary)
            .textCase(.uppercase)
            .tracking(0.4)
    }

    private func qualityLabel(_ q: ExportQuality) -> String {
        switch q {
        case .high:   return L10nKey.high.string(lang: lang)
        case .medium: return L10nKey.medium.string(lang: lang)
        case .low:    return L10nKey.low.string(lang: lang)
        }
    }

    private var redactionsCountLabel: String {
        let n = format == .pdf
            ? pageRedactions.values.reduce(0) { $0 + $1.count }
            : redactions.count
        if lang == .es {
            return "\(n) \(n == 1 ? "redacción" : "redacciones")"
        } else {
            return "\(n) \(n == 1 ? "redaction" : "redactions")"
        }
    }

    private var watermarkApplied: Bool {
        pm.isPro ? (watermark != nil) : true
    }

    private var shouldWarnForHighRiskExport: Bool {
        guard doc.fields.ocrRiskLevel == "high" else { return false }
        return UserDefaults.standard.object(forKey: "shield.ocr.warnLowConfidence") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "shield.ocr.warnLowConfidence")
    }

    // MARK: - Real export

    private func doExport() {
        exportErrorMessage = nil
        guard pm.canExportNow() else {
            exportErrorMessage = lang == .es
                ? "Has agotado tus exportaciones semanales. Actualiza a Pro para exportar sin límite."
                : "You used all weekly exports. Upgrade to Pro for unlimited exports."
            AppState.trackEvent("export_blocked_free_limit")
            showPaywall = true
            return
        }

        if shouldWarnForHighRiskExport && !acknowledgeHighRiskExport {
            exportErrorMessage = lang == .es
                ? "Debes confirmar el riesgo OCR alto antes de exportar."
                : "You must acknowledge high OCR risk before exporting."
            AppState.trackEvent("export_blocked_risk", properties: ["risk": "high"])
            return
        }

        let effectiveWatermark = pm.isPro
            ? watermark
            : (watermark ?? Watermark(
                text: lang == .es ? "Protegido con Shield Free" : "Protected with Shield Free",
                opacity: 0.18,
                isRepeating: true
            ))

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
                let url = await ExportEngine.exportAsPDF(
                    doc: doc,
                    pageRedactions: pageRedactions,
                    watermark: effectiveWatermark,
                    scale: scale
                )
                await MainActor.run {
                    isExporting = false
                    if let url {
                        exportedURL = url
                        isExported = true
                        pm.recordExport()
                        AppState.trackEvent("export_success", properties: ["format": "pdf", "pages": pageCount])
                    } else {
                        exportErrorMessage = lang == .es
                            ? "No se pudo exportar el PDF. Inténtalo de nuevo."
                            : "Could not export PDF. Please try again."
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
                        exportErrorMessage = lang == .es
                            ? "No se pudo exportar la imagen. Inténtalo de nuevo."
                            : "Could not export image. Please try again."
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
}

// MARK: - ExportEngine

enum ExportEngine {
    static func exportAsPDF(doc: DocumentItem, pageRedactions: [Int: [Redaction]], watermark: Watermark?, scale: CGFloat) async -> URL? {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("shield_\(doc.id)_\(Int(Date().timeIntervalSince1970)).pdf")

        do {
            // Only use original-PDF fast-path when there are no image adjustments
            if doc.imageAdjustment == nil {
                if let pdfURL = try exportOriginalPDFIfAvailable(doc: doc, pageRedactions: pageRedactions, watermark: watermark, to: tempURL) {
                    return pdfURL
                }
            }

            // Build each page as a flat UIImage (supports real blur + image adjustments), then embed in PDF
            let pageFiles = doc.pageFileNames ?? [doc.imageFileName].compactMap { $0 }
            var pageImages: [(UIImage, CGRect)] = []

            if !pageFiles.isEmpty {
                for (pageIndex, fileName) in pageFiles.enumerated() {
                    guard var sourceImage = AppState.loadImage(fileName: fileName, isVaulted: doc.isVaulted) else { continue }
                    // Apply image adjustments before compositing redactions
                    if let adj = doc.imageAdjustment {
                        sourceImage = applyImageAdjustment(sourceImage, store: adj) ?? sourceImage
                    }
                    let pageW: CGFloat = 595
                    let pageH = pageW / (sourceImage.size.width / sourceImage.size.height)
                    let pageRect = CGRect(x: 0, y: 0, width: pageW, height: pageH)
                    let redactions = pageRedactions[pageIndex] ?? []
                    let flat = await compositePageImage(
                        sourceImage: sourceImage, vectorDoc: nil,
                        redactions: redactions, watermark: watermark,
                        pageSize: pageRect.size
                    )
                    if let flat { pageImages.append((flat, pageRect)) }
                }
            } else if doc.sourceType == .pdf,
                      let sourceFileName = doc.sourceFileName,
                      let pdfData = AppState.loadSourceData(fileName: sourceFileName, isVaulted: doc.isVaulted),
                      let pdfDocument = PDFDocument(data: pdfData) {
                // PDF source with blur — rasterize each PDF page then composite
                for pageIndex in 0..<pdfDocument.pageCount {
                    guard let page = pdfDocument.page(at: pageIndex) else { continue }
                    let bounds = page.bounds(for: .mediaBox).standardized
                    let pageSize = bounds.size == .zero ? CGSize(width: 595, height: 842) : bounds.size
                    var pdfPageImage = renderPDFPage(page: page, size: pageSize)
                    if let adj = doc.imageAdjustment {
                        pdfPageImage = applyImageAdjustment(pdfPageImage, store: adj) ?? pdfPageImage
                    }
                    let flat = await compositePageImage(
                        sourceImage: pdfPageImage, vectorDoc: nil,
                        redactions: pageRedactions[pageIndex] ?? [], watermark: watermark,
                        pageSize: pageSize
                    )
                    if let flat { pageImages.append((flat, CGRect(origin: .zero, size: pageSize))) }
                }
            } else {
                let pageRect = CGRect(x: 0, y: 0, width: 595, height: 595 / 1.6)
                let vectorImg = await MainActor.run { renderVectorDoc(doc: doc, size: pageRect.size) }
                let flat = await compositePageImage(
                    sourceImage: nil, vectorDoc: vectorImg,
                    redactions: pageRedactions[0] ?? [], watermark: watermark,
                    pageSize: pageRect.size
                )
                if let flat { pageImages.append((flat, pageRect)) }
            }

            guard !pageImages.isEmpty else { return nil }

            let pdfRenderer = UIGraphicsPDFRenderer(bounds: pageImages[0].1)
            try pdfRenderer.writePDF(to: tempURL) { ctx in
                for (image, rect) in pageImages {
                    ctx.beginPage(withBounds: rect, pageInfo: [:])
                    image.draw(in: rect)
                }
            }
            return tempURL
        } catch {
            return nil
        }
    }

    // Composite a single page: source + non-blur redactions + blur via CIFilter + watermark
    private static func compositePageImage(
        sourceImage: UIImage?,
        vectorDoc: UIImage?,
        redactions: [Redaction],
        watermark: Watermark?,
        pageSize: CGSize
    ) async -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: pageSize, format: format)

        var base = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: pageSize)
            if let img = sourceImage {
                img.draw(in: rect)
            } else if let img = vectorDoc {
                img.draw(in: rect)
            }
            for r in redactions where !r.style.isBlur {
                let rRect = CGRect(
                    x: r.rect.origin.x * pageSize.width, y: r.rect.origin.y * pageSize.height,
                    width: r.rect.width * pageSize.width, height: r.rect.height * pageSize.height
                )
                drawRedactionCG(context: ctx.cgContext, rect: rRect, style: r.style)
            }
        }

        let blurReds = redactions.filter { $0.style.isBlur }
        if !blurReds.isEmpty, let cgBase = base.cgImage {
            base = renderer.image { ctx in
                base.draw(in: CGRect(origin: .zero, size: pageSize))
                for r in blurReds {
                    let rRect = CGRect(
                        x: r.rect.origin.x * pageSize.width, y: r.rect.origin.y * pageSize.height,
                        width: r.rect.width * pageSize.width, height: r.rect.height * pageSize.height
                    )
                    let radius: CGFloat = r.style == .blurStrong ? 20 : 10
                    if let blurred = applyBlurToCrop(sourceImage: cgBase, rect: rRect, radius: radius) {
                        blurred.draw(in: rRect)
                    } else {
                        drawRedactionCG(context: ctx.cgContext, rect: rRect, style: r.style)
                    }
                }
            }
        }

        if let wm = watermark {
            base = renderer.image { ctx in
                base.draw(in: CGRect(origin: .zero, size: pageSize))
                drawWatermarkCG(context: ctx.cgContext, in: CGRect(origin: .zero, size: pageSize), watermark: wm)
            }
        }
        return base
    }

    // Strip all EXIF/XMP/GPS metadata from a JPEG UIImage by re-encoding via ImageIO with empty metadata
    static func imageStrippingMetadata(_ image: UIImage, compressionQuality: CGFloat = 0.92) -> UIImage? {
        guard let cgImage = image.cgImage else { return image }
        let mutableData = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else { return image }
        // Empty properties = no EXIF, no GPS, no IPTC
        CGImageDestinationAddImage(dest, cgImage, [kCGImageDestinationLossyCompressionQuality as String: compressionQuality] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return image }
        return UIImage(data: mutableData as Data)
    }

    static func exportAsImage(doc: DocumentItem, imageFileName: String?, redactions: [Redaction], watermark: Watermark?, scale: CGFloat) async -> UIImage? {
        var sourceImage = imageFileName.flatMap {
            AppState.loadImage(fileName: $0, isVaulted: doc.isVaulted)
        }
        // Apply image adjustments before scaling/compositing
        if let adj = doc.imageAdjustment, let img = sourceImage {
            sourceImage = applyImageAdjustment(img, store: adj) ?? img
        }

        let baseSize: CGSize
        if let img = sourceImage {
            baseSize = img.size
        } else {
            baseSize = CGSize(width: 800, height: 500)
        }
        let scaledSize = CGSize(width: baseSize.width * scale, height: baseSize.height * scale)

        // Render vector doc on MainActor if needed
        let vectorImage: UIImage? = sourceImage == nil ? await MainActor.run {
            renderVectorDoc(doc: doc, size: scaledSize)
        } : nil

        // Build base image (source or vector) without blur redactions
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: scaledSize, format: format)

        var baseImage = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: scaledSize)
            let cgCtx = ctx.cgContext

            if let img = sourceImage {
                img.draw(in: CGRect(origin: .zero, size: scaledSize))
            } else if let img = vectorImage {
                img.draw(in: rect)
            }

            // Draw non-blur redactions
            for r in redactions where !r.style.isBlur {
                let redactRect = CGRect(
                    x: r.rect.origin.x * scaledSize.width,
                    y: r.rect.origin.y * scaledSize.height,
                    width: r.rect.width * scaledSize.width,
                    height: r.rect.height * scaledSize.height
                )
                drawRedactionCG(context: cgCtx, rect: redactRect, style: r.style)
            }
        }

        // Apply blur redactions using CIGaussianBlur
        let blurRedactions = redactions.filter { $0.style.isBlur }
        if !blurRedactions.isEmpty, let cgBase = baseImage.cgImage {
            let blurResult = renderer.image { ctx in
                baseImage.draw(in: CGRect(origin: .zero, size: scaledSize))
                let cgCtx = ctx.cgContext
                for r in blurRedactions {
                    let redactRect = CGRect(
                        x: r.rect.origin.x * scaledSize.width,
                        y: r.rect.origin.y * scaledSize.height,
                        width: r.rect.width * scaledSize.width,
                        height: r.rect.height * scaledSize.height
                    )
                    let radius: CGFloat = r.style == .blurStrong ? 20 : 10
                    if let blurred = applyBlurToCrop(sourceImage: cgBase, rect: redactRect, radius: radius) {
                        blurred.draw(in: redactRect)
                    } else {
                        drawRedactionCG(context: cgCtx, rect: redactRect, style: r.style)
                    }
                }
            }
            baseImage = blurResult
        }

        // Watermark pass
        if let wm = watermark {
            baseImage = renderer.image { ctx in
                baseImage.draw(in: CGRect(origin: .zero, size: scaledSize))
                drawWatermarkCG(context: ctx.cgContext, in: CGRect(origin: .zero, size: scaledSize), watermark: wm)
            }
        }

        // Strip EXIF/GPS — re-encode via ImageIO with no metadata properties
        return imageStrippingMetadata(baseImage) ?? baseImage
    }

    // Render vector doc to UIImage using ImageRenderer (iOS 16+)
    @MainActor
    static func renderVectorDoc(doc: DocumentItem, size: CGSize) -> UIImage? {
        let view = DocumentView(
            kind: doc.kind,
            size: size,
            fields: doc.fields,
            redactions: [],
            watermark: nil,
            imageFileName: doc.imageFileName,
            isVaulted: doc.isVaulted
        )
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        return renderer.uiImage
    }

    // Apply ImageAdjustmentStore to a UIImage using CIFilters (same pipeline as ScanImageProcessor)
    static func applyImageAdjustment(_ image: UIImage, store: ImageAdjustmentStore) -> UIImage? {
        guard let cg = image.cgImage else { return image }
        var ci = CIImage(cgImage: cg)
        let ctx = CIContext(options: [.useSoftwareRenderer: false])

        // Crop
        let ext = ci.extent
        let cropLeft   = ext.width  * CGFloat(store.cropLeft)
        let cropRight  = ext.width  * CGFloat(store.cropRight)
        let cropTop    = ext.height * CGFloat(store.cropTop)
        let cropBottom = ext.height * CGFloat(store.cropBottom)
        let cropRect = CGRect(
            x: ext.minX + cropLeft,
            y: ext.minY + cropBottom,
            width: max(20, ext.width  - cropLeft - cropRight),
            height: max(20, ext.height - cropTop  - cropBottom)
        )
        ci = ci.cropped(to: cropRect)

        // Color controls
        let colorFilter = CIFilter.colorControls()
        colorFilter.inputImage = ci
        colorFilter.brightness = Float(store.brightness)
        colorFilter.contrast   = Float(store.contrast)
        colorFilter.saturation = Float(store.saturation)
        ci = colorFilter.outputImage ?? ci

        // Sharpness
        if store.sharpness > 0.001 {
            let sharpen = CIFilter.sharpenLuminance()
            sharpen.inputImage = ci
            sharpen.sharpness  = Float(store.sharpness)
            sharpen.radius     = 0.8
            ci = sharpen.outputImage ?? ci
        }

        guard let outCG = ctx.createCGImage(ci, from: ci.extent) else { return image }
        var result = UIImage(cgImage: outCG)

        // Hard rotation (90° steps)
        if abs(store.rotation) > 0.001 {
            result = rotateUIImage(result, degrees: store.rotation) ?? result
        }

        // Flip
        if store.flipHorizontal || store.flipVertical {
            result = flipUIImage(result, h: store.flipHorizontal, v: store.flipVertical) ?? result
        }

        return result
    }

    private static func rotateUIImage(_ image: UIImage, degrees: Double) -> UIImage? {
        let radians = CGFloat(degrees * .pi / 180)
        let rotatedRect = CGRect(origin: .zero, size: image.size)
            .applying(CGAffineTransform(rotationAngle: radians)).integral
        UIGraphicsBeginImageContextWithOptions(rotatedRect.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.translateBy(x: rotatedRect.midX, y: rotatedRect.midY)
        ctx.rotate(by: radians)
        image.draw(in: CGRect(
            x: -image.size.width / 2, y: -image.size.height / 2,
            width: image.size.width, height: image.size.height
        ))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private static func flipUIImage(_ image: UIImage, h: Bool, v: Bool) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }
        ctx.translateBy(x: h ? image.size.width : 0, y: v ? image.size.height : 0)
        ctx.scaleBy(x: h ? -1 : 1, y: v ? -1 : 1)
        image.draw(at: .zero)
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    // Rasterize a PDFPage to UIImage
    private static func renderPDFPage(page: PDFPage, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            let cgCtx = ctx.cgContext
            cgCtx.saveGState()
            cgCtx.translateBy(x: 0, y: size.height)
            cgCtx.scaleBy(x: 1, y: -1)
            page.draw(with: .mediaBox, to: cgCtx)
            cgCtx.restoreGState()
        }
    }

    // Apply CIGaussianBlur to a rect within an existing CGImage
    private static func applyBlurToCrop(
        sourceImage: CGImage,
        rect: CGRect,
        radius: CGFloat
    ) -> UIImage? {
        let ciSource = CIImage(cgImage: sourceImage)
        let blurred = ciSource
            .cropped(to: rect)
            .clampedToExtent()
            .applyingFilter("CIGaussianBlur", parameters: ["inputRadius": radius])
            .cropped(to: rect)
        guard let cgResult = CIContext().createCGImage(blurred, from: rect) else { return nil }
        return UIImage(cgImage: cgResult)
    }

    private static func exportOriginalPDFIfAvailable(
        doc: DocumentItem,
        pageRedactions: [Int: [Redaction]],
        watermark: Watermark?,
        to url: URL
    ) throws -> URL? {
        guard doc.sourceType == .pdf,
              let sourceFileName = doc.sourceFileName,
              let pdfData = AppState.loadSourceData(fileName: sourceFileName, isVaulted: doc.isVaulted),
              let pdfDocument = PDFDocument(data: pdfData),
              pdfDocument.pageCount > 0 else {
            return nil
        }

        // Check if any page has blur redactions — if so, defer to compositePageImage pipeline
        let hasBlur = pageRedactions.values.flatMap { $0 }.contains { $0.style.isBlur }
        if hasBlur { return nil }

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        try renderer.writePDF(to: url) { ctx in
            for pageIndex in 0..<pdfDocument.pageCount {
                guard let page = pdfDocument.page(at: pageIndex) else { continue }
                let bounds = page.bounds(for: .mediaBox).standardized
                let pageRect = CGRect(origin: .zero, size: bounds.size == .zero ? CGSize(width: 595, height: 842) : bounds.size)
                ctx.beginPage(withBounds: pageRect, pageInfo: [:])

                let cgCtx = ctx.cgContext
                cgCtx.saveGState()
                cgCtx.translateBy(x: 0, y: pageRect.height)
                cgCtx.scaleBy(x: 1, y: -1)
                cgCtx.translateBy(x: -bounds.minX, y: -bounds.minY)
                page.draw(with: .mediaBox, to: cgCtx)
                cgCtx.restoreGState()

                for redaction in pageRedactions[pageIndex] ?? [] {
                    let rect = CGRect(
                        x: redaction.rect.origin.x * pageRect.width,
                        y: redaction.rect.origin.y * pageRect.height,
                        width: redaction.rect.width * pageRect.width,
                        height: redaction.rect.height * pageRect.height
                    )
                    drawRedactionCG(context: cgCtx, rect: rect, style: redaction.style)
                }

                if let watermark {
                    drawWatermarkCG(context: cgCtx, in: pageRect, watermark: watermark)
                }
            }
        }
        return url
    }

    private static func drawRedactionCG(context: CGContext, rect: CGRect, style: MaskStyle) {
        switch style {
        case .blockWhite:
            context.setFillColor(UIColor.white.cgColor)
            context.fill(rect)
        case .semi:
            context.setFillColor(UIColor.black.withAlphaComponent(0.55).cgColor)
            context.fill(rect)
        case .blurStrong:
            context.setFillColor(UIColor.white.withAlphaComponent(0.80).cgColor)
            context.fill(rect)
            context.setFillColor(UIColor.gray.withAlphaComponent(0.30).cgColor)
            context.fill(rect)
        case .blurSoft:
            context.setFillColor(UIColor.white.withAlphaComponent(0.55).cgColor)
            context.fill(rect)
            context.setFillColor(UIColor.white.withAlphaComponent(0.15).cgColor)
            context.fill(rect)
        default:
            context.setFillColor(UIColor.black.cgColor)
            context.fill(rect)
        }

        if style == .redactedTag {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: min(rect.height * 0.5, 14), weight: .bold),
                .foregroundColor: UIColor(Color(hex: "FFD60A"))
            ]
            let text = "REDACTED" as NSString
            let textSize = text.size(withAttributes: attrs)
            text.draw(at: CGPoint(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2
            ), withAttributes: attrs)
        }

        if style == .diagonal {
            context.setFillColor(UIColor(Color(hex: "FFD60A")).cgColor)
            var x = rect.minX
            while x < rect.maxX + rect.height {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: x, y: rect.minY))
                path.addLine(to: CGPoint(x: x + 3, y: rect.minY))
                path.addLine(to: CGPoint(x: x + 3 - rect.height, y: rect.maxY))
                path.addLine(to: CGPoint(x: x - rect.height, y: rect.maxY))
                path.close()
                context.saveGState()
                context.clip(to: rect)
                path.fill()
                context.restoreGState()
                x += 6
            }
        }
    }

    private static func drawWatermarkCG(context: CGContext, in rect: CGRect, watermark: Watermark) {
        let fontSize = rect.width * 0.07
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize, weight: .heavy),
            .foregroundColor: UIColor(watermark.color).withAlphaComponent(CGFloat(watermark.opacity))
        ]
        let text = watermark.text as NSString

        if watermark.isRepeating {
            let stepX = rect.width / 2.5
            let stepY = rect.height / 3.5
            var y = rect.minY
            var row = 0
            while y < rect.maxY + stepY {
                let xOffset: CGFloat = row.isMultiple(of: 2) ? 0 : stepX / 2
                var x = rect.minX - stepX + xOffset
                while x < rect.maxX + stepX {
                    let textSize = text.size(withAttributes: attrs)
                    context.saveGState()
                    context.translateBy(x: x + textSize.width / 2, y: y + textSize.height / 2)
                    context.rotate(by: -CGFloat.pi / 6)
                    text.draw(at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2), withAttributes: attrs)
                    context.restoreGState()
                    x += stepX
                }
                y += stepY
                row += 1
            }
        } else {
            let textSize = text.size(withAttributes: attrs)
            context.saveGState()
            context.translateBy(x: rect.midX, y: rect.midY)
            context.rotate(by: -CGFloat.pi / 6)
            text.draw(at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2), withAttributes: attrs)
            context.restoreGState()
        }
    }
}

// MARK: - ShareSheetView

struct ShareSheetView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
