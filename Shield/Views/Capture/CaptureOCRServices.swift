import Vision
import UIKit
import FoundationModels

// MARK: - OCRService

enum OCRService {
    enum DetectedDocumentType: String {
        case dni
        case passport
        case drivingLicense
        case visa
        case residencePermit
        case healthCard
        case document
    }

    enum OCRRiskLevel: String {
        case low
        case medium
        case high
    }

    private static let baseLanguages = ["es-ES", "en-US", "fr-FR", "de-DE", "it-IT", "pt-PT"]

    private static func languagesForCountry(_ country: String?) -> [String] {
        switch country?.uppercased() {
        case "ESP", "MEX", "ARG", "COL", "CHL", "PER", "ECU", "VEN", "BOL", "PRY", "URY",
             "USA", "GBR", "CAN", "AUS", "NZL", "IRL", "ZAF",
             "FRA", "BEL", "CHE", "LUX", "MCO",
             "DEU", "AUT", "LIE",
             "ITA", "SMR", "VAT",
             "PRT", "BRA", "AGO", "MOZ", "CPV":
            return []
        case "NLD", "SUR":
            return ["nl-NL"]
        case "POL":
            return ["pl-PL"]
        case "RUS", "BLR", "KAZ", "KGZ", "TJK", "UZB":
            return ["ru-RU"]
        case "UKR":
            return ["uk-UA"]
        case "TUR":
            return ["tr-TR"]
        case "GRC", "CYP":
            return ["el-GR"]
        case "SWE":
            return ["sv-SE"]
        case "NOR":
            return ["nb-NO"]
        case "DNK":
            return ["da-DK"]
        case "FIN":
            return ["fi-FI"]
        case "CZE":
            return ["cs-CZ"]
        case "SVK":
            return ["sk-SK"]
        case "HUN":
            return ["hu-HU"]
        case "ROU":
            return ["ro-RO"]
        case "BGR":
            return ["bg-BG"]
        case "HRV", "SRB", "BIH":
            return ["hr-HR"]
        case "CHN", "SGP":
            return ["zh-Hans"]
        case "TWN", "HKG", "MAC":
            return ["zh-Hant"]
        case "JPN":
            return ["ja-JP"]
        case "KOR":
            return ["ko-KR"]
        case "SAU", "ARE", "QAT", "KWT", "BHR", "OMN", "JOR", "LBN", "SYR", "IRQ",
             "EGY", "LBY", "TUN", "DZA", "MAR", "SDN", "YEM":
            return ["ar-SA"]
        case "ISR":
            return ["he-IL"]
        case "IND", "NPL":
            return ["hi-IN"]
        case "THA":
            return ["th-TH"]
        case "VNM":
            return ["vi-VN"]
        case "IDN", "MYS", "BRN":
            return ["id-ID"]
        case "PHL":
            return ["en-PH"]
        default:
            return []
        }
    }

    struct TextObservation {
        let text: String
        let boundingRect: CGRect
        let confidence: Double
    }

    static func recognizeText(in image: UIImage, extraLanguages: [String] = []) async -> [String] {
        await recognizeTextWithObservations(in: image, extraLanguages: extraLanguages).map(\.text)
    }

    static func recognizeTextWithObservations(
        in image: UIImage,
        extraLanguages: [String] = []
    ) async -> [TextObservation] {
        let languages = recognitionLanguages(extraLanguages: extraLanguages)
        let original = await performRecognition(in: image, languages: languages)
        let needsFallback = original.count < 8 || recognizedCharacterCount(in: original) < 80
        guard needsFallback else { return original }

        let enhanced = makeOCRVariants(from: image)
        guard !enhanced.isEmpty else { return original }

        var best = original
        for variant in enhanced {
            let candidate = await performRecognition(in: variant, languages: languages)
            if score(candidate) > score(best) {
                best = candidate
            }
        }
        return best
    }

    private static func recognitionLanguages(extraLanguages: [String]) -> [String] {
        var langs = baseLanguages
        for lang in extraLanguages where !langs.contains(lang) {
            langs.insert(lang, at: 0)
        }
        return langs
    }

    private static func performRecognition(in image: UIImage, languages: [String]) async -> [TextObservation] {
        guard let cgImage = image.cgImage else { return [] }

        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.recognitionLanguages = languages.map(Locale.Language.init(identifier:))

        let observations: [RecognizedTextObservation]
        do {
            observations = try await request.perform(on: cgImage)
        } catch {
            return []
        }

        return observations.compactMap { ob in
            guard let candidate = ob.topCandidates(1).first else { return nil }
            let vb = ob.boundingBox
            let uiRect = CGRect(
                x: vb.origin.x,
                y: 1.0 - vb.origin.y - vb.height,
                width: vb.width,
                height: vb.height
            )
            return TextObservation(
                text: candidate.string,
                boundingRect: uiRect,
                confidence: Double(candidate.confidence)
            )
        }
    }

    private static func recognizedCharacterCount(in observations: [TextObservation]) -> Int {
        observations.reduce(0) { $0 + $1.text.trimmingCharacters(in: .whitespacesAndNewlines).count }
    }

    private static func score(_ observations: [TextObservation]) -> Int {
        (observations.count * 24) + recognizedCharacterCount(in: observations)
    }

    private static func makeOCRVariants(from image: UIImage) -> [UIImage] {
        guard let cgImage = image.cgImage else { return [] }
        let ciImage = CIImage(cgImage: cgImage)
        let context = CIContext(options: [.useSoftwareRenderer: false])
        var variants: [UIImage] = []

        func renderedImage(from ci: CIImage) -> UIImage? {
            guard let out = context.createCGImage(ci, from: ci.extent) else { return nil }
            return UIImage(cgImage: out, scale: image.scale, orientation: image.imageOrientation)
        }

        let grayscale = CIFilter.colorControls()
        grayscale.inputImage = ciImage
        grayscale.saturation = 0
        grayscale.brightness = 0.03
        grayscale.contrast = 1.22
        if let img = grayscale.outputImage.flatMap(renderedImage(from:)) {
            variants.append(img)
        }

        let highContrast = CIFilter.colorControls()
        highContrast.inputImage = ciImage
        highContrast.saturation = 0
        highContrast.brightness = 0.07
        highContrast.contrast = 1.55
        if let contrastCI = highContrast.outputImage {
            let sharpen = CIFilter.sharpenLuminance()
            sharpen.inputImage = contrastCI
            sharpen.sharpness = 0.45
            if let img = sharpen.outputImage.flatMap(renderedImage(from:)) {
                variants.append(img)
            }
        }
        return variants
    }

