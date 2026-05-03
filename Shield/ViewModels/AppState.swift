import SwiftUI
import Combine
import CryptoKit
import Security
import UIKit

// MARK: - SortOption

enum SortOption: String, CaseIterable, Identifiable {
    case dateDesc, dateAsc, nameAsc, nameDesc
    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dateDesc: return "arrow.down.circle"
        case .dateAsc:  return "arrow.up.circle"
        case .nameAsc:  return "textformat.abc"
        case .nameDesc: return "textformat.abc"
        }
    }

    func label(lang: AppLanguage) -> String {
        switch self {
        case .dateDesc: return LanguageManager.shared.model("model_sort_date_desc")
        case .dateAsc:  return LanguageManager.shared.model("model_sort_date_asc")
        case .nameAsc:  return LanguageManager.shared.model("model_sort_name_asc")
        case .nameDesc: return LanguageManager.shared.model("model_sort_name_desc")
        }
    }
}

// MARK: - AppState

final class AppState: ObservableObject {
    private let autoLockTimestampKey = "shield.autoLock.backgroundTimestamp"
    private static let userActivityTimestampKey = "shield.autoLock.lastActivity"
    private static var lastActivityWrite: TimeInterval = 0
    private var inactivityCheckCancellable: AnyCancellable?
    private var currentScenePhase: ScenePhase = .active

    // MARK: - Onboarding (persisted)
    @Published var isOnboarded: Bool {
        didSet { UserDefaults.standard.set(isOnboarded, forKey: "shield.onboarded") }
    }
    @Published var isAuthenticated: Bool = false {
        didSet {
            if isAuthenticated {
                AppState.markUserActivity(force: true)
            }
        }
    }

    // MARK: - Preferences (persisted)
    var language: AppLanguage {
        get { LanguageManager.shared.current }
        set {
            objectWillChange.send()
            LanguageManager.shared.current = newValue
        }
    }
    @Published var preferredScheme: ColorScheme {
        didSet { UserDefaults.standard.set(preferredScheme == .dark, forKey: "shield.darkMode") }
    }

    // MARK: - Navigation
    @Published var selectedDoc: DocumentItem? = nil
    @Published var showCapture: Bool = false
    @Published var showVault: Bool = false
    @Published var activeTab: AppTab = .library

    // Style pre-selected from gallery — applied to editor when next doc is opened
    @Published var pendingMaskStyle: MaskStyle? = nil

    // Redaction mode pre-selected from the Home quick-actions — auto-applied when the editor opens
    @Published var pendingRedactionMode: RedactionMode? = nil

    // Pages to re-adjust from EditorView — CaptureView opens its ScanReviewView at the correct level
    @Published var scanReviewPagesForEdit: [UIImage] = []
    @Published var showScanReviewForEdit: Bool = false

    // MARK: - Library
    @Published var documents: [DocumentItem] = []
    @Published var searchQuery: String = ""
    @Published var activeCategory: DocumentCategory = .all
    @Published var activeCategoryID: String = DocumentCategory.all.rawValue  // supports custom too
    @Published var sortOption: SortOption = .dateDesc
    @Published var recentDocsPage: Int = 0
    static let recentDocsPageSize = 5

    // Triggered when a vaulted doc is closed from the editor — fires the 60s auto-lock countdown
    @Published var vaultedDocJustClosed: DocumentItem? = nil

    // MARK: - User categories (persisted)
    @Published var customCategories: [UserCategory] = [] {
        didSet { persistCustomCategories() }
    }

    // MARK: - Init

    init() {
        let ud = UserDefaults.standard
        isOnboarded     = ud.bool(forKey: "shield.onboarded")
        // Language is handled by LanguageManager.shared
        preferredScheme = ud.object(forKey: "shield.darkMode") == nil
            ? .dark
            : (ud.bool(forKey: "shield.darkMode") ? .dark : .light)

        // Default auto-lock to "1 minute" (index 1) for new installs
        if ud.object(forKey: "shield.autoLock") == nil {
            ud.set(1, forKey: "shield.autoLock")
        }

        documents = AppState.loadDocuments()
        customCategories = AppState.loadCustomCategories()
        AppState.markUserActivity(force: true)
        startInactivityMonitoring()
    }

