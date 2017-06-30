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


class AddSocialContactsViewController: ViewControllerPannable, UITableViewDataSource, UITableViewDelegate, SearchTableViewCellDelegate {

  @IBOutlet weak var friendsTableView: UITableView!
  @IBOutlet weak var numberOfFriendsText: UILabel!
  @IBOutlet weak var spinner: UIActivityIndicatorView!
  
  var isNewDataLoading = false
  var defaultImage : UIImage!
  var followeesMapping : [String: Int]!
  var followeeRequestsMapping : [String: Int]!
  var recentUsernameAdds : NSMutableDictionary!
  var currentSearchBegin = 0
  var currentSearchEnd = 25
  let searchOffset = 25
  let imageCache = NSCache<AnyObject, AnyObject>()
  var users: Array<UserPrivacyObjectModel>!
  var userName: String!

  var listOfFBUserIDs = Set<String>()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    users = Array<UserPrivacyObjectModel>()
    followeesMapping = [String: Int]()
    followeeRequestsMapping = [String: Int]()
    recentUsernameAdds = NSMutableDictionary()

    userName = getCurrentCachedUser()
    defaultImage = UIImage(imageLiteralResourceName: "Person Icon Black")
    
    let lambdaInvoker = AWSLambdaInvoker.default()
    var parameters = ["action":"getFolloweesDict", "target": userName]
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continueWith { (resultTask) -> AnyObject? in
      if resultTask.result != nil && resultTask.error == nil
      {
        self.followeesMapping = resultTask.result! as! [String: Int]
      }
     
      return nil
      
    }
    
    parameters = ["action":"getFolloweeRequestsDict", "target": userName]
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continueWith { (resultTask) -> AnyObject? in
      if resultTask.result != nil && resultTask.error == nil
      {
        self.followeeRequestsMapping = resultTask.result! as! [String: Int]
      }
      
      return nil
      
    }

