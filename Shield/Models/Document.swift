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
        if ShieldTheme.activeThemeID == .halloween2026 {
            switch self {
            case .all:      return "book.pages.fill"
            case .identity: return "theatermasks.fill"
            case .travel:   return "moon.stars.fill"
            case .driving:  return "car.side.fill"
            case .work:     return "briefcase.fill"
            case .health:   return "cross.vial.fill"
            case .finance:  return "banknote.fill"
            }
        }
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
        switch self {
        case .all:      return LanguageManager.shared.t("model_category_all", table: "Model", language: lang)
        case .identity: return LanguageManager.shared.t("model_category_identity", table: "Model", language: lang)
        case .travel:   return LanguageManager.shared.t("model_category_travel", table: "Model", language: lang)
        case .driving:  return LanguageManager.shared.t("model_category_driving", table: "Model", language: lang)
        case .work:     return LanguageManager.shared.t("model_category_work", table: "Model", language: lang)
        case .health:   return LanguageManager.shared.t("model_category_health", table: "Model", language: lang)
        case .finance:  return LanguageManager.shared.t("model_category_finance", table: "Model", language: lang)
        }
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

enum OCRSensitiveEntityKind: String, Codable, CaseIterable, Sendable {
    case documentNumber
    case supportNumber
    case fullName
    case dateOfBirth
    case nationality
    case expirationDate
    case address
    case mrz
    case email
    case phoneNumber
    case iban
    case paymentCard
    case barcode
}

struct OCRTextEvidence: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let pageIndex: Int
    let text: String
    let boundingRect: CGRect
    let confidence: Double

    init(
        id: UUID = UUID(),
        pageIndex: Int,
        text: String,
        boundingRect: CGRect,
        confidence: Double
    ) {
        self.id = id
        self.pageIndex = pageIndex
        self.text = text
        self.boundingRect = NormalizedDocumentGeometry.rect(boundingRect, minimumSize: 0)
        self.confidence = min(1, max(0, confidence))
    }
}

struct LocalSearchOccurrence: Identifiable, Equatable, Sendable {
    let id: String
    let pageIndex: Int
    let boundingRect: CGRect?
    let confidence: Double?
    /// Kept in memory for an explicit reveal action; it is never included in analytics.
    let protectedText: String
}

struct OCRSensitiveEntity: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let kind: OCRSensitiveEntityKind
    let value: String
    let pageIndex: Int
    let evidenceIDs: [UUID]
    let confidence: Double
    let validator: String?

    init(
        id: UUID = UUID(),
        kind: OCRSensitiveEntityKind,
        value: String,
        pageIndex: Int,
        evidenceIDs: [UUID],
        confidence: Double,
        validator: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.value = value
        self.pageIndex = pageIndex
        self.evidenceIDs = evidenceIDs
        self.confidence = min(1, max(0, confidence))
        self.validator = validator
    }
}

struct OCRPageEvidence: Codable, Equatable, Sendable {
    let pageIndex: Int
    let observations: [OCRTextEvidence]
    let entities: [OCRSensitiveEntity]
}

struct OCRFaceSuggestion: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    let pageIndex: Int
    let boundingRect: CGRect
    let confidence: Double
    let rollDegrees: Double?

    init(
        id: UUID = UUID(),
        pageIndex: Int,
        boundingRect: CGRect,
        confidence: Double,
        rollDegrees: Double? = nil
    ) {
        self.id = id
        self.pageIndex = pageIndex
        self.boundingRect = NormalizedDocumentGeometry.rect(boundingRect, minimumSize: 0.001)
        self.confidence = min(1, max(0, confidence))
        self.rollDegrees = rollDegrees?.isFinite == true ? rollDegrees : nil
    }
}

struct OCRExpectedEntity: Codable, Hashable, Sendable {
    let pageIndex: Int
    let kind: OCRSensitiveEntityKind
    let value: String
}

struct OCREvaluationMetrics: Equatable, Sendable {
    let truePositives: Int
    let falsePositives: Int
    let falseNegatives: Int

    var precision: Double {
        let denominator = truePositives + falsePositives
        return denominator == 0 ? 1 : Double(truePositives) / Double(denominator)
    }

    var recall: Double {
        let denominator = truePositives + falseNegatives
        return denominator == 0 ? 1 : Double(truePositives) / Double(denominator)
    }

    var f1: Double {
        let denominator = precision + recall
        return denominator == 0 ? 0 : 2 * precision * recall / denominator
    }
}

enum OCREvaluator {
    static func evaluate(
        expected: [OCRExpectedEntity],
        detected pages: [OCRPageEvidence],
        minimumConfidence: Double = 0.55
    ) -> OCREvaluationMetrics {
        let expectedKeys = Set(expected.map { key(page: $0.pageIndex, kind: $0.kind, value: $0.value) })
        let detectedKeys = Set(pages.flatMap(\.entities)
            .filter { $0.confidence >= minimumConfidence }
            .map { key(page: $0.pageIndex, kind: $0.kind, value: $0.value) })
        return OCREvaluationMetrics(
            truePositives: expectedKeys.intersection(detectedKeys).count,
            falsePositives: detectedKeys.subtracting(expectedKeys).count,
            falseNegatives: expectedKeys.subtracting(detectedKeys).count
        )
    }

    private static func key(page: Int, kind: OCRSensitiveEntityKind, value: String) -> String {
        let normalized = value.uppercased()
            .replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
        return "\(page)|\(kind.rawValue)|\(normalized)"
    }
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
    var ocrPageEvidence: [OCRPageEvidence]? = nil
    var ocrFaceSuggestions: [OCRFaceSuggestion]? = nil
    /// Algorithm version used to produce the stored face boxes. Older or unknown
    /// versions are recomputed so geometry fixes do not leave stale masks behind.
    var ocrFaceSuggestionsRevision: Int? = nil
    var ocrDismissedFaceSuggestionIDs: [UUID]? = nil

