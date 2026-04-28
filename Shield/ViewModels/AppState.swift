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
        if lang == .es {
            switch self {
            case .dateDesc: return "Más reciente primero"
            case .dateAsc:  return "Más antiguo primero"
            case .nameAsc:  return "Nombre A→Z"
            case .nameDesc: return "Nombre Z→A"
            }
        } else {
            switch self {
            case .dateDesc: return "Newest first"
            case .dateAsc:  return "Oldest first"
            case .nameAsc:  return "Name A→Z"
            case .nameDesc: return "Name Z→A"
            }
        }
    }
}

// MARK: - AppState

final class AppState: ObservableObject {

    // MARK: - Onboarding (persisted)
    @Published var isOnboarded: Bool {
        didSet { UserDefaults.standard.set(isOnboarded, forKey: "shield.onboarded") }
    }
    @Published var isAuthenticated: Bool = false

    // MARK: - Preferences (persisted)
    @Published var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "shield.language") }
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

    // MARK: - Library
    @Published var documents: [DocumentItem] = []
    @Published var searchQuery: String = ""
    @Published var activeCategory: DocumentCategory = .all
    @Published var activeCategoryID: String = DocumentCategory.all.rawValue  // supports custom too
    @Published var sortOption: SortOption = .dateDesc

    // MARK: - User categories (persisted)
    @Published var customCategories: [UserCategory] = [] {
        didSet { persistCustomCategories() }
    }

    // MARK: - Init

    init() {
        let ud = UserDefaults.standard
        isOnboarded     = ud.bool(forKey: "shield.onboarded")
        language        = AppLanguage(rawValue: ud.string(forKey: "shield.language") ?? "es") ?? .es
        preferredScheme = ud.object(forKey: "shield.darkMode") == nil
            ? .dark
            : (ud.bool(forKey: "shield.darkMode") ? .dark : .light)

        documents = AppState.loadDocuments()
        customCategories = AppState.loadCustomCategories()
    }

    // MARK: - Computed

    var hasActiveFilter: Bool {
        activeCategoryID != DocumentCategory.all.rawValue || !searchQuery.isEmpty
    }

    var filteredDocuments: [DocumentItem] {
        var docs = documents.filter { !$0.isVaulted }

        if activeCategoryID != DocumentCategory.all.rawValue {
            docs = docs.filter { doc in
                if let cid = doc.customCategoryID {
                    return cid == activeCategoryID
                }
                return doc.category.rawValue == activeCategoryID
            }
        }

        if !searchQuery.isEmpty {
            let q = searchQuery.lowercased()
            docs = docs.filter { $0.title.lowercased().contains(q) }
        }

        switch sortOption {
        case .dateDesc: break
        case .dateAsc:  docs = docs.reversed()
        case .nameAsc:  docs = docs.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .nameDesc: docs = docs.sorted { $0.title.localizedCompare($1.title) == .orderedDescending }
        }

        return docs
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

    func str(_ key: L10nKey) -> String { key.string(lang: language) }

    func redactionsCount(_ n: Int) -> String {
        if language == .es {
            return "\(n) \(n == 1 ? "redacción" : "redacciones")"
        } else {
            return "\(n) \(n == 1 ? "redaction" : "redactions")"
        }
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
            try? data.write(to: AppState.categoriesURL, options: .atomic)
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
        guard let data = try? Data(contentsOf: categoriesURL),
              let cats = try? JSONDecoder().decode([UserCategory].self, from: data) else {
            return []
        }
        return cats
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

    private let service = "com.shield.redact.secure-store"
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

// MARK: - Localization keys

enum L10nKey {
    case appName, tagline
    case welcome, welcomeSub, continueBtn, skip
    case setupSecurity, setupSecuritySub
    case enableFaceId, setPin
    case privacyTitle, privacySub
    case onDevice
    case unlock, enterPin, useFaceId
    case library, recents, vault, documents, search, all
    case scan, importDoc, newDocument
    case detectingEdges, holdSteady
    case redact, style, auto, manual, fields, text, watermark
    case done, cancel, apply, save, export, share, undo, redo
    case forVerificationOnly
    case extractedText, fieldsLabel
    case documentNumber, fullName, dateOfBirth, nationality, expires
    case address, issued, sex, mrz, copy, copied
    case exportPDF, exportImage, quality, high, medium, low, keepOriginal
    case locked, autoDetect

    func string(lang: AppLanguage) -> String {
        lang == .es ? esString : enString
    }

    private var esString: String {
        switch self {
        case .appName:           return "Shield"
        case .tagline:           return "Protege lo que compartes."
        case .welcome:           return "Bienvenido a Shield"
        case .welcomeSub:        return "Oculta datos sensibles antes de compartir cualquier documento."
        case .continueBtn:       return "Continuar"
        case .skip:              return "Omitir"
        case .setupSecurity:     return "Configura tu seguridad"
        case .setupSecuritySub:  return "Solo tú podrás abrir Shield."
        case .enableFaceId:      return "Activar Face ID"
        case .setPin:            return "Establecer PIN"
        case .privacyTitle:      return "Todo se queda en tu iPhone"
        case .privacySub:        return "Sin servidores. Sin nube. Sin telemetría. Tus documentos nunca salen del dispositivo a menos que tú los compartas."
        case .onDevice:          return "Procesado en el dispositivo"
        case .unlock:            return "Desbloquear"
        case .enterPin:          return "Introduce tu PIN"
        case .useFaceId:         return "Usar Face ID"
        case .library:           return "Biblioteca"
        case .recents:           return "Recientes"
        case .vault:             return "Bóveda"
        case .documents:         return "Documentos"
        case .search:            return "Buscar"
        case .all:               return "Todos"
        case .scan:              return "Escanear"
        case .importDoc:         return "Importar"
        case .newDocument:       return "Nuevo documento"
        case .detectingEdges:    return "Detectando bordes…"
        case .holdSteady:        return "Mantén firme"
        case .redact:            return "Redactar"
        case .style:             return "Estilo"
        case .auto:              return "Auto"
        case .manual:            return "Manual"
        case .fields:            return "Campos"
        case .text:              return "Texto"
        case .watermark:         return "Marca agua"
        case .done:              return "Hecho"
        case .cancel:            return "Cancelar"
        case .apply:             return "Aplicar"
        case .save:              return "Guardar"
        case .export:            return "Exportar"
        case .share:             return "Compartir"
        case .undo:              return "Deshacer"
        case .redo:              return "Rehacer"
        case .forVerificationOnly: return "Solo para verificación"
        case .extractedText:     return "Texto extraído"
        case .fieldsLabel:       return "Campos detectados"
        case .documentNumber:    return "Número de documento"
        case .fullName:          return "Nombre completo"
        case .dateOfBirth:       return "Fecha de nacimiento"
        case .nationality:       return "Nacionalidad"
        case .expires:           return "Caducidad"
        case .address:           return "Dirección"
        case .issued:            return "Expedido"
        case .sex:               return "Sexo"
        case .mrz:               return "MRZ"
        case .copy:              return "Copiar"
        case .copied:            return "Copiado"
        case .exportPDF:         return "Exportar como PDF"
        case .exportImage:       return "Exportar como imagen"
        case .quality:           return "Calidad"
        case .high:              return "Alta"
        case .medium:            return "Media"
        case .low:               return "Baja"
        case .keepOriginal:      return "Mantener original"
        case .locked:            return "Bloqueado"
        case .autoDetect:        return "Detección automática"
        }
    }

    private var enString: String {
        switch self {
        case .appName:           return "Shield"
        case .tagline:           return "Protect what you share."
        case .welcome:           return "Welcome to Shield"
        case .welcomeSub:        return "Hide sensitive data before you share any document."
        case .continueBtn:       return "Continue"
        case .skip:              return "Skip"
        case .setupSecurity:     return "Set up security"
        case .setupSecuritySub:  return "Only you can open Shield."
        case .enableFaceId:      return "Enable Face ID"
        case .setPin:            return "Set a PIN"
        case .privacyTitle:      return "Everything stays on your iPhone"
        case .privacySub:        return "No servers. No cloud. No telemetry. Your documents never leave the device unless you share them."
        case .onDevice:          return "Processed on-device"
        case .unlock:            return "Unlock"
        case .enterPin:          return "Enter PIN"
        case .useFaceId:         return "Use Face ID"
        case .library:           return "Library"
        case .recents:           return "Recents"
        case .vault:             return "Vault"
        case .documents:         return "Documents"
        case .search:            return "Search"
        case .all:               return "All"
        case .scan:              return "Scan"
        case .importDoc:         return "Import"
        case .newDocument:       return "New document"
        case .detectingEdges:    return "Detecting edges…"
        case .holdSteady:        return "Hold steady"
        case .redact:            return "Redact"
        case .style:             return "Style"
        case .auto:              return "Auto"
        case .manual:            return "Manual"
        case .fields:            return "Fields"
        case .text:              return "Text"
        case .watermark:         return "WM"
        case .done:              return "Done"
        case .cancel:            return "Cancel"
        case .apply:             return "Apply"
        case .save:              return "Save"
        case .export:            return "Export"
        case .share:             return "Share"
        case .undo:              return "Undo"
        case .redo:              return "Redo"
        case .forVerificationOnly: return "Verification only"
        case .extractedText:     return "Extracted text"
        case .fieldsLabel:       return "Detected fields"
        case .documentNumber:    return "Document number"
        case .fullName:          return "Full name"
        case .dateOfBirth:       return "Date of birth"
        case .nationality:       return "Nationality"
        case .expires:           return "Expires"
        case .address:           return "Address"
        case .issued:            return "Issued"
        case .sex:               return "Sex"
        case .mrz:               return "MRZ"
        case .copy:              return "Copy"
        case .copied:            return "Copied"
        case .exportPDF:         return "Export as PDF"
        case .exportImage:       return "Export as image"
        case .quality:           return "Quality"
        case .high:              return "High"
        case .medium:            return "Medium"
        case .low:               return "Low"
        case .keepOriginal:      return "Keep original"
        case .locked:            return "Locked"
        case .autoDetect:        return "Auto-detect"
        }
    }
}
