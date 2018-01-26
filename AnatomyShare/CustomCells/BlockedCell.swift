//
//  BlockedCell.swift
//  AnatomyShare
//
//  Created by Dave on 10/21/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class BlockedCell: UITableViewCell {
    
    @IBOutlet weak var displayName: UILabel!
    @IBOutlet weak var unblockButton: UIButton!
    var blockedUserUID: String!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func unblockPressed(_ sender: Any) {
        if let name = passedData.blockedUsers[blockedUserUID] {
            let unblockAlert = UIAlertController(title: "Unblock", message: "Unblock \(name)", preferredStyle: UIAlertControllerStyle.alert)
            
            unblockAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                // remove from database and refresh everything
                if let uid = Auth.auth().currentUser?.uid {
                    let ref = Database.database().reference()
                    ref.child("userActivity").child(uid).child("blocked").child(self.blockedUserUID).removeValue(completionBlock: {  (error, ref) in
                        if error != nil {
                            if let topController = UIApplication.topViewController() {
                                Helper.showAlertMessage(vc: topController, title: "Error", message: "Error unblocking \(name) please try again.")
                            }
                            return
                        }
                        passedData.blockedUsers.removeValue(forKey: self.blockedUserUID)
                        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadBlockedTableView"), object: nil)
                    })
                }
            }))
            unblockAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                // print("Handle Cancel Logic here")
            }))
            DispatchQueue.main.async {
                if let topController = UIApplication.topViewController() {
                    topController.present(unblockAlert, animated: true, completion: nil)
                }
                else {
                    return
                }
            }
        }
    }
}
