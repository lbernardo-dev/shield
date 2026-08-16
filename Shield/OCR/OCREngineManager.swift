import SwiftUI
import Combine

// MARK: - OCREngineMode

enum OCREngineMode: String, CaseIterable, Identifiable, Sendable {
    case visionUltra = "vision_ultra"
    case visionStandard = "vision_standard"
    case openEngine = "open_engine"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visionUltra: return "Apple Vision Neural Engine Ultra"
        case .visionStandard: return "Apple Vision Estándar (Rápido)"
        case .openEngine: return "Motor Abierto / Modelos Libres"
        }
    }

    var subtitle: String {
        switch self {
        case .visionUltra: return "Pre-procesamiento multi-paso, eliminación de sombras y fusión espacial"
        case .visionStandard: return "Reconocimiento directo de 1 paso con bajo consumo de batería"
        case .openEngine: return "Modelos libres y abiertos descargables en local (100% offline)"
        }
    }

    var badge: String {
        switch self {
        case .visionUltra: return "Recomendado"
        case .visionStandard: return "Bajo consumo"
        case .openEngine: return "Libre / Local"
        }
    }
}

// MARK: - OCRLanguagePack

struct OCRLanguagePack: Identifiable, Sendable {
    let id: String
    let code: String
    let name: String
    let sizeMB: Double
    var isInstalled: Bool
    var isDownloading: Bool = false
    var downloadProgress: Double = 0.0
}

// MARK: - OCREngineManager

@MainActor
final class OCREngineManager: ObservableObject {
    static let shared = OCREngineManager()

    private let defaults = UserDefaults.standard

    // MARK: - Published Settings
    @Published var activeMode: OCREngineMode {
        didSet { defaults.set(activeMode.rawValue, forKey: "shield.ocr.engineMode") }
    }

    @Published var enableShadowRemoval: Bool {
        didSet { defaults.set(enableShadowRemoval, forKey: "shield.ocr.enableShadowRemoval") }
    }

    @Published var enableAdaptiveContrast: Bool {
        didSet { defaults.set(enableAdaptiveContrast, forKey: "shield.ocr.enableAdaptiveContrast") }
    }

    @Published var enableDeskew: Bool {
        didSet { defaults.set(enableDeskew, forKey: "shield.ocr.enableDeskew") }
    }

    @Published var enableMathematicalCorrection: Bool {
        didSet { defaults.set(enableMathematicalCorrection, forKey: "shield.ocr.enableMathematicalCorrection") }
    }

    @Published var confidenceThreshold: Double {
        didSet { defaults.set(confidenceThreshold, forKey: "shield.ocr.confidenceThreshold") }
    }

    @Published var languagePacks: [OCRLanguagePack] = []

    private init() {
        let savedMode = defaults.string(forKey: "shield.ocr.engineMode") ?? OCREngineMode.visionUltra.rawValue
        self.activeMode = OCREngineMode(rawValue: savedMode) ?? .visionUltra

        self.enableShadowRemoval = defaults.object(forKey: "shield.ocr.enableShadowRemoval") as? Bool ?? true
        self.enableAdaptiveContrast = defaults.object(forKey: "shield.ocr.enableAdaptiveContrast") as? Bool ?? true
        self.enableDeskew = defaults.object(forKey: "shield.ocr.enableDeskew") as? Bool ?? true
        self.enableMathematicalCorrection = defaults.object(forKey: "shield.ocr.enableMathematicalCorrection") as? Bool ?? true
        self.confidenceThreshold = defaults.object(forKey: "shield.ocr.confidenceThreshold") as? Double ?? 0.55

        loadLanguagePacks()
    }

    // MARK: - Language Pack Management

    private func modelsDirectory() -> URL {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let modelsDir = docs.appendingPathComponent("OCRModels", isDirectory: true)
        if !fm.fileExists(atPath: modelsDir.path) {
            try? fm.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        }
        return modelsDir
    }

    func loadLanguagePacks() {
        let modelsDir = modelsDirectory()
        let fm = FileManager.default

        let basePacks: [(code: String, name: String, size: Double)] = [
            ("spa", "Español (ES/LATAM)", 14.8),
            ("eng", "Inglés (Internacional)", 15.2),
            ("fra", "Francés (Francia)", 13.9),
            ("deu", "Alemán (Alemania)", 14.5),
            ("ita", "Italiano (Italia)", 13.7),
            ("por", "Portugués (PT/BR)", 14.1),
            ("cat", "Catalán (España)", 12.8),
            ("eus", "Euskera (España)", 11.9),
            ("glg", "Gallego (España)", 12.1)
        ]

        self.languagePacks = basePacks.map { item in
            let filePath = modelsDir.appendingPathComponent("\(item.code).traineddata").path
            let installed = fm.fileExists(atPath: filePath)
            return OCRLanguagePack(
                id: item.code,
                code: item.code,
                name: item.name,
                sizeMB: item.size,
                isInstalled: installed
            )
        }
    }

    func downloadPack(_ pack: OCRLanguagePack) async {
        guard let index = languagePacks.firstIndex(where: { $0.id == pack.id }) else { return }
        languagePacks[index].isDownloading = true
        languagePacks[index].downloadProgress = 0.0

        // Simulated chunked on-device local asset verification / download
        for p in stride(from: 0.1, through: 1.0, by: 0.2) {
            try? await Task.sleep(nanoseconds: 120_000_000)
            if languagePacks.indices.contains(index) {
                languagePacks[index].downloadProgress = p
            }
        }

        // Write marker file locally
        let modelsDir = modelsDirectory()
        let targetFile = modelsDir.appendingPathComponent("\(pack.code).traineddata")
        let placeholderData = "MASKID_OCR_MODEL_\(pack.code.uppercased())_V2".data(using: .utf8) ?? Data()
        try? placeholderData.write(to: targetFile)

        if languagePacks.indices.contains(index) {
            languagePacks[index].isDownloading = false
            languagePacks[index].isInstalled = true
            languagePacks[index].downloadProgress = 1.0
        }
    }

    func deletePack(_ pack: OCRLanguagePack) {
        guard let index = languagePacks.firstIndex(where: { $0.id == pack.id }) else { return }
        let modelsDir = modelsDirectory()
        let targetFile = modelsDir.appendingPathComponent("\(pack.code).traineddata")
        try? FileManager.default.removeItem(at: targetFile)

        languagePacks[index].isInstalled = false
        languagePacks[index].downloadProgress = 0.0
        languagePacks[index].isDownloading = false
    }

    var totalInstalledStorageMB: Double {
        languagePacks.filter(\.isInstalled).reduce(0.0) { $0 + $1.sizeMB }
    }
}
