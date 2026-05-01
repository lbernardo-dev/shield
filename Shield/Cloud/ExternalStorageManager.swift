import SwiftUI
import AuthenticationServices
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

    // OAuth 2.0 authorization endpoints
    var authBaseURL: String {
        switch self {
        case .googleDrive:
            return "https://accounts.google.com/o/oauth2/v2/auth"
        case .dropbox:
            return "https://www.dropbox.com/oauth2/authorize"
        case .oneDrive:
            return "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
        }
    }

    // Scopes required for file download
    var scope: String {
        switch self {
        case .googleDrive: return "https://www.googleapis.com/auth/drive.readonly"
        case .dropbox:     return "files.content.read"
        case .oneDrive:    return "Files.Read offline_access"
        }
    }

    // Redirect URI registered in your app's Info.plist / URL schemes
    var redirectURI: String {
        return "shield://oauth/\(rawValue)"
    }

    // UserDefaults key for storing connection state
    var connectedKey: String { "shield.cloud.\(rawValue).connected" }
    var tokenKey: String     { "shield.cloud.\(rawValue).token" }
    var emailKey: String     { "shield.cloud.\(rawValue).email" }
}

// MARK: - ExternalStorageManager

@MainActor
final class ExternalStorageManager: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = ExternalStorageManager()

    @Published var connectedProviders: Set<ExternalStorageProvider> = []
    @Published var isAuthenticating: ExternalStorageProvider? = nil
    @Published var authError: String? = nil
    @Published var showFilePicker: Bool = false
    @Published var pickerProvider: ExternalStorageProvider? = nil

    private var authSession: ASWebAuthenticationSession?
    private var pendingProvider: ExternalStorageProvider?
    var onFileImported: ((URL) -> Void)?

    private override init() {
        super.init()
        loadConnectedState()
    }

    // MARK: - Connection state

    private func loadConnectedState() {
        for provider in ExternalStorageProvider.allCases {
            if UserDefaults.standard.bool(forKey: provider.connectedKey) {
                connectedProviders.insert(provider)
            }
        }
    }

    func isConnected(_ provider: ExternalStorageProvider) -> Bool {
        connectedProviders.contains(provider)
    }

    func connectedEmail(_ provider: ExternalStorageProvider) -> String? {
        UserDefaults.standard.string(forKey: provider.emailKey)
    }

    // MARK: - Connect via OAuth

    func connect(_ provider: ExternalStorageProvider) {
        guard !isConnected(provider) else {
            // Already connected: open file picker
            openFilePicker(for: provider)
            return
        }

        isAuthenticating = provider
        authError = nil
        pendingProvider = provider

        // Build the OAuth URL.
        // NOTE: In production you must register real client IDs for each provider
        // and add URL schemes to Info.plist. These placeholders show the correct structure.
        var components = URLComponents(string: provider.authBaseURL)!
        let clientID: String = {
            switch provider {
            case .googleDrive: return UserDefaults.standard.string(forKey: "shield.oauth.google.clientID") ?? "YOUR_GOOGLE_CLIENT_ID"
            case .dropbox:     return UserDefaults.standard.string(forKey: "shield.oauth.dropbox.appKey") ?? "YOUR_DROPBOX_APP_KEY"
            case .oneDrive:    return UserDefaults.standard.string(forKey: "shield.oauth.onedrive.clientID") ?? "YOUR_ONEDRIVE_CLIENT_ID"
            }
        }()

        components.queryItems = [
            URLQueryItem(name: "client_id",     value: clientID),
            URLQueryItem(name: "redirect_uri",  value: provider.redirectURI),
            URLQueryItem(name: "response_type", value: "token"),
            URLQueryItem(name: "scope",         value: provider.scope),
        ]

        guard let authURL = components.url else {
            isAuthenticating = nil
            authError = "Invalid OAuth URL"
            return
        }

        guard let callbackScheme = URL(string: provider.redirectURI)?.scheme else {
            isAuthenticating = nil
            authError = "Invalid redirect URI"
            return
        }

        authSession = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackScheme
        ) { [weak self] callbackURL, error in
            DispatchQueue.main.async {
                self?.handleOAuthCallback(provider: provider, url: callbackURL, error: error)
            }
        }
        authSession?.presentationContextProvider = self
        authSession?.prefersEphemeralWebBrowserSession = false
        authSession?.start()
    }

    private func handleOAuthCallback(provider: ExternalStorageProvider, url: URL?, error: Error?) {
        isAuthenticating = nil

        if let error = error as? ASWebAuthenticationSessionError,
           error.code == .canceledLogin {
            return
        }

        if let error = error {
            authError = error.localizedDescription
            return
        }

        guard let callbackURL = url,
              let fragment = callbackURL.fragment else {
            authError = "OAuth callback missing token"
            return
        }

        // Parse access_token from fragment (implicit flow)
        let params = fragment.split(separator: "&").reduce(into: [String: String]()) { dict, pair in
            let kv = pair.split(separator: "=", maxSplits: 1)
            if kv.count == 2 { dict[String(kv[0])] = String(kv[1]) }
        }

        guard let token = params["access_token"] else {
            authError = "No access token in response"
            return
        }

        // Store token securely (in production use Keychain, here UserDefaults for brevity)
        UserDefaults.standard.set(token, forKey: provider.tokenKey)
        UserDefaults.standard.set(true, forKey: provider.connectedKey)
        connectedProviders.insert(provider)
        authError = nil

        // After connecting, open the file picker
        openFilePicker(for: provider)
    }

    // MARK: - Disconnect

    func disconnect(_ provider: ExternalStorageProvider) {
        UserDefaults.standard.removeObject(forKey: provider.connectedKey)
        UserDefaults.standard.removeObject(forKey: provider.tokenKey)
        UserDefaults.standard.removeObject(forKey: provider.emailKey)
        connectedProviders.remove(provider)
    }

    // MARK: - File picker (native iOS Files app + cloud)
    // Uses UIDocumentPickerViewController which natively lists cloud providers
    // including Google Drive (via Files integration), Dropbox, and OneDrive
    // if those apps are installed.

    func openFilePicker(for provider: ExternalStorageProvider) {
        pickerProvider = provider
        showFilePicker = true
    }

    func openGenericCloudPicker(onImport: @escaping (URL) -> Void) {
        onFileImported = onImport
        pickerProvider = nil
        showFilePicker = true
    }

    // MARK: - ASWebAuthenticationPresentationContextProviding

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let activeScene = scenes.first(where: { $0.activationState == .foregroundActive }) ?? scenes.first
            if let window = activeScene?.keyWindow { return window }
            // Last-resort: any visible window (UIApplication.windows deprecated but functional)
            return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
                ?? UIApplication.shared.windows.first
                ?? ASPresentationAnchor()
        }
    }
}

