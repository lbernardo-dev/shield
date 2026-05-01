import SwiftUI

// MARK: - OBGoal

enum OBGoal: String, CaseIterable, Identifiable {
    case rental, work, vehicle, banking, travel, other
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .rental:  return "🏠"
        case .work:    return "💼"
        case .vehicle: return "🚗"
        case .banking: return "🏦"
        case .travel:  return "✈️"
        case .other:   return "📋"
        }
    }
    func label(lang: AppLanguage) -> String {
        switch self {
        case .rental:  return OnboardingKey.goalRental.string(lang: lang)
        case .work:    return OnboardingKey.goalWork.string(lang: lang)
        case .vehicle: return OnboardingKey.goalVehicle.string(lang: lang)
        case .banking: return OnboardingKey.goalBanking.string(lang: lang)
        case .travel:  return OnboardingKey.goalTravel.string(lang: lang)
        case .other:   return OnboardingKey.goalOther.string(lang: lang)
        }
    }
}

// MARK: - OBPainPoint

enum OBPainPoint: String, CaseIterable, Identifiable, Hashable {
    case photo, dob, docNumber, address, bank, notSure
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .photo:     return "😰"
        case .dob:       return "📅"
        case .docNumber: return "🔢"
        case .address:   return "🏠"
        case .bank:      return "💳"
        case .notSure:   return "🤷"
        }
    }
    func label(lang: AppLanguage) -> String {
        switch self {
        case .photo:     return OnboardingKey.painPhoto.string(lang: lang)
        case .dob:       return OnboardingKey.painDOB.string(lang: lang)
        case .docNumber: return OnboardingKey.painDocNum.string(lang: lang)
        case .address:   return OnboardingKey.painAddress.string(lang: lang)
        case .bank:      return OnboardingKey.painBank.string(lang: lang)
        case .notSure:   return OnboardingKey.painNotSure.string(lang: lang)
        }
    }
    var solutionKeys: (title: OnboardingKey, fix: OnboardingKey) {
        switch self {
        case .photo:     return (.solutionPhotoTitle, .solutionPhotoFix)
        case .dob:       return (.solutionDOBTitle, .solutionDOBFix)
        case .docNumber: return (.solutionDocNumTitle, .solutionDocNumFix)
        case .address:   return (.solutionAddressTitle, .solutionAddressFix)
        case .bank:      return (.solutionBankTitle, .solutionBankFix)
        case .notSure:   return (.solutionNotSureTitle, .solutionNotSureFix)
        }
    }
}

// MARK: - OBDocType

enum OBDocType: String, CaseIterable, Identifiable, Hashable {
    case dni, passport, license, payslip, bank, medical
    var id: String { rawValue }
    var emoji: String {
        switch self {
        case .dni:      return "🪪"
        case .passport: return "🛂"
        case .license:  return "🚗"
        case .payslip:  return "📄"
        case .bank:     return "🏦"
        case .medical:  return "🏥"
        }
    }
    func label(lang: AppLanguage) -> String {
        switch self {
        case .dni:      return OnboardingKey.prefDNI.string(lang: lang)
        case .passport: return OnboardingKey.prefPassport.string(lang: lang)
        case .license:  return OnboardingKey.prefLicense.string(lang: lang)
        case .payslip:  return OnboardingKey.prefPayslip.string(lang: lang)
        case .bank:     return OnboardingKey.prefBank.string(lang: lang)
        case .medical:  return OnboardingKey.prefMedical.string(lang: lang)
        }
    }
}

// MARK: - OnboardingState

@MainActor
final class OnboardingState: ObservableObject {
    @Published var currentStep: Int = 0
    @Published var selectedGoal: OBGoal? = nil
    @Published var selectedPainPoints: Set<OBPainPoint> = []
    @Published var selectedDocTypes: Set<OBDocType> = []

    let totalSteps = 11

    var progress: Double { Double(currentStep) / Double(totalSteps - 1) }
    var showTopBar: Bool { currentStep < totalSteps - 1 }

    func next() {
        guard currentStep < totalSteps - 1 else { return }
        withAnimation(.easeInOut(duration: 0.28)) { currentStep += 1 }
    }

    func persistAnswers() {
        let ud = UserDefaults.standard
        if let goal = selectedGoal {
            ud.set(goal.rawValue, forKey: "shield.onboarding.goal")
        }
        ud.set(Array(selectedPainPoints).map(\.rawValue), forKey: "shield.onboarding.painPoints")
        ud.set(Array(selectedDocTypes).map(\.rawValue), forKey: "shield.onboarding.docTypes")
    }
}
