import SwiftUI
import LocalAuthentication
import UIKit

// MARK: - HomeView

struct HomeView: View {
    var onScanTap: (() -> Void)? = nil
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @ObservedObject private var cloud = CloudSyncManager.shared
    @ObservedObject private var directCloud = DirectCloudStorageManager.shared
    @Environment(\.colorScheme) var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var showAllDocs = false
    @State private var allDocumentsMetric: HomeLibraryMetric = .documents
    @State private var showFilters = false
    @State private var showPaywall = false
    @State private var showCloudImport = false
    @State private var requestedCloudProvider: ExternalStorageProvider?
    @State private var showBatchRedact = false
    @State private var quickAccessToolsScrollRequest = 0
    @State private var verticalFoldWidth: CGFloat = 0
    @FocusState private var searchFocused: Bool

    // Vault auth flow from recents
    @State private var showVaultAuthForDoc: DocumentItem? = nil
    @State private var showVaultPINEntry = false
    @State private var showVaultPINSetup = false
    @State private var vaultAuthDoc: DocumentItem? = nil
    @State private var showVaultAutoLock = false
    @State private var vaultAutoLockDoc: DocumentItem? = nil

    var body: some View {
        ZStack(alignment: .top) {
            SeasonalThemeBackdrop()

            if ShieldTheme.activeThemeID == .halloween2026 {
                SeasonalThemeHomeBackdrop()
                    .ignoresSafeArea(edges: .top)
                    .accessibilityHidden(true)
            }

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    Group {
                        Color.clear
                            .frame(height: 1)
                            .id("home.top")
                        if horizontalSizeClass == .regular && !dynamicTypeSize.isAccessibilitySize {
                            regularHomeDashboard
                        } else {
                            LazyVStack(spacing: 0) {
                                heroSection
                                searchSection
                                quickAccessSection
                                    .padding(.bottom, 16)
                                localSearchIndexStatus
                                categoryGrid
                                libraryStatistics
                                recentsSection
                                workspaceSection
                                    .padding(.bottom, 24)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: ShieldTheme.workspaceWidth)
                    .frame(maxWidth: .infinity)
                }
                .background {
                    DuoVerticalDivisionReader(width: $verticalFoldWidth)
                }
                .contentMargins(.bottom, 24, for: .scrollContent)
                .scrollDismissesKeyboard(.interactively)
                .accessibilityIdentifier("home.scroll")
                .onAppear {
                    Task { @MainActor in
                        await Task.yield()
                        proxy.scrollTo("home.top", anchor: .top)
                    }
                }
                .onChange(of: quickAccessToolsScrollRequest) { _, _ in
                    Task { @MainActor in
                        await Task.yield()
                        withAnimation(reduceMotion ? nil : ShieldMotion.navigation) {
                            proxy.scrollTo("home.workspace", anchor: .top)
                        }
                    }
                }
            }
        }
        .colorScheme(appState.preferredScheme)
        .toolbar {
            if #available(iOS 27.1, *) {
                ToolbarItem(placement: .topBarLeading) {
                    HomeToolbarBrandLabel(
                        scheme: appState.preferredScheme,
                        isHalloween: ShieldTheme.activeThemeID == .halloween2026
                    )
                }
                .axisBehavior(.horizontalOnly)

                ToolbarItem(placement: .topBarTrailing) {
                    HomeProfileToolbarButton(
                        scheme: appState.preferredScheme,
                        isManagedTheme: ShieldTheme.activeThemeID.isSeasonal,
                        onToggleLanguage: toggleLanguage,
                        onToggleScheme: toggleColorScheme,
                        onOpenSettings: openSettings
                    )
                }
                .axisBehavior(.horizontalOnly)
            } else {
                ToolbarItem(placement: .topBarLeading) {
                    HomeToolbarBrandLabel(
                        scheme: appState.preferredScheme,
                        isHalloween: ShieldTheme.activeThemeID == .halloween2026
                    )
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HomeProfileToolbarButton(
                        scheme: appState.preferredScheme,
                        isManagedTheme: ShieldTheme.activeThemeID.isSeasonal,
                        onToggleLanguage: toggleLanguage,
                        onToggleScheme: toggleColorScheme,
                        onOpenSettings: openSettings
                    )
                }
            }

            if UIDevice.current.userInterfaceIdiom == .pad, let onScanTap {
                ToolbarItem(placement: .topBarTrailing) {
                    if #available(iOS 26.0, *) {
                        Button(action: onScanTap) {
                            Image(systemName: "camera.viewfinder")
                        }
                        .buttonStyle(.glassProminent)
                        .accessibilityLabel(LanguageManager.shared.capture("capture_scan_document"))
                        .accessibilityHint(LanguageManager.shared.capture("capture_scan_accessibility_hint"))
                        .accessibilityIdentifier("tab.capture")
                    } else {
                        Button(action: onScanTap) {
                            Image(systemName: "camera.viewfinder")
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityLabel(LanguageManager.shared.capture("capture_scan_document"))
                        .accessibilityHint(LanguageManager.shared.capture("capture_scan_accessibility_hint"))
                        .accessibilityIdentifier("tab.capture")
                    }
                }
            }
        }
        .sheet(isPresented: $showAllDocs) {
            AllDocumentsView(metric: allDocumentsMetric).environmentObject(appState)
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet(isPresented: $showFilters).environmentObject(appState)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: .settingsUpgrade).environmentObject(appState)
        }
        .sheet(isPresented: $showCloudImport) {
            ExternalStoragePickerSheet(
                isPresented: $showCloudImport,
                initialProvider: requestedCloudProvider
            ) { url in
                requestedCloudProvider = nil
                appState.pendingSharedImportURL = url
                appState.showCapture = true
            }.environmentObject(appState)
        }
        .sheet(isPresented: $showBatchRedact) {
            BatchRedactView(isPresented: $showBatchRedact)
                .environmentObject(appState)
        }
        // Vault-authenticated editor for vaulted docs opened from the recents list
        .fullScreenCover(item: $showVaultAuthForDoc) { doc in
            EditorView(doc: doc)
                .environmentObject(appState)
                .onDisappear {
                    if doc.isVaulted {
                        vaultAutoLockDoc = doc
                        showVaultAutoLock = true
                    }
                }
        }
        .fullScreenCover(isPresented: $showVaultPINEntry) {
            if let doc = vaultAuthDoc {
                PINEntryView(isPresented: $showVaultPINEntry) {
                    showVaultAuthForDoc = doc
                }
                .environmentObject(appState)
            }
        }
        .fullScreenCover(isPresented: $showVaultPINSetup) {
            if let doc = vaultAuthDoc {
                PINSetupView(isPresented: $showVaultPINSetup) {
                    showVaultAuthForDoc = doc
                }
                .environmentObject(appState)
            }
        }
        // Auto-lock countdown overlay (covers the whole Home)
        .overlay {
            if showVaultAutoLock, let doc = vaultAutoLockDoc {
                VaultAutoLockOverlay(
                    doc: doc,
                    lang: appState.language,
                    scheme: appState.preferredScheme,
                    onKeepEditing: {
                        showVaultAutoLock = false
                        vaultAutoLockDoc = nil
                        showVaultAuthForDoc = doc
                    },
                    onLockNow: {
                        showVaultAutoLock = false
                        vaultAutoLockDoc = nil
                    },
                    onTimerExpired: {
                        showVaultAutoLock = false
                        vaultAutoLockDoc = nil
                    }
                )
                .zIndex(100)
            }
        }
        .onAppear {
            Task { @MainActor in
                await Task.yield()
                appState.prepareLocalSearchIndexIfNeeded()
            }
        }
        .onChange(of: appState.searchQuery) { _, _ in
            Task { @MainActor in
                await Task.yield()
                appState.prepareLocalSearchIndexIfNeeded()
            }
        }
    }

    // MARK: - Hero

    private var regularHomeDashboard: some View {
        VStack(spacing: 18) {
            regularWelcomeHeader
            heroSection

            HStack(alignment: .top, spacing: 16 + verticalFoldWidth) {
                VStack(spacing: 0) {
                    searchSection
                    localSearchIndexStatus
                    categoryGrid
                    libraryStatistics
                        .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .top)

                VStack(spacing: 0) {
                    quickAccessSection
                        .padding(.bottom, 12)
                    workspaceSection
                        .padding(.bottom, 12)
                    recentsSection
                }
                .frame(maxWidth: .infinity, alignment: .top)
            }
        }
        .padding(.top, 12)
    }

    private var libraryStatistics: some View {
        let redactedCount = appState.documents.filter {
            $0.redactionCount > 0 || $0.totalRedactionCount > 0
        }.count
        let watermarkedCount = appState.documents.filter { document in
            guard let text = document.watermark?.text else { return false }
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count

        return HomeLibraryStatisticsView(
            documentCount: appState.documents.count,
            redactedDocumentCount: redactedCount,
            vaultDocumentCount: appState.vaultDocuments.count,
            watermarkedDocumentCount: watermarkedCount,
            scheme: appState.preferredScheme,
            language: appState.language,
            onSelect: { metric in
                appState.activeCategoryID = DocumentCategory.all.rawValue
                appState.searchQuery = ""
                allDocumentsMetric = metric
                showAllDocs = true
            }
        )
    }

    private var quickAccessSection: some View {
        HomeQuickAccessSection(
            scheme: appState.preferredScheme,
            onOpenLibrary: {
                appState.activeCategoryID = DocumentCategory.all.rawValue
                appState.searchQuery = ""
                allDocumentsMetric = .documents
                showAllDocs = true
            },
            onOpenVault: { appState.activeTab = .vault },
            onOpenTools: {
                withAnimation(reduceMotion ? nil : ShieldMotion.navigation) {
                    appState.isHomeWorkspaceToolsExpanded = true
                }
                // Publish the parent state before asking ScrollViewReader to
                // move the regular-width dashboard to the expanded section.
                Task { @MainActor in
                    await Task.yield()
                    quickAccessToolsScrollRequest += 1
                }
            },
            toolsExpanded: appState.isHomeWorkspaceToolsExpanded
        )
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.top, 8)
    }

    private var regularWelcomeHeader: some View {
        let isHalloween = ShieldTheme.activeThemeID == .halloween2026 && appState.preferredScheme == .dark

        return HStack {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(LanguageManager.shared.home("home_hero_title"))
                        .shieldFont(32, weight: .heavy)
                        .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                        .fixedSize(horizontal: false, vertical: true)
                    if isHalloween {
                        Text("🦇")
                            .font(.system(size: 22))
                    }
                }

                Text(LanguageManager.shared.home("home_hero_subtitle"))
                    .shieldFont(17, weight: .medium)
                    .foregroundColor(isHalloween ? Color(hex: "D8B4FE") : ShieldTheme.secondary(appState.preferredScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.bottom, 2)
    }

    private var heroSection: some View {
        HomeHeroCardView(
            scheme: appState.preferredScheme,
            isPro: pm.isPro,
            freeUsed: max(pm.freeDocumentsProcessedCount, appState.documents.count),
            freeLimit: PremiumManager.freeDocumentLimit,
            showsHeading: horizontalSizeClass != .regular || dynamicTypeSize.isAccessibilitySize,
            onProtect: openDocumentIntake,
            onUpgrade: { showPaywall = true },
            onLearnMore: openSettings
        )
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    // MARK: - Search

    private var searchSection: some View {
        let isHalloween = ShieldTheme.activeThemeID == .halloween2026 && appState.preferredScheme == .dark
        return HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .shieldFont(14, weight: .medium)
                .foregroundColor(searchFocused
                    ? (isHalloween ? Color(hex: "FFA53D") : ShieldTheme.accent)
                    : (isHalloween ? Color(hex: "A78BFA") : ShieldTheme.tertiary(appState.preferredScheme)))

            TextField(LanguageManager.shared.home("home_search_content_hint"), text: $appState.searchQuery)
                .shieldFont(15)
                .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                .focused($searchFocused)
                .submitLabel(.search)
                .accessibilityIdentifier("home.searchField")

            if !appState.searchQuery.isEmpty {
                Button {
                    appState.searchQuery = ""
                    searchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .shieldFont(14)
                        .foregroundColor(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.tertiary(appState.preferredScheme))
                        .frame(minWidth: 40, minHeight: 40)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LanguageManager.shared.common("common_clear"))
            }

            Button {
                showFilters = true
            } label: {
                Image(systemName: appState.hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .shieldFont(18, weight: .medium)
                    .foregroundColor(appState.hasActiveFilter ? (isHalloween ? Color(hex: "FFA53D") : ShieldTheme.accent) : (isHalloween ? Color(hex: "A78BFA") : ShieldTheme.tertiary(appState.preferredScheme)))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(minWidth: 40, minHeight: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(LanguageManager.shared.home("home_filters"))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            isHalloween
                ? Color(hex: "1C1026").opacity(0.85)
                : ShieldTheme.cardBackground(appState.preferredScheme)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ShieldTheme.rMD)
                .stroke(
                    isHalloween
                        ? (searchFocused ? Color(hex: "FF9A3D") : Color(hex: "7C3AED").opacity(0.35))
                        : (searchFocused ? ShieldTheme.accent.opacity(0.6) : ShieldTheme.line(appState.preferredScheme)),
                    lineWidth: searchFocused ? 1.5 : 0.8
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD))
        .animation(.easeInOut(duration: 0.15), value: searchFocused)
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var localSearchIndexStatus: some View {
        if appState.isPreparingLocalSearchOCR {
            HStack(spacing: ShieldTheme.s2) {
                ProgressView()
                    .controlSize(.mini)
                    .tint(ShieldTheme.accent)
                Text(LanguageManager.shared.home("home_search_preparing"))
                    .shieldFont(11, weight: .medium)
                    .foregroundStyle(ShieldTheme.secondary(appState.preferredScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.top, -10)
            .padding(.bottom, 12)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("home.search.indexing")
        }
    }

    // MARK: - Categories

    @State private var showNewCategory = false

    private var categoryGrid: some View {
        Group {
            if horizontalSizeClass == .compact && !dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(minimum: 44), spacing: 8), count: 4),
                    alignment: .leading,
                    spacing: 8
                ) {
                    categoryButtons(showsLabels: false)
                }
            } else {
                LazyVGrid(
                    columns: dynamicTypeSize.isAccessibilitySize
                        ? [GridItem(.flexible())]
                        : [GridItem(.adaptive(minimum: 130, maximum: 220), spacing: 8)],
                    alignment: .leading,
                    spacing: 8
                ) {
                    categoryButtons(showsLabels: true)
                }
            }
        }
        .padding(.horizontal, ShieldTheme.s5)
        .accessibilityIdentifier("home.categoryGrid")
        .padding(.bottom, 8)
        .sheet(isPresented: $showNewCategory) {
            NewCategorySheet(isPresented: $showNewCategory)
                .environmentObject(appState)
        }
    }

    @ViewBuilder
    private func categoryButtons(showsLabels: Bool) -> some View {
        ForEach(DocumentCategory.allCases) { cat in
            HomeCategoryChip(
                label: cat.label(lang: appState.language),
                icon: cat.icon,
                isActive: appState.activeCategoryID == cat.rawValue,
                scheme: appState.preferredScheme,
                showsLabel: showsLabels,
                accessibilityID: "home.category.\(cat.rawValue)"
            ) {
                withAnimation { appState.activeCategoryID = cat.rawValue }
            }
        }
        ForEach(appState.customCategories) { cat in
            HomeCategoryChip(
                label: cat.name,
                icon: cat.icon,
                isActive: appState.activeCategoryID == cat.id,
                scheme: appState.preferredScheme,
                showsLabel: showsLabels,
                accessibilityID: "home.category.custom.\(cat.id)"
            ) {
                withAnimation { appState.activeCategoryID = cat.id }
            }
            .contextMenu {
                Button(role: .destructive) {
                    appState.deleteCustomCategory(id: cat.id)
                } label: {
                    Label(LanguageManager.shared.common("common_delete_category"), systemImage: "trash")
                }
            }
        }
        Button {
            showNewCategory = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .shieldFont(showsLabels ? 11 : 16, weight: .semibold)
                if showsLabels {
                    Text(LanguageManager.shared.common("common_new"))
                        .shieldFont(12, weight: .semibold)
                }
            }
            .foregroundColor(ShieldTheme.accent)
            .padding(.horizontal, showsLabels ? 10 : 0)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .center)
            .contentShape(Rectangle())
            .background(ShieldTheme.accentDim)
            .overlay(Capsule().stroke(ShieldTheme.accent.opacity(0.4), lineWidth: 0.5))
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(LanguageManager.shared.common("common_new"))
        .accessibilityIdentifier("home.category.add")
    }

    // MARK: - Modes

    private var modesSection: some View {
        HomeModesSection(
            scheme: scheme,
            lang: appState.language,
            isPro: pm.isPro,
            onShowBatch: { showBatchRedact = true },
            onShowPaywall: { showPaywall = true },
            onModeSelected: { mode in
                appState.pendingRedactionMode = mode
                appState.showCapture = true
            }
        )
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private var workspaceSection: some View {
        let isHalloween = ShieldTheme.activeThemeID == .halloween2026 && appState.preferredScheme == .dark
        return VStack(spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : ShieldMotion.state) {
                    appState.isHomeWorkspaceToolsExpanded.toggle()
                }
            } label: {
                HStack(spacing: ShieldTheme.s3) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.accent(scheme))
                    Text(LanguageManager.shared.home("home_tools_services"))
                        .font(.headline)
                        .foregroundStyle(ShieldTheme.primary(scheme))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(isHalloween ? Color(hex: "FFA53D").opacity(0.8) : ShieldTheme.tertiary(scheme))
                        .rotationEffect(.degrees(appState.isHomeWorkspaceToolsExpanded ? 180 : 0))
                }
                .padding(ShieldTheme.s4)
                .background(
                    isHalloween
                        ? Color(hex: "1C1026").opacity(0.65)
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay {
                    if isHalloween {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: "7C3AED").opacity(0.3), lineWidth: 0.8)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityValue(LanguageManager.shared.common(
                appState.isHomeWorkspaceToolsExpanded ? "common_expanded" : "common_collapsed"
            ))
            .accessibilityIdentifier("home.workspace.toggle")
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.top, horizontalSizeClass == .regular ? 8 : ShieldTheme.s4)
            .background {
                if horizontalSizeClass == .regular {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(ShieldTheme.cardBackground(appState.preferredScheme))
                }
            }
            .overlay {
                if horizontalSizeClass == .regular {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ShieldTheme.line(appState.preferredScheme), lineWidth: 0.8)
                }
            }

            if appState.isHomeWorkspaceToolsExpanded {
                modesSection
                vaultSection
                cloudStorageSection
            }
        }
        .id("home.workspace")
    }

    // MARK: - Recents

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(LanguageManager.shared.home("home_recent_document"))
                    .shieldFont(24, weight: .heavy)
                    .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 12)

                Button {
                    showAllDocs = true
                } label: {
                    HStack(spacing: 3) {
                        Text(LanguageManager.shared.home("home_see_all"))
                            .shieldFont(14, weight: .semibold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(
                        ShieldTheme.activeThemeID == .halloween2026 && appState.preferredScheme == .dark
                            ? Color(hex: "FFA53D")
                            : ShieldTheme.accentColor(appState.preferredScheme)
                    )
                    .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LanguageManager.shared.home("home_see_all"))
            }
            .padding(.horizontal, ShieldTheme.s5)

            if appState.filteredDocuments.isEmpty {
                emptyLibraryState
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: horizontalSizeClass == .regular ? 220 : nil)
                    .background {
                        if horizontalSizeClass == .regular {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(ShieldTheme.cardBackground(appState.preferredScheme))
                        }
                    }
                    .overlay {
                        if horizontalSizeClass == .regular {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(ShieldTheme.line(appState.preferredScheme), lineWidth: 0.8)
                        }
                    }
                    .padding(.horizontal, horizontalSizeClass == .regular ? ShieldTheme.s5 : 0)
                    .padding(.bottom, horizontalSizeClass == .regular ? 4 : 24)
            } else {
                VStack(spacing: 0) {
                    if let doc = appState.filteredDocuments.first {
                        recentDocumentCard(for: doc)
                    }
                }
                .padding(.horizontal, ShieldTheme.s5)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func recentDocumentCard(for doc: DocumentItem) -> some View {
        HomeRecentDocumentCard(doc: doc, lang: appState.language) {
            guard !appState.showCapture else { return }
            guard !doc.isLocked else { return }
            if doc.isVaulted {
                vaultAuthDoc = doc
                authenticateForVaultDoc(doc)
            } else {
                appState.prepareSearchNavigation(to: doc)
                appState.selectedDoc = doc
            }
        }
        .environmentObject(appState)
        .contextMenu {
            if !doc.isVaulted {
                Button {
                    appState.toggleFavorite(doc)
                } label: {
                    Label(doc.isFavorite
                          ? LanguageManager.shared.home("home_remove_favorite")
                          : LanguageManager.shared.home("home_mark_favorite"),
                          systemImage: doc.isFavorite ? "star.slash" : "star.fill")
                }
            }
            Button {
                if doc.isVaulted {
                    vaultAuthDoc = doc
                    authenticateForVaultDoc(doc)
                } else {
                    appState.toggleVault(doc)
                }
            } label: {
                Label(doc.isVaulted
                      ? LanguageManager.shared.home("home_open_vault")
                      : LanguageManager.shared.home("home_move_vault"),
                      systemImage: doc.isVaulted ? "lock.open" : "lock.fill")
            }
            Divider()
            Button(role: .destructive) {
                appState.deleteDocument(doc)
            } label: {
                Label(LanguageManager.shared.common("common_delete"), systemImage: "trash")
            }
        }
    }

    private var paginationControls: some View {
        HomePaginationControls(
            scheme: appState.preferredScheme,
            currentPage: appState.recentDocsPage,
            totalPages: appState.recentDocsTotalPages,
            onPrevious: {
                withAnimation { appState.recentDocsPage = max(0, appState.recentDocsPage - 1) }
            },
            onNext: {
                withAnimation { appState.recentDocsPage = min(appState.recentDocsTotalPages - 1, appState.recentDocsPage + 1) }
            }
        )
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.top, 4)
    }

    private func authenticateForVaultDoc(_ doc: DocumentItem) {
        let ctx = LAContext()
        var error: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            if PINManager.hasPIN {
                showVaultPINEntry = true
            } else {
                showVaultPINSetup = true
            }
            return
        }
        ctx.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: LanguageManager.shared.home("home_vault_auth_reason")
        ) { success, _ in
            DispatchQueue.main.async {
                if success { showVaultAuthForDoc = doc }
                else if PINManager.hasPIN { showVaultPINEntry = true }
                else { showVaultPINSetup = true }
            }
        }
    }

    private var emptyLibraryState: some View {
        let hasActiveFilter = appState.hasActiveFilter
        return VStack(spacing: 8) {
            ShieldStateView(
                kind: .empty,
                title: hasActiveFilter
                    ? LanguageManager.shared.home("home_no_results")
                    : LanguageManager.shared.home("home_no_documents"),
                message: hasActiveFilter
                    ? LanguageManager.shared.home("home_no_results_subtitle")
                    : LanguageManager.shared.home("home_no_documents_subtitle"),
                actionLabel: hasActiveFilter
                    ? LanguageManager.shared.home("home_clear_filters")
                    : nil,
                action: hasActiveFilter ? {
                    withAnimation(reduceMotion ? nil : ShieldMotion.state) {
                        appState.activeCategoryID = DocumentCategory.all.rawValue
                        appState.searchQuery = ""
                    }
                } : nil
            )

            if !hasActiveFilter && horizontalSizeClass == .regular && dynamicTypeSize.isAccessibilitySize {
                ShieldButton(
                    label: LanguageManager.shared.capture("capture_scan_document"),
                    icon: "camera.viewfinder"
                ) {
                    appState.showCapture = true
                }
                .frame(maxWidth: 320)
            }

        }
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.vertical, horizontalSizeClass == .regular ? 20 : 0)
    }

    // MARK: - Cloud Storage

    private var cloudStorageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: LanguageManager.shared.home("home_cloud_storage"),
                action: pm.isPro ? nil : {
                    PremiumManager.recordFeatureGate(.cloudWorkflow, trigger: .settingsUpgrade)
                    showPaywall = true
                },
                actionLabel: LanguageManager.shared.home("home_pro_badge")
            )

            VStack(spacing: 0) {
                // iCloud row
                cloudRow(
                    icon: "icloud.fill",
                    colorHex: "5E5CE6",
                    name: "iCloud",
                    statusText: iCloudStatusText,
                    statusColor: iCloudStatusColor,
                    isPro: true,
                    isConnected: cloud.isAvailable,
                    onTap: {
                        if !pm.isPro {
                            PremiumManager.recordFeatureGate(.cloudWorkflow, trigger: .settingsUpgrade)
                            showPaywall = true
                            return
                        }
                        withAnimation { appState.activeTab = .settings }
                    }
                )

                ShieldDivider().padding(.leading, 58)

                // External providers
                ForEach(Array(ExternalStorageProvider.allCases.enumerated()), id: \.element.id) { idx, provider in
                    cloudRow(
                        icon: provider.icon,
                        colorHex: provider.iconColor,
                        name: provider.displayName,
                        statusText: providerStatusText(provider),
                        statusColor: providerStatusColor(provider),
                        isPro: true,
                        isConnected: directCloud.isConnected(provider),
                        showsDisclosureIndicator: true,
                        onTap: {
                            if !pm.isPro {
                                PremiumManager.recordFeatureGate(.cloudWorkflow, trigger: .settingsUpgrade)
                                showPaywall = true
                                return
                            }
                            requestedCloudProvider = provider
                            showCloudImport = true
                        }
                    )

                    if idx < ExternalStorageProvider.allCases.count - 1 {
                        ShieldDivider().padding(.leading, 58)
                    }
                }
            }
            .background(ShieldTheme.cardBackground(appState.preferredScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ShieldTheme.line(appState.preferredScheme), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, ShieldTheme.s4)

            if !pm.isPro {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .shieldFont(11, weight: .semibold)
                        .foregroundColor(ShieldTheme.accent)
                    Text(LanguageManager.shared.home("home_connect_cloud_description"))
                        .shieldFont(12)
                        .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                }
                .padding(.horizontal, ShieldTheme.s4)
                .padding(.top, 2)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func cloudRow(
        icon: String,
        colorHex: String,
        name: String,
        statusText: String,
        statusColor: Color,
        isPro: Bool,
        isConnected: Bool,
        isAuthenticating: Bool = false,
        showsDisclosureIndicator: Bool = false,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon badge
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(hex: colorHex))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .shieldFont(16, weight: .semibold)
                        .foregroundColor(.white)
                }
                .opacity(pm.isPro ? 1 : 0.45)

                // Name + status
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(name)
                            .shieldFont(14, weight: .semibold)
                            .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                        if !pm.isPro {
                            Text(LanguageManager.shared.common("common_pro"))
                                .shieldFont(9, weight: .bold)
                                .foregroundColor(ShieldTheme.accentText)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(ShieldTheme.accent)
                                .clipShape(Capsule())
                        }
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(pm.isPro ? statusColor : ShieldTheme.tertiary(appState.preferredScheme))
                            .frame(width: 6, height: 6)
                        Text(pm.isPro ? statusText : LanguageManager.shared.home("home_requires_pro"))
                            .shieldFont(12)
                            .foregroundColor(pm.isPro ? statusColor : ShieldTheme.tertiary(appState.preferredScheme))
                    }
                }

                Spacer()

                // Action indicator
                if !pm.isPro {
                    Image(systemName: "lock.fill")
                        .shieldFont(13, weight: .medium)
                        .foregroundColor(ShieldTheme.accent)
                } else if isAuthenticating {
                    ProgressView().scaleEffect(0.7).tint(ShieldTheme.accent)
                } else {
                    Image(systemName: (isConnected || showsDisclosureIndicator) ? "chevron.right" : "plus.circle.fill")
                        .shieldFont(14, weight: isConnected ? .medium : .semibold)
                        .foregroundColor(isConnected ? ShieldTheme.tertiary(appState.preferredScheme) : ShieldTheme.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    // MARK: - Cloud status helpers

    private var iCloudStatusText: String {
        let enabled = UserDefaults.standard.bool(forKey: "shield.icloud.enabled")
        guard enabled else {
            return LanguageManager.shared.home("home_icloud_not_enabled")
        }
        if cloud.isAvailable {
            if let last = cloud.lastSyncFormatted {
                return LanguageManager.shared.home("home_icloud_synced_status", last)
            }
            return LanguageManager.shared.home("home_icloud_ready")
        }
        return LanguageManager.shared.home("home_icloud_unavailable")
    }

    private var iCloudStatusColor: Color {
        let enabled = UserDefaults.standard.bool(forKey: "shield.icloud.enabled")
        guard enabled else { return ShieldTheme.tertiary(scheme) }
        return cloud.isAvailable ? ShieldTheme.success : ShieldTheme.warning
    }

    private func providerStatusText(_ provider: ExternalStorageProvider) -> String {
        if !directCloud.isConfigured(provider) {
            return LanguageManager.shared.common("cloud_configuration_required")
        }
        return directCloud.isConnected(provider)
            ? LanguageManager.shared.common("cloud_connected")
            : LanguageManager.shared.common("cloud_tap_to_connect")
    }

    private func providerStatusColor(_ provider: ExternalStorageProvider) -> Color {
        directCloud.isConnected(provider) ? ShieldTheme.success : ShieldTheme.tertiary(scheme)
    }

    // MARK: - Vault

    private var vaultSection: some View {
        HomeVaultCard(
            scheme: appState.preferredScheme,
            onTap: { withAnimation { appState.activeTab = .vault } }
        )
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.top, 24)
    }

    private func toggleLanguage() {
        withAnimation {
            appState.language = appState.language == .es ? .en : .es
        }
    }

    private func toggleColorScheme() {
        guard !ShieldTheme.activeThemeID.isSeasonal else { return }
        withAnimation {
            appState.preferredScheme = appState.preferredScheme == .dark ? .light : .dark
        }
    }

    private func openDocumentIntake() {
        if let onScanTap {
            onScanTap()
        } else {
            appState.showCapture = true
        }
    }

    private func openSettings() {
        withAnimation {
            appState.activeTab = .settings
        }
    }

}

