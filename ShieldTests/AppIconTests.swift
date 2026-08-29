import Testing
import Foundation
@testable import Shield

@Suite("AppIconOption & Alternate Icons Suite")
struct AppIconTests {

    @Test("Default App Icon is MaskIDBlue and does not require Pro")
    func testDefaultIconProperties() {
        let defaultIcon = AppIconOption.defaultIcon
        #expect(defaultIcon == .blue)
        #expect(defaultIcon.isDefault == true)
        #expect(defaultIcon.isPro == false)
        #expect(defaultIcon.alternateIconName == nil)
        #expect(defaultIcon.imageName == "MaskIDBlue")
    }

    @Test("All non-default icons are flagged as Pro and have valid alternate icon names")
    func testProIconsProperties() {
        let proIcons = AppIconOption.allCases.filter { !$0.isDefault }
        #expect(proIcons.count == 13)

        for icon in proIcons {
            #expect(icon.isPro == true)
            #expect(icon.alternateIconName == icon.rawValue)
            #expect(icon.imageName == icon.rawValue)
            #expect(!icon.haloColors.isEmpty)
        }
    }

    @Test("Resolution from alternate icon name strings with safe fallback")
    func testResolutionFromSystemName() {
        #expect(AppIconOption.from(alternateIconName: nil) == .blue)
        #expect(AppIconOption.from(alternateIconName: "MaskIDGold") == .gold)
        #expect(AppIconOption.from(alternateIconName: "MaskIDGreen") == .green)
        #expect(AppIconOption.from(alternateIconName: "MaskIDOcean") == .ocean)
        #expect(AppIconOption.from(alternateIconName: "MaskIDPurple") == .purple)
        #expect(AppIconOption.from(alternateIconName: "MaskIDRed") == .red)
        #expect(AppIconOption.from(alternateIconName: "MaskIDAurora") == .aurora)
        #expect(AppIconOption.from(alternateIconName: "MaskIDForest") == .forest)
        #expect(AppIconOption.from(alternateIconName: "MaskIDTide") == .tide)
        #expect(AppIconOption.from(alternateIconName: "MaskIDHalloween") == .halloween)
        #expect(AppIconOption.from(alternateIconName: "MaskIDChristmas") == .christmas)
        #expect(AppIconOption.from(alternateIconName: "MaskIDLunar") == .lunar)
        #expect(AppIconOption.from(alternateIconName: "MaskIDPride") == .pride)
        #expect(AppIconOption.from(alternateIconName: "MaskIDSpace") == .space)
        #expect(AppIconOption.from(alternateIconName: "UnknownNonExistentIcon") == .blue)
    }

    @Test("Localized names exist in Spanish and English for all icons")
    func testLocalizationIntegrity() {
        for icon in AppIconOption.allCases {
            let esName = icon.localizedName(language: .es)
            let enName = icon.localizedName(language: .en)
            #expect(!esName.isEmpty)
            #expect(!enName.isEmpty)
            #expect(esName != enName || icon == .blue) // "Azul Clásico" vs "Classic Blue", etc.
        }
    }

    @Test("AppState rejects Pro icons for free users and permits them for Pro users")
    @MainActor
    func testAppStateProGating() async throws {
        let appState = AppState()

        // 1. Free user attempting to select Pro icon (.gold) must throw AppIconError.proRequired
        var didThrowExpectedError = false
        do {
            try await appState.setAppIcon(.gold, isPro: false)
        } catch let error as AppState.AppIconError {
            if case .proRequired = error {
                didThrowExpectedError = true
            }
        } catch {
            // Other error
        }
        #expect(didThrowExpectedError == true)

        // 2. Free user selecting default .blue icon must succeed
        try await appState.setAppIcon(.blue, isPro: false)
        #expect(appState.currentAppIcon == .blue)

        // 3. Pro user selecting Pro icon (.gold) must succeed
        try await appState.setAppIcon(.gold, isPro: true)
        #expect(appState.currentAppIcon == .gold)

        // 4. Pro user switching to another Pro icon (.green)
        try await appState.setAppIcon(.green, isPro: true)
        #expect(appState.currentAppIcon == .green)

        // Reset to default
        try await appState.setAppIcon(.blue, isPro: true)
        #expect(appState.currentAppIcon == .blue)
    }
}
