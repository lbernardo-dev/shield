import SwiftUI
import VisionKit
import PhotosUI
import Vision
import UIKit
import UniformTypeIdentifiers
import PDFKit

// MARK: - CaptureView

struct CaptureView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @State private var showSourcePicker = false
    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var showPaywall = false
    @State private var isProcessing = false
    @State private var processingMessage = ""

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
            DocumentScannerView { image in
                showScanner = false
                processImage(image, title: nil)
            } onCancel: {
                showScanner = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView { image in
                showPhotoPicker = false
                processImage(image, title: nil)
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
            PaywallView(isPresented: $showPaywall).environmentObject(appState)
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
                Text(appState.language == .es ? "Añadir documento" : "Add document")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 44, height: 44)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Spacer()

            // Options
            VStack(spacing: 12) {
                captureOption(
                    icon: "camera.viewfinder",
                    title: appState.language == .es ? "Escanear documento" : "Scan document",
                    subtitle: appState.language == .es ? "Usa la cámara para escanear" : "Use camera to scan",
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
                    title: appState.language == .es ? "Desde fotos" : "From Photos",
                    subtitle: appState.language == .es ? "Selecciona una imagen" : "Pick an image",
                    primary: false
                ) {
                    guard ensureCanImportMoreDocuments() else { return }
                    showPhotoPicker = true
                }

                captureOption(
                    icon: "folder",
                    title: appState.language == .es ? "Desde archivos" : "From Files",
                    subtitle: appState.language == .es ? "PDF, imágenes y más" : "PDF, images and more",
                    primary: false
                ) {
                    guard ensureCanImportMoreDocuments() else { return }
                    showFilePicker = true
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Privacy note
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "666666"))
                Text(appState.language == .es
                     ? "Todo se procesa en el dispositivo. Sin servidores."
                     : "Processed on-device. No servers.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "666666"))
            }
            .padding(.bottom, 24)
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
        showPaywall = true
        return false
    }

    private func processImage(_ image: UIImage, title: String?) {
        guard pm.canAddDocument(currentCount: appState.documents.count) else {
            showPaywall = true
            return
        }
        isProcessing = true
        processingMessage = appState.language == .es ? "Reconociendo texto…" : "Recognizing text…"

        Task {
            // Run OCR
            let lines = await OCRService.recognizeText(in: image)
            let fields = OCRService.extractFields(from: lines)

            // Save image
            let docID = UUID().uuidString
            let fileName = appState.saveImage(image, id: docID)

            // Determine doc title
            let docTitle: String
            if let t = title, !t.isEmpty {
                docTitle = t
            } else if !fields.fullName.isEmpty {
                docTitle = fields.fullName
            } else {
                let fmt = DateFormatter()
                fmt.dateFormat = "d MMM HH:mm"
                docTitle = appState.language == .es
                    ? "Documento \(fmt.string(from: Date()))"
                    : "Document \(fmt.string(from: Date()))"
            }

            let doc = DocumentItem(
                id: docID,
                kind: .photo,
                title: docTitle,
                category: .identity,
                date: Date(),
                redactionCount: 0,
                isFavorite: false,
                isLocked: false,
                isVaulted: false,
                imageFileName: fileName,
                sourceType: .image,
                fields: fields,
                pageRedactions: [],
                watermark: nil
            )

            await MainActor.run {
                appState.addDocument(doc)
                isProcessing = false
                appState.selectedDoc = doc
                appState.showCapture = false
            }
        }
    }

    private func processFile(_ url: URL) {
        guard pm.canAddDocument(currentCount: appState.documents.count) else {
            showPaywall = true
            return
        }
        isProcessing = true
        processingMessage = appState.language == .es ? "Importando archivo…" : "Importing file…"

        Task {
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }

            // Try to load as UIImage first (JPEG/PNG)
            if let image = UIImage(contentsOfFile: url.path) {
                await MainActor.run { isProcessing = false }
                processImage(image, title: url.deletingPathExtension().lastPathComponent)
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
                processPDFPages(
                    pages,
                    title: pdfTitle,
                    docID: docID,
                    sourceFileName: sourceFileName
                )
                return
            }

            // Unsupported
            await MainActor.run {
                isProcessing = false
                appState.showCapture = false
            }
        }
    }

    private func processPDFPages(_ pages: [UIImage], title: String, docID: String, sourceFileName: String?) {
        isProcessing = true
        processingMessage = appState.language == .es ? "Procesando páginas…" : "Processing pages…"

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

            // OCR first page for fields
            let lines = await OCRService.recognizeText(in: pages[0])
            let fields = OCRService.extractFields(from: lines)

            let docTitle = !fields.fullName.isEmpty ? fields.fullName : title
            let doc = DocumentItem(
                id: docID,
                kind: .photo,
                title: docTitle,
                category: .identity,
                date: Date(),
                redactionCount: 0,
                isFavorite: false,
                isLocked: false,
                isVaulted: false,
                imageFileName: pageFileNames[0],
                pageFileNames: pageFileNames.count > 1 ? pageFileNames : nil,
                sourceType: .pdf,
                sourceFileName: sourceFileName,
                fields: fields,
                pageRedactions: [],
                watermark: nil
            )

            await MainActor.run {
                appState.addDocument(doc)
                isProcessing = false
                appState.selectedDoc = doc
                appState.showCapture = false
            }
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
}

