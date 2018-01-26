//
//  SearchTableViewController.swift
//  AnatomyShare
//
//  Created by Dave on 1/8/18.
//  Copyright © 2018 Dave. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import Kingfisher

class SearchTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    // keys to the search results
    var searchKeys = [String]()
    
    // Index passed in so we know which post to scroll to
    var indexToScrollTo: Int!
    var maxScreenSize: CGFloat = 0
    let screenSize: CGRect = UIScreen.main.bounds
    
    // Index for image that was touched to zoom in on
    var selectedRow: Int?
    
    // Flag to determine how to load the comments VC
    var viewAllCommentsPressed = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.maxScreenSize = screenSize.height > screenSize.width ? screenSize.height : screenSize.width
        self.tableView.estimatedRowHeight = self.maxScreenSize
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.tableView.scrollToRow(at: IndexPath(row: self.indexToScrollTo, section: 0), at: .middle, animated: false)
        }
        
        // Reload for filter
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTableView), name: NSNotification.Name(rawValue: "reloadSearchTableView"), object: nil)
    }
    
    @objc private func reloadTableView() {
        self.tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchKeys.isEmpty {
            return 0
        }
        else {
            var numberOfRows = 0
            for key in self.searchKeys {
                if passedData.postDict[key] != nil {
                    numberOfRows += 1
                }
                else {
                    if let index = self.searchKeys.index(of: key) {
                        self.searchKeys.remove(at: index)
                    }
                }
            }
            return numberOfRows
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "betterPostCell", for: indexPath) as! BetterPostCell
        cell.notHelpfulButton.isHidden = true
        
        let key = self.searchKeys[indexPath.row]
        if passedData.postDict[key] != nil {
            if passedData.postDict[key]?.userID == "BLOCKED" {
                return cell
            }
            
            cell.indexPath = indexPath
            
            // show like or unlike button?
            if let like = passedData.likedPosts[key] {
                if like {
                    DispatchQueue.main.async {
                        cell.helpfulButton.isHidden = true
                        cell.notHelpfulButton.isHidden = false
                    }
                }
                else {
                    DispatchQueue.main.async {
                        cell.helpfulButton.isHidden = false
                        cell.notHelpfulButton.isHidden = true
                    }
                }
            }
            else {
                DispatchQueue.main.async {
                    cell.helpfulButton.isHidden = false
                    cell.notHelpfulButton.isHidden = true
                }
            }
            
            let url = URL(string: passedData.postDict[key]!.pathToImage)
            cell.postImage.kf.setImage(with: url)
            if UserDefaults.standard.object(forKey: "FILTER") != nil {
                if UserDefaults.standard.bool(forKey: "FILTER") == true {
                    cell.postImage.blurImage()
                    
                }
                else {
                    cell.postImage.removeBlur()
                }
            }
            
            // download the user image for each cell
            let userImageRef = Database.database().reference()
            let userID = passedData.postDict[key]?.userID
            
            if let uid = Auth.auth().currentUser?.uid, let userID = passedData.postDict[key]?.userID {
                if uid == userID {
                    cell.editButton.isHidden = false
                    cell.reportButton.isHidden = true
                }
                else {
                    cell.editButton.isHidden = true
                    cell.reportButton.isHidden = false
                }
            }
            
            userImageRef.child("users").child(userID!).queryOrderedByKey().observeSingleEvent(of: .value, with: { dataSnapshot in
                if let pathSnap = dataSnapshot.value as? [String: AnyObject] {
                    if let imagePath = pathSnap["urlToImage"] as? String {
                        let url = URL(string: imagePath)
                        cell.userWhoPostedImageView.kf.setImage(with: url)
                        cell.userWhoPostedImageView.layer.cornerRadius = 6
                        cell.userWhoPostedImageView.clipsToBounds = true
                    }
                }
            })
            // disables the ugly cell highlighting
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.userWhoPostedLabel.attributedText = passedData.postDict[key]?.userWhoPostedLabel
            cell.userWhoPostedLabel.sizeToFit()
            
            let likes = passedData.postDict[key]!.likes!
            if likes != 1 {
                cell.helpfulLabel.text = "\(likes) Likes"
            }
            else {
                cell.helpfulLabel.text = "\(likes) Like"
            }
            
            cell.postID = key
            cell.postDescription.attributedText = passedData.postDict[key]?.fancyPostDescription
            cell.postDescription.sizeToFit()
            
            // Add Timestamp
            cell.timestamp.text = Helper.convertTimestamp(serverTimestamp: passedData.postDict[key]!.timestamp!)
            
            // needs to be calculated with the author can we get the fancy post description as a string
            // then we could try that?
            if (passedData.postDict[key]!.postDescription.height(withConstrainedWidth: UIScreen.main.bounds.width * 0.7, font: UIFont.systemFont(ofSize: UIFont.systemFontSize))) > cell.postDescription.frame.height && !cell.isExpanded {
                cell.moreButton.isHidden = false
            }
            else {
                // otherwise a resued cell will have the more button
                cell.moreButton.isHidden = true
            }
            
            // comment button
            cell.textbubbleButton.tag = indexPath.row
            cell.textbubbleButton.addTarget(self, action: #selector(self.textBubblePressed(_:)), for: UIControlEvents.touchUpInside)
            
            // view all comments button
            cell.numberOfCommentsButton.tag = indexPath.row
            cell.numberOfCommentsButton.addTarget(self, action: #selector(self.viewAllCommentsButtonPressed(_:)), for: UIControlEvents.touchUpInside)
            
            if passedData.postDict[key]!.numberOfComments > 0 {
                if passedData.postDict[key]!.numberOfComments == 1 {
                    cell.numberOfCommentsButton.setTitle("View \(passedData.postDict[key]!.numberOfComments!) comment", for: .normal)
                }
                else {
                    cell.numberOfCommentsButton.setTitle("View all \(passedData.postDict[key]!.numberOfComments!) comments", for: .normal)
                }
                cell.numberOfCommentsButton.tag = indexPath.row
                cell.numberOfCommentsButton.isHidden = false
            }
            else {
                cell.numberOfCommentsButton.isHidden = true
            }
            
            // change helpful button if the post has already been liked
            if passedData.postDict[key]!.userLiked {
                cell.helpfulButton.isHidden = true
                cell.notHelpfulButton.isHidden = false
            }
            else {
                cell.helpfulButton.isHidden = false
                cell.notHelpfulButton.isHidden = true
            }
            
            cell.moreTapAction = { (BetterPostCell) in
                passedData.postDict[key]!.isExpanded = !passedData.postDict[key]!.isExpanded
                cell.moreButton.isHidden = true
                
                // refresh
                DispatchQueue.main.async {
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
            }
            
            cell.editTapAction = { (BetterPostCell) in
                if indexPath.row + 1 <= self.searchKeys.count {
                    self.selectedRow = indexPath.row
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "toEditFromSearch", sender: nil)
                    }
                }
            }
            
            cell.likeTapAction = { (BetterPostCell) in
                // update values stored locally
                passedData.postDict[key]!.likes! += 1
                passedData.likedPosts[key] = true
                if let count = passedData.postDict[key]!.likes {
                    if count != 1 {
                        cell.helpfulLabel.text = "\(count) Likes"
                    }
                    else {
                        cell.helpfulLabel.text = "\(count) Like"
                    }
                }
            }
            
            cell.unlikeTapAction = { (BetterPostCell) in
                passedData.likedPosts[key] = false
                passedData.postDict[key]!.likes! -= 1
                if let count = passedData.postDict[key]!.likes {
                    if count != 1 {
                        cell.helpfulLabel.text = "\(count) Likes"
                    }
                    else {
                        cell.helpfulLabel.text = "\(count) Like"
                    }
                }
            }
            let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(self.segueToScrollView(_ :)))
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.swapCellImage(recognizer:)))
            cell.postImage.isUserInteractionEnabled = true
            cell.postImage.addGestureRecognizer(pinchGestureRecognizer)
            cell.postImage.addGestureRecognizer(tapGestureRecognizer)
            
            return cell
        }
        else {
            return  UITableViewCell()
        }
    }
    
    // Cell Height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let key = self.searchKeys[indexPath.row]
        if passedData.postDict[key] != nil && passedData.postDict[key]!.isExpanded {
            let sysFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
            let labelHeight = passedData.postDict[key]!.postDescription!.height(withConstrainedWidth: screenSize.width * 0.8, font: sysFont)
            return maxScreenSize + labelHeight - 100
        }
        else if passedData.postDict[key]?.userID == "BLOCKED" {
            return 0 // effectively makes the cell "invisible"
        }
        else {
            return maxScreenSize - 100
        }
    }
    
    // Cell Editing
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let block = UITableViewRowAction(style: .normal, title: "Block User") { action, index in
            let key = self.searchKeys[indexPath.row]
            if let userToBlock = passedData.postDict[key]?.userID, let name = passedData.postDict[key]?.author, let uid = Auth.auth().currentUser?.uid {
                DatabaseFunctions.blockUser(currentUserUID: uid, blockedUID: userToBlock, blockedName: name, indexPath: indexPath)
            }
        }
        block.backgroundColor = UIColor.red
        return [block]
    }
    
    // Method to change the post image if there's another image
    @objc func swapCellImage(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: location) {
            let key = self.searchKeys[indexPath.row]
            if let post = passedData.postDict[key] {
                // if there isn't an original path then we can't swap images
                if let path = post.pathToOriginal {
                    if let cell = self.tableView.cellForRow(at: indexPath) as? BetterPostCell {
                        if post.showingOriginalImage {
                            let url = URL(string: post.pathToImage)
                            cell.postImage.kf.indicatorType = .activity
                            cell.postImage.kf.setImage(with: url)
                            post.showingOriginalImage = false
                        }
                        else {
                            let url = URL(string: path)
                            cell.postImage.kf.indicatorType = .activity
                            cell.postImage.kf.setImage(with: url)
                            post.showingOriginalImage = true
                        }
                    }
                }
            }
        }
    }
    
    // Cell image pinched
    @objc func segueToScrollView(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            let touch = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touch) {
                selectedRow = indexPath.row
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "toZoomFromSearch", sender: sender)
                }
            }
        }
    }
    
    // View all comments pressed
    @objc func viewAllCommentsButtonPressed(_ sender: UIButton!) {
        viewAllCommentsPressed = true
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toCommentsFromSearch", sender: sender)
        }
    }
    
    // Text bubble pressed
    @objc func textBubblePressed(_ sender: UIButton!) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toCommentsFromSearch", sender: sender)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toZoomFromSearch" {
            if let destination = segue.destination as? ZoomedPhotoViewController {
                if selectedRow != nil {
                    let cell = tableView.cellForRow(at: [0, selectedRow!]) as! BetterPostCell
                    destination.selectedImage = cell.postImage.image
                }
            }
        }
        if segue.identifier == "toEditFromSearch" {
            if let destination = segue.destination as? EditPostViewController {
                if let index = selectedRow {
                    let postDraft = PostDraft()
                    postDraft.key = self.searchKeys[index]
                    if let post = passedData.postDict[postDraft.key!] {
                        postDraft.table = post.table
                        postDraft.region = post.region
                        postDraft.category = post.category
                        postDraft.text = post.postDescription
                        if let originalPath = post.pathToOriginal {
                            let url = URL(string: originalPath)
                            // this image is most likely not on the cache
                            // so we will just save the url to the post draft
                            // and if the user wants to edit the image we will download it
                            postDraft.originalImageURL = url
                        }
                        // get visible image from kingfisher cache
                        if let image = ImageCache.default.retrieveImageInDiskCache(forKey: post.pathToImage) {
                            postDraft.annotatedImage = image
                            destination.postDraft = postDraft
                        }
                    }
                }
            }
        }
        if segue.identifier == "toCommentsFromSearch" {
            if let destination = segue.destination as? CommentsViewController {
                if let button:UIButton = sender as! UIButton? {
                    destination.keyForPostToLoad = self.searchKeys[button.tag]
                    if viewAllCommentsPressed {
                        destination.shouldLaunchKeyboard = false
                        self.viewAllCommentsPressed = false
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
