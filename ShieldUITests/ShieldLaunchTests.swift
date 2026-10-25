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
    func testLockCompositionCentersOnAvailableDisplayAxis() throws {
        let app = launch(scene: "lock")
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))

        let elements = [
            app.descendants(matching: .any).matching(identifier: "lock.identityMark").firstMatch,
            app.staticTexts["lock.title"],
            app.buttons["lock.primaryUnlock"]
        ]
        let tolerance = max(16, window.frame.width * 0.02)

        for element in elements {
            XCTAssertTrue(element.waitForExistence(timeout: 5), element.debugDescription)
            XCTAssertLessThanOrEqual(
                abs(element.frame.midX - window.frame.midX),
                tolerance,
                "Lock content should align with the display/hinge center: \(element.debugDescription)"
            )
        }

        let isFoldedDuoWindow = (440..<700).contains(window.frame.width) && window.frame.height < 800
        if isFoldedDuoWindow {
            XCTAssertLessThanOrEqual(
                app.buttons["lock.primaryUnlock"].frame.maxX,
                window.frame.maxX - 80,
                "The primary action should stay clear of the Duo system rail"
            )
        }
    }

    @MainActor
    func testHomeBrandAndProfileAreAvailableInToolbar() throws {
        let app = launch(scene: "home")
        let window = app.windows.firstMatch
        let brand = app.descendants(matching: .any).matching(identifier: "home.toolbar.brand").firstMatch
        let profile = app.buttons["home.toolbar.profile"]

        XCTAssertTrue(brand.waitForExistence(timeout: 5), brand.debugDescription)
        XCTAssertTrue(profile.waitForExistence(timeout: 5), profile.debugDescription)
        XCTAssertTrue(profile.isHittable, "The profile action should remain reachable in the adaptive toolbar")
        if UIDevice.current.userInterfaceIdiom == .pad {
            let capture = scanTab(in: app)
            XCTAssertTrue(capture.waitForExistence(timeout: 5), capture.debugDescription)
            XCTAssertTrue(capture.isHittable, "The contextual iPad toolbar scan action should remain reachable")
            XCTAssertTrue(window.frame.intersects(capture.frame), "The iPad scan action should remain within the app window")
        } else {
            XCTAssertEqual(scanTabCount(in: app), 0, "Phone Home must not show a floating Scan accessory")
        }
        XCTAssertTrue(window.frame.intersects(brand.frame), "The brand should remain within the app window")
        XCTAssertTrue(window.frame.intersects(profile.frame), "The profile action should remain within the app window")
    }

    @MainActor
    func testHomeQuickAccessActionsAreVisibleAndTappable() throws {
        // Avoid a frozen accessibility snapshot on large simulator layouts
        // consuming XCTest's default 15-minute allowance.
        executionTimeAllowance = 120
        let app = launch(scene: "home")
        let window = app.windows.firstMatch
        let homeScrollView = app.scrollViews["home.scroll"]
        XCTAssertTrue(window.waitForExistence(timeout: 5))

        let primaryAction = app.buttons["home.primaryAction"]
        XCTAssertTrue(primaryAction.waitForExistence(timeout: 5), "The primary protection action should be visible first")
        XCTAssertTrue(primaryAction.isHittable, "The primary protection action should be immediately tappable")
        XCTAssertEqual(primaryAction.label, "Proteger un documento")

        let actionIDs = [
            ("home.quickAccess.library", "Todos los documentos", "All documents"),
            ("home.quickAccess.vault", "Bóveda", "Vault"),
            ("home.quickAccess.tools", "Modos, lote y nube", "Modes, batch, and cloud")
        ]

        for (identifier, spanishTitle, _) in actionIDs {
            let action = app.buttons[identifier]
            XCTAssertTrue(action.waitForExistence(timeout: 5), "Missing quick access action: \(identifier)")
            // On Duo's shorter display, later dashboard actions may begin
            // below the initial scroll position. Scroll only until each
            // action has a tappable hit region; partly visible cards can
            // still be reached without moving the dashboard unnecessarily.
            for _ in 0..<4 where !action.isHittable {
                XCTAssertTrue(homeScrollView.exists, "Home dashboard should remain vertically scrollable")
                homeScrollView.swipeUp()
            }
            XCTAssertTrue(action.isHittable, "Quick access action is not tappable: \(identifier)")
            XCTAssertEqual(action.label, spanishTitle, "Quick access label should be localized in Spanish: \(identifier)")
            XCTAssertGreaterThanOrEqual(action.frame.width, 44, "Quick access action needs a 44pt width: \(identifier)")
            XCTAssertGreaterThanOrEqual(action.frame.height, 44, "Quick access action needs a 44pt height: \(identifier)")
            XCTAssertTrue(window.frame.intersects(action.frame), "Quick access action is outside the app window: \(identifier)")
        }

        let toolsAction = app.buttons["home.quickAccess.tools"]
        toolsAction.tap()
        let workspaceToggle = app.buttons["home.workspace.toggle"]
        XCTAssertTrue(workspaceToggle.waitForExistence(timeout: 8), workspaceToggle.debugDescription)
        let expandedState = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Expandido"),
            object: workspaceToggle
        )
        let expandedStateResult = XCTWaiter.wait(for: [expandedState], timeout: 8)
        let toolsScreenshot = XCTAttachment(screenshot: app.screenshot())
        toolsScreenshot.name = "Home quick tools after tap"
        toolsScreenshot.lifetime = .keepAlways
        add(toolsScreenshot)
        XCTAssertEqual(expandedStateResult, .completed, "Expanding quick access should update the workspace toggle state")
        XCTAssertEqual(workspaceToggle.value as? String, "Expandido")
        let batchAction = app.buttons["home.quickModes.batch"]
        XCTAssertTrue(batchAction.waitForExistence(timeout: 8), "Expanding tools should expose the batch action")
        XCTAssertTrue(batchAction.isHittable, "The quick tools action should expand and reveal the batch tool")

        app.terminate()
        let englishApp = XCUIApplication()
        englishApp.launchArguments = [
            "-ui-testing",
            "-aso-screenshots",
            "-aso-language", "en",
            "-aso-scene", "home"
        ]
        englishApp.launch()
        XCTAssertTrue(englishApp.wait(for: .runningForeground, timeout: 10))
        let englishPrimaryAction = englishApp.buttons["home.primaryAction"]
        XCTAssertTrue(englishPrimaryAction.waitForExistence(timeout: 5))
        XCTAssertEqual(englishPrimaryAction.label, "Protect a document")
        for (identifier, _, englishTitle) in actionIDs {
            let action = englishApp.buttons[identifier]
            XCTAssertTrue(action.waitForExistence(timeout: 5), "Missing quick access action: \(identifier)")
            XCTAssertEqual(action.label, englishTitle, "Quick access label should be localized in English: \(identifier)")
        }
    }

    @MainActor
    func testDuoHomeKeepsBrandProfileAndPrimaryActionVisible() throws {
        let app = launch(scene: "home")
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))
        guard UIDevice.current.userInterfaceIdiom == .phone, window.frame.width >= 600 else {
            throw XCTSkip("This layout check targets the wide inner display of iPhone Duo")
        }

        let brand = app.descendants(matching: .any).matching(identifier: "home.toolbar.brand").firstMatch
        let profile = app.buttons["home.toolbar.profile"]
        let primaryAction = app.buttons["home.primaryAction"]
        let settingsNavigationItem = app.buttons["tab.3"]
        let categoryViewport = app.descendants(matching: .any)
            .matching(identifier: "home.categoryGrid")
            .firstMatch
        for control in [brand, profile, primaryAction] {
            XCTAssertTrue(control.waitForExistence(timeout: 5), control.debugDescription)
            XCTAssertTrue(window.frame.intersects(control.frame), "Home control is outside the Duo window: \(control)")
            XCTAssertTrue(control.isHittable, "Home control is not tappable in Duo landscape: \(control)")
        }
        XCTAssertEqual(scanTabCount(in: app), 0, "Duo Home must not expose the floating bottom Scan accessory")
        XCTAssertTrue(settingsNavigationItem.waitForExistence(timeout: 5), settingsNavigationItem.debugDescription)
        XCTAssertTrue(categoryViewport.waitForExistence(timeout: 5), categoryViewport.debugDescription)
        XCTAssertGreaterThan(brand.frame.width, 80, "The Duo header should show the app name beside its icon")
        XCTAssertLessThanOrEqual(
            abs(brand.frame.midY - profile.frame.midY),
            16,
            "The brand and avatar should share one horizontal header row"
        )
        XCTAssertLessThan(
            settingsNavigationItem.frame.maxX,
            primaryAction.frame.minX,
            "Wide displays should keep native navigation in a separate sidebar column"
        )
    }

    @MainActor
    func testCompactHomeHasNoFloatingScanAccessory() throws {
        let app = launch(scene: "home")
        let window = app.windows.firstMatch
        let primaryAction = app.buttons["home.primaryAction"]
        let search = app.textFields["home.searchField"]
        let categories = app.descendants(matching: .any)
            .matching(identifier: "home.categoryGrid")
            .firstMatch

        XCTAssertTrue(window.waitForExistence(timeout: 5))
        guard UIDevice.current.userInterfaceIdiom == .phone, window.frame.width < window.frame.height else {
            throw XCTSkip("This layout check targets compact phone Home")
        }
        XCTAssertEqual(scanTabCount(in: app), 0, "Compact Home must not show a floating Scan button or accessory")
        XCTAssertTrue(primaryAction.waitForExistence(timeout: 5), primaryAction.debugDescription)
        XCTAssertTrue(primaryAction.isHittable, "Home must retain its contextual document protection action")
        XCTAssertTrue(search.waitForExistence(timeout: 5), search.debugDescription)
        XCTAssertTrue(categories.waitForExistence(timeout: 5), categories.debugDescription)

        for category in ["all", "identity", "travel", "driving", "work", "health", "finance", "add"] {
            let button = app.buttons["home.category.\(category)"]
            XCTAssertTrue(button.waitForExistence(timeout: 3), "Missing compact category: \(category)")
            XCTAssertGreaterThanOrEqual(button.frame.width, 43.5, "Category \(category) needs a 44pt tap target")
            XCTAssertGreaterThanOrEqual(button.frame.height, 43.5, "Category \(category) needs a 44pt tap target")
            XCTAssertGreaterThanOrEqual(button.frame.minX, window.frame.minX + 8, "Category \(category) clips at the left edge")
            XCTAssertLessThanOrEqual(button.frame.maxX, window.frame.maxX - 8, "Category \(category) clips at the right edge")
        }
    }

    @MainActor
    func testHomeSearchFindsLocalOCRTextWithoutShowingUnmatchedDocuments() throws {
        let app = launch(scene: "home")
        let search = app.textFields["home.searchField"]
        XCTAssertTrue(search.waitForExistence(timeout: 5), search.debugDescription)
        XCTAssertTrue(search.isHittable)
        search.tap()
        search.typeText("Garcia\n")

        let matchingDocument = app.staticTexts["DNI — copia protegida"]
        scrollToElement(matchingDocument, in: app, scrollViewIdentifier: "home.scroll")
        XCTAssertTrue(matchingDocument.waitForExistence(timeout: 5), "Search should match normalized OCR names locally")
        XCTAssertFalse(app.staticTexts["Contrato de alquiler"].exists, "Unmatched documents should leave the recent result")
    }

    @MainActor
    func testProfileHasOneIconOnlySaveActionAtTheBottom() throws {
        let app = launch(scene: "profile")
        let close = app.buttons["profile.close"]
        let save = app.buttons["profile.save"]

        XCTAssertTrue(close.waitForExistence(timeout: 5), close.debugDescription)
        XCTAssertTrue(save.waitForExistence(timeout: 5), save.debugDescription)
        XCTAssertEqual(app.buttons.matching(identifier: "profile.save").count, 1)
        XCTAssertGreaterThan(save.frame.midY, app.windows.firstMatch.frame.midY)
        XCTAssertFalse(app.buttons["Guardar perfil"].exists,
                       "The duplicate full-width Save button should be absent from the profile form")
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
    func testLockAccessibilityInEnglishAndSpanish() throws { try audit(scene: "lock") }

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
    func testBatchPendingReviewQueueOpensTheAffectedDocument() throws {
        let app = launch(scene: "batch-review-queue")
        let review = app.buttons["home.batch.reviewDocument.aso-identity"]
        XCTAssertTrue(review.waitForExistence(timeout: 5), app.debugDescription)
        scrollToElement(review, in: app, scrollViewIdentifier: "home.batch.reviewQueue")
        XCTAssertTrue(review.isHittable)
        review.tap()

        let closeEditor = app.buttons["editor.close"]
        XCTAssertTrue(closeEditor.waitForExistence(timeout: 8), "Opening a pending queue item should return to its editor")
        if !closeEditor.isHittable {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "Batch queue editor close control not hittable"
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTFail("The editor close control is not hittable after opening the queued document. Frame: \(closeEditor.frame); window: \(app.windows.firstMatch.frame)\n\(app.debugDescription)")
        }
    }

    @MainActor
    func testQueuedImportFailureCanRetryThenSkipWithoutLosingFollowingFile() throws {
        let app = launch(scene: "batch-import-recovery")
        let importError = app.otherElements["capture.importError"]
        let retry = app.buttons["capture.importError.primary"]
        let skip = app.buttons["capture.importError.dismiss"]

        XCTAssertTrue(retry.waitForExistence(timeout: 15), app.debugDescription)
        XCTAssertTrue(importError.exists, "The failed first file should be identified in the import queue")
        retry.tap()
        XCTAssertTrue(retry.waitForNonExistence(timeout: 5), "Retry should dismiss the error while processing the same file")
        XCTAssertTrue(retry.waitForExistence(timeout: 15), "A repeated failure should retain the current file and offer retry again")

        skip.tap()
        let review = app.buttons["scanReview.continue"]
        XCTAssertTrue(review.waitForExistence(timeout: 15), "Skipping one failed file should continue with the next queued image")
        XCTAssertTrue(app.buttons["scanReview.cancel"].isHittable)
        app.buttons["scanReview.cancel"].tap()
        XCTAssertTrue(app.buttons["capture.scan"].waitForExistence(timeout: 8), "The remaining files should be discarded when the user cancels review")
        XCTAssertFalse(review.exists, "Cancelled review must not continue into another queued file")
    }

    @MainActor
    func testCancelingScanReviewCancelsRemainingQueuedFiles() throws {
        let app = launch(scene: "batch-import-cancel")
        let review = app.buttons["scanReview.continue"]
        XCTAssertTrue(review.waitForExistence(timeout: 15), app.debugDescription)

        let cancel = app.buttons["scanReview.cancel"]
        XCTAssertTrue(cancel.isHittable)
        cancel.tap()

        XCTAssertTrue(app.buttons["capture.scan"].waitForExistence(timeout: 8), "Cancel should return to the capture menu")
        XCTAssertTrue(review.waitForNonExistence(timeout: 5), "Cancelling the first file should stop the remaining queued file")
    }

    @MainActor
    func testVaultAccessibilityInEnglishAndSpanish() throws { try audit(scene: "vault") }

    @MainActor
    func testSettingsAccessibilityInEnglishAndSpanish() throws { try audit(scene: "settings") }

    @MainActor
    func testSettingsSummaryCardPrecedesAllSettingsSections() throws {
        let app = launch(scene: "settings")
        let header = app.staticTexts["settings.header.title"]
        let summary = app.descendants(matching: .any)
            .matching(identifier: "settings.summary")
            .firstMatch
        let firstSettingsRow = app.buttons["settings.route.themes"]

        XCTAssertTrue(header.waitForExistence(timeout: 5), "Settings should show a centered navigation title")
        XCTAssertTrue(summary.waitForExistence(timeout: 5), "Settings should show the account summary below its navigation header")
        XCTAssertTrue(firstSettingsRow.waitForExistence(timeout: 5), "The first settings section should follow the summary")
        XCTAssertLessThan(
            header.frame.maxY,
            summary.frame.minY,
            "The account summary should start below the Settings navigation header"
        )
        XCTAssertTrue(summary.isHittable, "The summary card should be visible at the top of Settings")
        XCTAssertLessThan(
            summary.frame.maxY,
            firstSettingsRow.frame.minY,
            "The summary card should appear before every settings section"
        )
    }

    @MainActor
    func testWhatsNewMatchesApprovedEnglishAndSpanishCopy() throws {
        let approvedCopy = [
            ("en", "Security status indicators retain their meaning across themes."),
            ("en", "On-device face suggestions respect image orientation; review and adjust each mask before export."),
            ("es", "Los indicadores del estado de seguridad conservan su significado entre temas."),
            ("es", "Las sugerencias locales de rostros respetan la orientación de página y se revisan antes de exportar.")
        ]

        for (language, expectedCopy) in approvedCopy {
            let app = XCUIApplication()
            app.launchArguments = [
                "-ui-testing", "-aso-screenshots",
                "-aso-language", language,
                "-aso-scene", "settings"
            ]
            app.launch()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

            let whatsNewRoute = app.buttons["settings.route.whatsNew"]
            scrollToElement(whatsNewRoute, in: app)
            XCTAssertTrue(whatsNewRoute.isHittable)
            whatsNewRoute.tap()
            XCTAssertTrue(app.staticTexts[expectedCopy].waitForExistence(timeout: 5), app.debugDescription)
            app.terminate()
        }
    }

    @MainActor
    func testSettingsNavigationRespondsToSingleTaps() throws {
        // Keep a broken simulator accessibility snapshot from consuming the
        // default XCTest allowance for dozens of minutes in the full suite.
        executionTimeAllowance = 180
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

        let missingFeature = app.buttons["feedback.option.missing_feature"]
        XCTAssertTrue(
            missingFeature.waitForExistence(timeout: 3),
            "Feedback form should show localized category options"
        )
        XCTAssertEqual(missingFeature.label, "Falta una función")
        XCTAssertTrue(
            app.textFields["feedback.comment"].waitForExistence(timeout: 3),
            "Feedback form should show a free-text comment field"
        )
        XCTAssertEqual(app.textFields["feedback.comment"].label, "Comentario opcional")
        XCTAssertEqual(app.buttons["feedback.action.send"].label, "Enviar comentarios")
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
        XCTAssertEqual(scanTabCount(in: app), 0, "Settings must not show a floating Scan control or empty accessory")
        let usesRegularWidth = app.windows.firstMatch.frame.width >= 600
        let nativeSidebarTab = app.cells["tab.0"]
        if nativeSidebarTab.exists {
            // When the native sidebar is expanded, its Documents row remains
            // available while Settings is selected.
            XCTAssertTrue(nativeSidebarTab.isHittable)
        } else if !usesRegularWidth {
            XCTAssertFalse(libraryTab(in: app).isHittable, "Compact footer navigation should be hidden while Settings is open")
        }

        let settingsClose = app.buttons["settings.close"]
        XCTAssertTrue(settingsClose.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsClose.isHittable)
        settingsClose.tap()
        // Tab bar reappears after Settings dismissal animation; allow extra time
        XCTAssertTrue(libraryTab(in: app).waitForExistence(timeout: 8))

        navigationTab(in: app, index: 3).tap()
        XCTAssertEqual(scanTabCount(in: app), 0, "Settings destinations must not show a floating Scan control")
        let preferences = app.buttons["settings.route.appPreferences"]
        XCTAssertTrue(preferences.waitForExistence(timeout: 5))
        preferences.tap()
        if !usesRegularWidth {
            XCTAssertFalse(libraryTab(in: app).isHittable, "Compact footer navigation should stay hidden in Settings destinations")
        }

        XCTAssertTrue(settingsClose.waitForExistence(timeout: 5))
        XCTAssertTrue(settingsClose.isHittable)
        settingsClose.tap()
        // Tab bar reappears after Settings dismissal animation; allow extra time
        XCTAssertTrue(libraryTab(in: app).waitForExistence(timeout: 8))
    }

    @MainActor
    func testRateAppOpensManualStoreReviewPage() throws {
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

        let rateApp = app.buttons["settings.action.rateApp"]
        scrollToElement(rateApp, in: app)
        XCTAssertTrue(rateApp.isHittable, rateApp.debugDescription)
        rateApp.tap()

        // The manual action opens Apple's product page. If the simulator has
        // no App Store handler, the app stays visible and shows its fallback.
        let openedExternalPage = app.wait(for: .runningBackground, timeout: 5)
        if openedExternalPage { app.activate() }
        XCTAssertTrue(
            openedExternalPage || app.alerts.firstMatch.waitForExistence(timeout: 2),
            "Rate the app should open Apple's review page or show an unavailable alert"
        )
    }

    @MainActor
    func testManualFeedbackFormIsLocalizedAndHasFreeText() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-aso-screenshots",
            "-aso-language", "es",
            "-aso-scene", "settings"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let sendFeedback = app.buttons["settings.action.sendFeedback"]
        scrollToElement(sendFeedback, in: app)
        XCTAssertTrue(sendFeedback.isHittable)
        sendFeedback.tap()

        let missingFeature = app.buttons["feedback.option.missing_feature"]
        XCTAssertTrue(missingFeature.waitForExistence(timeout: 3))
        XCTAssertEqual(missingFeature.label, "Falta una función")
        XCTAssertEqual(app.textFields["feedback.comment"].label, "Comentario opcional")
        XCTAssertEqual(app.buttons["feedback.action.send"].label, "Enviar comentarios")
    }

    @MainActor
    func testPaywallAccessibilityInEnglishAndSpanish() throws { try audit(scene: "paywall") }

    @MainActor
    func testPrimaryTabNavigationAndCaptureDismissal() throws {
        let app = launch(scene: "home")

        for index in [1, 2] {
            let tab = navigationTab(in: app, index: index)
            XCTAssertTrue(tab.waitForExistence(timeout: 3), "Missing tab tab.\(index)")
            XCTAssertTrue(tab.isHittable, "Tab is not tappable: tab.\(index)")
            tab.tap()
        }

        let settingsTab = navigationTab(in: app, index: 3)
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 3), "Missing tab tab.3")
        XCTAssertTrue(settingsTab.isHittable, "Tab is not tappable: tab.3")
        settingsTab.tap()

        let closeSettings = app.buttons["settings.close"]
        XCTAssertTrue(closeSettings.waitForExistence(timeout: 3))
        closeSettings.tap()
        XCTAssertTrue(closeSettings.waitForNonExistence(timeout: 5))

        // Tab bar reappears after Settings dismissal animation; allow extra time
        let homeTab = libraryTab(in: app)
        XCTAssertTrue(homeTab.waitForExistence(timeout: 8), "Missing tab tab.0")
        XCTAssertTrue(homeTab.isHittable, "Tab is not tappable: tab.0")
        homeTab.tap()

        let primaryAction = app.buttons["home.primaryAction"]
        XCTAssertTrue(primaryAction.waitForExistence(timeout: 3))
        XCTAssertTrue(primaryAction.isHittable)
        primaryAction.tap()

        let close = app.buttons["capture.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5))
        close.tap()
        XCTAssertTrue(close.waitForNonExistence(timeout: 5))
        XCTAssertTrue(libraryTab(in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(libraryTab(in: app).isHittable)
    }

    @MainActor
    func testHomePrimaryActionOpensDocumentIntake() throws {
        let app = launch(scene: "home")
        let primaryAction = app.buttons["home.primaryAction"]

        XCTAssertTrue(primaryAction.waitForExistence(timeout: 3))
        XCTAssertTrue(primaryAction.isHittable)
        let contextualScanCount = UIDevice.current.userInterfaceIdiom == .pad ? 1 : 0
        XCTAssertEqual(
            scanTabCount(in: app),
            contextualScanCount,
            "Phone Home has no floating Scan accessory; iPad retains its contextual toolbar action"
        )
        primaryAction.tap()

        let close = app.buttons["capture.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5), "The Home protection action should open the document intake flow")
        XCTAssertTrue(close.isHittable, "The intake close action should remain inside the safe area")
    }

    @MainActor
    func testIPadToolbarScanActionOpensDocumentIntake() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This contextual toolbar action is available on iPad")
        }

        let app = launch(scene: "home")
        let capture = app.buttons["tab.capture"]
        XCTAssertTrue(capture.waitForExistence(timeout: 5), capture.debugDescription)
        XCTAssertTrue(capture.isHittable)
        capture.tap()

        let close = app.buttons["capture.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 5), "The contextual iPad toolbar action should open document intake")
        XCTAssertTrue(close.isHittable)
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
    func testPhotoPickerCanCancelAndFilesPickerOpens() throws {
        let app = launch(scene: "capture")
        let cancelLabels = NSPredicate(format: "label ==[c] %@ OR label ==[c] %@", "Cancel", "Cancelar")

        let photos = app.buttons["capture.source.photos"]
        XCTAssertTrue(photos.waitForExistence(timeout: 3))
        XCTAssertTrue(photos.isHittable)
        photos.tap()
        let photosCancel = app.buttons.matching(cancelLabels).firstMatch
        XCTAssertTrue(photosCancel.waitForExistence(timeout: 8), app.debugDescription)
        photosCancel.tap()
        XCTAssertTrue(photos.waitForExistence(timeout: 5))
        XCTAssertTrue(photos.isHittable)

        let files = app.buttons["capture.source.files"]
        XCTAssertTrue(files.isHittable)
        files.tap()
        // iPhone exposes Recents as a button. iPad can open directly into the
        // document browser's empty-state view, where the same destination is
        // represented by its "No Recents" message instead.
        let recents = app.buttons.matching(
            NSPredicate(format: "label ==[c] %@ OR label ==[c] %@", "Recents", "Recientes")
        ).firstMatch
        let emptyRecents = app.staticTexts.matching(
            NSPredicate(format: "label ==[c] %@ OR label ==[c] %@", "No Recents", "Sin recientes")
        ).firstMatch
        let fileBrowserOpened = recents.waitForExistence(timeout: 8)
            || emptyRecents.waitForExistence(timeout: 1)
        XCTAssertTrue(fileBrowserOpened, app.debugDescription)
        XCTAssertFalse(files.isHittable, "The system Files picker should take focus while it is presented")

        app.terminate()
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
    func testScanReviewHeaderStaysBelowSystemStatusBar() throws {
        let simulatorName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? ""
        guard !simulatorName.localizedCaseInsensitiveContains("duo") else {
            throw XCTSkip("The Duo places scan review actions in its dedicated right rail")
        }

        let app = launch(scene: "scan-review")
        let window = app.windows.firstMatch
        let navigationBar = app.navigationBars["Mejorar escaneo"]
        let cancel = app.buttons["scanReview.cancel"]
        let continueButton = app.buttons["scanReview.continue"]

        XCTAssertTrue(window.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(cancel.isHittable, "Cancel should remain reachable in the native navigation bar")
        XCTAssertTrue(continueButton.isHittable, "Continue should remain reachable in the native navigation bar")
        XCTAssertTrue(window.frame.intersects(cancel.frame), "Cancel must remain inside the app's safe display area")
        XCTAssertTrue(window.frame.intersects(continueButton.frame), "Continue must remain inside the app's safe display area")
        XCTAssertGreaterThanOrEqual(
            cancel.frame.minY,
            navigationBar.frame.minY - 1,
            "The scan review cancel action must stay within the safe navigation bar"
        )
        XCTAssertGreaterThanOrEqual(
            continueButton.frame.minY,
            navigationBar.frame.minY - 1,
            "The scan review continue action must stay within the safe navigation bar"
        )
        XCTAssertLessThanOrEqual(cancel.frame.maxY, navigationBar.frame.maxY + 1)
        XCTAssertLessThanOrEqual(continueButton.frame.maxY, navigationBar.frame.maxY + 1)
        XCTAssertLessThanOrEqual(
            cancel.frame.minX,
            window.frame.maxX,
            "The cancel action must not extend into the iPhone status area"
        )
        XCTAssertLessThanOrEqual(
            continueButton.frame.maxX,
            window.frame.maxX,
            "The continue action must not extend into the iPhone status area"
        )

        app.terminate()
    }

    @MainActor
    func testDuoScanReviewActionsUseReservedRightRail() throws {
        let simulatorName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? ""
        guard simulatorName.localizedCaseInsensitiveContains("duo") else {
            throw XCTSkip("This placement assertion applies to the Duo reserved action rail")
        }

        let app = launch(scene: "scan-review", orientation: .landscapeRight)
        let window = app.windows.firstMatch
        let cancel = app.buttons["scanReview.cancel"]
        let continueButton = app.buttons["scanReview.continue"]

        XCTAssertTrue(window.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(cancel.isHittable, cancel.debugDescription)
        XCTAssertTrue(continueButton.isHittable, continueButton.debugDescription)
        XCTAssertGreaterThan(cancel.frame.midX, window.frame.midX, "Cancel should use Duo's reserved right action rail")
        XCTAssertGreaterThan(continueButton.frame.midX, window.frame.midX, "Continue should use Duo's reserved right action rail")

        app.terminate()
    }

    @MainActor
    func testDuoEditorActionsAndToolsStayInTheirAdaptiveRegions() throws {
        let simulatorName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? ""
        guard simulatorName.localizedCaseInsensitiveContains("duo") else {
            throw XCTSkip("This placement assertion applies to the Duo outer-display safe area")
        }

        let app = launch(scene: "editor", orientation: .landscapeRight)
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5), app.debugDescription)
        dismissUnsignedBuildPersistenceErrorIfPresent(in: app)

        let moreActions = app.buttons["editor.moreActions"]
        let actions = [app.buttons["editor.close"], moreActions, app.buttons["editor.export"]]
        for action in actions {
            XCTAssertTrue(action.waitForExistence(timeout: 5), action.debugDescription)
            XCTAssertTrue(action.isHittable, "Editor action is not reachable: \(action)")
            XCTAssertTrue(window.frame.intersects(action.frame), "Editor action is outside the app viewport: \(action)")
            XCTAssertLessThanOrEqual(
                action.frame.maxX,
                window.frame.maxX,
                "Native editor navigation actions must stay inside the Duo window: \(action)"
            )
        }
        let railActionMinX = min(
            app.buttons["editor.close"].frame.minX,
            app.buttons["editor.export"].frame.minX
        )
        let contentBoundary = railActionMinX - 12

        for tool in ["rect", "pan", "fields", "auto"] {
            let control = app.buttons["editor.tool.\(tool)"]
            XCTAssertTrue(control.waitForExistence(timeout: 5), control.debugDescription)
            XCTAssertTrue(control.isHittable, "Editing tool is not reachable: \(tool)")
            XCTAssertTrue(window.frame.intersects(control.frame), "Editing tool is outside the app viewport: \(tool)")
            XCTAssertLessThanOrEqual(
                control.frame.maxX,
                contentBoundary,
                "Editing tools must stay clear of Duo's system rail: \(tool)"
            )
        }
        let toolViewport = app.scrollViews["editor.tools.scroll"]
        XCTAssertTrue(toolViewport.waitForExistence(timeout: 5), toolViewport.debugDescription)
        XCTAssertLessThanOrEqual(
            toolViewport.frame.maxX,
            contentBoundary,
            "The Duo's system rail must remain outside the editor tool viewport"
        )

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Duo editor adaptive action rail"
        attachment.lifetime = .keepAlways
        add(attachment)

        let exportAction = app.buttons["editor.export"]
        exportAction.tap()
        let closeExport = app.buttons["export.close"]
        XCTAssertTrue(closeExport.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(closeExport.isHittable, "The native export sheet should keep its close action reachable on Duo")
        XCTAssertTrue(window.frame.intersects(closeExport.frame), "The export sheet action must stay within the app viewport")
        let exportAttachment = XCTAttachment(screenshot: app.screenshot())
        exportAttachment.name = "Duo native export sheet"
        exportAttachment.lifetime = .keepAlways
        add(exportAttachment)
        closeExport.tap()
        XCTAssertTrue(closeExport.waitForNonExistence(timeout: 3))

        app.terminate()
    }

    @MainActor
    func testDuoClosedEditorKeepsContentInsideTheSafeArea() throws {
        let simulatorName = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? ""
        guard simulatorName.localizedCaseInsensitiveContains("duo") else {
            throw XCTSkip("This placement assertion applies to the Duo outer display")
        }

        let app = launch(scene: "editor")
        defer { app.terminate() }

        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertLessThan(window.frame.width, window.frame.height, "The Duo should be in its closed portrait pose")
        dismissUnsignedBuildPersistenceErrorIfPresent(in: app)

        let moreActions = app.buttons["editor.moreActions"]
        let navigationElements = [
            app.buttons["editor.close"],
            app.buttons["editor.export"],
            moreActions
        ]
        for element in navigationElements {
            XCTAssertTrue(element.waitForExistence(timeout: 5), element.debugDescription)
            XCTAssertTrue(element.isHittable, "Editor navigation is not reachable: \(element)")
            XCTAssertLessThanOrEqual(
                element.frame.maxX,
                window.frame.maxX,
                "Native navigation actions must stay inside the Duo window: \(element)"
            )
        }
        let railActionMinX = min(
            app.buttons["editor.close"].frame.minX,
            app.buttons["editor.export"].frame.minX
        )
        let contentBoundary = railActionMinX - 12

        let safeAreaElements = [
            app.images["editor.document.preview"],
            app.scrollViews["editor.tools.scroll"],
            app.buttons["editor.tool.rect"],
            moreActions,
            app.buttons["editor.maskStyle.scroll"],
            app.buttons["Restablecer zoom"]
        ]

        for element in safeAreaElements {
            XCTAssertTrue(element.waitForExistence(timeout: 5), element.debugDescription)
            XCTAssertTrue(element.isHittable, "Editor content is not reachable: \(element)")
            XCTAssertLessThanOrEqual(
                element.frame.maxX,
                contentBoundary,
                "Editor content must leave the Duo system rail clear: \(element)"
            )
            XCTAssertLessThanOrEqual(
                element.frame.maxY,
                window.frame.maxY - 8,
                "Editor content must stay above the system navigation area: \(element)"
            )
        }

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Duo closed editor content safe area"
        attachment.lifetime = .keepAlways
        add(attachment)

        moreActions.tap()
        let presetMenuItem = app.buttons["editor.menu.presets"]
        XCTAssertTrue(presetMenuItem.waitForExistence(timeout: 3), app.debugDescription)
        XCTAssertTrue(presetMenuItem.isHittable, "The navigation menu must remain reachable on the closed display")
        XCTAssertLessThanOrEqual(
            presetMenuItem.frame.maxX,
            contentBoundary,
            "The menu content must stay clear of Duo's reserved system rail"
        )
    }

    @MainActor
    func testEditorExportCanOpenAndDismissWithoutChangingDocument() throws {
        let app = launch(scene: "editor")
        let export = app.buttons["editor.export"]
        XCTAssertTrue(export.waitForExistence(timeout: 3))
        XCTAssertTrue(export.isHittable)
        export.tap()

        let pdfFormat = app.buttons["export.format.pdf"]
        let imageFormat = app.buttons["export.format.image"]
        let mediumQuality = app.buttons["export.quality.medium"]
        let verificationDetails = app.buttons["export.verification.details"]
        XCTAssertTrue(pdfFormat.waitForExistence(timeout: 5))
        scrollToElement(imageFormat, in: app, scrollViewIdentifier: "export.form.scroll")
        XCTAssertTrue(imageFormat.isHittable, "Image export format should be reachable in the export form")
        imageFormat.tap()
        XCTAssertTrue(imageFormat.isSelected)
        pdfFormat.tap()
        XCTAssertTrue(pdfFormat.isSelected)
        scrollToElement(mediumQuality, in: app, scrollViewIdentifier: "export.form.scroll")
        XCTAssertTrue(mediumQuality.isHittable)
        scrollToElement(verificationDetails, in: app, scrollViewIdentifier: "export.form.scroll")
        XCTAssertTrue(verificationDetails.isHittable, verificationDetails.debugDescription + "\n" + app.debugDescription)
        verificationDetails.tap()

        let closeExport = app.buttons["export.close"]
        XCTAssertTrue(closeExport.waitForExistence(timeout: 3))
        closeExport.tap()
        XCTAssertTrue(closeExport.waitForNonExistence(timeout: 3))

        let closeEditor = app.buttons["editor.close"]
        XCTAssertTrue(closeEditor.isHittable)
        closeEditor.tap()
        if !closeEditor.waitForNonExistence(timeout: 1) {
            let discardDialogTitle = app.staticTexts["¿Salir sin guardar?"]
            let discardChanges = app.buttons["Salir"]
            XCTAssertTrue(discardDialogTitle.waitForExistence(timeout: 3))
            XCTAssertTrue(discardChanges.waitForExistence(timeout: 3))
            discardChanges.tap()
            XCTAssertTrue(discardDialogTitle.waitForNonExistence(timeout: 3), "Discard confirmation remained over the library")
        }
        XCTAssertTrue(closeEditor.waitForNonExistence(timeout: 3))
        let homeTab = libraryTab(in: app)
        let homeTabHittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "isHittable == true"),
            object: homeTab
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [homeTabHittable], timeout: 5),
            .completed,
            "Editor closed without returning to an interactive library tab.\n\(app.debugDescription)"
        )
    }

    @MainActor
    func testCustomProtectionProfileExposesItsCompleteSafePolicy() throws {
        let app = launch(scene: "editor")
        let moreActions = app.buttons["editor.moreActions"]
        XCTAssertTrue(moreActions.waitForExistence(timeout: 5))
        moreActions.tap()

        let presetsMenuItem = app.buttons["editor.menu.presets"]
        XCTAssertTrue(presetsMenuItem.waitForExistence(timeout: 3), app.debugDescription)
        presetsMenuItem.tap()

        let customPreset = app.buttons["editor.preset.custom"]
        XCTAssertTrue(customPreset.waitForExistence(timeout: 5), app.debugDescription)
        customPreset.tap()

        let createProfile = app.buttons["editor.customProfile.create"]
        XCTAssertTrue(createProfile.waitForExistence(timeout: 5), app.debugDescription)
        createProfile.tap()

        let firstControls = [
            "editor.customProfile.name",
            "editor.customProfile.entity.documentNumber"
        ]
        for identifier in firstControls {
            let control = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            XCTAssertTrue(control.waitForExistence(timeout: 5), "Missing custom profile control \(identifier): \(app.debugDescription)")
        }

        let maskStyle = app.descendants(matching: .any)
            .matching(identifier: "editor.customProfile.maskStyle").firstMatch
        let profileForm = app.collectionViews["editor.customProfile.form"]
        XCTAssertTrue(profileForm.waitForExistence(timeout: 3), app.debugDescription)
        var attempts = 0
        while !maskStyle.exists && attempts < 8 {
            profileForm.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(maskStyle.exists, app.debugDescription)

        let watermark = app.descendants(matching: .any)
            .matching(identifier: "editor.customProfile.watermarkEnabled").firstMatch
        attempts = 0
        while !watermark.exists && attempts < 8 {
            profileForm.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(watermark.exists, app.debugDescription)

        let outputFormat = app.descendants(matching: .any)
            .matching(identifier: "editor.customProfile.outputFormat").firstMatch
        attempts = 0
        while !outputFormat.exists && attempts < 10 {
            profileForm.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(outputFormat.exists, "The profile should offer a safe output format preference")
    }

    @MainActor
    func testProtectionProfilesSupportCRUDAndPersistAcrossRelaunch() throws {
        let app = launch(scene: "editor")
        let suffix = String(UUID().uuidString.prefix(8))
        let initialName = "MaskID QA \(suffix)"
        let renamedName = "MaskID QA edited \(suffix)"
        let duplicateName = "\(renamedName) · copia"

        openCustomProtectionProfiles(in: app)
        app.buttons["editor.customProfile.create"].tap()
        let nameField = app.textFields["editor.customProfile.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), app.debugDescription)
        nameField.tap()
        let currentName = nameField.value as? String ?? ""
        if !currentName.isEmpty {
            nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentName.count))
        }
        nameField.typeText(initialName)
        let save = app.buttons["Guardar perfil"]
        XCTAssertTrue(save.waitForExistence(timeout: 5), app.debugDescription)
        save.tap()

        let initialProfile = app.buttons["editor.customProfile.use.\(initialName)"]
        XCTAssertTrue(initialProfile.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertEqual(initialProfile.value as? String, "Seleccionado")

        let profileActions = app.buttons.matching(
            NSPredicate(format: "label == %@", "Acciones del perfil")
        )
        XCTAssertGreaterThanOrEqual(profileActions.count, 2, app.debugDescription)
        profileActions.element(boundBy: profileActions.count - 1).tap()
        app.buttons["Editar"].tap()

        XCTAssertTrue(nameField.waitForExistence(timeout: 5), app.debugDescription)
        nameField.tap()
        let savedName = nameField.value as? String ?? ""
        if !savedName.isEmpty {
            nameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: savedName.count))
        }
        nameField.typeText(renamedName)
        XCTAssertTrue(save.waitForExistence(timeout: 5), app.debugDescription)
        save.tap()
        let renamedProfile = app.buttons["editor.customProfile.use.\(renamedName)"]
        XCTAssertTrue(renamedProfile.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertFalse(initialProfile.exists, "Renaming should replace the original profile entry")

        profileActions.element(boundBy: profileActions.count - 1).tap()
        app.buttons["Duplicar"].tap()
        let duplicateProfile = app.buttons["editor.customProfile.use.\(duplicateName)"]
        XCTAssertTrue(duplicateProfile.waitForExistence(timeout: 8), app.debugDescription)

        renamedProfile.tap()
        XCTAssertTrue(renamedProfile.waitForNonExistence(timeout: 5), "Selecting a profile should close the manager")
        app.terminate()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        openCustomProtectionProfiles(in: app)
        let restoredProfile = app.buttons["editor.customProfile.use.\(renamedName)"]
        let restoredDuplicate = app.buttons["editor.customProfile.use.\(duplicateName)"]
        XCTAssertTrue(restoredProfile.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertTrue(restoredDuplicate.waitForExistence(timeout: 8), app.debugDescription)
        XCTAssertEqual(restoredProfile.value as? String, "Seleccionado", "The selected profile should persist across relaunch")

        profileActions.element(boundBy: profileActions.count - 1).tap()
        app.buttons["Eliminar"].tap()
        app.buttons["Eliminar perfil"].tap()
        XCTAssertTrue(restoredDuplicate.waitForNonExistence(timeout: 8), "The duplicate should be deleted from encrypted storage")

        profileActions.element(boundBy: profileActions.count - 1).tap()
        app.buttons["Eliminar"].tap()
        app.buttons["Eliminar perfil"].tap()
        XCTAssertTrue(restoredProfile.waitForNonExistence(timeout: 8), "The renamed profile should be deleted from encrypted storage")
        XCTAssertTrue(app.buttons["editor.customProfile.use.Custom"].exists, "The privacy-first default profile must remain after deleting custom profiles")
    }

    @MainActor
    func testEditorInspectorTabsAreReachableAndSelectable() throws {
        let app = launch(scene: "editor")
        let compactInspector = app.buttons["editor.inspector.open"]
        if compactInspector.waitForExistence(timeout: 2) {
            XCTAssertTrue(compactInspector.isHittable)
            compactInspector.tap()
            XCTAssertTrue(app.buttons["editor.inspector.close"].waitForExistence(timeout: 5))
        }

        for tab in ["detections", "mask", "watermark", "export"] {
            let control = app.buttons["editor.inspector.tab.\(tab)"]
            XCTAssertTrue(control.waitForExistence(timeout: 5), "Missing editor inspector tab: \(tab)")
            XCTAssertTrue(control.isHittable, "Editor inspector tab is not reachable: \(tab)")
            control.tap()
            XCTAssertTrue(control.isSelected, "Editor inspector did not select the \(tab) panel")
        }

        let compactClose = app.buttons["editor.inspector.close"]
        if compactClose.exists {
            compactClose.tap()
            XCTAssertTrue(compactClose.waitForNonExistence(timeout: 3))
        }
    }

    @MainActor
    func testEmptyEditorDetectionsOpenManualOCRFlow() throws {
        let app = launch(scene: "editor-empty-detections")
        let compactInspector = app.buttons["editor.inspector.open"]
        if compactInspector.waitForExistence(timeout: 2) {
            XCTAssertTrue(compactInspector.isHittable)
            compactInspector.tap()
        }

        let analyzeText = app.buttons["editor.inspector.openOCR"]
        XCTAssertTrue(analyzeText.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(analyzeText.isHittable)
        analyzeText.tap()

        let closeOCR = app.buttons["editor.ocr.close"]
        XCTAssertTrue(closeOCR.waitForExistence(timeout: 5), "The empty inspector action should open the OCR review sheet.\n\(app.debugDescription)")
        XCTAssertTrue(closeOCR.isHittable)
        closeOCR.tap()
        XCTAssertTrue(closeOCR.waitForNonExistence(timeout: 3))
    }

    @MainActor
    func testFaceSuggestionsCanBeDismissedAndProtected() throws {
        let app = launch(scene: "editor-face-suggestions")
        let reviewSuggestions = app.buttons["editor.faceSuggestions.open"]
        XCTAssertTrue(reviewSuggestions.waitForExistence(timeout: 5), app.debugDescription)
        reviewSuggestions.tap()

        let dismiss = app.buttons["editor.inspector.dismissFaceSuggestion.1"]
        scrollToElement(dismiss, in: app, scrollViewIdentifier: "editor.inspector.scroll")
        XCTAssertTrue(dismiss.isHittable)
        XCTAssertGreaterThanOrEqual(dismiss.frame.width, 44)
        XCTAssertGreaterThanOrEqual(dismiss.frame.height, 44)
        dismiss.tap()
        XCTAssertTrue(dismiss.waitForNonExistence(timeout: 3), "Dismissed face suggestions should leave the review list")

        let protect = app.buttons["editor.inspector.faceSuggestion.0"]
        scrollToElement(protect, in: app, scrollViewIdentifier: "editor.inspector.scroll")
        XCTAssertTrue(protect.isHittable)
        XCTAssertGreaterThanOrEqual(protect.frame.height, 44)
        protect.tap()
        XCTAssertTrue(
            app.buttons.matching(identifier: "editor.inspector.faceSuggestion.0")
                .matching(NSPredicate(format: "label CONTAINS[cd] %@", "protegid"))
                .firstMatch.waitForExistence(timeout: 3),
            "Protecting a face suggestion should record an explicit, visible decision"
        )
    }

    @MainActor
    func testCompactEditorOpensInspectorAsNativeSheet() throws {
        let app = launch(scene: "editor")
        let openInspector = app.buttons["editor.inspector.open"]
        guard openInspector.waitForExistence(timeout: 3) else {
            throw XCTSkip("The inspector opens as a side panel in the regular workspace")
        }
        XCTAssertTrue(openInspector.isHittable)
        openInspector.tap()

        let detections = app.buttons["editor.inspector.tab.detections"]
        let close = app.buttons["editor.inspector.close"]
        XCTAssertTrue(detections.waitForExistence(timeout: 5), "The compact inspector sheet should expose its panels")
        XCTAssertTrue(detections.isHittable)
        XCTAssertTrue(close.isHittable)
        close.tap()
        XCTAssertTrue(close.waitForNonExistence(timeout: 3))
        XCTAssertTrue(openInspector.isHittable)
    }

    @MainActor
    func testEditorMaskStylesCanScrollPastVisibleOptions() throws {
        let app = launch(scene: "editor")
        let scrollStyles = app.buttons["editor.maskStyle.scroll"]
        XCTAssertTrue(scrollStyles.waitForExistence(timeout: 5))
        XCTAssertTrue(scrollStyles.isHittable)
        scrollStyles.tap()

        let lastStyle = app.buttons["editor.maskStyle.semi"]
        XCTAssertTrue(lastStyle.waitForExistence(timeout: 5))
        XCTAssertTrue(lastStyle.isHittable, "The scroll affordance should expose styles past the clipped edge")
    }

    @MainActor
    func testEditorInspectorAdaptsToWideOrientation() throws {
        let app = launch(scene: "editor")
        defer { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .landscapeLeft

        let window = app.windows.firstMatch
        let landscape = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in window.frame.width > window.frame.height },
            object: nil
        )
        let rotationResult = XCTWaiter.wait(for: [landscape], timeout: 8)
        guard rotationResult == .completed else {
            let orientation = XCUIDevice.shared.orientation
            let frame = window.frame
            if orientation == .landscapeLeft && frame.width <= frame.height {
                throw XCTSkip("MaskID QA Duo reports landscapeLeft but keeps its app viewport portrait (\(frame.width) × \(frame.height)); landscape layout is covered on iPhone 18 Pro.")
            }
            XCTFail("Landscape did not reach the app window. Orientation: \(orientation.rawValue), window: \(frame)")
            return
        }

        let compactInspector = app.buttons["editor.inspector.open"]
        if compactInspector.waitForExistence(timeout: 2) {
            XCTAssertTrue(compactInspector.isHittable)
            compactInspector.tap()
            XCTAssertTrue(app.buttons["editor.inspector.close"].waitForExistence(timeout: 5))
        }

        for tab in ["detections", "mask", "watermark", "export"] {
            let control = app.buttons["editor.inspector.tab.\(tab)"]
            XCTAssertTrue(control.waitForExistence(timeout: 5), "Missing wide editor panel: \(tab)")
            XCTAssertTrue(control.isHittable, "Wide editor panel is not reachable: \(tab)")
        }

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Editor wide inspector and canvas"
        attachment.lifetime = .keepAlways
        add(attachment)

        let compactClose = app.buttons["editor.inspector.close"]
        if compactClose.exists {
            compactClose.tap()
            XCTAssertTrue(compactClose.waitForNonExistence(timeout: 3))
        }
    }

    @MainActor
    func testASOOCRFixtureDoesNotSurfaceMissingImageError() throws {
        let app = launch(scene: "04-ai-ocr-detection")
        XCTAssertTrue(app.staticTexts["Campos detectados"].waitForExistence(timeout: 5))
        XCTAssertFalse(
            app.staticTexts["No hay imagen disponible"].waitForExistence(timeout: 1),
            "The deterministic ASO fixture should reuse its seeded OCR fields without showing a missing-image error"
        )
    }

    @MainActor
    func testAnalyticsConsentIsExplicitAndOffByDefault() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-aso-screenshots",
            "-show-analytics-consent",
            "-aso-language", "es",
            "-aso-scene", "home"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let allow = app.buttons["analytics.consent.allow"]
        let decline = app.buttons["analytics.consent.decline"]
        XCTAssertTrue(allow.waitForExistence(timeout: 5))
        XCTAssertTrue(decline.exists)
        decline.tap()

        XCTAssertTrue(allow.waitForNonExistence(timeout: 3))
        XCTAssertFalse(app.buttons["settings.privacy.analyticsConsent"].exists)
    }

    @MainActor
    func testAnalyticsConsentCanBeRevokedFromPrivacySettings() throws {
        let app = launch(scene: "settings")
        let privacy = app.buttons["settings.route.privacy"]
        scrollToElement(privacy, in: app)
        XCTAssertTrue(privacy.isHittable)
        privacy.tap()

        let consent = app.switches["settings.privacy.analyticsConsent"]
        XCTAssertTrue(consent.waitForExistence(timeout: 5))
        if consent.value as? String == "1" {
            consent.tap()
        }
        XCTAssertEqual(consent.value as? String, "0")

        consent.tap()
        XCTAssertEqual(consent.value as? String, "1")
        consent.tap()
        XCTAssertEqual(consent.value as? String, "0")
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
        let homeTab = libraryTab(in: app)
        XCTAssertTrue(homeTab.isHittable, "The Documents tab should be tappable after dismissing the paywall")
    }

    @MainActor
    func testPaywallFooterGroupsCTAAndLegalActions() throws {
        let app = launch(scene: "paywall")
        let purchase = app.buttons["paywall.purchase"]
        let legalIdentifiers = [
            "paywall.restore",
            "paywall.privacy",
            "paywall.terms",
            "paywall.subscriptionTerms"
        ]

        XCTAssertTrue(purchase.waitForExistence(timeout: 3))
        let legalActions = legalIdentifiers.map { app.buttons[$0] }
        for action in legalActions {
            XCTAssertTrue(action.waitForExistence(timeout: 3), "Missing paywall footer action: \(action)")
            XCTAssertGreaterThanOrEqual(
                action.frame.minY,
                purchase.frame.maxY,
                "Every restore/legal action must sit below the purchase CTA"
            )
        }

        let footerContentHeight = legalActions.map(\.frame.maxY).max()! - purchase.frame.minY
        XCTAssertLessThanOrEqual(footerContentHeight, 112, "The default paywall footer should remain compact")
    }

    @MainActor
    func testPaywallControlsRemainVisibleInIPadLandscape() throws {
        guard UIDevice.current.userInterfaceIdiom == .pad else {
            throw XCTSkip("This layout check targets iPad landscape")
        }

        let app = launch(scene: "paywall")
        defer { XCUIDevice.shared.orientation = .portrait }
        XCUIDevice.shared.orientation = .landscapeLeft

        let window = app.windows.firstMatch
        let landscapeExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in window.frame.width > window.frame.height },
            object: nil
        )
        XCTAssertEqual(
            XCTWaiter.wait(for: [landscapeExpectation], timeout: 5),
            .completed,
            "The iPad window should rotate to landscape"
        )

        for identifier in [
            "paywall.purchase",
            "paywall.restore",
            "paywall.privacy",
            "paywall.terms",
            "paywall.subscriptionTerms"
        ] {
            let control = app.buttons[identifier]
            XCTAssertTrue(control.waitForExistence(timeout: 5), "Missing paywall control: \(identifier)")
            XCTAssertTrue(window.frame.intersects(control.frame), "Control is outside the iPad window: \(identifier)")
            XCTAssertTrue(control.isHittable, "Control is not tappable in iPad landscape: \(identifier)")
        }
    }

    @MainActor
    func testPersistentChromeAtAX5WithReducedMotion() throws {
        let cases: [(scene: String, visible: [String], hittable: [String])] = [
            ("lock", ["lock.primaryUnlock"], ["lock.primaryUnlock"]),
            ("settings", ["settings.close"], ["settings.close"]),
            ("editor", ["editor.close", "editor.export"], ["editor.close", "editor.export"]),
            ("paywall", ["paywall.close", "paywall.purchase"], ["paywall.close"]),
            ("capture", ["capture.close"], ["capture.close"])
        ]

        for testCase in cases {
            let app = XCUIApplication()
            app.launchArguments = [
                "-ui-testing",
                "-aso-screenshots",
                "-aso-language", "es",
                "-aso-scene", testCase.scene,
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
                "-UIAccessibilityReduceMotionEnabled", "YES",
                "-UIAccessibilityReduceTransparencyEnabled", "YES",
                "-UIAccessibilityDarkerSystemColorsEnabled", "YES"
            ]
            app.launch()
            XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
            let window = app.windows.firstMatch
            XCTAssertTrue(window.waitForExistence(timeout: 5))

            for identifier in testCase.visible {
                let element = app.buttons[identifier]
                XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing \(identifier) in \(testCase.scene)")
                XCTAssertTrue(
                    window.frame.intersects(element.frame),
                    "\(identifier) is outside the visible window in \(testCase.scene): \(element.frame)"
                )
            }

            for identifier in testCase.hittable {
                XCTAssertTrue(app.buttons[identifier].isHittable, "\(identifier) is not hittable in \(testCase.scene)")
            }
            app.terminate()
        }
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
    private func launch(scene: String, orientation: UIDeviceOrientation = .portrait) -> XCUIApplication {
        XCUIDevice.shared.orientation = orientation
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
    private func openCustomProtectionProfiles(in app: XCUIApplication) {
        let moreActions = app.buttons["editor.moreActions"]
        XCTAssertTrue(moreActions.waitForExistence(timeout: 5), app.debugDescription)
        moreActions.tap()
        let presets = app.buttons["editor.menu.presets"]
        XCTAssertTrue(presets.waitForExistence(timeout: 3), app.debugDescription)
        presets.tap()
        let customPreset = app.buttons["editor.preset.custom"]
        XCTAssertTrue(customPreset.waitForExistence(timeout: 5), app.debugDescription)
        customPreset.tap()
        XCTAssertTrue(app.buttons["editor.customProfile.create"].waitForExistence(timeout: 5), app.debugDescription)
    }

    @MainActor
    private func dismissUnsignedBuildPersistenceErrorIfPresent(in app: XCUIApplication) {
        // CODE_SIGNING_ALLOWED=NO cannot access the app's Keychain entitlement;
        // dismiss its expected storage diagnostic before checking layout.
        let dismiss = app.buttons["editor.persistenceError.dismiss"]
        if dismiss.waitForExistence(timeout: 2) {
            XCTAssertTrue(dismiss.isHittable, "The simulator storage diagnostic should be dismissible")
            dismiss.tap()
        }
    }

    @MainActor
    private func scanTab(in app: XCUIApplication) -> XCUIElement {
        let identifierMatch = app.buttons["tab.capture"]
        if identifierMatch.exists { return identifierMatch }

        // The adaptive TabView exposes sidebar destinations as cells on
        // regular-width iPad layouts and as buttons in the compact tab bar.
        let sidebarIdentifierMatch = app.cells["tab.capture"]
        if sidebarIdentifierMatch.exists { return sidebarIdentifierMatch }

        let labelPredicate = NSPredicate(format: "label ==[c] %@", "Escanear documento")
        let buttonMatch = app.buttons.matching(labelPredicate).firstMatch
        if buttonMatch.exists { return buttonMatch }
        let sidebarLabelMatch = app.cells.matching(labelPredicate).firstMatch
        if sidebarLabelMatch.exists { return sidebarLabelMatch }

        return app.descendants(matching: .any)
            .matching(identifier: "tab.capture")
            .firstMatch
    }

    @MainActor
    private func libraryTab(in app: XCUIApplication) -> XCUIElement {
        navigationTab(in: app, index: 0)
    }

    @MainActor
    private func navigationTab(in app: XCUIApplication, index: Int) -> XCUIElement {
        let identifierMatch = app.buttons["tab.\(index)"]
        if identifierMatch.exists && identifierMatch.isHittable {
            return identifierMatch
        }

        // Regular-width TabView presents native sidebar destinations as cells
        // instead of compact tab-bar buttons.
        let sidebarIdentifierMatch = app.cells["tab.\(index)"]
        if sidebarIdentifierMatch.exists && sidebarIdentifierMatch.isHittable {
            return sidebarIdentifierMatch
        }

        let labels: [(String, String)] = switch index {
        case 0: [("Documentos", "Docs")]
        case 1: [("Estilos", "Styles")]
        case 2: [("Bóveda", "Vault")]
        case 3: [("Ajustes", "Settings")]
        default: []
        }
        guard !labels.isEmpty else { return identifierMatch }
        let predicates = labels.map {
            NSPredicate(format: "label ==[c] %@ OR label ==[c] %@", $0.0, $0.1)
        }
        let combined = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        let labelMatch = app.buttons.matching(combined).firstMatch
        if labelMatch.exists { return labelMatch }

        let sidebarLabelMatch = app.cells.matching(combined).firstMatch
        return sidebarLabelMatch.exists ? sidebarLabelMatch : identifierMatch
    }

    @MainActor
    private func scanTabCount(in app: XCUIApplication) -> Int {
        let predicate = NSPredicate(
            format: "identifier == %@ OR label ==[c] %@",
            "tab.capture",
            "Escanear documento"
        )
        return app.buttons.matching(predicate).count + app.cells.matching(predicate).count
    }

    @MainActor
    private func scrollToElement(
        _ element: XCUIElement,
        in app: XCUIApplication,
        scrollViewIdentifier: String? = nil
    ) {
        let scrollView = scrollViewIdentifier.map { app.scrollViews[$0] } ?? app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 3))
        let threshold = app.frame.maxY - 110 // Clear custom tab bar
        let topThreshold: CGFloat = 90 // Clear navigation bar & dynamic island
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

    @MainActor
    func testShortOnboardingDeliversHomeWithoutEarlyPermissionOrPaywall() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-aso-screenshots",
            "-aso-language", "es",
            "-aso-scene", "onboarding"
        ]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let welcome = app.buttons["onboarding.welcome.continue"]
        XCTAssertTrue(welcome.waitForExistence(timeout: 10), "Welcome CTA missing")
        welcome.tap()

        let birthDate = app.buttons["onboarding.demo.field.dob"]
        let address = app.buttons["onboarding.demo.field.address"]
        XCTAssertTrue(birthDate.waitForExistence(timeout: 5), "Interactive review demo missing")
        birthDate.tap()
        address.tap()

        let showResult = app.buttons["onboarding.demo.showResult"]
        XCTAssertTrue(showResult.isEnabled, "The sample should allow reviewing two selected fields")
        showResult.tap()
        let continueOnboarding = app.buttons["onboarding.demo.continue"]
        XCTAssertTrue(continueOnboarding.waitForExistence(timeout: 5), "Reviewed demo result missing")
        continueOnboarding.tap()

        let skipSecurity = app.buttons["onboarding.security.skip"]
        XCTAssertTrue(skipSecurity.waitForExistence(timeout: 5), "Optional security setup missing")
        skipSecurity.tap()

        let primaryAction = app.buttons["home.primaryAction"]
        XCTAssertTrue(primaryAction.waitForExistence(timeout: 8), "First useful home action should follow onboarding")
        XCTAssertFalse(app.buttons["onboarding.paywall.purchase"].exists, "The first session must not force a paywall")
        XCTAssertFalse(app.buttons["analytics.consent.allow"].exists, "Analytics consent must not interrupt the first session")
        XCTAssertFalse(app.alerts.firstMatch.exists, "Camera permission should wait until capture begins")
    }

}
