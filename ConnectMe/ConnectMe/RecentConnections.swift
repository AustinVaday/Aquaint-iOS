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
import FRHyperLabel

class RecentConnections: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var recentConnTableView: UITableView!
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
        socialMediaImageDictionary = getAllPossibleSocialMediaImages()
        
        
        // Set up refresh control for when user drags for a refresh.
        refreshControl = UIRefreshControl()

        // When user pulls, this function will be called
        refreshControl.addTarget(self, action: #selector(RecentConnections.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
        recentConnTableView.addSubview(refreshControl)
        
        // Call all lambda functions and AWS-needed stuff
        generateData()
    
    }
    
    
    // Function that is called when user drags/pulls table with intention of refreshing it
    func refreshTable(sender:AnyObject)
    {
//        recentConnTableView.reloadData()

        generateData()
        
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

        print("DDD*********************************************************")
        print(" Size of connectionList is: ", connectionList.count)
        print(" Indexpath is: ", indexPath.row)
        print("*********************************************************")

        
        
        let cell = tableView.dequeueReusableCellWithIdentifier("contactsCell", forIndexPath: indexPath) as! ContactsTableViewCell
        
        if connectionList.isEmpty
        {
            return cell
        }
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
    
        // Set a tag on the collection view so we know which table row we're at when dealing with the collection view later on
        cell.collectionView.tag = /*(connectionList.count - 1) - */ indexPath.row
        
        print ("INDEXPATH ROW IS:", indexPath.row)
        print ("CONNECTIONLIST SIZE IS:", connectionList.count)
        let connectedUser = connectionList[indexPath.row]
        
        print("CVTAG#: ", cell.collectionView.tag, "CORRESPONDS TO: ", connectedUser.userName )
        
        let handler = {
            (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
            showPopupForUser(connectedUser.userName)
        }
        
        cell.cellName.clearActionDictionary()
        cell.cellName.text = connectedUser.userFullName
        cell.cellName.setLinkForSubstring(connectedUser.userFullName, withLinkHandler: handler)
        cell.cellUserName.text = connectedUser.userName
        cell.cellImage.image = connectedUser.userImage
        cell.cellTimeConnected.text = connectedUser.computeTimeDiff()
        
        cell.collectionView.reloadData()
//        let sections = NSIndexSet(index: 0)
//        cell.collectionView.reloadSections(sections)
//        
        return cell
        
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        // Set the new selectedRowIndex
        updateCurrentlyExpandedRow(&expansionObj, currentRow: indexPath.row)
        
        print  ("Index path: ", indexPath.row)
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
        print("CCC*********************************************************")
        print(" Size of connectionList is: ", connectionList.count)
        print(" Indexpath is: ", indexPath.row)
        print(" Collection view tag is: ", collectionView.tag)
        print(" User corresponding to tag is: ", connectionList[collectionView.tag].userName)
        print(" User supposedly has ", connectionList[collectionView.tag].keyValSocialMediaPairList.count, " linked profiles" )
        print(" Here they are: \n", connectionList[collectionView.tag].keyValSocialMediaPairList)
        print("*********************************************************")

        
        
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
                
                dispatch_async(dispatch_get_main_queue(), {
                    // Generate a UI image for the respective social media type
                    cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaType]
                    
                    cell.socialMediaType = socialMediaType //i.e. facebook, twitter, ..
                    cell.socialMediaName = socialMediaUserName //i.e. austinvaday, avtheman, ..
                })

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
    
    private func generateData()
    {
        // Store old connection list so that we can get determine whether to refresh table or not
        let previousConnectionList = connectionList
        
        // ALWAYS start with a fresh list.
        connectionList = Array<Connection>()

        // Get array of connections from Lambda -- RDS
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        let parameters = ["action":"getFollowees", "target": currentUserName]
        
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
                
                let connectionsFetchedList = resultTask.result! as! NSArray
                
                print("Connections FETCHED LIST IS: ", connectionsFetchedList)
                
                // If empty list, then no users to display (refresh table)
                // Update UI on main thread
                if connectionsFetchedList.count == 0
                {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.recentConnTableView.reloadData()
                    })
                }
                
                // Propogate local data structure -- helps us prevent needing to
                // fetch more data and prevents race conditions later too
                for userData in connectionsFetchedList
                {
                    let con = Connection()
                    con.userName = userData.objectAtIndex(0) as! String
                    con.timestampGMT = userData.objectAtIndex(1) as! Int
                    
                    self.connectionList.append(con)
                }
                
//                // If lists are equal, we haven't added or removed a user.
//                // So, simply refresh table to update the times
//                if (!self.areListsEqual(self.connectionList, array2: previousConnectionList))
//                {
//                    // Update UI on main thread
//                    dispatch_async(dispatch_get_main_queue(), {
//                        self.recentConnTableView.reloadData()
//                    })
//                    
//                    return nil
//                }

                // If lists are not equal, we need to fetch data from the servers
                // and re-propagate the list
                for userConnection in self.connectionList
                {
                    getUserDynamoData(userConnection.userName, completion: { (result, error) in
                        if error == nil && result != nil
                        {

                            let resultUser = result! as User
                            userConnection.userFullName = resultUser.realname
                            
                            if resultUser.accounts != nil
                            {
                                userConnection.keyValSocialMediaPairList = convertDictionaryToSocialMediaKeyValPairList(resultUser.accounts)
                            }
                            else
                            {
                                userConnection.keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
                            }
                            
                            getUserS3Image(userConnection.userName, completion: { (result, error) in
                                if error == nil && result != nil
                                {
                                    userConnection.userImage = result! as UIImage
                                }
                                else
                                {
                                    userConnection.userImage = self.defaultImage
                                }
                                
                                
                                // Update UI on main thread
                                dispatch_async(dispatch_get_main_queue(), {
//                                        let range = NSMakeRange(0, self.recentConnTableView.numberOfSections)
//                                        let sections = NSIndexSet(indexesInRange: range)
//                                        self.recentConnTableView.reloadSections(sections, withRowAnimation: .Fade)
//                                        self.recentConnTableView.reloadData()
                                    
                                        print("FINISHED RELOADING DATA FOR:::", userConnection.userName)
                                })
                
                            })
                        }
                    })
                }
                
//                print("GONNA DELAY")
                delay(5)
                {
                    // Update UI on main thread
                    dispatch_async(dispatch_get_main_queue(), {
////                        let range = NSMakeRange(0, self.recentConnTableView.numberOfSections)
//                        let sections = NSIndexSet(index: 0)
//                        self.recentConnTableView.reloadSections(sections, withRowAnimation: .Fade)                    
                        self.recentConnTableView.reloadData()
                        print("DONE RELOADED")
                    })
                }
                
                
            }
            else
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                
            }
            
            return nil
            
        }

    }
    
    // EXPECTED TO BE IN ORDER.
    private func areListsEqual(array1: Array<Connection>, array2: Array<Connection>) -> Bool
    {
        if array1.count != array2.count
        {
            return false
        }
        
        let size = array1.count
        for i in 0...size - 1
        {
            if array1[i] != array2[i]
            {
                return false
            }
        }
        return true
    }


}



