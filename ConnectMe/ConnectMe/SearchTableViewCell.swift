//
//  TableViewCell.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/31/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
import Firebase

class SearchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellName: UILabel!
    @IBOutlet weak var cellAddButton: UIButton!
    @IBOutlet weak var cellUserName: UILabel!
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    var firebaseRootRef : Firebase!
    
    
    
    @IBAction func onAddConnectionButtonClicked(sender: UIButton) {
        
        // Fetch current user from NSUserDefaults
        let currentUser = getCurrentUser()
        
        
        // If currentUser is not trying to add themselves
        if (currentUser != cellUserName.text)
        {
            firebaseRootRef = Firebase(url: firebaseRootRefString)
            
            // We need to add a two-way relationship for each user.
//            let firebaseConnectionsRef = Firebase(url: firebaseRootRefString + "Connections/")
            
//            firebaseConnectionsRef.childByAppendingPath("currentUser/")
            
            let connectionUserToAdd = cellUserName.text!
            
            // Get time of connection
            let connectionTime = getTimestampAsInt()

            // Add friend info to currentUser's database info
            firebaseRootRef.childByAppendingPath("Connections/" + currentUser + "/" + connectionUserToAdd).setValue(connectionTime)
            
            // Add friend info to connectionUserToAdd's database info
            firebaseRootRef.childByAppendingPath("Connections/" + connectionUserToAdd + "/" + currentUser).setValue(connectionTime)

        }
        
        print("You connected", currentUser ,"and", cellName.text)
    }
    
    
}
