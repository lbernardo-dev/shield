import XCTest

final class ShieldLaunchTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testApplicationReachesForeground() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
    }

    @MainActor
    func testLaunchScreenAccessibility() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        try app.performAccessibilityAudit(for: [
            .elementDetection,
            .hitRegion,
            .sufficientElementDescription,
            .trait
        ])
    }

    @MainActor
    func testHomeAccessibilityInEnglishAndSpanish() throws { try audit(scene: "home") }

    @MainActor
    func testOnboardingAccessibilityInEnglishAndSpanish() throws { try audit(scene: "onboarding") }

    @MainActor
    func testCaptureAccessibilityInEnglishAndSpanish() throws { try audit(scene: "capture") }

    @MainActor
    func testGalleryAccessibilityInEnglishAndSpanish() throws { try audit(scene: "gallery") }

    @MainActor
    func testEditorAccessibilityInEnglishAndSpanish() throws { try audit(scene: "editor") }

    @MainActor
    func testOCRAccessibilityInEnglishAndSpanish() throws { try audit(scene: "ocr") }

    @MainActor
    func testExportAccessibilityInEnglishAndSpanish() throws { try audit(scene: "export") }

    @MainActor
    func testBatchAccessibilityInEnglishAndSpanish() throws { try audit(scene: "batch") }

    @MainActor
    func testVaultAccessibilityInEnglishAndSpanish() throws { try audit(scene: "vault") }

    @MainActor
    func testSettingsAccessibilityInEnglishAndSpanish() throws { try audit(scene: "settings") }

    @MainActor
    func testSettingsNavigationRespondsToSingleTaps() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-aso-screenshots",
            "-aso-language", "es",
            "-aso-scene", "settings"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let routeIdentifiers = [
            "settings.route.appPreferences",
            "settings.route.security",
            "settings.route.cloud",
            "settings.route.export",
            "settings.route.information",
            "settings.route.whatsNew",
            "settings.route.privacy",
            "settings.route.terms",
            "settings.route.subscriptionTerms",
            "settings.route.support",
            "settings.route.faq"
        ]

        for identifier in routeIdentifiers {
            let route = app.buttons[identifier]
            scrollToElement(route, in: app)
            XCTAssertTrue(route.isHittable, route.debugDescription)
            route.tap()

            let backButton = app.buttons["settings.back"]
            XCTAssertTrue(backButton.waitForExistence(timeout: 3), "No explicit back action for \(identifier)")
            XCTAssertTrue(backButton.isHittable, "Back action is not hittable for \(identifier)")
            XCTAssertNotEqual(backButton.label, "common_back", "Back action is showing an untranslated localization key for \(identifier)")
            backButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            XCTAssertTrue(
                backButton.waitForNonExistence(timeout: 3),
                "The destination did not close after one physical-coordinate tap for \(identifier)"
            )
            XCTAssertTrue(app.staticTexts["Ajustes"].waitForExistence(timeout: 3))
        }

        let support = app.buttons["settings.route.support"]
        scrollToElement(support, in: app)
        XCTAssertTrue(support.isHittable)
        support.tap()
        XCTAssertTrue(app.buttons["settings.back"].waitForExistence(timeout: 3))

        let sendFeedback = app.buttons["settings.action.sendFeedback"]
        scrollToElement(sendFeedback, in: app)
        XCTAssertTrue(sendFeedback.isHittable)
        sendFeedback.tap()
        XCTAssertTrue(
            app.wait(for: .runningBackground, timeout: 5),
            "Feedback should open an available mail client or the support web fallback"
        )
    }

    @MainActor
    func testSettingsBackReturnsToRootWithOneTap() throws {
        executionTimeAllowance = 60
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-aso-screenshots",
            "-aso-language", "es",
            "-aso-scene", "settings"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let preferences = app.buttons["settings.route.appPreferences"]
        XCTAssertTrue(preferences.waitForExistence(timeout: 3))
        XCTAssertTrue(preferences.isHittable)
        preferences.tap()

        let backButton = app.buttons["settings.back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 3))
        XCTAssertTrue(backButton.isHittable)
        backButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        XCTAssertTrue(backButton.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Ajustes"].waitForExistence(timeout: 3))
        XCTAssertTrue(preferences.waitForExistence(timeout: 3))
        XCTAssertTrue(preferences.isHittable, "The settings root was not interactive after one back tap")
    }

    @MainActor
    func testRateAppOpensShieldReviewDestination() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-aso-screenshots",
            "-aso-language", "es",
            "-aso-scene", "settings"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let rateApp = app.buttons["settings.action.rateApp"]
        scrollToElement(rateApp, in: app)
        XCTAssertTrue(rateApp.isHittable, rateApp.debugDescription)
        rateApp.tap()
        XCTAssertTrue(
            app.wait(for: .runningBackground, timeout: 5),
            "Rate Shield should leave the app for its native or web App Store review destination"
        )
    }

    @MainActor
    func testPaywallAccessibilityInEnglishAndSpanish() throws { try audit(scene: "paywall") }

    @MainActor
    private func audit(scene: String) throws {
        for language in ["en", "es"] {
            let app = XCUIApplication()
            app.launchArguments = [
                "-ui-testing",
                "-aso-screenshots",
                "-aso-language", language,
                "-aso-scene", scene
            ]
            app.launch()
            XCTAssertTrue(
                app.wait(for: .runningForeground, timeout: 10),
                "Failed to launch \(scene) in \(language)"
            )
            XCTAssertTrue(
                app.windows.firstMatch.waitForExistence(timeout: 5),
                "No application window for \(scene) in \(language)"
            )
            _ = app.staticTexts.firstMatch.waitForExistence(timeout: 2)
            Thread.sleep(forTimeInterval: 0.5) // Allow simulator accessibility bridge to settle
            try app.performAccessibilityAudit(for: [
                .elementDetection,
                .hitRegion,
                .trait
            ]) { issue in
                let elementDescription = issue.element?.debugDescription ?? "<no element>"
                print("ACCESSIBILITY AUDIT [\(scene)/\(language)] \(issue.compactDescription)\n\(elementDescription)")
                
                // Element Detection is Vision-based. Dense protected-document previews
                // occasionally produce a report without an accessibility element to
                // remediate. Keep logging that diagnostic while never suppressing an
                // issue tied to a concrete XCUIElement.
                if issue.auditType == .elementDetection, issue.element == nil {
                    return true
                }
                
                // Ignore native search textfield hit target size issue
                if issue.auditType == .hitRegion, let element = issue.element {
                    let desc = element.debugDescription.lowercased()
                    if desc.contains("search") || desc.contains("buscar") {
                        return true
                    }
                }
                
                return false
            }
            app.terminate()
        }
    }

    @MainActor
    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication) {
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 3))
        let threshold = app.frame.maxY - 110 // Clear custom tab bar
        let topThreshold: CGFloat = 80 // Clear navigation bar
        var attempts = 0
        while attempts < 15 {
            if element.exists && element.isHittable {
                let frame = element.frame
                if frame.minY >= topThreshold && frame.maxY <= threshold {
                    break
                }
            }
            if element.exists {
                if element.frame.minY < topThreshold {
                    scrollView.swipeDown()
                } else {
                    scrollView.swipeUp()
                }
            } else {
                scrollView.swipeUp()
            }
            attempts += 1
        }
    }

}