    static var empty: DocumentFields {
        DocumentFields(documentNumber: "", fullName: "", dateOfBirth: "",
                       nationality: "", expires: "", sex: "", address: "",
                       issued: nil, mrz: nil,
                       ocrDocumentType: nil, ocrFullText: nil, ocrPageTexts: nil,
                       ocrMRZValid: nil, ocrMRZFormat: nil, ocrFieldConfidence: nil,
                       ocrDetectedCountry: nil, ocrRiskLevel: nil, ocrLowConfidenceFields: nil,
                       ocrBoundingTexts: nil, ocrBoundingRects: nil,
                       ocrFaceSuggestionsRevision: nil)
    }
}

// MARK: - FieldBox

struct FieldBox: Identifiable {
    let id = UUID()
    let rect: CGRect   // normalized 0..1
    let label: String
    let fieldKey: String?

    init(rect: CGRect, label: String, fieldKey: String? = nil) {
        self.rect = rect
        self.label = label
        self.fieldKey = fieldKey
    }
}

// MARK: - Per-page redactions

struct DocumentPageRedactions: Codable, Equatable {
    var pageIndex: Int
    var redactions: [Redaction]
}

// MARK: - Non-destructive page model

struct DocumentNormalizedQuad: Codable, Equatable {
    var topLeft: CGPoint
    var topRight: CGPoint
    var bottomLeft: CGPoint
    var bottomRight: CGPoint
}

struct DocumentPageTransform: Codable, Equatable {
    var filterPreset: String = "original"
    var straightenDegrees: Double = 0
    var rotationDegrees: Double = 0
    var perspectiveTopInset: Double = 0
    var perspectiveBottomInset: Double = 0
    var perspectiveSkew: Double = 0
    var perspectiveTopYOffset: Double = 0
    var perspectiveBottomYOffset: Double = 0
    var quad: DocumentNormalizedQuad?
    var cropLeft: Double = 0
    var cropRight: Double = 0
    var cropTop: Double = 0
    var cropBottom: Double = 0
    var brightness: Double = 0
    var contrast: Double = 1
    var sharpness: Double = 0
    var noiseReduction: Double = 0

    static let identity = DocumentPageTransform()
}

// MARK: - DocumentItem

struct DocumentItem: Identifiable, Codable {
    static let currentSchemaVersion = 5

    var schemaVersion: Int
    let id: String
    var kind: DocumentKind
    var title: String
    var category: DocumentCategory
    var customCategoryID: String?   // non-nil = user category overrides `category`
    var date: Date
    var modifiedAt: Date
    var redactionCount: Int
    var isFavorite: Bool
    var isLocked: Bool
    var isVaulted: Bool
    var imageFileName: String?      // filename inside shield_images/ dir (page 0 or single image)
    var pageFileNames: [String]?    // all pages for multi-page PDFs; nil = single page
    /// Immutable normalized assets captured before filters/crops are applied.
    /// Legacy documents can be nil because their original was not preserved.
    var originalPageFileNames: [String]?
    var pageTransforms: [DocumentPageTransform]
    var sourceType: ImportedDocumentSource
    var sourceFileName: String?
    var fields: DocumentFields
    var pageRedactions: [DocumentPageRedactions]
    /// Pages in a batch workflow that still need explicit human review before
    /// the protected export is enabled.
    var batchReviewPendingPageIndices: [Int]
    /// Pages on which the latest batch run prepared at least one suggestion.
    var batchSuggestionPageIndices: [Int]
    /// Geometry the user last reviewed. Older documents without this value
    /// are conservatively queued when their crop/orientation is non-identity.
    var redactionGeometryReviewedFingerprint: String?
    /// Geometry associated with the current partial review queue, if any.
    var redactionGeometryReviewPendingFingerprint: String?
    var watermark: Watermark?
    var imageAdjustment: ImageAdjustmentStore?

    var pageCount: Int { pageFileNames?.count ?? (imageFileName != nil ? 1 : 0) }
    var hasRasterPageAssets: Bool {
        (pageFileNames?.contains(where: { !$0.isEmpty }) ?? false) ||
            (imageFileName?.isEmpty == false)
    }
    /// Before raster-backed typed documents used their source page in the editor,
    /// the same normalized mask coordinates were shown over a synthetic template.
    /// Keep this distinction in the review fingerprint so those legacy masks are
    /// queued for a human check after the renderer changes.
    var usesRasterBackedTypedDocumentCoordinates: Bool {
        kind != .photo && hasRasterPageAssets
    }
    var totalRedactionCount: Int { pageRedactions.reduce(0) { $0 + $1.redactions.count } }
    var allImageFileNames: Set<String> {
        Set((pageFileNames ?? []) + (originalPageFileNames ?? []) + [imageFileName].compactMap { $0 })
    }

    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case id
        case kind
        case title
        case category
        case customCategoryID
        case date
        case modifiedAt
        case redactionCount
        case isFavorite
        case isLocked
        case isVaulted
        case imageFileName
        case pageFileNames
        case originalPageFileNames
        case pageTransforms
        case sourceType
        case sourceFileName
        case fields
        case pageRedactions
        case batchReviewPendingPageIndices
        case batchSuggestionPageIndices
        case redactionGeometryReviewedFingerprint
        case redactionGeometryReviewPendingFingerprint
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

