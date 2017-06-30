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

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, CustomSearchControllerDelegate, SearchTableViewCellDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

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
    let imageCache = NSCache<AnyObject, AnyObject>()
  
  // Leaderboard
  /*
  var mostFollowersList = [("austin", 4240), ("navid", 1200), ("maxwyb", 80), ("aquaint", 10), ("gyukawa7", 5), ("nicholasrudar", 2)]
  var mostFollowingList = [("navid", 2100), ("austin", 140), ("aquaint", 10)]
  */
//  var mostFollowersList = [(String, Int)]()
//  var mostFollowingList = [(String, Int)]()
  
//  var metricLists = []()
  var metricLists = [Int: [(String, Int)]]()
  
  var userProfileImages = [String: UIImage]()
  var verifiedUserList = [String: Bool]()
  var leaderboardMetricsMap = [Int: String]() // map an index to a metric
  var leaderboardDisplayNameMap = [Int: String]() // map an index to a display name
//  enum leaderboardType: Int {
//    case MOST_FOLLOWERS = 0
//    case MOST_FOLLOWINGS = 1
//  }
//  
//  let MOST_FOLLOWERS_LABEL = "Most Followers"
//  let MOST_FOLLOWINGS_LABEL = "Most Followings"
  
  // NOTE: this DynamoDB access function is written here rather than in BackendAPI,
  // because its retrieval result need to be passed into local variables inside SearchViewController.swift
  // Otherwise we would have to pass in SearchViewController as a parameter to this function
  func retrieveLeaderboardDynamoDB(_ targetMetric: String) {
    
    let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
    
//    var hashKeyMetric: String
//    switch targetMetric {
//    case leaderboardType.MOST_FOLLOWERS:
//      hashKeyMetric = "mostFollowers"
//    case leaderboardType.MOST_FOLLOWINGS:
//      hashKeyMetric = "mostFollowings"
//    }

    let hashKeyMetric = targetMetric
    
    dynamoDBObjectMapper.load(Leaderboard.self, hashKey: hashKeyMetric, rangeKey: nil).continue({ (resultTask) -> AnyObject? in
      
      if (resultTask.error != nil || resultTask.exception != nil || resultTask.result == nil) {
        return nil
      }
      
      let leaderboardInfo = resultTask.result as! Leaderboard
      // Every username on the leaderboard should correspond to an attribute entry (his number of followers, number of followings, etc.)  
      if leaderboardInfo.usernames.count != leaderboardInfo.attributes.count {
        print("aquaint-leaderboards DynamoDB data has format error.")
      }
      
      // create the list of tuples following format: [(username, attributeNumber)]
      var leaderboardTupleList = [(String, Int)]()
      for i in 0..<leaderboardInfo.usernames.count {
        let leaderboardTuple = (leaderboardInfo.usernames[i], leaderboardInfo.attributes[i])
        leaderboardTupleList.append(leaderboardTuple)
      }
      
      self.metricLists[leaderboardInfo.index as Int] = leaderboardTupleList
      self.leaderboardDisplayNameMap[leaderboardInfo.index as Int] = leaderboardInfo.displayname
      
//      if (targetMetric == leaderboardType.MOST_FOLLOWERS) {
//        self.mostFollowersList = leaderboardTupleList
//      } else if (targetMetric == leaderboardType.MOST_FOLLOWINGS) {
//        self.mostFollowingList = leaderboardTupleList
//      }
      

      self.getLeaderboardUserImages()
      //self.searchTableView.reloadData()
      
      // Retrieve verified status for each user
      for user in leaderboardInfo.usernames {
        
        getUserVerifiedData(user, completion: { (result, error) in
          if result != nil && error == nil {
            let userData = result! as UserVerifiedMinimalObjectModel
            
            if userData.isverified != nil && userData.isverified == 1
            {
              self.verifiedUserList[user] = true
            } else {
              self.verifiedUserList[user] = false
            }
          }
          
        })
      }
      
      return nil
    })
    
    
  }
  
  // fetch all profile images of users on the leaderboard
  func getLeaderboardUserImages() {
    
    let defaultImage = UIImage(imageLiteral: "Person Icon Black")
    // Whenever we get ONE user profile image, we refresh data in CollectionView for seemingly faster performance
    
    for (_,list) in metricLists {
      for user in list {
        getUserS3Image(user.0, extraPath: nil, completion: { (result, error) in
          if (error == nil && result != nil) {
            self.userProfileImages[user.0] = result
          } else {
            // if there is no user image on S3, explictly specify to use the default blank image
            // Otherwide the imageView may be overwritten by another user's profile image
            self.userProfileImages[user.0] = defaultImage
          }
          self.searchTableView.reloadData()
        })
      }
    }
    
    
//    for user in mostFollowersList {
//      getUserS3Image(user.0, extraPath: nil, completion: { (result, error) in
//        if (error == nil && result != nil) {
//          self.userProfileImages[user.0] = result
//        } else {
//          // if there is no user image on S3, explictly specify to use the default blank image
//          // Otherwide the imageView may be overwritten by another user's profile image
//          self.userProfileImages[user.0] = defaultImage
//        }
//        self.searchTableView.reloadData()
//      })
//    }
//    
//    for user in mostFollowingList {
//      if (self.userProfileImages[user.0] == nil) {
//        getUserS3Image(user.0, extraPath: nil, completion: { (result, error) in
//          if (error == nil && result != nil) {
//            self.userProfileImages[user.0] = result
//          } else {
//            self.userProfileImages[user.0] = defaultImage
//          }
//          self.searchTableView.reloadData()
//        })
//      }
//    }
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    // WARM UP lambda for simplesearch function call. Speeds up initial search significantly 
    let lambdaInvoker = AWSLambdaInvoker.default()
    var parameters = ["action":"simplesearch", "target": "a", "start": 0, "end": 5] as [String : Any]
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (result) -> AnyObject? in
      return nil
    }
    
    userName = getCurrentCachedUser()
    
    parameters = ["action":"getFolloweesDict", "target": userName]
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
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
    lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
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

    override func viewDidLoad(){
        filteredUsers = Array<UserPrivacyObjectModel>()
        followeesMapping = [String: Int]()
        followeeRequestsMapping = [String: Int]()
        recentUsernameAdds = NSMutableDictionary()
        animatedObjects = Array<UIView>()
      
        noSearchResultsView.isHidden = true
        
        configureCustomSearchController()
        
        userName = getCurrentCachedUser()
        defaultImage = UIImage(imageLiteral: "Person Icon Black")
      
      // Leaderboard
//      retrieveLeaderboardDynamoDB(leaderboardType.MOST_FOLLOWERS)
//      retrieveLeaderboardDynamoDB(leaderboardType.MOST_FOLLOWINGS)
        self.fetchLeaderboardsMetricsMap()

    }
  
    override func viewDidAppear(_ animated: Bool) {

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
    override func viewDidDisappear(_ animated: Bool) {
        
        // Clear any animations that were deployed
        clearUpAnimations()
        noSearchResultsView.isHidden = true
        
        // Only update dynamo if there are changes to account for.
        if recentUsernameAdds.count != 0
        {

            // Here's what we'll do: When the user leaves this page, we will take the recent additions (100 max)
            // and store them in dynamo. This information will be used for the newsfeed.
            let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.default()
            
            // Get dynamo mapper if it exists
            dynamoDBObjectMapper.load(NewsfeedEventListObjectModel.self, hashKey: self.userName, rangeKey: nil).continue({ (resultTask) -> AnyObject? in
                
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
                
                dynamoDBObjectMapper.save(newsfeedObjectMapper).continue { (resultTask) -> AnyObject? in
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
                dynamoDBObjectMapper.load(NewsfeedEventListObjectModel.self, hashKey: user, rangeKey: nil).continue({ (resultTask) -> AnyObject? in
                    
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
                    let timestamp = self.recentUsernameAdds.object(forKey: user) as! Int
                    let newsfeedObject = NSMutableDictionary(dictionary: ["event": "newfollower", "other":  otherUsersArray, "time" : timestamp] )
                    newsfeedObjectMapper.addNewsfeedObject(newsfeedObject)
                    
                    dynamoDBObjectMapper.save(newsfeedObjectMapper).continue { (resultTask) -> AnyObject? in
                        print("DynamoObjectMapper sucessful save for newsfeedObject #2")
                        
                        return nil
                    }
                    
                    return nil
                })

                
            }
            
            
        }
        
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
    
    func didChangeSearchText(_ searchText: String) {
        // Implement throttle search to limit network activity and reload x seconds after key press
        resetCurrentSearchOffsets()
        selectorSearchText = searchText
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(SearchViewController.simpleSearchSelector), object: nil)
        self.perform(#selector(SearchViewController.simpleSearchSelector), with: nil, afterDelay: 0.3)
    }
    
    // **** SEARCH TABLE VIEW *****
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      // If it's not time to show search results, show Leaderboard users instead
      if (!shouldShowSearchResults) {
        //let cell = tableView.dequeueReusableCellWithIdentifier("leaderboardCell", forIndexPath: indexPath) as! SearchTableViewLeaderboardCell
        let leaderboardCell = tableView.dequeueReusableCell(withIdentifier: "leaderboardCell") as! SearchTableViewLeaderboardCell
        
        leaderboardCell.setCollectionViewDataSourceDelegate(self, forRow: indexPath.row)
        
//        switch indexPath.row {
//        case leaderboardType.MOST_FOLLOWERS.rawValue:
//          leaderboardCell.titleLabel.text = MOST_FOLLOWERS_LABEL
//        case leaderboardType.MOST_FOLLOWINGS.rawValue:
//          leaderboardCell.titleLabel.text = MOST_FOLLOWINGS_LABEL
//        default:
//          break
//        }
        
        leaderboardCell.titleLabel.text = leaderboardDisplayNameMap[indexPath.row]
        
        leaderboardCell.userCollectionView.backgroundColor = UIColor.white
        leaderboardCell.userCollectionView.reloadData()
        return leaderboardCell
      }
      
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchCell", for: indexPath) as! SearchTableViewCell
        
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
          
          // This will dismiss keyboard if not dismissed already
          self.customSearchController.customSearchBar.resignFirstResponder()
        }
      
        cell.cellName.clearActionDictionary()
        cell.cellName.text = userFullName
        cell.cellName.setLinkForSubstring(userFullName, withLinkHandler: handler)
      
        // Check if verified account
        if filteredUsers[indexPath.item].isverified != nil && filteredUsers[indexPath.item].isverified == 1 {
          addVerifiedIconToLabel(userName, label: cell.cellUserName, size: 12)
        }
        else {
          cell.cellUserName.text = userName
        }
      
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
        
        // IMPORTANT!!!! If we don't have this we can't get data when user adds/deletes people.
        cell.searchDelegate = self
      
        print("SearchViewController default cell height for showing search result: \(tableView.rowHeight)")
      
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (shouldShowSearchResults)
        {
            // If user is searching, show applicable search results.
            // If no users, show animation indicating no result
            
            if filteredUsers.count == 0
            {
                setUpAnimations(self)
                
                if isTypingSearch
                {
                    searchResultsInfoLabel.isHidden = false
                }
                else
                {
                    searchResultsInfoLabel.isHidden = true
                }
            }
            else
            {
                clearUpAnimations()
                searchResultsInfoLabel.isHidden = true

            }
            
            return filteredUsers.count
        }
        else
        {
          // If it's not time to show search results, count how many Leaderboard types we have (Essentially count of LeaderboardType)
          // SearchTableViewLeaderboardCell
             return metricLists.count
        }
        
    }


    // If you want custom (beautiful) Aquaint search bar
    fileprivate func configureCustomSearchController()
    {
        let frame =  CGRect(x: 0.0, y: 0.0, width: searchTableView.frame.size.width, height: 48.0)
        let font = UIFont(name: "Avenir", size: 14.0)!
        
        // UI Color for #12BBD5 (www.uicolor.xyz)
//        let textColor = UIColor(red:0.07, green:0.73, blue:0.84, alpha:1.0)

        let textColor = UIColor.white
        
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

    func performSimpleSearch(_ searchText: String, start: Int, end: Int)
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
        
        let lambdaInvoker = AWSLambdaInvoker.default()
        let parameters = ["action":"simplesearch", "target": searchText, "start": start, "end": end] as [String : Any]
        lambdaInvoker.invokeFunction("mock_api", jsonObject: parameters).continue { (resultTask) -> AnyObject? in
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
                    
                    DispatchQueue.main.async(execute: {
                        self.spinner.stopAnimating()
                        self.noSearchResultsView.isHidden = false
                        self.filteredUsers = Array<UserPrivacyObjectModel>()
                        self.searchTableView.reloadData()
                        
                    })
                }
                else if searchResultArray.count == 0 && start != 0
                {
                    self.isNewDataLoading = false
                    DispatchQueue.main.async(execute: {
                        self.removeTableViewFooterSpinner()
                    })
                    
                }
                else if start == 0
                {
                    DispatchQueue.main.async(execute: {
                        self.noSearchResultsView.isHidden = true
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
                          
                            runningRequests = runningRequests - 1

                            if runningRequests == 0
                            {
                              // Update UI when no more running requests! (last async call finished)
                              // Update UI on main thread
                              DispatchQueue.main.async(execute: {
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
                                  self.filteredUsers.append(contentsOf: newFilteredUsersList)
                                  
                                }
                                
                                self.searchTableView.reloadData()
                                
                              })

                            }
                          
                          
                            getUserS3Image(searchUser, extraPath: nil, completion: { (result, error) in
                              
                                if (result != nil)
                                {
                                    // Cache user image so we don't have to reload it next time
                                    self.imageCache.setObject(result! as UIImage, forKey: searchUser)
                                  
                                    DispatchQueue.main.async(execute: { 
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

    fileprivate func setUpAnimations(_ viewController: UIViewController)
    {
      
      // Since we have Leaderboards now, floating social media emblems now becomes a legacy feature
        //setUpSocialMediaAnimations(self, subView: self.view, animatedObjects: &animatedObjects!, animationLocation: AnimationLocation.Middle, theme: AnimationAquaintEmblemTheme.DarkTheme)
//        // Only add more animations if none exist already. Prevents user abuse
//        if !animatedObjects.isEmpty
//        {
//            return
//        }
//        
//        for i in 0...10
//        {
//            
//            // Set up object to animate
//            let object = UIView()
//            
//            // Generate random size offset from 0.0 to 20.0
//            let randomSizeOffset = CGFloat(arc4random_uniform(20))
//            
////            let image = UIImage(named:"Search Icon")
////            let imageView = UIImageView(image: image)
////            imageView.frame = CGRect(x:0, y:0, width:20 + randomSizeOffset, height:20 + randomSizeOffset)
////            imageView.backgroundColor = generateRandomColor()
////            imageView.layer.cornerRadius = imageView.frame.size.width / 2
////            object.addSubview(imageView)
//            
//            object.frame = CGRect(x:0, y:0, width:20 + randomSizeOffset, height:20 + randomSizeOffset)
//            object.backgroundColor = generateRandomColor()
//            object.layer.cornerRadius = object.frame.size.width / 2
//
//            
//            // Generate random number from 0.0 and 200.0
//            let randomYOffset = CGFloat( arc4random_uniform(200))
//            
//            // Add object to subview
//            self.view.addSubview(object)
//            
//            // Create a cool path that defines animation curve
//            let path = UIBezierPath()
//            path.moveToPoint(CGPoint(x:-20, y:239 + randomYOffset))
//            path.addCurveToPoint(CGPoint(x:viewController.view.frame.width + 50 , y: 239 + randomYOffset), controlPoint1: CGPoint(x: 136, y: 373 + randomYOffset), controlPoint2: CGPoint(x: 178, y: 110 + randomYOffset))
//            
//            // Set up animation with path
//            let animation = CAKeyframeAnimation(keyPath: "position")
//            animation.path = path.CGPath
//            
//            // Set up rotational animations
//            animation.rotationMode = kCAAnimationRotateAuto
//            animation.repeatCount = Float.infinity
//            animation.duration = 5.0
//            // Each object will take between 4.0 and 8.0 seconds
//            // to complete one animation loop
//            animation.duration = Double(arc4random_uniform(40)+30) / 10
//            
//            // stagger each animation by a random value
//            // `290` was chosen simply by experimentation
//            animation.timeOffset = Double(arc4random_uniform(290))
//            
//            object.layer.addAnimation(animation, forKey: "animate position along path")
//            animatedObjects.append(object)
//        }
    }
    
    
    fileprivate func clearUpAnimations()
    {
      
        clearUpSocialMediaAnimations(&animatedObjects!)
//        // Only remove animations if there are some that exist already. O(1) if empty
//        if animatedObjects.isEmpty
//        {
//            return
//        }
//        
//        for object in animatedObjects
//        {
//            object.layer.removeAllAnimations()
//            object.removeFromSuperview()
//        }
//        
//        animatedObjects.removeAll()
    }

    // Implement delegate actions for SearchTableViewCellDelegate
  func addedUser(_ username: String, isPrivate: Bool) {
      if !isPrivate {
          // When user is added from tableview cell
          // Add to set to keep track of recently added users
          recentUsernameAdds.setObject(getTimestampAsInt(), forKey: username as NSCopying)
          followeesMapping[username] = getTimestampAsInt()
          print("OKOK. USER ADDED: ", username)
      }
      else {
        followeeRequestsMapping[username] = getTimestampAsInt()
      }
    }
    
  func removedUser(_ username: String, isPrivate: Bool) {
      if !isPrivate {
          // When user is removed from tableview cell
          if recentUsernameAdds.object(forKey: username) != nil
          {
              recentUsernameAdds.removeObject(forKey: username)
          }
          
          followeesMapping.removeValue(forKey: username)
          
          print("OKOK. USER REMOVED: ", username)
      } else {
        followeeRequestsMapping.removeValue(forKey: username)
      }

    }
    
    fileprivate func addTableViewFooterSpinner() {
        let footerSpinner = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        footerSpinner.startAnimating()
        footerSpinner.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44)
        self.searchTableView.tableFooterView = footerSpinner
    }
    
    fileprivate func removeTableViewFooterSpinner() {
        self.searchTableView.tableFooterView = nil
    }
    
    fileprivate func resetCurrentSearchOffsets() {
        self.currentSearchBegin = 0
        self.currentSearchEnd = self.searchOffset
    }
  
}

extension SearchViewController {
  
  // MARK: - UITableViewDelegate
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    if (!shouldShowSearchResults) {
      return 160
    } else {
      // Default TableViewCell row height for showing search results
      return 61
    }
  }
  
  // MARK: - UICollectionViewDataSource
  // sections are not needed in Leaderboard CollectionViews
  /*
  func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    //return 2;
    return 1;
  }
  */
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {

    if metricLists.isEmpty || metricLists[collectionView.tag] == nil {
      return 0
    }
    
    return metricLists[collectionView.tag]!.count
    
//    switch collectionView.tag {
//    case leaderboardType.MOST_FOLLOWERS.rawValue:
//      return mostFollowersList.count
//    case leaderboardType.MOST_FOLLOWINGS.rawValue:
//      return mostFollowingList.count
//    default:
//      return 0
//    }
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "userCollectionViewCell", for: indexPath) as! UserCollectionViewCell
    
    let list = metricLists[collectionView.tag]!
    // Add label of the number of followers to the leaderboard user
    let followNumber = list[indexPath.item].1
    // If the leaderboard user has too many followers, simplify the representation string
    if (followNumber > 1000) {
      cell.followNumberLabel.text = String(followNumber / 1000) + " k"
    } else {
      cell.followNumberLabel.text = String(followNumber)
    }
    
    // add profile picture of the leaderboard user
    let leaderboardUsername = list[indexPath.item].0
    
    if (self.verifiedUserList[leaderboardUsername] == true) {
      addVerifiedIconToLabel(leaderboardUsername, label: cell.userNameLabel, size:10)
      
    } else {
      cell.userNameLabel.text = leaderboardUsername
    }
    
    if let profileImage = userProfileImages[leaderboardUsername] {
      cell.userProfileImage.image = profileImage
      
    }
    
//    switch collectionView.tag {
//    case leaderboardType.MOST_FOLLOWERS.rawValue:
//      // Add label of the number of followers to the leaderboard user
//      let followNumber = mostFollowersList[indexPath.item].1
//      // If the leaderboard user has too many followers, simplify the representation string
//      if (followNumber > 1000) {
//        cell.followNumberLabel.text = String(followNumber / 1000) + " k"
//      } else {
//        cell.followNumberLabel.text = String(followNumber)
//      }
//      
//      // add profile picture of the leaderboard user
//      let leaderboardUsername = mostFollowersList[indexPath.item].0
//      
//      if (self.verifiedUserList[leaderboardUsername] == true) {
//        addVerifiedIconToLabel(leaderboardUsername, label: cell.userNameLabel, size:10)
//
//      } else {
//        cell.userNameLabel.text = leaderboardUsername
//      }
//      
//      if let profileImage = userProfileImages[leaderboardUsername] {
//        cell.userProfileImage.image = profileImage
//
//      }
//      
//    case leaderboardType.MOST_FOLLOWINGS.rawValue:
//      let followNumber = mostFollowingList[indexPath.item].1
//      if (followNumber > 1000) {
//        cell.followNumberLabel.text = String(followNumber / 1000) + " k"
//      } else {
//        cell.followNumberLabel.text = String(followNumber)
//      }
//
//      let leaderboardUsername = mostFollowingList[indexPath.item].0
//      
//      if (self.verifiedUserList[leaderboardUsername] == true) {
//        addVerifiedIconToLabel(leaderboardUsername, label: cell.userNameLabel, size:10)
//        
//      } else {
//        cell.userNameLabel.text = leaderboardUsername
//      }
//      
//      if let profileImage = userProfileImages[leaderboardUsername] {
//        cell.userProfileImage.image = profileImage
//      }
//      
//    default:
//      break
//    }
    
    /*
    // Change the background color of one CollectionViewCell
    let view = UIView(frame: cell.bounds)
    view.backgroundColor = UIColor(colorLiteralRed: 0.278, green: 0.694, blue: 0.537, alpha: 1.00)
    cell.selectedBackgroundView = view
    */
    
    // Adjust user's profile image: to fit the frame and be circular
    //cell.userProfileImage.contentMode = UIViewContentMode.ScaleAspectFit
    cell.userProfileImage.contentMode = UIViewContentMode.scaleAspectFill
    cell.userProfileImage.layer.cornerRadius = cell.userProfileImage.frame.size.width / 2
    cell.userProfileImage.clipsToBounds = true
    //cell.userProfileImage.layer.borderWidth = 5.0
    cell.userProfileImage.layer.borderWidth = 2.0
    
    // try to select a color for each user profile image's border
    //cell.userProfileImage.layer.borderColor = UIColor.whiteColor().CGColor
    //cell.userProfileImage.layer.borderColor = generateRandomColor().CGColor
    cell.userProfileImage.layer.borderColor = UIColor.init(RGBInt: 0xFF6699).cgColor  // Pink for Aqualytics bar charts


    return cell
  }
  
  // MARK: - UICollectionViewDelegate
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    
    
    showPopupForUser(String(metricLists[collectionView.tag]![indexPath.row].0), me: userName)

    
//    // Show the user's popup profile if a leaderboard user is clicked
//    switch collectionView.tag {
//    case leaderboardType.MOST_FOLLOWERS.rawValue:
//      showPopupForUser(String(mostFollowersList[indexPath.row].0), me: userName)
//      
//    case leaderboardType.MOST_FOLLOWINGS.rawValue:
//      showPopupForUser(String(mostFollowingList[indexPath.row].0), me: userName)
//      
//    default:
//      return
//    }
    
    collectionView.deselectItem(at: indexPath, animated: true)
  }
  
  /*
   // MARK: - UserCollectionViewDelegate (self-designed protocol for custom class)
   func didClickUserProfile() {
     print ("TODO")
   }
   */
  
  fileprivate func fetchLeaderboardsMetricsMap() {
    let dynamoDB = AWSDynamoDB.default()
    let scanInput = AWSDynamoDBScanInput()
    scanInput?.tableName = "aquaint-leaderboards"
    scanInput?.limit = 200
    scanInput?.exclusiveStartKey = nil
    
    dynamoDB.scan(scanInput!).continue { (resultTask) -> AnyObject? in
      if resultTask.result != nil && resultTask.error == nil
      {
        print("DB QUERY SUCCESS:", resultTask.result)
        let results = resultTask.result as! AWSDynamoDBScanOutput
        
        for result in results.items! {
          let metricName = (result["metric"]?.s)! as String
          let indexString = (result["index"]?.n)! as String
          let index = Int(indexString)!
          self.leaderboardMetricsMap[index] = metricName
          
          self.retrieveLeaderboardDynamoDB(metricName)
        }
        
      } else {
        print(resultTask.error)
      }
      
      return nil
    }
  }
  
}
