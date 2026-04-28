import SwiftUI

// MARK: - HomeView

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var scheme

    @State private var showAllDocs = false
    @State private var showFilters = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        ZStack(alignment: .top) {
            ShieldTheme.background(appState.preferredScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Sticky header — never scrolls
                stickyHeader

                // Scrollable content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        titleSection
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
                            .padding(.bottom, 110)
                    }
                }
            }
        }
        .colorScheme(appState.preferredScheme)
        .sheet(isPresented: $showAllDocs) {
            AllDocumentsView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showFilters) {
            FilterSheet(isPresented: $showFilters)
                .environmentObject(appState)
        }
    }

    // MARK: - Sticky Header (brand bar)

    private var stickyHeader: some View {
        HStack {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ShieldTheme.accentColor(appState.preferredScheme))
                        .frame(width: 28, height: 28)
                    Image(systemName: "shield.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(appState.preferredScheme == .dark ? ShieldTheme.accentText : ShieldTheme.accent)
                }
                Text(appState.str(.appName))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                    .tracking(-0.3)
            }
            Spacer()
            HStack(spacing: 8) {
                Button {
                    withAnimation { appState.language = appState.language == .es ? .en : .es }
                } label: {
                    Text(appState.language.displayName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                        .frame(width: 32, height: 32)
                        .background(ShieldTheme.cardBackground(appState.preferredScheme))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ShieldTheme.line(appState.preferredScheme), lineWidth: 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                Button {
                    withAnimation { appState.preferredScheme = appState.preferredScheme == .dark ? .light : .dark }
                } label: {
                    Image(systemName: appState.preferredScheme == .dark ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                        .frame(width: 32, height: 32)
                        .background(ShieldTheme.cardBackground(appState.preferredScheme))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(ShieldTheme.line(appState.preferredScheme), lineWidth: 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                IconButton(
                    icon: "gearshape",
                    size: 32,
                    color: ShieldTheme.primary(appState.preferredScheme),
                    background: ShieldTheme.cardBackground(appState.preferredScheme)
                ) {
                    withAnimation { appState.activeTab = .settings }
                }
            }
        }
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.top, 8)
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

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(appState.str(.documents))
                .font(.system(size: 34, weight: .heavy))
                .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                .tracking(-0.7)

            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(ShieldTheme.success)
                Text(appState.str(.onDevice))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(ShieldTheme.success)
                Text("· \(appState.documents.count) \(appState.str(.documents).lowercased())")
                    .font(.system(size: 13))
                    .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, ShieldTheme.s5)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Search

    private var searchSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(searchFocused
                    ? ShieldTheme.accent
                    : ShieldTheme.tertiary(appState.preferredScheme))

            TextField(appState.str(.search), text: $appState.searchQuery)
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
                            Label(appState.language == .es ? "Eliminar categoría" : "Delete category", systemImage: "trash")
                        }
                    }
                }
                Button {
                    showNewCategory = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
                        Text(appState.language == .es ? "Nueva" : "New").font(.system(size: 12, weight: .semibold))
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
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: appState.language == .es ? "Modos rápidos" : "Quick modes")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(RedactionMode.allCases) { mode in
                        ModeCard(mode: mode, lang: appState.language) {
                            appState.showCapture = true
                        }
                    }
                }
                .padding(.horizontal, ShieldTheme.s5)
                .padding(.bottom, 4)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Recents

    private var recentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: appState.str(.recents),
                action: { showAllDocs = true },
                actionLabel: appState.language == .es ? "Ver todo" : "See all"
            )

            if appState.filteredDocuments.isEmpty {
                emptyLibraryState
            } else {
                VStack(spacing: 10) {
                    ForEach(appState.filteredDocuments) { doc in
                        DocumentRow(doc: doc, lang: appState.language) {
                            guard !doc.isLocked else { return }
                            appState.selectedDoc = doc
                        }
                        .contextMenu {
                            Button {
                                appState.toggleFavorite(doc)
                            } label: {
                                Label(doc.isFavorite
                                      ? (appState.language == .es ? "Quitar favorito" : "Remove favorite")
                                      : (appState.language == .es ? "Marcar favorito" : "Mark favorite"),
                                      systemImage: doc.isFavorite ? "star.slash" : "star.fill")
                            }
                            Button {
                                appState.toggleVault(doc)
                            } label: {
                                Label(doc.isVaulted
                                      ? (appState.language == .es ? "Sacar de bóveda" : "Remove from vault")
                                      : (appState.language == .es ? "Mover a bóveda" : "Move to vault"),
                                      systemImage: doc.isVaulted ? "lock.open" : "lock.fill")
                            }
                            Divider()
                            Button(role: .destructive) {
                                appState.deleteDocument(doc)
                            } label: {
                                Label(appState.language == .es ? "Eliminar" : "Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, ShieldTheme.s4)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    private var emptyLibraryState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                .padding(.top, 32)
            Text(appState.language == .es ? "Sin documentos" : "No documents")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(ShieldTheme.secondary(appState.preferredScheme))
            Text(appState.language == .es
                 ? "Escanea o importa tu primer documento para empezar."
                 : "Scan or import your first document to get started.")
                .font(.system(size: 14))
                .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer().frame(height: 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, ShieldTheme.s4)
    }

    // MARK: - Vault

    private var vaultSection: some View {
        Button {
            withAnimation { appState.activeTab = .vault }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(ShieldTheme.accentDim)
                        .frame(width: 44, height: 44)
                    Image(systemName: "lock.rectangle.stack.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(ShieldTheme.accent)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(appState.str(.vault))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(ShieldTheme.primary(appState.preferredScheme))
                    Text(appState.language == .es ? "Almacenamiento seguro · Face ID" : "Secure storage · Face ID")
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
            }
            .padding(16)
            .background(ShieldTheme.cardBackground(appState.preferredScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ShieldTheme.line(appState.preferredScheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, ShieldTheme.s4)
        .padding(.top, 24)
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
                Text(appState.language == .es ? "Filtros" : "Filters")
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
                        Text(appState.language == .es ? "Limpiar" : "Clear")
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
                        Text(appState.language == .es ? "CATEGORÍA" : "CATEGORY")
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
                        Text(appState.language == .es ? "ORDENAR POR" : "SORT BY")
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
                Text(appState.language == .es ? "Aplicar filtros" : "Apply filters")
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
    let action: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    DocumentView(kind: doc.kind, size: CGSize(width: 64, height: 44),
                                 fields: doc.fields, imageFileName: doc.imageFileName, isVaulted: doc.isVaulted)
                        .frame(width: 64, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    if doc.isLocked {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.7))
                            .blur(radius: 6)
                        Image(systemName: "lock.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 64, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
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
                    HStack(spacing: 6) {
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
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
            }
            .padding(12)
            .background(ShieldTheme.cardBackground(appState.preferredScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ShieldTheme.line(appState.preferredScheme), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(doc.isLocked)
        .opacity(doc.isLocked ? 0.7 : 1)
    }
}

// MARK: - NewCategorySheet

struct NewCategorySheet: View {
    @EnvironmentObject var appState: AppState
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
                Text(appState.language == .es ? "Nueva categoría" : "New category")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 30, height: 30)
                        .background(ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()

            VStack(spacing: 16) {
                TextField(appState.language == .es ? "Nombre de categoría" : "Category name", text: $name)
                    .font(.system(size: 16))
                    .foregroundColor(ShieldTheme.textPrimary)
                    .padding(12)
                    .background(ShieldTheme.surface3)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(ShieldTheme.surfaceLine, lineWidth: 0.5))

                Text(appState.language == .es ? "Ícono" : "Icon")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(ShieldTheme.textTertiary)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                    ForEach(icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                        } label: {
                            Image(systemName: icon)
                                .font(.system(size: 18))
                                .foregroundColor(selectedIcon == icon ? .black : ShieldTheme.textPrimary)
                                .frame(width: 40, height: 40)
                                .background(selectedIcon == icon ? ShieldTheme.accent : ShieldTheme.surface3)
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
                    Text(appState.language == .es ? "Crear categoría" : "Create category")
                        .font(.system(size: 16, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(name.isEmpty ? ShieldTheme.surface3 : ShieldTheme.accent)
                        .foregroundColor(name.isEmpty ? ShieldTheme.textTertiary : ShieldTheme.accentText)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(name.isEmpty)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(ShieldTheme.surface2.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
