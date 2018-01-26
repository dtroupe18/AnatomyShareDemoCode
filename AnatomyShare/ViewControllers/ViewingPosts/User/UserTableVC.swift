//
//  UserTableVC.swift
//  AnatomyShare
//
//  Created by Dave on 1/8/18.
//  Copyright © 2018 Dave. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import Kingfisher

class UserTableVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var postKeys = [String]()
    
    // AutoID keys for querying the liked posts
    var likeKeys = [String]()
    
    // AutoID kets for querying commented posts
    var commentKeys = [String]()
    
    var oldestKey: String?
    
    var isLoading: Bool = false
    
    // Boolean Flags for what posts to show
    var showingCommentPosts = false
    var showingLikedPosts = false
    var showingUserPosts = true
    
    var indexToScrollTo: Int!
    var maxScreenSize: CGFloat = 0
    let screenSize: CGRect = UIScreen.main.bounds
    
    // Index for image that was touched to zoom in on
    var selectedRow: Int?
    
    // Flag to determine how to load the comments VC
    var viewAllCommentsPressed = false
    
    var userPostCount: Int?
    var commentCount: Int?
    var likeCount: Int?
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTableView), name: NSNotification.Name(rawValue: "reloadRegionTableView"), object: nil)
    }
    
    @objc private func reloadTableView() {
        self.tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.postKeys.isEmpty {
            return 0
        }
        else {
            var numberOfRows = 0
            for key in self.postKeys {
                if passedData.postDict[key] != nil {
                    numberOfRows += 1
                }
                else {
                    if let index = self.postKeys.index(of: key) {
                        self.postKeys.remove(at: index)
                    }
                }
            }
            return numberOfRows
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "betterPostCell", for: indexPath) as! BetterPostCell
        cell.notHelpfulButton.isHidden = true
        
        let key = self.postKeys[indexPath.row]
        if passedData.postDict[key] != nil {
            if passedData.postDict[key]?.userID == "BLOCKED" {
                return cell
            }
            if passedData.postDict[key]?.pathToImage == postDeletedString {
                cell.configureDeletedPostCell()
                return cell
            }
            
            cell.isUserInteractionEnabled = true
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
            if let userID = passedData.postDict[key]?.userID {
                userImageRef.child("users").child(userID).queryOrderedByKey().observeSingleEvent(of: .value, with: { dataSnapshot in
                    if let pathSnap = dataSnapshot.value as? [String: AnyObject] {
                        if let imagePath = pathSnap["urlToImage"] as? String {
                            let url = URL(string: imagePath)
                            cell.userWhoPostedImageView.kf.setImage(with: url)
                            cell.userWhoPostedImageView.layer.cornerRadius = 6
                            cell.userWhoPostedImageView.clipsToBounds = true
                        }
                    }
                })
            }
            
            // disables the ugly cell highlighting
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.userWhoPostedLabel.attributedText = passedData.postDict[key]?.userWhoPostedLabel
            cell.userWhoPostedLabel.sizeToFit()
            
            if let likes = passedData.postDict[key]!.likes {
                if likes != 1 {
                    cell.helpfulLabel.text = "\(likes) Likes"
                }
                else {
                    cell.helpfulLabel.text = "\(likes) Like"
                }
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
                if indexPath.row + 1 <= self.postKeys.count {
                    self.selectedRow = indexPath.row
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "toEditFromUser", sender: nil)
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
        let key = self.postKeys[indexPath.row]
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
            let key = self.postKeys[indexPath.row]
            if let userToBlock = passedData.postDict[key]?.userID, let name = passedData.postDict[key]?.author, let uid = Auth.auth().currentUser?.uid {
                DatabaseFunctions.blockUser(currentUserUID: uid, blockedUID: userToBlock, blockedName: name, indexPath: indexPath)
            }
        }
        block.backgroundColor = UIColor.red
        return [block]
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 1 >= self.postKeys.count && !self.isLoading {
            if self.showingUserPosts {
                if let count = self.userPostCount, let last = postKeys.last {
                    if self.postKeys.count >= count {
                        return
                    }
                    self.fetchMoreUserPosts(lastVisibleKey: last, { (done) in
                        if done {
                            Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                                self.tableView.reloadData()
                                self.isLoading = false
                            })
                        }
                    })
                }
            }
            else if self.showingLikedPosts {
                if let count = self.likeCount, let last = likeKeys.last {
                    if self.postKeys.count >= count {
                        return
                    }
                    self.fetchMoreLikedPosts(lastVisibleKey: last, { (done) in
                        if done {
                            Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                                self.tableView.reloadData()
                                self.isLoading = false
                            })
                        }
                    })
                }
            }
            else if self.showingCommentPosts {
                if let count = self.commentCount, let last = commentKeys.last {
                    if self.postKeys.count >= count {
                        return
                    }
                    else {
                        self.fetchMoreCommentPosts(lastVisibleKey: last, { (done) in
                            if done {
                                Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                                    self.tableView.reloadData()
                                    self.isLoading = false
                                })
                            }
                        })
                    }
                }
            }
        }
    }
    
    // Paging fetch
    private func fetchMoreUserPosts(lastVisibleKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = postKeys.count
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("userActivity").child(uid).child("posts").queryOrderedByKey().queryEnding(atValue: lastVisibleKey).queryLimited(toLast: 14).observeSingleEvent(of: .value, with: { keySnap in
                for child in keySnap.children {
                    let child = child as? DataSnapshot
                    if let key = child?.key {
                        if self.postKeys.index(of: key) == nil {
                            ref.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                                if !snap.exists() {
                                    // post is no longer up user must have deleted it
                                    // remove it and keep going
                                    UserViewController().removeFromUserPosts(key: key)
                                    DatabaseFunctions.decrementUserActivityCount(countName: "posts")
                                }
                                
                                if let post = snap.value as? [String: Any] {
                                    if let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let numLikes = post["likes"] as? Int, let author = post["author"] as? String {
                                        
                                        let posst = Post()
                                        posst.author = author
                                        posst.pathToImage = pathToImage
                                        posst.postID = postID
                                        posst.userID = userID
                                        posst.fancyPostDescription = Helper.createAttributedString(author: author, postText: postDescription)
                                        posst.postDescription = postDescription
                                        posst.timestamp = timestamp
                                        posst.table = table
                                        posst.region = region
                                        posst.category = category
                                        posst.numberOfComments = numberOfComments
                                        posst.likes = numLikes
                                        posst.userWhoPostedLabel = Helper.createAttributedPostLabel(username: author, table: table, region: region, category: category)
                                        
                                        // Check if the post has two images if it does get the other path
                                        if let originalPath = post["pathToOriginal"] as? String {
                                            posst.pathToOriginal = originalPath
                                        }
                                        
                                        passedData.postDict[postID] = posst
                                        if self.postKeys.index(of: key) == nil {
                                            self.postKeys.insert(key, at: currentNumberOfPosts)
                                        }
                                        self.tableView.reloadData()
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                                    completion(true)
                                })
                            })
                        }
                    }
                }
            })
        }
    }
    
    func fetchMoreLikedPosts(lastVisibleKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = self.postKeys.count
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("userActivity").child(uid).child("likes").queryOrderedByKey().queryEnding(atValue: lastVisibleKey).queryLimited(toLast: 14).observeSingleEvent(of: .value, with: { keySnap in
                for child in keySnap.children {
                    let child = child as? DataSnapshot
                    if let autoID = child?.key {
                        if let likePost = child?.value as? [String: AnyObject] {
                            if let key = likePost["postID"] as? String {
                                if self.postKeys.index(of: key) == nil {
                                    self.likeKeys.insert(autoID, at: currentNumberOfPosts)
                                    ref.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                                        if !snap.exists() {
                                            // post is no longer up user much have deleted it
                                            let posst = Post()
                                            posst.pathToImage = postDeletedString
                                            passedData.postDict[key] = posst
                                            if self.postKeys.index(of: key) == nil {
                                               self.postKeys.insert(key, at: currentNumberOfPosts)
                                            }
                                            self.tableView.reloadData()
                                        }
                                        
                                        if let post = snap.value as? [String: AnyObject] {
                                            if let likes = post["likes"] as? Int, let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let author = post["author"] as? String {
                                                
                                                let posst = Post()
                                                
                                                posst.author = author
                                                posst.pathToImage = pathToImage
                                                posst.postID = postID
                                                posst.userID = userID
                                                posst.fancyPostDescription = Helper.createAttributedString(author: author, postText: postDescription)
                                                posst.postDescription = postDescription
                                                posst.timestamp = timestamp
                                                posst.table = table
                                                posst.region = region
                                                posst.category = category
                                                posst.numberOfComments = numberOfComments
                                                posst.likes = likes
                                                posst.userWhoPostedLabel = Helper.createAttributedPostLabel(username: author, table: table, region: region, category: category)
                                                
                                                // Check if the post has two images if it does get the other path
                                                if let originalPath = post["pathToOriginal"] as? String {
                                                    posst.pathToOriginal = originalPath
                                                }
                                                
                                                passedData.postDict[postID] = posst
                                                if self.postKeys.index(of: key) == nil {
                                                    self.postKeys.insert(key, at: currentNumberOfPosts)
                                                }
                                                self.tableView.reloadData()
                                            }
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                                            completion(true)
                                        })
                                    })
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    private func fetchMoreCommentPosts(lastVisibleKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = self.postKeys.count
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("userActivity").child(uid).child("comments").queryOrderedByKey().queryEnding(atValue: lastVisibleKey).queryLimited(toLast: 13).observeSingleEvent(of: .value, with: { keySnap in
                for child in keySnap.children {
                    let child = child as? DataSnapshot
                    if let commentID = child?.key {
                        if let commentPost = child?.value as? [String: AnyObject] {
                            if let postID = commentPost["postID"] as? String {
                                if self.postKeys.index(of: postID) == nil {
                                    self.commentKeys.insert(commentID, at: currentNumberOfPosts)
                                    
                                    ref.child("posts").child(postID).observeSingleEvent(of: .value, with: { snap in
                                        if !snap.exists() {
                                            // post is no longer up user must have deleted it
                                            let posst = Post()
                                            posst.pathToImage = postDeletedString
                                            passedData.postDict[postID] = posst
                                            if self.postKeys.index(of: postID) == nil {
                                                self.postKeys.insert(postID, at: currentNumberOfPosts)
                                            }
                                            self.tableView.reloadData()
                                        }
                                        if let post = snap.value as? [String: AnyObject] {
                                            if let likes = post["likes"] as? Int, let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let author = post["author"] as? String {
                                                
                                                let posst = Post()
                                                posst.author = author
                                                posst.pathToImage = pathToImage
                                                posst.postID = postID
                                                posst.userID = userID
                                                posst.fancyPostDescription = Helper.createAttributedString(author: author, postText: postDescription)
                                                posst.postDescription = postDescription
                                                posst.timestamp = timestamp
                                                posst.table = table
                                                posst.region = region
                                                posst.category = category
                                                posst.numberOfComments = numberOfComments
                                                posst.likes = likes
                                                posst.userWhoPostedLabel = Helper.createAttributedPostLabel(username: author, table: table, region: region, category: category)
                                                
                                                // Check if the post has two images if it does get the other path
                                                if let originalPath = post["pathToOriginal"] as? String {
                                                    posst.pathToOriginal = originalPath
                                                }
                                                
                                                passedData.postDict[postID] = posst
                                                if self.postKeys.index(of: postID) == nil {
                                                    self.postKeys.insert(postID, at: currentNumberOfPosts)
                                                }
                                                self.tableView.reloadData()
                                            }
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                                            completion(true)
                                        })
                                    })
                                }
                            }
                        }
                    }
                }
            })
        }
    }
    
    // Method to change the post image if there's another image
    @objc func swapCellImage(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: location) {
            let key = self.postKeys[indexPath.row]
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
                    self.performSegue(withIdentifier: "toZoomFromUser", sender: sender)
                }
            }
        }
    }
    
    // View all comments pressed
    @objc func viewAllCommentsButtonPressed(_ sender: UIButton!) {
        viewAllCommentsPressed = true
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toCommentsFromUser", sender: sender)
        }
    }
    
    // Text bubble pressed
    @objc func textBubblePressed(_ sender: UIButton!) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toCommentsFromUser", sender: sender)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toZoomFromUser" {
            if let destination = segue.destination as? ZoomedPhotoViewController {
                if selectedRow != nil {
                    let cell = tableView.cellForRow(at: [0, selectedRow!]) as! BetterPostCell
                    destination.selectedImage = cell.postImage.image
                }
            }
        }
        if segue.identifier == "toEditFromUser" {
            if let destination = segue.destination as? EditPostViewController {
                if let index = selectedRow {
                    let postDraft = PostDraft()
                    postDraft.key = self.postKeys[index]
                    if let post = passedData.postDict[postDraft.key!] {
                        // get images from kingfisher cache
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
                        if let image = ImageCache.default.retrieveImageInDiskCache(forKey: post.pathToImage) {
                            postDraft.annotatedImage = image
                            destination.postDraft = postDraft
                            // print("passing post draft in user table VC")
                        }
                    }
                }
            }
        }
        if segue.identifier == "toCommentsFromUser" {
            if let destination = segue.destination as? CommentsViewController {
                if let button:UIButton = sender as! UIButton? {
                    destination.keyForPostToLoad = self.postKeys[button.tag]
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