private struct HomeCategoryChip: View {
    let label: String
    let icon: String?
    let isActive: Bool
    let scheme: ColorScheme
    let showsLabel: Bool
    let accessibilityID: String
    let action: () -> Void
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
    }

    private var foreground: Color {
        if isHalloween {
            return isActive ? Color(hex: "150801") : Color(hex: "E0D4FC")
        }
        return isActive ? ShieldTheme.accent(scheme) : ShieldTheme.primary(scheme)
    }

    private var fill: Color {
        if isHalloween {
            return isActive ? Color(hex: "FFA53D") : Color(hex: "241436")
        }
        return isActive ? ShieldTheme.accentDim(scheme) : ShieldTheme.cardBackground(scheme)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: showsLabel ? 6 : 0) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: showsLabel ? 12 : 16, weight: .semibold))
                        .accessibilityHidden(true)
                }

                if showsLabel {
                    Text(label)
                        .shieldFont(13, weight: .semibold)
                        .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                        .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.82)
                    Spacer(minLength: 0)
                }

            }
            .foregroundStyle(foreground)
            .padding(.horizontal, showsLabel ? 10 : 0)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: showsLabel ? .leading : .center)
            .background(fill, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        isActive ? ShieldTheme.accent(scheme).opacity(0.7) : ShieldTheme.line(scheme),
                        lineWidth: isActive ? 1 : 0.6
                    )
            }
            .contentShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(label)
        .accessibilityIdentifier(accessibilityID)
        .accessibilityValue(LanguageManager.shared.common(isActive ? "common_selected" : "common_not_selected"))
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

