import SwiftUI
import LocalAuthentication

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var pm = PremiumManager.shared
    @ObservedObject private var cloud = CloudSyncManager.shared
    @ObservedObject private var directCloud = DirectCloudStorageManager.shared
    @Environment(\.colorScheme) var scheme

    @State private var showAllDocs = false
    @State private var showFilters = false
    @State private var showPaywall = false
    @State private var showCloudImport = false
    @State private var requestedCloudProvider: ExternalStorageProvider?
    @State private var showBatchRedact = false
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
            ShieldTheme.background(appState.preferredScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBarSection

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        heroSection
                        searchSection
                        categoryScroll
                        Divider()
                            .background(ShieldTheme.line(appState.preferredScheme))
                            .padding(.horizontal, ShieldTheme.s5)
                            .padding(.top, 4)
                        modesSection
                        Divider()
                            .background(ShieldTheme.line(appState.preferredScheme))
                            .padding(.horizontal, ShieldTheme.s5)
                            .padding(.top, 8)
                        recentsSection
                        vaultSection
                        cloudStorageSection
                            .padding(.bottom, 110)
                    }
                    .frame(maxWidth: 1_100)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .colorScheme(appState.preferredScheme)
        .sheet(isPresented: $showAllDocs) {
            AllDocumentsView().environmentObject(appState)
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
                appState.showCapture = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("shield.importFileURL"),
                        object: url
                    )
                }
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
    }

    // MARK: - Top Bar

    private var topBarSection: some View {
        HomeTopBarView(
            scheme: appState.preferredScheme,
            language: appState.language,
            onToggleLanguage: toggleLanguage,
            onToggleScheme: toggleColorScheme,
            onOpenSettings: openSettings
        )
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.top, 2)
        .padding(.bottom, 10)
        .background(
            ShieldTheme.background(appState.preferredScheme)
                .ignoresSafeArea(edges: .top)
        )
        .overlay(alignment: .bottom) {
            ShieldTheme.line(appState.preferredScheme)
                .frame(height: 0.5)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        HomeHeroCardView(
            scheme: appState.preferredScheme,
            language: appState.language,
            documentCount: appState.documents.count,
            isPro: pm.isPro,
            freeUsed: appState.documents.count,
            freeLimit: PremiumManager.freeDocumentLimit,
            onUpgrade: { showPaywall = true },
            onPrimaryAction: { appState.showCapture = true },
            onSecondaryAction: handleCloudImportTap
        )
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.top, 12)
        .padding(.bottom, 14)
    }

    // MARK: - Search

    private var searchSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(searchFocused
                    ? ShieldTheme.accent
                    : ShieldTheme.tertiary(appState.preferredScheme))

            TextField(LanguageManager.shared.home("home_search"), text: $appState.searchQuery)
                .font(.system(size: 15))
                .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                .focused($searchFocused)
                .submitLabel(.search)

            if !appState.searchQuery.isEmpty {
                Button {
                    appState.searchQuery = ""
                    searchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                }
            }

            Button {
                showFilters = true
            } label: {
                Image(systemName: appState.hasActiveFilter ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(appState.hasActiveFilter ? ShieldTheme.accent : ShieldTheme.tertiary(appState.preferredScheme))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(ShieldTheme.cardBackground(appState.preferredScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    searchFocused ? ShieldTheme.accent.opacity(0.6) : ShieldTheme.line(appState.preferredScheme),
                    lineWidth: searchFocused ? 1.5 : 0.5
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .animation(.easeInOut(duration: 0.15), value: searchFocused)
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.bottom, 16)
    }

    // MARK: - Categories

    @State private var showNewCategory = false

    private var categoryScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(DocumentCategory.allCases) { cat in
                    PillButton(
                        label: cat.label(lang: appState.language),
                        icon: cat.icon,
                        isActive: appState.activeCategoryID == cat.rawValue
                    ) {
                        withAnimation { appState.activeCategoryID = cat.rawValue }
                    }
                }
                ForEach(appState.customCategories) { cat in
                    PillButton(
                        label: cat.name,
                        icon: cat.icon,
                        isActive: appState.activeCategoryID == cat.id
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
                        Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
                        Text(LanguageManager.shared.common("common_new")).font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(ShieldTheme.accent)
                    .padding(.horizontal, 10)
                    .frame(height: 28)
                    .background(ShieldTheme.accentDim)
                    .overlay(Capsule().stroke(ShieldTheme.accent.opacity(0.4), lineWidth: 0.5))
                    .clipShape(Capsule())
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal, ShieldTheme.s5)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $showNewCategory) {
            NewCategorySheet(isPresented: $showNewCategory)
                .environmentObject(appState)
        }
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

    // MARK: - Recents

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: LanguageManager.shared.home("home_recent_documents"),
                action: { showAllDocs = true },
                actionLabel: LanguageManager.shared.home("home_see_all")
            )

            if appState.filteredDocuments.isEmpty {
                emptyLibraryState
            } else {
                VStack(spacing: 10) {
                    ForEach(appState.filteredDocumentsPage) { doc in
                        DocumentRow(doc: doc, lang: appState.language) {
                            guard !doc.isLocked else { return }
                            if doc.isVaulted {
                                vaultAuthDoc = doc
                                authenticateForVaultDoc(doc)
                            } else {
                                appState.selectedDoc = doc
                            }
                        }
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
                }
                .padding(.horizontal, ShieldTheme.s4)

                // Pagination controls
                if appState.recentDocsTotalPages > 1 {
                    paginationControls
                }
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
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
        .padding(.horizontal, ShieldTheme.s4)
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
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                .padding(.top, 32)
            Text(LanguageManager.shared.home("home_no_documents"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ShieldTheme.secondary(appState.preferredScheme))
            Text(LanguageManager.shared.home("home_no_documents_subtitle"))
                .font(.system(size: 14))
                .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer().frame(height: 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.bottom, 90)
    }

    // MARK: - Cloud Storage

    private var cloudStorageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: LanguageManager.shared.home("home_cloud_storage"),
                action: pm.isPro ? nil : { showPaywall = true },
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
                        if !pm.isPro { showPaywall = true; return }
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
                            if !pm.isPro { showPaywall = true; return }
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
                    Image(systemName: "crown.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ShieldTheme.accent)
                    Text(LanguageManager.shared.home("home_connect_cloud_description"))
                        .font(.system(size: 12))
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .opacity(pm.isPro ? 1 : 0.45)

                // Name + status
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                        if !pm.isPro {
                            Text(LanguageManager.shared.common("common_pro"))
                                .font(.system(size: 9, weight: .bold))
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
                            .font(.system(size: 12))
                            .foregroundColor(pm.isPro ? statusColor : ShieldTheme.tertiary(appState.preferredScheme))
                    }
                }

                Spacer()

                // Action indicator
                if !pm.isPro {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ShieldTheme.accent)
                } else if isAuthenticating {
                    ProgressView().scaleEffect(0.7).tint(ShieldTheme.accent)
                } else {
                    Image(systemName: (isConnected || showsDisclosureIndicator) ? "chevron.right" : "plus.circle.fill")
                        .font(.system(size: 14, weight: isConnected ? .medium : .semibold))
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
        withAnimation {
            appState.preferredScheme = appState.preferredScheme == .dark ? .light : .dark
        }
    }

    private func openSettings() {
        withAnimation {
            appState.activeTab = .settings
        }
    }

    private func handleCloudImportTap() {
        if pm.isPro {
            showCloudImport = true
        } else {
            showPaywall = true
        }
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
                    .font(.system(size: 18, weight: .bold))
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
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(ShieldTheme.accent)
                    }
                }
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ShieldTheme.tertiary(effectiveScheme))
                        .frame(width: 28, height: 28)
                        .background(ShieldTheme.rowBackground(effectiveScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
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
                            .font(.system(size: 11, weight: .semibold))
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
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(ShieldTheme.tertiary(effectiveScheme))
                            .tracking(0.6)

                        VStack(spacing: 0) {
                            ForEach(SortOption.allCases) { option in
                                HStack {
                                    Image(systemName: option.icon)
                                        .font(.system(size: 14))
                                        .foregroundColor(appState.sortOption == option ? ShieldTheme.accent : ShieldTheme.secondary(effectiveScheme))
                                        .frame(width: 20)
                                    Text(option.label(lang: appState.language))
                                        .font(.system(size: 15))
                                        .foregroundColor(ShieldTheme.primary(effectiveScheme))
                                    Spacer()
                                    if appState.sortOption == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .semibold))
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
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(ShieldTheme.line(effectiveScheme), lineWidth: 0.5))
                    }
                }
                .padding(ShieldTheme.s5)
            }

            // Apply
            Button {
                isPresented = false
            } label: {
                Text(LanguageManager.shared.home("home_apply_filters"))
                    .font(.system(size: 16, weight: .bold))
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
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
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
    var action: (() -> Void)? = nil
    @Environment(\.colorScheme) var scheme

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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(mode.color)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.label(lang: lang))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(ShieldTheme.primary(scheme))
                    Text(mode.subtitle(lang: lang))
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minWidth: 168, alignment: .leading)
            .background(ShieldTheme.cardBackground(scheme))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ShieldTheme.line(scheme), lineWidth: 0.5)
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

    private var shouldMask: Bool { doc.isVaulted && !vaultUnlocked }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack {
                    DocumentView(kind: doc.kind, size: CGSize(width: 64, height: 44),
                                 fields: doc.fields, imageFileName: doc.imageFileName, isVaulted: doc.isVaulted,
                                 imageAdjustment: doc.imageAdjustment)
                        .frame(width: 64, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .blur(radius: shouldMask ? 4 : 0)

                    if doc.isLocked {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.7))
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 64, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        if shouldMask {
                            Text(LanguageManager.shared.home("home_protected_document"))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                                .lineLimit(1)
                                .redacted(reason: .placeholder)
                        } else {
                            Text(doc.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                                .lineLimit(1)
                            if doc.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(ShieldTheme.accent)
                            }
                        }
                    }
                    HStack(spacing: 6) {
                        if shouldMask {
                            Text("••••••")
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(ShieldTheme.accentDim)
                                .foregroundColor(ShieldTheme.accent)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            Text("·")
                                .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                                .font(.system(size: 12))
                            Text(doc.dateLabelLocalized(lang: lang))
                                .font(.system(size: 12))
                                .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                        } else {
                            Text(doc.category.label(lang: lang))
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(ShieldTheme.rowBackground(appState.preferredScheme))
                                .foregroundColor(ShieldTheme.secondary(appState.preferredScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 5))

                            Text("·")
                                .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                                .font(.system(size: 12))

                            Text(doc.dateLabelLocalized(lang: lang))
                                .font(.system(size: 12))
                                .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))

                            if doc.redactionCount > 0 {
                                Text("·")
                                    .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                                    .font(.system(size: 12))
                                Text(appState.redactionsCount(doc.redactionCount))
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(ShieldTheme.accent)
                            }
                        }
                    }
                }

                Spacer()

                // Vault badge or chevron
                if doc.isVaulted {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ShieldTheme.accent)
                        .accessibilityHidden(true)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                        .accessibilityHidden(true)
                }
            }
            .padding(12)
            .background(ShieldTheme.cardBackground(appState.preferredScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(doc.isVaulted
                        ? ShieldTheme.accent.opacity(0.35)
                        : ShieldTheme.line(appState.preferredScheme),
                            lineWidth: doc.isVaulted ? 1 : 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .trailing) {
                if doc.isVaulted {
                    LinearGradient(
                        colors: [Color.clear, ShieldTheme.accent.opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .allowsHitTesting(false)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(doc.isLocked)
        .opacity(doc.isLocked ? 0.7 : 1)
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
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ShieldTheme.primary(scheme))
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .frame(width: 30, height: 30)
                        .background(ShieldTheme.rowBackground(scheme))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()

            VStack(spacing: 16) {
                TextField(LanguageManager.shared.home("home_category_name_placeholder"), text: $name)
                    .font(.system(size: 16))
                    .foregroundColor(ShieldTheme.primary(scheme))
                    .padding(12)
                    .background(ShieldTheme.rowBackground(scheme))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ShieldTheme.line(scheme), lineWidth: 0.5))

                Text(LanguageManager.shared.home("home_icon_uppercase"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ShieldTheme.tertiary(scheme))
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 18))
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
                        .font(.system(size: 16, weight: .bold))
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
                ZStack {
                    Circle()
                        .fill(ShieldTheme.accentDim)
                        .frame(width: 72, height: 72)
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(ShieldTheme.accent)
                        .accessibilityHidden(true)
                }

                VStack(spacing: 8) {
                    Text(LanguageManager.shared.home("home_vault_mode"))
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(ShieldTheme.primary(scheme))
                        .tracking(-0.4)

                    Text(LanguageManager.shared.home("home_vault_auto_lock_msg"))
                        .font(.system(size: 14))
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
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(ShieldTheme.primary(scheme))
                }

                // Actions
                VStack(spacing: 10) {
                    Button {
                        stopTimer()
                        onLockNow()
                    } label: {
                        Label(LanguageManager.shared.home("home_lock_now"), systemImage: "lock.fill")
                            .font(.system(size: 15, weight: .bold))
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
                            .font(.system(size: 15, weight: .semibold))
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
    @State private var showDone = false

    private var selectableDocs: [DocumentItem] {
        appState.documents.filter { !$0.isVaulted }
    }

    var body: some View {
        NavigationView {
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
    }

    private var form: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Mode picker
                VStack(alignment: .leading, spacing: 8) {
                    Text(LanguageManager.shared.home("home_batch_redaction_mode"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ShieldTheme.tertiary(scheme))
                        .tracking(0.5)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(RedactionMode.allCases, id: \.self) { mode in
                            let isSelected = selectedMode == mode
                            Button { selectedMode = mode } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 12, weight: .semibold))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(mode.label(lang: appState.language))
                                            .font(.system(size: 12, weight: .bold))
                                        Text(mode.subtitle(lang: appState.language))
                                            .font(.system(size: 10))
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
                            .font(.system(size: 11, weight: .bold))
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
                                .font(.system(size: 12, weight: .semibold))
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
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(isSelected ? ShieldTheme.accent : ShieldTheme.tertiary(scheme))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(doc.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(ShieldTheme.primary(scheme))
                                        .lineLimit(1)
                                    Text("\(doc.pageCount) \(LanguageManager.shared.common("common_pages_count")) · \(doc.dateLabelLocalized(lang: appState.language))")
                                        .font(.system(size: 11))
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
                                .font(.system(size: 15, weight: .bold))
                        } else {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text(LanguageManager.shared.home("home_batch_apply_button", selectedIDs.count))
                                .font(.system(size: 15, weight: .bold))
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
                    .font(.system(size: 11))
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
                    .fill(ShieldTheme.successDim)
                    .frame(width: 90, height: 90)
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(ShieldTheme.success)
            }
            VStack(spacing: 6) {
                Text(LanguageManager.shared.home("home_batch_complete_title"))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(ShieldTheme.primary(scheme))
                Text(LanguageManager.shared.home("home_batch_complete_desc", selectedMode.label(lang: appState.language), processed))
                    .font(.system(size: 14))
                    .foregroundColor(ShieldTheme.secondary(scheme))
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Button { isPresented = false } label: {
                Text(LanguageManager.shared.common("common_done"))
                    .font(.system(size: 16, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(ShieldTheme.accent)
                    .foregroundColor(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    private func applyBatch() {
        guard !selectedIDs.isEmpty else { return }
        isProcessing = true
        processed = 0

        Task {
            for docID in selectedIDs {
                guard var doc = appState.documents.first(where: { $0.id == docID }) else { continue }
                let suggested = AutoRedactions.suggested(for: doc.kind, style: .block)
                let modeRects = AutoRedactions.ocrModeRects(for: selectedMode, fields: doc.fields)
                let toAdd: [Redaction] = suggested.isEmpty
                    ? modeRects.map { Redaction(rect: $0, style: .block) }
                    : suggested

                for pageIdx in 0..<max(doc.pageCount, 1) {
                    var existing = doc.redactions(for: pageIdx)
                    let newOnes = toAdd.filter { r in
                        !existing.contains(where: {
                            abs($0.rect.origin.x - r.rect.origin.x) < 0.01 &&
                            abs($0.rect.origin.y - r.rect.origin.y) < 0.01
                        })
                    }.map { Redaction(rect: $0.rect, style: $0.style) }
                    existing.append(contentsOf: newOnes)
                    doc.setRedactions(existing, for: pageIdx)
                }

                await MainActor.run {
                    appState.updateDocument(doc)
                    processed += 1
                }
            }

            AppState.trackEvent("batch_applied", properties: [
                "mode": selectedMode.rawValue,
                "docs": String(selectedIDs.count)
            ])

            await MainActor.run {
                isProcessing = false
                withAnimation { showDone = true }
            }
        }
    }
}
