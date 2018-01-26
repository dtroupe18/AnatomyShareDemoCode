//
//  AppDelegate.swift
//  AnatomyShare
//
//  Created by David Troupe on 5/23/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import UIKit
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    class func instance() -> AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
    
    // MARKER: CORE DATA
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "AnatomyShare")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                let nserror = error as NSError
                // fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                
                if let topController = UIApplication.topViewController() {
                    CustomActivityIndicator.sharedInstance.hideActivityIndicator(uiView: topController.view)
                    Helper.showAlertMessage(vc: topController, title: "Save Error", message: nserror.localizedDescription)
                }
                return
            }
        }
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if !passedData.isDebug {
            let releaseOptions = FirebaseOptions(googleAppID: "", gcmSenderID: "")
            releaseOptions.bundleID = ""
            releaseOptions.apiKey = ""
            releaseOptions.clientID = ""
            releaseOptions.databaseURL = ""
            releaseOptions.storageBucket = ""
            FirebaseApp.configure(options: releaseOptions)
        }
        else if passedData.isDebug {
            let debugOptions = FirebaseOptions(googleAppID: "", gcmSenderID: "")
            debugOptions.bundleID = ""
            debugOptions.apiKey = ""
            debugOptions.clientID = ""
            debugOptions.databaseURL = ""
            debugOptions.storageBucket = ""
            FirebaseApp.configure(options: debugOptions)
        }
        
        if CommandLine.arguments.contains("--uitesting") {
            resetState()
        }
        
        UINavigationBar.appearance().barTintColor = UIColor(red: 205/256, green: 0/255, blue: 0/255, alpha: 1)
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white]
        DatabaseFunctions.getUserLikes()
        DatabaseFunctions.getBlockedUsers()
        return true
    }
    
    func resetState() {
        // Function to reset the state of the app for UITesting
        //
        
        // Clear user defaults so the EULA is displayed
        //
        guard let defaultsName = Bundle.main.bundleIdentifier else { return }
        UserDefaults.standard.removePersistentDomain(forName: defaultsName)
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // clear some data?
        // passedData = PassedData()
    
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        DatabaseFunctions.getUserLikes()
        DatabaseFunctions.getBlockedUsers()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // clear some data?
        passedData = PassedData()
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

