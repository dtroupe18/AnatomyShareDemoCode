//
//  CommentsViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 7/9/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class CommentsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {
    
    let screenSize: CGRect = UIScreen.main.bounds
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var postCommentTextView: UITextView!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var bottomView: UIView!
    
    var keyForPostToLoad: String?
    let ref = Database.database().reference()
    let userImageRef = Database.database().reference()
    var comments = [Comment]()
    var shouldLaunchKeyboard = true
    
    override func viewDidLoad() {
        self.edgesForExtendedLayout = UIRectEdge()
        self.extendedLayoutIncludesOpaqueBars = false
        // INSET self.automaticallyAdjustsScrollViewInsets = false
        
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 100; // Default Size
        
        if shouldLaunchKeyboard {
            postCommentTextView.becomeFirstResponder()
        }
        
        fetchCommentsByChild()
        
        // styling
        postCommentTextView.layer.borderWidth = 1
        postCommentTextView.layer.borderColor = UIColor.gray.cgColor
        postCommentTextView.layer.cornerRadius = 8
        
        postButton.layer.borderWidth = 1
        postButton.layer.borderColor = UIColor.gray.cgColor
        postButton.layer.cornerRadius = 4
        super.viewDidLoad()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return comments.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if postCommentTextView.isFirstResponder {
            postCommentTextView.resignFirstResponder()
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == 0 {
            return false
        }
        else {
            if let uid = Auth.auth().currentUser?.uid {
                if uid == comments[indexPath.row - 1].userID {
                    return true
                }
                else {
                    return false
                }
            }
            return false
        }
    }
    
    

    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteComment(commentKey: comments[indexPath.row - 1].key, indexPath: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if keyForPostToLoad != nil {
            if let post = passedData.postDict[keyForPostToLoad!] {
                // first cell is a summary of the post your commenting on
                if indexPath.row == 0 {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "postSummaryCell") as! PostSummaryCell
                    let url = URL(string: post.pathToImage)
                    cell.postImage.kf.setImage(with: url, options: [.transition(.fade(0.2))])
                    cell.postTextLabel.attributedText = post.fancyPostDescription
                    cell.selectionStyle = UITableViewCellSelectionStyle.none
                    cell.layoutIfNeeded()
                    return cell
                }
                // every other cell is a comment cell
                else {
                    let cell = tableView.dequeueReusableCell(withIdentifier: "commentCell") as! CommentCell
                    userImageRef.child("users").child(comments[indexPath.row - 1].userID).queryOrderedByKey().observeSingleEvent(of: .value, with: { dataSnapshot in
                        if let pathSnap = dataSnapshot.value as? [String: AnyObject] {
                            if let imagePath = pathSnap["urlToImage"] as? String, let author = pathSnap["displayName"] as? String {
                                let url = URL(string: imagePath)
                                cell.userImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
                                cell.commentTextLabel.attributedText = Helper.createAttributedString(author: author, postText: self.comments[indexPath.row - 1].text)
                                cell.userImageView.layer.borderWidth = 1.0
                                cell.userImageView.layer.masksToBounds = false
                                cell.userImageView.layer.cornerRadius = cell.userImageView.frame.size.width / 2.0
                                cell.userImageView.clipsToBounds = true
                            }
                        }
                    })
                    
                    cell.selectionStyle = UITableViewCellSelectionStyle.none
                    cell.timestampLabel.text = Helper.convertTimestamp(serverTimestamp: comments[indexPath.row - 1].timestamp)
                    cell.layoutIfNeeded()
                    return cell
                }
            }
            else {
                return UITableViewCell()
            }
        }
        else {
            return UITableViewCell()
        }
    }
    
    @IBAction func postButtonPressed(_ sender: Any) {
        // upload the new comment
        if postCommentTextView.text != "" && keyForPostToLoad != nil {
            postButton.isEnabled = false
            CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)
            
            if let postID = passedData.postDict[keyForPostToLoad!]?.postID, let uid = Auth.auth().currentUser?.uid {
                
                let key = ref.child("comments").child(postID).childByAutoId().key
                let comment = ["uid": uid,
                               "timestamp": [".sv": "timestamp"],
                               "postID": postID,
                               "text": self.postCommentTextView.text!.trailingTrim(.whitespacesAndNewlines)] as [String : Any]
                
                let commentFeed = ["\(key)" : comment]
                
                // upload comment
                ref.child("comments").child(postID).updateChildValues(commentFeed, withCompletionBlock: { (error, success) in
                    if error != nil {
                        if let topController = UIApplication.topViewController() {
                            Helper.showAlertMessage(vc: topController, title: "Error", message: error!.localizedDescription)
                        }
                        return
                    }
                        // comment uploaded successfully
                    else {
                        self.addToUserActivity(commentKey: key)
                        DatabaseFunctions.incrementUserActivityCount(countName: "comments")
                        // increment the number of comments
                        self.ref.child("posts").child(postID).runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                            if var data = currentData.value as? [String: Any] {
                                var count = data["numberOfComments"] as! Int
                                count += 1
                                data["numberOfComments"] = count
                                currentData.value = data
                                return TransactionResult.success(withValue: currentData)
                            }
                            return TransactionResult.success(withValue: currentData)
                        }
                    }
                })
                // get serverTimeStamp
                ref.child("comments").child(postID).child(key).observeSingleEvent(of: .value, with: {
                    snap in
                    if let commentSnap = snap.value as? [String: AnyObject] {
                        if let timestamp = commentSnap["timestamp"] as? Double, let text = commentSnap["text"] as? String {
                            
                            let newComment = Comment()
                            newComment.userID = uid
                            newComment.timestamp = timestamp
                            newComment.text = text
                            newComment.key = key
                            self.comments.append(newComment)
                            self.tableView.reloadData()
                        }
                    }
                })
                ref.removeAllObservers()
            }
            updateCommentCount(postKey: keyForPostToLoad!, increment: true)
            CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
            postCommentTextView.text = ""
            postButton.isEnabled = true
        }
            
        else {
            if let topController = UIApplication.topViewController() {
                Helper.showAlertMessage(vc: topController, title: "Error", message: "Your comment must contain text!")
            }
            return
        }
        
    }
    
    func fetchCommentsByChild() {
        var commentCount = 0
        if keyForPostToLoad != nil {
            self.ref.child("comments").child(keyForPostToLoad!).queryOrderedByKey().observeSingleEvent(of: .value, with: {
                snapshot in
                for child in snapshot.children {
                    let child = child as? DataSnapshot
                    let key = child?.key
                    if let comment = child?.value as? [String: AnyObject] {
                        let com = Comment()
                        commentCount += 1
                        if let userID = comment["uid"] as? String, let text = comment["text"] as? String, let timestamp = comment["timestamp"] as? Double {
                            
                            // com.author = author
                            com.text = text
                            com.timestamp = timestamp
                            com.userID = userID
                            com.key = key
                            
                            self.comments.append(com)
                            passedData.postDict[self.keyForPostToLoad!]!.numberOfComments = commentCount
                        } // end if let
                        self.tableView.reloadData()
                    }
                }
            })
        }
    }
    
    private func deleteComment(commentKey: String, indexPath: IndexPath) {
        if keyForPostToLoad != nil {
            CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)
            // check that value exists first
            ref.child("comments").child(self.keyForPostToLoad!).child(commentKey).observeSingleEvent(of: .value, with: { snapshot in
                if snapshot.exists() {
                    self.ref.child("comments").child(self.keyForPostToLoad!).child(commentKey).removeValue(completionBlock: { (error, success) in
                        if error != nil {
                            CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                            if let topController = UIApplication.topViewController() {
                                Helper.showAlertMessage(vc: topController, title: "Error", message: error!.localizedDescription)
                            }
                            return
                        }
                            // sucessfully deleted the comment
                        else {
                            self.removeFromUserActivity(commentKey: commentKey)
                            DatabaseFunctions.decrementUserActivityCount(countName: "comments")
                            // decrement comment count
                            self.ref.child("posts").child(self.keyForPostToLoad!).runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                                if var data = currentData.value as? [String: Any] {
                                    var count = data["numberOfComments"] as! Int
                                    count -= 1
                                    data["numberOfComments"] = count
                                    currentData.value = data
                                    return TransactionResult.success(withValue: currentData)
                                }
                                return TransactionResult.success(withValue: currentData)
                            }
                        }
                    })
                    self.updateCommentCount(postKey: self.keyForPostToLoad!, increment: false)
                    self.comments.remove(at: indexPath.row - 1)
                    self.tableView.reloadData()
                }
            })
            CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
        }
    }
    
    func addToUserActivity(commentKey: String) {
        
            DispatchQueue.global(qos: .background).async {
                guard let key = self.keyForPostToLoad else { return }
                let activityRef = Database.database().reference()
                if let uid = Auth.auth().currentUser?.uid {
                    let update = ["postID" : key]
                    let fullUpdate = ["\(commentKey)": update] as [String: Any]
                    activityRef.child("userActivity").child(uid).child("comments").updateChildValues(fullUpdate)
                    // update to wait 30 seconds and try again
                }
            }
        
    }
    
    func removeFromUserActivity(commentKey: String) {
    
            DispatchQueue.global(qos: .background).async {
                let activityRef = Database.database().reference()
                if let uid = Auth.auth().currentUser?.uid {
                    activityRef.child("userActivity").child(uid).child("comments").child(commentKey).removeValue()
                    // update to wait 30 seconds and try again
                }
            }
        
    }
    
    func updateCommentCount(postKey: String, increment: Bool) {
        DispatchQueue.global(qos: .userInitiated).async {
            if increment && passedData.postDict[postKey] != nil {
                passedData.postDict[postKey]?.numberOfComments! += 1
            }
            else if passedData.postDict[postKey] != nil {
                passedData.postDict[postKey]?.numberOfComments! -= 1
            }
        }
    }
}




