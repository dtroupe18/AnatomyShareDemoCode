//
//  SearchViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 9/10/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import Kingfisher

class SearchViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    lazy var searchBar = UISearchBar(frame: CGRect.zero)
    var searchKeys = [String]()
    let noResults = "NO_RESULTS"
    
    var indexToPass: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 135;
        searchBar.placeholder = "Search"
        searchBar.delegate = self
        navigationItem.titleView = searchBar
        tableView.delegate = self
        tableView.dataSource = self
        self.edgesForExtendedLayout = UIRectEdge()
        self.extendedLayoutIncludesOpaqueBars = false
        tableView.contentInsetAdjustmentBehavior = .never
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SearchViewController.screenTapped))
        tap.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func screenTapped() {
        if searchKeys.count == 0 {
            self.searchBar.endEditing(true)
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell", for: indexPath) as! SearchResultCell
        if cell.isHidden {
            return 0
        }
        else {
            return UITableViewAutomaticDimension
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchKeys.isEmpty {
            return 0
        }
        else {
            var numberOfRows = 0
            for key in self.searchKeys {
                if passedData.postDict[key] != nil {
                    numberOfRows += 1
                }
                else {
                    if let index = self.searchKeys.index(of: key) {
                        self.searchKeys.remove(at: index)
                    }
                }
            }
            return numberOfRows
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let key = searchKeys[indexPath.row]
        if let post = passedData.postDict[key] {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell", for: indexPath) as! SearchResultCell
            let url = URL(string: post.pathToImage)
            cell.tinyImageView.kf.setImage(with: url)
            if UserDefaults.standard.object(forKey: "FILTER") != nil {
                if UserDefaults.standard.bool(forKey: "FILTER") == true {
                    cell.tinyImageView.blurImage()
                }
                else {
                    cell.tinyImageView.removeBlur()
                }
            }
            cell.postDescriptionLabel.text = post.postDescription
            cell.userWhoPostedLabel.attributedText = post.userWhoPostedLabel
            cell.userWhoPostedLabel.sizeToFit()
            cell.postDescriptionLabel.sizeToFit()
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
            
        }
        else if key == "NO_RESULTS" {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell", for: indexPath) as! SearchResultCell
            cell.userWhoPostedLabel.text = ""
            cell.postDescriptionLabel.text = "No Results"
            cell.tinyImageView.image = #imageLiteral(resourceName: "NothingFound")
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchResultCell", for: indexPath) as! SearchResultCell
            cell.isHidden = true
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.searchBar.text != nil && searchBar.isFirstResponder {
            DispatchQueue.main.async {
                self.searchBar.endEditing(true)
            }
            return
        }
        if searchKeys[indexPath.row] != noResults {
            self.indexToPass = indexPath.row
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "toSearchTableView", sender: nil)
            }
        }
    }
    
    // MARKER: Search
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let ref = Database.database().reference()
        let searchTerm = searchBar.text
        if searchTerm != "" {
            DispatchQueue.main.async {
                CustomActivityIndicator.sharedInstance.showActivityIndicator(uiView: self.view)
                self.searchBar.endEditing(true)
                self.searchKeys.removeAll()
                self.tableView.reloadData()
            }
            // write the searchTerm to search -> queries
            let key = ref.child("search").child("queries").childByAutoId().key
            let searchUpload = ["query": searchTerm]
            let searchFeed = ["\(key)": searchUpload]
            
            ref.child("search").child("queries").updateChildValues(searchFeed, withCompletionBlock: { (error, success) in
                if error != nil {
                    CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                    if let topController = UIApplication.topViewController() {
                        Helper.showAlertMessage(vc: topController, title: "Error", message: error!.localizedDescription)
                    }
                    return
                }
                else {
                    // listen for the results which will be written to
                    // search -> results -> key -> nbHits = number of results
                    // search -> results -> key -> hits -> 0, 1, 2... -> post
                    var count = 0
                    ref.child("search").child("results").child(key).observe(.childAdded, with: { snap in
                        if let value = snap.value as? Int {
                            count += 1
                            if count == 3 && value == 0 {
                                DispatchQueue.main.async {
                                    CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                    self.searchKeys.append(self.noResults)
                                    self.tableView.reloadData()
                                }
                            }
                        }
                        var resultCount = 0
                        for child in snap.children {
                            let child = child as? DataSnapshot
                            if let result = child?.value as? [String: Any] {
                                if let post = result["post"] as? [String: Any] {
                                    if let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let likes = post["likes"] as? Int, let author = post["author"] as? String {
                                        
                                        let posst = Post()
                                        if passedData.blockedUsers[userID] == nil {
                                            posst.author = author
                                            posst.pathToImage = pathToImage
                                            posst.postID = postID
                                            posst.userID = userID
                                            posst.fancyPostDescription = Helper.createAttributedString(author: author, postText: postDescription)
                                            posst.postDescription = postDescription
                                            posst.timestamp = timestamp
                                            posst.table = table
                                            posst.region = region
                                            posst.category = category
                                            posst.numberOfComments = numberOfComments
                                            posst.likes = likes
                                            posst.userWhoPostedLabel = Helper.createAttributedPostLabel(username: author, table: table, region: region, category: category)
                                            
                                            // Check if the post has two images if it does get the other path
                                            if let originalPath = post["pathToOriginal"] as? String {
                                                posst.pathToOriginal = originalPath
                                            }
                                            
                                            CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: self.view)
                                            passedData.postDict[postID] = posst
                                            if self.searchKeys.index(of: postID) == nil {
                                                self.searchKeys.insert(postID, at: resultCount)
                                                resultCount += 1
                                            }
                                            self.tableView.reloadData()
                                        }
                                    }
                                }
                            }
                        }
                    })
                }
            })
            ref.removeAllObservers()
        }
    }
    
    //Marker: Segues
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toSearchTableView" {
            if let destination = segue.destination as? SearchTableViewController {
                destination.searchKeys = self.searchKeys
                destination.indexToScrollTo = self.indexToPass
            }
        }
    }
}
