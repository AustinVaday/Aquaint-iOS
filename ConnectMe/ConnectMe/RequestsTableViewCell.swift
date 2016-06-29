//
//  RequestsTableViewCell.swift
//  Aquaint
//
//  Created by Austin Vaday on 4/10/16.
//  Copyright © 2016 ConnectMe. All rights reserved.
//

import UIKit
import Firebase

class RequestsTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellName: UILabel!
    @IBOutlet weak var cellAddButton: UIButton!
    @IBOutlet weak var cellDeleteButton: UIButton!
    @IBOutlet weak var cellUserName: UILabel!
    
    var currentUser : String!
    var firebaseRootRef: FIRDatabaseReference!
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    
    @IBAction func onAddButtonClicked(sender: UIButton) {
        
        // Get your user name. Get your connection's user name
        let currentUser = getCurrentUser()
        let connectedUserToAdd = cellUserName.text!
        
        firebaseRootRef = FIRDatabase.database().reference()
        
        // Remove relationship in ReceivedRequests
        let firebaseReceivedRequestsRef = firebaseRootRef.child("ReceivedRequests/" + currentUser + "/" + connectedUserToAdd)
        
        firebaseReceivedRequestsRef.removeValueWithCompletionBlock { (error, ref) -> Void in
            if (error != nil)
            {
                // Do something
            }
        }
        
        
        // Remove relationship in SentRequests
        let firebaseSentRequestsRef = firebaseRootRef.child("SentRequests/" + connectedUserToAdd + "/" + currentUser)
        
        firebaseSentRequestsRef.removeValueWithCompletionBlock { (error, ref) -> Void in
            if (error != nil)
            {
                // Do something
            }
        }
        
        
        // Add relationship to Connections
        let firebaseConnectionsRef = firebaseRootRef.child("Connections/" )
        
        // Get time of connection
        let connectionTime = getTimestampAsInt()
        
        // Add friend info to currentUser's database info
        firebaseConnectionsRef.child(currentUser + "/" + connectedUserToAdd).setValue(connectionTime)

        // Add friend info to connectionUserToAdd's database info
        firebaseConnectionsRef.child(connectedUserToAdd + "/" + currentUser).setValue(connectionTime)
        
    }
    
    
    
    @IBAction func onDeleteButtonClicked(sender: UIButton) {
        
        
        // Get your user name. Get your connection's user name
        let currentUser = getCurrentUser()
        let connectedUserToAdd = cellUserName.text!
        
        
        // Remove relationship in ReceivedRequests
        let firebaseReceivedRequestsRef = firebaseRootRef.child("ReceivedRequests/" + currentUser + "/" + connectedUserToAdd)
        
        firebaseReceivedRequestsRef.removeValueWithCompletionBlock { (error, ref) -> Void in
            if (error != nil)
            {
                // Do something
            }
        }
        
        
        // Remove relationship in SentRequests
        let firebaseSentRequestsRef = firebaseRootRef.child("SentRequests/" + connectedUserToAdd + "/" + currentUser)
        
        firebaseSentRequestsRef.removeValueWithCompletionBlock { (error, ref) -> Void in
            if (error != nil)
            {
                // Do something
            }
        }
        
        // That's it
        
        
        
    }
}
