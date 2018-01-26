//
//  EditPostViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 7/20/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import Kingfisher

class EditPostViewController: UIViewController, UINavigationControllerDelegate, UIGestureRecognizerDelegate, UIPopoverControllerDelegate, UITextViewDelegate, sendDataToViewProtocol {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var selectTableButton: UIButton!
    @IBOutlet weak var selectCategoryButton: UIButton!
    @IBOutlet weak var selectRegionButton: UIButton!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIButton!
    
    @IBOutlet weak var updateAnnotationsButton: UIButton!
    @IBOutlet weak var takeNewPhotoButton: UIButton!
    @IBOutlet weak var loadImageFromDraftButton: UIButton!
    
    
    final let failure: String = "FALSE"
    
    // edited markers
    var tableChanged: Bool  = false
    var categoryChanged: Bool  = false
    var regionChanged: Bool = false
    var imageChanged: Bool  = false
    var postDescriptionChanged: Bool  = false
    var showingAnnotatedImage: Bool = true
    
    // draft passed in that will be used to edit a post
    var postDraft: PostDraft!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        styleView()
        self.hideKeyboardWhenTappedAround()
        textView.delegate = self
        saveButton.isEnabled = false
        
        let UITapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.imageTapped(_:)))
        UITapRecognizer.delegate = self
        self.imageView.addGestureRecognizer(UITapRecognizer)
        self.imageView.isUserInteractionEnabled = true
        
        if let annotated = self.postDraft.annotatedImage {
            self.imageView.image = annotated
        }
        
        if self.postDraft.originalImage == nil, let url = self.postDraft.originalImageURL {
            // download the other image in case it's needed
            ImageDownloader.default.downloadImage(with: url, options: [], progressBlock: nil) {
                (image, error, url, data) in
                if let image = image {
                    self.postDraft.originalImage = image
                }
            }
        }
        
        self.textView.text = self.postDraft.text
        self.selectTableButton.setTitle(postDraft.table ?? "Select Table", for: .normal)
        self.selectCategoryButton.setTitle(postDraft.category ?? "Select Category", for: .normal)
        self.selectRegionButton.setTitle(postDraft.region ?? "Select Region", for: .normal)
        
        // Since we can enter this view from so many different places
        // we need to know how many VC to pop from the navigation stack once
        // the user is done uploading their post. We can get the current number
        // in the stack when the view loads, then we know to pop to that number - 1            
        if self.postDraft.popIndex == nil, let viewControllers = self.navigationController?.viewControllers {
            self.postDraft.popIndex = viewControllers.count - 2
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // update the button titles to reflect the newly chosen values
        // this is only needed on iphone
        
        if let hidden = self.navigationController?.isNavigationBarHidden {
            if hidden {
                self.navigationController?.setNavigationBarHidden(false, animated: false)
            }
        }
        
        if self.tableChanged || self.regionChanged || self.categoryChanged || self.imageChanged {
            saveButton.isEnabled = true
        }
        
        if let table = self.postDraft.table {
            self.selectTableButton.setTitle(table, for: .normal)
        }
        
        if let reg = self.postDraft.region {
            self.selectRegionButton.setTitle(reg, for: .normal)
        }
        
        if let cat = self.postDraft.category {
            self.selectCategoryButton.setTitle(cat, for: .normal)
        }
        
        // Check if a new image was passed in
        if let annotated = self.postDraft.annotatedImage {
            self.imageView.image = annotated
        }
    }
    
    //Handle the text changes here
    func textViewDidChange(_ textView: UITextView) {
        self.postDraft.text = textView.text.trailingTrim(.whitespacesAndNewlines)
        postDescriptionChanged = true
        saveButton.isEnabled = true
    }
    
    
    @IBAction func savePressed(_ sender: Any) {
        self.updateDatabaseForEdits()
    }
    
    func updateDatabaseForEdits() {
        let ref = Database.database().reference()
        if let key = self.postDraft.key, let table = self.postDraft.table, let cat = self.postDraft.category, let reg = self.postDraft.region, let text = self.postDraft.text {
            
            if !self.imageChanged && (self.tableChanged || self.categoryChanged || self.regionChanged || self.postDescriptionChanged) {
                
                CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)
                self.saveButton.isEnabled = false
                
                let updates : [AnyHashable: Any] = ["table": table,
                                                    "category": cat,
                                                    "region": reg,
                                                    "postDescription": text.trailingTrim(.whitespacesAndNewlines),
                                                    "categoryRegion:": "\(cat)\(reg)"]
                
                ref.child("posts").child(key).updateChildValues(updates, withCompletionBlock: { (error, success) in
                    if error != nil {
                        self.uploadFailed()
                        return
                    }
                    else if let post = passedData.postDict[key] {
                        // upload was successful so we update the local values and then go back to the previous view
                        post.category = cat
                        post.region = reg
                        post.table = table
                        post.postDescription = text
                        post.fancyPostDescription = Helper.createAttributedString(author: post.author, postText: text)
                        post.userWhoPostedLabel = Helper.createAttributedPostLabel(username: post.author, table: post.table, region: post.region, category: post.category)
                        
                        passedData.postDict[key] = post
                        Helper.reloadEverything()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                            CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                            if let viewControllers = self.navigationController?.viewControllers {
                                if let popIndex = self.postDraft.popIndex {
                                    if popIndex > -1 && popIndex < viewControllers.count {
                                        // print("popping to index: \(popIndex)")
                                        self.navigationController?.popToViewController(viewControllers[popIndex], animated: true)
                                    }
                                    else {
                                        self.navigationController?.popToViewController(viewControllers[0], animated: true)
                                    }
                                }
                                else {
                                    self.navigationController?.popToViewController(viewControllers[0], animated: true)
                                }
                            }
                            else {
                                self.navigationController?.popToRootViewController(animated: true)
                            }
                        }
                    }
                    else {
                        self.uploadFailed()
                        return
                    }
                })
            }
                
            else if self.imageChanged, let original = postDraft.originalImage, let annotated = self.postDraft.annotatedImage, let uid = Auth.auth().currentUser?.uid {
                // upload the new images and then update the imagePaths
                CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)
                let originalName = ref.child("posts").childByAutoId().key
                let annotatedName = NSUUID().uuidString
                
                var imageDict = [String: UIImage]()
                imageDict[originalName] = original
                imageDict[annotatedName] = annotated
                
                DatabaseFunctions.uploadImages(userID: uid, imageDict: imageDict, completionHandler: { (urls) in
                    if urls.count != 2 {
                        self.uploadFailed()
                        return
                    }
                    else {
                        let first = urls[0]
                        let second = urls[1]
                        
                        var annotatedPath: String?
                        var originalPath: String?
                        
                        // determine which url goes to each image
                        // the url returned from Firebase contains the filename
                        // so we can check if the url contains the file name
                        if first.range(of: "\(originalName)") != nil {
                            originalPath = first
                            annotatedPath = second
                        }
                        else if second.range(of: "\(originalName)") != nil {
                            originalPath = second
                            annotatedPath = first
                        }
                        else  {
                            // failure
                            self.uploadFailed()
                            return
                        }
                        
                        let updates: [AnyHashable: Any] = ["table": table,
                                                           "category": cat,
                                                           "region": reg,
                                                           "postDescription": text.trailingTrim(.whitespacesAndNewlines),
                                                           "pathToImage": annotatedPath!,
                                                           "pathToOriginal": originalPath!,
                                                           "categoryRegion:": "\(cat)\(reg)"]
                        
                        ref.child("posts").child(key).updateChildValues(updates, withCompletionBlock: { (error, success) in
                            if error != nil {
                                self.uploadFailed()
                                return
                            }
                            else if let post = passedData.postDict[key] {
                                // upload was successful so we update the local values and then go back to the previous view
                                post.category = cat
                                post.region = reg
                                post.table = table
                                post.postDescription = text
                                post.fancyPostDescription = Helper.createAttributedString(author: post.author, postText: text)
                                post.userWhoPostedLabel = Helper.createAttributedPostLabel(username: post.author, table: post.table, region: post.region, category: post.category)
                                post.pathToImage = annotatedPath!
                                post.pathToOriginal = originalPath!
                                
                                passedData.postDict[key] = post
                                Helper.reloadEverything()
                                
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                                    CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                    if let viewControllers = self.navigationController?.viewControllers {
                                        if let popIndex = self.postDraft.popIndex {
                                            if popIndex > -1 && popIndex < viewControllers.count {
                                                self.navigationController?.popToViewController(viewControllers[popIndex], animated: true)
                                            }
                                            else {
                                                self.navigationController?.popToViewController(viewControllers[0], animated: true)
                                            }
                                        }
                                        else {
                                            self.navigationController?.popToViewController(viewControllers[0], animated: true)
                                        }
                                    }
                                    else {
                                        self.navigationController?.popToRootViewController(animated: true)
                                    }
                                }
                            }
                            else {
                                self.uploadFailed()
                                return
                            }
                        })
                    }
                })
            }
        }
    }
    
    private func uploadFailed() {
        CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
        if let topController = UIApplication.topViewController() {
            Helper.showAlertMessage(vc: topController, title: "Error", message: "Post failed to upload please try again")
        }
    }
    
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        if showingAnnotatedImage {
            self.imageView.image = self.postDraft.originalImage
            self.showingAnnotatedImage = false
        }
        else {
            self.imageView.image = self.postDraft.annotatedImage
            self.showingAnnotatedImage = true
        }
    }
    
    func inputData(section: String, data: String) {
        // determine where the data goes
        if section == "Table" {
            postDraft.table = data
            selectTableButton.setTitle(data, for: .normal)
            tableChanged = true
            saveButton.isEnabled = true
        }
        else if section == "Category" {
            postDraft.category = data
            selectCategoryButton.setTitle(data, for: .normal)
            categoryChanged = true
            saveButton.isEnabled = true
        }
        else {
            postDraft.region = data
            selectRegionButton.setTitle(data, for: .normal)
            regionChanged = true
            saveButton.isEnabled = true
        }
    }
    
    @IBAction func updateAnnotationsPressed(_ sender: Any) {
        // load the annotation VC and allow them to see both images
        DispatchQueue.main.async{
            let storyboard: UIStoryboard = UIStoryboard(name: "CreatePost", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "AnnotateViewController") as? AnnotateViewController {
                vc.fromEditVC = true
                vc.postDraft = self.postDraft
                self.show(vc, sender: self)
            }
        }
    }
    
    @IBAction func takeNewPhotoPressed(_ sender: Any) {
        // load the camera vc
        DispatchQueue.main.async{
            let storyboard: UIStoryboard = UIStoryboard(name: "CreatePost", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as? CameraViewController {
                vc.fromEditVC = true
                vc.postDraft = self.postDraft
                self.show(vc, sender: self)
            }
        }
    }
    
    @IBAction func loadImageFromDraftPressed(_ sender: Any) {
        DispatchQueue.main.async{
            let storyboard: UIStoryboard = UIStoryboard(name: "CreatePost", bundle: nil)
            if let vc = storyboard.instantiateViewController(withIdentifier: "DraftsViewController") as? DraftsViewController {
                vc.fromEditVC = true
                vc.postDraftFromEdit = self.postDraft
                self.show(vc, sender: self)
            }
        }
    }
    
    @IBAction func selectTablePressed(_ sender: Any) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let popoverContent = self.storyboard?.instantiateViewController(withIdentifier: "SelectTable") as? SelectTableViewController {
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
                DispatchQueue.main.async {
                    self.present(popoverContent, animated: true, completion: nil)
                }
            }
        }
        else {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "toSelectTableFromEdit", sender: nil)
            }
        }
    }
    
    @IBAction func selectCategoryPressed(_ sender: Any) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let popoverContent = self.storyboard?.instantiateViewController(withIdentifier: "SelectCategory") as? SelectCategoryViewController {
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
                self.performSegue(withIdentifier: "toSelectCategoryFromEdit", sender: nil)
            }
        }
    }
    
    @IBAction func selectRegionPressed(_ sender: Any) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            if let popoverContent = self.storyboard?.instantiateViewController(withIdentifier: "SelectRegion") as? SelectRegionViewController {
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
                self.present(popoverContent, animated: false, completion: nil)
            }
        }
        else {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "toSelectRegionFromEdit", sender: nil)
            }
        }
    }
    
    @IBAction func deletePostPressed(_ sender: Any) {
        if let key = self.postDraft.key {
            let ref = Database.database().reference()
            // Are you sure you want to delete this post
            let deleteAlert = UIAlertController(title: "Delete Post", message: "Are you sure you want to delete your post? This action cannot be undone.", preferredStyle: UIAlertControllerStyle.alert)
            
            deleteAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                // print("Handle Ok logic here")
                ref.child("posts").child(key).removeValue(completionBlock: { (error, refer) in
                    if error != nil {
                        if let topController = UIApplication.topViewController() {
                            Helper.showAlertMessage(vc: topController, title: "Error", message: error!.localizedDescription)
                        }
                        return
                    }
                    else {
                        passedData.postDict.removeValue(forKey: key)
                        // remove from userActivity and decrement the count
                        if let uid = Auth.auth().currentUser?.uid {
                            ref.child("userActivity").child(uid).child("posts").child(key).removeValue()
                            // update to have a completion block?
                            DatabaseFunctions.decrementUserActivityCount(countName: "posts")
                        }
                        self.navigationController?.popViewController(animated: true)
                        Helper.reloadEverything()
                    }
                })
            }))
            
            deleteAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                // print("Handle Cancel Logic here")
            }))
            present(deleteAlert, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSelectTableFromEdit" {
            if let vc = segue.destination as? SelectTableViewController {
                vc.fromEditVC = true
            }
        }
            
        else if segue.identifier == "toSelectCategoryFromEdit" {
            if let vc = segue.destination as? SelectCategoryViewController {
                vc.fromEditVC = true
            }
        }
            
        else if segue.identifier == "toSelectRegionFromEdit" {
            if let vc = segue.destination as? SelectRegionViewController {
                vc.fromEditVC = true
            }
        }
    }
    
    
    func styleView() {
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.gray.cgColor
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 8
        textView.layer.borderColor = UIColor.gray.cgColor
        
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
        
        deleteButton.layer.borderWidth = 1
        deleteButton.layer.borderColor = UIColor.gray.cgColor
        deleteButton.layer.cornerRadius = 4
        
        updateAnnotationsButton.layer.borderWidth = 1
        updateAnnotationsButton.layer.borderColor = UIColor.gray.cgColor
        updateAnnotationsButton.layer.cornerRadius = 4
        updateAnnotationsButton.titleLabel?.minimumScaleFactor = 0.5
        updateAnnotationsButton.titleLabel?.numberOfLines = 1
        updateAnnotationsButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        takeNewPhotoButton.layer.borderWidth = 1
        takeNewPhotoButton.layer.borderColor = UIColor.gray.cgColor
        takeNewPhotoButton.layer.cornerRadius = 4
        takeNewPhotoButton.titleLabel?.minimumScaleFactor = 0.5
        takeNewPhotoButton.titleLabel?.numberOfLines = 1
        takeNewPhotoButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        loadImageFromDraftButton.layer.borderWidth = 1
        loadImageFromDraftButton.layer.borderColor = UIColor.gray.cgColor
        loadImageFromDraftButton.layer.cornerRadius = 4
        loadImageFromDraftButton.titleLabel?.minimumScaleFactor = 0.5
        loadImageFromDraftButton.titleLabel?.numberOfLines = 1
        loadImageFromDraftButton.titleLabel?.adjustsFontSizeToFitWidth = true

    }
    
    func removeUsernameFromPostDescription(fulltext: String) -> String {
        if let range = fulltext.range(of: ":") {
            let newText = fulltext[..<range.upperBound]
            return newText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        else {
            return failure
        }
    }
}
