//
//  ImageCropSquare.swift
//  AnatomyShare
//
//  Created by Dave on 12/31/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import Foundation
import UIKit

class ImageCropSquare: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        let color: UIColor = UIColor.red
        let path: UIBezierPath = UIBezierPath(rect: rect)
        path.lineWidth = 3.0
        color.set()
        path.stroke()
    }
}
