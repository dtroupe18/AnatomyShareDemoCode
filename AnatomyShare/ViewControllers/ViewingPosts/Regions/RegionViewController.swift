//
//  RegionViewController.swift
//  AnatomyShare
//
//  Created by Dave on 1/4/18.
//  Copyright © 2018 Dave. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Kingfisher

class RegionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var plusButton: UIBarButtonItem!
    
    // value passed in from previous VC
    var regionToLoad: String?
    
    // Loaded so we know when to stop getting posts
    // this can probably be removed?
    var oldestKey: String?
    
    // datasource - list of keys that we use to query
    // posts -> key = a regionToLoad Post
    var regionKeys = [String]()
    
    // Pagination Variable
    var isLoading: Bool = false
    
    // Variables to pass to tableview
    var indexToPass: Int?
    
    // Pull to refresh
    var refreshControl: UIRefreshControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        
        if let reg = regionToLoad {
            self.title = reg
            self.fetchRegionPosts(region: reg, { (granted) in
                if granted {
                    self.collectionView.reloadData()
                    self.isLoading = false
                }
            })
            self.fetchOldestRegionPostKey(region: reg)
        }
        
        let flow = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flow.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        let width = UIScreen.main.bounds.size.width
        flow.itemSize = CGSize(width: width / 3.0, height: width / 3.0)
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        
        self.extendedLayoutIncludesOpaqueBars = false
        self.hideKeyboardWhenTappedAround()
        
        collectionView.alwaysBounceVertical = true // so you can pulldown when there aren't enough posts
        
        // Pull to Refresh
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "Refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh), for: UIControlEvents.valueChanged)
        collectionView.addSubview(refreshControl)
        
        // Reload for filter
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadCollectionView), name: NSNotification.Name(rawValue: "reloadRegionCollectionView"), object: nil)
    }
    
    // Pull to Refresh
    @objc func refresh(sender: AnyObject) {
        if regionToLoad != nil && !self.isLoading {
            self.fetchRegionPosts(region: regionToLoad!, { (granted) in
                if granted {
                    self.collectionView.reloadData()
                    self.refreshControl.endRefreshing()
                    self.isLoading = false
                }
            })
        }
    }
    
    @objc private func reloadCollectionView() {
        self.collectionView.reloadData()
    }
    
    @IBAction func plusPressed(_ sender: Any) {
        DispatchQueue.main.async{
            let storyboard: UIStoryboard = UIStoryboard(name: "CreatePost", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "CameraViewController")
            self.show(vc, sender: self)
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Marker CollectionView Delegate
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if self.regionKeys.isEmpty {
            return 0
        }
        else {
            var numberOfRows = 0
            for key in self.regionKeys {
                if passedData.postDict[key] != nil {
                    numberOfRows += 1
                }
                else {
                    if let index = self.regionKeys.index(of: key) {
                        self.regionKeys.remove(at: index)
                    }
                }
            }
            return numberOfRows
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let key = regionKeys[indexPath.row]

        if let post = passedData.postDict[key] {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
            cell.indexPath = indexPath
            cell.layer.borderWidth = 1
            cell.layer.borderColor = UIColor.black.cgColor
            
            
            if passedData.postDict[key]?.userID != "BLOCKED" {
                let url = URL(string: post.pathToImage)
                cell.imageView.kf.setImage(with: url)
            }
            else {
                // Blocked User
                cell.imageView.image = #imageLiteral(resourceName: "UserBlocked")
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
    
    // handle cell touch
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.indexToPass = indexPath.row
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toRegionsTableView", sender: nil)
        }
    }
    
    // Pass variables before segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toRegionsTableView" {
            if let destination = segue.destination as? RegionsTableVC {
                destination.regionToLoad = self.regionToLoad
                destination.regionKeys = self.regionKeys
                destination.indexToScrollTo = self.indexToPass
                destination.oldestKey = self.oldestKey
            }
        }
    }
    
    // Horizontal Support - recalculate cell size on orientation change
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
    
    // Marker: When to load more posts
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row + 1 >= self.regionKeys.count && !self.isLoading {
            // print("might need to load more posts")
            if let reg = self.regionToLoad, let last = regionKeys.last, let oldest = self.oldestKey {
                // print("oldest: \(oldest) == \(last)")
                if last != oldest {
                    // print("going to load more posts")
                    self.isLoading = true
                    self.fetchMoreRegionPosts(region: reg, lastVisibleKey: last, { (granted) in
                        if granted {
                            Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block: { (timer) in
                                self.collectionView.reloadData()
                                self.isLoading = false
                            })
                        }
                    })
                }
            }
        }
    }
    
    // Marker: Get Oldest Key
    // This is done so we know if we should try to load more posts or not
    func fetchOldestRegionPostKey(region: String) {
        let databaseReference = Database.database().reference()
        databaseReference.child(region).queryOrderedByKey().queryLimited(toFirst: 1).observeSingleEvent(of: .value, with: { snap in
            for child in snap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    self.oldestKey = key
                }
            }
        })
    }
    
    // Marker: Loading Posts
    func fetchRegionPosts(region: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        // check to see if there are existing posts from a previous loading of this screen
        if !self.regionKeys.isEmpty {
            self.regionKeys.removeAll()
            self.collectionView.reloadData()
        }
        
        let databaseReference = Database.database().reference()
        databaseReference.child(region).queryOrderedByKey().queryLimited(toLast: 15).observeSingleEvent(of: .value, with: { keySnap in
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
                                    if self.regionKeys.index(of: postID) == nil {
                                        self.regionKeys.insert(postID, at: 0)
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
    
    // Paging fetch
    func fetchMoreRegionPosts(region: String, lastVisibleKey: String, _ completion: @escaping (Bool) -> ()) {
        self.isLoading = true
        let currentNumberOfPosts = self.regionKeys.count
        let databaseReference = Database.database().reference()
        
        databaseReference.child(region).queryOrderedByKey().queryEnding(atValue: lastVisibleKey).queryLimited(toLast: 15).observeSingleEvent(of: .value, with: { keySnap in
            for child in keySnap.children {
                let child = child as? DataSnapshot
                if let key = child?.key {
                    if self.regionKeys.index(of: key) == nil {
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
                                                if self.regionKeys.index(of: postID) == nil {
                                                    self.regionKeys.insert(postID, at: currentNumberOfPosts)
                                                }
                                                self.collectionView.reloadData()
                                            }
                                        }
                                    }
                                }
                            }
                            // completion
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75, execute: {
                                completion(true)
                            })
                        })
                    }
                }
            }
        })
    }
}
