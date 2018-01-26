//
//  ImageCell.swift
//  AnatomyShare
//
//  Created by David Troupe on 8/20/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit

class ImageCell: UICollectionViewCell {
    
    public var indexPath: IndexPath?
    @IBOutlet weak var imageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = UIImage()
    }
    
}
