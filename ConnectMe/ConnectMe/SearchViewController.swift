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

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, CustomSearchControllerDelegate, SearchTableViewCellDelegate {

    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var noSearchResultsView: UIView!
    @IBOutlet weak var searchResultsInfoLabel: UILabel!
    
    var searchController: UISearchController!
    var customSearchController: CustomSearchController!
    var userName : String!
    var userId   : String!
    var allUsers: Array<User>!
    var filteredUsers: Array<User>!
    var shouldShowSearchResults = false
    var isTypingSearch = false
    var defaultImage : UIImage!
    var followeesMapping : [String: Int]!
    var recentUsernameAdds : NSMutableDictionary!
    var animatedObjects : Array<UIView>!
    let imageCache = NSCache()
    

    override func viewDidLoad(){
        
        
        allUsers = Array<User>()
        filteredUsers = Array<User>()
        followeesMapping = [String: Int]()
        recentUsernameAdds = NSMutableDictionary()
        animatedObjects = Array<UIView>()
        
        noSearchResultsView.hidden = true
        
        configureCustomSearchController()
        
        userName = getCurrentCachedUser()
        defaultImage = UIImage(imageLiteral: "Person Icon Black")
        
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        let parameters = ["action":"getFolloweesDict", "target": userName]
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
                
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.searchTableView.reloadData()
                })
            }
            else
            {
                print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                
            }
            
            return nil
            
        }

        
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let scanExpression = AWSDynamoDBScanExpression()
        scanExpression.limit = 100
        
        dynamoDBObjectMapper.scan(User.self, expression: scanExpression) { (paginatedOutput, error) in
            
            if (error != nil)
            {
                print ("ERROR getting all users in search controller, ", error)
            }
            else
            {
                // Store all users locally
                for object in (paginatedOutput?.items)!
                {
                    let someUser = object as! User
                    
                    self.allUsers.append(someUser)
                    
                }
                
                // Update UI on main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.searchTableView.reloadData()
                })

            
            }
        }

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

            // Get a consistent timestamp
            let currentTimestamp = getTimestampAsInt()
            
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
                
                // Upload to Dynamo
            
                
                let otherUsersArray = self.recentUsernameAdds.allKeys as NSArray
                let newsfeedObject = NSMutableDictionary(dictionary: ["event": "newfollowing", "other": otherUsersArray, "time" : currentTimestamp] )
                newsfeedObjectMapper.addNewsfeedObject(newsfeedObject)
                
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
                    let newsfeedObject = NSMutableDictionary(dictionary: ["event": "newfollower", "other":  otherUsersArray, "time" : currentTimestamp] )
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
    
    // **** SEARCHBAR PROTOCOLS (CUSTOM SEARCH BAR) *****
    func didStartSearching() {
        // Use filtered array
        shouldShowSearchResults = true
        searchTableView.reloadData()
    }
    
    func didTapOnCancelButton() {
        // Use default array
        shouldShowSearchResults = false
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
        
        if searchText.isEmpty
        {
            isTypingSearch = false
        }
        else
        {
            isTypingSearch = true
        }
        
        filteredUsers = allUsers.filter({ (someUser) -> Bool in
            
            let userName = someUser.username as NSString
            let realName = someUser.realname as NSString
            
            // Check if we have a user with a corresponding exact substring (case insensitive)
            let userNameMatch = userName.rangeOfString(searchText, options: .CaseInsensitiveSearch).location != NSNotFound
            let realNameMatch = realName.rangeOfString(searchText, options: .CaseInsensitiveSearch).location != NSNotFound
            
            // If we have either a user name or real name match, add the user to the filtered array!
            return userNameMatch || realNameMatch
        })
        
        
        // Reload table view with new results
        searchTableView.reloadData()

    }
    
    // **** SEARCH TABLE VIEW *****
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("searchCell", forIndexPath: indexPath) as! SearchTableViewCell
        
        
        var userFullName : String!
        var userName : String!
        var userImage : UIImage!
        
        // Get applicable user from applicable array
        if (shouldShowSearchResults)
        {
            userFullName = filteredUsers[indexPath.item].realname
            userName     = filteredUsers[indexPath.item].username
        }
        else
        {
            userFullName = allUsers[indexPath.item].realname
            userName     = allUsers[indexPath.item].username
        }
        

        let image = imageCache.objectForKey(userName) as? UIImage
        
        if image != nil
        {
            cell.cellImage.image = image!
            print("USING CACHED IMAGE!")
        }
        else
        {
            getUserS3Image(userName, completion: { (result, error) in
                    
                // If no image, use default image
                if (error != nil)
                {
                    userImage = self.defaultImage

                }
                else if (result != nil)
                {
                    userImage = result
                }
                
                cell.cellImage.image = userImage
                
                // Cache user image so we don't have to reload it next time
                self.imageCache.setObject(userImage, forKey: userName)

            })
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
        
        if (shouldShowSearchResults)
        {
            // If user is searching, show applicable search results.
            // If no users, show animation indicating no result
            
            if filteredUsers.count == 0
            {
                setUpAnimations(self)
                noSearchResultsView.hidden = false
                
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
                noSearchResultsView.hidden = true
                searchResultsInfoLabel.hidden = true

            }
            
            return filteredUsers.count
        }
        else
        {
            
            clearUpAnimations()
            noSearchResultsView.hidden = true

            // If user is not searching, show all users
            return allUsers.count
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
        
        customSearchController.customSearchBar.placeholder = "Search for friends"
        
        
        customSearchController.customDelegate = self
        
        searchTableView.tableHeaderView = customSearchController.customSearchBar
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
    func addedUser(username: String) {
        // When user is added from tableview cell
        // Add to set to keep track of recently added users
        recentUsernameAdds.setObject(getTimestampAsInt(), forKey: username)
        followeesMapping[username] = getTimestampAsInt()
        print("OKOK. USER ADDED: ", username)
    }
    
    func removedUser(username: String) {
        // When user is removed from tableview cell
        if recentUsernameAdds.objectForKey(username) != nil
        {
            recentUsernameAdds.removeObjectForKey(username)
        }
        
        followeesMapping.removeValueForKey(username)
        
        print("OKOK. USER REMOVED: ", username)

    }
}