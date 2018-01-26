//
//  Data.swift
//  AnatomyShare
//
//  Created by David Troupe on 6/26/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import Foundation
import UIKit

let websiteURL = "https://sites.google.com/view/anatomyshare/home"
let privacyPolicyURL = "https://www.iubenda.com/privacy-policy/8217471"

let postDeletedURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/anatomyshare-b9fbc.appspot.com/o/posts%2FpostDeleted%2FpostDeleted.png?alt=media&token=9b3ac616-6b1d-43ea-87d9-eaad6e4333af")

let memeImageString = "https://usatftw.files.wordpress.com/2017/05/spongebob.jpg?w=1000&h=600&crop=1"

let postDeletedString = "https://firebasestorage.googleapis.com/v0/b/anatomyshare-b9fbc.appspot.com/o/posts%2FpostDeleted%2FpostDeleted.png?alt=media&token=9b3ac616-6b1d-43ea-87d9-eaad6e4333af"

let blockedPostString = "https://firebasestorage.googleapis.com/v0/b/anatomyshare-b9fbc.appspot.com/o/posts%2FpostDeleted%2FUserBlocked.png?alt=media&token=2273268a-f9f1-472e-b3bb-b7c9943230f9"

let blockedPostURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/anatomyshare-b9fbc.appspot.com/o/posts%2FpostDeleted%2FUserBlocked.png?alt=media&token=2273268a-f9f1-472e-b3bb-b7c9943230f9")

struct PassedData {
    var newUsername: String? = nil
    var likedPosts = [String: Bool]()
    var blockedUsers = [String: String]()
    var postDict = [String: Post]()
    let isDebug = false
}

var passedData = PassedData()