// MARK: - OCRService

enum OCRService {
    static func recognizeText(in image: UIImage) async -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { req, _ in
                let obs = req.results as? [VNRecognizedTextObservation] ?? []
                let texts = obs.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: texts)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["es-ES", "en-US", "fr-FR", "de-DE"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }
    }

    static func extractFields(from lines: [String]) -> DocumentFields {
        var docNum = ""
        var fullName = ""
        var dob = ""
        var expires = ""
        var nationality = ""
        var address = ""
        var mrz: String? = nil

        // MRZ: lines with < and length >= 20
        let mrzLines = lines.filter { $0.contains("<") && $0.count >= 20 }
        if mrzLines.count >= 2 {
            mrz = mrzLines.prefix(2).joined(separator: "\n")
            // Parse nationality from MRZ line 1 if passportUSA format: P<NAT...
            if let firstMRZ = mrzLines.first, firstMRZ.count >= 5 {
                let start = firstMRZ.index(firstMRZ.startIndex, offsetBy: 2)
                let end = firstMRZ.index(start, offsetBy: 3)
                let nat = String(firstMRZ[start..<end]).replacingOccurrences(of: "<", with: "")
                if !nat.isEmpty { nationality = nat }
            }
        }

        // Date patterns: dd/mm/yyyy, dd.mm.yyyy, dd MMM yyyy
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
        if dates.count >= 1 { dob = dates[0] }
        if dates.count >= 2 { expires = dates[1] }

        // Name: all-caps lines, no digits, length 5-60
        let nameLines = lines.filter { l in
            let stripped = l.trimmingCharacters(in: .whitespaces)
            guard stripped.count >= 5, stripped.count <= 60 else { return false }
            guard !stripped.contains("<"), !stripped.contains("/") else { return false }
            let upper = stripped.uppercased()
            return upper == stripped && stripped.rangeOfCharacter(from: .decimalDigits) == nil
        }
        if let first = nameLines.first { fullName = first }

        // Doc number: 8-16 alphanumeric chars
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

        return DocumentFields(
            documentNumber: docNum,
            fullName: fullName,
            dateOfBirth: dob,
            nationality: nationality,
            expires: expires,
            sex: "",
            address: address,
            issued: nil,
            mrz: mrz
        )
    }
}

// MARK: - DocumentScannerView (VisionKit wrapper)

struct DocumentScannerView: UIViewControllerRepresentable {
    var onScan: (UIImage) -> Void
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
            let image = scan.imageOfPage(at: 0)
            parent.onScan(image)
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

// MARK: - PhotoPickerView (PhotosUI wrapper)

struct PhotoPickerView: UIViewControllerRepresentable {
    var onPick: (UIImage) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
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
            guard let result = results.first else { parent.onCancel(); return }
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                DispatchQueue.main.async {
                    if let image = object as? UIImage {
                        self?.parent.onPick(image)
                    } else {
                        self?.parent.onCancel()
                    }
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
