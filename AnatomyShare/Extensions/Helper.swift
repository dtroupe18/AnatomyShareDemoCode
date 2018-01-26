//
//  Helper.swift
//  FakeInstagram
//
//  Created by David Troupe on 5/25/17.
//  Copyright © 2017 David Troupe. All rights reserved.
//

import Foundation
import UIKit

class Helper {
    
    static func presentMoreInformation() {
        let moreInformationAlert = UIAlertController(title: "AnatomyShare Information", message: "Thank you for expressing interest in AnatomyShare. You can contact us at AnatomyShareTeam@gmail.com or vist our website.", preferredStyle: UIAlertControllerStyle.alert)
        
        moreInformationAlert.addAction(UIAlertAction(title: "Visit Website", style: .default, handler: { (action: UIAlertAction!) in
            if let url = URL(string: websiteURL) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        
        moreInformationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            // print("Handle Cancel Logic here")
        }))
        DispatchQueue.main.async {
            if let topController = UIApplication.topViewController() {
                topController.present(moreInformationAlert, animated: true, completion: nil)
            }
            else {
                return
            }
        }
    }
    
    static func presentPrivacyPolicy() {
        let privacyAlert = UIAlertController(title: "AnatomyShare Privacy Policy", message: "Would you like to view our Privacy Policy?", preferredStyle: UIAlertControllerStyle.alert)
        
        privacyAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            if let url = URL(string: privacyPolicyURL) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        
        privacyAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            // print("Handle Cancel Logic here")
        }))
        DispatchQueue.main.async {
            if let topController = UIApplication.topViewController() {
                topController.present(privacyAlert, animated: true, completion: nil)
            }
            else {
                return
            }
        }

    }
    
    static func presentHelpInformation() {
        let helpAlert = UIAlertController(title: "AnatomyShare Information", message: "You can contact us at AnatomyShareTeam@gmail.com or vist our website.", preferredStyle: UIAlertControllerStyle.alert)
        
        helpAlert.addAction(UIAlertAction(title: "Visit Website", style: .default, handler: { (action: UIAlertAction!) in
            if let url = URL(string: websiteURL) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        
        helpAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            // print("Handle Cancel Logic here")
        }))
        DispatchQueue.main.async {
            if let topController = UIApplication.topViewController() {
                topController.present(helpAlert, animated: true, completion: nil)
            }
            else {
                return
            }
        }
    }
    
    static func showAlertMessage(vc: UIViewController, title: String, message: String) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(defaultAction)
        DispatchQueue.main.async {
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
    static func convertTimestamp(serverTimestamp: Double) -> String {
        let x = serverTimestamp / 1000
        let date = NSDate(timeIntervalSince1970: x)
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        
        return formatter.string(from: date as Date)
    }
    
    static func createAttributedString(author: String, postText: String) -> NSMutableAttributedString {
        let fullPostText = author + ": " + postText
        let authorWordRange = (fullPostText as NSString).range(of: author)
        let attributedString = NSMutableAttributedString(string: fullPostText, attributes: [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 16)])
        attributedString.setAttributes([NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16), NSAttributedStringKey.foregroundColor : UIColor.black], range: authorWordRange)
        
        return attributedString
    }
    
    static func createAttributedPostLabel(username: String, table: String, region: String, category: String) -> NSMutableAttributedString {
        let firstHalf = username + " posted in "
        let secondHalf = "\(table): \(region) | \(category)"
        let string = firstHalf + secondHalf as NSString
        let attributedString = NSMutableAttributedString(string: string as String, attributes: [NSAttributedStringKey.font:UIFont.systemFont(ofSize: 16.0)])
        
        let boldFontAttribute = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16.0)]
        
        // Part of string to be bold
        attributedString.addAttributes(boldFontAttribute, range: string.range(of: username))
        attributedString.addAttributes(boldFontAttribute, range: string.range(of: table))        
        return attributedString
    }
    
    static func createAttributedPostDescriptionLabel(table: String, category: String, region: String) -> NSMutableAttributedString {
        let string = "Post in... \(table) | \(category) | \(region)" as NSString
        let attributedString = NSMutableAttributedString(string: string as String, attributes: [NSAttributedStringKey.font:UIFont.systemFont(ofSize: 18.0)])
        
        let boldFontAttribute = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 16.0)]
        let range = (string as NSString).range(of: "Post in...")
        
        // Part of string to be bold
        attributedString.addAttribute(NSAttributedStringKey.foregroundColor, value: UIColor.lightGray , range: range)
        attributedString.addAttributes(boldFontAttribute, range: string.range(of: table))
        attributedString.addAttributes(boldFontAttribute, range: string.range(of: category))
        attributedString.addAttributes(boldFontAttribute, range: string.range(of: region))
        
        return attributedString
    }
    
    static func reloadEverything() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadNewsFeedTableView"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTableCollectionView"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadUserCollectionView"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadTableTableView"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadRegionCollectionView"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadRegionTableView"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reloadSearchTableView"), object: nil)
    }
    
    static func refreshEverything() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshNewsfeed"), object: nil)
    }
}
