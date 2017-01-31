//
//  FollowerListViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 1/1/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit
import AWSLambda
import FRHyperLabel

protocol FollowerListSetUserAndActionDelegate {
  func dataForUser() -> String
  func lambdaActionForUser() -> String
}

class FollowerListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
  
  @IBOutlet weak var userTableView: UITableView!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  var dataDelegate : FollowerListSetUserAndActionDelegate?
  
  var currentUserName : String!
  var lambdaAction : String!
  var socialMediaImageDictionary: Dictionary<String, UIImage>!
  var refreshControl : CustomRefreshControl!
  var connectionList : Array<Connection>!
  var expansionObj:CellExpansion!
  var defaultImage : UIImage!
  var defaultCollectionViewLayout : UICollectionViewLayout!
  var collectionViewClearDataRequest = false
  var isNewDataLoading = false
  var alphabeticalOrder = false
  var currentBegin = 0
  var currentEnd = 20
  let offset = 20
  
  var status : String!
  override func viewDidLoad() {
    
    // Get user to display in table
    currentUserName = dataDelegate?.dataForUser()
    
    // Get lambda action to perform (getFollowers) or (getFollowees)
    lambdaAction = dataDelegate?.lambdaActionForUser()
  
//    if currentUserName == nil {
//    }
//    
//    if lambdaAction == nil {
//    }
    
    connectionList = Array<Connection>()
    expansionObj = CellExpansion()
    
    defaultImage = UIImage(imageLiteral: "Person Icon Black")
    
    
    // Fill the dictionary of all social media names (key) with an image (val).
    // I.e. {["facebook", <facebook_emblem_image>], ["snapchat", <snapchat_emblem_image>] ...}
    socialMediaImageDictionary = getAllPossibleSocialMediaImages()
    
    
    // Set up refresh control for when user drags for a refresh.
    refreshControl = CustomRefreshControl()
    
    // When user pulls, this function will be called
    refreshControl.addTarget(self, action: #selector(RecentConnections.refreshTable(_:)), forControlEvents: UIControlEvents.ValueChanged)
    userTableView.addSubview(refreshControl)
    
    // Call all lambda functions and AWS-needed stuff
    generateData(true, start: currentBegin, end: currentEnd)
    
  }
  
  override func viewDidAppear(animated: Bool) {
    //        generateData(false)
  }
  
  // Function that is called when user drags/pulls table with intention of refreshing it
  func refreshTable(sender:AnyObject)
  {
    self.refreshControl.beginRefreshing()
    
    // Regenerate data
    currentBegin = 0
    currentEnd = offset
    isNewDataLoading = false
    generateData(false, start: currentBegin, end: currentEnd)
    
    // Need to end refreshing
    delay(1)
    {
      self.refreshControl.endRefreshing()
    }
  }
  
  
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    if scrollView == self.userTableView
    {
      let location = scrollView.contentOffset.y + scrollView.frame.size.height
      
      if location >= scrollView.contentSize.height
      {
        // Load data only if more data is not loading.
        if !isNewDataLoading
        {
          isNewDataLoading = true
          addTableViewFooterSpinner()
          
          currentBegin = currentBegin + offset
          currentEnd = currentEnd + offset
          generateData(false, start: currentBegin, end: currentEnd)
        }
      }
      
    }
  }
  
  func changeUser(newUserName: String) {
    self.currentUserName = newUserName
    
    // Regenerate data
    currentBegin = 0
    currentEnd = offset
    isNewDataLoading = false
    generateData(false, start: currentBegin, end: currentEnd)
  }
  
  func changeLambdaAction(newLambdaAction: String) {
    self.lambdaAction = newLambdaAction
    
    // Regenerate data
    currentBegin = 0
    currentEnd = offset
    isNewDataLoading = false
    generateData(false, start: currentBegin, end: currentEnd)
  }
  
  
  
  // TABLE VIEW
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
    // TODO: If more than one user,
    // Display up to 30 users immediately
    // Display 20 more if user keeps sliding down
    
    return connectionList.count
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    //        print("DDD*********************************************************")
    //        print(" Size of connectionList is: ", connectionList.count)
    //        print(" Number of rowsi n table is: ", tableView.numberOfRowsInSection(0))
    //        print(" Indexpath is: ", indexPath.row)
    //        print("*********************************************************")
    
    
    let cell = tableView.dequeueReusableCellWithIdentifier("contactsCell", forIndexPath: indexPath) as! ContactsTableViewCell
    
    if connectionList.count == 0
    {
      return cell
    }
    
    // Ensure that internal cellImage is circular
    cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
    
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
    cell.collectionView.tag = /*(connectionList.count - 1) - */ indexPath.row
    
    // Reset UICollectionViewLayout
    
    // So, turns out that iOS will re-use collection views. Imagine the following scenario:
    // Joe is at row 6, he has 4 social media profiles linked.
    // The page is refreshed, and Joe now is pushed to row 7 of the table.
    // Jill, who has 2 social media profiles, is now at row 6.
    // iOS will still assume that row 6's collectionView has 4 social media profiles,
    // and thus.. the app will search out of the proper index range and CRASH.
    // To fix this, we need to clear our data source, reload, and then reload with
    // applicable data. Shown as follows:
    //        let temporaryList = connectionList[indexPath.row].keyValSocialMediaPairList
    //        connectionList[indexPath.row].keyValSocialMediaPairList = Array<KeyValSocialMediaPair>()
    //        cell.collectionView.reloadData()
    //
    //        // Perform reloadData actions immediately instead of later
    //        cell.collectionView.layoutIfNeeded()
    //
    //        connectionList[indexPath.row].keyValSocialMediaPairList = temporaryList
    cell.collectionView.collectionViewLayout.invalidateLayout()
    cell.collectionView.reloadData()
    
    
    return cell
    
  }
  
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    
    if !tableView.dragging && !tableView.tracking
    {
      // Set the new selectedRowIndex
      updateCurrentlyExpandedRow(&expansionObj, currentRow: indexPath.row)
      
      // Update UI with animation
      tableView.beginUpdates()
      tableView.endUpdates()
      
    }
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    // Return height computed by our special function
    return getTableRowHeightForDropdownCell(&expansionObj, currentRow: indexPath.row)
  }
  
  // COLLECTION VIEW
  func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    
    if connectionList.count == 0
    {
      return 0
    }
    
    
    print("RETURNING content for index: ", collectionView.tag)
    print("Size is of collectionview should be...: ", connectionList[collectionView.tag].keyValSocialMediaPairList.count)
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
    
    let cell = collectionView.cellForItemAtIndexPath(indexPath) as! SocialMediaCollectionViewCell
    let socialMediaUserName = cell.socialMediaName // username..
    let socialMediaType = cell.socialMediaType // "facebook", "snapchat", etc..
    
    let socialMediaURL = getUserSocialMediaURL(socialMediaUserName, socialMediaTypeName: socialMediaType, sender: self)
    
    // Perform the request, go to external application and let the user do whatever they want!
    if socialMediaURL != nil
    {
      UIApplication.sharedApplication().openURL(socialMediaURL)
    }
    
  }
  
  private func generateData(showSpinner: Bool, start: Int, end: Int)
  {
    // If we don't store our data into a temporary object -- we'll be modifying the table data source while it may still
    // be used in the tableView methods! This prevents a crash.
    var newConnectionList = Array<Connection>()
    
    // Only show the middle spinner if user did not refresh table or if init (or else there would be two spinners!)
    if showSpinner && start == 0
    {
      spinner.hidden = false
      spinner.startAnimating()
    }
    
    if start != 0
    {
      addTableViewFooterSpinner()
    }
    
    // Get array of connections from Lambda -- RDS
    let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
    var parameters = ["action": lambdaAction, "target": currentUserName, "start": start, "end": end]
    
    // TODO:  ****** ACTUALLY IMPLEMENT BACKEND FOR THIS *******
  /*  if alphabeticalOrder {
       parameters = ["action": lambdaAction, "target": currentUserName, "start": start, "end": end, "order": "abc"]
    } */
    // TODO: ABOVE
    
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
        if connectionsFetchedList.count == 0 && start == 0
        {
          dispatch_async(dispatch_get_main_queue(), {
            self.spinner.hidden = true
            self.spinner.stopAnimating()
            self.connectionList = Array<Connection>()
            self.userTableView.reloadData()
            print("RELOADED 0 COUNT DATA")
          })
          
          return nil
        }
        else if connectionsFetchedList.count == 0 && start != 0
        {
          dispatch_async(dispatch_get_main_queue(), {
            self.removeTableViewFooterSpinner()
            
          })
          
        }
        
        // Propogate local data structure -- helps us prevent needing to
        // fetch more data and prevents race conditions later too
        for userData in connectionsFetchedList
        {
          let con = Connection()
          con.userName = userData.objectAtIndex(0) as! String
          con.timestampGMT = userData.objectAtIndex(1) as! Int
          
          newConnectionList.append(con)
        }
        
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
              
              getUserS3Image(userConnection.userName, completion: { (result, error) in
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
                  dispatch_async(dispatch_get_main_queue(), {
                    
                    // If initial fetch, just store entire array
                    if start == 0
                    {
                      self.connectionList = newConnectionList
                      self.spinner.hidden = true
                      self.spinner.stopAnimating()
                    }
                    else
                    {
                      self.removeTableViewFooterSpinner()
                      self.isNewDataLoading = false
                      self.connectionList.appendContentsOf(newConnectionList)
                    }
                    
                    self.userTableView.reloadData()
                    self.userTableView.layoutIfNeeded()
                    
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
        self.spinner.hidden = true
        self.spinner.stopAnimating()
        
      }
      
      return nil
      
    }
    
  }
  
  private func addTableViewFooterSpinner() {
    let footerSpinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    footerSpinner.startAnimating()
    footerSpinner.frame = CGRectMake(0, 0, self.view.frame.width, 44)
    self.userTableView.tableFooterView = footerSpinner
  }
  
  private func removeTableViewFooterSpinner() {
    self.userTableView.tableFooterView = nil
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



