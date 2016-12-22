//
//  TableViewCell.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/31/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//  Code is owned by: Austin Vaday and Navid Sarvian

import UIKit
import AWSLambda
import FRHyperLabel

protocol SearchTableViewCellDelegate
{
    func addedUser(username: String)
    func removedUser(username: String)
}

class SearchTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellName: FRHyperLabel!
    @IBOutlet weak var cellAddButton: UIButton!
//    @IBOutlet weak var cellAddPendingButton: UIButton!
    @IBOutlet weak var cellDeleteButton: UIButton!
    @IBOutlet weak var cellUserName: UILabel!
    
    var searchDelegate : SearchTableViewCellDelegate?

    // Set default FRHyperLabel for this app. Set it here so that we
    // do not have to set it later (if not, user might see default hyperlink while this is loading)
    override func awakeFromNib() {
      // UI Color for #0F7A9D (www.uicolor.xyz)
      cellName.numberOfLines = 0
      
      let aquaBlue = UIColor(red:0.06, green:0.48, blue:0.62, alpha:1.0)
      let attributes = [NSForegroundColorAttributeName: aquaBlue,
                        NSFontAttributeName: UIFont.boldSystemFontOfSize(cellName.font.pointSize)]
      cellName.linkAttributeDefault = attributes
      
    }
  
    func hideAllButtons()
    {
        // Deactivate the pending button
        cellAddButton.hidden  = true
        cellDeleteButton.hidden  = true
//        cellAddPendingButton.hidden = true
    }
    
    func unHideAllButtons()
    {
        // Deactivate the pending button
        cellAddButton.hidden  = false
        cellDeleteButton.hidden  = false
//        cellAddPendingButton.hidden = false
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
    
//    func activatePendingButton()
//    {
//        // Activate the pending button
//        cellAddPendingButton.superview?.bringSubviewToFront(cellAddPendingButton)
//
//    }

    @IBAction func onAddConnectionButtonClicked(sender: UIButton) {
        
        // Fetch current user from NSUserDefaults
        let currentUserName = getCurrentCachedUser()
        
        // If currentUser is not trying to add themselves
        if (currentUserName != cellUserName.text!)
        {
            // Call lambda to store user connectons in database!
            let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
            let parameters = ["action": "follow", "target": cellUserName.text!, "me": currentUserName]
            
            lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock({ (resultTask) -> AnyObject? in
                
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
                    // Perform update on UI on main thread
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.activateDeleteButton()
                    })
                    
                    self.searchDelegate?.addedUser(self.cellUserName.text!)

                }
                else
                {
                    print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                    
                }
                
                return nil

            })
            
        }
        
        print("You connected", currentUserName ,"and", cellName.text)
    }
    
//    // Undo friend add request
//    @IBAction func onAddPendingButtonClicked(sender: UIButton) {
//        
//        print("PENDING CLICKED")
//        
//        // Fetch current user from NSUserDefaults
//        let currentUser = getCurrentCachedUser()
//        
//        // If currentUser is not trying to add themselves
//        if (currentUser != cellUserName.text)
//        {
//            let firebaseSentRequestsRef = firebaseRootRef.child("SentRequests/")
//            let firebaseReceivedRequests = firebaseRootRef.child("ReceivedRequests/")
//            
//            let connectionUserToRemove = cellUserName.text!
//            
//            // User sends connection request to connectionUserToAdd. Storing relationship on server.
//            firebaseSentRequestsRef.child(currentUser + "/" + connectionUserToRemove).removeValue()
//            firebaseReceivedRequests.child(connectionUserToRemove + "/" + currentUser).removeValue()
//            
//            activateAddButton()
//        }
//        
//        
//    }

    @IBAction func onRemoveButtonClicked(sender: UIButton) {
        
        // Fetch current user from NSUserDefaults
        let currentUserName = getCurrentCachedUser()
        
        // If currentUser is not trying to add themselves
        if (currentUserName != cellUserName.text!)
        {
            // Call lambda to store user connectons in database!
            let lambdaInvoker = AWSLambdaInvoker.defaultLambdaInvoker()
            let parameters = ["action": "unfollow", "target": cellUserName.text!, "me": currentUserName]
            
            lambdaInvoker.invokeFunction("mock_api", JSONObject: parameters).continueWithBlock({ (resultTask) -> AnyObject? in
                
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
                    // Perform update on UI on main thread
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.activateAddButton()
                    })
                    
                    self.searchDelegate?.removedUser(self.cellUserName.text!)

                    
                }
                else
                {
                    print("FAILED TO INVOKE LAMBDA FUNCTION -- result is NIL!")
                    
                }
                
                return nil
                
            })
            
        }
        
        print("You connected", currentUserName ,"and", cellName.text)

    }
    
}
