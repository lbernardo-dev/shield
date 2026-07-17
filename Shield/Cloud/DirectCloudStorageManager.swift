import AuthenticationServices
import CryptoKit
import Foundation
import UIKit

struct CloudRemoteItem: Identifiable, Hashable {
    let id: String
    let name: String
    let isFolder: Bool
    let mimeType: String?
    let size: Int64?
    let providerPath: String?
}

enum DirectCloudError: LocalizedError {
    case providerNotConfigured(String)
    case authorizationCancelled
    case invalidAuthorizationResponse
    case invalidServerResponse
    case unsupportedFile
    case missingRefreshToken

    var errorDescription: String? {
        switch self {
        case .providerNotConfigured(let provider):
            return "\(provider) has not been configured with a real OAuth client ID."
        case .authorizationCancelled:
            return "Authorization was cancelled."
        case .invalidAuthorizationResponse:
            return "The provider returned an invalid authorization response."
        case .invalidServerResponse:
            return "The cloud provider returned an invalid response."
        case .unsupportedFile:
            return "This file type cannot be imported by Shield."
        case .missingRefreshToken:
            return "The cloud session expired. Connect the provider again."
        }
    }
}

private struct CloudOAuthToken: Codable {
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date
}

private struct OAuthTokenResponse: Decodable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Double?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}

private struct CloudProviderConfiguration {
    let clientID: String
    let redirectURI: String
    let callbackScheme: String

    var isUsable: Bool {
        !clientID.isEmpty &&
        !redirectURI.isEmpty &&
        !callbackScheme.isEmpty &&
        !clientID.contains("$(") &&
        !redirectURI.contains("$(") &&
        !callbackScheme.contains("$(")
    }
}

