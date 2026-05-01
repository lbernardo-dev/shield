import SwiftUI

// MARK: - DocumentCategory (built-in)

enum DocumentCategory: String, CaseIterable, Identifiable, Codable {
    case all
    case identity
    case travel
    case driving
    case work
    case health
    case finance

    var id: String { rawValue }

    var localizedLabel: String {
        switch self {
        case .all:      return LanguageManager.shared.model("model_category_all")
        case .identity: return LanguageManager.shared.model("model_category_identity")
        case .travel:   return LanguageManager.shared.model("model_category_travel")
        case .driving:  return LanguageManager.shared.model("model_category_driving")
        case .work:     return LanguageManager.shared.model("model_category_work")
        case .health:   return LanguageManager.shared.model("model_category_health")
        case .finance:  return LanguageManager.shared.model("model_category_finance")
        }
    }

    var icon: String {
        switch self {
        case .all:      return "doc.fill"
        case .identity: return "shield.fill"
        case .travel:   return "airplane"
        case .driving:  return "car.fill"
        case .work:     return "briefcase.fill"
        case .health:   return "heart.fill"
        case .finance:  return "dollarsign.circle.fill"
        }
    }

    func label(lang: AppLanguage) -> String {
        localizedLabel
    }
}

// MARK: - UserCategory (user-created)

struct UserCategory: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var icon: String
    var colorHex: String

    init(id: String = UUID().uuidString, name: String, icon: String, colorHex: String = "FFD60A") {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
    }
}

// MARK: - DocumentRenderer kind

enum DocumentKind: String, Codable {
    case dniESP
    case passportUSA
    case drivingUK
    case photo        // imported photo/scan – rendered from imageFileName
    case passportMEX
    case dniITA
    case genericID
}

enum ImportedDocumentSource: String, Codable {
    case image
    case pdf
}

// MARK: - DocumentFields

struct DocumentFields: Codable {
    var documentNumber: String
    var fullName: String
    var dateOfBirth: String
    var nationality: String
    var expires: String
    var sex: String
    var address: String
    var issued: String?
    var mrz: String?
    var ocrDocumentType: String?
    var ocrFullText: String?
    var ocrPageTexts: [String]?
    var ocrMRZValid: Bool?
    var ocrMRZFormat: String?
    var ocrFieldConfidence: [String: Double]?
    var ocrDetectedCountry: String?
    var ocrRiskLevel: String?
    var ocrLowConfidenceFields: [String]?

    static var empty: DocumentFields {
        DocumentFields(documentNumber: "", fullName: "", dateOfBirth: "",
                       nationality: "", expires: "", sex: "", address: "",
                       issued: nil, mrz: nil,
                       ocrDocumentType: nil, ocrFullText: nil, ocrPageTexts: nil,
                       ocrMRZValid: nil, ocrMRZFormat: nil, ocrFieldConfidence: nil,
                       ocrDetectedCountry: nil, ocrRiskLevel: nil, ocrLowConfidenceFields: nil)
    }
}

// MARK: - FieldBox

struct FieldBox: Identifiable {
    let id = UUID()
    let rect: CGRect   // normalized 0..1
    let label: String
}

// MARK: - Per-page redactions

struct DocumentPageRedactions: Codable, Equatable {
    var pageIndex: Int
    var redactions: [Redaction]
}

// MARK: - DocumentItem

struct DocumentItem: Identifiable, Codable {
    let id: String
    var kind: DocumentKind
    var title: String
    var category: DocumentCategory
    var customCategoryID: String?   // non-nil = user category overrides `category`
    var date: Date
    var redactionCount: Int
    var isFavorite: Bool
    var isLocked: Bool
    var isVaulted: Bool
    var imageFileName: String?      // filename inside shield_images/ dir (page 0 or single image)
    var pageFileNames: [String]?    // all pages for multi-page PDFs; nil = single page
    var sourceType: ImportedDocumentSource
    var sourceFileName: String?
    var fields: DocumentFields
    var pageRedactions: [DocumentPageRedactions]
    var watermark: Watermark?
    var imageAdjustment: ImageAdjustmentStore?

