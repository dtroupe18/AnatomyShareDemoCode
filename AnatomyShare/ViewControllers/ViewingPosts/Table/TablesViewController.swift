//
//  TablesViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 6/23/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import WebKit

class TablesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var openMapButton: UIBarButtonItem!
    var mapOpen = false
    var webView: WKWebView?
    
    
    let tables: NSArray = ["Table 1", "Table 2", "Table 3", "Table 4", "Table 5", "Table 6", "Table 7", "Table 8", "Table 9", "Table 10", "Table 11", "Table 12", "Table 13", "Table 14", "Table 15", "Table 16", "Table 17", "Table 18", "Table 19", "Table 20",  "Table 21", "Prosection"]
    
    var tableToPass: String? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 30
    }
    
    @IBAction func openMapPressed(_ sender: Any) {
        if !mapOpen {
            if let pdfURL = Bundle.main.url(forResource: "Map", withExtension: "pdf", subdirectory: nil, localization: nil)  {
                do {
                    webView = WKWebView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height))
                    webView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    mapOpen = true
                    let data = try Data(contentsOf: pdfURL)
                    if webView != nil {
                        DispatchQueue.main.async {
                            self.openMapButton.title = "Close Map"
                            self.webView!.load(data, mimeType: "application/pdf", characterEncodingName:"", baseURL: pdfURL.deletingLastPathComponent())
                            self.view.addSubview(self.webView!)
                        }
                    }
                }
                catch {
                    if let topController = UIApplication.topViewController() {
                        Helper.showAlertMessage(vc: topController, title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }
        else if mapOpen && webView != nil {
            DispatchQueue.main.async {
                self.webView!.removeFromSuperview()
                self.mapOpen = false
                self.openMapButton.title = "Open Map"
                self.webView = nil
            }
            
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tables.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tableCell", for: indexPath)
        cell.textLabel?.text = tables[indexPath.row] as? String
        // disables the ugly cell highlighting
        cell.selectionStyle = UITableViewCellSelectionStyle.none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableToPass = tables[indexPath.row] as? String
        
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "TablesToTable", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TablesToTable" {
            if tableToPass != nil {
                let controller = segue.destination as! TableCollectionViewController
                controller.tableToLoad = tableToPass
            }
            else {
                // do nothing no variables to pass
            }
        }
    }
}


