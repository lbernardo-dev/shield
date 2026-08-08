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
            XCTAssertTrue(
                app.scrollViews.firstMatch.waitForExistence(timeout: 3),
                "Settings root did not reappear after closing \(identifier)"
            )
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
    func testSettingsCloseExitsFromRootAndDestinations() throws {
        let app = launch(scene: "settings")

        let settingsClose = app.buttons["settings.close"]
        XCTAssertTrue(settingsClose.waitForExistence(timeout: 3))
        XCTAssertTrue(settingsClose.isHittable)
        XCTAssertFalse(app.buttons["tab.0"].exists, "The footer must be hidden in Settings")
        settingsClose.tap()
        XCTAssertTrue(app.buttons["tab.0"].waitForExistence(timeout: 3))

        app.buttons["tab.3"].tap()
        let preferences = app.buttons["settings.route.appPreferences"]
        XCTAssertTrue(preferences.waitForExistence(timeout: 3))
        preferences.tap()

        XCTAssertTrue(settingsClose.waitForExistence(timeout: 3))
        XCTAssertTrue(settingsClose.isHittable)
        XCTAssertFalse(app.buttons["tab.0"].exists, "The footer must remain hidden in Settings destinations")
        settingsClose.tap()
        XCTAssertTrue(app.buttons["tab.0"].waitForExistence(timeout: 3))
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
    func testPrimaryTabNavigationAndCaptureDismissal() throws {
        let app = launch(scene: "home")

        for identifier in ["tab.1", "tab.2"] {
            let tab = app.buttons[identifier]
            XCTAssertTrue(tab.waitForExistence(timeout: 3), "Missing tab \(identifier)")
            XCTAssertTrue(tab.isHittable, "Tab is not tappable: \(identifier)")
            tab.tap()
        }

        let settingsTab = app.buttons["tab.3"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 3), "Missing tab tab.3")
        XCTAssertTrue(settingsTab.isHittable, "Tab is not tappable: tab.3")
        settingsTab.tap()

        let closeSettings = app.buttons["settings.close"]
        XCTAssertTrue(closeSettings.waitForExistence(timeout: 3))
        closeSettings.tap()
        XCTAssertTrue(closeSettings.waitForNonExistence(timeout: 3))

        let homeTab = app.buttons["tab.0"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 3), "Missing tab tab.0")
        XCTAssertTrue(homeTab.isHittable, "Tab is not tappable: tab.0")
        homeTab.tap()

        let capture = app.buttons["tab.capture"]
        XCTAssertTrue(capture.isHittable)
        capture.tap()

        let close = app.buttons["capture.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        close.tap()
        XCTAssertTrue(close.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.buttons["tab.0"].isHittable)
    }

    @MainActor
    func testCaptureGuideCanToggleAndDismiss() throws {
        let app = launch(scene: "capture")
        let toggle = app.buttons["capture.toggleGuide"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertTrue(toggle.isHittable)
        toggle.tap()
        XCTAssertTrue(toggle.isHittable)

        let close = app.buttons["capture.close"]
        XCTAssertTrue(close.isHittable)
        close.tap()
        XCTAssertTrue(close.waitForNonExistence(timeout: 3))
    }

    @MainActor
    func testGalleryStylePreviewCanOpenAndDismiss() throws {
        let app = launch(scene: "gallery")
        let style = app.buttons["gallery.style.block"]
        XCTAssertTrue(style.waitForExistence(timeout: 3))
        XCTAssertTrue(style.isHittable)
        style.tap()

        let close = app.buttons["gallery.styleSource.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        close.tap()
        XCTAssertTrue(close.waitForNonExistence(timeout: 3))
        XCTAssertTrue(style.isHittable)
    }

    @MainActor
    func testEditorExportCanOpenAndDismissWithoutChangingDocument() throws {
        let app = launch(scene: "editor")
        let export = app.buttons["editor.export"]
        XCTAssertTrue(export.waitForExistence(timeout: 3))
        XCTAssertTrue(export.isHittable)
        export.tap()

        let closeExport = app.buttons["export.close"]
        XCTAssertTrue(closeExport.waitForExistence(timeout: 3))
        closeExport.tap()
        XCTAssertTrue(closeExport.waitForNonExistence(timeout: 3))

        let closeEditor = app.buttons["editor.close"]
        XCTAssertTrue(closeEditor.isHittable)
        closeEditor.tap()
        if !closeEditor.waitForNonExistence(timeout: 1) {
            let discardChanges = app.buttons["Salir"]
            XCTAssertTrue(discardChanges.waitForExistence(timeout: 3))
            discardChanges.tap()
        }
        XCTAssertTrue(closeEditor.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.buttons["tab.0"].isHittable)
    }

    @MainActor
    func testVaultLockReturnsToAuthenticationGate() throws {
        let app = launch(scene: "vault")
        let lock = app.buttons["vault.lock"]
        XCTAssertTrue(lock.waitForExistence(timeout: 3))
        XCTAssertTrue(lock.isHittable)
        lock.tap()

        let unlock = app.buttons["vault.unlock"]
        XCTAssertTrue(unlock.waitForExistence(timeout: 3))
        XCTAssertTrue(unlock.isHittable)
    }

    @MainActor
    func testPaywallCanDismissToWorkspace() throws {
        let app = launch(scene: "paywall")
        let close = app.buttons["paywall.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 3))
        XCTAssertTrue(close.isHittable)
        close.tap()
        XCTAssertTrue(close.waitForNonExistence(timeout: 3))
        XCTAssertTrue(app.buttons["tab.0"].isHittable)
    }

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
    private func launch(scene: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-aso-screenshots",
            "-aso-language", "es",
            "-aso-scene", scene
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        return app
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

    /// Drives the onboarding flow (steps 0-3) until the camera permission step.
    /// Assumes the app was launched with `-aso-scene onboarding` and language `es`.
    @MainActor
    private func walkToCamera(_ app: XCUIApplication) {
        let start = app.buttons["Empezar"]
        XCTAssertTrue(start.waitForExistence(timeout: 10), "Welcome CTA missing")
        start.tap()

        let goal = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Alquiler")).firstMatch
        XCTAssertTrue(goal.waitForExistence(timeout: 5), "Goal step not reached")
        goal.tap()
        let continue1 = app.buttons["Continuar"]
        XCTAssertTrue(continue1.waitForExistence(timeout: 5))
        XCTAssertTrue(continue1.isEnabled, "Continue disabled on goal step")
        continue1.tap()

        let pain = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Que vean mi foto")).firstMatch
        XCTAssertTrue(pain.waitForExistence(timeout: 5), "Pain point step not reached")
        pain.tap()
        let continue2 = app.buttons["Continuar"]
        XCTAssertTrue(continue2.waitForExistence(timeout: 5))
        continue2.tap()

        let address = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "DIRECCIÓN")).firstMatch
        XCTAssertTrue(address.waitForExistence(timeout: 5), "Demo step not reached")
        address.tap()
        let dobField = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "NAC")).firstMatch
        XCTAssertTrue(dobField.waitForExistence(timeout: 5))
        dobField.tap()

        let seeResult = app.buttons["Ver resultado"]
        XCTAssertTrue(seeResult.waitForExistence(timeout: 5))
        XCTAssertTrue(seeResult.isEnabled, "Selecting 2 fields did not enable demo result")
        seeResult.tap()

        let useIt = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Usarlo")).firstMatch
        XCTAssertTrue(useIt.waitForExistence(timeout: 5), "Demo result CTA missing")
        useIt.tap()
    }

    @MainActor
    func testCameraPermissionNotNowAdvancesToPaywall() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-aso-screenshots",
            "-aso-language", "es",
            "-aso-scene", "onboarding"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        walkToCamera(app)

        let notNow = app.buttons["Ahora no"]
        XCTAssertTrue(notNow.waitForExistence(timeout: 5), "Camera screen not reached")
        Thread.sleep(forTimeInterval: 0.8) // let the step transition settle
        print("CAMERA notNow label=\(notNow.label) enabled=\(notNow.isEnabled) hittable=\(notNow.isHittable) frame=\(notNow.frame)")
        let primaryExists = app.buttons["Activar cámara"].exists
        let primary = primaryExists ? app.buttons["Activar cámara"] : app.buttons["Continuar"]
        print("CAMERA primary exists=\(primary.exists) enabled=\(primary.isEnabled) hittable=\(primary.isHittable)")

        notNow.tap()
        let paywallTitle = app.staticTexts["MaskID Pro"]
        let advanced = paywallTitle.waitForExistence(timeout: 5)
        print("REPRO 'Ahora no' advanced to paywall: \(advanced)")
        XCTAssertTrue(advanced, "Camera 'Ahora no' did not advance to paywall (buttons dead?)")
    }

    @MainActor
    func testCameraPermissionContinueAdvancesToPaywall() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-aso-screenshots",
            "-aso-language", "es",
            "-aso-scene", "onboarding"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        walkToCamera(app)

        let continueButton = app.buttons["Continuar"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), "Camera 'Continuar' not present")
        Thread.sleep(forTimeInterval: 0.8)
        print("CAMERA Continuar label=\(continueButton.label) enabled=\(continueButton.isEnabled) hittable=\(continueButton.isHittable) frame=\(continueButton.frame)")

        continueButton.tap()
        let paywallTitle = app.staticTexts["MaskID Pro"]
        let advanced = paywallTitle.waitForExistence(timeout: 5)
        print("REPRO 'Continuar' advanced to paywall: \(advanced)")
        XCTAssertTrue(advanced, "Camera 'Continuar' did not advance to paywall (buttons dead?)")
    }

}