    var pageCount: Int { pageFileNames?.count ?? (imageFileName != nil ? 1 : 0) }
    var totalRedactionCount: Int { pageRedactions.reduce(0) { $0 + $1.redactions.count } }

    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case category
        case customCategoryID
        case date
        case redactionCount
        case isFavorite
        case isLocked
        case isVaulted
        case imageFileName
        case pageFileNames
        case sourceType
        case sourceFileName
        case fields
        case pageRedactions
        case watermark
        case imageAdjustment
    }

    func imageFileName(for page: Int) -> String? {
        if let pages = pageFileNames {
            return pages.indices.contains(page) ? pages[page] : nil
        }
        return page == 0 ? imageFileName : nil
    }

    func redactions(for page: Int) -> [Redaction] {
        pageRedactions.first(where: { $0.pageIndex == page })?.redactions ?? []
    }

    func dateLabelLocalized(lang: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: lang.rawValue)
        return formatter.string(from: date)
    }

    init(id: String = UUID().uuidString,
         kind: DocumentKind,
         title: String,
         category: DocumentCategory = .identity,
         customCategoryID: String? = nil,
         date: Date = Date(),
         redactionCount: Int = 0,
         isFavorite: Bool = false,
         isLocked: Bool = false,
         isVaulted: Bool = false,
         imageFileName: String? = nil,
         pageFileNames: [String]? = nil,
         sourceType: ImportedDocumentSource = .image,
         sourceFileName: String? = nil,
         fields: DocumentFields = .empty,
         pageRedactions: [DocumentPageRedactions] = [],
         watermark: Watermark? = nil,
         imageAdjustment: ImageAdjustmentStore? = nil) {
        self.id = id
        self.kind = kind
        self.title = title
        self.category = category
        self.customCategoryID = customCategoryID
        self.date = date
        self.redactionCount = redactionCount
        self.isFavorite = isFavorite
        self.isLocked = isLocked
        self.isVaulted = isVaulted
        self.imageFileName = imageFileName
        self.pageFileNames = pageFileNames
        self.sourceType = sourceType
        self.sourceFileName = sourceFileName
        self.fields = fields
        self.pageRedactions = pageRedactions
        self.watermark = watermark
        self.imageAdjustment = imageAdjustment
        self.redactionCount = pageRedactions.isEmpty
            ? redactionCount
            : pageRedactions.reduce(0) { $0 + $1.redactions.count }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        kind = try container.decode(DocumentKind.self, forKey: .kind)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decodeIfPresent(DocumentCategory.self, forKey: .category) ?? .identity
        customCategoryID = try container.decodeIfPresent(String.self, forKey: .customCategoryID)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        redactionCount = try container.decodeIfPresent(Int.self, forKey: .redactionCount) ?? 0
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        isVaulted = try container.decodeIfPresent(Bool.self, forKey: .isVaulted) ?? false
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        pageFileNames = try container.decodeIfPresent([String].self, forKey: .pageFileNames)
        sourceType = try container.decodeIfPresent(ImportedDocumentSource.self, forKey: .sourceType) ?? .image
        sourceFileName = try container.decodeIfPresent(String.self, forKey: .sourceFileName)
        fields = try container.decodeIfPresent(DocumentFields.self, forKey: .fields) ?? .empty
        pageRedactions = try container.decodeIfPresent([DocumentPageRedactions].self, forKey: .pageRedactions) ?? []
        watermark = try container.decodeIfPresent(Watermark.self, forKey: .watermark)
        imageAdjustment = try container.decodeIfPresent(ImageAdjustmentStore.self, forKey: .imageAdjustment)

        if !pageRedactions.isEmpty {
            redactionCount = pageRedactions.reduce(0) { $0 + $1.redactions.count }
        }
    }

    mutating func setRedactions(_ redactions: [Redaction], for page: Int) {
        if let index = pageRedactions.firstIndex(where: { $0.pageIndex == page }) {
            if redactions.isEmpty {
                pageRedactions.remove(at: index)
            } else {
                pageRedactions[index].redactions = redactions
            }
        } else if !redactions.isEmpty {
            pageRedactions.append(DocumentPageRedactions(pageIndex: page, redactions: redactions))
            pageRedactions.sort { $0.pageIndex < $1.pageIndex }
        }
        redactionCount = totalRedactionCount
    }

    var localizedDateLabel: String {
        let cal = Calendar.current
        let lang = LanguageManager.shared.current
        if cal.isDateInToday(date) {
            let fmt = DateFormatter()
            fmt.locale = Locale(identifier: lang.rawValue)
            fmt.dateStyle = .none
            fmt.timeStyle = .short
            return LanguageManager.shared.t("common_today_at", table: "Common", args: fmt.string(from: date))
        } else if cal.isDateInYesterday(date) {
            return LanguageManager.shared.common("common_yesterday")
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "d MMM"
            return fmt.string(from: date)
        }
    }
}

