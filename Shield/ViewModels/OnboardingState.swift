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
        case .rental:  return LanguageManager.shared.onboarding("onboarding_goal_rental")
        case .work:    return LanguageManager.shared.onboarding("onboarding_goal_work")
        case .vehicle: return LanguageManager.shared.onboarding("onboarding_goal_vehicle")
        case .banking: return LanguageManager.shared.onboarding("onboarding_goal_banking")
        case .travel:  return LanguageManager.shared.onboarding("onboarding_goal_travel")
        case .other:   return LanguageManager.shared.onboarding("onboarding_goal_other")
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
        case .photo:     return LanguageManager.shared.onboarding("onboarding_pain_photo")
        case .dob:       return LanguageManager.shared.onboarding("onboarding_pain_dob")
        case .docNumber: return LanguageManager.shared.onboarding("onboarding_pain_doc_num")
        case .address:   return LanguageManager.shared.onboarding("onboarding_pain_address")
        case .bank:      return LanguageManager.shared.onboarding("onboarding_pain_bank")
        case .notSure:   return LanguageManager.shared.onboarding("onboarding_pain_not_sure")
        }
    }
    var solutionKeys: (title: String, fix: String) {
        switch self {
        case .photo:     return ("onboarding_solution_photo_title", "onboarding_solution_photo_fix")
        case .dob:       return ("onboarding_solution_dob_title", "onboarding_solution_dob_fix")
        case .docNumber: return ("onboarding_solution_doc_num_title", "onboarding_solution_doc_num_fix")
        case .address:   return ("onboarding_solution_address_title", "onboarding_solution_address_fix")
        case .bank:      return ("onboarding_solution_bank_title", "onboarding_solution_bank_fix")
        case .notSure:   return ("onboarding_solution_not_sure_title", "onboarding_solution_not_sure_fix")
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
        case .dni:      return LanguageManager.shared.onboarding("onboarding_pref_dni")
        case .passport: return LanguageManager.shared.onboarding("onboarding_pref_passport")
        case .license:  return LanguageManager.shared.onboarding("onboarding_pref_license")
        case .payslip:  return LanguageManager.shared.onboarding("onboarding_pref_payslip")
        case .bank:     return LanguageManager.shared.onboarding("onboarding_pref_bank")
        case .medical:  return LanguageManager.shared.onboarding("onboarding_pref_medical")
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

    // Keep the first-run path short: two personalization choices, one real
    // interaction, the essential camera permission, then the post-value offer.
    let totalSteps = 6

    var progress: Double { Double(currentStep) / Double(totalSteps - 1) }
    var showTopBar: Bool { currentStep < totalSteps - 1 }

    func next() {
        guard currentStep < totalSteps - 1 else { return }
        withAnimation(.snappy(duration: 0.32, extraBounce: 0.04)) { currentStep += 1 }
    }

    func previous() {
        guard currentStep > 0 else { return }
        withAnimation(.snappy(duration: 0.32, extraBounce: 0.04)) { currentStep -= 1 }
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
