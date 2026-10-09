//
//  BrewUITestsLaunchTests.swift
//  BrewUITests
//
//  Created by Oscar Artemio Brito Ortiz on 12/09/26.
//

import XCTest

@MainActor
final class BrewUITestsLaunchTests: XCTestCase {
    func testFreshLibraryShowsAnActionableEmptyState() {
        let app = XCUIApplication()
        app.launchEnvironment["BREW_UI_TEST_STORE"] = UUID().uuidString
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Nothing to brew yet"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Library"].tap()
        XCTAssertTrue(app.buttons["Add your first coffee"].exists)
        app.buttons["Add your first coffee"].tap()
        XCTAssertTrue(app.textFields["coffee.name"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["coffee.save"].isEnabled)
    }
}
