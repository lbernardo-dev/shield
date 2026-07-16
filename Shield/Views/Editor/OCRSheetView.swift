import SwiftUI
import FoundationModels

// MARK: - OCRSheetView

struct OCRSheetView: View {
    let doc: DocumentItem
    let lang: AppLanguage
    @Binding var currentRedactions: [Redaction]
    @Environment(\.colorScheme) var scheme
    var onMaskField: (CGRect) -> Void
    var onUnmaskField: (CGRect) -> Void
    var onFieldsUpdated: ((DocumentFields) -> Void)?
    @Binding var isPresented: Bool

    @State private var copiedKey: String? = nil
    @State private var isRunningOCR: Bool = false
    @State private var ocrError: String? = nil
    @State private var ocrFields: DocumentFields? = nil
    @State private var showFullText = false
    @State private var showRawOCR = false
    @State private var page0Observations: [OCRService.TextObservation] = []
    // Tracks which field keys the user has masked in this session
    @State private var maskedKeys: Set<String> = []

    private var resolvedFields: DocumentFields {
        ocrFields ?? doc.fields
    }

    private var items: [(key: String, label: String, value: String, boxIndex: Int)] {
        let f = resolvedFields
        var result: [(key: String, label: String, value: String, boxIndex: Int)] = [
            ("docNum",  LanguageManager.shared.model("model_field_document_number"), f.documentNumber, 0),
            ("name",    LanguageManager.shared.model("model_field_full_name"),       f.fullName, 1),
            ("dob",     LanguageManager.shared.model("model_field_date_of_birth"),    f.dateOfBirth, 4),
            ("expires", LanguageManager.shared.model("model_field_expires"),        f.expires, 5),
            ("nat",     LanguageManager.shared.model("model_field_nationality"),    f.nationality, 2),
            ("addr",    LanguageManager.shared.model("model_field_address"),        f.address, 3),
        ]
        if let sn = f.supportNumber, !sn.isEmpty {
            result.insert(("supportNum", LanguageManager.shared.model("model_field_support_number"), sn, -1), at: 1)
        }
        return result
    }

    private var confidenceByItemKey: [String: Double] {
        let src = resolvedFields.ocrFieldConfidence ?? [:]
        return [
            "docNum":     src["documentNumber"] ?? 0,
            "supportNum": src["supportNumber"] ?? 0,
            "name":       src["fullName"] ?? 0,
            "dob":        src["dateOfBirth"] ?? 0,
            "expires":    src["expires"] ?? 0,
            "nat":        src["nationality"] ?? 0,
            "addr":       src["address"] ?? 0,
        ]
    }

    private var boxes: [FieldBox] {
        DocumentFieldBoxes.boxes(for: doc.kind)
    }

    // Fields that have a non-empty value (can be actioned)
    private var detectedItems: [(key: String, label: String, value: String, boxIndex: Int)] {
        items.filter { !$0.value.isEmpty }
    }

    private var missingItems: [(key: String, label: String, value: String, boxIndex: Int)] {
        items.filter { $0.value.isEmpty }
    }

    private var maskedCount: Int { maskedKeys.count }
    private var detectedCount: Int { detectedItems.count }
    private var hasSourceImage: Bool {
        doc.imageFileName != nil || !(doc.pageFileNames ?? []).isEmpty
    }
    private var effectiveObservations: [OCRService.TextObservation] {
        if !page0Observations.isEmpty {
            return page0Observations
        }
        guard let texts = resolvedFields.ocrBoundingTexts,
              let rects = resolvedFields.ocrBoundingRects else {
            return []
        }
        return zip(texts, rects).map {
            OCRService.TextObservation(text: $0.0, boundingRect: $0.1, confidence: 0.5)
        }
    }

    private var allFieldsMaskedText: String {
        lang == .es ? "Todos los campos sensibles están ocultos" : "All sensitive fields are hidden"
    }

