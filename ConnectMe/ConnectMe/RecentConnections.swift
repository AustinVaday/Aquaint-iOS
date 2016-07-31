//
//  RecentConnections.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/31/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit


class RecentConnections: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var recentConnTableView: UITableView!
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube")
    
    var currentUserName : String!
    
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var refreshControl : UIRefreshControl!
    var connectionList : Array<Connection>!
    
    var expansionObj:CellExpansion!

    override func viewDidLoad() {
        
        // Fetch the user's username
        currentUserName = getCurrentCachedUser()
        
        connectionList = Array<Connection>()
        expansionObj = CellExpansion()
        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages(possibleSocialMediaNameList)
        
        
        // Set up refresh control for when user drags for a refresh.
        refreshControl = UIRefreshControl()

        // When user pulls, this function will be called
        refreshControl.addTarget(self, action: #selector(RecentConnections.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
        recentConnTableView.addSubview(refreshControl)
        
        
        // Fill out temporary connections list...
        let con = Connection()
        
        for i in 0...10
        {
            con.userFullName = "User" + String(i)
            con.userName = "username" + String(i)
            con.socialMediaUserNames = ["facebook" : "AVTheMan", "snapchat": "yolo", "twitter": "tweet"]
            
            connectionList.append(con)
        }
        
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

        let cell = tableView.dequeueReusableCellWithIdentifier("contactsCell", forIndexPath: indexPath) as! ContactsTableViewCell
        
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
        updateCurrentlyExpandedRow(&expansionObj, currentRow: indexPath.row)
        
        // Update UI with animation
        tableView.beginUpdates()
        tableView.endUpdates()
    
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        // Return height computed by our special function
        return getTableRowHeightForDropdownCell(&expansionObj, currentRow: indexPath.row)
    
    }
    
    // COLLECTION VIEW
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
         
        // Use the tag to know which tableView row we're at
        return connectionList[collectionView.tag].socialMediaUserNames.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
        
        // Get the dictionary that holds information regarding the connected user's social media pages, and convert it to
        // an array so that we can easily get the social media mediums that the user has (i.e. facebook, twitter, etc).
        var userSocialMediaTypes = connectionList[collectionView.tag].socialMediaUserNames.allKeys as! Array<String>
        userSocialMediaTypes = userSocialMediaTypes.sort()
        
        print(indexPath.item)
        let socialMediaType = userSocialMediaTypes[indexPath.item % self.possibleSocialMediaNameList.count]
        
        print(socialMediaType)
        
        // We will delay the image assignment to prevent buggy race conditions
        // (Check to see what happens when the delay is not set... then you'll understand)
        // Probable cause: tableView.beginUpdates() and tableView.endUpdates() in tableView(didSelectIndexPath) method
        delay(0) { () -> () in
            
            // Generate a UI image for the respective social media type
            cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaType]
            
            cell.socialMediaType = socialMediaType //i.e. facebook, twitter, ..

        }

        // Make cell image circular
        cell.layer.cornerRadius = cell.frame.width / 2
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didHighlightItemAtIndexPath indexPath: NSIndexPath) {
        print("SELECTED ITEM AT ", indexPath.item)
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell
        let socialMediaUserName = cell.socialMediaName // username..
        let socialMediaType = cell.socialMediaType // "facebook", "snapchat", etc..
       
        //TODO: TEST THIS FUNCTION...
        let socialMediaURL = getUserSocialMediaURL(socialMediaUserName, socialMediaTypeName: socialMediaType, sender: self)
        
        // Perform the request, go to external application and let the user do whatever they want!
        UIApplication.sharedApplication().openURL(socialMediaURL)
        
    }

    


}



