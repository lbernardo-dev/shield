import SwiftUI

struct AllDocumentsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var metric: HomeLibraryMetric

    init(metric: HomeLibraryMetric = .documents) {
        _metric = State(initialValue: metric)
    }

    private var visibleDocuments: [DocumentItem] {
        appState.filteredDocuments.filter(metric.includes)
    }

    private var hasActiveFilter: Bool {
        appState.hasActiveFilter || metric != .documents
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SeasonalThemeBackdrop()

                Group {
                    if visibleDocuments.isEmpty {
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
                                : nil
                        ) {
                            if hasActiveFilter {
                                withAnimation(ShieldMotion.state) {
                                    appState.activeCategoryID = DocumentCategory.all.rawValue
                                    appState.searchQuery = ""
                                    metric = .documents
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 8) {
                                ForEach(visibleDocuments) { doc in
                                    DocumentRow(doc: doc, lang: appState.language) {
                                        guard !doc.isLocked else { return }
                                        appState.prepareSearchNavigation(to: doc)
                                        appState.selectedDoc = doc
                                        dismiss()
                                    }
                                    .contextMenu {
                                        Button {
                                            appState.toggleFavorite(doc)
                                        } label: {
                                            Label(doc.isFavorite
                                                  ? LanguageManager.shared.home("home_remove_favorite")
                                                  : LanguageManager.shared.home("home_mark_favorite"),
                                                  systemImage: doc.isFavorite ? "star.slash" : "star.fill")
                                        }
                                        Button {
                                            appState.toggleVault(doc)
                                        } label: {
                                            Label(doc.isVaulted
                                                  ? LanguageManager.shared.vault("vault_move_out")
                                                  : LanguageManager.shared.vault("vault_move_to_vault"),
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
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle(metric == .documents
                ? LanguageManager.shared.home("home_all_documents")
                : LanguageManager.shared.home(metric.localizationKey))
            .navigationBarTitleDisplayMode(.large)
            .colorScheme(appState.preferredScheme)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageManager.shared.common("common_close")) { dismiss() }
                        .font(.body.weight(.semibold))
                        .foregroundColor(ShieldTheme.accent(appState.preferredScheme))
                }
            }
            .searchable(
                text: $appState.searchQuery,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: Text(LanguageManager.shared.home("home_search_content_hint"))
            )
            .onAppear {
                appState.prepareLocalSearchIndexIfNeeded()
            }
            .onChange(of: appState.searchQuery) { _, _ in
                appState.prepareLocalSearchIndexIfNeeded()
            }
        }
    }
}
