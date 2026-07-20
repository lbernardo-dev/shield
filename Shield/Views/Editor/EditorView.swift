import SwiftUI

// MARK: - EditorView

struct EditorView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @StateObject private var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showPaywall = false
    @State private var paywallTrigger: PaywallTrigger = .manual
    @State private var showCancelConfirm = false
    @State private var showWatermarkConfig = false
    @State private var showReadjustReview = false
    @State private var readjustPages: [UIImage] = []
    @State private var shouldPersistOnDismiss = false
    @State private var currentPageAspect: CGFloat? = nil
    @State private var zoomScale: CGFloat = 1
    @GestureState private var magnifyScale: CGFloat = 1

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
        .background(ShieldTheme.pageBackground(scheme).ignoresSafeArea())
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
#if DEBUG
            if ASOScreenshotMode.isEnabled {
                if ASOScreenshotMode.scene == "ocr" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        vm.showOCRSheet = true
                    }
                } else if ASOScreenshotMode.scene == "export" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        vm.showExportSheet = true
                    }
                }
            }
#endif
        }
        .task(id: vm.currentImageFileName) {
            guard vm.doc.kind == .photo,
                  let fileName = vm.currentImageFileName,
                  let image = AppState.loadImage(fileName: fileName, isVaulted: vm.doc.isVaulted),
                  image.size.height > 0 else {
                currentPageAspect = nil
                return
            }
            currentPageAspect = image.size.width / image.size.height
            zoomScale = 1
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
                    guard vm.doc.originalPageFileNames?.count == readjustPages.count,
                          vm.doc.pageTransforms.count == readjustPages.count else {
                        // Legacy documents have no immutable original. Starting
                        // from identity prevents their baked adjustments from
                        // being applied a second time.
                        return Array(repeating: .default, count: readjustPages.count)
                    }
                    return vm.doc.pageTransforms.map(ScanPageAdjustment.init(documentTransform:))
                }(),
                onCancel: {
                    showReadjustReview = false
                    readjustPages = []
                },
                onConfirm: { adjustedPages, _, transforms in
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
                        _ = appState.saveImage(image, id: id, isVaulted: vm.doc.isVaulted)
                    }
                    vm.updateRenderedPages(transforms: transforms)
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
            .foregroundColor(ShieldTheme.accent(scheme))
            .frame(minHeight: 44)
            .contentShape(Rectangle())
            .keyboardShortcut(.cancelAction)
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
                    if let originals = vm.doc.originalPageFileNames, !originals.isEmpty {
                        fileNames = originals
                    } else if let all = vm.doc.pageFileNames, !all.isEmpty {
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
                        .foregroundColor(ShieldTheme.secondary(scheme))
                        .frame(width: 30, height: 30)
                }

                Button {
                    appState.updateDocument(vm.documentSnapshot)
                    vm.markSaved()
                    shouldPersistOnDismiss = false
                    appState.selectedDoc = nil
                    dismiss()
                } label: {
                    Text(LanguageManager.shared.common("common_save"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(vm.hasUnsavedChanges ? ShieldTheme.accentText : ShieldTheme.tertiary(scheme))
                        .padding(.horizontal, 14)
                        .frame(height: 30)
                        .background(vm.hasUnsavedChanges ? ShieldTheme.success : ShieldTheme.rowBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!vm.hasUnsavedChanges)
                .keyboardShortcut("s", modifiers: .command)

                Button {
                    vm.showExportSheet = true
                } label: {
                    Text(LanguageManager.shared.editor("editor_export"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ShieldTheme.accentText)
                        .padding(.horizontal, 14)
                        .frame(height: 30)
                        .background(ShieldTheme.accent(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            } // HStack
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.vertical, 4) // Reduced from 6
        .background(ShieldTheme.pageBackground(scheme).ignoresSafeArea(edges: .top))
        .overlay(alignment: .bottom) { ShieldDivider() }
    }

    private var documentMetaBar: some View {
        EditorDocumentMetaBar(
            title: vm.doc.title,
            changeCount: vm.changeCount,
            hasUnsavedChanges: vm.hasUnsavedChanges,
            lang: appState.language
        )
    }

    // MARK: - Sensitive banner

    @ViewBuilder
    private var sensitiveBanner: some View {
        EditorSensitiveBanner(
            isVisible: vm.showSensitiveBanner,
            isAnalyzing: vm.isAnalyzingOCRSuggestions,
            suggestedRedactionCount: vm.suggestedRedactionCount,
            docKind: vm.doc.kind,
            lang: appState.language,
            onApply: { vm.applyAutoDetect() },
            onOpenFields: { vm.showOCRSheet = true },
            onDismiss: { withAnimation { vm.showSensitiveBanner = false } }
        )
    }

    // MARK: - Propagate banner

    @ViewBuilder
    private var propagateBanner: some View {
        EditorPropagateBanner(
            pageCount: vm.pageCount,
            redactionCount: vm.redactions.count,
            onPropagate: { vm.propagateCurrentPageToAllPages() }
        )
    }

    // MARK: - Canvas area

    private func canvasSize(available: CGSize, isLandscape: Bool) -> CGSize {
        let w = available.width - 32  // hPad * 2
        let maxH = isLandscape ? available.height * 0.7 : available.height
        guard vm.doc.kind == .photo else {
            return CGSize(width: w, height: min(w / 1.6, maxH))
        }
        guard let aspect = currentPageAspect, aspect > 0 else {
            return CGSize(width: w, height: maxH)
        }
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
            let effectiveZoom = min(4, max(1, zoomScale * magnifyScale))

            ZStack {
                RadialGradient(
                    colors: [
                        scheme == .dark ? Color(hex: "15151b") : ShieldTheme.accentDim(scheme),
                        ShieldTheme.pageBackground(scheme)
                    ],
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
                                .foregroundColor(currentPage > 0 ? ShieldTheme.primary(scheme) : ShieldTheme.quaternary(scheme))
                                .frame(width: 22, height: 22)
                        }
                        .disabled(currentPage == 0)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel(LanguageManager.shared.editor("editor_previous_page"))
                        .keyboardShortcut(.leftArrow, modifiers: [])
                    }

                    Text(LanguageManager.shared.editor("editor_page_indicator", currentPage + 1, max(totalPages, 1)))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ShieldTheme.cardBackground(scheme))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    if totalPages > 1 {
                        Button {
                            vm.goToPage(currentPage + 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(currentPage < totalPages - 1 ? ShieldTheme.primary(scheme) : ShieldTheme.quaternary(scheme))
                                .frame(width: 22, height: 22)
                        }
                        .disabled(currentPage >= totalPages - 1)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel(LanguageManager.shared.editor("editor_next_page"))
                        .keyboardShortcut(.rightArrow, modifiers: [])
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(ShieldTheme.s4)
                .zIndex(2)

                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        DocumentCanvas(vm: vm, canvasSize: CGSize(width: canvasW, height: canvasH))
                            .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 12)
                            .frame(width: canvasW, height: canvasH)
                            .scaleEffect(effectiveZoom)
                    }
                    .frame(
                        width: max(geo.size.width, canvasW * effectiveZoom),
                        height: max(geo.size.height, canvasH * effectiveZoom)
                    )
                }
                .scrollEdgeEffectStyleIfAvailable()
                .scrollIndicators(effectiveZoom > 1 ? .visible : .hidden)
                .simultaneousGesture(
                    MagnifyGesture(minimumScaleDelta: 0.01)
                        .updating($magnifyScale) { value, state, _ in
                            state = value.magnification
                        }
                        .onEnded { value in
                            zoomScale = min(4, max(1, zoomScale * value.magnification))
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(reduceMotion ? nil : .snappy) {
                        zoomScale = zoomScale > 1 ? 1 : 2
                    }
                }

                HStack(spacing: 0) {
                    Button {
                        withAnimation(reduceMotion ? nil : .snappy) { zoomScale = max(1, zoomScale - 0.5) }
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                            .frame(width: 36, height: 34)
                    }
                    .disabled(zoomScale <= 1)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(LanguageManager.shared.editor("editor_zoom_out"))
                    .keyboardShortcut("-", modifiers: .command)

                    Text("\(Int(effectiveZoom * 100))%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .frame(minWidth: 48)

                    Button {
                        withAnimation(reduceMotion ? nil : .snappy) { zoomScale = min(4, zoomScale + 0.5) }
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                            .frame(width: 36, height: 34)
                    }
                    .disabled(zoomScale >= 4)
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel(LanguageManager.shared.editor("editor_zoom_in"))
                    .keyboardShortcut("+", modifiers: .command)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(LanguageManager.shared.editor("editor_zoom_controls"))
                .foregroundColor(ShieldTheme.primary(scheme))
                .background {
                    if #available(iOS 26, *) {
                        Color.clear
                            .glassEffect(.regular.interactive(), in: .capsule)
                    } else {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                }
                .overlay {
                    if #available(iOS 26, *) {
                        EmptyView()
                    } else {
                        Capsule().stroke(ShieldTheme.line(scheme), lineWidth: 0.8)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(ShieldTheme.s4)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .layoutPriority(1)
    }

    // MARK: - Mode chips

    private var modeChips: some View {
        EditorModeChips(
            activeMode: vm.activeMode,
            lang: appState.language,
            isPro: pm.isPro,
            onLockedTap: {
                paywallTrigger = .manual
                showPaywall = true
            },
            onSelect: { mode in
                vm.applyMode(mode)
                vm.tool = .rect
                vm.activeRedactionID = nil
            }
        )
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
        EditorBottomToolbar(
            canUndo: vm.canUndo,
            canRedo: vm.canRedo,
            selectedTool: vm.tool,
            lang: appState.language,
            watermarkActive: vm.watermark != nil,
            adjustActive: vm.showAdjustPanel,
            adjustDirty: !vm.imageAdjustment.isDefault,
            toolHelpText: toolHelpText,
            onUndo: { vm.undo() },
            onRedo: { vm.redo() },
            onToolTap: handleToolTap
        )
    }

    private var toolHelpText: String {
        switch vm.tool {
        case .rect: return LanguageManager.shared.editor("editor_tool_help_rect")
        case .fields: return LanguageManager.shared.editor("editor_tool_help_fields")
        case .auto: return LanguageManager.shared.editor("editor_tool_help_auto")
        case .text: return LanguageManager.shared.editor("editor_tool_help_text")
        case .watermark: return LanguageManager.shared.editor("editor_tool_help_watermark")
        case .adjust: return LanguageManager.shared.editor("editor_tool_help_adjust")
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

// MARK: - Conditional ScrollEdgeEffect Helper

extension View {
    @ViewBuilder
    fileprivate func scrollEdgeEffectStyleIfAvailable() -> some View {
        if #available(iOS 26, *) {
            self.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            self
        }
    }
}
