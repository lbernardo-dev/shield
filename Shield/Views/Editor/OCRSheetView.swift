import SwiftUI

// MARK: - OCRSheetView

struct OCRSheetView: View {
    let doc: DocumentItem
    let lang: AppLanguage
    var onMaskField: (CGRect) -> Void
    @Binding var isPresented: Bool

    @State private var copiedKey: String? = nil
    @State private var ocrLines: [String] = []
    @State private var isRunningOCR: Bool = false
    @State private var ocrError: String? = nil
    @State private var ocrFields: DocumentFields? = nil
    @State private var showFullText = false

    // Resolved fields: prefer OCR result if available, fallback to doc.fields
    private var resolvedFields: DocumentFields {
        ocrFields ?? doc.fields
    }

    private var items: [(key: String, label: String, value: String, boxIndex: Int)] {
        let f = resolvedFields
        return [
            ("docNum",  L10nKey.documentNumber.string(lang: lang), f.documentNumber, 0),
            ("name",    L10nKey.fullName.string(lang: lang),       f.fullName, 1),
            ("dob",     L10nKey.dateOfBirth.string(lang: lang),    f.dateOfBirth, 4),
            ("expires", L10nKey.expires.string(lang: lang),        f.expires, 5),
            ("nat",     L10nKey.nationality.string(lang: lang),    f.nationality, 2),
            ("addr",    L10nKey.address.string(lang: lang),        f.address, 3),
        ]
    }

    private var confidenceByItemKey: [String: Double] {
        let src = resolvedFields.ocrFieldConfidence ?? [:]
        return [
            "docNum": src["documentNumber"] ?? 0,
            "name": src["fullName"] ?? 0,
            "dob": src["dateOfBirth"] ?? 0,
            "expires": src["expires"] ?? 0,
            "nat": src["nationality"] ?? 0,
            "addr": src["address"] ?? 0
        ]
    }

