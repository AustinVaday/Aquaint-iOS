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
import AWSCognitoIdentityProvider
import AWSMobileHubHelper


class LogInController: UIViewController {
        
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var checkMarkView: UIView!
    @IBOutlet weak var checkMarkFlipped: UIImageView!
    @IBOutlet weak var emblem: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var logInButton: UIButton!
    
    var checkMarkFlippedCopy: UIImageView!
    var pool : AWSCognitoIdentityUserPool!
    
    let segueDestination = "toMainContainerViewController"
    
    // Counts how many times the user has incorrectly logged in.
    /* var wrongLogInCount: Int = 0 */
    
    override func viewDidLoad() {
    
        // GET AWS IDENTITY POOL
        pool = getAWSCognitoIdentityUserPool()
        
        
        self.checkMark.hidden = true
        self.checkMarkFlipped.hidden = true
        self.emblem.hidden = false
        
        checkMarkFlippedCopy = UIImageView(image: checkMark.image)
        
        flipImageHorizontally(checkMarkFlippedCopy)
    }
    
    
//    @IBAction func emailEditingDidEnd(sender: UITextField) {
//        let userEmailString:String = userEmail.text!
//        
//        if (userEmailString.isEmpty)
//        {
//            print("Empty email string")
//        }
//        else if(verifyEmailFormat(userEmailString))
//        {
//            print("PROPER EMAIL")
//        }
//        else
//        {
//            //TODO: make email field red.
//            print("IMPROPER EMAIL")
//        }
//        
//        
//    }
    
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
    @IBAction func userNameEditingDidEndOnExit(sender: AnyObject) {
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
        
        let userNameString:String = userName.text!.lowercaseString
        let userPasswordString:String =  userPassword.text!
        
        
        // Attempt to log user in
        pool.getUser(userNameString).getSession(userNameString, password: userPasswordString, validationData: nil, scopes: nil).continueWithBlock({ (sessionResultTask) -> AnyObject? in
            
            // If success login
            if sessionResultTask.error == nil
            {
                //let userId = ?
        
                //TODO: Map username to user ID?
                
                // Set cached current user
                setCurrentUser(userNameString)
                
                
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

            }
            else // If failure to login
            {
//                // Show the alert if it has not been showed already (we need this in case the user clicks many times -- quickly -- on the log-in button before it is disabled. This if statement prevents the display of multiple alerts).
//                if (self.presentedViewController == nil)
//                {
//                    showAlert("Sorry", message: "We could not log you in at this time, please try again.", buttonTitle: "Try again", sender: self)
//                }
                
                
                // Sign out?
                
                // Perform update on UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    self.spinner.stopAnimating()

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
            
            return nil
        })
        

        // Enable the log-in button again
        logInButton.enabled = true
        
    }
}