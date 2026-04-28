import SwiftUI
import UIKit

// MARK: - ExportSheetView

struct ExportSheetView: View {
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
    @State private var shareItem: Any? = nil

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
                            imageFileName: currentImageFileName
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
    }

    // MARK: - Exported state

    private var exportedState: some View {
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
                Text(lang == .es ? "Exportado" : "Exported")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Text("\(redactionsCountLabel)\(watermark != nil ? " · \(lang == .es ? "con marca de agua" : "with watermark")" : "")")
                    .font(.system(size: 13))
                    .foregroundColor(ShieldTheme.textSecondary)
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
        let n = redactions.count
        if lang == .es {
            return "\(n) \(n == 1 ? "redacción" : "redacciones")"
        } else {
            return "\(n) \(n == 1 ? "redaction" : "redactions")"
        }
    }

    // MARK: - Real export

    private func doExport() {
        withAnimation { isExporting = true }

        Task {
            let scale: CGFloat = quality == .high ? 3 : (quality == .medium ? 2 : 1)

            if format == .pdf {
                let url = await ExportEngine.exportAsPDF(
                    doc: doc,
                    pageRedactions: pageRedactions,
                    watermark: watermark,
                    scale: scale
                )
                await MainActor.run {
                    isExporting = false
                    exportedURL = url
                    isExported = true
                }
            } else {
                let image = await ExportEngine.exportAsImage(
                    doc: doc,
                    imageFileName: currentImageFileName,
                    redactions: redactions,
                    watermark: watermark,
                    scale: scale
                )
                await MainActor.run {
                    isExporting = false
                    exportedImage = image
                    isExported = true
                }
            }
        }
    }
}

// MARK: - ExportEngine

enum ExportEngine {
    static func exportAsPDF(doc: DocumentItem, pageRedactions: [Int: [Redaction]], watermark: Watermark?, scale: CGFloat) async -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("shield_\(doc.id)_\(Int(Date().timeIntervalSince1970)).pdf")

        do {
            try renderer.writePDF(to: tempURL) { ctx in
                let pageFiles = doc.pageFileNames ?? [doc.imageFileName].compactMap { $0 }

                if !pageFiles.isEmpty {
                    for (pageIndex, fileName) in pageFiles.enumerated() {
                        guard let sourceImage = AppState.imagesDir.appendingPathComponent(fileName).loadImage() else {
                            continue
                        }

                        let pageW: CGFloat = 595
                        let pageH = pageW / (sourceImage.size.width / sourceImage.size.height)
                        let pageRect = CGRect(x: 0, y: 0, width: pageW, height: pageH)
                        ctx.beginPage(withBounds: pageRect, pageInfo: [:])

                        let cgCtx = ctx.cgContext
                        sourceImage.draw(in: pageRect)

                        for redaction in pageRedactions[pageIndex] ?? [] {
                            let rect = CGRect(
                                x: redaction.rect.origin.x * pageW,
                                y: redaction.rect.origin.y * pageH,
                                width: redaction.rect.width * pageW,
                                height: redaction.rect.height * pageH
                            )
                            drawRedactionCG(context: cgCtx, rect: rect, style: redaction.style)
                        }

                        if let wm = watermark {
                            drawWatermarkCG(context: cgCtx, in: pageRect, watermark: wm)
                        }
                    }
                } else {
                    let pageRect = CGRect(x: 0, y: 0, width: 595, height: 595 / 1.6)
                    ctx.beginPage(withBounds: pageRect, pageInfo: [:])
                    let cgCtx = ctx.cgContext

                    if let image = renderVectorDoc(doc: doc, size: pageRect.size) {
                        image.draw(in: pageRect)
                    }

                    for redaction in pageRedactions[0] ?? [] {
                        let rect = CGRect(
                            x: redaction.rect.origin.x * pageRect.width,
                            y: redaction.rect.origin.y * pageRect.height,
                            width: redaction.rect.width * pageRect.width,
                            height: redaction.rect.height * pageRect.height
                        )
                        drawRedactionCG(context: cgCtx, rect: rect, style: redaction.style)
                    }

                    if let wm = watermark {
                        drawWatermarkCG(context: cgCtx, in: pageRect, watermark: wm)
                    }
                }
            }
            return tempURL
        } catch {
            return nil
        }
    }

    static func exportAsImage(doc: DocumentItem, imageFileName: String?, redactions: [Redaction], watermark: Watermark?, scale: CGFloat) async -> UIImage? {
        let sourceImage = imageFileName.flatMap {
            AppState.imagesDir.appendingPathComponent($0).loadImage()
        }

        let size: CGSize
        if let img = sourceImage {
            size = img.size
        } else {
            size = CGSize(width: 800, height: 500)   // ID card ratio
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size.width * scale, height: size.height * scale), format: format)

        return renderer.image { ctx in
            let scaledSize = CGSize(width: size.width * scale, height: size.height * scale)
            let rect = CGRect(origin: .zero, size: scaledSize)
            let cgCtx = ctx.cgContext

            // Draw source
            if let img = sourceImage {
                img.draw(in: rect)
            } else if let img = renderVectorDoc(doc: doc, size: scaledSize) {
                img.draw(in: rect)
            }

            // Draw redactions
            for r in redactions {
                let redactRect = CGRect(
                    x: r.rect.origin.x * scaledSize.width,
                    y: r.rect.origin.y * scaledSize.height,
                    width: r.rect.width * scaledSize.width,
                    height: r.rect.height * scaledSize.height
                )
                drawRedactionCG(context: cgCtx, rect: redactRect, style: r.style)
            }

            if let wm = watermark {
                drawWatermarkCG(context: cgCtx, in: rect, watermark: wm)
            }
        }
    }

    // Render vector doc to UIImage
    private static func renderVectorDoc(doc: DocumentItem, size: CGSize) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            // Placeholder: white background with doc title
            UIColor(Color(hex: "E8E4D8")).setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: min(size.height * 0.08, 24), weight: .bold),
                .foregroundColor: UIColor.black
            ]
            (doc.title as NSString).draw(at: CGPoint(x: 12, y: 12), withAttributes: attrs)
        }
    }

    private static func drawRedactionCG(context: CGContext, rect: CGRect, style: MaskStyle) {
        switch style {
        case .blockWhite:
            context.setFillColor(UIColor.white.cgColor)
        case .semi:
            context.setFillColor(UIColor.black.withAlphaComponent(0.55).cgColor)
        default:
            context.setFillColor(UIColor.black.cgColor)
        }
        context.fill(rect)

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
            .foregroundColor: UIColor.white.withAlphaComponent(CGFloat(watermark.opacity))
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
