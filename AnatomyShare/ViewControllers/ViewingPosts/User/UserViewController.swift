//
//  UserViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 9/2/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import Kingfisher

class UserViewController: UIViewController, UIImagePickerControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UINavigationControllerDelegate {
    
    // Navigation Button to sign the user out of Firebase
    @IBOutlet weak var signOutButton: UIBarButtonItem!
    
    // Navigation button that blurs all images in the app (required by Apple)
    @IBOutlet weak var filterButton: UIBarButtonItem!
    
    // CollectionView that displays the users posts
    @IBOutlet weak var collectionView: UICollectionView!
    
    // keys to the users actual posts
    var userPostKeys = [String]()
    
    // Keys for the posts a user commented on
    var commentedPostKeys = [String]()
    
    // AutoID kets for querying commented posts
    var commentKeys = [String]()
    
    // keys the posts the user liked
    var likedPostKeys = [String]()
    
    // AutoID keys for querying the liked posts
    var likeKeys = [String]()
    
    // Variables for users information
    var userName: String?
    var uid: String?
    var userImagePath: String?
    var userEmail: String?
    var newPhoto: UIImage?
    
    // HeaderView above the collectionview
    var headerRef: UserHeader!
    
    // Boolean Flags for what posts to show
    var showingCommentPosts = false
    var showingLikedPosts = false
    var showingUserPosts = true
    
    // Stats that will be loaded in for the user
    var userPostCount: Int = 0
    var commentCount: Int = 0
    var likeCount: Int = 0
    var keyToPass: String?
    
    // Pull to refresh
    var refreshControl: UIRefreshControl!
    
    // ImagePicker if the user wants to change their profile picture
    var imagePicker = UIImagePickerController()
    
    
    let screenSize: CGRect = UIScreen.main.bounds
    
    // Firebase storage reference
    var storage: StorageReference!
    
    // Paging Flag
    var isLoading: Bool = false
    
    // Variables to pass to tableview
    var indexToPass: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
        
        self.fetchUserPosts({ (done) in
            if done {
                self.collectionView.reloadData()
                self.isLoading = false
            }
        })
        
