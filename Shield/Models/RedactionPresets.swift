import SwiftUI
import OSLog

// MARK: - RedactionPreset

enum RedactionPreset: String, CaseIterable, Identifiable, Codable, Sendable {
    case rental = "rental"
    case employment = "employment"
    case hotel = "hotel"
    case banking = "banking"
    case marketplace = "marketplace"
    case travel = "travel"
    case school = "school"
    case insurance = "insurance"
    case custom = "custom"

    var id: String { rawValue }

    func title(lang: AppLanguage) -> String {
        switch self {
        case .rental:
            return lang == .es ? "Alquiler / Vivienda" : "Rental & Housing"
        case .employment:
            return lang == .es ? "Empleo / RRHH" : "Job & Employment"
        case .hotel:
            return lang == .es ? "Hotel / Alojamiento" : "Hotel & Check-in"
        case .banking:
            return lang == .es ? "Banca / KYC" : "Banking & KYC"
        case .marketplace:
            return lang == .es ? "Marketplace / Venta" : "Marketplace / Selling"
        case .travel:
            return lang == .es ? "Viajes" : "Travel"
        case .school:
            return lang == .es ? "Colegio / Universidad" : "School / University"
        case .insurance:
            return lang == .es ? "Seguro / Siniestro" : "Insurance / Claim"
        case .custom:
            return lang == .es ? "Personalizada" : "Custom"
        }
    }

    func subtitle(lang: AppLanguage) -> String {
        switch self {
        case .rental:
            return lang == .es ? "Oculta firma, soporte y dirección; añade marca de agua para alquiler." : "Masks signature, serial & address; adds rental watermark."
        case .employment:
            return lang == .es ? "Oculta dirección, firma y familia; mantiene nombre y titulación." : "Masks address, family & signature; keeps name and ID."
        case .hotel:
            return lang == .es ? "Oculta firma, soporte y datos bancarios; marca para hospedaje." : "Masks signature, card/IBAN & serial; adds check-in watermark."
        case .banking:
            return lang == .es ? "Conserva DNI y nombre; oculta datos de terceros y firma." : "Keeps ID & name; masks unrelated sensitive fields."
        case .marketplace:
            return lang == .es ? "Comparte lo necesario para vender; oculta identidad, contacto y pago." : "Share what a buyer needs; hide identity, contact and payment data."
        case .travel:
            return lang == .es ? "Mantén nombre y vigencia; oculta números, fecha de nacimiento y códigos." : "Keep name and validity; hide numbers, date of birth and codes."
        case .school:
            return lang == .es ? "Oculta dirección, contacto, fecha de nacimiento y números de documento." : "Hide address, contact, date of birth and document numbers."
        case .insurance:
            return lang == .es ? "Prepara una copia para el expediente; revisa cada dato sensible." : "Prepare a claim copy; review every sensitive field."
        case .custom:
            return lang == .es ? "Elige manualmente qué necesita realmente el receptor." : "Choose manually what the recipient actually needs."
        }
    }

    var icon: String {
        switch self {
        case .rental: return "house.fill"
        case .employment: return "briefcase.fill"
        case .hotel: return "bed.double.fill"
        case .banking: return "building.columns.fill"
        case .marketplace: return "tag.fill"
        case .travel: return "airplane"
        case .school: return "graduationcap.fill"
        case .insurance: return "cross.case.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    var iconColorHex: String {
        switch self {
        case .rental: return "20C7D9"
        case .employment: return "4E7BFF"
        case .hotel: return "FF9F0A"
        case .banking: return "30D158"
        case .marketplace: return "FF9F0A"
        case .travel: return "64D2FF"
        case .school: return "BF5AF2"
        case .insurance: return "FF375F"
        case .custom: return "8E8E93"
        }
    }

    func defaultWatermarkText(lang: AppLanguage) -> String {
        switch self {
        case .rental:
            return lang == .es ? "Solo para verificación de alquiler" : "For rental verification only"
        case .employment:
            return lang == .es ? "Copia para proceso de selección" : "For job application review only"
        case .hotel:
            return lang == .es ? "Solo para registro de alojamiento" : "For hotel check-in only"
        case .banking:
            return lang == .es ? "Para verificación de cuenta bancaria" : "For account verification only"
        case .marketplace:
            return lang == .es ? "Copia para esta venta" : "Copy for this sale"
        case .travel:
            return lang == .es ? "Copia para esta reserva de viaje" : "Copy for this travel booking"
        case .school:
            return lang == .es ? "Copia para gestión escolar" : "Copy for school administration"
        case .insurance:
            return lang == .es ? "Copia para gestión del seguro" : "Copy for insurance claim"
        case .custom:
            return lang == .es ? "Copia para el destinatario indicado" : "Copy for intended recipient"
        }
    }

    /// Entities that should be masked for this preset
    var maskedEntities: Set<OCRSensitiveEntityKind> {
        switch self {
        case .rental:
            return [.supportNumber, .address, .phoneNumber, .email, .iban, .paymentCard, .barcode]
        case .employment:
            return [.supportNumber, .address, .iban, .paymentCard, .dateOfBirth, .barcode]
        case .hotel:
            return [.supportNumber, .iban, .paymentCard, .address, .barcode]
        case .banking:
            return [.supportNumber, .paymentCard, .address, .barcode]
        case .marketplace:
            return [.documentNumber, .supportNumber, .fullName, .address, .phoneNumber, .email, .dateOfBirth, .iban, .paymentCard, .barcode, .mrz]
        case .travel:
            return [.documentNumber, .supportNumber, .dateOfBirth, .address, .phoneNumber, .email, .iban, .paymentCard, .barcode, .mrz]
        case .school:
            return [.documentNumber, .supportNumber, .address, .phoneNumber, .email, .dateOfBirth, .iban, .paymentCard, .barcode, .mrz]
        case .insurance:
            return [.documentNumber, .supportNumber, .address, .phoneNumber, .email, .dateOfBirth, .iban, .paymentCard, .barcode, .mrz]
        case .custom:
            return []
        }
    }
}

struct CustomProtectionProfile: Codable, Equatable, Sendable {
    var name: String
    var maskedEntityValues: [String]
    var maskStyleRawValue: String? = nil
    var appliesWatermark: Bool? = nil
    var watermarkText: String? = nil
    var preferredOutputFormatRawValue: String? = nil

