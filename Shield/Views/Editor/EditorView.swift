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

    init(doc: DocumentItem) {
        _vm = StateObject(wrappedValue: EditorViewModel(doc: doc))
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
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
            modeChips
            maskStylePicker
            bottomBar
        }
        .background(ShieldTheme.surface0.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear {
            if let style = appState.pendingMaskStyle {
                vm.maskStyle = style
                appState.pendingMaskStyle = nil
            }
        }
        .sheet(isPresented: $vm.showOCRSheet) {
            SheetContainer(heightFraction: 0.72) {
                OCRSheetView(
                    doc: vm.doc,
                    lang: appState.language,
                    onMaskField: { rect in
                        vm.addFromOCR(rect: rect)
                        vm.showOCRSheet = false
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
        .onReceive(vm.$doc.dropFirst()) { updated in
            appState.updateDocument(updated)
        }
        .onDisappear {
            appState.updateDocument(vm.documentSnapshot)
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button(LanguageManager.shared.common("common_cancel")) {
                if vm.redactions.isEmpty {
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

            VStack(spacing: 1) {
                Text(vm.doc.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .lineLimit(1)
                Text(vm.redactions.isEmpty
                     ? LanguageManager.shared.editor("editor_no_redactions")
                     : appState.redactionsCount(vm.redactions.count))
                    .font(.system(size: 11))
                    .foregroundColor(ShieldTheme.textTertiary)
            }

            Spacer()

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
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.vertical, 10)
        .background(ShieldTheme.surface0.ignoresSafeArea(edges: .top))
        .overlay(alignment: .bottom) { ShieldDivider() }
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
                    Text(LanguageManager.shared.editor("editor_sensitive_suggested", vm.suggestedRedactionCount))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(ShieldTheme.textPrimary)
                    Text(LanguageManager.shared.editor("editor_sensitive_based_on_template"))
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
            .padding(.vertical, 10)
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
            .padding(.vertical, 10)
            .background(ShieldTheme.accentDim)
            .overlay(
                Rectangle()
                    .stroke(ShieldTheme.accent.opacity(0.3), lineWidth: 0.5)
            )
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Canvas area

    private func canvasSize(available: CGSize) -> CGSize {
        let w = available.width - 32  // hPad * 2
        let h = available.height
        guard vm.doc.kind == .photo else {
            return CGSize(width: w, height: w / 1.6)
        }
        let img = vm.currentImageFileName.flatMap {
            AppState.loadImage(fileName: $0, isVaulted: vm.doc.isVaulted)
        }
        guard let img = img else { return CGSize(width: w, height: h) }
        let aspect = img.size.width / img.size.height
        let fitH = w / aspect
        if fitH <= h {
            return CGSize(width: w, height: fitH)
        } else {
            return CGSize(width: h * aspect, height: h)
        }
    }

    private var canvasArea: some View {
        GeometryReader { geo in
            let sz = canvasSize(available: geo.size)
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
            .padding(.vertical, 6)
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
        HStack {
            // Undo / Redo
            HStack(spacing: 4) {
                Button {
                    vm.undo()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(vm.canUndo ? ShieldTheme.textPrimary : ShieldTheme.textQuaternary)
                        .frame(width: 38, height: 38)
                        .background(ShieldTheme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!vm.canUndo)

                Button {
                    vm.redo()
                } label: {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(vm.canRedo ? ShieldTheme.textPrimary : ShieldTheme.textQuaternary)
                        .frame(width: 38, height: 38)
                        .background(ShieldTheme.surface2)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(!vm.canRedo)
            }

            Spacer()

            // Tools
            HStack(spacing: 4) {
                ForEach(EditorTool.allCases) { tool in
                    let isSelected = vm.tool == tool
                    let watermarkActive = tool == .watermark && vm.watermark != nil
                    let adjustActive = tool == .adjust && vm.showAdjustPanel
                    let adjustDirty  = tool == .adjust && !vm.imageAdjustment.isDefault
                    Button {
                        handleToolTap(tool)
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: tool.icon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(
                                    (isSelected || adjustActive) ? ShieldTheme.accentText : ShieldTheme.textPrimary
                                )
                                .frame(width: 38, height: 38)
                                .background((isSelected || adjustActive) ? ShieldTheme.accent : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            if watermarkActive || adjustDirty {
                                Circle()
                                    .fill(adjustDirty ? ShieldTheme.info : ShieldTheme.success)
                                    .frame(width: 8, height: 8)
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(ShieldTheme.surface2.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { ShieldDivider() }
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

    var body: some View {
        VStack(spacing: 0) {
            content()
        }
        .background(ShieldTheme.surface2)
        .presentationDetents([.fraction(heightFraction)])
        .presentationDragIndicator(.visible)
        .presentationBackground(ShieldTheme.surface2)
    }
}
