//
//  Protocols.swift
//  AnatomyShare
//
//  Created by David Troupe on 7/8/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import Foundation

protocol sendDataToViewProtocol: class {
    func inputData(section: String, data: String)
}

protocol sendFilterDataToViewProtocol {
    func filterData(section: String, data: String)
}

protocol BetterPostCellDelegate: NSObjectProtocol {
    func moreButtonPressed(cell: BetterPostCell)
}
