//
//  DraftCell.swift
//  AnatomyShare
//
//  Created by Dave on 12/29/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit

class DraftCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    // Closures
    var deleteTapAction: ((UICollectionViewCell) -> Void)?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = UIImage()
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        if sender is UIButton {
            deleteTapAction?(self)
        }
    }
}
