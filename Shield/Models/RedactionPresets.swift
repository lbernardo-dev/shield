import SwiftUI

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
