//
//  SearchViewController.swift
//  
//
//  Created by Austin Vaday on 4/7/16.
//
//

import UIKit
import AWSDynamoDB
import AWSLambda
import FRHyperLabel

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, CustomSearchControllerDelegate, SearchTableViewCellDelegate {

    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var noSearchResultsView: UIView!
    @IBOutlet weak var searchResultsInfoLabel: UILabel!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var searchController: UISearchController!
    var customSearchController: CustomSearchController!
    var userName : String!
    var userId   : String!
    var selectorSearchText : String!
    var filteredUsers: Array<UserPrivacyObjectModel>!
    var shouldShowSearchResults = false
    var isTypingSearch = false
    var isNewDataLoading = false
    var defaultImage : UIImage!
    var followeesMapping : [String: Int]!
    var followeeRequestsMapping : [String: Int]!
    var recentUsernameAdds : NSMutableDictionary!
    var animatedObjects : Array<UIView>!
    var currentSearchBegin = 0
    var currentSearchEnd = 15
    let searchOffset = 15
    let imageCache = NSCache()


    override func viewDidLoad(){
        filteredUsers = Array<UserPrivacyObjectModel>()
        followeesMapping = [String: Int]()
        followeeRequestsMapping = [String: Int]()
        recentUsernameAdds = NSMutableDictionary()
        animatedObjects = Array<UIView>()
        
        noSearchResultsView.hidden = true
        
        configureCustomSearchController()
        
        userName = getCurrentCachedUser()
        defaultImage = UIImage(imageLiteral: "Person Icon Black")
        
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        var parameters = ["action":"getFolloweesDict", "target": userName]
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
                self.followeesMapping = resultTask.result! as! [String: Int]
                
            }
            else
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                
            }
            
            return nil
            
        }
      
        parameters = ["action":"getFolloweeRequestsDict", "target": userName]
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
            
            print("SUCCESSFULLY INVOKEd LAMBDA FUNCTION WITH RESULT (REQUESTS): ", resultTask.result)
            self.followeeRequestsMapping = resultTask.result! as! [String: Int]
            
          }
          else
          {
            print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
            
          }
          
          return nil
          
        }


    }
  
    override func viewDidAppear(animated: Bool) {

        // If this is not here, then we will upload same user events to dynamo every time.
        recentUsernameAdds = NSMutableDictionary()
        
        // Set up animations
        
        if self.filteredUsers.count == 0
        {
            setUpAnimations(self)
        }
        print("Filter list size:", self.filteredUsers.count)
      
        awsMobileAnalyticsRecordPageVisitEventTrigger("SearchViewController", forKey: "page_name")
    }
    
    // When the view disappears, upload action data to Dynamo (used for newsfeed)
    override func viewDidDisappear(animated: Bool) {
        
        // Clear any animations that were deployed
        clearUpAnimations()
        noSearchResultsView.hidden = true
        
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
        if scrollView == searchTableView
        {
            let location = scrollView.contentOffset.y + scrollView.frame.size.height
            
            print("Location is ", location)
            print("content size is ", scrollView.contentSize.height)
            if location >= scrollView.contentSize.height
            {
                // Load data only if more data is not loading and if we actually have data to search
                if !isNewDataLoading && selectorSearchText != nil && !selectorSearchText.isEmpty
                {
                    isNewDataLoading = true
                    addTableViewFooterSpinner()
                    //Note: newsfeedPageNum will keep being incremented
                    currentSearchBegin = currentSearchBegin + searchOffset
                    currentSearchEnd = currentSearchEnd + searchOffset
                  
                 
                    performSimpleSearch(selectorSearchText, start: currentSearchBegin, end: currentSearchEnd)
                }
            }
            
        }
    }

    
    // **** SEARCHBAR PROTOCOLS (CUSTOM SEARCH BAR) *****
    func didStartSearching() {
        // Use filtered array
        shouldShowSearchResults = true
        resetCurrentSearchOffsets()
        searchTableView.reloadData()
    }
    
    func didTapOnCancelButton() {
        shouldShowSearchResults = false
        
        // Should wipe array
        filteredUsers = Array<UserPrivacyObjectModel>()
        setUpAnimations(self)
        resetCurrentSearchOffsets()
        
        searchTableView.reloadData()
    }
    
    func didTapOnSearchButton() {
        // If not already showing results, begin showing them now
        if (!shouldShowSearchResults)
        {
            shouldShowSearchResults = true
            searchTableView.reloadData()
        }
    }
    
    func didChangeSearchText(searchText: String) {
        // Implement throttle search to limit network activity and reload x seconds after key press
        resetCurrentSearchOffsets()
        selectorSearchText = searchText
        NSObject.cancelPreviousPerformRequestsWithTarget(self, selector: #selector(SearchViewController.simpleSearchSelector), object: nil)
        self.performSelector(#selector(SearchViewController.simpleSearchSelector), withObject: nil, afterDelay: 0.3)
    }
    
    // **** SEARCH TABLE VIEW *****
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("searchCell", forIndexPath: indexPath) as! SearchTableViewCell
        
        // Set default image immediately for smooth transitions
        cell.cellImage.image = defaultImage
        
        var userFullName : String!
        var userName : String!
      
        // Get applicable user from applicable array
        if (shouldShowSearchResults)
        {
            userFullName = filteredUsers[indexPath.item].realname
            userName     = filteredUsers[indexPath.item].username
          
            // Check if private account
            if filteredUsers[indexPath.item].isprivate != nil && filteredUsers[indexPath.item].isprivate == 1 {
              cell.displayPrivate = true
            }
            else {
              cell.displayPrivate = false
            }
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
        
        if (shouldShowSearchResults)
        {
            // If user is searching, show applicable search results.
            // If no users, show animation indicating no result
            
            if filteredUsers.count == 0
            {
                setUpAnimations(self)
                
                if isTypingSearch
                {
                    searchResultsInfoLabel.hidden = false
                }
                else
                {
                    searchResultsInfoLabel.hidden = true
                }
            }
            else
            {
                clearUpAnimations()
                searchResultsInfoLabel.hidden = true

            }
            
            return filteredUsers.count
        }
        else
        {
             return 0
        }
        
    }


    // If you want custom (beautiful) Aquaint search bar
    private func configureCustomSearchController()
    {
        let frame =  CGRectMake(0.0, 0.0, searchTableView.frame.size.width, 48.0)
        let font = UIFont(name: "Avenir", size: 14.0)!
        
        // UI Color for #12BBD5 (www.uicolor.xyz)
//        let textColor = UIColor(red:0.07, green:0.73, blue:0.84, alpha:1.0)

        let textColor = UIColor.whiteColor()
        
        // UI Color for #0F7A9D (www.uicolor.xyz)
        let tintColor = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
        
        // UI Color for #E6E6E6 (www.uicolor.xyz)
//        let tintColor = UIColor(red:0.90, green:0.90, blue:0.90, alpha:1.0)
        
        
        
        customSearchController = CustomSearchController(searchResultsController: self, searchBarFrame: frame, searchBarFont: font, searchBarTextColor: textColor, searchBarTintColor: tintColor)
        
        customSearchController.customSearchBar.placeholder = "Search for people"
        
        
        customSearchController.customDelegate = self
        
        searchTableView.tableHeaderView = customSearchController.customSearchBar
    }
    
    func simpleSearchSelector()
    {
        self.performSimpleSearch(self.selectorSearchText, start: 0, end: 15)
    }

    func performSimpleSearch(searchText: String, start: Int, end: Int)
    {
        if searchText.characters.count < 1
        {
            isTypingSearch = false
            return
        }
        else
        {
            isTypingSearch = true
        }
        
        
        
        if start != 0 && end != self.searchOffset
        {
            addTableViewFooterSpinner()
        }
        else
        {
            spinner.startAnimating()
        }
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        let parameters = ["action":"simplesearch", "target": searchText, "start": start, "end": end]
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
                
                print("RESULTO ARRAY IS:", resultTask.result)
                
                let searchResultArray = resultTask.result as! Array<String>
                
                if searchResultArray.count == 0 && start == 0
                {
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.spinner.stopAnimating()
                        self.noSearchResultsView.hidden = false
                        self.filteredUsers = Array<UserPrivacyObjectModel>()
                        self.searchTableView.reloadData()
                        
                    })
                }
                else if searchResultArray.count == 0 && start != 0
                {
                    self.isNewDataLoading = false
                    dispatch_async(dispatch_get_main_queue(), {
                        self.removeTableViewFooterSpinner()
                    })
                    
                }
                else if start == 0
                {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.noSearchResultsView.hidden = true
                    })
                }
        
                
                
                var runningRequests = 0
                var newFilteredUsersList = Array<UserPrivacyObjectModel>()
                
                // If lists are not equal, we need to fetch data from the servers
                // and re-propagate the list
                for searchUser in searchResultArray
                {
                    
                    runningRequests = runningRequests + 1
                    getUserDynamoData(searchUser, completion: { (result, error) in
                        if error == nil && result != nil
                        {
                            
                            let resultUser = result! as UserPrivacyObjectModel
                            
                            newFilteredUsersList.append(resultUser)
                            
                            getUserS3Image(searchUser, extraPath: nil, completion: { (result, error) in
                                
                                if (result != nil)
                                {
                                    // Cache user image so we don't have to reload it next time
                                    self.imageCache.setObject(result! as UIImage, forKey: searchUser)
                                    
                                }
                                
                                runningRequests = runningRequests - 1
                                
                                if runningRequests == 0
                                {
                                    // Update UI when no more running requests! (last async call finished)
                                    // Update UI on main thread
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.spinner.stopAnimating()
                                        
                                        // Initial fetch, just store entire array
                                        if start == 0 && end == self.searchOffset
                                        {
                                            self.filteredUsers = newFilteredUsersList
                                        }
                                        else // append to current filtered users list
                                        {
                                            self.removeTableViewFooterSpinner()
                                            self.isNewDataLoading = false
                                            self.filteredUsers.appendContentsOf(newFilteredUsersList)
                                            
                                        }
                                        
                                        self.searchTableView.reloadData()
                                        
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
        
        // Reload table view with new results
        searchTableView.reloadData()

    }

    private func setUpAnimations(viewController: UIViewController)
    {
        // Only add more animations if none exist already. Prevents user abuse
        if !animatedObjects.isEmpty
        {
            return
        }
        
        for i in 0...10
        {
            
            // Set up object to animate
            let object = UIView()
            
            // Generate random size offset from 0.0 to 20.0
            let randomSizeOffset = CGFloat(arc4random_uniform(20))
            
//            let image = UIImage(named:"Search Icon")
//            let imageView = UIImageView(image: image)
//            imageView.frame = CGRect(x:0, y:0, width:20 + randomSizeOffset, height:20 + randomSizeOffset)
//            imageView.backgroundColor = generateRandomColor()
//            imageView.layer.cornerRadius = imageView.frame.size.width / 2
//            object.addSubview(imageView)
            
            object.frame = CGRect(x:0, y:0, width:20 + randomSizeOffset, height:20 + randomSizeOffset)
            object.backgroundColor = generateRandomColor()
            object.layer.cornerRadius = object.frame.size.width / 2

            
            // Generate random number from 0.0 and 200.0
            let randomYOffset = CGFloat( arc4random_uniform(200))
            
            // Add object to subview
            self.view.addSubview(object)
            
            // Create a cool path that defines animation curve
            let path = UIBezierPath()
            path.moveToPoint(CGPoint(x:-20, y:239 + randomYOffset))
            path.addCurveToPoint(CGPoint(x:viewController.view.frame.width + 50 , y: 239 + randomYOffset), controlPoint1: CGPoint(x: 136, y: 373 + randomYOffset), controlPoint2: CGPoint(x: 178, y: 110 + randomYOffset))
            
            // Set up animation with path
            let animation = CAKeyframeAnimation(keyPath: "position")
            animation.path = path.CGPath
            
            // Set up rotational animations
            animation.rotationMode = kCAAnimationRotateAuto
            animation.repeatCount = Float.infinity
            animation.duration = 5.0
            // Each object will take between 4.0 and 8.0 seconds
            // to complete one animation loop
            animation.duration = Double(arc4random_uniform(40)+30) / 10
            
            // stagger each animation by a random value
            // `290` was chosen simply by experimentation
            animation.timeOffset = Double(arc4random_uniform(290))
            
            object.layer.addAnimation(animation, forKey: "animate position along path")
            animatedObjects.append(object)
        }
    }
    
    
    private func clearUpAnimations()
    {
        // Only remove animations if there are some that exist already. O(1) if empty
        if animatedObjects.isEmpty
        {
            return
        }
        
        for object in animatedObjects
        {
            object.layer.removeAllAnimations()
            object.removeFromSuperview()
        }
        
        animatedObjects.removeAll()
    }

    // Implement delegate actions for SearchTableViewCellDelegate
  func addedUser(username: String, isPrivate: Bool) {
      if !isPrivate {
          // When user is added from tableview cell
          // Add to set to keep track of recently added users
          recentUsernameAdds.setObject(getTimestampAsInt(), forKey: username)
          followeesMapping[username] = getTimestampAsInt()
          print("OKOK. USER ADDED: ", username)
      }
      else {
        followeeRequestsMapping[username] = getTimestampAsInt()
      }
    }
    
  func removedUser(username: String, isPrivate: Bool) {
      if !isPrivate {
          // When user is removed from tableview cell
          if recentUsernameAdds.objectForKey(username) != nil
          {
              recentUsernameAdds.removeObjectForKey(username)
          }
          
          followeesMapping.removeValueForKey(username)
          
          print("OKOK. USER REMOVED: ", username)
      } else {
        followeeRequestsMapping.removeValueForKey(username)
      }

    }
    
    private func addTableViewFooterSpinner() {
        let footerSpinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        footerSpinner.startAnimating()
        footerSpinner.frame = CGRectMake(0, 0, self.view.frame.width, 44)
        self.searchTableView.tableFooterView = footerSpinner
    }
    
    private func removeTableViewFooterSpinner() {
        self.searchTableView.tableFooterView = nil
    }
    
    private func resetCurrentSearchOffsets() {
        self.currentSearchBegin = 0
        self.currentSearchEnd = self.searchOffset
    }
    
}