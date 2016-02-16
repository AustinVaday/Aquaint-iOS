//
//  LogInController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/27/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//
//
//  Code is owned by: Austin Vaday and Navid Sarvian


import UIKit
import Parse
import Firebase

class LogInController: UIViewController {
        
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var checkMarkView: UIView!
    @IBOutlet weak var checkMarkFlipped: UIImageView!
    var checkMarkFlippedCopy: UIImageView!
    
    var firebaseRootRef: Firebase!
    
    @IBOutlet weak var emblem: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var logInButton: UIButton!
    
    // Counts how many times the user has incorrectly logged in.
    /* var wrongLogInCount: Int = 0 */
    
    override func viewDidLoad() {
        
        // Create a reference to firebase location
        firebaseRootRef = Firebase(url: "https://torrid-fire-8382.firebaseio.com/?page=Auth")
        
        
        self.checkMark.hidden = true
        self.checkMarkFlipped.hidden = true
        self.emblem.hidden = false
        
        checkMarkFlippedCopy = UIImageView(image: checkMark.image)
        
        flipImageHorizontally(checkMarkFlippedCopy)
    }
    
    @IBAction func emailEditingDidEnd(sender: UITextField) {
        let userEmailString:String = userEmail.text!
        
        if (userEmailString.isEmpty)
        {
            print("Empty email string")
        }
        else if(verifyEmailFormat(userEmailString))
        {
            print("PROPER EMAIL")
        }
        else
        {
            //TODO: make email field red.
            print("IMPROPER EMAIL")
        }
        
        
    }
    
    @IBAction func passwordEditingDidEnd(sender: UITextField) {
        
        let userPasswordString:String = userPassword.text!
        
        if (userPasswordString.isEmpty)
        {
            print("Empty password string")
        }
        else if (verifyPasswordFormat(userPasswordString))
        {
            print("PROPER PASSWORD")
        }
        else
        {
            //TODO: make password field red
            print("Please have at least 4 characters")
        }
    }

    // When user clicks "Next" on keyboard
    @IBAction func emailEditingDidEndOnExit(sender: UITextField) {
        userPassword.becomeFirstResponder()
    }
    
    // When user clicks "Go" on keyboard
    @IBAction func passwordEditingDidEndOnExit(sender: UITextField) {
        // Mimic clicking the log in button
        loginButtonClicked(logInButton.self)
    }
    @IBAction func loginButtonClicked(sender: UIButton) {
        
        // Disable log in button so that user can only send one request at a time
        logInButton.enabled = false
        
        // Show activity indicator (spinner)
        spinner.startAnimating()
        
        let userEmailString:String = userEmail.text!
        let userPasswordString:String =  userPassword.text!
        
        // Perform long-running operation on background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            

                self.spinner.startAnimating()
            
                self.firebaseRootRef.authUser(userEmailString, password: userPasswordString, withCompletionBlock:
                    { error, authData in

                        // If success log in
                        if (error == nil)
                        {
                            // Perform update on UI on main thread
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                                // Stop showing activity indicator (spinner)
                                self.checkMarkFlipped.hidden = false
                                
                                self.emblem.hidden = true
                                self.spinner.stopAnimating()
                                
                                
                                UIView.transitionWithView(self.checkMarkView, duration: 1, options: UIViewAnimationOptions.TransitionFlipFromLeft, animations: { () -> Void in
                                    
                                    print("HI")
                                    self.checkMarkFlipped.hidden = false
                                    
                                    self.checkMarkFlipped.image = self.checkMark.image
                                    
                                    }, completion: nil)
                                
                                
                                print("User logged in!")
                                
                                delay(1.5)
                                    {
                                        
                                        self.performSegueWithIdentifier("HomeViewController", sender: nil)
                                        
                                }
                                
                                self.checkMarkFlipped.image = self.checkMarkFlippedCopy.image
                                // Reset checkMarkFlipped back to flipped image
                                //                     self.checkMarkFlipped.image = tempImageFlipped
                                //                    flipImageHorizontally(self.checkMarkFlipped)
                                
                                //                    self.checkMark.hidden = true
                                //                    self.checkMarkFlipped.hidden = true
                                
                                
                                
                            })

                        }
                        else // If not success log in
                        {
                            // Perform update on UI on main thread
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                                /*
                                self.wrongLogInCount++
                                
                                // If user logs in incorrectly more than three times, give them a chance to change password...
                                if (self.wrongLogInCount > 3)
                                {
                                
                                }
                                */
                                
                                // Create alert to send to user
                                let alert = UIAlertController(title: "Please try again...", message: "The email and password do not match.", preferredStyle: UIAlertControllerStyle.Alert)
                                
                                
                                // Create the action to add to alert
                                let alertAction = UIAlertAction(title: "Try again", style: UIAlertActionStyle.Default, handler: nil)
                                
                                // Add the action to the alert
                                alert.addAction(alertAction)
                                
                                // Stop showing activity indicator (spinner)
                                self.spinner.stopAnimating()
                                
                                
                                // Show the alert if it has not been showed already (we need this in case the user clicks many times -- quickly -- on the log-in button before it is disabled. This if statement prevents the display of multiple alerts).
                                
                                if (self.presentedViewController == nil)
                                {
                                    self.showViewController(alert, sender: nil)
                                    
                                }
                                
                                
                                print("LogIn Error")
                                
                            })
                            

                        }
                    
                })
                
                
//                try PFUser.logInWithUsername(userEmailString, password: userPasswordString)
            
            
            
        })
        

        // Enable the log-in button again
        logInButton.enabled = true
        
    }
}