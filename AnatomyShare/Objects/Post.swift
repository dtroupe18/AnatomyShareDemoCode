//
//  Post.swift
//  AnatomyShare
//
//  Created by David Troupe on 5/26/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit

class Post: NSObject {
    
    var author: String!
    var likes: Int!
    var numberOfComments: Int!
    var pathToImage: String!
    var pathToOriginal: String?
    var userID: String!
    var postID: String!
    var postDescription: String!
    var timestamp: Double!
    var isExpanded = false
    var table: String!
    var category: String!
    var pathToUserImage: String!
    var region: String!
    var userLiked: Bool = false
    var showingOriginalImage: Bool = false
    var fancyPostDescription: NSMutableAttributedString!
    var userWhoPostedLabel: NSMutableAttributedString!
    
}
