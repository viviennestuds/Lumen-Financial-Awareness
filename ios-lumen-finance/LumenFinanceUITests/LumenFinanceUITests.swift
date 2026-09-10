import XCTest

final class LumenFinanceUITests: XCTestCase {
    private var lastCheckpoint: String = "not launched"

    override func setUpWithError() throws { continueAfterFailure = false }

    override func record(_ issue: XCTIssue) {
        var annotated = issue
        annotated.compactDescription += " [last completed: \(lastCheckpoint)]"
        if let location = issue.sourceCodeContext.location {
            annotated.compactDescription += " [source: \(location.fileURL.lastPathComponent):\(location.lineNumber)]"
        }
        if let detail = issue.detailedDescription {
            annotated.compactDescription += " [detail: \(detail)]"
        }
        let symbols = issue.sourceCodeContext.callStack.compactMap { frame -> String? in
            guard let info = try? frame.symbolInfo() else { return nil }
            return "\(info.imageName): \(info.symbolName)"
        }
        if !symbols.isEmpty {
            annotated.compactDescription += " [stack: \(symbols.joined(separator: " | "))]"
        }
        super.record(annotated)
    }

    private func checkpoint(_ name: String) {
        lastCheckpoint = name
        print("LUMEN_UI_CHECKPOINT \(name)")
    }

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
        checkpoint("1 application launched")
        if app.buttons["Get Started"].waitForExistence(timeout: 3) { app.buttons["Get Started"].tap() }
        let add = app.buttons["addActivity"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        checkpoint("2 initial ledger available")
        add.tap()
        app.buttons.containing(.staticText, identifier: "Manual Entry").firstMatch.tap()
        let amount = app.textFields["transactionAmount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 10))
        checkpoint("3 Manual Entry opened")
        amount.tap()
        checkpoint("3a amount focused")
        amount.typeText("12.34")
        checkpoint("3b amount entered")
        let name = app.textFields["transactionMerchant"]
        name.tap()
        checkpoint("3c merchant focused")
        name.typeText(merchant)
        checkpoint("4 transaction fields entered")
        app.buttons["Review transaction"].tap()
        let save = app.buttons["confirmTransaction"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts[merchant].exists)
        checkpoint("5 Review reached")
        save.tap()
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        checkpoint("6 Confirm returned to ledger; creation not yet independently observed")
        app.terminate()
        checkpoint("8 first termination completed")
        app.launch()
        checkpoint("9 first relaunch completed")
        inspect(merchant, in: app)
        checkpoint("10 Transaction inspected after relaunch")
        XCTAssertTrue(app.staticTexts["Pending"].exists)
        app.buttons["Confirm posted"].tap()
        XCTAssertTrue(app.staticTexts["Posted"].waitForExistence(timeout: 5))
        checkpoint("11 status transition observed")
        app.buttons["Edit"].tap()
        let editAmount = app.textFields["transactionAmount"]
        reveal(editAmount, in: app)
        editAmount.tap()
        let current = editAmount.value as? String ?? "12.34"
        editAmount.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count) + "23.45")
        app.buttons["Save changes"].tap()
        checkpoint("13 edit save tapped; persistence not yet observed")
        app.terminate()
        app.launch()
        inspect(merchant, in: app)
        XCTAssertTrue(app.staticTexts["Posted"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "23.45")).firstMatch.exists)
        checkpoint("15 edited value observed after relaunch")
        let delete = app.buttons["Delete transaction"]
        reveal(delete, in: app)
        delete.tap()
        app.buttons["Delete"].tap()
        checkpoint("16 delete confirmed; absence not yet observed")
        app.terminate()
        app.launch()
        checkpoint("17 final relaunch completed")
        app.buttons["Activity"].tap()
        let search = app.textFields["Search merchant, category, notes"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText(merchant)
        XCTAssertTrue(app.staticTexts["No transactions found"].waitForExistence(timeout: 10))
        checkpoint("18 test-owned Transaction confirmed absent")
    }
}
