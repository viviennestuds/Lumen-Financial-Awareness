import XCTest

final class LumenFinanceUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.isHittable { return }
            app.swipeUp()
        }
    }

    @MainActor
    private func inspect(_ merchant: String, in app: XCUIApplication) {
        app.buttons["Activity"].tap()
        let search = app.textFields["Search merchant, category, notes"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText(merchant)
        let row = app.buttons.containing(.staticText, identifier: merchant).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()
        XCTAssertTrue(app.navigationBars["Transaction"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testManualReviewSaveRelaunchInspectEditStatusAndDelete() throws {
        // Unique test-owned record only; never resets or deletes another user's history.
        let merchant = "Ledger test \(UUID().uuidString.prefix(8))"
        let app = XCUIApplication()
        app.launch()
        if app.buttons["Get Started"].waitForExistence(timeout: 3) { app.buttons["Get Started"].tap() }
        let add = app.buttons["addActivity"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        add.tap()
        app.buttons.containing(.staticText, identifier: "Manual Entry").firstMatch.tap()
        let amount = app.textFields["transactionAmount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 10))
        amount.tap()
        amount.typeText("12.34")
        let name = app.textFields["transactionMerchant"]
        name.tap()
        name.typeText(merchant)
        app.buttons["Review transaction"].tap()
        let save = app.buttons["confirmTransaction"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[merchant].exists)
        save.tap()
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        app.terminate()
        app.launch()
        inspect(merchant, in: app)
        XCTAssertTrue(app.staticTexts["Pending"].exists)
        app.buttons["Confirm posted"].tap()
        XCTAssertTrue(app.staticTexts["Posted"].waitForExistence(timeout: 5))
        app.buttons["Edit"].tap()
        let editAmount = app.textFields["transactionAmount"]
        reveal(editAmount, in: app)
        editAmount.tap()
        let current = editAmount.value as? String ?? "12.34"
        editAmount.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + "23.45")
        app.buttons["Save changes"].tap()
        app.terminate()
        app.launch()
        inspect(merchant, in: app)
        XCTAssertTrue(app.staticTexts["Posted"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "23.45")).firstMatch.exists)
        let delete = app.buttons["Delete transaction"]
        reveal(delete, in: app)
        delete.tap()
        app.buttons["Delete"].tap()
        app.terminate()
        app.launch()
        app.buttons["Activity"].tap()
        let search = app.textFields["Search merchant, category, notes"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText(merchant)
        XCTAssertTrue(app.staticTexts["No transactions found"].waitForExistence(timeout: 10))
    }
}
