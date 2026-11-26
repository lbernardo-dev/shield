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
    case .dropbox: return "Dropbox"
    }
  }

  var icon: String {
    switch self {
    case .googleDrive: return "g.circle.fill"
    case .dropbox: return "shippingbox.fill"
    }
  }

  var iconColor: String {
    switch self {
    case .googleDrive: return "4285F4"
    case .dropbox: return "0061FF"
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

  init(
    isPresented: Binding<Bool>,
    initialProvider: ExternalStorageProvider? = nil,
    onImport: @escaping (URL) -> Void
  ) {
    self._isPresented = isPresented
    self.initialProvider = initialProvider
    self.onImport = onImport
    self._selectedProvider = State(initialValue: initialProvider)
  }

  var body: some View {
    Group {
      if let provider = selectedProvider {
        CloudProviderBrowserView(
          provider: provider,
          onImport: { url in
            selectedProvider = nil
            isPresented = false
            onImport(url)
          },
          onDismiss: {
            if initialProvider != nil {
              isPresented = false
            } else {
              selectedProvider = nil
            }
          },
          onOpenFiles: {
            showDocPicker = true
          }
        )
      } else {
        pickerListView
      }
    }
    .presentationDetents(selectedProvider == nil ? [.medium] : [.large])
    .presentationDragIndicator(.hidden)
    .sheet(isPresented: $showDocPicker) {
      FilesPickerView(allowsMultipleSelection: false) { urls in
        guard let url = urls.first else {
          showDocPicker = false
          return
        }
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
  }

  private var pickerListView: some View {
    VStack(spacing: 0) {
      // Handle
      Capsule()
        .frame(width: 36, height: 4)
        .foregroundColor(ShieldTheme.textTertiary.opacity(0.5))
        .padding(.top, 10)

      HStack {
        Text(LanguageManager.shared.common("cloud_import_title"))
          .shieldFont(17, weight: .bold)
          .foregroundColor(ShieldTheme.textPrimary)
        Spacer()
        Button {
          isPresented = false
        } label: {
          Image(systemName: "xmark")
            .shieldFont(13, weight: .medium)
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
  }

  private var proGate: some View {
    VStack(spacing: 16) {
      Image(systemName: "icloud.and.arrow.down")
        .shieldFont(44, weight: .light)
        .foregroundColor(ShieldTheme.textTertiary)
      Text(LanguageManager.shared.common("cloud_pro_desc"))
        .shieldFont(14)
        .foregroundColor(ShieldTheme.textSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
      Button {
        showPaywall = true
      } label: {
        Label(
          LanguageManager.shared.paywall("paywall_unlock_pro"),
          systemImage: "sparkles"
        )
        .shieldFont(15, weight: .bold)
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
      .shieldFont(11)
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
  private func providerRow(
    icon: String, color: String, name: String, subtitle: String,
    isConnected: Bool, action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 14) {
        ZStack {
          RoundedRectangle(cornerRadius: 9)
            .fill(Color(hex: color))
            .frame(width: 36, height: 36)
          Image(systemName: icon)
            .shieldFont(16, weight: .semibold)
            .foregroundColor(.white)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(name)
            .shieldFont(14, weight: .semibold)
            .foregroundColor(ShieldTheme.textPrimary)
            .lineLimit(1)
          Text(subtitle)
            .shieldFont(11)
            .foregroundColor(ShieldTheme.textTertiary)
        }

        Spacer()

        if isConnected {
          Image(systemName: "chevron.right")
            .shieldFont(12, weight: .medium)
            .foregroundColor(ShieldTheme.textTertiary)
        } else {
          Text(LanguageManager.shared.common("cloud_connect"))
            .shieldFont(12, weight: .semibold)
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
  var onDismiss: (() -> Void)? = nil
  var onOpenFiles: (() -> Void)? = nil

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
            onChooseAnotherProvider: {
              if let onDismiss {
                onDismiss()
              } else {
                dismiss()
              }
            },
            onOpenFiles: onOpenFiles
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
                  .foregroundStyle(
                    item.isFolder ? Color(hex: provider.iconColor) : ShieldTheme.accent
                  )
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
              if let onDismiss {
                onDismiss()
              } else {
                dismiss()
              }
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
              if let onDismiss {
                onDismiss()
              } else {
                dismiss()
              }
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
  var onOpenFiles: (() -> Void)? = nil

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var isFloating = false

  private var isCancellation: Bool { failure == .cancelled }

  var body: some View {
    VStack(spacing: 0) {
      Spacer(minLength: 36)

      illustration
        .padding(.bottom, 28)

      Text(
        LanguageManager.shared.common(
          isCancellation ? "cloud_cancelled_title" : "cloud_connection_problem_title"
        )
      )
      .shieldFont(24, weight: .bold, design: .rounded)
      .foregroundStyle(ShieldTheme.textPrimary)
      .multilineTextAlignment(.center)

      Text(LanguageManager.shared.common(failure.messageKey))
        .shieldFont(15, weight: .regular)
        .foregroundStyle(ShieldTheme.textSecondary)
        .multilineTextAlignment(.center)
        .lineSpacing(3)
        .padding(.top, 9)
        .padding(.horizontal, 30)

      if provider == .googleDrive {
        VStack(spacing: 4) {
          HStack(spacing: 5) {
            Image(systemName: "info.circle.fill")
              .foregroundStyle(Color(hex: "0EA5E9"))
            Text(
              LanguageManager.shared.current == .es
                ? "Aviso de Google Cloud (Error 403)"
                : "Google Cloud Notice (Error 403)"
            )
            .shieldFont(12, weight: .bold)
            .foregroundStyle(ShieldTheme.textPrimary)
          }
          Text(
            LanguageManager.shared.current == .es
              ? "Google requiere que lbernardo.cu@gmail.com esté añadido como 'Test User' en Google Console. Mientras tanto, puedes usar 'Importar desde Archivos de iOS' para acceder a tu Google Drive sin restricciones."
              : "Google requires lbernardo.cu@gmail.com to be added as a 'Test User' in Google Console. Meanwhile, you can use 'Import from iOS Files' to access your Google Drive without restrictions."
          )
          .shieldFont(11)
          .foregroundStyle(ShieldTheme.textSecondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 12)
        }
        .padding(.vertical, 8)
        .background(Color(hex: "0EA5E9").opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 24)
        .padding(.top, 10)
      }

      VStack(spacing: 12) {
        Button(action: onRetry) {
          Label(
            LanguageManager.shared.common("cloud_retry_connection"),
            systemImage: "arrow.clockwise"
          )
          .shieldFont(15, weight: .bold)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(ShieldTheme.accent)
          .foregroundStyle(ShieldTheme.accentText)
          .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("cloud.recovery.retry")

        if let onOpenFiles {
          Button(action: onOpenFiles) {
            HStack(spacing: 8) {
              Image(systemName: "folder.fill")
                .foregroundStyle(Color(hex: "FFD60A"))
              Text(
                LanguageManager.shared.current == .es
                  ? "Importar desde Archivos de iOS"
                  : "Import from iOS Files"
              )
              .shieldFont(14, weight: .semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(ShieldTheme.surface2)
            .foregroundStyle(ShieldTheme.textPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
          }
          .buttonStyle(ScaleButtonStyle())
          .accessibilityIdentifier("cloud.recovery.openFiles")
        }

        Button(action: onChooseAnotherProvider) {
          Text(LanguageManager.shared.common("cloud_choose_provider"))
            .shieldFont(14, weight: .semibold)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .foregroundStyle(ShieldTheme.textSecondary)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("cloud.recovery.chooseProvider")
      }
      .padding(.top, 24)
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
            .shieldFont(31, weight: .semibold)
            .foregroundStyle(.white)
        }

      Image(
        systemName: isCancellation
          ? "arrow.uturn.backward.circle.fill" : "wifi.exclamationmark.circle.fill"
      )
      .shieldFont(29, weight: .bold)
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
