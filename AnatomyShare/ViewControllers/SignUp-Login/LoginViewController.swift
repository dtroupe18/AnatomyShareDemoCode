//
//  LoginViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 5/24/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var moreInformationButton: UIButton!
    @IBOutlet weak var privacyPolicyButton: UIButton!
    
    var canLogin = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        self.passwordField.delegate = self
        initialize()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let acceptedEULA = UserDefaults.standard.bool(forKey: "EULA")
        if acceptedEULA {
            canLogin = true
            Auth.auth().addStateDidChangeListener { (auth, user) in
                if user != nil && user!.isEmailVerified || passedData.isDebug && user != nil {
                    // Segue to newsfeed, don't ask the user to sign in again
                    DispatchQueue.main.async {
                        let vc = UIStoryboard(name: "Tabs", bundle: nil).instantiateViewController(withIdentifier: "FirstTab")
                        self.present(vc, animated: false, completion: nil)
                    }
                } else {
                    // No user is signed in or their email is not verified
                }
            }
        }
        else {
            canLogin = false
            self.askUserToAcceptEULA()
        }
        if let hidden = self.navigationController?.isNavigationBarHidden {
            if hidden {
                self.navigationController?.setNavigationBarHidden(false, animated: false)
            }
        }
    }
    
    func askUserToAcceptEULA() {
        let termsAlert = UIAlertController(title: "User End Agreement Not Accepted", message: "You will not be able to sign in until you accept the user end agreement.", preferredStyle: .alert)
        let showTermsAction = UIAlertAction(title: "Show Terms", style: .default) {
            (_) in
            self.performSegue(withIdentifier: "toEULA", sender: nil)
            
        }
        let alertActionCancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        termsAlert.addAction(showTermsAction)
        termsAlert.addAction(alertActionCancel)
        DispatchQueue.main.async {
            self.present(termsAlert, animated: true, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        login()
        return true
    }
    
    @IBAction func signUpPressed(_ sender: Any) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toSignUp", sender: nil)
        }
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        login()
    }
    
    func login() {
        if canLogin {
            guard emailField.text != "", passwordField.text != "" else {
                // Alert error message
                if let topController = UIApplication.topViewController() {
                    Helper.showAlertMessage(vc: topController, title: "Error", message: "Please enter an email and password")
                }
                return
            }
            
            CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)
            Auth.auth().signIn(withEmail: emailField.text!, password: passwordField.text!, completion: {(user, error) in
                if let error = error {
                    // alert user of the error
                    CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                    if let topController = UIApplication.topViewController() {
                        Helper.showAlertMessage(vc: topController, title: "Login Error", message: error.localizedDescription)
                    }
                    return
                }
                if user != nil && user!.isEmailVerified {
                    DispatchQueue.main.async {
                        CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                        let vc = UIStoryboard(name: "Tabs", bundle: nil).instantiateViewController(withIdentifier: "FirstTab")
                        self.present(vc, animated: true, completion: nil)
                    }
                }
                else {
                    CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                    self.presentEmailNotVerifiedAlert()
                    return
                }
            })
        }
        else {
            askUserToAcceptEULA()
        }
    }
    
    func presentEmailNotVerifiedAlert() {
        let alertVC = UIAlertController(title: "Email Verification Required", message: "Sorry, you cannot sign in because your email address has not been verified. Send another verification email to \(self.emailField.text ?? "No email entered")?", preferredStyle: .alert)
        let alertActionOkay = UIAlertAction(title: "Send", style: .default) {
            (_) in
            if let user = Auth.auth().currentUser {
                user.sendEmailVerification(completion: { (error) in
                    if error != nil {
                        if let topController = UIApplication.topViewController() {
                            Helper.showAlertMessage(vc: topController, title: "Error", message: error!.localizedDescription)
                        }
                    }
                })
            }
        }
        let alertActionCancel = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        alertVC.addAction(alertActionOkay)
        alertVC.addAction(alertActionCancel)
        DispatchQueue.main.async {
            self.present(alertVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        presentPasswordResetAlert()
    }
    
    @IBAction func moreInformationPressed(_ sender: Any) {
        Helper.presentMoreInformation()
    }
    
    @IBAction func privacyPolicyPressed(_ sender: Any) {
        Helper.presentPrivacyPolicy()
    }
    
    
    func presentPasswordResetAlert() {
        let alertController = UIAlertController(title: "Password Reset", message: "Enter your email address so we can send you a new password.", preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                Auth.auth().sendPasswordReset(withEmail: field.text!, completion: { (error) in
                    if error != nil {
                        if let topController = UIApplication.topViewController() {
                            Helper.showAlertMessage(vc: topController, title: "Error", message: error!.localizedDescription)
                        }
                        return
                    }
                    else {
                        if let topController = UIApplication.topViewController() {
                            Helper.showAlertMessage(vc: topController, title: "Success", message: "Password reset email sent.")
                        }
                        return
                    }
                })
            }
            else {
                // do nothing they didn't write anything?
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Ex: anatomyShare@rwjms.edu"
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        if let topController = UIApplication.topViewController() {
            topController.present(alertController, animated: true, completion: nil)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func initialize() {
        loginButton.layer.borderWidth = 1
        loginButton.layer.borderColor = UIColor.gray.cgColor
        loginButton.layer.cornerRadius = 4
        
        signupButton.layer.borderWidth = 1
        signupButton.layer.borderColor = UIColor.gray.cgColor
        signupButton.layer.cornerRadius = 4
        
        moreInformationButton.layer.borderWidth = 1
        moreInformationButton.layer.borderColor = UIColor.gray.cgColor
        moreInformationButton.layer.cornerRadius = 4
        
        privacyPolicyButton.layer.borderWidth = 1
        privacyPolicyButton.layer.borderColor = UIColor.gray.cgColor
        privacyPolicyButton.layer.cornerRadius = 4
    }
}