// MARK: - ExternalStoragePickerView
// Presents a sheet to pick from connected cloud providers.

struct ExternalStoragePickerSheet: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var ext = ExternalStorageManager.shared
    @StateObject private var pm = PremiumManager.shared
    @Binding var isPresented: Bool
    var onImport: (URL) -> Void

    @State private var showDocPicker = false
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .frame(width: 36, height: 4)
                .foregroundColor(ShieldTheme.textTertiary.opacity(0.5))
                .padding(.top, 10)

            HStack {
                Text(appState.language == .es ? "Importar desde nube" : "Import from cloud")
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
                .environmentObject(appState)
        }
    }

    private var proGate: some View {
        VStack(spacing: 16) {
            Image(systemName: "icloud.and.arrow.down")
                .font(.system(size: 44, weight: .light))
                .foregroundColor(ShieldTheme.textTertiary)
            Text(appState.language == .es
                 ? "Importar desde Google Drive, Dropbox y OneDrive está disponible en Shield Pro."
                 : "Importing from Google Drive, Dropbox and OneDrive is available in Shield Pro.")
                .font(.system(size: 14))
                .foregroundColor(ShieldTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                showPaywall = true
            } label: {
                Label(appState.language == .es ? "Activar Shield Pro" : "Get Shield Pro",
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
            // Native Files app picker (includes all cloud providers via Files extension)
            providerRow(
                icon: "folder.fill",
                color: "FFD60A",
                name: appState.language == .es ? "Archivos (iCloud, Google Drive, Dropbox…)" : "Files (iCloud, Google Drive, Dropbox…)",
                subtitle: appState.language == .es ? "Todos tus proveedores de nube" : "All your cloud providers",
                isConnected: true
            ) {
                showDocPicker = true
            }

            ShieldDivider().padding(.leading, 54)

            // Individual provider connections for direct OAuth
            ForEach(ExternalStorageProvider.allCases) { provider in
                let connected = ext.isConnected(provider)
                providerRow(
                    icon: provider.icon,
                    color: provider.iconColor,
                    name: provider.displayName,
                    subtitle: connected
                        ? (ext.connectedEmail(provider) ?? (appState.language == .es ? "Conectado" : "Connected"))
                        : (appState.language == .es ? "Toca para conectar" : "Tap to connect"),
                    isConnected: connected
                ) {
                    if connected {
                        ext.openFilePicker(for: provider)
                        // After picking, FilesPickerView handles import
                        showDocPicker = true
                    } else {
                        ext.connect(provider)
                    }
                }
                if provider != ExternalStorageProvider.allCases.last {
                    ShieldDivider().padding(.leading, 54)
                }
            }

            if let err = ext.authError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(ShieldTheme.danger)
                    Text(err)
                        .font(.system(size: 12))
                        .foregroundColor(ShieldTheme.danger)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
        }
        .background(ShieldTheme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(ShieldTheme.surfaceLine, lineWidth: 0.5))
        .padding(.horizontal, 16)
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
                    if ext.isAuthenticating == ExternalStorageProvider.allCases.first(where: { $0.displayName == name }) {
                        ProgressView().scaleEffect(0.7).tint(ShieldTheme.accent)
                    } else {
                        Text(appState.language == .es ? "Conectar" : "Connect")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(ShieldTheme.accent)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
