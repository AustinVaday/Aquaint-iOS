//
//  RecentConnections.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/31/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
import AWSLambda

class RecentConnections: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var recentConnTableView: UITableView!
    let possibleSocialMediaNameList = Array<String>(arrayLiteral: "facebook", "snapchat", "instagram", "twitter", "linkedin", "youtube")
    var currentUserName : String!
    var socialMediaImageDictionary: Dictionary<String, UIImage>!
    var refreshControl : UIRefreshControl!
    var connectionList : Array<Connection>!
    var expansionObj:CellExpansion!
    var defaultImage : UIImage!


    override func viewDidLoad() {
        
        // Fetch the user's username
        currentUserName = getCurrentCachedUser()
        
        connectionList = Array<Connection>()
        expansionObj = CellExpansion()

        defaultImage = UIImage(imageLiteral: "Person Icon Black")

        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages(possibleSocialMediaNameList)
        
        
        // Set up refresh control for when user drags for a refresh.
        refreshControl = UIRefreshControl()

        // When user pulls, this function will be called
        refreshControl.addTarget(self, action: #selector(RecentConnections.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
        recentConnTableView.addSubview(refreshControl)
        
        // Get array of connections from Lambda -- RDS
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        let parameters = ["action":"getFollowers", "target": currentUserName]

        lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
            if resultTask.error != nil
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION - Error: ", resultTask.error)
            }
            else if resultTask.exception != nil
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION - Exception: ", resultTask.exception)
                
            }
            else if resultTask.result != nil
            {
                
                
                print("SUCCESSFULLY INVOKEd LAMBDA FUNCTION WITH RESULT: ", resultTask.result)
                
                let connectionsFetchedDictionary = resultTask.result! as! [String: Int]
                
//                let connectionsFetchedArray = convertJSONStringToArray(resultTask.result!)

                for userName in connectionsFetchedDictionary.keys
                {
                    let con = Connection()

                    con.userName = userName
                    con.timestampGMT = connectionsFetchedDictionary[userName]!
                    
                    getUserDynamoData(userName, completion: { (result, error) in
                        if error == nil
                        {
                            if result != nil
                            {
                                let resultUser = result! as User
                                con.userFullName = resultUser.realname
                                
                                con.keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(resultUser.accounts, possibleSocialMediaNameList: self.possibleSocialMediaNameList)
                                
                                
                                getUserS3Image(userName, completion: { (result, error) in
                                    if error == nil
                                    {
                                        if result != nil
                                        {
                                            con.userImage = result! as UIImage
                                        }
                                    }
                                    else
                                    {
                                        con.userImage = self.defaultImage
                                    }
                                    
                                    
                                    self.connectionList.append(con)
                                    
                                    // Update UI on main thread
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.recentConnTableView.reloadData()
                                    })
                                })
                                

                            }
                        }
                    })
                }
                
                
            }
            else
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                
            }
            
            return nil
            
        }

        
//        // Fill out temporary connections list...
//        let con = Connection()
//        
//        for i in 0...10
//        {
//            con.userFullName = "User" + String(i)
//            con.userName = "username" + String(i)
//            con.userImage = UIImage(imageLiteral: "Person Icon Black")
//            con.timestampGMT = getTimestampAsInt()
//            con.socialMediaUserNames = ["facebook" : "AVTheMan", "snapchat": "yolo", "twitter": "tweet"]
//            
//            connectionList.append(con)
//        }
        
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
//        let list = connectionList[collectionView.tag].keyValSocialMediaPairList
//        
//        if list.isEmpty
//        {
//            return 0
//        }
    
        return connectionList[collectionView.tag].keyValSocialMediaPairList.count
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! SocialMediaCollectionViewCell
        
        
        // Get the dictionary that holds information regarding the connected user's social media pages, and convert it to
        // an array so that we can easily get the social media mediums that the user has (i.e. facebook, twitter, etc).
        let keyValSocialMediaPairList = connectionList[collectionView.tag].keyValSocialMediaPairList
        
        if (!keyValSocialMediaPairList.isEmpty)
        {
            let socialMediaPair = keyValSocialMediaPairList[indexPath.item % keyValSocialMediaPairList.count]
            let socialMediaType = socialMediaPair.socialMediaType
            let socialMediaUserName = socialMediaPair.socialMediaUserName
            
            // Generate a UI image for the respective social media type
            cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaType]
            
            cell.socialMediaName = socialMediaUserName // username
            cell.socialMediaType = socialMediaType // facebook, snapchat, etc

            // We will delay the image assignment to prevent buggy race conditions
            // (Check to see what happens when the delay is not set... then you'll understand)
            // Probable cause: tableView.beginUpdates() and tableView.endUpdates() in tableView(didSelectIndexPath) method
            delay(0) { () -> () in
                
                // Generate a UI image for the respective social media type
                cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaType]
                
                cell.socialMediaType = socialMediaType //i.e. facebook, twitter, ..
                cell.socialMediaName = socialMediaUserName //i.e. austinvaday, avtheman, ..
            }
            
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



