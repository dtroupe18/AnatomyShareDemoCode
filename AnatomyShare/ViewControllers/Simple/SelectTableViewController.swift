//
//  SelectTableViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 6/25/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit

class SelectTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var delegate: sendDataToViewProtocol? = nil
    @IBOutlet weak var tableView: UITableView!
    
    
    let tables: NSArray = ["Table 1", "Table 2", "Table 3", "Table 4", "Table 5", "Table 6", "Table 7", "Table 8", "Table 9", "Table 10", "Table 11", "Table 12", "Table 13", "Table 14", "Table 15", "Table 16", "Table 17", "Table 18", "Table 19", "Table 20",  "Table 21", "Prosection"]
    
    var selectedTable: String?
    
    var fromEditVC: Bool = false
    var fromDetailsVC: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 30; // Default Size
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.fromEditVC = false
        self.fromDetailsVC = false
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tables.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell")!
        cell.textLabel?.text = tables[indexPath.row] as? String
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedTable = tables[indexPath.row] as? String
        
        // iPad
        if delegate != nil && selectedTable != nil {
            delegate?.inputData(section: "Table", data: selectedTable!)
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
            return
        }
        else {
            if fromEditVC {
                _ = self.navigationController?.popViewController(animated: true)
                if let previousVC = self.navigationController?.viewControllers.last as? EditPostViewController {
                    previousVC.postDraft.table = self.selectedTable
                    previousVC.tableChanged = true
                }
            }
            else if fromDetailsVC {
                _ = self.navigationController?.popViewController(animated: true)
                if let previousVC = self.navigationController?.viewControllers.last as? PostDetailsViewController{
                    previousVC.postDraft.table = self.selectedTable
                }
            }
        }
    }
}
