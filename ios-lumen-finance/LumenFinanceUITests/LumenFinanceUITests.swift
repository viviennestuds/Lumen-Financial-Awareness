import XCTest

final class LumenFinanceUITests: XCTestCase {
    private var lastCheckpoint: String = "not launched"
    private var diagnosticStage: String = "not started"
    private var geometryObservations: [String] = []
    private var stateObservations: [String] = []
    private var characterizationMerchant: String?
    private var invalidFrameIssueCount: Int = 0

    override func setUpWithError() throws { continueAfterFailure = false }

    override func record(_ issue: XCTIssue) {
        if issue.compactDescription.contains("Invalid frame dimension (negative or non-finite)") {
            invalidFrameIssueCount += 1
        }
        var annotated = issue
        annotated.compactDescription += " [test: \(name)]"
        if !stateObservations.isEmpty {
            annotated.compactDescription += " [state: \(stateObservations.joined(separator: " | "))]"
        }
        if let characterizationMerchant {
            annotated.compactDescription += " [test-owned merchant: \(characterizationMerchant)]"
        }
        annotated.compactDescription += " [last completed: \(lastCheckpoint)]"
        annotated.compactDescription += " [diagnostic stage: \(diagnosticStage)]"
        if !geometryObservations.isEmpty {
            annotated.compactDescription += " [geometry: \(geometryObservations.joined(separator: " | "))]"
        }
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

    // No UI queries: persist only already-observed test telemetry in the test result.
    override func tearDownWithError() throws {
        if !stateObservations.isEmpty {
            let summary = "test=\(name); \(stateObservations.joined(separator: "; ")); merchant=\(characterizationMerchant ?? "none"); invalidFrameIssues=\(invalidFrameIssueCount); furthest=\(lastCheckpoint); stage=\(diagnosticStage); geometry=\(geometryObservations.joined(separator: " | "))"
            print("LUMEN_UI_CHARACTERIZATION \(summary)")
            let attachment = XCTAttachment(string: summary)
            attachment.name = "Lumen Run 6.1 characterization"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        try super.tearDownWithError()
    }

    private func observeState(_ key: String, _ value: String) {
        let observation = "\(key)=\(value)"
        stateObservations.append(observation)
        print("LUMEN_UI_STATE \(observation)")
    }

    private func checkpoint(_ name: String) {
        lastCheckpoint = name
        diagnosticStage = "after \(name)"
        print("LUMEN_UI_CHECKPOINT \(name)")
    }

    @MainActor
    private func captureGeometry(_ name: String, of element: XCUIElement) {
        diagnosticStage = "query \(name).exists"
        let exists = element.exists
        guard exists else {
            geometryObservations.append("\(name): exists=false")
            return
        }
        diagnosticStage = "query \(name).frame"
        let frame = element.frame
        let finite = [frame.origin.x, frame.origin.y, frame.width, frame.height].allSatisfy(\.isFinite)
        diagnosticStage = "query \(name).isHittable"
        let hittable = element.isHittable
        let result = "\(name): exists=\(exists), hittable=\(hittable), x=\(frame.origin.x), y=\(frame.origin.y), width=\(frame.width), height=\(frame.height), finite=\(finite), positive=\(frame.width > 0 && frame.height > 0), null=\(frame.isNull), empty=\(frame.isEmpty)"
        geometryObservations.append(result)
        print("LUMEN_UI_GEOMETRY \(result)")
        diagnosticStage = "\(name) geometry captured"
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
        diagnosticStage = "inspect: waiting for Activity; Get Started exists=\(app.buttons["Get Started"].exists)"
        XCTAssertTrue(app.buttons["Activity"].waitForExistence(timeout: 10),
                      "Activity must become available after launch without repeating onboarding")
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
    private func openManualEntryForProbe() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        if app.buttons["Get Started"].waitForExistence(timeout: 3) { app.buttons["Get Started"].tap() }
        let add = app.buttons["addActivity"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        add.tap()
        app.buttons.containing(.staticText, identifier: "Manual Entry").firstMatch.tap()
        XCTAssertTrue(app.textFields["transactionAmount"].waitForExistence(timeout: 10))
        checkpoint("probe Manual Entry opened")
        return app
    }

    @MainActor
    private func probeTextFocus(_ field: XCUIElement, name: String, text: String,
                                in app: XCUIApplication, coordinate: Bool = false) {
        XCTAssertTrue(field.exists)
        captureGeometry(name, of: field)
        XCTAssertTrue(field.isHittable)
        let frame = field.frame
        XCTAssertTrue([frame.origin.x, frame.origin.y, frame.width, frame.height].allSatisfy(\.isFinite))
        XCTAssertGreaterThan(frame.width, 0)
        XCTAssertGreaterThan(frame.height, 0)
        diagnosticStage = "\(name) pre-tap keyboard query"
        let keyboardBefore = app.keyboards.firstMatch.exists
        checkpoint("\(name) pre-tap keyboard=\(keyboardBefore)")
        diagnosticStage = "\(name) \(coordinate ? "coordinate" : "semantic") tap requested"
        if coordinate {
            field.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        } else {
            field.tap()
        }
        checkpoint("\(name) tap returned")
        diagnosticStage = "\(name) waiting for keyboard"
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        checkpoint("\(name) keyboard observed")
        diagnosticStage = "\(name) typing into focused field"
        field.typeText(text)
        checkpoint("\(name) typeText returned")
        // A vertical field loses its placeholder-based identity after text entry.
        let enteredField = name == "notes"
            ? app.descendants(matching: .any).matching(NSPredicate(format: "value == %@", text)).firstMatch
            : field
        XCTAssertEqual(enteredField.value as? String, text)
        checkpoint("\(name) local draft text observed; nothing saved")
    }

    @MainActor
    func testProbeAmountSemanticTap() {
        let app = openManualEntryForProbe()
        probeTextFocus(app.textFields["transactionAmount"], name: "amount", text: "12.34", in: app)
    }

    @MainActor
    func testProbeMerchantSemanticTap() {
        let app = openManualEntryForProbe()
        probeTextFocus(app.textFields["transactionMerchant"], name: "merchant", text: "Focus probe", in: app)
    }

    @MainActor
    func testProbeNotesSemanticTap() {
        let app = openManualEntryForProbe()
        let placeholder = "Add a gentle note for context…"
        let field = app.textFields[placeholder].exists ? app.textFields[placeholder] : app.textViews[placeholder]
        XCTAssertTrue(field.exists)
        diagnosticStage = "reveal notes without focus"
        reveal(field, in: app)
        checkpoint("notes reveal completed")
        probeTextFocus(field, name: "notes", text: "Focus probe", in: app)
    }

    @MainActor
    func testProbeNonTextControlTap() {
        let app = openManualEntryForProbe()
        let control = app.buttons["Income"]
        captureGeometry("income", of: control)
        XCTAssertTrue(control.isHittable)
        diagnosticStage = "income semantic tap requested"
        control.tap()
        checkpoint("income tap returned")
        XCTAssertTrue(app.textFields["transactionAmount"].exists)
        XCTAssertFalse(app.keyboards.firstMatch.exists)
        checkpoint("non-text interaction completed without keyboard; nothing saved")
    }

    @MainActor
    func testProbeAmountCoordinateTap() {
        let app = openManualEntryForProbe()
        probeTextFocus(app.textFields["transactionAmount"], name: "amount", text: "12.34", in: app, coordinate: true)
    }

    @MainActor
    func testB2IsolatedOnboardingRelaunch() {
        let app = XCUIApplication()
        app.launch()
        checkpoint("B2 initial launch returned")
        let onboardingWasPresented = app.buttons["Get Started"].waitForExistence(timeout: 3)
        observeState("Get Started initially observed", onboardingWasPresented ? "YES" : "NO")
        observeState("B2 evidence level", onboardingWasPresented ? "FULL" : "PARTIAL")
        if onboardingWasPresented {
            app.buttons["Get Started"].tap()
            checkpoint("B2 Get Started tap returned")
        }
        let mainShellBefore = app.buttons["Activity"].waitForExistence(timeout: 10)
        observeState("main shell before terminate", mainShellBefore ? "YES" : "NO")
        XCTAssertTrue(mainShellBefore, "B2 Activity must be available before termination")
        checkpoint("B2 main shell available before terminate")
        app.terminate()
        checkpoint("B2 termination returned")
        app.launch()
        checkpoint("B2 relaunch returned")
        let mainShellAfter = app.buttons["Activity"].waitForExistence(timeout: 10)
        let onboardingAfter = app.buttons["Get Started"].exists
        observeState("main shell after relaunch", mainShellAfter ? "YES" : "NO")
        observeState("Get Started after relaunch", onboardingAfter ? "YES" : "NO")
        XCTAssertTrue(mainShellAfter, "B2 Activity must survive termination/relaunch without repeating onboarding")
        XCTAssertFalse(onboardingAfter, "B2 Get Started must remain absent after relaunch")
        checkpoint("B2 isolated relaunch contract completed")
    }

    // Run 6 B1-A: literal canonical prefix through Review; deliberately no Done, Confirm or relaunch.
    @MainActor
    func testB1ACanonicalPrefixReachesReview() throws {
        // Unique test-owned record only; never resets or deletes another user's history.
        let merchant = "Ledger test \(UUID().uuidString.prefix(8))"
        characterizationMerchant = merchant
        let app = XCUIApplication()
        app.launch()
        checkpoint("1 application launched")
        let onboardingWasPresented = app.buttons["Get Started"].waitForExistence(timeout: 3)
        observeState("Get Started initially observed", onboardingWasPresented ? "YES" : "NO")
        if onboardingWasPresented {
            app.buttons["Get Started"].tap()
            observeState("onboarding completed this invocation", "YES")
        } else {
            observeState("onboarding completed this invocation", "NO")
        }
        let add = app.buttons["addActivity"]
        let mainShellAvailable = add.waitForExistence(timeout: 10)
        observeState("main shell became available", mainShellAvailable ? "YES" : "NO")
        XCTAssertTrue(mainShellAvailable)
        checkpoint("2 initial ledger available")
        add.tap()
        app.buttons.containing(.staticText, identifier: "Manual Entry").firstMatch.tap()
        let amount = app.textFields["transactionAmount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 10))
        checkpoint("3 Manual Entry opened")
        captureGeometry("amount", of: amount)
        captureGeometry("merchant", of: app.textFields["transactionMerchant"])
        captureGeometry("income", of: app.buttons["Income"])
        diagnosticStage = "amount semantic tap requested"
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
    }

    @MainActor
    func testManualReviewSaveRelaunchInspectEditStatusAndDelete() throws {
        // Unique test-owned record only; never resets or deletes another user's history.
        let merchant = "Ledger test \(UUID().uuidString.prefix(8))"
        characterizationMerchant = merchant
        let app = XCUIApplication()
        app.launch()
        checkpoint("1 application launched")
        let onboardingWasPresented = app.buttons["Get Started"].waitForExistence(timeout: 3)
        observeState("Get Started initially observed", onboardingWasPresented ? "YES" : "NO")
        if onboardingWasPresented {
            app.buttons["Get Started"].tap()
            observeState("onboarding completed this invocation", "YES")
        } else {
            observeState("onboarding completed this invocation", "NO")
        }
        let add = app.buttons["addActivity"]
        let mainShellAvailable = add.waitForExistence(timeout: 10)
        observeState("main shell became available", mainShellAvailable ? "YES" : "NO")
        XCTAssertTrue(mainShellAvailable)
        checkpoint("2 initial ledger available")
        add.tap()
        app.buttons.containing(.staticText, identifier: "Manual Entry").firstMatch.tap()
        let amount = app.textFields["transactionAmount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 10))
        checkpoint("3 Manual Entry opened")
        captureGeometry("amount", of: amount)
        captureGeometry("merchant", of: app.textFields["transactionMerchant"])
        captureGeometry("income", of: app.buttons["Income"])
        diagnosticStage = "amount semantic tap requested"
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
