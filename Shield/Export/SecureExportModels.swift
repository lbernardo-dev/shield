import Foundation

enum ExportVerificationFormat: String, Equatable, Sendable {
    case pdf
    case image
}

nonisolated struct ExportVerificationReport: Equatable, Sendable {
    let format: ExportVerificationFormat
    let outputOpened: Bool
    let expectedPageCount: Int
    let actualPageCount: Int
    let pagesReviewed: Int
    let hasExtractableText: Bool
    let annotationCount: Int
    let sensitiveMetadataKeys: [String]
    let metadataRemoved: Bool
    let ocrResidualTexts: [String]
    let redactionsApplied: Int
    let normalizedVisualObfuscations: Int
    let watermarkApplied: Bool
    let remainingDetectedSensitiveElements: Int
    let issues: [String]

    init(
        format: ExportVerificationFormat = .pdf,
        outputOpened: Bool,
        expectedPageCount: Int,
        actualPageCount: Int,
        pagesReviewed: Int? = nil,
        hasExtractableText: Bool,
        annotationCount: Int,
        sensitiveMetadataKeys: [String],
        metadataRemoved: Bool? = nil,
        ocrResidualTexts: [String],
        redactionsApplied: Int = 0,
        normalizedVisualObfuscations: Int,
        watermarkApplied: Bool = false,
        remainingDetectedSensitiveElements: Int = 0,
        issues: [String]
    ) {
        self.format = format
        self.outputOpened = outputOpened
        self.expectedPageCount = expectedPageCount
        self.actualPageCount = actualPageCount
        self.pagesReviewed = pagesReviewed ?? actualPageCount
        self.hasExtractableText = hasExtractableText
        self.annotationCount = annotationCount
        self.sensitiveMetadataKeys = sensitiveMetadataKeys
        self.metadataRemoved = metadataRemoved ?? sensitiveMetadataKeys.isEmpty
        self.ocrResidualTexts = ocrResidualTexts
        self.redactionsApplied = redactionsApplied
        self.normalizedVisualObfuscations = normalizedVisualObfuscations
        self.watermarkApplied = watermarkApplied
        self.remainingDetectedSensitiveElements = max(0, remainingDetectedSensitiveElements)
        self.issues = issues
    }

    var isVerified: Bool {
        outputOpened &&
        expectedPageCount == actualPageCount &&
        pagesReviewed == actualPageCount &&
        !hasExtractableText &&
        annotationCount == 0 &&
        metadataRemoved &&
        ocrResidualTexts.isEmpty &&
        issues.isEmpty
    }

    /// The byte-level checks passed, but OCR can still have suggestions that
    /// the user intentionally left visible. Keep that distinction explicit in
    /// the UI instead of calling every technically valid output "safe".
    var isReadyToShare: Bool {
        isVerified && remainingDetectedSensitiveElements == 0
    }
}

nonisolated struct SecurePDFExport: Sendable {
    let url: URL
    let report: ExportVerificationReport
}

nonisolated struct SecureImageExport: Sendable {
    let url: URL
    let report: ExportVerificationReport
}
