import Foundation

nonisolated struct ExportVerificationReport: Equatable, Sendable {
    let outputOpened: Bool
    let expectedPageCount: Int
    let actualPageCount: Int
    let hasExtractableText: Bool
    let annotationCount: Int
    let sensitiveMetadataKeys: [String]
    let ocrResidualTexts: [String]
    let normalizedVisualObfuscations: Int
    let issues: [String]

    var isVerified: Bool {
        outputOpened &&
        expectedPageCount == actualPageCount &&
        !hasExtractableText &&
        annotationCount == 0 &&
        sensitiveMetadataKeys.isEmpty &&
        ocrResidualTexts.isEmpty &&
        issues.isEmpty
    }
}

nonisolated struct SecurePDFExport: Sendable {
    let url: URL
    let report: ExportVerificationReport
}