    var maskedEntities: Set<OCRSensitiveEntityKind> {
        Set(maskedEntityValues.compactMap { OCRSensitiveEntityKind(rawValue: $0) })
    }

    var maskStyle: MaskStyle {
        guard let maskStyleRawValue, let style = MaskStyle(rawValue: maskStyleRawValue), !style.isPremium else {
            return .block
        }
        return style
    }

    var shouldApplyWatermark: Bool { appliesWatermark ?? true }
    var preferredOutputFormat: ProtectionProfileOutputFormat {
        guard let preferredOutputFormatRawValue,
              let format = ProtectionProfileOutputFormat(rawValue: preferredOutputFormatRawValue) else {
            return .pdf
        }
        return format
    }

    mutating func setMasked(_ isMasked: Bool, kind: OCRSensitiveEntityKind) {
        var values = maskedEntities
        if isMasked {
            values.insert(kind)
        } else {
            values.remove(kind)
        }
        maskedEntityValues = values.map(\.rawValue).sorted()
    }

    static let privacyFirst = CustomProtectionProfile(
        name: "Custom",
        maskedEntityValues: Set([
            OCRSensitiveEntityKind.documentNumber,
            .supportNumber,
            .dateOfBirth,
            .address,
            .mrz,
            .email,
            .phoneNumber,
            .iban,
            .paymentCard,
            .barcode
        ]).map(\.rawValue).sorted()
    )

    static func newProfile(name: String) -> CustomProtectionProfile {
        var profile = privacyFirst
        profile.name = name
        return profile
    }
}

enum ProtectionProfileOutputFormat: String, Codable, CaseIterable, Hashable, Sendable {
    case pdf
    case image
}

enum ProtectionProfileStore {
    private static let storageKey = "shield.protection.customProfiles.v2"
    private static let legacyStorageKey = "shield.protection.customProfile.v1"
    private static let activeProfileNameKey = "shield.protection.activeCustomProfileName.v1"
    private static let logger = Logger(subsystem: "com.romerodev.shield", category: "ProtectionProfileStore")

    private struct State: Codable {
        var profiles: [CustomProtectionProfile]
        var activeProfileName: String
    }

    private static var encryptedStoreURL: URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Shield", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("protection-profiles.secure")
    }

    static func load() -> CustomProtectionProfile {
        do {
            let state = try loadState()
            return state.profiles.first(where: { $0.name == state.activeProfileName }) ?? state.profiles[0]
        } catch {
            logger.error("Unable to load protection profiles: \(error.localizedDescription, privacy: .private)")
            return .privacyFirst
        }
    }

    static func loadProfiles() -> [CustomProtectionProfile] {
        do {
            return try loadState().profiles
        } catch {
            logger.error("Unable to load protection profiles: \(error.localizedDescription, privacy: .private)")
            return [.privacyFirst]
        }
    }

    @discardableResult
    static func save(
        _ profile: CustomProtectionProfile,
        replacingName: String? = nil,
        activateOnSave: Bool? = nil
    ) throws -> CustomProtectionProfile {
        var state = try loadState()
        var profiles = state.profiles
        if let replacingName {
            profiles.removeAll { $0.name == replacingName }
        }

        var savedProfile = profile
        if profiles.contains(where: { $0.name == savedProfile.name }) {
            var suffix = 2
            let baseName = savedProfile.name
            while profiles.contains(where: { $0.name == "\(baseName) (\(suffix))" }) {
                suffix += 1
            }
            savedProfile.name = "\(baseName) (\(suffix))"
        }
        profiles.append(savedProfile)
        state.profiles = profiles
        let shouldActivate = activateOnSave
            ?? (replacingName == nil || state.activeProfileName == replacingName)
        if shouldActivate {
            state.activeProfileName = savedProfile.name
        }
        try persist(state)
        return savedProfile
    }