    DispatchQueue.main.async { 
      self.getFacebookFriendsUsingApp { (error) in
        if error == nil {
          
          let numFriendsFound = self.listOfFBUserIDs.count
//          let numFriendsFoundStr = "You have " + String(numFriendsFound) + " friends on Facebook that use Aquaint."
          // Use arbirtary indicator until we can be certain that the numFriendsFound number is consistent with
          // the number of cells that it displays. Right now, it is not.
          let numFriendsFoundStr = "We found some of your Facebook friends on Aquaint!"
          DispatchQueue.main.async(execute: {
            self.numberOfFriendsText.text = numFriendsFoundStr
            self.numberOfFriendsText.isHidden = false
          })
          
          self.generateData(self.currentSearchBegin, end: self.currentSearchEnd)
        }
      }
    }
    

  }
  
  override func viewDidAppear(_ animated: Bool) {
    // If this is not here, then we will upload same user events to dynamo every time.
    recentUsernameAdds = NSMutableDictionary()

    awsMobileAnalyticsRecordPageVisitEventTrigger("AddSocialContactsViewController", forKey: "page_name")
  }
  
  // When the view disappears, upload action data to Dynamo (used for newsfeed)
  override func viewDidDisappear(_ animated: Bool) {
    
    // Only update dynamo if there are changes to account for.
    if recentUsernameAdds.count != 0
    {
      
      // Here's what we'll do: When the user leaves this page, we will take the recent additions (100 max)
      // and store them in dynamo. This information will be used for the newsfeed.
      let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
      
      // Get dynamo mapper if it exists
      dynamoDBObjectMapper.load(NewsfeedEventListObjectModel.self, hashKey: self.userName, rangeKey: nil).continueWith(block: { (resultTask) -> AnyObject? in
        
        var newsfeedObjectMapper : NewsfeedEventListObjectModel!
        
        // If successfull find, use that data
        if (resultTask.error == nil && resultTask.result != nil)
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
        let sortedKeys = self.recentUsernameAdds.allKeys.sorted(by: { (firstKey, secondKey) -> Bool in
          // Sort time in ascending order
          let string1 = firstKey as! String
          let string2 = secondKey as! String
          
          let timestamp1 = self.recentUsernameAdds.value(forKey: string1) as! Int
          let timestamp2 = self.recentUsernameAdds.value(forKey: string2) as! Int
          
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
          let timestamp = self.recentUsernameAdds.object(forKey: otherUser) as! Int
          let newsfeedObject = NSMutableDictionary(dictionary: ["event": "newfollowing", "other": otherUsersArray, "time" : timestamp])
          newsfeedObjectMapper.addNewsfeedObject(newsfeedObject)
          
        }
        
        dynamoDBObjectMapper.save(newsfeedObjectMapper).continueWith { (resultTask) -> AnyObject? in
          print("DynamoObjectMapper sucessful save for newsfeedObject #1")
          
          return nil
        }
        
        
        
        return nil
      })
      
      
      // For all people that a user follows, make sure to add a dynamo event for them too
      for user in recentUsernameAdds.allKeys
      {
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
        
        
        // Get dynamo mapper if it exists
        dynamoDBObjectMapper.load(NewsfeedEventListObjectModel.self, hashKey: user, rangeKey: nil).continueWith(block: { (resultTask) -> AnyObject? in
          
          var newsfeedObjectMapper : NewsfeedEventListObjectModel!
          
          // If successfull find, use that data
          if (resultTask.error == nil && resultTask.result != nil)
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
          let timestamp = self.recentUsernameAdds.object(forKey: user) as! Int
          let newsfeedObject = NSMutableDictionary(dictionary: ["event": "newfollower", "other":  otherUsersArray, "time" : timestamp] )
          newsfeedObjectMapper.addNewsfeedObject(newsfeedObject)
          
          dynamoDBObjectMapper.save(newsfeedObjectMapper).continueWith { (resultTask) -> AnyObject? in
            print("DynamoObjectMapper sucessful save for newsfeedObject #2")
            
            return nil
          }
          
          return nil
        })
        
        
      }
      
      
    }
    
  }

  @IBAction func backButtonClicked(_ sender: AnyObject) {
    self.dismiss(animated: true, completion: nil)
  }
  
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
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

  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! SearchTableViewCell
    
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
    
    let image = imageCache.object(forKey: userName as AnyObject) as? UIImage
    
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
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      if users.count == 0
      {
      }
      else
      {
        
      }
      
      return users.count
    
  }
  
  func generateData(_ start: Int, end: Int)
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


  func getFacebookFriendsUsingApp(_ completion: @escaping (_ error: NSError?)->())
  {
    let login = FBSDKLoginManager.init()
//    login.logOut()
    
    // Open in app instead of web browser!
    login.loginBehavior = FBSDKLoginBehavior.native
    
    // Request basic profile permissions just to get user ID
    login.logIn(withReadPermissions: ["public_profile", "user_friends"], from: self) { (result, error) in
      // If no error, store facebook user ID
      if (error == nil && result != nil) {
        print("SUCCESS LOG IN!", result.debugDescription)
        print(result?.description)
        
        print("RESULTOO: ", result)
        
        if (FBSDKAccessToken.current() != nil) {
          
          print("Current access user id: ", FBSDKAccessToken.current().userID)
          
          let currentGraphPath = "/me/friends?fields=id"
          
          self.startGraphRequest(currentGraphPath, completion: completion)
        
        }
      } else {
        completion(error as! NSError)
      }
    }
    
    
    
    print("YOLOGINYO")
    
  }
  
  fileprivate func startGraphRequest(_ path: String, completion: @escaping (_ error: NSError?)->()) {
    let request = FBSDKGraphRequest(graphPath: path, parameters: ["limit": "100"])
    request?.start { (connection, result, error) in
      if error == nil {
        let resultMap = result as! Dictionary<String, AnyObject>
        let resultIds = resultMap["data"] as! Array<Dictionary<String, String>>
        let pagingMap = resultMap["paging"] as! Dictionary<String, AnyObject>
//        
//        if pagingMap.keys.count != 0 && pagingMap.keys.contains("next")
//        {
//          print("PAGINATION TIME!!")
//          print(pagingMap["next"])
//          let nextGraphPath = pagingMap["next"] as! String
//          self.startGraphRequest(nextGraphPath, completion: completion)
//        }
        
        
        for object in resultIds {
          print("Id is: ", object["id"]! as String)
          let id = object["id"]! as String
          self.listOfFBUserIDs.insert(id)
        }
        
        completion(nil)
        
      } else {
        print("Error getting **FB friends", error)
        completion(error as! NSError)
      }
    }
    
  }

  fileprivate func fetchDynamoUserDataFromFBUID(_ fbUID: String) {
    let dynamoDB = AWSDynamoDB.default()
    let scanInput = AWSDynamoDBScanInput()
    scanInput?.tableName = "aquaint-users"
    scanInput?.limit = 200
    scanInput?.exclusiveStartKey = nil
      
    let UIDValue = AWSDynamoDBAttributeValue()
    UIDValue?.s = fbUID
    
    scanInput?.expressionAttributeValues = [":val" : UIDValue!]
    scanInput?.filterExpression = "fbuid = :val"
    
    
    dynamoDB.scan(scanInput!).continueWith { (resultTask) -> AnyObject? in
      print("SCAN FOR UID ", fbUID)
      if resultTask.result != nil && resultTask.error == nil
      {
        print("DB QUERY SUCCESS:", resultTask.result)
        let results = resultTask.result as! AWSDynamoDBScanOutput
        for result in results.items! {
          print("RESULT for UID ", fbUID, " IS: ", result)
          
          let user = UserPrivacyObjectModel()
          user?.realname = (result["realname"]?.s)! as String
          user?.username = (result["username"]?.s)! as String
          if result["isprivate"] != nil {
            let isprivateString = (result["isprivate"]?.n)! as String
            user?.isprivate = Int(isprivateString)! as NSNumber
          }
          
          self.users.append(user!)

          getUserS3Image(user?.username, extraPath: nil, completion: { (result, error) in
            
            if (result != nil)
            {
              // Cache user image so we don't have to reload it next time
              self.imageCache.setObject(result! as UIImage, forKey: user!.username as AnyObject)
              DispatchQueue.main.async(execute: {
                self.friendsTableView.reloadData()
              })

            }
            
          })
          
          
        }
        
      }
      else if resultTask.result == nil
      {
        print("DB QUERY NIL for UID:", fbUID )
      }
      else
      {
        print("DB QUERY FAILURE for UID:", fbUID, " error is: ", resultTask.error)
      }
      return nil
    }
  }
  
  
  // Implement delegate actions for SearchTableViewCellDelegate
  func addedUser(_ username: String, isPrivate: Bool) {
    // When user is added from tableview cell
    // Add to set to keep track of recently added users
    recentUsernameAdds.setObject(getTimestampAsInt(), forKey: username as NSCopying)
    followeesMapping[username] = getTimestampAsInt()
  }
  
  func removedUser(_ username: String, isPrivate: Bool) {
    // When user is removed from tableview cell
    if recentUsernameAdds.object(forKey: username) != nil
    {
      recentUsernameAdds.removeObject(forKey: username)
    }
    
    followeesMapping.removeValue(forKey: username)
    
  }
  
  fileprivate func addTableViewFooterSpinner() {
    let footerSpinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
    footerSpinner.startAnimating()
    footerSpinner.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
    self.friendsTableView.tableFooterView = footerSpinner
  }
  
  fileprivate func removeTableViewFooterSpinner() {
    self.friendsTableView.tableFooterView = nil
  }
  
  fileprivate func resetCurrentSearchOffsets() {
    self.currentSearchBegin = 0
    self.currentSearchEnd = self.searchOffset
  }

  
  
}
