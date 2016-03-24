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
import Firebase

class LogInController: UIViewController {
        
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var checkMarkView: UIView!
    @IBOutlet weak var checkMarkFlipped: UIImageView!
    
    @IBOutlet weak var emblem: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var logInButton: UIButton!
    
    var checkMarkFlippedCopy: UIImageView!
    var firebaseRootRef: Firebase!
    
    let segueDestination = "toMainPageViewController"
    let firebaseRootRefString = "https://torrid-fire-8382.firebaseio.com/"
    
    // Counts how many times the user has incorrectly logged in.
    /* var wrongLogInCount: Int = 0 */
    
    override func viewDidLoad() {
        
        // Create a reference to firebase location
        firebaseRootRef = Firebase(url: firebaseRootRefString)
        
        // Log out of of firebase if already logged in
        firebaseRootRef.unauth()
        
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
                            
                            let userId = authData.uid
                            var userName: String!
                            print("User logged in: ", userId)
   
                            
                            let firebaseUserIdToUserNameRef = self.firebaseRootRef.childByAppendingPath("UserIdToUserName/" + userId)
                
                            // Fetch respective username from this id
                            firebaseUserIdToUserNameRef.observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
                                print ("prior to snapshot")
                
                                // Means we have an error, display error..
                                if (snapshot.value.isKindOfClass(NSNull))
                                {
                                    
                                    // Obtain username and cache the user name for future use!
                                    let defaults = NSUserDefaults.standardUserDefaults()
                                    defaults.setObject("[error]:undefined_user_name", forKey: "username")
     
                                    // Show the alert if it has not been showed already (we need this in case the user clicks many times -- quickly -- on the log-in button before it is disabled. This if statement prevents the display of multiple alerts).
                                    if (self.presentedViewController == nil)
                                    {
                                        showAlert("Sorry", message: "We could not log you in at this time, please try again.", buttonTitle: "Try again", sender: self)
                                    }

                                    
                                    self.spinner.stopAnimating()
                                    
                                    self.firebaseRootRef.unauth()

                                    return
                                    
                                    
                                }
                                else
                                {
                                    userName = snapshot.value as! String
                    
                                    print ("after snapshot")
                                    
                                    print("User logged in has username: ", userName)
                                    
                                    // Obtain username and cache the user name for future use!
                                    let defaults = NSUserDefaults.standardUserDefaults()
                                    defaults.setObject(userName, forKey: "username")
                                }

                                
                            
                            // Perform update on UI on main thread
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                                // Stop showing activity indicator (spinner)
                                self.checkMarkFlipped.hidden = false
                                
                                self.emblem.hidden = true
                                self.spinner.stopAnimating()
                                
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
                            
                            })

                        }
                        else // If not success log in
                        {
                            // Perform update on UI on main thread
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                
                                
                                // Show the alert if it has not been showed already (we need this in case the user clicks many times -- quickly -- on the log-in button before it is disabled. This if statement prevents the display of multiple alerts).
                                if (self.presentedViewController == nil)
                                {
                                    showAlert("Please try again...", message: "The email and password do not match.", buttonTitle: "Try again", sender: self)
                                    
                                }
                                
                                // Stop showing activity indicator (spinner)
                                self.spinner.stopAnimating()
                                
                                print("LogIn Error")
                                
                            })
                            
                        }
                    
                })
            
        })
        

        // Enable the log-in button again
        logInButton.enabled = true
        
    }
}