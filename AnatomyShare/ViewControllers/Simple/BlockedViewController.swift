//
//  BlockedViewController.swift
//  AnatomyShare
//
//  Created by Dave on 10/21/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit

class BlockedViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var blockedUIDs = Array(passedData.blockedUsers.keys)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = UITableViewAutomaticDimension
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadTableView), name: NSNotification.Name(rawValue: "reloadBlockedTableView"), object: nil)
    }
    
    @objc private func reloadTableView() {
        self.tableView.reloadData()
    }
    
    //MARK: TABLEVIEW
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfRows = 0
        for uid in blockedUIDs {
            if passedData.blockedUsers[uid] != nil {
                numberOfRows += 1
            }
        }
        return numberOfRows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "blockedCell", for: indexPath) as! BlockedCell
        let currentUID = blockedUIDs[indexPath.row]
        cell.blockedUserUID = currentUID
        cell.displayName.text = passedData.blockedUsers[currentUID]
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
