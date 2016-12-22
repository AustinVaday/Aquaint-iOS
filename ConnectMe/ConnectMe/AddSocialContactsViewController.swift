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

class AddSocialContactsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, SearchTableViewCellDelegate {

  @IBOutlet weak var friendsTableView: UITableView!
  @IBOutlet weak var numberOfFriendsText: UITextField!
  
  var isNewDataLoading = false
  var defaultImage : UIImage!
  var followeesMapping : [String: Int]!
  var recentUsernameAdds : NSMutableDictionary!
  var currentSearchBegin = 0
  var currentSearchEnd = 15
  let searchOffset = 15
  let imageCache = NSCache()
  var users: Array<User>!
  var userName: String!

  
  // Data retrieved from previous VC
  var listOfFBUserIDs = Set<String>()
  
  override func viewDidLoad() {
    users = Array<User>()
    followeesMapping = [String: Int]()
    recentUsernameAdds = NSMutableDictionary()

    userName = getCurrentCachedUser()
    defaultImage = UIImage(imageLiteral: "Person Icon Black")
    
    let numFriendsFound = listOfFBUserIDs.count
    let numFriendsFoundStr = "We found " + String(numFriendsFound) + " of your Facebook friends on Aquaint."
    numberOfFriendsText.text = numFriendsFoundStr
    
    let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
    let parameters = ["action":"getFolloweesDict", "target": userName]
    lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
      if resultTask.result != nil && resultTask.error == nil
      {
        self.followeesMapping = resultTask.result! as! [String: Int]
      }
     
      return nil
      
    }
    
    generateData(self.currentSearchBegin, end: self.currentSearchEnd)

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

  func scrollViewDidScroll(scrollView: UIScrollView) {
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
  }

  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    
    let cell = tableView.dequeueReusableCellWithIdentifier("searchCell", forIndexPath: indexPath) as! SearchTableViewCell
    
    // Set default image immediately for smooth transitions
    cell.cellImage.image = defaultImage
    
    var userFullName : String!
    var userName : String!
    var userImage : UIImage!
    

    userFullName = users[indexPath.item].realname
    userName     = users[indexPath.item].username

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
        // If no relationship, show add button
      else
      {
        cell.activateAddButton()
      }
      
    }
    cell.cellName.text = userFullName
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
    if start != 0 && end != self.searchOffset
    {
      addTableViewFooterSpinner()
    }
    else
    {
//      spinner.startAnimating()
    }
    
    // FILL users<User> list here from the IDs of FB friends generated
    
    print("YOLOFBLIST: ", self.listOfFBUserIDs)
    
    
//    let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
//    let parameters = ["action":"simplesearch", "target": searchText, "start": start, "end": end]
//    lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock { (resultTask) -> AnyObject? in
//      if resultTask.error != nil
//      {
//        print("FAILED TO INVOKE LAMBDA FUNCTION - Error: ", resultTask.error)
//      }
//      else if resultTask.exception != nil
//      {
//        print("FAILED TO INVOKE LAMBDA FUNCTION - Exception: ", resultTask.exception)
//        
//      }
//      else if resultTask.result != nil
//      {
//        
//        print("RESULTO ARRAY IS:", resultTask.result)
//        
//        let searchResultArray = resultTask.result as! Array<String>
//        
//        if searchResultArray.count == 0 && start == 0
//        {
//          
//          dispatch_async(dispatch_get_main_queue(), {
//            self.spinner.stopAnimating()
//            self.noSearchResultsView.hidden = false
//            self.filteredUsers = Array<User>()
//            self.searchTableView.reloadData()
//            
//          })
//        }
//        else if searchResultArray.count == 0 && start != 0
//        {
//          self.isNewDataLoading = false
//          dispatch_async(dispatch_get_main_queue(), {
//            self.removeTableViewFooterSpinner()
//          })
//          
//        }
//        else if start == 0
//        {
//          dispatch_async(dispatch_get_main_queue(), {
//            self.noSearchResultsView.hidden = true
//          })
//        }
//        
//        
//        
//        var runningRequests = 0
//        var newFilteredUsersList = Array<User>()
//        
//        // If lists are not equal, we need to fetch data from the servers
//        // and re-propagate the list
//        for searchUser in searchResultArray
//        {
//          
//          runningRequests = runningRequests + 1
//          getUserDynamoData(searchUser, completion: { (result, error) in
//            if error == nil && result != nil
//            {
//              
//              let resultUser = result! as User
//              
//              newFilteredUsersList.append(resultUser)
//              
//              getUserS3Image(searchUser, completion: { (result, error) in
//                
//                if (result != nil)
//                {
//                  // Cache user image so we don't have to reload it next time
//                  self.imageCache.setObject(result! as UIImage, forKey: searchUser)
//                  
//                }
//                
//                runningRequests = runningRequests - 1
//                
//                if runningRequests == 0
//                {
//                  // Update UI when no more running requests! (last async call finished)
//                  // Update UI on main thread
//                  dispatch_async(dispatch_get_main_queue(), {
//                    self.spinner.stopAnimating()
//                    
//                    // Initial fetch, just store entire array
//                    if start == 0 && end == self.searchOffset
//                    {
//                      self.filteredUsers = newFilteredUsersList
//                    }
//                    else // append to current filtered users list
//                    {
//                      self.removeTableViewFooterSpinner()
//                      self.isNewDataLoading = false
//                      self.filteredUsers.appendContentsOf(newFilteredUsersList)
//                      
//                    }
//                    
//                    self.searchTableView.reloadData()
//                    
//                  })
//                  
//                }
//              })
//            }
//          })
//        }
//        
//      }
//      else
//      {
//        print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
//        
//      }
//      
//      return nil
//      
//    }
//    
//    // Reload table view with new results
//    friendsTableView.reloadData()
    
  }


  // Implement delegate actions for SearchTableViewCellDelegate
  func addedUser(username: String) {
    // When user is added from tableview cell
    // Add to set to keep track of recently added users
    recentUsernameAdds.setObject(getTimestampAsInt(), forKey: username)
    followeesMapping[username] = getTimestampAsInt()
  }
  
  func removedUser(username: String) {
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
