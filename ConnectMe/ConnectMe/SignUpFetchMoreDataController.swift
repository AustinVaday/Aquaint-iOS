//
//  SignUpFetchMoreDataController.swift
//  
//
//  Created by Austin Vaday on 7/3/16.
//
//

import UIKit
import AWSCognitoIdentityProvider

class SignUpFetchMoreDataController: UIViewController {
    

    @IBOutlet weak var realNameField: UITextField!
    @IBOutlet weak var realNameButton: UIButton!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var checkMarkFlipped: UIImageView!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var checkMarkView: UIView!
    
    var pool : AWSCognitoIdentityUserPool!
    var checkMarkFlippedCopy: UIImageView!
    var userPassword : String!
    
    let segueDestination = "toMainContainerViewController"
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // get the IDENTITY POOL
        pool = getAWSCognitoIdentityUserPool()

        // Set up animation
        self.checkMark.hidden = true
        self.checkMarkFlipped.hidden = true
        checkMarkFlippedCopy = UIImageView(image: checkMark.image)
        flipImageHorizontally(checkMarkFlippedCopy)
        
    }
    
    
    // // When user clicks "Go" on keyboard
    @IBAction func onTextFieldDidEndOnExit(sender: AnyObject) {
        // Mimic the "Sign Up" button being pressed
        self.onFinishButtonClicked(realNameButton.self)
    }
    
    @IBAction func onFinishButtonClicked(sender: UIButton) {
        
        let realNameString:String = realNameField.text!
        
        /*********************************************************************
         * ALERTS - send alert and leave if user enters in improper input
         **********************************************************************/
        if (realNameString.isEmpty)
        {
            showAlert("Empty field", message: "Please enter in your name!", buttonTitle: "Try again", sender: self)
            return
        }
        
        if (!verifyRealNameLength(realNameString))
        {
            showAlert("Name too long", message: "Please try a shorter name!", buttonTitle: "Try again", sender: self)
            return
        }
        
//        if (!verifyRealNameFormat(realNameString))
//        {
//            showAlert("Improper name format", message: "The name format you entered is invalid. Please try again.", buttonTitle: "Try again", sender: self)
//            return
//        }
        
        // Disable button so that user can only send one request at a time
        //        verifyButton.enabled = false
        
        // Show activity indicator (spinner)
        spinner.startAnimating()
        
        let currentUser = getCurrentUser()
        print("Current user signed in: ", currentUser)
        print("And password is: ", userPassword)
        
        
        // Attempt to log user in
        pool.getUser(currentUser).getSession(currentUser, password: self.userPassword, validationData: nil, scopes: nil).continueWithBlock({ (sessionResultTask) -> AnyObject? in
            
            // If success login
            if sessionResultTask.error == nil
            {
                
                // Now update the user's info
                let name = AWSCognitoIdentityUserAttributeType()
                name.name = "name"
                name.value = realNameString
                
                self.pool.getUser(currentUser).updateAttributes([name]).continueWithBlock { (resultTask) -> AnyObject? in
                    
                    print("RESULT TASK UPDATE: ", resultTask)
                    print("RESULT TASK ERROR: ", resultTask.error)
                    
                    // If success code
                    if resultTask.error == nil
                    {
                        print("NAME UPDATE SUCCESSFUL")
                        
                        // Perform update on UI on main thread
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            // Stop showing activity indicator (spinner)
                            self.spinner.stopAnimating()
                            self.checkMarkFlipped.hidden = false
                            
                            UIView.transitionWithView(self.checkMarkView, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: { () -> Void in
                                
                                self.checkMarkFlipped.hidden = false
                                self.checkMarkFlipped.image = self.checkMark.image
                                
                                }, completion: nil)
                            
                            
                            delay(1.5)
                            {
                                
                                self.performSegueWithIdentifier(self.segueDestination, sender: nil)
                                
                            }
                            
                            self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image
                        })

                        
                    }
                    else // If fail code
                    {
                        
                        // Perform update on UI on main thread
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            
                            self.spinner.stopAnimating()
                            
                            showAlert("Error", message: "Could not update your name. Please contact admin@aquaint.io for further assistance.", buttonTitle: "Try again", sender: self)
                        })
                        
                    }
                    
                    return nil
                }
            }
            else // If fail login
            {
                // Perform update on UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.spinner.stopAnimating()
                    
                    showAlert("Error", message: "Name update successful, but could not log you in at this time. Please try again.", buttonTitle: "Try again", sender: self)
                })
            }
            
            return nil
        })

        
        
        
        
        
        
        
    }
    
}
