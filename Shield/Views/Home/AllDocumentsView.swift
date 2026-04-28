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
                            Text(appState.language == .es ? "Sin documentos" : "No documents")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(ShieldTheme.secondary(appState.preferredScheme))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 8) {
                                ForEach(appState.documents.sorted { $0.date > $1.date }) { doc in
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
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle(appState.language == .es ? "Todos los documentos" : "All documents")
            .navigationBarTitleDisplayMode(.large)
            .colorScheme(appState.preferredScheme)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(appState.language == .es ? "Cerrar" : "Close") { dismiss() }
                        .foregroundColor(ShieldTheme.accent)
                }
            }
        }
    }
}
