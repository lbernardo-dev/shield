import SwiftUI
import Combine
import CryptoKit
import Security
import UIKit

#if DEBUG
enum ASOScreenshotMode {
    static let isEnabled = ProcessInfo.processInfo.arguments.contains("-aso-screenshots")

    static var scene: String {
        value(after: "-aso-scene") ?? "home"
    }

    static var language: AppLanguage {
        AppLanguage(rawValue: value(after: "-aso-language") ?? "es") ?? .es
    }

    private static func value(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }
}
#endif

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
    private let session: AppSessionCoordinator
    private var cancellables = Set<AnyCancellable>()

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
    @Published var pendingSharedImportURL: URL? = nil
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
        session = AppSessionCoordinator(userDefaults: ud)
        // Language is handled by LanguageManager.shared
        preferredScheme = ud.object(forKey: "shield.darkMode") == nil
            ? .dark
            : (ud.bool(forKey: "shield.darkMode") ? .dark : .light)

        documents = AppState.loadDocuments()
        customCategories = AppState.loadCustomCategories()

#if DEBUG
        if ASOScreenshotMode.isEnabled {
            LanguageManager.shared.current = ASOScreenshotMode.language
            preferredScheme = .dark
            session.isOnboarded = true
            session.isAuthenticated = true
            documents = Self.asoSampleDocuments(language: ASOScreenshotMode.language)

            switch ASOScreenshotMode.scene {
            case "capture":
                showCapture = true
            case "editor", "ocr", "export":
                selectedDoc = documents.first
            case "gallery":
                activeTab = .gallery
            case "vault":
                activeTab = .vault
            case "settings":
                activeTab = .settings
            default:
                activeTab = .library
            }
        }
#endif
        bindSession()
    }

#if DEBUG
    private static func asoSampleDocuments(language: AppLanguage) -> [DocumentItem] {
        var identityFields = DocumentFields.empty
        identityFields.documentNumber = "X1234567T"
        identityFields.supportNumber = "SYN123456"
        identityFields.fullName = language == .es ? "MARÍA GARCÍA LÓPEZ" : "ALEX MORGAN"
        identityFields.dateOfBirth = "14/03/1990"
        identityFields.nationality = language == .es ? "ESPAÑOLA" : "SPANISH"
        identityFields.expires = "12/11/2031"
        identityFields.sex = "F"
        identityFields.address = language == .es ? "CALLE EJEMPLO 24, MADRID" : "24 SAMPLE STREET, MADRID"
        identityFields.mrz = "IDESPX1234567T<<<<<<<<<<<<<<<"
        identityFields.ocrDocumentType = "DNI"
        identityFields.ocrMRZValid = true
        identityFields.ocrRiskLevel = "low"
        identityFields.ocrDetectedCountry = "ESP"
        identityFields.ocrFieldConfidence = [
            "documentNumber": 0.98,
            "fullName": 0.97,
            "dateOfBirth": 0.96,
            "address": 0.94,
            "mrz": 0.99
        ]

        let identityRedactions = AutoRedactions.suggested(for: .dniESP, style: .secure)
        let now = Date()
        let titles: [(String, String)] = [
            ("DNI — copia protegida", "ID card — protected copy"),
            ("Pasaporte — viaje", "Passport — travel"),
            ("Contrato de alquiler", "Rental agreement"),
            ("Nómina — abril", "Payslip — April"),
            ("Extracto bancario", "Bank statement"),
            ("Informe médico", "Medical report")
        ]

        return [
            DocumentItem(
                id: "aso-identity",
                kind: .dniESP,
                title: language == .es ? titles[0].0 : titles[0].1,
                category: .identity,
                date: now,
                isFavorite: true,
                pageFileNames: ["aso-id-front", "aso-id-back"],
                fields: identityFields,
                pageRedactions: [DocumentPageRedactions(pageIndex: 0, redactions: identityRedactions)],
                watermark: Watermark(text: language == .es ? "COPIA PROTEGIDA" : "PROTECTED COPY")
            ),
            DocumentItem(
                id: "aso-passport",
                kind: .passportUSA,
                title: language == .es ? titles[1].0 : titles[1].1,
                category: .travel,
                date: now.addingTimeInterval(-3_600),
                redactionCount: 7,
                isVaulted: true,
                pageFileNames: ["aso-passport"]
            ),
            DocumentItem(
                id: "aso-rental",
                kind: .genericID,
                title: language == .es ? titles[2].0 : titles[2].1,
                category: .work,
                date: now.addingTimeInterval(-86_400),
                redactionCount: 9,
                pageFileNames: ["aso-rental-1", "aso-rental-2", "aso-rental-3"]
            ),
            DocumentItem(
                id: "aso-payslip",
                kind: .dniITA,
                title: language == .es ? titles[3].0 : titles[3].1,
                category: .work,
                date: now.addingTimeInterval(-172_800),
                redactionCount: 6,
                isFavorite: true,
                pageFileNames: ["aso-payslip"]
            ),
            DocumentItem(
                id: "aso-bank",
                kind: .drivingUK,
                title: language == .es ? titles[4].0 : titles[4].1,
                category: .finance,
                date: now.addingTimeInterval(-259_200),
                redactionCount: 8,
                isVaulted: true,
                pageFileNames: ["aso-bank-1", "aso-bank-2"]
            ),
            DocumentItem(
                id: "aso-medical",
                kind: .passportMEX,
                title: language == .es ? titles[5].0 : titles[5].1,
                category: .health,
                date: now.addingTimeInterval(-345_600),
                redactionCount: 5,
                pageFileNames: ["aso-medical"]
            )
        ]
    }
