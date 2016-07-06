//
//  MenuController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/20/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian


import UIKit
import AWSCognitoIdentityProvider

class MenuController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    enum MenuData: Int {
        case YOUR_ACCOUNT
        case LINKED_ACCOUNTS
        case NOTIFICATIONS
        case INVITE_FRIENDS
        case HELP
        case TERMS
        case CLEAR_HISTORY
        case LOG_OUT
    }
    
    @IBOutlet weak var linkedAccountsCollectionView: UICollectionView!
    @IBOutlet weak var realNameLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var numFollowersLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    
    
    var currentUserName : String!
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var socialMediaUserNames: NSMutableDictionary!

    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube" /*, "phone"*/)

    
    override func viewDidLoad() {
        
        // Make the profile photo round
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width / 2
        
        
        
        // Fetch the user's username and real name
        currentUserName = getCurrentUser()
//        currentRealName = getCurrentRealUser()
        
        // Set the UI
        realNameLabel.text = "Real name"
        userNameLabel.text = currentUserName
        numFollowersLabel.text = "120"
        
        // Set up dictionary for user's social media names
        socialMediaUserNames = NSMutableDictionary()
        
        
        
        socialMediaUserNames.setValue("bobby", forKey: "facebook")
        socialMediaUserNames.setValue("bobby", forKey: "linkedin")
        socialMediaUserNames.setValue("bobby", forKey: "twitter")
        socialMediaUserNames.setValue("bobby", forKey: "instagram")
        socialMediaUserNames.setValue("bobby", forKey: "linkedin")
        socialMediaUserNames.setValue("bobby", forKey: "linkedin")
        socialMediaUserNames.setValue("bobby", forKey: "youtube")
        
        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages(possibleSocialMediaNameList)

    }
    
    
    
    /**************************************************************************
     *    COLLECTION VIEW PROTOCOL
     **************************************************************************/
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 15
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print ("SELECTED")
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
      let cell = collectionView.dequeueReusableCellWithReuseIdentifier("accountsCollectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
        
//        //Get the dictionary that holds information regarding the connected user's social media pages, and convert it to
//        // an array so that we can easily get the social media mediums that the user has (i.e. facebook, twitter, etc).
//        var userSocialMediaNames = socialMediaUserNames.allKeys as! Array<String>
//        
//        userSocialMediaNames = userSocialMediaNames.sort()
//        
//        let socialMediaName = userSocialMediaNames[indexPath.item % self.possibleSocialMediaNameList.count]
//        
        let socialMediaName = "facebook"
        // Generate a UI image for the respective social media type
        cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaName]
        
        cell.socialMediaName = socialMediaName
        
        // Make cell image circular
        cell.layer.cornerRadius = cell.frame.width / 2
        
        return cell
    }
    
    
    
    /**************************************************************************
     *    TABLE VIEW PROTOCOL
     **************************************************************************/
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 8
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("menuCell") as! MenuTableViewCell!
        
        let menuOption = MenuData(rawValue: indexPath.row)!
        
        switch (menuOption)
        {
        case .YOUR_ACCOUNT:
            cell.cellName.text = "Your Account"
            break;
        case .LINKED_ACCOUNTS:
            cell.cellName.text = "Linked Social Media Accounts"
            break;
        case .NOTIFICATIONS:
            cell.cellName.text = "Notification Settings"
            break;
        case .INVITE_FRIENDS:
            cell.cellName.text = "Invite Friends"
            break;
        case .HELP:
            cell.cellName.text = "Help & About Us"
            break;
        case .TERMS:
            cell.cellName.text = "Terms of Service"
            break;
        case .CLEAR_HISTORY:
            cell.cellName.text = "Clear Search History"
            break;
        case .LOG_OUT:
            cell.cellName.text = "Log Out"
            break;
    
//        default:
//            cell.cellName.text = "Error"
//            break;
        }
        

        
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    
    }
    
    
    func logUserOut()
    {
        
        // Ask user if they really want to log out...
        let alert = UIAlertController(title: nil, message: "Are you really sure you want to log out?", preferredStyle: UIAlertControllerStyle.Alert)
        
        let logOutAction = UIAlertAction(title: "Log out", style: UIAlertActionStyle.Default) { (UIAlertAction) -> Void in
            
            // present the log in home page
            
            //TODO: Add spinner functionality
            self.performSegueWithIdentifier("logOut", sender: nil)
            
            // Log out AWS
            
            
            
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil)
        
        alert.addAction(logOutAction)
        alert.addAction(cancelAction)
        
        self.showViewController(alert, sender: nil)
    }
}
