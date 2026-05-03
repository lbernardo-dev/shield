import SwiftUI

// MARK: - EditorView

struct EditorView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @StateObject private var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var paywallTrigger: PaywallTrigger = .manual
    @State private var showCancelConfirm = false
    @State private var showWatermarkConfig = false
    @State private var showReadjustReview = false
    @State private var readjustPages: [UIImage] = []
    @State private var shouldPersistOnDismiss = false

    init(doc: DocumentItem) {
        _vm = StateObject(wrappedValue: EditorViewModel(doc: doc))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            documentMetaBar
            sensitiveBanner
            propagateBanner
            canvasArea
            // Image adjust panel (shown when tool == .adjust)
            if vm.showAdjustPanel {
                ImageAdjustToolbar(vm: vm, lang: appState.language, isPro: pm.isPro) {
                    paywallTrigger = .styleLocked
                    showPaywall = true
                }
                .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
            }
            if !vm.showAdjustPanel {
                modeChips
            }
            if vm.tool == .rect || vm.tool == .fields || vm.activeRedactionID != nil {
                maskStylePicker
            }
            bottomBar
        }
        .background(ShieldTheme.surface0.ignoresSafeArea())
        .preferredColorScheme(appState.preferredScheme)
        .onAppear {
            if let style = appState.pendingMaskStyle {
                vm.maskStyle = style
                appState.pendingMaskStyle = nil
            }
            if let mode = appState.pendingRedactionMode {
                // Small delay so the canvas is fully laid out before drawing redactions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    vm.applyMode(mode)
                }
                appState.pendingRedactionMode = nil
            }
            vm.bootstrapOCRSuggestionsIfNeeded()
        }
        .sheet(isPresented: $vm.showOCRSheet) {
            SheetContainer(heightFraction: 0.80) {
                OCRSheetView(
                    doc: vm.doc,
                    lang: appState.language,
                    currentRedactions: $vm.redactions,
                    onMaskField: { rect in
                        vm.addFromOCR(rect: rect)
                    },
                    onUnmaskField: { rect in
                        vm.removeOCRRedaction(rect: rect)
                    },
                    onFieldsUpdated: { fields in
                        vm.updateOCRFields(fields)
                    },
                    isPresented: $vm.showOCRSheet
                )
            }
        }
        .sheet(isPresented: $vm.showExportSheet) {
            SheetContainer(heightFraction: 0.82) {
                ExportSheetView(
                    doc: vm.doc,
                    redactions: vm.redactions,
                    pageRedactions: vm.allPageRedactions,
                    watermark: vm.watermark,
                    lang: appState.language,
                    currentPage: vm.currentPage,
                    currentImageFileName: vm.currentImageFileName,
                    isPresented: $vm.showExportSheet,
                    onDone: {
                        appState.updateDocument(vm.documentSnapshot)
                        vm.markSaved()
                        vm.showExportSheet = false
                        appState.selectedDoc = nil
                        dismiss()
                    }
                )
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: paywallTrigger).environmentObject(appState)
        }
        .sheet(isPresented: $showWatermarkConfig) {
            SheetContainer(heightFraction: 0.52) {
                WatermarkConfigView(
                    watermark: vm.watermark,
                    lang: appState.language,
                    defaultText: LanguageManager.shared.model("model_for_verification_only"),
                    isPresented: $showWatermarkConfig
                ) { newWatermark in
                    vm.setWatermark(newWatermark)
                }
            }
        }
        .fullScreenCover(isPresented: $showReadjustReview) {
            ScanReviewView(
                pages: readjustPages,
                initialAdjustments: {
                    let adj = vm.imageAdjustment
                    let scanAdj = ScanPageAdjustment(
                        filterPreset: .auto, // Default to auto for re-adjust
                        straightenDegrees: 0,
                        rotationDegrees: adj.rotation,
                        perspectiveTopInset: 0,
                        perspectiveBottomInset: 0,
                        perspectiveSkew: 0,
                        perspectiveTopYOffset: 0,
                        perspectiveBottomYOffset: 0,
                        quad: nil,
                        cropLeft: adj.cropLeft,
                        cropRight: adj.cropRight,
                        cropTop: adj.cropTop,
                        cropBottom: adj.cropBottom,
                        brightness: adj.brightness,
                        contrast: adj.contrast,
                        sharpness: adj.sharpness,
                        noiseReduction: 0
                    )
                    return Array(repeating: scanAdj, count: readjustPages.count)
                }(),
                onCancel: {
                    showReadjustReview = false
                    readjustPages = []
                },
                onConfirm: { adjustedPages, _ in
                    let fileNames: [String]
                    if let all = vm.doc.pageFileNames, !all.isEmpty {
                        fileNames = all
                    } else if let first = vm.doc.imageFileName {
                        fileNames = [first]
                    } else {
                        fileNames = []
                    }
                    for (index, image) in adjustedPages.enumerated() {
                        guard index < fileNames.count else { break }
                        let id = (fileNames[index] as NSString).deletingPathExtension
                        _ = appState.saveImage(image, id: id)
                    }
                    vm.refreshAfterImageOverwrite()
                    showReadjustReview = false
                    readjustPages = []
                }
            )
            .environmentObject(appState)
        }
        .onDisappear {
            if shouldPersistOnDismiss {
                appState.updateDocument(vm.documentSnapshot)
                vm.markSaved()
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(LanguageManager.shared.common("common_cancel")) {
                if !vm.hasUnsavedChanges {
                    appState.selectedDoc = nil
                    dismiss()
                } else {
                    showCancelConfirm = true
                }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(ShieldTheme.accent)
            .confirmationDialog(
                LanguageManager.shared.editor("editor_exit_confirm"),
                isPresented: $showCancelConfirm,
                titleVisibility: .visible
            ) {
                Button(LanguageManager.shared.editor("editor_exit"), role: .destructive) {
                    appState.selectedDoc = nil
                    dismiss()
                }
                Button(LanguageManager.shared.editor("editor_keep_editing"), role: .cancel) {}
            } message: {
                Text(LanguageManager.shared.editor("editor_exit_warning"))
            }

            Spacer()

            HStack(spacing: 12) {
                // Re-adjust scan button
                Button {
                    let fileNames: [String]
                    if let all = vm.doc.pageFileNames, !all.isEmpty {
                        fileNames = all
                    } else if let first = vm.doc.imageFileName {
                        fileNames = [first]
                    } else {
                        fileNames = []
                    }
                    let pages = fileNames.compactMap {
                        AppState.loadImage(fileName: $0, isVaulted: vm.doc.isVaulted)
                    }
                    guard !pages.isEmpty else { return }
                    readjustPages = pages
                    showReadjustReview = true
                } label: {
                    Image(systemName: "camera.filters")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ShieldTheme.textSecondary)
                        .frame(width: 30, height: 30)
                }

                Button {
                    appState.updateDocument(vm.documentSnapshot)
                    vm.markSaved()
                    shouldPersistOnDismiss = false
                    appState.selectedDoc = nil
                    dismiss()
                } label: {
                    Text(appState.language == .es ? "Guardar" : "Save")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(vm.hasUnsavedChanges ? ShieldTheme.accentText : ShieldTheme.textTertiary)
                        .padding(.horizontal, 14)
                        .frame(height: 30)
                        .background(vm.hasUnsavedChanges ? ShieldTheme.success : ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!vm.hasUnsavedChanges)

                Button {
                    vm.showExportSheet = true
                } label: {
                    Text(LanguageManager.shared.editor("editor_export"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ShieldTheme.accentText)
                        .padding(.horizontal, 14)
                        .frame(height: 30)
                        .background(ShieldTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            } // HStack
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.vertical, 4) // Reduced from 6
        .background(ShieldTheme.surface0.ignoresSafeArea(edges: .top))
        .overlay(alignment: .bottom) { ShieldDivider() }
    }

    private var documentMetaBar: some View {
        HStack(spacing: 10) {
            Text(vm.doc.title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(ShieldTheme.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(vm.changeCount == 0
                 ? (appState.language == .es ? "Sin cambios" : "No changes")
                 : (appState.language == .es ? "\(vm.changeCount) cambios" : "\(vm.changeCount) changes"))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(vm.hasUnsavedChanges ? ShieldTheme.warning : ShieldTheme.textTertiary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(vm.hasUnsavedChanges ? ShieldTheme.warning.opacity(0.16) : ShieldTheme.surface2)
                .clipShape(Capsule())
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.vertical, 3) // Reduced from 4
        .background(ShieldTheme.surface0)
    }

    // MARK: - Sensitive banner

    @ViewBuilder
    private var sensitiveBanner: some View {
        if vm.showSensitiveBanner {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(ShieldTheme.warning)

                VStack(alignment: .leading, spacing: 1) {
                    let titleText: String = vm.isAnalyzingOCRSuggestions
                        ? (appState.language == .es ? "Analizando zonas sensibles…" : "Analyzing sensitive zones…")
                        : LanguageManager.shared.editor("editor_sensitive_suggested", vm.suggestedRedactionCount)
                    Text(titleText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShieldTheme.textPrimary)
                    Text(vm.doc.kind == .photo || vm.doc.kind == .genericID
                         ? (appState.language == .es ? "Basado en los campos OCR detectados." : "Based on detected OCR fields.")
                         : LanguageManager.shared.editor("editor_sensitive_based_on_template"))
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.textSecondary)
                }
                Spacer()

                Button {
                    vm.applyAutoDetect()
                } label: {
                    Text(LanguageManager.shared.common("common_apply"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .background(ShieldTheme.warning)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(vm.suggestedRedactionCount == 0 || vm.isAnalyzingOCRSuggestions)
                .opacity((vm.suggestedRedactionCount == 0 || vm.isAnalyzingOCRSuggestions) ? 0.55 : 1)

                Button {
                    vm.showOCRSheet = true
                } label: {
                    Text(appState.language == .es ? "Campos" : "Fields")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShieldTheme.accent)
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(ShieldTheme.accentDim)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button {
                    withAnimation { vm.showSensitiveBanner = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .padding(4)
                }
            }
            .padding(.horizontal, ShieldTheme.s4)
            .padding(.vertical, 4) // Reduced from 6
            .background(ShieldTheme.warning.opacity(0.10))
            .overlay(
                Rectangle()
                    .stroke(ShieldTheme.warning.opacity(0.35), lineWidth: 0.5)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Propagate banner

    @ViewBuilder
    private var propagateBanner: some View {
        if vm.pageCount > 1 && !vm.redactions.isEmpty {
            HStack(spacing: 10) {
                Image(systemName: "square.stack.3d.up.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(ShieldTheme.accent)

                VStack(alignment: .leading, spacing: 1) {
                    Text(LanguageManager.shared.editor("editor_redactions_on_page", vm.redactions.count))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShieldTheme.textPrimary)
                    Text(LanguageManager.shared.editor("editor_apply_to_all"))
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.textSecondary)
                }
                Spacer()

                Button {
                    vm.propagateCurrentPageToAllPages()
                } label: {
                    Text(LanguageManager.shared.editor("editor_find_all"))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .frame(height: 28)
                        .background(ShieldTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, ShieldTheme.s4)
            .padding(.vertical, 6)
            .background(ShieldTheme.accentDim)
            .overlay(
                Rectangle()
                    .stroke(ShieldTheme.accent.opacity(0.3), lineWidth: 0.5)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Canvas area

    private func canvasSize(available: CGSize, isLandscape: Bool) -> CGSize {
        let w = available.width - 32  // hPad * 2
        let maxH = isLandscape ? available.height * 0.7 : available.height
        guard vm.doc.kind == .photo else {
            return CGSize(width: w, height: min(w / 1.6, maxH))
        }
        let img = vm.currentImageFileName.flatMap {
            AppState.loadImage(fileName: $0, isVaulted: vm.doc.isVaulted)
        }
        guard let img = img else { return CGSize(width: w, height: maxH) }
        let aspect = img.size.width / img.size.height
        let fitH = w / aspect
        if fitH <= maxH {
            return CGSize(width: w, height: min(fitH, maxH))
        } else {
            return CGSize(width: maxH * aspect, height: maxH)
        }
    }

    private var canvasArea: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let sz = canvasSize(available: geo.size, isLandscape: isLandscape)
            let canvasW = sz.width
            let canvasH = sz.height
            let totalPages = vm.pageCount
            let currentPage = vm.currentPage

            ZStack {
                RadialGradient(
                    colors: [Color(hex: "15151b"), ShieldTheme.surface0],
                    center: .center,
                    startRadius: 0,
                    endRadius: max(canvasW, canvasH)
                )

                // Page indicator + navigation
                HStack(spacing: 6) {
                    if totalPages > 1 {
                        Button {
                            vm.goToPage(currentPage - 1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(currentPage > 0 ? ShieldTheme.textPrimary : ShieldTheme.textQuaternary)
                                .frame(width: 22, height: 22)
                        }
                        .disabled(currentPage == 0)
                    }

                    Text(LanguageManager.shared.editor("editor_page_indicator", currentPage + 1, max(totalPages, 1)))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ShieldTheme.surface2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ShieldTheme.surfaceLine, lineWidth: 0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    if totalPages > 1 {
                        Button {
                            vm.goToPage(currentPage + 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(currentPage < totalPages - 1 ? ShieldTheme.textPrimary : ShieldTheme.textQuaternary)
                                .frame(width: 22, height: 22)
                        }
                        .disabled(currentPage >= totalPages - 1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(ShieldTheme.s4)

                DocumentCanvas(vm: vm, canvasSize: CGSize(width: canvasW, height: canvasH))
                    .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 12)
                    .frame(width: canvasW, height: canvasH)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .layoutPriority(1)
    }

    // MARK: - Mode chips

    private var modeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(RedactionMode.allCases, id: \.self) { mode in
                    let isActive = vm.activeMode == mode
                    let locked = mode.requiresPro && !pm.isPro
                    Button {
                        if locked {
                            paywallTrigger = .manual
                            showPaywall = true
                        } else {
                            vm.applyMode(mode)
                            vm.tool = .rect
                            vm.activeRedactionID = nil
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: locked ? "lock.fill" : mode.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(mode.label(lang: appState.language))
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(locked ? ShieldTheme.textTertiary : (isActive ? .black : ShieldTheme.textPrimary))
                        .padding(.horizontal, 10)
                        .frame(height: 28)
                        .background(locked ? ShieldTheme.surface2 : (isActive ? mode.color : ShieldTheme.surface2))
                        .overlay(
                            Capsule()
                                .stroke(locked ? ShieldTheme.surfaceLine.opacity(0.5) : (isActive ? mode.color : ShieldTheme.surfaceLine), lineWidth: isActive ? 0 : 0.5)
                        )
                        .clipShape(Capsule())
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, ShieldTheme.s4)
            .padding(.vertical, 1) // Minimal padding
        }
    }

    // MARK: - Mask style picker

    private var maskStylePicker: some View {
        MaskStylePicker(
            selected: $vm.maskStyle,
            lang: appState.language,
            isUnlocked: { style in
                pm.canUseStyle(style)
            },
            onLockedSelect: { _ in
                paywallTrigger = .styleLocked
                showPaywall = true
            }
        ) { newStyle in
            if let id = vm.activeRedactionID {
                vm.changeStyle(of: id, to: newStyle)
            }
        }
    }

    // MARK: - Bottom toolbar

    private var bottomBar: some View {
        VStack(spacing: 2) { // Reduced spacing from 4
            HStack {
                // Undo / Redo
                HStack(spacing: 4) {
                    Button {
                        vm.undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(vm.canUndo ? ShieldTheme.textPrimary : ShieldTheme.textQuaternary)
                            .frame(width: 32, height: 32)
                            .background(ShieldTheme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(!vm.canUndo)

                    Button {
                        vm.redo()
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(vm.canRedo ? ShieldTheme.textPrimary : ShieldTheme.textQuaternary)
                            .frame(width: 32, height: 32)
                            .background(ShieldTheme.surface2)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(!vm.canRedo)
                }

                Spacer()

                // Tools
                HStack(spacing: 8) {
                    ForEach(EditorTool.allCases) { tool in
                        let isSelected = vm.tool == tool
                        let watermarkActive = tool == .watermark && vm.watermark != nil
                        let adjustActive = tool == .adjust && vm.showAdjustPanel
                        let adjustDirty  = tool == .adjust && !vm.imageAdjustment.isDefault
                        Button {
                            handleToolTap(tool)
                        } label: {
                            VStack(spacing: 2) {
                                ZStack(alignment: .topTrailing) {
                                    Image(systemName: tool.icon)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(
                                            (isSelected || adjustActive) ? ShieldTheme.accentText : ShieldTheme.textPrimary
                                        )
                                        .frame(width: 32, height: 32)
                                        .background((isSelected || adjustActive) ? ShieldTheme.accent : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    if watermarkActive || adjustDirty {
                                        Circle()
                                            .fill(adjustDirty ? ShieldTheme.info : ShieldTheme.success)
                                            .frame(width: 8, height: 8)
                                            .offset(x: 2, y: -2)
                                    }
                                }
                                Text(tool.label(lang: appState.language))
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor((isSelected || adjustActive) ? ShieldTheme.accent : ShieldTheme.textTertiary)
                            }
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: vm.tool == .rect ? "hand.draw" : "info.circle")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ShieldTheme.textTertiary)
                Text(toolHelpText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(ShieldTheme.textTertiary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .frame(height: 24)
            .background(ShieldTheme.surface3)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.top, 6)
        .padding(.bottom, 0)
        .background(ShieldTheme.surface2.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { ShieldDivider() }
    }

    private var toolHelpText: String {
        if appState.language == .es {
            switch vm.tool {
            case .rect: return "Arrastra sobre el documento para crear una nueva máscara."
            case .fields: return "Toca un campo para enmascararlo o quitar máscara."
            case .auto: return "Aplicación automática de zonas sensibles."
            case .text: return "Revisa OCR y aplica máscaras por campo."
            case .watermark: return "Configura marca de agua del documento."
            case .adjust: return "Ajusta brillo, recorte y geometría."
            }
        } else {
            switch vm.tool {
            case .rect: return "Drag over the document to create a new mask."
            case .fields: return "Tap a field to mask or unmask it."
            case .auto: return "Automatically applies sensitive areas."
            case .text: return "Review OCR and mask by field."
            case .watermark: return "Configure the document watermark."
            case .adjust: return "Adjust brightness, crop and geometry."
            }
        }
    }

    private func handleToolTap(_ tool: EditorTool) {
        withAnimation(.easeInOut(duration: 0.15)) {
            vm.tool = tool
        }
        switch tool {
        case .auto:
            vm.applyAutoDetect()
            withAnimation(.easeInOut(duration: 0.15)) { vm.tool = .rect }
        case .text:
            vm.showOCRSheet = true
        case .watermark:
            showWatermarkConfig = true
            withAnimation(.easeInOut(duration: 0.15)) { vm.tool = .rect }
        case .fields:
            vm.showFieldOverlays = !vm.showFieldOverlays
        case .adjust:
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.showAdjustPanel.toggle()
            }
            if vm.showAdjustPanel {
                withAnimation(.easeInOut(duration: 0.15)) { vm.tool = .rect }
            }
        default:
            break
        }
    }
}

// MARK: - SheetContainer

struct SheetContainer<Content: View>: View {
    let heightFraction: CGFloat
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(ShieldTheme.cardBackground(scheme))
        .presentationDetents([.fraction(heightFraction)])
        .presentationDragIndicator(.visible)
        .presentationBackground(ShieldTheme.cardBackground(scheme))
    }
}
