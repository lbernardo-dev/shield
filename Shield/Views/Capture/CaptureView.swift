import SwiftUI
import VisionKit
import PhotosUI
import UIKit
import UniformTypeIdentifiers
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

    func label(lang: AppLanguage? = nil) -> String {
        switch self {
        case .identity:       return LanguageManager.shared.capture("capture_kind_id_card")
        case .passport:       return LanguageManager.shared.capture("capture_kind_passport")
        case .drivingLicense: return LanguageManager.shared.capture("capture_kind_driving_license")
        case .a4Document:     return LanguageManager.shared.capture("capture_kind_a4")
        case .freeform:       return LanguageManager.shared.capture("capture_kind_freeform")
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

private struct PendingRenderedImport {
    let pages: [UIImage]
    let originalPages: [UIImage]
    let transforms: [DocumentPageTransform]
    let title: String
    let docID: String
    let sourceType: ImportedDocumentSource
    let sourceFileName: String?
}

// MARK: - CaptureView

struct CaptureView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var showPaywall = false
    @State private var paywallTrigger: PaywallTrigger = .manual
    @State private var showScanReview = false
    @State private var isProcessing = false
    @State private var processingMessage = ""
    @State private var processingProgress: Double? = nil
    @State private var processingTask: Task<Void, Never>? = nil
    @State private var queuedImportURLs: [URL] = []
    @State private var queuedImportIndex = 0
    @State private var queuedImportSource = "file"
    @State private var lastQueuedImportedDocumentID: String?
    @State private var importErrorMessage: String? = nil
    @State private var retryImportURL: URL? = nil
    @State private var retryImportSource: String = "file"
    @State private var stagedPages: [UIImage] = []
    @State private var stagedTitle: String? = nil
    @State private var stagedSourceType: ImportedDocumentSource = .image
    @State private var stagedSourceFileName: String? = nil
    @State private var stagedDocID: String = UUID().uuidString
    @State private var pendingRenderedImport: PendingRenderedImport? = nil
    @State private var pendingDocumentCommit: DocumentItem? = nil
    /// Non-nil when ScanReviewView was opened for re-adjustment of an existing document.
    /// In this mode, confirmed pages overwrite the doc's files instead of creating a new doc.
    @State private var docToReadjust: DocumentItem? = nil
    @State private var stagedAdjustments: [ScanPageAdjustment]? = nil
    @State private var selectedScanType: ScanDocumentType = .identity
    @State private var showScanTypeGuide: Bool = true
    @State private var showCloudPicker: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SeasonalThemeBackdrop()

                if isProcessing {
                    processingView
                } else {
                    captureMenu(bottomInset: geo.safeAreaInsets.bottom)
                }
            }
        }
        .preferredColorScheme(appState.preferredScheme)
        .fullScreenCover(isPresented: $showScanner) {
            DocumentScannerOverlayView(
                documentType: selectedScanType,
                showGuide: showScanTypeGuide,
                lang: LanguageManager.shared.current
            ) { images in
                showScanner = false
                guard !images.isEmpty else { return }
                stageScanPages(images, title: nil, sourceType: .image, sourceFileName: nil, docID: UUID().uuidString)
            } onCancel: {
                showScanner = false
            } onError: {
                showScanner = false
                importErrorMessage = CaptureImportError.scannerFailed.errorDescription
                    ?? CaptureImportError.scannerFailed.localizedDescription
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showScanReview) {
            ScanReviewView(
                pages: stagedPages,
                initialAdjustments: stagedAdjustments,
                onCancel: {
                    showScanReview = false
                    stagedPages = []
                    cleanupStagedSource()
                    stagedSourceFileName = nil
                    docToReadjust = nil
                    stagedAdjustments = nil
                    cancelQueuedImports()
                },
                onConfirm: { adjustedPages, hasAdjustments, transforms in
                    showScanReview = false
                    if let doc = docToReadjust {
                        guard appState.replaceRenderedPages(
                            for: doc,
                            with: adjustedPages,
                            transforms: transforms
                        ) != nil else {
                            importErrorMessage = CaptureImportError.storageWriteFailed.errorDescription
                                ?? CaptureImportError.storageWriteFailed.localizedDescription
                            docToReadjust = nil
                            return
                        }
                        docToReadjust = nil
                    } else {
                        // New document flow
                        handleReviewedPages(
                            adjustedPages,
                            originalPages: stagedPages,
                            transforms: transforms,
                            hasAdjustments: hasAdjustments
                        )
                    }
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
            } onError: { error in
                showPhotoPicker = false
                importErrorMessage = error.errorDescription ?? error.localizedDescription
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilesPickerView { urls in
                showFilePicker = false
                beginQueuedImports(urls, source: "file")
            } onCancel: {
                showFilePicker = false
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: paywallTrigger).environmentObject(appState)
        }
        .overlay {
            if let importErrorMessage {
                importErrorOverlay(message: importErrorMessage)
                    .transition(reduceMotion ? .opacity : .scale(scale: 0.98).combined(with: .opacity))
                    .zIndex(500)
            }
        }
        .animation(reduceMotion ? nil : ShieldMotion.state, value: importErrorMessage != nil)
        .onDisappear {
            processingTask?.cancel()
            if pendingDocumentCommit != nil || pendingRenderedImport != nil || retryImportURL != nil || !queuedImportURLs.isEmpty {
                discardPendingImport()
            }
        }
        .onAppear {
            consumePendingSharedImport()
#if DEBUG
            configureDebugScanReviewIfNeeded()
            configureDebugMultiImportQueueIfNeeded()
#endif
        }
        .onChange(of: appState.pendingSharedImportURL) { _, _ in
            consumePendingSharedImport()
        }
        .onChange(of: appState.pendingSharedImportError) { _, newValue in
            guard let newValue else { return }
            appState.pendingSharedImportError = nil
            importErrorMessage = newValue
        }
        .sheet(isPresented: $showCloudPicker) {
            ExternalStoragePickerSheet(isPresented: $showCloudPicker) { url in
                processFile(url)
            }.environmentObject(appState)
        }
        // Re-adjust scan from EditorView: present at THIS level so safe-area works correctly.
        .onChange(of: appState.showScanReviewForEdit) {
            guard appState.showScanReviewForEdit else { return }
            let doc = appState.selectedDoc
            docToReadjust = doc
            stagedPages = appState.scanReviewPagesForEdit.map { $0.normalizedForShield() }
            
            // Map existing adjustments if available
            if doc != nil {
                let count = appState.scanReviewPagesForEdit.count
                stagedAdjustments = Array(repeating: .default, count: count)
            }
            
            showScanReview = true
            appState.showScanReviewForEdit = false
            appState.scanReviewPagesForEdit = []
        }
    }

    // MARK: - Capture menu

    @ViewBuilder
    private func captureMenu(bottomInset: CGFloat) -> some View {
        CaptureMenuView(
            bottomInset: bottomInset,
            selectedScanType: selectedScanType,
            showGuide: showScanTypeGuide,
            onClose: { appState.showCapture = false },
            onToggleGuide: { withAnimation { showScanTypeGuide.toggle() } },
            onSelectScanType: { selectedScanType = $0 },
            onScan: {
                guard ensureCanImportMoreDocuments() else { return }
                if VNDocumentCameraViewController.isSupported {
                    showScanner = true
                } else {
                    showPhotoPicker = true
                }
            },
            onPhotos: {
                guard ensureCanImportMoreDocuments() else { return }
                showPhotoPicker = true
            },
            onFiles: {
                guard ensureCanImportMoreDocuments() else { return }
                showFilePicker = true
            },
            onCloud: {
                guard ensureCanImportMoreDocuments() else { return }
                showCloudPicker = true
            }
        )
    }

    // MARK: - Processing view

    private var processingView: some View {
        VStack(spacing: 24) {
            if let processingProgress {
                ProgressView(value: processingProgress)
                    .progressViewStyle(.linear)
                    .tint(ShieldTheme.accent)
                    .frame(maxWidth: 280)
                Text("\(Int(processingProgress * 100))%")
                    .shieldFont(13, weight: .semibold, design: .monospaced)
                    .foregroundColor(ShieldTheme.secondary(appState.preferredScheme))
            } else {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(ShieldTheme.accent)
            }
            Text(processingMessage)
                .shieldFont(16, weight: .semibold)
                .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                .multilineTextAlignment(.center)
            Button(LanguageManager.shared.common("common_cancel"), role: .cancel) {
                processingTask?.cancel()
                processingTask = nil
                retryImportURL = nil
                isProcessing = false
                processingProgress = nil
                cleanupStagedSource()
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ShieldTheme.pageBackground(appState.preferredScheme).ignoresSafeArea())
    }

    private var canRetryImport: Bool {
        pendingDocumentCommit != nil || pendingRenderedImport != nil || retryImportURL != nil
    }

    private func importErrorOverlay(message: String) -> some View {
        ShieldErrorCard(
            title: LanguageManager.shared.capture("capture_import_failed_title"),
            message: message,
            scheme: appState.preferredScheme,
            dismissLabel: queuedImportURLs.isEmpty
                ? LanguageManager.shared.common("common_ok")
                : LanguageManager.shared.capture("capture_multi_import_skip"),
            dismissAction: {
                importErrorMessage = nil
                if queuedImportURLs.isEmpty {
                    discardPendingImport()
                } else {
                    skipCurrentQueuedImport()
                }
            },
            accessibilityIdentifier: "capture.importError",
            primaryLabel: canRetryImport ? LanguageManager.shared.common("common_retry") : nil,
            primaryAction: canRetryImport ? {
                importErrorMessage = nil
                Task { @MainActor in
                    await Task.yield()
                    retryPendingImportIfNeeded()
                }
            } : nil
        )
    }

    // MARK: - Processing logic

    private func ensureCanImportMoreDocuments() -> Bool {
        if pm.canAddDocument(currentCount: appState.documents.count) {
            return true
        }
        PremiumManager.recordFeatureGate(.unlimitedDocuments, trigger: .docLimitReached)
        paywallTrigger = .docLimitReached
        showPaywall = true
        return false
    }

    private func processFile(_ url: URL, source: String = "file") {
        guard pm.canAddDocument(currentCount: appState.documents.count) else {
            SharedImportStore.removeTemporaryFile(url)
            PremiumManager.recordFeatureGate(.unlimitedDocuments, trigger: .docLimitReached)
            paywallTrigger = .docLimitReached
            showPaywall = true
            return
        }
        AppState.trackEvent("import_started", properties: ["source": source])
        retryImportURL = url
        retryImportSource = source
        isProcessing = true
        processingMessage = queuedImportProgressPrefix + LanguageManager.shared.capture("capture_importing_file")
        processingProgress = 0

        processingTask?.cancel()
        processingTask = Task {
            var shouldKeepForRetry = false
            var storedSourceFileName: String?
            defer {
                if !shouldKeepForRetry {
                    SharedImportStore.removeTemporaryFile(url)
                }
            }
            let hasScopedAccess = url.isFileURL && url.startAccessingSecurityScopedResource()
            defer {
                if hasScopedAccess { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let workingURL: URL
                if url.isFileURL {
                    workingURL = url
                } else {
                    guard ["http", "https"].contains(url.scheme?.lowercased() ?? "") else {
                        throw CaptureImportError.unsupportedFormat
                    }
                    var request = URLRequest(url: url)
                    request.timeoutInterval = 60
                    request.cachePolicy = .reloadIgnoringLocalCacheData
                    let (downloadedURL, response) = try await URLSession.shared.download(for: request)
                    guard let http = response as? HTTPURLResponse,
                          (200..<300).contains(http.statusCode) else {
                        throw CaptureImportError.sourceReadFailed
                    }
                    workingURL = downloadedURL
                }

                let prepared = try await CaptureImportPipeline.prepareFile(at: workingURL) { completed, total in
                    processingProgress = total > 0 ? Double(completed) / Double(total) : nil
                    processingMessage = queuedImportProgressPrefix
                        + LanguageManager.shared.editor("editor_page_indicator", completed, total)
                }
                try Task.checkCancellation()
                let docID = UUID().uuidString
                let sourceFileName: String?
                if let data = prepared.sourceData, let ext = prepared.sourceExtension {
                    guard let stored = appState.saveSourceFile(data, id: docID, fileExtension: ext) else {
                        throw CaptureImportError.storageWriteFailed
                    }
                    storedSourceFileName = stored
                    sourceFileName = stored
                } else {
                    sourceFileName = nil
                }
                try Task.checkCancellation()
                processingTask = nil
                retryImportURL = nil
                stagePreparedPages(
                    prepared.pages,
                    title: prepared.title,
                    sourceType: prepared.sourceType,
                    sourceFileName: sourceFileName,
                    docID: docID,
                    entryPoint: source
                )
            } catch is CancellationError {
                if let storedSourceFileName {
                    appState.removeStoredSource(fileName: storedSourceFileName)
                }
                if retryImportURL == url {
                    retryImportURL = nil
                }
                isProcessing = false
                processingProgress = nil
            } catch {
                shouldKeepForRetry = true
                failImport(error, source: source)
            }
        }
    }

    private func consumePendingSharedImport() {
        if let error = appState.pendingSharedImportError {
            appState.pendingSharedImportError = nil
            importErrorMessage = error
        }
        guard let url = appState.pendingSharedImportURL else { return }
        appState.pendingSharedImportURL = nil
        processFile(url, source: "share_sheet")
    }

    private func beginQueuedImports(_ urls: [URL], source: String) {
        let supportedURLs = urls.filter { $0.isFileURL }
        guard !supportedURLs.isEmpty else {
            importErrorMessage = CaptureImportError.unsupportedFormat.errorDescription
                ?? CaptureImportError.unsupportedFormat.localizedDescription
            return
        }

        queuedImportURLs = supportedURLs
        queuedImportIndex = 0
        queuedImportSource = source
        lastQueuedImportedDocumentID = nil
        processCurrentQueuedImport()
    }

    private var queuedImportProgressPrefix: String {
        guard !queuedImportURLs.isEmpty else { return "" }
        return LanguageManager.shared.capture(
            "capture_multi_import_progress",
            queuedImportIndex + 1,
            queuedImportURLs.count
        ) + " · "
    }

    private func processCurrentQueuedImport() {
        guard queuedImportURLs.indices.contains(queuedImportIndex) else {
            finishQueuedImports()
            return
        }

        guard pm.canAddDocument(currentCount: appState.documents.count) else {
            queuedImportURLs.dropFirst(queuedImportIndex).forEach(SharedImportStore.removeTemporaryFile)
            queuedImportURLs = Array(queuedImportURLs.prefix(queuedImportIndex))
            PremiumManager.recordFeatureGate(.unlimitedDocuments, trigger: .docLimitReached)
            paywallTrigger = .docLimitReached
            showPaywall = true
            finishQueuedImports()
            return
        }

        let url = queuedImportURLs[queuedImportIndex]
        processingMessage = LanguageManager.shared.capture(
            "capture_multi_import_progress",
            queuedImportIndex + 1,
            queuedImportURLs.count
        )
        processFile(url, source: queuedImportSource)
    }

    private func advanceQueuedImport() {
        queuedImportIndex += 1
        guard queuedImportIndex < queuedImportURLs.count else {
            finishQueuedImports()
            return
        }

        Task { @MainActor in
            await Task.yield()
            processCurrentQueuedImport()
        }
    }

    private func finishQueuedImports() {
        let lastDocument = lastQueuedImportedDocumentID.flatMap { id in
            appState.documents.first(where: { $0.id == id })
        }
        queuedImportURLs = []
        queuedImportIndex = 0
        queuedImportSource = "file"
        lastQueuedImportedDocumentID = nil

        if let lastDocument, !showPaywall {
            appState.selectedDoc = lastDocument
            appState.showCapture = false
        }
    }

    private func cancelQueuedImports() {
        queuedImportURLs.forEach(SharedImportStore.removeTemporaryFile)
        queuedImportURLs = []
        queuedImportIndex = 0
        queuedImportSource = "file"
        lastQueuedImportedDocumentID = nil
    }

    private func skipCurrentQueuedImport() {
        let nextIndex = queuedImportIndex + 1
        discardCurrentImportAssets()
        queuedImportIndex = nextIndex
        if queuedImportIndex < queuedImportURLs.count {
            processCurrentQueuedImport()
        } else {
            finishQueuedImports()
        }
    }

#if DEBUG
    private func configureDebugScanReviewIfNeeded() {
        guard ASOScreenshotMode.isEnabled, ASOScreenshotMode.scene == "scan-review" else { return }
        stagedPages = [Self.scanReviewFixture(language: ASOScreenshotMode.language)]
        stagedTitle = ASOScreenshotMode.language == .es ? "Documento de prueba" : "Sample document"
        stagedSourceType = .image
        stagedSourceFileName = nil
        stagedDocID = "scan-review-fixture"
        showScanReview = true
    }

    private func configureDebugMultiImportQueueIfNeeded() {
        guard ASOScreenshotMode.isEnabled else { return }
        let scene = ASOScreenshotMode.scene
        guard scene == "batch-import-recovery" || scene == "batch-import-cancel" else { return }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShieldSharedImports", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let runID = UUID().uuidString
            let imageData = Self.scanReviewFixture(language: ASOScreenshotMode.language).pngData()
            guard let imageData else { return }

            if scene == "batch-import-recovery" {
                let invalidPDF = directory.appendingPathComponent("MaskID-UI-\(runID)-invalid.pdf")
                let validImage = directory.appendingPathComponent("MaskID-UI-\(runID)-valid.png")
                try Data("not a PDF".utf8).write(to: invalidPDF, options: .atomic)
                try imageData.write(to: validImage, options: .atomic)
                beginQueuedImports([invalidPDF, validImage], source: "ui_testing")
            } else {
                let firstImage = directory.appendingPathComponent("MaskID-UI-\(runID)-first.png")
                let secondImage = directory.appendingPathComponent("MaskID-UI-\(runID)-second.png")
                try imageData.write(to: firstImage, options: .atomic)
                try imageData.write(to: secondImage, options: .atomic)
                beginQueuedImports([firstImage, secondImage], source: "ui_testing")
            }
        } catch {
            failImport(error, source: "ui_testing")
        }
    }

    private static func scanReviewFixture(language: AppLanguage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 620))
        return renderer.image { context in
            let bounds = CGRect(origin: .zero, size: CGSize(width: 900, height: 620))
            UIColor(red: 0.96, green: 0.95, blue: 0.90, alpha: 1).setFill()
            context.cgContext.fill(bounds)

            UIColor(red: 0.12, green: 0.24, blue: 0.42, alpha: 1).setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 900, height: 106))

            ((language == .es ? "DOCUMENTO DE PRUEBA" : "SAMPLE DOCUMENT") as NSString).draw(
                at: CGPoint(x: 42, y: 34),
                withAttributes: [
                    .font: UIFont.systemFont(ofSize: 34, weight: .bold),
                    .foregroundColor: UIColor.white
                ]
            )

            for (index, width) in [480, 350, 525, 280, 420, 310].enumerated() {
                UIColor(red: 0.35, green: 0.36, blue: 0.38, alpha: 0.75).setFill()
                context.cgContext.fill(CGRect(x: 52, y: 170 + index * 58, width: width, height: 14))
            }
        }
    }
