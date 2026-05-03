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
                            Text(appState.str("home_no_documents", table: "Home"))
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
                                                  ? appState.str("home_remove_favorite", table: "Home")
                                                  : appState.str("home_mark_favorite", table: "Home"),
                                                  systemImage: doc.isFavorite ? "star.slash" : "star.fill")
                                        }
                                        Button {
                                            appState.toggleVault(doc)
                                        } label: {
                                            Label(doc.isVaulted
                                                  ? appState.str("vault_move_out", table: "Vault")
                                                  : appState.str("vault_move_to_vault", table: "Vault"),
                                                  systemImage: doc.isVaulted ? "lock.open" : "lock.fill")
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            appState.deleteDocument(doc)
                                        } label: {
                                            Label(appState.str("common_delete", table: "Common"), systemImage: "trash")
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
            .navigationTitle(appState.str("home_all_documents", table: "Home"))
            .navigationBarTitleDisplayMode(.large)
            .colorScheme(appState.preferredScheme)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(appState.str("common_close", table: "Common")) { dismiss() }
                        .foregroundColor(ShieldTheme.accent)
                }
            }
        }
    }
}