@MainActor
final class DirectCloudStorageManager: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = DirectCloudStorageManager()

    @Published private(set) var connectedProviders: Set<ExternalStorageProvider> = []
    @Published private(set) var busyProvider: ExternalStorageProvider?

    private let tokenService = "com.romerodev.shield.cloud-oauth"
    private var activeSession: ASWebAuthenticationSession?

    private override init() {
        super.init()
        connectedProviders = Set(ExternalStorageProvider.allCases.filter { loadToken(for: $0) != nil })
    }

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }

    func isConfigured(_ provider: ExternalStorageProvider) -> Bool {
        configuration(for: provider).isUsable
    }

    func isConnected(_ provider: ExternalStorageProvider) -> Bool {
        connectedProviders.contains(provider)
    }

    func connect(_ provider: ExternalStorageProvider) async throws {
        let configuration = configuration(for: provider)
        guard configuration.isUsable else {
            throw DirectCloudError.providerNotConfigured(provider.displayName)
        }

        busyProvider = provider
        defer { busyProvider = nil }

        let verifier = Self.pkceVerifier()
        let challenge = Self.pkceChallenge(for: verifier)
        let state = UUID().uuidString
        let authorizationURL = try authorizationURL(
            for: provider,
            configuration: configuration,
            challenge: challenge,
            state: state
        )
        let callbackURL = try await authorize(
            at: authorizationURL,
            callbackScheme: configuration.callbackScheme
        )

        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              components.queryItems?.first(where: { $0.name == "state" })?.value == state,
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else {
            throw DirectCloudError.invalidAuthorizationResponse
        }

        let token = try await exchangeCode(
            code,
            verifier: verifier,
            provider: provider,
            configuration: configuration
        )
        try saveToken(token, for: provider)
        connectedProviders.insert(provider)
    }

    func disconnect(_ provider: ExternalStorageProvider) {
        KeychainStore.delete(service: tokenService, account: provider.rawValue)
        connectedProviders.remove(provider)
    }

    func listItems(for provider: ExternalStorageProvider, folder: CloudRemoteItem? = nil) async throws -> [CloudRemoteItem] {
        let token = try await validAccessToken(for: provider)
        switch provider {
        case .googleDrive:
            return try await listGoogleDrive(folderID: folder?.id, token: token)
        case .dropbox:
            return try await listDropbox(path: folder?.providerPath ?? "", token: token)
        }
    }

    func download(_ item: CloudRemoteItem, from provider: ExternalStorageProvider) async throws -> URL {
        guard !item.isFolder else { throw DirectCloudError.unsupportedFile }
        let token = try await validAccessToken(for: provider)
        let result: (Data, String)
        switch provider {
        case .googleDrive:
            result = try await downloadGoogleDrive(item, token: token)
        case .dropbox:
            result = try await downloadDropbox(item, token: token)
        }

        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ShieldCloudImports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let safeName = Self.sanitizedFileName(result.1)
        let url = directory.appendingPathComponent("\(UUID().uuidString)-\(safeName)")
        try result.0.write(to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    // MARK: OAuth

    private func configuration(for provider: ExternalStorageProvider) -> CloudProviderConfiguration {
        let info = Bundle.main.infoDictionary ?? [:]
        func string(_ key: String) -> String { (info[key] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
        switch provider {
        case .googleDrive:
            return CloudProviderConfiguration(
                clientID: string("ShieldGoogleDriveClientID"),
                redirectURI: string("ShieldGoogleDriveRedirectURI"),
                callbackScheme: string("ShieldGoogleDriveCallbackScheme")
            )
        case .dropbox:
            return CloudProviderConfiguration(
                clientID: string("ShieldDropboxAppKey"),
                redirectURI: string("ShieldDropboxRedirectURI"),
                callbackScheme: string("ShieldDropboxCallbackScheme")
            )
        }
    }

    private func authorizationURL(
        for provider: ExternalStorageProvider,
        configuration: CloudProviderConfiguration,
        challenge: String,
        state: String
    ) throws -> URL {
        let base: String
        var items: [URLQueryItem] = [
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state)
        ]

        switch provider {
        case .googleDrive:
            base = "https://accounts.google.com/o/oauth2/v2/auth"
            items += [
                URLQueryItem(name: "scope", value: "https://www.googleapis.com/auth/drive.readonly"),
                URLQueryItem(name: "access_type", value: "offline"),
                URLQueryItem(name: "prompt", value: "consent")
            ]
        case .dropbox:
            base = "https://www.dropbox.com/oauth2/authorize"
            items += [
                URLQueryItem(name: "scope", value: "files.metadata.read files.content.read"),
                URLQueryItem(name: "token_access_type", value: "offline")
            ]
        }

        var components = URLComponents(string: base)
        components?.queryItems = items
        guard let url = components?.url else { throw DirectCloudError.invalidAuthorizationResponse }
        return url
    }

    private func authorize(at url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { [weak self] callback, error in
                Task { @MainActor in
                    self?.activeSession = nil
                    if let authenticationError = error as? ASWebAuthenticationSessionError,
                       authenticationError.code == .canceledLogin {
                        continuation.resume(throwing: DirectCloudError.authorizationCancelled)
                    } else if let error {
                        continuation.resume(throwing: error)
                    } else if let callback {
                        continuation.resume(returning: callback)
                    } else {
                        continuation.resume(throwing: DirectCloudError.invalidAuthorizationResponse)
                    }
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            activeSession = session
            guard session.start() else {
                activeSession = nil
                continuation.resume(throwing: DirectCloudError.invalidAuthorizationResponse)
                return
            }
        }
    }

    private func exchangeCode(
        _ code: String,
        verifier: String,
        provider: ExternalStorageProvider,
        configuration: CloudProviderConfiguration
    ) async throws -> CloudOAuthToken {
        let endpoint: URL
        switch provider {
        case .googleDrive: endpoint = URL(string: "https://oauth2.googleapis.com/token")!
        case .dropbox: endpoint = URL(string: "https://api.dropboxapi.com/oauth2/token")!
        }
        let response: OAuthTokenResponse = try await formRequest(
            url: endpoint,
            parameters: [
                "client_id": configuration.clientID,
                "code": code,
                "code_verifier": verifier,
                "grant_type": "authorization_code",
                "redirect_uri": configuration.redirectURI
            ]
        )
        return CloudOAuthToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: Date().addingTimeInterval(response.expiresIn ?? 3_600)
        )
    }

    private func validAccessToken(for provider: ExternalStorageProvider) async throws -> String {
        guard var token = loadToken(for: provider) else {
            throw DirectCloudError.invalidAuthorizationResponse
        }
        guard token.expiresAt.timeIntervalSinceNow < 60 else { return token.accessToken }
        guard let refreshToken = token.refreshToken else { throw DirectCloudError.missingRefreshToken }
        let configuration = configuration(for: provider)
        guard configuration.isUsable else { throw DirectCloudError.providerNotConfigured(provider.displayName) }

        let endpoint: URL
        switch provider {
        case .googleDrive: endpoint = URL(string: "https://oauth2.googleapis.com/token")!
        case .dropbox: endpoint = URL(string: "https://api.dropboxapi.com/oauth2/token")!
        }
        let response: OAuthTokenResponse = try await formRequest(
            url: endpoint,
            parameters: [
                "client_id": configuration.clientID,
                "refresh_token": refreshToken,
                "grant_type": "refresh_token"
            ]
        )
        token.accessToken = response.accessToken
        token.refreshToken = response.refreshToken ?? refreshToken
        token.expiresAt = Date().addingTimeInterval(response.expiresIn ?? 3_600)
        try saveToken(token, for: provider)
        return token.accessToken
    }

    // MARK: Google Drive

    private struct GoogleFilesResponse: Decodable {
        struct File: Decodable {
            let id: String
            let name: String
            let mimeType: String
            let size: String?
        }
        let files: [File]
        let nextPageToken: String?
    }

    private func listGoogleDrive(folderID: String?, token: String) async throws -> [CloudRemoteItem] {
        var pageToken: String?
        var items: [CloudRemoteItem] = []
        repeat {
            var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
            var query = "trashed = false"
            if let folderID { query += " and '\(folderID)' in parents" }
            else { query += " and 'root' in parents" }
            components.queryItems = [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "fields", value: "nextPageToken,files(id,name,mimeType,size)"),
                URLQueryItem(name: "pageSize", value: "1000")
            ]
            if let pageToken { components.queryItems?.append(URLQueryItem(name: "pageToken", value: pageToken)) }
            let response: GoogleFilesResponse = try await authorizedJSON(url: components.url!, token: token)
            items += response.files.compactMap { file in
                let folder = file.mimeType == "application/vnd.google-apps.folder"
                guard folder || Self.isSupportedGoogleMimeType(file.mimeType) else { return nil }
                return CloudRemoteItem(
                    id: file.id,
                    name: file.name,
                    isFolder: folder,
                    mimeType: file.mimeType,
                    size: file.size.flatMap(Int64.init),
                    providerPath: nil
                )
            }
            pageToken = response.nextPageToken
        } while pageToken != nil
        return Self.sorted(items)
    }

    private func downloadGoogleDrive(_ item: CloudRemoteItem, token: String) async throws -> (Data, String) {
        let googleDocument = item.mimeType?.hasPrefix("application/vnd.google-apps.") == true
        let url: URL
        let name: String
        if googleDocument {
            var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files/\(item.id)/export")!
            components.queryItems = [URLQueryItem(name: "mimeType", value: "application/pdf")]
            url = components.url!
            name = item.name.lowercased().hasSuffix(".pdf") ? item.name : "\(item.name).pdf"
        } else {
            var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files/\(item.id)")!
            components.queryItems = [URLQueryItem(name: "alt", value: "media")]
            url = components.url!
            name = item.name
        }
        return (try await authorizedData(url: url, token: token), name)
    }

    // MARK: Dropbox

    private struct DropboxListResponse: Decodable {
        struct Entry: Decodable {
            let tag: String
            let name: String
            let pathLower: String?
            let id: String?
            let size: Int64?
            enum CodingKeys: String, CodingKey {
                case tag = ".tag"
                case name
                case pathLower = "path_lower"
                case id
                case size
            }
        }
        let entries: [Entry]
        let cursor: String
        let hasMore: Bool
        enum CodingKeys: String, CodingKey {
            case entries, cursor
            case hasMore = "has_more"
        }
    }

    private func listDropbox(path: String, token: String) async throws -> [CloudRemoteItem] {
        var response: DropboxListResponse = try await authorizedJSON(
            url: URL(string: "https://api.dropboxapi.com/2/files/list_folder")!,
            token: token,
            method: "POST",
            jsonBody: ["path": path, "recursive": false, "include_deleted": false]
        )
        var entries = response.entries
        while response.hasMore {
            response = try await authorizedJSON(
                url: URL(string: "https://api.dropboxapi.com/2/files/list_folder/continue")!,
                token: token,
                method: "POST",
                jsonBody: ["cursor": response.cursor]
            )
            entries += response.entries
        }
        return Self.sorted(entries.compactMap { entry in
            let folder = entry.tag == "folder"
            guard folder || Self.isSupportedFileName(entry.name) else { return nil }
            return CloudRemoteItem(
                id: entry.id ?? entry.pathLower ?? entry.name,
                name: entry.name,
                isFolder: folder,
                mimeType: nil,
                size: entry.size,
                providerPath: entry.pathLower
            )
        })
    }

    private func downloadDropbox(_ item: CloudRemoteItem, token: String) async throws -> (Data, String) {
        guard let path = item.providerPath else { throw DirectCloudError.invalidServerResponse }
        var request = URLRequest(url: URL(string: "https://content.dropboxapi.com/2/files/download")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let argument = try JSONSerialization.data(withJSONObject: ["path": path])
        request.setValue(String(decoding: argument, as: UTF8.self), forHTTPHeaderField: "Dropbox-API-Arg")
        return (try await performDataRequest(request), item.name)
    }

    // MARK: Networking and persistence

    private func formRequest<T: Decodable>(url: URL, parameters: [String: String]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var components = URLComponents()
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        let data = try await performDataRequest(request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func authorizedJSON<T: Decodable>(
        url: URL,
        token: String,
        method: String = "GET",
        jsonBody: [String: Any]? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let jsonBody {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let data = try await performDataRequest(request)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func authorizedData(url: URL, token: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await performDataRequest(request)
    }

    private func performDataRequest(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw DirectCloudError.invalidServerResponse
        }
        return data
    }

    private func saveToken(_ token: CloudOAuthToken, for provider: ExternalStorageProvider) throws {
        try KeychainStore.save(
            JSONEncoder().encode(token),
            service: tokenService,
            account: provider.rawValue,
            accessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        )
    }

    private func loadToken(for provider: ExternalStorageProvider) -> CloudOAuthToken? {
        do {
            guard let data = try KeychainStore.read(service: tokenService, account: provider.rawValue) else {
                return nil
            }
            return try? JSONDecoder().decode(CloudOAuthToken.self, from: data)
        } catch {
            return nil
        }
    }

    private static func pkceVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64URLEncodedString()
    }

    private static func pkceChallenge(for verifier: String) -> String {
        Data(SHA256.hash(data: Data(verifier.utf8))).base64URLEncodedString()
    }

    private static func isSupportedGoogleMimeType(_ mimeType: String) -> Bool {
        mimeType == "application/pdf" ||
        mimeType.hasPrefix("image/") ||
        [
            "application/vnd.google-apps.document",
            "application/vnd.google-apps.spreadsheet",
            "application/vnd.google-apps.presentation",
            "application/vnd.google-apps.drawing"
        ].contains(mimeType)
    }

    private static func isSupportedFileName(_ name: String) -> Bool {
        ["pdf", "jpg", "jpeg", "png", "tif", "tiff", "heic", "heif"]
            .contains(URL(fileURLWithPath: name).pathExtension.lowercased())
    }

    private static func sorted(_ items: [CloudRemoteItem]) -> [CloudRemoteItem] {
        items.sorted {
            if $0.isFolder != $1.isFolder { return $0.isFolder }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private static func sanitizedFileName(_ name: String) -> String {
        let invalid = CharacterSet(charactersIn: "/\\:?%*|\"<>").union(.newlines)
        let value = name.components(separatedBy: invalid).joined(separator: "-")
        return value.isEmpty ? "Cloud-Document" : String(value.prefix(160))
    }
}

private extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
