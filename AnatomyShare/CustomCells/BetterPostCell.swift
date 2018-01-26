//
//  BetterPostCell.swift
//  AnatomyShare
//
//  Created by David Troupe on 6/8/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth


class BetterPostCell: UITableViewCell {
    
    @IBOutlet weak var postImage: UIImageView!
    @IBOutlet weak var helpfulLabel: UILabel!
    @IBOutlet weak var moreButton: UIButton!
    @IBOutlet weak var postDescription: UILabel!
    @IBOutlet weak var timestamp: UILabel!
    @IBOutlet weak var helpfulButton: UIButton!
    @IBOutlet weak var notHelpfulButton: UIButton!
    @IBOutlet weak var userWhoPostedImageView: UIImageView!
    @IBOutlet weak var userWhoPostedLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var textbubbleButton: UIButton!
    @IBOutlet weak var postImageWidth: NSLayoutConstraint!
    @IBOutlet weak var numberOfCommentsButton: UIButton!
    @IBOutlet weak var reportButton: UIButton!
    
    var reportAlert = UIAlertController(title: "Report a Post", message: "Briefly describe why this post is being reported.", preferredStyle: .alert)
        
    let ref = Database.database().reference()
    public var indexPath: IndexPath!
    public var isHelpful = false
    var postID: String!
    
    // closures
    var moreTapAction: ((UITableViewCell) -> Void)?
    var editTapAction: ((UITableViewCell) -> Void)?
    var likeTapAction: ((UITableViewCell) -> Void)?
    var unlikeTapAction: ((UITableViewCell) -> Void)?
    var isExpanded = false
    var delegate: BetterPostCellDelegate?
    
    
    @IBAction func reportPressed(_ sender: Any) {
        presentAlert()
    }
    
    func presentAlert() {
        let alertController = UIAlertController(title: "Report a Post", message: "Briefly describe why this post is being reported.", preferredStyle: .alert)
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { (_) in
            if let field = alertController.textFields?[0] {
                if let text = field.text {
                    DatabaseFunctions.uploadReport(message: text, postKey: self.postID)
                }
            }
            else {
                DatabaseFunctions.uploadReport(message: "NO_MESSAGE", postKey: self.postID)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in }
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Ex: inappropriate description"
        }
        
        alertController.addAction(submitAction)
        alertController.addAction(cancelAction)
        
        DispatchQueue.main.async {
            if let topController = UIApplication.topViewController() {
                topController.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func helpfulPressed(_ sender: Any) {
        // used to update the post array
        if sender is UIButton {
            likeTapAction?(self)
        }
        
        self.helpfulButton.isEnabled = false
        let ref = Database.database().reference()
        
        // everything done here is abstracted away from the user
        if let uid = Auth.auth().currentUser?.uid {
            ref.child("posts").child(self.postID).observeSingleEvent(of: .value, with: { snapshot in
                if (snapshot.value as? [String: AnyObject]) != nil {
                    let updateLikes: [String: Any] = ["peopleWhoLike/\(uid)" : "true"]
                    ref.child("posts").child(self.postID).updateChildValues(updateLikes, withCompletionBlock: { (error, reff) in
                        if error == nil {
                            // uid was added to likes
                            // increment the like counter in Firebase now
                            
                            ref.child("posts").child(self.postID).runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                                if var data = currentData.value as? [String: Any] {
                                    if var count = data["likes"] as? Int {
                                        count += 1
                                        data["likes"] = count
                                        
                                        currentData.value = data
                                        return TransactionResult.success(withValue: currentData)
                                    }
                                }
                                
                                return TransactionResult.success(withValue: currentData)
                            }
                            DatabaseFunctions.incrementUserActivityCount(countName: "likes")
                            self.helpfulButton.isHidden = true
                            self.notHelpfulButton.isHidden = false
                            self.helpfulButton.isEnabled = true
                        }
                    })
                }
                // add like to userActivity
                if let uid = Auth.auth().currentUser?.uid {
                    let key = ref.child("userActivity").childByAutoId().key
                    if let postID = self.postID {
                        let feed = ["postID": postID]
                        let postFeed = ["\(key)": feed] as [String: Any]
                        ref.child("userActivity").child(uid).child("likes").updateChildValues(postFeed)
                    }
                }
            })
        }
        ref.removeAllObservers()
    }
    
    @IBAction func notHelpfulPressed(_ sender: Any) {
        // used to update array
        if sender is UIButton {
            unlikeTapAction?(self)
        }
        
        self.notHelpfulButton.isEnabled = false
        let ref = Database.database().reference()
        
        // check that the value currently exists in Firebase
        ref.child("posts").child(self.postID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let post = snapshot.value as? [String: AnyObject] {
                if let peopleWhoLike = post["peopleWhoLike"] as? [String: AnyObject] {
                    if let uid = Auth.auth().currentUser?.uid {
                        if peopleWhoLike[uid] != nil {
                            ref.child("posts").child(self.postID).child("peopleWhoLike").child(uid).removeValue(completionBlock: { (error, reff) in
                                // user removed from peopleWhoLike
                                if error == nil {
                                    // remove from userActivity
                                    if let uid = Auth.auth().currentUser?.uid {
                                        ref.child("userActivity").child(uid).child("likes").queryOrdered(byChild: "postID").queryEqual(toValue: self.postID).observeSingleEvent(of: .value, with: { likeSnap in
                                            likeSnap.ref.removeValue(completionBlock: { (e, success) in
                                                // removed from user activity
                                                if e == nil {
                                                    // decrement the likes count
                                                    ref.child("posts").child(self.postID).runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                                                        if var data = currentData.value as? [String: Any] {
                                                            if var count = data["likes"] as? Int {
                                                                count -= 1
                                                                data["likes"] = count
                                                                
                                                                currentData.value = data
                                                                return TransactionResult.success(withValue: currentData)
                                                            }
                                                        }
                                                        return TransactionResult.success(withValue: currentData)
                                                    }
                                                    DatabaseFunctions.decrementUserActivityCount(countName: "likes")
                                                    self.helpfulButton.isHidden = false
                                                    self.notHelpfulButton.isHidden = true
                                                    self.notHelpfulButton.isEnabled = true
                                                }
                                            })
                                        })
                                    }
                                }
                            })
                        }
                    }
                }
            }
        })
        ref.removeAllObservers()
    }
    
    func configureDeletedPostCell() {
        self.isUserInteractionEnabled = false
        self.userWhoPostedImageView.kf.setImage(with: URL(string: memeImageString))
        self.postImage.kf.setImage(with: postDeletedURL)
        self.helpfulLabel.text = ""
        self.postDescription.text = ""
        self.timestamp.text = "December 31, 1514"
        self.userWhoPostedLabel.text = ""
        
    }
    
    @IBAction func moreButtonPressed(_ sender: Any) {
        if sender is UIButton {
            isExpanded = !isExpanded
            postDescription.numberOfLines = isExpanded ? 0 : 2
            moreButton.setTitle("Read more...", for: .normal)
            moreTapAction?(self)
        }
    }
    
    @IBAction func didPressEdit(_ sender: Any) {
        if sender is UIButton {
            editTapAction?(self)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.helpfulButton.isHidden = false
        self.notHelpfulButton.isHidden = true
        self.postImage.image = UIImage()
        self.userWhoPostedImageView.image = UIImage()
        self.moreButton.isHidden = true
    }
}
