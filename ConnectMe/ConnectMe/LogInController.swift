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
    
    override func viewDidLoad() {
        // Show activity indicator (spinner)
    }
    
    @IBAction func emailEditingDidEnd(sender: UITextField) {
    }
    
    @IBAction func passwordEditingDidEnd(sender: UITextField) {
    }

    @IBAction func loginButtonClicked(sender: UIButton) {
        
        // Show activity indicator (spinner)
        spinner.startAnimating()
        
        let userEmailString:String = userEmail.text!
        let userPasswordString:String =  userPassword.text!

        
                
//        PFUser.logInWithUsernameInBackground("Austin", password: "123")
        
        do
        {
            

//            
//            dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                self.spinner.startAnimating()
//            })
            
            try PFUser.logInWithUsername(userEmailString, password: userPasswordString)
            
            // Stop showing activity indicator (spinner)
            spinner.stopAnimating()
            
            print("User logged in!")
            performSegueWithIdentifier("HomeViewController", sender: nil)
            
            
        }
        // Catch exception and display error if user does not exist
        catch
        {
            // Create alert to send to user
            let alert = UIAlertController(title: "Please try again...", message: "The email and password do not match.", preferredStyle: UIAlertControllerStyle.Alert)
            
            // Create the action to add to alert
            let alertAction = UIAlertAction(title: "Try again", style: UIAlertActionStyle.Default, handler: nil)
            
            // Add the action to the alert
            alert.addAction(alertAction)
            
            // Stop showing activity indicator (spinner)
            spinner.stopAnimating()
            
            // Show the alert
            showViewController(alert, sender: nil)
            
            
            print("LogIn Error")
            
        }
        
    }
    
    
}
