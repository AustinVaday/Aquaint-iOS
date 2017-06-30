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
    var refreshControl : CustomRefreshControl!
    var connectionList : Array<Connection>!
    var defaultImage : UIImage!
    var defaultCollectionViewLayout : UICollectionViewLayout!
    var collectionViewClearDataRequest = false

    var status : String!
    override func viewDidLoad() {
        
        // Fetch the user's username
        currentUserName = getCurrentCachedUser()

        connectionList = Array<Connection>()
      
        defaultImage = UIImage(imageLiteral: "Person Icon Black")

        
        // Fill the dictionary of all social media names (key) with an image (val).
        // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
        socialMediaImageDictionary = getAllPossibleSocialMediaImages()
        
        
        // Set up refresh control for when user drags for a refresh.
        refreshControl = CustomRefreshControl()

        // When user pulls, this function will be called
        refreshControl.addTarget(self, action: #selector(RecentConnections.refreshTable(_:)), for: UIControlEvents.valueChanged)
        recentConnTableView.addSubview(refreshControl)
        
        // Call all lambda functions and AWS-needed stuff
        generateData()
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
      awsMobileAnalyticsRecordPageVisitEventTrigger("RecentConnections", forKey: "page_name")
    }
    // Function that is called when user drags/pulls table with intention of refreshing it
    func refreshTable(_ sender:AnyObject)
    {
        self.refreshControl.beginRefreshing()
        
        // Clear table (not needed)
//        connectionList = Array<Connection>()
//        recentConnTableView.reloadData()
//        recentConnTableView.layoutIfNeeded()

        self.refreshControl.beginRefreshing()
      
        // Regenerate data
        generateData()
        
        // Need to end refreshing
        delay(0.5)
        {
            self.refreshControl.endRefreshing()
        }
    }
    
    
    
    // TABLE VIEW
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // TODO: If more than one user,
        // Display up to 30 users immediately
        // Display 20 more if user keeps sliding down
        
        return connectionList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

//        print("DDD*********************************************************")
//        print(" Size of connectionList is: ", connectionList.count)
//        print(" Number of rowsi n table is: ", tableView.numberOfRowsInSection(0))
//        print(" Indexpath is: ", indexPath.row)
//        print("*********************************************************")

        
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactsCell", for: indexPath) as! ContactsTableViewCell
        
        if connectionList.count == 0
        {
            return cell
        }
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
    
        // Set a tag on the collection view so we know which table row we're at when dealing with the collection view later on
        
        print ("INDEXPATH ROW IS:", indexPath.row)
        print ("CONNECTIONLIST SIZE IS:", connectionList.count)

        let connectedUser = connectionList[indexPath.row]
        
        let handler = {
            (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
            showPopupForUser(connectedUser.userName, me: self.currentUserName)
        }
        
        cell.cellName.clearActionDictionary()
        cell.cellName.text = connectedUser.userFullName
        cell.cellName.setLinkForSubstring(connectedUser.userFullName, withLinkHandler: handler)
        cell.cellUserName.text = connectedUser.userName
        cell.cellImage.image = connectedUser.userImage
        cell.cellTimeConnected.text = connectedUser.computeTimeDiff()
        
        return cell
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
        if !tableView.isDragging && !tableView.isTracking
        {
          let connectedUser = connectionList[indexPath.row]
          showPopupForUser(connectedUser.userName, me: self.currentUserName)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // Return height computed by our special function
        return 60
    }
    
    // COLLECTION VIEW
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if connectionList.count == 0
        {
            return 0
        }
        
        
        print("RETURNING content for index: ", collectionView.tag)
        print("Size is of collectionview should be...: ", connectionList[collectionView.tag].keyValSocialMediaPairList.count)
        return connectionList[collectionView.tag].keyValSocialMediaPairList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "collectionViewCell", for: indexPath) as! SocialMediaCollectionViewCell
        
        
        // Get the dictionary that holds information regarding the connected user's social media pages, and convert it to
        // an array so that we can easily get the social media mediums that the user has (i.e. facebook, twitter, etc).
        let keyValSocialMediaPairList = connectionList[collectionView.tag].keyValSocialMediaPairList
        
        if (!keyValSocialMediaPairList.isEmpty)
        {
            let socialMediaPair = keyValSocialMediaPairList[indexPath.item % keyValSocialMediaPairList.count]
            let socialMediaType = socialMediaPair.socialMediaType
            let socialMediaUserName = socialMediaPair.socialMediaUserName
            
            // Generate a UI image for the respective social media type
            cell.emblemImage.image = self.socialMediaImageDictionary[socialMediaType!]
            
            cell.socialMediaName = socialMediaUserName // username
            cell.socialMediaType = socialMediaType // facebook, snapchat, etc

            // We will delay the image assignment to prevent buggy race conditions
            // (Check to see what happens when the delay is not set... then you'll understand)
            // Probable cause: tableView.beginUpdates() and tableView.endUpdates() in tableView(didSelectIndexPath) method
            delay(0) { () -> () in
                
                DispatchQueue.main.async(execute: {
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
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        print("SELECTED ITEM AT ", indexPath.item)
        
        let cell = collectionView.cellForItem(at: indexPath) as! SocialMediaCollectionViewCell
        let socialMediaUserName = cell.socialMediaName // username..
        let socialMediaType = cell.socialMediaType // "facebook", "snapchat", etc..
       
        //TODO: TEST THIS FUNCTION...
        let socialMediaURL = getUserSocialMediaURL(socialMediaUserName, socialMediaTypeName: socialMediaType, sender: self)
        
        // Perform the request, go to external application and let the user do whatever they want!
        if socialMediaURL != nil
        {
            UIApplication.shared.openURL(socialMediaURL)
        }
    }
    
    fileprivate func generateData()
    {
        var newConnectionList = Array<Connection>()

        // Get array of connections from Lambda -- RDS
        let lambdaInvoker = AWSLambdaInvoker.default()
        let parameters = ["action":"getFollowees", "target": currentUserName]
        
        lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continueWith { (resultTask) -> AnyObject? in
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
                    DispatchQueue.main.async(execute: {
                        
                        self.connectionList = Array<Connection>()
                        self.recentConnTableView.reloadData()
                        print("RELOADED 0 COUNT DATA")
                    })
                    
                    return nil
                }
                
                // Propogate local data structure -- helps us prevent needing to
                // fetch more data and prevents race conditions later too
                for userData in connectionsFetchedList
                {
                    let con = Connection()
                    con.userName = userData.object(at: 0) as! String
                    con.timestampGMT = userData.object(at: 1) as! Int
                    
                    newConnectionList.append(con)
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

                
                var runningRequests = 0
                // If lists are not equal, we need to fetch data from the servers
                // and re-propagate the list
                for userConnection in newConnectionList
                {
                    runningRequests = runningRequests + 1
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
                            
                            getUserS3Image(userConnection.userName, extraPath: nil, completion: { (result, error) in
                                if error == nil && result != nil
                                {
                                    userConnection.userImage = result! as UIImage
                                }
                                else
                                {
                                    userConnection.userImage = self.defaultImage
                                }
                                
                                
                                runningRequests = runningRequests - 1
                                
                                if runningRequests == 0
                                {
                                    // Update UI when no more running requests! (last async call finished)
                                    // Update UI on main thread
                                    DispatchQueue.main.async(execute: {
                                        
                                        self.connectionList = newConnectionList
                                        
                                        self.recentConnTableView.reloadData()
                                        self.recentConnTableView.layoutIfNeeded()
                                        
                                        print("DONE RELOADED")
                                        print("Connection list size is: ", self.connectionList.count)
                                        
                                    })

                                }
                            })
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

    }
    
    // EXPECTED TO BE IN ORDER.
    fileprivate func areListsEqual(_ array1: Array<Connection>, array2: Array<Connection>) -> Bool
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



