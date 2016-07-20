//
//  SearchViewController.swift
//  
//
//  Created by Austin Vaday on 4/7/16.
//
//

import UIKit
import AWSDynamoDB

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating, UISearchBarDelegate {

    @IBOutlet weak var searchTableView: UITableView!
    
    var searchController: UISearchController!
    
    var userName : String!
    var userId   : String!
    var allUsers: Array<User>!
    var filteredUsers: Array<User>!
    var shouldShowSearchResults = false
    var defaultImage : UIImage!

    override func viewDidLoad(){
        
        allUsers = Array<User>()
        filteredUsers = Array<User>()
        
        configureSearchController()
        
        userName = getCurrentCachedUser()
        defaultImage = UIImage(imageLiteral: "Person Icon Black")
        
        
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

        
//        firebaseRootRef = FIRDatabase.database().reference()
//        
//        let firebaseUsersRef = firebaseRootRef.child("Users/")
//        let firebaseUserImagesRef = firebaseRootRef.child("UserImages/")
//        let firebaseSentRequestsRef = firebaseRootRef.child("SentRequests/" + userName)
//        let firebaseConnectionsRef = firebaseRootRef.child("Connections/" + userName)
//        
//        allUsers = Array<Connection>()
//        
//        
//        // Used to determine pending buttons
//        firebaseSentRequestsRef.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
//            
//                //Store a listing of all users that current user sent a connection request to. Used
//                //to determine which kind of button to display to user (add button, delete button, pending button)
//                if !(snapshot.value is NSNull)
//                {
//                    self.allUsersSentARequest = snapshot.value as! NSDictionary
//                }
//            
//                print("DETERMINES PENDING BUTTON")
//                self.searchTableView.reloadData()
//            
//            })
//        
//        // Used to determine delete buttons
//        firebaseConnectionsRef.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
//            
//                if !(snapshot.value is NSNull)
//                {
//                    self.allUsersConnections = snapshot.value as! NSDictionary
//                }
//                self.searchTableView.reloadData()
//            
//            })
//        
//        firebaseUsersRef.observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) -> Void in
//            
//            let user = Connection()
//            
//            // Store respective user info (key is the username)
//            user.userName = snapshot.key
//            
//            
//            // Retrieve user's info (except image)
//            firebaseUsersRef.child(user.userName).observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
//                
//                user.userFullName = snapshot.childSnapshotForPath("/fullName").value as! String
//                
//            })
//            
//            
//            // Store the user's image
//            firebaseUserImagesRef.child(user.userName).observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
//                
//                // Get base 64 string image
//                
//                // If user has an image, display it in table. Else, display default image
//                if (snapshot.exists())
//                {
//                    let userImageBase64String = snapshot.childSnapshotForPath("/profileImage").value as! String
//                    user.userImage = convertBase64ToImage(userImageBase64String)
//                }
//                else
//                {
//                    user.userImage = self.defaultImage
//                }
//                
//                self.searchTableView.reloadData()
//                
//            })
//            
//            
//            self.allUsers.append(user)
//            self.searchTableView.reloadData()
//
//            
//            
//        })
//
        
        

        
    }
    
    // **** SEARCHBAR PROTOCOLS *****
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        
        // Use filtered array
        shouldShowSearchResults = true
        searchTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        
        // Use default array
        shouldShowSearchResults = false
        searchTableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        
        // If not already showing results, begin showing them now
        if (!shouldShowSearchResults)
        {
            shouldShowSearchResults = true
            searchTableView.reloadData()
        }
        
        searchController.becomeFirstResponder()
    }
    
    // *** SEARCH RESULTS UPDATING PROTOCOL ****
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        
        let searchString = searchController.searchBar.text!
        
        
        filteredUsers = allUsers.filter({ (someUser) -> Bool in
        
            let userName = someUser.username as NSString
            let realName = someUser.realname as NSString
            
            // Check if we have a user with a corresponding exact substring (case insensitive)
            let userNameMatch = userName.rangeOfString(searchString, options: .CaseInsensitiveSearch).location != NSNotFound
            let realNameMatch = realName.rangeOfString(searchString, options: .CaseInsensitiveSearch).location != NSNotFound

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
            
//            // If already sent a request, display pending symbol
//            if ((allUsersSentARequest[userName]) != nil && (allUsersConnections[userName]) == nil)
//            {
//                cell.activatePendingButton()
//            }
//            // If already friends, display delete button
//            else if ((allUsersConnections[userName]) != nil)
//            {
//                cell.activateDeleteButton()
//            }
//            // If no relationship, show add button
//            else
//            {
//                cell.activateAddButton()
//            }
            
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

    
    private func configureSearchController()
    {
        
        //When the nil value is passed as an argument, 
        // the search controller knows that the view controller that exists to
        // is also going to handle and display the search results.
        searchController = UISearchController(searchResultsController: nil)
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search here"
        searchController.searchBar.delegate = self
        searchController.searchBar.sizeToFit()
        searchTableView.tableHeaderView = searchController.searchBar
        
        
    }

}