import SwiftUI

// MARK: - EditorView

struct EditorView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @StateObject private var vm: EditorViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var inspectorTab: PrivacyInspectorTab = .detections
    @State private var showPaywall = false
    @State private var paywallTrigger: PaywallTrigger = .manual
    @State private var showCancelConfirm = false
    @State private var showPersistenceError = false
    @State private var showInspectorSheet = false
    @State private var showWatermarkConfig = false
    @State private var showReadjustReview = false
    @State private var readjustPages: [UIImage] = []
    @State private var currentPageAspect: CGFloat? = nil
    @State private var zoomScale: CGFloat = 1
    @GestureState private var magnifyScale: CGFloat = 1
    @State private var panOffset: CGSize = .zero
    @GestureState private var dragPanOffset: CGSize = .zero

    init(doc: DocumentItem) {
        _vm = StateObject(wrappedValue: EditorViewModel(doc: doc))
    }

    var body: some View {
        NavigationStack {
            // Let NavigationStack supply the current safe-area width, including
            // Duo's changing side rail, instead of adding a device-specific inset.
            VStack(spacing: 0) {
                documentMetaBar
                contextBanner
                batchReviewBanner
                adaptiveWorkspace
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                editorToolbar
            }
            .toolbarBackground(ShieldTheme.pageBackground(scheme), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .confirmationDialog(
            LanguageManager.shared.editor("editor_exit_confirm"),
            isPresented: $showCancelConfirm,
            titleVisibility: .visible
        ) {
            Button(LanguageManager.shared.editor("editor_exit"), role: .destructive) {
                showCancelConfirm = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    closeEditor()
                }
            }
            Button(LanguageManager.shared.editor("editor_keep_editing"), role: .cancel) {
                showCancelConfirm = false
            }
        } message: {
            Text(LanguageManager.shared.editor("editor_exit_warning"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ShieldTheme.pageBackground(scheme).ignoresSafeArea())
        .preferredColorScheme(appState.preferredScheme)
        .onAppear {
            if vm.needsGeometryReviewPersistence {
                _ = persistEdits()
            }
            applyPendingSearchNavigationIfPossible()
            if let style = appState.pendingMaskStyle {
                vm.maskStyle = style
                appState.pendingMaskStyle = nil
            }
            if let mode = appState.pendingRedactionMode {
                // Small delay so the canvas is fully laid out before drawing redactions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if !vm.applyMode(mode) {
                        paywallTrigger = .featureLocked
                        showPaywall = true
                    }
                }
                appState.pendingRedactionMode = nil
            }
#if DEBUG
            if ASOScreenshotMode.isEnabled {
                let scene = ASOScreenshotMode.scene
                if scene == "04-ai-ocr-detection" || scene == "04" || scene == "04-ocr-results" || scene == "ocr" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        vm.showOCRSheet = true
                    }
                } else if scene == "05-antifraud-watermark" || scene == "05" || scene == "03-watermark-config" || scene == "03" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        showWatermarkConfig = true
                    }
                } else if scene == "10-irreversible-export" || scene == "10" || scene == "06-export-verification" || scene == "06" || scene == "07-exif-gps" || scene == "export" {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        vm.showExportSheet = true
                    }
                }
            }
