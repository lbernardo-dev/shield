import SwiftUI
import VisionKit
import PhotosUI
import Vision
import UIKit
import UniformTypeIdentifiers
import PDFKit
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - ScanDocumentType (frame guide during scanning)

enum ScanDocumentType: String, CaseIterable, Identifiable {
    case identity
    case passport
    case drivingLicense
    case a4Document
    case freeform

    var id: String { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .identity:       return LanguageManager.shared.t("capture_kind_id_card", table: "Capture")
        case .passport:       return LanguageManager.shared.t("capture_kind_passport", table: "Capture")
        case .drivingLicense: return LanguageManager.shared.t("capture_kind_driving_license", table: "Capture")
        case .a4Document:     return LanguageManager.shared.t("capture_kind_a4", table: "Capture")
        case .freeform:       return LanguageManager.shared.t("capture_kind_freeform", table: "Capture")
        }
    }

    var icon: String {
        switch self {
        case .identity:       return "creditcard"
        case .passport:       return "book.closed"
        case .drivingLicense: return "car"
        case .a4Document:     return "doc.text"
        case .freeform:       return "crop"
        }
    }

    // Aspect ratio width:height for the guide frame
    var aspectRatio: CGFloat {
        switch self {
        case .identity:       return 85.6 / 54.0   // ISO/IEC 7810 ID-1
        case .passport:       return 125.0 / 88.0  // ICAO 9303 booklet
        case .drivingLicense: return 85.6 / 54.0
        case .a4Document:     return 210.0 / 297.0
        case .freeform:       return 1.0
        }
    }

    // Corner hint labels for OCR field zones
    var fieldHints: [(label: String, normRect: CGRect)] {
        switch self {
        case .identity:
            return [
                (label: "Nombre",    normRect: CGRect(x: 0.30, y: 0.22, width: 0.65, height: 0.18)),
                (label: "Foto",      normRect: CGRect(x: 0.02, y: 0.12, width: 0.26, height: 0.65)),
                (label: "DOB",       normRect: CGRect(x: 0.60, y: 0.60, width: 0.36, height: 0.12)),
                (label: "MRZ",       normRect: CGRect(x: 0.00, y: 0.84, width: 1.00, height: 0.16)),
            ]
        case .passport:
            return [
                (label: "Foto",      normRect: CGRect(x: 0.02, y: 0.12, width: 0.26, height: 0.60)),
                (label: "Nombre",    normRect: CGRect(x: 0.30, y: 0.20, width: 0.66, height: 0.20)),
                (label: "Nº Pasap.", normRect: CGRect(x: 0.60, y: 0.18, width: 0.36, height: 0.10)),
                (label: "MRZ",       normRect: CGRect(x: 0.00, y: 0.82, width: 1.00, height: 0.18)),
            ]
        case .drivingLicense:
            return [
                (label: "Foto",      normRect: CGRect(x: 0.10, y: 0.18, width: 0.24, height: 0.56)),
                (label: "Nombre",    normRect: CGRect(x: 0.38, y: 0.22, width: 0.58, height: 0.18)),
                (label: "Nº Carnet", normRect: CGRect(x: 0.38, y: 0.68, width: 0.56, height: 0.10)),
            ]
        case .a4Document, .freeform:
            return []
        }
    }
}

// MARK: - CaptureView

struct CaptureView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @State private var showSourcePicker = false
    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var showPaywall = false
    @State private var paywallTrigger: PaywallTrigger = .manual
    @State private var showScanReview = false
    @State private var isProcessing = false
    @State private var processingMessage = ""
    @State private var stagedPages: [UIImage] = []
    @State private var stagedTitle: String? = nil
    @State private var stagedSourceType: ImportedDocumentSource = .image
    @State private var stagedSourceFileName: String? = nil
    @State private var stagedDocID: String = UUID().uuidString
    @State private var selectedScanType: ScanDocumentType = .identity
    @State private var showScanTypeGuide: Bool = true
    @State private var showCloudPicker: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isProcessing {
                processingView
            } else {
                captureMenu
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerOverlayView(
                documentType: selectedScanType,
                showGuide: showScanTypeGuide,
                lang: appState.language
            ) { images in
                showScanner = false
                guard !images.isEmpty else { return }
                stageScanPages(images, title: nil, sourceType: .image, sourceFileName: nil, docID: UUID().uuidString)
            } onCancel: {
                showScanner = false
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showScanReview) {
            ScanReviewView(
                pages: stagedPages,
                onCancel: {
                    showScanReview = false
                    stagedPages = []
                    stagedSourceFileName = nil
                },
                onConfirm: { adjustedPages, hasAdjustments in
                    showScanReview = false
                    handleReviewedPages(adjustedPages, hasAdjustments: hasAdjustments)
                }
            )
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView { images in
                showPhotoPicker = false
                guard !images.isEmpty else { return }
                stageScanPages(images, title: nil, sourceType: .image, sourceFileName: nil, docID: UUID().uuidString)
            } onCancel: {
                showPhotoPicker = false
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilesPickerView { url in
                showFilePicker = false
                processFile(url)
            } onCancel: {
                showFilePicker = false
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: paywallTrigger).environmentObject(appState)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("shield.importFileURL"))) { note in
            if let url = note.object as? URL {
                processFile(url)
            }
        }
        .sheet(isPresented: $showCloudPicker) {
            ExternalStoragePickerSheet(isPresented: $showCloudPicker) { url in
                processFile(url)
            }.environmentObject(appState)
        }
    }

    // MARK: - Capture menu

    private var captureMenu: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button {
                    appState.showCapture = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                Spacer()
                Text(appState.str("capture_add_document"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            // Document type selector
            documentTypeSelector
                .padding(.horizontal, 24)
                .padding(.top, 8)

            Spacer()

            // Options
            VStack(spacing: 12) {
                captureOption(
                    icon: "camera.viewfinder",
                    title: appState.str("capture_scan_document"),
                    subtitle: appState.str("capture_guide_frame", selectedScanType.label(lang: appState.language)),
                    primary: true
                ) {
                    guard ensureCanImportMoreDocuments() else { return }
                    if VNDocumentCameraViewController.isSupported {
                        showScanner = true
                    } else {
                        showPhotoPicker = true
                    }
                }

                captureOption(
                    icon: "photo.on.rectangle",
                    title: appState.str("capture_from_photos"),
                    subtitle: appState.str("capture_pick_images"),
                    primary: false
                ) {
                    guard ensureCanImportMoreDocuments() else { return }
                    showPhotoPicker = true
                }

                captureOption(
                    icon: "folder",
                    title: appState.str("capture_from_files"),
                    subtitle: appState.str("capture_files_subtitle"),
                    primary: false
                ) {
                    guard ensureCanImportMoreDocuments() else { return }
                    showFilePicker = true
                }

                captureOption(
                    icon: "icloud.and.arrow.down",
                    title: appState.str("capture_from_cloud"),
                    subtitle: "Google Drive, Dropbox, OneDrive…",
                    primary: false
                ) {
                    guard ensureCanImportMoreDocuments() else { return }
                    showCloudPicker = true
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Privacy note
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "666666"))
                Text(appState.str("capture_on_device_privacy"))
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "666666"))
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Document type selector

    @ViewBuilder
    private var documentTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(appState.str("capture_document_type"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "888888"))
                Spacer()
                Button {
                    withAnimation { showScanTypeGuide.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: showScanTypeGuide ? "eye.slash" : "eye")
                            .font(.system(size: 11, weight: .semibold))
                        Text(showScanTypeGuide
                             ? appState.str("capture_hide_guide")
                             : appState.str("capture_show_guide"))
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(ShieldTheme.accent)
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ScanDocumentType.allCases) { type in
                        let isSelected = selectedScanType == type
                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) { selectedScanType = type }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: type.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                Text(type.label(lang: appState.language))
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(isSelected ? .black : Color(hex: "aaaaaa"))
                            .padding(.horizontal, 12)
                            .frame(height: 32)
                            .background(isSelected ? ShieldTheme.accent : Color(hex: "1c1c1e"))
                            .overlay(
                                Capsule().stroke(
                                    isSelected ? ShieldTheme.accent : Color(hex: "333333"),
                                    lineWidth: 1
                                )
                            )
                            .clipShape(Capsule())
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func captureOption(icon: String, title: String, subtitle: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(primary ? ShieldTheme.accent : Color(hex: "1c1c1e"))
                        .frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(primary ? .black : .white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "888888"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(hex: "555555"))
            }
            .padding(16)
            .background(Color(hex: "111111"))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(primary ? ShieldTheme.accent.opacity(0.4) : Color(hex: "2a2a2a"), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Processing view

    private var processingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(ShieldTheme.accent)
            Text(processingMessage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Processing logic

    private func ensureCanImportMoreDocuments() -> Bool {
        if pm.canAddDocument(currentCount: appState.documents.count) {
            return true
        }
        paywallTrigger = .docLimitReached
        showPaywall = true
        return false
    }

    private func processFile(_ url: URL) {
        guard pm.canAddDocument(currentCount: appState.documents.count) else {
            paywallTrigger = .docLimitReached
            showPaywall = true
            return
        }
        AppState.trackEvent("import_started", properties: ["source": "file"])
        isProcessing = true
        processingMessage = appState.str("capture_importing_file")

        Task {
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }

            // Try to load as UIImage first (JPEG/PNG)
            if let image = UIImage(contentsOfFile: url.path) {
                await MainActor.run { isProcessing = false }
                stageScanPages(
                    [image],
                    title: url.deletingPathExtension().lastPathComponent,
                    sourceType: .image,
                    sourceFileName: nil,
                    docID: UUID().uuidString
                )
                return
            }

            // Try to render all PDF pages
            let pdfTitle = url.deletingPathExtension().lastPathComponent
            if let (pdfDocument, pdfData) = loadPDFDocument(from: url),
               let pages = renderPDFAllPages(document: pdfDocument),
               !pages.isEmpty {
                let docID = UUID().uuidString
                let sourceFileName = appState.saveSourceFile(pdfData, id: docID, fileExtension: "pdf")
                await MainActor.run { isProcessing = false }
                stageScanPages(
                    pages,
                    title: pdfTitle,
                    sourceType: .pdf,
                    sourceFileName: sourceFileName,
                    docID: docID
                )
                return
            }

            // Unsupported
            await MainActor.run {
                isProcessing = false
                AppState.trackEvent("import_failed", properties: ["source": "file"])
                appState.showCapture = false
            }
        }
    }

    private func stageScanPages(
        _ pages: [UIImage],
        title: String?,
        sourceType: ImportedDocumentSource,
        sourceFileName: String?,
        docID: String
    ) {
        guard !pages.isEmpty else { return }
        if sourceType == .image {
            AppState.trackEvent("import_started", properties: ["source": "image"])
        }
        stagedPages = pages
        stagedTitle = title
        stagedSourceType = sourceType
        stagedSourceFileName = sourceFileName
        stagedDocID = docID
        showScanReview = true
        AppState.trackEvent("scan_adjustment_opened", properties: [
            "pages": String(pages.count),
            "source": sourceType.rawValue
        ])
    }

    private func handleReviewedPages(_ pages: [UIImage], hasAdjustments: Bool) {
        guard !pages.isEmpty else { return }
        let title = stagedTitle ?? ""
        let docID = stagedDocID
        let sourceType: ImportedDocumentSource = (stagedSourceType == .pdf && hasAdjustments) ? .image : stagedSourceType
        let sourceFileName = sourceType == .pdf ? stagedSourceFileName : nil
        stagedPages = []
        stagedTitle = nil
        stagedSourceFileName = nil

        processImportedPages(
            pages,
            title: title,
            docID: docID,
            sourceType: sourceType,
            sourceFileName: sourceFileName
        )

        AppState.trackEvent("scan_adjustment_applied", properties: [
            "pages": String(pages.count),
            "has_adjustments": hasAdjustments ? "true" : "false"
        ])
    }

    private func processImportedPages(
        _ pages: [UIImage],
        title: String,
        docID: String,
        sourceType: ImportedDocumentSource,
        sourceFileName: String?
    ) {
        isProcessing = true
        processingMessage = appState.str("capture_processing_pages")

        Task {
            var pageFileNames: [String] = []

            for (idx, page) in pages.enumerated() {
                if let fileName = appState.saveImage(page, id: "\(docID)_p\(idx)") {
                    pageFileNames.append(fileName)
                }
            }

            guard !pageFileNames.isEmpty else {
                await MainActor.run {
                    isProcessing = false
                    appState.showCapture = false
                }
                return
            }

            // OCR all pages: two-pass adaptive — second pass adds country-specific languages if detected.
            // Also capture bounding boxes for page 0 to enable precision auto-redaction.
            let pageObservations = await OCRService.recognizeObservationsByPageAdaptive(in: pages)
            let pageLines = pageObservations.map { $0.map(\.text) }
            let pageTexts = pageLines.map { $0.joined(separator: "\n") }
            // Extract fields per page so multi-page docs don't bleed fields across pages
            let perPageFields = pageLines.map { OCRService.extractFields(from: $0) }
            // Merge: use page with highest aggregate confidence (MRZ page wins if valid)
            let bestPageFields = perPageFields.max(by: { a, b in
                let scoreA = (a.ocrFieldConfidence ?? [:]).values.reduce(0, +)
                let scoreB = (b.ocrFieldConfidence ?? [:]).values.reduce(0, +)
                let mrzA = (a.ocrMRZValid == true) ? 10.0 : 0.0
                let mrzB = (b.ocrMRZValid == true) ? 10.0 : 0.0
                return (scoreA + mrzA) < (scoreB + mrzB)
            })
            let lines = pageLines.flatMap { $0 }
            var fields = bestPageFields ?? OCRService.extractFields(from: lines)
            let detectedType = OCRService.detectDocumentType(from: lines)
            fields.ocrDocumentType = detectedType.rawValue
            fields.ocrPageTexts = pageTexts
            fields.ocrFullText = pageTexts.joined(separator: "\n\n")
            // Store bounding boxes from page 0 for precision redaction in the editor
            if let page0 = pageObservations.first {
                fields.ocrBoundingTexts = page0.map(\.text)
                fields.ocrBoundingRects = page0.map(\.boundingRect)
            }
            let detectedCountry = normalizedCountryCode(from: fields, detectedType: detectedType)
            fields.ocrDetectedCountry = detectedCountry
            let risk = OCRService.assessRisk(fields: fields, detectedType: detectedType, threshold: OCRService.minimumConfidenceThreshold())
            fields.ocrRiskLevel = risk.level.rawValue
            fields.ocrLowConfidenceFields = risk.lowFields

            let fallbackTitle: String = {
                if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return title }
                let fmt = DateFormatter()
                fmt.dateFormat = "d MMM HH:mm"
                return appState.str("capture_scan_fallback_title", fmt.string(from: Date()))
            }()
            let docTitle = !fields.fullName.isEmpty ? fields.fullName : fallbackTitle

            // Resolve the richest DocumentKind from OCR signals
            let resolvedKind = resolveDocumentKind(
                detectedType: detectedType,
                country: detectedCountry,
                mrzFormat: fields.ocrMRZFormat
            )
            let detectedCategory: DocumentCategory = {
                switch detectedType {
                case .passport:        return .travel
                case .visa:            return .travel
                case .residencePermit: return .identity
                case .drivingLicense:  return .driving
                case .healthCard:      return .health
                case .dni:             return .identity
                case .document:        return .work
                }
            }()
            let doc = DocumentItem(
                id: docID,
                kind: resolvedKind,
                title: docTitle,
                category: detectedCategory,
                date: Date(),
                redactionCount: 0,
                isFavorite: false,
                isLocked: false,
                isVaulted: false,
                imageFileName: pageFileNames[0],
                pageFileNames: pageFileNames.count > 1 ? pageFileNames : nil,
                sourceType: sourceType,
                sourceFileName: sourceFileName,
                fields: fields,
                pageRedactions: [],
                watermark: nil
            )

            await MainActor.run {
                appState.addDocument(doc)
                AppState.trackEvent("import_completed", properties: [
                    "source": sourceType.rawValue,
                    "pages": String(pageFileNames.count),
                    "detected_type": detectedType.rawValue,
                    "mrz_valid": (fields.ocrMRZValid == true) ? "true" : "false"
                ])
                if risk.level != .low {
                    AppState.trackEvent("risk_detected", properties: [
                        "source": sourceType.rawValue,
                        "risk": risk.level.rawValue,
                        "low_fields": risk.lowFields.joined(separator: ",")
                    ])
                }
                isProcessing = false
                appState.selectedDoc = doc
                appState.showCapture = false
            }
        }
    }

    /// Maps OCR-detected type + country to the richest available DocumentKind.
    /// Falls back to .photo so the image is still rendered correctly when no
    /// structured template exists for the detected combination.
    private func resolveDocumentKind(
        detectedType: OCRService.DetectedDocumentType,
        country: String?,
        mrzFormat: String?
    ) -> DocumentKind {
        switch detectedType {
        case .passport:
            switch country {
            case "USA": return .passportUSA
            case "MEX": return .passportMEX
            default:    return .photo   // render from image; no vector template for others
            }
        case .dni:
            switch country {
            case "ESP": return .dniESP
            case "ITA": return .dniITA
            default:    return .genericID
            }
        case .drivingLicense:
            switch country {
            case "GBR": return .drivingUK
            default:    return .photo
            }
        case .visa, .residencePermit, .healthCard, .document:
            return .photo
        }
    }

    private func loadPDFDocument(from url: URL) -> (PDFDocument, Data)? {
        guard let data = try? Data(contentsOf: url),
              let document = PDFDocument(data: data),
              document.pageCount > 0 else {
            return nil
        }
        return (document, data)
    }

    private func renderPDFAllPages(document: PDFDocument) -> [UIImage]? {
        let scale: CGFloat = 2.0
        var images: [UIImage] = []

        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            let pageRect = page.bounds(for: .mediaBox)
            let size = CGSize(width: max(pageRect.width * scale, 1), height: max(pageRect.height * scale, 1))
            images.append(page.thumbnail(of: size, for: .mediaBox))
        }

        return images.isEmpty ? nil : images
    }

    private func normalizedCountryCode(from fields: DocumentFields, detectedType: OCRService.DetectedDocumentType) -> String? {
        // MRZ nationality is the most reliable source
        let nat = fields.nationality.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if nat.count == 3, nat.allSatisfy({ $0 >= "A" && $0 <= "Z" }) {
            return nat
        }

        let docNum = fields.documentNumber.uppercased().replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)

        // Spanish NIE (X/Y/Z + 7 digits + letter) or DNI (8 digits + letter)
        if docNum.hasPrefix("X") || docNum.hasPrefix("Y") || docNum.hasPrefix("Z") { return "ESP" }
        if docNum.count == 9, docNum.first?.isNumber == true, docNum.last?.isLetter == true { return "ESP" }

        // Mexican CURP (18 alphanumeric with specific structure — already extracted)
        // Chinese Resident ID is 18 digits — differentiate by country hint from OCR text
        if docNum.count == 18 {
            // Check if we have a country hint from the text that disambiguates
            let fullText = (fields.ocrFullText ?? "").uppercased()
            if fullText.contains("CHINA") || fullText.contains("中国") || fullText.contains("中华") { return "CHN" }
            if fullText.contains("MEXICO") || fullText.contains("MÉXICO") || fullText.contains("CURP") { return "MEX" }
            // Without other signals we cannot determine CHN vs MEX from length alone
            return nil
        }

        // Brazilian CPF: 11 digits
        if docNum.count == 11, docNum.allSatisfy(\.isNumber) {
            let fullText = (fields.ocrFullText ?? "").uppercased()
            if fullText.contains("BRASIL") || fullText.contains("CPF") { return "BRA" }
        }

        // Argentine DNI: 7–8 digits
        if (docNum.count == 7 || docNum.count == 8), docNum.allSatisfy(\.isNumber) {
            let fullText = (fields.ocrFullText ?? "").uppercased()
            if fullText.contains("ARGENTINA") || fullText.contains("DNI") { return "ARG" }
        }

        return nil
    }
}

