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
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube" /*, "phone"*/)
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    
    var currentUserName : String!
    
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var firebaseRootRef : Firebase!
    var firebaseUsersRef: Firebase!
    var firebaseLinkedAccountsRef: Firebase!
    var firebaseConnectionsRef: Firebase!
    
    var connectionList : Array<Connection>!
    
    override func viewDidLoad() {
        
        // Fetch the user's username
        currentUserName = getCurrentUser()
        
        // Firebase root, our data is stored here
        firebaseRootRef = Firebase(url: firebaseRootRefString)
        firebaseUsersRef = Firebase(url: firebaseRootRefString + "Users/")
        firebaseLinkedAccountsRef = Firebase(url: firebaseRootRefString + "LinkedSocialMediaAccounts/")
        firebaseConnectionsRef = Firebase(url: firebaseRootRefString + "Connections/" + currentUserName)
        
        connectionList = Array<Connection>()
        
        // Load all connections and respective information from servers
        firebaseConnectionsRef.queryOrderedByValue().observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) -> Void in
            
            
            // Get your connection's user name
            let connectionUserName = snapshot.key
            let connection = Connection()
            
            // Store server data into our local "cached" object -- connection
            connection.userName = snapshot.key
            connection.timestampGMT = snapshot.value as! Int
            
            print("firebaseConnectionsRef snapshot value is: ", snapshot.value)
            print("conn username is:", connectionUserName)
            print("##1")
            
            // Store the user's Image
            self.firebaseUsersRef.childByAppendingPath(connectionUserName).observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
                
//                connection.userImage = snapshot.value as! String
                connection.userImage = snapshot.childSnapshotForPath("/userImage").value as! String
                connection.userFullName = snapshot.childSnapshotForPath("/fullName").value as! String
               
                print("##2")
                
//                self.recentConnTableView.reloadData()

            })
            
            // Store the user's social media accounts
            self.firebaseLinkedAccountsRef.childByAppendingPath(connectionUserName).observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
                
                print("LET'S DO THIS FOR: ", connectionUserName)
                // Store dictionary of all key-val pairs.. 
                // I.e.: (facebook, [user's facebook username])
                //       (twitter,  [user's twitter username]) ... etc
                connection.socialMediaUserNames = snapshot.value as! NSDictionary
                
                print("firebasedLinkedAccountsRef snapshot value is: ", snapshot.value)
                
                print("##3")
                
//                self.recentConnTableView.reloadData()
                
                
                // Add connection to connection list -- sorted in ascending order by time!
                self.connectionList.append(connection)
                
                
                print("RELOADING TABLE VIEWS NOW!")
                self.recentConnTableView.reloadData()

            })
            
            print("##4")
            

            
        })
        
        // Load up all images we have
        var imageName:String!
        var newUIImage:UIImage!
        let size = possibleSocialMediaNameList.count
        
        socialMediaImageDictionary = Dictionary<String, UIImage>()
        
        print("Size is: ", size)
        // Generate all necessary images for the emblems
        for (var i = 0; i < size; i++)
        {
            // Fetch emblem name
            imageName = possibleSocialMediaNameList[i]
         
            print("Generating image for: ", imageName)
            // Generate image
            newUIImage = UIImage(named: imageName)
            
            if (newUIImage != nil)
            {
                // Store image into our 'cache'
                socialMediaImageDictionary[imageName] = newUIImage
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
        
        return connectionList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print("TABLEVIEW 2")

        let cell = tableView.dequeueReusableCellWithIdentifier("recentConnCell", forIndexPath: indexPath) as! TableViewCell
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
        
        
        // Set a tag on the collection view so we know which table row we're at when dealing with the collection view later on
        cell.collectionView.tag = indexPath.row
        
        let connectedUser = connectionList[indexPath.row]
        
        cell.cellName.text = connectedUser.userFullName + " (" + connectedUser.userName + ")"
        
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
        
        print("TAG IS:", collectionView.tag)

        // Use the tag to know which tableView row we're at
        return connectionList[collectionView.tag].socialMediaUserNames.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("COLLECTIONVIEW 2")
        

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell

        
        // Get the dictionary that holds information regarding the connected user's social media pages, and convert it to
        // an array so that we can easily get the social media mediums that the user has (i.e. facebook, twitter, etc).
        var userSocialMediaNames = connectionList[collectionView.tag].socialMediaUserNames.allKeys as! Array<String>
        userSocialMediaNames = userSocialMediaNames.sort()
        
        let socialMediaName = userSocialMediaNames[indexPath.item % self.possibleSocialMediaNameList.count]
        
        print(socialMediaName)
        
        // We will delay the image assignment to prevent buggy race conditions
        // (Check to see what happens when the delay is not set... then you'll understand)
        // Probable cause: tableView.beginUpdates() and tableView.endUpdates() in tableView(didSelectIndexPath) method
        delay(0) { () -> () in
            
            // Generate a UI image for the respective social media type
            cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaName]
            
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
        
//        let userName = "AustinVaday"
        let connectionSocialMediaUserNames = connectionList[collectionView.tag].socialMediaUserNames
        
        
        urlString = ""
        altString = ""
        
        switch (socialMediaName)
        {
        case "facebook":
            
                let facebookUserName = connectionSocialMediaUserNames["facebook"] as! String
                urlString = "fb://requests/" + facebookUserName
                altString = "http://www.facebook.com/" + facebookUserName
            break;
        case "snapchat":
            
                let snapchatUserName = connectionSocialMediaUserNames["snapchat"] as! String
                urlString = "snapchat://add/" + snapchatUserName
                altString = ""
            break;
        case "instagram":
            
                let instagramUserName = connectionSocialMediaUserNames["instagram"] as! String
                urlString = "instagram://user?username=" + instagramUserName
                altString = "http://www.instagram.com/" + instagramUserName
            break;
        case "twitter":
            
                let twitterUserName = connectionSocialMediaUserNames["twitter"] as! String
                urlString = "twitter:///user?screen_name=" + twitterUserName
                altString = "http://www.twitter.com/" + twitterUserName
            break;
        case "linkedin":
            
                let linkedinUserName = connectionSocialMediaUserNames["linkedin"] as! String
                urlString = "linkedin://profile/" + linkedinUserName
                altString = "http://www.linkedin.com/in/" + linkedinUserName
                
            break;
        case "youtube":
            
                let youtubeUserName = connectionSocialMediaUserNames["youtube"] as! String
                urlString = "youtube:www.youtube.com/user/" + youtubeUserName
                altString = "http://www.youtube.com/" + youtubeUserName
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



