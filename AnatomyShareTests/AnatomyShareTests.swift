//
//  AnatomyShareTests.swift
//  AnatomyShareTests
//
//  Created by Dave on 6/20/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import XCTest
import FirebaseAuth
import Kingfisher

@testable import AnatomyShare

class AnatomyShareTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testBlankSignUp() {
        
        class FakeSignUpViewController: SignUpViewController {
            var presentWasCalled = false
            
            override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
                presentWasCalled = true
            }
        }
        
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController {
            vc.viewDidLoad()
            vc.nextPressed(self)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertTrue(vc.presentedViewController!.isEqual(vc.blankFieldAlert), "Blank field alert not presented")
            }
        }
        else {
            // just fail
            //
            XCTAssertTrue(false)
        }
    }
    
    func testValidUserName() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController {
            vc.viewDidLoad()
            
            vc.nameField.text = "dave.troupe"
            XCTAssertFalse(vc.isValidUserName(), "Failed for username with '.' ")
            
            vc.nameField.text = "dave#troupe"
            XCTAssertFalse(vc.isValidUserName(), "Failed for username with '#' ")
            
            vc.nameField.text = "dave$troupe"
            XCTAssertFalse(vc.isValidUserName(), "Failed for username with '$' ")
            
            vc.nameField.text = "dave[troupe"
            XCTAssertFalse(vc.isValidUserName(), "Failed for username with '[' ")
            
            vc.nameField.text = "dave]troupe"
            XCTAssertFalse(vc.isValidUserName(), "Failed for username with ']' ")
            
            vc.nameField.text = "Proper Username"
            XCTAssertTrue(vc.isValidEmail(), "Failed for 'Proper Username'")
        }
    }
    
    func testValidEmail() {
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewController(withIdentifier: "SignUpViewController") as? SignUpViewController {
            vc.viewDidLoad()
            
            vc.emailField.text = "fake@rwjms.rutgers.edu"
            XCTAssertTrue(vc.isValidEmail(), "Failed email for fake@rwjms.rutgers.edu")
            
            vc.emailField.text = "fake@gsbs.rutgers.edu"
            XCTAssertTrue(vc.isValidEmail(), "Failed email for fake@gsbs.rutgers.edu")
            
            vc.emailField.text = "anatomyshareteam@gmail.com"
            XCTAssertTrue(vc.isValidEmail(), "Failed email for anatomyshareteam@gmail.com")
            
            vc.emailField.text = "dave.troupe@gmail.com"
            XCTAssertFalse(vc.isValidEmail(), "Failed email for dave.troupe@gmail.com")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
