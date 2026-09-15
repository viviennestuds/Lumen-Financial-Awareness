import XCTest

final class LumenExistingStoreCompatibilityUITests: XCTestCase {
    private let harnessEnvironmentKey = "LUMEN_EXISTING_STORE_COMPATIBILITY"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func requireCompatibilityHarness() throws {
        guard ProcessInfo.processInfo.environment[harnessEnvironmentKey] == "1" else {
            throw XCTSkip("Historical-store compatibility harness is not active.")
        }
        print("LUMEN_COMPATIBILITY_TEST_ACTIVE")
    }

    @MainActor
    private func reachMainShell(in app: XCUIApplication) {
        if app.buttons["Get Started"].waitForExistence(timeout: 3) {
            app.buttons["Get Started"].tap()
        }

        XCTAssertFalse(
            app.staticTexts["Your ledger couldn’t open"].exists,
            "Candidate must open the inherited persistent ledger."
        )
        XCTAssertTrue(
            app.buttons["Activity"].waitForExistence(timeout: 10),
            "Main shell must be reachable."
        )
    }

    @MainActor
    private func openActivity(in app: XCUIApplication) {
        if app.navigationBars["Activity"].exists { return }
        let activity = app.buttons["Activity"]
        XCTAssertTrue(activity.waitForExistence(timeout: 10))
        activity.tap()
        XCTAssertTrue(app.navigationBars["Activity"].waitForExistence(timeout: 10))
    }

    @MainActor
    private func transactionRow(named merchant: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.containing(.staticText, identifier: merchant).firstMatch
    }

    @MainActor
    private func revealTransactionRow(named merchant: String, in app: XCUIApplication) -> XCUIElement {
        let row = transactionRow(named: merchant, in: app)

        for _ in 0..<10 {
            if row.exists && row.isHittable { return row }
            app.swipeUp()
        }
        for _ in 0..<20 {
            if row.exists && row.isHittable { return row }
            app.swipeDown()
        }

        return row
    }

    @MainActor
    private func assertTransactionExists(_ merchant: String, in app: XCUIApplication) {
        let row = revealTransactionRow(named: merchant, in: app)
        XCTAssertTrue(row.exists, "Historical transaction must exist: \(merchant)")
    }

    @MainActor
    private func openTransaction(_ merchant: String, in app: XCUIApplication) {
        openActivity(in: app)
        let row = revealTransactionRow(named: merchant, in: app)
        XCTAssertTrue(row.exists, "Historical transaction must exist: \(merchant)")
        XCTAssertTrue(row.isHittable, "Historical transaction row must be reachable: \(merchant)")
        row.tap()
        XCTAssertTrue(app.navigationBars["Transaction"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[merchant].waitForExistence(timeout: 10))
    }

    @MainActor
    private func assertDetailText(_ value: String, in app: XCUIApplication) {
        let text = app.staticTexts[value]
        if !text.exists {
            for _ in 0..<10 {
                app.swipeUp()
                if text.exists { break }
            }
        }
        XCTAssertTrue(text.exists, "Expected inherited detail value: \(value)")
    }

    @MainActor
    private func returnToActivity(in app: XCUIApplication) {
        let nav = app.navigationBars["Transaction"]
        XCTAssertTrue(nav.exists)
        let back = nav.buttons.firstMatch
        XCTAssertTrue(back.exists)
        back.tap()
        XCTAssertTrue(app.navigationBars["Activity"].waitForExistence(timeout: 10))
    }

    @MainActor
    private func revealConfirmPosted(in app: XCUIApplication) -> XCUIElement {
        let button = app.buttons["Confirm posted"]
        for _ in 0..<12 {
            if button.exists && button.isHittable { return button }
            app.swipeDown()
        }
        return button
    }

    @MainActor
    func testHarnessDataContinuityPreflight() throws {
        try requireCompatibilityHarness()
        print("LUMEN_COMPATIBILITY_PREFLIGHT_ACTIVE")

        let app = XCUIApplication()
        app.launch()

        let onboarding = app.buttons["Get Started"].waitForExistence(timeout: 3)
        let mainShell = onboarding || app.buttons["Activity"].waitForExistence(timeout: 10)
        XCTAssertTrue(mainShell, "Candidate must launch far enough for harness characterization.")

        print("LUMEN_COMPATIBILITY_PREFLIGHT_PASS")
    }

    @MainActor
    func testHistoricalStoreCompatibility() throws {
        try requireCompatibilityHarness()

        let app = XCUIApplication()
        app.launch()
        reachMainShell(in: app)
        print("LUMEN_COMPATIBILITY_LEDGER_OPEN_PASS")

        openActivity(in: app)
        assertTransactionExists("OpenAI", in: app)
        assertTransactionExists("Paycheck Direct Deposit", in: app)
        assertTransactionExists("HSA Pharmacy Purchase", in: app)
        assertTransactionExists("Dollar Tree", in: app)

        openTransaction("OpenAI", in: app)
        assertDetailText("Posted", in: app)
        assertDetailText("Expense", in: app)
        assertDetailText("Subscriptions", in: app)
        assertDetailText("Credit Card", in: app)
        assertDetailText("#recurring", in: app)
        assertDetailText("ChatGPT Plus", in: app)
        assertDetailText("Manual entry", in: app)
        assertDetailText("Not parsed", in: app)
        returnToActivity(in: app)
        print("LUMEN_COMPATIBILITY_SENTINEL_OPENAI_PASS")

        openTransaction("Paycheck Direct Deposit", in: app)
        assertDetailText("Posted", in: app)
        assertDetailText("Income", in: app)
        assertDetailText("Paycheck", in: app)
        assertDetailText("Bank Transfer", in: app)
        assertDetailText("#recurring", in: app)
        returnToActivity(in: app)
        print("LUMEN_COMPATIBILITY_SENTINEL_PAYCHECK_PASS")

        openTransaction("HSA Pharmacy Purchase", in: app)
        assertDetailText("Posted", in: app)
        assertDetailText("Expense", in: app)
        assertDetailText("Medical / HSA", in: app)
        assertDetailText("HSA", in: app)
        assertDetailText("#reimbursable", in: app)
        assertDetailText("Receipt photo", in: app)
        assertDetailText("Parsed", in: app)
        returnToActivity(in: app)
        print("LUMEN_COMPATIBILITY_SENTINEL_HSA_PASS")

        openTransaction("Dollar Tree", in: app)
        assertDetailText("Pending", in: app)
        assertDetailText("Expense", in: app)
        assertDetailText("Household", in: app)
        assertDetailText("Debit Card", in: app)
        assertDetailText("#essential", in: app)
        assertDetailText("Receipt photo", in: app)
        print("LUMEN_COMPATIBILITY_SENTINEL_PENDING_PASS")
        print("LUMEN_COMPATIBILITY_PHASE_A_PASS")

        let confirmPosted = revealConfirmPosted(in: app)
        XCTAssertTrue(confirmPosted.exists && confirmPosted.isHittable)
        confirmPosted.tap()
        XCTAssertTrue(app.staticTexts["Posted"].waitForExistence(timeout: 5))
        print("LUMEN_COMPATIBILITY_MUTATION_PASS")

        app.terminate()
        app.launch()
        reachMainShell(in: app)
        openTransaction("Dollar Tree", in: app)
        assertDetailText("Posted", in: app)
        returnToActivity(in: app)

        assertTransactionExists("OpenAI", in: app)
        assertTransactionExists("Paycheck Direct Deposit", in: app)
        assertTransactionExists("HSA Pharmacy Purchase", in: app)
        print("LUMEN_COMPATIBILITY_RELAUNCH_PASS")
    }
}
