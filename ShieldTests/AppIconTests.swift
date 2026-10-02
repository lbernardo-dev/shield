import Testing
import Foundation
@testable import Shield

@Suite("AppIconOption & Alternate Icons Suite")
struct AppIconTests {

    @Test("Default App Icon is MaskIDDefault and does not require Pro")
    func testDefaultIconProperties() {
        let defaultIcon = AppIconOption.defaultIcon
        #expect(defaultIcon == .base)
        #expect(defaultIcon.isDefault == true)
        #expect(defaultIcon.isPro == false)
        #expect(defaultIcon.alternateIconName == nil)
        #expect(defaultIcon.imageName == "MaskIDDefault")
    }

    @Test("Halloween icon is flagged as Pro and has valid alternate icon name")
    func testProIconsProperties() {
        let proIcons = AppIconOption.allCases.filter { !$0.isDefault }
        #expect(proIcons.count == 1)

        guard let halloween = proIcons.first else {
            Issue.record("Expected halloween icon")
            return
        }
        #expect(halloween == .halloween)
        #expect(halloween.isPro == true)
        #expect(halloween.alternateIconName == "MaskIDHalloween")
        #expect(halloween.imageName == "MaskIDHalloween")
        #expect(!halloween.haloColors.isEmpty)
    }

    @Test("Resolution from alternate icon name strings with safe fallback")
    func testResolutionFromSystemName() {
        #expect(AppIconOption.from(alternateIconName: nil) == .base)
        #expect(AppIconOption.from(alternateIconName: "MaskIDHalloween") == .halloween)
        #expect(AppIconOption.from(alternateIconName: "MaskIDBlue") == .base)
        #expect(AppIconOption.from(alternateIconName: "UnknownNonExistentIcon") == .base)
    }

    @Test("Localized names exist in Spanish and English for base and halloween icons")
    func testLocalizationIntegrity() {
        for icon in AppIconOption.allCases {
            let esName = icon.localizedName(language: .es)
            let enName = icon.localizedName(language: .en)
            #expect(!esName.isEmpty)
            #expect(!enName.isEmpty)
        }
    }

    @Test("Seasonal themes have their icons bound correctly")
    func testSeasonalThemeIconBinding() {
        #expect(SeasonalThemeID.base.icon == .base)
        #expect(SeasonalThemeID.halloween2026.icon == .halloween)
        #expect(SeasonalThemeCatalog.definition(for: .base)?.icon == .base)
        #expect(SeasonalThemeCatalog.definition(for: .halloween2026)?.icon == .halloween)
    }

    @Test("AppState applies seasonal theme icons directly")
    @MainActor
    func testAppStateThemeIconApplication() async {
        let appState = AppState()

        appState.applySeasonalThemeIcon(for: .base, isPro: false)
        #expect(appState.currentAppIcon == .base)

        appState.applySeasonalThemeIcon(for: .halloween2026, isPro: true)
        #expect(appState.currentAppIcon == .halloween)

        appState.applySeasonalThemeIcon(for: .base, isPro: true)
        #expect(appState.currentAppIcon == .base)
    }
}
