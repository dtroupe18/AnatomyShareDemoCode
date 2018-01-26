//
//  DraftsViewController.swift
//  AnatomyShare
//
//  Created by Dave on 12/29/17.
//  Copyright © 2017 Dave. All rights reserved.
//

import UIKit
import CoreData

class DraftsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    var draftToPass: PostDraft?
    var drafts = [PostDraft]()
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    let fileManager = FileManager.default
    
    var postDraftFromEdit: PostDraft?
    var fromEditVC: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(self.clearDrafts), name: NSNotification.Name(rawValue: "clearLoadedDrafts"), object: nil)
        
        let clearAllButton = UIButton(type: .custom)
        clearAllButton.setTitle("Clear All", for: .normal)
        clearAllButton.setTitleColor(UIColor.white, for: .normal)
        clearAllButton.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        clearAllButton.addTarget(self, action: #selector(self.clearImageCache), for: .touchUpInside)
        let barButton = UIBarButtonItem(customView: clearAllButton)
        self.navigationItem.setRightBarButton(barButton, animated: true)
        initialize()
    }
    
    @objc private func clearDrafts() {
        drafts.removeAll()
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARKER: CollectionView
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return drafts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DraftCell", for: indexPath) as! DraftCell
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.black.cgColor
        cell.deleteTapAction = { (DraftCell) in
            self.askToConfirmDelete(indexPath: indexPath)
        }
        
        // display the annotated image by default
        if let annotatedImage = drafts[indexPath.row].annotatedImage {
            cell.imageView.image = annotatedImage
            return cell
            
        }
        // if there's not annotated image then we display the original image
        else {
            cell.imageView.image = drafts[indexPath.row].originalImage
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.draftToPass = self.drafts[indexPath.row]
        // if we are from edit and the draft has both images we go back to edit
        // otherwise we want to move on to annotateVC
        if fromEditVC && self.draftToPass?.annotatedImage != nil, let editDraft = self.postDraftFromEdit {
            // check if the saved draft has table, cat, reg, or text
            // if it doesn't update it to have the values from the postDraft passed in
            if self.draftToPass?.table == nil {
                self.draftToPass?.table = editDraft.table
            }
            if self.draftToPass?.category == nil {
                self.draftToPass?.category = editDraft.category
            }
            if self.draftToPass?.region == nil {
                self.draftToPass?.region = editDraft.region
            }
            if self.draftToPass?.text == nil {
                self.draftToPass?.text = editDraft.text
            }
            self.draftToPass?.key = editDraft.key
            self.draftToPass?.popIndex = editDraft.popIndex
            DispatchQueue.main.async {
                _ = self.navigationController?.popViewController(animated: true)
                if let previousVC = self.navigationController?.viewControllers.last as? EditPostViewController {
                    previousVC.postDraft = self.draftToPass
                    previousVC.imageChanged = true
                }
            }
        }
        else {
            if self.fromEditVC, let editDraft = self.postDraftFromEdit {
                if self.draftToPass?.table == nil {
                    self.draftToPass?.table = editDraft.table
                }
                if self.draftToPass?.category == nil {
                    self.draftToPass?.category = editDraft.category
                }
                if self.draftToPass?.region == nil {
                    self.draftToPass?.region = editDraft.region
                }
                if self.draftToPass?.text == nil {
                    self.draftToPass?.text = editDraft.text
                }
                self.draftToPass?.key = editDraft.key
                self.draftToPass?.popIndex = editDraft.popIndex
            }
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "toAnnotateFromDrafts", sender: nil)
            }
        }
    }
    
    // MARKER: Delete
    private func askToConfirmDelete(indexPath: IndexPath) {
        let confirmAlert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete this image? This action cannot be undone.", preferredStyle: .alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            // call function to delete
            if let folder = self.drafts[indexPath.row].folderName {
               self.deleteImageFromDisk(folderName: folder, index: indexPath.row)
            }
        }))
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            // do nothing
        }))
        
        self.present(confirmAlert, animated: true, completion: nil)
    }
    
    // Delete From Disk
    private func deleteImageFromDisk(folderName: String, index: Int) {
        DispatchQueue.global(qos: .utility).async {
            let documentsURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let directoryPath = documentsURL.appendingPathComponent("Drafts/\(folderName)")
            
            if self.fileManager.fileExists(atPath: directoryPath.absoluteURL.path) {
                do {
                    try self.fileManager.removeItem(at: directoryPath)
                    self.drafts.remove(at: index)
                    self.deleteDraftFromCoreData(folderName: folderName)
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
                catch {
                    let deleteFailedAlert = UIAlertController(title: "Unable to Delete Photo", message: "Please try again.", preferredStyle: .alert)
                    
                    let ok = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                    // relate actions to controllers
                    deleteFailedAlert.addAction(ok)
                    DispatchQueue.main.async {
                        self.present(deleteFailedAlert, animated: true, completion: nil)
                    }
                    print(error.localizedDescription)
                }
            }
        }
    }
    // Delete From CoreData
    private func deleteDraftFromCoreData(folderName: String) {
        DispatchQueue.global(qos: .utility).async {
            if let appDel = self.appDelegate {
                // Fetch only the record with that folder name
                let container = appDel.persistentContainer
                let context = container.viewContext
                let fetchRequest = NSFetchRequest<Draft>(entityName: "Draft")
                let condition = NSPredicate(format: "folderName == \(folderName)")
                fetchRequest.predicate = condition
                
                do {
                    let results = try context.fetch(fetchRequest)
                    for result in results {
                        context.delete(result)
                    }
                }
                catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    // Marker: Fetch From Core Data
    func fetchFromCoreData() {
        DispatchQueue.global(qos: .utility).async {
            if let appDel = self.appDelegate {
                let container = appDel.persistentContainer
                let context = container.viewContext
                let fetchRequest = NSFetchRequest<Draft>(entityName: "Draft")
                let documentsURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileManager = FileManager.default
                
                do {
                    let drafts = try context.fetch(fetchRequest)
                    for draft in drafts.reversed() {
                        if let folderName = draft.folderName {
                            let folderPath = documentsURL.appendingPathComponent("/Drafts/\(folderName)")
                            // if this folder no longer exists the record was deleted from disk, but not from
                            // coreData so we delete it now. This also prevents errors if we try to load
                            // any non-existing folder
                            if !fileManager.fileExists(atPath: folderPath.path) {
                                context.delete(draft)
                            }
                            else {
                                // folder exists so we can load the images inside
                                let fileNames = try fileManager.contentsOfDirectory(atPath: folderPath.path)
                                let postDraft = PostDraft()
                                
                                postDraft.folderName = folderName
                                postDraft.table = draft.table
                                postDraft.category = draft.category
                                postDraft.region = draft.region
                                postDraft.text = draft.postDescription
                                postDraft.annotatedImageName = draft.annotatedImageName
                                postDraft.originalImageName = draft.originalImageName
                                postDraft.textOne = draft.textOne
                                postDraft.textTwo = draft.textTwo
                                postDraft.textThree = draft.textThree
                                postDraft.textFour = draft.textFour
                                postDraft.textFive = draft.textFive
                                
                                for fileName in fileNames {
                                    let imagePath = folderPath.appendingPathComponent(fileName)
                                    if fileManager.fileExists(atPath: imagePath.path) {
                                        if let contentsOfFile = UIImage(contentsOfFile: imagePath.path) {
                                            let upImage = contentsOfFile.correctlyOrientedImage()
                                            if postDraft.originalImage == nil {
                                                postDraft.originalImage = upImage
                                                postDraft.originalImageName = fileName
                                            }
                                            else if postDraft.annotatedImage == nil {
                                                postDraft.annotatedImage = upImage
                                                postDraft.annotatedImageName = fileName
                                            }
                                        }
                                    }
                                }
                                // prevents duplicates from being added
                                // this is needed because we want to refetch
                                // the results everytime this view appears
                                if !self.drafts.contains(postDraft) {
                                    // always insert items at the front so the newest draft is first
                                    self.drafts.append(postDraft)
                                    DispatchQueue.main.async {
                                        self.collectionView.reloadData()
                                    }
                                }
                            }
                        }
                    }
                }
                catch {
                    print("error retrieving images from core data")
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @objc private func clearImageCache() {
        let confirmAlert = UIAlertController(title: "Confirm Delete", message: "Are you sure you want to delete all of your drafts? This action cannot be undone.", preferredStyle: .alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            // call function to delete
            let documentsURL = self.fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let directoryPath = documentsURL.appendingPathComponent("Drafts")
            
            do {
                let files = try self.fileManager.contentsOfDirectory(atPath: directoryPath.path)
                for file in files {
                    try self.fileManager.removeItem(at: directoryPath.appendingPathComponent("\(file)"))
                    self.deleteDraftFromCoreData(folderName: file)
                    self.clearDrafts()
                }           
            }
            catch {
                print(error.localizedDescription)
            }
        }))
        
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            // do nothing
        }))
        
        self.present(confirmAlert, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toAnnotateFromDrafts" {
            if let destination = segue.destination as? AnnotateViewController {
                if self.draftToPass != nil {
                    destination.postDraft = self.draftToPass
                    destination.isSavedDraft = true
                    destination.fromEditVC = self.fromEditVC
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        // pass data back to edit if needed
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.fetchFromCoreData()
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
    
    private func initialize() {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        // CollectionView setup
        collectionView.delegate = self
        collectionView.dataSource = self
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
            let width = UIScreen.main.bounds.size.width
            flow.minimumInteritemSpacing = 0
            flow.minimumLineSpacing = 0
            
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                flow.itemSize = CGSize(width: width / 2.0, height: width / 2.0)
            case .pad:
                flow.itemSize = CGSize(width: width / 3.0, height: width / 3.0)
            case .unspecified:
                flow.itemSize = CGSize(width: width / 2.0, height: width / 2.0)
            default:
                flow.itemSize = CGSize(width: width / 2.0, height: width / 2.0)
            }
        }
        
        self.fetchFromCoreData()
    }
}
