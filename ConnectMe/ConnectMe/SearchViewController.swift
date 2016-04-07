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
    
    
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    


    override func viewDidLoad(){
        
//        userName = getCurrentUser()
        
//        firebaseRootRef = Firebase(url: firebaseRootRefString)

        let firebaseUsersRef = Firebase(url: firebaseRootRefString + "Users/")
        
        allUsers = Array<Connection>()
        
        firebaseUsersRef.observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) -> Void in
            
            print(snapshot.value)
            print("KEY IS: ", snapshot.key)
            
            let user = Connection()
            
            // Store respective user info (key is the username)
            user.userName = snapshot.key
            
            
            // Retrieve user's other info
            firebaseUsersRef.childByAppendingPath(user.userName).observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
                
                print(snapshot)
                user.userFullName = snapshot.childSnapshotForPath("/fullName").value as! String
                user.userImage    = snapshot.childSnapshotForPath("/userImage").value as! String
                
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
        
        cell.cellName.text = userFullName
        cell.cellUserName.text = userName
        
        return cell
        
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return allUsers.count
        
    }


}