    @discardableResult
    static func duplicate(_ profile: CustomProtectionProfile, lang: AppLanguage) throws -> CustomProtectionProfile {
        var copy = profile
        copy.name += lang == .es ? " · copia" : " · copy"
        return try save(copy, activateOnSave: false)
    }

    static func setActive(_ profile: CustomProtectionProfile) throws {
        var state = try loadState()
        guard state.profiles.contains(where: { $0.name == profile.name }) else { return }
        state.activeProfileName = profile.name
        try persist(state)
    }

    static func delete(name: String) throws {
        var state = try loadState()
        state.profiles.removeAll { $0.name == name }
        if state.profiles.isEmpty { state.profiles = [.privacyFirst] }
        if state.activeProfileName == name {
            state.activeProfileName = state.profiles[0].name
        }
        try persist(state)
    }

    private static func loadState() throws -> State {
        let fileURL = encryptedStoreURL
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                guard SecureFileStore.shared.isEncryptedFile(at: fileURL) else {
                    throw SecureFileStoreError.invalidCiphertext
                }
                let data = try SecureFileStore.shared.read(from: fileURL)
                let state = try JSONDecoder().decode(State.self, from: data)
                guard !state.profiles.isEmpty else { throw SecureFileStoreError.invalidCiphertext }
                removeLegacyDefaults()
                return normalized(state)
            } catch {
                logger.error("Unable to read encrypted protection profiles: \(error.localizedDescription, privacy: .private)")
                throw error
            }
        }

        let defaults = UserDefaults.standard
        let migratedProfiles: [CustomProtectionProfile]
        if let data = defaults.data(forKey: storageKey),
           let profiles = try? JSONDecoder().decode([CustomProtectionProfile].self, from: data),
           !profiles.isEmpty {
            migratedProfiles = profiles
        } else if let data = defaults.data(forKey: legacyStorageKey),
                  let profile = try? JSONDecoder().decode(CustomProtectionProfile.self, from: data) {
            migratedProfiles = [profile]
        } else {
            return State(profiles: [.privacyFirst], activeProfileName: CustomProtectionProfile.privacyFirst.name)
        }

        let state = normalized(State(
            profiles: migratedProfiles,
            activeProfileName: defaults.string(forKey: activeProfileNameKey) ?? migratedProfiles[0].name
        ))
        do {
            try persist(state)
            removeLegacyDefaults()
        } catch {
            logger.error("Unable to migrate legacy protection profiles to encrypted storage: \(error.localizedDescription, privacy: .private)")
            throw error
        }
        return state
    }

    private static func normalized(_ state: State) -> State {
        let profiles = state.profiles.isEmpty ? [.privacyFirst] : state.profiles
        let activeName = profiles.contains(where: { $0.name == state.activeProfileName })
            ? state.activeProfileName
            : profiles[0].name
        return State(profiles: profiles, activeProfileName: activeName)
    }

    private static func persist(_ state: State) throws {
        let normalizedState = normalized(state)
        let data = try JSONEncoder().encode(normalizedState)
        let fileURL = encryptedStoreURL
        try SecureFileStore.shared.write(data, to: fileURL)
        guard SecureFileStore.shared.isEncryptedFile(at: fileURL),
              try SecureFileStore.shared.read(from: fileURL) == data else {
            throw SecureFileStoreError.invalidCiphertext
        }
    }

    private static func removeLegacyDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: storageKey)
        defaults.removeObject(forKey: legacyStorageKey)
        defaults.removeObject(forKey: activeProfileNameKey)
    }
}

extension OCRSensitiveEntityKind {
    func title(lang: AppLanguage) -> String {
        switch self {
        case .documentNumber: lang == .es ? "Número de documento" : "Document number"
        case .supportNumber: lang == .es ? "Número de soporte" : "Support number"
        case .fullName: lang == .es ? "Nombre completo" : "Full name"
        case .dateOfBirth: lang == .es ? "Fecha de nacimiento" : "Date of birth"
        case .nationality: lang == .es ? "Nacionalidad" : "Nationality"
        case .expirationDate: lang == .es ? "Fecha de caducidad" : "Expiry date"
        case .address: lang == .es ? "Dirección" : "Address"
        case .mrz: lang == .es ? "Zona de lectura mecánica" : "Machine-readable zone"
        case .email: "Email"
        case .phoneNumber: lang == .es ? "Teléfono" : "Phone number"
        case .iban: "IBAN"
        case .paymentCard: lang == .es ? "Tarjeta de pago" : "Payment card"
        case .barcode: lang == .es ? "Código de barras / QR" : "Barcode / QR code"
        }
    }
}