#endif

    private func stageScanPages(
        _ pages: [UIImage],
        title: String?,
        sourceType: ImportedDocumentSource,
        sourceFileName: String?,
        docID: String
    ) {
        guard !pages.isEmpty else { return }
        
        isProcessing = true
        processingMessage = LanguageManager.shared.capture("capture_processing_pages")
        
        processingProgress = 0
        processingTask?.cancel()
        processingTask = Task {
            do {
                let normalizedPages = try await CaptureImportPipeline.prepareImages(pages) { completed, total in
                    processingProgress = Double(completed) / Double(max(total, 1))
                }
                try await Task.sleep(for: .milliseconds(350))
                try Task.checkCancellation()
                processingTask = nil
                stagePreparedPages(
                    normalizedPages,
                    title: title,
                    sourceType: sourceType,
                    sourceFileName: sourceFileName,
                    docID: docID
                )
            } catch is CancellationError {
                isProcessing = false
                processingProgress = nil
            } catch {
                failImport(error, source: sourceType.rawValue)
            }
        }
    }

    private func stagePreparedPages(
        _ normalizedPages: [UIImage],
        title: String?,
        sourceType: ImportedDocumentSource,
        sourceFileName: String?,
        docID: String,
        entryPoint: String = "file"
    ) {
        isProcessing = false
        processingProgress = nil
        if entryPoint == "share_sheet" {
            AppState.trackEvent("share_extension_completed", properties: ["source": "share_sheet"])
        }
                if sourceType == .image {
                    AppState.trackEvent("import_started", properties: ["source": "image"])
                }
                stagedPages = normalizedPages
                stagedTitle = title
                stagedSourceType = sourceType
                stagedSourceFileName = sourceFileName
                stagedDocID = docID
                showScanReview = true
                AppState.trackEvent("scan_adjustment_opened", properties: [
                    "pages": String(normalizedPages.count),
                    "source": sourceType.rawValue
                ])
    }

    private func handleReviewedPages(
        _ pages: [UIImage],
        originalPages: [UIImage],
        transforms: [DocumentPageTransform],
        hasAdjustments: Bool
    ) {
        guard !pages.isEmpty else { return }
        let title = stagedTitle ?? ""
        let docID = stagedDocID
        let sourceType = stagedSourceType
        let sourceFileName = stagedSourceFileName
        stagedPages = []
        stagedTitle = nil

        processImportedPages(
            pages,
            originalPages: originalPages,
            transforms: transforms,
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
        originalPages: [UIImage],
        transforms: [DocumentPageTransform],
        title: String,
        docID: String,
        sourceType: ImportedDocumentSource,
        sourceFileName: String?
    ) {
        isProcessing = true
        processingMessage = queuedImportProgressPrefix + LanguageManager.shared.capture("capture_processing_pages")
        processingProgress = 0

        processingTask?.cancel()
        processingTask = Task {
            var pageFileNames: [String] = []
            var originalPageFileNames: [String] = []

            for (idx, page) in pages.enumerated() {
                guard !Task.isCancelled else {
                    rollbackImportAssets(pageFileNames + originalPageFileNames, sourceFileName: sourceFileName)
                    isProcessing = false
                    processingProgress = nil
                    return
                }
                guard let fileName = appState.saveImage(page, id: "\(docID)_rendered_p\(idx)") else {
                    rollbackImportAssets(pageFileNames + originalPageFileNames, sourceFileName: nil)
                    preserveRenderedImportForRetry(
                        pages: pages,
                        originalPages: originalPages,
                        transforms: transforms,
                        title: title,
                        docID: docID,
                        sourceType: sourceType,
                        sourceFileName: sourceFileName
                    )
                    failImport(CaptureImportError.storageWriteFailed, source: sourceType.rawValue)
                    return
                }
                pageFileNames.append(fileName)
                processingProgress = Double(idx + 1) / Double(max(pages.count + originalPages.count, 1)) * 0.3
            }

            for (idx, page) in originalPages.enumerated() {
                guard !Task.isCancelled else {
                    rollbackImportAssets(pageFileNames + originalPageFileNames, sourceFileName: sourceFileName)
                    isProcessing = false
                    processingProgress = nil
                    return
                }
                guard let fileName = appState.saveImage(page, id: "\(docID)_original_p\(idx)") else {
                    rollbackImportAssets(pageFileNames + originalPageFileNames, sourceFileName: nil)
                    preserveRenderedImportForRetry(
                        pages: pages,
                        originalPages: originalPages,
                        transforms: transforms,
                        title: title,
                        docID: docID,
                        sourceType: sourceType,
                        sourceFileName: sourceFileName
                    )
                    failImport(CaptureImportError.storageWriteFailed, source: sourceType.rawValue)
                    return
                }
                originalPageFileNames.append(fileName)
                processingProgress = Double(pages.count + idx + 1) / Double(max(pages.count + originalPages.count, 1)) * 0.3
            }

            guard pageFileNames.count == pages.count,
                  originalPageFileNames.count == originalPages.count else {
                rollbackImportAssets(pageFileNames + originalPageFileNames, sourceFileName: nil)
                preserveRenderedImportForRetry(
                    pages: pages,
                    originalPages: originalPages,
                    transforms: transforms,
                    title: title,
                    docID: docID,
                    sourceType: sourceType,
                    sourceFileName: sourceFileName
                )
                failImport(CaptureImportError.storageWriteFailed, source: sourceType.rawValue)
                return
            }

            processingProgress = nil
            processingMessage = LanguageManager.shared.capture("capture_analyzing_sensitive_text")

            // OCR all pages: two-pass adaptive — second pass adds country-specific languages if detected.
            // Also capture bounding boxes for page 0 to enable precision auto-redaction.
            let pageObservations = await OCRService.recognizeObservationsByPageAdaptive(in: pages)
            guard !Task.isCancelled else {
                rollbackImportAssets(pageFileNames + originalPageFileNames, sourceFileName: sourceFileName)
                isProcessing = false
                return
            }
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
            fields.ocrPageEvidence = OCRService.buildPageEvidence(
                observations: pageObservations,
                extractedFields: perPageFields
            )
            do {
                fields.ocrFaceSuggestions = try await OCRService.detectFaceSuggestions(in: pages)
                fields.ocrFaceSuggestionsRevision = OCRService.faceSuggestionRevision
            } catch {
                // Leave detection unversioned so the editor can retry on a later open.
                fields.ocrFaceSuggestions = nil
                fields.ocrFaceSuggestionsRevision = nil
            }
            let detectedType = OCRService.detectDocumentType(from: lines)
            fields.ocrDocumentType = detectedType.rawValue
            fields.ocrPageTexts = pageTexts
            let fullText = pageTexts.joined(separator: "\n\n")
            fields.ocrFullText = fullText
            // Store bounding boxes from page 0 for precision redaction in the editor
            if let page0 = pageObservations.first {
                fields.ocrBoundingTexts = page0.map(\.text)
                fields.ocrBoundingRects = page0.map(\.boundingRect)
            }
            // Smart enrichment: fill any empty fields using on-device Foundation Model
            if SmartFieldExtractor.isAvailable() {
                if let enriched = await SmartFieldExtractor.enrich(fields: fields, ocrText: fullText) {
                    fields = enriched
                }
            }
            guard !Task.isCancelled else {
                rollbackImportAssets(pageFileNames + originalPageFileNames, sourceFileName: sourceFileName)
                isProcessing = false
                processingProgress = nil
                return
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
                return LanguageManager.shared.capture("capture_scan_fallback_title", fmt.string(from: Date()))
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
            let resolvedPageTransforms = transforms.count == pageFileNames.count
                ? transforms
                : Array(repeating: DocumentPageTransform.identity, count: pageFileNames.count)
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
                originalPageFileNames: originalPageFileNames.count == pageFileNames.count
                    ? originalPageFileNames
                    : nil,
                pageTransforms: resolvedPageTransforms,
                sourceType: sourceType,
                sourceFileName: sourceFileName,
                fields: fields,
                pageRedactions: [],
                redactionGeometryReviewedFingerprint: RedactionReviewGate.fingerprint(
                    pageTransforms: resolvedPageTransforms,
                    imageAdjustment: nil,
                    rasterBackedTypedDocument: resolvedKind != .photo
                ),
                watermark: nil
            )

            await MainActor.run {
                guard !Task.isCancelled else {
                    rollbackImportAssets(pageFileNames + originalPageFileNames, sourceFileName: sourceFileName)
                    isProcessing = false
                    processingProgress = nil
                    return
                }
                guard appState.addDocument(doc) else {
                    // Keep the already encrypted page assets so the user can
                    // retry the metadata commit without rescanning or losing input.
                    pendingDocumentCommit = doc
                    failImport(CaptureImportError.storageWriteFailed, source: sourceType.rawValue)
                    return
                }
                AppState.trackEvent("import_completed", properties: [
                    "source": sourceType.rawValue,
                    "pages": String(pageFileNames.count),
                    "detected_type": detectedType.rawValue,
                    "mrz_valid": (fields.ocrMRZValid == true) ? "true" : "false"
                ])
                ReviewFeedbackCoordinator.shared.track(
                    .coreActionCompleted(feature: .documentImport)
                )
                if risk.level != .low {
                    AppState.trackEvent("risk_detected", properties: [
                        "source": sourceType.rawValue,
                        "risk": risk.level.rawValue,
                        "low_fields": risk.lowFields.joined(separator: ",")
                    ])
                }
                isProcessing = false
                processingProgress = nil
                processingTask = nil
                stagedSourceFileName = nil
                if !queuedImportURLs.isEmpty {
                    lastQueuedImportedDocumentID = doc.id
                    advanceQueuedImport()
                } else {
                    appState.selectedDoc = doc
                    appState.showCapture = false
                }
            }
        }
    }

    private func failImport(_ error: Error, source: String) {
        processingTask = nil
        isProcessing = false
        processingProgress = nil
        let description = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        if queuedImportURLs.indices.contains(queuedImportIndex) {
            importErrorMessage = "\(queuedImportURLs[queuedImportIndex].lastPathComponent): \(description)"
        } else {
            importErrorMessage = description
        }
        ReviewFeedbackCoordinator.shared.track(.operationFailed(feature: .documentImport))
        AppState.trackEvent("import_failed", properties: [
            "source": source,
            "error_type": String(describing: type(of: error))
        ])
    }

    private func preserveRenderedImportForRetry(
        pages: [UIImage],
        originalPages: [UIImage],
        transforms: [DocumentPageTransform],
        title: String,
        docID: String,
        sourceType: ImportedDocumentSource,
        sourceFileName: String?
    ) {
        pendingRenderedImport = PendingRenderedImport(
            pages: pages,
            originalPages: originalPages,
            transforms: transforms,
            title: title,
            docID: docID,
            sourceType: sourceType,
            sourceFileName: sourceFileName
        )
        stagedSourceFileName = sourceFileName
    }

    private func retryPendingImportIfNeeded() {
        if let document = pendingDocumentCommit {
            guard appState.addDocument(document) else {
                importErrorMessage = CaptureImportError.storageWriteFailed.errorDescription
                    ?? CaptureImportError.storageWriteFailed.localizedDescription
                return
            }

            pendingDocumentCommit = nil
            stagedSourceFileName = nil
            AppState.trackEvent("import_completed", properties: [
                "source": document.sourceType.rawValue,
                "pages": String(document.pageCount),
                "detected_type": document.fields.ocrDocumentType ?? "unknown",
                "mrz_valid": (document.fields.ocrMRZValid == true) ? "true" : "false"
            ])
            ReviewFeedbackCoordinator.shared.track(.coreActionCompleted(feature: .documentImport))
            if !queuedImportURLs.isEmpty {
                lastQueuedImportedDocumentID = document.id
                advanceQueuedImport()
            } else {
                appState.selectedDoc = appState.documents.first(where: { $0.id == document.id }) ?? document
                appState.showCapture = false
            }
            return
        }

        if let pending = pendingRenderedImport {
            pendingRenderedImport = nil
            processImportedPages(
                pending.pages,
                originalPages: pending.originalPages,
                transforms: pending.transforms,
                title: pending.title,
                docID: pending.docID,
                sourceType: pending.sourceType,
                sourceFileName: pending.sourceFileName
            )
            return
        }

        if let retryImportURL {
            processFile(retryImportURL, source: retryImportSource)
        }
    }

    private func discardPendingImport() {
        discardCurrentImportAssets()
        cancelQueuedImports()
    }

    private func discardCurrentImportAssets() {
        if let document = pendingDocumentCommit {
            document.allImageFileNames.forEach {
                appState.removeStoredImage(fileName: $0, isVaulted: document.isVaulted)
            }
            if let sourceFileName = document.sourceFileName {
                appState.removeStoredSource(fileName: sourceFileName, isVaulted: document.isVaulted)
            }
        }
        pendingDocumentCommit = nil
        pendingRenderedImport = nil

        if let retryImportURL {
            SharedImportStore.removeTemporaryFile(retryImportURL)
        }
        retryImportURL = nil
        retryImportSource = "file"
        cleanupStagedSource()
    }

    private func cleanupStagedSource() {
        guard let stagedSourceFileName else { return }
        appState.removeStoredSource(fileName: stagedSourceFileName)
        self.stagedSourceFileName = nil
    }

    private func rollbackImportAssets(_ imageFileNames: [String], sourceFileName: String?) {
        imageFileNames.forEach { appState.removeStoredImage(fileName: $0) }
        if let sourceFileName {
            appState.removeStoredSource(fileName: sourceFileName)
        }
        if stagedSourceFileName == sourceFileName {
            stagedSourceFileName = nil
        }
    }

    /// Always returns .photo so the actual scanned/imported image is rendered
    /// in the editor. Vector templates (dniESP, passportUSA, etc.) are
    /// display-only demo assets — they must never replace a real scan.
    /// OCR-detected metadata (fields, kind label, category) is still stored on
    /// the DocumentItem for smart-field overlays and mode-chip suggestions.
    private func resolveDocumentKind(
        detectedType: OCRService.DetectedDocumentType,
        country: String?,
        mrzFormat: String?
    ) -> DocumentKind {
        return .photo
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