    static func extractFields(from lines: [String]) -> DocumentFields {
        let strictKYC = UserDefaults.standard.bool(forKey: "shield.ocr.strictKYC")
        let parsedMRZ = parseMRZ(from: lines, strictKYC: strictKYC)
        var fieldConfidence: [String: Double] = [:]

        var docNum = ""
        var supportNum: String? = nil
        var fullName = ""
        var dob = ""
        var expires = ""
        var nationality = ""
        var sex = ""
        var address = ""
        var mrz: String? = nil
        var mrzValid: Bool? = nil
        var mrzFormat: String? = nil

        if let parsedMRZ {
            docNum = parsedMRZ.documentNumber
            supportNum = parsedMRZ.supportNumber
            fullName = parsedMRZ.fullName
            dob = parsedMRZ.dateOfBirth
            expires = parsedMRZ.expires
            nationality = parsedMRZ.nationality
            sex = parsedMRZ.sex
            mrz = parsedMRZ.rawMRZ
            mrzValid = parsedMRZ.isCheckDigitValid
            mrzFormat = parsedMRZ.format
            let baseConfidence = parsedMRZ.isCheckDigitValid ? 0.98 : 0.78
            fieldConfidence["documentNumber"] = baseConfidence
            fieldConfidence["fullName"] = baseConfidence
            fieldConfidence["dateOfBirth"] = baseConfidence
            fieldConfidence["expires"] = baseConfidence
            fieldConfidence["nationality"] = baseConfidence
            fieldConfidence["sex"] = baseConfidence
            if parsedMRZ.supportNumber != nil { fieldConfidence["supportNumber"] = baseConfidence }
        }

        if dob.isEmpty || expires.isEmpty {
            let datePattern = "\\b(\\d{1,2}[/._-]\\d{1,2}[/._-]\\d{2,4}|\\d{1,2}\\s+\\d{1,2}\\s+\\d{4}|\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{2,4})\\b"
            let dateRegex = try? NSRegularExpression(pattern: datePattern, options: .caseInsensitive)
            var dates: [String] = []
            for line in lines {
                let range = NSRange(line.startIndex..., in: line)
                let matches = dateRegex?.matches(in: line, range: range) ?? []
                for match in matches {
                    if let r = Range(match.range, in: line) {
                        dates.append(String(line[r]))
                    }
                }
            }
            if dob.isEmpty, dates.count >= 1 { dob = dates[0] }
            if expires.isEmpty, dates.count >= 2 { expires = dates[1] }
            if fieldConfidence["dateOfBirth"] == nil, !dob.isEmpty { fieldConfidence["dateOfBirth"] = 0.62 }
            if fieldConfidence["expires"] == nil, !expires.isEmpty { fieldConfidence["expires"] = 0.62 }
        }

        if fullName.isEmpty {
            let issuingKeywords = ["REINO", "REPUBLIC", "REPUBLICA", "KINGDOM", "NATIONAL",
                                   "DOCUMENT", "DOCUMENTO", "IDENTITY", "IDENTIDAD", "PASSPORT",
                                   "PASAPORTE", "LICENSE", "LICENCIA", "MINISTRY", "MINISTERIO",
                                   "GOVERNMENT", "GOBIERNO", "ESTADO", "STATE", "UNION"]
            let nameLines = lines.filter { l in
                let stripped = l.trimmingCharacters(in: .whitespaces)
                guard stripped.count >= 3, stripped.count <= 60 else { return false }
                guard !stripped.contains("<"), !stripped.contains("/") else { return false }
                let upper = stripped.uppercased()
                guard upper == stripped, stripped.rangeOfCharacter(from: .decimalDigits) == nil else { return false }
                return !issuingKeywords.contains(where: { upper.contains($0) })
            }
            if !nameLines.isEmpty {
                let merged = nameLines.prefix(3).joined(separator: " ")
                fullName = merged.count <= 80 ? merged : nameLines[0]
            }
            if fieldConfidence["fullName"] == nil, !fullName.isEmpty { fieldConfidence["fullName"] = 0.58 }
        }

        if docNum.isEmpty {
            let labelPattern = "(?:DNI|N[IÍ]D|DOC(?:UMENTO)?\\s*(?:N(?:[ÚU])?M(?:ERO)?)?|N(?:[ÚU])?M(?:ERO)?\\s*DOC(?:UMENTO)?|IDENT(?:ITY)?\\s*(?:NO|NUMBER)?)\\s*[:#-]?\\s*([A-Z0-9\\s-]{6,20})"
            let labelRegex = try? NSRegularExpression(pattern: labelPattern, options: .caseInsensitive)
            for line in lines {
                let upper = line.uppercased()
                guard !upper.contains("SOPORT") else { continue }
                let range = NSRange(upper.startIndex..., in: upper)
                guard let match = labelRegex?.firstMatch(in: upper, range: range),
                      let r = Range(match.range(at: 1), in: upper) else { continue }

                let raw = String(upper[r])
                let compact = raw.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
                guard compact.count >= 7 else { continue }
                if let spanish = validateSpanishID(compact) {
                    docNum = spanish.value
                    fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.95)
                    break
                }
                let hasLetters = compact.rangeOfCharacter(from: .letters) != nil
                let hasDigits = compact.rangeOfCharacter(from: .decimalDigits) != nil
                if hasLetters && hasDigits && compact.count >= 8 {
                    docNum = compact
                    fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.83)
                    break
                }
            }
        }

        if docNum.isEmpty {
            let docPattern = "\\b([A-Z0-9][A-Z0-9\\s-]{6,20})\\b"
            let docRegex = try? NSRegularExpression(pattern: docPattern)
            var best: (value: String, score: Double)? = nil
            for line in lines {
                let upper = line.uppercased()
                let range = NSRange(upper.startIndex..., in: upper)
                let matches = docRegex?.matches(in: upper, range: range) ?? []

                for match in matches {
                    guard let r = Range(match.range(at: 1), in: upper) else { continue }
                    let raw = String(upper[r]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let compact = raw.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
                    guard compact.count >= 7, compact.count <= 16 else { continue }
                    guard !compact.contains("REINODE"), !compact.contains("DOCUMENTO"), !compact.contains("IDENTIDAD") else { continue }

                    if let spanish = validateSpanishID(compact) {
                        best = (spanish.value, max(best?.score ?? 0, 0.94))
                        continue
                    }

                    let hasLetters = compact.rangeOfCharacter(from: .letters) != nil
                    let hasDigits = compact.rangeOfCharacter(from: .decimalDigits) != nil
                    guard hasLetters && hasDigits else { continue }

                    var score = 0.60
                    if upper.contains("DNI") || upper.contains("DOC") || upper.contains("IDENT") { score += 0.18 }
                    if upper.contains("SOPORT") { score -= 0.15 }
                    if compact.count == 9 { score += 0.05 }
                    if let current = best {
                        if score > current.score { best = (compact, score) }
                    } else {
                        best = (compact, score)
                    }
                }
            }
            if let best {
                docNum = best.value
                fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, best.score)
            }
        }

        if fieldConfidence["documentNumber"] == nil, !docNum.isEmpty {
            fieldConfidence["documentNumber"] = 0.6
        }

        if address.isEmpty {
            let upperLines = lines.map { $0.uppercased() }
            for (i, line) in upperLines.enumerated() {
                if (line.contains("DOMICILIO") || line.contains("DOMICILI")) && i + 1 < upperLines.count {
                    var parts: [String] = []
                    for j in (i + 1)..<min(i + 4, lines.count) {
                        let part = lines[j].trimmingCharacters(in: .whitespaces)
                        let up = part.uppercased()
                        if up.contains("LUGAR") || up.contains("HIJOA") || up.contains("HIJO") ||
                            up.contains("NACIMIENTO") || up.contains("MRZ") || part.isEmpty { break }
                        parts.append(part)
                    }
                    if !parts.isEmpty {
                        address = parts.joined(separator: ", ")
                        fieldConfidence["address"] = 0.82
                        break
                    }
                }
            }
        }

        if address.isEmpty {
            let addrPattern = "\\d+.*\\b(CALLE|C/|AVE|AVENUE|ROAD|RD|STREET|ST|LANE|LN|DR|DRIVE|BLVD|C\\.|CL\\.)\\b"
            let addrRegex = try? NSRegularExpression(pattern: addrPattern, options: .caseInsensitive)
            for line in lines {
                let range = NSRange(line.startIndex..., in: line)
                if addrRegex?.firstMatch(in: line, range: range) != nil {
                    address = line
                    fieldConfidence["address"] = 0.52
                    break
                }
            }
        }

        if let normalizedSpanish = normalizeSpanishID(from: lines), !normalizedSpanish.value.isEmpty {
            docNum = normalizedSpanish.value
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, normalizedSpanish.confidence)
            if nationality.isEmpty { nationality = "ESP" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.86)
        }

        if let curp = extractCURP(from: lines), !curp.isEmpty {
            if docNum.isEmpty { docNum = curp }
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.84)
            if nationality.isEmpty { nationality = "MEX" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.84)
        }

        if let cpf = extractBrazilianCPF(from: lines), !cpf.isEmpty {
            if docNum.isEmpty { docNum = cpf }
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.88)
            if nationality.isEmpty { nationality = "BRA" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.88)
        }

        if let rut = extractChileanRUT(from: lines), !rut.isEmpty {
            if docNum.isEmpty { docNum = rut }
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.86)
            if nationality.isEmpty { nationality = "CHL" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.86)
        }

        if let aadhaar = extractAadhaar(from: lines), !aadhaar.isEmpty {
            if docNum.isEmpty { docNum = aadhaar }
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.90)
            if nationality.isEmpty { nationality = "IND" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.90)
        }

        if docNum.isEmpty, let pan = extractIndianPAN(from: lines), !pan.isEmpty {
            docNum = pan
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.88)
            if nationality.isEmpty { nationality = "IND" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.88)
        }

        if docNum.isEmpty, let nino = extractUKNINO(from: lines), !nino.isEmpty {
            docNum = nino
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.87)
            if nationality.isEmpty { nationality = "GBR" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.87)
        }

        if docNum.isEmpty, let deId = extractGermanID(from: lines), !deId.isEmpty {
            docNum = deId
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.82)
            if nationality.isEmpty { nationality = "DEU" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.82)
        }

        if docNum.isEmpty, let nir = extractFrenchNIR(from: lines), !nir.isEmpty {
            docNum = nir
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.82)
            if nationality.isEmpty { nationality = "FRA" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.82)
        }

        if docNum.isEmpty, let argDNI = extractArgentineDNI(from: lines), !argDNI.isEmpty {
            docNum = argDNI
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.78)
            if nationality.isEmpty { nationality = "ARG" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.78)
        }

        if docNum.isEmpty, let cc = extractColombianCC(from: lines), !cc.isEmpty {
            docNum = cc
            fieldConfidence["documentNumber"] = max(fieldConfidence["documentNumber"] ?? 0, 0.80)
            if nationality.isEmpty { nationality = "COL" }
            fieldConfidence["nationality"] = max(fieldConfidence["nationality"] ?? 0, 0.80)
        }

        if address.isEmpty {
            address = extractInternationalAddress(from: lines) ?? ""
            if !address.isEmpty { fieldConfidence["address"] = 0.52 }
        }

        if supportNum == nil {
            let upperLines = lines.map { $0.uppercased() }
            let labelPattern = try? NSRegularExpression(
                pattern: "NUM\\s+SOPORT[EO]?[\\s:/]*([A-Z]{2,3}[0-9]{5,8})",
                options: .caseInsensitive
            )
            for line in upperLines {
                if let m = labelPattern?.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                   let r = Range(m.range(at: 1), in: line) {
                    supportNum = String(line[r])
                    fieldConfidence["supportNumber"] = 0.88
                    break
                }
            }

            if supportNum == nil {
                for (i, line) in upperLines.enumerated() where i + 1 < upperLines.count {
                    if line.contains("NUM SOPORT") || line.contains("NÚM SUPORT") || line.contains("NUM SUPORT") {
                        let next = upperLines[i + 1].trimmingCharacters(in: .whitespaces)
                        let valuePattern = try? NSRegularExpression(pattern: "^([A-Z]{2,3}[0-9]{5,8})$")
                        if let m = valuePattern?.firstMatch(in: next, range: NSRange(next.startIndex..., in: next)),
                           let r = Range(m.range(at: 1), in: next) {
                            supportNum = String(next[r])
                            fieldConfidence["supportNumber"] = 0.85
                            break
                        }
                    }
                }
            }
        }

        return DocumentFields(
            documentNumber: docNum,
            supportNumber: supportNum,
            fullName: fullName,
            dateOfBirth: dob,
            nationality: nationality,
            expires: expires,
            sex: sex,
            address: address,
            issued: nil,
            mrz: mrz,
            ocrDocumentType: nil,
            ocrFullText: nil,
            ocrPageTexts: nil,
            ocrMRZValid: mrzValid,
            ocrMRZFormat: mrzFormat,
            ocrFieldConfidence: fieldConfidence.isEmpty ? nil : fieldConfidence,
            ocrDetectedCountry: nil,
            ocrRiskLevel: nil,
            ocrLowConfidenceFields: nil
        )
    }

    static func recognizeText(in images: [UIImage], extraLanguages: [String] = []) async -> [String] {
        guard !images.isEmpty else { return [] }
        var merged: [String] = []
        for image in images {
            let pageLines = await recognizeText(in: image, extraLanguages: extraLanguages)
            merged.append(contentsOf: pageLines)
        }
        return merged
    }

    static func recognizeTextByPage(in images: [UIImage], extraLanguages: [String] = []) async -> [[String]] {
        guard !images.isEmpty else { return [] }
        return await withTaskGroup(of: (Int, [String]).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let lines = await recognizeText(in: image, extraLanguages: extraLanguages)
                    return (index, lines)
                }
            }
            var results = [(Int, [String])]()
            results.reserveCapacity(images.count)
            for await result in group {
                results.append(result)
            }
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }

    static func recognizeObservationsByPageAdaptive(in images: [UIImage]) async -> [[TextObservation]] {
        let firstPass = await recognizeObservationsByPage(in: images)
        let allLines = firstPass.flatMap { $0 }.map(\.text)
        let country = detectCountryHint(from: allLines)
        let extra = languagesForCountry(country)
        guard !extra.isEmpty else { return firstPass }
        return await recognizeObservationsByPage(in: images, extraLanguages: extra)
    }

    static func recognizeTextByPageAdaptive(in images: [UIImage]) async -> [[String]] {
        let obs = await recognizeObservationsByPageAdaptive(in: images)
        return obs.map { $0.map(\.text) }
    }

    static func recognizeObservationsByPage(
        in images: [UIImage],
        extraLanguages: [String] = []
    ) async -> [[TextObservation]] {
        guard !images.isEmpty else { return [] }
        return await withTaskGroup(of: (Int, [TextObservation]).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let obs = await recognizeTextWithObservations(in: image, extraLanguages: extraLanguages)
                    return (index, obs)
                }
            }
            var results = [(Int, [TextObservation])]()
            results.reserveCapacity(images.count)
            for await result in group { results.append(result) }
            return results.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    static func buildPageEvidence(
        observations pages: [[TextObservation]],
        extractedFields: [DocumentFields]
    ) -> [OCRPageEvidence] {
        pages.enumerated().map { pageIndex, pageObservations in
            let evidence = pageObservations.map { observation in
                OCRTextEvidence(
                    pageIndex: pageIndex,
                    text: observation.text,
                    boundingRect: observation.boundingRect,
                    confidence: observation.confidence
                )
            }
            let fields = extractedFields.indices.contains(pageIndex)
                ? extractedFields[pageIndex]
                : .empty
            let candidates: [(OCRSensitiveEntityKind, String, String, String?)] = [
                (.documentNumber, fields.documentNumber, "documentNumber", "document-number"),
                (.supportNumber, fields.supportNumber ?? "", "supportNumber", "support-number"),
                (.fullName, fields.fullName, "fullName", "named-entity"),
                (.dateOfBirth, fields.dateOfBirth, "dateOfBirth", "date"),
                (.nationality, fields.nationality, "nationality", "country-code"),
                (.expirationDate, fields.expires, "expires", "date"),
                (.address, fields.address, "address", "address"),
                (.mrz, fields.mrz ?? "", "mrz", fields.ocrMRZValid == true ? "icao-check-digits" : "icao-structure")
            ]

            var entities: [OCRSensitiveEntity] = candidates.compactMap { candidate in
                let (kind, value, confidenceKey, validator) = candidate
                let normalizedValue = evidenceComparable(value)
                guard !normalizedValue.isEmpty else { return nil }
                let matches = evidence.filter { observation in
                    let token = evidenceComparable(observation.text)
                    guard token.count >= 3 else { return false }
                    return token == normalizedValue ||
                        normalizedValue.contains(token) ||
                        token.contains(normalizedValue)
                }
                guard !matches.isEmpty else { return nil }
                let visionConfidence = matches.map(\.confidence).reduce(0, +) / Double(matches.count)
                let extractionConfidence = fields.ocrFieldConfidence?[confidenceKey]
                let combinedConfidence = extractionConfidence.map { min($0, visionConfidence) }
                    ?? visionConfidence
                return OCRSensitiveEntity(
                    kind: kind,
                    value: value,
                    pageIndex: pageIndex,
                    evidenceIDs: matches.map(\.id),
                    confidence: combinedConfidence,
                    validator: validator
                )
            }
            entities.append(contentsOf: patternEntities(in: evidence, pageIndex: pageIndex))
            return OCRPageEvidence(
                pageIndex: pageIndex,
                observations: evidence,
                entities: entities
            )
        }
    }

    private static func patternEntities(
        in observations: [OCRTextEvidence],
        pageIndex: Int
    ) -> [OCRSensitiveEntity] {
        var entities: [OCRSensitiveEntity] = []
        var seen = Set<String>()

        func append(
            kind: OCRSensitiveEntityKind,
            value: String,
            evidence: OCRTextEvidence,
            validator: String,
            confidence: Double
        ) {
            let canonical = evidenceComparable(value)
            let key = "\(kind.rawValue)|\(canonical)"
            guard canonical.count >= 4, seen.insert(key).inserted else { return }
            entities.append(OCRSensitiveEntity(
                kind: kind,
                value: value,
                pageIndex: pageIndex,
                evidenceIDs: [evidence.id],
                confidence: min(evidence.confidence, confidence),
                validator: validator
            ))
        }

        for observation in observations {
            let text = observation.text
            for value in matches(pattern: #"[A-Z0-9._%+\-]+@[A-Z0-9.\-]+\.[A-Z]{2,}"#, text: text) {
                append(kind: .email, value: value, evidence: observation, validator: "rfc5322-shape", confidence: 0.96)
            }

            for value in matches(pattern: #"\b[A-Z]{2}\s?\d{2}(?:[\s\-]?[A-Z0-9]){11,30}\b"#, text: text) {
                if isValidIBAN(value) {
                    append(kind: .iban, value: value, evidence: observation, validator: "iso13616-mod97", confidence: 0.98)
                }
            }

            for value in matches(pattern: #"\b(?:\d[ -]?){13,19}\b"#, text: text) {
                if isValidPaymentCard(value) {
                    append(kind: .paymentCard, value: value, evidence: observation, validator: "luhn", confidence: 0.97)
                }
            }

            for value in matches(pattern: #"(?<!\w)(?:\+?\d{1,3}[ .-]?)?(?:\(?\d{2,4}\)?[ .-]?){2,4}\d{2,4}(?!\w)"#, text: text) {
                let digits = value.filter(\.isNumber)
                guard (9...15).contains(digits.count), !isValidPaymentCard(value) else { continue }
                append(kind: .phoneNumber, value: value, evidence: observation, validator: "e164-shape", confidence: 0.78)
            }
        }
        return entities
    }

    private static func matches(pattern: String, text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let swiftRange = Range(match.range, in: text) else { return nil }
            return String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    private static func isValidIBAN(_ value: String) -> Bool {
        let compact = value.uppercased().filter { $0.isLetter || $0.isNumber }
        guard (15...34).contains(compact.count),
              compact.prefix(2).allSatisfy({ $0.isLetter }),
              compact.dropFirst(2).prefix(2).allSatisfy({ $0.isNumber }) else { return false }
        let rearranged = String(compact.dropFirst(4)) + String(compact.prefix(4))
        var remainder = 0
        for character in rearranged {
            let expansion: String
            if let digit = character.wholeNumberValue {
                expansion = String(digit)
            } else if let ascii = character.asciiValue {
                expansion = String(Int(ascii) - 55)
            } else {
                return false
            }
            for digit in expansion.compactMap(\.wholeNumberValue) {
                remainder = (remainder * 10 + digit) % 97
            }
        }
        return remainder == 1
    }

    private static func isValidPaymentCard(_ value: String) -> Bool {
        let digits = value.compactMap(\.wholeNumberValue)
        guard (13...19).contains(digits.count), Set(digits).count > 1 else { return false }
        let sum = digits.reversed().enumerated().reduce(0) { partial, item in
            let (index, digit) = item
            guard index % 2 == 1 else { return partial + digit }
            let doubled = digit * 2
            return partial + (doubled > 9 ? doubled - 9 : doubled)
        }
        return sum.isMultiple(of: 10)
    }

    private static func evidenceComparable(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .uppercased()
            .replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
    }

    private static func detectCountryHint(from lines: [String]) -> String? {
        let combined = lines.joined(separator: " ").uppercased()
        let patterns: [(pattern: String, country: String)] = [
            ("中华人民共和国|中华人民|居民身份证", "CHN"),
            ("中華民國|臺灣|台湾", "TWN"),
            ("日本国|日本国旅券|JAPAN", "JPN"),
            ("대한민국|REPUBLIC OF KOREA", "KOR"),
            ("INDIA|AADHAAR|आधार|ELECTION COMMISSION OF INDIA|REPUBLIC OF INDIA", "IND"),
            ("THAILAND|ราชอาณาจักรไทย", "THA"),
            ("VIET NAM|VIỆT NAM|CỘNG HÒA XÃ HỘI", "VNM"),
            ("INDONESIA|REPUBLIK INDONESIA|KTP", "IDN"),
            ("MALAYSIA|MYKAD|MYKID", "MYS"),
            ("PHILIPPINES|PILIPINAS|REPUBLIKA NG", "PHL"),
            ("المملكة العربية السعودية|KINGDOM OF SAUDI|SAUDI ARABIA", "SAU"),
            ("UNITED ARAB EMIRATES|الإمارات العربية|EMIRATES", "ARE"),
            ("دولة قطر|STATE OF QATAR|QATAR", "QAT"),
            ("مملكة البحرين|KINGDOM OF BAHRAIN|BAHRAIN", "BHR"),
            ("سلطنة عُمان|SULTANATE OF OMAN|OMAN", "OMN"),
            ("دولة الكويت|STATE OF KUWAIT|KUWAIT", "KWT"),
            ("المملكة المغربية|KINGDOM OF MOROCCO|MAROC|MOROCCO", "MAR"),
            ("الجمهورية التونسية|TUNISIE|TUNISIA", "TUN"),
            ("الجمهورية الجزائرية|ALGERIE|ALGERIA", "DZA"),
            ("جمهورية مصر العربية|EGYPT|EGYPTE", "EGY"),
            ("إسرائيל|ISRAEL|מדינת ישראל", "ISR"),
            ("جمهورية العراق|IRAQ", "IRQ"),
            ("الجمهورية اللبنانية|LIBAN|LEBANON", "LBN"),
            ("تركيا|TÜRKIYE|TURKEY|TÜRK", "TUR"),
            ("РОССИЙСКАЯ ФЕДЕРАЦИЯ|РОССИЯ|RUSSIAN FEDERATION", "RUS"),
            ("УКРАЇНА|UKRAINE", "UKR"),
            ("БЕЛАРУСЬ|REPUBLIC OF BELARUS|BELARUS", "BLR"),
            ("КАЗАХСТАН|KAZAKHSTAN|ҚАЗАҚСТАН", "KAZ"),
            ("RZECZPOSPOLITA POLSKA|POLSKA|POLAND", "POL"),
            ("ČESKÁ REPUBLIKA|CZECH REPUBLIC|CZECHIA", "CZE"),
            ("SLOVENSKÁ REPUBLIKA|SLOVAK REPUBLIC|SLOVAKIA", "SVK"),
            ("MAGYARORSZÁG|HUNGARY", "HUN"),
            ("ROMÂNIA|ROMANIA", "ROU"),
            ("БЪЛГАРИЯ|REPUBLIC OF BULGARIA|BULGARIA", "BGR"),
            ("HRVATSKA|REPUBLIC OF CROATIA|CROATIA", "HRV"),
            ("SRBIJA|REPUBLIC OF SERBIA|SERBIA", "SRB"),
            ("SVERIGE|SWEDEN|KUNGARIKET SVERIGE", "SWE"),
            ("NOREG|NORGE|NORWAY|KINGDOM OF NORWAY", "NOR"),
            ("DANMARK|DENMARK|KONGERIGET", "DNK"),
            ("SUOMI|FINLAND", "FIN"),
            ("NEDERLAND|KONINKRIJK|NETHERLANDS", "NLD"),
            ("BELGIQUE|BELGIË|BELGIUM|BELGIEN", "BEL"),
            ("SCHWEIZ|SUISSE|SVIZZERA|SWITZERLAND", "CHE"),
            ("ÖSTERREICH|AUSTRIA|REPUBLIC OF AUSTRIA", "AUT"),
            ("REPÚBLICA ARGENTINA|ARGENTINA", "ARG"),
            ("REPÚBLICA DE COLOMBIA|COLOMBIA", "COL"),
            ("REPÚBLICA DE CHILE|CHILE", "CHL"),
            ("REPÚBLICA DEL PERÚ|PERÚ|PERU", "PER"),
            ("REPÚBLICA FEDERATIVA DO BRASIL|BRASIL|BRAZIL", "BRA"),
            ("REPÚBLICA PORTUGUESA|PORTUGAL", "PRT"),
            ("REINO DE ESPAÑA|ESPAÑA|SPAIN|DNI|DOCUMENTO NACIONAL DE IDENTIDAD", "ESP"),
            ("ITALIA|ITALIANA|CARTA D.IDENTIT|REPUBBLICA ITALIANA", "ITA"),
            ("REPUBLIQUE FRANÇAISE|FRANCE|FRANCAISE", "FRA"),
            ("BUNDESREPUBLIK DEUTSCHLAND|GERMANY|DEUTSCHLAND", "DEU"),
            ("UNITED KINGDOM|GREAT BRITAIN|UK PASSPORT|DRIVING LICENCE|DRIVER", "GBR"),
            ("UNITED STATES|USA|UNITED STATES OF AMERICA", "USA"),
            ("CANADA|CANADIEN|CANADIENNE", "CAN"),
            ("AUSTRALIA|COMMONWEALTH OF AUSTRALIA", "AUS"),
        ]
        for entry in patterns {
            if combined.range(of: entry.pattern, options: [.regularExpression]) != nil {
                return entry.country
            }
        }
        return nil
    }

    static func detectDocumentType(from lines: [String]) -> DetectedDocumentType {
        let strictKYC = UserDefaults.standard.bool(forKey: "shield.ocr.strictKYC")
        if let parsed = parseMRZ(from: lines, strictKYC: strictKYC) {
            switch parsed.documentCode {
            case "P", "PM", "PN":
                return .passport
            case "V", "VF", "VE", "VI", "VT":
                return .visa
            case "I", "ID", "A", "C", "AC":
                return .dni
            case "R", "RI":
                return .residencePermit
            default:
                break
            }
        }

        guard !lines.isEmpty else { return .document }
        let compact = lines.map { $0.uppercased() }
        let combined = compact.joined(separator: "\n")
        let mrzLines = compact.filter { $0.contains("<") && $0.count >= 20 }

        if mrzLines.contains(where: { $0.hasPrefix("V<") || $0.hasPrefix("V ") }) ||
            combined.contains("VISA") || combined.contains("VISUM") || combined.contains("VISAS") {
            return .visa
        }

        if mrzLines.contains(where: { $0.hasPrefix("P<") || $0.hasPrefix("PM<") || $0.hasPrefix("PN<") }) ||
            combined.contains("PASSPORT") || combined.contains("PASSEPORT") ||
            combined.contains("PASAPORTE") || combined.contains("REISEPASS") ||
            combined.contains("PASSAPORTO") || combined.contains("PASPOORT") ||
            combined.contains("PASAPORT") || combined.contains("ПАСПОРТ") ||
            combined.contains("护照") || combined.contains("旅券") || combined.contains("여권") ||
            combined.contains("पासपोर्ट") {
            return .passport
        }

        if combined.contains("DRIVING LICENCE") || combined.contains("DRIVER") ||
            combined.contains("PERMIS DE CONDUIRE") || combined.contains("FÜHRERSCHEIN") ||
            combined.contains("PATENTE") || combined.contains("LICENCIA DE CONDUCIR") ||
            combined.contains("RIJBEWIJS") || combined.contains("PRAWO JAZDY") ||
            combined.contains("CARTA DE CONDUÇÃO") || combined.contains("CARTEIRA DE HABILITAÇÃO") ||
            combined.contains("ВОДИТЕЛЬСКОЕ УДОСТОВЕРЕНИЕ") || combined.contains("AJOKORTTI") ||
            combined.contains("KØREKORT") || combined.contains("KÖRKORT") ||
            combined.contains("FØRERBEVIS") || combined.contains("PRAVOVOŽNJE") ||
            combined.contains("运动驾驶证") || combined.contains("驾驶证") ||
            combined.contains("DRIVER'S LICENSE") || combined.contains("OPERATOR LICENSE") {
            return .drivingLicense
        }

        if combined.contains("RESIDENCE PERMIT") || combined.contains("PERMIS DE RÉSIDENCE") ||
            combined.contains("AUFENTHALTSTITEL") || combined.contains("PERMESSO DI SOGGIORNO") ||
            combined.contains("VERBLIJFSVERGUNNING") || combined.contains("PERMISO DE RESIDENCIA") ||
            combined.contains("AUTORIZACIÓN DE RESIDENCIA") ||
            combined.contains("NIE") || combined.contains("NÚMERO DE IDENTIDAD DE EXTRANJERO") ||
            combined.contains("TITRE DE SÉJOUR") || combined.contains("CARTA DI SOGGIORNO") ||
            combined.contains("BIOMETRIC RESIDENCE") || combined.contains("BRP") ||
            combined.contains("GREEN CARD") || combined.contains("PERMANENT RESIDENT") ||
            combined.contains("ЗЕЛЕНАЯ КАРТА") || combined.contains("ВНЖ") {
            return .residencePermit
        }

        if combined.contains("HEALTH CARD") || combined.contains("INSURANCE CARD") ||
            combined.contains("CARTE VITALE") || combined.contains("CARTE D'ASSURANCE") ||
            combined.contains("KRANKENVERSICHERUNG") || combined.contains("GESUNDHEITSKARTE") ||
            combined.contains("EHIC") || combined.contains("GHIC") ||
            combined.contains("EUROPEAN HEALTH INSURANCE") ||
            combined.contains("TARJETA SANITARIA") || combined.contains("SIP") ||
            combined.contains("TESSERA SANITARIA") || combined.contains("CARTÃO DE SAÚDE") {
            return .healthCard
        }

        if mrzLines.contains(where: { $0.hasPrefix("ID") || $0.hasPrefix("I<") || $0.hasPrefix("A<") || $0.hasPrefix("C<") }) ||
            combined.contains("NATIONAL IDENTITY") || combined.contains("IDENTITY CARD") ||
            combined.contains("DOCUMENTO NACIONAL") || combined.contains("CARTA D'IDENTIT") ||
            combined.contains("PERSONALAUSWEIS") || combined.contains("CARTE NATIONALE D'IDENTIT") ||
            combined.contains("IDENTITEITSKAART") || combined.contains("DOWÓD OSOBISTY") ||
            combined.contains("SZEMÉLYIGAZOLVÁNY") || combined.contains("BULETIN DE IDENTITATE") ||
            combined.contains("CEDULA") || combined.contains("CÉDULA") ||
            combined.contains("DOCUMENTO DE IDENTIDAD") || combined.contains("TARJETA DE IDENTIDAD") ||
            combined.contains("CARTÃO DE CIDADÃO") || combined.contains("BILHETE DE IDENTIDADE") ||
            combined.contains("DNI") || combined.contains("NIF") ||
            combined.contains("NATIONAL ID") || combined.contains("NATL ID") ||
            combined.contains("身份证") || combined.contains("주민등록증") ||
            combined.contains("AADHAR") || combined.contains("AADHAAR") ||
            combined.contains("VOTER ID") || combined.contains("ELECTION COMMISSION") {
            return .dni
        }

        return .document
    }

    static func minimumConfidenceThreshold() -> Double {
        let index = UserDefaults.standard.integer(forKey: "shield.ocr.minConfidence")
        switch index {
        case 0: return 0.70
        case 1: return 0.80
        case 2: return 0.90
        default: return 0.80
        }
    }

    static func assessRisk(fields: DocumentFields, detectedType: DetectedDocumentType, threshold: Double) -> (level: OCRRiskLevel, lowFields: [String]) {
        let confidence = fields.ocrFieldConfidence ?? [:]
        let criticalKeys: [String]
        switch detectedType {
        case .passport, .visa:
            criticalKeys = ["documentNumber", "fullName", "dateOfBirth", "expires"]
        case .dni, .residencePermit:
            criticalKeys = ["documentNumber", "fullName", "dateOfBirth", "expires"]
        case .drivingLicense:
            criticalKeys = ["documentNumber", "fullName", "dateOfBirth"]
        case .healthCard, .document:
            criticalKeys = ["documentNumber", "fullName"]
        }

        let lowFields = criticalKeys.filter { key in
            let value = confidence[key] ?? 0
            return value < threshold
        }

        if lowFields.isEmpty {
            return (.low, [])
        } else if lowFields.count >= max(2, criticalKeys.count / 2) {
            return (.high, lowFields)
        } else {
            return (.medium, lowFields)
        }
    }

    private struct ParsedMRZ {
        let format: String
        let documentCode: String
        let documentNumber: String
        let supportNumber: String?
        let fullName: String
        let dateOfBirth: String
        let expires: String
        let nationality: String
        let sex: String
        let rawMRZ: String
        let isCheckDigitValid: Bool
    }

    private static func parseMRZ(from lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        let candidates = normalizedMRZLines(lines)
        guard !candidates.isEmpty else { return nil }

        if let parsed = parseTD3(lines: candidates, strictKYC: strictKYC) { return parsed }
        if let parsed = parseTD1(lines: candidates, strictKYC: strictKYC) { return parsed }
        if let parsed = parseTD2(lines: candidates, strictKYC: strictKYC) { return parsed }
        if let parsed = parseMRVA(lines: candidates, strictKYC: strictKYC) { return parsed }
        if let parsed = parseMRVB(lines: candidates, strictKYC: strictKYC) { return parsed }
        return nil
    }

    private static func parseTD2(lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        guard lines.count >= 2 else { return nil }
        for i in 0..<(lines.count - 1) {
            var line1 = lines[i]
            var line2 = lines[i + 1]
            guard line1.count >= 36, line2.count >= 36 else { continue }
            guard let firstTwo = line1.first.map(String.init), firstTwo != "V" else { continue }
            guard !line1.hasPrefix("P<") else { continue }
            line1 = String(line1.prefix(36))
            line2 = String(line2.prefix(36))

            let documentCode = cleanField(mrzSlice(line1, 0, 2))
            let docNumber = cleanField(mrzSlice(line2, 0, 9))
            let nationality = cleanField(mrzSlice(line2, 10, 3))
            let dob = mrzSlice(line2, 13, 6)
            let sex = cleanField(mrzSlice(line2, 20, 1))
            let expires = mrzSlice(line2, 21, 6)
            let nameField = mrzSlice(line1, 5, 31)
            let fullName = parseMRZName(nameField)

            let checkDoc = validateMRZCheckDigit(data: mrzSlice(line2, 0, 9), checkDigit: mrzSlice(line2, 9, 1))
            let checkDob = validateMRZCheckDigit(data: mrzSlice(line2, 13, 6), checkDigit: mrzSlice(line2, 19, 1))
            let checkExp = validateMRZCheckDigit(data: mrzSlice(line2, 21, 6), checkDigit: mrzSlice(line2, 27, 1))
            let allValid = checkDoc && checkDob && checkExp

            if strictKYC && !allValid { continue }
            guard checkDoc || checkDob else { continue }

            return ParsedMRZ(
                format: "TD2",
                documentCode: documentCode,
                documentNumber: docNumber,
                supportNumber: nil,
                fullName: fullName,
                dateOfBirth: normalizeMRZDate(dob),
                expires: normalizeMRZDate(expires),
                nationality: nationality,
                sex: sex,
                rawMRZ: line1 + "\n" + line2,
                isCheckDigitValid: allValid
            )
        }
        return nil
    }

    private static func parseMRVA(lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        guard lines.count >= 2 else { return nil }
        for i in 0..<(lines.count - 1) {
            var line1 = lines[i]
            var line2 = lines[i + 1]
            guard line1.hasPrefix("V<") || line1.hasPrefix("V ") else { continue }
            guard line1.count >= 44, line2.count >= 44 else { continue }
            line1 = String(line1.prefix(44))
            line2 = String(line2.prefix(44))

            let docNumber = cleanField(mrzSlice(line2, 0, 9))
            let nationality = cleanField(mrzSlice(line2, 10, 3))
            let dob = mrzSlice(line2, 13, 6)
            let sex = cleanField(mrzSlice(line2, 20, 1))
            let expires = mrzSlice(line2, 21, 6)
            let nameField = mrzSlice(line1, 5, 39)
            let fullName = parseMRZName(nameField)

            let checkDoc = validateMRZCheckDigit(data: mrzSlice(line2, 0, 9), checkDigit: mrzSlice(line2, 9, 1))
            let checkDob = validateMRZCheckDigit(data: mrzSlice(line2, 13, 6), checkDigit: mrzSlice(line2, 19, 1))
            let checkExp = validateMRZCheckDigit(data: mrzSlice(line2, 21, 6), checkDigit: mrzSlice(line2, 27, 1))
            let allValid = checkDoc && checkDob && checkExp
            if strictKYC && !allValid { continue }
            guard checkDoc else { continue }

            return ParsedMRZ(
                format: "MRV-A",
                documentCode: "V",
                documentNumber: docNumber,
                supportNumber: nil,
                fullName: fullName,
                dateOfBirth: normalizeMRZDate(dob),
                expires: normalizeMRZDate(expires),
                nationality: nationality,
                sex: sex,
                rawMRZ: line1 + "\n" + line2,
                isCheckDigitValid: allValid
            )
        }
        return nil
    }

    private static func parseMRVB(lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        guard lines.count >= 2 else { return nil }
        for i in 0..<(lines.count - 1) {
            var line1 = lines[i]
            var line2 = lines[i + 1]
            guard line1.hasPrefix("V<") || line1.hasPrefix("V ") else { continue }
            guard line1.count >= 36, line1.count < 44 else { continue }
            guard line2.count >= 36 else { continue }
            line1 = String(line1.prefix(36))
            line2 = String(line2.prefix(36))

            let docNumber = cleanField(mrzSlice(line2, 0, 9))
            let nationality = cleanField(mrzSlice(line2, 10, 3))
            let dob = mrzSlice(line2, 13, 6)
            let sex = cleanField(mrzSlice(line2, 20, 1))
            let expires = mrzSlice(line2, 21, 6)
            let nameField = mrzSlice(line1, 5, 31)
            let fullName = parseMRZName(nameField)

            let checkDoc = validateMRZCheckDigit(data: mrzSlice(line2, 0, 9), checkDigit: mrzSlice(line2, 9, 1))
            let checkDob = validateMRZCheckDigit(data: mrzSlice(line2, 13, 6), checkDigit: mrzSlice(line2, 19, 1))
            let checkExp = validateMRZCheckDigit(data: mrzSlice(line2, 21, 6), checkDigit: mrzSlice(line2, 27, 1))
            let allValid = checkDoc && checkDob && checkExp
            if strictKYC && !allValid { continue }
            guard checkDoc else { continue }

            return ParsedMRZ(
                format: "MRV-B",
                documentCode: "V",
                documentNumber: docNumber,
                supportNumber: nil,
                fullName: fullName,
                dateOfBirth: normalizeMRZDate(dob),
                expires: normalizeMRZDate(expires),
                nationality: nationality,
                sex: sex,
                rawMRZ: line1 + "\n" + line2,
                isCheckDigitValid: allValid
            )
        }
        return nil
    }

    private static func normalizedMRZLines(_ lines: [String]) -> [String] {
        lines
            .map { raw in
                var s = raw
                    .uppercased()
                    .replacingOccurrences(of: "\t", with: "")
                s = s.replacingOccurrences(of: "  +", with: "<", options: .regularExpression)
                s = s.replacingOccurrences(of: " ", with: "")
                return String(s.filter { $0 == "<" || $0.isNumber || ($0 >= "A" && $0 <= "Z") })
            }
            .filter { $0.count >= 20 && ($0.contains("<") || $0.allSatisfy { $0.isNumber || ($0 >= "A" && $0 <= "Z") }) }
    }

    private static func parseTD3(lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        guard lines.count >= 2 else { return nil }
        for i in 0..<(lines.count - 1) {
            var line1 = lines[i]
            var line2 = lines[i + 1]
            guard line1.hasPrefix("P<") else { continue }
            if line1.count < 44 || line2.count < 44 { continue }
            line1 = String(line1.prefix(44))
            line2 = String(line2.prefix(44))

            let docNumber = cleanField(mrzSlice(line2, 0, 9))
            let nationality = cleanField(mrzSlice(line2, 10, 3))
            let dob = mrzSlice(line2, 13, 6)
            let sex = cleanField(mrzSlice(line2, 20, 1))
            let expires = mrzSlice(line2, 21, 6)

            let checkDoc = validateMRZCheckDigit(data: mrzSlice(line2, 0, 9), checkDigit: mrzSlice(line2, 9, 1))
            let checkDob = validateMRZCheckDigit(data: mrzSlice(line2, 13, 6), checkDigit: mrzSlice(line2, 19, 1))
            let checkExp = validateMRZCheckDigit(data: mrzSlice(line2, 21, 6), checkDigit: mrzSlice(line2, 27, 1))
            let checkPersonal = validateMRZCheckDigit(data: mrzSlice(line2, 28, 14), checkDigit: mrzSlice(line2, 42, 1))
            let compositeData = mrzSlice(line2, 0, 10) + mrzSlice(line2, 13, 7) + mrzSlice(line2, 21, 22)
            let checkFinal = validateMRZCheckDigit(data: compositeData, checkDigit: mrzSlice(line2, 43, 1))
            let allValid = checkDoc && checkDob && checkExp && checkPersonal && checkFinal
            if strictKYC && !allValid { continue }

            let nameField = mrzSlice(line1, 5, 39)
            let fullName = parseMRZName(nameField)

            return ParsedMRZ(
                format: "TD3",
                documentCode: "P",
                documentNumber: docNumber,
                supportNumber: nil,
                fullName: fullName,
                dateOfBirth: normalizeMRZDate(dob),
                expires: normalizeMRZDate(expires),
                nationality: nationality,
                sex: sex,
                rawMRZ: line1 + "\n" + line2,
                isCheckDigitValid: allValid
            )
        }
        return nil
    }

    private static func parseTD1(lines: [String], strictKYC: Bool) -> ParsedMRZ? {
        guard lines.count >= 3 else { return nil }
        for i in 0..<(lines.count - 2) {
            var line1 = lines[i]
            var line2 = lines[i + 1]
            var line3 = lines[i + 2]
            guard line1.hasPrefix("I<") || line1.hasPrefix("ID") || line1.hasPrefix("A<") || line1.hasPrefix("C<") else { continue }
            if line1.count < 30 || line2.count < 30 || line3.count < 30 { continue }
            line1 = String(line1.prefix(30))
            line2 = String(line2.prefix(30))
            line3 = String(line3.prefix(30))

            let documentCode = cleanField(mrzSlice(line1, 0, 2))
            let serialDocNumber = cleanField(mrzSlice(line1, 5, 9))
            let optionalField1 = cleanField(mrzSlice(line1, 15, 14))
            let dob = mrzSlice(line2, 0, 6)
            let sex = cleanField(mrzSlice(line2, 7, 1))
            let expires = mrzSlice(line2, 8, 6)
            let nationality = cleanField(mrzSlice(line2, 15, 3))
            let fullName = parseMRZName(line3)

            let checkDoc = validateMRZCheckDigit(data: mrzSlice(line1, 5, 9), checkDigit: mrzSlice(line1, 14, 1))
            let checkDob = validateMRZCheckDigit(data: mrzSlice(line2, 0, 6), checkDigit: mrzSlice(line2, 6, 1))
            let checkExp = validateMRZCheckDigit(data: mrzSlice(line2, 8, 6), checkDigit: mrzSlice(line2, 14, 1))
            let compositeData = mrzSlice(line1, 5, 25) + mrzSlice(line2, 0, 7) + mrzSlice(line2, 8, 7) + mrzSlice(line2, 18, 11)
            let checkFinal = validateMRZCheckDigit(data: compositeData, checkDigit: mrzSlice(line2, 29, 1))
            let allValid = checkDoc && checkDob && checkExp && checkFinal
            if strictKYC && !allValid { continue }

            let isSpanishDNI = validateSpanishID(optionalField1) != nil
            let preferredDocNumber: String = isSpanishDNI ? validateSpanishID(optionalField1)!.value : serialDocNumber
            let resolvedSupportNumber: String? = isSpanishDNI && !serialDocNumber.isEmpty ? serialDocNumber : nil

            return ParsedMRZ(
                format: "TD1",
                documentCode: documentCode,
                documentNumber: preferredDocNumber,
                supportNumber: resolvedSupportNumber,
                fullName: fullName,
                dateOfBirth: normalizeMRZDate(dob),
                expires: normalizeMRZDate(expires),
                nationality: nationality,
                sex: sex,
                rawMRZ: line1 + "\n" + line2 + "\n" + line3,
                isCheckDigitValid: allValid
            )
        }
        return nil
    }

    private static func parseMRZName(_ field: String) -> String {
        let cleaned = field.replacingOccurrences(of: "<", with: " ").trimmingCharacters(in: .whitespaces)
        let normalizedSpaces = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return normalizedSpaces
    }

    private static func normalizeMRZDate(_ yymmdd: String) -> String {
        guard yymmdd.count == 6, yymmdd.allSatisfy(\.isNumber) else { return cleanField(yymmdd) }
        let yy = Int(yymmdd.prefix(2)) ?? 0
        let mm = yymmdd.dropFirst(2).prefix(2)
        let dd = yymmdd.suffix(2)
        let currentYear = Calendar.current.component(.year, from: Date()) % 100
        let century = yy > currentYear + 5 ? "19" : "20"
        return "\(dd)/\(mm)/\(century)\(String(format: "%02d", yy))"
    }

    private static func validateMRZCheckDigit(data: String, checkDigit: String) -> Bool {
        guard let expected = checkDigit.first else { return false }
        let computed = computeMRZCheckDigit(data)
        return computed == expected
    }

    private static func computeMRZCheckDigit(_ data: String) -> Character {
        let weights = [7, 3, 1]
        var sum = 0
        for (index, ch) in data.enumerated() {
            let value = mrzCharValue(ch)
            sum += value * weights[index % weights.count]
        }
        return Character(String(sum % 10))
    }

    private static func mrzCharValue(_ ch: Character) -> Int {
        if ch == "<" { return 0 }
        if let digit = ch.wholeNumberValue { return digit }
        if let ascii = ch.asciiValue, ascii >= 65, ascii <= 90 {
            return Int(ascii - 55)
        }
        return 0
    }

    private static func cleanField(_ value: String) -> String {
        value.replacingOccurrences(of: "<", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func mrzSlice(_ source: String, _ start: Int, _ length: Int) -> String {
        guard start >= 0, length > 0, start < source.count else { return "" }
        let safeStart = source.index(source.startIndex, offsetBy: start)
        let endOffset = min(source.count, start + length)
        let safeEnd = source.index(source.startIndex, offsetBy: endOffset)
        return String(source[safeStart..<safeEnd])
    }

    private static func normalizeSpanishID(from lines: [String]) -> (value: String, confidence: Double)? {
        let joined = lines.joined(separator: " ").uppercased()
        let pattern = "\\b([XYZ]?\\d{7,8}[A-Z])\\b"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(joined.startIndex..., in: joined)
        let matches = regex?.matches(in: joined, range: range) ?? []
        for match in matches {
            guard let r = Range(match.range(at: 1), in: joined) else { continue }
            let candidate = String(joined[r])
            if let normalized = validateSpanishID(candidate) {
                return normalized
            }
        }

        let compact = joined.replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
        let compactPattern = "([XYZ]?\\d{7,8}[A-Z])"
        if let compactRegex = try? NSRegularExpression(pattern: compactPattern) {
            let compactRange = NSRange(compact.startIndex..., in: compact)
            for match in compactRegex.matches(in: compact, range: compactRange) {
                guard let r = Range(match.range(at: 1), in: compact) else { continue }
                let candidate = String(compact[r])
                if let normalized = validateSpanishID(candidate) {
                    return normalized
                }
            }
        }
        return nil
    }

    private static func validateSpanishID(_ raw: String) -> (value: String, confidence: Double)? {
        let value = raw.replacingOccurrences(of: " ", with: "").uppercased()
        let map = Array("TRWAGMYFPDXBNJZSQVHLCKE")

        if value.count == 9, value.first?.isNumber == true {
            let numberPart = String(value.prefix(8))
            guard let number = Int(numberPart), let last = value.last else { return nil }
            let expected = map[number % 23]
            if last == expected {
                return (value, 0.96)
            }
            return nil
        }

        if value.count == 9, let prefix = value.first, ["X", "Y", "Z"].contains(String(prefix)) {
            let body = String(value.dropFirst().prefix(7))
            guard body.allSatisfy(\.isNumber), let last = value.last else { return nil }
            let replacedPrefix: String
            switch prefix {
            case "X": replacedPrefix = "0"
            case "Y": replacedPrefix = "1"
            case "Z": replacedPrefix = "2"
            default: return nil
            }
            guard let number = Int(replacedPrefix + body) else { return nil }
            let expected = map[number % 23]
            if last == expected {
                return (value, 0.94)
            }
        }
        return nil
    }

    private static func extractCURP(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        let pattern = "\\b([A-Z][AEIOUX][A-Z]{2}\\d{6}[HM][A-Z]{5}[A-Z0-9]\\d)\\b"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(joined.startIndex..., in: joined)
        guard let match = regex?.firstMatch(in: joined, range: range),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    private static func extractBrazilianCPF(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ")
        let pattern = "\\b(\\d{3}\\.\\d{3}\\.\\d{3}-\\d{2}|\\d{11})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        let candidate = String(joined[r]).replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard candidate.count == 11, !candidate.allSatisfy({ $0 == candidate.first }) else { return nil }
        return String(joined[r])
    }

    private static func extractChileanRUT(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        let pattern = "\\b(\\d{1,2}\\.\\d{3}\\.\\d{3}-[0-9K]|\\d{7,8}-[0-9K])\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    private static func extractAadhaar(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ")
        let pattern = "\\b(\\d{4}\\s\\d{4}\\s\\d{4}|\\d{12})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(joined.startIndex..., in: joined)
        for match in regex.matches(in: joined, range: range) {
            guard let r = Range(match.range(at: 1), in: joined) else { continue }
            let candidate = String(joined[r]).replacingOccurrences(of: " ", with: "")
            if candidate.count == 12, candidate.first != "0", candidate.first != "1" {
                return String(joined[r])
            }
        }
        return nil
    }

    private static func extractIndianPAN(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        let pattern = "\\b([A-Z]{5}[0-9]{4}[A-Z])\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    private static func extractUKNINO(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        let pattern = "\\b([A-CEGHJ-PR-TW-Z]{1}[A-CEGHJ-NPR-TW-Z]{1}\\s?\\d{2}\\s?\\d{2}\\s?\\d{2}\\s?[A-D])\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    private static func extractGermanID(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        let pattern = "\\b([A-Z][A-Z0-9]{8})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(joined.startIndex..., in: joined)
        for match in regex.matches(in: joined, range: range) {
            guard let r = Range(match.range(at: 1), in: joined) else { continue }
            let candidate = String(joined[r])
            let hasLetter = candidate.dropFirst().contains(where: { $0.isLetter })
            let hasDigit = candidate.contains(where: { $0.isNumber })
            if hasLetter && hasDigit { return candidate }
        }
        return nil
    }

    private static func extractFrenchNIR(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").replacingOccurrences(of: " ", with: "")
        let pattern = "(\\d{13}\\d{2})"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        let candidate = String(joined[r])
        guard candidate.first == "1" || candidate.first == "2" else { return nil }
        return candidate
    }

    private static func extractArgentineDNI(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        guard joined.contains("DNI") || joined.contains("DOCUMENTO NACIONAL") || joined.contains("ARGENTINA") else { return nil }
        let pattern = "\\b(\\d{7,8})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    private static func extractColombianCC(from lines: [String]) -> String? {
        let joined = lines.joined(separator: " ").uppercased()
        guard joined.contains("CC") || joined.contains("CEDULA") || joined.contains("CÉDULA") ||
              joined.contains("COLOMBIA") || joined.contains("COLOMBIANA") else { return nil }
        let pattern = "\\b(\\d{6,10})\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: joined, range: NSRange(joined.startIndex..., in: joined)),
              let r = Range(match.range(at: 1), in: joined) else { return nil }
        return String(joined[r])
    }

    private static func extractInternationalAddress(from lines: [String]) -> String? {
        let keywords = [
            "CALLE", "C/", "AVENIDA", "AV.", "PASEO", "PLAZA", "CARRER", "RUA", "RUA ", "TRAVESSA",
            "RUE", "AVENUE", "BOULEVARD", "BD ", "BD.", "IMPASSE", "ALLÉE", "PLACE",
            "STRASSE", "STR.", "WEG", "PLATZ", "GASSE", "ALLEE",
            "VIA", "CORSO", "PIAZZA", "VIALE", "VICOLO",
            "STRAAT", "LAAN", "PLEIN", "WEG ", "GRACHT",
            "ULICA", "UL.", "ALEJA", "AL.",
            "STREET", "ST ", "AVENUE", "AVE", "ROAD", "RD ", "LANE", "LN ", "DRIVE", "BLVD", "COURT", "CT ",
            "SHARIA", "SHAR3", "SHAREI",
        ]
        let upperLines = lines.map { $0.uppercased() }
        for line in upperLines {
            for kw in keywords {
                if line.contains(kw) && line.rangeOfCharacter(from: .decimalDigits) != nil {
                    return line.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }
}

// MARK: - SmartFieldExtractor

enum SmartFieldExtractor {
    @available(iOS 26.0, *)
    @Generable
    struct ExtractedFields {
        @Guide(description: "Document or ID number visible in the text. Empty string if not found.")
        var documentNumber: String
        @Guide(description: "Full name of the person. Empty string if not found.")
        var fullName: String
        @Guide(description: "Date of birth in DD/MM/YYYY format. Empty string if not found.")
        var dateOfBirth: String
        @Guide(description: "Expiry/validity date in DD/MM/YYYY format. Empty string if not found.")
        var expires: String
        @Guide(description: "Nationality or country code (3-letter ISO if possible). Empty string if not found.")
        var nationality: String
        @Guide(description: "Full postal address including street, number, city. Empty string if not found.")
        var address: String
        @Guide(description: "Sex/gender (M or F). Empty string if not found.")
        var sex: String
        @Guide(description: "Document type: dni, passport, drivinglicense, residencepermit, healthcard, or document.")
        var documentType: String
    }

    static func isAvailable() -> Bool {
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        return false
    }

    static func enrich(fields: DocumentFields, ocrText: String) async -> DocumentFields? {
        guard #available(iOS 26.0, *) else { return nil }
        guard SystemLanguageModel.default.isAvailable else { return nil }
        guard !ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }

        let prompt = """
        You are a document data extraction engine. Extract the structured fields below from the OCR text of an identity document. The text may be in any language, have OCR errors, or use non-standard layouts.

        Rules:
        - Return ONLY the JSON with the requested fields. No explanation.
        - For dates always use DD/MM/YYYY format.
        - For documentNumber: extract the main identifier (DNI, passport number, ID number, etc).
        - For fullName: combine surname(s) and given name(s) if they appear on separate lines.
        - For address: capture street + number + city, joining separate lines with ", ".
        - If a field is not present, return empty string "".

        OCR text:
        \(ocrText.prefix(2000))
        """

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(
                to: prompt,
                generating: ExtractedFields.self
            )
            let extracted = response.content
            var updated = fields

            if fields.documentNumber.isEmpty, !extracted.documentNumber.isEmpty {
                updated.documentNumber = extracted.documentNumber
                var conf = updated.ocrFieldConfidence ?? [:]
                conf["documentNumber"] = max(conf["documentNumber"] ?? 0, 0.72)
                updated.ocrFieldConfidence = conf
            }
            if fields.fullName.isEmpty, !extracted.fullName.isEmpty {
                updated.fullName = extracted.fullName
                var conf = updated.ocrFieldConfidence ?? [:]
                conf["fullName"] = max(conf["fullName"] ?? 0, 0.70)
                updated.ocrFieldConfidence = conf
            }
            if fields.dateOfBirth.isEmpty, !extracted.dateOfBirth.isEmpty {
                updated.dateOfBirth = extracted.dateOfBirth
                var conf = updated.ocrFieldConfidence ?? [:]
                conf["dateOfBirth"] = max(conf["dateOfBirth"] ?? 0, 0.70)
                updated.ocrFieldConfidence = conf
            }
            if fields.expires.isEmpty, !extracted.expires.isEmpty {
                updated.expires = extracted.expires
                var conf = updated.ocrFieldConfidence ?? [:]
                conf["expires"] = max(conf["expires"] ?? 0, 0.70)
                updated.ocrFieldConfidence = conf
            }
            if fields.nationality.isEmpty, !extracted.nationality.isEmpty {
                updated.nationality = extracted.nationality
                var conf = updated.ocrFieldConfidence ?? [:]
                conf["nationality"] = max(conf["nationality"] ?? 0, 0.68)
                updated.ocrFieldConfidence = conf
            }
            if fields.address.isEmpty, !extracted.address.isEmpty {
                updated.address = extracted.address
                var conf = updated.ocrFieldConfidence ?? [:]
                conf["address"] = max(conf["address"] ?? 0, 0.72)
                updated.ocrFieldConfidence = conf
            }
            if fields.sex.isEmpty, !extracted.sex.isEmpty {
                updated.sex = extracted.sex
            }
            if (fields.ocrDocumentType == nil || fields.ocrDocumentType == "document"),
               !extracted.documentType.isEmpty {
                updated.ocrDocumentType = extracted.documentType
            }
            return updated
        } catch {
            return nil
        }
    }
}