    func shortDateLabelLocalized(lang: AppLanguage) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: lang.rawValue)
        return formatter.string(from: date)
    }

    func compactDateLabel(lang: AppLanguage) -> String {
        let calendar = Calendar.current
        let isCurrentYear = calendar.component(.year, from: date) == calendar.component(.year, from: Date())
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lang.rawValue)
        if isCurrentYear {
            formatter.setLocalizedDateFormatFromTemplate("dMMM")
        } else {
            formatter.setLocalizedDateFormatFromTemplate("dMMMyyyy")
        }
        return formatter.string(from: date)
    }

    init(id: String = UUID().uuidString,
         kind: DocumentKind,
         title: String,
         category: DocumentCategory = .identity,
         customCategoryID: String? = nil,
         date: Date = Date(),
         modifiedAt: Date = Date(),
         redactionCount: Int = 0,
         isFavorite: Bool = false,
         isLocked: Bool = false,
         isVaulted: Bool = false,
         imageFileName: String? = nil,
         pageFileNames: [String]? = nil,
         originalPageFileNames: [String]? = nil,
         pageTransforms: [DocumentPageTransform] = [],
         sourceType: ImportedDocumentSource = .image,
         sourceFileName: String? = nil,
         fields: DocumentFields = .empty,
         pageRedactions: [DocumentPageRedactions] = [],
         batchReviewPendingPageIndices: [Int] = [],
         batchSuggestionPageIndices: [Int] = [],
         redactionGeometryReviewedFingerprint: String? = nil,
         redactionGeometryReviewPendingFingerprint: String? = nil,
         watermark: Watermark? = nil,
         imageAdjustment: ImageAdjustmentStore? = nil) {
        self.schemaVersion = Self.currentSchemaVersion
        self.id = id
        self.kind = kind
        self.title = title
        self.category = category
        self.customCategoryID = customCategoryID
        self.date = date
        self.modifiedAt = modifiedAt
        self.redactionCount = redactionCount
        self.isFavorite = isFavorite
        self.isLocked = isLocked
        self.isVaulted = isVaulted
        self.imageFileName = imageFileName
        self.pageFileNames = pageFileNames
        self.originalPageFileNames = originalPageFileNames
        self.pageTransforms = pageTransforms
        self.sourceType = sourceType
        self.sourceFileName = sourceFileName
        self.fields = fields
        self.pageRedactions = pageRedactions
        self.batchReviewPendingPageIndices = Array(Set(batchReviewPendingPageIndices.filter { $0 >= 0 })).sorted()
        self.batchSuggestionPageIndices = Array(Set(batchSuggestionPageIndices.filter { $0 >= 0 })).sorted()
        self.redactionGeometryReviewedFingerprint = redactionGeometryReviewedFingerprint
        self.redactionGeometryReviewPendingFingerprint = redactionGeometryReviewPendingFingerprint
        self.watermark = watermark
        self.imageAdjustment = imageAdjustment
        self.redactionCount = pageRedactions.isEmpty
            ? redactionCount
            : pageRedactions.reduce(0) { $0 + $1.redactions.count }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        id = try container.decode(String.self, forKey: .id)
        kind = try container.decode(DocumentKind.self, forKey: .kind)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decodeIfPresent(DocumentCategory.self, forKey: .category) ?? .identity
        customCategoryID = try container.decodeIfPresent(String.self, forKey: .customCategoryID)
        date = try container.decodeIfPresent(Date.self, forKey: .date) ?? Date()
        modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt) ?? date
        redactionCount = try container.decodeIfPresent(Int.self, forKey: .redactionCount) ?? 0
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isLocked = try container.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        isVaulted = try container.decodeIfPresent(Bool.self, forKey: .isVaulted) ?? false
        imageFileName = try container.decodeIfPresent(String.self, forKey: .imageFileName)
        pageFileNames = try container.decodeIfPresent([String].self, forKey: .pageFileNames)
        originalPageFileNames = try container.decodeIfPresent([String].self, forKey: .originalPageFileNames)
        pageTransforms = try container.decodeIfPresent([DocumentPageTransform].self, forKey: .pageTransforms) ?? []
        sourceType = try container.decodeIfPresent(ImportedDocumentSource.self, forKey: .sourceType) ?? .image
        sourceFileName = try container.decodeIfPresent(String.self, forKey: .sourceFileName)
        fields = try container.decodeIfPresent(DocumentFields.self, forKey: .fields) ?? .empty
        pageRedactions = try container.decodeIfPresent([DocumentPageRedactions].self, forKey: .pageRedactions) ?? []
        batchReviewPendingPageIndices = Array(
            Set((try container.decodeIfPresent([Int].self, forKey: .batchReviewPendingPageIndices) ?? []).filter { $0 >= 0 })
        ).sorted()
        batchSuggestionPageIndices = Array(
            Set((try container.decodeIfPresent([Int].self, forKey: .batchSuggestionPageIndices) ?? []).filter { $0 >= 0 })
        ).sorted()
        redactionGeometryReviewedFingerprint = try container.decodeIfPresent(
            String.self,
            forKey: .redactionGeometryReviewedFingerprint
        )
        redactionGeometryReviewPendingFingerprint = try container.decodeIfPresent(
            String.self,
            forKey: .redactionGeometryReviewPendingFingerprint
        )
        watermark = try container.decodeIfPresent(Watermark.self, forKey: .watermark)
        imageAdjustment = try container.decodeIfPresent(ImageAdjustmentStore.self, forKey: .imageAdjustment)

        if !pageRedactions.isEmpty {
            redactionCount = pageRedactions.reduce(0) { $0 + $1.redactions.count }
        }
    }

    mutating func migrateToCurrentSchema() {
        guard schemaVersion < Self.currentSchemaVersion else { return }
        if schemaVersion < 4 {
            // Legacy images may already contain baked adjustments. Do not pretend
            // they are immutable originals; keeping this nil prevents a destructive
            // re-adjustment from being presented as reversible.
            originalPageFileNames = nil
            if pageTransforms.isEmpty {
                pageTransforms = Array(repeating: .identity, count: pageCount)
            }
        }
        // Schema 5 adds optional geometry-review fingerprints. Existing values
        // remain nil so the editor can queue only documents whose geometry moved.
        schemaVersion = Self.currentSchemaVersion
    }

    func originalImageFileName(for page: Int) -> String? {
        guard let originals = originalPageFileNames, originals.indices.contains(page) else { return nil }
        return originals[page]
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

    var localSearchContent: String {
        guard !isVaulted else { return "" }
        let fieldValues = [
            fields.documentNumber,
            fields.supportNumber ?? "",
            fields.fullName,
            fields.dateOfBirth,
            fields.nationality,
            fields.expires,
            fields.sex,
            fields.address,
            fields.mrz ?? ""
        ]
        let pageText = (fields.ocrPageTexts ?? [])
            + (fields.ocrBoundingTexts ?? [])
            + [fields.ocrFullText].compactMap { $0 }
        let evidenceText = (fields.ocrPageEvidence ?? []).flatMap { page in
            page.observations.map(\.text) + page.entities.map(\.value)
        }
        return ([title] + fieldValues + pageText + evidenceText)
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    func matchesLocalSearch(_ query: String) -> Bool {
        guard !isVaulted else { return false }
        let alternatives = LocalDocumentSearch.alternatives(from: query)
        guard !alternatives.isEmpty else { return query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return alternatives.contains { LocalDocumentSearch.contains($0, in: localSearchContent) }
    }

    func matchingOCRPageIndices(for query: String) -> [Int] {
        guard !isVaulted else { return [] }
        let alternatives = LocalDocumentSearch.alternatives(from: query)
        guard !alternatives.isEmpty else { return [] }

        var matches = Set<Int>()
        for (index, text) in (fields.ocrPageTexts ?? []).enumerated()
        where alternatives.contains(where: { LocalDocumentSearch.contains($0, in: text) }) {
            matches.insert(index)
        }
        for page in fields.ocrPageEvidence ?? [] {
            if page.observations.contains(where: { observation in
                alternatives.contains(where: { LocalDocumentSearch.contains($0, in: observation.text) })
            }) || page.entities.contains(where: { entity in
                alternatives.contains(where: { LocalDocumentSearch.contains($0, in: entity.value) })
            }) {
                matches.insert(page.pageIndex)
            }
        }
        if (fields.ocrBoundingTexts ?? []).contains(where: { text in
            alternatives.contains(where: { LocalDocumentSearch.contains($0, in: text) })
        }) {
            matches.insert(0)
        }

        let fieldValues = [
            fields.documentNumber,
            fields.supportNumber ?? "",
            fields.fullName,
            fields.dateOfBirth,
            fields.nationality,
            fields.expires,
            fields.sex,
            fields.address,
            fields.mrz ?? ""
        ]
        if fieldValues.contains(where: { text in
            alternatives.contains(where: { LocalDocumentSearch.contains($0, in: text) })
        }) || ((fields.ocrFullText ?? "").isEmpty == false && alternatives.contains(where: {
            LocalDocumentSearch.contains($0, in: fields.ocrFullText ?? "")
        }) && matches.isEmpty) {
            matches.insert(0)
        }
        return matches.sorted()
    }

    func localSearchOccurrences(for query: String, pageIndex: Int? = nil) -> [LocalSearchOccurrence] {
        guard !isVaulted else { return [] }
        let alternatives = LocalDocumentSearch.alternatives(from: query)
        guard !alternatives.isEmpty else { return [] }

        var occurrences: [LocalSearchOccurrence] = []
        var includedIDs = Set<String>()

        func add(_ occurrence: LocalSearchOccurrence) {
            guard pageIndex == nil || pageIndex == occurrence.pageIndex,
                  includedIDs.insert(occurrence.id).inserted else { return }
            occurrences.append(occurrence)
        }

        for page in fields.ocrPageEvidence ?? [] {
            for observation in page.observations where alternatives.contains(where: {
                LocalDocumentSearch.contains($0, in: observation.text)
            }) {
                add(LocalSearchOccurrence(
                    id: observation.id.uuidString,
                    pageIndex: observation.pageIndex,
                    boundingRect: observation.boundingRect,
                    confidence: observation.confidence,
                    protectedText: String(observation.text.prefix(160))
                ))
            }

            let observationsByID = Dictionary(
                page.observations.map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            for entity in page.entities where alternatives.contains(where: {
                LocalDocumentSearch.contains($0, in: entity.value)
            }) {
                let evidence = entity.evidenceIDs.compactMap { observationsByID[$0] }
                if evidence.isEmpty {
                    add(LocalSearchOccurrence(
                        id: entity.id.uuidString,
                        pageIndex: entity.pageIndex,
                        boundingRect: nil,
                        confidence: entity.confidence,
                        protectedText: String(entity.value.prefix(160))
                    ))
                } else {
                    for observation in evidence {
                        add(LocalSearchOccurrence(
                            id: observation.id.uuidString,
                            pageIndex: observation.pageIndex,
                            boundingRect: observation.boundingRect,
                            confidence: min(observation.confidence, entity.confidence),
                            protectedText: String(entity.value.prefix(160))
                        ))
                    }
                }
            }
        }

        if occurrences.isEmpty {
            let texts = fields.ocrBoundingTexts ?? []
            let rects = fields.ocrBoundingRects ?? []
            for (index, text) in texts.enumerated()
            where alternatives.contains(where: { LocalDocumentSearch.contains($0, in: text) }) {
                add(LocalSearchOccurrence(
                    id: "legacy-box-\(index)",
                    pageIndex: 0,
                    boundingRect: rects.indices.contains(index) ? rects[index] : nil,
                    confidence: nil,
                    protectedText: String(text.prefix(160))
                ))
            }
        }

        if occurrences.isEmpty {
            for (index, text) in (fields.ocrPageTexts ?? []).enumerated()
            where alternatives.contains(where: { LocalDocumentSearch.contains($0, in: text) }) {
                add(LocalSearchOccurrence(
                    id: "page-text-\(index)",
                    pageIndex: index,
                    boundingRect: nil,
                    confidence: nil,
                    protectedText: String(text.prefix(160))
                ))
            }
        }

        if occurrences.isEmpty {
            let fieldValues: [(String, String)] = [
                ("documentNumber", fields.documentNumber),
                ("supportNumber", fields.supportNumber ?? ""),
                ("fullName", fields.fullName),
                ("dateOfBirth", fields.dateOfBirth),
                ("nationality", fields.nationality),
                ("expirationDate", fields.expires),
                ("sex", fields.sex),
                ("address", fields.address),
                ("mrz", fields.mrz ?? "")
            ]
            for (key, value) in fieldValues where alternatives.contains(where: {
                LocalDocumentSearch.contains($0, in: value)
            }) {
                add(LocalSearchOccurrence(
                    id: "field-\(key)",
                    pageIndex: 0,
                    boundingRect: nil,
                    confidence: fields.ocrFieldConfidence?[key],
                    protectedText: String(value.prefix(160))
                ))
            }
        }

        if occurrences.isEmpty,
           let fullText = fields.ocrFullText,
           alternatives.contains(where: { LocalDocumentSearch.contains($0, in: fullText) }) {
            add(LocalSearchOccurrence(
                id: "legacy-full-text",
                pageIndex: 0,
                boundingRect: nil,
                confidence: nil,
                protectedText: String(fullText.prefix(160))
            ))
        }

        let sortedOccurrences = occurrences.sorted {
            if $0.pageIndex != $1.pageIndex { return $0.pageIndex < $1.pageIndex }
            if $0.boundingRect?.minY != $1.boundingRect?.minY {
                return ($0.boundingRect?.minY ?? 0) < ($1.boundingRect?.minY ?? 0)
            }
            return ($0.boundingRect?.minX ?? 0) < ($1.boundingRect?.minX ?? 0)
        }
        return Array(sortedOccurrences.prefix(50))
    }
}

/// Bounded, local-only search normalization. Commas, semicolons and newlines
/// let people search for several alternatives without enabling user regexes.
enum LocalDocumentSearch {
    private static let maximumQueryLength = 160
    private static let maximumAlternatives = 8

    static func alternatives(from query: String) -> [String] {
        let boundedQuery = String(query.prefix(maximumQueryLength))
        var seen = Set<String>()
        let components: [Substring] = boundedQuery
            .split(whereSeparator: { $0 == "," || $0 == ";" || $0.isNewline })
        return components
            .compactMap { component in
                let normalized = normalize(component.description)
                guard !normalized.isEmpty, seen.insert(normalized).inserted else { return nil }
                return normalized
            }
            .prefix(maximumAlternatives)
            .map { $0 }
    }

    static func contains(_ normalizedQuery: String, in text: String) -> Bool {
        let normalizedText = normalize(text)
        guard !normalizedText.isEmpty else { return false }
        if normalizedText.contains(normalizedQuery) { return true }

        let compactQuery = compact(normalizedQuery)
        return compactQuery.count >= 3 && compact(normalizedText).contains(compactQuery)
    }

    private static func normalize(_ value: String) -> String {
        let folded = value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        let words = folded.split(whereSeparator: { !$0.isLetter && !$0.isNumber })
        return words.joined(separator: " ")
    }

    private static func compact(_ value: String) -> String {
        String(value.filter { $0.isLetter || $0.isNumber })
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

/// Determines when existing redaction rectangles need another human review.
/// Brightness and other visual filters do not move annotations; crop and
/// orientation changes do.
enum RedactionReviewGate {
    static func requiresReview(from old: ImageAdjustmentStore?, to new: ImageAdjustmentStore?) -> Bool {
        let oldGeometry = AdjustmentGeometry(old)
        let newGeometry = AdjustmentGeometry(new)
        return oldGeometry != newGeometry
    }

    static func requiresReview(from old: [DocumentPageTransform], to new: [DocumentPageTransform]) -> Bool {
        return (0..<max(old.count, new.count)).contains { index in
            let oldPage = old.indices.contains(index) ? old[index] : .identity
            let newPage = new.indices.contains(index) ? new[index] : .identity
            return PageGeometry(oldPage) != PageGeometry(newPage)
        }
    }

    private static func normalizedDegrees(_ value: Double) -> Double {
        (value.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
    }

    static func pendingPageIndices(existing: [Int], pageCount: Int) -> [Int] {
        guard pageCount > 0 else { return [] }
        return Array(Set(existing.filter { $0 >= 0 && $0 < pageCount }).union(0..<pageCount)).sorted()
    }

    static let identityFingerprint = "identity"

    static func fingerprint(
        pageTransforms: [DocumentPageTransform],
        imageAdjustment: ImageAdjustmentStore?,
        rasterBackedTypedDocument: Bool = false
    ) -> String {
        let adjustment = AdjustmentGeometry(imageAdjustment)
        let pages = pageTransforms.map(PageGeometry.init)
        let geometryFingerprint: String
        guard !adjustment.isIdentity || pages.contains(where: { !$0.isIdentity }) else {
            geometryFingerprint = identityFingerprint
            return rasterBackedTypedDocument ? "raster-typed-v1:\(geometryFingerprint)" : geometryFingerprint
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        if let data = try? encoder.encode(GeometrySnapshot(adjustment: adjustment, pages: pages)) {
            geometryFingerprint = data.base64EncodedString()
        } else {
            geometryFingerprint = "unavailable"
        }
        return rasterBackedTypedDocument ? "raster-typed-v1:\(geometryFingerprint)" : geometryFingerprint
    }

    private struct GeometrySnapshot: Encodable {
        let adjustment: AdjustmentGeometry
        let pages: [PageGeometry]
    }

    private struct PageGeometry: Codable, Equatable {
        var rotation: Double
        var straighten: Double
        var perspectiveTopInset: Double
        var perspectiveBottomInset: Double
        var perspectiveSkew: Double
        var perspectiveTopYOffset: Double
        var perspectiveBottomYOffset: Double
        var quad: DocumentNormalizedQuad?
        var cropLeft: Double
        var cropRight: Double
        var cropTop: Double
        var cropBottom: Double

        init(_ transform: DocumentPageTransform) {
            rotation = RedactionReviewGate.normalizedDegrees(transform.rotationDegrees)
            straighten = RedactionReviewGate.normalizedDegrees(transform.straightenDegrees)
            perspectiveTopInset = transform.perspectiveTopInset
            perspectiveBottomInset = transform.perspectiveBottomInset
            perspectiveSkew = transform.perspectiveSkew
            perspectiveTopYOffset = transform.perspectiveTopYOffset
            perspectiveBottomYOffset = transform.perspectiveBottomYOffset
            quad = transform.quad
            cropLeft = transform.cropLeft
            cropRight = transform.cropRight
            cropTop = transform.cropTop
            cropBottom = transform.cropBottom
        }

        var isIdentity: Bool { self == PageGeometry(.identity) }
    }

    private struct AdjustmentGeometry: Codable, Equatable {
        var rotation: Double
        var flipHorizontal: Bool
        var flipVertical: Bool
        var cropLeft: Double
        var cropRight: Double
        var cropTop: Double
        var cropBottom: Double

        init(_ adjustment: ImageAdjustmentStore?) {
            rotation = RedactionReviewGate.normalizedDegrees(adjustment?.rotation ?? 0)
            flipHorizontal = adjustment?.flipHorizontal ?? false
            flipVertical = adjustment?.flipVertical ?? false
            cropLeft = adjustment?.cropLeft ?? 0
            cropRight = adjustment?.cropRight ?? 0
            cropTop = adjustment?.cropTop ?? 0
            cropBottom = adjustment?.cropBottom ?? 0
        }

        var isIdentity: Bool { self == AdjustmentGeometry(nil) }
    }
}

// MARK: - Field boxes (normalized 0..1)

enum DocumentFieldBoxes {
    static let dniESP: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.30, y: 0.212, width: 0.30, height: 0.105), label: "Surname 1", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.352, width: 0.30, height: 0.105), label: "Surname 2", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.492, width: 0.22, height: 0.105), label: "Name", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.772, width: 0.32, height: 0.105), label: "Doc №", fieldKey: "docNum"),
        FieldBox(rect: CGRect(x: 0.62, y: 0.632, width: 0.34, height: 0.105), label: "DOB", fieldKey: "dob"),
        FieldBox(rect: CGRect(x: 0.62, y: 0.772, width: 0.30, height: 0.105), label: "Expires", fieldKey: "expires"),
        FieldBox(rect: CGRect(x: 0.40, y: 0.632, width: 0.20, height: 0.105), label: "Nationality", fieldKey: "nat"),
        FieldBox(rect: CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.60), label: "Photo"),
        FieldBox(rect: CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14), label: "MRZ"),
    ]

    static let passportUSA: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.62, y: 0.212, width: 0.33, height: 0.10), label: "Passport №", fieldKey: "docNum"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.352, width: 0.42, height: 0.10), label: "Surname", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.492, width: 0.42, height: 0.10), label: "Given names", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.612, width: 0.36, height: 0.10), label: "Nationality", fieldKey: "nat"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.732, width: 0.31, height: 0.10), label: "DOB", fieldKey: "dob"),
        FieldBox(rect: CGRect(x: 0.70, y: 0.732, width: 0.28, height: 0.10), label: "Expires", fieldKey: "expires"),
        FieldBox(rect: CGRect(x: 0.04, y: 0.20, width: 0.20, height: 0.57), label: "Photo"),
        FieldBox(rect: CGRect(x: 0.00, y: 0.85, width: 1.00, height: 0.15), label: "MRZ"),
    ]

    static let drivingUK: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.36, y: 0.232, width: 0.43, height: 0.10), label: "Surname", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.36, y: 0.352, width: 0.43, height: 0.10), label: "Names", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.36, y: 0.472, width: 0.36, height: 0.10), label: "DOB", fieldKey: "dob"),
        FieldBox(rect: CGRect(x: 0.36, y: 0.592, width: 0.36, height: 0.10), label: "Issued"),
        FieldBox(rect: CGRect(x: 0.62, y: 0.592, width: 0.36, height: 0.10), label: "Expires", fieldKey: "expires"),
        FieldBox(rect: CGRect(x: 0.36, y: 0.712, width: 0.46, height: 0.10), label: "Driver №", fieldKey: "docNum"),
        FieldBox(rect: CGRect(x: 0.36, y: 0.832, width: 0.62, height: 0.10), label: "Address", fieldKey: "addr"),
        FieldBox(rect: CGRect(x: 0.13, y: 0.22, width: 0.20, height: 0.55), label: "Photo"),
    ]

    static let photo: [FieldBox] = []  // no predefined boxes for photo docs

    static let passportMEX: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.28, y: 0.712, width: 0.30, height: 0.10), label: "Passport №", fieldKey: "docNum"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.222, width: 0.42, height: 0.10), label: "Apellido(s)", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.352, width: 0.42, height: 0.10), label: "Nombre(s)", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.472, width: 0.36, height: 0.10), label: "Nationality", fieldKey: "nat"),
        FieldBox(rect: CGRect(x: 0.28, y: 0.592, width: 0.30, height: 0.10), label: "Nacimiento", fieldKey: "dob"),
        FieldBox(rect: CGRect(x: 0.62, y: 0.712, width: 0.33, height: 0.10), label: "Vence", fieldKey: "expires"),
        FieldBox(rect: CGRect(x: 0.04, y: 0.20, width: 0.20, height: 0.52), label: "Foto"),
        FieldBox(rect: CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14), label: "MRZ"),
    ]

    static let dniITA: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.38, y: 0.212, width: 0.42, height: 0.10), label: "Cognome", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.38, y: 0.342, width: 0.42, height: 0.10), label: "Nome", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.38, y: 0.472, width: 0.30, height: 0.10), label: "Nationality", fieldKey: "nat"),
        FieldBox(rect: CGRect(x: 0.38, y: 0.702, width: 0.38, height: 0.10), label: "Codice fiscale", fieldKey: "docNum"),
        FieldBox(rect: CGRect(x: 0.38, y: 0.582, width: 0.30, height: 0.10), label: "Nascita", fieldKey: "dob"),
        FieldBox(rect: CGRect(x: 0.70, y: 0.702, width: 0.28, height: 0.10), label: "Scadenza", fieldKey: "expires"),
        FieldBox(rect: CGRect(x: 0.14, y: 0.20, width: 0.20, height: 0.52), label: "Foto"),
        FieldBox(rect: CGRect(x: 0.00, y: 0.87, width: 1.00, height: 0.13), label: "MRZ"),
    ]

    static let genericID: [FieldBox] = [
        FieldBox(rect: CGRect(x: 0.30, y: 0.212, width: 0.42, height: 0.10), label: "Surname", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.342, width: 0.42, height: 0.10), label: "Name", fieldKey: "name"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.472, width: 0.32, height: 0.10), label: "Nationality", fieldKey: "nat"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.702, width: 0.36, height: 0.10), label: "Doc №", fieldKey: "docNum"),
        FieldBox(rect: CGRect(x: 0.30, y: 0.582, width: 0.32, height: 0.10), label: "DOB", fieldKey: "dob"),
        FieldBox(rect: CGRect(x: 0.62, y: 0.702, width: 0.32, height: 0.10), label: "Expires", fieldKey: "expires"),
        FieldBox(rect: CGRect(x: 0.04, y: 0.20, width: 0.20, height: 0.52), label: "Photo"),
        FieldBox(rect: CGRect(x: 0.00, y: 0.87, width: 1.00, height: 0.13), label: "MRZ"),
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

    /// Returns the template fallback region for an OCR sheet field. Fields
    /// split across multiple printed rows are combined into one conservative
    /// rectangle; imported documents continue to prefer their OCR evidence.
    static func fallbackRect(for fieldKey: String, kind: DocumentKind) -> CGRect? {
        let rects = boxes(for: kind).filter { $0.fieldKey == fieldKey }.map(\.rect)
        guard let first = rects.first else { return nil }
        return rects.dropFirst().reduce(first) { $0.union($1) }
    }
}

