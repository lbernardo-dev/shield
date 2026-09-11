import SwiftUI
import Combine

// MARK: - OCREngineMode

enum OCREngineMode: String, CaseIterable, Identifiable, Sendable {
    case visionUltra = "vision_ultra"
    case visionStandard = "vision_standard"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .visionUltra: return "Apple Vision Neural Engine Ultra"
        case .visionStandard: return "Apple Vision Estándar (Rápido)"
        }
    }

    var subtitle: String {
        switch self {
        case .visionUltra: return "Pre-procesamiento multi-paso, eliminación de sombras y fusión espacial"
        case .visionStandard: return "Reconocimiento directo de 1 paso con bajo consumo de batería"
        }
    }

    var badge: String {
        switch self {
        case .visionUltra: return "Recomendado"
        case .visionStandard: return "Bajo consumo"
        }
    }
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

    private init() {
        let savedMode = defaults.string(forKey: "shield.ocr.engineMode") ?? OCREngineMode.visionUltra.rawValue
        self.activeMode = OCREngineMode(rawValue: savedMode) ?? .visionUltra

        self.enableShadowRemoval = defaults.object(forKey: "shield.ocr.enableShadowRemoval") as? Bool ?? true
        self.enableAdaptiveContrast = defaults.object(forKey: "shield.ocr.enableAdaptiveContrast") as? Bool ?? true
        self.enableDeskew = defaults.object(forKey: "shield.ocr.enableDeskew") as? Bool ?? true
    }
}