#endif

    // MARK: - Computed

    var isOnboarded: Bool {
        get { session.isOnboarded }
        set { session.isOnboarded = newValue }
    }

    var isAuthenticated: Bool {
        get { session.isAuthenticated }
        set { session.isAuthenticated = newValue }
    }

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
        for fileName in doc.allImageFileNames {
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

    @discardableResult
    func toggleVault(_ doc: DocumentItem) -> Bool {
        var d = doc
        guard relocateAssetsTransactionally(for: d, toVault: !doc.isVaulted) else {
            return false
        }
        d.isVaulted.toggle()
        updateDocument(d)
        return true
    }

    func deleteAllDocuments() {
        for doc in documents {
            for fileName in doc.allImageFileNames {
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

    func removeStoredImage(fileName: String, isVaulted: Bool = false) {
        SecureFileStore.shared.removeFile(
            at: AppState.resolveImageURL(fileName: fileName, isVaulted: isVaulted)
        )
    }

    func removeStoredSource(fileName: String, isVaulted: Bool = false) {
        SecureFileStore.shared.removeFile(
            at: AppState.resolveSourceURL(fileName: fileName, isVaulted: isVaulted)
        )
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
        AppSessionCoordinator.markUserActivity(force: force)
    }

    func completeSuccessfulUnlock() {
        session.completeSuccessfulUnlock()
    }

    static func trackEvent(_ name: String, properties: [String: String] = [:]) {
        let safeName = sanitizedTelemetryValue(name)
        let allowedKeys: Set<String> = [
            "source", "format", "pages", "redactions", "count", "kind", "mode",
            "method", "risk", "low_fields", "detected_type", "mrz_valid",
            "has_adjustments", "product_id", "trigger", "reason", "error_type"
        ]
        let safeProperties = properties.reduce(into: [String: String]()) { result, item in
            guard allowedKeys.contains(item.key) else { return }
            result[item.key] = sanitizedTelemetryValue(item.value)
        }
        var payload: [String: Any] = safeProperties
        payload["event"] = safeName
        payload["timestamp"] = ISO8601DateFormatter().string(from: Date())
        payload["build"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

        guard JSONSerialization.isValidJSONObject(payload),
              let line = try? JSONSerialization.data(withJSONObject: payload, options: [])
        else {
            return
        }

        var log = (try? SecureFileStore.shared.read(from: telemetryURL)) ?? Data()
        log.append(line)
        log.append(0x0A)
        let maximumBytes = 512 * 1_024
        if log.count > maximumBytes {
            let suffix = log.suffix(maximumBytes)
            if let firstLineBreak = suffix.firstIndex(of: 0x0A) {
                log = Data(suffix[suffix.index(after: firstLineBreak)...])
            } else {
                log = Data(suffix)
            }
        }
        try? SecureFileStore.shared.write(log, to: telemetryURL)

    }

    func redactionsCount(_ n: Int) -> String {
        LanguageManager.shared.t("common_redactions_count", table: "Common", args: n)
    }

    // MARK: - App lifecycle / auto-lock

    func handleScenePhaseChange(_ phase: ScenePhase) {
        session.handleScenePhaseChange(phase)
    }

    // MARK: - Persistence (private)

    private func bindSession() {
        session.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

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

    private static func sanitizedTelemetryValue(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._,-"))
        let scalars = value.unicodeScalars.filter { allowed.contains($0) }.prefix(64)
        return String(String.UnicodeScalarView(scalars))
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
            return docs.map { document in
                var migrated = document
                migrated.migrateToCurrentSchema()
                return migrated
            }
        }
        guard let data = try? Data(contentsOf: docsURL),
              let docs = try? JSONDecoder().decode([DocumentItem].self, from: data) else {
            return []
        }
        return docs.map { document in
            var migrated = document
            migrated.migrateToCurrentSchema()
            return migrated
        }
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

    private func relocateAssetsTransactionally(for doc: DocumentItem, toVault: Bool) -> Bool {
        var pairs = doc.allImageFileNames.map { fileName in
            (
                AppState.resolveImageURL(fileName: fileName, isVaulted: doc.isVaulted),
                AppState.resolveImageURL(fileName: fileName, isVaulted: toVault)
            )
        }
        if let sourceFileName = doc.sourceFileName {
            pairs.append((
                AppState.resolveSourceURL(fileName: sourceFileName, isVaulted: doc.isVaulted),
                AppState.resolveSourceURL(fileName: sourceFileName, isVaulted: toVault)
            ))
        }

        var createdDestinations: [URL] = []
        do {
            for (source, destination) in pairs {
                guard FileManager.default.fileExists(atPath: source.path) else { continue }
                try SecureFileStore.shared.copyFile(from: source, to: destination)
                createdDestinations.append(destination)
            }
            for (source, _) in pairs {
                SecureFileStore.shared.removeFile(at: source)
            }
            return true
        } catch {
            createdDestinations.forEach(SecureFileStore.shared.removeFile(at:))
            return false
        }
    }
}

// MARK: - Secure storage

enum SecureFileStoreError: Error {
    case invalidCiphertext
    case unexpectedKeyData
}

final class SecureFileStore: Sendable {
    static let shared = SecureFileStore()

    private let service = "com.romerodev.shield.secure-store"
    private let libraryKeyAccount = "master-key"
    private let vaultKeyAccount = "vault-master-key"
    private let magicHeader = "SHLD1".data(using: .utf8)!

    private init() {}

    func write(_ data: Data, to url: URL) throws {
        let encrypted = magicHeader + (try encrypt(data, for: url))
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
        let ciphertext = Data(data.dropFirst(magicHeader.count))
        do {
            return try decrypt(ciphertext, for: url)
        } catch {
            // Existing vault files from schema v1 used the library key. Read
            // them once so the next move/write transparently re-encrypts them.
            guard isVaultURL(url) else { throw error }
            return try decrypt(ciphertext, account: libraryKeyAccount)
        }
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
        guard FileManager.default.fileExists(atPath: sourceURL.path) else { return }
        let plaintext = try read(from: sourceURL)
        try FileManager.default.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try write(plaintext, to: destinationURL)
        try FileManager.default.removeItem(at: sourceURL)
    }

    func copyFile(from sourceURL: URL, to destinationURL: URL) throws {
        guard sourceURL != destinationURL else { return }
        guard FileManager.default.fileExists(atPath: sourceURL.path) else { return }
        let plaintext = try read(from: sourceURL)
        try FileManager.default.createDirectory(
            at: destinationURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try write(plaintext, to: destinationURL)
    }

    private func encrypt(_ data: Data, for url: URL) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey(for: url))
        guard let combined = sealedBox.combined else {
            throw SecureFileStoreError.invalidCiphertext
        }
        return combined
    }

    private func decrypt(_ data: Data, for url: URL) throws -> Data {
        try decrypt(data, account: keyAccount(for: url))
    }

    private func decrypt(_ data: Data, account: String) throws -> Data {
        let box = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(box, using: symmetricKey(account: account))
    }

    private func symmetricKey(for url: URL) throws -> SymmetricKey {
        try symmetricKey(account: keyAccount(for: url))
    }

    private func symmetricKey(account: String) throws -> SymmetricKey {
        if let stored = try KeychainStore.read(service: service, account: account) {
            return SymmetricKey(data: stored)
        }

        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        try KeychainStore.save(
            keyData,
            service: service,
            account: account,
            accessible: account == vaultKeyAccount
                ? kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
                : kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        )
        return key
    }

    private func keyAccount(for url: URL) -> String {
        isVaultURL(url) ? vaultKeyAccount : libraryKeyAccount
    }

    private func isVaultURL(_ url: URL) -> Bool {
        url.pathComponents.contains("vault-images") || url.pathComponents.contains("vault-sources")
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
