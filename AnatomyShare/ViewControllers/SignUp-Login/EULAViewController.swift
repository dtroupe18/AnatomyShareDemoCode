//
//  EULAViewController.swift
//  AnatomyShare
//
//  Created by Dave on 10/1/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit

class EULAViewController: UIViewController {
    
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var declineButton: UIButton!
    @IBOutlet weak var agreeButton: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "EULA"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func disagreePressed(_ sender: Any) {
        UserDefaults.standard.set(false, forKey: "EULA")
        if let topController = UIApplication.topViewController() {
            Helper.showAlertMessage(vc: topController, title: "Terms Declined", message: "Access to our app is only granted to users who accept the terms of use.")
            self.navigationController?.popViewController(animated: true)
        }
        else {
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    @IBAction func agreePressed(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "EULA")
        self.navigationController?.popViewController(animated: true)
    }
    
}
