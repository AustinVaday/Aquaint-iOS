//
//  AddSocialContactsViewController.swift
//  Aquaint
//
//  Created by Austin Vaday on 12/21/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import AWSLambda
import AWSS3
import AWSDynamoDB
import FRHyperLabel
import FBSDKLoginKit


class AddSocialContactsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SearchTableViewCellDelegate {

  @IBOutlet weak var friendsTableView: UITableView!
  @IBOutlet weak var numberOfFriendsText: UILabel!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  var isNewDataLoading = false
  var defaultImage : UIImage!
  var followeesMapping : [String: Int]!
  var followeeRequestsMapping : [String: Int]!
  var recentUsernameAdds : NSMutableDictionary!
  var currentSearchBegin = 0
  var currentSearchEnd = 15
  let searchOffset = 15
  let imageCache = NSCache()
  var users: Array<UserPrivacyObjectModel>!
  var userName: String!

  var listOfFBUserIDs = Set<String>()
  
  override func viewDidLoad() {
    users = Array<UserPrivacyObjectModel>()
    followeesMapping = [String: Int]()
    followeeRequestsMapping = [String: Int]()
    recentUsernameAdds = NSMutableDictionary()

    userName = getCurrentCachedUser()
    defaultImage = UIImage(imageLiteral: "Person Icon Black")
    
    let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
    var parameters = ["action":"getFolloweesDict", "target": userName]
    lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.result != nil && resultTask.error == nil
      {
        self.followeesMapping = resultTask.result! as! [String: Int]
      }
     
      return nil
      
    }
    
    parameters = ["action":"getFolloweeRequestsDict", "target": userName]
    lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.result != nil && resultTask.error == nil
      {
        self.followeeRequestsMapping = resultTask.result! as! [String: Int]
      }
      
