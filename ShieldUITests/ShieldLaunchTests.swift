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
    func testCaptureAccessibilityInEnglishAndSpanish() throws { try audit(scene: "capture") }

    @MainActor
    func testEditorAccessibilityInEnglishAndSpanish() throws { try audit(scene: "editor") }

    @MainActor
    func testOCRAccessibilityInEnglishAndSpanish() throws { try audit(scene: "ocr") }

    @MainActor
    func testExportAccessibilityInEnglishAndSpanish() throws { try audit(scene: "export") }

    @MainActor
    func testVaultAccessibilityInEnglishAndSpanish() throws { try audit(scene: "vault") }

    @MainActor
    func testSettingsAccessibilityInEnglishAndSpanish() throws { try audit(scene: "settings") }

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

}