// MARK: - Scan Review + Image Adjustments

enum ScanFilterPreset: String, CaseIterable, Identifiable {
    case original
    case auto
    case blackWhite
    case highContrast

    var id: String { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .original: return "Original"
        case .auto: return "Auto"
        case .blackWhite: return LanguageManager.shared.str("capture_black_white", table: "Capture")
        case .highContrast: return LanguageManager.shared.str("capture_high_contrast", table: "Capture")
        }
    }
}

enum ScanAdjustmentPreset: String, CaseIterable, Identifiable {
    case document
    case photo
    case grayscale

    var id: String { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .document: return LanguageManager.shared.str("capture_document", table: "Capture")
        case .photo: return LanguageManager.shared.str("capture_photo", table: "Capture")
        case .grayscale: return LanguageManager.shared.str("capture_grayscale_strong", table: "Capture")
        }
    }

    func adjustment() -> ScanPageAdjustment {
        switch self {
        case .document:
            return ScanPageAdjustment(
                filterPreset: .auto,
                straightenDegrees: 0,
                rotationDegrees: 0,
                perspectiveTopInset: 0,
                perspectiveBottomInset: 0,
                perspectiveSkew: 0,
                perspectiveTopYOffset: 0,
                perspectiveBottomYOffset: 0,
                cropLeft: 0,
                cropRight: 0,
                cropTop: 0,
                cropBottom: 0,
                brightness: 0.02,
                contrast: 1.25,
                sharpness: 0.4,
                noiseReduction: 0.02
            )
        case .photo:
            return ScanPageAdjustment(
                filterPreset: .original,
                straightenDegrees: 0,
                rotationDegrees: 0,
                perspectiveTopInset: 0,
                perspectiveBottomInset: 0,
                perspectiveSkew: 0,
                perspectiveTopYOffset: 0,
                perspectiveBottomYOffset: 0,
                cropLeft: 0,
                cropRight: 0,
                cropTop: 0,
                cropBottom: 0,
                brightness: 0,
                contrast: 1.08,
                sharpness: 0.18,
                noiseReduction: 0
            )
        case .grayscale:
            return ScanPageAdjustment(
                filterPreset: .highContrast,
                straightenDegrees: 0,
                rotationDegrees: 0,
                perspectiveTopInset: 0,
                perspectiveBottomInset: 0,
                perspectiveSkew: 0,
                perspectiveTopYOffset: 0,
                perspectiveBottomYOffset: 0,
                cropLeft: 0,
                cropRight: 0,
                cropTop: 0,
                cropBottom: 0,
                brightness: 0.05,
                contrast: 1.52,
                sharpness: 0.6,
                noiseReduction: 0.03
            )
        }
    }
}

struct ScanPageAdjustment: Equatable {
    var filterPreset: ScanFilterPreset = .auto
    var straightenDegrees: Double = 0
    var rotationDegrees: Double = 0
    var perspectiveTopInset: Double = 0
    var perspectiveBottomInset: Double = 0
    var perspectiveSkew: Double = 0
    var perspectiveTopYOffset: Double = 0
    var perspectiveBottomYOffset: Double = 0
    // 4-point perspective handles (normalized 0..1, CIImage coordinate system: origin bottom-left)
    // nil = not set (sliders govern); non-nil overrides sliders
    var quad: ScanQuad? = nil
    var cropLeft: Double = 0
    var cropRight: Double = 0
    var cropTop: Double = 0
    var cropBottom: Double = 0
    var brightness: Double = 0
    var contrast: Double = 1.0
    var sharpness: Double = 0
    var noiseReduction: Double = 0

    static let `default` = ScanPageAdjustment()

    var hasAdjustments: Bool {
        self != .default
    }
}

/// Normalized quad for 4-point perspective correction (0..1, origin top-left in UIKit coords).
struct ScanQuad: Equatable {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomLeft: CGPoint
    var bottomRight: CGPoint

    static let identity = ScanQuad(
        topLeft: CGPoint(x: 0.05, y: 0.05),
        topRight: CGPoint(x: 0.95, y: 0.05),
        bottomLeft: CGPoint(x: 0.05, y: 0.95),
        bottomRight: CGPoint(x: 0.95, y: 0.95)
    )
}

enum ScanImageProcessor {
    static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func apply(_ image: UIImage, adjustment: ScanPageAdjustment) -> UIImage? {
        guard let cg = image.cgImage else { return image }
        var ci = CIImage(cgImage: cg)

        // Preset first
        ci = applyPreset(ci, preset: adjustment.filterPreset)

        // Geometry (straighten with crop-to-fit behavior)
        if abs(adjustment.straightenDegrees) > 0.001 {
            let angle = adjustment.straightenDegrees * .pi / 180
            ci = ci.applyingFilter("CIStraightenFilter", parameters: [kCIInputAngleKey: angle])
        }

        // Perspective correction (manual keystone)
        if hasPerspectiveAdjustments(adjustment) {
            ci = applyPerspective(ci, adjustment: adjustment)
        }

        // Crop (normalized insets)
        let extent = ci.extent
        let left = extent.width * adjustment.cropLeft
        let right = extent.width * adjustment.cropRight
        let top = extent.height * adjustment.cropTop
        let bottom = extent.height * adjustment.cropBottom
        let cropRect = CGRect(
            x: extent.minX + left,
            y: extent.minY + bottom,
            width: max(20, extent.width - left - right),
            height: max(20, extent.height - top - bottom)
        )
        ci = ci.cropped(to: cropRect)

        // Fine controls
        let color = CIFilter.colorControls()
        color.inputImage = ci
        color.brightness = Float(adjustment.brightness)
        color.contrast = Float(adjustment.contrast)
        color.saturation = 1.0
        ci = color.outputImage ?? ci

        if adjustment.sharpness > 0.001 {
            let sharpen = CIFilter.sharpenLuminance()
            sharpen.inputImage = ci
            sharpen.sharpness = Float(adjustment.sharpness)
            sharpen.radius = 0.8
            ci = sharpen.outputImage ?? ci
        }

        if adjustment.noiseReduction > 0.001 {
            let noise = CIFilter.noiseReduction()
            noise.inputImage = ci
            noise.noiseLevel = Float(adjustment.noiseReduction)
            noise.sharpness = 0.4
            ci = noise.outputImage ?? ci
        }

        guard let out = context.createCGImage(ci, from: ci.extent) else { return nil }
        let rendered = UIImage(cgImage: out)

        // Hard rotation (90° steps)
        if abs(adjustment.rotationDegrees) < 0.001 { return rendered }
        return rotate(image: rendered, degrees: adjustment.rotationDegrees)
    }