      return nil
      
    }

    dispatch_async(dispatch_get_main_queue()) { 
      self.getFacebookFriendsUsingApp { (error) in
        if error == nil {
          
          let numFriendsFound = self.listOfFBUserIDs.count
//          let numFriendsFoundStr = "You have " + String(numFriendsFound) + " friends on Facebook that use Aquaint."
          // Use arbirtary indicator until we can be certain that the numFriendsFound number is consistent with
          // the number of cells that it displays. Right now, it is not.
          let numFriendsFoundStr = "We found some of your Facebook friends on Aquaint!"
          dispatch_async(dispatch_get_main_queue(), {
            self.numberOfFriendsText.text = numFriendsFoundStr
            self.numberOfFriendsText.hidden = false
          })
          
          self.generateData(self.currentSearchBegin, end: self.currentSearchEnd)
        }
      }
    }
    

  }
  
  override func viewDidAppear(animated: Bool) {
    // If this is not here, then we will upload same user events to dynamo every time.
    recentUsernameAdds = NSMutableDictionary()

  }
  
  // When the view disappears, upload action data to Dynamo (used for newsfeed)
  override func viewDidDisappear(animated: Bool) {
    
    // Only update dynamo if there are changes to account for.
    if recentUsernameAdds.count != 0
    {
      
      // Here's what we'll do: When the user leaves this page, we will take the recent additions (100 max)
      // and store them in dynamo. This information will be used for the newsfeed.
      let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
      
      // Get dynamo mapper if it exists
      dynamoDBObjectMapper.load(NewsfeedEventListObjectModel.self, hashKey: self.userName, rangeKey: nil).continueWithBlock({ (resultTask) -> AnyObject? in
        
        var newsfeedObjectMapper : NewsfeedEventListObjectModel!
        
        // If successfull find, use that data
        if (resultTask.error == nil && resultTask.exception == nil && resultTask.result != nil)
        {
          newsfeedObjectMapper = resultTask.result as! NewsfeedEventListObjectModel
        }
        else // Else, use new mapper class
        {
          newsfeedObjectMapper = NewsfeedEventListObjectModel()
        }
        
        // Store key
        newsfeedObjectMapper.username = self.userName
        
        // Sort datastructure by value (sort by timestamp)
        let sortedKeys = self.recentUsernameAdds.allKeys.sort({ (firstKey, secondKey) -> Bool in
          // Sort time in ascending order
          let string1 = firstKey as! String
          let string2 = secondKey as! String
          
          let timestamp1 = self.recentUsernameAdds.valueForKey(string1) as! Int
          let timestamp2 = self.recentUsernameAdds.valueForKey(string2) as! Int
          
          return timestamp1 < timestamp2
        })
        
        // Upload to Dynamo
        
        // Add an event for first 10 username add
        let numUsersLimit = 10
        var index = 0
        for otherUser in sortedKeys
        {
          // Prevent too many adds at once
          index = index + 1
          if index >= numUsersLimit
          {
            // Exit loop
            break
          }
          
          let otherUsersArray = NSArray(object: otherUser)
          let timestamp = self.recentUsernameAdds.objectForKey(otherUser) as! Int
          let newsfeedObject = NSMutableDictionary(dictionary: ["event": "newfollowing", "other": otherUsersArray, "time" : timestamp])
          newsfeedObjectMapper.addNewsfeedObject(newsfeedObject)
          
        }
        
        dynamoDBObjectMapper.save(newsfeedObjectMapper).continueWithSuccessBlock { (resultTask) -> AnyObject? in
          print("DynamoObjectMapper sucessful save for newsfeedObject #1")
          
          return nil
        }
        
        
        
        return nil
      })
      
      
      // For all people that a user follows, make sure to add a dynamo event for them too
      for user in recentUsernameAdds.allKeys
      {
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        
        
        // Get dynamo mapper if it exists
        dynamoDBObjectMapper.load(NewsfeedEventListObjectModel.self, hashKey: user, rangeKey: nil).continueWithBlock({ (resultTask) -> AnyObject? in
          
          var newsfeedObjectMapper : NewsfeedEventListObjectModel!
          
          // If successfull find, use that data
          if (resultTask.error == nil && resultTask.exception == nil && resultTask.result != nil)
          {
            newsfeedObjectMapper = resultTask.result as! NewsfeedEventListObjectModel
          }
          else // Else, use a new mapper class
          {
            newsfeedObjectMapper = NewsfeedEventListObjectModel()
          }
          
          // Store key
          newsfeedObjectMapper.username = user as! String
          
          // Upload to Dynamo - Indicate that this user has a new follower
          let otherUsersArray = NSArray(object: self.userName)
          let timestamp = self.recentUsernameAdds.objectForKey(user) as! Int
          let newsfeedObject = NSMutableDictionary(dictionary: ["event": "newfollower", "other":  otherUsersArray, "time" : timestamp] )
          newsfeedObjectMapper.addNewsfeedObject(newsfeedObject)
          
          dynamoDBObjectMapper.save(newsfeedObjectMapper).continueWithSuccessBlock { (resultTask) -> AnyObject? in
            print("DynamoObjectMapper sucessful save for newsfeedObject #2")
            
            return nil
          }
          
          return nil
        })
        
        
      }
      
      
    }
    
  }

  @IBAction func backButtonClicked(sender: AnyObject) {
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  func scrollViewDidScroll(scrollView: UIScrollView) {
    /*
    if scrollView == friendsTableView
    {
      let location = scrollView.contentOffset.y + scrollView.frame.size.height
      
      print("Location is ", location)
      print("content size is ", scrollView.contentSize.height)
      if location >= scrollView.contentSize.height
      {
        // Load data only if more data is not loading and if we actually have data to search
        if !isNewDataLoading
        {
          isNewDataLoading = true
          addTableViewFooterSpinner()
          //Note: newsfeedPageNum will keep being incremented
          currentSearchBegin = currentSearchBegin + searchOffset
          currentSearchEnd = currentSearchEnd + searchOffset
          
          
          generateData(currentSearchBegin, end: currentSearchEnd)
        }
      }
      
    }
     */
  }

  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier("searchCell", forIndexPath: indexPath) as! SearchTableViewCell
    
    // Set default image immediately for smooth transitions
    cell.cellImage.image = defaultImage
    
    var userFullName : String!
    var userName : String!

    userFullName = users[indexPath.item].realname
    userName     = users[indexPath.item].username

    // Check if private account
    if users[indexPath.item].isprivate != nil && users[indexPath.item].isprivate == 1 {
      cell.displayPrivate = true
    }
    else {
      cell.displayPrivate = false
    }
    
    let image = imageCache.objectForKey(userName) as? UIImage
    
    if image != nil
    {
      cell.cellImage.image = image!
      print("USING CACHED IMAGE!")
    }
    else
    {
      cell.cellImage.image = self.defaultImage
    }
    
    // Do not let user add him/herself
    if (userName == self.userName)
    {
      print("HIDING ALL BUTTONS FOR: ", self.userName)
      cell.hideAllButtons()
    }
    else
    {
      cell.unHideAllButtons()
      
      // If already follow someone, display delete button
      if (followeesMapping[userName] != nil)
      {
        cell.activateDeleteButton()
      }
      // If already pending follow request, display pending button
      else if (followeeRequestsMapping[userName] != nil)
      {
        cell.activatePendingButton()
      }
      // If no relationship, show add button
      else
      {
        cell.activateAddButton()
      }
      
    }
    
    // Set up hyperlink
    let handler = {
      (hyperLabel: FRHyperLabel!, substring: String!) -> Void in
      showPopupForUser(userName, me: self.userName, searchConsistencyDelegate: cell)
    }
    
    cell.cellName.clearActionDictionary()
    cell.cellName.text = userFullName
    cell.cellName.setLinkForSubstring(userFullName, withLinkHandler: handler)
    cell.cellUserName.text = userName

    // Ensure that internal cellImage is circular
    cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
    
    // IMPORTANT!!!! If we don't have this we can't get data when user adds/deletes people.
    cell.searchDelegate = self
    
    return cell
    
  }
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if users.count == 0
      {
      }
      else
      {
        
      }
      
      return users.count
    
  }
  
  func generateData(start: Int, end: Int)
  {
//    if start != 0 && end != self.searchOffset
//    {
//      addTableViewFooterSpinner()
//    }
//    else
//    {
//      spinner.startAnimating()
//    }
    
    
    spinner.startAnimating()

    // No pagination just yet..
    for fbUID in self.listOfFBUserIDs {
      print("Processing fbUID: ", fbUID)
      fetchDynamoUserDataFromFBUID(fbUID)
      
    }
    
    spinner.stopAnimating()
    
  }


  func getFacebookFriendsUsingApp(completion: (error: NSError?)->())
  {
    let login = FBSDKLoginManager.init()
//    login.logOut()
    
    // Open in app instead of web browser!
    login.loginBehavior = FBSDKLoginBehavior.Native
    
    // Request basic profile permissions just to get user ID
    login.logInWithReadPermissions(["public_profile", "user_friends"], fromViewController: self) { (result, error) in
      // If no error, store facebook user ID
      if (error == nil && result != nil) {
        print("SUCCESS LOG IN!", result.debugDescription)
        print(result.description)
        
        print("RESULTOO: ", result)
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
          
          print("Current access user id: ", FBSDKAccessToken.currentAccessToken().userID)
          
          let request = FBSDKGraphRequest(graphPath: "/me/friends?fields=id", parameters: nil)
          request.startWithCompletionHandler { (connection, result, error) in
            if error == nil {
              let resultMap = result as! Dictionary<String, AnyObject>
              let resultIds = resultMap["data"] as! Array<Dictionary<String, String>>
              
              for object in resultIds {
                print("Id is: ", object["id"]! as String)
                let id = object["id"]! as String
                self.listOfFBUserIDs.insert(id)
              }
              
              completion(error: nil)
              
            } else {
              print("Error getting **FB friends", error)
              completion(error: error)
            }
          }
        }
      } else {
        completion(error: error)
      }
    }
    
    
    
    print("YOLOGINYO")
    
  }

  private func fetchDynamoUserDataFromFBUID(fbUID: String) {
    let dynamoDB = AWSDynamoDB.defaultDynamoDB()
    let scanInput = AWSDynamoDBScanInput()
    scanInput.tableName = "aquaint-users"
    scanInput.limit = 100
    scanInput.exclusiveStartKey = nil
      
    let UIDValue = AWSDynamoDBAttributeValue()
    UIDValue.S = fbUID
    
    scanInput.expressionAttributeValues = [":val" : UIDValue]
    scanInput.filterExpression = "fbuid = :val"
    
    
    dynamoDB.scan(scanInput).continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.result != nil && resultTask.error == nil
      {
        print("DB QUERY SUCCESS:", resultTask.result)
        let results = resultTask.result as! AWSDynamoDBScanOutput
        for result in results.items! {
          print("RESULT IS: ", result)
          
          let user = UserPrivacyObjectModel()
          user.realname = (result["realname"]?.S)! as String
          user.username = (result["username"]?.S)! as String
          if result["isprivate"] != nil {
            let isprivateString = (result["isprivate"]?.N)! as String
            user.isprivate = Int(isprivateString)! as NSNumber
          }
          
          self.users.append(user)

          getUserS3Image(user.username, completion: { (result, error) in
            
            if (result != nil)
            {
              // Cache user image so we don't have to reload it next time
              self.imageCache.setObject(result! as UIImage, forKey: user.username)
              dispatch_async(dispatch_get_main_queue(), {
                self.friendsTableView.reloadData()
              })

            }
            
          })
          
          
        }
        
        
      }
      else
      {
        print("DB QUERY FAILURE:", resultTask.error)
      }
      return nil
    }
  }
  
  
  // Implement delegate actions for SearchTableViewCellDelegate
  func addedUser(username: String, isPrivate: Bool) {
    // When user is added from tableview cell
    // Add to set to keep track of recently added users
    recentUsernameAdds.setObject(getTimestampAsInt(), forKey: username)
    followeesMapping[username] = getTimestampAsInt()
  }
  
  func removedUser(username: String, isPrivate: Bool) {
    // When user is removed from tableview cell
    if recentUsernameAdds.objectForKey(username) != nil
    {
      recentUsernameAdds.removeObjectForKey(username)
    }
    
    followeesMapping.removeValueForKey(username)
    
  }
  
  private func addTableViewFooterSpinner() {
    let footerSpinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
    footerSpinner.startAnimating()
    footerSpinner.frame = CGRectMake(0, 0, self.view.frame.width, 44)
    self.friendsTableView.tableFooterView = footerSpinner
  }
  
  private func removeTableViewFooterSpinner() {
    self.friendsTableView.tableFooterView = nil
  }
  
  private func resetCurrentSearchOffsets() {
    self.currentSearchBegin = 0
    self.currentSearchEnd = self.searchOffset
  }

  
  
}
