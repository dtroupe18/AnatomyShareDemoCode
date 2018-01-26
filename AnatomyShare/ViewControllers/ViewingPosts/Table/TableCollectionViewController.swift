//
//  TableCollectionViewController.swift
//  AnatomyShare
//
//  Created by David Troupe on 8/14/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import Kingfisher

class TableCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIPopoverControllerDelegate, sendDataToViewProtocol {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    // Table number passed in from previous VC
    var tableToLoad: String!
    
    // Category selected to filter the current tables posts
    var selectedCategory: String?
    
    // Regoin selected to filter the current tables posts
    var selectedRegion: String?
    
    // HeaderView
    var header: TableHeaderReusableView!
    
    // Pull to refresh
    var refreshControl: UIRefreshControl!
    
    // String to appear in description if nothing else is there
    let defaultProfileDesc = "Use this space to describe your cadaver."
    
    // Post key to pass to the next view controller
    var keyToPass: String?
    
    // Boolean flag to know when a new value was passed in for
    // selectedCategory or selectedRegion
    var shouldRefreshFilters = false
    
    // Loading Flag
    var isLoading: Bool = false
    
    // Keys for the current tables posts
    var currentTableKeys = [String]()
    
    // Oldest keys to determine when to stop paging
    var oldestTableKey: String?
    var oldestTableCategoryKey: String?
    var oldestTableRegionKey: String?
    var oldestTableCategoryRegionKey: String?
    
    // Variables to pass to tableview
    var indexToPass: Int?
    
    // Assigned indexPath for header
    var headerIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = tableToLoad
        
        // load the tables posts
        fetchInitialTablesPosts(tableNumber: tableToLoad, { (done) in
            if done {
                self.collectionView.reloadData()
                self.isLoading = false
            }
        })
        
