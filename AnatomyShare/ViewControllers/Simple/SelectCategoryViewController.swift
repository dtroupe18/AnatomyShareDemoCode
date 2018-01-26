//
//  SelectCategoryViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 6/26/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit

class SelectCategoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var delegate: sendDataToViewProtocol? = nil
    var filterDelegate: sendFilterDataToViewProtocol? = nil

    let categories: NSArray = ["Model Features", "Pathologies", "Anomalies", "Surgeries", "Other"]
    var selectedCategory: String?
    
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
        self.fromTableCV = false
        self.fromEditVC = false
        self.fromDetailsVC = false
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell")!
        cell.textLabel?.text = categories[indexPath.row] as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedCategory = categories[indexPath.row] as? String
        
        // iPad
        if delegate != nil && selectedCategory != nil {
            DispatchQueue.main.async {
                self.delegate?.inputData(section: "Category", data: self.selectedCategory!)
                self.dismiss(animated: true, completion: nil)
            }
        }
        // iPhone and this VC was not presented as a popover
        else {
            if fromTableCV {
                _ = self.navigationController?.popViewController(animated: true)
                if let previousVC = self.navigationController?.viewControllers.last as? TableCollectionViewController {
                    previousVC.selectedCategory = self.selectedCategory
                    previousVC.shouldRefreshFilters = true
                }
            }
            else if fromEditVC {
                _ = self.navigationController?.popViewController(animated: true)
                if let previousVC = self.navigationController?.viewControllers.last as? EditPostViewController {
                    previousVC.postDraft.category = self.selectedCategory
                    previousVC.categoryChanged = true
                }
            }
            else if fromDetailsVC {
                _ = self.navigationController?.popViewController(animated: true)
                if let previousVC = self.navigationController?.viewControllers.last as? PostDetailsViewController {
                    previousVC.postDraft.category = self.selectedCategory
                }
            }
        }
    }
}

    
    

    