// MARK: - FilterSheet

struct FilterSheet: View {
    @EnvironmentObject var appState: AppState
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var scheme

    private var effectiveScheme: ColorScheme { appState.preferredScheme }

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .frame(width: 36, height: 4)
                .foregroundColor(ShieldTheme.tertiary(effectiveScheme))
                .padding(.top, 10)

            HStack {
                Text(LanguageManager.shared.home("home_filters"))
                    .shieldFont(18, weight: .bold)
                    .foregroundColor(ShieldTheme.primary(effectiveScheme))
                Spacer()
                if appState.hasActiveFilter {
                    Button {
                        withAnimation {
                            appState.activeCategoryID = DocumentCategory.all.rawValue
                            appState.searchQuery = ""
                        }
                    } label: {
                        Text(LanguageManager.shared.home("home_clear"))
                            .shieldFont(13, weight: .semibold)
                            .foregroundColor(ShieldTheme.accent)
                    }
                }
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .shieldFont(13, weight: .medium)
                        .foregroundColor(ShieldTheme.tertiary(effectiveScheme))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .background(ShieldTheme.rowBackground(effectiveScheme))
                        .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rSM))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()
                .background(ShieldTheme.line(effectiveScheme))
                .padding(.horizontal, ShieldTheme.s5)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Category filter
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LanguageManager.shared.home("home_category_uppercase"))
                            .shieldFont(11, weight: .semibold)
                            .foregroundColor(ShieldTheme.tertiary(effectiveScheme))
                            .tracking(0.6)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            ForEach(DocumentCategory.allCases) { cat in
                                FilterChip(
                                    label: cat.label(lang: appState.language),
                                    icon: cat.icon,
                                    isActive: appState.activeCategoryID == cat.rawValue,
                                    scheme: effectiveScheme
                                ) {
                                    withAnimation { appState.activeCategoryID = cat.rawValue }
                                }
                            }
                            ForEach(appState.customCategories) { cat in
                                FilterChip(
                                    label: cat.name,
                                    icon: cat.icon,
                                    isActive: appState.activeCategoryID == cat.id,
                                    scheme: effectiveScheme
                                ) {
                                    withAnimation { appState.activeCategoryID = cat.id }
                                }
                            }
                        }
                    }

                    // Sort (UI only for now — extend AppState as needed)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(LanguageManager.shared.home("home_sort_by_uppercase"))
                            .shieldFont(11, weight: .semibold)
                            .foregroundColor(ShieldTheme.tertiary(effectiveScheme))
                            .tracking(0.6)

                        VStack(spacing: 0) {
                            ForEach(SortOption.allCases) { option in
                                HStack {
                                    Image(systemName: option.icon)
                                        .shieldFont(14)
                                        .foregroundColor(appState.sortOption == option ? ShieldTheme.accent : ShieldTheme.secondary(effectiveScheme))
                                        .frame(width: 20)
                                    Text(option.label(lang: appState.language))
                                        .shieldFont(15)
                                        .foregroundColor(ShieldTheme.primary(effectiveScheme))
                                    Spacer()
                                    if appState.sortOption == option {
                                        Image(systemName: "checkmark")
                                            .shieldFont(13, weight: .semibold)
                                            .foregroundColor(ShieldTheme.accent)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(
                                    appState.sortOption == option
                                        ? ShieldTheme.accentDim
                                        : ShieldTheme.cardBackground(effectiveScheme)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation { appState.sortOption = option }
                                }

                                if option != SortOption.allCases.last {
                                    Divider()
                                        .background(ShieldTheme.line(effectiveScheme))
                                        .padding(.leading, 48)
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD))
                        .overlay(RoundedRectangle(cornerRadius: ShieldTheme.rMD).stroke(ShieldTheme.line(effectiveScheme), lineWidth: 0.5))
                    }
                }
                .padding(ShieldTheme.s5)
            }

            // Apply
            Button {
                isPresented = false
            } label: {
                Text(LanguageManager.shared.home("home_apply_filters"))
                    .shieldFont(16, weight: .bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ShieldTheme.accent)
                    .foregroundColor(ShieldTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.bottom, 32)
        }
        .background(ShieldTheme.background(effectiveScheme).ignoresSafeArea())
        .colorScheme(appState.preferredScheme)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - FilterChip

