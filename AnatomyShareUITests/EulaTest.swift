//
//  AnatomyShareUITests.swift
//  AnatomyShareUITests
//
//  Created by Dave on 6/20/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import XCTest

class AnatomyShareUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        // XCUIApplication().launch()
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        app.terminate()
    }
    
    func testEULA() {
        app.launch()
        
        // Check that alert is presented to user informing them they need to accept the EULA
        //
        let alert = app.alerts["User End Agreement Not Accepted"]
        alert.buttons["Show Terms"].tap()
       
        // EULA should be displayed after user presses show terms
        //
        XCTAssertTrue(app.isDisplayingEULA)
        app/*@START_MENU_TOKEN@*/.buttons["Accept"]/*[[".otherElements[\"EULA\"].buttons[\"Accept\"]",".buttons[\"Accept\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        // EULA should not longer be displayed
        //
        XCTAssertFalse(app.isDisplayingEULA)
    }
}

extension XCUIApplication {
    var isDisplayingEULA: Bool {
        print("isDisplayingEULA: \(otherElements["EULA"].exists)")
        return otherElements["EULA"].exists
    }
}