        // Notication to reload the collectionView when filter is enabled
        NotificationCenter.default.addObserver(self, selector: #selector(reloadCollectionView), name: NSNotification.Name(rawValue: "reloadTableCollectionView"), object: nil)
        
        // Notification to refresh collectionView
        NotificationCenter.default.addObserver(self, selector: #selector(refreshCollectionView), name: NSNotification.Name(rawValue: "refreshTableCollectionView"), object: nil)
        
        let flow = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flow.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        let width = UIScreen.main.bounds.size.width
        flow.itemSize = CGSize(width: width / 3.0, height: width / 3.0)
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        
        self.extendedLayoutIncludesOpaqueBars = false
        self.hideKeyboardWhenTappedAround()
        
        collectionView.alwaysBounceVertical = true // so you can pulldown when there isnt't enough posts
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "") // no title
        refreshControl.addTarget(self, action: #selector(self.refreshCollectionView), for: UIControlEvents.valueChanged)
        collectionView.addSubview(refreshControl)
    }
    
    // If the user is on an iphone the filters are selected in another view not a pop-over so
    // this handles the logic behind those choices
    override func viewWillAppear(_ animated: Bool) {
        if self.shouldRefreshFilters {
            self.collectionView.reloadData()
            if self.selectedCategory != nil && self.selectedRegion != nil  {
                self.fetchCategoryRegionPosts(tableNumber: self.tableToLoad, category: self.selectedCategory!, region: self.selectedRegion!, { (done) in
                    if done {
                        self.collectionView.reloadData()
                        self.isLoading = false
                    }
                })
            }
            else if self.selectedCategory != nil &&  self.selectedRegion == nil {
                self.fetchCategoryPosts(tableNumber: self.tableToLoad, category: self.selectedCategory!, { (done) in
                    if done {
                        self.collectionView.reloadData()
                        self.isLoading = false
                    }
                })
            }
            else if self.selectedRegion != nil {
                self.fetchRegionPosts(tableNumber: self.tableToLoad, region: self.selectedRegion!, { (done) in
                    if done {
                        self.collectionView.reloadData()
                        self.isLoading = false
                    }
                })
            }
        }
    }
    
    @objc func reloadCollectionView() {
        self.collectionView.reloadData()
    }
    
    // Pull to refresh handler
    @objc func refreshCollectionView() {
        if !self.isLoading {
            if selectedCategory != nil && selectedRegion != nil {
                self.fetchCategoryRegionPosts(tableNumber: self.tableToLoad, category: selectedCategory!, region: selectedRegion!, { (done) in
                    if done {
                        self.collectionView.reloadData()
                        self.refreshControl.endRefreshing()
                        self.isLoading = false
                    }
                })
            }
            else if selectedCategory != nil {
                self.fetchCategoryPosts(tableNumber: self.tableToLoad, category: selectedCategory!, { (done) in
                    if done {
                        self.collectionView.reloadData()
                        self.refreshControl.endRefreshing()
                        self.isLoading = false
                    }
                })
            }
            else if selectedRegion != nil {
                self.fetchRegionPosts(tableNumber: self.tableToLoad, region: selectedRegion!, { (done) in
                    if done {
                        self.collectionView.reloadData()
                        self.refreshControl.endRefreshing()
                        self.isLoading = false
                    }
                })
            }
            else if selectedCategory == nil && selectedRegion == nil {
                self.fetchInitialTablesPosts(tableNumber: self.tableToLoad, { (done) in
                    if done {
                        self.collectionView.reloadData()
                        self.refreshControl.endRefreshing()
                        self.isLoading = false
                    }
                })
            }
        }
    }
    
    // Show the camera so the user can take a picture to upload
    @IBAction func plusPressed(_ sender: Any) {
        DispatchQueue.main.async{
            let storyboard: UIStoryboard = UIStoryboard(name: "CreatePost", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CameraViewController")
            self.show(vc, sender: self)
        }
    }
    
    // recalculate cell size on orientation change
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard let flow = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        flow.invalidateLayout()
        flow.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        let width = UIScreen.main.bounds.size.width
        flow.itemSize = CGSize(width: width / 3.0, height: width / 3.0)
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
    }
    
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.currentTableKeys.isEmpty {
            return 0
        }
        else {
            var numberOfRows = 0
            for key in self.currentTableKeys {
                if passedData.postDict[key] != nil {
                    numberOfRows += 1
                }
                else {
                    if let index = self.currentTableKeys.index(of: key) {
                        self.currentTableKeys.remove(at: index)
                    }
                }
            }
            return numberOfRows
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let key = currentTableKeys[indexPath.row]
        
        if let post = passedData.postDict[key] {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
            cell.indexPath = indexPath
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.black.cgColor
            
            if passedData.postDict[key]?.userID != "BLOCKED" {
                let url = URL(string: post.pathToImage)
                cell.imageView.kf.setImage(with: url)
            }
            // FILTER REQUIRED BY APPLE
            if UserDefaults.standard.object(forKey: "FILTER") != nil {
                if UserDefaults.standard.bool(forKey: "FILTER") == true {
                    cell.imageView.blurImage()
                    
                }
                else {
                    cell.imageView.removeBlur()
                }
            }
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
            cell.imageView.image = #imageLiteral(resourceName: "UserBlocked")
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row + 1 >= currentTableKeys.count && !self.isLoading {
            if selectedCategory != nil && selectedRegion != nil {
                if let last = currentTableKeys.last, let oldest = self.oldestTableCategoryRegionKey {
                    if last != oldest {
                        fetchMoreCategoryRegionPosts(tableNumber: tableToLoad, category: self.selectedCategory!, region: self.selectedRegion!, lastVisibleKey: last, { (done) in
                            if done {
                                Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                                    self.collectionView.reloadData()
                                    self.isLoading = false
                                })
                            }
                        })
                    }
                }
            }
            else if selectedCategory != nil {
                // page more on category
                if let last = currentTableKeys.last, let oldest = self.oldestTableCategoryKey {
                    if last != oldest {
                        fetchMoreCategoryPosts(tableNumber: tableToLoad, category: selectedCategory!, lastVisibleKey: last, { (done) in
                            if done {
                                Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                                    self.collectionView.reloadData()
                                    self.isLoading = false
                                })
                            }
                        })
                    }
                }
            }
            else if selectedRegion != nil {
                // page more on region
                if let last = currentTableKeys.last, let oldest = self.oldestTableRegionKey {
                    if last != oldest {
                        fetchMoreRegionPosts(tableNumber: tableToLoad, region: selectedRegion!, lastVisibleKey: last, { (done) in
                            if done {
                                Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                                    self.collectionView.reloadData()
                                    self.isLoading = false
                                })
                            }
                        })
                    }
                }
            }
            else if selectedCategory == nil && selectedRegion == nil {
                if let last = currentTableKeys.last, let oldest = self.oldestTableKey {
                    if last != oldest {
                        fetchMoreTablePosts(tableNumber: tableToLoad, lastVisibleKey: last, { (done) in
                            if done {
                                Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { (timer) in
                                    self.collectionView.reloadData()
                                    self.isLoading = false
                                })
                            }
                        })
                    }
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.indexToPass = indexPath.row
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toTableTableView", sender: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView =
                collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "tableHeader", for: indexPath) as! TableHeaderReusableView
            
            self.headerIndexPath = indexPath
            headerView.profileLabel.font = UIFont.boldSystemFont(ofSize: 24.0)
            headerView.descriptionTextView.layer.borderWidth = 3
            headerView.descriptionTextView.layer.borderColor = UIColor.lightGray.cgColor
            headerView.descriptionTextView.layer.cornerRadius = 8
            headerView.descriptionTextView.isUserInteractionEnabled = false
            headerView.editButton.layer.cornerRadius = 4
            
            if self.selectedCategory != nil {
                headerView.selectCategoryButton.setTitle(self.selectedCategory, for: .normal)
            }
            
            if self.selectedRegion != nil {
                headerView.selectRegionButton.setTitle(self.selectedRegion, for: .normal)
            }
            
            
            let profileDescRef = Database.database().reference()
            profileDescRef.child("profileDescriptions").child(tableToLoad).queryOrderedByKey().observeSingleEvent(of: .value, with: { snap in
                if snap.exists() {
                    if let desc = snap.value as? [String: AnyObject] {
                        if let text = desc["text"] as? String {
                            DispatchQueue.main.async {
                                headerView.descriptionTextView.text = text
                            }
                        }
                    }
                }
            })
            
            headerView.editAction = { (TableHeaderReusableView) in
                if !headerView.descriptionTextView.isUserInteractionEnabled {
                    let editAlert = UIAlertController(title: "Edit Description", message: "Are you sure you want to edit this cadaver's profile? This action will be seen by everyone who views this page.", preferredStyle: UIAlertControllerStyle.alert)
                    editAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                        DispatchQueue.main.async {
                            if headerView.descriptionTextView.text == self.defaultProfileDesc {
                                headerView.descriptionTextView.text = ""
                            }
                            DispatchQueue.main.async {
                                headerView.descriptionTextView.isUserInteractionEnabled = true
                                headerView.editButton.setTitleColor(UIColor.red, for: .normal)
                                headerView.editButton.setTitle("Save", for: .normal)
                                headerView.descriptionTextView.backgroundColor = UIColor.lightGray
                                headerView.descriptionTextView.becomeFirstResponder()
                            }
                        }
                    }))
                    editAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                        // print("Handle Cancel Logic here")
                    }))
                    DispatchQueue.main.async {
                        self.present(editAlert, animated: true, completion: nil)
                    }
                }
                else {
                    let saveAlert = UIAlertController(title: "Save Description", message: "Ready to save?", preferredStyle: UIAlertControllerStyle.alert)
                    let text = ["text": headerView.descriptionTextView.text!.trailingTrim(.whitespacesAndNewlines)]
                    saveAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
                        Database.database().reference().child("profileDescriptions").child(self.tableToLoad).updateChildValues(text, withCompletionBlock: { (error, success) in
                            if error != nil {
                                if let topController = UIApplication.topViewController() {
                                    Helper.showAlertMessage(vc: topController, title: "Error", message: error!.localizedDescription)
                                }
                                return
                            }
                            else {
                                // reset the button
                                DispatchQueue.main.async {
                                    headerView.descriptionTextView.isUserInteractionEnabled = false
                                    headerView.editButton.setTitle("Edit", for: .normal)
                                    headerView.editButton.backgroundColor = UIColor.white
                                    headerView.editButton.setTitleColor(UIColor.black, for: .normal)
                                    headerView.descriptionTextView.backgroundColor = UIColor.white
                                    headerView.descriptionTextView.resignFirstResponder()
                                }
                            }
                        })
                    }))
                    saveAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
                        // print("Handle Cancel Logic here")
                    }))
                    DispatchQueue.main.async {
                        self.present(saveAlert, animated: true, completion: nil)
                    }
                }
                
            }
            
            headerView.selectCategoryAction = { (TableHeaderReusableView) in
                if UIDevice.current.userInterfaceIdiom == .pad {
                    if let popoverContent = self.storyboard?.instantiateViewController(withIdentifier: "SelectCategory") as? SelectCategoryViewController {
                        popoverContent.delegate = self
                        popoverContent.modalPresentationStyle = .popover
                        _ = popoverContent.popoverPresentationController
                        
                        if let popover = popoverContent.popoverPresentationController {
                            let viewForSource = headerView.selectCategoryButton!
                            popover.sourceView = viewForSource
                            popover.sourceRect = viewForSource.bounds
                            popover.permittedArrowDirections = .down
                            popoverContent.preferredContentSize = CGSize(width: 300, height: 200)
                            popoverContent.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
                            popover.delegate = self as? UIPopoverPresentationControllerDelegate
                        }
                        DispatchQueue.main.async {
                            self.present(popoverContent, animated: true, completion: nil)
                        }
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "toSelectCategoryFromTableCV", sender: nil)
                    }
                }
            }
            
            headerView.selectRegionAction = { (TableHeaderReusableView) in
                if UIDevice.current.userInterfaceIdiom == .pad {
                    // print("using iPad")
                    
                    if let popoverContent = self.storyboard?.instantiateViewController(withIdentifier: "SelectRegion") as? SelectRegionViewController {
                        popoverContent.delegate = self
                        popoverContent.modalPresentationStyle = .popover
                        _ = popoverContent.popoverPresentationController
                        
                        if let popover = popoverContent.popoverPresentationController {
                            let viewForSource = headerView.selectRegionButton!
                            popover.sourceView = viewForSource
                            popover.sourceRect = viewForSource.bounds
                            popover.permittedArrowDirections = .down
                            popoverContent.preferredContentSize = CGSize(width: 300, height: 200)
                            popoverContent.popoverPresentationController?.delegate = self as? UIPopoverPresentationControllerDelegate
                            popover.delegate = self as? UIPopoverPresentationControllerDelegate
                        }
                        DispatchQueue.main.async {
                            self.present(popoverContent, animated: false, completion: nil)
                        }
                    }
                    
                }
                else {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "toSelectRegionFromTableCV", sender: nil)
                    }
                }
            }
            
            headerView.seeAllAction = { (TableHeaderReusableView) in
                if self.selectedRegion != nil || self.selectedCategory != nil {
                    self.currentTableKeys.removeAll()
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                        headerView.selectCategoryButton.setTitle("Select Category", for: .normal)
                        headerView.selectRegionButton.setTitle("Select Region", for: .normal)
                    }
                    self.selectedRegion = nil
                    self.selectedCategory = nil
                    self.fetchInitialTablesPosts(tableNumber: self.tableToLoad, { (done) in
                        if done {
                            Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                                self.collectionView.reloadData()
                                self.isLoading = false
                            })
                        }
                    })
                }
            }
            header = headerView
            return headerView
            
            
        default:
            assert(false, "Unexpected element kind")
            return UICollectionReusableView()
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {        
        if segue.identifier == "toTableTableView" {
            if let destination = segue.destination as? TableTableViewVC {
                if self.selectedCategory != nil && self.selectedRegion != nil {
                    destination.category = self.selectedCategory
                    destination.region = self.selectedRegion
                    destination.showingCategoryRegion = true
                    destination.oldestKey = self.oldestTableCategoryRegionKey
                }
                else if self.selectedCategory != nil {
                    destination.category = self.selectedCategory
                    destination.showingCategoryPosts = true
                    destination.oldestKey = self.oldestTableCategoryKey
                }
                else if self.selectedRegion != nil {
                    destination.region = self.selectedRegion
                    destination.showingRegionPosts = true
                    destination.oldestKey = self.oldestTableRegionKey
                }
                else {
                    destination.showingAllPosts = true
                    destination.oldestKey = self.oldestTableKey
                }
                destination.postKeys = self.currentTableKeys
                destination.tableNumber = self.tableToLoad
                destination.indexToScrollTo = self.indexToPass
            }
        }
        else if segue.identifier == "toSelectCategoryFromTableCV" {
            if let vc = segue.destination as? SelectCategoryViewController {
                vc.fromTableCV = true
            }
        }
        else if segue.identifier == "toSelectRegionFromTableCV" {
            if let vc = segue.destination as? SelectRegionViewController {
                vc.fromTableCV = true
            }
        }
    }
    
    func inputData(section: String, data: String) {
        // determine where the data goes
        if section == "Category" {
            selectedCategory = data
            header.selectCategoryButton.setTitle(selectedCategory, for: .normal)
            // update the post array
            if selectedRegion == nil && selectedCategory != nil {
                fetchCategoryPosts(tableNumber: self.tableToLoad, category: self.selectedCategory!, { (done) in
                    if done {
                        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                            self.collectionView.reloadData()
                            self.isLoading = false
                        })
                    }
                })
            }
            else if selectedRegion != nil && selectedCategory != nil {
                fetchCategoryRegionPosts(tableNumber: self.tableToLoad, category: self.selectedCategory!, region: self.selectedRegion!, { (done) in
                    if done {
                        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                            self.collectionView.reloadData()
                            self.isLoading = false
                        })
                    }
                })
            }
        }
        else if section == "Region" {
            selectedRegion = data
            header.selectRegionButton.setTitle(selectedRegion, for: .normal)
            if selectedCategory == nil && selectedRegion != nil {
                fetchRegionPosts(tableNumber: self.tableToLoad, region: self.selectedRegion!, { (done) in
                    if done {
                        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                            self.collectionView.reloadData()
                            self.isLoading = false
                        })
                    }
                })
            }
            else if selectedCategory != nil && selectedRegion != nil {
                fetchCategoryRegionPosts(tableNumber: self.tableToLoad, category: self.selectedCategory!, region: self.selectedRegion!, { (done) in
                    if done {
                        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                            self.collectionView.reloadData()
                            self.isLoading = false
                        })
                    }
                })
            }
        }
    }
    
    /* MARKER: DATABASE
     - All functions needed for filtering and pagination of the table collectionView
     */
    func fetchCategoryPosts(tableNumber: String, category: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        if !self.currentTableKeys.isEmpty {
            self.currentTableKeys.removeAll()
            self.collectionView.reloadData()
        }
        self.fetchOldestTableCategoryKey(tableNumber: tableNumber, category: category)
        let databaseReference = Database.database().reference()
        databaseReference.child(tableNumber).child(category).queryOrderedByKey().queryLimited(toLast: 13).observeSingleEvent(of: .value, with: { keySnap in
            if !keySnap.exists() {
                // nothing to load
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                    completion(true)
                })
            }
            for child in keySnap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    databaseReference.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                        if let post = snap.value as? [String: AnyObject] {
                            if let likes = post["likes"] as? Int, let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let author = post["author"] as? String {
                                
                                if passedData.blockedUsers[userID] == nil {
                                    let posst = Post()
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
                                    
                                    passedData.postDict[postID] = posst
                                    if self.currentTableKeys.index(of: postID) == nil {
                                        self.currentTableKeys.insert(postID, at: 0)
                                    }
                                    self.collectionView.reloadData()
                                }
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                            completion(true)
                        })
                    })
                }
            }
        })
    }
    
    func fetchMoreCategoryPosts(tableNumber: String, category: String, lastVisibleKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = currentTableKeys.count
        let databaseReference = Database.database().reference()
        databaseReference.child(tableNumber).child(category).queryOrderedByKey().queryEnding(atValue: lastVisibleKey).queryLimited(toLast: 14).observeSingleEvent(of: .value, with: { keySnap in
            for child in keySnap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    if self.currentTableKeys.index(of: key) == nil {
                        databaseReference.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                            if let post = snap.value as? [String: AnyObject] {
                                if let postID = post["postID"] as? String {
                                    if postID != lastVisibleKey {
                                        if let pathToImage = post["pathToImage"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let category = post["category"] as? String, let likes = post["likes"] as? Int, let author = post["author"] as? String {
                                            
                                            if passedData.blockedUsers[userID] == nil {
                                                let posst = Post()
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
                                                
                                                passedData.postDict[postID] = posst
                                                if self.currentTableKeys.index(of: postID) == nil {
                                                    self.currentTableKeys.insert(postID, at: currentNumberOfPosts)
                                                }
                                                self.collectionView.reloadData()
                                            }
                                        }
                                    }
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                                completion(true)
                            })
                        })
                    }
                }
            }
        })
    }
    
    
    func fetchRegionPosts(tableNumber: String, region: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        if !currentTableKeys.isEmpty {
            self.currentTableKeys.removeAll()
            self.collectionView.reloadData()
        }
        self.fetchOldestTableRegionKey(tableNumber: tableNumber, region: region)
        let databaseReference = Database.database().reference()
        databaseReference.child(tableNumber).child(region).queryOrderedByKey().queryLimited(toLast: 13).observeSingleEvent(of: .value, with: { keySnap in
            if !keySnap.exists() {
                // nothing to load
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                    completion(true)
                })
            }
            for child in keySnap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    databaseReference.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                        if let post = snap.value as? [String: AnyObject] {
                            if let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let likes = post["likes"] as? Int, let author = post["author"] as? String {
                                
                                if passedData.blockedUsers[userID] == nil {
                                    let posst = Post()
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
                                    
                                    passedData.postDict[postID] = posst
                                    if self.currentTableKeys.index(of: postID) == nil {
                                        self.currentTableKeys.insert(postID, at: 0)
                                    }
                                    self.collectionView.reloadData()
                                }
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                            completion(true)
                        })
                    })
                }
            }
        })
    }
    
    func fetchMoreRegionPosts(tableNumber: String, region: String, lastVisibleKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = currentTableKeys.count
        let databaseReference = Database.database().reference()
        databaseReference.child(tableNumber).child(region).queryOrderedByKey().queryEnding(atValue: lastVisibleKey).queryLimited(toLast: 14).observeSingleEvent(of: .value, with: { keySnap in
            for child in keySnap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    if self.currentTableKeys.index(of: key) == nil {
                        databaseReference.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                            if let post = snap.value as? [String: Any] {
                                if let postID = post["postID"] as? String {
                                    if postID != lastVisibleKey {
                                        if let category = post["category"] as? String, let pathToImage = post["pathToImage"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let numLikes = post["likes"] as? Int, let reg = post["region"] as? String, let author = post["author"] as? String {
                                            
                                            if passedData.blockedUsers[userID] == nil {
                                                let posst = Post()
                                                posst.author = author
                                                posst.pathToImage = pathToImage
                                                posst.postID = postID
                                                posst.userID = userID
                                                posst.fancyPostDescription = Helper.createAttributedString(author: author, postText: postDescription)
                                                posst.postDescription = postDescription
                                                posst.timestamp = timestamp
                                                posst.table = table
                                                posst.region = reg
                                                posst.category = category
                                                posst.numberOfComments = numberOfComments
                                                posst.likes = numLikes
                                                posst.userWhoPostedLabel = Helper.createAttributedPostLabel(username: author, table: table, region: region, category: category)
                                                
                                                // Check if the post has two images if it does get the other path
                                                if let originalPath = post["pathToOriginal"] as? String {
                                                    posst.pathToOriginal = originalPath
                                                }
                                                
                                                passedData.postDict[postID] = posst
                                                if self.currentTableKeys.index(of: postID) == nil {
                                                    self.currentTableKeys.insert(postID, at: currentNumberOfPosts)
                                                }
                                                self.collectionView.reloadData()
                                            }
                                        }
                                    }
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                                completion(true)
                            })
                        })
                    }
                }
            }
        })
    }
    
    func fetchCategoryRegionPosts(tableNumber: String, category: String, region: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        if !self.currentTableKeys.isEmpty {
            self.currentTableKeys.removeAll()
            self.collectionView.reloadData()
        }
        self.fetchOldestTableCategoryRegionKey(tableNumber: tableNumber, category: category, region: region)
        let databaseReference = Database.database().reference()
        databaseReference.child(tableNumber).child(category).child(region).queryLimited(toLast: 13).observeSingleEvent(of: .value, with: { keySnap in
            if !keySnap.exists() {
                // nothing to load
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                    completion(true)
                })
            }
            for child in keySnap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    databaseReference.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                        if snap.exists() {
                            if let post = snap.value as? [String: AnyObject] {
                                if let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let numLikes = post["likes"] as? Int, let author = post["author"] as? String {
                                    
                                    if passedData.blockedUsers[userID] == nil {
                                        let posst = Post()
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
                                        posst.likes = numLikes
                                        posst.userWhoPostedLabel = Helper.createAttributedPostLabel(username: author, table: table, region: region, category: category)
                                        
                                        // Check if the post has two images if it does get the other path
                                        if let originalPath = post["pathToOriginal"] as? String {
                                            posst.pathToOriginal = originalPath
                                        }
                                        
                                        passedData.postDict[postID] = posst
                                        if self.currentTableKeys.index(of: postID) == nil {
                                            self.currentTableKeys.insert(postID, at: 0)
                                        }
                                        self.collectionView.reloadData()
                                    }
                                }
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                            completion(true)
                        })
                    })
                }
            }
        })
    }
    
    
    func fetchMoreCategoryRegionPosts(tableNumber: String, category: String, region: String, lastVisibleKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = currentTableKeys.count
        let databaseReference = Database.database().reference()
        databaseReference.child(tableNumber).child(category).child(region).queryOrderedByKey().queryEnding(atValue: lastVisibleKey).queryLimited(toLast: 14).observeSingleEvent(of: .value, with: { keySnap in
            for child in keySnap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    if self.currentTableKeys.index(of: key) == nil {
                        databaseReference.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                            if let post = snap.value as? [String: Any] {
                                if let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let numLikes = post["likes"] as? Int, let author = post["author"] as? String {
                                    
                                    if passedData.blockedUsers[userID] == nil {
                                        let posst = Post()
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
                                        posst.likes = numLikes
                                        posst.userWhoPostedLabel = Helper.createAttributedPostLabel(username: author, table: table, region: region, category: category)
                                        
                                        // Check if the post has two images if it does get the other path
                                        if let originalPath = post["pathToOriginal"] as? String {
                                            posst.pathToOriginal = originalPath
                                        }
                                        
                                        passedData.postDict[postID] = posst
                                        if self.currentTableKeys.index(of: postID) == nil {
                                            self.currentTableKeys.insert(postID, at: currentNumberOfPosts)
                                        }
                                        self.collectionView.reloadData()
                                    }
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                                completion(true)
                            })
                        })
                    }
                }
            }
        })
    }
    
    func fetchInitialTablesPosts(tableNumber: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        if !self.currentTableKeys.isEmpty {
            self.currentTableKeys.removeAll()
            self.collectionView.reloadData()
        }
        self.fetchOldestTableKey(tableNumber: tableNumber)
        let databaseReference = Database.database().reference()
        databaseReference.child(tableNumber).child("all").queryOrderedByKey().queryLimited(toLast: 13).observeSingleEvent(of: .value, with: { keySnap in
            // print("keySnap: \(keySnap)")
            if !keySnap.exists() {
                // no table posts
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                    completion(true)
                })
            }
            for child in keySnap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    // print("key \(key)")
                    // go get the post from "posts"
                    databaseReference.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                        // print("snap \(snap)")
                        if let post = snap.value as? [String: AnyObject] {
                            if let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let likes = post["likes"] as? Int, let author = post["author"] as? String {

                                if passedData.blockedUsers[userID] == nil {
                                    let posst = Post()
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
                                    
                                    passedData.postDict[postID] = posst
                                    if self.currentTableKeys.index(of: key) == nil {
                                        self.currentTableKeys.insert(key, at: 0)
                                    }
                                    self.collectionView.reloadData()
                                }
                            }
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                            completion(true)
                        })
                    })
                }
            }
        })
    }
    
    func fetchMoreTablePosts(tableNumber: String, lastVisibleKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = currentTableKeys.count
        let databaseReference = Database.database().reference()
        databaseReference.child(tableNumber).child("all").queryOrderedByKey().queryEnding(atValue: lastVisibleKey).queryLimited(toLast: 14).observeSingleEvent(of: .value, with: { keySnap in
            for child in keySnap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    if self.currentTableKeys.index(of: key) == nil {
                        databaseReference.child("posts").child(key).observeSingleEvent(of: .value, with: { snap in
                            if !snap.exists() {
                               // print("snap missing for \(key)")
                            }
                            if let post = snap.value as? [String: AnyObject] {
                                if let pathToImage = post["pathToImage"] as? String, let postID = post["postID"] as? String, let postDescription = post["postDescription"] as? String, let timestamp = post["timestamp"] as? Double, let category = post["category"] as? String, let table = post["table"] as? String, let userID = post["userID"] as? String, let numberOfComments = post["numberOfComments"] as? Int, let region = post["region"] as? String, let numLikes = post["likes"] as? Int, let author = post["author"] as? String {
                                    
                                    if passedData.blockedUsers[userID] == nil {
                                        let posst = Post()
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
                                        posst.likes = numLikes
                                        posst.userWhoPostedLabel = Helper.createAttributedPostLabel(username: author, table: table, region: region, category: category)
                                        
                                        // Check if the post has two images if it does get the other path
                                        if let originalPath = post["pathToOriginal"] as? String {
                                            posst.pathToOriginal = originalPath
                                        }
                                        
                                        passedData.postDict[postID] = posst
                                        if self.currentTableKeys.index(of: postID) == nil {
                                            self.currentTableKeys.insert(postID, at: currentNumberOfPosts)
                                        }
                                        self.collectionView.reloadData()
                                    }
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                                completion(true)
                            })
                        })
                    }
                }
            }
        })
    }
    
    // Get the oldest keys so we know when to stop querying
    // Need to get
    // Oldest table key, oldest table region key, oldest table category, and oldest tableCategory
    func fetchOldestTableKey(tableNumber: String) {
        let ref = Database.database().reference()
        ref.child(tableNumber).child("all").queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    self.oldestTableKey = key
                }
            }
        })
    }
    
    func fetchOldestTableCategoryKey(tableNumber: String, category: String) {
        let ref = Database.database().reference()
        ref.child(tableNumber).child(category).queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    self.oldestTableCategoryKey = key
                }
            }
        })
    }
    
    func fetchOldestTableRegionKey(tableNumber: String, region: String) {
        let ref = Database.database().reference()
        ref.child(tableNumber).child(region).queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    self.oldestTableRegionKey = key
                }
            }
        })
    }
    
    func fetchOldestTableCategoryRegionKey(tableNumber: String, category: String, region: String) {
        let ref = Database.database().reference()
        ref.child(tableNumber).child(category).child(region).queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    self.oldestTableCategoryRegionKey = key
                }
            }
        })
    }
}


