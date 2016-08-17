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

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, CustomSearchControllerDelegate {

    @IBOutlet weak var searchTableView: UITableView!
    
    var searchController: UISearchController!
    var customSearchController: CustomSearchController!
    var userName : String!
    var userId   : String!
    var allUsers: Array<User>!
    var filteredUsers: Array<User>!
    var shouldShowSearchResults = false
    var defaultImage : UIImage!
    var followeesMapping : [String: Int]!
    var recentUsernameAdds : Set<String>!
    

    override func viewDidLoad(){
        
        allUsers = Array<User>()
        filteredUsers = Array<User>()
        followeesMapping = [String: Int]()
        recentUsernameAdds = Set<String>!
        
//        configureSearchController()
        configureCustomSearchController()
        
        userName = getCurrentCachedUser()
        defaultImage = UIImage(imageLiteral: "Person Icon Black")
        
        let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
        let parameters = ["action":"getFollowees", "target": userName]
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
        
        let dynamoDBObjectMapper = AWSDynamoDBObjectMapper.defaultDynamoDBObjectMapper()
        let newsfeedObjectMapper = NewsfeedObjectModel()
        newsfeedObjectMapper.username = "myUserNameA"
        let newsfeedObject = NSMutableDictionary(dictionary: ["event": "eventA", "otheruser": "otheruserA", "timestamp" : getTimestampAsInt()] )
        newsfeedObjectMapper.addNewsfeedObject(newsfeedObject)
        
        dynamoDBObjectMapper.save(newsfeedObjectMapper).continueWithSuccessBlock { (resultTask) -> AnyObject? in
            print("DynamoObjectMapper sucessful save for newsfeedObject")
            
            return nil
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
    
    
//    // **** SEARCHBAR PROTOCOLS (DEFAULT SEARCH BAR) ***** 
//    // **** NOT CURRENTLY USED ****
//    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
//        
//        // Use filtered array
//        shouldShowSearchResults = true
//        searchTableView.reloadData()
//    }
//    
//    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        
//        // Use default array
//        shouldShowSearchResults = false
//        searchTableView.reloadData()
//    }
//    
//    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        
//        // If not already showing results, begin showing them now
//        if (!shouldShowSearchResults)
//        {
//            shouldShowSearchResults = true
//            searchTableView.reloadData()
//        }
//        
//        searchController.becomeFirstResponder()
//    }
//    
//    // *** SEARCH RESULTS UPDATING PROTOCOL ****
//    func updateSearchResultsForSearchController(searchController: UISearchController) {
//        
//        let searchString = searchController.searchBar.text!
//        
//        
//        filteredUsers = allUsers.filter({ (someUser) -> Bool in
//        
//            let userName = someUser.username as NSString
//            let realName = someUser.realname as NSString
//            
//            // Check if we have a user with a corresponding exact substring (case insensitive)
//            let userNameMatch = userName.rangeOfString(searchString, options: .CaseInsensitiveSearch).location != NSNotFound
//            let realNameMatch = realName.rangeOfString(searchString, options: .CaseInsensitiveSearch).location != NSNotFound
//
//            // If we have either a user name or real name match, add the user to the filtered array!
//            return userNameMatch || realNameMatch
//        })
//        
//        
//        // Reload table view with new results
//        searchTableView.reloadData()
//    }
//    
    
    
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

            
        })
        
        
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
        
//        // Create a nice border for the cellImage
//        cell.cellImage.layer.borderWidth = 0.5
//        cell.cellImage.layer.borderColor = UIColor.blackColor().CGColor
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if (shouldShowSearchResults)
        {
            // If user is searching, show applicable search results
            return filteredUsers.count
        }
        else
        {
            // If user is not searching, show all users
            return allUsers.count
        }
        
    }

    
    // If you want default (ugly) iOS search bar
    private func configureSearchController()
    {
        
        //When the nil value is passed as an argument, 
        // the search controller knows that the view controller that exists to
        // is also going to handle and display the search results.
//        searchController = UISearchController(searchResultsController: nil)
//        searchController.dimsBackgroundDuringPresentation = false
//        searchController.searchResultsUpdater = self
//        searchController.searchBar.placeholder = "Search here"
//        searchController.searchBar.delegate = self
//        searchController.searchBar.sizeToFit()
//        searchTableView.tableHeaderView = searchController.searchBar
        
        
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

}