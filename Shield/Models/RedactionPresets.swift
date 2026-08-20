import SwiftUI

// MARK: - RedactionPreset

enum RedactionPreset: String, CaseIterable, Identifiable, Codable, Sendable {
    case rental = "rental"
    case employment = "employment"
    case hotel = "hotel"
    case banking = "banking"

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
        }
    }

    var icon: String {
        switch self {
        case .rental: return "house.fill"
        case .employment: return "briefcase.fill"
        case .hotel: return "bed.double.fill"
        case .banking: return "building.columns.fill"
        }
    }

    var iconColorHex: String {
        switch self {
        case .rental: return "20C7D9"
        case .employment: return "4E7BFF"
        case .hotel: return "FF9F0A"
        case .banking: return "30D158"
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
        }
    }
}
