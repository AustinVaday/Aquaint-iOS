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
    var firebaseRootRef : FIRDatabaseReference!
    var allUsers: Array<Connection>!
    var allUsersSentARequest : NSDictionary!
    var allUsersConnections : NSDictionary!
    
    var defaultImage : UIImage!

    override func viewDidLoad(){
        
        allUsersSentARequest = NSDictionary()
        allUsersConnections = NSDictionary()
        
        
        userName = getCurrentUser()
        
        defaultImage = UIImage(imageLiteral: "Person Icon Black")

        
        firebaseRootRef = FIRDatabase.database().reference()
        
        let firebaseUsersRef = firebaseRootRef.child("Users/")
        let firebaseUserImagesRef = firebaseRootRef.child("UserImages/")
        let firebaseSentRequestsRef = firebaseRootRef.child("SentRequests/" + userName)
        let firebaseConnectionsRef = firebaseRootRef.child("Connections/" + userName)
        
        allUsers = Array<Connection>()
        
        
        // Used to determine pending buttons
        firebaseSentRequestsRef.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
            
                //Store a listing of all users that current user sent a connection request to. Used
                //to determine which kind of button to display to user (add button, delete button, pending button)
                if !(snapshot.value is NSNull)
                {
                    self.allUsersSentARequest = snapshot.value as! NSDictionary
                }
            
                print("DETERMINES PENDING BUTTON")
                self.searchTableView.reloadData()
            
            })
        
        // Used to determine delete buttons
        firebaseConnectionsRef.observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
            
                if !(snapshot.value is NSNull)
                {
                    self.allUsersConnections = snapshot.value as! NSDictionary
                }
                self.searchTableView.reloadData()
            
            })
        
        firebaseUsersRef.observeEventType(FIRDataEventType.ChildAdded, withBlock: { (snapshot) -> Void in
            
            let user = Connection()
            
            // Store respective user info (key is the username)
            user.userName = snapshot.key
            
            
            // Retrieve user's info (except image)
            firebaseUsersRef.child(user.userName).observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
                
                user.userFullName = snapshot.childSnapshotForPath("/fullName").value as! String
                
            })
            
            
            // Store the user's image
            firebaseUserImagesRef.child(user.userName).observeSingleEventOfType(FIRDataEventType.Value, withBlock: { (snapshot) -> Void in
                
                // Get base 64 string image
                
                // If user has an image, display it in table. Else, display default image
                if (snapshot.exists())
                {
                    let userImageBase64String = snapshot.childSnapshotForPath("/profileImage").value as! String
                    user.userImage = convertBase64ToImage(userImageBase64String)
                }
                else
                {
                    user.userImage = self.defaultImage
                }
                
                self.searchTableView.reloadData()
                
            })
            
            
            self.allUsers.append(user)
            self.searchTableView.reloadData()

            
            
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
            print("HIDING ALL BUTTONS FOR: ", self.userName)
            cell.hideAllButtons()
        }
        else
        {
            cell.unHideAllButtons()
            
            // If already sent a request, display pending symbol
            if ((allUsersSentARequest[userName]) != nil && (allUsersConnections[userName]) == nil)
            {
                cell.activatePendingButton()
            }
            // If already friends, display delete button
            else if ((allUsersConnections[userName]) != nil)
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
        cell.cellImage.image = userImage
        
        
        // Ensure that internal cellImage is circular
        cell.cellImage.layer.cornerRadius = cell.cellImage.frame.size.width / 2
        
//        // Create a nice border for the cellImage
//        cell.cellImage.layer.borderWidth = 0.5
//        cell.cellImage.layer.borderColor = UIColor.blackColor().CGColor
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return allUsers.count
        
    }


}