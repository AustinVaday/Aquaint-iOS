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
    @IBOutlet weak var cellAddPendingButton: UIButton!
    @IBOutlet weak var cellDeleteButton: UIButton!
    @IBOutlet weak var cellUserName: UILabel!
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"


    func deactivateAllButtons()
    {
        // Deactivate the pending button
        cellAddButton.hidden  = true
        cellAddButton.userInteractionEnabled = false
        cellDeleteButton.hidden  = true
        cellDeleteButton.userInteractionEnabled = false
        cellAddPendingButton.hidden = true
        cellAddPendingButton.userInteractionEnabled = false
    }
    
    func activateAddButton()
    {
        // Activate the pending button
        cellAddButton.hidden  = false
        cellAddButton.userInteractionEnabled = true
        cellAddPendingButton.hidden  = true
        cellAddPendingButton.userInteractionEnabled = false
        cellDeleteButton.hidden = true
        cellDeleteButton.userInteractionEnabled = false
    }
    
    func activateDeleteButton()
    {
        cellDeleteButton.hidden  = false
        cellDeleteButton.userInteractionEnabled = true
        cellAddPendingButton.hidden  = true
        cellAddPendingButton.userInteractionEnabled = false
        cellAddButton.hidden = true
        cellAddButton.userInteractionEnabled = false
    }
    
    func activatePendingButton()
    {
        // Activate the pending button
        cellAddPendingButton.hidden  = false
        cellAddPendingButton.userInteractionEnabled = true
        cellAddButton.hidden  = true
        cellAddButton.userInteractionEnabled = false
        cellDeleteButton.hidden = true
        cellDeleteButton.userInteractionEnabled = false
    }

    @IBAction func onAddConnectionButtonClicked(sender: UIButton) {
        
        deactivateAllButtons()
        activatePendingButton()
        
        // Fetch current user from NSUserDefaults
        let currentUser = getCurrentUser()
        
        // If currentUser is not trying to add themselves
        if (currentUser != cellUserName.text)
        {
            let firebaseRootRef = Firebase(url: firebaseRootRefString)
            let firebaseSentRequestsRef = Firebase(url: firebaseRootRefString + "SentRequests/")
            let firebaseReceivedRequests = Firebase(url: firebaseRootRefString + "ReceivedRequests/")
            
            // We need to add a two-way relationship for each user.
//            let firebaseConnectionsRef = Firebase(url: firebaseRootRefString + "Connections/")
            
//            firebaseConnectionsRef.childByAppendingPath("currentUser/")
            
            let connectionUserToAdd = cellUserName.text!
            
            // Get time of connection
            let connectionTime = getTimestampAsInt()

            // User sends connection request to connectionUserToAdd. Storing relationship on server.
            firebaseSentRequestsRef.childByAppendingPath(currentUser + "/" + connectionUserToAdd).setValue(connectionTime)
            firebaseReceivedRequests.childByAppendingPath(connectionUserToAdd + "/" + currentUser).setValue(connectionTime)
            
            
//            // Add friend info to currentUser's database info
//            firebaseRootRef.childByAppendingPath("Connections/" + currentUser + "/" + connectionUserToAdd).setValue(connectionTime)
//            
//            // Add friend info to connectionUserToAdd's database info
//            firebaseRootRef.childByAppendingPath("Connections/" + connectionUserToAdd + "/" + currentUser).setValue(connectionTime)

        }
        
        print("You connected", currentUser ,"and", cellName.text)
    }
    
    
}
