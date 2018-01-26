//
//  LoginTests.swift
//  AnatomyShareUITests
//
//  Created by Dave on 1/24/18.
//  Copyright © 2018 Dave. All rights reserved.
//

import XCTest

class LoginScreenTests: XCTestCase {
    
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
        
        // We need to get rid of the EULA so that we can test other things on the login screen
        // More information about what is being done here can be found in EulaTest.swift
        //
        app.launch()
        let alert = app.alerts["User End Agreement Not Accepted"]
        alert.buttons["Show Terms"].tap()
        app/*@START_MENU_TOKEN@*/.buttons["Accept"]/*[[".otherElements[\"EULA\"].buttons[\"Accept\"]",".buttons[\"Accept\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
        app.terminate()
    }
    
    func testAppleReviewAccountSignIn() {
        // Test to ensure that the credentials provided to Apple
        // still allow them to sign in
        
        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("AnatomyShareTeam@gmail.com")
        
        let passwordSecureTextField = app.secureTextFields[" Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("password")
        app.buttons["Log In"].tap()
        
        // Need to have a delay here so there is time for the
        // segue to happen
        //
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertTrue(self.app.isDisplayingNewsfeed)
        }
    }
    
    func testBlankLogin() {
        // Make sure you get an error if you try to login without credentials
        // and that you do not move on to the newsfeed
        //
        app.buttons["Log In"].tap()
        XCTAssertTrue(app.alerts["Error"].exists)
        app.alerts["Error"].buttons["OK"].tap()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertFalse(self.app.isDisplayingNewsfeed)
        }
    }
    
    func testIncorrectSignIn() {
        // Test to ensure that invalid credentials
        // do not allow the user to sign in
        //
        
        let emailTextField = app.textFields["Email"]
        emailTextField.tap()
        emailTextField.typeText("xxxxx@gmail.com")
        
        let passwordSecureTextField = app.secureTextFields[" Password"]
        passwordSecureTextField.tap()
        passwordSecureTextField.typeText("FakePassword")
        app.buttons["Log In"].tap()
        
        // Ensure that we got an error message
        //
        XCTAssertTrue(app.alerts["Login Error"].exists)
        
        // Ensure that we do not move on to the newsfeed
        //
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            XCTAssertFalse(self.app.isDisplayingNewsfeed)
        }
    }
    
    func testForgotPassword() {
        // Ensure that an alert asking the user for the email
        // is provided when forgot password is pressed
        //
        
        let forgotPasswordButton = app.buttons["Forgot Password?"]
        forgotPasswordButton.tap()
        XCTAssertTrue(app.alerts["Password Reset"].exists)
        
        // Ensure error message is displayed if there's not email entered
        //
        let passwordResetAlert = app.alerts["Password Reset"]
        let submitButton = passwordResetAlert.buttons["Submit"]
        submitButton.tap()
        
        XCTAssertTrue(app.alerts["Error"].waitForExistence(timeout: 5))
        
        let okButton = self.app.alerts["Error"].buttons["OK"]
        okButton.tap()
        
        
        // Start over with forgot password again
        // press cancel and make sure no error is displayed
        //
        forgotPasswordButton.tap()
        passwordResetAlert.buttons["Cancel"].tap()
        XCTAssertFalse(app.alerts["Error"].waitForExistence(timeout: 5))
        
        // Start over with forgot password again
        // this time we will enter an invalid email and
        // ensure that an error is displayed
        //
        forgotPasswordButton.tap()
        let exAnatomyshareRwjmsEduTextField = passwordResetAlert.collectionViews.textFields["Ex: anatomyShare@rwjms.edu"]
        exAnatomyshareRwjmsEduTextField.typeText("xxxx@gmail.com")
        submitButton.tap()
        
        XCTAssertTrue(app.alerts["Error"].waitForExistence(timeout: 5))
    }
}

extension XCUIApplication {
    var isDisplayingNewsfeed: Bool {
        return otherElements["Newsfeed"].exists
    }
}

