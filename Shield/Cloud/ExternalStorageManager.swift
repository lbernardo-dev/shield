import SwiftUI
import UniformTypeIdentifiers

// MARK: - ExternalStorageProvider

enum ExternalStorageProvider: String, CaseIterable, Identifiable {
    case googleDrive
    case dropbox

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .googleDrive: return "Google Drive"
        case .dropbox:     return "Dropbox"
        }
    }

    var icon: String {
        switch self {
        case .googleDrive: return "g.circle.fill"
        case .dropbox:     return "shippingbox.fill"
        }
    }

    var iconColor: String {
        switch self {
        case .googleDrive: return "4285F4"
        case .dropbox:     return "0061FF"
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
    @State private var failure: CloudProviderFailure?

    private var language: AppLanguage { LanguageManager.shared.current }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView(LanguageManager.shared.common("cloud_connecting"))
                } else if let failure {
                    CloudConnectionRecoveryView(
                        provider: provider,
                        failure: failure,
                        onRetry: { Task { await loadCurrentFolder(forceReconnect: true) } },
                        onChooseAnotherProvider: { dismiss() }
                    )
                } else if items.isEmpty {
                    ContentUnavailableView(
                        LanguageManager.shared.common("cloud_no_compatible_documents"),
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
                                ? LanguageManager.shared.common("common_close")
                                : LanguageManager.shared.common("cloud_browser_back"),
                            systemImage: folders.isEmpty ? "xmark" : "chevron.left"
                        )
                    }
                    .accessibilityIdentifier("cloud.browser.back")
                }
                if manager.isConnected(provider) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(LanguageManager.shared.common("cloud_disconnect"), role: .destructive) {
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
        failure = nil
        do {
            if forceReconnect { manager.disconnect(provider) }
            if !manager.isConnected(provider) {
                try await manager.connect(provider)
            }
            items = try await manager.listItems(for: provider, folder: folders.last)
        } catch {
            failure = CloudProviderFailure(error)
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
            failure = CloudProviderFailure(error)
            isLoading = false
        }
    }

    private func fileIcon(_ item: CloudRemoteItem) -> String {
        item.name.lowercased().hasSuffix(".pdf") ? "doc.richtext.fill" : "photo.fill"
    }
}

private enum CloudProviderFailure: Equatable {
    case cancelled
    case unavailable
    case sessionExpired
    case unsupportedFile
    case connection

    init(_ error: Error) {
        guard let cloudError = error as? DirectCloudError else {
            self = .connection
            return
        }
        switch cloudError {
        case .authorizationCancelled:
            self = .cancelled
        case .providerNotConfigured:
            self = .unavailable
        case .missingRefreshToken:
            self = .sessionExpired
        case .unsupportedFile:
            self = .unsupportedFile
        case .invalidAuthorizationResponse, .invalidServerResponse:
            self = .connection
        }
    }

    var messageKey: String {
        switch self {
        case .cancelled: "cloud_cancelled_message"
        case .unavailable: "cloud_unavailable_message"
        case .sessionExpired: "cloud_session_expired_message"
        case .unsupportedFile: "cloud_unsupported_file_message"
        case .connection: "cloud_connection_problem_message"
        }
    }
}

private struct CloudConnectionRecoveryView: View {
    let provider: ExternalStorageProvider
    let failure: CloudProviderFailure
    let onRetry: () -> Void
    let onChooseAnotherProvider: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isFloating = false

    private var isCancellation: Bool { failure == .cancelled }

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 36)

            illustration
                .padding(.bottom, 28)

            Text(LanguageManager.shared.common(
                isCancellation ? "cloud_cancelled_title" : "cloud_connection_problem_title"
            ))
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(ShieldTheme.textPrimary)
            .multilineTextAlignment(.center)

            Text(LanguageManager.shared.common(failure.messageKey))
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(ShieldTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 9)
                .padding(.horizontal, 30)

            VStack(spacing: 12) {
                Button(action: onRetry) {
                    Label(
                        LanguageManager.shared.common("cloud_retry_connection"),
                        systemImage: "arrow.clockwise"
                    )
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(ShieldTheme.accent)
                    .foregroundStyle(ShieldTheme.accentText)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityIdentifier("cloud.recovery.retry")

                Button(action: onChooseAnotherProvider) {
                    Text(LanguageManager.shared.common("cloud_choose_provider"))
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(ShieldTheme.textSecondary)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityIdentifier("cloud.recovery.chooseProvider")
            }
            .padding(.top, 28)
            .padding(.horizontal, 28)

            Spacer(minLength: 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RadialGradient(
                colors: [Color(hex: provider.iconColor).opacity(0.10), .clear],
                center: .center,
                startRadius: 12,
                endRadius: 260
            )
            .ignoresSafeArea()
        }
        .onAppear {
            guard !reduceMotion else { return }
            isFloating = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(isCancellation ? "cloud.recovery.cancelled" : "cloud.recovery.problem")
    }

    private var illustration: some View {
        ZStack {
            Circle()
                .fill(Color(hex: provider.iconColor).opacity(0.10))
                .frame(width: 136, height: 136)

            Circle()
                .stroke(Color(hex: provider.iconColor).opacity(0.22), lineWidth: 1)
                .frame(width: 112, height: 112)

            Circle()
                .fill(Color(hex: provider.iconColor).opacity(0.7))
                .frame(width: 7, height: 7)
                .offset(x: -58, y: -35)

            Circle()
                .fill(ShieldTheme.accent.opacity(0.8))
                .frame(width: 5, height: 5)
                .offset(x: 61, y: 29)

            RoundedRectangle(cornerRadius: 22)
                .fill(Color(hex: provider.iconColor))
                .frame(width: 76, height: 76)
                .shadow(color: Color(hex: provider.iconColor).opacity(0.28), radius: 18, y: 10)
                .overlay {
                    Image(systemName: provider.icon)
                        .font(.system(size: 31, weight: .semibold))
                        .foregroundStyle(.white)
                }

            Image(systemName: isCancellation ? "arrow.uturn.backward.circle.fill" : "wifi.exclamationmark.circle.fill")
                .font(.system(size: 29, weight: .bold))
                .symbolRenderingMode(.palette)
                .foregroundStyle(ShieldTheme.accentText, ShieldTheme.accent)
                .background(Circle().fill(ShieldTheme.surface1).padding(2))
                .offset(x: 36, y: 36)
                .symbolEffect(.bounce, value: isFloating)
        }
        .offset(y: isFloating ? -5 : 5)
        .scaleEffect(isFloating ? 1.02 : 0.98)
        .animation(
            reduceMotion ? nil : .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
            value: isFloating
        )
        .accessibilityHidden(true)
    }
}
