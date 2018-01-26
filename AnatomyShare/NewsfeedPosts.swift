//
//  NewsfeedPosts.swift
//  AnatomyShare
//
//  Created by Dave on 7/28/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class NewsfeedPosts: NSObject, UITableViewDataSource {
    
    var newsfeedPosts = [Post]()
    let screenSize: CGRect = UIScreen.main.bounds
    var postToEdit: Post?
    var selectedImageRow: Int!
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsfeedPosts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "betterPostCell", for: indexPath) as! BetterPostCell
        
        // size the image to the width of the screen
        // screen size for dynamic layout
        
        // sort so the most recent post is first
        newsfeedPosts.sort(by: {$0.timestamp > $1.timestamp})
        cell.indexPath = indexPath
        cell.postImage.downloadImage(from: newsfeedPosts[indexPath.row].pathToImage)
        
        // download the user image for each cell
        let testRef = Database.database().reference()
        let userID = newsfeedPosts[indexPath.row].userID
        
        // check if the post was created by the current user
        // post.userID == current user
        if userID! == Auth.auth().currentUser!.uid {
            cell.editButton.isHidden = false
        }
        else {
            cell.editButton.isHidden = true
        }
        
        testRef.child("users").child(userID!).queryOrderedByKey().observeSingleEvent(of: .value, with: { dataSnapshot in
            if let pathSnap = dataSnapshot.value as? [String: AnyObject] {
                if let imagePath = pathSnap["urlToImage"] as? String {
                    cell.userWhoPostedImageView.downloadUserImage(from: imagePath)
                    cell.userWhoPostedImageView.layer.cornerRadius = 6
                    cell.userWhoPostedImageView.clipsToBounds = true
                }
            }
        })
        testRef.removeAllObservers()
        
        // disables the ugly cell highlighting
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        cell.userWhoPostedLabel.attributedText = newsfeedPosts[indexPath.row].userWhoPostedLabel
        // added size to fit 6/15
        cell.userWhoPostedLabel.sizeToFit()
        
        let likes = newsfeedPosts[indexPath.row].likes!
        if likes != 1 {
            cell.helpfulLabel.text = "\(likes) Likes"
        }
        else {
            cell.helpfulLabel.text = "\(likes) Like"
        }
        
        cell.postID = newsfeedPosts[indexPath.row].postID
        
        cell.postDescription.attributedText = newsfeedPosts[indexPath.row].fancyPostDescription
        cell.postDescription.sizeToFit()
        
        // Add Timestamp
        cell.timestamp.text = Helper.convertTimestamp(serverTimestamp: newsfeedPosts[indexPath.row].timestamp!)
        
        if newsfeedPosts[indexPath.row].postDescription.height(withConstrainedWidth: screenSize.width * 0.9, font: UIFont.systemFont(ofSize: UIFont.systemFontSize)) > cell.postDescription.frame.height {
            cell.moreButton.isHidden = false
        }
        else {
            // otherwise a resued cell will have the more button
            cell.moreButton.isHidden = true
        }
        
        // comment button
        cell.textbubbleButton.tag = indexPath.row
        cell.textbubbleButton.addTarget(self, action: #selector(NewsFeedViewController.textBubblePressed(_:)), for: UIControlEvents.touchUpInside)
        
        // change helpful button if the post has already been liked
        
        if newsfeedPosts[indexPath.row].peopleWhoLike.count > 0 && newsfeedPosts[indexPath.row].peopleWhoLike.contains(Auth.auth().currentUser!.uid) {
            cell.helpfulButton.isHidden = true
            cell.notHelpfulButton.isHidden = false
        }
        else {
            cell.helpfulButton.isHidden = false
            cell.notHelpfulButton.isHidden = true
        }
        
        cell.moreTapAction = { (BetterPostCell) in
            self.newsfeedPosts[indexPath.row].isExpanded = !self.newsfeedPosts[indexPath.row].isExpanded
            cell.moreButton.isHidden = true
            
            // refresh
            tableView.beginUpdates()
            tableView.endUpdates()
        }
        
        cell.editTapAction = { (BetterPostCell) in
            self.postToEdit = self.newsfeedPosts[indexPath.row]
            self.selectedImageRow = indexPath.row
            if let topController = UIApplication.topViewController() {
                topController.performSegue(withIdentifier: "toEdit", sender: nil)
            }
        }
        
        cell.likeTapAction = { (BetterPostCell) in
            // update values stored locally
            self.newsfeedPosts[indexPath.row].likes! += 1
            self.newsfeedPosts[indexPath.row].peopleWhoLike.append(Auth.auth().currentUser!.uid)
        }
        
        cell.unlikeTapAction = { (BetterPostCell) in
            self.newsfeedPosts[indexPath.row].peopleWhoLike = self.newsfeedPosts[indexPath.row].peopleWhoLike.filter { $0 != Auth.auth().currentUser!.uid }
            self.newsfeedPosts[indexPath.row].likes! -= 1
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(segueToScrollView(_ :)))
        cell.postImage.isUserInteractionEnabled = true
        cell.postImage.addGestureRecognizer(tapGestureRecognizer)
        
        return cell
    }
    
        
    func insertData(post: Post) {
        newsfeedPosts.append(post)
    }
    
    func replaceData(oldPost: Post, newPost: Post) {
        if let index = newsfeedPosts.index(of: oldPost) {
            newsfeedPosts[index] = newPost
        }
    }
    
    func segueToScrollView(_ sender: UITapGestureRecognizer) {
        let touch = sender.location(in: tableView)
        if let indexPath = tableView.indexPathForRow(at: touch) {
            selectedImageRow = indexPath.row
            // print("Row Selected: \(selectedImageRow)\n")
            self.performSegue(withIdentifier: "toScrollView", sender: sender)
        }
        
    }
}
