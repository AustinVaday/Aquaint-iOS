//
//  SearchViewController.swift
//  
//
//  Created by Austin Vaday on 4/7/16.
//
//

import UIKit
import Firebase

class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var searchTableView: UITableView!
    
    var userName : String!
    var userId   : String!
    var firebaseRootRef : Firebase!
    var allUsers: Array<Connection>!
    var allUsersSentARequest : NSDictionary!
    var allUsersConnections : NSDictionary!
    
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    
    var defaultImage : UIImage!

    override func viewDidLoad(){
        
        allUsersSentARequest = NSDictionary()
        allUsersConnections = NSDictionary()
        
        
        userName = getCurrentUser()
        
        defaultImage = UIImage(imageLiteral: "Person Icon Black")

        
//        firebaseRootRef = Firebase(url: firebaseRootRefString)

        let firebaseUsersRef = Firebase(url: firebaseRootRefString + "Users/")
        let firebaseSentRequestsRef = Firebase(url: firebaseRootRefString + "SentRequests/" + userName)
        let firebaseConnectionsRef = Firebase(url: firebaseRootRefString + "Connections/" + userName)
        
        allUsers = Array<Connection>()
        
        
        // Used to determine pending buttons
        firebaseSentRequestsRef.observeEventType(FEventType.Value, withBlock: { (snapshot) -> Void in
            
                //Store a listing of all users that current user sent a connection request to. Used
                //to determine which kind of button to display to user (add button, delete button, pending button)
                if !(snapshot.value is NSNull)
                {
                    self.allUsersSentARequest = snapshot.value as! NSDictionary
                }
            
                self.searchTableView.reloadData()
            
            })
        
        // Used to determine delete buttons
        firebaseConnectionsRef.observeEventType(FEventType.Value, withBlock: { (snapshot) -> Void in
            
                if !(snapshot.value is NSNull)
                {
                    self.allUsersConnections = snapshot.value as! NSDictionary
                }
                self.searchTableView.reloadData()
            
            })
        
        firebaseUsersRef.observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) -> Void in
            
            let user = Connection()
            
            // Store respective user info (key is the username)
            user.userName = snapshot.key
            
            
            // Retrieve user's other info
            firebaseUsersRef.childByAppendingPath(user.userName).observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
                
                user.userFullName = snapshot.childSnapshotForPath("/fullName").value as! String
                let userImageBase64String = snapshot.childSnapshotForPath("/userImage").value as! String
                
                // Convert base 64 image to UIImage
                if (userImageBase64String == "none")
                {
                    user.userImage = self.defaultImage
                }
                else
                {
                    user.userImage = convertBase64ToImage(userImageBase64String)
                }
                
                self.allUsers.append(user)
                
                self.searchTableView.reloadData()
                
                print("RELOADED")
                
            })
            
        })

        
        

        
    }
    
    // **** SEARCH TABLE VIEW *****
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("searchCell", forIndexPath: indexPath) as! SearchTableViewCell
        
        let userFullName = allUsers[indexPath.item].userFullName
        let userName     = allUsers[indexPath.item].userName
        let userImage    = allUsers[indexPath.item].userImage
        
        
        // Do not let user add him/herself
        if (userName == self.userName)
        {
            cell.deactivateAllButtons()
        }
        else
        {
            // If already sent a request, display pending symbol
            if ((allUsersSentARequest[userName]) != nil && (allUsersConnections[userName]) == nil)
            {
                cell.deactivateAllButtons()
                cell.activatePendingButton()
            }
            // If already friends, display delete button
            else if ((allUsersConnections[userName]) != nil)
            {
                cell.deactivateAllButtons()
                cell.activateDeleteButton()
            }
            // If no relationship, show add button
            else
            {
                cell.deactivateAllButtons()
                cell.activateAddButton()
            }
            
        }
        cell.cellName.text = userFullName
        cell.cellUserName.text = userName
        cell.cellImage.image = userImage
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return allUsers.count
        
    }


}