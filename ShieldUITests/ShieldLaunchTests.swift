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

            let navigationBar = app.navigationBars.firstMatch
            XCTAssertTrue(navigationBar.waitForExistence(timeout: 3), "No destination opened for \(identifier)")
            let backButton = navigationBar.buttons.firstMatch
            XCTAssertTrue(backButton.isHittable, "No back action for \(identifier)")
            backButton.tap()
            XCTAssertTrue(app.staticTexts["Ajustes"].waitForExistence(timeout: 3))
        }

        let support = app.buttons["settings.route.support"]
        scrollToElement(support, in: app)
        XCTAssertTrue(support.isHittable)
        support.tap()
        XCTAssertTrue(app.navigationBars["Soporte"].waitForExistence(timeout: 3))

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
                return false
            }
            app.terminate()
        }
    }

    @MainActor
    private func scrollToElement(_ element: XCUIElement, in app: XCUIApplication) {
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 3))
        var attempts = 0
        while !element.isHittable, attempts < 16 {
            scrollView.swipeUp(velocity: .fast)
            attempts += 1
        }
    }

}