    private static func applyPreset(_ image: CIImage, preset: ScanFilterPreset) -> CIImage {
        switch preset {
        case .original:
            return image
        case .auto:
            let color = CIFilter.colorControls()
            color.inputImage = image
            color.saturation = 0
            color.brightness = 0.03
            color.contrast = 1.16
            return color.outputImage ?? image
        case .blackWhite:
            let mono = CIFilter.colorControls()
            mono.inputImage = image
            mono.saturation = 0
            mono.brightness = 0.05
            mono.contrast = 1.32
            return mono.outputImage ?? image
        case .highContrast:
            let color = CIFilter.colorControls()
            color.inputImage = image
            color.saturation = 0
            color.brightness = 0.08
            color.contrast = 1.55
            return color.outputImage ?? image
        }
    }

    private static func hasPerspectiveAdjustments(_ adjustment: ScanPageAdjustment) -> Bool {
        adjustment.quad != nil ||
        abs(adjustment.perspectiveTopInset) > 0.0001 ||
        abs(adjustment.perspectiveBottomInset) > 0.0001 ||
        abs(adjustment.perspectiveSkew) > 0.0001 ||
        abs(adjustment.perspectiveTopYOffset) > 0.0001 ||
        abs(adjustment.perspectiveBottomYOffset) > 0.0001
    }

    private static func applyPerspective(_ image: CIImage, adjustment: ScanPageAdjustment) -> CIImage {
        let extent = image.extent
        guard extent.width > 10, extent.height > 10 else { return image }

        // 4-point quad takes priority over sliders
        if let quad = adjustment.quad {
            let w = extent.width, h = extent.height
            let filter = CIFilter.perspectiveCorrection()
            filter.inputImage = image
            // UIKit coords (origin top-left) → CIImage coords (origin bottom-left)
            filter.topLeft     = CGPoint(x: extent.minX + quad.topLeft.x * w,     y: extent.minY + (1 - quad.topLeft.y) * h)
            filter.topRight    = CGPoint(x: extent.minX + quad.topRight.x * w,    y: extent.minY + (1 - quad.topRight.y) * h)
            filter.bottomLeft  = CGPoint(x: extent.minX + quad.bottomLeft.x * w,  y: extent.minY + (1 - quad.bottomLeft.y) * h)
            filter.bottomRight = CGPoint(x: extent.minX + quad.bottomRight.x * w, y: extent.minY + (1 - quad.bottomRight.y) * h)
            return filter.outputImage ?? image
        }

        let width = extent.width
        let height = extent.height

        let topInset = width * CGFloat(clamp(adjustment.perspectiveTopInset, min: 0, max: 0.42))
        let bottomInset = width * CGFloat(clamp(adjustment.perspectiveBottomInset, min: 0, max: 0.42))
        let skew = width * CGFloat(clamp(adjustment.perspectiveSkew, min: -0.2, max: 0.2))
        let topYOffset = height * CGFloat(clamp(adjustment.perspectiveTopYOffset, min: 0, max: 0.3))
        let bottomYOffset = height * CGFloat(clamp(adjustment.perspectiveBottomYOffset, min: 0, max: 0.3))

        var topLeftX = extent.minX + topInset + max(0, skew)
        var topRightX = extent.maxX - topInset + min(0, skew)
        var bottomLeftX = extent.minX + bottomInset - min(0, skew)
        var bottomRightX = extent.maxX - bottomInset - max(0, skew)

        let minGap = width * 0.25
        if topRightX - topLeftX < minGap {
            let cx = (topRightX + topLeftX) * 0.5
            topLeftX = cx - minGap * 0.5
            topRightX = cx + minGap * 0.5
        }
        if bottomRightX - bottomLeftX < minGap {
            let cx = (bottomRightX + bottomLeftX) * 0.5
            bottomLeftX = cx - minGap * 0.5
            bottomRightX = cx + minGap * 0.5
        }

        let topY = extent.maxY - topYOffset
        let bottomY = extent.minY + bottomYOffset

        guard topY - bottomY > height * 0.25 else { return image }

        let filter = CIFilter.perspectiveCorrection()
        filter.inputImage = image
        filter.topLeft = CGPoint(x: topLeftX, y: topY)
        filter.topRight = CGPoint(x: topRightX, y: topY)
        filter.bottomLeft = CGPoint(x: bottomLeftX, y: bottomY)
        filter.bottomRight = CGPoint(x: bottomRightX, y: bottomY)
        return filter.outputImage ?? image
    }

    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        Swift.max(min, Swift.min(max, value))
    }

    private static func rotate(image: UIImage, degrees: Double) -> UIImage? {
        let radians = CGFloat(degrees * .pi / 180)
        let oldSize = image.size
        let rotatedRect = CGRect(origin: .zero, size: oldSize).applying(CGAffineTransform(rotationAngle: radians)).integral
        UIGraphicsBeginImageContextWithOptions(rotatedRect.size, false, image.scale)
        guard let ctx = UIGraphicsGetCurrentContext() else { return image }
        ctx.translateBy(x: rotatedRect.midX, y: rotatedRect.midY)
        ctx.rotate(by: radians)
        image.draw(in: CGRect(x: -oldSize.width / 2, y: -oldSize.height / 2, width: oldSize.width, height: oldSize.height))
        let output = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return output
    }
}

// MARK: - FourPointPerspectiveEditor

struct FourPointPerspectiveEditor: View {
    @Binding var quad: ScanQuad
    let imageSize: CGSize

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Quadrilateral outline
                Path { path in
                    let tl = point(quad.topLeft, in: geo.size)
                    let tr = point(quad.topRight, in: geo.size)
                    let bl = point(quad.bottomLeft, in: geo.size)
                    let br = point(quad.bottomRight, in: geo.size)
                    path.move(to: tl)
                    path.addLine(to: tr)
                    path.addLine(to: br)
                    path.addLine(to: bl)
                    path.closeSubpath()
                }
                .stroke(ShieldTheme.accent.opacity(0.8), style: StrokeStyle(lineWidth: 1.5, dash: [6, 3]))

                // Corner handles
                handle(position: point(quad.topLeft, in: geo.size), label: "↖") { delta in
                    quad.topLeft = clampPoint(CGPoint(x: quad.topLeft.x + delta.x / w, y: quad.topLeft.y + delta.y / h))
                }
                handle(position: point(quad.topRight, in: geo.size), label: "↗") { delta in
                    quad.topRight = clampPoint(CGPoint(x: quad.topRight.x + delta.x / w, y: quad.topRight.y + delta.y / h))
                }
                handle(position: point(quad.bottomLeft, in: geo.size), label: "↙") { delta in
                    quad.bottomLeft = clampPoint(CGPoint(x: quad.bottomLeft.x + delta.x / w, y: quad.bottomLeft.y + delta.y / h))
                }
                handle(position: point(quad.bottomRight, in: geo.size), label: "↘") { delta in
                    quad.bottomRight = clampPoint(CGPoint(x: quad.bottomRight.x + delta.x / w, y: quad.bottomRight.y + delta.y / h))
                }
            }
            .frame(width: w, height: h)
        }
    }

    private func point(_ normalized: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(x: normalized.x * size.width, y: normalized.y * size.height)
    }

    private func clampPoint(_ p: CGPoint) -> CGPoint {
        CGPoint(x: max(0, min(1, p.x)), y: max(0, min(1, p.y)))
    }

    @ViewBuilder
    private func handle(position: CGPoint, label: String, onDrag: @escaping (CGPoint) -> Void) -> some View {
        ZStack {
            Circle()
                .fill(ShieldTheme.accent)
                .frame(width: 26, height: 26)
                .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.black)
        }
        .position(position)
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    onDrag(CGPoint(x: value.translation.width, y: value.translation.height))
                }
        )
    }
}

// MARK: - ScanReviewView

struct ScanReviewView: View {
    @EnvironmentObject var appState: AppState
    let pages: [UIImage]
    var onCancel: () -> Void
    var onConfirm: ([UIImage], Bool) -> Void

    @State private var selectedPage = 0
    @State private var adjustments: [ScanPageAdjustment] = []
    @State private var applying = false
    @State private var selectedPreset: ScanAdjustmentPreset = .document
    @State private var showQuadEditor = false

    var body: some View {
        ZStack {
            ShieldTheme.pageBackground(.dark).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                previewArea
                pageStrip
                controls
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if adjustments.count != pages.count {
                adjustments = Array(repeating: .default, count: pages.count)
            }
        }
    }

