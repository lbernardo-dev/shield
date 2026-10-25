import SwiftUI

// MARK: - PrivacyInspectorTab

enum PrivacyInspectorTab: String, CaseIterable, Identifiable {
    case detections
    case mask
    case watermark
    case export

    var id: String { rawValue }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .detections:
            return lang == .es ? "Detecciones" : "Detections"
        case .mask:
            return lang == .es ? "Máscara" : "Mask"
        case .watermark:
            return lang == .es ? "Marca Agua" : "Watermark"
        case .export:
            return lang == .es ? "Exportar" : "Export"
        }
    }

    var icon: String {
        switch self {
        case .detections: return "text.viewfinder"
        case .mask:       return "rectangle.dashed"
        case .watermark:  return "drop.halffull"
        case .export:     return "square.and.arrow.up"
        }
    }
}

// MARK: - EditorPrivacyInspector

struct EditorPrivacyInspector: View {
    @ObservedObject var vm: EditorViewModel
    let lang: AppLanguage
    let isPro: Bool
    let searchQuery: String
    @Binding var activeTab: PrivacyInspectorTab
    let onOpenOCR: () -> Void
    let onPersist: () -> Void
    var onTriggerPaywall: () -> Void
    @Environment(\.colorScheme) private var scheme
    @State private var revealedSearchMatchIDs: Set<String> = []