    deinit {
        inactivityCheckCancellable?.cancel()
    }

    // MARK: - Computed

    var hasActiveFilter: Bool {
        activeCategoryID != DocumentCategory.all.rawValue || !searchQuery.isEmpty
    }

    // All documents including vaulted — used for the Home recents list.
    // Vaulted docs appear masked in the UI; tapping them triggers vault auth.
    var filteredDocuments: [DocumentItem] {
        var docs = documents  // include vaulted

        if activeCategoryID != DocumentCategory.all.rawValue {
            docs = docs.filter { doc in
                // Vaulted docs always appear regardless of category filter
                if doc.isVaulted { return true }
                if let cid = doc.customCategoryID {
                    return cid == activeCategoryID
                }
                return doc.category.rawValue == activeCategoryID
            }
        }

        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            // Vaulted docs are always visible (title is hidden in UI anyway)
            docs = docs.filter { $0.isVaulted || $0.title.lowercased().contains(q) }
        }

        switch sortOption {
        case .dateDesc: docs = docs.sorted { $0.date > $1.date }
        case .dateAsc:  docs = docs.sorted { $0.date < $1.date }
        case .nameAsc:  docs = docs.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .nameDesc: docs = docs.sorted { $0.title.localizedCompare($1.title) == .orderedDescending }
        }

