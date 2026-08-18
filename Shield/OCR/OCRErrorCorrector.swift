import Foundation

// MARK: - OCRErrorCorrector

enum OCRErrorCorrector {
    private static let dniControlLetters = Array("TRWAGMYFPDXBNJZSQVHLCKE")

    // Common OCR character substitution matrix
    private static let digitToLetterConfusions: [Character: [Character]] = [
        "0": ["O", "D", "Q"],
        "1": ["I", "L", "T"],
        "2": ["Z"],
        "5": ["S"],
        "6": ["G", "B"],
        "8": ["B"],
        "9": ["Q", "P"]
    ]

    private static let letterToDigitConfusions: [Character: [Character]] = [
        "O": ["0"], "D": ["0"], "Q": ["0"], "U": ["0"],
        "I": ["1"], "L": ["1"], "T": ["1"], "J": ["1"], "l": ["1"], "|": ["1"],
        "Z": ["2"],
        "E": ["3"],
        "A": ["4"],
        "S": ["5"], "s": ["5"],
        "G": ["6"], "b": ["6"],
        "B": ["8"],
        "P": ["9"], "g": ["9"], "q": ["9"]
    ]

    // MARK: - Spanish DNI & NIE Error Correction

    struct IDCorrectionResult: Sendable {
        let original: String
        let corrected: String
        let isValid: Bool
        let confidence: Double
    }

    /// Validates and auto-repairs Spanish DNI / NIE numbers using Modulo 23 checksum rules and OCR confusion matrices.
    static func correctSpanishID(_ rawText: String) -> IDCorrectionResult? {
        let clean = rawText.uppercased().replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
        guard clean.count >= 8, clean.count <= 10 else { return nil }

        // 1. Direct validation if clean is already valid 9-char (8 digits + 1 letter, or X/Y/Z + 7 digits + 1 letter)
        if clean.count == 9 {
            if let valid = validateDNIorNIE(clean) {
                return IDCorrectionResult(original: rawText, corrected: valid, isValid: true, confidence: 0.99)
            }
        }

        // 2. Permutation testing for single OCR character errors
        let chars = Array(clean)
        if chars.count == 9 {
            // Test letter-to-digit in numeric positions (indices 0..7 for DNI, 1..7 for NIE)
            let startIdx = (chars[0] == "X" || chars[0] == "Y" || chars[0] == "Z") ? 1 : 0
            for i in startIdx..<8 {
                let char = chars[i]
                if let candidateDigits = letterToDigitConfusions[char] {
                    for cand in candidateDigits {
                        var testChars = chars
                        testChars[i] = cand
                        let candidateStr = String(testChars)
                        if let valid = validateDNIorNIE(candidateStr) {
                            return IDCorrectionResult(original: rawText, corrected: valid, isValid: true, confidence: 0.96)
                        }
                    }
                }
            }

            // Test digit-to-letter in the control letter position (index 8)
            let lastChar = chars[8]
            if let candidateLetters = digitToLetterConfusions[lastChar] {
                for cand in candidateLetters {
                    var testChars = chars
                    testChars[8] = cand
                    let candidateStr = String(testChars)
                    if let valid = validateDNIorNIE(candidateStr) {
                        return IDCorrectionResult(original: rawText, corrected: valid, isValid: true, confidence: 0.96)
                    }
                }
            }

            // If only digits are present (8 digits, missing or noise letter)
            if startIdx == 0 {
                let digitsOnly = String(chars.prefix(8))
                if let num = Int(digitsOnly) {
                    let expectedLetter = dniControlLetters[num % 23]
                    let corrected = digitsOnly + String(expectedLetter)
                    return IDCorrectionResult(original: rawText, corrected: corrected, isValid: true, confidence: 0.94)
                }
            }
        }

        return nil
    }

    private static func validateDNIorNIE(_ str: String) -> String? {
        guard str.count == 9 else { return nil }
        let chars = Array(str)

        // DNI: 8 digits + 1 letter
        let first8 = String(chars.prefix(8))
        let lastLetter = chars[8]
        if let num = Int(first8), lastLetter.isLetter {
            let expected = dniControlLetters[num % 23]
            if lastLetter == expected {
                return str
            }
        }

        // NIE: X (0), Y (1), Z (2) + 7 digits + 1 letter
        let firstChar = chars[0]
        if firstChar == "X" || firstChar == "Y" || firstChar == "Z" {
            let prefixNum: String
            switch firstChar {
            case "X": prefixNum = "0"
            case "Y": prefixNum = "1"
            case "Z": prefixNum = "2"
            default: return nil
            }
            let mid7 = String(chars[1..<8])
            if let totalNum = Int(prefixNum + mid7), lastLetter.isLetter {
                let expected = dniControlLetters[totalNum % 23]
                if lastLetter == expected {
                    return str
                }
            }
        }

        return nil
    }

    // MARK: - MRZ ICAO 9303 Check Digit Repair

    /// Verifies and repairs ICAO 9303 MRZ fields (Document Number, Date of Birth, Expiry).
    static func verifyAndRepairMRZField(value: String, checkDigit: Character) -> (repaired: String, isValid: Bool) {
        let weights = [7, 3, 1]
        let cleaned = value.replacingOccurrences(of: "<", with: "0").uppercased()

        func calculateCheckDigit(_ str: String) -> Character? {
            var sum = 0
            for (index, char) in str.enumerated() {
                let weight = weights[index % 3]
                let val: Int
                if let digit = char.wholeNumberValue {
                    val = digit
                } else if let ascii = char.asciiValue, ascii >= 65 && ascii <= 90 {
                    val = Int(ascii - 55)
                } else {
                    val = 0
                }
                sum += val * weight
            }
            return Character(String(sum % 10))
        }

        if let expected = calculateCheckDigit(cleaned), expected == checkDigit {
            return (value, true)
        }

        // Try global letter->digit substitution (e.g. all 'O' -> '0', 'I' -> '1')
        var allDigits = cleaned
        for (letter, digits) in letterToDigitConfusions {
            if let primaryDigit = digits.first {
                allDigits = allDigits.replacingOccurrences(of: String(letter), with: String(primaryDigit))
            }
        }
        if let expected = calculateCheckDigit(allDigits), expected == checkDigit {
            return (allDigits, true)
        }

        // Try single character substitutions
        var chars = Array(cleaned)
        for (i, char) in chars.enumerated() {
            if let candidates = letterToDigitConfusions[char] ?? digitToLetterConfusions[char] {
                for cand in candidates {
                    chars[i] = cand
                    if let expected = calculateCheckDigit(String(chars)), expected == checkDigit {
                        return (String(chars), true)
                    }
                }
                chars[i] = char // restore
            }
        }

        return (value, false)
    }

    // MARK: - IBAN Formatter and Corrector

    static func correctIBAN(_ rawText: String) -> String? {
        let clean = rawText.uppercased().replacingOccurrences(of: "[^A-Z0-9]", with: "", options: .regularExpression)
        guard clean.count >= 15 && clean.count <= 34 else { return nil }

        // Replace common OCR errors in country code (first 2 characters)
        var chars = Array(clean)
        for i in 0..<2 {
            if let letter = digitToLetterConfusions[chars[i]]?.first {
                chars[i] = letter
            }
        }
        // Replace common OCR errors in checksum (indices 2 and 3)
        for i in 2..<4 {
            if let digit = letterToDigitConfusions[chars[i]]?.first {
                chars[i] = digit
            }
        }

        return String(chars)
    }
}