    private var currentSearchOccurrences: [LocalSearchOccurrence] {
        vm.doc.localSearchOccurrences(for: searchQuery, pageIndex: vm.currentPage)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Inspector Tab Bar
            tabSelector
                .padding(.horizontal, ShieldTheme.s3)
                .padding(.vertical, ShieldTheme.s2)
                .background(ShieldTheme.cardBackground(scheme))

            Divider()

            // Inspector Content. The empty detections state uses the available
            // panel height so it does not bunch up below the actions with a
            // large unused area underneath on Duo and iPad.
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: ShieldTheme.s4) {
                        switch activeTab {
                        case .detections:
                            detectionsSection
                        case .mask:
                            maskPropertiesSection
                        case .watermark:
                            watermarkSection
                        case .export:
                            exportSection
                        }
                    }
                    .padding(ShieldTheme.s4)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                }
                .accessibilityIdentifier("editor.inspector.scroll")
            }
        }
        .background(ShieldTheme.cardBackground(scheme))
        .onChange(of: searchQuery) { _, _ in
            revealedSearchMatchIDs.removeAll()
        }
        .onChange(of: vm.currentPage) { _, _ in
            revealedSearchMatchIDs.removeAll()
        }
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 4) {
            ForEach(PrivacyInspectorTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        activeTab = tab
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.icon)
                            .shieldFont(14, weight: activeTab == tab ? .bold : .medium)
                        Text(tab.label(lang: lang))
                            .shieldFont(10, weight: activeTab == tab ? .bold : .medium)
                            .lineLimit(1)
                    }
                    .foregroundStyle(activeTab == tab ? ShieldTheme.accent(scheme) : ShieldTheme.secondary(scheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(activeTab == tab ? ShieldTheme.accentDim(scheme) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label(lang: lang))
                .accessibilityIdentifier("editor.inspector.tab.\(tab.id)")
                .accessibilityAddTraits(activeTab == tab ? [.isSelected, .isButton] : .isButton)
            }
        }
    }

    // MARK: - Detections Section

    private var detectionsSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            if !currentSearchOccurrences.isEmpty {
                localSearchSection
            }

            HStack {
                Text(lang == .es ? "DATOS SENSIBLES DETECTADOS" : "DETECTED SENSITIVE DATA")
                    .shieldFont(11, weight: .bold)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                Spacer()
                let totalDetected = detectedFields.count
                Text("\(totalProtectedCount)/\(totalDetected) \(lang == .es ? "protegidos" : "protected")")
                    .shieldFont(10, weight: .semibold)
                    .foregroundStyle(totalProtectedCount == totalDetected && totalDetected > 0 ? ShieldTheme.success : ShieldTheme.warning)
            }

            // Mass Actions
            HStack(spacing: ShieldTheme.s2) {
                Button {
                    protectAllDetected()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                        Text(lang == .es ? "Proteger todos" : "Protect All")
                    }
                    .shieldFont(11, weight: .bold)
                    .foregroundStyle(ShieldTheme.accentText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(ShieldTheme.accent(scheme), in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(!detectedFields.contains { !isFieldProtected($0) })
                .opacity(detectedFields.contains { !isFieldProtected($0) } ? 1 : 0.55)
                .accessibilityIdentifier("editor.inspector.protectAll")

                Button {
                    clearCurrentPageRedactions()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark.circle")
                        Text(lang == .es ? "Limpiar" : "Clear")
                    }
                    .shieldFont(11, weight: .semibold)
                    .foregroundStyle(ShieldTheme.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(ShieldTheme.dangerDim, in: RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(vm.redactions.isEmpty)
                .opacity(vm.redactions.isEmpty ? 0.55 : 1)
                .accessibilityIdentifier("editor.inspector.clear")
            }

            // Detected items list
            if detectedFields.isEmpty {
                Spacer(minLength: ShieldTheme.s4)
                VStack(spacing: ShieldTheme.s2) {
                    Image(systemName: "text.badge.checkmark")
                        .shieldFont(24)
                        .foregroundStyle(ShieldTheme.tertiary(scheme))
                    Text(lang == .es ? "No se han detectado campos automáticamente en esta página." : "No fields automatically detected on this page.")
                        .shieldFont(12)
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                        .multilineTextAlignment(.center)
                    Text(LanguageManager.shared.editor("editor_ocr_empty_inspector_explanation"))
                        .shieldFont(11)
                        .foregroundStyle(ShieldTheme.tertiary(scheme))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)

                    Button(action: onOpenOCR) {
                        Label(
                            LanguageManager.shared.editor("editor_ocr_empty_inspector_action"),
                            systemImage: "text.viewfinder"
                        )
                        .shieldFont(12, weight: .bold)
                        .foregroundStyle(ShieldTheme.accentText)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .background(ShieldTheme.accent(scheme), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("editor.inspector.openOCR")
                }
                .frame(maxWidth: .infinity)
                Spacer(minLength: ShieldTheme.s4)
            } else {
                VStack(spacing: 8) {
                    ForEach(detectedFields, id: \.key) { field in
                        let isProtected = isFieldProtected(field)
                        HStack(spacing: 8) {
                            Image(systemName: isProtected ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .shieldFont(14)
                                .foregroundStyle(isProtected ? ShieldTheme.success : ShieldTheme.warning)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(field.label)
                                    .shieldFont(12, weight: .semibold)
                                    .foregroundStyle(ShieldTheme.primary(scheme))
                                Text(field.value)
                                    .shieldFont(11)
                                    .foregroundStyle(ShieldTheme.secondary(scheme))
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button {
                                toggleFieldProtection(field)
                            } label: {
                                Text(isProtected ? (lang == .es ? "Desmarcar" : "Unmask") : (lang == .es ? "Proteger" : "Protect"))
                                    .shieldFont(11, weight: .bold)
                                    .foregroundStyle(isProtected ? ShieldTheme.secondary(scheme) : ShieldTheme.accentText)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(isProtected ? ShieldTheme.rowBackground(scheme) : ShieldTheme.accent(scheme))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(ShieldTheme.s2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(ShieldTheme.rowBackground(scheme).opacity(0.6))
                        )
                    }
                }
            }

            if !vm.currentPageFaceSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: ShieldTheme.s2) {
                    Text(LanguageManager.shared.editor("editor_face_suggestions_section"))
                        .shieldFont(11, weight: .bold)
                        .foregroundStyle(ShieldTheme.secondary(scheme))

                    Text(LanguageManager.shared.editor("editor_face_suggestions_guidance"))
                        .shieldFont(11)
                        .foregroundStyle(ShieldTheme.tertiary(scheme))
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(Array(vm.currentPageFaceSuggestions.enumerated()), id: \.element.id) { index, suggestion in
                        let isProtected = vm.isFaceSuggestionProtected(suggestion)
                        HStack(spacing: 8) {
                            Image(systemName: isProtected ? "checkmark.circle.fill" : "face.smiling")
                                .foregroundStyle(isProtected ? ShieldTheme.success : ShieldTheme.warning)
                            Text(LanguageManager.shared.editor("editor_face_suggestions_item", index + 1))
                                .shieldFont(12, weight: .semibold)
                                .foregroundStyle(ShieldTheme.primary(scheme))
                            Text("Vision \(Int(suggestion.confidence * 100))%")
                                .shieldFont(10, weight: .medium, design: .monospaced)
                                .foregroundStyle(ShieldTheme.tertiary(scheme))
                            Spacer(minLength: 4)
                            Button {
                                vm.acceptFaceSuggestion(suggestion)
                                onPersist()
                            } label: {
                                Text(LanguageManager.shared.editor(
                                    isProtected ? "editor_face_suggestions_protected" : "editor_face_suggestions_protect"
                                ))
                                    .shieldFont(11, weight: .bold)
                                    .foregroundStyle(isProtected ? ShieldTheme.secondary(scheme) : ShieldTheme.accentText)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                .frame(minHeight: 44)
                                .contentShape(Rectangle())
                                    .background(
                                        isProtected
                                            ? ShieldTheme.rowBackground(scheme)
                                            : ShieldTheme.accent(scheme),
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(isProtected)
                            .accessibilityIdentifier("editor.inspector.faceSuggestion.\(index)")
                            Button {
                                vm.dismissFaceSuggestion(suggestion)
                                onPersist()
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .shieldFont(14, weight: .semibold)
                                    .foregroundStyle(ShieldTheme.tertiary(scheme))
                                    .frame(width: 44, height: 44)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(LanguageManager.shared.editor("editor_face_suggestions_dismiss"))
                            .accessibilityIdentifier("editor.inspector.dismissFaceSuggestion.\(index)")
                        }
                    }
                }
                .padding(ShieldTheme.s3)
                .background(ShieldTheme.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var localSearchSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s2) {
            HStack(spacing: ShieldTheme.s2) {
                Image(systemName: "text.magnifyingglass")
                    .foregroundStyle(ShieldTheme.selection(scheme))
                Text(LanguageManager.shared.editor("editor_local_search_matches_heading"))
                    .shieldFont(11, weight: .bold)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                Spacer()
                Text("\(currentSearchOccurrences.count)")
                    .shieldFont(11, weight: .bold, design: .monospaced)
                    .foregroundStyle(ShieldTheme.selection(scheme))
            }

            ForEach(Array(currentSearchOccurrences.enumerated()), id: \.element.id) { index, occurrence in
                let isRevealed = revealedSearchMatchIDs.contains(occurrence.id)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(LanguageManager.shared.editor(
                            "editor_local_search_match_page",
                            index + 1,
                            occurrence.pageIndex + 1
                        ))
                            .shieldFont(11, weight: .semibold)
                            .foregroundStyle(ShieldTheme.primary(scheme))
                        Spacer()
                        if let confidence = occurrence.confidence {
                            Text("\(Int(confidence * 100))%")
                                .shieldFont(10, weight: .medium, design: .monospaced)
                                .foregroundStyle(ShieldTheme.tertiary(scheme))
                        }
                    }

                    HStack(spacing: ShieldTheme.s2) {
                        Text(isRevealed ? occurrence.protectedText : "••••••••")
                            .shieldFont(12, weight: isRevealed ? .regular : .semibold)
                            .foregroundStyle(ShieldTheme.secondary(scheme))
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Button(LanguageManager.shared.editor(
                            isRevealed ? "editor_local_search_hide" : "editor_local_search_reveal"
                        )) {
                            if isRevealed {
                                revealedSearchMatchIDs.remove(occurrence.id)
                            } else {
                                revealedSearchMatchIDs.insert(occurrence.id)
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityIdentifier("editor.searchMatch.reveal.\(index)")
                    }
                }
                .padding(ShieldTheme.s2)
                .background(ShieldTheme.rowBackground(scheme), in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(ShieldTheme.s3)
        .background(ShieldTheme.selection(scheme).opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .accessibilityIdentifier("editor.localSearch.matches")
    }

    // MARK: - Mask Properties Section

    private var maskPropertiesSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            if let activeID = vm.activeRedactionID,
               let activeIndex = vm.redactions.firstIndex(where: { $0.id == activeID }) {
                let redaction = vm.redactions[activeIndex]

                HStack {
                    Text(lang == .es ? "MÁSCARA SELECCIONADA" : "SELECTED MASK")
                        .shieldFont(11, weight: .bold)
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                    Spacer()
                    Button {
                        vm.removeRedaction(id: activeID)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash.fill")
                            Text(lang == .es ? "Eliminar" : "Delete")
                        }
                        .shieldFont(11, weight: .bold)
                        .foregroundStyle(ShieldTheme.danger)
                    }
                    .buttonStyle(.plain)
                }

                // Mask Style Selector for Active Redaction
                maskStyleGrid(currentStyle: redaction.style) { newStyle in
                    if newStyle.isPremium && !isPro {
                        onTriggerPaywall()
                    } else {
                        var updated = redaction
                        updated.style = newStyle
                        vm.updateRedaction(updated)
                    }
                }

                // Micro-nudge controls
                Text(lang == .es ? "AJUSTE PRECISO DE POSICIÓN" : "FINE POSITION ADJUSTMENT")
                    .shieldFont(10, weight: .bold)
                    .foregroundStyle(ShieldTheme.tertiary(scheme))
                    .padding(.top, 4)

                HStack(spacing: 8) {
                    nudgeButton(icon: "arrow.left") { nudgeActive(dx: -0.01, dy: 0, dw: 0, dh: 0) }
                    nudgeButton(icon: "arrow.right") { nudgeActive(dx: 0.01, dy: 0, dw: 0, dh: 0) }
                    nudgeButton(icon: "arrow.up") { nudgeActive(dx: 0, dy: -0.01, dw: 0, dh: 0) }
                    nudgeButton(icon: "arrow.down") { nudgeActive(dx: 0, dy: 0.01, dw: 0, dh: 0) }
                    Spacer()
                    nudgeButton(icon: "minus.magnifyingglass") { nudgeActive(dx: 0, dy: 0, dw: -0.02, dh: -0.02) }
                    nudgeButton(icon: "plus.magnifyingglass") { nudgeActive(dx: 0, dy: 0, dw: 0.02, dh: 0.02) }
                }

            } else {
                // Default mask style when none is selected
                Text(lang == .es ? "ESTILO DE MÁSCARA PREDETERMINADO" : "DEFAULT MASK STYLE")
                    .shieldFont(11, weight: .bold)
                    .foregroundStyle(ShieldTheme.secondary(scheme))

                maskStyleGrid(currentStyle: vm.maskStyle) { newStyle in
                    if newStyle.isPremium && !isPro {
                        onTriggerPaywall()
                    } else {
                        vm.maskStyle = newStyle
                    }
                }

                Divider().padding(.vertical, 4)

                // List of existing masks
                HStack {
                    Text(lang == .es ? "MÁSCARAS EN ESTA PÁGINA" : "MASKS ON THIS PAGE")
                        .shieldFont(11, weight: .bold)
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                    Spacer()
                    Text("\(vm.redactions.count)")
                        .shieldFont(11, weight: .bold)
                        .foregroundStyle(ShieldTheme.accent(scheme))
                }

                if vm.redactions.isEmpty {
                    Text(lang == .es ? "Dibuja un rectángulo en el documento o selecciona una detección." : "Draw a rectangle over the document or select a detection.")
                        .shieldFont(12)
                        .foregroundStyle(ShieldTheme.tertiary(scheme))
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 6) {
                        ForEach(Array(vm.redactions.enumerated()), id: \.element.id) { index, mask in
                            Button {
                                vm.activeRedactionID = mask.id
                            } label: {
                                HStack {
                                    Text("#\(index + 1) \(mask.style.localizedLabel)")
                                        .shieldFont(12, weight: .medium)
                                        .foregroundStyle(ShieldTheme.primary(scheme))
                                    Spacer()
                                    Text("\(Int(mask.rect.width * 100))% × \(Int(mask.rect.height * 100))%")
                                        .shieldFont(10)
                                        .foregroundStyle(ShieldTheme.tertiary(scheme))
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(ShieldTheme.rowBackground(scheme))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func nudgeButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .shieldFont(12, weight: .bold)
                .foregroundStyle(ShieldTheme.primary(scheme))
                .frame(width: 36, height: 36)
                .background(ShieldTheme.rowBackground(scheme), in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }

    private func nudgeActive(dx: CGFloat, dy: CGFloat, dw: CGFloat, dh: CGFloat) {
        guard let id = vm.activeRedactionID,
              let redaction = vm.redactions.first(where: { $0.id == id }) else { return }
        var rect = redaction.rect
        rect.origin.x = max(0, min(1 - rect.width, rect.origin.x + dx))
        rect.origin.y = max(0, min(1 - rect.height, rect.origin.y + dy))
        rect.size.width = max(0.02, min(1 - rect.origin.x, rect.width + dw))
        rect.size.height = max(0.02, min(1 - rect.origin.y, rect.height + dh))
        vm.resizeRedaction(id: id, newRect: rect)
    }

    private func maskStyleGrid(currentStyle: MaskStyle, onSelect: @escaping (MaskStyle) -> Void) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(MaskStyle.allCases) { style in
                Button {
                    onSelect(style)
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(style == .blockWhite ? Color.white : Color.black)
                                .frame(height: 28)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.8)
                                )

                            if style.isPremium && !isPro {
                                Image(systemName: "lock.fill")
                                    .shieldFont(10)
                                    .foregroundStyle(ShieldTheme.warning)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                                    .padding(2)
                            }
                        }

                        Text(style.localizedLabel)
                            .shieldFont(10, weight: style == currentStyle ? .bold : .regular)
                            .foregroundStyle(style == currentStyle ? ShieldTheme.accent(scheme) : ShieldTheme.secondary(scheme))
                            .lineLimit(1)
                    }
                    .padding(4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(style == currentStyle ? ShieldTheme.accentDim(scheme) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(style == currentStyle ? ShieldTheme.accent(scheme) : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Watermark Section

    private var watermarkSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s3) {
            HStack {
                Text(lang == .es ? "MARCA DE AGUA ANTI-FRAUDE" : "ANTI-FRAUD WATERMARK")
                    .shieldFont(11, weight: .bold)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                Spacer()
                Toggle("", isOn: Binding(
                    get: { vm.watermark != nil },
                    set: { enabled in
                        if enabled {
                            vm.setWatermark(Watermark(
                                text: LanguageManager.shared.model("model_for_verification_only"),
                                opacity: 0.20,
                                isRepeating: true
                            ))
                        } else {
                            vm.setWatermark(nil)
                        }
                    }
                ))
                .labelsHidden()
                .accessibilityIdentifier("editor.inspector.watermark.enabled")
            }

            if var wm = vm.watermark {
                VStack(alignment: .leading, spacing: ShieldTheme.s3) {
                    Text(lang == .es ? "Texto de la marca" : "Watermark Text")
                        .shieldFont(11, weight: .semibold)
                        .foregroundStyle(ShieldTheme.secondary(scheme))

                    TextField(
                        LanguageManager.shared.model("model_for_verification_only"),
                        text: Binding(
                            get: { wm.text },
                            set: { newText in
                                wm.text = newText
                                vm.setWatermark(wm)
                            }
                        )
                    )
                    .textFieldStyle(.roundedBorder)
                    .shieldFont(12)

                    Text("\(lang == .es ? "Opacidad" : "Opacity"): \(Int(wm.opacity * 100))%")
                        .shieldFont(11, weight: .semibold)
                        .foregroundStyle(ShieldTheme.secondary(scheme))

                    Slider(
                        value: Binding(
                            get: { wm.opacity },
                            set: { newOpacity in
                                wm.opacity = newOpacity
                                vm.setWatermark(wm)
                            }
                        ),
                        in: 0.05...0.60
                    )

                    Toggle(
                        lang == .es ? "Patrón repetido diagonal" : "Repeating Diagonal Pattern",
                        isOn: Binding(
                            get: { wm.isRepeating },
                            set: { repeating in
                                wm.isRepeating = repeating
                                vm.setWatermark(wm)
                            }
                        )
                    )
                    .shieldFont(12)
                }
                .padding(ShieldTheme.s3)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ShieldTheme.rowBackground(scheme))
                )
            } else {
                Text(lang == .es ? "Activa la marca de agua para estampar un aviso legal anti-fraude en todas las páginas." : "Enable watermark to stamp an anti-fraud notice across all pages.")
                    .shieldFont(12)
                    .foregroundStyle(ShieldTheme.tertiary(scheme))
                    .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Export Section

    private var exportSection: some View {
        VStack(alignment: .leading, spacing: ShieldTheme.s4) {
            Text(lang == .es ? "SEGURIDAD DE EXPORTACIÓN" : "EXPORT SECURITY")
                .shieldFont(11, weight: .bold)
                .foregroundStyle(ShieldTheme.secondary(scheme))

            VStack(spacing: 8) {
                securityCheckRow(
                    icon: "lock.shield.fill",
                    title: lang == .es ? "Rasterizado destructivo irreversible" : "Irreversible destructive rasterization",
                    desc: lang == .es ? "Los píxeles redactados se aplanan permanentemente." : "Redacted pixels are permanently flattened."
                )
                securityCheckRow(
                    icon: "text.badge.xmark",
                    title: lang == .es ? "Texto subyacente eliminado" : "Underlying text removed",
                    desc: lang == .es ? "Sin capas editables ni texto OCR residual." : "No selectable layers or residual OCR text."
                )
                securityCheckRow(
                    icon: "camera.badge.ellipsis",
                    title: lang == .es ? "Metadatos eliminados" : "Metadata stripped",
                    desc: lang == .es ? "EXIF, GPS, dispositivo y fechas borrados." : "EXIF, GPS, device and timestamps cleared."
                )
            }
            .padding(ShieldTheme.s3)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(ShieldTheme.rowBackground(scheme))
            )

            Button {
                vm.showExportSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up.fill")
                    Text(lang == .es ? "Exportar documento protegido" : "Export Protected Document")
                }
                .shieldFont(14, weight: .bold)
                .foregroundStyle(ShieldTheme.accentText)
                .frame(maxWidth: .infinity)
                .frame(height: ShieldTheme.controlHeight)
                .background(ShieldTheme.accent(scheme), in: RoundedRectangle(cornerRadius: ShieldTheme.rMD))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("editor.inspector.export")
        }
    }

    private func securityCheckRow(icon: String, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .shieldFont(16)
                .foregroundStyle(ShieldTheme.success)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .shieldFont(12, weight: .bold)
                    .foregroundStyle(ShieldTheme.primary(scheme))
                Text(desc)
                    .shieldFont(10)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
            }
        }
    }

    // MARK: - Field Detection Helpers

    private struct InspectorFieldItem {
        let key: String
        let label: String
        let value: String
        let rect: CGRect
    }

    private var detectedFields: [InspectorFieldItem] {
        let f = vm.doc.fields
        var items: [InspectorFieldItem] = []

        let boxes = DocumentFieldBoxes.boxes(for: vm.doc.kind)
        func boxRect(index: Int) -> CGRect {
            boxes.indices.contains(index) ? boxes[index].rect : CGRect(x: 0.1, y: 0.1, width: 0.3, height: 0.05)
        }

        if !f.documentNumber.isEmpty {
            items.append(InspectorFieldItem(key: "docNum", label: LanguageManager.shared.model("model_field_document_number"), value: f.documentNumber, rect: boxRect(index: 0)))
        }
        if let sn = f.supportNumber, !sn.isEmpty {
            items.append(InspectorFieldItem(key: "supportNum", label: LanguageManager.shared.model("model_field_support_number"), value: sn, rect: CGRect(x: 0.6, y: 0.15, width: 0.3, height: 0.05)))
        }
        if !f.fullName.isEmpty {
            items.append(InspectorFieldItem(key: "name", label: LanguageManager.shared.model("model_field_full_name"), value: f.fullName, rect: boxRect(index: 1)))
        }
        if !f.dateOfBirth.isEmpty {
            items.append(InspectorFieldItem(key: "dob", label: LanguageManager.shared.model("model_field_date_of_birth"), value: f.dateOfBirth, rect: boxRect(index: 4)))
        }
        if !f.expires.isEmpty {
            items.append(InspectorFieldItem(key: "expires", label: LanguageManager.shared.model("model_field_expires"), value: f.expires, rect: boxRect(index: 5)))
        }
        if !f.nationality.isEmpty {
            items.append(InspectorFieldItem(key: "nat", label: LanguageManager.shared.model("model_field_nationality"), value: f.nationality, rect: boxRect(index: 2)))
        }
        if !f.address.isEmpty {
            items.append(InspectorFieldItem(key: "addr", label: LanguageManager.shared.model("model_field_address"), value: f.address, rect: boxRect(index: 3)))
        }

        // Add Vision bounding texts if present
        if let texts = f.ocrBoundingTexts, let rects = f.ocrBoundingRects, texts.count == rects.count {
            for i in 0..<min(texts.count, 6) {
                let text = texts[i]
                if !text.isEmpty && !items.contains(where: { $0.value == text }) {
                    items.append(InspectorFieldItem(key: "ocr_\(i)", label: "OCR #\(i + 1)", value: text, rect: rects[i]))
                }
            }
        }

        return items
    }

    private var totalProtectedCount: Int {
        detectedFields.filter { isFieldProtected($0) }.count
    }

    private func isFieldProtected(_ field: InspectorFieldItem) -> Bool {
        vm.redactions.contains {
            abs($0.rect.origin.x - field.rect.origin.x) < 0.05 &&
            abs($0.rect.origin.y - field.rect.origin.y) < 0.05
        }
    }

    private func toggleFieldProtection(_ field: InspectorFieldItem) {
        if isFieldProtected(field) {
            if let existing = vm.redactions.first(where: {
                abs($0.rect.origin.x - field.rect.origin.x) < 0.05 &&
                abs($0.rect.origin.y - field.rect.origin.y) < 0.05
            }) {
                vm.removeRedaction(id: existing.id)
            }
        } else {
            let redaction = Redaction(rect: field.rect, style: vm.maskStyle)
            vm.addRedaction(redaction)
            vm.activeRedactionID = redaction.id
        }
    }

    private func protectAllDetected() {
        for field in detectedFields where !isFieldProtected(field) {
            let redaction = Redaction(rect: field.rect, style: vm.maskStyle)
            vm.addRedaction(redaction)
        }
    }

    private func clearCurrentPageRedactions() {
        for r in vm.redactions {
            vm.removeRedaction(id: r.id)
        }
        vm.activeRedactionID = nil
    }
}
