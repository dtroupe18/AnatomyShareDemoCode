//
//  UserHeader.swift
//  AnatomyShare
//
//  Created by David Troupe on 9/3/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class UserHeader: UICollectionReusableView {
    
    @IBOutlet weak var displayName: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var changeImageButton: UIButton!
    @IBOutlet weak var postCount: UILabel!
    @IBOutlet weak var likeCount: UILabel!
    @IBOutlet weak var commentCount: UILabel!
    @IBOutlet weak var postsLabel: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!
    @IBOutlet weak var helpButton: UIButton!
    @IBOutlet weak var postsButton: UIButton!
    @IBOutlet weak var likesButton: UIButton!
    @IBOutlet weak var commentsButton: UIButton!
    @IBOutlet weak var blockedButton: UIButton!
    
    
    let usernameRef = Database.database().reference()
    var oldUserNameFormatted: String?
    var oldUserName: String?
    var newUserName: String?
    
    var changePhotoAction: ((UICollectionReusableView) -> Void)?
    var selectLikesAction: ((UICollectionReusableView) -> Void)?
    var selectPostsAction: ((UICollectionReusableView) -> Void)?
    var selectCommentsAction: ((UICollectionReusableView) -> Void)?
    var blockedButtonAction: ((UICollectionReusableView) -> Void)?
    
    
    
    
    @IBAction func blockedPressed(_ sender: Any) {
        if sender is UIButton {
            blockedButtonAction?(self)
        }
    }
    
    @IBAction func commentsPressed(_ sender: Any) {
        if sender is UIButton {
            selectCommentsAction?(self)
        }
    }
    
    
    @IBAction func likesPressed(_ sender: Any) {
        if sender is UIButton {
            selectLikesAction?(self)
        }
    }
    
    @IBAction func postsPressed(_ sender: Any) {
        if sender is UIButton {
            selectPostsAction?(self)
        }
    }
    
    
    @IBAction func changeImagePressed(_ sender: Any) {
        if sender is UIButton {
            changePhotoAction?(self)
        }
    }
    
    @IBAction func editNamePressed(_ sender: Any) {
        let ref = Database.database().reference()
        // initial press
        if !displayName.isUserInteractionEnabled {
            displayName.isUserInteractionEnabled = true
            editButton.setTitle("Save", for: .normal)
            editButton.setTitleColor(UIColor.red, for: .normal)
            DispatchQueue.main.async {
                self.displayName.becomeFirstResponder()
            }
        }
        // reset button and save new username
        else if displayName.isUserInteractionEnabled && displayName.text != "" {
            guard let topVC = UIApplication.topViewController() else { return }
            CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: topVC.view)
            self.setOldUsername()
            // check if username is available 
            let requestedUsername = displayName.text!.removingWhitespaces().lowercased()
            ref.child("usernames").child(requestedUsername).observeSingleEvent(of: .value, with: { snap in
                if snap.exists() {
                    //username is already taken
                    if let topController = UIApplication.topViewController() {
                        self.editButton.setTitle("Edit Name", for: .normal)
                        self.editButton.setTitleColor(UIColor.black, for: .normal)
                        self.displayName.isUserInteractionEnabled = false
                        if self.oldUserName != nil {
                            self.displayName.text = self.oldUserName!
                        }
                        self.displayName.resignFirstResponder()
                        CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: topController.view)
                        Helper.showAlertMessage(vc: topController, title: "Error", message: "Requested username is not available")
                    }
                    return
                }
                else {
                    // username is available
                    if let uid = Auth.auth().currentUser?.uid {
                        ref.child("users").child(uid).updateChildValues(["displayName": self.displayName.text!], withCompletionBlock: { (error, success) in
                            if error != nil {
                                if let topController = UIApplication.topViewController() {
                                    self.editButton.setTitle("Edit Name", for: .normal)
                                    self.editButton.setTitleColor(UIColor.black, for: .normal)
                                    self.displayName.isUserInteractionEnabled = false
                                    if self.oldUserName != nil {
                                        self.displayName.text = self.oldUserName!
                                    }
                                    self.displayName.resignFirstResponder()
                                    CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: topController.view)
                                    Helper.showAlertMessage(vc: topController, title: "Error", message: "Unable to save new display name please try again")
                                }
                                return
                            }
                            else {
                                // saved new username to users now save to usernames and remove the old one
                                self.removeOldUsername()
                                self.saveNewUsername()
                            }
                        })
                    }
                }
            })
            editButton.setTitle("Edit Name", for: .normal)
            editButton.setTitleColor(UIColor.black, for: .normal)
            displayName.isUserInteractionEnabled = false
            displayName.resignFirstResponder()
            
            CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: topVC.view)
        }
    }
    
    @IBAction func helpPresed(_ sender: Any) {
        Helper.presentHelpInformation()
    }
    
    
    private func setOldUsername() {
        if let currentName = Auth.auth().currentUser?.displayName {
            oldUserNameFormatted = currentName.removingWhitespaces().lowercased()
            oldUserName = currentName
        }
    }
    
    private func removeOldUsername() {
        if oldUserNameFormatted != nil {
            usernameRef.child("usernames").child(oldUserNameFormatted!).removeValue(completionBlock: { (error, success) in
                if error != nil {
                    // print(error!.localizedDescription)
                }
            })
        }
    }
    
    private func saveNewUsername() {
        let newUsername = displayName.text!.removingWhitespaces().lowercased()
        if let uid = Auth.auth().currentUser?.uid {
            usernameRef.child("usernames").updateChildValues([newUsername: uid], withCompletionBlock: { (e, success) in
                if e != nil {
                    if let topController = UIApplication.topViewController() {
                        Helper.showAlertMessage(vc: topController, title: "Error", message: "Unable to save new display name please try again")
                    }
                    else {
                        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                        changeRequest?.displayName = self.displayName.text
                        changeRequest?.commitChanges(completion: nil) // update
                        passedData.newUsername = self.displayName.text
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "updateUserNavTitle"), object: nil)
                    }
                }
            })
        }
    }
    
    
    
    
    
    
        
}
