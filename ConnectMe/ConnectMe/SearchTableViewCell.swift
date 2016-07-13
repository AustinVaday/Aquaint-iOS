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
    let firebaseRootRef = FIRDatabase.database().reference()

    func hideAllButtons()
    {
        // Deactivate the pending button
        cellAddButton.hidden  = true
        cellDeleteButton.hidden  = true
        cellAddPendingButton.hidden = true
    }
    
    func unHideAllButtons()
    {
        // Deactivate the pending button
        cellAddButton.hidden  = false
        cellDeleteButton.hidden  = false
        cellAddPendingButton.hidden = false
    }
    
    func activateAddButton()
    {
        // Activate the pending button
//        cellAddButton.hidden  = false
//        cellAddButton.userInteractionEnabled = true
//        cellAddPendingButton.hidden  = true
//        cellAddPendingButton.userInteractionEnabled = false
//        cellDeleteButton.hidden = true
//        cellDeleteButton.userInteractionEnabled = false
        
        cellAddButton.superview?.bringSubviewToFront(cellAddButton)
        
    }
    
    func activateDeleteButton()
    {
        
        cellDeleteButton.superview?.bringSubviewToFront(cellDeleteButton)

    }
    
    func activatePendingButton()
    {
        // Activate the pending button
        cellAddPendingButton.superview?.bringSubviewToFront(cellAddPendingButton)

    }

    @IBAction func onAddConnectionButtonClicked(sender: UIButton) {
        
        // Fetch current user from NSUserDefaults
        let currentUser = getCurrentCachedUser()
        
        // If currentUser is not trying to add themselves
        if (currentUser != cellUserName.text)
        {
            let firebaseSentRequestsRef = firebaseRootRef.child("SentRequests/")
            let firebaseReceivedRequests = firebaseRootRef.child("ReceivedRequests/")

            let connectionUserToAdd = cellUserName.text!
            
            // Get time of connection
            let connectionTime = getTimestampAsInt()

            // User sends connection request to connectionUserToAdd. Storing relationship on server.
            firebaseSentRequestsRef.child(currentUser + "/" + connectionUserToAdd).setValue(connectionTime)
            firebaseReceivedRequests.child(connectionUserToAdd + "/" + currentUser).setValue(connectionTime)
            
            activatePendingButton()

        }
        
        print("You connected", currentUser ,"and", cellName.text)
    }
    
    // Undo friend add request
    @IBAction func onAddPendingButtonClicked(sender: UIButton) {
        
        print("PENDING CLICKED")
        
        // Fetch current user from NSUserDefaults
        let currentUser = getCurrentCachedUser()
        
        // If currentUser is not trying to add themselves
        if (currentUser != cellUserName.text)
        {
            let firebaseSentRequestsRef = firebaseRootRef.child("SentRequests/")
            let firebaseReceivedRequests = firebaseRootRef.child("ReceivedRequests/")
            
            let connectionUserToRemove = cellUserName.text!
            
            // User sends connection request to connectionUserToAdd. Storing relationship on server.
            firebaseSentRequestsRef.child(currentUser + "/" + connectionUserToRemove).removeValue()
            firebaseReceivedRequests.child(connectionUserToRemove + "/" + currentUser).removeValue()
            
            activateAddButton()
        }
        
        
    }
    
    @IBAction func onRemoveButtonClicked(sender: UIButton) {
        
        print("REMOVE CLICKED")
        
        // Fetch current user from NSUserDefaults
        let currentUser = getCurrentCachedUser()
        
        // If currentUser is not trying to add themselves
        if (currentUser != cellUserName.text)
        {
            
            let connectionUserToRemove = cellUserName.text!
            
            let firebaseConnectionsRef = firebaseRootRef.child("Connections/")
            
            // Deletes friendship
            firebaseConnectionsRef.child(connectionUserToRemove + "/" + currentUser).removeValue()
            firebaseConnectionsRef.child(currentUser + "/" + connectionUserToRemove).removeValue()
            
            activateAddButton()
        }

    }
    
}