// MARK: - ImageAdjustmentStore (Codable persistence companion to ImageAdjustment)

struct ImageAdjustmentStore: Codable, Equatable {
    var brightness: Double
    var contrast: Double
    var saturation: Double
    var sharpness: Double
    var rotation: Double
    var flipHorizontal: Bool
    var flipVertical: Bool
    var cropLeft: Double
    var cropRight: Double
    var cropTop: Double
    var cropBottom: Double
}

// MARK: - Field boxes (normalized 0..1)

enum DocumentFieldBoxes {
    static let dniESP: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.30, y: 0.22, width: 0.22, height: 0.07), label: "Surname 1"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.36, width: 0.22, height: 0.07), label: "Surname 2"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.50, width: 0.18, height: 0.07), label: "Name"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.78, width: 0.18, height: 0.07), label: "Doc №"),
        FieldBox(rect: CGRect(x: 0.62, y: 0.64, width: 0.22, height: 0.07), label: "DOB"),
        FieldBox(rect: CGRect(x: 0.62, y: 0.78, width: 0.22, height: 0.07), label: "Expires"),
        FieldBox(rect: CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55), label: "Photo"),
        FieldBox(rect: CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14), label: "MRZ"),
    ]

    static let passportUSA: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.62, y: 0.22, width: 0.22, height: 0.07), label: "Passport №"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.36, width: 0.30, height: 0.07), label: "Surname"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.50, width: 0.30, height: 0.07), label: "Given names"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.74, width: 0.22, height: 0.07), label: "DOB"),
        FieldBox(rect: CGRect(x: 0.70, y: 0.74, width: 0.24, height: 0.07), label: "Expires"),
        FieldBox(rect: CGRect(x: 0.04, y: 0.20, width: 0.20, height: 0.55), label: "Photo"),
        FieldBox(rect: CGRect(x: 0.00, y: 0.85, width: 1.00, height: 0.15), label: "MRZ"),
    ]

    static let drivingUK: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.36, y: 0.24, width: 0.22, height: 0.07), label: "Surname"),
        FieldBox(rect: CGRect(x: 0.36, y: 0.36, width: 0.22, height: 0.07), label: "Names"),
        FieldBox(rect: CGRect(x: 0.36, y: 0.48, width: 0.22, height: 0.07), label: "DOB"),
        FieldBox(rect: CGRect(x: 0.36, y: 0.72, width: 0.40, height: 0.07), label: "Driver №"),
        FieldBox(rect: CGRect(x: 0.36, y: 0.84, width: 0.55, height: 0.07), label: "Address"),
        FieldBox(rect: CGRect(x: 0.13, y: 0.22, width: 0.20, height: 0.55), label: "Photo"),
    ]

    static let photo: [FieldBox] = []  // no predefined boxes for photo docs

    static func boxes(for kind: DocumentKind) -> [FieldBox] {
        switch kind {
        case .dniESP:       return dniESP
        case .passportUSA:  return passportUSA
        case .drivingUK:    return drivingUK
        case .photo, .passportMEX, .dniITA, .genericID: return photo
        }
    }
}

// MARK: - Auto-suggested redactions

