//
//  NewsFeedViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 6/8/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseAuth
import Kingfisher

class NewsFeedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    // Pull to refresth
    var refreshControl: UIRefreshControl!
    
    // used to determine the size of a cell items
    let screenSize: CGRect = UIScreen.main.bounds
    
    // Variables that are passed in segues
    var selectedRow: Int?
    var selectedIndexPath: IndexPath?
    
    // Flag for which comment button was pressed
    var viewAllCommentsPressed = false
    
    // Keys to all of the newest posts
    var newsfeedKeys = [String]()
    
    // Flag to track when Firebase has been queried for more posts
    var isLoading: Bool = false
    
    // Oldest post key, used to determine when all posts have been loaded
    var oldestPostKey: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fetchOldestPostKey()
        view.accessibilityIdentifier = "Newsfeed"
        // Load initial posts
        self.fetchInitialPosts({ success in
            if success {
                self.tableView.reloadData()
                self.isLoading = false
            }
        })
        
        // Notification to reload the tableview, such as when the filter is activated
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTableView), name: NSNotification.Name(rawValue: "reloadNewsFeedTableView"), object: nil)
        
        // Notifcation to actually reload the visible posts from Firebase (update local storage of data)
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: NSNotification.Name(rawValue: "refreshNewsfeed"), object: nil)
        
        // Setup pull to refresh
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "") // no title
        refreshControl.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)
        tableView.addSubview(refreshControl)
    }
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if newsfeedKeys.isEmpty {
            return 0
        }
        else {
            var numberOfRows = 0
            for key in self.newsfeedKeys {
                if passedData.postDict[key] != nil {
                    numberOfRows += 1
                }
                else {
                    if let index = self.newsfeedKeys.index(of: key) {
                        self.newsfeedKeys.remove(at: index)
                    }
                }
            }
            return numberOfRows
        }
    }
    
    // Enables swipe to edit action on rows
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Blocking a user is the cell action
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let block = UITableViewRowAction(style: .normal, title: "Block User") { action, index in
            let key = self.newsfeedKeys[indexPath.row]
            if let userToBlock = passedData.postDict[key]?.userID, let name = passedData.postDict[key]?.author, let uid = Auth.auth().currentUser?.uid {
                DatabaseFunctions.blockUser(currentUserUID: uid, blockedUID: userToBlock, blockedName: name, indexPath: indexPath)
            }
        }
        block.backgroundColor = UIColor.red
        return [block]
    }
    
    // Configuring a cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "betterPostCell", for: indexPath) as! BetterPostCell
        cell.notHelpfulButton.isHidden = true
        
        let key = newsfeedKeys[indexPath.row]
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
            if (passedData.postDict[key]!.postDescription.height(withConstrainedWidth: screenSize.width * 0.7, font: UIFont.systemFont(ofSize: UIFont.systemFontSize))) > cell.postDescription.frame.height && !cell.isExpanded {
                cell.moreButton.isHidden = false
            }
            else {
                // otherwise a resued cell will have the more button
                cell.moreButton.isHidden = true
            }
            
            // comment button
            cell.textbubbleButton.tag = indexPath.row
            cell.textbubbleButton.addTarget(self, action: #selector(NewsFeedViewController.textBubblePressed(_:)), for: UIControlEvents.touchUpInside)
            
            // view all comments button
            cell.numberOfCommentsButton.tag = indexPath.row
            cell.numberOfCommentsButton.addTarget(self, action: #selector(NewsFeedViewController.viewAllCommentsButtonPressed(_:)), for: UIControlEvents.touchUpInside)
            
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
                if indexPath.row + 1 <= self.newsfeedKeys.count {
                    self.selectedRow = indexPath.row
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "toEdit", sender: nil)
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let key = newsfeedKeys[indexPath.row]
        // Used to determine the height of a cell
        let maxScreenSize = UIScreen.main.bounds.height > UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        
        if passedData.postDict[key] != nil && passedData.postDict[key]!.isExpanded {
            let sysFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
            let labelHeight = passedData.postDict[key]!.postDescription!.height(withConstrainedWidth: screenSize.width * 0.8, font: sysFont)
            return maxScreenSize + labelHeight - 100
        }
        else {
            return maxScreenSize - 100
        }
    }
    
    @objc func textBubblePressed(_ sender: UIButton!) {
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toComments", sender: sender)
        }
    }
    
    @objc func viewAllCommentsButtonPressed(_ sender: UIButton!) {
        viewAllCommentsPressed = true
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toComments", sender: sender)
        }
    }
    
    
    @IBAction func plusPressed(_ sender: Any) {
        DispatchQueue.main.async{
            let storyboard: UIStoryboard = UIStoryboard(name: "CreatePost", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CameraViewController")
            self.show(vc, sender: self)
        }
    }
    
    
    // MARKER: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toComments" {
            if let destination = segue.destination as? CommentsViewController {
                if let button:UIButton = sender as! UIButton? {
                    destination.keyForPostToLoad = newsfeedKeys[button.tag]
                    if viewAllCommentsPressed {
                        destination.shouldLaunchKeyboard = false
                        viewAllCommentsPressed = false
                    }
                }
            }
        }
        if segue.identifier == "toScrollView" {
            if let destination = segue.destination as? ZoomedPhotoViewController {
                if selectedRow != nil {
                    let cell = tableView.cellForRow(at: [0, selectedRow!]) as! BetterPostCell
                    destination.selectedImage = cell.postImage.image
                }
            }
        }
        if segue.identifier == "toEdit" {
            if let destination = segue.destination as? EditPostViewController {
                if let index = selectedRow {
                    let postDraft = PostDraft()
                    postDraft.key = self.newsfeedKeys[index]
                    if let post = passedData.postDict[postDraft.key!] {
                        postDraft.table = post.table
                        postDraft.category = post.category
                        postDraft.region = post.region
                        postDraft.text = post.postDescription
                        if let originalPath = post.pathToOriginal {
                            let url = URL(string: originalPath)
                            // this image is most likely not on the cache
                            // so we will just save the url to the post draft
                            // and if the user wants to edit the image we will download it
                            postDraft.originalImageURL = url
                        }
                        // get images from kingfisher cache
                        if let image = ImageCache.default.retrieveImageInDiskCache(forKey: post.pathToImage) {
                            postDraft.annotatedImage = image
                            destination.postDraft = postDraft
                            // print("passing post draft in newsfeed")
                        }
                    }
                }
            }
        }
    }
    
    // Method to change the post image if there's another image
    @objc func swapCellImage(recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: self.tableView)
        if let indexPath = self.tableView.indexPathForRow(at: location) {
            let key = self.newsfeedKeys[indexPath.row]
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
                    self.performSegue(withIdentifier: "toScrollView", sender: sender)
                }
            }
        }
    }
    
    // Pagination Caller
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row + 2 > self.newsfeedKeys.count && !self.isLoading {
            if let oldest = self.oldestPostKey, let last = self.newsfeedKeys.last {
                if last != oldest {
                    self.isLoading = true
                    self.fetchMorePosts(lastVisiblePostKey: last, { (done) in
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
    
    // Marker: Database functions to fetch posts
    func fetchInitialPosts(_ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        // check if there are existing posts and remove them if needed
        if !self.newsfeedKeys.isEmpty {
            self.newsfeedKeys.removeAll()
            self.tableView.reloadData()
        }
        
        let ref = Database.database().reference()
        ref.child("posts").queryLimited(toLast: 7).observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    if let post = child?.value as? [String: AnyObject] {
                        if let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let numLikes = post["likes"] as? Int, let author = post["author"] as? String {
                            
                            if passedData.blockedUsers[userID] == nil {
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
                                if self.newsfeedKeys.index(of: key) == nil {
                                    self.newsfeedKeys.insert(key, at: 0)
                                }
                                self.tableView.reloadData()
                            }
                        } // end if let
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                completion(true)
            })
        })
    }
    
    // Paging fetch
    func fetchMorePosts(lastVisiblePostKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = self.newsfeedKeys.count
        let ref = Database.database().reference()
        ref.child("posts").queryOrderedByKey().queryEnding(atValue: lastVisiblePostKey).queryLimited(toLast: 8).observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    if self.newsfeedKeys.index(of: key) == nil {
                        if let post = child?.value as? [String: AnyObject] {
                            if let likes = post["likes"] as? Int, let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let author = post["author"] as? String {
                                
                                
                                if passedData.blockedUsers[userID] == nil {
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
                                    if self.newsfeedKeys.index(of: postID) == nil {
                                        self.newsfeedKeys.insert(postID, at: currentNumberOfPosts)
                                    }
                                    self.tableView.reloadData()
                                }
                            } // end if let
                        }
                    }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                completion(true)
            })
        })
    }
    
    @objc func refresh(sender:AnyObject) {
        if !self.isLoading {
            self.fetchInitialPosts({ (done) in
                if done {
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                    self.isLoading = false
                }
            })
        }
    }
    
    @objc func reloadTableView() {
        self.tableView.reloadData()
    }
    
    func fetchOldestPostKey() {
        let databaseReference = Database.database().reference()
        databaseReference.child("posts").queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { snap in
            if let postSnap = snap.value as? [String: AnyObject] {
                for(_, post) in postSnap {
                    if let oldestKey = post["postID"] as? String {
                        self.oldestPostKey = oldestKey
                    }
                }
            }
        })
    }
}




































