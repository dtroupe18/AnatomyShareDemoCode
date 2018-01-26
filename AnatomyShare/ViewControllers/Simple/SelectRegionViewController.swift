//
//  SelectLabViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 7/2/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit


class SelectRegionViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var delegate: sendDataToViewProtocol? = nil
    var filterDelegate: sendFilterDataToViewProtocol? = nil
    
    let regions: NSArray = ["Back and Spinal Cord", "Upper Limb", "Lower Limb", "Abdomen", "Pelvis and Perineum", "Head and Neck", "Thorax"]
    
    var selectedRegion: String?
    
    // Flags to determine what to do when a row is selected
    var fromEditVC: Bool = false
    var fromTableCV: Bool = false
    var fromDetailsVC: Bool = false
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 30; // Default Size
    }
    override func viewWillDisappear(_ animated: Bool) {
        self.fromEditVC = false
        self.fromTableCV = false
        self.fromDetailsVC = false
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "regionCell")
        cell?.textLabel?.text = regions[indexPath.row] as? String
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedRegion = regions[indexPath.row] as? String
        // iPad
        if delegate != nil && selectedRegion != nil {
            DispatchQueue.main.async {
                self.delegate?.inputData(section: "Region", data: self.selectedRegion!)
                self.dismiss(animated: true, completion: nil)
            }
        }
        // iPhone
        else {
            if fromTableCV {
                _ = self.navigationController?.popViewController(animated: true)
                if let previousVC = self.navigationController?.viewControllers.last as? TableCollectionViewController {
                    previousVC.selectedRegion = self.selectedRegion
                    previousVC.shouldRefreshFilters = true
                }
            }
            else if fromEditVC {
                _ = self.navigationController?.popViewController(animated: true)
                if let previousVC = self.navigationController?.viewControllers.last as? EditPostViewController {
                    previousVC.postDraft.region = self.selectedRegion
                    previousVC.regionChanged = true
                }
            }
            else if fromDetailsVC {
                _ = self.navigationController?.popViewController(animated: true)
                if let previousVC = self.navigationController?.viewControllers.last as? PostDetailsViewController {
                    previousVC.postDraft.region = self.selectedRegion
                }
            }
        }
    }
}
