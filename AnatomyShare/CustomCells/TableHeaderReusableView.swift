//
//  TableHeaderReusableView.swift
//  AnatomyShare
//
//  Created by David Troupe on 8/15/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit

class TableHeaderReusableView: UICollectionReusableView {
    
    @IBOutlet weak var profileLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var selectRegionButton: UIButton!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var selectCategoryButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    
    var selectCategoryAction: ((UICollectionReusableView) -> Void)?
    var selectRegionAction: ((UICollectionReusableView) -> Void)?
    var seeAllAction: ((UICollectionReusableView) -> Void)?
    var editAction: ((UICollectionReusableView) -> Void)?
    
    
    
    @IBAction func selectRegionPressed(_ sender: Any) {
        if sender is UIButton {
            selectRegionAction?(self)
        }
    }
    
    @IBAction func seeAllPressed(_ sender: Any) {
        if sender is UIButton {
            seeAllAction?(self)
        }
    }
    
    @IBAction func selectCategoryPressed(_ sender: Any) {
        if sender is UIButton {
            selectCategoryAction?(self)
        }
    }
    
    @IBAction func editPressed(_ sender: Any) {
        if sender is UIButton {
            editAction?(self)
        }
    }
}
