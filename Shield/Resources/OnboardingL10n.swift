import Foundation

// MARK: - OnboardingKey

enum OnboardingKey: Hashable {
    // Navigation
    case continueBtn, skipAll, notNow

    // Screen 1 — Welcome
    case welcomeTitle, welcomeSubtitle, welcomeCTA

    // Screen 2 — Goal
    case goalTitle, goalSubtitle
    case goalRental, goalWork, goalVehicle, goalBanking, goalTravel, goalOther

    // Screen 3 — Pain Points
    case painTitle, painSubtitle
    case painPhoto, painDOB, painDocNum, painAddress, painBank, painNotSure

    // Screen 4 — Social Proof
    case socialTitle
    case social1Name, social1Tag, social1Text
    case social2Name, social2Tag, social2Text
    case social3Name, social3Tag, social3Text
    case socialNote

    // Screen 5 — Solution
    case solutionTitle
    case solutionPhotoTitle, solutionPhotoFix
    case solutionDOBTitle, solutionDOBFix
    case solutionDocNumTitle, solutionDocNumFix
    case solutionAddressTitle, solutionAddressFix
    case solutionBankTitle, solutionBankFix
    case solutionNotSureTitle, solutionNotSureFix
    case solutionDefaultTitle, solutionDefaultFix

    // Screen 6 — Preferences
    case prefsTitle, prefsSubtitle
    case prefDNI, prefPassport, prefLicense, prefPayslip, prefBank, prefMedical

    // Screen 7 — Camera
    case cameraTitle, cameraSubtitle
    case cameraBullet1, cameraBullet2, cameraBullet3
    case cameraEnable

    // Screen 8 — Face ID
    case faceIDTitle, faceIDSubtitle
    case faceIDBullet1, faceIDBullet2, faceIDBullet3
    case faceIDEnable

    // Screen 9 — Processing
    case processingText

    // Screen 10 — Demo
    case demoTitle, demoSubtitle
    case demoInstructionPlural, demoInstructionSingular, demoInstructionDone
    case demoFieldPhoto, demoFieldDOB, demoFieldDocNum, demoFieldAddress
    case demoFieldHidden, demoSeeResult
    case demoResultTitle, demoResultSubtitle, demoResultCTA
    case demoSampleName, demoSampleCountry

    // Screen 11 — Paywall
    case paywallTitle, paywallSubtitle
    case paywallTestimonial, paywallTestimonialAuthor
    case paywallFeat1, paywallFeat2, paywallFeat3, paywallFeat4, paywallFeat5
    case paywallCTA, paywallRestore, paywallLegal, paywallSkip

    func string(lang: AppLanguage) -> String {
        lang == .es ? esString : enString
    }

