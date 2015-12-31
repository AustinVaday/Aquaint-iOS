//
//  LogInController.swift
//  ConnectMe
//
//  Created by Austin Vaday on 12/27/15.
//  Copyright © 2015 ConnectMe. All rights reserved.
//

import UIKit
import Parse

class LogInController: UIViewController {
        
    @IBOutlet weak var userEmail: UITextField!
    @IBOutlet weak var userPassword: UITextField!
    @IBOutlet weak var checkMark: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var logInButton: UIButton!
    
    
    // Counts how many times the user has incorrectly logged in.
    /* var wrongLogInCount: Int = 0 */
    
    override func viewDidLoad() {      
    }
    
    @IBAction func emailEditingDidEnd(sender: UITextField) {
    }
    
    @IBAction func passwordEditingDidEnd(sender: UITextField) {
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
            
            do
            {
                self.spinner.startAnimating()
            
                try PFUser.logInWithUsername(userEmailString, password: userPasswordString)
            
                // Perform update on UI on main thread
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    
                    // Stop showing activity indicator (spinner)
                    self.spinner.stopAnimating()
                    
                    self.checkMark.hidden = false
                    
                    print("User logged in!")
                    self.performSegueWithIdentifier("HomeViewController", sender: nil)
                    
                    self.checkMark.hidden = true
                    
                })
          

            
            
            }
            // Catch exception and display error if user does not exist
            catch
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
        

        // Enable the log-in button again
        logInButton.enabled = true
        
    }
}