import SwiftUI
import UniformTypeIdentifiers

// MARK: - ExternalStorageProvider

enum ExternalStorageProvider: String, CaseIterable, Identifiable {
    case googleDrive
    case dropbox
    case oneDrive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .googleDrive: return "Google Drive"
        case .dropbox:     return "Dropbox"
        case .oneDrive:    return "OneDrive"
        }
    }

    var icon: String {
        switch self {
        case .googleDrive: return "g.circle.fill"
        case .dropbox:     return "shippingbox.fill"
        case .oneDrive:    return "cloud.fill"
        }
    }

    var iconColor: String {
        switch self {
        case .googleDrive: return "4285F4"
        case .dropbox:     return "0061FF"
        case .oneDrive:    return "0078D4"
        }
    }

}

// MARK: - ExternalStoragePickerView
// Direct providers authenticate with OAuth 2.0 + PKCE and browse their remote
// APIs. Files remains a separate system File Provider integration.

struct ExternalStoragePickerSheet: View {
    @StateObject private var pm = PremiumManager.shared
    @ObservedObject private var cloudStorage = DirectCloudStorageManager.shared
    @Binding var isPresented: Bool
    var initialProvider: ExternalStorageProvider? = nil
    var onImport: (URL) -> Void

    @State private var showDocPicker = false
    @State private var showPaywall = false
    @State private var selectedProvider: ExternalStorageProvider?

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .frame(width: 36, height: 4)
                .foregroundColor(ShieldTheme.textTertiary.opacity(0.5))
                .padding(.top, 10)

            HStack {
                Text(LanguageManager.shared.common("cloud_import_title"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(ShieldTheme.textPrimary)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ShieldTheme.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(ShieldTheme.surface3)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)

            if !pm.isPro {
                proGate
            } else {
                providerList
            }

            Spacer()
        }
        .background(ShieldTheme.surface1.ignoresSafeArea())
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .onAppear {
            if let initialProvider {
                selectedProvider = initialProvider
            }
        }
        .sheet(isPresented: $showDocPicker) {
            FilesPickerView { url in
                showDocPicker = false
                isPresented = false
                onImport(url)
            } onCancel: {
                showDocPicker = false
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall, trigger: .settingsUpgrade)
        }
        .sheet(item: $selectedProvider) { provider in
            CloudProviderBrowserView(provider: provider) { url in
                selectedProvider = nil
                isPresented = false
                onImport(url)
            }
        }
    }