    // MARK: - Español
    private var esString: String {
        switch self {
        case .continueBtn:          return "Continuar"
        case .skipAll:              return "Omitir"
        case .notNow:               return "Ahora no"
        case .welcomeTitle:         return "Comparte tus documentos.\nSolo lo que quieras."
        case .welcomeSubtitle:      return "Oculta tus datos sensibles en segundos.\nSin servidores. Sin rastro."
        case .welcomeCTA:           return "Empezar"
        case .goalTitle:            return "¿Para qué sueles compartir tus documentos?"
        case .goalSubtitle:         return "Así personalizamos Shield para ti."
        case .goalRental:           return "Alquiler de vivienda"
        case .goalWork:             return "Trabajo o contrato"
        case .goalVehicle:          return "Alquiler de vehículo"
        case .goalBanking:          return "Trámites bancarios"
        case .goalTravel:           return "Viaje o inmigración"
        case .goalOther:            return "Otro trámite"
        case .painTitle:            return "¿Qué te preocupa al enviar tus documentos?"
        case .painSubtitle:         return "Selecciona todo lo que aplique."
        case .painPhoto:            return "Que vean mi foto"
        case .painDOB:              return "Que vean mi fecha de nacimiento"
        case .painDocNum:           return "Que copien mi número de documento"
        case .painAddress:          return "Que vean mi dirección completa"
        case .painBank:             return "Que accedan a mis datos bancarios"
        case .painNotSure:          return "No sé qué datos debería ocultar"
        case .socialTitle:          return "Miles de personas comparten sus docs con tranquilidad"
        case .social1Name:          return "Marta R."
        case .social1Tag:           return "Inquilina"
        case .social1Text:          return "Por fin puedo enviar mi DNI sin que vean mi foto ni mi dirección. Lo uso cada vez que alquilo un coche."
        case .social2Name:          return "Carlos M."
        case .social2Tag:           return "Autónomo"
        case .social2Text:          return "Me lo pidieron para un contrato freelance. En 30 segundos tenía el documento listo para enviar."
        case .social3Name:          return "Sofía L."
        case .social3Tag:           return "Viajera frecuente"
        case .social3Text:          return "Viajo mucho y siempre me piden el pasaporte. Shield me da el control sobre lo que comparto."
        case .socialNote:           return "Testimonios representativos · Los resultados individuales pueden variar"
        case .solutionTitle:        return "Shield te protege exactamente donde lo necesitas"
        case .solutionPhotoTitle:   return "Que vean tu foto"
        case .solutionPhotoFix:     return "Oculta la imagen con un bloque opaco en un toque"
        case .solutionDOBTitle:     return "Que vean tu fecha de nacimiento"
        case .solutionDOBFix:       return "Oculta los campos que quieras con un toque"
        case .solutionDocNumTitle:  return "Que copien tu número de doc"
        case .solutionDocNumFix:    return "Redacta cualquier campo con precisión total"
        case .solutionAddressTitle: return "Que vean tu dirección"
        case .solutionAddressFix:   return "Redacta la dirección sin afectar el resto"
        case .solutionBankTitle:    return "Que accedan a tus datos bancarios"
        case .solutionBankFix:      return "Protege números de cuenta y extractos en segundos"
        case .solutionNotSureTitle: return "No saber qué ocultar"
        case .solutionNotSureFix:   return "Shield detecta automáticamente los campos sensibles"
        case .solutionDefaultTitle: return "Dejar rastro digital"
        case .solutionDefaultFix:   return "Todo ocurre en tu dispositivo. Nadie más accede a tus datos."
        case .prefsTitle:           return "¿Qué documentos vas a proteger?"
        case .prefsSubtitle:        return "Selecciona los que usas más."
        case .prefDNI:              return "DNI / Cédula"
        case .prefPassport:         return "Pasaporte"
        case .prefLicense:          return "Carnet de conducir"
        case .prefPayslip:          return "Nómina / Contrato"
        case .prefBank:             return "Extracto bancario"
        case .prefMedical:          return "Documento médico"
        case .cameraTitle:          return "Escanea cualquier documento al instante"
        case .cameraSubtitle:       return "Shield usa la cámara para capturar tus docs directamente, sin pasar por el carrete."
        case .cameraBullet1:        return "Detecta el tipo de documento automáticamente"
        case .cameraBullet2:        return "Encuadre inteligente para fotos nítidas"
        case .cameraBullet3:        return "Procesado en el dispositivo. Nunca en servidores."
        case .cameraEnable:         return "Activar cámara"
        case .faceIDTitle:          return "Tu vault privado, solo para tus ojos"
        case .faceIDSubtitle:       return "El vault guarda tus documentos cifrados. Face ID es la única llave."
        case .faceIDBullet1:        return "Acceso instantáneo con un vistazo"
        case .faceIDBullet2:        return "Se bloquea automáticamente al salir"
        case .faceIDBullet3:        return "Cifrado AES-256. Nadie más puede abrirlo."
        case .faceIDEnable:         return "Activar Face ID"
        case .processingText:       return "Preparando tu espacio privado…"
        case .demoTitle:            return "Pruébalo tú mismo"
        case .demoSubtitle:         return "Toca los campos para ocultarlos en este documento de ejemplo."
        case .demoInstructionPlural:  return "Oculta al menos 2 campos"
        case .demoInstructionSingular: return "Oculta 1 campo más"
        case .demoInstructionDone:  return "¡Listo! Ya puedes ver el resultado"
        case .demoFieldPhoto:       return "Foto"
        case .demoFieldDOB:         return "Fecha de nac."
        case .demoFieldDocNum:      return "N.º documento"
        case .demoFieldAddress:     return "Dirección"
        case .demoFieldHidden:      return "Oculto"
        case .demoSeeResult:        return "Ver resultado"
        case .demoResultTitle:      return "Tu documento está protegido"
        case .demoResultSubtitle:   return "Así es como lo verá quien lo reciba."
        case .demoResultCTA:        return "Continuar"
        case .demoSampleName:       return "García López, Juan"
        case .demoSampleCountry:    return "🇪🇸 ESPAÑA · DNI"
        case .paywallTitle:         return "Tu privacidad, sin límites"
        case .paywallSubtitle:      return "Empieza gratis. Cancela cuando quieras."
        case .paywallTestimonial:   return "\"Desde que uso Shield, comparto mis docs sin dudarlo ni un segundo.\""
        case .paywallTestimonialAuthor: return "— Carlos M., autónomo"
        case .paywallFeat1:         return "Documentos ilimitados"
        case .paywallFeat2:         return "9 estilos de redacción"
        case .paywallFeat3:         return "Vault cifrado con Face ID"
        case .paywallFeat4:         return "Detección automática con IA"
        case .paywallFeat5:         return "Sincronización iCloud"
        case .paywallCTA:           return "Empezar prueba gratuita de 7 días"
        case .paywallRestore:       return "Restaurar compra"
        case .paywallLegal:         return "Se renueva automáticamente. Cancela en cualquier momento."
        case .paywallSkip:          return "Continuar sin Pro"
        }
    }

