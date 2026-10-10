//
//  BrewUITests.swift
//  BrewUITests
//
//  Created by Oscar Artemio Brito Ortiz on 12/09/26.
//

import XCTest

@MainActor
final class BrewUITests: XCTestCase {
    private var app: XCUIApplication!
    private let coffeeName = "UI Test Coffee"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["BREW_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    func testCreateCoffeeGuidedBrewNotesAndRepeat() throws {
        createCoffee()
        prepareRecipe()
        XCTAssertEqual(app.staticTexts["guide.currentStep"].label, "Bloom")
        XCTAssertEqual(app.staticTexts["guide.nextStep"].label, "Next: First pour at 0:30")
        app.buttons["timer.start"].tap()
        app.buttons["timer.pause"].tap()
        XCTAssertTrue(app.buttons["timer.resume"].exists)
        app.buttons["timer.resume"].tap()
        app.buttons["timer.finish"].tap()
        XCTAssertTrue(app.buttons["evaluation.skip"].waitForExistence(timeout: 5))
        enterNotes("Peach and chocolate")
        app.buttons["evaluation.save"].tap()
        XCTAssertTrue(app.buttons["recommendation.done"].waitForExistence(timeout: 5))
        app.buttons["recommendation.done"].tap()
        openLatestBrew()
        let notes = app.staticTexts["brew.tasteNotes"]
        reveal(notes)
        XCTAssertEqual(notes.label, "Peach and chocolate")
        let repeatButton = app.buttons["brew.repeat"]
        reveal(repeatButton)
        repeatButton.tap()
        XCTAssertTrue(app.buttons["setup.continue"].waitForExistence(timeout: 5))
        app.buttons["setup.continue"].tap()
        app.buttons["timer.start"].tap()
        app.buttons["timer.finish"].tap()
        XCTAssertTrue(app.buttons["evaluation.skip"].waitForExistence(timeout: 5))
        app.buttons["evaluation.skip"].tap()
        XCTAssertTrue(app.buttons["brew.repeat"].waitForExistence(timeout: 5))
    }

    func testSkipThenEvaluateAfterRelaunch() throws {
        createCoffee()
        prepareRecipe()
        app.buttons["timer.start"].tap()
        app.buttons["timer.finish"].tap()
        app.buttons["evaluation.skip"].tap()
        app.terminate()
        app.launch()
        openLatestBrew()
        let evaluate = app.buttons["brew.evaluate"]
        reveal(evaluate)
        XCTAssertTrue(evaluate.exists)
        evaluate.tap()
        enterNotes("Evaluated later")
        app.buttons["evaluation.save"].tap()
        let notes = app.staticTexts["brew.tasteNotes"]
        XCTAssertTrue(notes.waitForExistence(timeout: 5))
        reveal(notes)
        XCTAssertEqual(notes.label, "Evaluated later")
        app.terminate()
        app.launch()
        openLatestBrew()
        let persisted = app.staticTexts["brew.tasteNotes"]
        reveal(persisted)
        XCTAssertEqual(persisted.label, "Evaluated later")
    }

    func testPendingBrewRemainsReachableWhenLastCoffeeIsArchived() throws {
        createCoffee()
        prepareRecipe()
        app.buttons["timer.start"].tap()
        app.tabBars.buttons["Library"].tap()
        element("coffee.open.\(coffeeName)").tap()
        app.buttons["More"].tap()
        app.buttons["coffee.archive"].tap()
        app.sheets.buttons["coffee.confirmArchive"].firstMatch.tap()
        app.tabBars.buttons["Brew"].tap()
        app.terminate()
        app.launch()
        let continueButton = app.buttons["pending.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.tap()
        XCTAssertTrue(app.buttons["timer.finish"].waitForExistence(timeout: 5))
        app.buttons["timer.finish"].tap()
        app.buttons["evaluation.skip"].tap()
        XCTAssertTrue(app.staticTexts["Nothing to brew yet"].waitForExistence(timeout: 5))
    }

    func testDraftRecoveryAndDiscard() throws {
        createCoffee()
        prepareRecipe()
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["pending.continue"].waitForExistence(timeout: 5))
        app.buttons["pending.discard"].tap()
        app.sheets.buttons["pending.confirmDiscard"].firstMatch.tap()
        let discarded = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: app.buttons["pending.continue"])
        XCTAssertEqual(XCTWaiter.wait(for: [discarded], timeout: 5), .completed)
        app.terminate()
        app.launch()
        XCTAssertFalse(app.buttons["pending.continue"].exists)
    }

    private func createCoffee() {
        app.tabBars.buttons["Library"].tap()
        app.buttons["library.add"].tap()
        XCTAssertTrue(app.textFields["coffee.name"].waitForExistence(timeout: 5))
        app.textFields["coffee.name"].tap()
        app.textFields["coffee.name"].typeText(coffeeName)
        app.textFields["coffee.origin"].tap()
        app.textFields["coffee.origin"].typeText("Mexico")
        app.buttons["coffee.roast"].tap()
        app.buttons["Medium"].tap()
        app.buttons["coffee.save"].tap()
        XCTAssertTrue(element("coffee.open.\(coffeeName)").waitForExistence(timeout: 5))
    }

    private func prepareRecipe() {
        app.tabBars.buttons["Brew"].tap()
        app.buttons.containing(.staticText, identifier: "V60").firstMatch.tap()
        element("brew.choose.\(coffeeName)").tap()
        app.buttons["setup.recipe"].tap()
        app.buttons["V60 starter"].tap()
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "isEnabled == true"),
                                              object: app.buttons["setup.continue"])
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        app.buttons["setup.continue"].tap()
        XCTAssertTrue(app.buttons["timer.start"].waitForExistence(timeout: 5))
    }

    private func openLatestBrew() {
        app.tabBars.buttons["Library"].tap()
        element("coffee.open.\(coffeeName)").tap()
        let history = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history.brew."))
        XCTAssertTrue(history.firstMatch.waitForExistence(timeout: 5))
        reveal(history.firstMatch)
        history.firstMatch.tap()
    }

    private func enterNotes(_ text: String) {
        let field = app.textFields["evaluation.notes"]
        reveal(field)
        field.tap()
        field.typeText(text)
    }

    private func element(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func reveal(_ element: XCUIElement) {
        for _ in 0..<8 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists)
    }
}