// MARK: - Auto-suggested redactions

enum AutoRedactions {
    static func suggested(for kind: DocumentKind, style: MaskStyle = .block) -> [Redaction] {
        let rects: [CGRect]
        switch kind {
        case .dniESP:
            rects = [
                CGRect(x: 0.29, y: 0.77, width: 0.33, height: 0.11),   // Document number label + value
                CGRect(x: 0.61, y: 0.63, width: 0.35, height: 0.11),   // DOB label + value
                CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14),   // MRZ
                CGRect(x: 0.04, y: 0.18, width: 0.22, height: 0.60),   // Photo and full silhouette
            ]
        case .passportUSA:
            rects = [
                CGRect(x: 0.61, y: 0.21, width: 0.34, height: 0.10),   // Passport № label + value
                CGRect(x: 0.27, y: 0.73, width: 0.33, height: 0.10),   // DOB label + value
                CGRect(x: 0.00, y: 0.85, width: 1.00, height: 0.15),   // MRZ
                CGRect(x: 0.04, y: 0.20, width: 0.20, height: 0.57),   // Photo and full silhouette
            ]
        case .passportMEX:
            rects = [
                CGRect(x: 0.27, y: 0.59, width: 0.32, height: 0.10),   // DOB label + value
                CGRect(x: 0.27, y: 0.71, width: 0.32, height: 0.10),   // Passport number label + value
                CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14),
                CGRect(x: 0.04, y: 0.20, width: 0.20, height: 0.52),
            ]
        case .dniITA:
            rects = [
                CGRect(x: 0.37, y: 0.58, width: 0.31, height: 0.10),   // DOB label + value
                CGRect(x: 0.37, y: 0.70, width: 0.39, height: 0.10),   // Tax/document number label + value
                CGRect(x: 0.00, y: 0.86, width: 1.00, height: 0.14),
                CGRect(x: 0.13, y: 0.20, width: 0.22, height: 0.52),
            ]
        case .drivingUK:
            rects = [
                CGRect(x: 0.35, y: 0.47, width: 0.38, height: 0.10),   // DOB label + value
                CGRect(x: 0.35, y: 0.71, width: 0.47, height: 0.10),   // Driver № label + value
                CGRect(x: 0.35, y: 0.83, width: 0.63, height: 0.10),   // Address label + value
                CGRect(x: 0.13, y: 0.22, width: 0.20, height: 0.55),   // Photo
            ]
        case .genericID:
            rects = [
                CGRect(x: 0.29, y: 0.70, width: 0.38, height: 0.11),   // Document number label + value
                CGRect(x: 0.29, y: 0.58, width: 0.34, height: 0.11),   // DOB label + value
                CGRect(x: 0.04, y: 0.20, width: 0.20, height: 0.52),   // Photo and full silhouette
                CGRect(x: 0.00, y: 0.87, width: 1.00, height: 0.13),   // Bottom strip / MRZ
            ]
        case .photo:
            rects = []
        }
        return rects.map { Redaction(rect: $0, style: style) }
    }

    // Builds redaction rects for vector demo templates only. Real imported
    // documents must use `ocrPrecisionModeRects` so every zone has evidence.
    static func ocrModeRects(for mode: RedactionMode, fields: DocumentFields) -> [CGRect] {
        ocrPrecisionModeRects(for: mode, fields: fields)
    }

    /// Builds suggestions from exactly one page's OCR evidence. Batch workflows
    /// must use this overload so a field detected on one page can never place a
    /// mask at the same coordinates on a different page.
    static func ocrModeRects(for mode: RedactionMode, pageEvidence: OCRPageEvidence) -> [CGRect] {
        evidencePrecisionRects(for: mode, page: pageEvidence) ?? []
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
        if fields.ocrPageEvidence != nil {
            return evidencePrecisionRects(for: mode, fields: fields)
        }
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

    private static func evidencePrecisionRects(
        for mode: RedactionMode,
        fields: DocumentFields
    ) -> [CGRect]? {
        guard let page = fields.ocrPageEvidence?.first else { return nil }
        return evidencePrecisionRects(for: mode, page: page)
    }

    private static func evidencePrecisionRects(
        for mode: RedactionMode,
        page: OCRPageEvidence
    ) -> [CGRect]? {
        let hiddenKinds: Set<OCRSensitiveEntityKind>
        switch mode {
        case .rental:
            hiddenKinds = [.documentNumber, .supportNumber, .dateOfBirth, .expirationDate, .address, .mrz, .email, .phoneNumber, .iban, .paymentCard]
        case .travel:
            hiddenKinds = [.documentNumber, .supportNumber, .expirationDate, .mrz, .email, .phoneNumber, .paymentCard]
        case .job:
            hiddenKinds = [.documentNumber, .supportNumber, .dateOfBirth, .nationality, .email, .phoneNumber, .iban]
        case .verify:
            hiddenKinds = [.documentNumber, .supportNumber, .dateOfBirth, .mrz, .email, .phoneNumber]
        case .legal:
            hiddenKinds = [.documentNumber, .supportNumber, .dateOfBirth, .address, .mrz, .email, .phoneNumber, .iban, .paymentCard]
        case .health:
            hiddenKinds = [.documentNumber, .supportNumber, .dateOfBirth, .nationality, .address, .mrz, .email, .phoneNumber, .paymentCard]
        case .banking:
            hiddenKinds = [.documentNumber, .supportNumber, .dateOfBirth, .expirationDate, .nationality, .address, .mrz, .email, .phoneNumber, .iban, .paymentCard]
        }

        let observations = Dictionary(uniqueKeysWithValues: page.observations.map { ($0.id, $0) })
        let rects = page.entities
            .filter { hiddenKinds.contains($0.kind) && $0.confidence >= 0.55 }
            .compactMap { entity -> CGRect? in
                let evidence = entity.evidenceIDs.compactMap { observations[$0]?.boundingRect }
                guard let first = evidence.first else { return nil }
                let union = evidence.dropFirst().reduce(first) { $0.union($1) }
                let dx = max(0.005, union.width * 0.08)
                let dy = max(0.004, union.height * 0.20)
                return union.insetBy(dx: -dx, dy: -dy)
                    .intersection(CGRect(x: 0, y: 0, width: 1, height: 1))
            }
        return rects.isEmpty ? nil : rects
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

    // Calibrated grid geometry is retained only for the explicit vector demo
    // templates above; it is never applied to a captured/imported document.
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

struct BatchRedactionPlan: Equatable {
    let pageRedactions: [DocumentPageRedactions]
    let pagesWithSuggestions: Int
    let pagesWithoutSuggestions: Int

    var suggestionCount: Int {
        pageRedactions.reduce(0) { $0 + $1.redactions.count }
    }
}

enum BatchRedactionPlanner {
    /// Plans only evidence-backed suggestions. It deliberately does not use
    /// document-template grids because a multi-page imported file can contain
    /// different layouts on each page.
    static func plan(for document: DocumentItem, mode: RedactionMode) -> BatchRedactionPlan {
        let pageCount = max(document.pageCount, 1)
        var changes: [DocumentPageRedactions] = []
        var pagesWithSuggestions = 0

        for pageIndex in 0..<pageCount {
            let pageRects: [CGRect]
            if let evidence = document.fields.ocrPageEvidence?.first(where: { $0.pageIndex == pageIndex }) {
                pageRects = AutoRedactions.ocrModeRects(for: mode, pageEvidence: evidence)
            } else if pageIndex == 0, document.fields.ocrPageEvidence == nil {
                // Legacy single-page imports stored OCR boxes without page
                // evidence. Keep that compatibility path limited to page 0.
                pageRects = AutoRedactions.ocrPrecisionModeRects(for: mode, fields: document.fields)
            } else {
                pageRects = []
            }

            let existing = document.redactions(for: pageIndex)
            let additions = pageRects
                .map { Redaction(rect: $0, style: .block) }
                .filter { candidate in
                    !existing.contains { current in
                        let overlap = current.rect.intersection(candidate.rect)
                        guard !overlap.isNull, !overlap.isEmpty else { return false }
                        let smallerArea = min(
                            current.rect.width * current.rect.height,
                            candidate.rect.width * candidate.rect.height
                        )
                        guard smallerArea > 0 else { return false }
                        return overlap.width * overlap.height / smallerArea >= 0.92
                    }
                }

            if !additions.isEmpty {
                pagesWithSuggestions += 1
                changes.append(DocumentPageRedactions(pageIndex: pageIndex, redactions: existing + additions))
            }
        }

        return BatchRedactionPlan(
            pageRedactions: changes,
            pagesWithSuggestions: pagesWithSuggestions,
            pagesWithoutSuggestions: pageCount - pagesWithSuggestions
        )
    }
}
