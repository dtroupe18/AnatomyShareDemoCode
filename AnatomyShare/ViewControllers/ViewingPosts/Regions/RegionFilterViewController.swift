//
//  RegionFilterViewController.swift
//  AnatomyShare
//
//  Created by Dave on 1/4/18.
//  Copyright © 2018 Dave. All rights reserved.
//

import UIKit

class RegionFilterViewController: UIViewController {
    
    @IBOutlet weak var headAndNeckButton: UIButton!
    @IBOutlet weak var thoraxButton: UIButton!
    @IBOutlet weak var pelvisAndPerineumButton: UIButton!
    @IBOutlet weak var abdomenButton: UIButton!
    @IBOutlet weak var upperLimbButton: UIButton!
    @IBOutlet weak var backAndSpinalCordbutton: UIButton!
    @IBOutlet weak var lowerLimbButton: UIButton!
    
    var regionToLoad: String?
    let regions: [String] = ["Head and Neck", "Thorax", "Abdomen", "Pelvis and Perineum", "Upper Limb", "Back and Spinal Cord", "Lower Limb"]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleButtons()
    }
    
    private func styleButtons() {
        headAndNeckButton.layer.borderWidth = 1
        headAndNeckButton.layer.borderColor = UIColor.darkGray.cgColor
        thoraxButton.layer.borderWidth = 1
        thoraxButton.layer.borderColor = UIColor.darkGray.cgColor
        pelvisAndPerineumButton.layer.borderWidth = 1
        pelvisAndPerineumButton.layer.borderColor = UIColor.darkGray.cgColor
        abdomenButton.layer.borderWidth = 1
        abdomenButton.layer.borderColor = UIColor.darkGray.cgColor
        upperLimbButton.layer.borderWidth = 1
        upperLimbButton.layer.borderColor = UIColor.darkGray.cgColor
        backAndSpinalCordbutton.layer.borderWidth = 1
        backAndSpinalCordbutton.layer.borderColor = UIColor.darkGray.cgColor
        lowerLimbButton.layer.borderWidth = 1
        lowerLimbButton.layer.borderColor = UIColor.darkGray.cgColor
    }
    
    @IBAction func headPressed(_ sender: Any) {
        self.regionToLoad = regions[0]
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toFilteredRegion", sender: nil)
        }
    }
    
    @IBAction func thoraxPressed(_ sender: Any) {
        self.regionToLoad = regions[1]
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toFilteredRegion", sender: nil)
        }
    }
    
    @IBAction func abdomenPressed(_ sender: Any) {
        self.regionToLoad = regions[2]
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toFilteredRegion", sender: nil)
        }
    }
    
    @IBAction func pelvisPressed(_ sender: Any) {
        self.regionToLoad = regions[3]
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toFilteredRegion", sender: nil)
        }
    }
    
    @IBAction func upperLimbPresed(_ sender: Any) {
        self.regionToLoad = regions[4]
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toFilteredRegion", sender: nil)
        }
    }
    
    @IBAction func backPressed(_ sender: Any) {
        self.regionToLoad = regions[5]
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toFilteredRegion", sender: nil)
        }
    }
    
    @IBAction func lowerLimbPressed(_ sender: Any) {
        self.regionToLoad = regions[6]
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toFilteredRegion", sender: nil)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // pass region to next vc
        if segue.identifier == "toFilteredRegion" {
            if let destination = segue.destination as? RegionViewController, let reg = self.regionToLoad {
                destination.regionToLoad = reg
            }
        }
    }
}