    private func visibleFieldsText(_ count: Int) -> String {
        if lang == .es {
            return count == 1 ? "Queda 1 campo visible" : "Quedan \(count) campos visibles"
        }
        return "\(count) field\(count == 1 ? "" : "s") still visible"
    }

    private var maskAllText: String {
        lang == .es ? "Ocultar todo" : "Mask all"
    }

    private var unmaskAllText: String {
        lang == .es ? "Mostrar todo" : "Unmask all"
    }

    private var detectedFieldsTitle: String {
        lang == .es ? "Campos detectados" : "Detected fields"
    }

    private var missingFieldsTitle: String {
        lang == .es ? "No detectados" : "Not detected"
    }

    private var noFieldsDetectedText: String {
        lang == .es ? "No se han detectado campos. Toca Releer para intentarlo otra vez." : "No fields detected. Tap Reread to try again."
    }

    private var maskToggleText: String {
        lang == .es ? "Ocultar" : "Mask"
    }

    private var unmaskToggleText: String {
        lang == .es ? "Mostrar" : "Unmask"
    }

    private func maskedSummaryText(masked: Int, total: Int) -> String {
        if lang == .es {
            return "\(masked)/\(total) campos ocultos"
        }
        return "\(masked)/\(total) fields masked"
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().background(ShieldTheme.line(scheme))
            statusRow
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    summaryBanner
                    detectedFieldsSection
                    if !missingItems.isEmpty {
                        missingFieldsSection
                    }
                    extraSections
                }
                .padding(.bottom, 36)
            }
            footer
        }
        .background(ShieldTheme.background(scheme))
        .onAppear {
            syncMaskedKeysFromRedactions()
            if hasSourceImage {
                runOCR()
            }
        }
        .onChange(of: currentRedactions.count) {
            syncMaskedKeysFromRedactions()
        }
        .onChange(of: currentRedactions.map { $0.rect.midX + $0.rect.midY }) {
            syncMaskedKeysFromRedactions()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(LanguageManager.shared.model("model_detected_fields"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(ShieldTheme.primary(scheme))
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(ShieldTheme.success)
                    Text(LanguageManager.shared.common("common_on_device"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ShieldTheme.success)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer()
            if hasSourceImage && !isRunningOCR {
                Button { runOCR() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                        Text(LanguageManager.shared.editor("editor_ocr_reread"))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(ShieldTheme.accent(scheme))
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(ShieldTheme.accentDim(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(ShieldTheme.accentStroke(scheme), lineWidth: 0.8)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            if isRunningOCR {
                HStack(spacing: 6) {
                    ProgressView().scaleEffect(0.75).tint(ShieldTheme.accent(scheme))
                    Text(LanguageManager.shared.editor("editor_ocr_analyzing"))
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.secondary(scheme))
                }
            }
            Button { isPresented = false } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                    .frame(width: 28, height: 28)
                    .background(ShieldTheme.rowBackground(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            Divider().background(ShieldTheme.line(scheme))
            HStack {
                Button {
                    isPresented = false
                } label: {
                    Text(LanguageManager.shared.common("common_done"))
                        .font(.system(size: 14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(ShieldTheme.accent(scheme))
                        .foregroundColor(ShieldTheme.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.vertical, 12)
            .background(ShieldTheme.background(scheme))
        }
    }

    // MARK: - Status row (doc type / country / MRZ / risk)

    @ViewBuilder
    private var statusRow: some View {
        if !isRunningOCR {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if let t = resolvedFields.ocrDocumentType, !t.isEmpty, t != "(null)" {
                            statusPill(icon: "doc.text.viewfinder",
                                       text: detectedTypeLabel(t),
                                       color: ShieldTheme.accent)
                        }
                        if let c = resolvedFields.ocrDetectedCountry, !c.isEmpty, c != "(null)" {
                            statusPill(icon: "globe", text: c, color: ShieldTheme.secondary(scheme))
                        }
                        if let mrzValid = resolvedFields.ocrMRZValid {
                            statusPill(
                                icon: mrzValid ? "checkmark.seal.fill" : "exclamationmark.triangle.fill",
                                text: mrzValid ? "MRZ ✓" : "MRZ ✗",
                                color: mrzValid ? ShieldTheme.success : ShieldTheme.warning
                            )
                        }
                        if let level = resolvedFields.ocrRiskLevel, level != "low" {
                            statusPill(icon: "exclamationmark.triangle.fill",
                                       text: "OCR \(level.uppercased())",
                                       color: ShieldTheme.warning)
                        }
                        if let err = ocrError {
                            statusPill(icon: "xmark.circle.fill", text: err, color: ShieldTheme.danger)
                        }
                    }
                    .padding(.horizontal, ShieldTheme.s5)
                    .padding(.vertical, 8)
                }
                Divider().background(ShieldTheme.line(scheme))
            }
        }
    }

    private func statusPill(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 10, weight: .semibold))
            Text(text).font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }

    // MARK: - Summary banner

    private var summaryBanner: some View {
        let total = detectedCount
        let masked = maskedCount
        let allMasked = total > 0 && masked >= total
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(maskedSummaryText(masked: masked, total: total))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(allMasked ? ShieldTheme.success : ShieldTheme.primary(scheme))
                Text(allMasked
                     ? allFieldsMaskedText
                     : visibleFieldsText(total - masked))
                    .font(.system(size: 11))
                    .foregroundColor(ShieldTheme.secondary(scheme))
            }
            Spacer()
            if total > 0 {
                Button {
                    if allMasked {
                        unmaskAll()
                    } else {
                        maskAll()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: allMasked ? "eye" : "eye.slash")
                            .font(.system(size: 11, weight: .bold))
                        Text(allMasked ? unmaskAllText : maskAllText)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(allMasked ? ShieldTheme.secondary(scheme) : ShieldTheme.accent)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(allMasked ? ShieldTheme.rowBackground(scheme) : ShieldTheme.accentDim(scheme))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(allMasked ? ShieldTheme.line(scheme) : ShieldTheme.accentStroke(scheme), lineWidth: 0.8)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.vertical, 12)
        .background(ShieldTheme.cardBackground(scheme))
    }

    // MARK: - Detected fields section

    private var detectedFieldsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(
                title: detectedFieldsTitle,
                count: detectedCount,
                color: ShieldTheme.success
            )
            if detectedItems.isEmpty && !isRunningOCR {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                    Text(noFieldsDetectedText)
                        .font(.system(size: 13))
                        .foregroundColor(ShieldTheme.secondary(scheme))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, ShieldTheme.s5)
            } else {
                VStack(spacing: 6) {
                    ForEach(detectedItems, id: \.key) { item in
                        fieldRow(item: item)
                    }
                }
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Missing fields section

    private var missingFieldsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader(title: missingFieldsTitle, count: missingItems.count, color: ShieldTheme.tertiary(scheme))
            VStack(spacing: 4) {
                ForEach(missingItems, id: \.key) { item in
                    HStack(spacing: 10) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 12))
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                        Text(item.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(ShieldTheme.cardBackground(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Extra sections (MRZ / raw text)

    private var extraSections: some View {
        VStack(spacing: 0) {
            // MRZ block
            if let mrz = resolvedFields.mrz {
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(title: "MRZ", count: nil, color: ShieldTheme.accent(scheme))
                    Text(mrz)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(ShieldTheme.secondary(scheme))
                        .lineLimit(nil)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(ShieldTheme.rowBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal, ShieldTheme.s5)
                }
                .padding(.bottom, 8)
            }

            // Full text (collapsible)
            if let fullText = resolvedFields.ocrFullText,
               !fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) { showFullText.toggle() }
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .font(.system(size: 11))
                                .foregroundColor(ShieldTheme.tertiary(scheme))
                            Text(LanguageManager.shared.editor("editor_ocr_full_doc"))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(ShieldTheme.tertiary(scheme))
                            Spacer()
                            Image(systemName: showFullText ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11))
                                .foregroundColor(ShieldTheme.tertiary(scheme))
                        }
                        .padding(.horizontal, ShieldTheme.s5)
                        .padding(.vertical, 10)
                    }
                    if showFullText {
                        Text(fullText)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(ShieldTheme.secondary(scheme))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(ShieldTheme.rowBackground(scheme))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .padding(.horizontal, ShieldTheme.s5)
                            .padding(.bottom, 8)
                    }
                }
            }
        }
    }

    // MARK: - Field row

    @ViewBuilder
    private func fieldRow(item: (key: String, label: String, value: String, boxIndex: Int)) -> some View {
        let isMasked = maskedKeys.contains(item.key)
        let confidence = confidenceByItemKey[item.key] ?? 0
        let confidenceColor: Color = confidence >= 0.85 ? ShieldTheme.success
                                   : confidence >= 0.65 ? ShieldTheme.warning
                                   : ShieldTheme.danger

        HStack(spacing: 10) {
            // Masked indicator strip
            RoundedRectangle(cornerRadius: 2)
                .fill(isMasked ? ShieldTheme.success : ShieldTheme.line(scheme))
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.label.uppercased())
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .tracking(0.4)
                    if confidence > 0 {
                        Capsule()
                            .fill(confidenceColor.opacity(0.18))
                            .frame(height: 14)
                            .overlay(
                                Text("\(Int((confidence * 100).rounded()))%")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(confidenceColor)
                            )
                            .frame(width: 34)
                    }
                }
                Text(item.value)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(isMasked ? ShieldTheme.tertiary(scheme) : ShieldTheme.primary(scheme))
                    .lineLimit(2)
                    .strikethrough(isMasked, color: ShieldTheme.tertiary(scheme))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(item.label)
            .accessibilityValue(
                confidence > 0
                    ? "\(item.value), \(Int((confidence * 100).rounded()))%"
                    : item.value
            )

            Spacer(minLength: 4)

            // Copy button
            if !isMasked {
                Button {
                    UIPasteboard.general.string = item.value
                    copiedKey = item.key
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { copiedKey = nil }
                } label: {
                    Image(systemName: copiedKey == item.key ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(copiedKey == item.key ? ShieldTheme.success : ShieldTheme.tertiary(scheme))
                        .frame(width: 30, height: 30)
                        .background(ShieldTheme.cardBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
                .accessibilityLabel(
                    copiedKey == item.key
                        ? (lang == .es ? "Copiado" : "Copied")
                        : (lang == .es ? "Copiar \(item.label)" : "Copy \(item.label)")
                )
            }

            // Mask / Unmask button
            Button {
                toggleMask(item: item)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: isMasked ? "eye" : "eye.slash")
                        .font(.system(size: 11, weight: .bold))
                    Text(isMasked ? unmaskToggleText : maskToggleText)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(isMasked ? ShieldTheme.success : ShieldTheme.accent(scheme))
                .padding(.horizontal, 10)
                .frame(height: 30)
                .background(isMasked ? ShieldTheme.success.opacity(0.15) : ShieldTheme.accentDim(scheme))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isMasked ? ShieldTheme.success.opacity(0.25) : ShieldTheme.accentStroke(scheme), lineWidth: 0.8)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityLabel("\(isMasked ? unmaskToggleText : maskToggleText) \(item.label)")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isMasked ? ShieldTheme.success.opacity(0.06) : ShieldTheme.rowBackground(scheme))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isMasked ? ShieldTheme.success.opacity(0.3) : ShieldTheme.line(scheme), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: isMasked)
    }

    private func sectionHeader(title: String, count: Int?, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(ShieldTheme.tertiary(scheme))
                .tracking(0.6)
            if let count {
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(color.opacity(0.15))
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
    }

    // MARK: - Mask / Unmask logic

    private func toggleMask(item: (key: String, label: String, value: String, boxIndex: Int)) {
        if maskedKeys.contains(item.key) {
            // Unmask: remove the redaction near the field's rect
            if let rect = ocrRectForField(key: item.key) {
                onUnmaskField(rect)
            } else if item.boxIndex >= 0 && item.boxIndex < boxes.count {
                onUnmaskField(boxes[item.boxIndex].rect)
            }
            maskedKeys.remove(item.key)
        } else {
            // Mask: add redaction
            if let rect = ocrRectForField(key: item.key) {
                onMaskField(rect)
                maskedKeys.insert(item.key)
            } else if item.boxIndex >= 0 && item.boxIndex < boxes.count {
                onMaskField(boxes[item.boxIndex].rect)
                maskedKeys.insert(item.key)
            }
        }
    }

    private func maskAll() {
        for item in detectedItems where !maskedKeys.contains(item.key) {
            toggleMask(item: item)
        }
    }

    private func unmaskAll() {
        for item in detectedItems where maskedKeys.contains(item.key) {
            toggleMask(item: item)
        }
    }

    /// Sync maskedKeys from the actual redactions on canvas (e.g. after undo or external change).
    private func syncMaskedKeysFromRedactions() {
        var newMasked: Set<String> = []
        for item in items {
            guard !item.value.isEmpty else { continue }
            // Prefer OCR bounding rect; fall back to template FieldBox
            if let rect = ocrRectForField(key: item.key) {
                let isCovered = currentRedactions.contains { r in
                    abs(r.rect.midX - rect.midX) < 0.06 && abs(r.rect.midY - rect.midY) < 0.06
                }
                if isCovered { newMasked.insert(item.key) }
            } else if item.boxIndex >= 0 && item.boxIndex < boxes.count {
                let boxRect = boxes[item.boxIndex].rect
                let isCovered = currentRedactions.contains { r in
                    abs(r.rect.midX - boxRect.midX) < 0.06 && abs(r.rect.midY - boxRect.midY) < 0.06
                }
                if isCovered { newMasked.insert(item.key) }
            }
        }
        maskedKeys = newMasked
    }

    // MARK: - OCR logic

    private func runOCR() {
        let images = loadSourceImages()
        guard !images.isEmpty else {
            ocrError = LanguageManager.shared.editor("editor_ocr_error_no_image")
            return
        }
        isRunningOCR = true
        ocrError = nil
        // Don't clear maskedKeys here — preserve the visual state during re-analysis

        Task {
            let pageObs = await OCRService.recognizeObservationsByPageAdaptive(in: images)
            let allObs = pageObs.flatMap { $0 }
            let lines = allObs.map(\.text)
            var fields = OCRService.extractFields(from: lines)
            let detectedType = OCRService.detectDocumentType(from: lines)
            fields.ocrDocumentType = detectedType.rawValue
            let pageTexts = pageObs.map { $0.map(\.text).joined(separator: "\n") }
            fields.ocrPageTexts = pageTexts
            let fullText = pageTexts.joined(separator: "\n\n")
            fields.ocrFullText = fullText
            fields.ocrDetectedCountry = detectCountry(from: fields, lines: lines)
            let p0obs = pageObs.first ?? []
            fields.ocrBoundingTexts = p0obs.map(\.text)
            fields.ocrBoundingRects = p0obs.map(\.boundingRect)

            // Smart enrichment pass: use on-device Foundation Model to fill missing fields
            if SmartFieldExtractor.isAvailable() {
                if let enriched = await SmartFieldExtractor.enrich(fields: fields, ocrText: fullText) {
                    fields = enriched
                }
            }

            let risk = OCRService.assessRisk(fields: fields, detectedType: detectedType,
                                             threshold: OCRService.minimumConfidenceThreshold())
            fields.ocrRiskLevel = risk.level.rawValue
            fields.ocrLowConfidenceFields = risk.lowFields

            await MainActor.run {
                ocrFields = fields
                page0Observations = p0obs
                isRunningOCR = false
                onFieldsUpdated?(fields)
                syncMaskedKeysFromRedactions()
            }
        }
    }

    private func loadSourceImages() -> [UIImage] {
        let rawImages: [UIImage]
        if let pages = doc.pageFileNames, !pages.isEmpty {
            rawImages = pages.compactMap { AppState.loadImage(fileName: $0, isVaulted: doc.isVaulted) }
        } else if let fileName = doc.imageFileName,
                  let image = AppState.loadImage(fileName: fileName, isVaulted: doc.isVaulted) {
            rawImages = [image]
        } else {
            rawImages = []
        }
        guard let adjustment = doc.imageAdjustment else { return rawImages }
        return rawImages.map { ExportEngine.applyImageAdjustment($0, store: adjustment) ?? $0 }
    }

    private func ocrRectForField(key: String) -> CGRect? {
        let f = resolvedFields
        let value: String
        switch key {
        case "docNum":     value = f.documentNumber
        case "supportNum": value = f.supportNumber ?? ""
        case "name":       value = f.fullName
        case "dob":        value = f.dateOfBirth
        case "expires":    value = f.expires
        case "nat":        value = f.nationality
        case "addr":       value = f.address
        default: return nil
        }
        guard !value.isEmpty else { return nil }
        let normalizedValue = normalizedOCRToken(value)
        guard !normalizedValue.isEmpty else { return nil }
        let observations = effectiveObservations

        // Exact single-token match
        if let obs = observations.first(where: { normalizedOCRToken($0.text) == normalizedValue }) {
            return padded(obs.boundingRect)
        }

        // For multi-word values (address, full name), union matching OCR tokens.
        // Match normalized tokens to tolerate OCR punctuation/accents noise.
        let words = normalizedValue.components(separatedBy: .whitespaces).filter { $0.count >= 3 }
        guard !words.isEmpty else {
            if let obs = observations.first(where: { normalizedOCRToken($0.text) == normalizedValue }) {
                return padded(obs.boundingRect)
            }
            return nil
        }
        var matched: [OCRService.TextObservation] = []
        for obs in observations {
            let candidate = normalizedOCRToken(obs.text)
            if candidate.count >= 3 && normalizedValue.contains(candidate) {
                matched.append(obs)
            }
        }
        guard !matched.isEmpty else { return nil }
        let union = matched.dropFirst().reduce(matched[0].boundingRect) { $0.union($1.boundingRect) }
        return padded(union)
    }

    private func normalizedOCRToken(_ value: String) -> String {
        let folded = value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let filtered = folded.replacingOccurrences(of: "[^A-Za-z0-9 ]+", with: " ", options: .regularExpression)
        return filtered
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private func padded(_ r: CGRect) -> CGRect {
        let dx = max(0.005, r.width  * 0.10)
        let dy = max(0.006, r.height * 0.20)
        return r.insetBy(dx: -dx, dy: -dy)
            .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
    }

    private func detectCountry(from fields: DocumentFields, lines: [String]) -> String? {
        let nat = fields.nationality.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if nat.count == 3 { return nat }
        let combined = lines.joined(separator: " ").uppercased()
        if combined.contains("ESPAÑA") || combined.contains("DNI") || combined.contains("REINO DE ESP") { return "ESP" }
        let docNum = fields.documentNumber.uppercased()
        if docNum.hasPrefix("X") || docNum.hasPrefix("Y") || docNum.hasPrefix("Z") { return "ESP" }
        if docNum.count == 9, docNum.last?.isLetter == true { return "ESP" }
        return nil
    }

    private func detectedTypeLabel(_ raw: String) -> String {
        switch raw.lowercased() {
        case "dni": return lang == .es ? "DNI / Identidad" : "DNI / ID Card"
        case "passport": return LanguageManager.shared.editor("editor_ocr_passport")
        case "drivinglicense": return lang == .es ? "Carnet de conducir" : "Driving Licence"
        case "residencepermit": return lang == .es ? "Permiso de residencia" : "Residence Permit"
        case "healthcard": return lang == .es ? "Tarjeta sanitaria" : "Health Card"
        default: return LanguageManager.shared.editor("editor_ocr_doc")
        }
    }
}
