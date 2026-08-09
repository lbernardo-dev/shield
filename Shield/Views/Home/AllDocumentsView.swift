import SwiftUI

struct AllDocumentsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ShieldTheme.background(appState.preferredScheme).ignoresSafeArea()

                Group {
                    if appState.filteredDocuments.isEmpty {
                        ShieldStateView(
                            kind: .empty,
                            title: appState.hasActiveFilter
                                ? LanguageManager.shared.home("home_no_results")
                                : LanguageManager.shared.home("home_no_documents"),
                            message: appState.hasActiveFilter
                                ? LanguageManager.shared.home("home_no_results_subtitle")
                                : LanguageManager.shared.home("home_no_documents_subtitle"),
                            actionLabel: appState.hasActiveFilter
                                ? LanguageManager.shared.home("home_clear_filters")
                                : nil
                        ) {
                            if appState.hasActiveFilter {
                                withAnimation(ShieldMotion.state) {
                                    appState.activeCategoryID = DocumentCategory.all.rawValue
                                    appState.searchQuery = ""
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 8) {
                                ForEach(appState.filteredDocuments) { doc in
                                    DocumentRow(doc: doc, lang: appState.language) {
                                        guard !doc.isLocked else { return }
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
            .navigationTitle(LanguageManager.shared.home("home_all_documents"))
            .navigationBarTitleDisplayMode(.large)
            .colorScheme(appState.preferredScheme)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LanguageManager.shared.common("common_close")) { dismiss() }
                        .foregroundColor(ShieldTheme.accent)
                }
            }
        }
    }
}
