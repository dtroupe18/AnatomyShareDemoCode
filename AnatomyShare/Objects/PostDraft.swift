//
//  Draft.swift
//  AnatomyShare
//
//  Created by Dave on 12/29/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import Foundation
import UIKit

class PostDraft: NSObject {
    
    var folderName: String?
    var originalImageName: String?
    var originalImage: UIImage?
    var originalImageURL: URL?
    
    var annotatedImageName: String?
    var annotatedImage: UIImage?
    var annotatedImageURL: URL?
    
    var table: String?
    var category: String?
    var region: String?
    var text: String?
    
    // used when editing a post
    var key: String?
    var popIndex: Int?
    
    // upload credentials so searching has the
    // writing from the users images
    var textOne: String?
    var textTwo: String?
    var textThree: String?
    var textFour: String?
    var textFive: String?
    
    override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? PostDraft {
            return self.folderName == other.folderName
        }
        else {
            return false
        }
    }
}
