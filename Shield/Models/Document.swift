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
        case .all:      return "doc.on.doc.fill"
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
    var supportNumber: String?   // NUM SOPORTE (Spanish DNI serial, e.g. CJU127354)
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
    /// Vision-detected text observations on page 0: [text: normalizedBoundingRect]
    /// Stored as parallel arrays (text[i] corresponds to rect[i]) for Codable simplicity.
    var ocrBoundingTexts: [String]?
    var ocrBoundingRects: [CGRect]?

    static var empty: DocumentFields {
        DocumentFields(documentNumber: "", fullName: "", dateOfBirth: "",
                       nationality: "", expires: "", sex: "", address: "",
                       issued: nil, mrz: nil,
                       ocrDocumentType: nil, ocrFullText: nil, ocrPageTexts: nil,
                       ocrMRZValid: nil, ocrMRZFormat: nil, ocrFieldConfidence: nil,
                       ocrDetectedCountry: nil, ocrRiskLevel: nil, ocrLowConfidenceFields: nil,
                       ocrBoundingTexts: nil, ocrBoundingRects: nil)
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

    static let passportMEX: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.60, y: 0.22, width: 0.24, height: 0.07), label: "Passport №"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.36, width: 0.30, height: 0.07), label: "Apellido(s)"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.50, width: 0.30, height: 0.07), label: "Nombre(s)"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.64, width: 0.22, height: 0.07), label: "Nacimiento"),
        FieldBox(rect: CGRect(x: 0.70, y: 0.72, width: 0.24, height: 0.07), label: "Vence"),
        FieldBox(rect: CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55), label: "Foto"),
        FieldBox(rect: CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14), label: "MRZ"),
    ]

    static let dniITA: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.30, y: 0.22, width: 0.22, height: 0.07), label: "Cognome"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.36, width: 0.22, height: 0.07), label: "Nome"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.50, width: 0.18, height: 0.07), label: "Comune"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.78, width: 0.18, height: 0.07), label: "N° documento"),
        FieldBox(rect: CGRect(x: 0.62, y: 0.62, width: 0.24, height: 0.07), label: "Nascita"),
        FieldBox(rect: CGRect(x: 0.62, y: 0.76, width: 0.22, height: 0.07), label: "Scadenza"),
        FieldBox(rect: CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55), label: "Foto"),
        FieldBox(rect: CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14), label: "MRZ"),
    ]

    static let genericID: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.30, y: 0.22, width: 0.22, height: 0.07), label: "Surname"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.36, width: 0.22, height: 0.07), label: "Name"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.78, width: 0.18, height: 0.07), label: "Doc №"),
        FieldBox(rect: CGRect(x: 0.62, y: 0.64, width: 0.22, height: 0.07), label: "DOB"),
        FieldBox(rect: CGRect(x: 0.62, y: 0.78, width: 0.22, height: 0.07), label: "Expires"),
        FieldBox(rect: CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55), label: "Photo"),
        FieldBox(rect: CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14), label: "MRZ"),
    ]

    static func boxes(for kind: DocumentKind) -> [FieldBox] {
        switch kind {
        case .dniESP:      return dniESP
        case .passportUSA: return passportUSA
        case .drivingUK:   return drivingUK
        case .passportMEX: return passportMEX
        case .dniITA:      return dniITA
        case .genericID:   return genericID
        case .photo:       return photo
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

    // Builds redaction rects for photo/generic docs.
    // When Vision bounding boxes are stored in `fields`, uses precise per-word positions.
    // Falls back to calibrated grid estimates when boxes are unavailable.
    static func ocrModeRects(for mode: RedactionMode, fields: DocumentFields) -> [CGRect] {
        let fallbackRects = gridRects(for: mode)
        // Try precision mode first: match stored OCR observations against sensitive field values.
        if let preciseRects = precisionRects(for: mode, fields: fields), !preciseRects.isEmpty {
            // If OCR found too few zones, blend with fallback so obvious PII is still covered.
            if preciseRects.count < max(2, fallbackRects.count / 2) {
                return mergeRects(preciseRects + fallbackRects)
            }
            return mergeRects(preciseRects)
        }
        return fallbackRects
    }

    /// Returns ONLY bounding-box-derived rects for `mode`, with no grid fallback.
    /// Returns an empty array when Vision OCR did not detect the required fields.
    /// Use this for photo/genericID documents where grid zones would be meaningless.
    static func ocrPrecisionModeRects(for mode: RedactionMode, fields: DocumentFields) -> [CGRect] {
        guard let precise = precisionRects(for: mode, fields: fields), !precise.isEmpty else {
            return []
        }
        return mergeRects(precise)
    }

    // Precision: locate actual field text in Vision bounding boxes and expand slightly for coverage.
    private static func precisionRects(for mode: RedactionMode, fields: DocumentFields) -> [CGRect]? {
        guard let texts = fields.ocrBoundingTexts,
              let rects = fields.ocrBoundingRects,
              texts.count == rects.count,
              !texts.isEmpty else { return nil }

        struct OCRToken {
            let raw: String
            let normalized: String
            let compact: String
            let rect: CGRect
        }

        func normalize(_ value: String) -> String {
            let folded = value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let filtered = folded.replacingOccurrences(of: "[^A-Za-z0-9 ]+", with: " ", options: .regularExpression)
            return filtered
                .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .uppercased()
        }

        let tokens: [OCRToken] = zip(texts, rects).map { text, rect in
            let normalized = normalize(text)
            return OCRToken(
                raw: text,
                normalized: normalized,
                compact: normalized.replacingOccurrences(of: " ", with: ""),
                rect: rect
            )
        }

        // Sensitive field values to search for, keyed by semantic name
        var sensitiveValues: [String: String] = [:]
        if !fields.documentNumber.isEmpty { sensitiveValues["docNumber"]     = fields.documentNumber.uppercased() }
        if let sn = fields.supportNumber, !sn.isEmpty { sensitiveValues["supportNumber"] = sn.uppercased() }
        if !fields.dateOfBirth.isEmpty    { sensitiveValues["dob"]           = fields.dateOfBirth.uppercased() }
        if !fields.expires.isEmpty        { sensitiveValues["expires"]       = fields.expires.uppercased() }
        if !fields.fullName.isEmpty       { sensitiveValues["name"]          = fields.fullName.uppercased() }
        if !fields.nationality.isEmpty    { sensitiveValues["nat"]           = fields.nationality.uppercased() }
        if let mrz = fields.mrz, !mrz.isEmpty {
            sensitiveValues["mrz"] = mrz.uppercased().components(separatedBy: "\n").first ?? ""
        }
        if !fields.address.isEmpty        { sensitiveValues["address"]       = fields.address.uppercased() }

        // Pad a rect slightly so it fully covers the glyph
        func pad(_ r: CGRect) -> CGRect {
            let dx = max(0.005, r.width  * 0.08)
            let dy = max(0.004, r.height * 0.20)
            return r.insetBy(dx: -dx, dy: -dy).intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
        }

        func mergeForMultiline(_ rects: [CGRect]) -> [CGRect] {
            guard !rects.isEmpty else { return [] }
            if rects.count == 1 { return rects }
            let union = rects.dropFirst().reduce(rects[0]) { $0.union($1) }
            return [union]
        }

        // Finds matching OCR rectangles for a field value.
        // Uses compact comparison so values like "12345678A" match OCR "1234 5678 A".
        func findRects(for value: String, mergeMultiline: Bool = false) -> [CGRect] {
            let normalizedValue = normalize(value)
            let compactValue = normalizedValue.replacingOccurrences(of: " ", with: "")
            guard !compactValue.isEmpty else { return [] }

            var matches: [CGRect] = []
            for token in tokens {
                guard !token.compact.isEmpty else { continue }
                let exact = token.compact == compactValue
                let included = token.compact.count >= 4 && compactValue.contains(token.compact)
                if exact || included {
                    matches.append(token.rect)
                }
            }

            if mergeMultiline {
                return mergeForMultiline(matches)
            }
            return matches
        }

        // Which semantic fields each mode needs to hide
        let hideKeys: [String]
        switch mode {
        case .rental:  hideKeys = ["docNumber", "supportNumber", "dob", "expires", "address", "mrz"]
        case .travel:  hideKeys = ["docNumber", "supportNumber", "expires", "mrz"]
        case .job:     hideKeys = ["docNumber", "supportNumber", "dob", "nat"]
        case .verify:  hideKeys = ["docNumber", "supportNumber", "dob", "mrz"]
        case .legal:   hideKeys = ["docNumber", "supportNumber", "dob", "address", "mrz"]
        case .health:  hideKeys = ["docNumber", "supportNumber", "dob", "nat", "address", "mrz"]
        case .banking: hideKeys = ["docNumber", "supportNumber", "dob", "expires", "nat", "address", "mrz"]
        }

        var result: [CGRect] = []
        var seenCenters: [CGPoint] = []

        func appendUnique(_ rect: CGRect) {
            let c = CGPoint(x: rect.midX, y: rect.midY)
            if seenCenters.contains(where: { abs($0.x - c.x) < 0.015 && abs($0.y - c.y) < 0.015 }) {
                return
            }
            seenCenters.append(c)
            result.append(pad(rect))
        }

        for key in hideKeys {
            guard let value = sensitiveValues[key] else { continue }
            let multiline = key == "address" || key == "name"
            let matches = findRects(for: value, mergeMultiline: multiline)
            for rect in matches {
                appendUnique(rect)
            }
        }

        // For MRZ: cover the entire bottom band as a single wide rect
        if hideKeys.contains("mrz"), let mrz = fields.mrz, !mrz.isEmpty {
            let mrzLines = mrz.components(separatedBy: "\n").filter { !$0.isEmpty }
            var mrzRects: [CGRect] = []
            for line in mrzLines {
                let key = String(line.prefix(8)).uppercased()
                let normalizedKey = normalize(key).replacingOccurrences(of: " ", with: "")
                let lineMatches = tokens.filter { $0.compact.hasPrefix(normalizedKey) || normalizedKey.hasPrefix($0.compact) }
                mrzRects.append(contentsOf: lineMatches.map(\.rect))
            }
            if !mrzRects.isEmpty {
                let union = mrzRects.dropFirst().reduce(mrzRects[0]) { $0.union($1) }
                appendUnique(union)
            }
        }

        return result.isEmpty ? nil : result
    }

    private static func mergeRects(_ rects: [CGRect]) -> [CGRect] {
        var merged: [CGRect] = []
        for rect in rects {
            if merged.contains(where: {
                abs($0.midX - rect.midX) < 0.015 &&
                abs($0.midY - rect.midY) < 0.015 &&
                abs($0.width - rect.width) < 0.03 &&
                abs($0.height - rect.height) < 0.03
            }) {
                continue
            }
            merged.append(rect)
        }
        return merged
    }

    // Calibrated grid fallback — used when bounding boxes are unavailable.
    private static func gridRects(for mode: RedactionMode) -> [CGRect] {
        switch mode {
        case .rental:
            return [
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),
                CGRect(x: 0.00, y: 0.82, width: 1.00, height: 0.18),
            ]
        case .travel:
            return [
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),
                CGRect(x: 0.00, y: 0.84, width: 1.00, height: 0.16),
            ]
        case .job:
            return [
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),
            ]
        case .verify:
            return [
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),
                CGRect(x: 0.00, y: 0.84, width: 1.00, height: 0.16),
            ]
        case .legal:
            return [
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),
                CGRect(x: 0.00, y: 0.80, width: 1.00, height: 0.10),
                CGRect(x: 0.00, y: 0.84, width: 1.00, height: 0.16),
            ]
        case .health:
            return [
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),
                CGRect(x: 0.28, y: 0.62, width: 0.68, height: 0.08),
                CGRect(x: 0.00, y: 0.84, width: 1.00, height: 0.16),
            ]
        case .banking:
            return [
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.55),
                CGRect(x: 0.60, y: 0.20, width: 0.34, height: 0.08),
                CGRect(x: 0.28, y: 0.52, width: 0.68, height: 0.08),
                CGRect(x: 0.28, y: 0.62, width: 0.68, height: 0.08),
                CGRect(x: 0.28, y: 0.72, width: 0.45, height: 0.07),
                CGRect(x: 0.00, y: 0.80, width: 1.00, height: 0.20),
            ]
        }
    }
}