#endif
        }
        .task {
            // OCR bootstrap publishes its loading state. Let the initial
            // SwiftUI layout finish before starting that state transition.
            await Task.yield()
            guard !Task.isCancelled else { return }
            vm.bootstrapOCRSuggestionsIfNeeded()
            vm.bootstrapFaceSuggestionsIfNeeded()
        }
        .onChange(of: vm.doc.fields.ocrFaceSuggestions) { oldValue, newValue in
            guard oldValue != newValue else { return }
            _ = persistEdits()
        }
        .onChange(of: vm.doc.fields.ocrDismissedFaceSuggestionIDs) { oldValue, newValue in
            guard oldValue != newValue else { return }
            _ = persistEdits()
        }
        .onChange(of: vm.needsGeometryReviewPersistence) { oldValue, newValue in
            guard !oldValue, newValue else { return }
            DispatchQueue.main.async {
                guard vm.needsGeometryReviewPersistence else { return }
                _ = persistEdits()
            }
        }
        .onChange(of: vm.doc.fields.ocrPageEvidence) { oldValue, newValue in
            if oldValue != newValue { _ = persistEdits() }
            applyPendingSearchNavigationIfPossible()
        }
        .onChange(of: appState.searchQuery) { _, newQuery in
            guard newQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            appState.pendingDocumentSearchDocumentID = nil
            appState.pendingDocumentSearchPageIndex = nil
        }
        .overlay {
            if showPersistenceError {
                ShieldErrorCard(
                    title: LanguageManager.shared.common("common_error"),
                    message: LanguageManager.shared.capture("capture_error_storage_write"),
                    scheme: scheme,
                    dismissLabel: LanguageManager.shared.common("common_ok"),
                    dismissAction: { showPersistenceError = false },
                    accessibilityIdentifier: "editor.persistenceError"
                )
                .transition(reduceMotion ? .opacity : .scale(scale: 0.98).combined(with: .opacity))
                .zIndex(500)
            }
        }
        .animation(reduceMotion ? nil : ShieldMotion.state, value: showPersistenceError)
        .task(id: vm.currentImageFileName) {
            guard let fileName = vm.currentImageFileName,
                  let image = AppState.loadImage(fileName: fileName, isVaulted: vm.doc.isVaulted),
                  image.size.height > 0 else {
                currentPageAspect = nil
                return
            }
            currentPageAspect = image.size.width / image.size.height
            zoomScale = 1
        }
        .sheet(isPresented: $vm.showOCRSheet) {
            SheetContainer {
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
            SheetContainer {
                ExportSheetView(
                    doc: vm.doc,
                    redactions: vm.redactions,
                    pageRedactions: vm.allPageRedactions,
                    watermark: vm.watermark,
                    lang: appState.language,
                    currentPage: vm.currentPage,
                    currentImageFileName: vm.currentImageFileName,
                    preferredOutputFormat: vm.preferredExportFormat,
                    isPresented: $vm.showExportSheet,
                    onDone: {
                        guard persistEdits() else {
                            vm.showExportSheet = false
                            return
                        }
                        vm.showExportSheet = false
                        closeEditor()
                    },
                    onReview: {
                        if let pendingPage = vm.batchReviewPendingPageIndices.first {
                            vm.goToPage(pendingPage)
                            inspectorTab = .detections
                        }
                        if persistEdits() {
                            vm.showExportSheet = false
                        } else {
                            vm.showExportSheet = false
                        }
                    }
                )
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: paywallTrigger).environmentObject(appState)
        }
        .sheet(isPresented: $showWatermarkConfig) {
            SheetContainer {
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
        .sheet(isPresented: $showInspectorSheet) {
            NavigationStack {
                privacyInspector
                    .navigationTitle(appState.language == .es ? "Privacidad" : "Privacy")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(appState.language == .es ? "Listo" : "Done") {
                                showInspectorSheet = false
                            }
                            .accessibilityIdentifier("editor.inspector.close")
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $vm.showPresetPicker) {
            RedactionPresetPickerSheet(lang: appState.language) { preset in
                vm.applyPreset(preset, lang: appState.language)
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
                    guard let savedDocument = appState.replaceRenderedPages(
                        for: vm.documentSnapshot,
                        with: adjustedPages,
                        transforms: transforms
                    ) else {
                        showPersistenceError = true
                        showReadjustReview = false
                        readjustPages = []
                        return
                    }
                    vm.adoptSavedDocument(savedDocument)
                    showReadjustReview = false
                    readjustPages = []
                }
            )
            .environmentObject(appState)
        }
    }

    @discardableResult
    private func persistEdits() -> Bool {
        guard appState.updateDocument(vm.documentSnapshot) else {
            showPersistenceError = true
            return false
        }
        vm.markSaved()
        return true
    }

    private func closeEditor() {
        appState.selectedDoc = nil
        dismiss()
    }

    private func persistEditsAndClose() {
        guard persistEdits() else { return }
        closeEditor()
    }

    private func applyPendingSearchNavigationIfPossible() {
        guard appState.pendingDocumentSearchDocumentID == vm.doc.id,
              let pageIndex = vm.doc.matchingOCRPageIndices(for: appState.searchQuery).first,
              pageIndex < vm.pageCount else { return }
        vm.goToPage(pageIndex)
        appState.pendingDocumentSearchDocumentID = nil
        appState.pendingDocumentSearchPageIndex = nil
    }

    @ViewBuilder
    private var batchReviewBanner: some View {
        if !vm.batchReviewPendingPageIndices.isEmpty {
            HStack(spacing: ShieldTheme.s3) {
                Image(systemName: "eye.fill")
                    .foregroundStyle(ShieldTheme.warning)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LanguageManager.shared.editor("editor_batch_review_title"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ShieldTheme.primary(scheme))
                    Text(LanguageManager.shared.editor("editor_batch_review_guidance"))
                        .font(.caption)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(ShieldTheme.secondary(scheme))
                    Text(LanguageManager.shared.editor(
                        "editor_batch_review_page_status",
                        vm.currentPage + 1,
                        vm.batchReviewPendingPageIndices.count
                    ))
                    .font(.caption)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
                }
                Spacer(minLength: ShieldTheme.s2)
                if vm.batchReviewPendingPageIndices.contains(vm.currentPage) {
                    Button {
                        markBatchPageReviewedAndContinue()
                    } label: {
                        Text(LanguageManager.shared.editor(
                            nextPendingBatchReviewPage != nil
                                ? "editor_batch_review_mark_page"
                                : "editor_batch_review_mark_complete_page"
                        ))
                            .font(.caption.weight(.semibold))
                            .frame(minHeight: 44)
                            .padding(.horizontal, ShieldTheme.s2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ShieldTheme.accent(scheme))
                    .accessibilityIdentifier("editor.batchReview.markPage")
                    .accessibilityHint(LanguageManager.shared.editor("editor_batch_review_mark_hint"))
                } else if let nextPage = nextPendingBatchReviewPage {
                    Button {
                        vm.goToPage(nextPage)
                    } label: {
                        Text(LanguageManager.shared.editor("editor_batch_review_open_next"))
                            .font(.caption.weight(.semibold))
                            .frame(minHeight: 44)
                            .padding(.horizontal, ShieldTheme.s2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(ShieldTheme.accent(scheme))
                    .accessibilityIdentifier("editor.batchReview.openNextPage")
                    .accessibilityHint(LanguageManager.shared.editor("editor_batch_review_open_hint"))
                }
            }
            .padding(.horizontal, ShieldTheme.s4)
            .padding(.vertical, ShieldTheme.s2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ShieldTheme.warningBackground(scheme), ignoresSafeAreaEdges: [])
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("editor.batchReview.banner")
        }
    }

    private func markBatchPageReviewedAndContinue() {
        let nextPage = nextPendingBatchReviewPage
        vm.markCurrentBatchPageReviewed()
        guard persistEdits() else {
            showPersistenceError = true
            return
        }
        if let nextPage { vm.goToPage(nextPage) }
    }

    private var nextPendingBatchReviewPage: Int? {
        vm.batchReviewPendingPageIndices.first { $0 > vm.currentPage }
            ?? vm.batchReviewPendingPageIndices.first { $0 != vm.currentPage }
    }

    private var compactWorkspace: some View {
        VStack(spacing: 0) {
            canvasArea
            contextualToolPanels
            bottomBar
        }
    }

    private var adaptiveWorkspace: some View {
        GeometryReader { geometry in
            let minimumWidth: CGFloat = vm.pageCount > 1 ? 740 : 620
            if horizontalSizeClass == .regular, geometry.size.width >= minimumWidth {
                regularWorkspace
            } else {
                compactWorkspace
            }
        }
    }

    private var regularWorkspace: some View {
        GeometryReader { geo in
            if #available(iOS 27.1, *) {
                duoRegularWorkspace(containerWidth: geo.size.width)
            } else {
                legacyRegularWorkspace(containerWidth: geo.size.width)
            }
        }
    }

    @available(iOS 27.1, *)
    private func duoRegularWorkspace(containerWidth: CGFloat) -> some View {
        ArrangementView {
            expandedEditorPrimary(containerWidth: containerWidth)
        } secondary: {
            privacyInspector
                .frame(
                    minWidth: 280,
                    maxWidth: .infinity
                )
                .background(ShieldTheme.cardBackground(scheme))
        }
        .arrangementViewStyle(.split)
    }

    private func legacyRegularWorkspace(containerWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            expandedEditorPrimary(containerWidth: containerWidth)
            Rectangle()
                .fill(ShieldTheme.line(scheme))
                .frame(width: 0.5)
            privacyInspector
                .frame(width: inspectorWidth(for: containerWidth))
        }
    }

    private func expandedEditorPrimary(containerWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            if vm.pageCount > 1 {
                EditorPageNavigator(vm: vm, lang: appState.language)
                    .frame(width: pageNavigatorWidth(for: containerWidth))
                Rectangle()
                    .fill(ShieldTheme.line(scheme))
                    .frame(width: 0.5)
            }

            VStack(spacing: 0) {
                canvasArea
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                contextualToolPanels
                bottomBar
            }
            .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func inspectorWidth(for containerWidth: CGFloat) -> CGFloat {
        min(340, max(280, containerWidth * 0.32))
    }

    private func pageNavigatorWidth(for containerWidth: CGFloat) -> CGFloat {
        min(128, max(112, containerWidth * 0.14))
    }

    private var privacyInspector: some View {
        EditorPrivacyInspector(
            vm: vm,
            lang: appState.language,
            isPro: pm.isPro,
            searchQuery: appState.searchQuery,
            activeTab: $inspectorTab,
            onOpenOCR: { vm.showOCRSheet = true },
            onPersist: { _ = persistEdits() },
            onTriggerPaywall: {
                PremiumManager.recordFeatureGate(.advancedStyles, trigger: .styleLocked)
                paywallTrigger = .styleLocked
                showPaywall = true
            }
        )
    }

    @ViewBuilder
    private var contextualToolPanels: some View {
        if vm.showAdjustPanel {
            ImageAdjustToolbar(vm: vm, lang: appState.language, isPro: pm.isPro) {
                PremiumManager.recordFeatureGate(.advancedAdjustments, trigger: .featureLocked)
                paywallTrigger = .featureLocked
                showPaywall = true
            }
            .transition(AnyTransition.move(edge: .bottom).combined(with: .opacity))
        }
        if vm.tool == .rect || vm.tool == .fields || vm.activeRedactionID != nil {
            maskStylePicker
        }
    }

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            closeButton
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            originalPreviewButton
            if horizontalSizeClass != .compact {
                moreActionsMenu
            }
            if horizontalSizeClass == .compact {
                inspectorButton
            }
            saveButton
        }
        if #available(iOS 27.0, *) {
            ToolbarItem(placement: .topBarPinnedTrailing) {
                exportButton
            }
        } else {
            ToolbarItem(placement: .confirmationAction) {
                exportButton
            }
        }
    }

    private var closeButton: some View {
        Button(role: .cancel) {
            if !vm.hasUnsavedChanges {
                appState.selectedDoc = nil
                dismiss()
            } else {
                showCancelConfirm = true
            }
        } label: {
            Label(
                LanguageManager.shared.common("common_cancel"),
                systemImage: "xmark"
            )
        }
        .foregroundStyle(ShieldTheme.accent(scheme))
        .keyboardShortcut(.cancelAction)
        .accessibilityIdentifier("editor.close")
    }

    private var inspectorButton: some View {
        Button {
            showInspectorSheet = true
        } label: {
            Label(
                LanguageManager.shared.editor("editor_inspector_accessibility_label"),
                systemImage: "slider.horizontal.3"
            )
            .labelStyle(.iconOnly)
        }
        .accessibilityLabel(LanguageManager.shared.editor("editor_inspector_accessibility_label"))
        .accessibilityIdentifier("editor.inspector.open")
    }

    private var originalPreviewButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                vm.isPeekingOriginal.toggle()
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } label: {
            Label(
                LanguageManager.shared.editor(
                    vm.isPeekingOriginal ? "editor_original_preview_hide" : "editor_original_preview_show"
                ),
                systemImage: vm.isPeekingOriginal ? "eye.slash.fill" : "eye.fill"
            )
            .labelStyle(.iconOnly)
            .foregroundStyle(vm.isPeekingOriginal ? ShieldTheme.warning : ShieldTheme.secondary(scheme))
        }
        .accessibilityLabel(LanguageManager.shared.editor(
            vm.isPeekingOriginal ? "editor_original_preview_hide" : "editor_original_preview_show"
        ))
    }

    private var moreActionsMenu: some View {
        Menu {
            Button {
                vm.showPresetPicker = true
            } label: {
                Label(
                    LanguageManager.shared.editor("editor_protection_profiles_title"),
                    systemImage: "wand.and.stars"
                )
            }
            .accessibilityIdentifier("editor.menu.presets")

            Button {
                vm.showOCRSheet = true
            } label: {
                Label(
                    LanguageManager.shared.model("model_detected_fields"),
                    systemImage: "text.viewfinder"
                )
            }

            Button(action: openReadjustReview) {
                Label(
                    LanguageManager.shared.capture("capture_adjustments"),
                    systemImage: "camera.filters"
                )
            }
        } label: {
            Label(
                LanguageManager.shared.common("common_more"),
                systemImage: "ellipsis.circle"
            )
            .labelStyle(.iconOnly)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .foregroundStyle(ShieldTheme.secondary(scheme))
        }
        .accessibilityLabel(LanguageManager.shared.common("common_more"))
        .accessibilityIdentifier("editor.moreActions")
    }

    private var saveButton: some View {
        Button {
            persistEditsAndClose()
        } label: {
            Label(LanguageManager.shared.common("common_save"), systemImage: "square.and.arrow.down")
        }
        .disabled(!vm.hasUnsavedChanges)
        .tint(vm.hasUnsavedChanges ? ShieldTheme.success : ShieldTheme.tertiary(scheme))
        .accessibilityLabel(LanguageManager.shared.common("common_save"))
        .keyboardShortcut("s", modifiers: .command)
        .accessibilityIdentifier("editor.save")
    }

    private var exportButton: some View {
        Button {
            vm.showExportSheet = true
        } label: {
            Label(LanguageManager.shared.editor("editor_export"), systemImage: "square.and.arrow.up")
        }
        .tint(ShieldTheme.accent(scheme))
        .accessibilityLabel(LanguageManager.shared.editor("editor_export"))
        .keyboardShortcut("e", modifiers: [.command, .shift])
        .accessibilityIdentifier("editor.export")
    }

    private func openReadjustReview() {
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
    }

    private var documentMetaBar: some View {
        EditorDocumentMetaBar(
            title: vm.doc.title,
            changeCount: vm.changeCount,
            hasUnsavedChanges: vm.hasUnsavedChanges,
            lang: appState.language
        ) {
            if horizontalSizeClass == .compact {
                moreActionsMenu
                    .frame(width: 44, height: 44)
            }
        }
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

    @ViewBuilder
    private var contextBanner: some View {
        VStack(spacing: 0) {
            if vm.showSensitiveBanner {
                sensitiveBanner
            }
            if !vm.currentPageUnresolvedFaceSuggestions.isEmpty {
                faceSuggestionsBanner
            }
            if !vm.showSensitiveBanner && vm.currentPageUnresolvedFaceSuggestions.isEmpty {
                propagateBanner
            }
        }
    }

    private var faceSuggestionsBanner: some View {
        HStack(spacing: ShieldTheme.s3) {
            Image(systemName: "face.smiling")
                .foregroundStyle(ShieldTheme.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text(LanguageManager.shared.editor("editor_face_suggestions_title"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ShieldTheme.primary(scheme))
                Text(LanguageManager.shared.editor(
                    "editor_face_suggestions_count",
                    vm.currentPageUnresolvedFaceSuggestions.count
                ))
                    .font(.caption)
                    .foregroundStyle(ShieldTheme.secondary(scheme))
            }
            Spacer(minLength: 4)
            Button {
                inspectorTab = .detections
                if horizontalSizeClass != .regular {
                    showInspectorSheet = true
                }
            } label: {
                Text(LanguageManager.shared.editor("editor_face_suggestions_review"))
                    .font(.caption.weight(.semibold))
                    .frame(minHeight: 44)
                    .padding(.horizontal, ShieldTheme.s2)
            }
            .buttonStyle(.plain)
            .foregroundStyle(ShieldTheme.accent(scheme))
            .accessibilityIdentifier("editor.faceSuggestions.open")
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.vertical, ShieldTheme.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ShieldTheme.warning.opacity(0.09), ignoresSafeAreaEdges: [])
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
        guard vm.currentImageFileName != nil else {
            let w = max(50, available.width - 32)
            let maxH = max(50, available.height - 32)
            return CGSize(width: w, height: min(w / 1.6, maxH))
        }
        let aspect = DocumentCoordinateTransform.adjustedAspect(
            currentPageAspect ?? 1.6,
            using: vm.doc.imageAdjustment
        )
        return DocumentCoordinateTransform.contentAspectFitRect(
            in: available,
            contentAspect: aspect,
            horizontalPadding: 16,
            verticalPadding: 16
        ).size
    }

    private var canvasArea: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let sz = canvasSize(available: geo.size, isLandscape: isLandscape)
            let canvasW = sz.width
            let canvasH = sz.height
            let totalPages = vm.pageCount
            let currentPage = vm.currentPage
            let localSearchOccurrences = vm.doc.localSearchOccurrences(
                for: appState.searchQuery,
                pageIndex: currentPage
            )
            let effectiveZoom = min(4, max(1, zoomScale * magnifyScale))

            let effectivePan = (effectiveZoom > 1 || vm.tool == .pan)
                ? CGSize(width: panOffset.width + dragPanOffset.width, height: panOffset.height + dragPanOffset.height)
                : CGSize.zero

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
                                .shieldFont(11, weight: .bold)
                                .foregroundColor(currentPage > 0 ? ShieldTheme.primary(scheme) : ShieldTheme.quaternary(scheme))
                                .frame(width: 22, height: 22)
                        }
                        .disabled(currentPage == 0)
                        .frame(minWidth: 44, minHeight: 44)
                        .accessibilityLabel(LanguageManager.shared.editor("editor_previous_page"))
                        .keyboardShortcut(.leftArrow, modifiers: [])
                    }

                    Text(LanguageManager.shared.editor("editor_page_indicator", currentPage + 1, max(totalPages, 1)))
                        .shieldFont(11, weight: .semibold)
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
                                .shieldFont(11, weight: .bold)
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

                if vm.isPeekingOriginal {
                    HStack(spacing: 8) {
                        Image(systemName: "eye.fill")
                            .shieldFont(12, weight: .bold)
                        Text(appState.language == .es ? "Viendo original sin marcas" : "Viewing unredacted original")
                            .shieldFont(12, weight: .bold)
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                vm.isPeekingOriginal = false
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .shieldFont(14, weight: .bold)
                                .foregroundColor(ShieldTheme.warning)
                        }
                    }
                    .foregroundColor(ShieldTheme.warning)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(ShieldTheme.cardBackground(scheme).opacity(0.95))
                    .overlay(
                        Capsule().stroke(ShieldTheme.warning.opacity(0.5), lineWidth: 1.2)
                    )
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 10)
                    .zIndex(3)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        DocumentCanvas(
                            vm: vm,
                            canvasSize: CGSize(width: canvasW, height: canvasH),
                            effectiveZoom: effectiveZoom,
                            localSearchOccurrences: localSearchOccurrences
                        )
                        .shadow(color: .black.opacity(0.45), radius: 24, x: 0, y: 12)
                        .frame(width: canvasW, height: canvasH)
                        .scaleEffect(effectiveZoom)
                        .offset(x: effectivePan.width, y: effectivePan.height)
                    }
                    .frame(
                        width: max(geo.size.width, canvasW * effectiveZoom),
                        height: max(geo.size.height, canvasH * effectiveZoom)
                    )
                }
                .scrollDisabled(vm.tool == .rect || vm.tool == .fields || vm.isDraggingRedaction || vm.isResizingRedaction)
                .scrollEdgeEffectStyleIfAvailable()
                .scrollIndicators(effectiveZoom > 1 && vm.tool == .pan ? .visible : .hidden)
                .simultaneousGesture(
                    MagnifyGesture(minimumScaleDelta: 0.01)
                        .updating($magnifyScale) { value, state, _ in
                            state = value.magnification
                        }
                        .onEnded { value in
                            zoomScale = min(4, max(1, zoomScale * value.magnification))
                            if zoomScale <= 1 {
                                panOffset = .zero
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture(minimumDistance: 8)
                        .updating($dragPanOffset) { value, state, _ in
                            // Only 1-finger pan if the tool is explicitly Pan / Mover
                            guard vm.tool == .pan else { return }
                            state = value.translation
                        }
                        .onEnded { value in
                            guard vm.tool == .pan else { return }
                            let maxPanX = max(0, (canvasW * effectiveZoom - geo.size.width) / 2 + 180)
                            let maxPanY = max(0, (canvasH * effectiveZoom - geo.size.height) / 2 + 180)
                            let newW = min(maxPanX, max(-maxPanX, panOffset.width + value.translation.width))
                            let newH = min(maxPanY, max(-maxPanY, panOffset.height + value.translation.height))
                            panOffset = CGSize(width: newW, height: newH)
                        }
                )
                .onTapGesture(count: 2) {
                    withAnimation(reduceMotion ? nil : .snappy) {
                        if zoomScale > 1 {
                            zoomScale = 1
                            panOffset = .zero
                        } else {
                            zoomScale = 2
                        }
                    }
                }

                HStack(spacing: 8) {
                    if effectiveZoom > 1 {
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                if vm.tool == .rect {
                                    vm.tool = .pan
                                } else {
                                    vm.tool = .rect
                                }
                            }
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: vm.tool == .pan ? "hand.raised.fill" : "rectangle.dashed")
                                    .shieldFont(12, weight: .bold)
                                Text(vm.tool == .pan ? LanguageManager.shared.editor("editor_tool_pan") : LanguageManager.shared.editor("editor_tool_rect"))
                                    .shieldFont(11, weight: .bold)
                            }
                            .foregroundColor(vm.tool == .pan ? ShieldTheme.accentText : ShieldTheme.primary(scheme))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(vm.tool == .pan ? ShieldTheme.accent(scheme) : ShieldTheme.cardBackground(scheme), in: Capsule())
                            .overlay(Capsule().stroke(ShieldTheme.accentStroke(scheme), lineWidth: 0.8))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }

                    HStack(spacing: 0) {
                        Button {
                            withAnimation(reduceMotion ? nil : .snappy) { zoomScale = max(1, zoomScale - 0.5) }
                        } label: {
                            Image(systemName: "minus.magnifyingglass")
                                .frame(width: 44, height: 44)
                        }
                        .disabled(zoomScale <= 1)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityLabel(LanguageManager.shared.editor("editor_zoom_out"))
                        .keyboardShortcut("-", modifiers: .command)

                        Button {
                            withAnimation(reduceMotion ? nil : .snappy) {
                                zoomScale = 1
                                panOffset = .zero
                            }
                        } label: {
                            Text("\(Int(effectiveZoom * 100))%")
                                .shieldFont(11, weight: .semibold, design: .monospaced)
                                .foregroundColor(ShieldTheme.primary(scheme))
                                .frame(minWidth: 44, minHeight: 44)
                        }
                        .buttonStyle(.plain)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityLabel(LanguageManager.shared.editor("editor_reset_zoom"))

                        Button {
                            withAnimation(reduceMotion ? nil : .snappy) { zoomScale = min(4, zoomScale + 0.5) }
                        } label: {
                            Image(systemName: "plus.magnifyingglass")
                                .frame(width: 44, height: 44)
                        }
                        .disabled(zoomScale >= 4)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .accessibilityLabel(LanguageManager.shared.editor("editor_zoom_in"))
                        .keyboardShortcut("+", modifiers: .command)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(LanguageManager.shared.editor("editor_zoom_controls"))
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .background(ShieldTheme.cardBackground(scheme), in: Capsule())
                    .overlay(Capsule().stroke(ShieldTheme.line(scheme), lineWidth: 0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(ShieldTheme.s4)
            }
            .onChange(of: geo.size) { oldSize, newSize in
                guard oldSize.width > 0, oldSize.height > 0, zoomScale > 1 else { return }
                panOffset = DocumentCoordinateTransform.preserveFocalPoint(
                    oldSize: oldSize,
                    newSize: newSize,
                    currentPan: panOffset,
                    effectiveZoom: zoomScale
                )
            }
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .accessibilityIdentifier("editor.canvasArea")
    }

    // MARK: - Mode chips

    private var modeChips: some View {
        EditorModeChips(
            activeMode: vm.activeMode,
            lang: appState.language,
            isPro: pm.isPro,
            onLockedTap: {
                PremiumManager.recordFeatureGate(.professionalModes, trigger: .featureLocked)
                paywallTrigger = .featureLocked
                showPaywall = true
            },
            onSelect: { mode in
                guard vm.applyMode(mode) else {
                    paywallTrigger = .featureLocked
                    showPaywall = true
                    return
                }
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
                PremiumManager.recordFeatureGate(.advancedStyles, trigger: .styleLocked)
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
            activeMode: vm.activeMode,
            lang: appState.language,
            isPro: pm.isPro,
            watermarkActive: vm.watermark != nil,
            adjustActive: vm.showAdjustPanel,
            adjustDirty: !vm.imageAdjustment.isDefault,
            onUndo: { vm.undo() },
            onRedo: { vm.redo() },
            onModeSelect: { mode in
                guard vm.applyMode(mode) else {
                    paywallTrigger = .featureLocked
                    showPaywall = true
                    return
                }
                vm.tool = .rect
                vm.activeRedactionID = nil
            },
            onLockedModeTap: {
                PremiumManager.recordFeatureGate(.professionalModes, trigger: .featureLocked)
                paywallTrigger = .featureLocked
                showPaywall = true
            },
            onToolTap: handleToolTap
        )
    }

    private func handleToolTap(_ tool: EditorTool) {
        if tool == .watermark {
            showWatermarkConfig = true
            withAnimation(.easeInOut(duration: 0.15)) { vm.tool = .rect }
            return
        }

        if tool.requiresPro && !pm.isPro {
            if let feature = tool.premiumFeature {
                PremiumManager.recordFeatureGate(feature, trigger: .featureLocked)
            }
            paywallTrigger = .featureLocked
            showPaywall = true
            return
        }
        withAnimation(.easeInOut(duration: 0.15)) {
            vm.tool = tool
        }
        switch tool {
        case .pan:
            break
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
    @ViewBuilder let content: () -> Content
    @Environment(\.colorScheme) var scheme

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(ShieldTheme.cardBackground(scheme))
        .presentationDetents([.medium, .large])
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