    // MARK: - English
    private var enString: String {
        switch self {
        case .continueBtn:          return "Continue"
        case .skipAll:              return "Skip"
        case .notNow:               return "Not now"
        case .welcomeTitle:         return "Share your documents.\nOnly what you want."
        case .welcomeSubtitle:      return "Hide sensitive data in seconds.\nNo servers. No trace."
        case .welcomeCTA:           return "Get Started"
        case .goalTitle:            return "Why do you share your documents?"
        case .goalSubtitle:         return "We'll personalize Shield for you."
        case .goalRental:           return "Renting a home"
        case .goalWork:             return "Work or contracts"
        case .goalVehicle:          return "Renting a vehicle"
        case .goalBanking:          return "Banking procedures"
        case .goalTravel:           return "Travel or immigration"
        case .goalOther:            return "Other"
        case .painTitle:            return "What worries you when sharing documents?"
        case .painSubtitle:         return "Select all that apply."
        case .painPhoto:            return "Someone seeing my photo"
        case .painDOB:              return "Exposing my date of birth"
        case .painDocNum:           return "Someone copying my document number"
        case .painAddress:          return "Revealing my full address"
        case .painBank:             return "Exposing my bank details"
        case .painNotSure:          return "I'm not sure what to hide"
        case .socialTitle:          return "Thousands of people share their docs with confidence"
        case .social1Name:          return "Marta R."
        case .social1Tag:           return "Tenant"
        case .social1Text:          return "I can finally send my ID without exposing my photo or address. I use it every time I rent a car."
        case .social2Name:          return "Carlos M."
        case .social2Tag:           return "Freelancer"
        case .social2Text:          return "They asked for my ID for a freelance contract. In 30 seconds I had a clean doc ready to send."
        case .social3Name:          return "Sofía L."
        case .social3Tag:           return "Frequent traveler"
        case .social3Text:          return "I travel a lot and they always ask for my passport. Shield gives me control over what I share."
        case .socialNote:           return "Representative testimonials · Individual results may vary"
        case .solutionTitle:        return "Shield protects you exactly where it matters"
        case .solutionPhotoTitle:   return "Someone seeing your photo"
        case .solutionPhotoFix:     return "Cover it with an opaque block in one tap"
        case .solutionDOBTitle:     return "Exposing your date of birth"
        case .solutionDOBFix:       return "Hide whichever fields you choose with a tap"
        case .solutionDocNumTitle:  return "Copying your document number"
        case .solutionDocNumFix:    return "Redact any field with precision"
        case .solutionAddressTitle: return "Revealing your full address"
        case .solutionAddressFix:   return "Redact the address without touching the rest"
        case .solutionBankTitle:    return "Exposing your bank details"
        case .solutionBankFix:      return "Protect account numbers and statements in seconds"
        case .solutionNotSureTitle: return "Not knowing what to hide"
        case .solutionNotSureFix:   return "Shield auto-detects sensitive fields for you"
        case .solutionDefaultTitle: return "Leaving a digital trace"
        case .solutionDefaultFix:   return "Everything stays on your device. No one else sees your data."
        case .prefsTitle:           return "What documents will you protect?"
        case .prefsSubtitle:        return "Select the ones you use most."
        case .prefDNI:              return "National ID"
        case .prefPassport:         return "Passport"
        case .prefLicense:          return "Driver's license"
        case .prefPayslip:          return "Payslip / Contract"
        case .prefBank:             return "Bank statement"
        case .prefMedical:          return "Medical document"
        case .cameraTitle:          return "Scan any document instantly"
        case .cameraSubtitle:       return "Shield uses your camera to capture documents directly — nothing saved to your gallery."
        case .cameraBullet1:        return "Automatically detects the document type"
        case .cameraBullet2:        return "Smart framing for sharp, clean scans"
        case .cameraBullet3:        return "Processed on-device. Never on servers."
        case .cameraEnable:         return "Enable Camera"
        case .faceIDTitle:          return "Your private vault, for your eyes only"
        case .faceIDSubtitle:       return "The vault stores your encrypted documents. Face ID is the only key."
        case .faceIDBullet1:        return "Instant access with a glance"
        case .faceIDBullet2:        return "Auto-locks when you leave the app"
        case .faceIDBullet3:        return "AES-256 encryption. No one else can open it."
        case .faceIDEnable:         return "Enable Face ID"
        case .processingText:       return "Setting up your private space…"
        case .demoTitle:            return "Try it yourself"
        case .demoSubtitle:         return "Tap the fields to hide them on this sample document."
        case .demoInstructionPlural:  return "Hide at least 2 fields"
        case .demoInstructionSingular: return "Hide 1 more field"
        case .demoInstructionDone:  return "Done! You can see the result"
        case .demoFieldPhoto:       return "Photo"
        case .demoFieldDOB:         return "Date of birth"
        case .demoFieldDocNum:      return "Document no."
        case .demoFieldAddress:     return "Address"
        case .demoFieldHidden:      return "Hidden"
        case .demoSeeResult:        return "See result"
        case .demoResultTitle:      return "Your document is protected"
        case .demoResultSubtitle:   return "This is what the recipient will see."
        case .demoResultCTA:        return "Continue"
        case .demoSampleName:       return "García López, Juan"
        case .demoSampleCountry:    return "🇪🇸 SPAIN · ID"
        case .paywallTitle:         return "Your privacy, without limits"
        case .paywallSubtitle:      return "Start free. Cancel anytime."
        case .paywallTestimonial:   return "\"Since I started using Shield, I share my docs without a second thought.\""
        case .paywallTestimonialAuthor: return "— Carlos M., freelancer"
        case .paywallFeat1:         return "Unlimited documents"
        case .paywallFeat2:         return "9 redaction styles"
        case .paywallFeat3:         return "Face ID encrypted vault"
        case .paywallFeat4:         return "AI auto-detection"
        case .paywallFeat5:         return "iCloud sync"
        case .paywallCTA:           return "Start 7-day free trial"
        case .paywallRestore:       return "Restore purchase"
        case .paywallLegal:         return "Renews automatically. Cancel anytime."
        case .paywallSkip:          return "Continue without Pro"
        }
    }
}