    private var boxes: [FieldBox] {
        DocumentFieldBoxes.boxes(for: doc.kind)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10nKey.fieldsLabel.string(lang: lang))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(ShieldTheme.textPrimary)
                    HStack(spacing: 5) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(ShieldTheme.success)
                        Text(L10nKey.onDevice.string(lang: lang))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ShieldTheme.success)
                    }
                }
                Spacer()
                if doc.imageFileName != nil && !isRunningOCR {
                    Button { runOCR() } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "text.viewfinder")
                                .font(.system(size: 12, weight: .semibold))
                            Text(lang == .es ? "Releer" : "Reread")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(ShieldTheme.accent)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(ShieldTheme.accentDim)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.leading, 8)
            }
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.bottom, 14)

            // OCR status
            if isRunningOCR {
                HStack(spacing: 10) {
                    ProgressView().scaleEffect(0.7).tint(ShieldTheme.accent)
                    Text(lang == .es ? "Analizando imagen…" : "Analyzing image…")
                        .font(.system(size: 13))
                        .foregroundColor(ShieldTheme.textSecondary)
                }
                .padding(.vertical, 8)
            } else if let err = ocrError {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(ShieldTheme.danger)
                    .padding(.horizontal, ShieldTheme.s5)
                    .padding(.bottom, 6)
            }

            if let detectedType = resolvedFields.ocrDocumentType, !detectedType.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.viewfinder")
                        .font(.system(size: 11, weight: .semibold))
                    Text(lang == .es ? "Tipo detectado: \(detectedTypeLabel(detectedType))" : "Detected type: \(detectedTypeLabel(detectedType))")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(ShieldTheme.accent)
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let mrzValid = resolvedFields.ocrMRZValid {
                HStack(spacing: 6) {
                    Image(systemName: mrzValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text(mrzValidationLabel(isValid: mrzValid, format: resolvedFields.ocrMRZFormat))
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(mrzValid ? ShieldTheme.success : ShieldTheme.warning)
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let country = resolvedFields.ocrDetectedCountry, !country.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                        .font(.system(size: 11, weight: .semibold))
                    Text(lang == .es ? "País detectado: \(country)" : "Detected country: \(country)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(ShieldTheme.textSecondary)
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if shouldShowRiskWarning, let riskText = riskWarningText() {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text(riskText)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(ShieldTheme.warning)
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.bottom, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Fields
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(items, id: \.key) { item in
                        FieldRow(
                            label: item.label,
                            value: item.value,
                            isCopied: copiedKey == item.key,
                            confidence: confidenceByItemKey[item.key] ?? 0,
                            lang: lang,
                            onCopy: {
                                UIPasteboard.general.string = item.value
                                copiedKey = item.key
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    copiedKey = nil
                                }
                            },
                            onMask: {
                                if item.boxIndex < boxes.count {
                                    onMaskField(boxes[item.boxIndex].rect)
                                } else if doc.kind == .photo {
                                    // For photo docs provide a sensible default rect
                                    onMaskField(CGRect(x: 0.1, y: 0.1, width: 0.4, height: 0.08))
                                }
                            }
                        )
                    }

                    // Raw OCR lines (collapsible, shows only for photo docs)
                    if !ocrLines.isEmpty {
                        ocrLinesSection
                    }

                    // MRZ block
                    if let mrz = resolvedFields.mrz {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(L10nKey.mrz.string(lang: lang))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(ShieldTheme.textTertiary)
                                .textCase(.uppercase)
                                .tracking(0.3)
                            Text(mrz)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(ShieldTheme.textSecondary)
                                .lineLimit(nil)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(ShieldTheme.surface3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(ShieldTheme.surfaceLine, lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    if let fullText = resolvedFields.ocrFullText, !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Button {
                                withAnimation { showFullText.toggle() }
                            } label: {
                                HStack {
                                    Text(lang == .es ? "Documento completo (OCR)" : "Full document (OCR)")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(ShieldTheme.textTertiary)
                                    Spacer()
                                    Image(systemName: showFullText ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 11))
                                        .foregroundColor(ShieldTheme.textTertiary)
                                }
                            }

                            if showFullText {
                                Text(fullText)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(ShieldTheme.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(10)
                                    .background(ShieldTheme.surface3)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            if doc.imageFileName != nil && doc.fields.fullName.isEmpty {
                runOCR()
            }
        }
    }

    // MARK: - Raw OCR section

    @State private var showRawOCR = false

    private var ocrLinesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation { showRawOCR.toggle() }
            } label: {
                HStack {
                    Text(lang == .es ? "Texto extraído (\(ocrLines.count) líneas)" : "Extracted text (\(ocrLines.count) lines)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ShieldTheme.textTertiary)
                    Spacer()
                    Image(systemName: showRawOCR ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.textTertiary)
                }
            }

            if showRawOCR {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(ocrLines.prefix(30).enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(ShieldTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(ShieldTheme.surface3)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    // MARK: - OCR logic

    private func runOCR() {
        let images = loadSourceImages()
        guard !images.isEmpty else {
            ocrError = lang == .es ? "No hay imagen disponible" : "No image available"
            return
        }

        isRunningOCR = true
        ocrError = nil

        Task {
            let pageLines = await OCRService.recognizeTextByPage(in: images)
            let lines = pageLines.flatMap { $0 }
            var fields = OCRService.extractFields(from: lines)
            let detectedType = OCRService.detectDocumentType(from: lines)
            fields.ocrDocumentType = detectedType.rawValue
            let pageTexts = pageLines.map { $0.joined(separator: "\n") }
            fields.ocrPageTexts = pageTexts
            fields.ocrFullText = pageTexts.joined(separator: "\n\n")
            fields.ocrDetectedCountry = detectCountry(from: fields)
            let risk = OCRService.assessRisk(fields: fields, detectedType: detectedType, threshold: OCRService.minimumConfidenceThreshold())
            fields.ocrRiskLevel = risk.level.rawValue
            fields.ocrLowConfidenceFields = risk.lowFields
            await MainActor.run {
                ocrLines = lines
                ocrFields = fields
                isRunningOCR = false
            }
        }
    }

    private func detectedTypeLabel(_ raw: String) -> String {
        switch raw.lowercased() {
        case "dni": return "DNI"
        case "passport": return lang == .es ? "Pasaporte" : "Passport"
        default: return lang == .es ? "Documento" : "Document"
        }
    }

    private func mrzValidationLabel(isValid: Bool, format: String?) -> String {
        let formatSuffix = format.map { " (\($0))" } ?? ""
        if lang == .es {
            return isValid ? "MRZ validada\(formatSuffix)" : "MRZ no validada\(formatSuffix)"
        }
        return isValid ? "MRZ validated\(formatSuffix)" : "MRZ not validated\(formatSuffix)"
    }

    private func loadSourceImages() -> [UIImage] {
        if let pages = doc.pageFileNames, !pages.isEmpty {
            return pages.compactMap { AppState.loadImage(fileName: $0, isVaulted: doc.isVaulted) }
        }
        if let fileName = doc.imageFileName,
           let image = AppState.loadImage(fileName: fileName, isVaulted: doc.isVaulted) {
            return [image]
        }
        return []
    }

    private func detectCountry(from fields: DocumentFields) -> String? {
        let nat = fields.nationality.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if nat.count == 3 { return nat }
        let docNum = fields.documentNumber.uppercased()
        if docNum.hasPrefix("X") || docNum.hasPrefix("Y") || docNum.hasPrefix("Z") { return "ESP" }
        if docNum.count == 9, docNum.first?.isNumber == true { return "ESP" }
        if docNum.count == 18 { return "MEX" }
        return nil
    }

    private var shouldShowRiskWarning: Bool {
        UserDefaults.standard.object(forKey: "shield.ocr.warnLowConfidence") == nil
            ? true
            : UserDefaults.standard.bool(forKey: "shield.ocr.warnLowConfidence")
    }

    private func riskWarningText() -> String? {
        guard let level = resolvedFields.ocrRiskLevel, level != "low" else { return nil }
        let lowFields = (resolvedFields.ocrLowConfidenceFields ?? [])
            .map(localizedFieldLabel)
            .joined(separator: ", ")
        if lang == .es {
            if lowFields.isEmpty {
                return "Riesgo OCR \(level.uppercased()). Revisa antes de compartir."
            }
            return "Riesgo OCR \(level.uppercased()). Campos débiles: \(lowFields)."
        }
        if lowFields.isEmpty {
            return "OCR risk \(level.uppercased()). Review before sharing."
        }
        return "OCR risk \(level.uppercased()). Weak fields: \(lowFields)."
    }

    private func localizedFieldLabel(_ key: String) -> String {
        switch key {
        case "documentNumber": return L10nKey.documentNumber.string(lang: lang)
        case "fullName": return L10nKey.fullName.string(lang: lang)
        case "dateOfBirth": return L10nKey.dateOfBirth.string(lang: lang)
        case "expires": return L10nKey.expires.string(lang: lang)
        case "nationality": return L10nKey.nationality.string(lang: lang)
        case "address": return L10nKey.address.string(lang: lang)
        default: return key
        }
    }
}

// MARK: - FieldRow

private struct FieldRow: View {
    let label: String
    let value: String
    let isCopied: Bool
    let confidence: Double
    let lang: AppLanguage
    let onCopy: () -> Void
    let onMask: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ShieldTheme.textTertiary)
                    .textCase(.uppercase)
                    .tracking(0.3)
                Text(value.isEmpty ? "—" : value)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .lineLimit(1)
                if confidence > 0 {
                    Text((lang == .es ? "Confianza: " : "Confidence: ") + "\(Int((confidence * 100).rounded()))%")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(ShieldTheme.textTertiary)
                }
            }
            Spacer()

            Button(action: onCopy) {
                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isCopied ? ShieldTheme.success : ShieldTheme.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(ShieldTheme.surface2)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button(action: onMask) {
                HStack(spacing: 4) {
                    Image(systemName: "eye.slash")
                        .font(.system(size: 11, weight: .semibold))
                    Text(lang == .es ? "Ocultar" : "Mask")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(ShieldTheme.accent)
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(ShieldTheme.accentDim)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(ShieldTheme.surface3)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ShieldTheme.surfaceLine, lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