        self.getUserImagePath()
        self.getUserActivityCounts()
        
    }
    
    // CollectionView Delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    // Depends on which set of posts we are looking at
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showingUserPosts {
            if self.userPostKeys.isEmpty {
                return 0
            }
            else {
                var numberOfRows = 0
                for key in self.userPostKeys {
                    if passedData.postDict[key] != nil {
                        numberOfRows += 1
                    }
                    else {
                        if let index = self.userPostKeys.index(of: key) {
                            self.userPostKeys.remove(at: index)
                        }
                    }
                }
                return numberOfRows
            }
        }
        else if showingCommentPosts {
            if self.commentedPostKeys.isEmpty {
                return 0
            }
            else {
                var numberOfRows = 0
                for key in self.commentedPostKeys {
                    if passedData.postDict[key] != nil {
                        numberOfRows += 1
                    }
                    else {
                        if let index = self.commentedPostKeys.index(of: key) {
                            // print("removing commented post key for \(key)")
                            self.commentedPostKeys.remove(at: index)
                        }
                    }
                }
                return numberOfRows
            }
        }
        else {
            if self.likedPostKeys.isEmpty {
                return 0
            }
            else {
                var numberOfRows = 0
                for key in self.likedPostKeys {
                    if passedData.postDict[key] != nil {
                        numberOfRows += 1
                    }
                    else {
                        if let index = self.likedPostKeys.index(of: key) {
                            self.likedPostKeys.remove(at: index)
                        }
                    }
                }
                return numberOfRows
            }
        }
    }
    
    // CollectionView Cell Configuration
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if self.showingUserPosts {
            let key = self.userPostKeys[indexPath.row]
            if let post = passedData.postDict[key] {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
                cell.indexPath = indexPath
                let url = URL(string: post.pathToImage)
                cell.imageView.kf.setImage(with: url)
                
                // Check if the filter is on
                let filterOn = UserDefaults.standard.bool(forKey: "FILTER")
                if filterOn {
                    cell.imageView.blurImage()
                }
                else {
                    cell.imageView.removeBlur()
                }
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.black.cgColor
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
                return cell
            }
        }
        else if self.showingCommentPosts && !self.commentedPostKeys.isEmpty {
            let key = self.commentedPostKeys[indexPath.row]
            if let post = passedData.postDict[key] {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
                cell.indexPath = indexPath
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.black.cgColor
                let url = URL(string: post.pathToImage)
                cell.imageView.kf.setImage(with: url)
                let filterOn = UserDefaults.standard.bool(forKey: "FILTER")
                if filterOn {
                    cell.imageView.blurImage()
                }
                else {
                    cell.imageView.removeBlur()
                }
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.black.cgColor
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
                return cell
            }
        }
        else if self.showingLikedPosts && !self.likedPostKeys.isEmpty {
            let key = likedPostKeys[indexPath.row]
            if let post = passedData.postDict[key] {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
                cell.indexPath = indexPath
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.black.cgColor
                let url = URL(string: post.pathToImage)
                cell.imageView.kf.setImage(with: url)
                let filterOn = UserDefaults.standard.bool(forKey: "FILTER")
                if filterOn {
                    cell.imageView.blurImage()
                }
                else {
                    cell.imageView.removeBlur()
                }
                cell.layer.borderWidth = 1
                cell.layer.borderColor = UIColor.black.cgColor
                return cell
            }
            else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
                return cell
            }
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.indexToPass = indexPath.row
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toUserTableView", sender: nil)
        }
    }
    
    // Horizontal Support: Recalculate cell size on orientation change
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard let flow = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        flow.invalidateLayout()
        flow.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        let width = UIScreen.main.bounds.size.width
        flow.itemSize = CGSize(width: width / 3.0, height: width / 3.0)
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
    }
    
    
    //MARK: Paging
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if showingUserPosts && indexPath.row + 1 >= userPostKeys.count && !self.isLoading {
            if self.userPostKeys.count >= self.userPostCount {
                return
            }
            else if let last = self.userPostKeys.last {
                self.fetchMoreUserPosts(lastVisibleKey: last, { (done) in
                    if done {
                        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                            self.collectionView.reloadData()
                            self.isLoading = false
                        })
                    }
                })
            }
        }
        
        if showingLikedPosts && indexPath.row + 1 >= likedPostKeys.count && !self.isLoading {
            if self.likedPostKeys.count >= self.likeCount {
                return
            }
            else if let lastVisibleKey = self.likeKeys.last {
                self.fetchMoreLikedPosts(lastVisibleKey: lastVisibleKey, { (done) in
                    if done {
                        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                            self.collectionView.reloadData()
                            self.isLoading = false
                        })
                    }
                })
            }
            
        }
        else if showingCommentPosts && indexPath.row + 1 >= commentedPostKeys.count && !self.isLoading {
            if commentedPostKeys.count >= self.commentCount {
                return
            }
            else if let last = self.commentKeys.last {
                self.fetchMoreCommentPosts(lastVisibleKey: last, { (done) in
                    if done {
                        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                            self.collectionView.reloadData()
                            self.isLoading = false
                        })
                    }
                })
            }
        }
    }
    
    // MARK: Header
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionElementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "userHeader", for: indexPath) as! UserHeader
            
            if self.userName != nil {
                header.displayName.text = userName
            }
            if self.userImagePath != nil {
                let url = URL(string: userImagePath!)
                header.image.kf.setImage(with: url)
            }
            
            for  subView in header.email.subviews {
                if let label = subView as? UILabel {
                    label.minimumScaleFactor = 0.3
                    label.adjustsFontSizeToFitWidth = true
                }
            }
            
            if self.showingUserPosts {
                header.postsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            }
            
            header.image.layer.borderWidth = 1.0
            header.image.layer.masksToBounds = false
            header.image.layer.cornerRadius = header.image.frame.size.width / 2.0
            header.image.clipsToBounds = true
            header.editButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
            header.changeImageButton.layer.borderWidth = 0.7
            header.changeImageButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15.0)
            header.changeImageButton.layer.borderColor = UIColor.lightGray.cgColor
            header.changeImageButton.layer.cornerRadius = 4
            
            if userEmail != nil {
                header.email.text = userEmail!
            }
            
            if passedData.blockedUsers.count == 0 {
                header.blockedButton.isHidden = true
            }
            else {
                header.blockedButton.isHidden = false
            }
            
            header.blockedButtonAction = {(UserHeader) in
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "toBlocked", sender: nil)
                }
            }
            
            header.changePhotoAction = { (UserHeader) in
                self.imagePicker.allowsEditing = true
                self.imagePicker.sourceType = .photoLibrary
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    self.imagePicker.modalPresentationStyle = .popover
                    
                    if self.imagePicker.popoverPresentationController != nil {
                        self.imagePicker.popoverPresentationController!.delegate = self as? UIPopoverPresentationControllerDelegate
                        self.imagePicker.popoverPresentationController!.sourceView =  header.changeImageButton
                        
                        let xLocation = (self.screenSize.width / 100) * 15
                        let yLocation = (self.screenSize.height / 2)
                        self.imagePicker.popoverPresentationController?.sourceRect = CGRect(x: xLocation, y: yLocation, width: 0, height: 0)
                    }
                }
                DispatchQueue.main.async {
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
            }
            header.selectCommentsAction = { (UserHeader) in
                header.commentsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                header.likesButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
                header.postsButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
                self.showingCommentPosts = true
                self.showingUserPosts = false
                self.showingLikedPosts = false
                self.fetchCommentedPosts({ (done) in
                    if done {
                        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                            self.collectionView.reloadData()
                            self.isLoading = false
                        })
                    }
                })
            }
            
            header.selectPostsAction = { (UserHeader) in
                header.postsButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                header.commentsButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
                header.likesButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
                self.showingUserPosts = true
                self.showingCommentPosts = false
                self.showingLikedPosts = false
                self.collectionView.reloadData()
            }
            // QWE HEADER ACTIONS
            header.selectLikesAction = { (UserHeader) in
                header.likesButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
                header.postsButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
                header.commentsButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
                self.showingLikedPosts = true
                self.showingUserPosts = false
                self.showingCommentPosts = false
                self.fetchLikedPosts( { (done) in
                    if done {
                        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                            self.collectionView.reloadData()
                            self.isLoading = false
                        })
                    }
                })
            }
            
            headerRef = header
            return header
        }
            
        else {
            assert(false, "Unexpected element kind")
            return UICollectionReusableView()
        }
    }
    
    // MARK: ImagePicker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
            self.newPhoto = image
            uploadNewImage()
        }
        else {
            print("Error with image picker")
        }
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true)
        }
    }
    
    // MARK: Database Functions
    private func fetchUserPosts(_ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        if !self.userPostKeys.isEmpty {
            self.userPostKeys.removeAll()
            self.collectionView.reloadData()
        }
        
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("userActivity").child(uid).child("posts").queryLimited(toLast: 13).observeSingleEvent(of: .value, with: { snap in
                if !snap.exists() {
                    // no posts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                        completion(true)
                    })
                }
                for child in snap.children {
                    let child = child as? DataSnapshot
                    if let key = child?.key {
                        ref.child("posts").child(key).observeSingleEvent(of: .value, with: { postSnap in
                            if !postSnap.exists() {
                                // post is no longer up user must have deleted it
                                // remove it and keep going
                                self.removeFromUserPosts(key: key)
                                DatabaseFunctions.decrementUserActivityCount(countName: "posts")
                            }
                            
                            if let post = postSnap.value as? [String: Any] {
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
                                    if self.userPostKeys.index(of: postID) == nil {
                                        self.userPostKeys.insert(postID, at: 0)
                                    }
                                    self.collectionView.reloadData()
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                                completion(true)
                            })
                        })
                    }
                }
            })
        }
    }
    
    private func fetchMoreUserPosts(lastVisibleKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = self.userPostKeys.count
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("userActivity").child(uid).child("posts").queryOrderedByKey().queryEnding(atValue: lastVisibleKey).queryLimited(toLast: 14).observeSingleEvent(of: .value, with: { keySnap in
                for child in keySnap.children {
                    let child = child as? DataSnapshot
                    if let key = child?.key {
                        if self.userPostKeys.index(of: key) == nil {
                            ref.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                                if !snap.exists() {
                                    // post is no longer up user must have deleted it
                                    // remove it and keep going
                                    self.removeFromUserPosts(key: key)
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
                                        if self.userPostKeys.index(of: key) == nil {
                                            self.userPostKeys.insert(key, at: currentNumberOfPosts)
                                        }
                                        self.collectionView.reloadData()
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
    
    private func fetchLikedPosts(_ completion: @escaping (Bool) -> ()) {
        // get the key for every post a user has liked on from
        // userActivity -> uid -> likes -> AutoID -> "postID": keyForLikedPost
        self.isLoading = true
        if !self.likedPostKeys.isEmpty {
            self.likedPostKeys.removeAll()
            self.likeKeys.removeAll()
            self.collectionView.reloadData()
        }
        
        let ref = Database.database().reference()
        if let uid = Auth.auth().currentUser?.uid {
            ref.child("userActivity").child(uid).child("likes").queryOrderedByKey().queryLimited(toLast: 13).observeSingleEvent(of: .value, with: { keySnap in
                if !keySnap.exists() {
                    // no posts were liked
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                        completion(true)
                    })
                }
                for child in keySnap.children {
                    let child = child as? DataSnapshot
                    if let autoID = child?.key {
                        if let likePost = child?.value as? [String: AnyObject] {
                            if let key = likePost["postID"] as? String {
                                self.likeKeys.insert(autoID, at: 0)
                                // use that key to get the post
                                ref.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                                    if !snap.exists() {
                                        // post is no longer up user much have deleted it
                                        let posst = Post()
                                        posst.pathToImage = postDeletedString
                                        passedData.postDict[key] = posst
                                        if self.likedPostKeys.index(of: key) == nil {
                                            self.likedPostKeys.insert(key, at: 0)
                                        }
                                        self.collectionView.reloadData()
                                        
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
                                            if self.likedPostKeys.index(of: key) == nil {
                                                self.likedPostKeys.insert(key, at: 0)
                                            }
                                            self.collectionView.reloadData()
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
            })
        }
    }
    
    func fetchMoreLikedPosts(lastVisibleKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = self.likedPostKeys.count
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("userActivity").child(uid).child("likes").queryOrderedByKey().queryEnding(atValue: lastVisibleKey).queryLimited(toLast: 14).observeSingleEvent(of: .value, with: { keySnap in
                for child in keySnap.children {
                    let child = child as? DataSnapshot
                    if let autoID = child?.key {
                        if let likePost = child?.value as? [String: AnyObject] {
                            if let key = likePost["postID"] as? String {
                                if self.likedPostKeys.index(of: key) == nil {
                                    self.likeKeys.insert(autoID, at: currentNumberOfPosts)
                                    ref.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                                        if !snap.exists() {
                                            // post is no longer up user much have deleted it
                                            let posst = Post()
                                            posst.pathToImage = postDeletedString
                                            passedData.postDict[key] = posst
                                            if self.likedPostKeys.index(of: key) == nil {
                                                self.likedPostKeys.insert(key, at: currentNumberOfPosts)
                                            }
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
                                                if self.likedPostKeys.index(of: key) == nil {
                                                    self.likedPostKeys.insert(key, at: currentNumberOfPosts)
                                                }
                                                self.collectionView.reloadData()
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
    
    private func fetchCommentedPosts(_ completion: @escaping (Bool) -> ()) {
        // get the key for every post a user has commented on from
        // userActivity -> uid -> comments -> commentID -> "postID": key for post
        // posts with multiple comments are only loaded once
        self.isLoading = true
        if !self.commentedPostKeys.isEmpty {
            self.commentedPostKeys.removeAll()
            self.commentKeys.removeAll()
            self.collectionView.reloadData()
        }
        
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("userActivity").child(uid).child("comments").queryOrderedByKey().queryLimited(toLast: 13).observeSingleEvent(of: .value, with: { keySnap in
                if !keySnap.exists() {
                    // no posts were commented on
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                        completion(true)
                    })
                }
                for child in keySnap.children {
                    let child = child as? DataSnapshot
                    if let commentID = child?.key {
                        if let commentPost = child?.value as? [String: AnyObject] {
                            if let postID = commentPost["postID"] as? String {
                                self.commentKeys.insert(commentID, at: 0)
                                // use that key to get the post
                                ref.child("posts").child(postID).observeSingleEvent(of: .value, with: { snap in
                                    if !snap.exists() {
                                        // post is no longer up user much have deleted it
                                        let posst = Post()
                                        posst.pathToImage = postDeletedString
                                        passedData.postDict[postID] = posst
                                        if self.commentedPostKeys.index(of: postID) == nil {
                                            self.commentedPostKeys.insert(postID, at: 0)
                                        }
                                        self.collectionView.reloadData()
                                    }
                                    else if let post = snap.value as? [String: AnyObject] {
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
                                            if self.commentedPostKeys.index(of: postID) == nil {
                                                self.commentedPostKeys.insert(postID, at: 0)
                                            }
                                            self.collectionView.reloadData()
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
            })
        }
    }
    
    private func fetchMoreCommentPosts(lastVisibleKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = self.commentedPostKeys.count
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("userActivity").child(uid).child("comments").queryOrderedByKey().queryEnding(atValue: lastVisibleKey).queryLimited(toLast: 13).observeSingleEvent(of: .value, with: { keySnap in
                for child in keySnap.children {
                    let child = child as? DataSnapshot
                    if let commentID = child?.key {
                        if let commentPost = child?.value as? [String: AnyObject] {
                            if let postID = commentPost["postID"] as? String {
                                if self.commentedPostKeys.index(of: postID) == nil {
                                    self.commentKeys.insert(commentID, at: currentNumberOfPosts)
                                    
                                    ref.child("posts").child(postID).observeSingleEvent(of: .value, with: { snap in
                                        if !snap.exists() {
                                            // post is no longer up user must have deleted it
                                            let posst = Post()
                                            posst.pathToImage = postDeletedString
                                            passedData.postDict[postID] = posst
                                            if self.commentedPostKeys.index(of: postID) == nil {
                                                self.commentedPostKeys.insert(postID, at: currentNumberOfPosts)
                                            }
                                            self.collectionView.reloadData()
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
                                                if self.commentedPostKeys.index(of: postID) == nil {
                                                    self.commentedPostKeys.insert(postID, at: currentNumberOfPosts)
                                                }
                                                self.collectionView.reloadData()
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
    
    private func uploadNewImage() {
        CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)
        if newPhoto != nil {
            let key = Database.database().reference().child("posts").childByAutoId()
            let imageRef = self.storage.child("\(key).jpg")
            
            if let imageData = UIImageJPEGRepresentation(newPhoto!, 0.5) {
                let uploadTask = imageRef.putData(imageData, metadata: nil, completion: { (metadata, error) in
                    if error != nil {
                        CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                        if let topController = UIApplication.topViewController() {
                            Helper.showAlertMessage(vc: topController, title: "Error", message: error!.localizedDescription)
                        }
                        return
                    }
                    imageRef.downloadURL(completion: { (url, err) in
                        if err != nil {
                            CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                            if let topController = UIApplication.topViewController() {
                                Helper.showAlertMessage(vc: topController, title: "Error", message: err!.localizedDescription)
                            }
                            return
                        }
                        if let url = url {
                            let newPhotoPath = url.absoluteString
                            if let uid = Auth.auth().currentUser?.uid {
                                let ref = Database.database().reference()
                                ref.child("users").child(uid).child("urlToImage").setValue(newPhotoPath, withCompletionBlock: { (e, success) in
                                    if e != nil {
                                        CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                        if let topController = UIApplication.topViewController() {
                                            Helper.showAlertMessage(vc: topController, title: "Error", message: e!.localizedDescription)
                                        }
                                        return
                                    }
                                    self.userImagePath = url.absoluteString
                                    self.collectionView.reloadData()
                                    CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                })
                            }
                        }
                    })
                })
                uploadTask.resume()
            }
        }
    }
    
    private func getUserActivityCounts() {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("userActivity").child(uid).child("counts").observeSingleEvent(of: .value, with: { snap in
                if !snap.exists() {
                    // create user counts
                    if let uid = Auth.auth().currentUser?.uid {
                        DatabaseFunctions.createUserActivityCounts(uid: uid)
                    }
                }
                if let counts = snap.value as? [String: Any] {
                    if let numberOfLikes = counts["likes"] as? Int, let commentCount = counts["comments"] as? Int, let postCount = counts["posts"] as? Int {
                        DispatchQueue.main.async {
                            self.headerRef.postCount.text = String(postCount)
                            self.headerRef.commentCount.text = String(commentCount)
                            self.headerRef.likeCount.text = String(numberOfLikes)
                            self.collectionView.reloadData()
                        }
                        self.userPostCount = postCount
                        self.commentCount = commentCount
                        self.likeCount = numberOfLikes
                    }
                }
            })
        }
    }
        
    private func getUserImagePath() {
        guard let userID = Auth.auth().currentUser?.uid  else { return }
        let ref = Database.database().reference()
        ref.child("users").child(userID).observeSingleEvent(of: .value, with: { snap in
            if let userInfo = snap.value as? [String: Any] {
                if let imagePath = userInfo["urlToImage"] {
                    self.userImagePath = imagePath as? String
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        })
    }
    
    @objc func refresh() {
        if !self.isLoading {
            // print("not loading...")
            if self.showingUserPosts {
                // print("showing user posts...")
                self.fetchUserPosts({ (done) in
                    // print("done....")
                    if done {
                        self.collectionView.reloadData()
                        self.refreshControl.endRefreshing()
                        self.isLoading = false
                    }
                })
            }
            else if self.showingLikedPosts {
                self.fetchLikedPosts({ (done) in
                    if done {
                        self.collectionView.reloadData()
                        self.refreshControl.endRefreshing()
                        self.isLoading = false
                    }
                })
            }
            else if self.showingCommentPosts {
                self.fetchCommentedPosts({ (done) in
                    if done {
                        self.collectionView.reloadData()
                        self.refreshControl.endRefreshing()
                        self.isLoading = false
                    }
                })
            }
        }
        else {
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
        }
        self.getUserActivityCounts()
    }
    
    
    //MARK: Other Functions
    @objc func reloadTitle() {
        if passedData.newUsername != nil {
            navigationItem.title = passedData.newUsername!
            userName = passedData.newUsername!
            passedData.newUsername = nil
        }
    }
    
    @IBAction func signOutPressed(_ sender: Any) {
        // sign out the current user and segue back to sign in vc
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NavigationController")
                self.present(vc, animated: true, completion: nil)
            }
        }
        catch let error as NSError {
            if let topController = UIApplication.topViewController() {
                Helper.showAlertMessage(vc: topController, title: "Sign out error", message: error.localizedDescription)
            }
        }
    }
    
    @IBAction func filterPressed(_ sender: Any) {
        let filterOn: Bool = UserDefaults.standard.bool(forKey: "FILTER")
        if filterOn {
            UserDefaults.standard.set(false, forKey: "FILTER")
            filterButton.title = "Filter Off"
            Helper.reloadEverything()
        }
        else {
            UserDefaults.standard.set(true, forKey: "FILTER")
            filterButton.title = "Filter On"
            Helper.reloadEverything()
        }
    }
    
    private func updateImageviewImage() {
        if newPhoto != nil {
            DispatchQueue.main.async {
                self.headerRef.image.image = self.newPhoto!
                self.collectionView.reloadData()
            }
        }
    }
    
    @objc func reloadCollectionView() {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
        }
    }
    
    private func initialize() {
        if !passedData.isDebug {
            storage = Storage.storage().reference(forURL: "gs://anatomyshare-b9fbc.appspot.com")
        }
        else if passedData.isDebug {
            storage = Storage.storage().reference(forURL: "gs://anatomysharedevelopment.appspot.com")
        }
        
        storage = storage.child("profilePics")
        imagePicker.delegate = self
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTitle), name: NSNotification.Name(rawValue: "updateUserNavTitle"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCollectionView), name: NSNotification.Name(rawValue: "reloadUserCollectionView"), object: nil)
        
        
        if let displayName = Auth.auth().currentUser?.displayName {
            navigationItem.title = displayName
            userName = displayName
        }
        else {
            navigationItem.title = "My Profile"
        }
        
        if let id = Auth.auth().currentUser?.uid {
            uid = id
        }
        
        if let email = Auth.auth().currentUser?.email {
            self.userEmail = email
        }
        
        let flow = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flow.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        let width = UIScreen.main.bounds.size.width
        flow.itemSize = CGSize(width: width / 3.0, height: width / 3.0)
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        
        self.extendedLayoutIncludesOpaqueBars = false
        // INSET self.automaticallyAdjustsScrollViewInsets = false
        self.hideKeyboardWhenTappedAround()
        
        collectionView.alwaysBounceVertical = true // so you can pulldown when there aren't enough posts
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "") // no title
        refreshControl.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)
        collectionView.addSubview(refreshControl)
        
        showingCommentPosts = false
        showingLikedPosts = false
        showingUserPosts = true
    }
    
    //Marker: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toUserTableView" {
            if let destination = segue.destination as? UserTableVC {
                if self.showingUserPosts {
                    destination.postKeys = self.userPostKeys
                    destination.userPostCount = self.userPostCount
                }
                else if self.showingLikedPosts {
                    destination.postKeys = self.likedPostKeys
                    destination.likeCount = self.likeCount
                    destination.likeKeys = self.likeKeys
                }
                else if self.showingCommentPosts {
                    destination.postKeys = self.commentedPostKeys
                    destination.commentCount = self.commentCount
                    destination.commentKeys = self.commentKeys
                }
                destination.indexToScrollTo = self.indexToPass
                destination.showingUserPosts = self.showingUserPosts
                destination.showingCommentPosts = self.showingCommentPosts
                destination.showingLikedPosts = self.showingLikedPosts
            }
        }
    }
    
    func removeFromUserPosts(key: String) {
        DispatchQueue.global(qos: .background).async {
            let activityRef = Database.database().reference()
            if let uid = Auth.auth().currentUser?.uid {
                activityRef.child("userActivity").child(uid).child("posts").child(key).removeValue()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
