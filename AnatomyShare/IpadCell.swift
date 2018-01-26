//
//  IpadCell.swift
//  AnatomyShare
//
//  Created by Dave on 6/30/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit

class IpadCell: UITableViewCell {
    
    @IBOutlet weak var postImage: UIImageView!
    
    @IBOutlet weak var userWhoPostedImageView: UIImageView!

    @IBOutlet weak var userWhoPostedLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
