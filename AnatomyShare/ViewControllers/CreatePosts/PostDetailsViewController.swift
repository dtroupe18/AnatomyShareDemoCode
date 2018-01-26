//
//  UploadTwoViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 6/12/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseAuth
import FirebaseStorage

class PostDetailsViewController: UIViewController, UITextViewDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, sendDataToViewProtocol {
    
    @IBOutlet weak var tinyImageView: UIImageView!
    @IBOutlet weak var postText: UITextView!
    @IBOutlet weak var postButton: UIBarButtonItem!
    @IBOutlet weak var selectTableButton: UIButton!
    @IBOutlet weak var selectCategoryButton: UIButton!
    @IBOutlet weak var selectRegionButton: UIButton!
    @IBOutlet weak var saveAsDraftButton: UIButton!
    
    var showingAnnotatedImage: Bool = false
    var buttonsNeedToBeReset = false
    
    var postDraft: PostDraft!
    
    // gesture recognizer to swap images in imageview
    var tapGesture: UITapGestureRecognizer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    @IBAction func selectTablePressed(_ sender: Any) {
        buttonsNeedToBeReset = true
        if UIDevice.current.userInterfaceIdiom == .pad {
            DispatchQueue.main.async {
                let popoverContent = self.storyboard?.instantiateViewController(withIdentifier: "Tables") as! SelectTableViewController
                popoverContent.delegate = self
                popoverContent.modalPresentationStyle = .popover
                _ = popoverContent.popoverPresentationController
                
                if let popover = popoverContent.popoverPresentationController {
                    let viewForSource = sender as! UIView
                    popover.sourceView = viewForSource
                    popover.sourceRect = viewForSource.bounds
                    popover.permittedArrowDirections = .down
                    popoverContent.preferredContentSize = CGSize(width: 300, height: 200)
                    popoverContent.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
                    popover.delegate = self as? UIPopoverPresentationControllerDelegate
                }
                self.present(popoverContent, animated: true, completion: nil)
            }
        }
        else {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "toTables", sender: nil)
            }
        }
    }
    
    
    @IBAction func selectCategoryPressed(_ sender: Any) {
        buttonsNeedToBeReset = true
        if UIDevice.current.userInterfaceIdiom == .pad {
            DispatchQueue.main.async {
                let popoverContent = self.storyboard?.instantiateViewController(withIdentifier: "Categories") as! SelectCategoryViewController
                popoverContent.delegate = self
                popoverContent.modalPresentationStyle = .popover
                _ = popoverContent.popoverPresentationController
                
                if let popover = popoverContent.popoverPresentationController {
                    let viewForSource = sender as! UIView
                    popover.sourceView = viewForSource
                    popover.sourceRect = viewForSource.bounds
                    popover.permittedArrowDirections = .down
                    popoverContent.preferredContentSize = CGSize(width: 300, height: 200)
                    popoverContent.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
                    popover.delegate = self as? UIPopoverPresentationControllerDelegate
                }
                self.present(popoverContent, animated: true, completion: nil)
            }
        }
        else {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "toCategories", sender: nil)
            }
        }
    }
    
    @IBAction func selectRegionPressed(_ sender: Any) {
        buttonsNeedToBeReset = true
        if UIDevice.current.userInterfaceIdiom == .pad {
            DispatchQueue.main.async {
                let popoverContent = self.storyboard?.instantiateViewController(withIdentifier: "Regions") as! SelectRegionViewController
                popoverContent.delegate = self
                popoverContent.modalPresentationStyle = .popover
                _ = popoverContent.popoverPresentationController
                
                if let popover = popoverContent.popoverPresentationController {
                    let viewForSource = sender as! UIView
                    popover.sourceView = viewForSource
                    popover.sourceRect = viewForSource.bounds
                    popover.permittedArrowDirections = .down
                    popoverContent.preferredContentSize = CGSize(width: 300, height: 200)
                    popoverContent.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
                    popover.delegate = self as? UIPopoverPresentationControllerDelegate
                }
                self.present(popoverContent, animated: true, completion: nil)
            }
        }
        else {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "toRegions", sender: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toRegions" {
            if let vc = segue.destination as? SelectRegionViewController {
                vc.fromDetailsVC = true
            }
        }
        else if segue.identifier == "toCategories" {
            if let vc = segue.destination as? SelectCategoryViewController {
                vc.fromDetailsVC = true
            }
        }
        
        else if segue.identifier == "toTables" {
            if let vc = segue.destination as? SelectTableViewController {
                vc.fromDetailsVC = true
            }
        }
    }
    
    @IBAction func saveAsDraft(_ sender: Any) {
        // both images have to be there in order to save as a draft
        if self.postDraft.originalImage != nil && self.postDraft.annotatedImage != nil {
            self.postDraft.originalImage = self.postDraft.originalImage?.correctlyOrientedImage()
            self.postDraft.text = self.postText.text
            // We don't know if the draft has been saved before so we don't know if
            // we should call overwrite or save. Overwrite will check if a previous
            // version exists if it doesn't then it wll call saveDraft.
            let requiredDict: [String: Any] = ["draft": self.postDraft]
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "saveDraftFromPostDetails"), object: nil, userInfo: requiredDict)
            // AnnotateViewController().overwriteSavedDraft(postDraft: self.postDraft)
        }
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    
    // Marker: SendDataToViewProtocol
    func inputData(section: String, data: String) {
        // determine where the data goes
        if section == "Table" {
            self.postDraft.table = data
            DispatchQueue.main.async {
                self.selectTableButton.setTitle(data, for: .normal)
            }
        }
        else if section == "Category" {
            self.postDraft.category = data
            DispatchQueue.main.async {
                self.selectCategoryButton.setTitle(data, for: .normal)
            }
        }
        else {
            self.postDraft.region = data
            DispatchQueue.main.async {
                self.selectRegionButton.setTitle(data, for: .normal)
            }
        }
    }
    
    @IBAction func postPressed(_ sender: Any) {
        if self.canPost() {
            if let uid = Auth.auth().currentUser?.uid, let name = Auth.auth().currentUser?.displayName {
                if self.postText.isFirstResponder {
                    self.postText.resignFirstResponder()
                }
                CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)
                
                let ref = Database.database().reference()
                let key = ref.child("posts").childByAutoId().key
                let annotatedName = NSUUID().uuidString
                
                var imageDict = [String: UIImage]()
                imageDict[key] = self.postDraft.originalImage!
                imageDict[annotatedName] = self.postDraft.annotatedImage!
                
                
                DatabaseFunctions.uploadImages(userID: uid, imageDict: imageDict, completionHandler: { (urls) in
                    if urls.count == 2 {
                        
                        let first = urls[0]
                        let second = urls[1]
                        
                        var annotatedPath: String?
                        var originalPath: String?
                        
                        // determine which url goes to each image
                        // the url returned from Firebase contains the filename
                        // so we can check if the url contains the file name
                        if first.range(of: "\(key)") != nil {
                            originalPath = first
                            annotatedPath = second
                        }
                        else if second.range(of: "\(key)") != nil {
                            originalPath = second
                            annotatedPath = first
                        }
                        else  {
                            // Failure
                            CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                            if let topController = UIApplication.topViewController() {
                                Helper.showAlertMessage(vc: topController, title: "Error", message: "Post failed to upload please try again")
                            }
                            return
                            
                        }
                        
                        guard let text = self.postText.text, let table = self.postDraft.table, let cat = self.postDraft.category,
                            let reg = self.postDraft.region
                            else {
                                CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                if let topController = UIApplication.topViewController() {
                                    Helper.showAlertMessage(vc: topController, title: "Error", message: "Post failed to upload please try again")
                                }
                                return
                                }
                        
                        let feed = ["userID": uid,
                                    "author": name,
                                    "pathToImage": annotatedPath!,
                                    "pathToOriginal": originalPath!,
                                    "likes": 0,
                                    "numberOfComments": 0,
                                    "postDescription": text.trailingTrim(.whitespacesAndNewlines),
                                    "timestamp": [".sv": "timestamp"],
                                    "table": table,
                                    "category": cat,
                                    "region": reg,
                                    "categoryRegion": "\(cat)\(reg)",
                                    "one": self.postDraft.textOne,
                                    "two": self.postDraft.textTwo,
                                    "three": self.postDraft.textThree,
                                    "four": self.postDraft.textFour,
                                    "five": self.postDraft.textFive,
                                    "postID": key] as [String: Any?]
                        
                        let postFeed = ["\(key)" : feed]
                        
                        ref.child("posts").updateChildValues(postFeed, withCompletionBlock: { (error, success) in
                            if error != nil {
                                CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                if let topController = UIApplication.topViewController() {
                                    Helper.showAlertMessage(vc: topController, title: "Error", message: "Post failed to upload please try again")
                                }
                                return
                            }
                            // data successfully uploaded
                            else {
                                // upload to userActivity
                                let userUpdate = ["\(key)" : true]
                                ref.child("userActivity").child(uid).child("posts").updateChildValues(userUpdate, withCompletionBlock: { (e, suc) in
                                    // update to try again if there's an error
                                })
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    self.navigationController?.viewControllers = []
                                    // DatabaseFunctions.refreshNewsfeed()
                                    DatabaseFunctions.incrementUserActivityCount(countName: "posts")
                                    CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                    self.performSegue(withIdentifier: "finishedPost", sender: nil)
                                }
                            }
                        })
                    }
                })
            }
        }
    }
    
    private func canPost() -> Bool {
        if self.postDraft.annotatedImage == nil || self.postDraft.originalImage == nil {
            if let topController = UIApplication.topViewController() {
                Helper.showAlertMessage(vc: topController, title: "Error", message: ("All posts must contain an image"))
            }
            return false
        }
        else if self.postDraft.table == nil || self.postDraft.category == nil || self.postDraft.region == nil {
            if let topController = UIApplication.topViewController() {
                Helper.showAlertMessage(vc: topController, title: "Error", message: ("All posts must contain a table, category, and region."))
            }
            return false
        }
        else {
            return true
        }
    }
        
    override func viewWillAppear(_ animated: Bool) {
        // passed data is used to get the selected table, category, region
        // if the user is on an iphone
        if let table = self.postDraft.table {
            self.selectTableButton.setTitle(table, for: .normal)
        }
        if let cat = self.postDraft.category {
            self.selectCategoryButton.setTitle(cat, for: .normal)
        }
        if let reg = self.postDraft.region {
            self.selectRegionButton.setTitle(reg, for: .normal)
        }
        if let text = self.postDraft.text {
            self.postText.text = text
        }
    }
    
    @objc private func handleTap(recognizer: UITapGestureRecognizer) {
        if showingAnnotatedImage {
            self.tinyImageView.image = self.postDraft.originalImage
            self.showingAnnotatedImage = false
        }
        else {
            self.tinyImageView.image = self.postDraft.annotatedImage
            self.showingAnnotatedImage = true
        }
    }
    
    // Pass data to the previous viewController if the user pressed the back button
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParentViewController {
            if let previousVC = self.navigationController?.viewControllers.last as? AnnotateViewController {
                self.postDraft.text = self.postText.text
                previousVC.postDraft = self.postDraft
            }
        }
    }
    
    
    private func initialize() {
        if let hidden = self.navigationController?.isNavigationBarHidden {
            if hidden {
                self.navigationController?.setNavigationBarHidden(false, animated: false)
            }
        }
        
        if self.postDraft.annotatedImage != nil {
            self.tinyImageView.image = self.postDraft.annotatedImage
            showingAnnotatedImage = true
        }
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(recognizer:)))
        self.tinyImageView.addGestureRecognizer(tapGesture!)
        self.tinyImageView.isUserInteractionEnabled = true
        
        //styling
        tinyImageView.layer.borderWidth = 1
        tinyImageView.layer.borderColor = UIColor.gray.cgColor
        tinyImageView.layer.cornerRadius = 8
        tinyImageView.clipsToBounds = true
        
        postText.layer.borderWidth = 1
        postText.layer.cornerRadius = 8
        postText.layer.borderColor = UIColor.gray.cgColor
        postText.textColor = .black
        postText.delegate = self
        // postText.text = self.text ?? "" QWE
        
        self.hideKeyboardWhenTappedAround()
        
        // Style Buttons
        selectTableButton.layer.borderWidth = 1
        selectTableButton.layer.borderColor = UIColor.gray.cgColor
        selectTableButton.layer.cornerRadius = 4
        selectTableButton.titleLabel?.minimumScaleFactor = 0.5
        selectTableButton.titleLabel?.numberOfLines = 1
        selectTableButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        selectCategoryButton.layer.borderWidth = 1
        selectCategoryButton.layer.borderColor = UIColor.gray.cgColor
        selectCategoryButton.layer.cornerRadius = 4
        selectCategoryButton.titleLabel?.minimumScaleFactor = 0.5
        selectCategoryButton.titleLabel?.numberOfLines = 1
        selectCategoryButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        selectRegionButton.layer.borderWidth = 1
        selectRegionButton.layer.borderColor = UIColor.gray.cgColor
        selectRegionButton.layer.cornerRadius = 4
        selectRegionButton.titleLabel?.minimumScaleFactor = 0.5
        selectRegionButton.titleLabel?.numberOfLines = 1
        selectRegionButton.titleLabel?.adjustsFontSizeToFitWidth = true
    }
}