        return docs
    }

    var filteredDocumentsPage: [DocumentItem] {
        let all = filteredDocuments
        let pageSize = AppState.recentDocsPageSize
        let end = min((recentDocsPage + 1) * pageSize, all.count)
        let start = min(recentDocsPage * pageSize, end)
        return Array(all[start..<end])
    }

    var recentDocsTotalPages: Int {
        max(1, Int(ceil(Double(filteredDocuments.count) / Double(AppState.recentDocsPageSize))))
    }

    var vaultDocuments: [DocumentItem] {
        documents.filter { $0.isVaulted }
    }

    // MARK: - Document CRUD

    func addDocument(_ doc: DocumentItem) {
        documents.insert(doc, at: 0)
        persistDocuments()
    }

    func updateDocument(_ doc: DocumentItem) {
        if let idx = documents.firstIndex(where: { $0.id == doc.id }) {
            documents[idx] = doc
            persistDocuments()
        }
    }

    func deleteDocument(_ doc: DocumentItem) {
        let fileNames = Set((doc.pageFileNames ?? []) + [doc.imageFileName].compactMap { $0 })
        for fileName in fileNames {
            SecureFileStore.shared.removeFile(at: AppState.resolveImageURL(fileName: fileName, isVaulted: doc.isVaulted))
        }
        if let sourceFileName = doc.sourceFileName {
            SecureFileStore.shared.removeFile(at: AppState.resolveSourceURL(fileName: sourceFileName, isVaulted: doc.isVaulted))
        }
        documents.removeAll { $0.id == doc.id }
        persistDocuments()
    }

    func toggleFavorite(_ doc: DocumentItem) {
        var d = doc
        d.isFavorite.toggle()
        updateDocument(d)
    }

    func toggleVault(_ doc: DocumentItem) {
        var d = doc
        moveAssets(for: &d, toVault: !doc.isVaulted)
        d.isVaulted.toggle()
        updateDocument(d)
    }

    func deleteAllDocuments() {
        for doc in documents {
            let fileNames = Set((doc.pageFileNames ?? []) + [doc.imageFileName].compactMap { $0 })
            for fileName in fileNames {
                SecureFileStore.shared.removeFile(at: AppState.resolveImageURL(fileName: fileName, isVaulted: doc.isVaulted))
            }
            if let sourceFileName = doc.sourceFileName {
                SecureFileStore.shared.removeFile(at: AppState.resolveSourceURL(fileName: sourceFileName, isVaulted: doc.isVaulted))
            }
        }
        documents.removeAll()
        persistDocuments()
    }

    // MARK: - Image storage

    @discardableResult
    func saveImage(_ image: UIImage, id: String) -> String? {
        let fileName = "\(id).jpg"
        let url = AppState.libraryImagesDir.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.85) else { return nil }
        do {
            try SecureFileStore.shared.write(data, to: url)
            return fileName
        } catch {
            return nil
        }
    }

    func loadImage(fileName: String, isVaulted: Bool? = nil) -> UIImage? {
        AppState.loadImage(fileName: fileName, isVaulted: isVaulted)
    }

    @discardableResult
    func saveSourceFile(_ data: Data, id: String, fileExtension: String) -> String? {
        let ext = fileExtension.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        let fileName = "\(id).\(ext)"
        let url = AppState.librarySourcesDir.appendingPathComponent(fileName)
        do {
            try SecureFileStore.shared.write(data, to: url)
            return fileName
        } catch {
            return nil
        }
    }

    func loadSourceData(fileName: String, isVaulted: Bool) -> Data? {
        AppState.loadSourceData(fileName: fileName, isVaulted: isVaulted)
    }

    // MARK: - Category CRUD

    func addCustomCategory(_ cat: UserCategory) {
        customCategories.append(cat)
    }

    func deleteCustomCategory(id: String) {
        customCategories.removeAll { $0.id == id }
    }

    // MARK: - Helpers

    func str(_ key: String) -> String {
        LanguageManager.shared.localize(key: key)
    }

    func str(_ key: String, _ args: CVarArg...) -> String {
        let format = LanguageManager.shared.localize(key: key)
        return String(format: format, locale: Locale(identifier: LanguageManager.shared.current.rawValue), arguments: args)
    }

    func str(_ key: String, args: CVarArg..., table: String) -> String {
        let format = LanguageManager.shared.t(key, table: table)
        return String(format: format, locale: Locale(identifier: LanguageManager.shared.current.rawValue), arguments: args)
    }

    static func markUserActivity(force: Bool = false) {
        let now = Date().timeIntervalSince1970
        if !force && now - lastActivityWrite < 1.0 {
            return
        }
        lastActivityWrite = now
        UserDefaults.standard.set(now, forKey: userActivityTimestampKey)
    }

    func completeSuccessfulUnlock() {
        isAuthenticated = true
        let now = Date().timeIntervalSince1970
        let defaults = UserDefaults.standard
        defaults.set(now, forKey: autoLockTimestampKey)
        Self.markUserActivity(force: true)
    }

    static func trackEvent(_ name: String, properties: [String: String] = [:]) {
        var payload: [String: Any] = properties
        payload["event"] = name
        payload["timestamp"] = ISO8601DateFormatter().string(from: Date())
        payload["build"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

        guard JSONSerialization.isValidJSONObject(payload),
              let line = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let handle = FileHandle(forWritingAtPath: telemetryURL.path) ?? createTelemetryFile(at: telemetryURL)
        else {
            return
        }

        do {
            try handle.seekToEnd()
            handle.write(line)
            handle.write(Data([0x0A]))
            try handle.close()
        } catch {
            try? handle.close()
        }

        #if DEBUG
        print("ShieldTelemetry:", name, properties)
        #endif
    }

    func redactionsCount(_ n: Int) -> String {
        LanguageManager.shared.t("common_redactions_count", table: "Common", args: n)
    }

    // MARK: - App lifecycle / auto-lock

    func handleScenePhaseChange(_ phase: ScenePhase) {
        currentScenePhase = phase
        switch phase {
        case .active:
            applyAutoLockIfNeededOnResume()
            AppState.markUserActivity(force: true)
        case .background:
            markBackgroundTimestampAndLockIfImmediate()
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    private func markBackgroundTimestampAndLockIfImmediate() {
        let defaults = UserDefaults.standard
        defaults.set(Date().timeIntervalSince1970, forKey: autoLockTimestampKey)

        guard isOnboarded, isAuthenticated else { return }
        if autoLockDelaySeconds == 0 {
            isAuthenticated = false
        }
    }

    private func applyAutoLockIfNeededOnResume() {
        guard isOnboarded, isAuthenticated else { return }
        guard let delay = autoLockDelaySeconds else { return }
        // Immediate auto-lock is already enforced on background transition.
        // Avoid re-locking on transient active callbacks (e.g. Face ID prompt dismissal).
        guard delay > 0 else {
            AppState.markUserActivity(force: true)
            return
        }

        let defaults = UserDefaults.standard
        let backgroundTimestamp = defaults.double(forKey: autoLockTimestampKey)
        guard backgroundTimestamp > 0 else { return }

        let elapsed = Date().timeIntervalSince1970 - backgroundTimestamp
        if elapsed >= delay {
            isAuthenticated = false
        } else {
            AppState.markUserActivity(force: true)
        }
    }

    private var autoLockDelaySeconds: TimeInterval? {
        let idx = UserDefaults.standard.integer(forKey: "shield.autoLock")
        switch idx {
        case 0: return 0
        case 1: return 60
        case 2: return 5 * 60
        case 3: return 15 * 60
        case 4: return nil
        default: return 0
        }
    }

    private func startInactivityMonitoring() {
        inactivityCheckCancellable = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.applyForegroundInactivityLockIfNeeded()
            }
    }

    private func applyForegroundInactivityLockIfNeeded() {
        guard currentScenePhase == .active else { return }
        guard isOnboarded, isAuthenticated else { return }
        // Keep foreground sessions uninterrupted. Auto-lock is enforced on background/resume.
        // This prevents lock-screen interruptions while actively reviewing or editing documents.
        Self.markUserActivity(force: true)
    }

    // MARK: - Persistence (private)

    private static var appSupportDir: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Shield", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var imagesDir: URL {
        libraryImagesDir
    }

    static var libraryImagesDir: URL {
        let dir = appSupportDir.appendingPathComponent("images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var vaultImagesDir: URL {
        let dir = appSupportDir.appendingPathComponent("vault-images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var librarySourcesDir: URL {
        let dir = appSupportDir.appendingPathComponent("sources", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static var vaultSourcesDir: URL {
        let dir = appSupportDir.appendingPathComponent("vault-sources", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static var docsURL: URL {
        appSupportDir.appendingPathComponent("documents.json")
    }

    private static var categoriesURL: URL {
        appSupportDir.appendingPathComponent("categories.json")
    }

    private static var telemetryURL: URL {
        appSupportDir.appendingPathComponent("telemetry.ndjson")
    }

    private static func createTelemetryFile(at url: URL) -> FileHandle? {
        FileManager.default.createFile(atPath: url.path, contents: nil)
        return FileHandle(forWritingAtPath: url.path)
    }

    static func resolveImageURL(fileName: String, isVaulted: Bool? = nil) -> URL {
        switch isVaulted {
        case true:
            return vaultImagesDir.appendingPathComponent(fileName)
        case false:
            return libraryImagesDir.appendingPathComponent(fileName)
        case nil:
            let vaultURL = vaultImagesDir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: vaultURL.path) { return vaultURL }
            return libraryImagesDir.appendingPathComponent(fileName)
        }
    }

    static func resolveSourceURL(fileName: String, isVaulted: Bool? = nil) -> URL {
        switch isVaulted {
        case true:
            return vaultSourcesDir.appendingPathComponent(fileName)
        case false:
            return librarySourcesDir.appendingPathComponent(fileName)
        case nil:
            let vaultURL = vaultSourcesDir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: vaultURL.path) { return vaultURL }
            return librarySourcesDir.appendingPathComponent(fileName)
        }
    }

    static func loadImage(fileName: String, isVaulted: Bool? = nil) -> UIImage? {
        SecureFileStore.shared.loadImage(from: resolveImageURL(fileName: fileName, isVaulted: isVaulted))
    }

    static func loadSourceData(fileName: String, isVaulted: Bool? = nil) -> Data? {
        try? SecureFileStore.shared.read(from: resolveSourceURL(fileName: fileName, isVaulted: isVaulted))
    }

    private func persistDocuments() {
        if let data = try? JSONEncoder().encode(documents) {
            try? SecureFileStore.shared.write(data, to: AppState.docsURL)
        }
    }

    private func persistCustomCategories() {
        if let data = try? JSONEncoder().encode(customCategories) {
            try? SecureFileStore.shared.write(data, to: AppState.categoriesURL)
        }
    }

    private static func loadDocuments() -> [DocumentItem] {
        if let data = try? SecureFileStore.shared.read(from: docsURL),
           let docs = try? JSONDecoder().decode([DocumentItem].self, from: data) {
            return docs
        }
        guard let data = try? Data(contentsOf: docsURL),
              let docs = try? JSONDecoder().decode([DocumentItem].self, from: data) else {
            return []
        }
        return docs
    }

    private static func loadCustomCategories() -> [UserCategory] {
        // Try encrypted first, fall back to plain (migration path)
        if let data = try? SecureFileStore.shared.read(from: categoriesURL),
           let cats = try? JSONDecoder().decode([UserCategory].self, from: data) {
            return cats
        }
        if let data = try? Data(contentsOf: categoriesURL),
           let cats = try? JSONDecoder().decode([UserCategory].self, from: data) {
            return cats
        }
        return []
    }

    private func moveAssets(for doc: inout DocumentItem, toVault: Bool) {
        let imageFileNames = Set((doc.pageFileNames ?? []) + [doc.imageFileName].compactMap { $0 })
        for fileName in imageFileNames {
            let from = AppState.resolveImageURL(fileName: fileName, isVaulted: doc.isVaulted)
            let to = AppState.resolveImageURL(fileName: fileName, isVaulted: toVault)
            try? SecureFileStore.shared.moveFile(from: from, to: to)
        }
        if let sourceFileName = doc.sourceFileName {
            let from = AppState.resolveSourceURL(fileName: sourceFileName, isVaulted: doc.isVaulted)
            let to = AppState.resolveSourceURL(fileName: sourceFileName, isVaulted: toVault)
            try? SecureFileStore.shared.moveFile(from: from, to: to)
        }
    }
}

// MARK: - Secure storage

enum SecureFileStoreError: Error {
    case invalidCiphertext
    case unexpectedKeyData
}

final class SecureFileStore {
    static let shared = SecureFileStore()

    private let service = "com.romerodev.shield.secure-store"
    private let account = "master-key"
    private let magicHeader = "SHLD1".data(using: .utf8)!

    private init() {}

    func write(_ data: Data, to url: URL) throws {
        let encrypted = magicHeader + (try encrypt(data))
        try encrypted.write(to: url, options: .atomic)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: url.path
        )
    }

    func read(from url: URL) throws -> Data {
        let data = try Data(contentsOf: url)
        guard data.starts(with: magicHeader) else {
            return data
        }
        return try decrypt(Data(data.dropFirst(magicHeader.count)))
    }

    func loadImage(from url: URL) -> UIImage? {
        if let data = try? read(from: url),
           let image = UIImage(data: data) {
            return image
        }
        return UIImage(contentsOfFile: url.path)
    }

    func removeFile(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    func moveFile(from sourceURL: URL, to destinationURL: URL) throws {
        guard sourceURL != destinationURL else { return }
        let dir = destinationURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        if FileManager.default.fileExists(atPath: sourceURL.path) {
            try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
            try FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.complete],
                ofItemAtPath: destinationURL.path
            )
        }
    }

    private func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey())
        guard let combined = sealedBox.combined else {
            throw SecureFileStoreError.invalidCiphertext
        }
        return combined
    }

    private func decrypt(_ data: Data) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: symmetricKey())
    }

    private func symmetricKey() throws -> SymmetricKey {
        if let stored = try KeychainStore.read(service: service, account: account) {
            return SymmetricKey(data: stored)
        }

        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        try KeychainStore.save(
            keyData,
            service: service,
            account: account,
            accessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        )
        return key
    }
}

enum KeychainStore {
    static func save(_ data: Data, service: String, account: String, accessible: CFString) throws {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessible
        ]

        let status = SecItemCopyMatching(baseQuery as CFDictionary, nil)
        if status == errSecSuccess {
            let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw NSError(domain: NSOSStatusErrorDomain, code: Int(updateStatus))
            }
            return
        }

        var addQuery = baseQuery
        attributes.forEach { addQuery[$0.key] = $0.value }
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(addStatus))
        }
    }

    static func read(service: String, account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            return result as? Data
        case errSecItemNotFound:
            return nil
        default:
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    static func delete(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}
