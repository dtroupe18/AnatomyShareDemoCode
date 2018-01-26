//
//  DatabaseFunctions.swift
//  AnatomyShare
//
//  Created by David Troupe on 7/28/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import Foundation
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class DatabaseFunctions {
    
    // Function that can upload an array of images with a completion handler that returns
    // a string array holding the url to each image
    static func uploadImages(userID: String, imageDict: [String: UIImage], completionHandler: @escaping ([String]) -> ()) {
        var storage: StorageReference
        
        if !passedData.isDebug {
            storage = Storage.storage().reference(forURL: "gs://anatomyshare-b9fbc.appspot.com")
        }
        else {
            storage = Storage.storage().reference(forURL: "gs://anatomysharedevelopment.appspot.com")
        }
        
        var imageURLs = [String]()
        var uploadCount: Int = 0
        
        for (key, image) in imageDict {
            // create a unique file name for the image we are about to upload
            let imageName = key
            let storageRef = storage.child("posts").child(userID).child("\(imageName).jpg")
            
            guard let data = UIImageJPEGRepresentation(image, 0.6) else { return }
            
            let uploadTask = storageRef.putData(data, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    if let topController = UIApplication.topViewController() {
                        CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: topController.view)
                        Helper.showAlertMessage(vc: topController, title: "Upload Error", message: error!.localizedDescription)
                    }
                    return
                }
                storageRef.downloadURL(completion: { (url, error) in
                    if let imageURL = url  {
                        imageURLs.append(imageURL.absoluteString)
                        uploadCount += 1
                        if uploadCount == imageDict.count  {
                            completionHandler(imageURLs)
                        }
                    }
                })
            })
            uploadTask.observe(.failure) { (snapshot) in
                if let topController = UIApplication.topViewController() {
                    CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: topController.view)
                    Helper.showAlertMessage(vc: topController, title: "Error", message: "Post failed to upload please try again")
                }
                return
            }
        }
    }
    
    
    static func getBlockedUsers() {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("userActivity").child(uid).child("blocked").observeSingleEvent(of: .value, with: { snap in
                for child in snap.children {
                    let child = child as? DataSnapshot
                    if let key = child?.key, let name = child?.value as? String {
                        passedData.blockedUsers[key] = name
                    }
                }
            })
        }
    }
    
    static func blockUser(currentUserUID: String, blockedUID: String, blockedName: String, indexPath: IndexPath) {
        let upload = [blockedUID: blockedName]
        let ref = Database.database().reference()
        ref.child("userActivity").child(currentUserUID).child("blocked").updateChildValues(upload, withCompletionBlock: { (error, sucess) in
            if error != nil {
                if let topController = UIApplication.topViewController() {
                    Helper.showAlertMessage(vc: topController, title: "Error", message: "Failed to block user please try again")
                }
            }
            else {
                if let topController = UIApplication.topViewController() {
                    passedData.blockedUsers[blockedUID] = blockedName
                    // newsfeedKeys.remove(at: indexPath.row)
                    Helper.refreshEverything()
                    Helper.showAlertMessage(vc: topController, title: "User Blocked", message: "\(blockedName) has been blocked")
                }
            }
        })
    }
    
    static func getUserLikes() {
        if let uid = Auth.auth().currentUser?.uid {
            let ref = Database.database().reference()
            ref.child("userActivity").child(uid).child("likes").queryOrderedByKey().observeSingleEvent(of: .value, with: { snap in
                if snap.exists() {
                    for child in snap.children {
                        let child = child as? DataSnapshot
                        if let likePost = child?.value as? [String: AnyObject] {
                            if let key = likePost["postID"] as? String {
                                passedData.likedPosts[key] = true
                            }
                        }
                    }
                }
            })
        }
    }
        
    static func incrementUserActivityCount(countName: String) {
        DispatchQueue.global(qos: .background).async {
            if let uid = Auth.auth().currentUser?.uid {
                let databaseReference = Database.database().reference()
                databaseReference.child("userActivity").child(uid).child("counts").runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                    if var data = currentData.value as? [String: Any] {
                        if var count = data[countName] as? Int {
                            count += 1
                            data[countName] = count
                            currentData.value = data
                            return TransactionResult.success(withValue: currentData)
                        }
                    }
                    return TransactionResult.success(withValue: currentData)
                }
            }
        }
    }
    
    static func decrementUserActivityCount(countName: String) {
        DispatchQueue.global(qos: .background).async {
            if let uid = Auth.auth().currentUser?.uid {
                let databaseReference = Database.database().reference()
                databaseReference.child("userActivity").child(uid).child("counts").runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                    if var data = currentData.value as? [String: Any] {
                        if var count = data[countName] as? Int {
                            count -= 1
                            data[countName] = count
                            currentData.value = data
                            return TransactionResult.success(withValue: currentData)
                        }
                    }
                    return TransactionResult.success(withValue: currentData)
                }
            }
        }
    }
    
    static func removePostKeyFrom(child: String, key: String) {
        let databaseReference = Database.database().reference()
        databaseReference.child(child).child(key).removeValue()
    }
    
    static func addPostKeyTo(child: String, key: String) {
        let databaseReference = Database.database().reference()
        databaseReference.child(child).updateChildValues([key: key])
    }
    
    static func uploadReport(message: String, postKey: String) {
        let databaseReference = Database.database().reference()
        if let displayName = Auth.auth().currentUser?.displayName, let uid = Auth.auth().currentUser?.uid {
            let key = databaseReference.child("posts").childByAutoId().key
            
            // get some info about the post
            databaseReference.child("posts").child(postKey).observeSingleEvent(of: .value, with: { snap in
                if snap.exists() {
                    if let post = snap.value as? [String: AnyObject] {
                        
                        if let pathToImage = post["pathToImage"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let table = post["table"] as? String, let userID = post["userID"] as? String {
                            
                            databaseReference.child("users").child(userID).observeSingleEvent(of: .value, with: { snapShot in
                                if let userInfo = snapShot.value as? [String: Any] {
                                    if let author = userInfo["displayName"] as? String {
                                        let report = ["reportedBy": displayName,
                                                      "reason": message,
                                                      "reportedByUid": uid,
                                                      "author": author,
                                                      "table": table,
                                                      "uid": userID,
                                                      "postDescription": postDescription,
                                                      "pathToImage": pathToImage,
                                                      "timestamp": timestamp,
                                                      "postID": key] as [String: Any]
                                        
                                        let reportFeed = ["\(key)" : report]
                                        
                                        databaseReference.child("reportedPosts").child(postKey).updateChildValues(reportFeed, withCompletionBlock: { (error,success) in
                                            if error != nil {
                                                if let topController = UIApplication.topViewController() {
                                                    Helper.showAlertMessage(vc: topController, title: "Error", message: "Error uploading your report please try again.")
                                                }
                                                return
                                            }
                                            else {
                                                if let topController = UIApplication.topViewController() {
                                                    Helper.showAlertMessage(vc: topController, title: "Success", message: "Post successfully reported.")
                                                }
                                                return
                                            }
                                        })                                        
                                    }
                                }
                            })
                        }
                    }
                }
            })
        }
    }
    
    static func createUserActivityCounts(uid: String) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + .seconds(5)) {
            let databaseReference = Database.database().reference()
            let userCounts: [String: Any] = ["posts": 0,
                                             "comments": 0,
                                             "likes": 0]
            databaseReference.child("userActivity").child(uid).child("counts").setValue(userCounts) { (error, ref) -> Void in
                if error != nil {
                    print(error!.localizedDescription)
                }
            }
        }
    }
    
}

