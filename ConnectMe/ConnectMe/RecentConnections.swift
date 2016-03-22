//
//  RecentConnections.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/31/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
import Firebase
import Contacts

class RecentConnections: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {

    
    let NO_ROW = -1
    @IBOutlet weak var recentConnTableView: UITableView!
    var selectedRowIndex:Int = -1
    var expandedRow:Int = -1
    var isARowExpanded:Bool = false
    let defaultRowHeight:CGFloat = 55
    let expandedRowHeight:CGFloat = 100
    let socialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube" /*, "phone"*/)
    
    var socialMediaImageList : Array<UIImage>! // An array of social media emblem images
    
    var firebaseRootRef : Firebase!
    
    override func viewDidLoad() {
    
        // Firebase root, our data is stored here
        firebaseRootRef = Firebase(url: "https://torrid-fire-8382.firebaseio.com")
        
//        firebaseRootRef.childByAppendingPath(
        
        // Load up all images we have
        var imageName:String!
        var newUIImage:UIImage!
        let size = socialMediaNameList.count
        
        socialMediaImageList = Array<UIImage>()
        print("Size is: ", size)
        // Generate all necessary images for the emblems
        for (var i = 0; i < size; i++)
        {
            // Fetch emblem name
            imageName = socialMediaNameList[i]
         
            print("Generating image for: ", imageName)
            // Generate image
            newUIImage = UIImage(named: imageName)
            
            if (newUIImage != nil)
            {
                // Store image
                socialMediaImageList.append(newUIImage)
            }
            else
            {
                print ("ERROR: RecentConnections.swift : social media emblem image not found.")
                // TODO: Show error image
                // socialMediaImageList.append(UIImage(named: ")
            }
            
        }
        
    }
    // TABLE VIEW
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // TODO: If more than one user,
        // Display up to 30 users immediately
        // Display 20 more if user keeps sliding down
        
        print("TABLEVIEW 1")
        
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print("TABLEVIEW 2")

        let cell = tableView.dequeueReusableCellWithIdentifier("recentConnCell", forIndexPath: indexPath) as! TableViewCell
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2

        // Set the user name
        cell.cellName.text = "User " + String(indexPath.row)
        
        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        print("TABLEVIEW 3")

        // Set the new selectedRowIndex
        selectedRowIndex = indexPath.row
        
        // Update UI with animation
        tableView.beginUpdates()
        tableView.endUpdates()
        

//        let cell = tableView.dequeueReusableCellWithIdentifier("recentConnCell", forIndexPath: indexPath) as! TableViewCell
//
//        cell.collectionView.reloadData()
    
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        print("TABLEVIEW 4")

        let currentRow = indexPath.row
        
        // If a row is selected, we want to expand the cells
        if (currentRow == selectedRowIndex)
        {
            // Collapse if it is already expanded
            if (isARowExpanded && expandedRow == currentRow)
            {
                isARowExpanded = false
                expandedRow = NO_ROW
                return defaultRowHeight
            }
            else
            {
                isARowExpanded = true
                expandedRow = currentRow
                return expandedRowHeight
            }
        }
        else
        {
            return defaultRowHeight
        }
        
    }
    
    // COLLECTION VIEW
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("COLLECTIONVIEW 1")
        

        return socialMediaNameList.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("COLLECTIONVIEW 2")
        

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell

        let socialMediaName = socialMediaNameList[indexPath.item % self.socialMediaNameList.count]
        
        print(socialMediaName)
        
        // We will delay the image assignment to prevent buggy race conditions
        // (Check to see what happens when the delay is not set... then you'll understand)
        // Probable cause: tableView.beginUpdates() and tableView.endUpdates() in tableView(didSelectIndexPath) method
        delay(0) { () -> () in
            
            // Generate a UI image for the respective social media type
            cell.emblemImage.image = self.socialMediaImageList[indexPath.item % self.socialMediaImageList.count]
            
            cell.socialMediaName = socialMediaName

        }

        // Make cell image circular
        cell.layer.cornerRadius = cell.frame.width / 2
        
        // Make cell movements cleaner (increased FPM)
//        cell.layer.shouldRasterize = true
        
        return cell
    }


//    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
//        print("SELECTED ITEM AT ", indexPath.item)
//
//    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        print("SELECTED ITEM AT ", indexPath.item)
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell
        let socialMediaName = cell.socialMediaName
        
        var urlString:String!
        var altString:String!
        var socialMediaURL:NSURL!
        var contact:CNMutableContact = CNMutableContact()
        
        let userName = "AustinVaday"
        
        urlString = ""
        altString = ""
        
        switch (socialMediaName)
        {
        case "facebook":
                urlString = "fb://requests/" + userName
                altString = "http://www.facebook.com/" + userName
            break;
        case "snapchat":
                urlString = "snapchat://add/" + userName
                altString = ""
            break;
        case "instagram":
                urlString = "instagram://user?username=" + userName
                altString = "http://www.instagram.com/" + userName
            break;
        case "twitter":
                urlString = "twitter:///user?screen_name=" + userName
                altString = "http://www.twitter.com/" + userName
            break;
        case "linkedin":
                urlString = "linkedin://profile/" + userName
                altString = "http://www.linkedin.com/in/" + userName
                
            break;
        case "youtube":
                urlString = "youtube:www.youtube.com/user/" + userName
                altString = "http://www.youtube.com/" + userName
            break;
        case "phone":
                print ("COMING SOON")
                
//                contact.familyName = "Vaday"
//                contact.givenName  = "Austin"
//                
//                let phoneNum  = CNPhoneNumber(stringValue: "9493758223")
//                let cellPhone = CNLabeledValue(label: CNLabelPhoneNumberiPhone, value: phoneNum)
//                
//                contact.phoneNumbers.append(cellPhone)
//                
//                //TODO: Check if contact already exists in phone
//                let saveRequest = CNSaveRequest()
//                saveRequest.addContact(contact, toContainerWithIdentifier: nil)
//                
                
//                return
            
            break;
        default:
            break;
        }
        
        socialMediaURL = NSURL(string: urlString)
        
        // If user doesn't have social media app installed, open using default browser instead (use altString)
        if (!UIApplication.sharedApplication().canOpenURL(socialMediaURL))
        {
            if (altString != "")
            {
                socialMediaURL = NSURL(string: altString)
            }
            else
            {
                if (socialMediaName == "snapchat")
                {
                showAlert("Sorry", message: "You need to have the Snapchat app! Please download it and try again!", buttonTitle: "Ok", sender: self)
                }
                else
                {
                    showAlert("Hold on!", message: "Feature coming soon...", buttonTitle: "Ok", sender: self)
                }
                return
            }
        }
        
        // Perform the request, go to external application and let the user do whatever they want!
        UIApplication.sharedApplication().openURL(socialMediaURL)
        
    }

    


}



