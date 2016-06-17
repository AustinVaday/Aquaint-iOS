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


class RecentConnections: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {

    
    @IBOutlet weak var recentConnTableView: UITableView!
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube")
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    
    var currentUserName : String!
    
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var expansionObj:CellExpansion!
    var firebaseRootRef : Firebase!
    var firebaseUsersRef: Firebase!
    var firebaseLinkedAccountsRef: Firebase!
    var firebaseConnectionsRef: Firebase!
    var firebaseUserImagesRef: Firebase!
    var refreshControl : UIRefreshControl!
    var connectionList : Array<Connection>!
    var defaultImage : UIImage!
    
    override func viewDidLoad() {
        
        // Fetch the user's username
        currentUserName = getCurrentUser()
        
        // Firebase root, our data is stored here
        firebaseRootRef = Firebase(url: firebaseRootRefString)
        firebaseUsersRef = Firebase(url: firebaseRootRefString + "Users/")
        firebaseUserImagesRef = Firebase(url: firebaseRootRefString + "UserImages/")
        firebaseLinkedAccountsRef = Firebase(url: firebaseRootRefString + "LinkedSocialMediaAccounts/")
        firebaseConnectionsRef = Firebase(url: firebaseRootRefString + "Connections/" + currentUserName)
        
        connectionList = Array<Connection>()
        expansionObj = CellExpansion()
        
        defaultImage = UIImage(imageLiteral: "Person Icon Black")
        
        // Load all connections and respective information from servers
        firebaseConnectionsRef.queryOrderedByValue().observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) -> Void in
            
            
            // Get your connection's user name
            let connectionUserName = snapshot.key
            let connection = Connection()
            
            // Store server data into our local "cached" object -- connection
            connection.userName = snapshot.key
            connection.timestampGMT = snapshot.value as! Int
            
            // Store the user's info (except image)
            self.firebaseUsersRef.childByAppendingPath(connectionUserName).observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
            
                connection.userFullName = snapshot.childSnapshotForPath("/fullName").value as! String
                
//                self.recentConnTableView.reloadData()

            })
            
            // Store the user's image
            self.firebaseUserImagesRef.childByAppendingPath(connectionUserName).observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
                
                // Get base 64 string image
                
                // If user has an image, display it in table. Else, display default image
                if (snapshot.exists())
                {
                    let userImageBase64String = snapshot.childSnapshotForPath("/profileImage").value as! String
                    connection.userImage = convertBase64ToImage(userImageBase64String)
                }
                else
                {
                    connection.userImage = self.defaultImage

                }

                self.recentConnTableView.reloadData()
                
            })
            
            // Store the user's social media accounts
            self.firebaseLinkedAccountsRef.childByAppendingPath(connectionUserName).observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in

                // Store dictionary of all key-val pairs..
                // I.e.: (facebook, [user's facebook username])
                //       (twitter,  [user's twitter username]) ... etc
                connection.socialMediaUserNames = snapshot.value as! NSDictionary
                
//                self.recentConnTableView.reloadData()
                
                
                // Add connection to connection list -- sorted in ascending order by time!
                // Front of list == largest time == most recent add
//                print(snapshot)
//                self.connectionList.insert(connection, atIndex: 0)
                
              self.connectionList.append(connection)
// NOTE: CODE CRASHES FOR connectionList.insert because apparantly it's fetching 'aquaint' at the beginning of the list... look into this!!!!)

                self.recentConnTableView.reloadData()

            })


            
        })
        
        // Load up all images we have
        var imageName:String!
        var newUIImage:UIImage!
        let size = possibleSocialMediaNameList.count
        
        socialMediaImageDictionary = Dictionary<String, UIImage>()
        
        // Generate all necessary images for the emblems
        for i in 0 ... size - 1
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
        refreshControl.addTarget(self, action: "refreshTable:", forControlEvents: UIControlEvents.ValueChanged)
        recentConnTableView.addSubview(refreshControl)
        
        
        
    }
    
    // Function that is called when user drags/pulls table with intention of refreshing it
    func refreshTable(sender:AnyObject)
    {
        recentConnTableView.reloadData()
        
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

        let cell = tableView.dequeueReusableCellWithIdentifier("recentConnCell", forIndexPath: indexPath) as! TableViewCell
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
    
        // Set a tag on the collection view so we know which table row we're at when dealing with the collection view later on
        cell.collectionView.tag = /*(connectionList.count - 1) - */ indexPath.row
        
        let connectedUser = connectionList[indexPath.row]
        
        print("CVTAG#: ", cell.collectionView.tag, "CORRESPONDS TO: ", connectedUser.userName )
        
        cell.cellName.text = connectedUser.userFullName
        cell.cellUserName.text = connectedUser.userName
        cell.cellImage.image = connectedUser.userImage
        cell.cellTimeConnected.text = connectedUser.computeTimeDiff()
        
        
        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Set the new selectedRowIndex
        expansionObj.selectedRowIndex = indexPath.row
        
        // Update UI with animation
        tableView.beginUpdates()
        tableView.endUpdates()
        

//        let cell = tableView.dequeueReusableCellWithIdentifier("recentConnCell", forIndexPath: indexPath) as! TableViewCell
//
//        cell.collectionView.reloadData()
    
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {

        let currentRow = indexPath.row
        
        // If a row is selected, we want to expand the cells
        if (currentRow == expansionObj.selectedRowIndex)
        {
            // Collapse if it is already expanded
            if (expansionObj.isARowExpanded && expansionObj.expandedRow == currentRow)
            {
                expansionObj.isARowExpanded = false
                expansionObj.expandedRow = expansionObj.NO_ROW
                return expansionObj.defaultRowHeight
            }
            else
            {
                expansionObj.isARowExpanded = true
                expansionObj.expandedRow = currentRow
                return expansionObj.expandedRowHeight
            }
        }
        else
        {
            return expansionObj.defaultRowHeight
        }
        
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



