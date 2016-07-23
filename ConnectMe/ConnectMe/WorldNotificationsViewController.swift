//
//  WorldNotificationsViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/30/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import Firebase

class WorldNotificationsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    let cellIdentifier = "connectionCell"
    
    @IBOutlet weak var worldConnectionsTableView: UITableView!
    
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube")
    
    var currentUserName : String!
    
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var firebaseRootRef : FIRDatabaseReference!
    var firebaseUsersRef: FIRDatabaseReference!
    var firebaseLinkedAccountsRef: FIRDatabaseReference!
    var firebaseConnectionsRef: FIRDatabaseReference!
    var firebaseUserImagesRef: FIRDatabaseReference!
    var refreshControl : UIRefreshControl!
    var connectionList : Array<Connection>!
    var defaultImage : UIImage!
    
    
    var expansionObj:CellExpansion!
    
    override func viewDidLoad() {
        
        // Fetch the user's username
        currentUserName = getCurrentCachedUser()
        
        // Firebase root, our data is stored here
        firebaseRootRef = FIRDatabase.database().reference()
        firebaseUsersRef = firebaseRootRef.child("Users/")
        firebaseUserImagesRef = firebaseRootRef.child("UserImages/")
        firebaseLinkedAccountsRef = firebaseRootRef.child("LinkedSocialMediaAccounts/")
        firebaseConnectionsRef = firebaseRootRef.child("Connections/" + currentUserName)
        
        connectionList = Array<Connection>()
        expansionObj = CellExpansion()
        
        defaultImage = UIImage(imageLiteral: "Person Icon Black")
        
        //TEMP : USED TO MAKE WEBSITE IMAGES
        // ---------------------------------
        
        var connection = Connection()
        connection.timestampGMT = 1462085382
        connection.userFullName = "Jane Stevens"
        connection.userImage = UIImage(imageLiteral: "1")
        connection.socialMediaUserNames = NSDictionary(dictionary: ["facebook" : "austinvaday", "snapchat" : "austinvaday", "instagram" : "avtheman", "twitter" : "austinvaday", "youtube" : "austinvaday", "linkedin" : "austinvaday"])
        connectionList.append(connection)
        
        connection = Connection()
        connection.timestampGMT = 1462085372
        connection.userFullName = "Cooper Elisha"
        connection.userImage = UIImage(imageLiteral: "9")
        connection.socialMediaUserNames = NSDictionary(dictionary: ["facebook" : "austinvaday", "snapchat" : "austinvaday", "instagram" : "avtheman", "twitter" : "austinvaday", "youtube" : "austinvaday", "linkedin" : "austinvaday"])
        connectionList.append(connection)
        
        
        connection = Connection()
        connection.timestampGMT = 1462084282
        connection.userFullName = "Aaron Konani"
        connection.userImage = UIImage(imageLiteral: "10")
        connection.socialMediaUserNames = NSDictionary(dictionary: ["facebook" : "austinvaday", "snapchat" : "austinvaday", "instagram" : "avtheman", "twitter" : "austinvaday", "youtube" : "austinvaday", "linkedin" : "austinvaday"])
        connectionList.append(connection)
        
        
          connection = Connection()
        connection.timestampGMT = 1462082382
        connection.userFullName = "Hoyt Tim"
        connection.userImage = UIImage(imageLiteral: "11")
        connection.socialMediaUserNames = NSDictionary(dictionary: ["facebook" : "austinvaday", "snapchat" : "austinvaday", "instagram" : "avtheman", "twitter" : "austinvaday", "youtube" : "austinvaday", "linkedin" : "austinvaday"])
        connectionList.append(connection)
        
        
          connection = Connection()
        connection.timestampGMT = 1462075382
        connection.userFullName = "Mathis Antonio"
        connection.userImage = UIImage(imageLiteral: "14")
        connection.socialMediaUserNames = NSDictionary(dictionary: ["facebook" : "austinvaday", "snapchat" : "austinvaday", "instagram" : "avtheman", "twitter" : "austinvaday", "youtube" : "austinvaday", "linkedin" : "austinvaday"])
        connectionList.append(connection)
        
        
          connection = Connection()
        connection.timestampGMT = 1462025382
        connection.userFullName = "Sophos Hudde"
        connection.userImage = UIImage(imageLiteral: "3")
        connection.socialMediaUserNames = NSDictionary(dictionary: ["facebook" : "austinvaday", "snapchat" : "austinvaday", "instagram" : "avtheman", "twitter" : "austinvaday", "youtube" : "austinvaday", "linkedin" : "austinvaday"])
        connectionList.append(connection)
        
        
          connection = Connection()
        connection.timestampGMT = 1462025381
        connection.userFullName = "Juliana Olivia"
        connection.userImage = UIImage(imageLiteral: "2")
        connection.socialMediaUserNames = NSDictionary(dictionary: ["facebook" : "austinvaday", "snapchat" : "austinvaday", "instagram" : "avtheman", "twitter" : "austinvaday", "youtube" : "austinvaday", "linkedin" : "austinvaday"])
        connectionList.append(connection)
        
        
          connection = Connection()
        connection.timestampGMT = 1462025381
        connection.userFullName = "Tamara Ava"
        connection.userImage = UIImage(imageLiteral: "5")
        connection.socialMediaUserNames = NSDictionary(dictionary: ["facebook" : "austinvaday", "snapchat" : "austinvaday", "instagram" : "avtheman", "twitter" : "austinvaday", "youtube" : "austinvaday", "linkedin" : "austinvaday"])
        connectionList.append(connection)
        

        
        
        
        // ---------------------------------
        
//        // Load all connections and respective information from servers
//        firebaseConnectionsRef.queryOrderedByValue().observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) -> Void in
//            
//            
//            // Get your connection's user name
//            let connectionUserName = snapshot.key
//            let connection = Connection()
//            
//            // Store server data into our local "cached" object -- connection
//            connection.userName = snapshot.key
//            connection.timestampGMT = snapshot.value as! Int
//            
//            // Store the user's info (except image)
//            self.firebaseUsersRef.child(connectionUserName).observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
//                
//                connection.userFullName = snapshot.childSnapshotForPath("/fullName").value as! String
//                
//                //                self.recentConnTableView.reloadData()
//                
//            })
//            
//            // Store the user's image
//            self.firebaseUserImagesRef.child(connectionUserName).observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
//                
//                // Get base 64 string image
//                
//                // If user has an image, display it in table. Else, display default image
//                if (snapshot.exists())
//                {
//                    let userImageBase64String = snapshot.childSnapshotForPath("/profileImage").value as! String
//                    connection.userImage = convertBase64ToImage(userImageBase64String)
//                }
//                else
//                {
//                    connection.userImage = self.defaultImage
//                    
//                }
//                
//                self.recentConnTableView.reloadData()
//                
//            })
//            
//            // Store the user's social media accounts
//            self.firebaseLinkedAccountsRef.child(connectionUserName).observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
//                
//                // Store dictionary of all key-val pairs..
//                // I.e.: (facebook, [user's facebook username])
//                //       (twitter,  [user's twitter username]) ... etc
//                connection.socialMediaUserNames = snapshot.value as! NSDictionary
//                
//                //                self.recentConnTableView.reloadData()
//                
//                
//                // Add connection to connection list -- sorted in ascending order by time!
//                // Front of list == largest time == most recent add
//                //                print(snapshot)
//                //                self.connectionList.insert(connection, atIndex: 0)
//                
//                self.connectionList.append(connection)
//                // NOTE: CODE CRASHES FOR connectionList.insert because apparantly it's fetching 'aquaint' at the beginning of the list... look into this!!!!)
//                
//                self.recentConnTableView.reloadData()
//                
//            })
//            
//            
//            
//        })
        
        // Load up all images we have
        var imageName:String!
        var newUIImage:UIImage!
        let size = possibleSocialMediaNameList.count
        
        socialMediaImageDictionary = Dictionary<String, UIImage>()
        
        // Generate all necessary images for the emblems
        for i in 0...size-1
        {
            // Fetch emblem name
            imageName = possibleSocialMediaNameList[i]
            
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
        
        
        // Set up refresh control for when user drags for a refresh.
        refreshControl = UIRefreshControl()
        //        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        // When user pulls, this function will be called
        refreshControl.addTarget(self, action: #selector(WorldNotificationsViewController.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
        worldConnectionsTableView.addSubview(refreshControl)
        
        
        
    }
    
    // Function that is called when user drags/pulls table with intention of refreshing it
    func refreshTable(sender:AnyObject)
    {
        worldConnectionsTableView.reloadData()
        
        // Need to end refreshing
        delay(0.5)
        {
            self.refreshControl.endRefreshing()
        }
    }
    
    
    
    // TABLE VIEW
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // TODO: If more than one user,
        // Display up to 30 users immediately
        // Display 20 more if user keeps sliding down
        
        return connectionList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! WorldNotificationsTableViewCell
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
        
        // Set a tag on the collection view so we know which table row we're at when dealing with the collection view later on
        cell.collectionView.tag = /*(connectionList.count - 1) - */ indexPath.row
        
        let connectedUser = connectionList[indexPath.row]
        
        print("CVTAG#: ", cell.collectionView.tag, "CORRESPONDS TO: ", connectedUser.userName )
        
//        let mutableMessageString = NSMutableAttributedString(string: connectedUser.userFullName + " became aquainted with you",
//                                                             attributes: [NSFontAttributeName : ])
        
        let textString = connectedUser.userFullName +  " became aquainted with you. "
        cell.cellMessage.attributedText = createAttributedTextString(textString, boldStartArray: [0], boldEndArray: [connectedUser.userFullName.characters.count])
        cell.cellImage.image = connectedUser.userImage
        cell.cellTimeConnected.text = connectedUser.computeTimeDiff()
        
        
        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Set the new selectedRowIndex
        updateCurrentlyExpandedRow(&expansionObj, currentRow: indexPath.row)
        
        // Update UI with animation
        tableView.beginUpdates()
        tableView.endUpdates()
        
        
        //        let cell = tableView.dequeueReusableCellWithIdentifier("recentConnCell", forIndexPath: indexPath) as! TableViewCell
        //
        //        cell.collectionView.reloadData()
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        let currentRow = indexPath.row
        
        // Return height computed by our special function
        return getTableRowHeightForDropdownCell(&expansionObj, currentRow: currentRow)
    }
    
    // COLLECTION VIEW
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        //        print("------------------------------------")
        //        for (var i = 0; i < connectionList.count; i++)
        //        {
        //            print("username:", connectionList[i].userName)
        //            print("social media accounts", connectionList[i].socialMediaUserNames)
        //
        //        }
        //        print("------------------------------------")
        
        
        //        print("TAG IS:", collectionView.tag)
        //
        //        print(connectionList[collectionView.tag].userName)
        //        print(connectionList[collectionView.tag].socialMediaUserNames.count)
        
        print("88888", connectionList[collectionView.tag].socialMediaUserNames.count)
        
        // Use the tag to know which tableView row we're at
        return connectionList[collectionView.tag].socialMediaUserNames.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("COLLECTIONVIEW 2")
        
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
        
        print("CVTAG IS:", collectionView.tag)
        
        
        // Get the dictionary that holds information regarding the connected user's social media pages, and convert it to
        // an array so that we can easily get the social media mediums that the user has (i.e. facebook, twitter, etc).
        var userSocialMediaNames = connectionList[collectionView.tag].socialMediaUserNames.allKeys as! Array<String>
        userSocialMediaNames = userSocialMediaNames.sort()
        
        print(indexPath.item)
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