    private var proGate: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(ShieldTheme.textTertiary)
            Text(LanguageManager.shared.common("cloud_pro_desc"))
                .font(.system(size: 14))
                .foregroundColor(ShieldTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showPaywall = true
            } label: {
                Label(LanguageManager.shared.paywall("paywall_unlock_pro"),
                      systemImage: "crown.fill")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(ShieldTheme.accent)
                    .foregroundColor(ShieldTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 24)
        }
        .padding(.top, 16)
    }

    private var providerList: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                // Native Files app picker (includes all cloud providers via Files extension)
                providerRow(
                    icon: "folder.fill",
                    color: "FFD60A",
                    name: LanguageManager.shared.common("cloud_files_title"),
                    subtitle: LanguageManager.shared.common("cloud_files_subtitle"),
                    isConnected: true
                ) {
                    showDocPicker = true
                }

                ShieldDivider().padding(.leading, 54)

                ForEach(ExternalStorageProvider.allCases) { provider in
                    providerRow(
                        icon: provider.icon,
                        color: provider.iconColor,
                        name: provider.displayName,
                        subtitle: providerSubtitle(provider),
                        isConnected: cloudStorage.isConnected(provider)
                    ) {
                        selectedProvider = provider
                    }
                    if provider != ExternalStorageProvider.allCases.last {
                        ShieldDivider().padding(.leading, 54)
                    }
                }
            }
            .background(ShieldTheme.surface2)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShieldTheme.surfaceLine, lineWidth: 0.5))
            .padding(.horizontal, 16)

            Label(
                LanguageManager.shared.common("cloud_provider_setup_hint"),
                systemImage: "info.circle"
            )
            .font(.system(size: 11))
            .foregroundColor(ShieldTheme.textTertiary)
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
    }

    private func providerSubtitle(_ provider: ExternalStorageProvider) -> String {
        if !cloudStorage.isConfigured(provider) {
            return LanguageManager.shared.common("cloud_configuration_required")
        }
        return cloudStorage.isConnected(provider)
            ? LanguageManager.shared.common("cloud_connected")
            : LanguageManager.shared.common("cloud_tap_to_connect")
    }

    @ViewBuilder
    private func providerRow(icon: String, color: String, name: String, subtitle: String,
                               isConnected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(hex: color))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(ShieldTheme.textPrimary)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(ShieldTheme.textTertiary)
                }

                Spacer()

                if isConnected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(ShieldTheme.textTertiary)
                } else {
                    Text(LanguageManager.shared.common("cloud_connect"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(ShieldTheme.accent)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

private struct CloudProviderBrowserView: View {
    let provider: ExternalStorageProvider
    let onImport: (URL) -> Void

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = DirectCloudStorageManager.shared
    @State private var folders: [CloudRemoteItem] = []
    @State private var items: [CloudRemoteItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var language: AppLanguage { LanguageManager.shared.current }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView(language == .es ? "Conectando…" : "Connecting…")
                } else if let errorMessage {
                    ContentUnavailableView {
                        Label(provider.displayName, systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button(language == .es ? "Reintentar" : "Try again") {
                            Task { await loadCurrentFolder(forceReconnect: true) }
                        }
                    }
                } else if items.isEmpty {
                    ContentUnavailableView(
                        language == .es ? "No hay documentos compatibles" : "No compatible documents",
                        systemImage: "folder"
                    )
                } else {
                    List(items) { item in
                        Button {
                            Task { await open(item) }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.isFolder ? "folder.fill" : fileIcon(item))
                                    .foregroundStyle(item.isFolder ? Color(hex: provider.iconColor) : ShieldTheme.accent)
                                    .frame(width: 28)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .foregroundStyle(.primary)
                                        .lineLimit(2)
                                    if let size = item.size, !item.isFolder {
                                        Text(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Spacer()
                                if item.isFolder {
                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .contentShape(.rect)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(folders.last?.name ?? provider.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if folders.isEmpty {
                            dismiss()
                        } else {
                            folders.removeLast()
                            Task { await loadCurrentFolder() }
                        }
                    } label: {
                        Label(
                            folders.isEmpty
                                ? (language == .es ? "Cerrar" : "Close")
                                : (language == .es ? "Volver" : "Back"),
                            systemImage: folders.isEmpty ? "xmark" : "chevron.left"
                        )
                    }
                    .accessibilityIdentifier("cloud.browser.back")
                }
                if manager.isConnected(provider) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(language == .es ? "Desconectar" : "Disconnect", role: .destructive) {
                            manager.disconnect(provider)
                            dismiss()
                        }
                    }
                }
            }
        }
        .task { await loadCurrentFolder() }
    }

    private func loadCurrentFolder(forceReconnect: Bool = false) async {
        isLoading = true
        errorMessage = nil
        do {
            if forceReconnect { manager.disconnect(provider) }
            if !manager.isConnected(provider) {
                try await manager.connect(provider)
            }
            items = try await manager.listItems(for: provider, folder: folders.last)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func open(_ item: CloudRemoteItem) async {
        if item.isFolder {
            folders.append(item)
            await loadCurrentFolder()
            return
        }
        isLoading = true
        do {
            let url = try await manager.download(item, from: provider)
            onImport(url)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func fileIcon(_ item: CloudRemoteItem) -> String {
        item.name.lowercased().hasSuffix(".pdf") ? "doc.richtext.fill" : "photo.fill"
    }
}