enum AutoRedactions {
    static func suggested(for kind: DocumentKind, style: MaskStyle = .block) -> [Redaction] {
        let rects: [CGRect]
        switch kind {
        case .dniESP:
            rects = [
                CGRect(x: 0.30, y: 0.78, width: 0.20, height: 0.07),   // Doc number
                CGRect(x: 0.62, y: 0.64, width: 0.22, height: 0.07),   // DOB
                CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14),   // MRZ
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),   // Photo
            ]
        case .passportUSA:
            rects = [
                CGRect(x: 0.62, y: 0.22, width: 0.22, height: 0.07),   // Passport №
                CGRect(x: 0.28, y: 0.74, width: 0.22, height: 0.07),   // DOB
                CGRect(x: 0.00, y: 0.85, width: 1.00, height: 0.15),   // MRZ
                CGRect(x: 0.04, y: 0.20, width: 0.20, height: 0.55),   // Photo
            ]
        case .passportMEX:
            rects = [
                CGRect(x: 0.60, y: 0.22, width: 0.24, height: 0.07),
                CGRect(x: 0.28, y: 0.72, width: 0.24, height: 0.07),
                CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14),
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),
            ]
        case .dniITA:
            rects = [
                CGRect(x: 0.30, y: 0.78, width: 0.22, height: 0.07),
                CGRect(x: 0.62, y: 0.62, width: 0.24, height: 0.07),
                CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14),
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),
            ]
        case .drivingUK:
            rects = [
                CGRect(x: 0.36, y: 0.72, width: 0.40, height: 0.07),   // Driver №
                CGRect(x: 0.36, y: 0.84, width: 0.55, height: 0.07),   // Address
                CGRect(x: 0.13, y: 0.22, width: 0.20, height: 0.55),   // Photo
            ]
        case .genericID:
            rects = [
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),   // Photo area
                CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14),   // Bottom strip
            ]
        case .photo:
            rects = []
        }
        return rects.map { Redaction(rect: $0, style: style) }
    }

    // Builds redaction rects for photo/generic docs using OCR detected fields.
    // Each mode hides a different subset of personal data.
    static func ocrModeRects(for mode: RedactionMode, fields: DocumentFields) -> [CGRect] {
        // For photo docs we use approximate grid positions based on common document layouts.
        // These are normalized 0..1 rectangles that cover likely field positions.
        switch mode {
        case .rental:
            // Rental: hide photo zone, address, DOB, doc number — keep name visible
            return [
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),   // photo
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),   // DOB
                CGRect(x: 0.00, y: 0.82, width: 1.00, height: 0.18),   // bottom (address/MRZ)
            ]
        case .travel:
            // Travel: hide doc/passport number and MRZ only
            return [
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),   // doc number
                CGRect(x: 0.00, y: 0.84, width: 1.00, height: 0.16),   // MRZ / barcode
            ]
        case .job:
            // Job application: hide DOB, doc number, photo
            return [
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),   // photo
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),   // DOB
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),   // doc number
            ]
        case .verify:
            // Verification only: hide doc number + MRZ, show name+photo
            return [
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),   // doc number
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),   // DOB
                CGRect(x: 0.00, y: 0.84, width: 1.00, height: 0.16),   // MRZ
            ]
        case .legal:
            // Legal: hide DOB, address, signature, doc number — keep name visible
            return [
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),   // doc number
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),   // DOB
                CGRect(x: 0.00, y: 0.80, width: 1.00, height: 0.10),   // address/issuer
                CGRect(x: 0.00, y: 0.84, width: 1.00, height: 0.16),   // MRZ / signature
            ]
        case .health:
            // Health: hide DOB, SS/insurance number, address, nationality, MRZ
            return [
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),   // photo
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),   // DOB
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),   // insurance/SS number
                CGRect(x: 0.28, y: 0.62, width: 0.68, height: 0.08),   // nationality
                CGRect(x: 0.00, y: 0.84, width: 1.00, height: 0.16),   // MRZ
            ]
        case .banking:
            // Banking: maximum protection — hide everything except name
            return [
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),   // photo
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),   // account/IBAN
                CGRect(x: 0.28, y: 0.52, width: 0.68, height: 0.08),   // expiry/issue date
                CGRect(x: 0.28, y: 0.62, width: 0.68, height: 0.08),   // nationality
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),   // DOB
                CGRect(x: 0.00, y: 0.80, width: 1.00, height: 0.20),   // address/MRZ/signature
            ]
        }
    }
}