    private var header: some View {
        HStack {
            Button(appState.str("capture_cancel")) {
                onCancel()
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(ShieldTheme.textSecondary)

            Spacer()
            Text(appState.str("capture_enhance_title"))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(ShieldTheme.textPrimary)
            Spacer()

            Button(applying ? appState.str("capture_processing") : appState.str("capture_save")) {
                applyAndContinue()
            }
            .disabled(applying)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(ShieldTheme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 12)
    }

    private var previewArea: some View {
        let image = pages[safe: selectedPage] ?? pages.first ?? UIImage()
        let adjustment = adjustments[safe: selectedPage] ?? .default
        // In quad-edit mode show original; otherwise show processed preview
        let preview: UIImage = showQuadEditor ? image : (ScanImageProcessor.apply(image, adjustment: adjustment) ?? image)

        return ZStack(alignment: .topTrailing) {
            GeometryReader { geo in
                let maxH: CGFloat = 260
                let aspect = preview.size.width / max(preview.size.height, 1)
                let frameW = min(geo.size.width, maxH * aspect)
                let frameH = frameW / aspect

                ZStack {
                    Image(uiImage: preview)
                        .resizable()
                        .scaledToFit()
                        .frame(width: frameW, height: frameH)
                        .background(ShieldTheme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // 4-point perspective overlay
                    if showQuadEditor {
                        let currentQuad = Binding<ScanQuad>(
                            get: { adjustments[safe: selectedPage]?.quad ?? .identity },
                            set: { newQuad in
                                if selectedPage < adjustments.count {
                                    adjustments[selectedPage].quad = newQuad
                                }
                            }
                        )
                        FourPointPerspectiveEditor(quad: currentQuad, imageSize: preview.size)
                            .frame(width: frameW, height: frameH)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: maxH, alignment: .center)
            }
            .frame(height: 260)

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(selectedPage + 1)/\(max(1, pages.count))")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ShieldTheme.surface3)
                    .clipShape(Capsule())

                // Quad editor toggle
                Button {
                    if !showQuadEditor, adjustments[safe: selectedPage]?.quad == nil,
                       selectedPage < adjustments.count {
                        adjustments[selectedPage].quad = .identity
                    }
                    withAnimation(.spring(response: 0.25)) { showQuadEditor.toggle() }
                } label: {
                    Image(systemName: showQuadEditor ? "perspective" : "skew")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(showQuadEditor ? .black : ShieldTheme.textPrimary)
                        .frame(width: 28, height: 28)
                        .background(showQuadEditor ? ShieldTheme.accent : ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
            }
            .padding(10)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    private var pageStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(pages.enumerated()), id: \.offset) { idx, image in
                    let preview = ScanImageProcessor.apply(image, adjustment: adjustments[safe: idx] ?? .default) ?? image
                    Button {
                        selectedPage = idx
                    } label: {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 70, height: 92)
                            .clipped()
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedPage == idx ? ShieldTheme.accent : ShieldTheme.surfaceLine, lineWidth: selectedPage == idx ? 2 : 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
    }

    private var controls: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                presetSection
                filterSection
                geometrySection
                cropSection
                imageSection

                HStack(spacing: 8) {
                    Button {
                        resetCurrentPage()
                    } label: {
                        Text(appState.str("capture_reset_page", table: "Capture"))
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(ShieldTheme.surface3)
                            .foregroundColor(ShieldTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        resetAllPages()
                    } label: {
                        Text(appState.str("capture_reset_all", table: "Capture"))
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(ShieldTheme.surface3)
                            .foregroundColor(ShieldTheme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }

                Button {
                    guard let current = adjustments[safe: selectedPage] else { return }
                    adjustments = Array(repeating: current, count: pages.count)
                    AppState.trackEvent("scan_batch_applied", properties: ["pages": String(pages.count)])
                } label: {
                    Text(appState.str("capture_apply_all_pages", table: "Capture"))
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(ShieldTheme.accentDim)
                        .foregroundColor(ShieldTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 26)
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.str("capture_quick_presets"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.textSecondary)

            Picker("", selection: $selectedPreset) {
                ForEach(ScanAdjustmentPreset.allCases) { preset in
                    Text(preset.label(lang: appState.language)).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            Button {
                applyPresetToCurrentPage(selectedPreset)
            } label: {
                Text(appState.str("capture_apply_preset"))
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(ShieldTheme.surface3)
                    .foregroundColor(ShieldTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.str("capture_filters"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.textSecondary)
            Picker("", selection: binding(\.filterPreset)) {
                ForEach(ScanFilterPreset.allCases) { preset in
                    Text(preset.label(lang: appState.language)).tag(preset)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var geometrySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.str("capture_geometry"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.textSecondary)

            // 4-point perspective hint when active
            if showQuadEditor {
                HStack(spacing: 8) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.accent)
                    Text(appState.str("capture_drag_perspective_hint"))
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.textSecondary)
                    Spacer()
                    Button {
                        if selectedPage < adjustments.count {
                            adjustments[selectedPage].quad = .identity
                        }
                    } label: {
                        Text(appState.str("capture_reset"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ShieldTheme.danger)
                    }
                }
                .padding(8)
                .background(ShieldTheme.accentDim)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            sliderRow(
                title: appState.str("capture_straighten"),
                valueText: "\(Int(binding(\.straightenDegrees).wrappedValue))°"
            ) {
                Slider(value: binding(\.straightenDegrees), in: -25...25, step: 1)
            }

            Button {
                detectPerspectiveForCurrentPage()
            } label: {
                Text(appState.str("capture_auto_perspective"))
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(ShieldTheme.surface3)
                    .foregroundColor(ShieldTheme.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(ScaleButtonStyle())

            sliderRow(
                title: appState.str("capture_top_perspective"),
                valueText: percent(binding(\.perspectiveTopInset).wrappedValue)
            ) {
                Slider(value: binding(\.perspectiveTopInset), in: 0...0.3, step: 0.01)
            }

            sliderRow(
                title: appState.str("capture_bottom_perspective"),
                valueText: percent(binding(\.perspectiveBottomInset).wrappedValue)
            ) {
                Slider(value: binding(\.perspectiveBottomInset), in: 0...0.3, step: 0.01)
            }

            sliderRow(
                title: appState.str("capture_horizontal_skew"),
                valueText: signed(binding(\.perspectiveSkew).wrappedValue)
            ) {
                Slider(value: binding(\.perspectiveSkew), in: -0.16...0.16, step: 0.005)
            }

            sliderRow(
                title: appState.str("capture_top_vertical_trim"),
                valueText: percent(binding(\.perspectiveTopYOffset).wrappedValue)
            ) {
                Slider(value: binding(\.perspectiveTopYOffset), in: 0...0.25, step: 0.01)
            }

            sliderRow(
                title: appState.str("capture_bottom_vertical_trim"),
                valueText: percent(binding(\.perspectiveBottomYOffset).wrappedValue)
            ) {
                Slider(value: binding(\.perspectiveBottomYOffset), in: 0...0.25, step: 0.01)
            }

            HStack(spacing: 8) {
                Button {
                    var a = adjustments[selectedPage]
                    a.rotationDegrees -= 90
                    adjustments[selectedPage] = a
                } label: {
                    Text(appState.str("capture_rotate_left"))
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(ShieldTheme.surface3)
                        .foregroundColor(ShieldTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())

                Button {
                    var a = adjustments[selectedPage]
                    a.rotationDegrees += 90
                    adjustments[selectedPage] = a
                } label: {
                    Text(appState.str("capture_rotate_right"))
                        .font(.system(size: 12, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(ShieldTheme.surface3)
                        .foregroundColor(ShieldTheme.textPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private var cropSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.str("capture_crop"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.textSecondary)

            sliderRow(title: appState.str("capture_left"), valueText: percent(binding(\.cropLeft).wrappedValue)) {
                Slider(value: binding(\.cropLeft), in: 0...0.35, step: 0.01)
            }
            sliderRow(title: appState.str("capture_right"), valueText: percent(binding(\.cropRight).wrappedValue)) {
                Slider(value: binding(\.cropRight), in: 0...0.35, step: 0.01)
            }
            sliderRow(title: appState.str("capture_top"), valueText: percent(binding(\.cropTop).wrappedValue)) {
                Slider(value: binding(\.cropTop), in: 0...0.35, step: 0.01)
            }
            sliderRow(title: appState.str("capture_bottom"), valueText: percent(binding(\.cropBottom).wrappedValue)) {
                Slider(value: binding(\.cropBottom), in: 0...0.35, step: 0.01)
            }
        }
    }

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.str("capture_adjustments"))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.textSecondary)

            sliderRow(title: appState.str("capture_brightness"), valueText: signed(binding(\.brightness).wrappedValue)) {
                Slider(value: binding(\.brightness), in: -0.3...0.3, step: 0.01)
            }
            sliderRow(title: appState.str("capture_contrast"), valueText: String(format: "%.2f", binding(\.contrast).wrappedValue)) {
                Slider(value: binding(\.contrast), in: 0.7...1.8, step: 0.01)
            }
            sliderRow(title: appState.str("capture_sharpness"), valueText: String(format: "%.2f", binding(\.sharpness).wrappedValue)) {
                Slider(value: binding(\.sharpness), in: 0...1.5, step: 0.01)
            }
            sliderRow(title: appState.str("capture_noise_reduction"), valueText: String(format: "%.2f", binding(\.noiseReduction).wrappedValue)) {
                Slider(value: binding(\.noiseReduction), in: 0...0.08, step: 0.005)
            }
        }
    }

    @ViewBuilder
    private func sliderRow<Content: View>(title: String, valueText: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Spacer()
                Text(valueText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ShieldTheme.textTertiary)
            }
            content()
        }
        .padding(10)
        .background(ShieldTheme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func applyAndContinue() {
        guard !applying else { return }
        applying = true

        Task {
            var output: [UIImage] = []
            output.reserveCapacity(pages.count)

            for (idx, page) in pages.enumerated() {
                let adjustment = adjustments[safe: idx] ?? .default
                output.append(ScanImageProcessor.apply(page, adjustment: adjustment) ?? page)
            }

            let hasAdjustments = adjustments.contains { $0.hasAdjustments }
            await MainActor.run {
                applying = false
                onConfirm(output, hasAdjustments)
            }
        }
    }

    private func applyPresetToCurrentPage(_ preset: ScanAdjustmentPreset) {
        guard adjustments.indices.contains(selectedPage) else { return }
        let base = preset.adjustment()
        adjustments[selectedPage] = sanitizedCrop(base)
        AppState.trackEvent("scan_adjustment_applied", properties: [
            "mode": "preset",
            "preset": preset.rawValue
        ])
    }

    private func resetCurrentPage() {
        guard adjustments.indices.contains(selectedPage) else { return }
        adjustments[selectedPage] = .default
    }

    private func resetAllPages() {
        adjustments = Array(repeating: .default, count: pages.count)
    }

    private func detectPerspectiveForCurrentPage() {
        guard adjustments.indices.contains(selectedPage) else { return }
        guard let image = pages[safe: selectedPage], let cg = image.cgImage else { return }

        Task {
            guard let detected = detectPerspectiveRect(from: cg) else { return }
            await MainActor.run {
                guard adjustments.indices.contains(selectedPage) else { return }
                var adj = adjustments[selectedPage]
                // Populate slider-based fields
                adj.perspectiveTopInset = detected.topInset
                adj.perspectiveBottomInset = detected.bottomInset
                adj.perspectiveSkew = detected.skew
                adj.perspectiveTopYOffset = detected.topYOffset
                adj.perspectiveBottomYOffset = detected.bottomYOffset
                // Seed the quad editor with the Vision-detected corners so both
                // the sliders and the drag handles start from the same detected rectangle.
                adj.quad = detected.quad
                adjustments[selectedPage] = sanitizedCrop(adj)
                AppState.trackEvent("scan_adjustment_applied", properties: [
                    "mode": "auto_perspective"
                ])
            }
        }
    }

    private struct DetectedPerspective {
        let topInset: Double
        let bottomInset: Double
        let skew: Double
        let topYOffset: Double
        let bottomYOffset: Double
        let quad: ScanQuad
    }

    private func detectPerspectiveRect(from cgImage: CGImage) -> DetectedPerspective? {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.45
        request.minimumSize = 0.25
        request.quadratureTolerance = 35

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        guard let rect = request.results?.first else { return nil }

        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        guard width > 10, height > 10 else { return nil }

        // VNImagePointForNormalizedPoint uses Vision coords (origin bottom-left, Y flipped)
        let tl = VNImagePointForNormalizedPoint(rect.topLeft, Int(width), Int(height))
        let tr = VNImagePointForNormalizedPoint(rect.topRight, Int(width), Int(height))
        let bl = VNImagePointForNormalizedPoint(rect.bottomLeft, Int(width), Int(height))
        let br = VNImagePointForNormalizedPoint(rect.bottomRight, Int(width), Int(height))

        let leftTopInset = max(0, tl.x / width)
        let rightTopInset = max(0, (width - tr.x) / width)
        let leftBottomInset = max(0, bl.x / width)
        let rightBottomInset = max(0, (width - br.x) / width)

        let topInset = clamp((leftTopInset + rightTopInset) * 0.5, min: 0, max: 0.3)
        let bottomInset = clamp((leftBottomInset + rightBottomInset) * 0.5, min: 0, max: 0.3)

        let topMid = (tl.x + tr.x) * 0.5
        let bottomMid = (bl.x + br.x) * 0.5
        let skew = clamp((topMid - bottomMid) / width, min: -0.16, max: 0.16)

        let topY = (tl.y + tr.y) * 0.5
        let bottomY = (bl.y + br.y) * 0.5
        let topYOffset = clamp((height - topY) / height, min: 0, max: 0.25)
        let bottomYOffset = clamp(bottomY / height, min: 0, max: 0.25)

        // Convert Vision image-space points to UIKit normalized (origin top-left, Y down)
        // Vision's VNImagePointForNormalizedPoint returns points with Y measured from bottom
        let quad = ScanQuad(
            topLeft:     CGPoint(x: clamp(tl.x / width, min: 0, max: 1), y: clamp(1.0 - tl.y / height, min: 0, max: 1)),
            topRight:    CGPoint(x: clamp(tr.x / width, min: 0, max: 1), y: clamp(1.0 - tr.y / height, min: 0, max: 1)),
            bottomLeft:  CGPoint(x: clamp(bl.x / width, min: 0, max: 1), y: clamp(1.0 - bl.y / height, min: 0, max: 1)),
            bottomRight: CGPoint(x: clamp(br.x / width, min: 0, max: 1), y: clamp(1.0 - br.y / height, min: 0, max: 1))
        )

        return DetectedPerspective(
            topInset: topInset,
            bottomInset: bottomInset,
            skew: skew,
            topYOffset: topYOffset,
            bottomYOffset: bottomYOffset,
            quad: quad
        )
    }

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> Double {
        Double(Swift.max(min, Swift.min(max, value)))
    }

    private func binding<T>(_ keyPath: WritableKeyPath<ScanPageAdjustment, T>) -> Binding<T> {
        Binding(
            get: { adjustments[safe: selectedPage]?[keyPath: keyPath] ?? ScanPageAdjustment.default[keyPath: keyPath] },
            set: { newValue in
                guard adjustments.indices.contains(selectedPage) else { return }
                var adj = adjustments[selectedPage]
                adj[keyPath: keyPath] = newValue
                adjustments[selectedPage] = sanitizedCrop(adj)
            }
        )
    }

    private func sanitizedCrop(_ adjustment: ScanPageAdjustment) -> ScanPageAdjustment {
        var a = adjustment
        let h = a.cropLeft + a.cropRight
        if h > 0.8 {
            let scale = 0.8 / h
            a.cropLeft *= scale
            a.cropRight *= scale
        }
        let v = a.cropTop + a.cropBottom
        if v > 0.8 {
            let scale = 0.8 / v
            a.cropTop *= scale
            a.cropBottom *= scale
        }
        return a
    }

    private func percent(_ value: Double) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private func signed(_ value: Double) -> String {
        let prefix = value >= 0 ? "+" : ""
        return "\(prefix)\(String(format: "%.2f", value))"
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - OCRService

enum OCRService {
    enum DetectedDocumentType: String {
        case dni              // National ID cards (all countries)
        case passport         // Passport booklets (all countries)
        case drivingLicense   // Driver licenses
        case visa             // Visa labels / stickers
        case residencePermit  // Residence permits, NIE, etc.
        case healthCard       // Health / insurance cards
        case document         // Generic fallback
    }

    enum OCRRiskLevel: String {
        case low
        case medium
        case high
    }

    // Base language set used for initial pass (covers ~60 % of world documents).
    private static let baseLanguages = ["es-ES", "en-US", "fr-FR", "de-DE", "it-IT", "pt-PT"]

    // Extended languages added on second pass when country is identified.
    // Vision-supported locale identifiers as of iOS 17.
    private static func languagesForCountry(_ country: String?) -> [String] {
        switch country?.uppercased() {
        // Already in base — no second pass needed
        case "ESP", "MEX", "ARG", "COL", "CHL", "PER", "ECU", "VEN", "BOL", "PRY", "URY",
             "USA", "GBR", "CAN", "AUS", "NZL", "IRL", "ZAF",
             "FRA", "BEL", "CHE", "LUX", "MCO",
             "DEU", "AUT", "LIE",
             "ITA", "SMR", "VAT",
             "PRT", "BRA", "AGO", "MOZ", "CPV":
            return []
        // Dutch
        case "NLD", "SUR":
            return ["nl-NL"]
        // Polish
        case "POL":
            return ["pl-PL"]
        // Russian / Cyrillic
        case "RUS", "BLR", "KAZ", "KGZ", "TJK", "UZB":
            return ["ru-RU"]
        // Ukrainian
        case "UKR":
            return ["uk-UA"]
        // Turkish
        case "TUR":
            return ["tr-TR"]
        // Greek
        case "GRC", "CYP":
            return ["el-GR"]
        // Swedish
        case "SWE":
            return ["sv-SE"]
        // Norwegian
        case "NOR":
            return ["nb-NO"]
        // Danish
        case "DNK":
            return ["da-DK"]
        // Finnish
        case "FIN":
            return ["fi-FI"]
        // Czech
        case "CZE":
            return ["cs-CZ"]
        // Slovak
        case "SVK":
            return ["sk-SK"]
        // Hungarian
        case "HUN":
            return ["hu-HU"]
        // Romanian
        case "ROU":
            return ["ro-RO"]
        // Bulgarian
        case "BGR":
            return ["bg-BG"]
        // Croatian / Serbian / Bosnian (Latin)
        case "HRV", "SRB", "BIH":
            return ["hr-HR"]
        // Simplified Chinese
        case "CHN", "SGP":
            return ["zh-Hans"]
        // Traditional Chinese
        case "TWN", "HKG", "MAC":
            return ["zh-Hant"]
        // Japanese
        case "JPN":
            return ["ja-JP"]
        // Korean
        case "KOR":
            return ["ko-KR"]
        // Arabic
        case "SAU", "ARE", "QAT", "KWT", "BHR", "OMN", "JOR", "LBN", "SYR", "IRQ",
             "EGY", "LBY", "TUN", "DZA", "MAR", "SDN", "YEM":
            return ["ar-SA"]
        // Hebrew
        case "ISR":
            return ["he-IL"]
        // Hindi / Devanagari
        case "IND", "NPL":
            return ["hi-IN"]
        // Thai
        case "THA":
            return ["th-TH"]
        // Vietnamese
        case "VNM":
            return ["vi-VN"]
        // Indonesian / Malay
        case "IDN", "MYS", "BRN":
            return ["id-ID"]
        // Filipino / Tagalog (use English as best available)
        case "PHL":
            return ["en-PH"]
        default:
            return []
        }
    }

    struct TextObservation {
        let text: String
        /// Normalized rect in UIKit coordinates (origin top-left, 0..1).
        let boundingRect: CGRect
    }

    static func recognizeText(in image: UIImage, extraLanguages: [String] = []) async -> [String] {
        await recognizeTextWithObservations(in: image, extraLanguages: extraLanguages).map(\.text)
    }

    static func recognizeTextWithObservations(
        in image: UIImage,
        extraLanguages: [String] = []
    ) async -> [TextObservation] {
        guard let cgImage = image.cgImage else { return [] }
        let languages: [String] = {
            var langs = baseLanguages
            for lang in extraLanguages where !langs.contains(lang) {
                langs.insert(lang, at: 0)
            }
            return langs
        }()

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, _ in
                let obs = req.results as? [VNRecognizedTextObservation] ?? []
                let results: [TextObservation] = obs.compactMap { ob in
                    guard let text = ob.topCandidates(1).first?.string else { return nil }
                    // Vision: origin bottom-left, Y up → convert to UIKit top-left, Y down
                    let vb = ob.boundingBox
                    let uiRect = CGRect(x: vb.origin.x,
                                       y: 1.0 - vb.origin.y - vb.height,
                                       width: vb.width,
                                       height: vb.height)
                    return TextObservation(text: text, boundingRect: uiRect)
                }
                continuation.resume(returning: results)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = languages

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    static func extractFields(from lines: [String]) -> DocumentFields {
        let strictKYC = UserDefaults.standard.bool(forKey: "shield.ocr.strictKYC")
        let parsedMRZ = parseMRZ(from: lines, strictKYC: strictKYC)
        var fieldConfidence: [String: Double] = [:]

        var docNum = ""
        var fullName = ""
        var dob = ""
        var expires = ""
        var nationality = ""
        var sex = ""
        var address = ""
        var mrz: String? = nil
        var mrzValid: Bool? = nil
        var mrzFormat: String? = nil

        if let parsedMRZ {
            docNum = parsedMRZ.documentNumber
            fullName = parsedMRZ.fullName
            dob = parsedMRZ.dateOfBirth
            expires = parsedMRZ.expires
            nationality = parsedMRZ.nationality
            sex = parsedMRZ.sex
            mrz = parsedMRZ.rawMRZ
            mrzValid = parsedMRZ.isCheckDigitValid
            mrzFormat = parsedMRZ.format
            let baseConfidence = parsedMRZ.isCheckDigitValid ? 0.98 : 0.78
            fieldConfidence["documentNumber"] = baseConfidence
            fieldConfidence["fullName"] = baseConfidence
            fieldConfidence["dateOfBirth"] = baseConfidence
            fieldConfidence["expires"] = baseConfidence
            fieldConfidence["nationality"] = baseConfidence
            fieldConfidence["sex"] = baseConfidence
        }

        // Date patterns: dd/mm/yyyy, dd.mm.yyyy, dd MMM yyyy
        if dob.isEmpty || expires.isEmpty {
            let datePattern = "\\b(\\d{1,2}[/.]\\d{1,2}[/.]\\d{2,4}|\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{2,4})\\b"
            let dateRegex = try? NSRegularExpression(pattern: datePattern, options: .caseInsensitive)
            var dates: [String] = []
            for line in lines {
                let range = NSRange(line.startIndex..., in: line)
                let matches = dateRegex?.matches(in: line, range: range) ?? []
                for match in matches {
                    if let r = Range(match.range, in: line) {
                        dates.append(String(line[r]))
                    }
                }
            }
            if dob.isEmpty, dates.count >= 1 { dob = dates[0] }
            if expires.isEmpty, dates.count >= 2 { expires = dates[1] }
            if fieldConfidence["dateOfBirth"] == nil, !dob.isEmpty { fieldConfidence["dateOfBirth"] = 0.62 }
            if fieldConfidence["expires"] == nil, !expires.isEmpty { fieldConfidence["expires"] = 0.62 }
        }

        // Name: all-caps lines, no digits, length 5-60
        if fullName.isEmpty {
            let nameLines = lines.filter { l in
                let stripped = l.trimmingCharacters(in: .whitespaces)
                guard stripped.count >= 5, stripped.count <= 60 else { return false }
                guard !stripped.contains("<"), !stripped.contains("/") else { return false }
                let upper = stripped.uppercased()
                return upper == stripped && stripped.rangeOfCharacter(from: .decimalDigits) == nil
            }
            if let first = nameLines.first { fullName = first }
            if fieldConfidence["fullName"] == nil, !fullName.isEmpty { fieldConfidence["fullName"] = 0.58 }
        }

        // Doc number: 8-16 alphanumeric chars
        if docNum.isEmpty {
            let docPattern = "\\b([A-Z0-9]{7,16})\\b"
            let docRegex = try? NSRegularExpression(pattern: docPattern)
            for line in lines {
                let range = NSRange(line.startIndex..., in: line)
                if let match = docRegex?.firstMatch(in: line, range: range),
                   let r = Range(match.range, in: line) {
                    let candidate = String(line[r])
                    // Must contain both letters and digits to be likely doc number
                    let hasLetters = candidate.rangeOfCharacter(from: .letters) != nil
                    let hasDigits = candidate.rangeOfCharacter(from: .decimalDigits) != nil
                    if hasLetters && hasDigits && candidate.count >= 8 {
                        docNum = candidate
                        break
                    }
                }
            }
            if fieldConfidence["documentNumber"] == nil, !docNum.isEmpty { fieldConfidence["documentNumber"] = 0.6 }
        }

        // Address: lines with digits + street keywords
        let addrPattern = "\\d+.*\\b(CALLE|C/|AVE|AVENUE|ROAD|RD|STREET|ST|LANE|LN|DR|DRIVE|BLVD|C\\.|CL\\.)\\b"
        let addrRegex = try? NSRegularExpression(pattern: addrPattern, options: .caseInsensitive)
        for line in lines {
            let range = NSRange(line.startIndex..., in: line)
            if addrRegex?.firstMatch(in: line, range: range) != nil {
                address = line
                break
            }
        }
        if !address.isEmpty { fieldConfidence["address"] = 0.52 }

        // Country-specific normalization (ES DNI/NIE, MX CURP)
        if let normalizedSpanish = normalizeSpanishID(from: lines), !normalizedSpanish.value.isEmpty {
            docNum = normalizedSpanish.value
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, normalizedSpanish.confidence)
            if nationality.isEmpty { nationality = "ESP" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.86)
        }

        if let curp = extractCURP(from: lines), !curp.isEmpty {
            if docNum.isEmpty { docNum = curp }
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.84)
            if nationality.isEmpty { nationality = "MEX" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.84)
        }

        // --- International extractors (run after MRZ/Spanish/CURP) ---

        // Brazilian CPF: 000.000.000-00 or 00000000000 (11 digits)
        if let cpf = extractBrazilianCPF(from: lines), !cpf.isEmpty {
            if docNum.isEmpty { docNum = cpf }
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.88)
            if nationality.isEmpty { nationality = "BRA" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.88)
        }

        // Chilean RUT: 12.345.678-9 or 12345678-9
        if let rut = extractChileanRUT(from: lines), !rut.isEmpty {
            if docNum.isEmpty { docNum = rut }
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.86)
            if nationality.isEmpty { nationality = "CHL" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.86)
        }

        // Indian Aadhaar: 12-digit XXXX XXXX XXXX
        if let aadhaar = extractAadhaar(from: lines), !aadhaar.isEmpty {
            if docNum.isEmpty { docNum = aadhaar }
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.90)
            if nationality.isEmpty { nationality = "IND" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.90)
        }

        // Indian PAN: AAAAA9999A (10-char alphanumeric with specific structure)
        if docNum.isEmpty, let pan = extractIndianPAN(from: lines), !pan.isEmpty {
            docNum = pan
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.88)
            if nationality.isEmpty { nationality = "IND" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.88)
        }

        // UK National Insurance Number: AA 99 99 99 A
        if docNum.isEmpty, let nino = extractUKNINO(from: lines), !nino.isEmpty {
            docNum = nino
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.87)
            if nationality.isEmpty { nationality = "GBR" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.87)
        }

        // German Personalausweis: T22000129 (1 letter + 8 alphanumeric)
        if docNum.isEmpty, let deId = extractGermanID(from: lines), !deId.isEmpty {
            docNum = deId
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.82)
            if nationality.isEmpty { nationality = "DEU" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.82)
        }

        // French NIR (Numéro INSEE): 1 85 12 75 108 111 88
        if docNum.isEmpty, let nir = extractFrenchNIR(from: lines), !nir.isEmpty {
            docNum = nir
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.82)
            if nationality.isEmpty { nationality = "FRA" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.82)
        }

        // Argentine DNI: 8-digit number (all numeric — must not clash with other patterns)
        if docNum.isEmpty, let argDNI = extractArgentineDNI(from: lines), !argDNI.isEmpty {
            docNum = argDNI
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.78)
            if nationality.isEmpty { nationality = "ARG" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.78)
        }

        // Colombian cédula: 6–10 digits preceded by "CC" or cedula keyword
        if docNum.isEmpty, let cc = extractColombianCC(from: lines), !cc.isEmpty {
            docNum = cc
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.80)
            if nationality.isEmpty { nationality = "COL" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.80)
        }

        // Multilingual address keywords (French, German, Italian, Portuguese, Arabic)
        if address.isEmpty {
            address = extractInternationalAddress(from: lines) ?? ""
            if !address.isEmpty { fieldConfidence["address"] = 0.52 }
        }

        return DocumentFields(
            documentNumber: docNum,
            fullName: fullName,
            dateOfBirth: dob,
            nationality: nationality,
            expires: expires,
            sex: sex,
            address: address,
            issued: nil,
            mrz: mrz,
            ocrDocumentType: nil,
            ocrFullText: nil,
            ocrPageTexts: nil,
            ocrMRZValid: mrzValid,
            ocrMRZFormat: mrzFormat,
            ocrFieldConfidence: fieldConfidence.isEmpty ? nil : fieldConfidence,
            ocrDetectedCountry: nil,
            ocrRiskLevel: nil,
            ocrLowConfidenceFields: nil
        )
    }

    static func recognizeText(in images: [UIImage], extraLanguages: [String] = []) async -> [String] {
        guard !images.isEmpty else { return [] }
        var merged: [String] = []
        for image in images {
            let pageLines = await recognizeText(in: image, extraLanguages: extraLanguages)
            merged.append(contentsOf: pageLines)
        }
        return merged
    }

    static func recognizeTextByPage(in images: [UIImage], extraLanguages: [String] = []) async -> [[String]] {
        guard !images.isEmpty else { return [] }
        // Run pages concurrently for large multi-page documents.
        return await withTaskGroup(of: (Int, [String]).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let lines = await recognizeText(in: image, extraLanguages: extraLanguages)
                    return (index, lines)
                }
            }
            var results = [(Int, [String])]()
            results.reserveCapacity(images.count)
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    // Two-pass OCR returning full observations (text + bounding box).
    static func recognizeObservationsByPageAdaptive(in images: [UIImage]) async -> [[TextObservation]] {
        let firstPass = await recognizeObservationsByPage(in: images)
        let allLines = firstPass.flatMap { $0 }.map(\.text)
        let country = detectCountryHint(from: allLines)
        let extra = languagesForCountry(country)
        guard !extra.isEmpty else { return firstPass }
        return await recognizeObservationsByPage(in: images, extraLanguages: extra)
    }

    // Two-pass OCR returning text strings only.
    static func recognizeTextByPageAdaptive(in images: [UIImage]) async -> [[String]] {
        let obs = await recognizeObservationsByPageAdaptive(in: images)
        return obs.map { $0.map(\.text) }
    }

    static func recognizeObservationsByPage(
        in images: [UIImage],
        extraLanguages: [String] = []
    ) async -> [[TextObservation]] {
        guard !images.isEmpty else { return [] }
        return await withTaskGroup(of: (Int, [TextObservation]).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let obs = await recognizeTextWithObservations(in: image, extraLanguages: extraLanguages)
                    return (index, obs)
                }
            }
            var results = [(Int, [TextObservation])]()
            results.reserveCapacity(images.count)
            for await result in group { results.append(result) }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private static func detectCountryHint(from lines: [String]) -> String? {
        let combined = lines.joined(separator: " ").uppercased()
        // Ordered: most specific patterns first to avoid false matches.
        let patterns: [(pattern: String, country: String)] = [
            // East Asia (non-Latin scripts first — unambiguous)
            ("中华人民共和国|中华人民|居民身份证", "CHN"),
            ("中華民國|臺灣|台湾", "TWN"),
            ("日本国|日本国旅券|JAPAN", "JPN"),
            ("대한민국|REPUBLIC OF KOREA", "KOR"),
            // South / Southeast Asia
            ("INDIA|AADHAAR|आधार|ELECTION COMMISSION OF INDIA|REPUBLIC OF INDIA", "IND"),
            ("THAILAND|ราชอาณาจักรไทย", "THA"),
            ("VIET NAM|VIỆT NAM|CỘNG HÒA XÃ HỘI", "VNM"),
            ("INDONESIA|REPUBLIK INDONESIA|KTP", "IDN"),
            ("MALAYSIA|MYKAD|MYKID", "MYS"),
            ("PHILIPPINES|PILIPINAS|REPUBLIKA NG", "PHL"),
            // Middle East / North Africa
            ("المملكة العربية السعودية|KINGDOM OF SAUDI|SAUDI ARABIA", "SAU"),
            ("UNITED ARAB EMIRATES|الإمارات العربية|EMIRATES", "ARE"),
            ("دولة قطر|STATE OF QATAR|QATAR", "QAT"),
            ("مملكة البحرين|KINGDOM OF BAHRAIN|BAHRAIN", "BHR"),
            ("سلطنة عُمان|SULTANATE OF OMAN|OMAN", "OMN"),
            ("دولة الكويت|STATE OF KUWAIT|KUWAIT", "KWT"),
            ("المملكة المغربية|KINGDOM OF MOROCCO|MAROC|MOROCCO", "MAR"),
            ("الجمهورية التونسية|TUNISIE|TUNISIA", "TUN"),
            ("الجمهورية الجزائرية|ALGERIE|ALGERIA", "DZA"),
            ("جمهورية مصر العربية|EGYPT|EGYPTE", "EGY"),
            ("إسرائيל|ISRAEL|מדינת ישראל", "ISR"),
            ("جمهورية العراق|IRAQ", "IRQ"),
            ("الجمهورية اللبنانية|LIBAN|LEBANON", "LBN"),
            ("تركيا|TÜRKIYE|TURKEY|TÜRK", "TUR"),
            // Eastern Europe / CIS
            ("РОССИЙСКАЯ ФЕДЕРАЦИЯ|РОССИЯ|RUSSIAN FEDERATION", "RUS"),
            ("УКРАЇНА|UKRAINE", "UKR"),
            ("БЕЛАРУСЬ|REPUBLIC OF BELARUS|BELARUS", "BLR"),
            ("КАЗАХСТАН|KAZAKHSTAN|ҚАЗАҚСТАН", "KAZ"),
            // Central / Eastern Europe
            ("RZECZPOSPOLITA POLSKA|POLSKA|POLAND", "POL"),
            ("ČESKÁ REPUBLIKA|CZECH REPUBLIC|CZECHIA", "CZE"),
            ("SLOVENSKÁ REPUBLIKA|SLOVAK REPUBLIC|SLOVAKIA", "SVK"),
            ("MAGYARORSZÁG|HUNGARY", "HUN"),
            ("ROMÂNIA|ROMANIA", "ROU"),
            ("БЪЛГАРИЯ|REPUBLIC OF BULGARIA|BULGARIA", "BGR"),
            ("HRVATSKA|REPUBLIC OF CROATIA|CROATIA", "HRV"),
            ("SRBIJA|REPUBLIC OF SERBIA|SERBIA", "SRB"),
            // Northern Europe
            ("SVERIGE|SWEDEN|KUNGARIKET SVERIGE", "SWE"),
            ("NOREG|NORGE|NORWAY|KINGDOM OF NORWAY", "NOR"),
            ("DANMARK|DENMARK|KONGERIGET", "DNK"),
            ("SUOMI|FINLAND", "FIN"),
            // Western Europe
            ("NEDERLAND|KONINKRIJK|NETHERLANDS", "NLD"),
            ("BELGIQUE|BELGIË|BELGIUM|BELGIEN", "BEL"),
            ("SCHWEIZ|SUISSE|SVIZZERA|SWITZERLAND", "CHE"),
            ("ÖSTERREICH|AUSTRIA|REPUBLIC OF AUSTRIA", "AUT"),
            // Latin America
            ("REPÚBLICA ARGENTINA|ARGENTINA", "ARG"),
            ("REPÚBLICA DE COLOMBIA|COLOMBIA", "COL"),
            ("REPÚBLICA DE CHILE|CHILE", "CHL"),
            ("REPÚBLICA DEL PERÚ|PERÚ|PERU", "PER"),
            ("REPÚBLICA FEDERATIVA DO BRASIL|BRASIL|BRAZIL", "BRA"),
            ("REPÚBLICA PORTUGUESA|PORTUGAL", "PRT"),
            // Already in base — still emit for normalizedCountryCode
            ("REINO DE ESPAÑA|ESPAÑA|SPAIN|DNI|DOCUMENTO NACIONAL DE IDENTIDAD", "ESP"),
            ("ITALIA|ITALIANA|CARTA D.IDENTIT|REPUBBLICA ITALIANA", "ITA"),
            ("REPUBLIQUE FRANÇAISE|FRANCE|FRANCAISE", "FRA"),
            ("BUNDESREPUBLIK DEUTSCHLAND|GERMANY|DEUTSCHLAND", "DEU"),
            ("UNITED KINGDOM|GREAT BRITAIN|UK PASSPORT|DRIVING LICENCE|DRIVER", "GBR"),
            ("UNITED STATES|USA|UNITED STATES OF AMERICA", "USA"),
            ("CANADA|CANADIEN|CANADIENNE", "CAN"),
            ("AUSTRALIA|COMMONWEALTH OF AUSTRALIA", "AUS"),
        ]
        for entry in patterns {
            if combined.range(of: entry.pattern, options: [.regularExpression]) != nil {
                return entry.country
            }
        }
        return nil
    }

    static func detectDocumentType(from lines: [String]) -> DetectedDocumentType {
        let strictKYC = UserDefaults.standard.bool(forKey: "shield.ocr.strictKYC")
        if let parsed = parseMRZ(from: lines, strictKYC: strictKYC) {
            switch parsed.documentCode {
            case "P", "PM", "PN":             return .passport
            case "V", "VF", "VE", "VI", "VT": return .visa
            case "I", "ID", "A", "C", "AC":   return .dni
            case "R", "RI":                    return .residencePermit
            default: break
            }
        }

        guard !lines.isEmpty else { return .document }
        let compact = lines.map { $0.uppercased() }
        let combined = compact.joined(separator: "\n")
        let mrzLines = compact.filter { $0.contains("<") && $0.count >= 20 }

        // Visa
        if mrzLines.contains(where: { $0.hasPrefix("V<") || $0.hasPrefix("V ") }) ||
            combined.contains("VISA") || combined.contains("VISUM") || combined.contains("VISAS") {
            return .visa
        }

        // Passport
        if mrzLines.contains(where: { $0.hasPrefix("P<") || $0.hasPrefix("PM<") || $0.hasPrefix("PN<") }) ||
            combined.contains("PASSPORT") || combined.contains("PASSEPORT") ||
            combined.contains("PASAPORTE") || combined.contains("REISEPASS") ||
            combined.contains("PASSAPORTO") || combined.contains("PASPOORT") ||
            combined.contains("PASAPORT") || combined.contains("ПАСПОРТ") ||
            combined.contains("护照") || combined.contains("旅券") || combined.contains("여권") ||
            combined.contains("पासपोर्ट") {
            return .passport
        }

        // Driving license — checked before generic ID
        if combined.contains("DRIVING LICENCE") || combined.contains("DRIVER") ||
            combined.contains("PERMIS DE CONDUIRE") || combined.contains("FÜHRERSCHEIN") ||
            combined.contains("PATENTE") || combined.contains("LICENCIA DE CONDUCIR") ||
            combined.contains("RIJBEWIJS") || combined.contains("PRAWO JAZDY") ||
            combined.contains("CARTA DE CONDUÇÃO") || combined.contains("CARTEIRA DE HABILITAÇÃO") ||
            combined.contains("ВОДИТЕЛЬСКОЕ УДОСТОВЕРЕНИЕ") || combined.contains("AJOKORTTI") ||
            combined.contains("KØREKORT") || combined.contains("KÖRKORT") ||
            combined.contains("FØRERBEVIS") || combined.contains("PRAVOVOŽNJE") ||
            combined.contains("运动驾驶证") || combined.contains("驾驶证") ||
            combined.contains("DRIVER'S LICENSE") || combined.contains("OPERATOR LICENSE") {
            return .drivingLicense
        }

        // Residence permit / NIE / long-stay visa
        if combined.contains("RESIDENCE PERMIT") || combined.contains("PERMIS DE RÉSIDENCE") ||
            combined.contains("AUFENTHALTSTITEL") || combined.contains("PERMESSO DI SOGGIORNO") ||
            combined.contains("VERBLIJFSVERGUNNING") || combined.contains("PERMISO DE RESIDENCIA") ||
            combined.contains("AUTORIZACIÓN DE RESIDENCIA") ||
            combined.contains("NIE") || combined.contains("NÚMERO DE IDENTIDAD DE EXTRANJERO") ||
            combined.contains("TITRE DE SÉJOUR") || combined.contains("CARTA DI SOGGIORNO") ||
            combined.contains("BIOMETRIC RESIDENCE") || combined.contains("BRP") ||
            combined.contains("GREEN CARD") || combined.contains("PERMANENT RESIDENT") ||
            combined.contains("ЗЕЛЕНАЯ КАРТА") || combined.contains("ВНЖ") {
            return .residencePermit
        }

        // Health / insurance cards
        if combined.contains("HEALTH CARD") || combined.contains("INSURANCE CARD") ||
            combined.contains("CARTE VITALE") || combined.contains("CARTE D'ASSURANCE") ||
            combined.contains("KRANKENVERSICHERUNG") || combined.contains("GESUNDHEITSKARTE") ||
            combined.contains("EHIC") || combined.contains("GHIC") ||
            combined.contains("EUROPEAN HEALTH INSURANCE") ||
            combined.contains("TARJETA SANITARIA") || combined.contains("SIP") ||
            combined.contains("TESSERA SANITARIA") || combined.contains("CARTÃO DE SAÚDE") {
            return .healthCard
        }

        // National identity cards
        if mrzLines.contains(where: { $0.hasPrefix("ID") || $0.hasPrefix("I<") || $0.hasPrefix("A<") || $0.hasPrefix("C<") }) ||
            combined.contains("NATIONAL IDENTITY") || combined.contains("IDENTITY CARD") ||
            combined.contains("DOCUMENTO NACIONAL") || combined.contains("CARTA D'IDENTIT") ||
            combined.contains("PERSONALAUSWEIS") || combined.contains("CARTE NATIONALE D'IDENTIT") ||
            combined.contains("IDENTITEITSKAART") || combined.contains("DOWÓD OSOBISTY") ||
            combined.contains("SZEMÉLYIGAZOLVÁNY") || combined.contains("BULETIN DE IDENTITATE") ||
            combined.contains("CEDULA") || combined.contains("CÉDULA") ||
            combined.contains("DOCUMENTO DE IDENTIDAD") || combined.contains("TARJETA DE IDENTIDAD") ||
            combined.contains("CARTÃO DE CIDADÃO") || combined.contains("BILHETE DE IDENTIDADE") ||
            combined.contains("DNI") || combined.contains("NIF") ||
            combined.contains("NATIONAL ID") || combined.contains("NATL ID") ||
            combined.contains("身份证") || combined.contains("주민등록증") ||
            combined.contains("AADHAR") || combined.contains("AADHAAR") ||
            combined.contains("VOTER ID") || combined.contains("ELECTION COMMISSION") {
            return .dni
        }

        return .document
    }

    static func minimumConfidenceThreshold() -> Double {
        let index = UserDefaults.standard.integer(forKey: "shield.ocr.minConfidence")
        switch index {
        case 0: return 0.70
        case 1: return 0.80
        case 2: return 0.90
        default: return 0.80
        }
    }

    static func assessRisk(fields: DocumentFields, detectedType: DetectedDocumentType, threshold: Double) -> (level: OCRRiskLevel, lowFields: [String]) {
        let confidence = fields.ocrFieldConfidence ?? [:]
        let criticalKeys: [String]
        switch detectedType {
        case .passport, .visa:
            criticalKeys = ["documentNumber", "fullName", "dateOfBirth", "expires"]
        case .dni, .residencePermit:
            criticalKeys = ["documentNumber", "fullName", "dateOfBirth", "expires"]
        case .drivingLicense:
            criticalKeys = ["documentNumber", "fullName", "dateOfBirth"]
        case .healthCard, .document:
            criticalKeys = ["documentNumber", "fullName"]
        }

        let lowFields = criticalKeys.filter { key in
            let value = confidence[key] ?? 0
            return value < threshold
        }

        if lowFields.isEmpty {
            return (.low, [])
        } else if lowFields.count >= max(2, criticalKeys.count / 2) {
            return (.high, lowFields)
        } else {
            return (.medium, lowFields)
        }
    }

    private struct ParsedMRZ {
        let format: String
        let documentCode: String
        let documentNumber: String
        let fullName: String
        let dateOfBirth: String
        let expires: String
        let nationality: String
        let sex: String
        let rawMRZ: String
        let isCheckDigitValid: Bool
    }

    private static func parseMRZ(from lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        let candidates = normalizedMRZLines(lines)
        guard !candidates.isEmpty else { return nil }

        if let parsed = parseTD3(lines: candidates, strictKYC: strictKYC)   { return parsed }
        if let parsed = parseTD1(lines: candidates, strictKYC: strictKYC)   { return parsed }
        if let parsed = parseTD2(lines: candidates, strictKYC: strictKYC)   { return parsed }
        if let parsed = parseMRVA(lines: candidates, strictKYC: strictKYC)  { return parsed }
        if let parsed = parseMRVB(lines: candidates, strictKYC: strictKYC)  { return parsed }
        return nil
    }

    // TD2 — 2 lines × 36 chars (some official travel docs, older EU IDs)
    private static func parseTD2(lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        guard lines.count >= 2 else { return nil }
        for i in 0..<(lines.count - 1) {
            var line1 = lines[i]
            var line2 = lines[i + 1]
            guard line1.count >= 36, line2.count >= 36 else { continue }
            // Accepted document codes for TD2: I, A, C (ID cards in TD2 format) or P (some states)
            guard let firstTwo = line1.first.map(String.init), firstTwo != "V" else { continue }
            guard !line1.hasPrefix("P<") else { continue } // TD3 handles P<
            line1 = String(line1.prefix(36))
            line2 = String(line2.prefix(36))

            let documentCode = cleanField(mrzSlice(line1, 0, 2))
            let docNumber = cleanField(mrzSlice(line2, 0, 9))
            let nationality = cleanField(mrzSlice(line2, 10, 3))
            let dob = mrzSlice(line2, 13, 6)
            let sex = cleanField(mrzSlice(line2, 20, 1))
            let expires = mrzSlice(line2, 21, 6)
            let nameField = mrzSlice(line1, 5, 31)
            let fullName = parseMRZName(nameField)

            let checkDoc = validateMRZCheckDigit(data: mrzSlice(line2, 0, 9), checkDigit: mrzSlice(line2, 9, 1))
            let checkDob = validateMRZCheckDigit(data: mrzSlice(line2, 13, 6), checkDigit: mrzSlice(line2, 19, 1))
            let checkExp = validateMRZCheckDigit(data: mrzSlice(line2, 21, 6), checkDigit: mrzSlice(line2, 27, 1))
            let allValid = checkDoc && checkDob && checkExp

            if strictKYC && !allValid { continue }
            // Require at least one valid check digit to avoid false TD2 matches on garbled lines
            guard checkDoc || checkDob else { continue }

            return ParsedMRZ(
                format: "TD2",
                documentCode: documentCode,
                documentNumber: docNumber,
                fullName: fullName,
                dateOfBirth: normalizeMRZDate(dob),
                expires: normalizeMRZDate(expires),
                nationality: nationality,
                sex: sex,
                rawMRZ: line1 + "\n" + line2,
                isCheckDigitValid: allValid
            )
        }
        return nil
    }

    // MRV-A — 2 lines × 44 chars, visa label format A (large visa sticker)
    private static func parseMRVA(lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        guard lines.count >= 2 else { return nil }
        for i in 0..<(lines.count - 1) {
            var line1 = lines[i]
            var line2 = lines[i + 1]
            guard line1.hasPrefix("V<") || line1.hasPrefix("V ") else { continue }
            guard line1.count >= 44, line2.count >= 44 else { continue }
            line1 = String(line1.prefix(44))
            line2 = String(line2.prefix(44))

            let docNumber = cleanField(mrzSlice(line2, 0, 9))
            let nationality = cleanField(mrzSlice(line2, 10, 3))
            let dob = mrzSlice(line2, 13, 6)
            let sex = cleanField(mrzSlice(line2, 20, 1))
            let expires = mrzSlice(line2, 21, 6)
            let nameField = mrzSlice(line1, 5, 39)
            let fullName = parseMRZName(nameField)

            let checkDoc = validateMRZCheckDigit(data: mrzSlice(line2, 0, 9), checkDigit: mrzSlice(line2, 9, 1))
            let checkDob = validateMRZCheckDigit(data: mrzSlice(line2, 13, 6), checkDigit: mrzSlice(line2, 19, 1))
            let checkExp = validateMRZCheckDigit(data: mrzSlice(line2, 21, 6), checkDigit: mrzSlice(line2, 27, 1))
            let allValid = checkDoc && checkDob && checkExp
            if strictKYC && !allValid { continue }
            guard checkDoc else { continue }

            return ParsedMRZ(
                format: "MRV-A",
                documentCode: "V",
                documentNumber: docNumber,
                fullName: fullName,
                dateOfBirth: normalizeMRZDate(dob),
                expires: normalizeMRZDate(expires),
                nationality: nationality,
                sex: sex,
                rawMRZ: line1 + "\n" + line2,
                isCheckDigitValid: allValid
            )
        }
        return nil
    }

    // MRV-B — 2 lines × 36 chars, visa label format B (small visa sticker)
    private static func parseMRVB(lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        guard lines.count >= 2 else { return nil }
        for i in 0..<(lines.count - 1) {
            var line1 = lines[i]
            var line2 = lines[i + 1]
            guard line1.hasPrefix("V<") || line1.hasPrefix("V ") else { continue }
            guard line1.count >= 36, line1.count < 44 else { continue } // MRV-B is 36, not 44
            guard line2.count >= 36 else { continue }
            line1 = String(line1.prefix(36))
            line2 = String(line2.prefix(36))

            let docNumber = cleanField(mrzSlice(line2, 0, 9))
            let nationality = cleanField(mrzSlice(line2, 10, 3))
            let dob = mrzSlice(line2, 13, 6)
            let sex = cleanField(mrzSlice(line2, 20, 1))
            let expires = mrzSlice(line2, 21, 6)
            let nameField = mrzSlice(line1, 5, 31)
            let fullName = parseMRZName(nameField)

            let checkDoc = validateMRZCheckDigit(data: mrzSlice(line2, 0, 9), checkDigit: mrzSlice(line2, 9, 1))
            let checkDob = validateMRZCheckDigit(data: mrzSlice(line2, 13, 6), checkDigit: mrzSlice(line2, 19, 1))
            let checkExp = validateMRZCheckDigit(data: mrzSlice(line2, 21, 6), checkDigit: mrzSlice(line2, 27, 1))
            let allValid = checkDoc && checkDob && checkExp
            if strictKYC && !allValid { continue }
            guard checkDoc else { continue }

            return ParsedMRZ(
                format: "MRV-B",
                documentCode: "V",
                documentNumber: docNumber,
                fullName: fullName,
                dateOfBirth: normalizeMRZDate(dob),
                expires: normalizeMRZDate(expires),
                nationality: nationality,
                sex: sex,
                rawMRZ: line1 + "\n" + line2,
                isCheckDigitValid: allValid
            )
        }
        return nil
    }

    private static func normalizedMRZLines(_ lines: [String]) -> [String] {
        lines
            .map { raw in
                raw
                    .uppercased()
                    .replacingOccurrences(of: " ", with: "")
                    .replacingOccurrences(of: "\t", with: "")
                    .filter { $0 == "<" || $0.isNumber || ($0 >= "A" && $0 <= "Z") }
            }
            .filter { $0.count >= 20 && $0.contains("<") }
    }

    private static func parseTD3(lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        guard lines.count >= 2 else { return nil }
        for i in 0..<(lines.count - 1) {
            var line1 = lines[i]
            var line2 = lines[i + 1]
            guard line1.hasPrefix("P<") else { continue }
            if line1.count < 44 || line2.count < 44 { continue }
            line1 = String(line1.prefix(44))
            line2 = String(line2.prefix(44))

            let docNumber = cleanField(mrzSlice(line2, 0, 9))
            let nationality = cleanField(mrzSlice(line2, 10, 3))
            let dob = mrzSlice(line2, 13, 6)
            let sex = cleanField(mrzSlice(line2, 20, 1))
            let expires = mrzSlice(line2, 21, 6)

            let checkDoc = validateMRZCheckDigit(data: mrzSlice(line2, 0, 9), checkDigit: mrzSlice(line2, 9, 1))
            let checkDob = validateMRZCheckDigit(data: mrzSlice(line2, 13, 6), checkDigit: mrzSlice(line2, 19, 1))
            let checkExp = validateMRZCheckDigit(data: mrzSlice(line2, 21, 6), checkDigit: mrzSlice(line2, 27, 1))
            let checkPersonal = validateMRZCheckDigit(data: mrzSlice(line2, 28, 14), checkDigit: mrzSlice(line2, 42, 1))
            let compositeData = mrzSlice(line2, 0, 10) + mrzSlice(line2, 13, 7) + mrzSlice(line2, 21, 22)
            let checkFinal = validateMRZCheckDigit(data: compositeData, checkDigit: mrzSlice(line2, 43, 1))
            let allValid = checkDoc && checkDob && checkExp && checkPersonal && checkFinal
            if strictKYC && !allValid { continue }

            let nameField = mrzSlice(line1, 5, 39)
            let fullName = parseMRZName(nameField)

            return ParsedMRZ(
                format: "TD3",
                documentCode: "P",
                documentNumber: docNumber,
                fullName: fullName,
                dateOfBirth: normalizeMRZDate(dob),
                expires: normalizeMRZDate(expires),
                nationality: nationality,
                sex: sex,
                rawMRZ: line1 + "\n" + line2,
                isCheckDigitValid: allValid
            )
        }
        return nil
    }

    private static func parseTD1(lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        guard lines.count >= 3 else { return nil }
        for i in 0..<(lines.count - 2) {
            var line1 = lines[i]
            var line2 = lines[i + 1]
            var line3 = lines[i + 2]
            guard line1.hasPrefix("I<") || line1.hasPrefix("ID") || line1.hasPrefix("A<") || line1.hasPrefix("C<") else { continue }
            if line1.count < 30 || line2.count < 30 || line3.count < 30 { continue }
            line1 = String(line1.prefix(30))
            line2 = String(line2.prefix(30))
            line3 = String(line3.prefix(30))

            let documentCode = cleanField(mrzSlice(line1, 0, 2))
            let docNumber = cleanField(mrzSlice(line1, 5, 9))
            let dob = mrzSlice(line2, 0, 6)
            let sex = cleanField(mrzSlice(line2, 7, 1))
            let expires = mrzSlice(line2, 8, 6)
            let nationality = cleanField(mrzSlice(line2, 15, 3))
            let fullName = parseMRZName(line3)

            let checkDoc = validateMRZCheckDigit(data: mrzSlice(line1, 5, 9), checkDigit: mrzSlice(line1, 14, 1))
            let checkDob = validateMRZCheckDigit(data: mrzSlice(line2, 0, 6), checkDigit: mrzSlice(line2, 6, 1))
            let checkExp = validateMRZCheckDigit(data: mrzSlice(line2, 8, 6), checkDigit: mrzSlice(line2, 14, 1))
            let compositeData = mrzSlice(line1, 5, 25) + mrzSlice(line2, 0, 7) + mrzSlice(line2, 8, 7) + mrzSlice(line2, 18, 11)
            let checkFinal = validateMRZCheckDigit(data: compositeData, checkDigit: mrzSlice(line2, 29, 1))
            let allValid = checkDoc && checkDob && checkExp && checkFinal
            if strictKYC && !allValid { continue }

            return ParsedMRZ(
                format: "TD1",
                documentCode: documentCode,
                documentNumber: docNumber,
                fullName: fullName,
                dateOfBirth: normalizeMRZDate(dob),
                expires: normalizeMRZDate(expires),
                nationality: nationality,
                sex: sex,
                rawMRZ: line1 + "\n" + line2 + "\n" + line3,
                isCheckDigitValid: allValid
            )
        }
        return nil
    }

    private static func parseMRZName(_ field: String) -> String {
        let cleaned = field.replacingOccurrences(of: "<", with: " ").trimmingCharacters(in: .whitespaces)
        let normalizedSpaces = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return normalizedSpaces
    }

    private static func normalizeMRZDate(_ yymmdd: String) -> String {
        guard yymmdd.count == 6, yymmdd.allSatisfy(\.isNumber) else { return cleanField(yymmdd) }
        let yy = Int(yymmdd.prefix(2)) ?? 0
        let mm = yymmdd.dropFirst(2).prefix(2)
        let dd = yymmdd.suffix(2)
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let century = yy > currentYear + 5 ? "19" : "20"
        return "\(dd)/\(mm)/\(century)\(String(format: "%02d", yy))"
    }

    private static func validateMRZCheckDigit(data: String, checkDigit: String) -> Bool {
        guard let expected = checkDigit.first else { return false }
        let computed = computeMRZCheckDigit(data)
        return computed == expected
    }

    private static func computeMRZCheckDigit(_ data: String) -> Character {
        let weights = [7, 3, 1]
        var sum = 0
        for (index, ch) in data.enumerated() {
            let value = mrzCharValue(ch)
            sum += value * weights[index % weights.count]
        }
        return Character(String(sum % 10))
    }

    private static func mrzCharValue(_ ch: Character) -> Int {
        if ch == "<" { return 0 }
        if let digit = ch.wholeNumberValue { return digit }
        if let ascii = ch.asciiValue, ascii >= 65, ascii <= 90 {
            return Int(ascii - 55) // A=10 ... Z=35
        }
        return 0
    }

    private static func cleanField(_ value: String) -> String {
        value.replacingOccurrences(of: "<", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func mrzSlice(_ source: String, _ start: Int, _ length: Int) -> String {
        guard start >= 0, length > 0, start < source.count else { return "" }
        let safeStart = source.index(source.startIndex, offsetBy: start)
        let endOffset = min(source.count, start + length)
        let safeEnd = source.index(source.startIndex, offsetBy: endOffset)
        return String(source[safeStart..<safeEnd])
    }

    private static func normalizeSpanishID(from lines: [String]) -> (value: String, confidence: Double)? {
        let joined = lines.joined(separator: " ").uppercased()
        let pattern = "\\b([XYZ]?\\d{7,8}[A-Z])\\b"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(joined.startIndex..., in: joined)
        let matches = regex?.matches(in: joined, range: range) ?? []
        for match in matches {
            guard let r = Range(match.range(at: 1), in: joined) else { continue }
            let candidate = String(joined[r])
            if let normalized = validateSpanishID(candidate) {
                return normalized
            }
        }
        return nil
    }

    private static func validateSpanishID(_ raw: String) -> (value: String, confidence: Double)? {
        let value = raw.replacingOccurrences(of: " ", with: "").uppercased()
        let map = Array("TRWAGMYFPDXBNJZSQVHLCKE")

        if value.count == 9, value.first?.isNumber == true {
            let numberPart = String(value.prefix(8))
            guard let number = Int(numberPart), let last = value.last else { return nil }
            let expected = map[number % 23]
            if last == expected {
                return (value, 0.96)
            }
            return nil
        }

        if value.count == 9, let prefix = value.first, ["X", "Y", "Z"].contains(String(prefix)) {
            let body = String(value.dropFirst().prefix(7))
            guard body.allSatisfy(\.isNumber), let last = value.last else { return nil }
            let replacedPrefix: String
            switch prefix {
            case "X": replacedPrefix = "0"
            case "Y": replacedPrefix = "1"
            case "Z": replacedPrefix = "2"
            default: return nil
            }
            guard let number = Int(replacedPrefix + body) else { return nil }
            let expected = map[number % 23]
            if last == expected {
                return (value, 0.94)
            }
        }
        return nil
    }

    private static func extractCURP(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        let pattern = "\\b([A-Z][AEIOUX][A-Z]{2}\\d{6}[HM][A-Z]{5}[A-Z0-9]\\d)\\b"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(joined.startIndex..., in: joined)
        guard let match = regex?.firstMatch(in: joined, range: range),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    // Brazilian CPF: 000.000.000-00 or 00000000000
    private static func extractBrazilianCPF(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ")
        let pattern = "\\b(\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}|\\d{11})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        let candidate = String(joined[r]).replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        // Validate CPF check digits
        guard candidate.count == 11, !candidate.allSatisfy({ $0 == candidate.first }) else { return nil }
        return String(joined[r])
    }

    // Chilean RUT: 12.345.678-9 or 12345678-9 (digits + optional letter K)
    private static func extractChileanRUT(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        let pattern = "\\b(\\d{1,2}\\.\\d{3}\\.\\d{3}-[0-9K]|\\d{7,8}-[0-9K])\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    // Indian Aadhaar: 12 digits, often written as XXXX XXXX XXXX
    private static func extractAadhaar(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ")
        // Match 12-digit grouped patterns
        let pattern = "\\b(\\d{4}\\s\\d{4}\\s\\d{4}|\\d{12})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(joined.startIndex..., in: joined)
        // Aadhaar cannot start with 0 or 1
        for match in regex.matches(in: joined, range: range) {
            guard let r = Range(match.range(at: 1), in: joined) else { continue }
            let candidate = String(joined[r]).replacingOccurrences(of: " ", with: "")
            if candidate.count == 12, candidate.first != "0", candidate.first != "1" {
                return String(joined[r])
            }
        }
        return nil
    }

    // Indian PAN: 5 letters + 4 digits + 1 letter (e.g. ABCDE1234F)
    private static func extractIndianPAN(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        let pattern = "\\b([A-Z]{5}[0-9]{4}[A-Z])\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    // UK NINO: AA 99 99 99 A (two letters, six digits in groups, one letter suffix)
    private static func extractUKNINO(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        let pattern = "\\b([A-CEGHJ-PR-TW-Z]{1}[A-CEGHJ-NPR-TW-Z]{1}\\s?\\d{2}\\s?\\d{2}\\s?\\d{2}\\s?[A-D])\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    // German Personalausweis number: 1 letter + 8 alphanumeric (e.g. T22000129)
    private static func extractGermanID(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        // Must appear near "AUSWEISNUMMER", "SERIENNR", or be on a labeled line
        let pattern = "\\b([A-Z][A-Z0-9]{8})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(joined.startIndex..., in: joined)
        for match in regex.matches(in: joined, range: range) {
            guard let r = Range(match.range(at: 1), in: joined) else { continue }
            let candidate = String(joined[r])
            // Require mix of letter and digit
            let hasLetter = candidate.dropFirst().contains(where: { $0.isLetter })
            let hasDigit  = candidate.contains(where: { $0.isNumber })
            if hasLetter && hasDigit { return candidate }
        }
        return nil
    }

    // French NIR (Numéro de Sécurité Sociale): 13 digits + 2-digit key
    private static func extractFrenchNIR(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").replacingOccurrences(of: " ", with: "")
        let pattern = "(\\d{13}\\d{2})"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        let candidate = String(joined[r])
        // First digit: 1 (male) or 2 (female)
        guard candidate.first == "1" || candidate.first == "2" else { return nil }
        return candidate
    }

    // Argentine DNI: 7–8 digit number, often labeled "DNI" or "DOCUMENTO"
    private static func extractArgentineDNI(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        // Only extract if a DNI keyword is nearby
        guard joined.contains("DNI") || joined.contains("DOCUMENTO NACIONAL") || joined.contains("ARGENTINA") else { return nil }
        let pattern = "\\b(\\d{7,8})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    // Colombian cédula: 6–10 digits, preceded by "CC" or "CEDULA"
    private static func extractColombianCC(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        guard joined.contains("CC") || joined.contains("CEDULA") || joined.contains("CÉDULA") ||
              joined.contains("COLOMBIA") || joined.contains("COLOMBIANA") else { return nil }
        let pattern = "\\b(\\d{6,10})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    // Multilingual address keyword extraction
    private static func extractInternationalAddress(from lines: [String]) -> String? {
        let keywords = [
            // Spanish/Portuguese
            "CALLE", "C/", "AVENIDA", "AV.", "PASEO", "PLAZA", "CARRER", "RUA", "RUA ", "TRAVESSA",
            // French
            "RUE", "AVENUE", "BOULEVARD", "BD ", "BD.", "IMPASSE", "ALLÉE", "PLACE",
            // German/Austrian/Swiss
            "STRASSE", "STR.", "WEG", "PLATZ", "GASSE", "ALLEE",
            // Italian
            "VIA", "CORSO", "PIAZZA", "VIALE", "VICOLO",
            // Dutch
            "STRAAT", "LAAN", "PLEIN", "WEG ", "GRACHT",
            // Polish
            "ULICA", "UL.", "ALEJA", "AL.",
            // English
            "STREET", "ST ", "AVENUE", "AVE", "ROAD", "RD ", "LANE", "LN ", "DRIVE", "BLVD", "COURT", "CT ",
            // Arabic transliterated
            "SHARIA", "SHAR3", "SHAREI",
        ]
        let upperLines = lines.map { $0.uppercased() }
        for line in upperLines {
            for kw in keywords {
                if line.contains(kw) && line.rangeOfCharacter(from: .decimalDigits) != nil {
                    return line.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }
}

// MARK: - DocumentScannerView (VisionKit wrapper)

struct DocumentScannerView: UIViewControllerRepresentable {
    var onScan: ([UIImage]) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScannerView
        init(_ parent: DocumentScannerView) { self.parent = parent }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            guard scan.pageCount > 0 else {
                parent.onCancel()
                return
            }
            var images: [UIImage] = []
            images.reserveCapacity(scan.pageCount)
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            parent.onScan(images)
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            parent.onCancel()
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFailWithError error: Error) {
            parent.onCancel()
        }
    }
}

// MARK: - DocumentScannerOverlayView
// Wraps VisionKit scanner with an optional guide-frame overlay for the selected document type.

struct DocumentScannerOverlayView: View {
    let documentType: ScanDocumentType
    let showGuide: Bool
    let lang: AppLanguage
    var onScan: ([UIImage]) -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            DocumentScannerView(onScan: onScan, onCancel: onCancel)
                .ignoresSafeArea()

            if showGuide && documentType != .freeform {
                GeometryReader { geo in
                    let frameW = geo.size.width * 0.84
                    let frameH = frameW / documentType.aspectRatio
                    let offsetX = (geo.size.width - frameW) / 2
                    let offsetY = (geo.size.height - frameH) / 2

                    ZStack {
                        // Dimming overlay with cutout
                        GuideFrameCutout(
                            frameRect: CGRect(x: offsetX, y: offsetY, width: frameW, height: frameH)
                        )
                        .fill(Color.black.opacity(0.45))
                        .ignoresSafeArea()

                        // Guide frame border with corner handles
                        GuideFrameBorder(
                            x: offsetX, y: offsetY, w: frameW, h: frameH
                        )

                        // Field zone hints inside the frame
                        if !documentType.fieldHints.isEmpty {
                            ForEach(Array(documentType.fieldHints.enumerated()), id: \.offset) { _, hint in
                                let hx = offsetX + hint.normRect.origin.x * frameW
                                let hy = offsetY + hint.normRect.origin.y * frameH
                                let hw = hint.normRect.width * frameW
                                let hh = hint.normRect.height * frameH

                                ZStack(alignment: .topLeading) {
                                    Rectangle()
                                        .strokeBorder(
                                            Color.white.opacity(0.45),
                                            style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                                        )
                                        .frame(width: hw, height: hh)

                                    Text(hint.label)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white.opacity(0.85))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Color.black.opacity(0.55))
                                        .clipShape(RoundedRectangle(cornerRadius: 3))
                                        .offset(y: -16)
                                }
                                .position(x: hx + hw / 2, y: hy + hh / 2)
                            }
                        }

                        // Label
                        VStack(spacing: 4) {
                            Text(documentType.label(lang: lang))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(ShieldTheme.accent.opacity(0.85))
                                .clipShape(Capsule())

                            Text(LanguageManager.shared.t("capture_align_hint", table: "Capture"))
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        .position(x: geo.size.width / 2, y: offsetY - 44)
                    }
                }
                .allowsHitTesting(false)
            }
        }
    }
}

private struct GuideFrameCutout: Shape {
    let frameRect: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRoundedRect(in: frameRect, cornerSize: CGSize(width: 12, height: 12))
        return path
    }

    // even-odd fill rule creates the cutout
    var fillStyle: FillStyle { FillStyle(eoFill: true) }
}

extension GuideFrameCutout {
    func fill(_ content: some ShapeStyle) -> some View {
        self.fill(content, style: FillStyle(eoFill: true))
    }
}

private struct GuideFrameBorder: View {
    let x, y, w, h: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(ShieldTheme.accent, lineWidth: 2)
                .frame(width: w, height: h)
                .position(x: x + w / 2, y: y + h / 2)

            // Corner tick marks
            ForEach(corners, id: \.self) { corner in
                cornerTick(at: corner)
            }
        }
    }

    private var corners: [String] { ["tl", "tr", "bl", "br"] }

    private func cornerTick(at corner: String) -> some View {
        let len: CGFloat = 22
        let tl = corner == "tl"
        let tr = corner == "tr"
        let bl = corner == "bl"
        let cx: CGFloat = (tl || bl) ? x : x + w
        let cy: CGFloat = (tl || tr) ? y : y + h
        let hDir: CGFloat = (tl || bl) ? 1 : -1
        let vDir: CGFloat = (tl || tr) ? 1 : -1

        return ZStack {
            Path { p in
                p.move(to: CGPoint(x: cx, y: cy))
                p.addLine(to: CGPoint(x: cx + hDir * len, y: cy))
            }
            .stroke(ShieldTheme.accent, lineWidth: 3)

            Path { p in
                p.move(to: CGPoint(x: cx, y: cy))
                p.addLine(to: CGPoint(x: cx, y: cy + vDir * len))
            }
            .stroke(ShieldTheme.accent, lineWidth: 3)
        }
    }
}

// MARK: - PhotoPickerView (PhotosUI wrapper)

struct PhotoPickerView: UIViewControllerRepresentable {
    var onPick: ([UIImage]) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 0
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        init(_ parent: PhotoPickerView) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                parent.onCancel()
                return
            }

            var imagesByIndex: [Int: UIImage] = [:]
            let lock = NSLock()
            let group = DispatchGroup()
            var loadedAny = false

            for (index, result) in results.enumerated() {
                guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
                loadedAny = true
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
                    defer { group.leave() }
                    guard let image = object as? UIImage else { return }
                    lock.lock()
                    imagesByIndex[index] = image
                    lock.unlock()
                }
            }

            guard loadedAny else {
                parent.onCancel()
                return
            }

            group.notify(queue: .main) { [weak self] in
                let orderedImages = results.indices.compactMap { imagesByIndex[$0] }
                if orderedImages.isEmpty {
                    self?.parent.onCancel()
                } else {
                    self?.parent.onPick(orderedImages)
                }
            }
        }
    }
}

// MARK: - FilesPickerView (UIDocumentPickerViewController wrapper)

struct FilesPickerView: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.pdf, .image, .jpeg, .png, .tiff]
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: FilesPickerView
        init(_ parent: FilesPickerView) { self.parent = parent }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { parent.onCancel(); return }
            parent.onPick(url)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.onCancel()
        }
    }
}