struct FilterChip: View {
    let label: String
    let icon: String?
    let isActive: Bool
    let scheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .shieldFont(13, weight: .semibold)
                }
                Text(label)
                    .shieldFont(13, weight: .semibold)
                    .lineLimit(1)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .shieldFont(11, weight: .bold)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isActive ? ShieldTheme.accentDim : ShieldTheme.cardBackground(scheme))
            .foregroundColor(isActive ? ShieldTheme.accent : ShieldTheme.primary(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isActive ? ShieldTheme.accent.opacity(0.6) : ShieldTheme.line(scheme), lineWidth: isActive ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - ModeCard

struct ModeCard: View {
    let mode: RedactionMode
    let lang: AppLanguage
    var isLocked: Bool = false
    var action: (() -> Void)? = nil
    @Environment(\.colorScheme) var scheme

    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && scheme == .dark
    }

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(mode.color.opacity(0.13))
                        .frame(width: 32, height: 32)
                    Image(systemName: mode.icon)
                        .shieldFont(14, weight: .semibold)
                        .foregroundColor(mode.color)
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .shieldFont(9, weight: .bold)
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.label(lang: lang))
                        .shieldFont(13, weight: .bold)
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Text(mode.subtitle(lang: lang))
                        .shieldFont(11)
                        .foregroundColor(isHalloween ? Color(hex: "D8B4FE") : ShieldTheme.tertiary(scheme))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minWidth: 168, alignment: .leading)
            .background(
                isHalloween
                    ? Color(hex: "1C1026").opacity(0.85)
                    : ShieldTheme.cardBackground(scheme)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isHalloween
                            ? LinearGradient(colors: [Color(hex: "FF9A3D").opacity(0.4), Color(hex: "7C3AED").opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [ShieldTheme.line(scheme)], startPoint: .top, endPoint: .bottom),
                        lineWidth: isHalloween ? 1.0 : 0.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - DocumentRow

struct DocumentRow: View {
    let doc: DocumentItem
    let lang: AppLanguage
    var vaultUnlocked: Bool = false
    let action: () -> Void
    @EnvironmentObject var appState: AppState

    private var isHalloween: Bool {
        ShieldTheme.activeThemeID == .halloween2026 && appState.preferredScheme == .dark
    }

    private var shouldMask: Bool { doc.isVaulted && !vaultUnlocked }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack {
                    if doc.kind == .photo {
                        DocumentThumbnailView(doc: doc, maxPixelSize: 180, contentMode: .fill)
                            .frame(width: 60, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .blur(radius: shouldMask ? 4 : 0)
                    } else {
                        DocumentView(kind: doc.kind, size: CGSize(width: 60, height: 44),
                                     fields: doc.fields, redactions: doc.redactions(for: 0), watermark: doc.watermark,
                                     imageFileName: doc.imageFileName, isVaulted: doc.isVaulted,
                                     imageAdjustment: doc.imageAdjustment)
                            .frame(width: 60, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .blur(radius: shouldMask ? 4 : 0)
                    }

                    if doc.isLocked || shouldMask {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.4))
                        Image(systemName: "lock.fill")
                            .shieldFont(13, weight: .semibold)
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 60, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if shouldMask {
                            Text(LanguageManager.shared.home("home_protected_document"))
                                .shieldFont(14, weight: .semibold)
                                .foregroundColor(isHalloween ? Color(hex: "E9D5FF") : ShieldTheme.secondary(appState.preferredScheme))
                                .lineLimit(1)
                        } else {
                            Text(doc.title)
                                .shieldFont(14, weight: .bold)
                                .foregroundColor(isHalloween ? Color.white : ShieldTheme.primary(appState.preferredScheme))
                                .lineLimit(1)
                            if doc.isFavorite {
                                Image(systemName: "star.fill")
                                    .shieldFont(11)
                                    .foregroundColor(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.accent)
                                    .symbolEffect(.bounce, value: doc.isFavorite)
                            }
                        }
                    }
                    HStack(spacing: 6) {
                        if shouldMask {
                            Text(LanguageManager.shared.vault("vault_aes_badge"))
                                .shieldFont(11, weight: .bold)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(isHalloween ? Color(hex: "F97316").opacity(0.2) : ShieldTheme.accentDim(appState.preferredScheme))
                                .foregroundColor(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            Text("·")
                                .foregroundColor(isHalloween ? Color(hex: "C4B5FD") : ShieldTheme.tertiary(appState.preferredScheme))
                                .shieldFont(12)
                            Text(doc.compactDateLabel(lang: lang))
                                .shieldFont(12)
                                .foregroundColor(isHalloween ? Color(hex: "E9D5FF") : ShieldTheme.tertiary(appState.preferredScheme))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        } else {
                            Text(doc.category.label(lang: lang))
                                .shieldFont(11, weight: .semibold)
                                .lineLimit(1)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2.5)
                                .background(isHalloween ? Color(hex: "2D183B") : ShieldTheme.rowBackground(appState.preferredScheme))
                                .foregroundColor(isHalloween ? Color(hex: "F3E8FF") : ShieldTheme.secondary(appState.preferredScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 5))

                            Text("·")
                                .foregroundColor(isHalloween ? Color(hex: "C4B5FD") : ShieldTheme.tertiary(appState.preferredScheme))
                                .shieldFont(12)

                            Text(doc.compactDateLabel(lang: lang))
                                .shieldFont(12)
                                .foregroundColor(isHalloween ? Color(hex: "E9D5FF") : ShieldTheme.tertiary(appState.preferredScheme))
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)

                            if doc.redactionCount > 0 {
                                Text("·")
                                    .foregroundColor(isHalloween ? Color(hex: "C4B5FD") : ShieldTheme.tertiary(appState.preferredScheme))
                                    .shieldFont(12)
                                Text(appState.redactionsCount(doc.redactionCount))
                                    .shieldFont(12, weight: .bold)
                                    .foregroundColor(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.accent)
                                    .lineLimit(1)
                            }
                        }

                    }

                    // Keep the expiry state on its own line. The previous
                    // inline placement made short labels such as “Vigente”
                    // compete with category/date/redaction metadata and wrap
                    // one character per line in the compact vault card.
                    if vaultUnlocked {
                        expiryBadge
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 4)

                // Vault badge or chevron
                if doc.isVaulted {
                    Image(systemName: "lock.shield.fill")
                        .shieldFont(16, weight: .semibold)
                        .foregroundColor(isHalloween ? Color(hex: "FFA53D") : ShieldTheme.accent)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "chevron.right")
                        .shieldFont(12, weight: .semibold)
                        .foregroundColor(isHalloween ? Color(hex: "FFA53D").opacity(0.8) : ShieldTheme.tertiary(appState.preferredScheme))
                        .accessibilityHidden(true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                isHalloween
                    ? Color(hex: "1C1026").opacity(0.88)
                    : ShieldTheme.cardBackground(appState.preferredScheme)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isHalloween
                            ? LinearGradient(
                                colors: [Color(hex: "FF9A3D").opacity(0.45), Color(hex: "7C3AED").opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [ShieldTheme.line(appState.preferredScheme)], startPoint: .top, endPoint: .bottom),
                        lineWidth: isHalloween ? 1.0 : 0.8
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(ScaleButtonStyle())
        .disabled(doc.isLocked)
        .opacity(doc.isLocked ? 0.7 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private var accessibilityLabel: String {
        if shouldMask {
            return LanguageManager.shared.home("home_protected_document")
        }
        return doc.title
    }

    private var accessibilityHint: String {
        if doc.isLocked {
            return LanguageManager.shared.vault("vault_locked_desc")
        }
        if doc.isVaulted {
            return LanguageManager.shared.vault("vault_unlock_faceid")
        }
        return ""
    }

    @ViewBuilder
    private var expiryBadge: some View {
        switch DocumentExpiryReminderManager.shared.status(for: doc) {
        case .expiringSoon(let days):
            HStack(spacing: 3) {
                Image(systemName: "clock.badge.exclamationmark")
                    .shieldFont(9, weight: .bold)
                Text(LanguageManager.shared.vault("vault_expires_in", days))
                    .shieldFont(10, weight: .bold)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(ShieldTheme.warning.opacity(0.18))
            .foregroundColor(ShieldTheme.warning)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        case .expired:
            HStack(spacing: 3) {
                Image(systemName: "xmark.shield")
                    .shieldFont(9, weight: .bold)
                Text(LanguageManager.shared.vault("vault_expired"))
                    .shieldFont(10, weight: .bold)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(ShieldTheme.danger.opacity(0.18))
            .foregroundColor(ShieldTheme.danger)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        case .valid:
            Text(LanguageManager.shared.vault("vault_valid"))
                .shieldFont(10, weight: .semibold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(ShieldTheme.success.opacity(0.15))
                .foregroundColor(ShieldTheme.success)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        case .notSet:
            EmptyView()
        }
    }
}

// MARK: - NewCategorySheet

struct NewCategorySheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var selectedIcon = "folder.fill"

    private let icons = [
        "folder.fill", "star.fill", "heart.fill", "bookmark.fill",
        "tag.fill", "house.fill", "person.fill", "briefcase.fill",
        "graduationcap.fill", "car.fill", "airplane", "cross.fill",
        "dollarsign.circle.fill", "building.fill", "camera.fill", "music.note"
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(LanguageManager.shared.home("home_new_category"))
                    .shieldFont(18, weight: .bold)
                    .foregroundColor(ShieldTheme.primary(scheme))
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .shieldFont(14, weight: .medium)
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .frame(width: 30, height: 30)
                        .background(ShieldTheme.rowBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()

            VStack(spacing: 16) {
                TextField(LanguageManager.shared.home("home_category_name_placeholder"), text: $name)
                    .shieldFont(16)
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .padding(12)
                    .background(ShieldTheme.rowBackground(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ShieldTheme.line(scheme), lineWidth: 0.5))

                Text(LanguageManager.shared.home("home_icon_uppercase"))
                    .shieldFont(12, weight: .bold)
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .shieldFont(18)
                                .foregroundColor(selectedIcon == icon ? .black : ShieldTheme.primary(scheme))
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? ShieldTheme.accent : ShieldTheme.rowBackground(scheme))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }

                Button {
                    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    let cat = UserCategory(name: name.trimmingCharacters(in: .whitespaces), icon: selectedIcon)
                    appState.addCustomCategory(cat)
                    isPresented = false
                } label: {
                    Text(LanguageManager.shared.home("home_create_category"))
                        .shieldFont(16, weight: .bold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(name.isEmpty ? ShieldTheme.rowBackground(scheme) : ShieldTheme.accent)
                        .foregroundColor(name.isEmpty ? ShieldTheme.tertiary(scheme) : ShieldTheme.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(name.isEmpty)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(ShieldTheme.cardBackground(scheme).ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - VaultAutoLockOverlay

struct VaultAutoLockOverlay: View {
    @EnvironmentObject var appState: AppState
    let doc: DocumentItem
    let lang: AppLanguage
    let scheme: ColorScheme
    let onKeepEditing: () -> Void
    let onLockNow: () -> Void
    let onTimerExpired: () -> Void

    private static let countdownSeconds = 60

    @State private var remaining = VaultAutoLockOverlay.countdownSeconds
    @State private var timer: Timer? = nil

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .transition(.opacity)

            // Card
            VStack(spacing: 24) {
                // Icon
                MaskIDIdentityMark(
                    size: 80,
                    presentation: .animatedLoop,
                    treatment: .feature
                )

                VStack(spacing: 8) {
                    Text(LanguageManager.shared.home("home_vault_mode"))
                        .shieldFont(20, weight: .heavy)
                        .foregroundColor(ShieldTheme.primary(scheme))

                    Text(LanguageManager.shared.home("home_vault_auto_lock_msg"))
                        .shieldFont(14)
                        .foregroundColor(ShieldTheme.secondary(scheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Countdown ring
                ZStack {
                    Circle()
                        .stroke(ShieldTheme.rowBackground(scheme), lineWidth: 5)
                        .frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: CGFloat(remaining) / CGFloat(VaultAutoLockOverlay.countdownSeconds))
                        .stroke(ShieldTheme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: remaining)
                    Text("\(remaining)")
                        .shieldFont(28, weight: .bold, design: .monospaced)
                        .foregroundColor(ShieldTheme.primary(scheme))
                }

                // Actions
                VStack(spacing: 10) {
                    Button {
                        stopTimer()
                        onLockNow()
                    } label: {
                        Label(LanguageManager.shared.home("home_lock_now"), systemImage: "lock.fill")
                            .shieldFont(15, weight: .bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(ShieldTheme.accent)
                            .foregroundColor(ShieldTheme.accentText)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())

                    Button {
                        stopTimer()
                        onKeepEditing()
                    } label: {
                        Text(LanguageManager.shared.home("home_keep_editing"))
                            .shieldFont(15, weight: .semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(ShieldTheme.rowBackground(scheme))
                            .foregroundColor(ShieldTheme.primary(scheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(ShieldTheme.cardBackground(scheme))
                    .shadow(color: .black.opacity(0.4), radius: 24, y: 8)
            )
            .padding(.horizontal, 32)
        }
        .onAppear { startTimer() }
        .onDisappear { stopTimer() }
    }

    private func startTimer() {
        remaining = VaultAutoLockOverlay.countdownSeconds
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            DispatchQueue.main.async {
                if remaining > 0 {
                    remaining -= 1
                } else {
                    stopTimer()
                    onTimerExpired()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - BatchRedactView

struct BatchRedactView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @Environment(\.colorScheme) var scheme
    @Binding var isPresented: Bool

    @State private var selectedIDs: Set<String> = []
    @State private var selectedMode: RedactionMode = .rental
    @State private var isProcessing = false
    @State private var processed = 0
    @State private var failed = 0
    @State private var pagesWithSuggestions = 0
    @State private var pagesWithoutSuggestions = 0
    @State private var showDone = false
    @State private var pendingReviewDocumentID: String?

    private var selectableDocs: [DocumentItem] {
        appState.documents.filter { !$0.isVaulted }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showDone {
                    doneState
                } else {
                    form
                }
            }
            .navigationTitle(LanguageManager.shared.home("home_batch_pro"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LanguageManager.shared.capture("capture_cancel")) {
                        isPresented = false
                    }
                    .foregroundColor(ShieldTheme.accent)
                }
            }
        }
        .preferredColorScheme(appState.preferredScheme)
        .onAppear {
            let pendingDocuments = appState.documents.filter {
                !$0.isVaulted && !$0.batchReviewPendingPageIndices.isEmpty
            }
            if !pendingDocuments.isEmpty {
                selectedIDs = Set(pendingDocuments.map(\.id))
                processed = pendingDocuments.count
                pagesWithSuggestions = pendingDocuments.reduce(0) { $0 + $1.batchSuggestionPageIndices.count }
                pagesWithoutSuggestions = pendingDocuments.reduce(0) {
                    $0 + max(0, $1.pageCount - $1.batchSuggestionPageIndices.count)
                }
                showDone = true
                return
            }
#if DEBUG
            if ASOScreenshotMode.isEnabled {
                selectedIDs = Set(selectableDocs.prefix(3).map { $0.id })
            }
#endif
        }
        .onDisappear {
            guard let pendingReviewDocumentID else { return }
            Task { @MainActor in
                await Task.yield()
                guard let document = appState.documents.first(where: { $0.id == pendingReviewDocumentID }) else {
                    return
                }
                appState.selectedDoc = document
            }
        }
    }

    private var form: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Mode picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(LanguageManager.shared.home("home_batch_redaction_mode"))
                        .shieldFont(11, weight: .bold)
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .tracking(0.5)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(RedactionMode.allCases, id: \.self) { mode in
                            let isSelected = selectedMode == mode
                            let isLocked = mode.requiresPro && !pm.isPro
                            Button {
                                if isLocked {
                                    PremiumManager.recordFeatureGate(.professionalModes, trigger: .featureLocked)
                                } else {
                                    selectedMode = mode
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: isLocked ? "lock.fill" : mode.icon)
                                        .shieldFont(12, weight: .semibold)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(mode.label(lang: appState.language))
                                            .shieldFont(12, weight: .bold)
                                        Text(mode.subtitle(lang: appState.language))
                                            .shieldFont(10)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                }
                                .foregroundColor(isSelected ? .black : ShieldTheme.secondary(scheme))
                                .padding(10)
                                .background(isSelected ? mode.color : ShieldTheme.cardBackground(scheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? mode.color : ShieldTheme.line(scheme), lineWidth: isSelected ? 0 : 0.5)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }

                // Document picker
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(LanguageManager.shared.home("home_batch_documents_count", selectedIDs.count))
                            .shieldFont(11, weight: .bold)
                            .foregroundColor(ShieldTheme.tertiary(scheme))
                            .tracking(0.5)
                        Spacer()
                        Button {
                            if selectedIDs.count == selectableDocs.count {
                                selectedIDs = []
                            } else {
                                selectedIDs = Set(selectableDocs.map { $0.id })
                            }
                        } label: {
                            Text(selectedIDs.count == selectableDocs.count
                                 ? LanguageManager.shared.common("common_deselect_all")
                                 : LanguageManager.shared.common("common_select_all"))
                                .shieldFont(12, weight: .semibold)
                                .foregroundColor(ShieldTheme.accent)
                                .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                                .contentShape(Rectangle())
                        }
                    }

                    ForEach(selectableDocs) { doc in
                        let isSelected = selectedIDs.contains(doc.id)
                        Button {
                            if isSelected { selectedIDs.remove(doc.id) } else { selectedIDs.insert(doc.id) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .shieldFont(18, weight: .semibold)
                                    .foregroundColor(isSelected ? ShieldTheme.accent : ShieldTheme.tertiary(scheme))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(doc.title)
                                        .shieldFont(14, weight: .semibold)
                                        .foregroundColor(ShieldTheme.primary(scheme))
                                        .lineLimit(1)
                                    Text("\(doc.pageCount) \(LanguageManager.shared.common("common_pages_count")) · \(doc.dateLabelLocalized(lang: appState.language))")
                                        .shieldFont(11)
                                        .foregroundColor(ShieldTheme.tertiary(scheme))
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(isSelected ? ShieldTheme.accentDim : ShieldTheme.cardBackground(scheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? ShieldTheme.accent.opacity(0.6) : ShieldTheme.line(scheme), lineWidth: 0.5)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }

                // Apply button
                Button {
                    applyBatch()
                } label: {
                    HStack(spacing: 8) {
                        if isProcessing {
                            ProgressView().tint(.black).scaleEffect(0.9)
                            Text(LanguageManager.shared.home("home_batch_processing", processed, selectedIDs.count))
                                .shieldFont(15, weight: .bold)
                        } else {
                            Image(systemName: "square.stack.3d.up.fill")
                                .shieldFont(15, weight: .semibold)
                            Text(LanguageManager.shared.home("home_batch_apply_button", selectedIDs.count))
                                .shieldFont(15, weight: .bold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(selectedIDs.isEmpty ? ShieldTheme.rowBackground(scheme) : ShieldTheme.accent)
                    .foregroundColor(selectedIDs.isEmpty ? ShieldTheme.tertiary(scheme) : .black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(selectedIDs.isEmpty || isProcessing)

                Text(LanguageManager.shared.home("home_batch_description"))
                    .shieldFont(11)
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
    }

    private var doneState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(ShieldTheme.warning.opacity(0.16))
                    .frame(width: 90, height: 90)
                    Image(systemName: failed == 0 ? "doc.text.magnifyingglass" : "exclamationmark")
                    .shieldFont(44, weight: .semibold)
                    .foregroundColor(ShieldTheme.warning)
            }
            VStack(spacing: 6) {
                Text(LanguageManager.shared.home(failed == 0 ? "home_batch_complete_title" : "home_batch_partial_title"))
                    .shieldFont(22, weight: .bold)
                    .foregroundColor(ShieldTheme.primary(scheme))
                Text(LanguageManager.shared.home("home_batch_complete_desc", processed))
                    .shieldFont(14)
                    .foregroundColor(ShieldTheme.secondary(scheme))
                    .multilineTextAlignment(.center)
                if failed > 0 {
                    Text(LanguageManager.shared.home("home_batch_failed_count", failed))
                        .shieldFont(13, weight: .semibold)
                        .foregroundColor(ShieldTheme.danger)
                        .multilineTextAlignment(.center)
                }
            }
            Text(LanguageManager.shared.home(
                "home_batch_page_summary",
                pagesWithSuggestions,
                pagesWithoutSuggestions
            ))
            .shieldFont(12, weight: .medium)
            .foregroundColor(ShieldTheme.secondary(scheme))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)

            reviewQueue

            Spacer()
            Button {
                selectedIDs = []
                processed = 0
                failed = 0
                pagesWithSuggestions = 0
                pagesWithoutSuggestions = 0
                withAnimation { showDone = false }
            } label: {
                Text(LanguageManager.shared.home("home_batch_new"))
                    .shieldFont(15, weight: .semibold)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .foregroundColor(ShieldTheme.accent)
            }
            .buttonStyle(.plain)
            Button { isPresented = false } label: {
                Text(LanguageManager.shared.common("common_done"))
                    .shieldFont(16, weight: .bold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(ShieldTheme.accent)
                    .foregroundColor(ShieldTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: ShieldTheme.rMD))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private var reviewQueue: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(LanguageManager.shared.home("home_batch_review_queue_title"))
                    .shieldFont(12, weight: .bold)
                    .foregroundColor(ShieldTheme.secondary(scheme))
                ForEach(appState.documents.filter {
                    !$0.isVaulted && !$0.batchReviewPendingPageIndices.isEmpty
                }) { document in
                        let documentID = document.id
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(document.title)
                                    .shieldFont(13, weight: .semibold)
                                    .foregroundColor(ShieldTheme.primary(scheme))
                                    .lineLimit(1)
                                Text(LanguageManager.shared.home(
                                    "home_batch_pages_pending",
                                    document.batchReviewPendingPageIndices.count
                                ))
                                    .shieldFont(11)
                                    .foregroundColor(ShieldTheme.warning)
                            }
                            Spacer(minLength: 4)
                            Button {
                                pendingReviewDocumentID = documentID
                                isPresented = false
                            } label: {
                                Text(LanguageManager.shared.home("home_batch_review_open"))
                                    .shieldFont(11, weight: .semibold)
                                    .frame(minHeight: 44)
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(ShieldTheme.accent)
                            .accessibilityIdentifier("home.batch.reviewDocument.\(documentID)")
                        }
                        .padding(.horizontal, 12)
                        .background(ShieldTheme.cardBackground(scheme), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .frame(maxHeight: 220)
        .accessibilityIdentifier("home.batch.reviewQueue")
    }

    private func applyBatch() {
        guard pm.isPro else {
            PremiumManager.recordFeatureGate(.batchProcessing, trigger: .settingsUpgrade)
            isPresented = false
            return
        }
        guard !selectedIDs.isEmpty else { return }
        isProcessing = true
        processed = 0
        failed = 0
        pagesWithSuggestions = 0
        pagesWithoutSuggestions = 0

        Task {
            for docID in selectedIDs.sorted() {
                guard var doc = appState.documents.first(where: { $0.id == docID }) else {
                    await MainActor.run { failed += 1 }
                    continue
                }

                let plan = BatchRedactionPlanner.plan(for: doc, mode: selectedMode)
                for page in plan.pageRedactions {
                    doc.setRedactions(page.redactions, for: page.pageIndex)
                }
                doc.batchReviewPendingPageIndices = Array(0..<max(doc.pageCount, 1))
                doc.batchSuggestionPageIndices = plan.pageRedactions.map(\.pageIndex).sorted()
                await MainActor.run {
                    let saved = appState.updateDocument(doc)
                    if saved {
                        processed += 1
                        pagesWithSuggestions += plan.pagesWithSuggestions
                        pagesWithoutSuggestions += plan.pagesWithoutSuggestions
                    } else {
                        failed += 1
                    }
                }
            }

            AppState.trackEvent("batch_applied", properties: [
                "mode": selectedMode.rawValue,
                "docs": String(processed),
                "failed": String(failed)
            ])

            await MainActor.run {
                isProcessing = false
                withAnimation { showDone = true }
            }
        }
    }
}
