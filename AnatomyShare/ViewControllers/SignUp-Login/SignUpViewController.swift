//
//  SignUpViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 5/24/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class SignUpViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirmPassword: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var selectPictureButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var imageViewHeight: NSLayoutConstraint!
    @IBOutlet weak var imageViewWidth: NSLayoutConstraint!
    
    
    //initialize picker
    let picker = UIImagePickerController()
    
    // setup storage
    var userStorage: StorageReference!
    
    // setup database
    var ref: DatabaseReference!
    
    let screenSize = UIScreen.main.bounds
    
    // Blank field alert
    var blankFieldAlert: UIAlertController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.hideKeyboardWhenTappedAround()
        picker.delegate = self
        var storage: StorageReference!
        
        if !passedData.isDebug {
            storage = Storage.storage().reference(forURL: "gs://anatomyshare-b9fbc.appspot.com")
        }
        else {
            storage = Storage.storage().reference(forURL: "gs://anatomysharedevelopment.appspot.com")
        }
        
        userStorage = storage.child("profilePics")
        ref = Database.database().reference()
        
        
        let screenWidth = screenSize.width / 2
        imageViewWidth.constant = screenWidth
        imageViewHeight.constant = screenWidth
        
        // style buttons....
        selectPictureButton.layer.borderWidth = 1
        selectPictureButton.layer.cornerRadius = 4
        selectPictureButton.layer.borderColor = UIColor.gray.cgColor
        nextButton.layer.borderWidth = 1
        nextButton.layer.cornerRadius = 4
        nextButton.layer.borderColor = UIColor.gray.cgColor
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let hidden = self.navigationController?.isNavigationBarHidden {
            if hidden {
                self.navigationController?.setNavigationBarHidden(false, animated: false)
            }
        }
    }
    
    @IBAction func selectImagePressed(_ sender: Any) {
        // check if we can access the library first? If no we need to ask again
        picker.allowsEditing = true
        picker.sourceType = .photoLibrary // can be camera or library
        picker.modalPresentationStyle = .popover
        
        if picker.popoverPresentationController != nil {
            picker.popoverPresentationController!.delegate = self as? UIPopoverPresentationControllerDelegate
            picker.popoverPresentationController!.sourceView =  view
            let xLocation = (screenSize.width / 100) * 15
            let yLocation = (screenSize.height / 2)
            picker.popoverPresentationController?.sourceRect = CGRect(x: xLocation, y: yLocation, width: 0, height: 0)
        }
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let editedImage = info[UIImagePickerControllerEditedImage] as? UIImage {
            // Use editedImage Here
            self.imageView.image = editedImage
            nextButton.isHidden = false
        }
        else if let originalImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // Use originalImage Here
            self.imageView.image = originalImage
            nextButton.isHidden = false
        }
        else {
            if let vc = UIApplication.topViewController() {
                Helper.showAlertMessage(vc: vc, title: "Image Error", message: "An error occured during image selection")
            }
        }
        picker.dismiss(animated: true)
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        // make sure everything is filled out
        guard nameField.text != "", emailField.text != "", password.text != "", confirmPassword.text != "" else {
            // alert user
            //
            blankFieldAlert = UIAlertController(title: "Error", message: "Please enter all of the required fields", preferredStyle: .alert)
            // Default alert action
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            blankFieldAlert?.addAction(defaultAction)
            if blankFieldAlert != nil {
                self.present(blankFieldAlert!, animated: true, completion: nil)
                return
            }
            return
        }
        
        if password.text == confirmPassword.text && isValidEmail() && isValidUserName() {
            CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)

            Auth.auth().createUser(withEmail: self.emailField.text!, password: self.password.text!, completion: { (user, error) in
                
                if let error = error {
                    CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                    if let topController = UIApplication.topViewController() {
                        Helper.showAlertMessage(vc: topController, title: "Error", message: error.localizedDescription)
                    }
                    return
                }
                
                if let user = user {
                    // so we can use the posters name not the UID
                    let changeRequest = Auth.auth().currentUser!.createProfileChangeRequest()
                    changeRequest.displayName = self.nameField.text!.trailingTrim(.whitespacesAndNewlines)
                    changeRequest.commitChanges(completion: nil)
                    
                    
                    let imageRef = self.userStorage.child("\(user.uid).jpg")
                    
                    let data = UIImageJPEGRepresentation(self.imageView.image!, 0.5) // small image so compress more
                    
                    let uploadTask = imageRef.putData(data!, metadata: nil, completion: { (metadata, err) in
                        if err != nil {
                            CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                            if let topController = UIApplication.topViewController() {
                                Helper.showAlertMessage(vc: topController, title: "Error", message: err!.localizedDescription)
                            }
                            return
                        }
                        
                        imageRef.downloadURL(completion: { (url, er) in
                            if er != nil {
                                if let topController = UIApplication.topViewController() {
                                    Helper.showAlertMessage(vc: topController, title: "Error", message: er!.localizedDescription)
                                }
                                CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                return
                            }
                            
                            if let url = url {
                                let userInfo: [String: Any] = ["uid": user.uid,
                                                               "displayName": self.nameField.text!,
                                                               "email": self.emailField.text!,
                                                               "urlToImage": url.absoluteString]
                                
                                self.ref.child("users").child(user.uid).setValue(userInfo) { (error, ref) -> Void in
                                    if error != nil {
                                        // try again?
                                        print(error!.localizedDescription)
                                        CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                    }
                                }
                                self.ref.child("usernames").child(self.nameField.text!.removingWhitespaces().lowercased()).setValue(Auth.auth().currentUser!.uid) { (error, ref) -> Void in
                                    if error != nil {
                                        print(error!.localizedDescription)
                                        CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                    }
                                }
                                // differeny way to segue to another viewController
                                DatabaseFunctions.createUserActivityCounts(uid: user.uid)
                                CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                self.sendVerificationEmail()
                                DispatchQueue.main.async {
                                    self.navigationController?.popViewController(animated: true)
                                }
                            }
                        })
                    })
                    uploadTask.resume()
                }
            })
        }
        else if !isValidEmail() {
            if let topController = UIApplication.topViewController() {
                Helper.showAlertMessage(vc: topController, title: "RWJMS Students Only", message: "This application is currently only open to students at Robert Wood Johnson Medical School. If you are interested in using this app at your school please contact the developer.")
            }
            return
        }
        else if !isValidUserName() {
            if let topController = UIApplication.topViewController() {
                Helper.showAlertMessage(vc: topController, title: "Username Error", message: "Usernames cannot contain any of the following (. # $ [ ]). Please remove those characters and try again.")
            }
            return
        }
        else {
            // alert
            if let topController = UIApplication.topViewController() {
                Helper.showAlertMessage(vc: topController, title: "Error", message: "Passwords do not match")
            }
            return
        }
    }
    
    private func sendVerificationEmail() {
        Auth.auth().currentUser?.sendEmailVerification(completion: { (error) in
            if error != nil {
                if let topController = UIApplication.topViewController() {
                    Helper.showAlertMessage(vc: topController, title: "Error", message: "There was a problem sending an email to verify your account. Another one will be sent when you attempt to sign in.")
                }
                return
            }
            else {
                if let topController = UIApplication.topViewController() {
                    Helper.showAlertMessage(vc: topController, title: "Email Verification Required", message: "You will receive an email shortly to verify your account. This must be done before you can sign in.")
                }
                return
            }
        })
    }
    
    // Function to deterime if the username has any charcters that are not allowed
    // in a Firebase path. If they are present we prompt the user the change their display name.
    // If this is not done then the app will crash when the invalid username is uploaded.
    //
    func isValidUserName() -> Bool {
        if nameField.text?.lowercased().range(of: ".") != nil || nameField.text?.lowercased().range(of: "#") != nil || nameField.text?.lowercased().range(of: "$") != nil || nameField.text?.lowercased().range(of: "[") != nil ||
            nameField.text?.lowercased().range(of: "]") != nil {
            return false
        }
        return true
    }
    
    func isValidEmail() -> Bool {
        if self.emailField.text!.lowercased().range(of: "@rwjms.rutgers.edu") != nil
            || self.emailField.text!.lowercased().range(of: "@gsbs.rutgers.edu") != nil
            || self.emailField.text!.lowercased().range(of: "anatomyshareteam@gmail.com") != nil
            || passedData.isDebug {
            return true
        }
        return false
    }    
}



