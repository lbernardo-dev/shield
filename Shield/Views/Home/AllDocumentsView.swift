import SwiftUI

struct AllDocumentsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ShieldTheme.background(appState.preferredScheme).ignoresSafeArea()

                Group {
                    if appState.documents.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 44, weight: .light))
                                .foregroundColor(ShieldTheme.tertiary(appState.preferredScheme))
                            Text(LanguageManager.shared.home("home_no_documents"))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(ShieldTheme.secondary(appState.preferredScheme))
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
